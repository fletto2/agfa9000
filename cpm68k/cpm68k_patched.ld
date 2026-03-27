/*
 * cpm68k.ld - CP/M-68K CCP+BDOS linker script
 *
 * CCP+BDOS only. BIOS is linked separately at LMA=0.
 * CCP+BDOS: VMA 0x02001800 (RAM), LMA 0x1800 (ROM)
 */

_init = 0x020000045a;

MEMORY
{
    ram (rwx) : ORIGIN = 0x02001800, LENGTH = 0x6000
}

SECTIONS
{
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
