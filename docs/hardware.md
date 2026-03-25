# Hardware Details - Agfa Compugraphic 9000PS

## Main Board (RIP)
- **CPU**: Motorola 68020 @ 16MHz (gold ceramic PGA package)
- **ROM**: 20x AM27C256 (32KB each) = 640KB total
  - 4-wide interleave: HH, HM, LM, LL (for 32-bit data bus)
  - 5 banks (0-4), labeled PSATS1TS
  - Combined into 0.bin-4.bin (128KB each)
- **RAM**: 4MB SIPP DRAM installed (expandable to 6MB max)
  - Address range: 0x02000000 - 0x023FFFFF (4MB installed)
  - Firmware tests up to 16MB in 1MB increments
- **Vector table**: SSP=0x0200024C, PC=0x00000856
- **Board label**: "REVISION II" "87506-502"
- **Date code**: 1986, Week 45 (November 1986)
- **FPU**: None installed (boot code detects via trace trick at 0x0051C; bank 4 has full software FPU)
- **SCSI**: AMD AM5380 at 0x05000001 with pseudo-DMA at 0x05000026
- **Compiler**: Sun Microsystems C (Sun CC), standard C library functions present

## Serial Communications — Single Z8530 SCC

Only **one physical Zilog Z8530** (labeled Z088530) exists on the board. The 16 PAL chips decode it to **two separate address ranges** with different register layouts:

### 0x07000000 — Debug Console (compact byte-addressed layout)
Standard Z8530 register mapping:

| Address | Function |
|---------|----------|
| 0x07000000 | Channel B control (RR0/WR0) |
| 0x07000001 | Channel B data |
| 0x07000002 | Channel A control (RR0/WR0) |
| 0x07000003 | Channel A data |
| 0x07000020 | Hardware reset strobe (PAL-decoded, not part of Z8530) |

- **Channel A** (TxDA pin 15, RxDA pin 13): Self-test error output, S-record loader. Init at ROM 0x848B6 with **9600 8N2** (WR4=0x4C, 2 stop bits).
- **Channel B** (TxDB pin 19, RxDB pin 22): Atlas Monitor interactive console. Init at ROM 0x994 with **9600 8N1** (WR4=0x44, 1 stop bit).
- Both channels share the same baud rate setup: WR12=0x0A, WR13=0x00, BRG from 3.6864 MHz PCLK.

**SCC init register values** (from table at ROM 0x161C / 0x848F4):
```
WR1=0x00, WR3=0xC1, WR4=0x44 (monitor) or 0x4C (self-test),
WR5=0x6A, WR9=0x0A, WR11=0x50, WR12=0x0A, WR13=0x00,
WR14=0x01, WR15=0x00
```

**Serial I/O** (for Channel A, confirmed on pin 15):
- TX ready: poll bit 2 of 0x07000002, write data to 0x07000003
- RX ready: poll bit 0 of 0x07000002, read data from 0x07000003

### 0x04000000 — IO Board Communication (register-per-address PAL decode)
The PAL decodes address bits directly as Z8530 register numbers:
- Bits A4-A0 = WR register number (0-15)
- Bit A5 = channel select (0=Channel B, 1=Channel A)
- This eliminates the standard Z8530 two-write register selection protocol

Registers accessed: 0x0400000B-0x0400000F (Ch B), 0x04000020-0x0400002F (Ch A).
Used for the 5-state DMA protocol to the IO board.

**Note**: The disassembly refers to these as "SCC #1" (0x04000000) and "SCC #2" (0x07000000). These are logical names for the two address windows of the same physical chip.

## Memory Map (Main Board, from disassembly)

| Address Range | Size | Description |
|--------------|------|-------------|
| 0x00000000 - 0x0009FFFF | 640KB | ROM (5 banks, 128KB each) |
| 0x02000000 - 0x023FFFFF | 4MB | RAM (SIPP DRAM, expandable to 6MB) |
| 0x04000000 - 0x0400002F | 48B | Z8530 SCC — IO board comm (PAL register-per-address decode) |
| 0x05000001 - 0x0500000F | 8 regs | AMD AM5380 SCSI controller (odd byte lane) |
| 0x05000026 | 1B | SCSI pseudo-DMA data port |
| 0x06000000 | 1B | Bus control latch (R/W) — SCSI signals + IO board flow control |
| 0x06080000 | 1B | Display/graphics control latch (W) |
| 0x060C0000 | 2B | FIFO reset/control register (W) — likely MK4501N control |
| 0x06100000 | 4B | Display/rendering controller (W) — set 0xFFFFFFFF at boot |
| 0x07000000 - 0x07000003 | 4B | Z8530 SCC — debug console (compact byte-addressed) |
| 0x07000020 | 1B | SCC hardware reset strobe (PAL-decoded, read side-effect) |

Address decode: A25:A23 select major device groups. Within 0x06xxxxxx, A20/A19/A18 select sub-devices.

## Additional ICs (Main Board — not addressed by 68020 firmware)

- **Rockwell R6522 VIA** (x2): On the main board near the Centronics parallel port. Never referenced in 640KB of main board ROM code. Likely drive the Centronics parallel interface (as noted by Adrian's Digital Basement video).
- **ST MK4501N** (x4): Dual-port FIFO. Main data pipeline between 68020 and imaging hardware. Control register likely at 0x060C0000.
- **XICOR X2804AP**: 512x8 EEPROM. Stores calibration/configuration data. Likely bit-banged through 0x06000000 latch bits. May only be accessed by manufacturing/calibration tools.

## IO Board (ATI - Agfa Typesetter Interface)
- **CPU**: Motorola 68000 @ 8MHz
- **ROM**: 2x AM27C256 (HI=U21, LO=U22) = 64KB combined as io.bin
- **Firmware**: "Agfa T9400PS ATI v2.2" (PSATI++ Rev v2.2 85804-3/4 9-4-90)
- **Vector table**: SSP=0x14000, PC=0x400
- **Debug port**: "Hello, this is the debug port" / "type ATI for normal operation"
- **Debug commands**: MD (dump), MM (modify), GO (execute), LO (S-record), LED, VIDEO, RESOL, INVERS, MODE, RESET, DEBUG, TMD, ATI
- **ATI commands**: Brace-delimited: {SRE%}, {SRC$}, {SRSP}, {SRGP}
- **ATI responses** (15 total): !STA, !L&S, !BEG, !END, !PWR, _GST, _CMD, _INF, _SET, _GET, _MOD, _NEG, _POS, _GPR, _RES
- **Device subsystems**: RE (Raster Engine), PA (Paper Advance), DN (Densitometer), MG (Motor/Gantry), SH (Shutter)

### IO Board Peripherals (corrected 2026-03-25)
- **1× Z8530 SCC at 0x50000**: Serial communication (inter-board PS channel + debug)
  - Register layout: +1=ChB Cmd, +3=ChB Data, +5=ChA Cmd, +7=ChA Data (odd byte lane, D0-D7)
  - Firmware serial I/O: check status at +3 (bit 0=RX ready, bit 2=TX ready), data at +7
- **2× R6522AP VIA at 0x40000 (VIA #1) and 0x40010 (VIA #2)**: Imagesetter mechanism control
  - Odd byte addresses (D0-D7 via LDS), standard RS0=A1..RS3=A4 wiring
  - VIA #1 register map from base 0x40000: +0x01=ORB, +0x03=ORA, +0x05=DDRB, +0x07=DDRA, +0x09=T1CL, +0x0B=T1CH, +0x0D=T1LL, +0x0F=T1LH, +0x11=T2CL, +0x13=T2CH, +0x15=SR, +0x17=ACR, +0x19=PCR, +0x1B=IFR, +0x1D=IER, +0x1F=ORA_nh
  - VIA #2 register map: same offsets from base 0x40010
- **AM26LS30**: RS-232 dual driver/receiver (near SCC)
- **AM26LS31 or AM26LS32**: RS-422 differential transceiver
- **Empty sockets**: Unpopulated RS-422 driver for optional second channel
- **Previous analysis incorrectly identified 0x40000 and 0x40010 as "SCC #2" and "SCC #3"**

### IO Board VIA Init (ROM 0x1116)
Both VIAs initialized with ORB/ORA/DDRB at offsets +1/+3/+5/+7. VIA #1 also gets timer and IER config at +9/+B/+D/+F/+1B/+1D/+1F.

VIA #1 init values:
- DDRB (+0x05): multiple writes, purpose TBD (handshake sequence?)
- ORA (+0x03): 0xBB
- IFR (+0x1B): 0x14 (clear T1 + CB1 flags)
- ORA_nh (+0x1F): 0xC0 (initial output)
- IER (+0x1D): 0x3F (disable interrupts bits 0-5)
- T1CL (+0x09): 0x70, T1CH (+0x0B): 0x00 (starts 28µs one-shot timer)
- T1LL (+0x0D): 0xFF, T1LH (+0x0F): 0xFF (latch for future restarts)

VIA #1 runtime (via pointer at RAM 0x172E0 = 0x40000):
- Motor direction: write to ORA_nh (+0x1F) and IER (+0x1D)
- Resolution (1200/2400 DPI): write to IER (+0x1D) or ORA_nh (+0x1F)
- DIP switches: read IFR (+0x1B) bits 2-4 (inverted)
- Hardware status: read IFR (+0x1B) bit 1
- VIA #2 present check: read IFR (+0x1B) bit 5

### IO Board Serial Base Pointers
Firmware stores three serial I/O base pointers in RAM:
- 0x1511A: initially 0x040010 (VIA #2), later overwritten to 0x050000 (SCC)
- 0x1511E: initially 0x040000 (VIA #1), later overwritten to 0x050000 (SCC)
- 0x15122: always 0x050000 (SCC)

The same read/write functions (0x1206, 0x1222) are used for both VIA port I/O and SCC serial I/O, accessing offsets +3 (status) and +7 (data) from whichever base is current.

## Bus Control Latch (0x06000000)
Bidirectional byte-wide I/O port implemented as PAL-decoded discrete logic (output latch + input buffer). Shadow register at RAM 0x020170F8, init value 0x31.

| Bit | Signal | Function |
|-----|--------|----------|
| 5 | SCSI /SEL | SCSI selection signal |
| 4 | SCSI /BSY | SCSI busy signal (pulsed at init) |
| 3 | SCSI signal | Toggled during SCSI operations |
| 2 | SCSI signal | SCSI control |
| 1 | Flow control | IO board DMA flow control (read in SCC interrupt handler) |
| 0 | Strobe | Clock/strobe (pulsed: clear then set) |

## RAM Layout (at 0x02000000+)
| Offset | Description |
|--------|-------------|
| 0x0000 | RAM size |
| 0x0004 | ROM size (0x01000000 = 16MB address space) |
| 0x0008 | Base address (0) |
| 0x000C | Top of RAM pointer |
| 0x0010 | System init flag (0=not init, >=2=fully init) |
| 0x0014 | NMI vector pointer |
| 0x0018 | Level 7 interrupt vector pointer |
| 0x002C | SCC interrupt handler vector (installed by 0x84AFC) |
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
| 0x02D0 | Memory address table (8 entries) |
| 0x0300 | S-record data buffer |
| 0x0400 | Extended RAM area / RAM test start |
| 0x0410 | Saved register set for initialization |
| 0x0594-0x0598 | SCC DMA state vars |
| 0x08F8 | Current color space |
| 0x09E4 | HW rendering flag |
| 0x170EC | I/O buffer status flag |
| 0x170F0 | SCC debug console pointer (→0x07000002 for Ch A) |
| 0x170F4 | SCC debug console alt pointer (→0x07000000 for Ch B) |
| 0x170F8 | Bus control latch shadow register (0x06000000) |
| 0x1720C | Current SCSI target ID (0-7) |
| 0x17250 | SCSI I/O request queue pointer |
| 0x1810C | Display/rendering controller structure |
| 0x1811C | Display/graphics control shadow (0x06080000) |
| 0x22340 | SCC IO board comm context structure |
| 0x22378 | SCSI timeout counter |
| 0x2237C | Timer handler priority queue (linked list) |

## Hard Drive
- Quantum P40S, 40MB, SCSI
- 82,029 sectors x 512 bytes = 41,998,848 bytes
- Imaged with BlueSCSI in initiator mode (5 bad sectors)
