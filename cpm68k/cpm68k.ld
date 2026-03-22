/*
 * cpm68k.ld - CP/M-68K linker script for Agfa 9000PS (ROM version)
 *
 * BIOS is linked at ROM address 0x400 (LMA), runs from RAM 0x02000400 (VMA).
 * CCP+BDOS linked at ROM 0x1800 (LMA), runs from RAM 0x02001800 (VMA).
 * The preloader copies both to RAM before executing.
 *
 * _init is the BIOS function table at a fixed RAM address.
 */

_init = 0x020004f8;

MEMORY
{
    rom  (rx)  : ORIGIN = 0x00000000, LENGTH = 128K
    ram  (rwx) : ORIGIN = 0x02000400, LENGTH = 60K
}

SECTIONS
{
    /* Vector table + preloader in ROM (stays in ROM, not copied) */
    .vectors 0x00000000 :
    {
        agfa_bios.o(.text)
    } > rom

    /* CCP+BDOS: stored in ROM at 0x1800, runs in RAM at 0x02001800 */
    .text 0x02001800 : AT(0x1800)
    {
        *(.text)
        *(.text.*)
        *(.rodata)
        *(.rodata.*)
    } > ram

    .data : AT(ADDR(.data) - 0x02000000)
    {
        *(.data)
    } > ram

    .bss :
    {
        *(.bss)
        *(COMMON)
    } > ram
}
