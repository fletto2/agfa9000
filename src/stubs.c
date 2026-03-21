/*
 * stubs.c -- Stub functions for Musashi FPU (softfloat) and disassembler
 *
 * The Agfa 9000PS has no FPU. The firmware detects this at boot and uses
 * software FPU emulation in bank 4. We only need to provide link stubs
 * so Musashi compiles; FPU instructions will trap as expected.
 */

#include "musashi/m68k.h"

/* Softfloat stubs — FPU instructions will never execute on the Agfa */
typedef struct { unsigned long long low; unsigned short high; } floatx80;
typedef unsigned int float32;
typedef unsigned long long float64;

int float_rounding_mode = 0;

floatx80 int32_to_floatx80(int v) { floatx80 r = {0,0}; return r; }
floatx80 float32_to_floatx80(float32 v) { floatx80 r = {0,0}; return r; }
floatx80 float64_to_floatx80(float64 v) { floatx80 r = {0,0}; return r; }
float32 floatx80_to_float32(floatx80 v) { return 0; }
float64 floatx80_to_float64(floatx80 v) { return 0; }
int floatx80_to_int32(floatx80 v) { return 0; }
int floatx80_to_int32_round_to_zero(floatx80 v) { return 0; }
floatx80 floatx80_add(floatx80 a, floatx80 b) { return a; }
floatx80 floatx80_sub(floatx80 a, floatx80 b) { return a; }
floatx80 floatx80_mul(floatx80 a, floatx80 b) { return a; }
floatx80 floatx80_div(floatx80 a, floatx80 b) { return a; }
floatx80 floatx80_rem(floatx80 a, floatx80 b) { return a; }
floatx80 floatx80_sqrt(floatx80 v) { return v; }
int floatx80_is_nan(floatx80 v) { return 0; }

/* Disassembler read callbacks */
unsigned int m68k_read_disassembler_16(unsigned int addr)
{
    return m68k_read_memory_16(addr);
}

unsigned int m68k_read_disassembler_32(unsigned int addr)
{
    return m68k_read_memory_32(addr);
}
