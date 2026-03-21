/*
 * link.ld -- Linker script for Agfa 9000PS bare-metal programs
 *
 * Loads at 0x02001000 (4KB into RAM, above system variables).
 * Stack at 0x0200F000 (60KB mark, well below the bad RAM at 0x02200000).
 *
 * For ROM burning: change ORIGIN to 0x00000000 and LENGTH to 128K.
 */

MEMORY
{
    ram (rwx) : ORIGIN = 0x02010000, LENGTH = 960K
}

SECTIONS
{
    .text : {
        *(.text)
        *(.rodata)
        *(.rodata.*)
    } > ram

    .data : {
        *(.data)
    } > ram

    .bss : {
        _bss_start = .;
        *(.bss)
        *(COMMON)
        _bss_end = .;
    } > ram

    _end = .;
}
