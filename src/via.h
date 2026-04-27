/*
 * via.h -- R6522 VIA (Versatile Interface Adapter) emulation
 *
 * Implements the Rockwell R6522AP as used on the Agfa 9000PS main board.
 * Two VIAs at 0x04000000 (VIA #1) and 0x04000020 (VIA #2) provide
 * parallel I/O to the IO board via 50-pin IDC ribbon cable.
 *
 * Register map (PAL direct-register decode, byte offsets 0x00-0x0F):
 *   0x00  ORB/IRB   Output/Input Register B
 *   0x01  ORA/IRA   Output/Input Register A (with handshake)
 *   0x02  DDRB      Data Direction Register B (1=output, 0=input)
 *   0x03  DDRA      Data Direction Register A
 *   0x04  T1C-L     Timer 1 Counter Low (read=counter, write=latch)
 *   0x05  T1C-H     Timer 1 Counter High (write starts timer)
 *   0x06  T1L-L     Timer 1 Latch Low
 *   0x07  T1L-H     Timer 1 Latch High (write clears T1 flag)
 *   0x08  T2C-L     Timer 2 Counter Low
 *   0x09  T2C-H     Timer 2 Counter High (write starts timer)
 *   0x0A  SR        Shift Register
 *   0x0B  ACR       Auxiliary Control Register
 *   0x0C  PCR       Peripheral Control Register
 *   0x0D  IFR       Interrupt Flag Register (write 1 to clear)
 *   0x0E  IER       Interrupt Enable Register (bit 7: 1=set, 0=clear)
 *   0x0F  ORA/IRA   Output/Input Register A (no handshake)
 *
 * Port behavior:
 *   - Writing ORB/ORA stores to output latch
 *   - Reading ORB: output pins return latch, input pins return actual pin level
 *   - Reading ORA (reg 1): returns pin levels (with CA1/CA2 handshake side effects)
 *   - Reading ORA-nh (reg 0x0F): returns pin levels (no handshake side effects)
 *   - For output pins on Port B: read returns latch value
 *   - For output pins on Port A: read returns actual pin level (NOT latch)
 *
 * Timer 1:
 *   - ACR bit 6: 0=one-shot, 1=free-running
 *   - ACR bit 7: 0=no PB7 output, 1=PB7 toggles on timer
 *   - Writing T1C-H loads latch→counter and starts counting
 *   - Counter decrements at E clock rate (CPU/10 for 68000 systems)
 *   - On underflow: sets IFR bit 6, optionally toggles PB7
 *
 * Timer 2:
 *   - ACR bit 5: 0=timed interrupt (one-shot), 1=count pulses on PB6
 *   - Writing T2C-H starts counting
 *   - On underflow: sets IFR bit 5
 *
 * IFR bits: 0=CA2, 1=CA1, 2=SR, 3=CB2, 4=CB1, 5=T2, 6=T1, 7=any
 * IER bits: same mapping, bit 7: write 1=set enables, 0=clear enables
 */
#ifndef VIA_H
#define VIA_H

#include <stdint.h>

/* Register indices */
#define VIA_ORB   0
#define VIA_ORA   1
#define VIA_DDRB  2
#define VIA_DDRA  3
#define VIA_T1CL  4
#define VIA_T1CH  5
#define VIA_T1LL  6
#define VIA_T1LH  7
#define VIA_T2CL  8
#define VIA_T2CH  9
#define VIA_SR    10
#define VIA_ACR   11
#define VIA_PCR   12
#define VIA_IFR   13
#define VIA_IER   14
#define VIA_ORA_NH 15

/* IFR/IER bit masks */
#define VIA_IRQ_CA2  0x01
#define VIA_IRQ_CA1  0x02
#define VIA_IRQ_SR   0x04
#define VIA_IRQ_CB2  0x08
#define VIA_IRQ_CB1  0x10
#define VIA_IRQ_T2   0x20
#define VIA_IRQ_T1   0x40
#define VIA_IRQ_ANY  0x80

typedef struct via6522 {
    /* Output latches */
    uint8_t ora;            /* Port A output latch */
    uint8_t orb;            /* Port B output latch */

    /* Data direction (1=output, 0=input) */
    uint8_t ddra;
    uint8_t ddrb;

    /* External pin levels (set by connected hardware) */
    uint8_t pa_in;          /* Port A input pin levels */
    uint8_t pb_in;          /* Port B input pin levels */

    /* Handshake pins */
    uint8_t ca1, ca2;       /* Control lines A */
    uint8_t cb1, cb2;       /* Control lines B */
    uint8_t ca1_prev, cb1_prev;  /* Previous state for edge detection */

    /* Timer 1 */
    uint16_t t1_counter;
    uint16_t t1_latch;
    int t1_running;
    int t1_pb7_state;       /* PB7 toggle state */

    /* Timer 2 */
    uint16_t t2_counter;
    uint8_t  t2_latch_lo;   /* Only low byte is latched */
    int t2_running;

    /* Shift register */
    uint8_t sr;

    /* Control registers */
    uint8_t acr;            /* Auxiliary Control Register */
    uint8_t pcr;            /* Peripheral Control Register */

    /* Interrupt registers */
    uint8_t ifr;            /* Interrupt Flag Register */
    uint8_t ier;            /* Interrupt Enable Register */

    /* Name for debug */
    const char *name;
} via6522_t;

/* Initialize VIA to power-on reset state */
void via_init(via6522_t *v, const char *name);

/* Read a VIA register (0x00-0x0F) */
uint8_t via_read(via6522_t *v, int reg);

/* Write a VIA register (0x00-0x0F) */
void via_write(via6522_t *v, int reg, uint8_t val);

/* Advance timers by N clock cycles (call from emulator main loop).
 * VIAs run at 1MHz on the Agfa 9000PS (CPU clock / 16).
 * Returns nonzero if IRQ line should be asserted. */
int via_tick(via6522_t *v, int cycles);

/* Set external pin levels (called by inter-board wiring) */
void via_set_pa(via6522_t *v, uint8_t val);
void via_set_pb(via6522_t *v, uint8_t val);
void via_set_ca1(via6522_t *v, int level);
void via_set_cb1(via6522_t *v, int level);

/* Get output pin levels (for inter-board wiring) */
uint8_t via_get_pa(via6522_t *v);
uint8_t via_get_pb(via6522_t *v);

/* Check if IRQ is active */
int via_irq_active(via6522_t *v);

#endif
