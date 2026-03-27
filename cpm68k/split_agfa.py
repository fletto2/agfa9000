#!/usr/bin/env python3
"""
split_agfa.py - Split ROM image into Agfa 9000PS EPROM images

Names each file by socket designation (U-number) as printed on the PCB.
Generates all 20 EPROMs (5 banks x 4 byte lanes). Unused banks are 0xFF.

Agfa 9000PS main board (PSATS1TS) socket map:

  Bank 0 (0x00000-0x1FFFF):  U291=HH0  U294=HM0  U283=LM0  U281=LL0
  Bank 1 (0x20000-0x3FFFF):  U303=HH1  U300=HM1  U305=LM1  U297=LL1
  Bank 2 (0x40000-0x5FFFF):  U306=HH2  U304=HM2  U287=LM2  U284=LL2
  Bank 3 (0x60000-0x7FFFF):  U295=HH3  U292=HM3  U301=LM3  U298=LL3
  Bank 4 (0x80000-0x9FFFF):  U16=HH4   U20=HM4   U19=LM4   U17=LL4

Byte interleave (32-bit data bus):
  HH = byte 0 (bits 31-24) of each longword
  HM = byte 1 (bits 23-16)
  LM = byte 2 (bits 15-8)
  LL = byte 3 (bits 7-0)

Usage: python3 split_agfa.py <rom_image> <output_dir>
"""

import sys, os

BANK_SIZE = 128 * 1024   # 128KB per bank
EPROM_SIZE = 32 * 1024   # 32KB per EPROM (AM27C256)
NUM_BANKS = 5

# Socket designations: SOCKET_MAP[bank][lane] = U-number
# Lane order: HH=0, HM=1, LM=2, LL=3
SOCKET_MAP = {
    0: {0: 'U291', 1: 'U294', 2: 'U283', 3: 'U281'},
    1: {0: 'U303', 1: 'U300', 2: 'U305', 3: 'U297'},
    2: {0: 'U306', 1: 'U304', 2: 'U287', 3: 'U284'},
    3: {0: 'U295', 1: 'U292', 2: 'U301', 3: 'U298'},
    4: {0: 'U16',  1: 'U20',  2: 'U19',  3: 'U17'},
}

LANE_NAMES = ['HH', 'HM', 'LM', 'LL']

def split(rom_path, out_dir):
    with open(rom_path, 'rb') as f:
        rom = f.read()

    # Pad to full 5-bank size with 0xFF
    full_size = BANK_SIZE * NUM_BANKS
    rom = rom.ljust(full_size, b'\xff')

    os.makedirs(out_dir, exist_ok=True)

    for bank in range(NUM_BANKS):
        bank_data = rom[bank * BANK_SIZE : (bank + 1) * BANK_SIZE]

        for lane_idx, lane_name in enumerate(LANE_NAMES):
            # Deinterleave: extract every 4th byte
            eprom_data = bytearray()
            for i in range(0, BANK_SIZE, 4):
                eprom_data.append(bank_data[i + lane_idx])

            assert len(eprom_data) == EPROM_SIZE

            socket = SOCKET_MAP[bank][lane_idx]
            filename = f"{socket}_{lane_name}{bank}.bin"
            filepath = os.path.join(out_dir, filename)
            with open(filepath, 'wb') as f:
                f.write(eprom_data)

            is_empty = all(b == 0xFF for b in eprom_data)
            if is_empty:
                status = "0xFF (blank)"
            else:
                used = sum(1 for b in eprom_data if b != 0xFF)
                status = f"{used} bytes used"

            print(f"  {filename:20s}  socket {socket:4s}  bank {bank}  {lane_name}  {status}")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <rom_image> <output_dir>")
        sys.exit(1)
    split(sys.argv[1], sys.argv[2])
