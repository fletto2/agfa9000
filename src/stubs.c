/*
 * stubs.c -- Minimal stubs for Musashi functions not otherwise provided
 */

#include "musashi/m68k.h"

/* Disassembler read callbacks */
unsigned int m68k_read_disassembler_16(unsigned int addr)
{
    return m68k_read_memory_16(addr);
}

unsigned int m68k_read_disassembler_32(unsigned int addr)
{
    return m68k_read_memory_32(addr);
}
