/*
 * vera.h -- Commander X16 VERA video/audio module emulation
 *
 * Ported from the Commander X16 Emulator (x16-emulator)
 * Original Copyright (c) 2019 Michael Steil
 * Original Copyright (c) 2020 Frank van den Hoef
 * All rights reserved. License: 2-clause BSD
 *
 * VERA (Versatile Embedded Retro Adapter) provides:
 *   - 128KB VRAM
 *   - Two tile/bitmap layers + 128 sprites
 *   - 256-color palette (12-bit RGB)
 *   - 16-channel PSG + PCM audio with FIFO
 *   - SPI controller for SD card
 *   - FX extensions (line draw, polygon fill, affine, cache, multiplier)
 *
 * On the Agfa 9000PS, VERA replaces VIA #2 at 0x04000020-0x0400003F
 * (32 registers via A0-A4 address lines).
 *
 * Register map ($00-$1F):
 *   $00  ADDRx_L    VRAM address bits 7:0
 *   $01  ADDRx_M    VRAM address bits 15:8
 *   $02  ADDRx_H    Increment[7:4], NIBBLE[2:1], VRAM[16]
 *   $03  DATA0      VRAM data port 0 (auto-increment on access)
 *   $04  DATA1      VRAM data port 1 (auto-increment on access)
 *   $05  CTRL       RESET[7], DCSEL[6:1], ADDRSEL[0]
 *   $06  IEN        IRQ enables: VSYNC[0], LINE[1], SPRCOL[2], AFLOW[3]
 *   $07  ISR        IRQ status (write 1 to clear)
 *   $08  IRQLINE_L  Scanline for LINE IRQ (low 8 bits) / read: current scanline
 *   $09  DC_VIDEO   (DCSEL=0) or FX/position regs (DCSEL=2-6)
 *   $0A  DC_HSCALE  (DCSEL=0) or FX regs
 *   $0B  DC_VSCALE  (DCSEL=0) or FX regs
 *   $0C  DC_BORDER  (DCSEL=0) or FX regs
 *   $0D-$13  L0_*   Layer 0 config/scroll
 *   $14-$1A  L1_*   Layer 1 config/scroll
 *   $1B  AUDIO_CTRL PCM control
 *   $1C  AUDIO_RATE PCM sample rate
 *   $1D  AUDIO_DATA Audio FIFO (write-only)
 *   $1E  SPI_DATA   SPI transfer
 *   $1F  SPI_CTRL   SPI control
 */

#ifndef VERA_H
#define VERA_H

#include <stdint.h>
#include <stdbool.h>

/* VRAM size */
#define VERA_VRAM_SIZE  (128 * 1024)

/* Display dimensions */
#define VERA_SCREEN_W   640
#define VERA_SCREEN_H   480

/* Register offsets (from base address) */
#define VERA_ADDR_L       0x00
#define VERA_ADDR_M       0x01
#define VERA_ADDR_H       0x02
#define VERA_DATA0        0x03
#define VERA_DATA1        0x04
#define VERA_CTRL         0x05
#define VERA_IEN          0x06
#define VERA_ISR          0x07
#define VERA_IRQLINE_L    0x08
#define VERA_DC_VIDEO     0x09
#define VERA_DC_HSCALE    0x0A
#define VERA_DC_VSCALE    0x0B
#define VERA_DC_BORDER    0x0C
#define VERA_L0_CONFIG    0x0D
#define VERA_L0_MAPBASE   0x0E
#define VERA_L0_TILEBASE  0x0F
#define VERA_L0_HSCROLL_L 0x10
#define VERA_L0_HSCROLL_H 0x11
#define VERA_L0_VSCROLL_L 0x12
#define VERA_L0_VSCROLL_H 0x13
#define VERA_L1_CONFIG    0x14
#define VERA_L1_MAPBASE   0x15
#define VERA_L1_TILEBASE  0x16
#define VERA_L1_HSCROLL_L 0x17
#define VERA_L1_HSCROLL_H 0x18
#define VERA_L1_VSCROLL_L 0x19
#define VERA_L1_VSCROLL_H 0x1A
#define VERA_AUDIO_CTRL   0x1B
#define VERA_AUDIO_RATE   0x1C
#define VERA_AUDIO_DATA   0x1D
#define VERA_SPI_DATA     0x1E
#define VERA_SPI_CTRL     0x1F

/* IEN/ISR bits */
#define VERA_IRQ_VSYNC  0x01
#define VERA_IRQ_LINE   0x02
#define VERA_IRQ_SPRCOL 0x04
#define VERA_IRQ_AFLOW  0x08

typedef struct vera {
    /* Framebuffer for SDL display (0x00RRGGBB / SDL_PIXELFORMAT_RGB888) */
    uint32_t *framebuffer;

    /* Frame counter (incremented on vsync) */
    int frame_count;

    /* IRQ output state */
    int irq_out;
} vera_t;

/* Initialize VERA to power-on state */
void vera_init(vera_t *v);

/* Read a VERA register ($00-$1F) */
uint8_t vera_read(vera_t *v, int reg);

/* Write a VERA register ($00-$1F) */
void vera_write(vera_t *v, int reg, uint8_t val);

/* Advance by N CPU cycles. Generates scanlines, vsync IRQs.
 * Returns nonzero if IRQ line should be asserted. */
int vera_tick(vera_t *v, int cycles);

/* Render current frame to framebuffer (call once per vsync) */
void vera_render_frame(vera_t *v);

/* Set SDL output sample rate so APU ticks at native 48828 Hz internally */
void vera_set_output_rate(int sdl_rate);

/* Check if IRQ is active */
int vera_irq_active(vera_t *v);

#endif
