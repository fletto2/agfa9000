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

/* Check host stdin for input → feed to SCC RX */
static void check_host_input(void)
{
    unsigned char c;
    if (read(0, &c, 1) == 1) {
        /* Feed to both channels */
        scc_rx_char(&scc, SCC_CH_A, c);
        scc_rx_char(&scc, SCC_CH_B, c);
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

unsigned int m68k_read_memory_8(unsigned int addr)
{
    /* IO board CPU active? */
    if (emu_current_cpu == 1)
        return ioboard_read8(addr);

    /* ROM */
    if (addr < ROM_TOTAL)
        return rom[addr];

    /* RAM */
    if (addr >= 0x02000000 && addr < 0x02000000 + ram_size)
        return apply_stuck_byte(addr, ram[addr - 0x02000000]);

    /* SCC #1 at 0x04000000 (register-per-address PAL decode) */
    if (addr >= 0x04000000 && addr <= 0x0400002F) {
        int offset = addr & 0x3F;
        int reg = offset & 0x0F;
        int ch = (offset & 0x20) ? 0 : 1;  /* A5: 0=ChB, 0x20=ChA */
        /* RR0 and RR2: inject cross-connect status.
         * The firmware polls multiple PAL offsets for status:
         * offset 0x00 and 0x02 are both used as status registers.
         * offset 0x02 is polled at 0x84C2E (btst #0, A1@(2)).
         * The PAL likely maps both to RR0-equivalent status. */
        if (reg == 0 || reg == 2) {
            uint8_t rr0 = 0x04;  /* TX always ready */
            if (fifo_io_to_main.count > 0)
                rr0 |= 0x01;  /* RX available from IO board */
            rr0 |= 0x20;      /* CTS asserted (IO board present) */
            /* When offset 0x02 is re-polled (Channel B status) AND
             * we're writing 3 first (the firmware does write-then-poll),
             * this is the start of a new byte read cycle.
             * Consume the previous byte from the FIFO. */
            return rr0;
        }
        /* PAL offset 0x0D: the SCC #1 interrupt handler at 0x84A48 reads
         * this for TX/RX status. Bit 0 = TX buffer empty, bit 1 = RX ready.
         * This is the status register used by the DMA protocol handler. */
        if (reg == 0x0D) {
            uint8_t status = 0;
            status |= 0x01;  /* Bit 0: TX buffer empty (always ready) */
            if (fifo_io_to_main.count > 0)
                status |= 0x02;  /* Bit 1: RX data available */
            return status;
        }
        /* PAL offset 0x0F: reads return status with bit 2 = 0 (ready).
         * The firmware polls this at 0x3BC68 during SCC init. */
        if (reg == 0x0F) {
            return 0x01;  /* No pending status changes */
        }
        /* Offsets 0x04/0x05 and 0x24/0x25: Z8536 CIO timer counter.
         * NOT SCC registers — a separate counter/timer chip decoded through
         * the same PAL address space as SCC #1.
         * The firmware writes 0xFFFF to load, then reads back elapsed count.
         * Timer counts down from loaded value. We return a value that
         * produces the correct calibration result:
         *   delta = 0xFFFE → calibrated = (0xFFFE * 3686 - 32768) >> 16 ≈ 3685
         */
        if (reg == 4 || reg == 5) {
            static uint16_t timer_ctr = 0xFFFF;
            static int timer_reads = 0;
            timer_reads++;
            /* First pair of reads: return high value (0xFFFF) */
            /* Second pair (after BRG zero): return low value (0x0001) */
            /* The delta = 0xFFFF - 0x0001 = 0xFFFE */
            uint16_t val16;
            if (timer_reads <= 4)
                val16 = 0xFFFF;  /* First read pair */
            else
                val16 = 0x0001;  /* Second read pair */
            if (timer_reads >= 8) timer_reads = 0;  /* Reset for next calibration */
            if (reg == 5)
                return (val16 >> 8) & 0xFF;
            else
                return val16 & 0xFF;
        }
        if (reg == 8) {
            if (fifo_io_to_main.count > 0) {
                uint8_t data;
                xfifo_get(&fifo_io_to_main, &data);
                if (verbose)
                    fprintf(stderr, "[SCC1] RX: 0x%02X '%c'\n", data,
                            data >= 0x20 && data < 0x7F ? data : '.');
                return data;
            }
            return 0;
        }
        return scc_pal_read(&scc, offset);
    }

    /* SCSI at 0x05000001 (odd byte lane) */
    if (addr >= 0x05000001 && addr <= 0x0500000F && (addr & 1))
        return ncr5380_read(&scsi, (addr - 0x05000001) >> 1);

    /* SCSI pseudo-DMA */
    if (addr == 0x05000026)
        return ncr5380_dma_read(&scsi);

    /* Bus control latch */
    if (addr == 0x06000000) return bus_ctl_latch;
    if (addr == 0x06080000) return gfx_ctl_latch;
    if (addr == 0x060C0000) return fifo_ctl >> 8;
    if (addr == 0x060C0001) return fifo_ctl & 0xFF;
    if (addr >= 0x06100000 && addr <= 0x06100003)
        return (display_ctl >> (8 * (3 - (addr & 3)))) & 0xFF;

    /* SCC #2 at 0x07000000 (compact byte-addressed) */
    if (addr >= 0x07000000 && addr <= 0x07000003)
        return scc_compact_read(&scc, addr & 3);

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
    if (addr >= 0x04000000 && addr <= 0x0400002F) {
        int offset = addr & 0x3F;
        int reg = offset & 0x0F;
        /* Trace all writes in verbose mode */
        if (verbose) {
            static int scc1_write_count = 0;
            if (scc1_write_count < 200) {
                fprintf(stderr, "[SCC1-W] off=0x%02X val=0x%02X '%c'\n",
                        offset, val, val >= 0x20 && val < 0x7F ? val : '.');
                scc1_write_count++;
            }
        }
        /* Intercept data register writes: send to IO board FIFO.
         * Check multiple potential data register offsets. */
        if (reg == 8 || reg == 3) {
            xfifo_put(&fifo_main_to_io, val);
        }
        scc_pal_write(&scc, offset, val);
        return;
    }
    if (addr >= 0x05000001 && addr <= 0x0500000F && (addr & 1)) {
        ncr5380_write(&scsi, (addr - 0x05000001) >> 1, val);
        return;
    }
    if (addr == 0x05000026) { ncr5380_dma_write(&scsi, val); return; }
    if (addr == 0x06000000) { bus_ctl_latch = val; return; }
    if (addr == 0x06080000) { gfx_ctl_latch = val; return; }
    if (addr == 0x060C0000) { fifo_ctl = val << 8; return; }
    if (addr == 0x060C0001) { fifo_ctl = (fifo_ctl & 0xFF00) | val; return; }
    if (addr >= 0x06100000 && addr <= 0x06100003) {
        int shift = 8 * (3 - (addr & 3));
        display_ctl = (display_ctl & ~(0xFF << shift)) | (val << shift);
        return;
    }
    if (addr >= 0x07000000 && addr <= 0x07000003) {
        scc_compact_write(&scc, addr & 3, val);
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
    fprintf(stderr, "  -io <io.bin>      Load IO board ROM (68000, enables dual-CPU)\n");
    fprintf(stderr, "  -v                Verbose logging\n");
    fprintf(stderr, "\nExample: %s roms/ -stuck 16 -hd HD00_Agfa_RIP.hda -io roms/io.bin\n", prog);
    exit(1);
}

int main(int argc, char **argv)
{
    const char *rom_dir = NULL;
    const char *hd_image = NULL;
    const char *io_rom = NULL;
    int hd_block_size = 512;
    int stuck_bit = -1;
    int stuck_high = 0;
    int i;

    for (i = 1; i < argc; i++) {
        if (argv[i][0] != '-') {
            rom_dir = argv[i];
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
        } else if (!strcmp(argv[i], "-v")) {
            verbose = 1;
        } else {
            usage(argv[0]);
        }
    }
    if (!rom_dir) usage(argv[0]);

    /* Fault injection */
    if (stuck_bit >= 0 && stuck_bit < 32) {
        stuck_mask = 1U << stuck_bit;
        stuck_value = stuck_high ? 1 : 0;
        fprintf(stderr, "Fault: D%d stuck %s at 0x%08X-0x%08X\n",
                stuck_bit, stuck_high ? "HIGH" : "LOW",
                stuck_addr_start, stuck_addr_end);
    }

    /* Init peripherals */
    scc_init(&scc);
    scc_set_tx_callback(&scc, SCC_CH_A, scc_tx_handler, NULL);
    scc_set_tx_callback(&scc, SCC_CH_B, scc_tx_handler, NULL);
    /* CTS on Channel B: deasserted by default (auto-boots to PostScript,
     * matching Adrian's hardware). Use -cts to assert it and get the
     * Atlas Monitor prompt instead. */
    scc_set_cts(&scc, SCC_CH_B, 0);

    ncr5380_init(&scsi);

    /* Init cross-connect FIFOs for IO board communication */
    xfifo_init(&fifo_main_to_io);
    xfifo_init(&fifo_io_to_main);

    /* Load ROMs */
    fprintf(stderr, "Agfa 9000PS Emulator\n");
    fprintf(stderr, "RAM: %d MB\n", ram_size / (1024 * 1024));
    if (load_all_roms(rom_dir) < 0) return 1;

    /* Mount HD image */
    if (hd_image) {
        if (ncr5380_attach_image(&scsi, 0, hd_image, hd_block_size) < 0)
            return 1;
    }

    /* Patch self-test to return immediately (D0=0 = pass).
     * The self-test at 0x84658 fills/verifies all of RAM which takes
     * forever at emulated speed. Patch entry: moveq #0,d0; rts */
    /* Init both CPUs using the Plexus dual-CPU pattern:
     * allocate context, set_context, set_cpu_type, m68k_init, pulse_reset, get_context */

    void *main_ctx = calloc(1, m68k_context_size());
    void *io_ctx = NULL;

    /* Main CPU: 68020 */
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
            /* Run main CPU */
            emu_current_cpu = 0;
            int cycles = m68k_execute(160000);
            total_cycles += cycles;

            /* Run IO board CPU (68000 @ 8MHz = 80K cycles per 10ms) */
            if (ioboard.loaded) {
                ioboard_run(&ioboard, 80000);
            }

            /* (Handshake injection removed — 0x84C2E is timer calibration,
             * not IO board handshake. The BRG zero-count simulation in
             * scc.c now handles this correctly.) */

            check_host_input();
            scc_tick(&scc);
            ncr5380_tick(&scsi);

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
                    static int timer_irq_ctr = 0;
                    if (++timer_irq_ctr >= 3) {
                        timer_irq_ctr = 0;
                        unsigned int handler = m68k_read_memory_32(0x02000020);
                        if (handler != 0) {
                            m68k_set_irq(2);
                        }
                    }
                    if (timer_irq_ctr == 1)
                        m68k_set_irq(0);  /* Clear after one slice */
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
                    else if (pc >= 0x84C70 && pc < 0x84C80) name = "timer calibration";
                    else if (pc >= 0x84AFC && pc < 0x84B10) name = "init_scc1_and_scsi";
                    else if (pc >= 0x85B58 && pc < 0x85B70) name = "SCSI device scan";
                    else if (pc >= 0x3C2A4 && pc < 0x3C2C0) name = "printer_init";
                    else if (pc >= 0x3BC8A && pc < 0x3BCA0) name = "scc1_config";
                    else if (pc >= 0x71330 && pc < 0x71410) name = "PS interpreter!";
                    else if (pc >= 0x40E30 && pc < 0x40E40) name = "PS main entry!";
                    else if (pc >= 0x5A550 && pc < 0x5A570) name = "bank2 PS code";
                    if (name) {
                        fprintf(stderr, "[MILE] 0x%05X: %s\n", pc, name);
                        last_milestone = pc;
                    }
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
