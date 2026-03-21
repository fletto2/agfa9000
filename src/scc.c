/*
 * scc.c -- Zilog Z8530 SCC emulation for Agfa 9000PS
 *
 * Implements register-level emulation of the Z8530 dual-channel SCC.
 * Supports the two-step register access protocol (write pointer to WR0,
 * then read/write the selected register).
 *
 * Simplifications vs real hardware:
 *   - No interrupt generation (Agfa firmware uses polled mode for serial I/O)
 *   - No BRG timing simulation (TX is instant, RX is fed externally)
 *   - No CRC computation
 *   - Simplified RX FIFO (3 bytes, same as real chip)
 *
 * Reference: Zilog Z8530 SCC Technical Manual, Hatari scc.c
 */

#include <string.h>
#include "scc.h"

/* ---- Internal helpers ---- */

static void update_rr0(scc_channel_t *ch)
{
    uint8_t rr0 = 0;

    /* Bit 0: RX Character Available */
    if (ch->rx_fifo_count > 0)
        rr0 |= SCC_RR0_RX_AVAILABLE;

    /* Bit 2: TX Buffer Empty (we're always ready to accept data) */
    if (!ch->tx_pending)
        rr0 |= SCC_RR0_TX_EMPTY;

    /* Bit 3: DCD */
    if (ch->dcd)
        rr0 |= SCC_RR0_DCD;

    /* Bit 5: CTS */
    if (ch->cts)
        rr0 |= SCC_RR0_CTS;

    ch->rr[0] = rr0;
}

static void channel_reset(scc_channel_t *ch)
{
    memset(ch->wr, 0, sizeof(ch->wr));
    memset(ch->rr, 0, sizeof(ch->rr));
    ch->reg_ptr = 0;
    ch->rx_fifo_count = 0;
    ch->rx_fifo_rd = 0;
    ch->rx_fifo_wr = 0;
    ch->tx_pending = 0;
    ch->tx_data = 0;
    ch->cts = 0;
    ch->dcd = 0;

    /* RR1: All Sent, no errors */
    ch->rr[1] = 0x01;

    update_rr0(ch);
}

/* Read a register by number */
static uint8_t read_reg(scc_channel_t *ch, int reg)
{
    switch (reg) {
    case 0:
        update_rr0(ch);
        return ch->rr[0];
    case 1:
        return ch->rr[1];  /* All Sent, no errors */
    case 2:
        return ch->rr[2];  /* Interrupt vector */
    case 3:
        return ch->rr[3];  /* Interrupt pending (channel A only) */
    case 8:  /* Data register — read from RX FIFO */
        if (ch->rx_fifo_count > 0) {
            uint8_t data = ch->rx_fifo[ch->rx_fifo_rd];
            ch->rx_fifo_rd = (ch->rx_fifo_rd + 1) % 3;
            ch->rx_fifo_count--;
            update_rr0(ch);
            return data;
        }
        return 0;
    case 10:
        return ch->rr[10]; /* DPLL/SDLC status */
    case 12:
        return ch->wr[12]; /* BRG TC low (readable) */
    case 13:
        return ch->wr[13]; /* BRG TC high (readable) */
    case 15:
        /* RR15 mirrors WR15 on real Z8530, but in the Agfa's PAL
         * register-per-address mode, the firmware polls this expecting
         * status bits to clear. Return 0 (no pending ext/status changes)
         * to let the IO board comm init proceed. */
        return 0;
    default:
        return ch->rr[reg & 0x0F];
    }
}

/* Write a register by number */
static void write_reg(scc_channel_t *ch, int channel, int reg, uint8_t val)
{
    switch (reg) {
    case 0: {
        /* WR0: Register pointer and commands */
        uint8_t ptr = val & 0x07;  /* Bits 0-2: register pointer */
        uint8_t cmd = (val >> 3) & 0x07;  /* Bits 3-5: command */
        if (ptr != 0)
            ch->reg_ptr = ptr;
        /* Handle commands */
        switch (cmd) {
        case 0: break;  /* Null command */
        case 1: break;  /* Point high (set bit 3 of pointer) */
        case 2:         /* Reset ext/status interrupts */
            update_rr0(ch);
            break;
        case 3: break;  /* Send abort (SDLC) */
        case 4: break;  /* Enable INT on next RX character */
        case 5: break;  /* Reset TX INT pending */
        case 6: break;  /* Error reset */
        case 7: break;  /* Reset highest IUS */
        }
        /* Handle "point high" bit for registers 8-15 */
        if (cmd == 1)
            ch->reg_ptr |= 0x08;
        ch->wr[0] = val;
        break;
    }
    case 1:  /* WR1: Interrupt enables */
        ch->wr[1] = val;
        break;
    case 2:  /* WR2: Interrupt vector */
        ch->wr[2] = val;
        ch->rr[2] = val;  /* RR2 reflects WR2 */
        break;
    case 3:  /* WR3: RX parameters */
        ch->wr[3] = val;
        break;
    case 4:  /* WR4: TX/RX misc parameters (stop bits, parity, clock mode) */
        ch->wr[4] = val;
        break;
    case 5:  /* WR5: TX parameters (TX enable, DTR, RTS, etc.) */
        ch->wr[5] = val;
        break;
    case 6:  /* WR6: Sync character / SDLC address */
        ch->wr[6] = val;
        break;
    case 7:  /* WR7: Sync character / SDLC flag */
        ch->wr[7] = val;
        break;
    case 8:  /* WR8: TX data register */
        ch->wr[8] = val;
        ch->tx_data = val;
        ch->tx_pending = 1;
        /* Fire TX callback immediately (we don't simulate baud rate timing) */
        if (ch->tx_callback)
            ch->tx_callback(channel, val, ch->tx_ctx);
        ch->tx_pending = 0;
        update_rr0(ch);
        break;
    case 9:  /* WR9: Master interrupt control / reset */
        ch->wr[9] = val;
        /* Bits 6-7: reset commands */
        if (val & 0x80) {
            /* Channel A reset or force hardware reset */
        }
        if (val & 0x40) {
            /* Channel B reset */
        }
        break;
    case 10: /* WR10: Misc TX/RX control */
        ch->wr[10] = val;
        break;
    case 11: /* WR11: Clock mode control */
        ch->wr[11] = val;
        break;
    case 12: /* WR12: BRG time constant low */
        ch->wr[12] = val;
        break;
    case 13: /* WR13: BRG time constant high */
        ch->wr[13] = val;
        break;
    case 14: /* WR14: BRG command/misc */
        ch->wr[14] = val;
        break;
    case 15: /* WR15: External/status interrupt enable */
        ch->wr[15] = val;
        break;
    }
}

/* ---- Public API ---- */

void scc_init(scc_t *scc)
{
    memset(scc, 0, sizeof(*scc));
    channel_reset(&scc->ch[SCC_CH_A]);
    channel_reset(&scc->ch[SCC_CH_B]);
}

void scc_reset(scc_t *scc)
{
    /* Preserve callbacks */
    void (*cb_a)(int, uint8_t, void*) = scc->ch[SCC_CH_A].tx_callback;
    void *ctx_a = scc->ch[SCC_CH_A].tx_ctx;
    void (*cb_b)(int, uint8_t, void*) = scc->ch[SCC_CH_B].tx_callback;
    void *ctx_b = scc->ch[SCC_CH_B].tx_ctx;

    scc_init(scc);

    scc->ch[SCC_CH_A].tx_callback = cb_a;
    scc->ch[SCC_CH_A].tx_ctx = ctx_a;
    scc->ch[SCC_CH_B].tx_callback = cb_b;
    scc->ch[SCC_CH_B].tx_ctx = ctx_b;
}

/* Compact byte-addressed access (0x07000000):
 * addr bit 1 = channel (0=B, 1=A)
 * addr bit 0 = data/ctrl (0=ctrl, 1=data) */
uint8_t scc_compact_read(scc_t *scc, int addr)
{
    int ch_idx = (addr & 2) ? SCC_CH_A : SCC_CH_B;
    int is_data = addr & 1;
    scc_channel_t *ch = &scc->ch[ch_idx];

    if (is_data) {
        return read_reg(ch, 8);  /* RR8 = data */
    } else {
        uint8_t reg = ch->reg_ptr;
        ch->reg_ptr = 0;  /* Reset pointer after read */
        return read_reg(ch, reg);
    }
}

void scc_compact_write(scc_t *scc, int addr, uint8_t val)
{
    int ch_idx = (addr & 2) ? SCC_CH_A : SCC_CH_B;
    int is_data = addr & 1;
    scc_channel_t *ch = &scc->ch[ch_idx];

    if (is_data) {
        write_reg(ch, ch_idx, 8, val);  /* WR8 = data */
    } else {
        uint8_t reg = ch->reg_ptr;
        if (reg == 0) {
            /* WR0: sets pointer and/or executes command */
            write_reg(ch, ch_idx, 0, val);
        } else {
            write_reg(ch, ch_idx, reg, val);
            ch->reg_ptr = 0;  /* Reset after write */
        }
    }
}

/* Register-per-address PAL decode (0x04000000):
 * offset bits 3-0 = register number (0-15)
 * offset bit 5 = channel (0=B, 0x20=A) */
uint8_t scc_pal_read(scc_t *scc, int offset)
{
    int ch_idx = (offset & 0x20) ? SCC_CH_A : SCC_CH_B;
    int reg = offset & 0x0F;
    return read_reg(&scc->ch[ch_idx], reg);
}

void scc_pal_write(scc_t *scc, int offset, uint8_t val)
{
    int ch_idx = (offset & 0x20) ? SCC_CH_A : SCC_CH_B;
    int reg = offset & 0x0F;
    write_reg(&scc->ch[ch_idx], ch_idx, reg, val);
}

void scc_rx_char(scc_t *scc, int channel, uint8_t data)
{
    scc_channel_t *ch = &scc->ch[channel];
    if (ch->rx_fifo_count < 3) {
        ch->rx_fifo[ch->rx_fifo_wr] = data;
        ch->rx_fifo_wr = (ch->rx_fifo_wr + 1) % 3;
        ch->rx_fifo_count++;
        update_rr0(ch);
    }
    /* If FIFO full, character is dropped (overrun) */
}

void scc_set_cts(scc_t *scc, int channel, int state)
{
    scc->ch[channel].cts = state;
    update_rr0(&scc->ch[channel]);
}

void scc_set_dcd(scc_t *scc, int channel, int state)
{
    scc->ch[channel].dcd = state;
    update_rr0(&scc->ch[channel]);
}

void scc_set_tx_callback(scc_t *scc, int channel,
    void (*cb)(int channel, uint8_t data, void *ctx), void *ctx)
{
    scc->ch[channel].tx_callback = cb;
    scc->ch[channel].tx_ctx = ctx;
}

void scc_tick(scc_t *scc)
{
    /* In polled mode, nothing time-dependent to do.
     * If we add interrupt support later, timers would go here. */
    update_rr0(&scc->ch[SCC_CH_A]);
    update_rr0(&scc->ch[SCC_CH_B]);
}
