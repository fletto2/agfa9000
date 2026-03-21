# Agfa Compugraphic 9000PS - Reverse Engineering Analysis

Reverse engineering analysis of the firmware from an **Agfa Compugraphic 9000PS PostScript RIP** (Raster Image Processor) used with the Agfa 9400 imagesetter. The machine is non-functional and was featured on [Adrian's Digital Basement](https://www.youtube.com/@adriansdigitalbasement) — this project analyzes the firmware ROMs and hard drive image to understand the boot process and diagnose why it gets stuck.

## What's Here

This repository contains annotated disassembly, documentation, and tools produced during the reverse engineering effort. **No copyrighted ROM binaries or disk images are included.**

```
disassembly/           Annotated disassembly of all 6 ROM banks (v7, seventh pass)
  bank0_atlas_monitor.asm    Bank 0: Atlas Monitor, boot, exceptions, PS string tables
  bank1_fonts_scc.asm        Bank 1: Encrypted font data, SCC communication code
  bank2_ps_interpreter.asm   Bank 2: PostScript interpreter init, operators, graphics
  bank3_ps_continued.asm     Bank 3: PS main loop, math, lexer, file I/O, stacks
  bank4_filesystem_scsi.asm  Bank 4: Filesystem, SCSI driver, C runtime, software FPU
  io_board_ati.asm           IO board: ATI v2.2 typesetter interface, debug monitor
docs/
  hardware.md                Hardware details, memory map, RAM layout
  memory_map.md              Clean memory map reference (addresses, registers, entry points)
  filesystem.md              Proprietary HD filesystem format documentation
tools/
  agfa_fs.py                 Python tool to read the proprietary filesystem from disk images
FAILURE_ANALYSIS.md          Comprehensive boot trace and failure diagnosis
```

## Hardware Overview

### Main Board (RIP)
- **CPU**: Motorola 68020 @ 16MHz
- **ROM**: 640KB across 5 banks (20x AM27C256 EPROMs, 4-wide interleave for 32-bit bus)
- **RAM**: 4MB SIPP DRAM installed (expandable to 6MB, firmware tests up to 16MB)
- **SCSI**: AMD AM5380 with pseudo-DMA
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

## Failure Diagnosis (TL;DR)

The self-test at ROM 0x84658 prints a repeating error on the serial console:

```
*** FAIL: Test = 02, data = 1010 ***
```

**Decoded**: Test type 02 = RAM pattern test. Data 0x1010 = bit 16 (D16) stuck at address 0x02200000 (2MB into RAM). This is a failing SIPP DRAM module in the HM byte lane (bits 16-23).

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

## License

MIT — see [LICENSE](LICENSE). Note: this license covers the analysis, documentation, and tools in this repository. The original Agfa/Adobe firmware is copyrighted and not included.
