# HD Filesystem Format - Agfa Proprietary

## Overview
- Proprietary filesystem, NOT Unix/FAT
- 1024-byte page size
- Volume: 41,014 pages (41,998,848 bytes) on Quantum P40S 40MB SCSI disk
- 296 valid files: 118 fonts, 163 FC/ (font cache), 5 Sys, 6 DB, 1 diag, 1 user, 2 root-level PS files
- 120 deleted directory entries (empty name, header pages 0xFF-filled)
- 81 files have corrupted headers (mostly FC/ cache entries - 0xFF filled pages)

## Magic Numbers
- `0x1EADE460` - File header magic (at offset 0x00 in every file header page)
- `0x5FA87D27` - Root page magic (at offset 0x00 in Root0/Root1 pages)

## Checksum
- Additive: sum of 256 uint32 big-endian values in each 1024-byte page must equal 0
- Used for both root pages and file headers
- Implementation: `fs_checksum()` at bank 4 ROM offset 0x9C0

## Root Page Structure (Root0 at page 0, Root1 at page 41004)
- Dual-root redundancy with timestamp comparison to determine active root
- Root contains pointers to AllocMap and Directory pages
- Contains volume total page count
- Also stores runtime RAM pointers (0x02017144) that are meaningless on disk

### Root Page Fields
| Offset | Size | Description |
|--------|------|-------------|
| 0x00 | 4 | Magic: 0x5FA87D27 |
| 0x04 | 4 | Checksum adjustment |
| 0x08+ | var | Volume metadata, timestamps |

### Root Extents (at offset 0x80+)
- Same format as file header extents (see below)
- Root0 extent points to page containing directory/allocmap references

## File Header Structure (1024 bytes at page_num * 1024)
| Offset | Size | Description |
|--------|------|-------------|
| 0x00 | 4 | Magic: 0x1EADE460 |
| 0x04 | 4 | Checksum adjustment (makes page sum = 0) |
| 0x08 | 4 | Volume ID |
| 0x10 | 4 | File ID |
| 0x14 | 4 | Timestamp 1 |
| 0x18 | 4 | Timestamp 2 |
| 0x20 | 4 | Data size in bytes |
| 0x26 | var | Filename (null-terminated, max ~90 bytes) |

**NOTE:** File ID is at offset 0x10, NOT 0x04 as originally thought. Offset 0x04 is the checksum.

## Extent Table (in file header, starting at offset ~0x88)
| Offset | Size | Description |
|--------|------|-------------|
| 0x88 | 2 | Number of extents (uint16 in upper half of uint32) |
| 0x8C+ | 8/ea | Extent entries |

### Extent Entry Format (8 bytes each, 68020 C struct alignment)
```
[uint16 start_page][uint16 padding][uint16 cumul_pages][uint16 padding]
```
- Values are uint16 stored in the UPPER HALF of uint32 words (big-endian: bytes 0-1 are value, 2-3 are padding)
- Entry 0: always the header page itself (cumul_pages = 0)
- Entries 1+: data extents
- Pages per extent = cumul_pages[i] - cumul_pages[i-1]
- Files can be fragmented across non-contiguous extents

### Example: fonts/AvantGarde-Book (56,436 bytes)
- 3 extents totaling 56 data pages with other files' pages interleaved

## Directory Structure
- Stored in `Sys/Directory` file (starts at page 9)
- Contains variable-length entries, 4-byte aligned

### Directory Entry Format
```
[uint16 entry_length][uint16 flags][uint32 file_id][uint32 page_number][filename\0][padding]
```
- `flags = 0x0003`: active file
- `flags = 0x0000`: deleted entry
- `page_number * 1024` = byte offset to file header in disk image
- Deleted entries: retain directory slot but have empty filename and header pages are 0xFF-filled
- 416 total directory entries, 296 valid, 120 deleted

## Allocation Map
- `Sys/AllocMap` at page 2
- Simple bitmap: 1 bit per page
- Queried by `fs_is_allocated()` at bank 4 ROM offset 0xD20

## System Files
| Name | Page | Description |
|------|------|-------------|
| Sys/Root0 | 0 | Primary root (magic 0x5FA87D27) |
| Sys/Root1 | 41004 | Backup root |
| Sys/AllocMap | 2 | Block allocation bitmap |
| Sys/Directory | 9 | File directory |
| Sys/Start | varies | Startup configuration |

## SCSI Controller
- NCR 5380 compatible at base address 0x05000001 (odd byte lane)
- 8 consecutive registers at odd addresses
- Pseudo-DMA data port at 0x05000026
- SCSI device structure in RAM at 0x02017144
- Function pointer table at offsets 0xB4-0xC4 in device structure
- Capacity table at 0x02017210

## Key ROM Functions (bank 4, address = 0x80000 + offset)
| Offset | Name | Description |
|--------|------|-------------|
| 0x70E | fs_read_root | Read and validate root page |
| 0x7CA | fs_find_valid_root | Try Root0 then Root1 |
| 0x800 | fs_init_roots | Init dual-root with timestamp comparison |
| 0x89E | fs_sync_root | Write root with checksum |
| 0x9C0 | fs_checksum | Sum 256 uint32 values |
| 0x9E8 | fs_update_timestamp | Update if current > stored + 60 |
| 0xAB0 | fs_glob_match | Wildcard matcher (* and ?) |
| 0xB3E | fs_flush_page | Write dirty cached page |
| 0xB84 | fs_get_page | Page cache with 8KB block reads |
| 0xC0E | fs_alloc_modify | Bitmap allocation/deallocation |
| 0xD20 | fs_is_allocated | Bitmap query |
| 0xD5C | fs_find_free_space | Contiguous free block search |
| 0x5F32 | scsi_init | Full SCSI controller init |

## Tool
- `agfa_fs.py` at `/home/fletto/src/claude/agfa9000/agfa_fs.py`
- Commands: `info`, `list`, `extract`, `dump`, `verify`
- Handles fragmented files, deleted entries, corrupt pages
