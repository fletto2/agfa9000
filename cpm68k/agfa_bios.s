/*==========================================================================
 * agfa_bios.s - CP/M-68K BIOS for Agfa Compugraphic 9000PS
 *==========================================================================
 *
 * Single-user CP/M-68K for the Agfa 9000PS PostScript RIP
 * Motorola 68020 @ 16MHz, Z8530 SCC, AMD AM5380 SCSI
 *
 * Assembler: GNU as (m68k-elf-as -m68020)
 *
 * Memory map:
 *   ROM:  0x00000000 - 0x0009FFFF  (640KB, original Agfa firmware)
 *   RAM:  0x02000000 - 0x023FFFFF  (4MB)
 *   SCC:  0x07000000 - 0x07000003  (Z8530, compact layout)
 *   SCSI: 0x05000000 - 0x0500000F  (NCR 5380, addr & 7 mapping)
 *   DMA:  0x05000020              (SCSI pseudo-DMA port)
 *
 * RAM layout:
 *   0x02000000 - 0x020003FF  System variables (reserved)
 *   0x02000400 - 0x020007FF  BIOS code + data (1KB)
 *   0x02000800 - 0x02000FFF  BIOS stack (2KB)
 *   0x02001000 - 0x0200FFFF  CCP + BDOS (60KB)
 *   0x02010000 - 0x0203FFFF  TPA (192KB)
 *
 * Console: Z8530 Channel B (TxDB pin 19, RxDB pin 22), 9600 8N1
 *          For Atlas Monitor S-record loading, assert /CTSB (pin 30)
 *
 * Disk: SCSI HD at ID 0, 512-byte sectors, CP/M 4KB blocks
 *       First 2 tracks reserved (system), 128 dir entries
 *
 * Can be loaded via Atlas Monitor S-record loader:
 *   1. Connect to Channel B, ground pin 30 (/CTSB)
 *   2. Power on, get monitor prompt
 *   3. Send the .s28 file
 *   4. Type G to execute
 */

    .text
    .even

/*==========================================================================
 * Constants
 *==========================================================================*/

    /* Memory */
    .equ RAM_BASE,      0x02000000
    .equ BIOS_BASE,     0x02000400
    .equ BIOS_STACK,    0x02001000
    .equ CCP_BASE,      0x02001000
    .equ TPA_BASE,      0x02010000
    .equ TPA_END,       0x02040000  /* 192KB TPA */

    /* Z8530 SCC - compact layout at 0x07000000 */
    /* Channel B: ctrl=0x07000000, data=0x07000001 (console) */
    /* Channel A: ctrl=0x07000002, data=0x07000003 */
    .equ SCC_BASE,      0x07000000
    .equ SCC_BCTL,      0x07000000  /* Channel B control */
    .equ SCC_BDAT,      0x07000001  /* Channel B data */
    .equ SCC_RESET,     0x07000020  /* Hardware reset strobe */

    /* CP/M disk parameters (ROM disk, same geometry as gas68k) */
    .equ SECTOR_SIZE,   128         /* CP/M logical sector */
    .equ SPT,           26          /* Sectors per track */
    .equ BSH,           3           /* Block shift (2KB blocks, same as gas68k) */
    .equ BLM,           7
    .equ EXM,           0
    .equ DSM,           148         /* 149 blocks (gas68k ROM disk) */
    .equ DRM,           127         /* 128 directory entries */
    .equ AL0,           0xC0
    .equ AL1,           0x00
    .equ OFF,           2           /* 2 reserved tracks */

    /* BIOS function count */
    .equ NFUNCS,        20

/*==========================================================================
 * Vector table (for ROM burning) / Entry point (for S-record loading)
 *==========================================================================*/

    .long   BIOS_STACK          /* Initial SSP */
    .long   _start              /* Reset PC */

    .globl  _start
    .even
_start:
    move.w  #0x2700, %sr        /* Supervisor, all IRQs masked */
    lea     BIOS_STACK, %sp

    /* Hardware reset strobe (required before SCC init) */
    tst.b   SCC_RESET

    /* Delay */
    moveq   #20, %d0
.Ldly:  subq.l  #1, %d0
    bgt.s   .Ldly

    /* Init SCC Channel B: 9600 8N1 */
    lea     SCC_BCTL, %a0
    lea     scc_init_tab(%pc), %a1
    moveq   #19, %d0
.Lscc_init:
    move.l  (%sp), (%sp)        /* Delay */
    move.l  (%sp), (%sp)
    move.b  (%a1)+, (%a0)
    dbf     %d0, .Lscc_init

    /* Banner */
    lea     banner(%pc), %a0
    bsr     prtstr

    /* Clear BIOS variables */
    lea     disk_state(%pc), %a0
    moveq   #11, %d0
.Lclr_vars:
    clr.b   (%a0)+
    dbf     %d0, .Lclr_vars

    /* Set up TRAP #2 vector for BDOS calls */
    move.l  #trap2_dispatch, 0x88   /* TRAP #2 vector */

    /* Print ready message */
    lea     ready_msg(%pc), %a0
    bsr     prtstr

    /* Jump to CCP cold boot */
    jmp     cpm                 /* CCP cold boot entry */

/*==========================================================================
 * Exception handlers
 *==========================================================================*/
    /* TRAP #2 dispatch: redirect to BDOS traphndl without clobbering regs.
     * Uses push+RTS pattern (from gas68kcpm bug fix #9). */
    .even
trap2_dispatch:
    move.l  active_bdos_entry(%pc), -(%sp)
    rts

/*==========================================================================
 * BIOS function table (pointed to by _init)
 *==========================================================================*/
    .even
    .globl _init
_init:
biosbase:
    .long   _init
    .long   wboot, coninstat, conin, conout, lstout
    .long   auxout, auxin, home, seldsk, settrk
    .long   setsec, setdma, read, write, lststat
    .long   sectran, 0 /* submit pgm */, 0 /* set exc */, getseg, setdma
    .long   flush, setexc

/*==========================================================================
 * Warm boot
 *==========================================================================*/
    .even
wboot:
    lea     wboot_msg(%pc), %a0
    bsr     prtstr
    jmp     ccpwboot            /* CCP warm boot entry */

/*==========================================================================
 * Console I/O - Z8530 Channel B
 *==========================================================================*/
    .even
coninstat:
    btst    #0, SCC_BCTL        /* RR0 bit 0: Rx available */
    beq.s   .Lnot_ready
    moveq   #-1, %d0            /* 0xFF = char available */
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
    btst    #2, SCC_BCTL        /* RR0 bit 2: Tx ready */
    beq.s   conout
    move.b  %d1, SCC_BDAT
    rts

conoutstat:
    btst    #2, SCC_BCTL
    beq.s   .Lnot_ready
    moveq   #-1, %d0
    rts

/*==========================================================================
 * Stub I/O (list, aux)
 *==========================================================================*/
    .even
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
    /* Return TPA bounds in D1/D2 */
    move.l  #TPA_BASE, %d1      /* start */
    move.l  #TPA_END, %d2       /* end */
    clr.l   %d0                 /* success */
    rts

setexc:
    /* D1 = exception number, D2 = handler address */
    /* Returns old handler in D0 */
    andi.l  #0xFF, %d1
    lsl.l   #2, %d1
    movea.l %d1, %a0
    move.l  (%a0), %d0          /* old handler */
    /* Protect TRAP #2 */
    cmpi.l  #0x88, %d1
    beq.s   .Lsetexc_done
    move.l  %d2, (%a0)          /* set new handler */
.Lsetexc_done:
    rts

setiob:
    move.b  %d1, iobyte
    rts

getiob:
    clr.l   %d0
    move.b  iobyte(%pc), %d0
    rts

flush:
    clr.l   %d0
    rts

/*==========================================================================
 * Disk I/O - SCSI via NCR 5380
 *==========================================================================*/
    .even
home:
    lea     disk_state(%pc), %a0
    clr.w   (%a0)               /* track = 0 */
    rts

seldsk:
    lea     disk_state(%pc), %a0
    andi.l  #0xF, %d1
    move.w  %d1, 4(%a0)        /* drive */
    tst.w   %d1                 /* only drive 0 */
    bne.s   .Lseldsk_bad
    lea     dph0(%pc), %a1
    move.l  %a1, %d0
    rts
.Lseldsk_bad:
    clr.l   %d0
    rts

settrk:
    lea     disk_state(%pc), %a0
    move.w  %d1, (%a0)          /* track */
    rts

setsec:
    lea     disk_state(%pc), %a0
    move.w  %d1, 2(%a0)        /* sector */
    rts

setdma:
    lea     disk_state(%pc), %a0
    move.l  %d1, 8(%a0)        /* dma_addr */
    rts

sectran:
    /* No sector translation (1:1) */
    move.l  %d1, %d0
    rts

/*--------------------------------------------------------------------------
 * read - Read one 128-byte CP/M sector from ROM disk
 *
 * ROM disk is embedded at rom_disk_base (appended after BIOS+CCP+BDOS).
 * Simple linear layout: sector_offset = (track * SPT + sector) * 128
 *--------------------------------------------------------------------------*/
    .even
read:
    lea     disk_state(%pc), %a0

    /* Compute linear sector offset */
    clr.l   %d0
    move.w  (%a0), %d0          /* track */
    mulu    #SPT, %d0
    clr.l   %d1
    move.w  2(%a0), %d1         /* sector */
    add.l   %d1, %d0            /* linear sector */
    lsl.l   #7, %d0             /* * 128 = byte offset */

    /* Source: ROM disk base + offset */
    lea     rom_disk_base(%pc), %a1
    adda.l  %d0, %a1

    /* Destination: DMA address */
    movea.l 8(%a0), %a0

    /* Copy 128 bytes (32 longwords) */
    moveq   #31, %d0
.Lcopy128:
    move.l  (%a1)+, (%a0)+
    dbf     %d0, .Lcopy128

    clr.l   %d0                 /* success */
    rts

/*--------------------------------------------------------------------------
 * write - ROM disk is read-only
 *--------------------------------------------------------------------------*/
    .even
write:
    moveq   #1, %d0             /* error: read-only */
    rts

/*==========================================================================
 * Data tables
 *==========================================================================*/
    .even

/* SCC init table: 9600 8N1, BRG from 3.6864 MHz PCLK */
/* Matches Atlas Monitor ROM at 0x161C (20 bytes) */
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

/* Disk Parameter Header - drive 0 */
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
    .word   SPT                 /* SPT: sectors per track */
    .byte   BSH                 /* BSH: block shift */
    .byte   BLM                 /* BLM: block mask */
    .byte   EXM                 /* EXM: extent mask */
    .byte   0                   /* pad */
    .word   DSM                 /* DSM: total blocks - 1 */
    .word   DRM                 /* DRM: directory entries - 1 */
    .byte   AL0                 /* AL0 */
    .byte   AL1                 /* AL1 */
    .word   0                   /* CKS: check size (0 for HD) */
    .word   OFF                 /* OFF: reserved tracks */

/* Strings */
banner:
    .asciz  "\r\n\r\nCP/M-68K for Agfa 9000PS\r\n"
ready_msg:
    .asciz  "BIOS ready. ROM disk A.\r\n\r\n"
wboot_msg:
    .asciz  "\r\nWarm boot\r\n"

/*==========================================================================
 * BSS (variables in RAM, after code)
 *==========================================================================*/
    .even

/* Disk state: track(2) + sector(2) + drive(2) + pad(2) + dma_addr(4) */
disk_state:     .space  12

/* CP/M buffers */
dirbuf:         .space  128
ckv0:           .space  32
alv0:           .space  ((DSM / 8) + 1)

/* BIOS variables */
active_bdos_entry:
    .long   traphndl            /* BDOS TRAP #2 handler (set by bdosinit) */
iobyte:
    .word   0

    .even
bios_end:

/*==========================================================================
 * ROM disk image follows here (appended by Makefile)
 * Format: 94 tracks, 26 sectors/track, 128 bytes/sector
 * Built with mkfs.cpm + cpmcp from cpmtools
 *==========================================================================*/
    .even
    .globl rom_disk_base
rom_disk_base:
    /* ROM disk data appended here by the linker/objcopy */
