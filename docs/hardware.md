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

## Memory Map (Main Board — hardware verified by Adrian Black)

| Address Range | Size | Description |
|--------------|------|-------------|
| 0x00000000 - 0x0009FFFF | 640KB | ROM (5 banks, 128KB each) |
| 0x02000000 - 0x023FFFFF | 4MB | RAM (DRAM, expandable to 16MB, refresh by PAL hardware) |
| 0x04000000 - 0x0400000F | 16B | **R6522 VIA #1** — parallel I/O to IO board via 50-pin IDC |
| 0x04000020 - 0x0400002F | 16B | **R6522 VIA #2** — second VIA for IO board communication |
| 0x05000001 - 0x0500000F | 8 regs | AMD AM5380 SCSI controller (odd byte lane) |
| 0x05000026 | 1B | SCSI pseudo-DMA data port |
| 0x06000000 | 1B | Bus control latch (R/W) — SCSI signals only |
| 0x06080000 | 1B | Display/graphics control latch (W) |
| 0x060C0000 | 2B | FIFO reset/control register (W) — likely MK4501N control |
| 0x06100000 | 4B | Display/rendering controller (W) — set 0xFFFFFFFF at boot |
| 0x07000000 - 0x07000003 | 4B | Z8530 SCC — Ch A = RS-232, Ch B = RS-422/AppleTalk |
| 0x07000020 | 1B | SCC hardware reset strobe (PAL-decoded, read side-effect) |

Address decode: A25:A23 select major device groups. Within 0x06xxxxxx, A20/A19/A18 select sub-devices.

### R6522 VIA Register Map (PAL direct-register decode at 0x04000000)

VIA #1 at 0x04000000, VIA #2 at 0x04000020. Each register at single byte offset:

| Offset | Register | VIA #1 Init | VIA #2 Init |
|--------|----------|-------------|-------------|
| +0x00 | ORB | 0x72→0xE2 | 0x2D |
| +0x01 | ORA | 0x22 | 0x01 |
| +0x02 | DDRB | 0xFF (all out) | 0x3F (lower 6 out) |
| +0x03 | DDRA | 0xFF (all out) | 0x01 (bit 0 out) |
| +0x04 | T1C-L | | |
| +0x05 | T1C-H | | |
| +0x06 | T1L-L | | |
| +0x07 | T1L-H | | |
| +0x08 | T2C-L | | |
| +0x09 | T2C-H | | |
| +0x0A | SR | | |
| +0x0B | ACR | 0x68 | 0x68 |
| +0x0C | PCR | 0x03 | 0x20 |
| +0x0D | IFR | 0x7F (clear all) | 0x7F (clear all) |
| +0x0E | IER | 0x7F (disable all) | 0x7F (disable all) |
| +0x0F | ORA-nh | | |

**Hardware verified:** /CS1 on VIA #1 toggles continuously during boot while polling IO board.
I/O pins on both VIAs physically trace to the 50-pin IDC connector.
System hangs without IO board: 68020 gets stuck polling a VIA register.

One VIA 8-bit port connects to the MK4501N FIFO on the IO board.
Other VIA port lines talk to the SCC2691 UART on the IO board plus other control signals.

### Z8530 SCC (at 0x07000000 — external serial ports ONLY)

- **Channel A**: RS-232 serial port (Atlas Monitor/debug console at 9600 8N1, also PostScript `executive` interactive mode)
- **Channel B**: RS-422/AppleTalk port
- **Does NOT connect to the IO board** — physically wired to AM26LS30 (RS-232) and AM26LS31/32 (RS-422) line drivers only

## Additional ICs (Main Board)

- **ST MK4501N** (x4): Dual-port FIFO. Main data pipeline between 68020 and imaging hardware. Control register likely at 0x060C0000.
- **XICOR X2804AP**: 512x8 EEPROM. Stores calibration/configuration data. May only be accessed by manufacturing/calibration tools.
- **DRAM refresh**: Handled entirely by registered PAL hardware. Zero refresh code in firmware. CP/M and Minix custom ROMs run without any refresh setup.

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

### IO Board Peripherals (corrected 2026-03-25, verified by Adrian)

- **1× MC68681 DUART at 0x40000**: Two serial channels + I/O port + timer
  - Channel A (9600 baud): connected to SCC2691 RXD/TXD (ATI protocol to main board)
  - Channel B (1200 baud): auxiliary (print engine via 37-pin connector)
  - Input Port: IP1=stop button, IP2-4=dial, IP5=SCC2691/DUART2 presence
  - Output Port: OP5=amber LED, OP6=FIFO control, OP7=red LED, plus resolution/motor/reset bits
  - Lower byte lane (D0-D7, odd addresses)

- **1× SCC2691 single-channel UART**: Inter-board serial communication
  - Data/select lines wired through 50-pin ribbon to main board R6522 VIAs
  - RXD/TXD wired directly to MC68681 DUART Port A
  - Carries the ATI protocol (Adrian confirmed serial comms visible here during boot)
  - Firmware checks DUART IP5 for presence; if absent, 0x50000 init is skipped

- **1× MK4501N FIFO at 0x20000** (512×9): Inter-board high-speed data buffer
  - Upper byte lane (D8-D15, even addresses), any address in 0x20000-0x2FFFF
  - 9th bit connects to DUART I/O pins (IP5, OP2)
  - One VIA port on main board likely drives this FIFO

- **2× R6522AP VIA**: Physically on the IO board but NOT directly addressed by 68000 firmware
  - I/O lines wired to 50-pin ribbon (controlled by main board VIAs)
  - Adrian verified: data lines on VIAs connect to the SCC2691 chip
  - May also control IO board status LEDs (never seen active under IO board firmware alone)

- **AM26LS30**: RS-232 transceiver (for SCC2691 or DUART serial)
- **AM26LS31 or AM26LS32**: RS-422 differential transceiver
- **Empty sockets**: Unpopulated RS-422 driver for optional second channel

### Inter-Board Communication Path (verified by Adrian)

```
Main board (68020)                    IO board (68000)
  R6522 VIA #1/2  ----50-pin IDC---->  SCC2691 UART
  (0x04000000)         ribbon           RXD/TXD wired to
                                        MC68681 DUART Port A
                                        (0x040007 = RHRA/THRA)

  R6522 VIA port  ----50-pin IDC---->  MK4501N FIFO
  (8-bit parallel)     ribbon           (0x020000, bulk data)
```

The main board VIAs provide parallel control of the SCC2691 (select/data lines) and
direct data to the MK4501N FIFO. The ATI protocol runs as serial over the SCC2691→DUART path.

## Bus Control Latch (0x06000000)
Bidirectional byte-wide I/O port implemented as PAL-decoded discrete logic (output latch + input buffer). Shadow register at RAM 0x020170F8, init value 0x31.

| Bit | Signal | Function |
|-----|--------|----------|
| 5 | SCSI /SEL | SCSI selection signal |
| 4 | SCSI /BSY | SCSI busy signal (pulsed at init) |
| 3 | SCSI signal | Toggled during SCSI operations |
| 2 | SCSI signal | SCSI control |
| 1 | SCSI signal | Additional SCSI control |
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
