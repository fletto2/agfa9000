/*
 * agfa9000.c -- Agfa Compugraphic 9000PS Emulator
 *
 * Emulates the Agfa 9000PS PostScript RIP main board:
 *   - Motorola 68020 @ 16MHz (via Musashi)
 *   - 640KB ROM (5 banks)
 *   - Up to 16MB RAM with optional stuck-bit fault injection
 *   - Zilog Z8530 SCC (proper register emulation, dual address decode)
 *   - AMD AM5380 SCSI (full bus phase state machine, HD image support)
 *   - Hardware registers at 0x06xxxxxx
 *
 * Usage:
 *   agfa9000 <rom_dir> [options]
 *   agfa9000 <rom_dir> -hd <image>       Mount HD image at SCSI ID 0
 *   agfa9000 <rom_dir> -stuck 16         Inject D16 stuck-low fault
 *   agfa9000 <rom_dir> -ram 6            Set RAM to 6MB
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>

#include "musashi/m68k.h"
#include "scc.h"
#include "scsi.h"
#include "ioboard.h"

/* ================================================================== */
/* Memory                                                             */
/* ================================================================== */

#define ROM_SIZE    (128 * 1024)
#define ROM_BANKS   5
#define ROM_TOTAL   (ROM_SIZE * ROM_BANKS)
#define RAM_MAX     (16 * 1024 * 1024)

static unsigned char rom[ROM_TOTAL];
static unsigned char ram[RAM_MAX];
static unsigned int  ram_size = 4 * 1024 * 1024;

/* Stuck-bit fault injection */
static unsigned int  stuck_mask = 0;
static unsigned int  stuck_value = 0;
static unsigned int  stuck_addr_start = 0x02200000;
static unsigned int  stuck_addr_end   = 0x02300000;

/* Hardware registers */
static unsigned char bus_ctl_latch = 0x31;
static unsigned char gfx_ctl_latch = 0;
static unsigned short fifo_ctl = 0;
static unsigned int  display_ctl = 0;

/* Peripherals */
static scc_t scc;
static ncr5380_t scsi;

/* R6522 VIA #1 (0x04000000) + VIA #2 (0x04000020) — IO board communication */
#include "via.h"
static via6522_t via[2];

/* IO board */
static ioboard_t ioboard;
static xfifo_t fifo_main_to_io;
static xfifo_t fifo_io_to_main;
extern ioboard_t *current_io_ptr;  /* defined in ioboard.c */

/* CPU dispatch: 0 = main 68020, 1 = IO board 68000 */
int emu_current_cpu = 0;

/* Cycle counter */
static unsigned long long total_cycles = 0;
int verbose = 0;

/* Sys/Start injection: feed the boot PS file through SCC after XON */
static unsigned char *sysstart_data = NULL;
static int sysstart_len = 0;
static int sysstart_pos = 0;

/* Terminal */
static struct termios orig_termios;
static int terminal_raw = 0;

/* ================================================================== */
/* Terminal I/O                                                       */
/* ================================================================== */

static void term_raw_on(void)
{
    struct termios t;
    tcgetattr(0, &orig_termios);
    t = orig_termios;
    t.c_lflag &= ~(ICANON | ECHO);
    t.c_cc[VMIN] = 0;
    t.c_cc[VTIME] = 0;
    tcsetattr(0, TCSANOW, &t);
    fcntl(0, F_SETFL, fcntl(0, F_GETFL) | O_NONBLOCK);
    terminal_raw = 1;
}

static void term_raw_off(void)
{
    if (terminal_raw) {
        fcntl(0, F_SETFL, fcntl(0, F_GETFL) & ~O_NONBLOCK);
        tcsetattr(0, TCSANOW, &orig_termios);
        terminal_raw = 0;
    }
}

/* ================================================================== */
/* SCC TX callback — sends serial output to host stdout               */
/* ================================================================== */

static void scc_tx_handler(int channel, uint8_t data, void *ctx)
{
    /* Output from both channels goes to stdout */
    char c = data;
    write(1, &c, 1);
}

static int irq_count = 0;
static void scc_irq_handler(int state, void *ctx)
{
    /* SCC interrupt: Level 5 autovector on the Agfa 9000PS */
    if (state) {
        m68k_set_irq(5);
        irq_count++;
    } else {
        m68k_set_irq(0);
    }
}

/* Check host stdin for input → feed to SCC RX */
/* Track which SCC channel has been read from (= active console).
 * Referenced by scc.c to auto-detect on first RX data read. */
int console_channel = -1;  /* -1 = unknown, feed both */

static void check_host_input(void)
{
    unsigned char c;

    /* Only feed characters when the SCC receiver is enabled (WR3 bit 0).
     * This prevents stdin bytes from being consumed before the BIOS
     * initializes the SCC — on real hardware, characters wait in the
     * line buffer until the receiver is ready. */
    int a_rx_en = scc.ch[SCC_CH_A].wr[3] & 0x01;
    int b_rx_en = scc.ch[SCC_CH_B].wr[3] & 0x01;
    { static int input_trace = 0;
      if (input_trace == 0 && (a_rx_en || b_rx_en)) {
          fprintf(stderr, "[INPUT-EN] a_wr3=0x%02X b_wr3=0x%02X ch=%d\n",
                  scc.ch[SCC_CH_A].wr[3], scc.ch[SCC_CH_B].wr[3], console_channel);
          input_trace = 1;
      }
    }
    if (!a_rx_en && !b_rx_en)
        return;  /* SCC not initialized yet — hold stdin */

    if (console_channel >= 0) {
        /* Feed only the detected console channel */
        if (scc.ch[console_channel].rx_fifo_count < 16) {
            if (read(0, &c, 1) == 1)
                scc_rx_char(&scc, console_channel, c);
        }
    } else {
        /* Not yet determined — feed all RX-enabled channels with FIFO room */
        int a_room = a_rx_en && scc.ch[SCC_CH_A].rx_fifo_count < 16;
        int b_room = b_rx_en && scc.ch[SCC_CH_B].rx_fifo_count < 16;
        if (a_room || b_room) {
            if (read(0, &c, 1) == 1) {
                if (a_room) scc_rx_char(&scc, SCC_CH_A, c);
                if (b_room) scc_rx_char(&scc, SCC_CH_B, c);
            }
        }
    }
}

/* ================================================================== */
/* RAM with stuck-bit fault injection                                 */
/* ================================================================== */

static inline unsigned char apply_stuck_byte(unsigned int addr, unsigned char val)
{
    if (stuck_mask && addr >= stuck_addr_start && addr < stuck_addr_end) {
        int byte_pos = 3 - (addr & 3);
        unsigned char byte_mask = (stuck_mask >> (byte_pos * 8)) & 0xFF;
        if (byte_mask) {
            if (stuck_value) val |= byte_mask;
            else val &= ~byte_mask;
        }
    }
    return val;
}

/* ================================================================== */
/* Musashi memory callbacks                                           */
/* ================================================================== */

/* Forward declarations for IO board memory access */
extern uint8_t ioboard_read8(unsigned int addr);
extern void ioboard_write8(unsigned int addr, uint8_t val);

/* Crash trace: circular buffer of last 16 PCs.
 * When CPU reads address 0 (reset vector fetch = crash), dump the buffer. */
static unsigned int pc_history[4096];
static int pc_hist_idx = 0;

static void pc_history_record(void)
{
    pc_history[pc_hist_idx & 15] = m68k_get_reg(NULL, M68K_REG_PC);
    pc_hist_idx++;
}

/* Musashi instruction hook — called BEFORE every instruction */
static unsigned int last_vbr = 0;
static unsigned int irq_trace[128];
static int irq_trace_idx = 0;
static int irq_trace_armed = 0;

void agfa_instr_hook(unsigned int pc)
{
    pc_history[pc_hist_idx & 4095] = pc;
    pc_hist_idx++;

    /* Shell at 0x02045D00: text=0x3114, total=0x14D70 (334 clicks)
     * Text: 0x02045D00 - 0x02048E14
     * Data/BSS/Stack: 0x02048E14 - 0x0205AB00
     * Crash at 0x0205AAEC = executing shell's stack */
    if (pc >= 0x02048E14 && pc < 0x0205B000) {
        static int bad_pc = 0;
        if (bad_pc == 0) {
            fprintf(stderr, "\n[WILD-PC] at 0x%08X — last 500 PCs:\n", pc);
            for (int j = 500; j >= 1; j--) {
                unsigned int p = pc_history[(pc_hist_idx - j) & 4095];
                char tag = ' ';
                if (p >= 0x02045D00 && p < 0x02048E14) tag = 'C';
                else if (p >= 0x02000000 && p < 0x02020000) tag = 'K';
                else if (p >= 0x02048E14 && p < 0x0205B000) tag = 'X';
                else tag = '?';
                fprintf(stderr, "  [-%03d] %c 0x%08X\n", j, tag, p);
            }
            bad_pc = 1;
            /* Find where loaded text ends - scan for first zero word */
            fprintf(stderr, "\n[TEXT-SCAN] Finding where text becomes zeros:\n");
            unsigned int scan_addr;
            for (scan_addr = 0x02045D00; scan_addr < 0x02049000; scan_addr += 16) {
                unsigned int w = (m68k_read_memory_8(scan_addr) << 24) |
                                 (m68k_read_memory_8(scan_addr+1) << 16) |
                                 (m68k_read_memory_8(scan_addr+2) << 8) |
                                  m68k_read_memory_8(scan_addr+3);
                if (w == 0) {
                    /* Found zero, show a few lines before */
                    fprintf(stderr, "  First zero 32-bit word at 0x%08X (offset 0x%X)\n",
                            scan_addr, scan_addr - 0x02045D00);
                    for (unsigned int a = scan_addr - 64; a < scan_addr + 64; a += 16) {
                        fprintf(stderr, "  %08X:", a);
                        for (int b = 0; b < 16; b++)
                            fprintf(stderr, " %02X", m68k_read_memory_8(a + b));
                        fprintf(stderr, "\n");
                    }
                    break;
                }
            }
        }
    }

    /* After the timer IRQ fires, record the next 128 raw instruction PCs */
    if (irq_trace_armed == 1) {
        irq_trace[irq_trace_idx++] = pc;
        if (irq_trace_idx >= 128) {
            fprintf(stderr, "\n=== 128 instructions after timer IRQ ===\n");
            for (int i = 0; i < 128; i++)
                fprintf(stderr, "  [%3d] 0x%08X\n", i, irq_trace[i]);
            fprintf(stderr, "=== END ===\n");
            irq_trace_armed = 2;
        }
    }

    /* Detect VBR changes */
    unsigned int vbr = m68k_get_reg(NULL, M68K_REG_VBR);
    if (vbr != last_vbr) {
        unsigned int v29 = m68k_read_memory_32(vbr + 29*4);
        unsigned int v24 = m68k_read_memory_32(vbr + 24*4);
        unsigned int v32 = m68k_read_memory_32(vbr + 32*4);
        fprintf(stderr, "[VBR] changed: 0x%08X -> 0x%08X at PC=0x%08X v24=0x%08X v29=0x%08X v32=0x%08X\n",
                last_vbr, vbr, pc, v24, v29, v32);
        last_vbr = vbr;
    }
}

static void crash_dump(void)
{
    FILE *f = fopen("crash.log", "a");
    if (!f) return;
    fprintf(f, "--- CRASH (read from addr 0x00000000) at cycle %llu ---\n", total_cycles);
    int i;
    for (i = 0; i < 64; i++) {
        unsigned int pc = pc_history[(pc_hist_idx + i) & 63];
        fprintf(f, "  PC[-%02d] = 0x%08X\n", 63 - i, pc);
    }
    fprintf(f, "\n");
    fclose(f);
    fprintf(stderr, "[CRASH] PC trace dumped to crash.log\n");
}

unsigned int m68k_read_memory_8(unsigned int addr)
{
    /* Crash detection: only triggers on 32-bit reads from address 0
     * when the PC is also 0 (actual reset/double-fault). Normal code
     * can read address 0 legitimately (it's valid ROM). */

    /* IO board CPU active? */
    if (emu_current_cpu == 1)
        return ioboard_read8(addr);

    /* ROM */
    if (addr < ROM_TOTAL)
        return rom[addr];

    /* RAM */
    if (addr >= 0x02000000 && addr < 0x02000000 + ram_size)
        return apply_stuck_byte(addr, ram[addr - 0x02000000]);

    /* R6522 VIA #1 at 0x04000000 and VIA #2 at 0x04000020
     * PAL direct-register decode: 16 registers at byte offsets 0x00-0x0F.
     * Adrian verified: both VIAs' I/O lines go to 50-pin ribbon → IO board.
     * VIA #1 Port A = 8-bit parallel data bus to IO board
     * VIA #1 Port B = handshake/clock signals
     * VIA #2 Port B bits 6-7 = input from IO board (handshake back) */
    if (addr >= 0x04000000 && addr <= 0x0400002F) {
        int offset = addr & 0x3F;
        int via_num = (offset & 0x20) ? 1 : 0;
        int reg = offset & 0x0F;
        return via_read(&via[via_num], reg);
    }

    /* SCSI NCR 5380: addresses 0x05000000-0x0500000F
     * Register selected by address bits A2-A0 (address >> 1 & 7).
     * The firmware accesses both even and odd addresses for the same register. */
    /* SCSI NCR 5380: addresses 0x05000000-0x0500000F
     * Register = (addr & 0x0E) >> 1 : registers at 2-byte intervals.
     * Even addresses = write side, odd addresses = read side.
     * 0x5000000/1 = reg 0, 0x5000002/3 = reg 1, ... 0x500000E/F = reg 7 */
    if (addr >= 0x05000000 && addr <= 0x0500000F) {
        int reg = addr & 7;
        return ncr5380_read(&scsi, reg);
    }

    /* SCSI pseudo-DMA (firmware uses 0x5000020, docs say 0x5000026) */
    if (addr >= 0x05000020 && addr <= 0x05000027)
        return ncr5380_dma_read(&scsi);

    /* Bus control latch */
    if (addr == 0x06000000) return bus_ctl_latch;
    if (addr == 0x06080000) return gfx_ctl_latch;
    if (addr == 0x060C0000) return fifo_ctl >> 8;
    if (addr == 0x060C0001) return fifo_ctl & 0xFF;
    if (addr >= 0x06100000 && addr <= 0x06100003)
        return (display_ctl >> (8 * (3 - (addr & 3)))) & 0xFF;

    /* SCC #2 at 0x07000000 (compact byte-addressed) */
    if (addr >= 0x07000000 && addr <= 0x07000003) {
        static int scc2_reads[4] = {0};
        scc2_reads[addr & 3]++;
        if (scc2_reads[addr & 3] <= 3)
            fprintf(stderr, "[SCC2] read addr=%d PC=0x%08X cnt=%d/%d/%d/%d\n",
                addr & 3, m68k_get_reg(NULL, M68K_REG_PC),
                scc2_reads[0], scc2_reads[1], scc2_reads[2], scc2_reads[3]);
        return scc_compact_read(&scc, addr & 3);
    }

    /* SCC reset strobe */
    if (addr == 0x07000020)
        return 0;

    return 0;
}

unsigned int m68k_read_memory_16(unsigned int addr)
{
    return (m68k_read_memory_8(addr) << 8) | m68k_read_memory_8(addr + 1);
}

unsigned int m68k_read_memory_32(unsigned int addr)
{
    /* Crash detection: 32-bit read from address 0 = reset SSP fetch.
     * This only happens during actual CPU reset or double bus fault. */
    if (addr == 0 && emu_current_cpu == 0) {
        unsigned int pc = m68k_get_reg(NULL, M68K_REG_PC);
        /* Only trigger if PC suggests we're in a reset/exception cascade,
         * not normal code reading ROM address 0 */
        if (pc < 0x100 || pc > 0x02100000) {
            static int crash_count = 0;
            if (crash_count < 5) {
                crash_dump();
                crash_count++;
            }
        }
    }

    /* IO board dispatch (must be before fast paths!) */
    if (emu_current_cpu == 1)
        return (m68k_read_memory_16(addr) << 16) | m68k_read_memory_16(addr + 2);

    /* Fast path: ROM (main board only) */
    if (addr + 3 < ROM_TOTAL)
        return (rom[addr] << 24) | (rom[addr+1] << 16)
             | (rom[addr+2] << 8) | rom[addr+3];

    /* Fast path: RAM (main board only) */
    if (addr >= 0x02000000 && addr + 3 < 0x02000000 + ram_size) {
        unsigned int off = addr - 0x02000000;
        unsigned int val = (ram[off] << 24) | (ram[off+1] << 16)
                         | (ram[off+2] << 8) | ram[off+3];
        if (stuck_mask && addr >= stuck_addr_start && addr < stuck_addr_end) {
            if (stuck_value) val |= stuck_mask;
            else val &= ~stuck_mask;
        }
        return val;
    }

    return (m68k_read_memory_16(addr) << 16) | m68k_read_memory_16(addr + 2);
}

void m68k_write_memory_8(unsigned int addr, unsigned int val)
{
    if (emu_current_cpu == 1) {
        ioboard_write8(addr, val);
        return;
    }
    if (addr >= 0x02000000 && addr < 0x02000000 + ram_size) {
        ram[addr - 0x02000000] = val;
        return;
    }
    /* R6522 VIA #1 (0x04000000) + VIA #2 (0x04000020) — IO board communication */
    if (addr >= 0x04000000 && addr <= 0x0400002F) {
        int offset = addr & 0x3F;
        int via_num = (offset & 0x20) ? 1 : 0;
        int reg = offset & 0x0F;
        /* Save old ORB for edge detection */
        uint8_t old_orb = via[via_num].orb;

        via_write(&via[via_num], reg, val);

        /* SCC2691 emulation: when VIA #1 ORB changes and DDRA=0 (input),
         * put the appropriate SCC2691 register value on PA pins immediately.
         * This ensures the main board sees the right value when it reads ORA. */
        if (via_num == 0 && reg == VIA_ORB && via[0].ddra == 0x00) {
            int scc2691_reg = (via[0].orb >> 5) & 7;
            switch (scc2691_reg) {
            case 1: { /* SRA — status register */
                uint8_t sra = 0x0C;  /* TXRDY + TXEMT */
                if (fifo_io_to_main.count > 0)
                    sra |= 0x01;  /* RXRDY */
                via_set_pa(&via[0], sra);
                break;
            }
            case 5: { /* ISR — interrupt status
                      * Bit 0=TxRDY, Bit 1=RxRDY/FFULL, Bit 2=counter ready,
                      * Bit 3=delta break. Firmware checks bit 2 in DMA receive. */
                uint8_t isr = 0x05;  /* TxRDY + counter ready (bit 2) */
                if (fifo_io_to_main.count > 0)
                    isr |= 0x02;  /* RxRDY */
                via_set_pa(&via[0], isr);
                break;
            }
            case 3: /* RHR — receive data */
                if (fifo_io_to_main.count > 0) {
                    uint8_t byte;
                    xfifo_get(&fifo_io_to_main, &byte);
                    via_set_pa(&via[0], byte);
                    {
                        static int rhr_trace = 0;
                        if (rhr_trace < 20) {
                            fprintf(stderr, "[SCC2691-RHR] byte=0x%02X '%c' remaining=%d\n",
                                    byte, byte >= 0x20 && byte < 0x7F ? byte : '.', fifo_io_to_main.count);
                            rhr_trace++;
                        }
                    }
                } else {
                    via_set_pa(&via[0], 0x00);
                }
                break;
            default:
                via_set_pa(&via[0], 0x00);
                break;
            }
        }

        /* Inter-board wiring: VIA #1 ↔ IO board data transfer.
         *
         * The DMA protocol uses ORB as a clocked handshake:
         *   1. Set DDRA=0xFF (output), write data byte to ORA
         *   2. Toggle ORB bits (AND masks clear clock phases)
         *   3. OR 0xFC restores idle → this completes the clock cycle
         *   4. Data byte is now latched by IO board hardware
         *
         * For receive:
         *   1. Set DDRA=0x00 (input)
         *   2. Toggle ORB bits (different mask pattern)
         *   3. Read ORA-nh to get the byte from IO board
         *
         * Trigger: when ORB transitions to idle (bits 2-7 all set after
         * being partially cleared), the clock cycle is complete. */
        if (via_num == 0 && reg == VIA_ORB) {
            uint8_t new_orb = via[0].orb;
            /* Detect idle-restore: bits 2-7 going from partially cleared to all set.
             * The OR 0xFC pattern sets bits 2-7 = 0xFC mask on the ORB. */
            int was_active = (old_orb & 0xFC) != 0xFC;
            int now_idle = (new_orb & 0xFC) == 0xFC;
            if (was_active && now_idle) {
                /* Clock cycle complete.
                 * ORB bits 7-5 encode the SCC2691 register being accessed:
                 *   0=MRA, 1=CSRA, 2=CRA, 3=THR/RHR, 4=ACR, 5=IMR, 6=CTU, 7=CTL
                 * Only register 3 (THR) writes are actual data bytes.
                 * All others are SCC2691 configuration — don't forward to DUART. */
                int scc2691_reg = (old_orb >> 5) & 7;

                if (verbose) {
                    static int clk_trace = 0;
                    if (clk_trace < 500)
                        fprintf(stderr, "[VIA-CLK] orb=0x%02X reg=%d ddra=0x%02X ora=0x%02X %s\n",
                                old_orb, scc2691_reg, via[0].ddra, via[0].ora,
                                (scc2691_reg == 3 && via[0].ddra == 0xFF) ? "→DATA" :
                                (via[0].ddra == 0x00) ? "←READ" : "(config)");
                    clk_trace++;
                }

                if (via[0].ddra == 0xFF && scc2691_reg == 3) {
                    /* Write to SCC2691 THR (TX Holding Register):
                     * This is an actual data byte for the IO board.
                     * Forward to DUART RX via the serial cross-connect. */
                    xfifo_put(&fifo_main_to_io, via[0].ora);
                } else if (via[0].ddra == 0x00 && scc2691_reg == 3) {
                    /* Read from SCC2691 RHR (RX Holding Register):
                     * IO board sent data back. VIA PA pins already set
                     * from fifo_io_to_main in the main loop tick. */
                }
            }
        }
        return;
    }
    if (addr >= 0x05000000 && addr <= 0x0500000F) {
        int reg = addr & 7;
        ncr5380_write(&scsi, reg, val);
        return;
    }
    if (addr >= 0x05000020 && addr <= 0x05000027) { ncr5380_dma_write(&scsi, val); return; }
    if (addr == 0x06000000) {
        uint8_t old = bus_ctl_latch;
        bus_ctl_latch = val;
        if (val != old) {
            static int latch_trace = 0;
            if (latch_trace < 30) {
                fprintf(stderr, "[LATCH] 0x%02X -> 0x%02X (diff=%02X)\n",
                        old, val, old ^ val);
                latch_trace++;
            }
        }
        /* SCSI selection via bus control latch:
         * The Agfa firmware drives SCSI bus signals through the latch
         * instead of the NCR 5380's ICR register.
         * Bit 5 = /SEL, Bit 4 = /BSY
         * When SEL is asserted (bit 5 set) and a target ID is on the
         * NCR 5380 data bus, perform SCSI selection. */
        if (!(val & 0x20) && (old & 0x20)) {
            /* SEL is active-LOW: bit 5 going from 1→0 = assertion */
            /* SEL just asserted — check data bus for target ID */
            /* Use last non-zero NCR data as target ID bit mask.
             * The firmware writes the target ID to NCR reg 0 before
             * asserting SEL through the bus latch. By the time SEL
             * is asserted, reg 0 may have been cleared. */
            static uint8_t last_nonzero_data = 0;
            if (scsi.output_data != 0) last_nonzero_data = scsi.output_data;
            uint8_t data = last_nonzero_data;
            fprintf(stderr, "[SCSI-SEL] SEL asserted, last_data=0x%02X\n", data);
            int id;
            for (id = 0; id < 8; id++) {
                if ((data & (1 << id)) && scsi.devices[id].present) {
                    scsi.selected_id = id;
                    scsi.phase = SCSI_PHASE_COMMAND;
                    scsi.cmd_pos = 0;
                    scsi.cmd_len = 0;
                    fprintf(stderr, "[SCSI] Selected ID %d via bus latch!\n", id);
                    break;
                }
            }
        }
        return;
    }
    if (addr == 0x06080000) { gfx_ctl_latch = val; return; }
    if (addr == 0x060C0000) { fifo_ctl = val << 8; return; }
    if (addr == 0x060C0001) { fifo_ctl = (fifo_ctl & 0xFF00) | val; return; }
    if (addr >= 0x06100000 && addr <= 0x06100003) {
        int shift = 8 * (3 - (addr & 3));
        display_ctl = (display_ctl & ~(0xFF << shift)) | (val << shift);
        return;
    }
    if (addr >= 0x07000000 && addr <= 0x07000003) {
        /* Count SCC Channel A data writes (addr=3) */
        if (addr == 0x07000003) {
            static int scc_tx_count = 0;
            scc_tx_count++;
            /* Log at specific milestones */
            if (scc_tx_count == 100 || scc_tx_count == 500 || scc_tx_count == 1000 || scc_tx_count == 2000)
                fprintf(stderr, "[SCC-TX] count=%d val=0x%02X '%c'\n",
                        scc_tx_count, val, (val >= 0x20 && val < 0x7F) ? val : '.');
        }
        scc_compact_write(&scc, addr & 3, val);
        /* Check ocount debug marker */
        if (addr == 0x07000003) {
            int ocount_dbg = (int)(signed char)ram[0x10]<<24 | (ram[0x11]<<16) | (ram[0x12]<<8) | ram[0x13];
            static int last_oc = -1;
            if (ocount_dbg != last_oc && ocount_dbg > 0) {
                fprintf(stderr, "[OCOUNT] = %d after SCC TX\n", ocount_dbg);
                last_oc = ocount_dbg;
            }
        }
        return;
    }
    /* Ignore: ROM writes, SCC strobe, unmapped */
}

void m68k_write_memory_16(unsigned int addr, unsigned int val)
{
    m68k_write_memory_8(addr, (val >> 8) & 0xFF);
    m68k_write_memory_8(addr + 1, val & 0xFF);
}

void m68k_write_memory_32(unsigned int addr, unsigned int val)
{
    if (emu_current_cpu == 1) {
        m68k_write_memory_16(addr, (val >> 16) & 0xFFFF);
        m68k_write_memory_16(addr + 2, val & 0xFFFF);
        return;
    }
    if (addr >= 0x02000000 && addr + 3 < 0x02000000 + ram_size) {
        unsigned int off = addr - 0x02000000;
        ram[off]   = (val >> 24) & 0xFF;
        ram[off+1] = (val >> 16) & 0xFF;
        ram[off+2] = (val >> 8) & 0xFF;
        ram[off+3] = val & 0xFF;
        return;
    }
    m68k_write_memory_16(addr, (val >> 16) & 0xFFFF);
    m68k_write_memory_16(addr + 2, val & 0xFFFF);
}

/* ================================================================== */
/* ROM loading                                                        */
/* ================================================================== */

static int load_rom(const char *dir, int bank, const char *name)
{
    char path[512];
    FILE *f;
    size_t n;
    snprintf(path, sizeof(path), "%s/%s", dir, name);
    f = fopen(path, "rb");
    if (!f) { fprintf(stderr, "Cannot open %s\n", path); return -1; }
    n = fread(rom + bank * ROM_SIZE, 1, ROM_SIZE, f);
    fclose(f);
    if (n != ROM_SIZE) {
        fprintf(stderr, "Short read on %s: %zu/%d bytes\n", path, n, ROM_SIZE);
        return -1;
    }
    fprintf(stderr, "Loaded %s -> bank %d (0x%05X-0x%05X)\n",
            name, bank, bank * ROM_SIZE, (bank + 1) * ROM_SIZE - 1);
    return 0;
}

static int load_all_roms(const char *dir)
{
    static const char *names[] = {"0.bin", "1.bin", "2.bin", "3.bin", "4.bin"};
    int i;
    for (i = 0; i < ROM_BANKS; i++)
        if (load_rom(dir, i, names[i]) < 0) return -1;
    return 0;
}

/* ================================================================== */
/* Main                                                               */
/* ================================================================== */

static void usage(const char *prog)
{
    fprintf(stderr, "Agfa 9000PS Emulator\n\n");
    fprintf(stderr, "Usage: %s <rom_dir> [options]\n\n", prog);
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  -hd <image>       Mount HD image at SCSI ID 0 (512-byte sectors)\n");
    fprintf(stderr, "  -hd1024 <image>   Mount HD image at SCSI ID 0 (1024-byte sectors)\n");
    fprintf(stderr, "  -ram <MB>         Set RAM size (1-16, default 4)\n");
    fprintf(stderr, "  -stuck <bit>      Inject stuck-LOW fault on data bit (0-31)\n");
    fprintf(stderr, "  -stuck-high <bit> Inject stuck-HIGH fault\n");
    fprintf(stderr, "  -stuck-range <start> <end>  Fault address range (hex)\n");
    fprintf(stderr, "  -rom <image>      Load flat ROM image (e.g. CP/M combined binary)\n");
    fprintf(stderr, "  -roms <dir>       Load split EPROMs from directory (Uxxx_LANEn.bin)\n");
    fprintf(stderr, "  -io <io.bin>      Load IO board ROM (68000, enables dual-CPU)\n");
    fprintf(stderr, "  -sysstart <file>  Inject Sys/Start file through SCC after boot\n");
    fprintf(stderr, "  -v                Verbose logging\n");
    fprintf(stderr, "\nExamples:\n");
    fprintf(stderr, "  %s roms/ -hd HD00_Agfa_RIP.hda     (Agfa PostScript firmware)\n", prog);
    fprintf(stderr, "  %s -rom image.bin                   (flat ROM image)\n", prog);
    fprintf(stderr, "  %s -roms cpm_test/                  (split EPROMs by socket)\n", prog);
    exit(1);
}

int main(int argc, char **argv)
{
    const char *rom_dir = NULL;
    const char *rom_image = NULL;   /* flat 640KB ROM image (e.g. CP/M) */
    const char *split_roms_dir = NULL;  /* directory of Uxxx_LANEn.bin split EPROMs */
    const char *hd_image = NULL;
    const char *io_rom = NULL;
    const char *sysstart_file = NULL;
    int hd_block_size = 512;
    int stuck_bit = -1;
    int stuck_high = 0;
    int i;

    for (i = 1; i < argc; i++) {
        if (argv[i][0] != '-') {
            rom_dir = argv[i];
        } else if (!strcmp(argv[i], "-rom") && i+1 < argc) {
            rom_image = argv[++i];
        } else if (!strcmp(argv[i], "-roms") && i+1 < argc) {
            split_roms_dir = argv[++i];
        } else if (!strcmp(argv[i], "-hd") && i+1 < argc) {
            hd_image = argv[++i]; hd_block_size = 512;
        } else if (!strcmp(argv[i], "-hd1024") && i+1 < argc) {
            hd_image = argv[++i]; hd_block_size = 1024;
        } else if (!strcmp(argv[i], "-ram") && i+1 < argc) {
            ram_size = atoi(argv[++i]) * 1024 * 1024;
            if (ram_size > RAM_MAX) ram_size = RAM_MAX;
        } else if (!strcmp(argv[i], "-stuck") && i+1 < argc) {
            stuck_bit = atoi(argv[++i]);
        } else if (!strcmp(argv[i], "-stuck-high") && i+1 < argc) {
            stuck_bit = atoi(argv[++i]); stuck_high = 1;
        } else if (!strcmp(argv[i], "-stuck-range") && i+2 < argc) {
            stuck_addr_start = strtoul(argv[++i], NULL, 16);
            stuck_addr_end = strtoul(argv[++i], NULL, 16);
        } else if (!strcmp(argv[i], "-io") && i+1 < argc) {
            io_rom = argv[++i];
        } else if (!strcmp(argv[i], "-sysstart") && i+1 < argc) {
            sysstart_file = argv[++i];
        } else if (!strcmp(argv[i], "-v")) {
            verbose = 1;
        } else {
            usage(argv[0]);
        }
    }
    if (!rom_dir && !rom_image && !split_roms_dir) usage(argv[0]);

    /* Fault injection */
    if (stuck_bit >= 0 && stuck_bit < 32) {
        stuck_mask = 1U << stuck_bit;
        stuck_value = stuck_high ? 1 : 0;
        fprintf(stderr, "Fault: D%d stuck %s at 0x%08X-0x%08X\n",
                stuck_bit, stuck_high ? "HIGH" : "LOW",
                stuck_addr_start, stuck_addr_end);
    }

    /* Load Sys/Start file for injection */
    if (sysstart_file) {
        FILE *f = fopen(sysstart_file, "rb");
        if (f) {
            fseek(f, 0, SEEK_END);
            sysstart_len = ftell(f);
            fseek(f, 0, SEEK_SET);
            sysstart_data = malloc(sysstart_len);
            fread(sysstart_data, 1, sysstart_len, f);
            fclose(f);
            fprintf(stderr, "Loaded Sys/Start: %s (%d bytes)\n", sysstart_file, sysstart_len);
        } else {
            fprintf(stderr, "Cannot open Sys/Start: %s\n", sysstart_file);
        }
    }

    /* Init peripherals */
    scc_init(&scc);
    scc_set_tx_callback(&scc, SCC_CH_A, scc_tx_handler, NULL);
    scc_set_tx_callback(&scc, SCC_CH_B, scc_tx_handler, NULL);
    /* Assert DCD on both channels — serial console has no modem.
     * Without DCD, Minix's rs_read sends SIGHUP and drops all input. */
    scc_set_dcd(&scc, SCC_CH_A, 1);
    scc_set_dcd(&scc, SCC_CH_B, 1);
    /* SCC interrupt callback: asserts Level 5 autovector on 68020 */
    scc_set_irq_callback(&scc, scc_irq_handler, NULL);
    /* CTS on Channel B: deasserted by default (auto-boots to PostScript,
     * matching Adrian's hardware). Use -cts to assert it and get the
     * Atlas Monitor prompt instead. */
    scc_set_cts(&scc, SCC_CH_B, 0);

    ncr5380_init(&scsi);

    /* Init R6522 VIAs for IO board communication */
    via_init(&via[0], "VIA1");
    via_init(&via[1], "VIA2");

    /* VIA #2 Timer 1 will be started by the firmware during boot/calibration.
     * Don't pre-start it — let the firmware configure it properly. */

    /* Init cross-connect FIFOs for IO board communication */
    xfifo_init(&fifo_main_to_io);
    xfifo_init(&fifo_io_to_main);

    /* Load ROMs */
    fprintf(stderr, "Agfa 9000PS Emulator\n");
    fprintf(stderr, "RAM: %d MB\n", ram_size / (1024 * 1024));
    if (rom_image) {
        /* Load flat ROM image (e.g. CP/M) */
        FILE *f = fopen(rom_image, "rb");
        if (!f) { fprintf(stderr, "Cannot open %s\n", rom_image); return 1; }
        size_t n = fread(rom, 1, ROM_TOTAL, f);
        fclose(f);
        fprintf(stderr, "Loaded ROM image: %s (%zu bytes)\n", rom_image, n);
        if (n < 8) { fprintf(stderr, "ROM image too small\n"); return 1; }
    } else if (split_roms_dir) {
        /* Load split EPROM images and interleave into combined ROM.
         * Socket map for Agfa main board (5 banks x 4 byte lanes): */
        static const struct { const char *socket; int bank; int lane; } eprom_map[] = {
            {"U291", 0, 0}, {"U294", 0, 1}, {"U283", 0, 2}, {"U281", 0, 3},
            {"U303", 1, 0}, {"U300", 1, 1}, {"U305", 1, 2}, {"U297", 1, 3},
            {"U306", 2, 0}, {"U304", 2, 1}, {"U287", 2, 2}, {"U284", 2, 3},
            {"U295", 3, 0}, {"U292", 3, 1}, {"U301", 3, 2}, {"U298", 3, 3},
            {"U16",  4, 0}, {"U20",  4, 1}, {"U19",  4, 2}, {"U17",  4, 3},
        };
        static const char *lane_names[] = {"HH", "HM", "LM", "LL"};
        memset(rom, 0xFF, ROM_TOTAL);  /* blank = 0xFF */
        int loaded = 0;
        for (int e = 0; e < 20; e++) {
            char path[512];
            snprintf(path, sizeof(path), "%s/%s_%s%d.bin",
                     split_roms_dir, eprom_map[e].socket,
                     lane_names[eprom_map[e].lane], eprom_map[e].bank);
            FILE *f = fopen(path, "rb");
            if (!f) continue;  /* missing = blank (0xFF) */
            unsigned char eprom[32768];
            size_t n = fread(eprom, 1, 32768, f);
            fclose(f);
            if (n != 32768) {
                fprintf(stderr, "Warning: %s is %zu bytes (expected 32768)\n", path, n);
            }
            /* Interleave into combined ROM: each EPROM byte maps to
             * rom[bank*128K + i*4 + lane] */
            int bank = eprom_map[e].bank;
            int lane = eprom_map[e].lane;
            for (size_t i = 0; i < n; i++) {
                rom[bank * 131072 + i * 4 + lane] = eprom[i];
            }
            loaded++;
        }
        fprintf(stderr, "Loaded %d split EPROMs from %s\n", loaded, split_roms_dir);
        rom_image = split_roms_dir;  /* flag as non-Agfa for interrupt gating */
    } else {
        if (load_all_roms(rom_dir) < 0) return 1;
    }

    /* Mount HD image */
    if (hd_image) {
        if (ncr5380_attach_image(&scsi, 0, hd_image, hd_block_size) < 0)
            return 1;
    }

    /* Patch self-test to return immediately (D0=0 = pass).
     * The self-test at 0x84658 fills/verifies all of RAM which takes
     * forever at emulated speed. Patch entry: moveq #0,d0; rts */
    /* ROM verified intact. The function at 0x898B8 exists and starts with
     * LINK A6, #0 (proper C function prologue). Previous analysis
     * confused file offset 0x198B8 (= address 0x998B8, which IS zeros)
     * with the correct offset 0x98B8 (= address 0x898B8, which has code). */

    /* Init both CPUs using the Plexus dual-CPU pattern:
     * allocate context, set_context, set_cpu_type, m68k_init, pulse_reset, get_context */

    void *main_ctx = calloc(1, m68k_context_size());
    void *io_ctx = NULL;

    /* Main CPU: 68020 (matches real Agfa 9000PS hardware) */
    m68k_set_context(main_ctx);
    m68k_set_cpu_type(M68K_CPU_TYPE_68020);
    m68k_init();
    emu_current_cpu = 0;
    m68k_pulse_reset();
    m68k_get_context(main_ctx);

    fprintf(stderr, "Main CPU: SSP=0x%08X PC=0x%08X\n",
            m68k_read_memory_32(0), m68k_read_memory_32(4));

    /* IO board CPU: 68000 */
    if (io_rom) {
        ioboard_init(&ioboard, &fifo_main_to_io, &fifo_io_to_main);
        if (ioboard_load_rom(&ioboard, io_rom) == 0) {
            io_ctx = calloc(1, m68k_context_size());
            m68k_set_context(io_ctx);
            m68k_set_cpu_type(M68K_CPU_TYPE_68000);
            m68k_init();
            emu_current_cpu = 1;
            extern ioboard_t *current_io_ptr;  /* from ioboard.c */
            current_io_ptr = &ioboard;
            m68k_pulse_reset();

            /* Verify IO board CPU state immediately after reset */
            fprintf(stderr, "[IO] After reset: PC=0x%08X SP=0x%08X\n",
                    m68k_get_reg(NULL, M68K_REG_PC),
                    m68k_get_reg(NULL, M68K_REG_A7));

            /* Run a few instructions to verify */
            m68k_execute(10);
            fprintf(stderr, "[IO] After 10 cycles: PC=0x%08X SP=0x%08X\n",
                    m68k_get_reg(NULL, M68K_REG_PC),
                    m68k_get_reg(NULL, M68K_REG_A7));

            m68k_get_context(io_ctx);
            memcpy(ioboard.cpu_ctx, io_ctx, m68k_context_size());
            ioboard.loaded = 1;

            fprintf(stderr, "[IO] CPU: SSP=0x%08X PC=0x%08X\n",
                (ioboard.rom[0]<<24)|(ioboard.rom[1]<<16)|(ioboard.rom[2]<<8)|ioboard.rom[3],
                (ioboard.rom[4]<<24)|(ioboard.rom[5]<<16)|(ioboard.rom[6]<<8)|ioboard.rom[7]);

            /* Restore main CPU */
            emu_current_cpu = 0;
            current_io_ptr = NULL;
            m68k_set_context(main_ctx);
        }
    }

    fprintf(stderr, "Running... (Ctrl+C to quit)\n---\n");

    term_raw_on();
    atexit(term_raw_off);

    /* Main loop: time-slice between main CPU (68020 @ 16MHz) and
     * IO board CPU (68000 @ 8MHz). Run in 10ms slices:
     * Main: 160,000 cycles, IO: 80,000 cycles (half clock speed) */
    {
        unsigned long long last_report = 0;
        for (;;) {
            /* Check if VIA #2 Timer 1 interrupt should fire.
             * The timer ISR at 0x84B70 is invoked via Level 2 autovector.
             * Assert IRQ before execute() so Musashi can service it.
             * Only enable after the firmware has had time to set up vectors
             * (checked by looking at the timer handler vector at RAM 0x68). */
            {
                static int timer_irq_ok = 0;
                /* Only enable timer IRQ after the PS interpreter has installed
                 * the Level 2 handler at RAM 0x02000024 (indirect vector).
                 * Before that, the ROM stub at 0x6BC goes to error handler. */
                uint32_t l2_handler = (ram[0x24] << 24) | (ram[0x25] << 16) |
                                      (ram[0x26] << 8) | ram[0x27];
                if (!timer_irq_ok && l2_handler != 0) {
                    timer_irq_ok = 1;
                    /* Start VIA #2 Timer 1 in free-running mode.
                     * The firmware normally does this during calibration,
                     * but calibration is unreachable until the IO board
                     * handshake completes. */
                    via[1].acr |= 0x40;  /* Free-running mode */
                    via[1].t1_latch = 5000;
                    via[1].t1_counter = 5000;
                    via[1].t1_running = 1;
                    via[1].ier |= VIA_IRQ_T1;
                    fprintf(stderr, "[EMU] VIA2 Timer1 started + IRQ enabled at cycle %llu\n", total_cycles);
                }
                if (timer_irq_ok && via_irq_active(&via[1]))
                    m68k_set_irq(2);
                else if (timer_irq_ok && !via_irq_active(&via[1]))
                    m68k_set_irq(0);
            }

            /* Run main CPU */
            emu_current_cpu = 0;
            int cycles = m68k_execute(10000); /* 10K cycles per slice */
            total_cycles += cycles;
            pc_history_record();

            /* Run IO board CPU (68000 @ 8MHz ≈ half main board speed).
             * Run 100K IO cycles per slice to ensure the IO board can
             * complete init loops and respond to the main board in time.
             * On real hardware both CPUs run concurrently; here we interleave. */
            if (ioboard.loaded) {
                ioboard_run(&ioboard, 100000);
            }

            /* Sys/Start injection: after the PS interpreter sends XON (0x11)
             * and enters the SCC DMA polling loop, feed Sys/Start bytes
             * into the SCC RX on both channels. The interpreter reads
             * PostScript source from the serial port. */
            /* Sys/Start injection: feed one byte per slice into the
             * compact SCC RX, only when the FIFO has room.
             * The PS interpreter reads from the serial port via the
             * compact SCC at 0x07000000. */
            if (sysstart_data && sysstart_pos < sysstart_len) {
                /* Only feed when Channel B FIFO is empty (interpreter
                 * reads from Channel B via 0x07000000/01) */
                if (scc.ch[SCC_CH_B].rx_fifo_count == 0) {
                    scc_rx_char(&scc, SCC_CH_B, sysstart_data[sysstart_pos]);
                    scc_rx_char(&scc, SCC_CH_A, sysstart_data[sysstart_pos]);
                    sysstart_pos++;
                }
                if (sysstart_pos >= sysstart_len) {
                    fprintf(stderr, "[EMU] Sys/Start fully injected (%d bytes)\n", sysstart_len);
                    sysstart_data = NULL;  /* Don't inject again */
                }
            }

            /* (Handshake injection removed — 0x84C2E is timer calibration,
             * not IO board handshake. The BRG zero-count simulation in
             * scc.c now handles this correctly.) */

            check_host_input();
            scc_tick_n(&scc, cycles);
            ncr5380_tick(&scsi);

            /* Tick VIA timers (E clock = CPU clock / 10 for 68020 at 16MHz) */
            via_tick(&via[0], cycles / 10);
            via_tick(&via[1], cycles / 10);
            /* TODO: VIA #2 Timer 1 generates Level 2 autovector interrupt.
             * This is needed for the PS interpreter's timeout mechanism.
             * For now, just tick the timer so IFR bit 6 gets set when
             * the firmware polls it. The firmware also has a software
             * timeout counter that might work without actual interrupts. */

            /* Inter-board wiring: IO board → main board.
             *
             * The SCC2691 on the IO board sits between DUART and main VIA.
             * When the main board reads SCC2691 registers via VIA:
             *   - SRA (reg 1): status register (bit 0=RXRDY, bit 2=TXRDY)
             *   - RHR (reg 3): received data byte
             *
             * We emulate the SCC2691 by maintaining its register state on
             * the VIA PA input pins. The main board reads by setting DDRA=0
             * and toggling ORB with the register address, then reading ORA. */
            {
                /* SCC2691 emulated status: always TX ready.
                 * RX ready if IO board sent response data. */
                uint8_t scc2691_sra = 0x04;  /* TXRDY always */
                if (fifo_io_to_main.count > 0)
                    scc2691_sra |= 0x01;  /* RXRDY */

                /* When DDRA=0 (input mode), put appropriate value on PA
                 * based on the register being read (ORB bits 7-5). */
                if (via[0].ddra == 0x00) {
                    int scc2691_reg = (via[0].orb >> 5) & 7;
                    switch (scc2691_reg) {
                    case 1:  /* SRA — status register */
                        via_set_pa(&via[0], scc2691_sra);
                        break;
                    case 5:  /* ISR — interrupt status register */
                        /* Bit 0 = TxRDY, bit 1 = RxRDY/FFULL, bit 2 = delta break,
                         * bit 3 = counter ready, bit 4 = reserved */
                        {
                            uint8_t isr = 0x01;  /* TxRDY always set */
                            if (fifo_io_to_main.count > 0)
                                isr |= 0x02;  /* RxRDY */
                            via_set_pa(&via[0], isr);
                        }
                        break;
                    case 3:  /* RHR — receive holding register */
                        if (fifo_io_to_main.count > 0) {
                            uint8_t byte;
                            xfifo_get(&fifo_io_to_main, &byte);
                            via_set_pa(&via[0], byte);
                            if (verbose) {
                                static int rx_trace = 0;
                                if (rx_trace < 20)
                                    fprintf(stderr, "[SCC2691-RX] byte=0x%02X '%c' remaining=%d\n",
                                            byte, byte >= 0x20 && byte < 0x7F ? byte : '.',
                                            fifo_io_to_main.count);
                                rx_trace++;
                            }
                        } else {
                            via_set_pa(&via[0], 0x00);
                        }
                        break;
                    default:
                        /* Other registers: return 0 or last written value */
                        break;
                    }
                }

                /* Assert CA1 when IO board has data available */
                if (fifo_io_to_main.count > 0) {
                    via_set_ca1(&via[0], 0);  /* Falling edge */
                } else {
                    via_set_ca1(&via[0], 1);  /* Release */
                }
            }

            { static int loop_trace = 0;
              if (loop_trace == 2000) {
                fprintf(stderr, "[LOOP] cycle=%llu rom_image=%p\n", total_cycles, (void*)rom_image);
              }
              loop_trace++;
            }



            /* Agfa firmware-specific interrupt generation.
             * Skip when running a flat ROM image (e.g. CP/M) which
             * doesn't use the Agfa's timer/SCC interrupt scheme. */
            if (!rom_image) {
            /* SCC #1 interrupt: if the firmware has enabled TX interrupts
             * (WR1 bits) and the SCC is ready, assert Level 3 autovector.
             * The handler at 0x84A48 drives the DMA protocol. */
            {
                /* Check if SCC #1 TX interrupt is enabled.
                 * In PAL mode, WR1 is at offset 0x01 (Ch B) or 0x21 (Ch A).
                 * The firmware writes to 0x0400000E which we mapped as WR14,
                 * and to 0x0400000D as WR13. The actual interrupt enable
                 * might be at a different PAL offset.
                 * For now: if the init_scc1_and_scsi at 0x84AFC has run
                 * (it writes 3 to 0x0400000E), assert Level 3 periodically. */
                static int irq_counter = 0;
                /* Timer interrupt: Level 2 autovector (vector 26, addr 0x68).
                 * The timer ISR at 0x84B70 (installed to RAM 0x02000020)
                 * decrements the timeout counter at 0x02022378.
                 * Generate Level 2 interrupts periodically to drive timeouts. */
                {
                    /* CIO timer interrupt: assert Level 1, cleared when the ISR
                     * acknowledges by reading PAL offset 0x04 (CIO status).
                     * The ISR at 0x84B7E does: tstb 0x4000024 (acknowledge).
                     * We track this with a flag: set on assert, cleared on ack. */
                    {
                        static int timer_irq_pending = 0;
                        static int timer_irq_cooldown = 0;
                        if (timer_irq_cooldown > 0) {
                            timer_irq_cooldown--;
                        } else if (!timer_irq_pending) {
                            unsigned int handler = m68k_read_memory_32(0x02000020);
                            if (handler != 0) {
                                m68k_set_irq(1);
                                timer_irq_pending = 1;
                            }
                        }
                        /* The acknowledge happens when the ISR reads PAL offset 0x04
                         * (CIO timer register at 0x4000024). We detect this in the
                         * PAL read handler and clear the pending flag. For now, just
                         * deassert after a few slices to prevent re-entry. */
                        if (timer_irq_pending) {
                            static int ack_count = 0;
                            ack_count++;
                            if (ack_count >= 3) {
                                m68k_set_irq(0);
                                timer_irq_pending = 0;
                                timer_irq_cooldown = 20; /* Wait before next interrupt */
                                ack_count = 0;
                            }
                        }
                    }
                }

                /* SCC #1 interrupt: Level 5 autovector (vector 28, addr 0x70).
                 * The ROM stub at 0x706 reads the redirect pointer at
                 * 0x200002C and jumps to the handler at 0x84A48.
                 * The handler drives the 5-state DMA protocol for IO board
                 * communication.
                 *
                 * Pulse Level 5 when the handler is installed and the SCC
                 * has data to send or receive (TX buffer empty or RX available).
                 */
                if (++irq_counter >= 5) {
                    irq_counter = 0;
                    unsigned int handler = m68k_read_memory_32(0x0200002C);
                    if (handler != 0) {
                        m68k_set_irq(5);
                    }
                }
                if (irq_counter == 1) {
                    m68k_set_irq(0);
                }
            }
            } /* end if (!rom_image) — Agfa-specific interrupts */

            /* Milestone tracing: log when PC hits key addresses */
            {
                unsigned int pc = m68k_get_reg(NULL, M68K_REG_PC);
                static unsigned int last_milestone = 0;
                if (pc != last_milestone) {
                    const char *name = NULL;
                    /* Use ranges instead of exact addresses — tight loops
                     * mean we rarely land exactly on the entry point */
                    if (pc >= 0x40508 && pc < 0x40520) name = "PS init entry";
                    else if (pc >= 0x84658 && pc < 0x84670) {
                        static int st_count = 0;
                        if (++st_count <= 10)
                            fprintf(stderr, "[MILE] self-test entry #%d (cycle %llu)\n", st_count, total_cycles);
                    }
                    else if (pc >= 0x84790 && pc < 0x847A0) name = "self-test exit";
                    else if (pc >= 0x84C70 && pc < 0x84C80) {
                        name = "timer calibration";
                        /* After calibration completes, the result is stored
                         * at 0x02022310. Read and display it. */
                        static int cal_count = 0;
                        if (++cal_count == 2) {
                            /* Second hit = return from first calibration.
                             * Check what was stored. */
                            uint32_t cal = m68k_read_memory_32(0x02022310);
                            uint32_t tmr = (m68k_read_memory_8(0x04000025) << 8)
                                         | m68k_read_memory_8(0x04000024);
                            fprintf(stderr, "[CAL] Stored calibration at 0x02022310: 0x%08X (%d)\n"
                                    "[CAL] Timer reload value: 0x%04X\n", cal, cal, tmr);
                        }
                    }
                    /* PS init milestones (non-overlapping, address order) */
                    else if (pc >= 0x40528 && pc < 0x40540) name = "PS init: memset";
                    else if (pc >= 0x40560 && pc < 0x40574) name = "PS init: before FPU";
                    else if (pc >= 0x40574 && pc < 0x4057A) name = "PS init: FPU init call";
                    else if (pc >= 0x4057A && pc < 0x40580) name = "PS init: timer cal call";
                    else if (pc >= 0x40580 && pc < 0x40586) name = "PS init: FILESYSTEM call";
                    else if (pc >= 0x40586 && pc < 0x40594) {
                        name = "PS init: IRQ ENABLED (counter check)";
                        /* Periodically dump the timer counter */
                        /* Dump timer chain state after interrupts are enabled */
                        static int irq_dump_done = 0;
                        if (!irq_dump_done) {
                            irq_dump_done = 1;
                            uint32_t chain = m68k_read_memory_32(0x0202237C);
                            uint32_t counter = m68k_read_memory_32(0x02022378);
                            uint32_t cal = m68k_read_memory_32(0x02022310);
                            uint32_t handler = m68k_read_memory_32(0x02000020);
                            fprintf(stderr, "[TIMER] chain=0x%08X counter=0x%08X cal=0x%08X handler=0x%08X\n",
                                    chain, counter, cal, handler);
                            if (chain >= 0x02000000 && chain < 0x02400000) {
                                /* Dump first timer chain entry */
                                uint32_t next = m68k_read_memory_32(chain);
                                uint32_t tick = m68k_read_memory_32(chain + 8);
                                uint32_t cb = m68k_read_memory_32(chain + 12);
                                fprintf(stderr, "[TIMER] Entry: next=0x%08X ticks=%d callback=0x%08X\n",
                                        next, tick, cb);
                            }
                        }
                    }
                    else if (pc >= 0x40594 && pc < 0x4059C) name = "PS init: push args";
                    else if (pc >= 0x4059C && pc < 0x405A4) name = "PS init: SERIAL BUF INIT";
                    else if (pc >= 0x405A4 && pc < 0x405AA) name = "PS init: LAST INIT";
                    else if (pc >= 0x405A4 && pc <= 0x405AC) {
                        static int trap_dump = 0;
                        if (!trap_dump) {
                            trap_dump = 1;
                            fprintf(stderr, "[TRAP] At PC=0x%X: RAM 0x2000070=0x%08X "
                                    "0x2000014=0x%08X 0x2000080=0x%08X\n",
                                    pc,
                                    m68k_read_memory_32(0x2000070),
                                    m68k_read_memory_32(0x2000014),
                                    m68k_read_memory_32(0x2000080));
                        }
                        name = "*** NEAR ILLEGAL! ***";
                    }
                    else if (pc >= 0x4059C && pc < 0x405A4) name = "PS init: SERIAL BUF call";
                    else if (pc >= 0x405A4 && pc < 0x405AA) name = "PS init: LAST INIT call";
                    else if (pc >= 0x405AA && pc < 0x405AC) name = "*** PS ILLEGAL TRAP ***";
                    /* Subroutine targets */
                    else if (pc >= 0x812B0 && pc < 0x812C0) name = "filesystem init (0x812B4)";
                    else if (pc >= 0x81150 && pc < 0x81160) name = "unknown init (0x81156)";
                    else if (pc >= 0x410C0 && pc < 0x410D0) name = "serial buf init (0x410C8)";
                    else if (pc >= 0x8E000 && pc < 0x8E010) name = "init 0x8E000";
                    else if (pc >= 0x8E038 && pc < 0x8E042) name = "0x8E000 RETURNING";
                    else if (pc >= 0x898B0 && pc < 0x898C0) name = "FPU init (0x898B8)";
                    else if (pc >= 0x90100 && pc < 0x90110) name = "init 0x90100";
                    else if (pc >= 0x84AFC && pc < 0x84B10) name = "init_scc1_and_scsi";
                    else if (pc >= 0x85B58 && pc < 0x85B70) name = "SCSI device scan";
                    else if (pc >= 0x86020 && pc < 0x86030) name = "SCSI scan one device";
                    else if (pc >= 0x85770 && pc < 0x85790) name = "SCSI probe device";
                    else if (pc >= 0x8601A && pc < 0x86022) {
                        static int exit_count = 0;
                        if (++exit_count <= 3)
                            fprintf(stderr, "[SCSI] Timer wait EXIT (counter=%d)\n",
                                    m68k_read_memory_32(0x02022378));
                        name = "SCSI timer wait EXIT";
                    }
                    else if (pc >= 0x8600E && pc < 0x8601A) name = "SCSI timer wait";
                    else if (pc >= 0x3C2A4 && pc < 0x3C2C0) name = "printer_init";
                    else if (pc >= 0x3BC8A && pc < 0x3BCA0) name = "scc1_config";
                    else if (pc >= 0x71330 && pc < 0x71410) name = "*** PS INTERPRETER ***";
                    else if (pc >= 0x40E30 && pc < 0x40E40) name = "PS main entry";
                    else if (pc >= 0x5A550 && pc < 0x5A570) name = "bank2 PS code";
                    /* Exception handlers */
                    else if (pc >= 0x460 && pc < 0x475) name = "exception handler (0x468)";
                    else if (pc >= 0x770 && pc < 0x790) name = "FATAL handler (0x772)";
                    else if (pc >= 0x8DF50 && pc < 0x8DF70) name = "PS exec handler";
                    /* Boot points */
                    else if (pc >= 0x856 && pc < 0x870) name = "COLD/WARM BOOT";
                    else if (pc >= 0x200C && pc < 0x2020) name = "PS boot thunk";
                    if (name) {
                        fprintf(stderr, "[MILE] 0x%05X: %s\n", pc, name);
                        last_milestone = pc;
                    }
                }
            }

            /* Periodic timer counter dump (Agfa firmware only) */
            if (!rom_image) {
                static unsigned long long last_counter_dump = 0;
                if (total_cycles - last_counter_dump > 100000000) {
                    uint32_t counter = m68k_read_memory_32(0x02022378);
                    uint32_t handler = m68k_read_memory_32(0x02000020);
                    fprintf(stderr, "[CTR] counter=%d handler=0x%08X\n",
                            counter, handler);
                    last_counter_dump = total_cycles;
                }
            }

            /* Periodic status for Minix debugging */
            { static unsigned long long last_status = 0;
              extern int console_channel;
              if (total_cycles - last_status > 5000000) {
                unsigned int pc = m68k_get_reg(NULL, M68K_REG_PC);
                unsigned int sr = m68k_get_reg(NULL, M68K_REG_SR);
                /* Read TTY state from RAM: tty_table[0] at 0x0200B204 */
                unsigned int tty_base = 0x0200B304;
                int tty_ev = (int)m68k_read_memory_32(tty_base + 0);
                int tty_ic = (int)m68k_read_memory_32(tty_base + 12);
                int tty_ec = (int)m68k_read_memory_32(tty_base + 16);
                int tty_mn = (int)m68k_read_memory_32(tty_base + 28);
                int tty_il = (int)m68k_read_memory_32(tty_base + 72);
                int tty_to = (int)m68k_read_memory_32(0x0200F734);
                int rxcnt = (int)m68k_read_memory_32(0x021FFFF0);
                int rscnt = (int)m68k_read_memory_32(0x021FFFF4);
                int stored = (int)m68k_read_memory_32(0x021FFFE0);
                int storedic = (int)m68k_read_memory_32(0x021FFFE4);
                unsigned int tp_ptr = m68k_read_memory_32(0x021FFFE8);
                fprintf(stderr, "[STATUS] cyc=%llu ev=%d ic=%d ec=%d il=%d rx=%d st=%d sic=%d tp=0x%X tbl=0x%X\n",
                    total_cycles, tty_ev, tty_ic, tty_ec, tty_il, rxcnt, stored, storedic, tp_ptr, tty_base);
                /* Dump tty_table[0] offsets 0-160 to map struct layout */
                if (total_cycles < 100000000) {
                    fprintf(stderr, "[TTY-DUMP0]");
                    for (int k = 0; k < 80; k += 4)
                        fprintf(stderr, " %d:%08X", k, m68k_read_memory_32(tty_base + k));
                    fprintf(stderr, "\n[TTY-DUMP1]");
                    for (int k = 80; k < 160; k += 4)
                        fprintf(stderr, " %d:%08X", k, m68k_read_memory_32(tty_base + k));
                    fprintf(stderr, "\n");
                }
                last_status = total_cycles;
              }
            }
            if (verbose && total_cycles - last_report > 16000000) {
                unsigned int pc = m68k_get_reg(NULL, M68K_REG_PC);
                fprintf(stderr, "[%llu] PC=0x%08X", total_cycles, pc);
                if (ioboard.loaded) {
                    /* Must switch context to read IO board registers */
                    void *save = calloc(1, m68k_context_size());
                    m68k_get_context(save);
                    m68k_set_context(ioboard.cpu_ctx);
                    unsigned int io_pc = m68k_get_reg(NULL, M68K_REG_PC);
                    m68k_set_context(save);
                    free(save);
                    fprintf(stderr, " IO=0x%04X", io_pc & 0xFFFFFF);
                }
                fprintf(stderr, "\n");
                last_report = total_cycles;
            }
        }
    }

    return 0;
}

/* Detect infinite loop (panic) and dump PC history */
static unsigned int prev_pc_for_loop = 0;
static int same_pc_count = 0;

void check_stuck(void) {
    unsigned int pc = m68k_get_reg(NULL, M68K_REG_PC);
    if (pc == prev_pc_for_loop) {
        same_pc_count++;
        if (same_pc_count == 100) {
            fprintf(stderr, "\n=== STUCK at PC=0x%08X, dumping last 64 PCs ===\n", pc);
            /* Dump PC history with symbol lookup from nm */
            for (int i = 4095; i >= 0; i--) {
                int idx = (pc_hist_idx - 1 - i) & 4095;
                fprintf(stderr, "  PC[-%02d] = 0x%08X\n", i, pc_history[idx]);
            }
            fprintf(stderr, "=== END TRACE ===\n");
            _exit(1);
        }
    } else {
        prev_pc_for_loop = pc;
        same_pc_count = 0;
    }
}
