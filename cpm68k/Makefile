# CP/M-68K for Agfa 9000PS (ROM disk version)
#
# Single-user CP/M with ROM-embedded floppy disk, same approach as gas68kcpm.
# BIOS + CCP/BDOS + ROM disk all linked into one image.

CROSS = /opt/cross/m68k_new/bin/m68k-elf-
CC = $(CROSS)gcc
AS = $(CROSS)as
LD = $(CROSS)ld
NM = $(CROSS)nm
OBJCOPY = $(CROSS)objcopy
SIZE = $(CROSS)size

# CP/M source (local copy)
CPM_DIR = cpm-src
CPM_C_SRC = bdosmain.c bdosmisc.c bdosrw.c ccp.c conbdos.c dskutil.c fileio.c iosys.c
CPM_S_SRC = bdosif.s ccpbdos.s ccpif.s ccpload.s exceptn.s filetyps.s pgmld2.s stack.s
CPM_C_OBJ = $(addprefix obj/cpm_, $(CPM_C_SRC:.c=.o))
CPM_S_OBJ = $(addprefix obj/cpm_, $(CPM_S_SRC:.s=.o))
CPM_OBJS = $(CPM_C_OBJ) $(CPM_S_OBJ)

# ROM disk from gas68kcpm (if available)
GAS68K = /home/fletto/src/claude/cpm68k/gas68kcpm

# Compiler flags: target 68000 (CP/M code is 68000-compatible)
M68K_CFLAGS = -m68000 -Os -finline-functions -fno-builtin -nostdinc
M68K_ASFLAGS = -m68000
LGCC_DIR = $(dir $(shell $(CC) -m68000 -print-libgcc-file-name))

all: obj cpm68k.bin

obj:
	mkdir -p obj

# BIOS (68020 for Agfa hardware, but 68000 instructions only for compatibility)
agfa_bios.o: agfa_bios.s
	$(AS) -m68000 -o $@ $<

# CP/M C sources
obj/cpm_%.o: $(CPM_DIR)/%.c | obj
	$(CC) $(M68K_CFLAGS) -c $< -o $@

# CP/M assembly sources
obj/cpm_%.o: $(CPM_DIR)/%.s | obj
	$(AS) $(M68K_ASFLAGS) $< -o $@

# Link BIOS + CCP/BDOS
cpm68k_core.elf: agfa_bios.o $(CPM_OBJS) cpm68k.ld
	$(LD) -N -T cpm68k.ld -o $@ agfa_bios.o $(CPM_OBJS) -L$(LGCC_DIR) -lgcc
	@echo "--- Key addresses ---"
	@$(NM) $@ | grep -E ' (cpm|ccpwboot|_init|_bdos|traphndl|rom_disk_base)$$' || true

cpm68k_core.bin: cpm68k_core.elf
	$(OBJCOPY) -O binary $< $@

# ROM disk image
rom_diska.img:
	@if [ -f "$(GAS68K)/rom_diska.img" ]; then \
		cp "$(GAS68K)/rom_diska.img" $@; \
		echo "Copied ROM disk from gas68kcpm (94 tracks, 26 spt)"; \
	else \
		echo "Creating empty ROM disk"; \
		dd if=/dev/zero bs=128 count=$$((94*26)) of=$@ 2>/dev/null; \
	fi

# Final binary: code + ROM disk concatenated
cpm68k.bin: cpm68k_core.bin rom_diska.img
	cat $^ > $@
	@echo "Built: $@ ($$(wc -c < $@) bytes)"
	@echo "  Code: $$(wc -c < cpm68k_core.bin) bytes"
	@echo "  Disk: $$(wc -c < rom_diska.img) bytes"

clean:
	rm -rf obj *.o *.elf *.bin rom_diska.img

size: cpm68k_core.elf
	$(SIZE) $<

.PHONY: all clean size
