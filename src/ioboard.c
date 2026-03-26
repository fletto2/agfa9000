/*
 * ioboard.c -- Agfa 9000PS IO Board (68000 @ 8MHz) emulation
 *
 * Hardware map (from github.com/misterblack1/agfa_ebs_pnafati):
 *   0x000000-0x00FFFF  ROM (64KB)
 *   0x010000-0x01FFFF  SRAM (16KB physical, 4x mirrored in 64KB block)
 *   0x020000-0x02FFFF  MK4501N FIFO (512x9, upper byte D8-D15, even addresses)
 *   0x030000-0x03FFFF  FIFO mirror
 *   0x040000-0x04FFFF  MC68681 DUART (lower byte D0-D7, odd addresses)
 *   0x050000-0x07FFFF  Unpopulated (no DTACK on real hardware)
 *
 * Inter-board communication goes through the MK4501N FIFO at 0x020000.
 * The main board's DMA protocol at 0x04000000 sends data over the ribbon
 * cable into this FIFO. The IO board firmware reads it.
 *
 * The DUART handles: serial console (Port A, 9600 8N1), auxiliary serial
 * (Port B, 1200 baud), front panel (LEDs via OPR, buttons/dial via IP),
 * and FIFO handshaking (IP5=FIFO status, OP6=FIFO control).
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "musashi/m68k.h"
#include "ioboard.h"

/* ================================================================== */
/* Cross-connect FIFO                                                 */
/* ================================================================== */

void xfifo_init(xfifo_t *f)
{
    memset(f, 0, sizeof(*f));
}

int xfifo_put(xfifo_t *f, uint8_t data)
{
    if (f->count >= XFIFO_SIZE) return -1;
    f->buf[f->wr] = data;
    f->wr = (f->wr + 1) % XFIFO_SIZE;
    f->count++;
    return 0;
}

int xfifo_get(xfifo_t *f, uint8_t *data)
{
    if (f->count <= 0) return -1;
    *data = f->buf[f->rd];
    f->rd = (f->rd + 1) % XFIFO_SIZE;
    f->count--;
    return 0;
}

int xfifo_empty(xfifo_t *f)
{
    return f->count == 0;
}

/* ================================================================== */
/* Global IO board state (accessed by Musashi callbacks)              */
/* ================================================================== */

ioboard_t *current_io_ptr = NULL;
#define current_io current_io_ptr

/* ================================================================== */
/* MC68681 DUART emulation                                            */
/* ================================================================== */

static uint8_t duart_read(ioboard_t *io, int reg)
{
    mc68681_t *d = &io->duart;
    switch (reg) {
    case DUART_MRA:
        /* Auto-increment: reads MR1A then MR2A alternately */
        if (d->mr_ptr_a == 0) { d->mr_ptr_a = 1; return d->mr1a; }
        else { d->mr_ptr_a = 0; return d->mr2a; }
    case DUART_SRA: {
        /* Status Register A: bit 0=RXRDY, bit 2=TXRDY, bit 3=TXEMT */
        uint8_t sra = 0x0C;  /* TX ready + TX empty */
        /* Check if main board sent data (via VIA → SCC2691 → DUART RX).
         * Use main_to_io FIFO for the serial ATI command path. */
        if (io->main_to_io && io->main_to_io->count > 0)
            sra |= 0x01;  /* RXRDY: data available from main board */
        {
            extern int verbose;
            static int sra_trace = 0;
            if (verbose && sra_trace < 20) {
                fprintf(stderr, "[IO-DUART] SRA read: 0x%02X serial_fifo=%d\n",
                        sra, io->main_to_io ? io->main_to_io->count : -1);
                sra_trace++;
            }
        }
        return sra;
    }
    case DUART_THRA: {
        /* RX Holding Register A: read data from main board serial path */
        uint8_t data = 0;
        if (io->main_to_io && io->main_to_io->count > 0)
            xfifo_get(io->main_to_io, &data);
        return data;
    }
    case DUART_ACR:
        return 0;  /* IPCR: no input port changes */
    case DUART_IMR:
        return 0;  /* ISR: no interrupts pending */
    case DUART_CTU:
        return d->regs[DUART_CTU];
    case DUART_CTL:
        return d->regs[DUART_CTL];
    case DUART_MRB:
        if (d->mr_ptr_b == 0) { d->mr_ptr_b = 1; return d->mr1b; }
        else { d->mr_ptr_b = 0; return d->mr2b; }
    case DUART_SRB:
        return 0x0C;  /* TX ready + empty */
    case DUART_THRB:
        return 0;
    case DUART_IVR:
        return d->regs[DUART_IVR];
    case DUART_OPCR: {
        /* Input Port read:
         * IP0: unused (=1)
         * IP1: hardware interlock / RIP presence (0=connected, 1=disconnected)
         * IP2-4: dial (3-bit octal, active-low: 111=position 0)
         * IP5: SCC2691/DUART2 present at 0x50000 (0=present, 1=absent)
         *
         * The firmware checks IP1 to detect if the main board (RIP) is connected.
         * IP1=0 → duart_check_status returns 1 → "connected"
         * IP1=1 → duart_check_status returns 0 → "not connected"
         *
         * On Adrian's board: IP5=1 (no device at 0x50000).
         * For emulation with IO board: IP1=0 (RIP connected). */
        uint8_t ip = 0xFC;  /* 0b11111100: IP1=0 (connected), IP5=1 (no 0x50000),
                             * IP2-4=111 (dial=0), IP0=0 */
        return ip;
    }
    case DUART_SET_OPR:
        return 0;  /* Start counter read — return 0 */
    case DUART_RST_OPR:
        return 0;  /* Stop counter read — return 0 */
    default:
        return d->regs[reg];
    }
}

static void duart_write(ioboard_t *io, int reg, uint8_t val)
{
    mc68681_t *d = &io->duart;
    switch (reg) {
    case DUART_MRA:
        if (d->mr_ptr_a == 0) { d->mr1a = val; d->mr_ptr_a = 1; }
        else { d->mr2a = val; d->mr_ptr_a = 0; }
        break;
    case DUART_SRA:
        d->regs[DUART_SRA] = val;  /* CSRA: baud rate select */
        break;
    case DUART_CRA: {
        /* Command Register A */
        int cmd = (val >> 4) & 0x07;
        if (cmd == 1) d->mr_ptr_a = 0;  /* Reset MR pointer */
        /* Commands 2-7: reset Rx/Tx/error/break — no-op in emulator */
        /* Bits 3-2: Tx enable/disable; bits 1-0: Rx enable/disable */
        d->regs[DUART_CRA] = val;
        break;
    }
    case DUART_THRA:
        /* TX Holding A — send to main board via SCC2691 → ribbon → VIA */
        d->regs[DUART_THRA] = val;
        if (io->io_to_main)
            xfifo_put(io->io_to_main, val);
        {
            static int tx_trace = 0;
            if (tx_trace < 20) {
                fprintf(stderr, "[IO-TX] byte=0x%02X '%c' fifo=%d\n",
                        val, val >= 0x20 && val < 0x7F ? val : '.',
                        io->io_to_main ? io->io_to_main->count : -1);
                tx_trace++;
            }
        }
        break;
    case DUART_ACR:
        d->regs[DUART_ACR] = val;
        break;
    case DUART_IMR:
        d->regs[DUART_IMR] = val;
        break;
    case DUART_MRB:
        if (d->mr_ptr_b == 0) { d->mr1b = val; d->mr_ptr_b = 1; }
        else { d->mr2b = val; d->mr_ptr_b = 0; }
        break;
    case DUART_SRB:
        d->regs[DUART_SRB] = val;  /* CSRB */
        break;
    case DUART_CRB: {
        int cmd = (val >> 4) & 0x07;
        if (cmd == 1) d->mr_ptr_b = 0;
        d->regs[DUART_CRB] = val;
        break;
    }
    case DUART_THRB:
        d->regs[DUART_THRB] = val;
        break;
    case DUART_OPCR:
        d->regs[DUART_OPCR] = val;  /* Output port configuration */
        break;
    case DUART_SET_OPR:
        d->opr |= val;  /* Set output port bits */
        break;
    case DUART_RST_OPR:
        d->opr &= ~val;  /* Clear output port bits */
        break;
    default:
        d->regs[reg] = val;
        break;
    }
}

/* ================================================================== */
/* MK4501N FIFO emulation (at 0x020000-0x02FFFF)                     */
/* ================================================================== */
/* The MK4501N is a 512×9 hardware FIFO for bulk raster data.
 * It is a SEPARATE data path from the DUART serial (ATI protocol).
 * The FIFO is on the upper byte lane (D8-D15), so it responds to
 * EVEN addresses. Any address in the 0x020000-0x02FFFF range accesses
 * the same FIFO data port. The 9th bit connects to DUART I/O pins.
 *
 * In the emulator, we use a separate internal FIFO for this device
 * to avoid draining the ATI serial data path. */
static xfifo_t mk4501_fifo;  /* Internal MK4501N FIFO (separate from serial) */

static uint8_t fifo_read(ioboard_t *io)
{
    uint8_t data = 0;
    (void)io;
    xfifo_get(&mk4501_fifo, &data);
    return data;
}

static void fifo_write(ioboard_t *io, uint8_t val)
{
    (void)io;
    xfifo_put(&mk4501_fifo, val);
}

/* ================================================================== */
/* Musashi memory callbacks (IO board)                                */
/* ================================================================== */

extern int emu_current_cpu;  /* 0 = main, 1 = IO board */

uint8_t ioboard_read8(unsigned int addr)
{
    ioboard_t *io = current_io;
    if (!io) return 0;

    /* Mask to 512KB (A16-A18 decoded, A19+ ignored) */
    addr &= 0x7FFFF;

    /* ROM: Block 0 (0x00000-0x0FFFF) */
    if (addr < 0x10000)
        return io->rom[addr];

    /* RAM: Block 1 (0x10000-0x1FFFF), 16KB physical mirrored 4x */
    if (addr >= 0x10000 && addr < 0x20000)
        return io->ram[(addr - 0x10000) & 0x3FFF];

    /* MK4501N FIFO: Block 2 (0x20000-0x2FFFF) + Block 3 mirror (0x30000-0x3FFFF)
     * FIFO is on upper byte lane (even addresses only) */
    if (addr >= 0x20000 && addr < 0x40000) {
        if (!(addr & 1))  /* Even address = upper byte = FIFO */
            return fifo_read(io);
        return 0xFF;  /* Odd address: no device on lower byte at FIFO block */
    }

    /* MC68681 DUART: Block 4 (0x40000-0x4FFFF)
     * DUART is on lower byte lane (odd addresses only) */
    if (addr >= 0x40000 && addr < 0x50000) {
        if (addr & 1) {  /* Odd address = lower byte = DUART */
            int reg = (addr - 0x40000) >> 1;
            if (reg < DUART_NUM_REGS) {
                uint8_t val = duart_read(io, reg);
                {
                    static int duart_rd_trace = 0;
                    if (duart_rd_trace < 200) {
                        extern int verbose;
                        fprintf(stderr, "[IO-DUART-RD] addr=0x%05X reg=%d val=0x%02X fifo=%d\n",
                                addr, reg, val, io->fifo_in ? io->fifo_in->count : -1);
                        duart_rd_trace++;
                    }
                }
                return val;
            }
        }
        return 0xFF;
    }

    /* Blocks 5-7 (0x50000-0x7FFFF): Unpopulated — no DTACK on real hardware.
     * In emulation, just return 0xFF to avoid hanging. The firmware checks
     * DUART IP5 before accessing 0x50000 and skips if not present. */
    return 0xFF;
}

void ioboard_write8(unsigned int addr, uint8_t val)
{
    ioboard_t *io = current_io;
    if (!io) return;

    addr &= 0x7FFFF;

    /* RAM: Block 1 */
    if (addr >= 0x10000 && addr < 0x20000) {
        io->ram[(addr - 0x10000) & 0x3FFF] = val;
        return;
    }

    /* MK4501N FIFO: Block 2+3 (even addresses = upper byte) */
    if (addr >= 0x20000 && addr < 0x40000) {
        if (!(addr & 1))
            fifo_write(io, val);
        return;
    }

    /* MC68681 DUART: Block 4 (odd addresses = lower byte) */
    if (addr >= 0x40000 && addr < 0x50000) {
        if (addr & 1) {
            int reg = (addr - 0x40000) >> 1;
            if (reg < DUART_NUM_REGS)
                duart_write(io, reg, val);
        }
        return;
    }

    /* Blocks 5-7: writes to unpopulated space — ignore */
    /* ROM: writes ignored */
}

/* ================================================================== */
/* Public API                                                         */
/* ================================================================== */

void ioboard_init(ioboard_t *io, xfifo_t *main_to_io, xfifo_t *io_to_main)
{
    memset(io, 0, sizeof(*io));
    io->main_to_io = main_to_io;
    io->io_to_main = io_to_main;
    io->fifo_in = main_to_io;   /* MK4501N FIFO input = data from main board */
    io->fifo_out = io_to_main;  /* MK4501N FIFO output = data to main board */

    /* Allocate CPU context storage */
    io->cpu_ctx_size = m68k_context_size();
    io->cpu_ctx = calloc(1, io->cpu_ctx_size);

    /* Pre-load IO board boot response into the return FIFO.
     * On real hardware, the IO board boots faster than the main board
     * and sends "0001+" (ATI ready acknowledgment) before the main board
     * reaches its SCC2691 polling loop. In the emulator, both boards
     * start simultaneously, so we pre-load the response to avoid deadlock. */
    if (io_to_main) {
        const char *boot_resp = "0001+";
        for (int i = 0; boot_resp[i]; i++)
            xfifo_put(io_to_main, boot_resp[i]);
        fprintf(stderr, "[IO] Pre-loaded boot response: \"%s\" (%d bytes)\n",
                boot_resp, (int)strlen(boot_resp));
    }
}

int ioboard_load_rom(ioboard_t *io, const char *path)
{
    FILE *f = fopen(path, "rb");
    if (!f) {
        fprintf(stderr, "[IO] Cannot open ROM: %s\n", path);
        return -1;
    }
    size_t n = fread(io->rom, 1, sizeof(io->rom), f);
    fclose(f);
    fprintf(stderr, "[IO] Loaded %s (%zu bytes)\n", path, n);
    io->loaded = 1;
    return 0;
}

void ioboard_reset(ioboard_t *io)
{
    void *main_ctx = calloc(1, m68k_context_size());
    m68k_get_context(main_ctx);

    m68k_set_cpu_type(M68K_CPU_TYPE_68000);

    extern int emu_current_cpu;
    current_io = io;
    emu_current_cpu = 1;

    m68k_pulse_reset();
    m68k_get_context(io->cpu_ctx);

    fprintf(stderr, "[IO] CPU reset: SSP=0x%08X PC=0x%08X\n",
            (io->rom[0] << 24) | (io->rom[1] << 16) | (io->rom[2] << 8) | io->rom[3],
            (io->rom[4] << 24) | (io->rom[5] << 16) | (io->rom[6] << 8) | io->rom[7]);

    current_io = NULL;
    emu_current_cpu = 0;
    m68k_set_context(main_ctx);
    free(main_ctx);
}

void ioboard_run(ioboard_t *io, int cycles)
{
    if (!io->loaded) return;

    extern int emu_current_cpu;

    void *main_ctx = calloc(1, m68k_context_size());
    m68k_get_context(main_ctx);

    m68k_set_context(io->cpu_ctx);
    current_io_ptr = io;
    emu_current_cpu = 1;

    m68k_execute(cycles);

    /* Debug: trace IO board PC progression */
    {
        static int run_trace = 0;
        if (run_trace < 50) {
            unsigned int pc = m68k_get_reg(NULL, M68K_REG_PC);
            unsigned int sp = m68k_get_reg(NULL, M68K_REG_A7);
            fprintf(stderr, "[IO-RUN] PC=0x%08X SP=0x%08X cycles=%d\n", pc, sp, cycles);
            run_trace++;
        }
    }

    m68k_get_context(io->cpu_ctx);

    m68k_set_context(main_ctx);
    emu_current_cpu = 0;
    current_io_ptr = NULL;
    free(main_ctx);
}
