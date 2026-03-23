# Agfa Compugraphic 9000PS - Reverse Engineering & Emulator

Reverse engineering analysis and emulator for the **Agfa Compugraphic 9000PS PostScript RIP** (Raster Image Processor) used with the Agfa 9400 imagesetter. The machine was featured on [Adrian's Digital Basement](https://www.youtube.com/@adriansdigitalbasement) — this project analyzes the firmware ROMs and hard drive image, diagnoses the hardware failure, and includes a working emulator that boots the original firmware.

## Emulator

A standalone emulator that boots the original unmodified 640KB firmware and runs the Adobe PostScript Level 1 interpreter. This is the first emulator ever built for this hardware.

```
cd src
git clone https://github.com/kstenerud/Musashi musashi
cd musashi && gcc -o m68kmake m68kmake.c && ./m68kmake . && cd ..
make
./agfa9000 /path/to/roms -hd HD00_Agfa_RIP.hda
```

### What Works

- **Full boot sequence**: Atlas Monitor cold start, RAM detection, SCC init, FPU init (68881 via softfloat), timer calibration, self-test, SCSI device scan
- **PostScript interpreter**: Adobe PostScript v49.3 main loop runs at 0x71400
- **SCSI disk access**: NCR 5380 emulation with bus phase state machine, HD image mounted, START UNIT / TEST UNIT READY commands execute
- **Dual CPU**: Main board 68020 + IO board 68000 time-sliced via Musashi context switching
- **Fault injection**: `./agfa9000 roms/ -stuck 16` reproduces Adrian's exact `***FAIL: Test = 02, data = 1010 ***` error
- **Serial output**: XON (0x11) on SCC Channel A/B

### Options

```
./agfa9000 <rom_dir> [options]
  -hd <image>         Mount HD image at SCSI ID 0
  -io <io.bin>        Load IO board ROM (68000, enables dual-CPU)
  -rom <image>        Load flat ROM image
  -roms <dir>         Load split EPROMs by socket name (Uxxx_LANEn.bin)
  -ram <MB>           Set RAM size (1-16, default 4)
  -stuck <bit>        Inject stuck-LOW fault on data bit (0-31)
  -stuck-high <bit>   Inject stuck-HIGH fault
  -sysstart <file>    Inject Sys/Start file through SCC
  -v                  Verbose logging
```

### Architecture

```
src/
  agfa9000.c    Main emulator (memory map, interrupt generation, peripherals)
  scc.c/h       Z8530 SCC (two-step register access, dual PAL decode modes)
  scsi.c/h      NCR 5380 SCSI (bus phases, DMA, INQUIRY/READ/WRITE)
  ioboard.c/h   IO board 68000 (dual-CPU context switching, SCC cross-connect)
  stubs.c       Musashi disassembler callbacks
  Makefile
  musashi/      Musashi 68020 CPU core (clone separately)
```

### Key Technical Discoveries (from emulator development)

- NCR 5380 register mapping: `addr & 7` (byte-per-register at 0x05000000)
- Pseudo-DMA port at 0x05000020 (not 0x05000026 as originally documented)
- Timer interrupt is Level 1 autovector (redirect at RAM 0x02000020)
- SCC #1 interrupt is Level 5 autovector (redirect at RAM 0x0200002C)
- CIO timer calibration uses SCC BRG zero-count as reference oscillator
- PS interpreter input comes through SCC DMA (bus latch 0x06000000), not compact SCC
- SCSI selection uses standard NCR 5380 ICR register (not the bus control latch)
- 4MB RAM minimum required (system variables extend to 0x02022290+)

## What's Here

```
disassembly/           Annotated disassembly of all 6 ROM banks (v7, seventh pass)
  bank0_atlas_monitor.asm    Bank 0: Atlas Monitor, boot, exceptions, PS string tables
  bank1_fonts_scc.asm        Bank 1: Encrypted font data, SCC communication code
  bank2_ps_interpreter.asm   Bank 2: PostScript interpreter init, operators, graphics
  bank3_ps_continued.asm     Bank 3: PS main loop, math, lexer, file I/O, stacks
  bank4_filesystem_scsi.asm  Bank 4: Filesystem, SCSI driver, C runtime, software FPU
  io_board_ati.asm           IO board: ATI v2.2 typesetter interface, debug monitor
src/                   Emulator source code (see above)
cpm_test/              CP/M-68K ready-to-burn EPROMs (4x AM27C256, Bank 0 only)
  README.md            Burning guide, socket map, installation, serial setup
  U291_HH0.bin         Socket U291 — byte lane HH (bits 31-24)
  U294_HM0.bin         Socket U294 — byte lane HM (bits 23-16)
  U283_LM0.bin         Socket U283 — byte lane LM (bits 15-8)
  U281_LL0.bin         Socket U281 — byte lane LL (bits 7-0)
demo/                  Bare-metal programs for the Agfa hardware
  ramtest.c            Comprehensive RAM diagnostic (S-record for Atlas Monitor)
  demon_agfa.c         Demon Attack game port (bare metal, VT100)
  bootloader.S         Channel A S-record bootloader ROM
  crt0.S               Startup code with SCC init
docs/
  hardware.md          Hardware details, memory map, RAM layout
  memory_map.md        Clean memory map reference (addresses, registers, entry points)
  filesystem.md        Proprietary HD filesystem format documentation
tools/
  agfa_fs.py           Python tool to read the proprietary filesystem from disk images
FAILURE_ANALYSIS.md    Comprehensive boot trace and failure diagnosis
```

**No copyrighted ROM binaries or disk images are included.**

## CP/M-68K

A working CP/M-68K port that runs on the Agfa hardware. The entire system — BIOS, CCP/BDOS, LZSS decompressor, and 12 programs including Colossal Cave Adventure — fits in **4 EPROMs** (128KB, Bank 0 only). Works with the stock 2MB RAM.

Burn the 4 files in `cpm_test/` to AM27C256 EPROMs, swap them into the Bank 0 sockets (U291, U294, U283, U281), connect a serial terminal at 9600 8N1 to SCC Channel B, and power on. See [cpm_test/README.md](cpm_test/README.md) for the full guide.

To test in the emulator:

```
./src/agfa9000 -roms cpm_test/ -ram 2
```

## Hardware Overview

### Main Board (RIP)
- **CPU**: Motorola 68020 @ 16MHz
- **FPU**: Motorola 68881 (optional, software FPU in ROM bank 4)
- **ROM**: 640KB across 5 banks (20x AM27C256 EPROMs, 4-wide interleave for 32-bit bus)
- **RAM**: 4MB SIPP DRAM installed (expandable to 6MB, firmware tests up to 16MB)
- **SCSI**: AMD AM5380 with pseudo-DMA at 0x05000020
- **Serial**: Single Zilog Z8530 SCC, PAL-decoded to two address ranges:
  - `0x04000000`: IO board communication (register-per-address PAL decode)
  - `0x07000000`: Debug console (compact byte-addressed layout)
- **Additional ICs**: 2x Rockwell R6522 VIA, 4x ST MK4501N FIFO, XICOR X2804AP EEPROM, 16x PAL chips
- **Firmware**: Adobe PostScript v49.3 on "Atlas" reference design, compiled with Sun Microsystems C (1983-1986)

### IO Board (ATI - Agfa Typesetter Interface)
- **CPU**: Motorola 68000 @ 8MHz
- **ROM**: 64KB (2x AM27C256)
- **Firmware**: ATI v2.2 — controls the imagesetter hardware (laser, paper advance, densitometer)
- **Debug port**: Built-in debug monitor ("Hello, this is the debug port", type ATI for normal operation)

### Storage
- Quantum P40S, 40MB SCSI hard drive
- Proprietary filesystem: 1024-byte pages, 296 files (fonts, font cache, system files)
- Boot file: `Sys/Start` (eexec-encrypted PostScript)

## Failure Diagnosis

The self-test at ROM 0x84658 prints a repeating error on the serial console:

```
*** FAIL: Test = 02, data = 1010 ***
```

**Decoded**: Test type 02 = RAM pattern test. Data 0x1010 = bit 16 (D16) stuck at address 0x02200000 (2MB into RAM). This is a failing SIPP DRAM module in the HM byte lane (bits 16-23).

**Confirmed by emulator**: Running `./agfa9000 roms/ -stuck 16` produces the identical error output.

**To fix:**
1. Replace the failing SIPP DRAM module
2. Fix PSU — 5V rail measures 4.78V at the board (marginal)
3. Connect a serial terminal — 9600 baud to Z8530 Channel A (TxDA pin 15) for self-test output, or Channel B (TxDB pin 19) for Atlas Monitor interactive console

See [FAILURE_ANALYSIS.md](FAILURE_ANALYSIS.md) for the complete instruction-level boot trace and detailed diagnostic guide.

## Disassembly Notes

The disassembly was produced using a multi-pass automated analysis pipeline (Capstone disassembler + distilled LLM annotation), with manual verification of critical sections.

Key conventions discovered:
- **Banks 2-4**: Standard C calling convention (`LINK A6` / `UNLK A6` / `RTS`)
- **Bank 0**: Coroutine-style (A5 = continuation address, `JMP (A5)` instead of `RTS`)
- **Bank 1 0x20000-0x3AEB7**: Encrypted Adobe Type 1 font data (eexec), not code
- **PostScript object types** (low 4 bits): 1=int, 2=real, 4=bool, 5=string, 6=dict, 7=exec, 8=mark, 9=name, 13=operator

**Note on SCC naming**: The disassembly refers to "SCC #1" (0x04000000) and "SCC #2" (0x07000000) as if they are separate chips. In reality, there is one physical Z8530 with PAL-decoded dual addressing. The names are retained as logical identifiers throughout the disassembly.

## Filesystem Tool

`tools/agfa_fs.py` reads the proprietary filesystem from the HD image:

```
python3 agfa_fs.py HD00_Agfa_RIP.hda info       # Volume info
python3 agfa_fs.py HD00_Agfa_RIP.hda list        # List all files
python3 agfa_fs.py HD00_Agfa_RIP.hda extract FILE # Extract a file
python3 agfa_fs.py HD00_Agfa_RIP.hda dump FILE   # Hex dump a file
python3 agfa_fs.py HD00_Agfa_RIP.hda verify      # Verify checksums
```

The filesystem uses dual-root redundancy, additive checksums (page sum = 0), and extent-based allocation. See [docs/filesystem.md](docs/filesystem.md) for the complete format specification.

## Credits

- Reverse engineering analysis by fletto with Claude (Anthropic)
- Original video and hardware investigation by [Adrian's Digital Basement](https://www.youtube.com/@adriansdigitalbasement)
- Disassembly annotation assisted by distilled LLMs
- CPU emulation by [Musashi](https://github.com/kstenerud/Musashi) (Karl Stenerud)

## License

MIT — see [LICENSE](LICENSE). Note: this license covers the analysis, documentation, and tools in this repository. The original Agfa/Adobe firmware is copyrighted and not included.
