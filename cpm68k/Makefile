# CP/M-68K for Agfa 9000PS — ROM version
#
# Builds a 640KB ROM image for burning into the Agfa's 20 EPROMs
# (5 banks × 4 AM27C256, HH/HM/LM/LL byte interleave).
#
# Layout:
#   0x00000-0x003FF  Vector table (1KB)
#   0x00400-0x017FF  BIOS code+data (~5KB)
#   0x01800-0x077FF  CCP+BDOS (~24KB)
#   0x07800-0x9FFFF  ROM disk A (94 tracks, ~312KB)
#
# Build:
#   make              Build full ROM image
#   make eproms       Split into 20 EPROM images
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

# ROM is 640KB (5 banks × 128KB)
ROM_SIZE = 655360
BANK_SIZE = 131072

all: obj agfa_cpm_rom.bin

obj:
	mkdir -p obj

# BIOS
agfa_bios.o: agfa_bios.s
	$(AS) $(M68K_ASFLAGS) -o $@ $<

# CP/M C sources
obj/cpm_%.o: $(CPM_DIR)/%.c | obj
	$(CC) $(M68K_CFLAGS) -c $< -o $@

# CP/M assembly sources
obj/cpm_%.o: $(CPM_DIR)/%.s | obj
	$(AS) $(M68K_ASFLAGS) $< -o $@

# Link BIOS + CCP/BDOS
cpm68k.elf: agfa_bios.o $(CPM_OBJS) cpm68k.ld
	$(LD) -N -T cpm68k.ld -o $@ agfa_bios.o $(CPM_OBJS) -L$(LGCC_DIR) -lgcc
	@echo "--- Key addresses ---"
	@$(NM) $@ | grep -E ' (cpm|ccpwboot|_init|_bdos|traphndl|biosbase|trap2_dispatch|_start)$$' || true

# Binary (vectors + BIOS + CCP/BDOS, no ROM disk yet)
cpm68k_code.bin: cpm68k.elf
	$(OBJCOPY) -O binary $< $@

# ROM disk image
rom_diska.img:
	@if [ -f "$(GAS68K)/rom_diska.img" ]; then \
		cp "$(GAS68K)/rom_diska.img" $@; \
		echo "Copied ROM disk from gas68kcpm (94 tracks, 26 spt)"; \
	else \
		echo "Creating empty ROM disk (94 tracks × 26 sectors × 128 bytes)"; \
		dd if=/dev/zero bs=128 count=$$((94*26)) of=$@ 2>/dev/null; \
	fi

###
### Full 640KB ROM image
###
agfa_cpm_rom.bin: cpm68k_code.bin rom_diska.img
	dd if=/dev/zero bs=1 count=$(ROM_SIZE) 2>/dev/null | tr '\000' '\377' > $@
	dd if=cpm68k_code.bin of=$@ conv=notrunc 2>/dev/null
	dd if=rom_diska.img of=$@ bs=1 seek=$$((0x7800)) conv=notrunc 2>/dev/null
	@echo ""
	@echo "ROM image: $@ ($(ROM_SIZE) bytes = 640KB)"
	@echo "  Vectors:  0x00000-0x003FF"
	@echo "  BIOS:     0x00400-0x017FF"
	@echo "  CCP+BDOS: 0x01800-0x077FF"
	@echo "  ROM disk: 0x07800-0x5BFFF (~340KB)"
	@echo "  Unused:   0x5C000-0x9FFFF (0xFF fill)"

###
### EPROM split: 5 banks × 4 chips = 20 EPROMs
### Each bank is 128KB = 4 × 32KB (AM27C256)
### 4-wide byte interleave: HH (byte 0), HM (byte 1), LM (byte 2), LL (byte 3)
###
eproms: agfa_cpm_rom.bin
	@mkdir -p eproms
	python3 split_eproms.py $< eproms/
	@echo ""
	@echo "20 EPROM images in eproms/:"
	@ls -la eproms/*.bin

clean:
	rm -rf obj eproms *.o *.elf *.bin rom_diska.img

size: cpm68k.elf
	$(SIZE) $<

.PHONY: all clean size eproms
