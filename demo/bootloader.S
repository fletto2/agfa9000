/*
 * bootloader.S -- Minimal S-record bootloader for Agfa 9000PS
 *
 * Replaces bank 0 ROM. Accepts Motorola S-records on SCC Channel A
 * (TxDA pin 15, 9600 8N2) and executes them.
 *
 * Usage:
 *   1. Burn this into the 4 EPROMs for bank 0
 *   2. Connect serial terminal to pin 15 (TxDA) at 9600 8N2
 *   3. Power on -- you'll see the "AGFA BOOT>" prompt
 *   4. Type 'S' to enter S-record upload mode
 *   5. Paste/send your .s28 file
 *   6. Type 'G' to execute (runs from the S7/S9 start address)
 *   7. Or type 'G addr' to execute at a specific hex address
 *
 * Commands:
 *   S  - Enter S-record upload mode (send .s28 file)
 *   G  - Execute loaded program (at S7/S9 address or last 'G addr')
 *   D  - Dump 256 bytes at current address
 *   R  - Reset (warm boot)
 *   ?  - Help
 *
 * Build:
 *   m68k-elf-as -m68020 -o bootloader.o bootloader.S
 *   m68k-elf-ld -Ttext=0x00000000 -nostdlib -o bootloader.elf bootloader.o
 *   m68k-elf-objcopy -O binary bootloader.elf bootloader.bin
 *   # Then split bootloader.bin into 4 interleaved EPROMs (HH/HM/LM/LL)
 */

/* Macro for inline single-char output */
.macro scc_putc_imm char
    move.b  #\char, %d0
    bsr     putc
.endm

    .text
    .even

/* ================================================================== */
/* Exception vectors                                                  */
/* ================================================================== */
    .long   0x0200F000          /* 000: Initial SSP */
    .long   cold_start          /* 004: Reset PC */
    .long   fault_handler       /* 008: Bus Error */
    .long   fault_handler       /* 00C: Address Error */
    .long   fault_handler       /* 010: Illegal Instruction */
    .long   fault_handler       /* 014: Zero Divide */
    .long   fault_handler       /* 018: CHK */
    .long   fault_handler       /* 01C: TRAPV */
    .long   fault_handler       /* 020: Privilege Violation */
    .long   fault_handler       /* 024: Trace */
    .long   fault_handler       /* 028: Line 1010 */
    .long   fault_handler       /* 02C: Line 1111 */
    /* Fill remaining vectors with fault handler */
    .rept   52
    .long   fault_handler
    .endr

/* ================================================================== */
/* Cold start                                                         */
/* ================================================================== */
    .even
cold_start:
    move.w  #0x2700, %sr        /* Supervisor, all IRQs masked */
    lea     0x0200F000, %sp     /* Stack in low RAM */

    /* Hardware reset strobe */
    tst.b   0x07000020
    moveq   #20, %d0
.Lcs_dly:
    subq.l  #1, %d0
    bgt.s   .Lcs_dly

    /* Init SCC Channel A: 9600 8N2 */
    lea     0x07000002, %a0
    lea     scc_tab(%pc), %a1
    moveq   #20, %d0
.Lcs_scc:
    move.l  (%sp), (%sp)
    move.l  (%sp), (%sp)
    move.b  (%a1)+, (%a0)
    dbf     %d0, .Lcs_scc

    /* Clear exec address */
    clr.l   exec_addr

    /* Print banner */
    lea     str_banner(%pc), %a0
    bsr     puts

    /* Fall into command loop */

/* ================================================================== */
/* Command loop                                                       */
/* ================================================================== */
cmd_loop:
    lea     str_prompt(%pc), %a0
    bsr     puts

    bsr     getc                /* Read command char */
    bsr     putc                /* Echo it */

    cmp.b   #'S', %d0
    beq     cmd_srec
    cmp.b   #'s', %d0
    beq     cmd_srec
    cmp.b   #'G', %d0
    beq     cmd_go
    cmp.b   #'g', %d0
    beq     cmd_go
    cmp.b   #'D', %d0
    beq     cmd_dump
    cmp.b   #'d', %d0
    beq     cmd_dump
    cmp.b   #'R', %d0
    beq     cold_start
    cmp.b   #'r', %d0
    beq     cold_start
    cmp.b   #'?', %d0
    beq     cmd_help

    lea     str_crlf(%pc), %a0
    bsr     puts
    bra     cmd_loop

/* ================================================================== */
/* S-record loader                                                    */
/* ================================================================== */
cmd_srec:
    lea     str_srec_start(%pc), %a0
    bsr     puts

.Lsr_line:
    bsr     getc                /* Wait for 'S' */
    cmp.b   #'S', %d0
    bne     .Lsr_skip_line
    bsr     getc                /* Record type digit */
    move.b  %d0, %d7            /* D7 = type ('0'-'9') */
    sub.b   #'0', %d7

    /* Read byte count */
    bsr     read_hex_byte       /* D0 = byte count */
    move.l  %d0, %d6            /* D6 = remaining bytes */
    move.b  %d0, %d5            /* D5 = checksum accumulator */

    /* Read address based on type */
    cmp.b   #1, %d7
    beq     .Lsr_addr2
    cmp.b   #9, %d7
    beq     .Lsr_addr2
    cmp.b   #2, %d7
    beq     .Lsr_addr3
    cmp.b   #8, %d7
    beq     .Lsr_addr3
    cmp.b   #3, %d7
    beq     .Lsr_addr4
    cmp.b   #7, %d7
    beq     .Lsr_addr4
    bra     .Lsr_skip_line      /* S0, S4, S5, S6 -- skip */

.Lsr_addr2:                     /* 16-bit address */
    bsr     read_hex_byte
    add.b   %d0, %d5
    move.l  %d0, %a2
    lsl.l   #8, %d0
    bsr     read_hex_byte
    add.b   %d0, %d5
    or.b    %d0, %d0            /* can't or into An */
    move.l  %a2, %d1
    lsl.l   #8, %d1
    or.l    %d0, %d1
    move.l  %d1, %a2
    subq.l  #3, %d6             /* addr used 2 bytes + 1 checksum */
    bra.s   .Lsr_data

.Lsr_addr3:                     /* 24-bit address */
    bsr     read_hex_byte
    add.b   %d0, %d5
    move.l  %d0, %d1
    lsl.l   #8, %d1
    bsr     read_hex_byte
    add.b   %d0, %d5
    or.l    %d0, %d1
    lsl.l   #8, %d1
    bsr     read_hex_byte
    add.b   %d0, %d5
    or.l    %d0, %d1
    move.l  %d1, %a2
    subq.l  #4, %d6             /* addr used 3 bytes + 1 checksum */
    bra.s   .Lsr_data

.Lsr_addr4:                     /* 32-bit address */
    bsr     read_hex_byte
    add.b   %d0, %d5
    move.l  %d0, %d1
    lsl.l   #8, %d1
    bsr     read_hex_byte
    add.b   %d0, %d5
    or.l    %d0, %d1
    lsl.l   #8, %d1
    bsr     read_hex_byte
    add.b   %d0, %d5
    or.l    %d0, %d1
    lsl.l   #8, %d1
    bsr     read_hex_byte
    add.b   %d0, %d5
    or.l    %d0, %d1
    move.l  %d1, %a2
    subq.l  #5, %d6             /* addr used 4 bytes + 1 checksum */

.Lsr_data:
    /* Check for end records (S7/S8/S9) */
    cmp.b   #7, %d7
    bge.s   .Lsr_end_rec

    /* Read data bytes */
    subq.l  #1, %d6             /* don't count checksum byte */
    ble.s   .Lsr_chk
.Lsr_dbyte:
    bsr     read_hex_byte
    add.b   %d0, %d5
    move.b  %d0, (%a2)+
    subq.l  #1, %d6
    bgt.s   .Lsr_dbyte

.Lsr_chk:
    /* Read and verify checksum */
    bsr     read_hex_byte
    add.b   %d0, %d5
    cmp.b   #0xFF, %d5
    beq.s   .Lsr_ok
    scc_putc_imm '#'            /* Checksum error marker */
    bra     .Lsr_line

.Lsr_ok:
    scc_putc_imm '.'            /* Progress dot */
    bra     .Lsr_line

.Lsr_end_rec:
    /* S7/S8/S9: store execution address */
    move.l  %a2, exec_addr
    lea     str_srec_done(%pc), %a0
    bsr     puts
    bra     cmd_loop

.Lsr_skip_line:
    /* Skip to end of line */
    cmp.b   #10, %d0
    beq     .Lsr_line
    cmp.b   #13, %d0
    beq     .Lsr_line
    bsr     getc
    bra.s   .Lsr_skip_line

/* ================================================================== */
/* Go (execute)                                                       */
/* ================================================================== */
cmd_go:
    /* Try to read optional hex address */
    bsr     skip_spaces
    cmp.b   #13, %d0
    beq.s   .Lgo_default
    cmp.b   #10, %d0
    beq.s   .Lgo_default

    /* Read hex address */
    bsr     read_hex_long
    move.l  %d0, exec_addr

.Lgo_default:
    move.l  exec_addr, %d0
    tst.l   %d0
    beq.s   .Lgo_noaddr

    lea     str_go(%pc), %a0
    bsr     puts
    move.l  %d0, %a0
    bsr     print_hex_long
    lea     str_crlf(%pc), %a0
    bsr     puts

    move.l  exec_addr, %a0
    jmp     (%a0)               /* Jump to loaded program */

.Lgo_noaddr:
    lea     str_noaddr(%pc), %a0
    bsr     puts
    bra     cmd_loop

/* ================================================================== */
/* Hex dump                                                           */
/* ================================================================== */
cmd_dump:
    bsr     skip_spaces
    cmp.b   #13, %d0
    beq.s   .Ld_def
    cmp.b   #10, %d0
    beq.s   .Ld_def
    bsr     read_hex_long
    move.l  %d0, dump_addr
.Ld_def:
    lea     str_crlf(%pc), %a0
    bsr     puts
    move.l  dump_addr, %a2
    moveq   #15, %d7            /* 16 lines */
.Ld_line:
    move.l  %a2, %d0
    bsr     print_hex_long
    scc_putc_imm ':'
    scc_putc_imm ' '
    moveq   #15, %d6            /* 16 bytes per line */
.Ld_byte:
    moveq   #0, %d0
    move.b  (%a2)+, %d0
    bsr     print_hex_byte
    scc_putc_imm ' '
    dbf     %d6, .Ld_byte
    lea     str_crlf(%pc), %a0
    bsr     puts
    dbf     %d7, .Ld_line
    move.l  %a2, dump_addr
    bra     cmd_loop

/* ================================================================== */
/* Help                                                               */
/* ================================================================== */
cmd_help:
    lea     str_help(%pc), %a0
    bsr     puts
    bra     cmd_loop

/* ================================================================== */
/* Fault handler                                                      */
/* ================================================================== */
    .even
fault_handler:
    lea     str_fault(%pc), %a0
    bsr     puts
    bra     cmd_loop

/* ================================================================== */
/* SCC I/O primitives                                                 */
/* ================================================================== */

    .even
putc:
    lea     0x07000002, %a0
.Lpc_wait:
    btst    #2, (%a0)
    beq.s   .Lpc_wait
    move.b  %d0, 1(%a0)
    rts

    .even
getc:
    lea     0x07000002, %a0
.Lgc_wait:
    btst    #0, (%a0)
    beq.s   .Lgc_wait
    moveq   #0, %d0
    move.b  1(%a0), %d0
    rts

    .even
puts:
    /* A0 = string pointer */
    move.l  %a0, -(%sp)
    move.l  %a1, -(%sp)
.Lps_loop:
    move.b  (%a0)+, %d0
    beq.s   .Lps_end
    lea     0x07000002, %a1
.Lps_wait:
    btst    #2, (%a1)
    beq.s   .Lps_wait
    move.b  %d0, 1(%a1)
    bra.s   .Lps_loop
.Lps_end:
    move.l  (%sp)+, %a1
    move.l  (%sp)+, %a0
    rts

/* ================================================================== */
/* Hex I/O helpers                                                    */
/* ================================================================== */

    .even
skip_spaces:
    bsr     getc
    cmp.b   #' ', %d0
    beq.s   skip_spaces
    rts

    .even
read_hex_nibble:
    /* Reads one hex char from serial, returns 0-15 in D0 */
    bsr     getc
    cmp.b   #'0', %d0
    blt.s   .Lrhn_bad
    cmp.b   #'9', %d0
    ble.s   .Lrhn_dig
    or.b    #0x20, %d0          /* to lowercase */
    cmp.b   #'a', %d0
    blt.s   .Lrhn_bad
    cmp.b   #'f', %d0
    bgt.s   .Lrhn_bad
    sub.b   #('a' - 10), %d0
    rts
.Lrhn_dig:
    sub.b   #'0', %d0
    rts
.Lrhn_bad:
    moveq   #0, %d0
    rts

    .even
read_hex_byte:
    /* Returns byte in D0 */
    bsr     read_hex_nibble
    lsl.b   #4, %d0
    move.b  %d0, -(%sp)
    bsr     read_hex_nibble
    or.b    (%sp)+, %d0
    rts

    .even
read_hex_long:
    /* Read up to 8 hex digits, stop on non-hex. Returns in D0. */
    /* First char is already in D0 from skip_spaces */
    moveq   #0, %d1             /* accumulator */
    moveq   #7, %d2             /* max 8 digits */
.Lrhl_loop:
    /* Convert D0 to nibble */
    cmp.b   #'0', %d0
    blt.s   .Lrhl_done
    cmp.b   #'9', %d0
    ble.s   .Lrhl_dig
    or.b    #0x20, %d0
    cmp.b   #'a', %d0
    blt.s   .Lrhl_done
    cmp.b   #'f', %d0
    bgt.s   .Lrhl_done
    sub.b   #('a' - 10), %d0
    bra.s   .Lrhl_acc
.Lrhl_dig:
    sub.b   #'0', %d0
.Lrhl_acc:
    lsl.l   #4, %d1
    or.b    %d0, %d1
    dbf     %d2, .Lrhl_next
    bra.s   .Lrhl_done
.Lrhl_next:
    bsr     getc
    bra.s   .Lrhl_loop
.Lrhl_done:
    move.l  %d1, %d0
    rts

    .even
print_hex_byte:
    /* Print D0.B as 2 hex digits */
    move.l  %d0, -(%sp)
    lsr.b   #4, %d0
    bsr     .Lphn
    move.l  (%sp)+, %d0
    and.b   #0x0F, %d0
    /* fall through */
.Lphn:
    cmp.b   #10, %d0
    blt.s   .Lphn_dig
    add.b   #('A' - 10), %d0
    bra     putc
.Lphn_dig:
    add.b   #'0', %d0
    bra     putc

    .even
print_hex_long:
    /* Print D0.L as 8 hex digits */
    move.l  %d0, -(%sp)
    swap    %d0
    move.l  %d0, -(%sp)
    lsr.w   #8, %d0
    bsr     print_hex_byte
    move.l  (%sp)+, %d0
    bsr     print_hex_byte
    move.l  (%sp), %d0
    lsr.w   #8, %d0
    bsr     print_hex_byte
    move.l  (%sp)+, %d0
    bsr     print_hex_byte
    rts

/* ================================================================== */
/* SCC init table                                                     */
/* ================================================================== */
    .even
scc_tab:
    .byte   0x01, 0x00
    .byte   0x03, 0xC1
    .byte   0x04, 0x4C
    .byte   0x05, 0x6A
    .byte   0x09, 0x0A
    .byte   0x0B, 0x50
    .byte   0x0C, 0x0A
    .byte   0x0D, 0x00
    .byte   0x0E, 0x01
    .byte   0x0F, 0x00
    .byte   0x13

/* ================================================================== */
/* Strings                                                            */
/* ================================================================== */
    .even
str_banner:
    .asciz  "\r\n\r\nAgfa 9000PS Bootloader (Channel A, 9600 8N2)\r\n"
str_prompt:
    .asciz  "\r\nAGFA BOOT> "
str_srec_start:
    .asciz  "\r\nSend S-records now...\r\n"
str_srec_done:
    .asciz  "\r\nUpload complete.\r\n"
str_go:
    .asciz  "\r\nExecuting at 0x"
str_noaddr:
    .asciz  "\r\nNo address set. Use 'S' to upload or 'G <addr>'.\r\n"
str_help:
    .ascii  "\r\nCommands:\r\n"
    .ascii  "  S  Upload S-record file\r\n"
    .ascii  "  G  Execute (or G <hex addr>)\r\n"
    .ascii  "  D  Hex dump (or D <hex addr>)\r\n"
    .ascii  "  R  Reset\r\n"
    .asciz  "  ?  This help\r\n"
str_fault:
    .asciz  "\r\n*** EXCEPTION ***\r\n"
str_crlf:
    .asciz  "\r\n"

/* ================================================================== */
/* BSS (in RAM)                                                       */
/* ================================================================== */
    .bss
    .even
exec_addr:  .long   0
dump_addr:  .long   0
