/*
 * scc.c -- Zilog Z8530 SCC emulation for Agfa 9000PS
 *
 * Implements register-level emulation of the Z8530 dual-channel SCC.
 * Supports the two-step register access protocol (write pointer to WR0,
 * then read/write the selected register).
 *
 * Features:
 *   - Full interrupt generation (MIE, per-channel RX/TX/ext status)
 *   - BRG countdown at PCLK rate with auto-reload and zero-count interrupt
 *   - TX baud rate delay simulation
 *   - 16-byte RX FIFO (real chip has 3 bytes)
 *   - No CRC computation
 *
 * Reference: Zilog Z8530 SCC Technical Manual, Hatari scc.c
 */

#include <stdio.h>
#include <string.h>
#include "scc.h"

/* Forward declarations */
void scc_update_irq(scc_t *scc);

/* ---- Internal helpers ---- */

static void update_rr0(scc_channel_t *ch)
{
    uint8_t rr0 = 0;

    /* Bit 0: RX Character Available */
    if (ch->rx_fifo_count > 0)
        rr0 |= SCC_RR0_RX_AVAILABLE;

    /* Bit 2: TX Buffer Empty.
     * Clear tx_pending on read — polled TX loops read RR0 in a tight loop
     * and need TX to become ready within the same execute slice. */
    if (ch->tx_pending && ch->tx_delay > 0)
        ch->tx_pending = 0;  /* simulate baud rate completion on poll */
    if (!ch->tx_pending)
        rr0 |= SCC_RR0_TX_EMPTY;

    /* Bit 3: DCD */
    if (ch->dcd)
        rr0 |= SCC_RR0_DCD;

    /* Bit 5: CTS */
    if (ch->cts)
        rr0 |= SCC_RR0_CTS;

    /* Bit 1: Zero Count (BRG reached zero) */
    if (ch->brg_zero_fired)
        rr0 |= SCC_RR0_ZERO_COUNT;

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
/* Forward declaration — RR3 needs access to both channels */
static uint8_t read_reg(scc_t *scc, scc_channel_t *ch, int reg)
{
    switch (reg) {
    case 0:
        update_rr0(ch);
        return ch->rr[0];
    case 1:
        return ch->rr[1];  /* All Sent, no errors */
    case 2:
        return ch->rr[2];  /* Interrupt vector */
    case 3: {
        /* RR3: Interrupt Pending (only readable from Channel A).
         * Bit 5: Channel A RX IP
         * Bit 4: Channel A TX IP
         * Bit 3: Channel A Ext/Status IP
         * Bit 2: Channel B RX IP
         * Bit 1: Channel B TX IP
         * Bit 0: Channel B Ext/Status IP
         */
        uint8_t rr3 = 0;
        scc_channel_t *cha = &scc->ch[SCC_CH_A];
        scc_channel_t *chb = &scc->ch[SCC_CH_B];
        if (cha->ext_status_pending) rr3 |= 0x08;
        if (cha->tx_int_pending)     rr3 |= 0x10;
        if (cha->rx_int_pending)     rr3 |= 0x20;
        if (chb->ext_status_pending) rr3 |= 0x01;
        if (chb->tx_int_pending)     rr3 |= 0x02;
        if (chb->rx_int_pending)     rr3 |= 0x04;
        { static int rr3d = 0;
          if (rr3d < 5)
            if(0) fprintf(stderr, "[RR3] ext_a=%d tx_a=%d rx_a=%d ext_b=%d → 0x%02X\n",
                cha->ext_status_pending, cha->tx_int_pending, cha->rx_int_pending,
                chb->ext_status_pending, rr3);
          rr3d++;
        }
        return rr3;
    }
    case 8:  /* Data register — read from RX FIFO */
        if (ch->rx_fifo_count > 0) {
            uint8_t data = ch->rx_fifo[ch->rx_fifo_rd];
            ch->rx_fifo_rd = (ch->rx_fifo_rd + 1) % 16;
            ch->rx_fifo_count--;
            update_rr0(ch);
            /* Clear RX interrupt if FIFO empty */
            if (ch->rx_fifo_count == 0) {
                ch->rx_int_pending = 0;
                scc_update_irq(scc);
            }
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
        return ch->wr[15]; /* RR15 mirrors WR15 on the real Z8530 */
    default:
        return ch->rr[reg & 0x0F];
    }
}

/* Write a register by number */
static void write_reg(scc_t *scc, scc_channel_t *ch, int channel, int reg, uint8_t val)
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
            ch->brg_zero_fired = 0;
            ch->ext_status_pending = 0;
            /* Restart BRG counter for next tick */
            if (ch->brg_enabled)
                ch->brg_counter = ch->brg_reload;
            update_rr0(ch);
            scc_update_irq(scc);
            break;
        case 3: break;  /* Send abort (SDLC) */
        case 4: break;  /* Enable INT on next RX character */
        case 5:         /* Reset TX INT pending */
            ch->tx_int_pending = 0;
            scc_update_irq(scc);
            break;
        case 6: break;  /* Error reset */
        case 7:         /* Reset highest IUS */
            /* On a real Z8530, this resets only the highest-priority
             * IUS bit. We clear all, but then re-assert any that
             * are still active (data in FIFO, etc). */
            ch->ext_status_pending = 0;
            ch->rx_int_pending = 0;
            ch->tx_int_pending = 0;
            /* Re-assert RX int if FIFO still has data and RX ints enabled */
            if (ch->rx_fifo_count > 0 && (ch->wr[1] & 0x18))
                ch->rx_int_pending = 1;
            scc_update_irq(scc);
            break;
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
        fprintf(stderr, "[SCC] ch%d WR3: 0x%02X→0x%02X (rx_en=%d)\n", channel, ch->wr[3], val, val & 1);
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
        /* Fire TX callback and simulate baud rate delay.
         * Keep tx_pending=1 for a cycle count matching the baud rate,
         * so the firmware's TX-ready polling loop has realistic timing.
         * Without this, the PS interpreter floods output without ever
         * checking for RX data (TX is always instantly "ready"). */
        if (ch->tx_callback)
            ch->tx_callback(channel, val, ch->tx_ctx);
        /* tx_pending stays 1 — cleared by scc_tick after delay */
        ch->tx_delay = 1;  /* minimal delay — clears on next tick */
        update_rr0(ch);
        break;
    case 9:  /* WR9: Master interrupt control / reset */
        ch->wr[9] = val;
        /* WR9 is shared between channels — update MIE in scc_t */
        scc->mie = (val & 0x08) ? 1 : 0;  /* bit 3 = MIE */
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
        ch->brg_enabled = (val & 0x01) ? 1 : 0;
        if (ch->brg_enabled) {
            int tc = ch->wr[12] | (ch->wr[13] << 8);
            /* BRG counts down from TC at PCLK rate. Use raw TC as reload.
             * scc_tick_n() divides ncycles by 4 to convert CPU→PCLK. */
            ch->brg_reload = tc + 2;  /* Z8530 counts TC+2 before zero */
            if (ch->brg_reload < 1) ch->brg_reload = 1;
            ch->brg_counter = ch->brg_reload;
            ch->brg_zero_fired = 0;
        }
        break;
    case 15: /* WR15: External/status interrupt enable */
        ch->wr[15] = val;
        ch->brg_zero_count_ie = (val & 0x02) ? 1 : 0;
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
    int other_idx = ch_idx ? SCC_CH_B : SCC_CH_A;
    int is_data = addr & 1;
    scc_channel_t *ch = &scc->ch[ch_idx];
    scc_channel_t *other = &scc->ch[other_idx];

    if (is_data) {
        /* Track which channel is the active console (for stdin routing) */
        extern int console_channel;
        if (console_channel < 0 && ch->rx_fifo_count > 0)
            console_channel = ch_idx;
        return read_reg(scc, ch, 8);  /* RR8 = data */
    } else {
        uint8_t reg = ch->reg_ptr;
        ch->reg_ptr = 0;  /* Reset pointer after read */
        /* RR3 needs both channels for cross-channel interrupt status */
        if (reg == 3) {
            uint8_t val = read_reg(scc, ch, reg);
            {
                static int rr3_trace = 0;
                if (rr3_trace < 5) {
                    if(0) fprintf(stderr, "[SCC] RR3 read: ch=%d brg_en=%d/%d zc=%d/%d cnt=%d/%d → 0x%02X\n",
                        ch_idx, ch->brg_enabled, other->brg_enabled,
                        ch->brg_zero_fired, other->brg_zero_fired,
                        ch->brg_counter, other->brg_counter, val);
                    rr3_trace++;
                }
            }
            return val;
        }
        return read_reg(scc, ch, reg);
    }
}

void scc_compact_write(scc_t *scc, int addr, uint8_t val)
{
    int ch_idx = (addr & 2) ? SCC_CH_A : SCC_CH_B;
    int is_data = addr & 1;
    scc_channel_t *ch = &scc->ch[ch_idx];

    if (is_data) {
        write_reg(scc, ch, ch_idx, 8, val);  /* WR8 = data */
    } else {
        uint8_t reg = ch->reg_ptr;
        if (reg == 0) {
            /* WR0: sets pointer and/or executes command */
            write_reg(scc, ch, ch_idx, 0, val);
        } else {
            {
                static int wr_trace = 0;
                if (0) {
                    fprintf(stderr, "[SCC] Ch%c WR%d = 0x%02X\n",
                            ch_idx ? 'A' : 'B', reg, val);
                    wr_trace++;
                }
            }
            write_reg(scc, ch, ch_idx, reg, val);
            ch->reg_ptr = 0;  /* Reset after write */
        }
    }
}

/* Register-per-address PAL decode mode (unused on Agfa — 0x04000000 is VIA).
 * Kept for potential use with other Z8530 configurations.
 * offset bits 3-0 = register number (0-15)
 * offset bit 5 = channel (0=B, 0x20=A) */
uint8_t scc_pal_read(scc_t *scc, int offset)
{
    int ch_idx = (offset & 0x20) ? SCC_CH_A : SCC_CH_B;
    int reg = offset & 0x0F;
    return read_reg(scc, &scc->ch[ch_idx], reg);
}

void scc_pal_write(scc_t *scc, int offset, uint8_t val)
{
    int ch_idx = (offset & 0x20) ? SCC_CH_A : SCC_CH_B;
    int reg = offset & 0x0F;
    write_reg(scc, &scc->ch[ch_idx], ch_idx, reg, val);
}

void scc_rx_char(scc_t *scc, int channel, uint8_t data)
{
    scc_channel_t *ch = &scc->ch[channel];
    /* trace disabled for performance */
    if (ch->rx_fifo_count < 16) {
        ch->rx_fifo[ch->rx_fifo_wr] = data;
        ch->rx_fifo_wr = (ch->rx_fifo_wr + 1) % 16;
        ch->rx_fifo_count++;
        update_rr0(ch);

        /* Generate RX interrupt if WR1 enables it (bits 4:3 != 00) */
        if (ch->wr[1] & 0x18) {
            ch->rx_int_pending = 1;
            scc_update_irq(scc);
        }
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

void scc_set_irq_callback(scc_t *scc,
    void (*cb)(int state, void *ctx), void *ctx)
{
    scc->irq_callback = cb;
    scc->irq_ctx = ctx;
}

void scc_update_irq(scc_t *scc)
{
    /* Check if any channel has a pending interrupt with MIE enabled */
    int irq = 0;
    if (scc->mie) {
        int i;
        for (i = 0; i < 2; i++) {
            scc_channel_t *ch = &scc->ch[i];
            if (ch->ext_status_pending || ch->rx_int_pending || ch->tx_int_pending)
                irq = 1;
        }
    }
    if (irq != scc->irq_state) {
        scc->irq_state = irq;
        if (scc->irq_callback)
            scc->irq_callback(irq, scc->irq_ctx);
    }
}

void scc_tick_n(scc_t *scc, int ncycles)
{
    int i;
    /* BRG runs at PCLK ≈ CPU_CLK/4 */
    int pclk_ticks = ncycles / 4;
    if (pclk_ticks < 1) pclk_ticks = 1;

    for (i = 0; i < 2; i++) {
        scc_channel_t *ch = &scc->ch[i];

        /* TX baud rate simulation: count down tx_delay, clear tx_pending when done */
        if (ch->tx_pending && ch->tx_delay > 0) {
            ch->tx_delay -= pclk_ticks;
            if (ch->tx_delay <= 0) {
                ch->tx_pending = 0;
                ch->tx_delay = 0;
                /* Generate TX empty interrupt if WR1 bit 1 (TX int enable) is set */
                if (ch->wr[1] & 0x02) {
                    ch->tx_int_pending = 1;
                    scc_update_irq(scc);
                }
            }
        }

        update_rr0(ch);

        /* BRG countdown at PCLK rate with auto-reload */
        if (ch->brg_enabled) {
            ch->brg_counter -= pclk_ticks;
            if (ch->brg_counter <= 0) {
                static int brg_trace = 0;
                if (brg_trace < 5) {
                    if(0) fprintf(stderr, "[BRG] ch%d zero! reload=%d zc_ie=%d wr1=%02x mie=%d en=[%d,%d]\n",
                            i, ch->brg_reload, ch->brg_zero_count_ie, ch->wr[1], scc->mie,
                            scc->ch[0].brg_enabled, scc->ch[1].brg_enabled);
                    brg_trace++;
                }
                ch->brg_zero_fired = 1;
                ch->brg_counter = ch->brg_reload; /* auto-reload */

                /* Set ext/status pending when BRG zero-counts.
                 * The Z8530 sets the ext/status latch when WR15 bit 1
                 * (Zero Count IE) is enabled. WR1 bit 0 only controls
                 * whether the latch generates an actual interrupt. */
                if (ch->brg_zero_count_ie) {
                    ch->ext_status_pending = 1;
                }
            }
        }
    }
    scc_update_irq(scc);
}
