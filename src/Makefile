# Makefile for Agfa 9000PS Emulator

CC = gcc
CFLAGS = -O2 -Wall -Wno-unused-result -Wno-unused-variable \
         -DM68K_EMULATE_020=1 -DM68K_EMULATE_040=0 -DM68K_EMULATE_030=0
LDFLAGS =

MUSASHI_DIR = musashi
MUSASHI_SRC = $(MUSASHI_DIR)/m68kcpu.c \
              $(MUSASHI_DIR)/m68kops.c \
              $(MUSASHI_DIR)/m68kdasm.c

TARGET = agfa9000

all: $(TARGET)

SRC = agfa9000.c scc.c scsi.c ioboard.c stubs.c

$(TARGET): $(SRC) scc.h scsi.h ioboard.h $(MUSASHI_SRC)
	$(CC) $(CFLAGS) -I$(MUSASHI_DIR) -o $@ $(SRC) $(MUSASHI_SRC) $(LDFLAGS) -lm

clean:
	rm -f $(TARGET)

# Quick test: run with Adrian's fault
test: $(TARGET)
	@echo "Run with: ./agfa9000 /path/to/roms -stuck 16"
	@echo "Or without faults: ./agfa9000 /path/to/roms"

.PHONY: all clean test
