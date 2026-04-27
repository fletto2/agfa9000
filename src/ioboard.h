/*
 * ioboard.h -- Agfa 9000PS IO Board (68000) emulation
 *
 * Hardware (from Adrian's reverse engineering at github.com/misterblack1/agfa_ebs_pnafati):
 *   Block 0: 0x000000-0x00FFFF  ROM (64KB EPROM)
 *   Block 1: 0x010000-0x01FFFF  SRAM (16KB physical, 4x mirrored)
 *   Block 2: 0x020000-0x02FFFF  MK4501N FIFO (512x9, upper byte lane D8-D15)
 *   Block 3: 0x030000-0x03FFFF  FIFO mirror
 *   Block 4: 0x040000-0x04FFFF  MC68681 DUART (lower byte lane D0-D7, odd addresses)
 *   Block 5-7: 0x050000-0x07FFFF  UNPOPULATED (no DTACK!)
 *
 * Address decode: A16-A18 to 3-to-8 decoder. A19-A23 ignored (512KB repeats).
 *
 * Inter-board communication: Main board writes data through its PAL-decoded
 * DMA protocol at 0x04000000 -> ribbon cable -> MK4501N FIFO at 0x020000.
 * IO board firmware reads the FIFO to receive commands/data.
 *
 * MC68681 DUART: Port A (9600 8N1) = ATI serial via SCC2691.
 * Port B (1200 baud) = auxiliary. I/O port: IP1=RIP presence, IP2-4=dial,
 * IP5=FIFO/DUART2 presence. OP5=amber LED, OP7=red LED, OP6=FIFO control.
 *
 * The firmware checks IP5 for a second device at 0x50000 (could be
 * optional DUART2 or SCC). On Adrian's board, nothing is there.
 */
#ifndef IOBOARD_H
#define IOBOARD_H

#include <stdint.h>

/* Cross-connect FIFO for inter-board communication */
#define XFIFO_SIZE 512  /* MK4501N has 512 entries */

typedef struct xfifo {
    uint8_t buf[XFIFO_SIZE];
    int rd, wr, count;
} xfifo_t;

/* MC68681 DUART register indices (16 registers, odd byte offsets) */
#define DUART_MRA     0   /* +0x01: Mode Register A (auto-increment MR1A/MR2A) */
#define DUART_SRA     1   /* +0x03: Status Register A (read) / Clock Select A (write) */
#define DUART_CRA     2   /* +0x05: Command Register A (write only) */
#define DUART_THRA    3   /* +0x07: TX Holding A (write) / RX Holding A (read) */
#define DUART_ACR     4   /* +0x09: Aux Control (write) / Input Port Change (read) */
#define DUART_IMR     5   /* +0x0B: Interrupt Mask (write) / Interrupt Status (read) */
#define DUART_CTU     6   /* +0x0D: Counter/Timer Upper */
#define DUART_CTL     7   /* +0x0F: Counter/Timer Lower */
#define DUART_MRB     8   /* +0x11: Mode Register B */
#define DUART_SRB     9   /* +0x13: Status Register B (read) / Clock Select B (write) */
#define DUART_CRB     10  /* +0x15: Command Register B (write only) */
#define DUART_THRB    11  /* +0x17: TX Holding B (write) / RX Holding B (read) */
#define DUART_IVR     12  /* +0x19: Interrupt Vector Register */
#define DUART_OPCR    13  /* +0x1B: Input Port (read) / Output Port Config (write) */
#define DUART_SET_OPR 14  /* +0x1D: Start Counter (read) / Set Output Port (write) */
#define DUART_RST_OPR 15  /* +0x1F: Stop Counter (read) / Reset Output Port (write) */
#define DUART_NUM_REGS 16

typedef struct mc68681 {
    uint8_t regs[DUART_NUM_REGS];
    uint8_t opr;        /* Output Port Register (actual state) */
    uint8_t mr_ptr_a;   /* MR pointer for channel A (0=MR1, 1=MR2) */
    uint8_t mr_ptr_b;   /* MR pointer for channel B */
    uint8_t mr1a, mr2a; /* Mode registers A */
    uint8_t mr1b, mr2b; /* Mode registers B */
} mc68681_t;

typedef struct ioboard {
    /* ROM and RAM */
    uint8_t rom[64 * 1024];      /* 64KB ROM */
    uint8_t ram[64 * 1024];      /* 64KB RAM (16KB physical, 4x mirrored) */

    /* CPU context (saved/restored when switching CPUs) */
    void *cpu_ctx;
    int cpu_ctx_size;

    /* MC68681 DUART at 0x40000 */
    mc68681_t duart;

    /* MK4501N FIFO at 0x20000 (inter-board data buffer) */
    xfifo_t *fifo_in;     /* Data FROM main board (main writes, IO reads) */
    xfifo_t *fifo_out;    /* Data TO main board (IO writes, main reads) */

    /* Cross-connect FIFOs (legacy names, point to same as fifo_in/fifo_out) */
    xfifo_t *main_to_io;
    xfifo_t *io_to_main;

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
