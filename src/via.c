/*
 * via.c -- R6522 VIA (Versatile Interface Adapter) emulation
 *
 * Based on the Rockwell R6522 datasheet (Rev. 9, June 1987).
 * Implements the register behavior needed for the Agfa 9000PS main board
 * where two VIAs provide parallel I/O to the IO board.
 */

#include <stdio.h>
#include <string.h>
#include "via.h"

extern int verbose;

void via_init(via6522_t *v, const char *name)
{
    memset(v, 0, sizeof(*v));
    v->name = name;
    /* After reset: all registers cleared except timers (undefined).
     * DDR=0 (all inputs), IER=0 (all disabled), IFR=0 (all clear).
     * Ports default to input. */
    v->pa_in = 0xFF;  /* Floating inputs read high (pull-ups) */
    v->pb_in = 0xFF;
    v->ca1 = 1;       /* Idle high */
    v->cb1 = 1;
    v->ca1_prev = 1;
    v->cb1_prev = 1;
}

/* Compute effective Port A pin levels */
static uint8_t pa_pins(via6522_t *v)
{
    /* Output pins driven by ORA, input pins from external */
    return (v->ora & v->ddra) | (v->pa_in & ~v->ddra);
}

/* Compute effective Port B pin levels */
static uint8_t pb_pins(via6522_t *v)
{
    uint8_t out = v->orb;
    /* ACR bit 7: Timer 1 PB7 output */
    if (v->acr & 0x80)
        out = (out & 0x7F) | (v->t1_pb7_state ? 0x80 : 0x00);
    return (out & v->ddrb) | (v->pb_in & ~v->ddrb);
}

/* Update IFR bit 7 (composite) */
static void update_irq(via6522_t *v)
{
    if (v->ifr & v->ier & 0x7F)
        v->ifr |= VIA_IRQ_ANY;
    else
        v->ifr &= ~VIA_IRQ_ANY;
}

/* Set an IFR flag bit */
static void set_ifr(via6522_t *v, uint8_t bit)
{
    v->ifr |= bit;
    update_irq(v);
}

/* Check CA1/CB1 edge transitions */
static void check_handshake(via6522_t *v)
{
    /* CA1: PCR bit 0 selects edge. 0=negative (falling), 1=positive (rising) */
    int ca1_edge = v->pcr & 0x01;
    if (ca1_edge) {
        /* Positive edge */
        if (v->ca1 && !v->ca1_prev)
            set_ifr(v, VIA_IRQ_CA1);
    } else {
        /* Negative edge */
        if (!v->ca1 && v->ca1_prev)
            set_ifr(v, VIA_IRQ_CA1);
    }
    v->ca1_prev = v->ca1;

    /* CB1: PCR bit 4 selects edge. 0=negative, 1=positive */
    int cb1_edge = (v->pcr >> 4) & 0x01;
    if (cb1_edge) {
        if (v->cb1 && !v->cb1_prev)
            set_ifr(v, VIA_IRQ_CB1);
    } else {
        if (!v->cb1 && v->cb1_prev)
            set_ifr(v, VIA_IRQ_CB1);
    }
    v->cb1_prev = v->cb1;
}

uint8_t via_read(via6522_t *v, int reg)
{
    switch (reg) {
    case VIA_ORB: {
        /* Reading ORB: output pins return latch, input pins return pin level.
         * Also clears CB1/CB2 interrupt flags. */
        uint8_t val = (v->orb & v->ddrb) | (v->pb_in & ~v->ddrb);
        /* ACR bit 7: PB7 from timer */
        if (v->acr & 0x80)
            val = (val & 0x7F) | (v->t1_pb7_state ? 0x80 : 0x00);
        v->ifr &= ~(VIA_IRQ_CB1 | VIA_IRQ_CB2);
        update_irq(v);
        return val;
    }

    case VIA_ORA:
        /* Reading ORA: returns pin levels (output OR input).
         * Port A ALWAYS reads pins, even for output bits.
         * Clears CA1/CA2 interrupt flags. */
        v->ifr &= ~(VIA_IRQ_CA1 | VIA_IRQ_CA2);
        update_irq(v);
        return pa_pins(v);

    case VIA_DDRB:
        return v->ddrb;

    case VIA_DDRA:
        return v->ddra;

    case VIA_T1CL:
        /* Reading T1C-L clears T1 interrupt flag */
        v->ifr &= ~VIA_IRQ_T1;
        update_irq(v);
        return v->t1_counter & 0xFF;

    case VIA_T1CH:
        return (v->t1_counter >> 8) & 0xFF;

    case VIA_T1LL:
        return v->t1_latch & 0xFF;

    case VIA_T1LH:
        return (v->t1_latch >> 8) & 0xFF;

    case VIA_T2CL:
        /* Reading T2C-L clears T2 interrupt flag */
        v->ifr &= ~VIA_IRQ_T2;
        update_irq(v);
        return v->t2_counter & 0xFF;

    case VIA_T2CH:
        return (v->t2_counter >> 8) & 0xFF;

    case VIA_SR:
        return v->sr;

    case VIA_ACR:
        return v->acr;

    case VIA_PCR:
        return v->pcr;

    case VIA_IFR:
        return v->ifr;

    case VIA_IER:
        /* Bit 7 always reads as 1 (Rockwell convention) */
        return v->ier | 0x80;

    case VIA_ORA_NH:
        /* Same as ORA but without clearing CA1/CA2 flags */
        return pa_pins(v);

    default:
        return 0;
    }
}

void via_write(via6522_t *v, int reg, uint8_t val)
{
    if (verbose) {
        static int trace_count = 0;
        if (trace_count < 200) {
            fprintf(stderr, "[%s-W] reg=0x%02X val=0x%02X '%c'\n",
                    v->name, reg, val, val >= 0x20 && val < 0x7F ? val : '.');
            trace_count++;
        }
    }

    switch (reg) {
    case VIA_ORB:
        v->orb = val;
        /* Clears CB1/CB2 interrupt flags */
        v->ifr &= ~(VIA_IRQ_CB1 | VIA_IRQ_CB2);
        update_irq(v);
        break;

    case VIA_ORA:
        v->ora = val;
        /* Clears CA1/CA2 interrupt flags */
        v->ifr &= ~(VIA_IRQ_CA1 | VIA_IRQ_CA2);
        update_irq(v);
        break;

    case VIA_DDRB:
        v->ddrb = val;
        break;

    case VIA_DDRA:
        v->ddra = val;
        break;

    case VIA_T1CL:
        /* Write to T1C-L: loads low latch only, does NOT start timer */
        v->t1_latch = (v->t1_latch & 0xFF00) | val;
        break;

    case VIA_T1CH:
        /* Write to T1C-H: loads high latch, transfers latch→counter,
         * clears T1 interrupt flag, starts timer */
        v->t1_latch = (v->t1_latch & 0x00FF) | (val << 8);
        v->t1_counter = v->t1_latch;
        v->t1_running = 1;
        v->ifr &= ~VIA_IRQ_T1;
        update_irq(v);
        break;

    case VIA_T1LL:
        v->t1_latch = (v->t1_latch & 0xFF00) | val;
        break;

    case VIA_T1LH:
        /* Write to T1L-H: loads high latch, clears T1 flag.
         * Does NOT transfer to counter or start timer. */
        v->t1_latch = (v->t1_latch & 0x00FF) | (val << 8);
        v->ifr &= ~VIA_IRQ_T1;
        update_irq(v);
        break;

    case VIA_T2CL:
        /* Write to T2C-L: loads low latch only */
        v->t2_latch_lo = val;
        break;

    case VIA_T2CH:
        /* Write to T2C-H: loads counter from latch+val, starts timer,
         * clears T2 interrupt flag */
        v->t2_counter = v->t2_latch_lo | (val << 8);
        v->t2_running = 1;
        v->ifr &= ~VIA_IRQ_T2;
        update_irq(v);
        break;

    case VIA_SR:
        v->sr = val;
        break;

    case VIA_ACR:
        v->acr = val;
        break;

    case VIA_PCR:
        v->pcr = val;
        break;

    case VIA_IFR:
        /* Writing 1 to bits 0-6 clears those flags. Bit 7 ignored. */
        v->ifr &= ~(val & 0x7F);
        update_irq(v);
        break;

    case VIA_IER:
        /* Bit 7: 1=set enable bits, 0=clear enable bits */
        if (val & 0x80)
            v->ier |= (val & 0x7F);
        else
            v->ier &= ~(val & 0x7F);
        update_irq(v);
        break;

    case VIA_ORA_NH:
        /* Same as ORA but without clearing CA1/CA2 flags */
        v->ora = val;
        break;
    }
}

int via_tick(via6522_t *v, int cycles)
{
    int irq = 0;

    /* Timer 1 */
    if (v->t1_running) {
        if (v->t1_counter <= (uint16_t)cycles) {
            /* Timer expired */
            set_ifr(v, VIA_IRQ_T1);
            irq = 1;

            if (v->acr & 0x40) {
                /* Free-running: reload from latch */
                v->t1_counter = v->t1_latch;
                /* Toggle PB7 if enabled */
                if (v->acr & 0x80)
                    v->t1_pb7_state ^= 1;
            } else {
                /* One-shot: stop, set flag, continue counting (wraps) */
                v->t1_running = 0;
                v->t1_counter = 0xFFFF;
            }
        } else {
            v->t1_counter -= cycles;
        }
    }

    /* Timer 2 (one-shot only, pulse counting not implemented) */
    if (v->t2_running && !(v->acr & 0x20)) {
        if (v->t2_counter <= (uint16_t)cycles) {
            set_ifr(v, VIA_IRQ_T2);
            v->t2_running = 0;
            v->t2_counter = 0xFFFF;
            irq = 1;
        } else {
            v->t2_counter -= cycles;
        }
    }

    /* Check handshake transitions */
    check_handshake(v);

    return irq || via_irq_active(v);
}

void via_set_pa(via6522_t *v, uint8_t val)
{
    v->pa_in = val;
}

void via_set_pb(via6522_t *v, uint8_t val)
{
    v->pb_in = val;
}

void via_set_ca1(via6522_t *v, int level)
{
    v->ca1 = level ? 1 : 0;
    check_handshake(v);
}

void via_set_cb1(via6522_t *v, int level)
{
    v->cb1 = level ? 1 : 0;
    check_handshake(v);
}

uint8_t via_get_pa(via6522_t *v)
{
    return pa_pins(v);
}

uint8_t via_get_pb(via6522_t *v)
{
    return pb_pins(v);
}

int via_irq_active(via6522_t *v)
{
    return (v->ifr & v->ier & 0x7F) ? 1 : 0;
}
