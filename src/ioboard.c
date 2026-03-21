/*
 * ioboard.c -- Agfa 9000PS IO Board (68000 @ 8MHz) emulation
 *
 * Runs the ATI v2.2 firmware in a second Musashi instance, cross-connected
 * to the main board via SCC serial FIFOs.
 *
 * Memory map (IO board, 68000):
 *   0x00000-0x0FFFF  ROM (64KB, io.bin)
 *   0x10000-0x1FFFF  RAM (stack at 0x14000, vars at 0x15000+)
 *   0x40000-0x4000F  SCC #1 (PS channel — cross-connected to main board)
 *   0x40010-0x4001F  SCC #2 (debug console)
 *   0x50000-0x5000F  SCC #3 (ATI to imagesetter)
 *   0x172E0-0x172FF  Hardware control register
 *
 * The IO board's SCC #1 at 0x40000 is wired via serial cable to the
 * main board's SCC at 0x04000000. Data written to one side's TX appears
 * in the other side's RX FIFO.
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

/* Exported so main emulator can set it during init */
ioboard_t *current_io_ptr = NULL;

/* Local alias */
#define current_io current_io_ptr

/* ================================================================== */
/* IO board SCC emulation (simplified)                                */
/* ================================================================== */

/* IO board SCC layout: standard Z8530 with register offsets +1,+3,+5,+7
 * But the IO board firmware uses direct byte access at:
 *   0x40000+0 = Ch A ctrl,  0x40000+1 = Ch A data (? — need to verify)
 * Actually from the disassembly, the IO board SCC uses sequential offsets */

static uint8_t io_scc_read(ioboard_t *io, int channel, int is_data)
{
    if (is_data) {
        /* Data register read */
        io->scc_rx_ready[channel] = 0;
        return io->scc_rx_buf[channel];
    }

    /* Control register read */
    uint8_t reg = io->scc_reg_ptr[channel];
    io->scc_reg_ptr[channel] = 0;

    switch (reg) {
    case 0: {
        uint8_t rr0 = 0x04;  /* TX always ready */
        if (io->scc_rx_ready[channel])
            rr0 |= 0x01;  /* RX available */
        /* For channel 0 (PS channel): check cross-connect FIFO */
        if (channel == 0 && io->main_to_io && io->main_to_io->count > 0) {
            /* Transfer from FIFO to RX buffer if not already buffered */
            if (!io->scc_rx_ready[0]) {
                uint8_t data;
                if (xfifo_get(io->main_to_io, &data) == 0) {
                    io->scc_rx_buf[0] = data;
                    io->scc_rx_ready[0] = 1;
                    rr0 |= 0x01;
                }
            }
        }
        rr0 |= 0x20;  /* CTS always asserted */
        return rr0;
    }
    case 1:
        return 0x01;  /* All sent, no errors */
    case 2:
        return io->scc_wr[channel][2];  /* Interrupt vector */
    default:
        return 0;
    }
}

static void io_scc_write(ioboard_t *io, int channel, int is_data, uint8_t val)
{
    if (is_data) {
        /* Data register write — TX */
        if (channel == 0 && io->io_to_main) {
            /* PS channel: send to main board via cross-connect FIFO */
            xfifo_put(io->io_to_main, val);
            extern int verbose;
            if (verbose)
                fprintf(stderr, "[IO-SCC] TX→main: 0x%02X '%c'\n", val,
                        val >= 0x20 && val < 0x7F ? val : '.');
        }
        /* Channel 1 (debug): could output to stderr for debugging */
        /* Channel 2 (ATI): ignored (no imagesetter emulation) */
        return;
    }

    /* Control register write */
    uint8_t reg = io->scc_reg_ptr[channel];
    if (reg == 0) {
        uint8_t ptr = val & 0x07;
        if (ptr != 0) io->scc_reg_ptr[channel] = ptr;
        io->scc_wr[channel][0] = val;
    } else {
        io->scc_wr[channel][reg] = val;
        io->scc_reg_ptr[channel] = 0;
    }
}

/* Decode IO board SCC address to channel and data/ctrl.
 * SCC #1 at 0x40000: offsets 0-F, even=ctrl, odd=data for each channel pair
 * SCC #2 at 0x40010: offsets 0-F
 * SCC #3 at 0x50000: offsets 0-F */
/* IO board SCC register layout (68000 odd-byte lane):
 * Base+1 = Channel B control  (0x40001)
 * Base+3 = Channel B data     (0x40003)
 * Base+5 = Channel A control  (0x40005)
 * Base+7 = Channel A data     (0x40007)
 * Bit 1 of offset selects data vs control.
 * Bit 2 of offset selects channel A vs B. */
static void decode_scc_addr(unsigned int addr, int *channel, int *is_data)
{
    int offset;
    if (addr >= 0x50000 && addr <= 0x5000F) {
        *channel = 2;  /* ATI imagesetter */
        offset = addr - 0x50000;
    } else if (addr >= 0x40010 && addr <= 0x4001F) {
        *channel = 1;  /* Debug console */
        offset = addr - 0x40010;
    } else {
        *channel = 0;  /* PS channel (cross-connected to main board) */
        offset = addr - 0x40000;
    }
    *is_data = (offset >> 1) & 1;  /* Bit 1: 0=control, 1=data */
}

/* ================================================================== */
/* Musashi memory callbacks (IO board)                                */
/* These are called when the IO board CPU is the active context.      */
/* We use a wrapper approach: save the "current CPU" indicator and    */
/* have the callbacks dispatch based on it.                           */
/* ================================================================== */

/* Since Musashi uses global callbacks, we need a way to distinguish
 * which CPU is currently executing. We use a global flag. */
extern int emu_current_cpu;  /* 0 = main, 1 = IO board */

/* IO board memory read */
uint8_t ioboard_read8(unsigned int addr)
{
    ioboard_t *io = current_io;
    if (!io) return 0;

    /* ROM: 0x00000-0x0FFFF */
    if (addr < 0x10000)
        return io->rom[addr];

    /* RAM: 0x10000-0x1FFFF (and extended up to 0x1FFFF) */
    if (addr >= 0x10000 && addr < 0x20000)
        return io->ram[addr - 0x10000];

    /* SCC #1 at 0x40000 */
    if (addr >= 0x40000 && addr <= 0x4000F) {
        int ch, is_data;
        decode_scc_addr(addr, &ch, &is_data);
        return io_scc_read(io, ch, is_data);
    }

    /* SCC #2 at 0x40010 */
    if (addr >= 0x40010 && addr <= 0x4001F) {
        int ch, is_data;
        decode_scc_addr(addr, &ch, &is_data);
        return io_scc_read(io, ch, is_data);
    }

    /* SCC #3 at 0x50000 */
    if (addr >= 0x50000 && addr <= 0x5000F) {
        int ch, is_data;
        decode_scc_addr(addr, &ch, &is_data);
        return io_scc_read(io, ch, is_data);
    }

    /* Hardware control at 0x172E0 */
    if (addr >= 0x172E0 && addr <= 0x172FF)
        return io->hw_regs[addr - 0x172E0];

    /* Extended RAM (0x15000-0x1FFFF is within the 0x10000-0x1FFFF range) */

    return 0;
}

void ioboard_write8(unsigned int addr, uint8_t val)
{
    ioboard_t *io = current_io;
    if (!io) return;

    /* RAM */
    if (addr >= 0x10000 && addr < 0x20000) {
        io->ram[addr - 0x10000] = val;
        return;
    }

    /* SCC #1 */
    if (addr >= 0x40000 && addr <= 0x4000F) {
        int ch, is_data;
        decode_scc_addr(addr, &ch, &is_data);
        io_scc_write(io, ch, is_data, val);
        return;
    }

    /* SCC #2 */
    if (addr >= 0x40010 && addr <= 0x4001F) {
        int ch, is_data;
        decode_scc_addr(addr, &ch, &is_data);
        io_scc_write(io, ch, is_data, val);
        return;
    }

    /* SCC #3 */
    if (addr >= 0x50000 && addr <= 0x5000F) {
        int ch, is_data;
        decode_scc_addr(addr, &ch, &is_data);
        io_scc_write(io, ch, is_data, val);
        return;
    }

    /* Hardware control */
    if (addr >= 0x172E0 && addr <= 0x172FF) {
        io->hw_regs[addr - 0x172E0] = val;
        return;
    }

    /* Ignore ROM writes and unmapped */
}

/* ================================================================== */
/* Public API                                                         */
/* ================================================================== */

void ioboard_init(ioboard_t *io, xfifo_t *main_to_io, xfifo_t *io_to_main)
{
    memset(io, 0, sizeof(*io));
    io->main_to_io = main_to_io;
    io->io_to_main = io_to_main;

    /* Allocate CPU context storage */
    io->cpu_ctx_size = m68k_context_size();
    io->cpu_ctx = calloc(1, io->cpu_ctx_size);
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
    /* Save current (main) CPU context */
    void *main_ctx = calloc(1, m68k_context_size());
    m68k_get_context(main_ctx);

    /* Configure as 68000 and reset — this sets up the IO board's
     * initial state including the correct cycle tables for 68000 */
    m68k_set_cpu_type(M68K_CPU_TYPE_68000);

    /* Set the memory callbacks to IO board mode temporarily */
    extern int emu_current_cpu;
    current_io = io;
    emu_current_cpu = 1;

    m68k_pulse_reset();

    /* Run a few cycles to let the 68000 fetch its vectors */
    /* (pulse_reset loads SSP and PC from the vector table) */

    /* Save IO board initial context (with 68000 type and cycle tables) */
    m68k_get_context(io->cpu_ctx);

    fprintf(stderr, "[IO] CPU reset: SSP=0x%08X PC=0x%08X\n",
            (io->rom[0] << 24) | (io->rom[1] << 16) | (io->rom[2] << 8) | io->rom[3],
            (io->rom[4] << 24) | (io->rom[5] << 16) | (io->rom[6] << 8) | io->rom[7]);

    /* Restore main CPU context */
    current_io = NULL;
    emu_current_cpu = 0;
    m68k_set_context(main_ctx);
    /* Don't call set_cpu_type here — set_context already restored the 68020 type */
    free(main_ctx);
}

void ioboard_run(ioboard_t *io, int cycles)
{
    if (!io->loaded) return;

    extern int emu_current_cpu;

    /* Save main CPU context */
    void *main_ctx = calloc(1, m68k_context_size());
    m68k_get_context(main_ctx);

    /* Switch to IO board context (already contains 68000 type from init) */
    m68k_set_context(io->cpu_ctx);
    current_io_ptr = io;
    emu_current_cpu = 1;

    /* Check for incoming data from main board */
    if (io->main_to_io && io->main_to_io->count > 0) {
        if (!io->scc_rx_ready[0]) {
            uint8_t data;
            if (xfifo_get(io->main_to_io, &data) == 0) {
                io->scc_rx_buf[0] = data;
                io->scc_rx_ready[0] = 1;
            }
        }
    }

    m68k_execute(cycles);

    /* Save IO board context */
    m68k_get_context(io->cpu_ctx);

    /* Restore main CPU context */
    m68k_set_context(main_ctx);
    emu_current_cpu = 0;
    current_io_ptr = NULL;
    free(main_ctx);
}
