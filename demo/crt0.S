/*
 * crt0.S -- Bare-metal startup for Agfa 9000PS (68020 @ 16MHz)
 *
 * Loading via Atlas Monitor S-record loader:
 *   1. Connect terminal to Z8530 Channel B (TxDB pin 19) at 9600 8N1
 *   2. Assert CTS on Channel B (ground pin 23, or use terminal's RTS)
 *   3. Power on — Atlas Monitor prompt appears
 *   4. Type 'S' — send the .s28 file
 *   5. After "Done Downloading", type 'G' to execute
 *
 * NOTE: The Atlas Monitor's S-record loader adds 0x02000000 to all
 * addresses automatically, so S-records must have addresses offset
 * by -0x02000000 (e.g., load address 0x02001000 → S-record addr 0x001000).
 *
 * Output goes to BOTH Channel A (pin 15) and Channel B (pin 19),
 * so it works regardless of which channel the terminal is connected to.
 *
 * SCC Channel A: 9600 8N2 (self-test compatible, WR4=0x4C)
 * SCC Channel B: 9600 8N1 (monitor compatible, WR4=0x44)
 */

    .text
    .even

/* ------------------------------------------------------------------ */
/* Vector table (only used if burned into ROM at 0x00000000)          */
/* For S-record loading, the Atlas Monitor provides vectors.          */
/* ------------------------------------------------------------------ */
    .long   0x0200F000          /* Initial SSP */
    .long   _start              /* Reset vector */

/* ------------------------------------------------------------------ */
/* Entry point                                                        */
/* ------------------------------------------------------------------ */
    .globl  _start
    .even
_start:
    move.w  #0x2700, %sr        /* Supervisor mode, all IRQs masked */
    lea     0x0200F000, %sp     /* Stack in low RAM */

    /* Hardware reset strobe (required before SCC init) */
    tst.b   0x07000020

    /* Delay: 20 iterations, ~8us at 16MHz (matches ROM at 0x848D0) */
    moveq   #20, %d0
.Ldly0:
    subq.l  #1, %d0
    bgt.s   .Ldly0

    /* Init SCC Channel A (0x07000002): 9600 8N2 */
    lea     0x07000002, %a0
    lea     scc_tab_cha(%pc), %a1
    moveq   #20, %d0
.Lscc_a:
    move.l  (%sp), (%sp)        /* Delay (~1us, matches ROM at 0x848E8) */
    move.l  (%sp), (%sp)
    move.b  (%a1)+, (%a0)
    dbf     %d0, .Lscc_a

    /* Init SCC Channel B (0x07000000): 9600 8N1 */
    lea     0x07000000, %a0
    lea     scc_tab_chb(%pc), %a1
    moveq   #19, %d0            /* 20 bytes (no trailing 0x13) */
.Lscc_b:
    move.l  (%sp), (%sp)
    move.l  (%sp), (%sp)
    move.b  (%a1)+, (%a0)
    dbf     %d0, .Lscc_b

    /* Jump to C main */
    jsr     main

    /* If main returns, halt */
    stop    #0x2700

/* ------------------------------------------------------------------ */
/* SCC init tables (from ROM 0x848F4 and 0x161C)                      */
/* Confirmed working values, PCLK = 3.6864 MHz                       */
/* ------------------------------------------------------------------ */
    .even
scc_tab_cha:    /* Channel A: 9600 8N2 (21 bytes, matches self-test ROM 0x848F4) */
    .byte   0x01, 0x00          /* WR1  = 0x00 */
    .byte   0x03, 0xC1          /* WR3  = 0xC1: Rx 8 bits, Rx enable */
    .byte   0x04, 0x4C          /* WR4  = 0x4C: x16 clock, 2 stop bits */
    .byte   0x05, 0x6A          /* WR5  = 0x6A: Tx 8 bits, Tx enable, RTS */
    .byte   0x09, 0x0A          /* WR9  = 0x0A */
    .byte   0x0B, 0x50          /* WR11 = 0x50: BRG for Rx/Tx */
    .byte   0x0C, 0x0A          /* WR12 = 0x0A: TC low = 10 */
    .byte   0x0D, 0x00          /* WR13 = 0x00: TC high = 0 */
    .byte   0x0E, 0x01          /* WR14 = 0x01: BRG enable */
    .byte   0x0F, 0x00          /* WR15 = 0x00 */
    .byte   0x13                /* Point to WR3 (cleanup) */

    .even
scc_tab_chb:    /* Channel B: 9600 8N1 (20 bytes, matches monitor ROM 0x161C) */
    .byte   0x01, 0x00
    .byte   0x03, 0xC1
    .byte   0x04, 0x44          /* WR4  = 0x44: x16 clock, 1 stop bit */
    .byte   0x05, 0x6A
    .byte   0x09, 0x0A
    .byte   0x0B, 0x50
    .byte   0x0C, 0x0A
    .byte   0x0D, 0x00
    .byte   0x0E, 0x01
    .byte   0x0F, 0x00

/* ------------------------------------------------------------------ */
/* Serial I/O: output to BOTH channels simultaneously                 */
/* ------------------------------------------------------------------ */

    .even
    .globl  scc_putc
scc_putc:
    move.l  4(%sp), %d0
    /* Channel A */
    lea     0x07000002, %a0
.Ltxa:
    btst    #2, (%a0)
    beq.s   .Ltxa
    move.b  %d0, 1(%a0)
    /* Channel B */
    lea     0x07000000, %a0
.Ltxb:
    btst    #2, (%a0)
    beq.s   .Ltxb
    move.b  %d0, 1(%a0)
    rts

    .even
    .globl  scc_puts
scc_puts:
    move.l  4(%sp), %a0
    tst.l   %a0
    beq.s   .Lps_end
.Lps_loop:
    moveq   #0, %d0
    move.b  (%a0)+, %d0
    beq.s   .Lps_end
    move.l  %a0, -(%sp)
    move.l  %d0, -(%sp)
    bsr     scc_putc
    addq.l  #4, %sp
    move.l  (%sp)+, %a0
    bra.s   .Lps_loop
.Lps_end:
    rts

/* ------------------------------------------------------------------ */
/* Busy-wait delay using DBF (68020 loop mode: ~5 cycles/iter)        */
/* At 16MHz: 5 cycles = 312.5ns, so 3200 iters ≈ 1ms                 */
/* void delay_ms(int ms)                                              */
/* ------------------------------------------------------------------ */
    .even
    .globl  delay_ms
delay_ms:
    move.l  4(%sp), %d0
    ble.s   .Ldly_done
.Ldly_outer:
    move.w  #3199, %d1          /* 3200 iterations via DBF */
.Ldly_inner:
    dbf     %d1, .Ldly_inner
    subq.l  #1, %d0
    bne.s   .Ldly_outer
.Ldly_done:
    rts
