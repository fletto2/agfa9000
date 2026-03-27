# CP/M-68K for Agfa 9000PS -- ROM version with LZSS-compressed disk
#
# Builds a 128KB ROM image (single bank = 4 EPROMs).
# The ROM disk is LZSS-compressed and decompressed to RAM at boot.
#
# Layout:
#   0x00000-0x003FF  Vector table (1KB)
#   0x00400-0x017FF  BIOS code+data (~5KB, includes LZSS decompressor)
#   0x01800-0x077FF  CCP+BDOS (~24KB)
#   0x07800-0x1FFFF  LZSS-compressed ROM disk (~100KB)
#
# Build:
#   make              Build full ROM image
#   make eproms       Split into 4 EPROM images
#   make clean

CROSS = /opt/cross/m68k_new/bin/m68k-elf-
CC = $(CROSS)gcc
AS = $(CROSS)as
LD = $(CROSS)ld
NM = $(CROSS)nm
OBJCOPY = $(CROSS)objcopy
SIZE = $(CROSS)size

CPM_DIR = cpm-src
CPM_C_SRC = bdosmain.c bdosmisc.c bdosrw.c ccp.c conbdos.c dskutil.c fileio.c iosys.c
CPM_S_SRC = bdosif.s ccpbdos.s ccpif.s ccpload.s exceptn.s filetyps.s pgmld2.s stack.s
CPM_C_OBJ = $(addprefix obj/cpm_, $(CPM_C_SRC:.c=.o))
CPM_S_OBJ = $(addprefix obj/cpm_, $(CPM_S_SRC:.s=.o))
CPM_OBJS = $(CPM_C_OBJ) $(CPM_S_OBJ)

GAS68K = /home/fletto/src/claude/cpm68k/gas68kcpm

M68K_CFLAGS = -m68000 -Os -finline-functions -fno-builtin -nostdinc
M68K_ASFLAGS = -m68000
LGCC_DIR = $(dir $(shell $(CC) -m68000 -print-libgcc-file-name))

# ROM is 128KB (1 bank x 128KB = 4 EPROMs)
ROM_SIZE = 131072
BANK_SIZE = 131072

all: obj agfa_cpm_rom.bin

obj:
	mkdir -p obj

# BIOS needs -m68020 for MOVEC VBR instruction
agfa_bios.o: agfa_bios.s
	$(AS) -m68020 -o $@ $<

obj/cpm_%.o: $(CPM_DIR)/%.c | obj
	$(CC) $(M68K_CFLAGS) -c $< -o $@

obj/cpm_%.o: $(CPM_DIR)/%.s | obj
	$(AS) $(M68K_ASFLAGS) $< -o $@

# Auto-extract _init ROM offset from BIOS object, compute RAM address
INIT_ROM = $(shell $(NM) agfa_bios.o 2>/dev/null | awk '/ _init$$/{print "0x"$$1}')
INIT_RAM = $(shell printf '0x%08X' $$(( $(INIT_ROM) + 0x02000000 )) 2>/dev/null)

cpm68k.elf: agfa_bios.o $(CPM_OBJS) cpm68k.ld
	$(LD) -N -T cpm68k.ld --defsym _init=$(INIT_RAM) -o $@ agfa_bios.o $(CPM_OBJS) -L$(LGCC_DIR) -lgcc
	@echo "--- Key addresses ---"
	@echo "  _init (auto): $(INIT_ROM) (ROM) -> $(INIT_RAM) (RAM)"
	@$(NM) $@ | grep -E ' (cpm|ccpwboot|_init|_bdos|traphndl|biosbase|_start)$$' || true

cpm68k_code.bin: cpm68k.elf
	$(OBJCOPY) -O binary $< $@

# ROM disk: get from gas68kcpm, then LZSS-compress
rom_diska.img:
	@if [ -f "$(GAS68K)/rom_diska.img" ]; then \
		cp "$(GAS68K)/rom_diska.img" $@; \
		echo "Copied ROM disk from gas68kcpm (94 tracks, 26 spt)"; \
	else \
		echo "Creating empty ROM disk (94 tracks x 26 sectors x 128 bytes)"; \
		dd if=/dev/zero bs=128 count=$$((94*26)) of=$@ 2>/dev/null; \
	fi

rom_diska.lzss: rom_diska.img lzss_compress.py
	python3 lzss_compress.py $< $@

###
### 128KB ROM image (1 bank = 4 EPROMs)
###
agfa_cpm_rom.bin: cpm68k_code.bin rom_diska.lzss
	@LZSS_SIZE=$$(wc -c < rom_diska.lzss); \
	TOTAL=$$((0x7800 + $$LZSS_SIZE)); \
	if [ $$TOTAL -gt $(ROM_SIZE) ]; then \
		echo "ERROR: code+disk = $$TOTAL bytes, exceeds $(ROM_SIZE) (128KB)"; \
		exit 1; \
	fi
	dd if=/dev/zero bs=1 count=$(ROM_SIZE) 2>/dev/null | tr '\000' '\377' > $@
	dd if=cpm68k_code.bin of=$@ conv=notrunc 2>/dev/null
	dd if=rom_diska.lzss of=$@ bs=1 seek=$$((0x7800)) conv=notrunc 2>/dev/null
	@LZSS_SIZE=$$(wc -c < rom_diska.lzss); \
	DISK_END=$$((0x7800 + $$LZSS_SIZE)); \
	echo ""; \
	echo "ROM image: $@ ($(ROM_SIZE) bytes = 128KB, 1 bank, 4 EPROMs)"; \
	echo "  Vectors:    0x00000-0x003FF"; \
	echo "  BIOS:       0x00400-0x017FF"; \
	echo "  CCP+BDOS:   0x01800-0x077FF"; \
	echo "  ROM disk:   0x07800-$$(printf '0x%05X' $$DISK_END) ($$LZSS_SIZE bytes LZSS, 312KB uncompressed)"; \
	echo "  Free:       $$(printf '0x%05X' $$DISK_END)-0x1FFFF ($$(( $(ROM_SIZE) - $$DISK_END )) bytes)"

###
### EPROM split: 1 bank x 4 chips = 4 EPROMs
###
eproms: agfa_cpm_rom.bin
	@mkdir -p eproms
	python3 split_eproms.py $< eproms/
	@echo ""
	@echo "4 EPROM images in eproms/:"
	@ls -la eproms/*.bin

clean:
	rm -rf obj eproms *.o *.elf *.bin rom_diska.img rom_diska.lzss

size: cpm68k.elf
	$(SIZE) $<

.PHONY: all clean size eproms
