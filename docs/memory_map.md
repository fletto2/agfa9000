# Memory Map Reference - Agfa Compugraphic 9000PS

## Main Board Address Space

| Address Range | Size | Description |
|---------------|------|-------------|
| `0x00000000 - 0x0009FFFF` | 640KB | ROM (5 banks, 128KB each) |
| `0x02000000 - 0x02FFFFFF` | up to 16MB | RAM (stack starts at 0x0200024C) |
| `0x04000000` | - | SCC #1 (Zilog 8530, IO board communication) |
| `0x05000001` | 8 regs | NCR 5380 SCSI controller (odd byte lane) |
| `0x05000026` | - | SCSI pseudo-DMA data port |
| `0x06080000` | - | Hardware register (cleared during boot) |
| `0x060C0000` | - | Hardware register (cleared during boot) |
| `0x06100000` | - | Display/rendering controller (HW acceleration) |
| `0x07000000` | - | SCC #2 (Zilog 8530, debug console, 9600 8N1) |
| `0x07000020` | - | Hardware status/config register |

## ROM Banks

| Bank | Address Range | Contents |
|------|---------------|----------|
| 0 | `0x00000 - 0x1FFFF` | Atlas Monitor, boot, exceptions, PS string tables |
| 1 | `0x20000 - 0x3FFFF` | Encrypted font data (to 0x3AEB7), SCC comm code (0x3AEB8+) |
| 2 | `0x40000 - 0x5FFFF` | PostScript interpreter: init, operators, graphics, fonts, raster |
| 3 | `0x60000 - 0x7FFFF` | PS interpreter: main loop, math, lexer, file I/O, stacks |
| 4 | `0x80000 - 0x9FFFF` | Filesystem, SCSI driver, C runtime, software FPU |

## RAM Layout (base = 0x02000000)

### System Variables (0x0000 - 0x00FF)

| Offset | Description |
|--------|-------------|
| `0x0000` | RAM size |
| `0x0004` | ROM size (0x01000000) |
| `0x0008` | Base address (0) |
| `0x000C` | Top of RAM pointer |
| `0x0010` | System flags/config |
| `0x0014` | NMI vector pointer |
| `0x0018` | Level 7 interrupt vector pointer |
| `0x003C - 0x005B` | Exception vector redirect table (8 entries) |
| `0x0060` | Saved D0 across warm boot |
| `0x0064` | Hardware base (0x06100000) |
| `0x0068 - 0x007C` | Exception handler hook pointers |
| `0x0080` | FPU present flag |
| `0x00F8` | Current color space |

### Atlas Monitor State (0x0250 - 0x0400)

| Offset | Description |
|--------|-------------|
| `0x0250` | CACR shadow register |
| `0x0254` | Current PC / execution address |
| `0x0284` | Error message string pointer |
| `0x0288 - 0x0289` | Saved interrupt mask bytes (SCC Ch A & B) |
| `0x028A` | Saved Status Register |
| `0x028C` | Saved Program Counter |
| `0x0290 - 0x02C9` | Register save area (D0-D7, A0-A7) |
| `0x02CA - 0x02FF` | Haltpoint table (8 entries x 6 bytes) |
| `0x02D0` | Memory address table |
| `0x0300` | S-record data buffer |
| `0x0400` | Extended RAM area |
| `0x0410` | Saved register set for initialization |

### SCC/DMA State (0x0594+)

| Offset | Description |
|--------|-------------|
| `0x0594 - 0x0598` | SCC DMA state vars |
| `0x09E4` | HW rendering flag |

### Display List (0x12304+)

| Offset | Description |
|--------|-------------|
| `0x12304` | Display list slot array |
| `0x132A4` | Display list free list head |
| `0x132B0` | Display list allocation count |

### PostScript Engine (0x16794+)

| Offset | Description |
|--------|-------------|
| `0x16794` | Pending operation code 1 |
| `0x16798` | Pending operation code 2 |
| `0x1679C` | Pending operation code 3 (codes: -4/-5/-7) |
| `0x167A4` | Loop counter |
| `0x16E94` | LCG random seed |
| `0x16E98` | Free page list (filesystem) |
| `0x16E9C` | SCSI timeout callback pointer |
| `0x16EA0` | SCSI timeout value |
| `0x16EA4` | SCSI timeout mode (1=normal, 2=extended) |
| `0x16EA8` | SCC channel pointer |
| `0x16EAC` | SCSI device table |
| `0x16FD0` | SCSI command queue |
| `0x170FC` | FPU context |

### Heap & Memory Management (0x17144+)

| Offset | Description |
|--------|-------------|
| `0x17144` | SCSI device structure base |
| `0x17210` | SCSI capacity table |
| `0x1732C` | malloc heap start |
| `0x17340` | malloc heap end |
| `0x17354` | Font dictionary hash table |
| `0x173A6` | Stream channel count |
| `0x1741C` | brk pointer (sbrk) |
| `0x17464 + 0x9C` | Gamma range [0.1, 3.2] |
| `0x17528` | Block size info |
| `0x17574` | Heap base pointer |
| `0x175A4` | LRU active head |
| `0x175C4` | Free list pointers |
| `0x175C8` | Current object pointer |
| `0x175CC` | Free list head |

### High RAM (0x22000+)

| Offset | Description |
|--------|-------------|
| `0x221EC` | HW acceleration callback table |
| `0x222C8` | Error handler |
| `0x22310` | System clock |

## Key Entry Points

| Address | Description |
|---------|-------------|
| `0x00856` | Cold boot entry (reset vector PC) |
| `0x00860` | Warm boot entry (D7=0) |
| `0x00868` | Monitor setup (post-RAM detect) |
| `0x01A6E` | RAM detection routine |
| `0x0200C` | PS init thunk (jumps to 0x40508) |
| `0x40508` | PostScript initialization entry |
| `0x40E36` | PostScript main entry |
| `0x46000` | Operator dispatcher (46-entry jump table at 0x46944) |
| `0x480B0` | malloc |
| `0x48208` | free |
| `0x47F50` | coalesce (heap block merge) |
| `0x71334` | Interpreter entry |
| `0x71400` | Main interpreter loop (type dispatch table at 0x71420) |
| `0x85B58` | SCSI device scan |
| `0x85F32` | SCSI init |
| `0x86110` | SCSI bus reset |

## IO Board Address Space

| Address | Description |
|---------|-------------|
| `0x00000 - 0x0FFFF` | ROM (64KB) |
| `0x14000` | RAM (stack) |
| `0x40000` | SCC - PS channel (main board communication) |
| `0x40010` | SCC - Debug port |
| `0x50000` | SCC - ATI to imagesetter |
| `0x172E0` | HW control (baud rate, data bits, flags) |

## NCR 5380 SCSI Registers (at 0x05000001, odd addresses)

| Register | Address | Description |
|----------|---------|-------------|
| 0 | `0x05000001` | Current SCSI Data / Output Data |
| 1 | `0x05000003` | Initiator Command |
| 2 | `0x05000005` | Mode |
| 3 | `0x05000007` | Target Command |
| 4 | `0x05000009` | Current SCSI Bus Status |
| 5 | `0x0500000B` | Bus and Status |
| 6 | `0x0500000D` | Input Data |
| 7 | `0x0500000F` | Reset Parity/Interrupts |
