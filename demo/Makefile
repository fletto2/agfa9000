# Makefile for Agfa 9000PS bare-metal programs
#
# Targets:
#   make              Build RAM diagnostic (S-record + binary)
#   make game         Build Demon Attack game
#   make bootloader   Build Channel A bootloader ROM
#   make clean        Remove build artifacts
#
# The Atlas Monitor's S-record loader (ROM 0x107C) adds 0x02000000 to
# all addresses. S2 records are generated with addresses offset by
# -0x02000000 so they load at the correct RAM location.
#
# Loading via Atlas Monitor:
#   1. Connect terminal to Z8530 Channel B (TxDB pin 19) at 9600 8N1
#   2. Assert CTS on Channel B (ground Z8530 pin 23)
#   3. Power on — Atlas Monitor prompt appears
#   4. Type 'S', send .s28 file
#   5. Type 'G' to execute

CROSS = /opt/cross/m68k_new/bin/m68k-elf-
CC = $(CROSS)gcc
AS = $(CROSS)as
LD = $(CROSS)ld
OBJCOPY = $(CROSS)objcopy
OBJDUMP = $(CROSS)objdump

CFLAGS = -m68020 -O2 -nostdlib -ffreestanding -fno-builtin \
         -Wall -Wno-implicit-int -Wno-implicit-function-declaration \
         -Wno-return-type
ASFLAGS = -m68020
LDFLAGS = -T link.ld -nostdlib

# Address offset: Atlas Monitor adds 0x02000000, so subtract it for S-records
ADDR_OFFSET = -0x02000000

# ---- RAM Diagnostic (default target) ----

all: ramtest.s28 ramtest.bin

ramtest_crt0.o: crt0.S
	$(AS) $(ASFLAGS) -o $@ $<

ramtest.o: ramtest.c
	$(CC) $(CFLAGS) -c -o $@ $<

ramtest.elf: ramtest_crt0.o ramtest.o link.ld
	$(LD) $(LDFLAGS) -o $@ ramtest_crt0.o ramtest.o

ramtest.s28: ramtest.elf
	$(OBJCOPY) -O srec --change-addresses $(ADDR_OFFSET) $< $@
	@echo "S2 records with addresses offset by $(ADDR_OFFSET) for Atlas Monitor"

ramtest.bin: ramtest.elf
	$(OBJCOPY) -O binary $< $@

# ---- Demon Attack Game ----

game: demon_agfa.s28 demon_agfa.bin

game_crt0.o: crt0.S
	$(AS) $(ASFLAGS) -o $@ $<

demon_agfa.o: demon_agfa.c
	$(CC) $(CFLAGS) -c -o $@ $<

demon_agfa.elf: game_crt0.o demon_agfa.o link.ld
	$(LD) $(LDFLAGS) -o $@ game_crt0.o demon_agfa.o

demon_agfa.s28: demon_agfa.elf
	$(OBJCOPY) -O srec --change-addresses $(ADDR_OFFSET) $< $@

demon_agfa.bin: demon_agfa.elf
	$(OBJCOPY) -O binary $< $@

# ---- Channel A Bootloader ROM ----

bootloader: bootloader.bin

bootloader.o: bootloader.S
	$(AS) $(ASFLAGS) -o $@ $<

bootloader.elf: bootloader.o
	$(LD) -Ttext=0x00000000 -nostdlib -o $@ $<

bootloader.bin: bootloader.elf
	$(OBJCOPY) -O binary $< $@

# ---- Utilities ----

clean:
	rm -f *.o *.elf *.s28 *.bin *.lst

size: ramtest.elf
	$(CROSS)size $<

.PHONY: all game bootloader clean size
