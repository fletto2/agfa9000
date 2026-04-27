# SYNC.md — Agfa 9000PS Build & Distribution Workflow

How to rebuild and publish ROMs/disk after changing the source. This is a
multi-step pipeline because three OSes (CP/M-68K, Minix 2.0.4, optional
ports like Doom/AW) share one set of EPROMs and one SCSI disk image.

## Source repos

| Repo | Path | Public? | What lives there |
|---|---|---|---|
| **fletto2/agfa9000** | `/home/fletto/agfa9000/` | private (do NOT push) | CP/M, Minix, AW, Doom, NES VGM, emulator source |
| **ki3v-workshop/agfa-mon** | `/home/fletto/ext/src/claude/agfa9000/agfa-mon/` | public | AGFA-MON monitor source AND distributed ROM/disk artifacts in `os_roms/` |

The fletto2/agfa9000 repo is intentionally not public. **All published
artifacts go to agfa-mon's `os_roms/` folder.**

## What needs rebuilding when X changes

| Changed | Rebuild |
|---|---|
| `cpm68k/agfa_bios_bank1.s` | CP/M bank 1 |
| `cpm68k/zork/*.c` | Zork binary, repopulate disk |
| `cpm68k/<app>/Makefile` | That app, repopulate disk |
| `minix/agfa-port/kernel/*.c` | Minix kernel, bank 2 |
| `minix/agfa-port/cmds/*.c` | Minix userland, repopulate disk |
| `anotherworld/*.cpp` | AW binary, repopulate disk |
| `doom/*.c` | Doom binary, repopulate disk |
| `agfa-mon/agfa-monitor/*.m68` | Monitor bank 0 (Adrian builds & burns this; we mirror their EPROMs) |

## Toolchain

```
PATH=/opt/cross/m68k_new/bin:$PATH
```

This gives `m68k-elf-as`, `m68k-elf-ld`, `m68k-elf-nm`, `m68k-elf-objcopy`,
`m68k-elf-gcc` v12.2.0.

## Build sequence (full rebuild)

Always do CP/M first, then Minix. Minix's `build.sh` regenerates `disk.img`
and copies bank 0 EPROMs from CP/M's `eproms/`, so CP/M must be built first.

### 1. CP/M bank 1

```bash
export PATH="/opt/cross/m68k_new/bin:$PATH"
cd /home/fletto/agfa9000/cpm68k

# Apps that go on the C: drive (only if changed):
cd zork && make && cd ..
cd advent && make && cd ..
cd base64 && make && cd ..
cd emacs && make && cd ..

# Bank 1 BIOS (always):
m68k-elf-as -m68020 -o agfa_bios_bank1.o agfa_bios_bank1.s

# Two-pass link to resolve _init address:
m68k-elf-ld -N -T cpm68k_bank1.ld -o /tmp/cpm_check.elf \
    agfa_bios_bank1.o obj/cpm_*.o \
    /opt/cross/m68k_new/lib/gcc/m68k-elf/12.2.0/libgcc.a
INIT_ADDR=$(m68k-elf-nm /tmp/cpm_check.elf | grep "T _init" | awk '{print $1}')
m68k-elf-ld -N -T cpm68k_bank1.ld --defsym _init=0x${INIT_ADDR} \
    -o cpm68k_bank1.elf agfa_bios_bank1.o obj/cpm_*.o \
    /opt/cross/m68k_new/lib/gcc/m68k-elf/12.2.0/libgcc.a
m68k-elf-objcopy -O binary cpm68k_bank1.elf cpm68k_bank1.bin

# Combine monitor (bank 0) + CP/M (bank 1) → split EPROMs in eproms/
python3 combine_rom.py
```

After this, `cpm68k/eproms/` has all 8 bank 0+1 EPROMs.

### 2. Anotherworld / Doom (if changed)

```bash
cd /home/fletto/agfa9000/anotherworld && make    # produces aw.bin AND aw.raw
cd /home/fletto/agfa9000/doom && make -f Makefile.minix3
```

The `aw.raw` (loaded via Minix `run`) is what goes on the SCSI disk.

### 3. Minix kernel + disk image

```bash
export PATH="/opt/cross/m68k_new/bin:$PATH"
cd /home/fletto/agfa9000/minix/agfa-port
bash build.sh
```

This:
- Compiles kernel, MM, FS, INIT, all userland (`cmds/`, `ash/`)
- Builds bank 2 (Minix) EPROMs in `eproms/`
- Copies bank 0 EPROMs from `cpm68k/eproms/` (NOT bank 1)
- Regenerates `disk.img` (2 GB sparse, ~107 MB actual): MIX root + SWP swap + CPM partition + 11 sub-drives
- The Minix root partition is populated with kernel a.out files, /etc, /usr/games (doom.bin, aw.bin, nes.vwad, nesvgm), and userland binaries

**`build.sh` WIPES the CPM partition.** So after this step you must
repopulate CP/M (next step).

### 4. Sync CP/M bank 1 EPROMs into Minix's eproms/

`build.sh` only copies bank 0; bank 1 in `minix/agfa-port/eproms/` will be
stale. Sync manually:

```bash
cp /home/fletto/agfa9000/cpm68k/eproms/U297_LL1.bin \
   /home/fletto/agfa9000/cpm68k/eproms/U300_HM1.bin \
   /home/fletto/agfa9000/cpm68k/eproms/U303_HH1.bin \
   /home/fletto/agfa9000/cpm68k/eproms/U305_LM1.bin \
   /home/fletto/agfa9000/minix/agfa-port/eproms/
```

### 5. Repopulate CP/M partition

```bash
cd /home/fletto/agfa9000/cpm68k
python3 populate_cpm.py
```

This writes apps to C: (DUMP, PIP, STAT, MORE, ED, EMACS, ERAQ, WHEREIS,
DDT, DDT68000, SID, MAKE, ADVENT, BASE64, ZORK + ZORK.WAD) and the dev kit
to D:-N: (from `~/src/68k/cpmsim/disk/userN/`).

After this, `disk.img` has fresh CP/M data and the Minix root.

## Test in emulator

```bash
cd /home/fletto/agfa9000/src
./agfa9000 -roms ../cpm68k/eproms/ -hd ../minix/agfa-port/disk.img -ram 4
# In monitor:
#   c    → CP/M
#   u    → Minix (UNIX)
#   B    → BASIC
```

For VERA tests add `-vera`. For automated/scripted testing, pipe input
via stdin:

```bash
(echo "c"; sleep 4; echo "c:"; sleep 1; echo "dir"; sleep 2) | \
    timeout 15 ./agfa9000 -roms ../cpm68k/eproms/ \
                          -hd ../minix/agfa-port/disk.img -ram 4 2>&1 | tail -20
```

## Publishing locations

There are THREE distribution targets, all kept in sync:

1. **`/home/fletto/ext/src/claude/agfa9000/agfa-mon/os_roms/`** —
   local clone of `ki3v-workshop/agfa-mon` GitHub repo. Push to GitHub for
   public distribution.
2. **`/home/fletto/agfa9000/os_roms/`** — local mirror in the source tree
   (NOT pushed; convenience for emulator testing).
3. **`adrian@imxsnd45.com:~/agfa/os_roms/`** — Adrian's server. Adrian
   pulls EPROMs from here for hardware flashing and shares with collaborators.

All three should hold identical EPROM and disk image contents.

## Publishing to ki3v-workshop/agfa-mon (the public repo)

The agfa-mon `os_roms/` folder is the **canonical published location** for
ROM/disk binaries. Adrian and others fetch from here.

### Files to publish

| File | Source |
|---|---|
| `U28[1347]_LL0/LM0.bin`, `U29[14]_HM0/HH0.bin` | bank 0 (monitor — usually unchanged unless agfa-mon source updated) |
| `U297_LL1.bin`, `U300_HM1.bin`, `U303_HH1.bin`, `U305_LM1.bin` | bank 1 (CP/M) — from `cpm68k/eproms/` |
| `U284_LL2.bin`, `U287_LM2.bin`, `U304_HM2.bin`, `U306_HH2.bin` | bank 2 (Minix) — from `minix/agfa-port/eproms/` |
| `disk.img.gz` | **GitHub only** — gzipped `minix/agfa-port/disk.img` (GitHub 100 MB file limit) |
| `disk.img`    | **Adrian's SSH server only** — raw, no gzip needed (faster `cp` to BlueSCSI image) |
| `README.md`   | description (rarely changes) |
| `checksums.txt` | sha256 of all binaries (regenerate every push) |

### Publishing steps

```bash
# 1. Make sure local clone is up to date
cd /home/fletto/ext/src/claude/agfa9000/agfa-mon
git pull origin main

# 2. Copy fresh EPROMs from the build outputs
ROMS=/home/fletto/ext/src/claude/agfa9000/agfa-mon/os_roms

cp /home/fletto/agfa9000/cpm68k/eproms/U281_LL0.bin   $ROMS/
cp /home/fletto/agfa9000/cpm68k/eproms/U283_LM0.bin   $ROMS/
cp /home/fletto/agfa9000/cpm68k/eproms/U291_HH0.bin   $ROMS/
cp /home/fletto/agfa9000/cpm68k/eproms/U294_HM0.bin   $ROMS/

cp /home/fletto/agfa9000/cpm68k/eproms/U297_LL1.bin   $ROMS/
cp /home/fletto/agfa9000/cpm68k/eproms/U300_HM1.bin   $ROMS/
cp /home/fletto/agfa9000/cpm68k/eproms/U303_HH1.bin   $ROMS/
cp /home/fletto/agfa9000/cpm68k/eproms/U305_LM1.bin   $ROMS/

cp /home/fletto/agfa9000/minix/agfa-port/eproms/U284_LL2.bin $ROMS/
cp /home/fletto/agfa9000/minix/agfa-port/eproms/U287_LM2.bin $ROMS/
cp /home/fletto/agfa9000/minix/agfa-port/eproms/U304_HM2.bin $ROMS/
cp /home/fletto/agfa9000/minix/agfa-port/eproms/U306_HH2.bin $ROMS/

# 3. Compress disk image FOR GITHUB ONLY (file size limit).
#    Adrian's server gets the raw .img — no gzip required.
gzip -c /home/fletto/agfa9000/minix/agfa-port/disk.img > $ROMS/disk.img.gz

# 4. Regenerate checksums
cd $ROMS
sha256sum *.bin disk.img.gz > checksums.txt

# 5. Commit and push to GitHub
cd /home/fletto/ext/src/claude/agfa9000/agfa-mon
git add os_roms/ agfa-monitor/    # add agfa-monitor/ if VERA_DETECT or other monitor source changed
git commit -m "Update ROMs and disk image: <short summary of fixes>"
git push origin main

# 6. Mirror to /home/fletto/agfa9000/os_roms/
cp $ROMS/*.bin $ROMS/disk.img.gz $ROMS/checksums.txt /home/fletto/agfa9000/os_roms/

# 7. Sync to Adrian's server (imxsnd45.com).  Push the RAW disk image
#    (not the .gz) — no GitHub size limit applies and Adrian can `cp`
#    it straight to the BlueSCSI image with no `gunzip` step.
ssh adrian@imxsnd45.com "mkdir -p /home/adrian/agfa/os_roms"
scp $ROMS/*.bin $ROMS/README.md \
    /home/fletto/agfa9000/minix/agfa-port/disk.img \
    adrian@imxsnd45.com:/home/adrian/agfa/os_roms/

# Refresh checksums on the server WITHOUT the .gz (it's not pushed)
ssh adrian@imxsnd45.com "cd /home/adrian/agfa/os_roms && \
                          rm -f disk.img.gz && \
                          sha256sum *.bin disk.img > checksums.txt"

# 8. Verify the sync
ssh adrian@imxsnd45.com "ls -la /home/adrian/agfa/os_roms/ && \
                          sha256sum -c /home/adrian/agfa/os_roms/checksums.txt"
```

### What does NOT get pushed

- The fletto2/agfa9000 source repo (cpm68k/, minix/agfa-port/,
  anotherworld/, doom/, src/) — kept private
- ELF/intermediate files (`*.elf`, `*.o`, `*.bin` outside `eproms/`)
- For GitHub: the raw `disk.img` (only the gzipped version, due to 100 MB
  file limit)
- For Adrian's SSH server: the gzipped `disk.img.gz` (raw is fine)

## Sanity checklist before push

- [ ] CP/M boots in emulator (`c` from monitor, `dir` on C: drive shows files)
- [ ] At least one previously-crashing CP/M app runs (e.g., `dump pip.68k`)
- [ ] Minix boots and login works (`u` from monitor → `root` → `ls /`)
- [ ] Minix can run a SCSI-loaded binary (`run /usr/games/doom.bin` or aw.bin)
- [ ] No "SCSI bus is busy" loops during testing
- [ ] EPROM bank 1 timestamps in `cpm68k/eproms/` and `minix/agfa-port/eproms/`
      match (otherwise step 4 above was skipped)

## Common pitfalls

1. **Forgetting to repopulate CP/M after `build.sh`** — Minix's build wipes
   the CPM partition. Adventure/Zork/etc. will be missing.
2. **Stale bank 1 in Minix's eproms/** — `build.sh` doesn't copy bank 1.
   Test users see old CP/M behavior even though source was updated.
3. **Pushing to fletto2/agfa9000** — that's the wrong repo. Only push
   binaries to ki3v-workshop/agfa-mon.
4. **Forgetting to regenerate `checksums.txt`** — users verify before
   flashing; stale checksums cause confusion.
5. **Not gzipping disk.img for GitHub** — the 2 GB sparse file is only ~107 MB
   compressed; pushing uncompressed will exceed GitHub's 100 MB file limit.
   For Adrian's SSH server, push raw `disk.img` (no gzip needed there;
   he `cp`s it straight to the BlueSCSI image without unpacking).
6. **PDMA/PIO confusion** — the SCSI driver should use PDMA-with-DRQ-poll.
   PIO is a fallback. The PDMA cleanup MUST read register 7 (RPIS) after
   clearing MR.DMA or back-to-back reads break.
7. **AGFA-MON's VERA_PUTCHAR clobbering SR** — CP/M's ROM_PUTCHAR/PRINTSTR
   wrappers must save/restore SR around the monitor call, otherwise IPL=7
   gets demoted to IPL=0 and pending IRQs run with CP/M's null vector
   table → freeze.
