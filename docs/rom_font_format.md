# Adobe ROM Font Format — Agfa 9000PS

## Overview

Bank 1 (ROM 0x20000–0x3AEB7, 108KB) contains 8 built-in fonts in Adobe's
proprietary ROM font format. This is **not** standard PFB or eexec — it's a
linked-list directory of font descriptor records with embedded glyph data,
designed for the Atlas PostScript reference platform.

## Fonts

| Font                    | Version  | ROM Address | Size    |
|-------------------------|----------|-------------|---------|
| Helvetica               | 001.002  | 0x25DAC     | 17.0 KB |
| Helvetica Bold          | 001.002  | 0x2A1CC     | 17.1 KB |
| Helvetica Oblique       | 001.002  | 0x2E63C     | 0.8 KB  |
| Helvetica Bold Oblique  | 001.002  | 0x2E94C     | 2.5 KB  |
| Courier                 | 001.004  | 0x2F364     | 20.1 KB |
| Courier Oblique         | 001.004  | 0x343C8     | 1.1 KB  |
| Courier Bold            | 001.004  | 0x3485C     | 1.1 KB  |
| Courier Bold Oblique    | 001.004  | 0x34CEC     | 24.5 KB |

The Oblique variants are small because they share glyph data with the upright
versions — they only store the oblique transformation matrix.

## Directory Structure

The region 0x20000–0x25DAB contains font directory entries (linked list).
Each entry is a variable-length record:

```
struct font_dir_entry {
    uint32_t tag;           // 0x03000000 = font record marker
    uint32_t ram_ref;       // RAM address for runtime (0x020Cxxxx)
    uint32_t type_tag;      // 0x01000000 or 0x15000000
    uint32_t aux_data;      // varies (bitmask, length, or 0xFFFFFF9F)
    // ... may repeat (multiple directory references per font)
};
```

Tag 0x03000000 appears throughout as a record delimiter. The 0x020Cxxxx
values are RAM addresses where the PS interpreter loads font data at runtime.

## Font Descriptor (at each font)

Each font starts with a cleartext ASCII header:

```
001.002Helvetica is a registered trademark of Allied Corporation.HelveticaHelveticaMediumdic
```

Format: `VVV.VVV` + copyright + FontName + FamilyName + Weight + `dic`

Immediately after the cleartext:

```
struct font_post_header {     // big-endian
    uint16_t width_entries;   // character width table entries (9 for Helvetica, 19 for Courier)
    uint16_t metric_entries;  // font metric entries
    uint16_t total_entries;   // width_entries + 1
    uint16_t reserved;        // 0
    uint32_t encoding_flags;  // bit position encodes font index (0x10, 0x80, etc.)
    uint32_t data_ptr1;       // ROM address → character width/metric tables
    uint32_t data_ptr2;       // ROM address → encoding vectors / adjustment tables
};
```

## Glyph Data

After the post-header, the bulk font data follows. It is NOT standard eexec
encryption. The data contains:

- Character width tables (indexed by character code)
- Font descriptor arrays (family, weight, style metadata)
- Encoding vectors (character name → code mappings)
- Font metric structures (ascender, descender, cap height, etc.)
- Glyph outline data (CharStrings in a proprietary binary encoding)

The glyph outlines use Adobe's Type 1 CharString format but are stored in
raw binary, not eexec-encrypted. The CharString interpreter in the PS engine
(Bank 2-3) processes these directly.

## Data Between Fonts (0x20000–0x25DAB)

The 24KB region before the first font (Helvetica) contains:
- Font directory linked list (tag 0x03000000 records)
- RAM reference table (0x020Cxxxx addresses)
- Cross-reference pointers between font variants

## Encoding Flags

Each font has a unique bit position in the `encoding_flags` field:

| Font                   | Flag          |
|------------------------|---------------|
| Helvetica              | 0x00000010    |
| Helvetica Bold         | 0x00000080    |
| Helvetica Oblique      | 0x00000400    |
| Helvetica Bold Oblique | 0x00002000    |
| Courier                | 0x00010000    |
| Courier Oblique        | 0x00080000    |
| Courier Bold           | 0x00400000    |
| Courier Bold Oblique   | 0x02000000    |

This is a selection bitmask — the PS `findfont` operator uses these flags
to locate fonts in ROM.

## PostScript Programs in ROM

Bank 0 contains two embedded PostScript programs:

### Test Page (0x08690, 2.8KB)
A complete PostScript program that renders a diagnostic test page:
- Font re-encoding procedure (`ReEncodeSmall`)
- Bordered page with rounded corners and grid
- Moiré pattern test (35 nested scaled squares)
- Gray gradient arc fan (13 steps)
- System info: firmware revision, serial channel config, resolution, page count

### Operator Name Table (0x0308B, 3KB)
Concatenated PostScript operator names used by the interpreter's name lookup:
`def`, `vmstatus`, `setrom`, `setram`, `save`, `restore`, `dictfull`,
`dictstackoverflow`, etc.

### Status Dict Entry (Bank 4, 0x90200, 34 bytes)
```postscript
statusdict/customstring true put
```

## SCC Communication Code (0x3AEB8–0x3FFFF)

The remaining 21KB after the font data in Bank 1 is **executable 68020 code**
(not font data). This implements the SCC serial communication subsystem:
- DMA state machine (states 1→2→3→4→5→0)
- SCC channel configuration
- IO board handshake protocol ("004PWR")
- Stream I/O subsystem
