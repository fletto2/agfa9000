/*==========================================================================
 * agfa_bios.s - CP/M-68K BIOS for Agfa Compugraphic 9000PS
 *==========================================================================
 *
 * Single-user CP/M-68K for the Agfa 9000PS PostScript RIP
 * Motorola 68020 @ 16MHz, Z8530 SCC, 2MB RAM
 *
 * ROM layout (single 128KB bank = 4 EPROMs):
 *   0x00000-0x003FF  Vector table (1KB)
 *   0x00400-0x017FF  BIOS code+data (~5KB)
 *   0x01800-0x077FF  CCP+BDOS (LMA, ~24KB)
 *   0x07800-0x1FFFF  LZSS-compressed ROM disk (~100KB)
 *
 * RAM layout (4MB at 0x02000000-0x023FFFFF):
 *   0x02000000-0x020003FF  Exception vectors (VBR points here)
 *   0x02000400-0x020017FF  BIOS (copied from ROM)
 *   0x02001800-0x020077FF  CCP+BDOS (copied from ROM, runs here)
 *   0x02007800-0x0204FFFF  Decompressed ROM disk in RAM (~312KB)
 *   0x02050000-0x023EFFFF  TPA (~3.6MB)
 *   0x023F0000-0x023FFFFF  Supervisor stack (64KB)
 *
 * Console: Z8530 Channel B (TxDB pin 19, RxDB pin 22), 9600 8N1
 *
 * ROM disk: LZSS-compressed in ROM, decompressed to RAM at boot.
 *   94 tracks, 26 sectors/track, 128 bytes/sector, 2KB blocks
 *
 * EPROM layout: 1 bank x 4 EPROMs (AM27C256, 32KB each) = 4 EPROMs
 */

    .text
    .even

/*==========================================================================
 * Constants
 *==========================================================================*/

    /* ROM addresses */
    .equ BIOS_ROM,      0x00000400  /* BIOS code in ROM */
    .equ CCP_LMA,       0x00001800  /* CCP+BDOS load address in ROM */
    .equ LZSS_ROM,      0x00007800  /* Compressed ROM disk in ROM */

    /* RAM addresses (4MB: 0x02000000-0x023FFFFF) */
    .equ RAM_BASE,      0x02000000
    .equ BIOS_RAM,      0x02000400  /* BIOS runs here */
    .equ CCP_VMA,       0x02001800  /* CCP+BDOS runs here */
    .equ RAMDISK_BASE,  0x02007800  /* Decompressed ROM disk in RAM */
    .equ TPA_BASE,      0x02050000  /* TPA starts after RAM disk */
    .equ TPA_END,       0x023F0000  /* TPA ends here (~3.6MB) */
    .equ SSP_TOP,       0x02400000  /* Supervisor stack top (end of 4MB) */

    /* ROM-to-RAM delta */
    .equ ROM_RAM_DELTA, 0x02000000  /* RAM addr = ROM addr + delta */

    /* Sizes */
    .equ BIOS_SIZE,     0x1400      /* 5KB for BIOS code+data */
    .equ CCP_SIZE,      0x6000      /* 24KB for CCP+BDOS */

    /* Z8530 SCC - compact layout at 0x07000000 */
    .equ SCC_BCTL,      0x07000000  /* Channel B control */
    .equ SCC_BDAT,      0x07000001  /* Channel B data */
    .equ SCC_RESET,     0x07000020  /* Hardware reset strobe */

    /* CP/M disk parameters (ROM disk, same as gas68kcpm) */
    .equ SPT,           26
    .equ BSH,           4           /* 2KB blocks: 2^4 = 16 sectors/block */
    .equ BLM,           15          /* 2^BSH - 1 */
    .equ EXM,           1           /* DSM<256, BLS/1024 - 1 */
    .equ DSM,           148         /* (94-2)*26*128/2048 - 1 */
    .equ DRM,           127         /* 128 directory entries */
    .equ OFF,           2           /* 2 reserved tracks */

    /* LZSS parameters */
    .equ LZSS_MIN_MATCH, 3

/*==========================================================================
 * Vector table at ROM 0x00000
 *==========================================================================*/

vectors:
    .long   SSP_TOP                         /* 000: Initial SSP */
    .long   preloader                       /* 004: Reset PC -> preloader (ROM) */
    .long   exc_buserror + ROM_RAM_DELTA    /* 008: Bus error */
    .long   exc_buserror + ROM_RAM_DELTA    /* 00C: Address error */
    .long   exc_generic + ROM_RAM_DELTA     /* 010: Illegal instruction */
    .long   exc_generic + ROM_RAM_DELTA     /* 014: Zero divide */
    .long   exc_generic + ROM_RAM_DELTA     /* 018: CHK */
    .long   exc_generic + ROM_RAM_DELTA     /* 01C: TRAPV */
    .long   exc_generic + ROM_RAM_DELTA     /* 020: Privilege violation */
    .long   exc_generic + ROM_RAM_DELTA     /* 024: Trace */
    .long   exc_generic + ROM_RAM_DELTA     /* 028: Line 1010 */
    .long   exc_generic + ROM_RAM_DELTA     /* 02C: Line 1111 */
    .rept 3
    .long   exc_generic + ROM_RAM_DELTA     /* 030-038: Reserved */
    .endr
    .long   exc_generic + ROM_RAM_DELTA     /* 03C: Uninitialized interrupt */
    .rept 8
    .long   exc_generic + ROM_RAM_DELTA     /* 040-05C: Reserved */
    .endr
    .long   exc_generic + ROM_RAM_DELTA     /* 060: Spurious interrupt */
    .long   exc_generic + ROM_RAM_DELTA     /* 064: Level 1 autovector */
    .long   exc_generic + ROM_RAM_DELTA     /* 068: Level 2 autovector */
    .long   exc_generic + ROM_RAM_DELTA     /* 06C: Level 3 autovector */
    .long   exc_generic + ROM_RAM_DELTA     /* 070: Level 4 autovector */
    .long   exc_generic + ROM_RAM_DELTA     /* 074: Level 5 autovector */
    .long   exc_generic + ROM_RAM_DELTA     /* 078: Level 6 autovector */
    .long   exc_generic + ROM_RAM_DELTA     /* 07C: Level 7 (NMI) */

    /* TRAP #0-#1: unused */
    .long   exc_generic + ROM_RAM_DELTA     /* 080: TRAP #0 */
    .long   exc_generic + ROM_RAM_DELTA     /* 084: TRAP #1 */
    .long   trap2_dispatch_rom              /* 088: TRAP #2 (BDOS) - ROM stub */
    .long   traphndl + ROM_RAM_DELTA        /* 08C: TRAP #3 (BIOS dispatch) */

    /* TRAP #4-#15 */
    .rept 12
    .long   exc_generic + ROM_RAM_DELTA
    .endr

    /* Vectors 48-63 */
    .rept 16
    .long   exc_generic + ROM_RAM_DELTA
    .endr

    /* Vectors 64-255: fill remainder */
    .rept 192
    .long   exc_generic + ROM_RAM_DELTA
    .endr

/*==========================================================================
 * Preloader - runs from ROM, copies BIOS+CCP to RAM, decompresses disk
 *==========================================================================*/
    .org    0x400

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

    /* Copy vector table from ROM to RAM (for VBR relocation) */
    lea     0, %a0
    lea     RAM_BASE, %a1
    move.w  #255, %d0
.Lcpvec:
    move.l  (%a0)+, (%a1)+
    dbf     %d0, .Lcpvec

    /* Decompress ROM disk: LZSS_ROM -> RAMDISK_BASE */
    lea     LZSS_ROM, %a0          /* compressed source in ROM */
    lea     RAMDISK_BASE, %a1      /* decompressed destination in RAM */
    bsr     lzss_decompress

    /* Jump to BIOS _start in RAM */
    jmp     (_start + ROM_RAM_DELTA)

.Lcopy:
    lsr.l   #2, %d0             /* byte count -> longword count */
    subq.l  #1, %d0
.Lcopy_loop:
    move.l  (%a0)+, (%a1)+
    dbf     %d0, .Lcopy_loop
    subi.l  #0x10000, %d0
    bcc.s   .Lcopy_loop
    rts

/*==========================================================================
 * LZSS Decompressor
 *
 * Input:  A0 = compressed data (4-byte header + stream)
 *         A1 = output buffer
 * Format: First 4 bytes = uncompressed size (big-endian)
 *         Then groups of: 1 flag byte + 8 items
 *         Flag bit 1 = literal (1 byte)
 *         Flag bit 0 = match (2 bytes: length<<4 | offset_hi, offset_lo)
 *           offset = 12-bit (1-4096), length = 4-bit + 3 (3-18)
 *
 * Clobbers: D0-D5, A0-A2
 *==========================================================================*/
lzss_decompress:
    move.l  (%a0)+, %d4         /* D4 = uncompressed size */
    movea.l %a1, %a2            /* A2 = output start (for offset calc) */
    adda.l  %d4, %a2            /* A2 = output end */

.Llz_group:
    cmpa.l  %a2, %a1            /* reached end? */
    bge.s   .Llz_done
    clr.l   %d0
    move.b  (%a0)+, %d0         /* D0 = flag byte */
    moveq   #0, %d5             /* D5 = bit counter 0..7 */

.Llz_item:
    cmpa.l  %a2, %a1
    bge.s   .Llz_done
    btst    %d5, %d0            /* test flag bit (bit 0 first) */
    beq.s   .Llz_match

    /* Literal byte */
    move.b  (%a0)+, (%a1)+
    bra.s   .Llz_next

.Llz_match:
    /* Match reference: 2 bytes */
    clr.l   %d1
    move.b  (%a0)+, %d1         /* D1 = length<<4 | offset_hi */
    clr.l   %d2
    move.b  (%a0)+, %d2         /* D2 = offset_lo */

    /* Extract length: top 4 bits of D1 + MIN_MATCH */
    move.l  %d1, %d3
    lsr.l   #4, %d3
    addq.l  #LZSS_MIN_MATCH, %d3  /* D3 = match length (3-18) */

    /* Extract offset: bottom 4 bits of D1 << 8 | D2, then +1 */
    andi.l  #0x0F, %d1
    lsl.l   #8, %d1
    or.l    %d2, %d1
    addq.l  #1, %d1             /* D1 = offset (1-4096) */

    /* Copy from (output - offset) */
    movea.l %a1, %a3
    suba.l  %d1, %a3            /* A3 = source (can't use A3 directly, use manual loop) */
    subq.l  #1, %d3
.Llz_copy:
    move.b  (%a3)+, (%a1)+
    dbf     %d3, .Llz_copy

.Llz_next:
    addq.l  #1, %d5
    cmpi.l  #8, %d5
    blt.s   .Llz_item
    bra.s   .Llz_group

.Llz_done:
    rts

/*==========================================================================
 * TRAP #2 ROM stub -- redirects to RAM BDOS handler
 *==========================================================================*/
    .even
trap2_dispatch_rom:
    move.l  (active_bdos_entry + ROM_RAM_DELTA), -(%sp)
    rts

/*==========================================================================
 * BIOS code - copied to RAM 0x02000400, runs from there
 *==========================================================================*/

    .even
_start:
    move.w  #0x2700, %sr
    lea     SSP_TOP, %sp

    /* Set VBR to RAM (vectors already copied by preloader) */
    lea     RAM_BASE, %a0
    movec   %a0, %vbr

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

    /* Clear disk state */
    lea     disk_state(%pc), %a0
    moveq   #11, %d0
.Lclr:  clr.b   (%a0)+
    dbf     %d0, .Lclr

    /* Jump to CCP cold boot */
    jmp     cpm

/*==========================================================================
 * Exception handlers
 *==========================================================================*/
    .even
exc_generic:
    rte

exc_buserror:
    move.w  #0x2700, %sr
    addq.l  #8, %sp
    rte

/*==========================================================================
 * TRAP #3 handler -- BIOS function dispatch
 *==========================================================================*/
    .even
traphndl:
    lea     biosbase(%pc), %a0
    andi.l  #0xFF, %d0
    cmpi    #nfuncs, %d0
    bcc.s   trapng
    lsl     #2, %d0
    move.l  (%a0,%d0), %a0
    jsr     (%a0)
trapng:
    rte

/*==========================================================================
 * BIOS Function 0: _init
 *==========================================================================*/
    .even
    .globl _init
_init:
    clr.l   %d0
    rts

/*==========================================================================
 * BIOS function table (biosbase)
 *==========================================================================*/
    .even
biosbase:
    .long   _init + ROM_RAM_DELTA       /* 0 */
    .long   wboot + ROM_RAM_DELTA       /* 1 */
    .long   coninstat + ROM_RAM_DELTA   /* 2 */
    .long   conin + ROM_RAM_DELTA       /* 3 */
    .long   conout + ROM_RAM_DELTA      /* 4 */
    .long   lstout + ROM_RAM_DELTA      /* 5 */
    .long   auxout + ROM_RAM_DELTA      /* 6 */
    .long   auxin + ROM_RAM_DELTA       /* 7 */
    .long   home + ROM_RAM_DELTA        /* 8 */
    .long   seldsk + ROM_RAM_DELTA      /* 9 */
    .long   settrk + ROM_RAM_DELTA      /* 10 */
    .long   setsec + ROM_RAM_DELTA      /* 11 */
    .long   setdma + ROM_RAM_DELTA      /* 12 */
    .long   read + ROM_RAM_DELTA        /* 13 */
    .long   write + ROM_RAM_DELTA       /* 14 */
    .long   lststat + ROM_RAM_DELTA     /* 15 */
    .long   sectran + ROM_RAM_DELTA     /* 16 */
    .long   conoutstat + ROM_RAM_DELTA  /* 17 */
    .long   getseg + ROM_RAM_DELTA      /* 18 */
    .long   getiob + ROM_RAM_DELTA      /* 19 */
    .long   setiob + ROM_RAM_DELTA      /* 20 */
    .long   flush + ROM_RAM_DELTA       /* 21 */
    .long   setexc + ROM_RAM_DELTA      /* 22 */
    .long   auxinstat + ROM_RAM_DELTA   /* 23 */
    .long   auxoutstat + ROM_RAM_DELTA  /* 24 */

.equ nfuncs, (. - biosbase) / 4

/*==========================================================================
 * Warm boot
 *==========================================================================*/
    .even
wboot:
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

conoutstat:
    moveq   #-1, %d0
    rts

lstout:
lststat:
auxout:
auxoutstat:
    rts
auxin:
auxinstat:
    clr.l   %d0
    rts

/*==========================================================================
 * String output (address in A0)
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
    lea     memrgn(%pc), %a0
    move.l  %a0, %d0
    rts

setexc:
    andi.l  #0xFF, %d1
    cmpi.w  #0x23, %d1
    beq.s   .Lsetexc_readonly
    lsl.l   #2, %d1
    addi.l  #RAM_BASE, %d1
    movea.l %d1, %a0
    move.l  (%a0), %d0
    move.l  %d2, (%a0)
    rts
.Lsetexc_readonly:
    lsl.l   #2, %d1
    addi.l  #RAM_BASE, %d1
    movea.l %d1, %a0
    move.l  (%a0), %d0
    rts

getiob:
    move.w  iobyte(%pc), %d0
    rts

setiob:
    lea     iobyte(%pc), %a0
    move.w  %d1, (%a0)
    rts

flush:
    clr.l   %d0
    rts

/*==========================================================================
 * Disk I/O - reads from decompressed RAM disk at RAMDISK_BASE
 *==========================================================================*/
    .even
home:
    lea     disk_state(%pc), %a0
    clr.w   (%a0)
    rts

seldsk:
    andi.l  #0xF, %d1
    bne.s   .Lseldsk_bad
    lea     disk_state(%pc), %a0
    move.w  %d1, 4(%a0)
    lea     dph0(%pc), %a0
    move.l  %a0, %d0
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
    clr.l   %d0
    movea.l %d2, %a0
    ext.l   %d1
    tst.l   %d2
    beq.s   .Lnotran
    asl     #1, %d1
    move.w  (%a0,%d1), %d0
    rts
.Lnotran:
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

    /* Source: decompressed RAM disk */
    lea     RAMDISK_BASE, %a1
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
    /* Compute byte offset: (track * SPT + sector) * 128 */
    movea.l 4(%sp), %a0
    clr.l   %d0
    move.w  (%a0), %d0
    mulu    #SPT, %d0
    clr.l   %d1
    move.w  2(%a0), %d1
    add.l   %d1, %d0
    lsl.l   #7, %d0

    /* Destination: decompressed RAM disk */
    lea     RAMDISK_BASE, %a1
    adda.l  %d0, %a1

    /* Source: DMA address */
    movea.l 8(%a0), %a0

    moveq   #31, %d0
.Lwrite128:
    move.l  (%a0)+, (%a1)+
    dbf     %d0, .Lwrite128

    clr.l   %d0
    rts

/*==========================================================================
 * Data tables
 *==========================================================================*/
    .even

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

    .even
dph0:
    .long   xlt0 + ROM_RAM_DELTA            /* XLT: sector translate table */
    .word   0, 0, 0                         /* hiwater, dum1, dum2 */
    .long   dirbuf + ROM_RAM_DELTA          /* directory buffer (RAM) */
    .long   dpb0 + ROM_RAM_DELTA            /* DPB pointer (RAM) */
    .long   ckv0 + ROM_RAM_DELTA            /* check vector (RAM) */
    .long   alv0 + ROM_RAM_DELTA            /* allocation vector (RAM) */

xlt0:
    .word   0,6,12,18,24,4,10,16,22,2,8,14,20
    .word   1,7,13,19,25,5,11,17,23,3,9,15,21

memrgn:
    .word   0
    .long   TPA_BASE
    .long   TPA_END - TPA_BASE

dpb0:
    .word   SPT
    .byte   BSH
    .byte   BLM
    .byte   EXM
    .byte   0
    .word   DSM
    .word   DRM
    .word   0
    .word   32
    .word   OFF

banner:
    .ascii  "\r\n\r\n"
    .ascii  "Agfa CP/M-68K v1.6 (4MB)\r\n"
    .asciz  "9600 8N1\r\n\r\n"

/*==========================================================================
 * BSS
 *==========================================================================*/
    .even
disk_state:     .space  12
dirbuf:         .space  128
ckv0:           .space  32
alv0:           .space  ((DSM / 4) + 2)
active_bdos_entry:
    .long   0
iobyte:
    .word   0

    .even
bios_end:
