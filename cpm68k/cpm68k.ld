/*
 * cpm68k.ld - CP/M-68K linker script for Agfa 9000PS
 *
 * Single-user, everything runs from RAM.
 * BIOS at 0x02000400, CCP+BDOS at 0x02001000.
 * _init points to the BIOS function table.
 */

_init = 0x020004f8;

MEMORY
{
    ram (rwx) : ORIGIN = 0x02000400, LENGTH = 0x3FC00
}

SECTIONS
{
    /* BIOS comes first (agfa_bios.o) */
    .bios 0x02000400 :
    {
        agfa_bios.o(.text)
        agfa_bios.o(.rodata)
        agfa_bios.o(.data)
        agfa_bios.o(.bss)
    } > ram

    /* CCP + BDOS at 0x02001000 */
    .text 0x02001000 :
    {
        *(.text)
        *(.text.*)
        *(.rodata)
        *(.rodata.*)
    } > ram

    .data :
    {
        *(.data)
    } > ram

    .bss :
    {
        *(.bss)
        *(COMMON)
    } > ram
}
