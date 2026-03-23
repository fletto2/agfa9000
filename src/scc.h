/*
 * scc.h -- Zilog Z8530 SCC emulation for Agfa 9000PS
 *
 * Emulates one physical Z8530 with two channels (A and B).
 * Supports both compact byte-addressed mode (0x07000000)
 * and register-per-address PAL decode mode (0x04000000).
 */
#ifndef SCC_H
#define SCC_H

#include <stdint.h>

/* RR0 status bits */
#define SCC_RR0_RX_AVAILABLE    0x01
#define SCC_RR0_ZERO_COUNT      0x02
#define SCC_RR0_TX_EMPTY        0x04
#define SCC_RR0_DCD             0x08
#define SCC_RR0_SYNC_HUNT       0x10
#define SCC_RR0_CTS             0x20
#define SCC_RR0_TX_UNDERRUN     0x40
#define SCC_RR0_BREAK_ABORT     0x80

/* Channel index */
#define SCC_CH_A    0
#define SCC_CH_B    1

typedef struct scc_channel {
    uint8_t wr[16];         /* Write registers WR0-WR15 */
    uint8_t rr[16];         /* Read registers RR0-RR15 */
    uint8_t reg_ptr;        /* Current register pointer (set via WR0) */

    /* RX FIFO (simplified: 3-byte like real Z8530) */
    uint8_t rx_fifo[3];
    int rx_fifo_count;
    int rx_fifo_rd;
    int rx_fifo_wr;

    /* TX state */
    int tx_pending;         /* Byte waiting to be sent */
    uint8_t tx_data;        /* Data to transmit */

    /* Status */
    int cts;                /* CTS pin state (1=asserted) */
    int dcd;                /* DCD pin state (1=asserted) */

    /* BRG (Baud Rate Generator) simulation */
    int brg_enabled;        /* WR14 bit 0 */
    int brg_zero_count_ie;  /* WR15 bit 1 */
    int brg_counter;        /* Countdown to zero (ticks) */
    int brg_reload;         /* BRG time constant for auto-reload */
    int brg_zero_fired;     /* Zero count has occurred */

    /* Interrupt pending flags */
    int ext_status_pending; /* External/status interrupt pending */
    int rx_int_pending;     /* RX interrupt pending */
    int tx_int_pending;     /* TX interrupt pending */

    /* Callback for transmitted data */
    void (*tx_callback)(int channel, uint8_t data, void *ctx);
    void *tx_ctx;
} scc_channel_t;

typedef struct scc {
    scc_channel_t ch[2];    /* ch[0]=Channel A, ch[1]=Channel B */
    int mie;                /* Master Interrupt Enable (WR9 bit 3) */
    int irq_state;          /* Current IRQ output state */
    void (*irq_callback)(int state, void *ctx);
    void *irq_ctx;
} scc_t;

/* Initialize SCC */
void scc_init(scc_t *scc);

/* Reset SCC (hardware reset) */
void scc_reset(scc_t *scc);

/* Compact access mode (0x07000000): addr bits decode channel and data/ctrl */
/* addr & 2 = channel (0=B, 1=A), addr & 1 = data/ctrl (0=ctrl, 1=data) */
uint8_t scc_compact_read(scc_t *scc, int addr);
void scc_compact_write(scc_t *scc, int addr, uint8_t val);

/* Register-per-address PAL mode (0x04000000):
 * offset & 0x0F = register number, offset & 0x20 = channel (0=B, 0x20=A) */
uint8_t scc_pal_read(scc_t *scc, int offset);
void scc_pal_write(scc_t *scc, int offset, uint8_t val);

/* Feed a received byte into a channel's RX FIFO */
void scc_rx_char(scc_t *scc, int channel, uint8_t data);

/* Set CTS/DCD pin state for a channel */
void scc_set_cts(scc_t *scc, int channel, int state);
void scc_set_dcd(scc_t *scc, int channel, int state);

/* Set TX callback (called when firmware transmits a byte) */
void scc_set_tx_callback(scc_t *scc, int channel,
    void (*cb)(int channel, uint8_t data, void *ctx), void *ctx);

/* Set IRQ callback (called when SCC asserts/deasserts interrupt) */
void scc_set_irq_callback(scc_t *scc,
    void (*cb)(int state, void *ctx), void *ctx);

/* Periodic tick (handles TX timing) */
void scc_tick(scc_t *scc);

/* Update interrupt output state (call after modifying pending flags) */
void scc_update_irq(scc_t *scc);

#endif
