#!/usr/bin/env python3
"""
split_eproms.py - Split ROM into AM27C256 EPROM images

Agfa 9000PS ROM layout:
  N banks x 128KB each (auto-detected from file size)
  Each bank: 4 x AM27C256 (32KB) with byte interleave:
    HH = bytes 0, 4, 8, 12, ...  (bits 24-31)
    HM = bytes 1, 5, 9, 13, ...  (bits 16-23)
    LM = bytes 2, 6, 10, 14, ... (bits 8-15)
    LL = bytes 3, 7, 11, 15, ... (bits 0-7)

Output: 4*N files named {lane}{bank}.bin
  e.g., HH0.bin, HM0.bin, LM0.bin, LL0.bin for bank 0

Usage: python3 split_eproms.py <rom_image> <output_dir>
"""

import sys, os

BANK_SIZE = 128 * 1024  # 128KB per bank
EPROM_SIZE = 32 * 1024  # 32KB per EPROM (AM27C256)
NUM_BANKS = None  # auto-detect from file size
LANES = ['HH', 'HM', 'LM', 'LL']

def split(rom_path, out_dir):
    with open(rom_path, 'rb') as f:
        rom = f.read()

    num_banks = len(rom) // BANK_SIZE
    if len(rom) % BANK_SIZE != 0:
        num_banks += 1
        rom = rom.ljust(num_banks * BANK_SIZE, b'\xff')
    print(f"ROM: {len(rom)} bytes = {num_banks} banks x {BANK_SIZE // 1024}KB = {num_banks * 4} EPROMs")

    os.makedirs(out_dir, exist_ok=True)

    for bank in range(num_banks):
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
