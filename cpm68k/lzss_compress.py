#!/usr/bin/env python3
"""
LZSS compressor for CP/M ROM disk images.

Format:
  Stream of flag bytes, each followed by 8 items.
  Flag bit = 1: literal byte (1 byte)
  Flag bit = 0: match reference (2 bytes: offset high nibble + length, offset low byte)
    - offset: 12 bits (1-4096 bytes back in sliding window)
    - length: 4 bits + 3 (3-18 bytes)

Header: 4 bytes big-endian = uncompressed size
"""

import sys, struct

WINDOW_SIZE = 4096
MAX_MATCH = 18
MIN_MATCH = 3

def compress(data):
    out = bytearray()
    out += struct.pack('>I', len(data))  # 4-byte header: uncompressed size
    
    pos = 0
    n = len(data)
    
    while pos < n:
        flag_byte = 0
        flag_pos = len(out)
        out.append(0)  # placeholder for flag byte
        items = bytearray()
        
        for bit in range(8):
            if pos >= n:
                flag_byte |= (1 << bit)  # literal (padding)
                items.append(0)
                continue
            
            # Search for best match in sliding window
            best_len = 0
            best_off = 0
            
            search_start = max(0, pos - WINDOW_SIZE)
            for s in range(search_start, pos):
                ml = 0
                while ml < MAX_MATCH and pos + ml < n and data[s + ml] == data[pos + ml]:
                    ml += 1
                if ml > best_len:
                    best_len = ml
                    best_off = pos - s
                    if ml == MAX_MATCH:
                        break
            
            if best_len >= MIN_MATCH:
                # Match: flag bit = 0
                length_code = best_len - MIN_MATCH  # 0-15
                offset_code = best_off - 1          # 0-4095
                items.append(((offset_code >> 8) & 0x0F) | (length_code << 4))
                items.append(offset_code & 0xFF)
                pos += best_len
            else:
                # Literal: flag bit = 1
                flag_byte |= (1 << bit)
                items.append(data[pos])
                pos += 1
        
        out[flag_pos] = flag_byte
        out += items
    
    return bytes(out)

def decompress(data):
    """Verify decompressor matches."""
    size = struct.unpack('>I', data[:4])[0]
    out = bytearray()
    pos = 4
    
    while len(out) < size:
        if pos >= len(data):
            break
        flags = data[pos]; pos += 1
        
        for bit in range(8):
            if len(out) >= size:
                break
            if flags & (1 << bit):
                out.append(data[pos]); pos += 1
            else:
                b1 = data[pos]; b2 = data[pos+1]; pos += 2
                length = (b1 >> 4) + MIN_MATCH
                offset = ((b1 & 0x0F) << 8) | b2
                offset += 1
                for _ in range(length):
                    out.append(out[-offset])
    
    return bytes(out[:size])

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <input> <output>")
        sys.exit(1)
    
    with open(sys.argv[1], 'rb') as f:
        data = f.read()
    
    compressed = compress(data)
    
    # Verify
    decompressed = decompress(compressed)
    assert decompressed == data, "Decompression verification failed!"
    
    with open(sys.argv[2], 'wb') as f:
        f.write(compressed)
    
    ratio = len(compressed) / len(data) * 100
    print(f"Compressed: {len(data)} -> {len(compressed)} bytes ({ratio:.1f}%)")
