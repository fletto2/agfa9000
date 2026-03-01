# Hardware Details - Agfa Compugraphic 9000PS

## Main Board (RIP)
- **CPU**: Motorola 68020 @ 16MHz (gold ceramic PGA package)
- **ROM**: 20x AM27C256 (32KB each) = 640KB total
  - 4-wide interleave: HH, HM, LM, LL (for 32-bit data bus)
  - 5 banks (0-4), labeled PSATS1TS
  - Combined into 0.bin-4.bin (128KB each)
- **Vector table**: SSP=0x0200024C, PC=0x00000856
- **Board label**: "REVISION II" "87506-502"
- **FPU**: None installed (boot code detects via trace trick; bank 4 has full software FPU)
- **SCSI**: NCR 5380 at 0x05000001 with pseudo-DMA at 0x05000026

## IO Board (ATI - Agfa Typesetter Interface)
- **CPU**: Motorola 68000 @ 8MHz
- **ROM**: 2x AM27C256 (HI=U21, LO=U22) = 64KB combined as io.bin
- **Firmware**: "Agfa T9400PS ATI v2.2" (PSATI++ Rev v2.2 85804-3/4 9-4-90)
- **Vector table**: SSP=0x14000, PC=0x400
- **UART**: MC68681 DUART for serial
- **Debug port**: "Hello, this is the debug port" / "type ATI for normal operation"
- **Debug commands**: MD (dump), MM (modify), GO (execute), LO (S-record), LED, VIDEO, RESOL, INVERS, MODE, RESET, DEBUG, TMD, ATI
- **ATI commands**: Brace-delimited: {SRE%}, {SRC$}, {SRSP}, {SRGP}
- **ATI responses** (15 total): !STA, !L&S, !BEG, !END, !PWR, _GST, _CMD, _INF, _SET, _GET, _MOD, _NEG, _POS, _GPR, _RES (100-104 significant)
- **Device subsystems**: RE (Raster Engine), PA (Paper Advance), DN (Densitometer), MG (Motor/Gantry), SH (Shutter)
- **3 SCCs**: 0x040000 (PS channel), 0x040010 (debug), 0x050000 (ATI to imagesetter)
- **HW control**: 0x172E0 (baud 1200/2400, data bits 7/8, flags)

## Memory Map (Main Board, from disassembly)
| Address Range | Description |
|--------------|-------------|
| 0x00000000 | ROM (vector table + code, 640KB) |
| 0x02000000 | RAM (stack at 0x0200024C, variables) |
| 0x03000000 | End of RAM test range (max 16MB RAM) |
| 0x04000000 | Zilog SCC serial controller (channels A & B) |
| 0x05000001 | NCR 5380 SCSI controller (odd byte lane, 8 regs at odd addrs) |
| 0x05000026 | SCSI pseudo-DMA data port |
| 0x06080000 | Hardware register (cleared during boot) |
| 0x060C0000 | Hardware register (cleared during boot) |
| 0x06100000 | Display/rendering controller (HW acceleration, set 0xFFFFFFFF at boot) |
| 0x07000000 | Zilog SCC #2 (Atlas Monitor debug console, 9600 8N1) |
| 0x07000020 | Hardware status/config register |

## RAM Layout (at 0x02000000+)
| Offset | Description |
|--------|-------------|
| 0x0000 | RAM size |
| 0x0004 | ROM size (0x01000000 = 16MB?) |
| 0x0008 | Base address (0) |
| 0x000C | Top of RAM pointer |
| 0x0010 | System flags/config |
| 0x0014 | NMI vector pointer |
| 0x0018 | Level 7 interrupt vector pointer |
| 0x003C-0x005B | Exception vector redirect table (8 entries) |
| 0x0060 | Saved D0 across warm boot |
| 0x0064 | Hardware base (0x06100000) |
| 0x0068-0x007C | Exception handler hook pointers (bus err, addr err, illegal, etc.) |
| 0x0080 | FPU present flag |
| 0x0250 | CACR shadow register |
| 0x0254 | Current PC / execution address |
| 0x0284 | Error message string pointer |
| 0x0288-0x0289 | Saved interrupt mask bytes for SCC Ch A & B |
| 0x028A | Saved Status Register |
| 0x028C | Saved Program Counter |
| 0x0290-0x02C9 | Register save area (D0-D7, A0-A7 = 64 bytes) |
| 0x02CA-0x02FF | Haltpoint table (8 entries x 6 bytes) |
| 0x0300 | S-record data buffer |
| 0x0400 | Extended RAM area |
| 0x0410 | Saved register set for initialization |
| 0x09E4 | HW rendering flag (checked by 0x589CE-0x58E18) |
| 0x16794 | Pending operation code 1 |
| 0x16798 | Pending operation code 2 |
| 0x1679C | Pending operation code 3 (codes: -4/-5/-7) |
| 0x17144 | SCSI device structure base |
| 0x17210 | SCSI capacity table |
| 0x1732C | malloc heap start |
| 0x17340 | malloc heap end |
| 0x17354 | Font dictionary hash table |
| 0x1741C | brk pointer (sbrk) |
| 0x174 | PS execution context (magic 'A' at offset+4) |
| 0x17528 | Block size info |
| 0x17574 | Heap base pointer |
| 0x175A4 | LRU active head |
| 0x175C4 | Free list pointers |
| 0x175C8 | Current object pointer |
| 0x175CC | Free list head |
| 0x17464+0x9C | Gamma range [0.1, 3.2] |
| 0x167A4 | Loop counter |
| 0x16E94 | LCG random seed |
| 0x16E98 | Free page list (filesystem) |
| 0x16E9C | SCSI timeout callback pointer |
| 0x16EA0 | SCSI timeout value |
| 0x16EA4 | SCSI timeout mode (1=normal, 2=extended) |
| 0x16EA8 | SCC channel pointer |
| 0x08F8 | Current color space |
| 0x0594-0x0598 | SCC DMA state vars |
| 0x12304 | Display list slot array |
| 0x132A4 | Display list free list head |
| 0x132B0 | Display list allocation count |
| 0x221EC | HW acceleration callback table |
| 0x002D0 | Memory address table (v7) |
| 0x16EAC | SCSI device table (v7) |
| 0x16FD0 | SCSI command queue (v7) |
| 0x170FC | FPU context (v7) |
| 0x173A6 | Stream channel count (v7) |
| 0x22310 | System clock (v7) |
| 0x222C8 | Error handler (v7) |

## Hard Drive
- Quantum P40S, 40MB, SCSI
- 82,029 sectors x 512 bytes = 41,998,848 bytes
- Imaged with BlueSCSI in initiator mode (5 bad sectors)
