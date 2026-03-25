# Memory Map Reference - Agfa Compugraphic 9000PS

## Main Board Address Space

| Address Range | Size | Description |
|---------------|------|-------------|
| `0x00000000 - 0x0009FFFF` | 640KB | ROM (5 banks, 128KB each) |
| `0x02000000 - 0x023FFFFF` | 4MB | RAM (SIPP DRAM, expandable to 6MB) |
| `0x04000000 - 0x0400002F` | 48B | Z8530 SCC — IO board comm (PAL register-per-address decode) |
| `0x05000001 - 0x0500000F` | 8 regs | AMD AM5380 SCSI controller (odd byte lane) |
| `0x05000026` | - | SCSI pseudo-DMA data port |
| `0x06000000` | 1B | Bus control latch (R/W) — SCSI signals + IO board flow control |
| `0x06080000` | 1B | Display/graphics control latch (W), shadow at 0x0200181C |
| `0x060C0000` | 2B | FIFO reset/control register (W) — likely MK4501N control |
| `0x06100000` | 4B | Display/rendering controller (W), shadow at 0x02000064 |
| `0x07000000 - 0x07000003` | 4B | Z8530 SCC — debug console (compact byte-addressed) |
| `0x07000020` | 1B | SCC hardware reset strobe (read side-effect, PAL-decoded) |

**Note**: 0x04000000 and 0x07000000 are two address windows into the **same physical Z8530**. The PAL chips provide different register access modes for each window.

## Z8530 SCC Register Layout

### Debug Console at 0x07000000 (compact)

| Address | Function |
|---------|----------|
| `0x07000000` | Channel B control |
| `0x07000001` | Channel B data |
| `0x07000002` | Channel A control |
| `0x07000003` | Channel A data |

- Channel A (pin 15 TxDA): Self-test output, 9600 8N2
- Channel B (pin 19 TxDB): Atlas Monitor console, 9600 8N1

### IO Board Comm at 0x04000000 (register-per-address)

Address bits A4-A0 = WR register number, bit A5 = channel select:

| Offset Range | Channel | Example |
|-------------|---------|---------|
| `0x00 - 0x0F` | B | 0x0400000B = WR11, 0x0400000E = WR14 |
| `0x20 - 0x2F` | A | 0x0400002B = WR11, 0x0400002E = WR14 |

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
| `0x0010` | System init flag (0=not init, >=2=fully init) |
| `0x0014` | NMI vector pointer |
| `0x0018` | Level 7 interrupt vector pointer |
| `0x002C` | SCC interrupt handler vector |
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
| `0x170EC` | I/O buffer status flag |
| `0x170F0` | SCC debug ptr (→0x07000002, Channel A) |
| `0x170F4` | SCC debug alt ptr (→0x07000000, Channel B) |
| `0x170F8` | Bus control latch shadow (0x06000000), init=0x31 |
| `0x170FC` | FPU context |

### Heap & Memory Management (0x17144+)

| Offset | Description |
|--------|-------------|
| `0x17144` | SCSI device structure base |
| `0x1720C` | Current SCSI target ID (0-7) |
| `0x17210` | SCSI capacity table |
| `0x17250` | SCSI I/O request queue pointer |
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
| `0x1810C` | Display/rendering controller structure |
| `0x1811C` | Display/graphics control shadow (0x06080000) |

### High RAM (0x22000+)

| Offset | Description |
|--------|-------------|
| `0x221EC` | HW acceleration callback table |
| `0x222C8` | Error handler |
| `0x22310` | System clock |
| `0x22340` | SCC IO board comm context (+0x14=Rx callback, +0x18=Tx mask, +0x1C=flow state) |
| `0x22378` | SCSI timeout counter |
| `0x2237C` | Timer handler priority queue |

## Key Entry Points

| Address | Description |
|---------|-------------|
| `0x00856` | Cold boot entry (reset vector PC) |
| `0x00860` | Warm boot entry (D7=0) |
| `0x00868` | Monitor setup (post-RAM detect) |
| `0x00994` | Monitor SCC init (both channels, 9600 8N1) |
| `0x01A6E` | RAM detection routine |
| `0x0200C` | PS init thunk (SR=0x2700, 3x NOP, JMP 0x40508) |
| `0x40508` | PostScript initialization entry |
| `0x40E36` | PostScript main entry |
| `0x46000` | Operator dispatcher (46-entry jump table at 0x46944) |
| `0x480B0` | malloc |
| `0x48208` | free |
| `0x47F50` | coalesce (heap block merge) |
| `0x71334` | Interpreter entry |
| `0x71400` | Main interpreter loop (type dispatch table at 0x71420) |
| `0x84658` | Self-test (ROM checksum + RAM pattern test) |
| `0x848B6` | Self-test SCC init (Channel A, 9600 8N2) |
| `0x84A48` | SCC IO board comm interrupt handler (Level 3 autovector) |
| `0x84AFC` | init_scc1_and_scsi (installs IRQ vector, inits shadow register) |
| `0x85B58` | SCSI device scan |
| `0x85F32` | SCSI init |
| `0x86110` | SCSI bus reset |

## Bus Control Latch (0x06000000)

Shadow register at RAM 0x020170F8, init value 0x31.

| Bit | Signal | Function |
|-----|--------|----------|
| 5 | SCSI /SEL | SCSI selection signal |
| 4 | SCSI /BSY | SCSI busy (pulsed at init as reset) |
| 3 | SCSI ctl | Toggled during SCSI operations |
| 2 | SCSI ctl | SCSI control signal |
| 1 | Flow ctl | IO board DMA flow control (readable) |
| 0 | Strobe | Clock/strobe (pulsed: clear then set) |

## IO Board Address Space

Source: https://github.com/misterblack1/agfa_ebs_pnafati (Adrian's reverse engineering)

Address decode: A16-A18 to 3-to-8 decoder. A19-A23 ignored (512KB repeats across 16MB).

| Block | Address | Device | Byte Lane |
|-------|---------|--------|-----------|
| 0 | `0x000000-0x00FFFF` | ROM (64KB EPROM) | Both |
| 1 | `0x010000-0x01FFFF` | SRAM (16KB physical, 4× mirrored) | Both |
| 2 | `0x020000-0x02FFFF` | **MK4501N FIFO** (512×9, inter-board data) | Upper (D8-D15, even addr) |
| 3 | `0x030000-0x03FFFF` | FIFO mirror (alias of Block 2) | Upper |
| 4 | `0x040000-0x04FFFF` | **MC68681 DUART** (serial + GPIO) | Lower (D0-D7, odd addr) |
| 5-7 | `0x050000-0x07FFFF` | **Unpopulated** (no DTACK → CPU halt!) | None |

**Critical corrections** (confirmed from Adrian's GitHub repo):
- 0x50000 is DEAD — no SCC, no DTACK. Firmware checks DUART IP5 and skips if absent.
- Inter-board data goes through MK4501N FIFO at 0x020000, NOT SCC serial.
- 0x40000 is MC68681 DUART, NOT R6522 VIA or Z8530 SCC.
- Two R6522AP VIAs physically on board but NOT addressed by firmware.

### MC68681 DUART Register Map (odd bytes from 0x40000)

| Address | Offset | Read | Write |
|---------|--------|------|-------|
| `0x40001` | +0x01 | MR1A/MR2A (auto-increment) | MR1A/MR2A |
| `0x40003` | +0x03 | SRA (Status A: bit0=RXRDY, bit2=TXRDY) | CSRA (Clock Select A: 0xBB=9600) |
| `0x40005` | +0x05 | — | CRA (Command A) |
| `0x40007` | +0x07 | RHRA (RX data) | THRA (TX data) |
| `0x40009` | +0x09 | IPCR (Input Port Change) | ACR (Aux Control: 0x70=timer mode) |
| `0x4000B` | +0x0B | ISR (Interrupt Status) | IMR (Interrupt Mask: 0x00=all off) |
| `0x4000D` | +0x0D | CTU (Counter Upper) | CTU |
| `0x4000F` | +0x0F | CTL (Counter Lower) | CTL |
| `0x40011` | +0x11 | MR1B/MR2B | MR1B/MR2B |
| `0x40013` | +0x13 | SRB (Status B) | CSRB (Clock Select B: 0x88=1200) |
| `0x40015` | +0x15 | — | CRB (Command B) |
| `0x40017` | +0x17 | RHRB (RX data) | THRB (TX data) |
| `0x40019` | +0x19 | IVR | IVR (Interrupt Vector) |
| `0x4001B` | +0x1B | IP (Input Port) | OPCR (Output Port Config) |
| `0x4001D` | +0x1D | Start Counter | Set OPR (set output bits) |
| `0x4001F` | +0x1F | Stop Counter | Reset OPR (clear output bits) |

CRA/CRB command bits: [6:4]=command (001=reset MR, 010=reset Rx, 011=reset Tx),
[3:2]=Tx (01=enable, 10=disable), [1:0]=Rx (01=enable, 10=disable)

DUART Input Port: bit1=stop button, bits2-4=dial (3-bit octal), bit5=FIFO/DUART2 present
DUART Output Port: bit0=resolution, bit1=motor, bit2=reset, OP5=amber LED, OP6=FIFO ctl, OP7=red LED

### MK4501N FIFO (even bytes at 0x020000-0x02FFFF)

Any read/write to an even address in 0x020000-0x02FFFF accesses the FIFO data port.
512 entries × 9 bits (8-bit data on D8-D15, 9th bit to DUART IP5/OP2).
Block 3 (0x030000-0x03FFFF) is a mirror alias.

## AMD AM5380 SCSI Registers (at 0x05000001, odd addresses)

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
