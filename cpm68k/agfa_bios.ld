/* BIOS linker script: linked at address 0 (ROM), runs from ROM initially */
SECTIONS { .text 0 : { *(.text) *(.rodata) *(.data) *(.bss) } }
