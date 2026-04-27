# Agfa Compugraphic 9000PS - Reverse Engineering Project

## Project Overview
Reverse engineering an Agfa Compugraphic 9000PS PostScript RIP (Raster Image Processor) for an Agfa 9400 imagesetter. The machine is non-functional and we are analyzing firmware ROMs and a hard drive image to understand the boot process and diagnose the failure.

## Hardware
- **Main board**: Motorola 68020 @ 16MHz, 640KB ROM (5 banks × 128KB), up to 16MB RAM
- **IO board**: Motorola 68000 @ 8MHz, 64KB ROM, ATI v2.2 (Agfa Typesetter Interface)
- **Storage**: Quantum P40S 40MB SCSI hard drive (imaged via BlueSCSI, 5 bad sectors in non-critical areas)
- **Firmware**: Adobe PostScript v49.3 on "Atlas" reference design, compiled with Sun Microsystems C (1983-1986)

## Working Directories
- **ROM binaries & source data**: `/home/fletto/ext/src/claude/agfa9000/`
- **Analysis output & scripts**: `/home/fletto/src/claude/agfa9000/`
- **Project memory**: `/home/fletto/.claude/projects/-home-fletto-ext-src-claude-agfa9000/memory/`

## Key Tools
- m68k cross-objdump: `/opt/cross/m68k_new/bin/m68k-elf-objdump`
- Python capstone library (v5.0.6) for disassembly
- DeepSeek API for automated disassembly annotation (key in `deepseek_api_key.txt`)
- `agfa_fs.py` — custom filesystem tool for the proprietary HD format (list/extract/info/dump/verify)
- `deepseek_disasm_v7.py` — current automated disassembly+annotation script (3KB chunks, feeds prior pass as context)

## ROM Banks
| Bank | File | Address Range | Arch | Contents |
|------|------|--------------|------|----------|
| 0 | 0.bin | 0x00000-0x1FFFF | 68020 | Atlas Monitor, boot, exceptions, PS string tables |
| 1 | 1.bin | 0x20000-0x3FFFF | 68020 | Encrypted font data (to 0x3AEB7), SCC comm code (0x3AEB8+) |
| 2 | 2.bin | 0x40000-0x5FFFF | 68020 | PostScript interpreter: init, operators, graphics, fonts, raster |
| 3 | 3.bin | 0x60000-0x7FFFF | 68020 | PS interpreter: main loop (0x71400), math, lexer, file I/O, stacks |
| 4 | 4.bin | 0x80000-0x9FFFF | 68020 | Filesystem, SCSI driver, C runtime, software FPU |
| IO | IO Board/io.bin | 0x00000-0x0FFFF | 68000 | ATI v2.2 typesetter interface, debug monitor |

## Current Analysis Files (v7 = latest)
- `annotated_bank{0,1,2,3,4}_v7.asm` — DeepSeek-annotated disassembly (1.68MB total, 198 chunks, 2 errors)
- `annotated_io_v7.asm` — IO board analysis (54KB, 6 chunks, 0 errors)
- `failure_analysis.txt` — comprehensive failure analysis and boot trace (Fourth Revision, v7 knowledge)
- `annotated_main_board_v3.asm` — manual annotation of boot code (0x0000-0x1CE0)
- Prior versions (v4-v6) also present but superseded

## Key Conventions
- Banks 2-4: C calling convention (LINK A6 / UNLK A6 / RTS)
- Bank 0: coroutine-style (A5 = continuation, JMP (A5) instead of RTS)
- Bank 1 0x20000-0x3AEB7: encrypted Adobe Type 1 font data (eexec), NOT code
- PS object types (low 4 bits): 1=int, 2=real, 4=bool, 5=string, 6=dict, 7=exec, 8=mark, 9=name, 13=operator

## Important Addresses
- Reset vector: SSP=0x0200024C, PC=0x00000856
- Warm boot entry: 0x00000860 (D7=0)
- Monitor setup: 0x00000868 (post-RAM detect)
- PS init entry: 0x40508 (from boot thunk at 0x0200C)
- PS main entry: 0x40E36
- Main interpreter loop: 0x71400 (entry at 0x71334, type dispatch table at 0x71420)
- Operator dispatcher: 0x46000-0x47388 (monolithic, 46-entry jump table at 0x46944)
- malloc: 0x480B0, free: 0x48208, coalesce: 0x47F50
- SCSI init: 0x85F32, device scan: 0x85B58, bus reset: 0x86110
- NCR 5380 at 0x05000001, pseudo-DMA at 0x05000026
- SCC #1: 0x04000000 (IO board comm), SCC #2: 0x07000000 (debug console, 9600 8N1)
- Display/HW accel: 0x06100000, mystery HW regs: 0x06080000, 0x060C0000
- Printer init: 0x3C2A4 (sends "004PWR" to IO board as first handshake)
- SCC #1 channel config: 0x3BC8A, DMA state machine: 0x3B312
- Stream put byte with wait: 0x3F936 (can hang if buffer full and no DMA drain)
- Stream system init: 0x3FB12
- IO board main entry: 0x0400, main loop: 0x042C, debug monitor: 0x2E98

## HD Filesystem
- Proprietary format, 1024-byte pages, 41014 pages total
- File magic: 0x1EADE460, Root magic: 0x5FA87D27
- Actual PS boot file: `Sys/Start` (14.9KB eexec-encrypted PostScript)
- 296 valid files (118 fonts, 163 FC/ cache, 5 Sys, misc)
- All critical boot files intact: Root0, Root1, AllocMap, Directory, Sys/Start
- Use `agfa_fs.py` for all filesystem operations

## Failure Analysis Summary
The machine powers on, boots cleanly through the Atlas Monitor (single reset, confirmed by scope), auto-boots to PostScript init at 0x40508, and then gets stuck.

**Most likely cause (★★★★★): SCSI timeout retry loop**
- PS init configures SCC #1 (0x3BC8A), sends "004PWR" to IO board (0x3C2A4)
- IO board responds (it's working, in polling loop since ~t=0.001s)
- PS init proceeds through internal setup to SCSI bus scan (0x85B58)
- No working disk → selection timeouts on all 8 SCSI IDs → retry loop → "pulsing"
- 8 IDs × 5000ms INQUIRY timeout × 10 retries = ~400s worst case per full scan

**"Totally stuck without IO board" explained:**
- scc1_write_byte (0x3B080) polls CTS with 10,000-tick timeout per byte
- Without IO board, CTS never asserts → stuck in SCC polling, never reaches SCSI

**Other contributing factors:**
- Low voltage (4.78V, marginal for DRAM/SCC/NCR5380 which need 4.75V min)
- Stream system could deadlock if DMA never drains buffer (0x3F936)

**To fix:** Fix PSU to 5.00V at board, configure BlueSCSI at correct SCSI ID with valid image, connect serial terminal (9600 8N1) to SCC #2 for Atlas Monitor access.

See `failure_analysis.txt` for complete boot trace, all diagnostic addresses, and step-by-step debugging guide.

## CP/M-68K Port
A working CP/M-68K that runs on the real Agfa hardware. Fits in 4 EPROMs (Bank 0 only, 128KB).

- **Repository**: `/home/fletto/agfa9000/` (GitHub: fletto2/agfa9000)
- **Build source** (local only): `/home/fletto/agfa9000/cpm68k/`
- **Ready-to-burn EPROMs**: `/home/fletto/agfa9000/cpm_test/` (in git repo)
- **CP/M source** (local only): `/home/fletto/agfa9000/cpm68k/cpm-src/` (DRI CP/M-68K with bug fixes)
- **Reference BIOS**: `/home/fletto/src/claude/cpm68k/gas68kcpm/gas68kbios.s`
- **Emulator test**: `./src/agfa9000 -roms cpm_test/ -ram 2`
- **ROM disk**: LZSS-compressed (312KB → 100KB), decompressed to RAM at boot
- **TPA**: ~1.6MB (0x02050000–0x021F0000) with 2MB RAM
- **Console**: SCC Channel B default, Channel A (RS-422) swapped variant
- **Both variants tested**: `cpm_test/` has 4 + 4 EPROMs (Channel B + Channel A swapped)

### EPROM socket map (Bank 0)
| Socket | Lane | File |
|--------|------|------|
| U291 | HH (bits 31-24) | U291_HH0.bin |
| U294 | HM (bits 23-16) | U294_HM0.bin |
| U283 | LM (bits 15-8) | U283_LM0.bin |
| U281 | LL (bits 7-0) | U281_LL0.bin |

### Key bugs fixed (from comparison with gas68kcpm)
1. Function table order wrong (getseg at position 19 instead of 18)
2. DPB BSH/BLM wrong (1KB blocks instead of 2KB)
3. Missing sector translate table (disk formatted with skew 6)
4. getseg/seldsk double ROM_RAM_DELTA on PC-relative addresses
5. TRAP #2 protected in setexc (BDOS couldn't install handler)
6. Vector table zero-filled gaps
7. ccpload.s RTE without 68020 format word
8. _init address hardcoded in linker script
9. Missing BIOS function stubs
10. Allocation vector too small

## Minix 2.0.4 Port
**FULLY WORKING.** Minix 2 Unix port boots to an interactive shell prompt.
Kernel/MM/FS/TTY/INIT all work. exec(), fork(), read(), write() functional.
Shell processes commands and outputs results. 50+ bugs fixed.

- **Source**: `/home/fletto/agfa9000/minix/agfa-port/` (kernel, mm, fs, cmds, lib)
- **Minix ST base**: `/home/fletto/agfa9000/minix/minix-st-2.0.4/`
- **PT68K reference**: `/home/fletto/agfa9000/minix/minix-for-the-PT68K-2-4/`
- **Build**: `cd agfa-port && bash build.sh` (cascade rebuild)
- **ROM image**: 640KB, all 20 EPROMs (kernel + Minix V2 rootfs read from ROM)
- **Console**: SCC Channel A (directly wired connector), timer on Channel B (RS-422)
- **Emulator test**: `./src/agfa9000 -roms minix/agfa-port/eproms/ -ram 2`

### Boot + shell output (working)
```
Minix 2.0.4  Copyright 2001 Prentice-Hall, Inc.
Agfa 9000PS (68020), compiled ...
init_clock: timer on ChB, TC=33331
Memory size = 2048K   MINIX = 279K   RAM disk = 0K   Available = 1769K
INIT OK
# echo hello world
hello world
# echo works
works
#
```

### What works
- Kernel boots, all 10 tasks initialize (NR_TASKS=10), VBR set to RAM
- Timer: SCC Channel B BRG, 60Hz via genint handler
- IPC: mini_send/mini_rec with 34-byte messages, context switching
- Shadow memory: copyclicks/flipclicks/zeroclicks with 32-bit phys_clicks
- MM initializes, prints memory banner, enters main loop
- FS mounts ROM root filesystem (big-endian Minix V2, 16-byte dir entries)
- INIT (PID 1) runs, opens /dev/console, writes to stdout
- exec() succeeds: init execs /bin/sh, shell runs interactively
- Shell: prompt, canonical input, echo, builtin commands (echo, cd, pwd, exit, set)
- SCC RX interrupts deliver input from serial console
- Console output via polled SCC drain (rs_ostart loop)
- 13 user commands + root filesystem in ROM, Minix a.out format with -mpcrel
- Files >7KB load correctly (indirect blocks working)

### All bugs fixed (50+, from 68000 Atari ST source + GCC porting)
**68020 assembly (agfampx.S):**
1. `save` format word offset: SP+10 not SP+6 (BSR return addr + SR + PC + format)
2. `save` KSP computation: add 4 (BSR return) to frame size
3. `restart` pushes format word (0x0000) for 68020 RTE
4. `_intr5` on Level 5 autovector (was on Level 2 — wrong vector)
5. Vector table: all 256 entries point to RAM handlers (no zero-fill gaps)
6. `_sys` handler: move.w → move.l for 32-bit int syscall arguments
7. `genint` handler: move.w → move.l for handler argument, stack cleanup #2 → #4
8. `copy_mes` in klib68k: 26 bytes → 34 bytes (8 longs + 1 word)
9. Size check: `cmp.l #26` → `cmp.l #34` for fast message copy path
10. `savtt` offset: 77 → 79 (LSB of 4-byte int p_trap on big-endian)
11. IPC stubs: move.w → moveq for D0 operation code (clears upper 16 bits)
12. `_checksp` removed from restart (A2 push corrupted format word area)
13. `_intr5` uses genint instead of save (prevents stack corruption during syscalls)
14. `copyclicks`/`flipclicks`/`zeroclicks`: move.w → move.l, offsets 4/6/8 → 4/8/12

**Kernel C code:**
15. `scr_init`: redirects /dev/console to SCC serial via rs_init
16. `tty_timeout`: initialized to LONG_MAX (not -1 which is negative on signed clock_t)
17. `rs_init`: SCC console interrupts disabled during boot handshake
18. `init_clock`: redirected to agfa_init_clock (was MFP — infinite loop)
19. SCC channels: console on Channel A, timer on Channel B
20. `_EM_WSIZE=4` in kernel Makefile (ioctl encoding must match FS)
21. `dev_t` widened from `short` to `int` (big-endian type promotion fix)
22. `NR_RAMS` override moved after includes (ROM device minor 5 accepted)
23. `NR_BUFS=40` for Agfa (small ROM filesystem, saves BSS)
24. Stack space in `_sizes` (+16/32/8 clicks for MM/FS/INIT)
25. `stshadow.c` linked (real mkshadow/rmshadow/unshadow for fork)
26. `siaint` checks Channel A RR3 bits (0x20/0x10/0x08 not Channel B)
27. `scc_rx_int` checks RR0_RX_AVAIL before reading (spurious filter)
28. `rs_ostart` polled drain loop (sends all bytes without TX interrupts)
29. `tty_timeout=0` when output or input pending (one-shot HARD_INT request)
30. `tty_agfa.c`: "Agfa 9000PS (68020)" banner replaces Atari detection
31. SCC RX interrupts enabled after TTY init (WR1=0x10)
32. `force_timeout` in scc_rx_int (safe with RR0 check gate)
33. `NR_CONS=1` (was 3 — Atari ST default for video consoles)
34. `CLOCAL` set on serial console termios (skip modem DCD check in rs_read)
35. `rs_init` skip if rs_lines[0] already claimed by console (prevents tty backpointer
   overwrite: RS232 tty_table[1] was overwriting rs_lines[0].tty → characters stored
   in wrong tty's input queue, shell read() never completed)

**MM:**
36. MM putk: direct SCC writes (bypasses TTY deadlock during init)

**User space:**
37. `__MLONG__` removed from MM/FS/cmds (ifdef was backwards)
38. `-mpcrel` for position-independent user commands (SHADOWING=1)
39. `execve()` argc field added to stack frame (was missing)
40. `/etc/ttytab` with `/bin/login`, `/dev/tty00` alias in rootfs
41. `init.c`: opens `/dev/console` for fd 0/1/2
42. Shell: builtin `echo` command (fork+exec not needed for basic testing)

**Filesystem:**
43. `mkrootfs.py`: big-endian struct.pack, 16-byte dir entries
44. `mkminixbin.py`: ELF-to-Minix a.out conversion
45. `mkrootfs.py`: indirect block zone index never incremented — every zone number
   overwrote slot 0, only last zone survived. Files >7 blocks had zeroed tail.
   Shell's _main (at offset 0x2CA4) was all zeros → executed as NOP sled → SIGILL.

**Emulator:**
46. SCC RX interrupt generation (scc_rx_char sets rx_int_pending)
47. SCC RX FIFO clears rx_int_pending when empty
48. DCD asserted on both channels (prevents SIGHUP on rs_read)
49. SCC Reset Highest IUS (WR0 cmd 7): re-assert rx_int_pending if FIFO still has data
   (was clearing ALL pending flags, losing interrupt for remaining FIFO characters)
50. BRG timer: `scc_tick_n(cycles)` with PCLK-rate countdown (was decrement-by-1)
51. BRG reload: use raw `tc+2` value (was `tc/1000+1` legacy scaling hack)

### Key discoveries
- `__MLONG__` ifdef in type.h is BACKWARDS (WITH selects 16-bit path)
- `dev_t = short` on big-endian: GCC stores 32-bit int, value lands in wrong bytes
- `_EM_WSIZE` missing in kernel: ioctl encoding (SYSGETENV) silently mismatched
- `tty_timeout = (clock_t)-1` is NEGATIVE on signed clock_t → tty_wakeup every tick
- FS stack had ZERO room: _sizes exactly matched BSS, no space for function calls
- `force_timeout()` = `tty_timeout = 0` — must only be called for real RX data
- SCC DCD must be asserted or rs_read sends SIGHUP and drops all input
- NR_TASKS=10 (not 5): 8 base + NR_CTRLRS(1) + ENABLE_PRINTER(1)
- Console+RS232 share rs_lines[0]: second rs_init overwrites tty backpointer
- mkrootfs indirect block: `zones` list never updated in loop → only last zone in slot 0
- Z8530 Reset Highest IUS must not clear pending RX if FIFO still has data
- `tcflag_t` is `unsigned short` (2 bytes), not int — struct offsets differ from expected

### Key hardware findings
- SCC Channel A = console connector, Channel B = RS-422 (timer via BRG)
- 68020 exception frames: format word adds 2 bytes after PC
- `.s` (lowercase) extension skips C preprocessing — renamed to `.S`
- On real hardware, SCC DCD is tied to RS-232 pin 8 (needs hardware pull-up)
- SCSI selection uses bus control latch at 0x06000000, NOT NCR 5380 ICR

## SCSI Driver Status (IN PROGRESS)
The SCSI block device driver (`agfascsi.c`) is compiled and linked into the kernel.
The `scsi_task` is registered as CTRLR(0). A 10MB test disk image (`disk.img`) exists.

**Current issue:** The kernel crashes with SIGFPE at FS entry (0x2029100) after adding the
SCSI driver. The SCSI code added ~2560 bytes of text + large BSS (partition tables, buffers).
This shifted all memory layout addresses. `build.sh` was updated to recompute _sizes with
stack padding (MM+16, FS+32, INIT+8 clicks) and all addresses are correct in the proc table.
But the rootfs ROM offset changed from 0x15000 to 0x15200, and while `memory_agfa.c` was
updated, the crash persists — possibly stale object files or a build ordering issue.

**Next steps:**
1. Clean rebuild from scratch (`build.sh` does `make clean` per component)
2. Verify rootfs offset matches between mkrom.py (0x15200) and memory_agfa.c (0x15200)
3. Verify mkrootfs.py `total_size` matches: `0xA0000 - 0x15200`
4. If crash persists, bisect: try with NR_SCSI_DRIVES=1 but WITHOUT registering scsi_task
   (leave CTRLR(0) as nop_task) to isolate SCSI BSS impact from task execution
5. Once booting, test SCSI with `-hd disk.img`: `cat /dev/hd0` should read sector 0
6. Create writable Minix V2 filesystem on partition, mount at `/usr`

**Key files:**
- `kernel/agfascsi.c` — complete SCSI block driver (NCR 5380, polled PIO)
- `kernel/agfascsi.h` — register definitions
- `kernel/agfamain.c` — registers scsi_task as CTRLR(0)
- `mkdisk.py` — creates test disk image with Atari-style partition table
- `build.sh` — automated build with correct _sizes + stack padding

## Memory Files
Detailed analysis notes are in the project memory directory:
- `memory/hardware.md` — full hardware details, memory map, RAM layout with 50+ documented offsets
- `memory/disassembly.md` — comprehensive function map for all 6 ROM banks (v7 stats and key improvements)
- `memory/filesystem.md` — HD filesystem format, structures, key ROM functions
- `memory/MEMORY.md` — project overview, file inventory, task status
