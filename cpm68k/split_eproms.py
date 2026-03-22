#!/usr/bin/env python3
"""
split_eproms.py - Split 640KB ROM into 20 AM27C256 EPROM images

Agfa 9000PS ROM layout:
  5 banks × 128KB each
  Each bank: 4 × AM27C256 (32KB) with byte interleave:
    HH = bytes 0, 4, 8, 12, ...  (bits 24-31)
    HM = bytes 1, 5, 9, 13, ...  (bits 16-23)
    LM = bytes 2, 6, 10, 14, ... (bits 8-15)
    LL = bytes 3, 7, 11, 15, ... (bits 0-7)

Output: 20 files named {lane}{bank}.bin
  e.g., HH0.bin, HM0.bin, LM0.bin, LL0.bin for bank 0

Usage: python3 split_eproms.py <rom_image> <output_dir>
"""

import sys, os

BANK_SIZE = 128 * 1024  # 128KB per bank
EPROM_SIZE = 32 * 1024  # 32KB per EPROM (AM27C256)
NUM_BANKS = 5
LANES = ['HH', 'HM', 'LM', 'LL']

def split(rom_path, out_dir):
    with open(rom_path, 'rb') as f:
        rom = f.read()

    if len(rom) != BANK_SIZE * NUM_BANKS:
        print(f"Warning: ROM is {len(rom)} bytes, expected {BANK_SIZE * NUM_BANKS}")
        rom = rom.ljust(BANK_SIZE * NUM_BANKS, b'\xff')

    os.makedirs(out_dir, exist_ok=True)

    for bank in range(NUM_BANKS):
        bank_data = rom[bank * BANK_SIZE : (bank + 1) * BANK_SIZE]

        # Deinterleave: extract every 4th byte for each lane
        for lane_idx, lane_name in enumerate(LANES):
            eprom_data = bytearray()
            for i in range(0, BANK_SIZE, 4):
                eprom_data.append(bank_data[i + lane_idx])

            assert len(eprom_data) == EPROM_SIZE

            filename = f"{lane_name}{bank}.bin"
            filepath = os.path.join(out_dir, filename)
            with open(filepath, 'wb') as f:
                f.write(eprom_data)

            # Check if this EPROM is all 0xFF (empty)
            if all(b == 0xFF for b in eprom_data):
                status = "(empty)"
            else:
                used = sum(1 for b in eprom_data if b != 0xFF)
                status = f"({used} bytes used)"

            print(f"  {filename}: {EPROM_SIZE} bytes {status}")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <rom_image> <output_dir>")
        sys.exit(1)
    split(sys.argv[1], sys.argv[2])
