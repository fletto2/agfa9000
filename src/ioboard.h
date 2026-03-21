/*
 * ioboard.h -- Agfa 9000PS IO Board (68000) emulation
 *
 * The IO board runs a Motorola 68000 @ 8MHz with:
 *   - 64KB ROM at 0x00000-0x0FFFF
 *   - RAM at 0x10000-0x1FFFF (stack at 0x14000, vars at 0x15000+)
 *   - SCC #1 at 0x40000 (PS channel — connects to main board SCC #1)
 *   - SCC #2 at 0x40010 (debug console)
 *   - SCC #3 at 0x50000 (ATI to imagesetter)
 *   - HW control at 0x172E0
 *
 * Communication with the main board is via a cross-connected SCC serial
 * link: main board SCC (0x04000000) ←→ IO board SCC (0x40000).
 */
#ifndef IOBOARD_H
#define IOBOARD_H

#include <stdint.h>

/* Cross-connect FIFO for inter-board serial communication */
#define XFIFO_SIZE 256

typedef struct xfifo {
    uint8_t buf[XFIFO_SIZE];
    int rd, wr, count;
} xfifo_t;

typedef struct ioboard {
    /* ROM and RAM */
    uint8_t rom[64 * 1024];      /* 64KB ROM */
    uint8_t ram[128 * 1024];     /* 128KB RAM (generous) */

    /* CPU context (saved/restored when switching CPUs) */
    void *cpu_ctx;
    int cpu_ctx_size;

    /* SCC registers (simplified — 3 channels) */
    /* Channel 0 at 0x40000: PS channel (cross-connected to main board) */
    /* Channel 1 at 0x40010: debug console */
    /* Channel 2 at 0x50000: ATI to imagesetter */
    uint8_t scc_wr[3][16];
    uint8_t scc_rr[3][16];
    uint8_t scc_reg_ptr[3];
    uint8_t scc_rx_buf[3];
    int scc_rx_ready[3];

    /* Hardware control register at 0x172E0 */
    uint8_t hw_regs[32];

    /* Cross-connect FIFOs: main ↔ IO board */
    xfifo_t *main_to_io;    /* Main board TX → IO board RX */
    xfifo_t *io_to_main;    /* IO board TX → main board RX */

    /* State */
    int loaded;
} ioboard_t;

/* Initialize IO board */
void ioboard_init(ioboard_t *io, xfifo_t *main_to_io, xfifo_t *io_to_main);

/* Load IO board ROM */
int ioboard_load_rom(ioboard_t *io, const char *path);

/* Reset IO board CPU */
void ioboard_reset(ioboard_t *io);

/* Run IO board for a given number of cycles */
void ioboard_run(ioboard_t *io, int cycles);

/* FIFO operations */
void xfifo_init(xfifo_t *f);
int xfifo_put(xfifo_t *f, uint8_t data);
int xfifo_get(xfifo_t *f, uint8_t *data);
int xfifo_empty(xfifo_t *f);

#endif
