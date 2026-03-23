# Agfa CP/M-68K Test ROMs

CP/M-68K for the Agfa Compugraphic 9000PS. Burns into the existing EPROM
sockets — no hardware modifications needed. Runs with the stock 2MB RAM.

## What's included

The entire system fits in **Bank 0 only** (4 EPROMs). Banks 1–4 are blank
(0xFF fill) and can be left with the original Adobe ROMs if you prefer —
the CP/M code never touches addresses above 0x1FFFF.

### Programs on the ROM disk

```
STAT.68K     PIP.68K      ED.68K       DDT.68K      DUMP.68K
SID.68K      MORE.68K     ERAQ.68K     WHEREIS.68K  BBYE.68K
SPLIT.68K    ADVENT.68K
```

The ROM disk is LZSS-compressed in the EPROMs and decompressed to RAM at
boot (~100KB compressed → 312KB). Read-only.

## EPROM files → socket map

Each `.bin` file is named `Uxxx_LANEn.bin` where `Uxxx` is the socket
silk-screen label on the Agfa main board (PSATS1TS).

| File               | Socket | Byte lane          | Size |
|--------------------|--------|--------------------|------|
| `U291_HH0.bin`     | U291   | HH (bits 31–24)   | 32KB |
| `U294_HM0.bin`     | U294   | HM (bits 23–16)   | 32KB |
| `U283_LM0.bin`     | U283   | LM (bits 15–8)    | 32KB |
| `U281_LL0.bin`     | U281   | LL (bits 7–0)     | 32KB |

Only Bank 0 is needed. Banks 1–4 are not used by CP/M — leave the
original Adobe EPROMs in those sockets.

### Swapped channel variant

The `*_swapped.bin` files use **SCC Channel A** (RS-422 port) for the
console instead of Channel B. Try these if Channel B doesn't produce
output on your serial adapter — the Z8530 has two channels going to
different physical connectors.

| File                        | Socket | Console channel |
|-----------------------------|--------|-----------------|
| `U291_HH0_swapped.bin`     | U291   | Channel A       |
| `U294_HM0_swapped.bin`     | U294   | Channel A       |
| `U283_LM0_swapped.bin`     | U283   | Channel A       |
| `U281_LL0_swapped.bin`     | U281   | Channel A       |

## Burning

1. Use AM27C256 EPROMs (or compatible 32K×8: 27C256, W27C256, AT27C256, SST27SF256)
2. Burn each `.bin` file to the EPROM matching its socket label
3. **You only need to burn the 4 Bank 0 EPROMs** (U291, U294, U283, U281)
4. Banks 1–4 can be blank EPROMs or the original Adobe ROMs — doesn't matter

## Installation

1. Power off the Agfa, disconnect mains
2. Pull the original 4 Bank 0 EPROMs:
   - **U291** (HH0), **U294** (HM0), **U283** (LM0), **U281** (LL0)
3. Keep the originals safe — you'll want them to restore PostScript later
4. Insert the 4 CP/M EPROMs into the same sockets
5. Banks 1–4: leave the original Adobe EPROMs in place (CP/M ignores them)

## Serial console

CP/M uses **SCC Channel B** — same serial port as the Atlas Monitor:

- **Baud rate:** 9600
- **Data bits:** 8
- **Parity:** None
- **Stop bits:** 1
- **Flow control:** None
- **Connector:** TxDB = pin 19, RxDB = pin 22 on the Z8530

Connect a USB-to-serial adapter (3.3V or 5V TTL) to the debug header.
The active pins are the same ones the Atlas Monitor uses — if you've
already found the serial output, this is the same port.

Ground **/CTSB** (pin 30 on the Z8530) to keep CTS asserted, otherwise
the SCC won't transmit. A simple wire from pin 30 to ground will do.

## Boot sequence

1. Power on
2. 68020 resets, loads SSP and PC from Bank 0 vectors
3. Preloader copies BIOS + CCP/BDOS from ROM to RAM at 0x02000000
4. LZSS decompressor expands the ROM disk (100KB → 312KB) into RAM
5. BIOS sets VBR to RAM, initializes SCC at 9600 8N1
6. Banner appears on serial console:
   ```
   Agfa CP/M-68K v1.5
   Z8530 Channel B, 9600 8N1
   ```
7. `A>` prompt — you're in CP/M

## Using CP/M

```
A>dir                    List files on the ROM disk
A>stat *.*               Show file sizes
A>type FILE.TXT          Display a text file
A>advent                 Play Colossal Cave Adventure
A>dump FILE.68K          Hex dump a file
A>ddt                    Dynamic Debugging Tool (68K debugger)
A>sid                    Symbolic Instruction Debugger
```

The ROM disk is read-only (it's decompressed from ROM into RAM).
`ERA` and `REN` will report errors. `PIP` can copy files to the
console but not to disk.

## Restoring PostScript

To put the Agfa back to its original PostScript firmware:

1. Power off
2. Remove the 4 CP/M EPROMs from U291, U294, U283, U281
3. Reinstall the original 4 Bank 0 Adobe EPROMs
4. Power on — the Atlas Monitor and PostScript interpreter will boot normally

## Technical details

- **CPU:** Motorola 68020 @ 16MHz (uses MOVEC VBR for vector relocation)
- **RAM:** 2MB at 0x02000000 (stock configuration, no repair needed)
- **ROM disk:** 94 tracks, 26 sectors/track, 128 bytes/sector, 2KB blocks
- **TPA:** ~1.6MB (0x02050000–0x021F0000) — plenty for any CP/M program
- **Compression:** LZSS (312KB disk → 100KB in ROM), decompressed at boot
- **Exception handling:** Patched for 68020 stack frames (format word in RTE)
