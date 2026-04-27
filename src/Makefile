# Makefile for Agfa 9000PS Emulator

CC = gcc
CFLAGS = -O3 -Wall -Wno-unused-result -Wno-unused-variable \
         -DM68K_EMULATE_020=1 -DM68K_EMULATE_040=0 -DM68K_EMULATE_030=0 \
         -DENABLE_INSTR_HOOK=1
LDFLAGS =

MUSASHI_DIR = musashi
# Note: m68kfpu.c is #included by m68kcpu.c, don't compile separately
MUSASHI_SRC = $(MUSASHI_DIR)/m68kcpu.c \
              $(MUSASHI_DIR)/m68kops.c \
              $(MUSASHI_DIR)/m68kdasm.c \
              $(MUSASHI_DIR)/softfloat/softfloat.c

TARGET = agfa9000

# SDL2 support for VERA video output (optional)
SDL2_CFLAGS := $(shell pkg-config --cflags sdl2 2>/dev/null)
SDL2_LIBS := $(shell pkg-config --libs sdl2 2>/dev/null)
ifneq ($(SDL2_LIBS),)
  CFLAGS += -DENABLE_VERA_SDL $(SDL2_CFLAGS)
  LDFLAGS += $(SDL2_LIBS)
endif

all: $(TARGET)

SRC = agfa9000.c scc.c scsi.c via.c ioboard.c vera.c stubs.c

# Include paths for softfloat
CFLAGS += -I$(MUSASHI_DIR)/softfloat

$(TARGET): $(SRC) scc.h scsi.h via.h ioboard.h vera.h $(MUSASHI_SRC)
	$(CC) $(CFLAGS) -I$(MUSASHI_DIR) -o $@ $(SRC) $(MUSASHI_SRC) $(LDFLAGS) -lm -lpthread

clean:
	rm -f $(TARGET)

# Quick test: run with VERA video
test-vera: $(TARGET)
	./agfa9000 -roms ../minix/agfa-port/eproms/ -hd ../minix/agfa-port/disk.img -vera

.PHONY: all clean test-vera
