/*==========================================================================
 * agfa_bios.s - CP/M-68K BIOS for Agfa Compugraphic 9000PS
 *==========================================================================
 *
 * Single-user CP/M-68K for the Agfa 9000PS PostScript RIP
 * Motorola 68020 @ 16MHz, Z8530 SCC, 4MB RAM
 *
 * ROM layout (replaces all 5 banks, 640KB total):
 *   0x00000-0x003FF  Vector table (1KB)
 *   0x00400-0x017FF  BIOS code+data (~5KB)
 *   0x01800-0x077FF  CCP+BDOS (LMA, ~24KB)
 *   0x07800-0x9FFFF  ROM disk A (94 tracks, ~312KB)
 *
 * RAM layout:
 *   0x02000000-0x020003FF  Exception vector redirect (mirrors ROM vectors)
 *   0x02000400-0x020017FF  BIOS (copied from ROM)
 *   0x02001800-0x020077FF  CCP+BDOS (copied from ROM, runs here)
 *   0x02007800-0x0200F7FF  TPA (32KB - can extend if needed)
 *   0x0200F800-0x0200FFFF  Supervisor stack (2KB)
 *
 * Console: Z8530 Channel B (TxDB pin 19, RxDB pin 22), 9600 8N1
 *
 * ROM disk: read directly from ROM at 0x07800, no copy needed.
 *   94 tracks, 26 sectors/track, 128 bytes/sector, 2KB blocks
 *
 * EPROM layout: 5 banks x 4 EPROMs (AM27C256, 32KB each)
 *   Bank 0: HH0/HM0/LM0/LL0 (vectors + BIOS + CCP start)
 *   Bank 1: HH1/HM1/LM1/LL1 (CCP end + ROM disk start)
 *   Bank 2: HH2/HM2/LM2/LL2 (ROM disk continued)
 *   Banks 3-4: 0xFF fill (unused, or future expansion)
 */

    .text
    .even

/*==========================================================================
 * Constants
 *==========================================================================*/

    /* ROM addresses */
    .equ BIOS_ROM,      0x00000400  /* BIOS code in ROM */
    .equ CCP_LMA,       0x00001800  /* CCP+BDOS load address in ROM */
    .equ ROMDISK_ROM,   0x00007800  /* ROM disk in ROM */

    /* RAM addresses */
    .equ RAM_BASE,      0x02000000
    .equ BIOS_RAM,      0x02000400  /* BIOS runs here */
    .equ CCP_VMA,       0x02001800  /* CCP+BDOS runs here */
    .equ TPA_BASE,      0x02007800  /* TPA starts here */
    .equ TPA_END,       0x0200F800  /* TPA ends here (32KB) */
    .equ SSP_TOP,       0x02010000  /* Supervisor stack top */

    /* ROM-to-RAM delta */
    .equ ROM_RAM_DELTA, 0x02000000  /* RAM addr = ROM addr + delta */

    /* Sizes */
    .equ BIOS_SIZE,     0x1400      /* 5KB for BIOS code+data */
    .equ CCP_SIZE,      0x6000      /* 24KB for CCP+BDOS */

    /* Z8530 SCC - compact layout at 0x07000000 */
    .equ SCC_BCTL,      0x07000002  /* Channel A control (RS-422 port) */
    .equ SCC_BDAT,      0x07000003  /* Channel A data (RS-422 port) */
    .equ SCC_RESET,     0x07000020  /* Hardware reset strobe */

    /* CP/M disk parameters (ROM disk, same as gas68kcpm) */
    .equ SPT,           26
    .equ BSH,           3           /* 2KB blocks */
    .equ BLM,           7
    .equ EXM,           0
    .equ DSM,           148
    .equ DRM,           127
    .equ AL0,           0xC0
    .equ AL1,           0x00
    .equ OFF,           2

    .equ NFUNCS,        20

/*==========================================================================
 * Vector table at ROM 0x00000
 *==========================================================================*/

vectors:
    .long   SSP_TOP             /* 000: Initial SSP */
    .long   preloader           /* 004: Reset PC → preloader */
    .long   exc_buserror        /* 008: Bus error */
    .long   exc_buserror        /* 00C: Address error */
    .long   exc_generic         /* 010: Illegal instruction */
    .long   exc_generic         /* 014: Zero divide */
    .long   exc_generic         /* 018: CHK */
    .long   exc_generic         /* 01C: TRAPV */
    .long   exc_generic         /* 020: Privilege violation */
    .long   exc_generic         /* 024: Trace */
    .long   exc_generic         /* 028: Line 1010 */
    .long   exc_generic         /* 02C: Line 1111 */
    .fill   20, 4, 0            /* 030-07F: reserved */
    .long   exc_generic         /* 080: TRAP #0 */
    .long   exc_generic         /* 084: TRAP #1 */
    .long   trap2_dispatch_rom  /* 088: TRAP #2 (BDOS) */
    .fill   13, 4, 0            /* 08C-0BF: TRAP #3-#15 */
    .fill   16, 4, 0            /* 0C0-0FF: unassigned */

    /* Pad to 0x400 */
    .org    0x400

/*==========================================================================
 * Preloader - runs from ROM, copies BIOS+CCP to RAM
 *==========================================================================*/

preloader:
    move.w  #0x2700, %sr
    lea     SSP_TOP, %sp

    /* Copy BIOS from ROM 0x400 to RAM 0x02000400 */
    lea     BIOS_ROM, %a0
    lea     BIOS_RAM, %a1
    move.l  #BIOS_SIZE, %d0
    bsr     .Lcopy

    /* Copy CCP+BDOS from ROM 0x1800 to RAM 0x02001800 */
    lea     CCP_LMA, %a0
    lea     CCP_VMA, %a1
    move.l  #CCP_SIZE, %d0
    bsr     .Lcopy

    /* Jump to BIOS _start in RAM */
    jmp     _start

.Lcopy:
    lsr.l   #2, %d0             /* byte count → longword count */
    subq.l  #1, %d0
.Lcopy_loop:
    move.l  (%a0)+, (%a1)+
    dbf     %d0, .Lcopy_loop
    subi.l  #0x10000, %d0
    bcc.s   .Lcopy_loop
    rts

/*==========================================================================
 * TRAP #2 ROM stub - redirects to RAM copy
 * (Used before preloader copies the real handler to RAM)
 *==========================================================================*/
    .even
trap2_dispatch_rom:
    move.l  #trap2_dispatch, -(%sp)
    addi.l  #ROM_RAM_DELTA, (%sp)
    rts

/*==========================================================================
 * BIOS code - copied to RAM 0x02000400, runs from there
 *==========================================================================*/

    .even
_start:
    move.w  #0x2700, %sr
    lea     SSP_TOP, %sp

    /* Hardware reset strobe (required before SCC init) */
    tst.b   SCC_RESET
    moveq   #20, %d0
.Ldly:  subq.l  #1, %d0
    bgt.s   .Ldly

    /* Init SCC Channel B: 9600 8N1 */
    lea     SCC_BCTL, %a0
    lea     scc_init_tab(%pc), %a1
    moveq   #19, %d0
.Lscc_init:
    move.l  (%sp), (%sp)
    move.l  (%sp), (%sp)
    move.b  (%a1)+, (%a0)
    dbf     %d0, .Lscc_init

    /* Banner */
    lea     banner(%pc), %a0
    bsr     prtstr

    /* Set up TRAP #2 vector in RAM vector area */
    move.l  #trap2_dispatch, 0x88

    /* Clear disk state */
    lea     disk_state(%pc), %a0
    moveq   #11, %d0
.Lclr:  clr.b   (%a0)+
    dbf     %d0, .Lclr

    lea     ready_msg(%pc), %a0
    bsr     prtstr

    /* Jump to CCP cold boot */
    jmp     cpm

/*==========================================================================
 * Exception handlers
 *==========================================================================*/
    .even
exc_generic:
    rte

exc_buserror:
    /* 68020 bus error frame is longer than normal - skip extra words */
    move.w  #0x2700, %sr
    addq.l  #8, %sp             /* skip bus error extra info */
    rte

/*==========================================================================
 * TRAP #2 dispatch (runs from RAM)
 *==========================================================================*/
    .even
trap2_dispatch:
    move.l  active_bdos_entry(%pc), -(%sp)
    rts

/*==========================================================================
 * BIOS function table - _init points here
 *==========================================================================*/
    .even
    .globl _init
_init:
biosbase:
    .long   _init
    .long   wboot, coninstat, conin, conout, lstout
    .long   auxout, auxin, home, seldsk, settrk
    .long   setsec, setdma, read, write, lststat
    .long   sectran, 0, setexc, getseg, setdma
    .long   flush, setexc

/*==========================================================================
 * Warm boot
 *==========================================================================*/
    .even
wboot:
    lea     wboot_msg(%pc), %a0
    bsr     prtstr
    jmp     ccpwboot

/*==========================================================================
 * Console I/O - Z8530 Channel B
 *==========================================================================*/
    .even
coninstat:
    btst    #0, SCC_BCTL
    beq.s   .Lnot_ready
    moveq   #-1, %d0
    rts
.Lnot_ready:
    clr.l   %d0
    rts

conin:
    btst    #0, SCC_BCTL
    beq.s   conin
    clr.l   %d0
    move.b  SCC_BDAT, %d0
    rts

conout:
    btst    #2, SCC_BCTL
    beq.s   conout
    move.b  %d1, SCC_BDAT
    rts

lstout:
lststat:
auxout:
    rts
auxin:
    clr.l   %d0
    rts

/*==========================================================================
 * String output
 *==========================================================================*/
    .even
prtstr:
    move.l  %d1, -(%sp)
.Lps_loop:
    move.b  (%a0)+, %d1
    beq.s   .Lps_done
    bsr     conout
    bra.s   .Lps_loop
.Lps_done:
    move.l  (%sp)+, %d1
    rts

/*==========================================================================
 * System functions
 *==========================================================================*/
    .even
getseg:
    move.l  #TPA_BASE, %d1
    move.l  #TPA_END, %d2
    clr.l   %d0
    rts

setexc:
    andi.l  #0xFF, %d1
    lsl.l   #2, %d1
    movea.l %d1, %a0
    move.l  (%a0), %d0
    cmpi.l  #0x88, %d1          /* protect TRAP #2 */
    beq.s   .Lsetexc_done
    move.l  %d2, (%a0)
.Lsetexc_done:
    rts

flush:
    clr.l   %d0
    rts

/*==========================================================================
 * Disk I/O - ROM disk (read directly from ROM, no copy)
 *==========================================================================*/
    .even
home:
    lea     disk_state(%pc), %a0
    clr.w   (%a0)
    rts

seldsk:
    lea     disk_state(%pc), %a0
    andi.l  #0xF, %d1
    move.w  %d1, 4(%a0)
    tst.w   %d1
    bne.s   .Lseldsk_bad
    lea     dph0(%pc), %a1
    move.l  %a1, %d0
    rts
.Lseldsk_bad:
    clr.l   %d0
    rts

settrk:
    lea     disk_state(%pc), %a0
    move.w  %d1, (%a0)
    rts

setsec:
    lea     disk_state(%pc), %a0
    move.w  %d1, 2(%a0)
    rts

setdma:
    lea     disk_state(%pc), %a0
    move.l  %d1, 8(%a0)
    rts

sectran:
    move.l  %d1, %d0
    rts

read:
    lea     disk_state(%pc), %a0

    /* linear sector = track * SPT + sector */
    clr.l   %d0
    move.w  (%a0), %d0
    mulu    #SPT, %d0
    clr.l   %d1
    move.w  2(%a0), %d1
    add.l   %d1, %d0
    lsl.l   #7, %d0             /* * 128 = byte offset */

    /* Source: ROM disk base + offset (ROM address, NOT RAM) */
    lea     ROMDISK_ROM, %a1
    adda.l  %d0, %a1

    /* Destination: DMA address */
    movea.l 8(%a0), %a0

    moveq   #31, %d0
.Lcopy128:
    move.l  (%a1)+, (%a0)+
    dbf     %d0, .Lcopy128

    clr.l   %d0
    rts

write:
    moveq   #1, %d0             /* ROM disk is read-only */
    rts

/*==========================================================================
 * Data tables
 *==========================================================================*/
    .even

/* SCC init: 9600 8N1, matches Atlas Monitor ROM at 0x161C */
scc_init_tab:
    .byte   0x01, 0x00          /* WR1  = no interrupts */
    .byte   0x03, 0xC1          /* WR3  = Rx 8 bits, enable */
    .byte   0x04, 0x44          /* WR4  = x16, 1 stop, no parity */
    .byte   0x05, 0x6A          /* WR5  = Tx 8 bits, enable, RTS */
    .byte   0x09, 0x0A          /* WR9  = NV, MIE */
    .byte   0x0B, 0x50          /* WR11 = BRG clocks */
    .byte   0x0C, 0x0A          /* WR12 = TC low = 10 */
    .byte   0x0D, 0x00          /* WR13 = TC high = 0 */
    .byte   0x0E, 0x01          /* WR14 = BRG enable */
    .byte   0x0F, 0x00          /* WR15 = no ext/status */

/* Disk Parameter Header */
    .even
dph0:
    .long   0                   /* XLT (no translation) */
    .word   0, 0, 0             /* scratch */
    .long   dirbuf              /* directory buffer */
    .long   dpb0                /* DPB pointer */
    .long   ckv0                /* check vector */
    .long   alv0                /* allocation vector */

/* Disk Parameter Block */
dpb0:
    .word   SPT
    .byte   BSH
    .byte   BLM
    .byte   EXM
    .byte   0
    .word   DSM
    .word   DRM
    .byte   AL0
    .byte   AL1
    .word   0                   /* CKS (0 for fixed disk) */
    .word   OFF

/* Strings */
banner:
    .ascii  "\r\n\r\n"
    .ascii  "CP/M-68K v1.3 for Agfa 9000PS\r\n"
    .asciz  "Z8530 SCC Channel A (RS-422), 9600 8N1\r\n\r\n"
ready_msg:
    .asciz  "A>\r\n"
wboot_msg:
    .asciz  "\r\nWarm boot\r\n"

/*==========================================================================
 * BSS - variables in RAM (initialized by preloader clear or _start)
 *==========================================================================*/
    .even
disk_state:     .space  12      /* track(2)+sector(2)+drive(2)+pad(2)+dma(4) */
dirbuf:         .space  128
ckv0:           .space  32
alv0:           .space  ((DSM / 8) + 1)
active_bdos_entry:
    .long   0                   /* set by bdosinit via setexc */
iobyte:
    .word   0

    .even
bios_end:
