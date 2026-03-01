#!/usr/bin/env python3
#
# agfa_fs.py - Read/extract tool for Agfa Compugraphic 9000PS filesystem images
#
# This software is freely distributable.
#
# ============================================================================
#
# The Agfa 9000PS PostScript RIP uses a proprietary filesystem on its
# internal SCSI hard drive (Quantum P40S). This tool can list, extract,
# and analyze files within disk images from these machines.
#
# No external dependencies -- uses only Python 3 standard library.
#
# --------------------------------------------------------------------------
# USAGE
# --------------------------------------------------------------------------
#
# List files:
#   python3 agfa_fs.py <image> list
#   python3 agfa_fs.py <image> list -v          (verbose: show extents)
#   python3 agfa_fs.py <image> list fonts/*      (glob pattern filter)
#
# Extract files:
#   python3 agfa_fs.py <image> extract -o <dir>          (extract all)
#   python3 agfa_fs.py <image> extract -o <dir> <name>   (extract one file)
#   python3 agfa_fs.py <image> extract -o <dir> 'fonts/*' (glob pattern)
#
# Volume info:
#   python3 agfa_fs.py <image> info
#
# Dump file header:
#   python3 agfa_fs.py <image> dump <name>
#   python3 agfa_fs.py <image> dump --page <N>
#
# Verify checksums:
#   python3 agfa_fs.py <image> verify
#
# --------------------------------------------------------------------------
# ON-DISK FORMAT (big-endian, Motorola 68020)
# --------------------------------------------------------------------------
#
# Page size: 1024 bytes
# All multi-byte values are big-endian.
#
# File Header (first page of each file):
#   +0x00  uint32    magic: 0x1EADE460
#   +0x04  uint32    checksum complement (makes page sum = 0)
#   +0x08  uint32    volume_id (constant across all files on volume)
#   +0x0C  uint32    reserved (0)
#   +0x10  uint32    file_id (matches directory entry)
#   +0x14  uint32    timestamp_1
#   +0x18  uint32    timestamp_2
#   +0x1C  uint32    timestamp_3
#   +0x20  uint32    data_size (file content in bytes)
#   +0x24  uint16    name_offset (always 0x0026)
#   +0x26  char[]    filename (null-terminated, path-like with /)
#   +0x88  uint32    num_extents
#   +0x8C  uint32    extent_flags (typically 0x0001FFFF)
#   +0x90  uint32    extent_meta (typically 0xFC180000)
#   +0x94  extent[0..N-1]: each 8 bytes:
#            uint32  start_page
#            uint32  cumulative_page_count
#          Entry 0 is the header page (cumul=0).
#          Entries 1+ are data extents. Pages in extent i =
#            cumul[i] - cumul[i-1].
#
# Root Page (in Sys/Root0's data area):
#   +0x00  uint32    root_magic: 0x5FA87D27
#   +0x04  uint32    checksum complement
#   +0x08  uint32    volume_timestamp
#   +0x0C  uint32    device_ptr (runtime, not meaningful on disk)
#   +0x10  uint32    allocmap_file_id
#   +0x14  uint32    allocmap_page
#   +0x18  uint32    device_ptr2 (runtime)
#   +0x1C  uint32    directory_file_id
#   +0x20  uint32    directory_page
#   +0x24  uint32    root0_page
#   +0x28  uint32    root1_page
#   +0x2C  uint32    unknown
#   +0x30  uint32    last_modified_timestamp
#   +0x34  uint32    total_pages
#
# Directory Entry (variable length, 4-byte aligned):
#   +0x00  uint16    entry_length (total bytes including padding)
#   +0x02  uint16    flags (0x0003 = active file)
#   +0x04  uint32    file_id
#   +0x08  uint32    page_number (of file header)
#   +0x0C  char[]    filename (null-terminated, padded to 4-byte alignment)
#
# Allocation Map (Sys/AllocMap):
#   Bitmap, 1 bit per page. Bit set = page allocated.
#   Big-endian bit ordering (bit 7 of byte 0 = page 0).
#
# Page Checksum:
#   Sum of all 256 uint32 values in a 1024-byte page.
#   Valid pages have checksum = 0.
#
# ============================================================================

import struct
import sys
import os
import signal
import fnmatch
import argparse
from typing import List, Tuple, Optional, NamedTuple, BinaryIO

# Handle broken pipe gracefully (e.g. piping to head)
signal.signal(signal.SIGPIPE, signal.SIG_DFL)

PAGE_SIZE = 1024
FILE_MAGIC = 0x1EADE460
ROOT_MAGIC = 0x5FA87D27


class Extent(NamedTuple):
    start_page: int
    page_count: int


class FileEntry:
    """Represents a file on the Agfa filesystem."""
    def __init__(self):
        self.name: str = ""
        self.file_id: int = 0
        self.header_page: int = 0
        self.flags: int = 0
        self.data_size: int = 0
        self.volume_id: int = 0
        self.timestamps: Tuple[int, int, int] = (0, 0, 0)
        self.num_extents: int = 0
        self.extents: List[Extent] = []
        self.checksum_ok: bool = True

    @property
    def total_data_pages(self) -> int:
        if self.extents:
            return sum(e.page_count for e in self.extents)
        return 0


class RootPage:
    """Represents the filesystem root page."""
    def __init__(self):
        self.magic: int = 0
        self.checksum_ok: bool = False
        self.volume_timestamp: int = 0
        self.allocmap_file_id: int = 0
        self.allocmap_page: int = 0
        self.directory_file_id: int = 0
        self.directory_page: int = 0
        self.root0_page: int = 0
        self.root1_page: int = 0
        self.last_modified: int = 0
        self.total_pages: int = 0


class AgfaFS:
    """Agfa Compugraphic 9000PS filesystem reader."""

    def __init__(self, image_path: str):
        self.image_path = image_path
        self.f: Optional[BinaryIO] = None
        self.image_size: int = 0
        self.root: Optional[RootPage] = None
        self.files: List[FileEntry] = []

    def open(self):
        self.f = open(self.image_path, 'rb')
        self.f.seek(0, 2)
        self.image_size = self.f.tell()
        self.f.seek(0)
        self._read_root()
        self._read_directory()

    def close(self):
        if self.f:
            self.f.close()
            self.f = None

    def __enter__(self):
        self.open()
        return self

    def __exit__(self, *args):
        self.close()

    @staticmethod
    def _page_checksum(data: bytes) -> int:
        """Compute additive checksum over a 1024-byte page."""
        assert len(data) == PAGE_SIZE
        total = 0
        for i in range(0, PAGE_SIZE, 4):
            total = (total + struct.unpack('>I', data[i:i+4])[0]) & 0xFFFFFFFF
        return total

    def _read_page(self, page_num: int) -> bytes:
        """Read a single 1024-byte page."""
        self.f.seek(page_num * PAGE_SIZE)
        return self.f.read(PAGE_SIZE)

    def _read_root(self):
        """Read and parse the filesystem root page."""
        # Root0 file header is at page 0
        hdr_page = self._read_page(0)
        magic = struct.unpack('>I', hdr_page[0:4])[0]
        if magic != FILE_MAGIC:
            raise ValueError(f"Not an Agfa filesystem image: bad magic at page 0 "
                             f"(got 0x{magic:08X}, expected 0x{FILE_MAGIC:08X})")

        # Parse Root0 header to find data location
        hdr_data_size = struct.unpack('>I', hdr_page[0x20:0x24])[0]
        num_extents = struct.unpack('>I', hdr_page[0x88:0x8C])[0]

        # Find the root data page - use extents if available
        root_data_page = 1  # default: page after header
        if num_extents >= 2:
            # Extent entry 1 at 0x9C: uint16 start_page in upper half of uint32
            root_data_page = struct.unpack('>H', hdr_page[0x9C:0x9E])[0]
        elif hdr_data_size > 0:
            root_data_page = 1

        root_page_data = self._read_page(root_data_page)
        root_magic = struct.unpack('>I', root_page_data[0:4])[0]

        if root_magic != ROOT_MAGIC:
            # Try page 1 as fallback
            root_page_data = self._read_page(1)
            root_magic = struct.unpack('>I', root_page_data[0:4])[0]
            if root_magic != ROOT_MAGIC:
                raise ValueError(f"Cannot find root page (magic 0x{ROOT_MAGIC:08X})")

        self.root = RootPage()
        self.root.magic = root_magic
        self.root.checksum_ok = self._page_checksum(root_page_data) == 0
        self.root.volume_timestamp = struct.unpack('>I', root_page_data[0x08:0x0C])[0]
        self.root.allocmap_file_id = struct.unpack('>I', root_page_data[0x10:0x14])[0]
        self.root.allocmap_page = struct.unpack('>I', root_page_data[0x14:0x18])[0]
        self.root.directory_file_id = struct.unpack('>I', root_page_data[0x1C:0x20])[0]
        self.root.directory_page = struct.unpack('>I', root_page_data[0x20:0x24])[0]
        self.root.root0_page = struct.unpack('>I', root_page_data[0x24:0x28])[0]
        self.root.root1_page = struct.unpack('>I', root_page_data[0x28:0x2C])[0]
        self.root.last_modified = struct.unpack('>I', root_page_data[0x30:0x34])[0]
        self.root.total_pages = struct.unpack('>I', root_page_data[0x34:0x38])[0]

    def _read_directory(self):
        """Read and parse the directory from the filesystem."""
        dir_page = self.root.directory_page
        dir_hdr = self._read_page(dir_page)

        magic = struct.unpack('>I', dir_hdr[0:4])[0]
        if magic != FILE_MAGIC:
            raise ValueError(f"Directory header at page {dir_page} has bad magic")

        data_size = struct.unpack('>I', dir_hdr[0x20:0x24])[0]
        num_extents = struct.unpack('>I', dir_hdr[0x88:0x8C])[0]

        # Read directory data using extents
        dir_data = self._read_file_data(dir_hdr, data_size)

        # Parse directory entries
        pos = 0
        while pos < len(dir_data):
            if pos + 12 > len(dir_data):
                break
            entry_len = struct.unpack('>H', dir_data[pos:pos+2])[0]
            if entry_len == 0 or entry_len < 12:
                break
            if pos + entry_len > len(dir_data):
                break

            flags = struct.unpack('>H', dir_data[pos+2:pos+4])[0]
            file_id = struct.unpack('>I', dir_data[pos+4:pos+8])[0]
            page_num = struct.unpack('>I', dir_data[pos+8:pos+12])[0]

            name_end = dir_data.find(b'\x00', pos + 12)
            if name_end < 0:
                name_end = pos + entry_len
            name = dir_data[pos+12:name_end].decode('ascii', errors='replace')

            # Skip deleted/empty entries
            if not name or flags == 0:
                pos += entry_len
                continue

            entry = FileEntry()
            entry.name = name
            entry.file_id = file_id
            entry.header_page = page_num
            entry.flags = flags

            # Read file header for size and extent info
            if page_num * PAGE_SIZE < self.image_size:
                file_hdr = self._read_page(page_num)
                hdr_magic = struct.unpack('>I', file_hdr[0:4])[0]
                if hdr_magic == FILE_MAGIC:
                    entry.checksum_ok = self._page_checksum(file_hdr) == 0
                    entry.volume_id = struct.unpack('>I', file_hdr[0x08:0x0C])[0]
                    entry.data_size = struct.unpack('>I', file_hdr[0x20:0x24])[0]
                    entry.timestamps = (
                        struct.unpack('>I', file_hdr[0x14:0x18])[0],
                        struct.unpack('>I', file_hdr[0x18:0x1C])[0],
                        struct.unpack('>I', file_hdr[0x1C:0x20])[0],
                    )
                    entry.num_extents = struct.unpack('>I', file_hdr[0x88:0x8C])[0]
                    entry.extents = self._parse_extents(file_hdr)
                else:
                    entry.checksum_ok = False

            self.files.append(entry)
            pos += entry_len

    @staticmethod
    def _parse_extents(header_page: bytes) -> List[Extent]:
        """Parse extent entries from a file header page.

        Each extent entry is 8 bytes: two 16-bit values each stored in the
        upper half of a 32-bit word (68020 C struct alignment).
        Entry 0 is the header page (cumul=0). Entries 1+ are data extents.
        """
        num_extents = struct.unpack('>I', header_page[0x88:0x8C])[0]
        if num_extents == 0 or num_extents > 100:
            return []

        extents = []
        prev_cumul = 0
        for i in range(num_extents):
            off = 0x94 + i * 8
            if off + 8 > PAGE_SIZE:
                break
            # Values are uint16 in upper half of uint32 (lower 16 bits = 0)
            start_page = struct.unpack('>H', header_page[off:off+2])[0]
            cumul_pages = struct.unpack('>H', header_page[off+4:off+6])[0]

            if i == 0:
                # Entry 0 is the header page itself (cumul=0)
                prev_cumul = cumul_pages
                continue

            page_count = cumul_pages - prev_cumul
            if page_count > 0:
                extents.append(Extent(start_page, page_count))
            prev_cumul = cumul_pages

        return extents

    def _read_file_data(self, header_page: bytes, data_size: int) -> bytes:
        """Read file data following extents from header page."""
        extents = self._parse_extents(header_page)

        if not extents:
            # No extents - try reading contiguously after header
            num_ext_raw = struct.unpack('>I', header_page[0x88:0x8C])[0]
            if num_ext_raw >= 2:
                # Has extent info but parsed to empty - header-only file
                return b''
            # Fallback: read contiguously
            header_page_num = struct.unpack('>I', header_page[0x94:0x98])[0]
            if header_page_num == 0:
                # Guess from file_id field and directory
                return b''
            pages_needed = (data_size + PAGE_SIZE - 1) // PAGE_SIZE
            buf = bytearray()
            for p in range(pages_needed):
                buf.extend(self._read_page(header_page_num + 1 + p))
            return bytes(buf[:data_size])

        buf = bytearray()
        for ext in extents:
            for p in range(ext.page_count):
                page_offset = (ext.start_page + p) * PAGE_SIZE
                if page_offset + PAGE_SIZE <= self.image_size:
                    buf.extend(self._read_page(ext.start_page + p))
                else:
                    buf.extend(b'\x00' * PAGE_SIZE)

        return bytes(buf[:data_size]) if data_size > 0 else bytes(buf)

    def extract_file(self, entry: FileEntry) -> bytes:
        """Extract a file's data content."""
        if entry.header_page * PAGE_SIZE >= self.image_size:
            return b''
        header_page = self._read_page(entry.header_page)
        magic = struct.unpack('>I', header_page[0:4])[0]
        if magic != FILE_MAGIC:
            return b''
        data_size = entry.data_size
        if data_size == 0:
            # Try to compute from extents
            total_pages = entry.total_data_pages
            if total_pages > 0:
                data_size = total_pages * PAGE_SIZE
        return self._read_file_data(header_page, data_size)

    def find_files(self, pattern: str = "*") -> List[FileEntry]:
        """Find files matching a glob pattern."""
        return [f for f in self.files if fnmatch.fnmatch(f.name, pattern)]


def format_size(size: int) -> str:
    """Format a byte size for display."""
    if size < 1024:
        return f"{size}B"
    elif size < 1024 * 1024:
        return f"{size / 1024:.1f}K"
    else:
        return f"{size / (1024 * 1024):.1f}M"


def cmd_list(fs: AgfaFS, args):
    """List files on the volume."""
    pattern = args.pattern or "*"
    files = fs.find_files(pattern)

    if not files:
        print(f"No files matching '{pattern}'")
        return

    # Sort by page number (disk order)
    files.sort(key=lambda f: f.header_page)

    if args.verbose:
        print(f"{'Name':<40} {'FileID':>8} {'Page':>7} {'Size':>10} "
              f"{'Extents':>3} {'Chk':>3}")
        print("-" * 80)
        for f in files:
            chk = "OK" if f.checksum_ok else "BAD"
            size_str = format_size(f.data_size) if f.data_size > 0 else \
                       (format_size(f.total_data_pages * PAGE_SIZE) if f.total_data_pages else "?")
            print(f"{f.name:<40} {f.file_id:>8X} {f.header_page:>7} "
                  f"{size_str:>10} {f.num_extents:>3} {chk:>3}")
            if args.verbose and f.extents:
                for i, ext in enumerate(f.extents):
                    print(f"  extent {i}: page {ext.start_page} "
                          f"({ext.page_count} pages, "
                          f"{ext.page_count * PAGE_SIZE} bytes)")
    else:
        print(f"{'Name':<45} {'Size':>10} {'Page':>7}")
        print("-" * 65)
        for f in files:
            size_str = format_size(f.data_size) if f.data_size > 0 else \
                       (format_size(f.total_data_pages * PAGE_SIZE) if f.total_data_pages else "?")
            print(f"{f.name:<45} {size_str:>10} {f.header_page:>7}")

    print(f"\n{len(files)} files")
    total_size = sum(f.data_size for f in files if f.data_size > 0)
    print(f"Total data: {format_size(total_size)}")


def cmd_info(fs: AgfaFS, args):
    """Show volume information."""
    r = fs.root
    print("Agfa Compugraphic 9000PS Filesystem")
    print("=" * 50)
    print(f"Image:              {fs.image_path}")
    print(f"Image size:         {format_size(fs.image_size)} ({fs.image_size} bytes)")
    print(f"Root magic:         0x{r.magic:08X} {'(valid)' if r.magic == ROOT_MAGIC else '(INVALID)'}")
    print(f"Root checksum:      {'OK' if r.checksum_ok else 'BAD'}")
    print(f"Volume timestamp:   0x{r.volume_timestamp:08X} ({r.volume_timestamp})")
    print(f"Last modified:      0x{r.last_modified:08X} ({r.last_modified})")
    print(f"Total pages:        {r.total_pages} ({format_size(r.total_pages * PAGE_SIZE)})")
    print(f"Page size:          {PAGE_SIZE} bytes")
    print()
    print(f"Root0 page:         {r.root0_page}")
    print(f"Root1 page:         {r.root1_page}")
    print(f"AllocMap page:      {r.allocmap_page} (file_id 0x{r.allocmap_file_id:08X})")
    print(f"Directory page:     {r.directory_page} (file_id 0x{r.directory_file_id:08X})")
    print()

    # File statistics
    prefixes = {}
    for f in fs.files:
        prefix = f.name.split('/')[0] if '/' in f.name else '(root)'
        prefixes[prefix] = prefixes.get(prefix, 0) + 1
    print(f"Total files:        {len(fs.files)}")
    for p in sorted(prefixes.keys()):
        print(f"  {p + ':':.<20} {prefixes[p]:>4}")


def cmd_extract(fs: AgfaFS, args):
    """Extract files from the image."""
    output_dir = args.output
    pattern = args.pattern or "*"
    files = fs.find_files(pattern)

    if not files:
        print(f"No files matching '{pattern}'")
        return

    os.makedirs(output_dir, exist_ok=True)
    extracted = 0
    errors = 0

    for entry in files:
        try:
            data = fs.extract_file(entry)
            if not data and entry.data_size > 0:
                print(f"  SKIP  {entry.name} (could not read data)")
                errors += 1
                continue

            # Create subdirectories as needed
            out_path = os.path.join(output_dir, entry.name.replace('/', os.sep))
            out_dir = os.path.dirname(out_path)
            if out_dir:
                os.makedirs(out_dir, exist_ok=True)

            with open(out_path, 'wb') as out_f:
                out_f.write(data)

            size_str = format_size(len(data))
            print(f"  {size_str:>8}  {entry.name}")
            extracted += 1

        except Exception as e:
            print(f"  ERROR {entry.name}: {e}")
            errors += 1

    print(f"\nExtracted {extracted} files, {errors} errors")


def cmd_dump(fs: AgfaFS, args):
    """Dump file header in hex."""
    if args.page is not None:
        page_num = args.page
    else:
        name = args.name
        matches = [f for f in fs.files if f.name == name]
        if not matches:
            # Try glob
            matches = fs.find_files(name)
        if not matches:
            print(f"File not found: {name}")
            return
        page_num = matches[0].header_page
        print(f"File: {matches[0].name} (page {page_num})")

    page_data = fs._read_page(page_num)
    checksum = AgfaFS._page_checksum(page_data)

    print(f"Page {page_num} (offset 0x{page_num * PAGE_SIZE:X}):")
    print(f"Checksum: 0x{checksum:08X} {'(valid)' if checksum == 0 else '(INVALID)'}")
    print()

    for off in range(0, PAGE_SIZE, 16):
        hex_str = ' '.join(f'{page_data[off+i]:02X}' for i in range(16))
        ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in page_data[off:off+16])
        print(f"  {off:04X}: {hex_str}  {ascii_str}")
        # Stop after first run of all-zero lines
        if off >= 0xC0 and all(b == 0 for b in page_data[off:off+16]):
            remaining_zero = all(b == 0 for b in page_data[off:])
            if remaining_zero:
                print(f"  ... (zero to end of page)")
                break

    # Parse header fields if it's a file header
    magic = struct.unpack('>I', page_data[0:4])[0]
    if magic == FILE_MAGIC:
        print()
        print("Parsed file header:")
        file_id = struct.unpack('>I', page_data[0x10:0x14])[0]
        data_size = struct.unpack('>I', page_data[0x20:0x24])[0]
        vol_id = struct.unpack('>I', page_data[0x08:0x0C])[0]
        ts1 = struct.unpack('>I', page_data[0x14:0x18])[0]
        ts2 = struct.unpack('>I', page_data[0x18:0x1C])[0]
        ts3 = struct.unpack('>I', page_data[0x1C:0x20])[0]
        name_off = struct.unpack('>H', page_data[0x24:0x26])[0]
        name_end = page_data.find(b'\x00', 0x26)
        name = page_data[0x26:name_end].decode('ascii', errors='replace') if name_end > 0x26 else ""
        num_ext = struct.unpack('>I', page_data[0x88:0x8C])[0]

        print(f"  Magic:      0x{magic:08X}")
        print(f"  Checksum:   0x{struct.unpack('>I', page_data[4:8])[0]:08X}")
        print(f"  Volume ID:  0x{vol_id:08X}")
        print(f"  File ID:    0x{file_id:08X} ({file_id})")
        print(f"  Data size:  {data_size} (0x{data_size:X})")
        print(f"  Timestamps: {ts1}, {ts2}, {ts3}")
        print(f"  Name off:   0x{name_off:04X}")
        print(f"  Filename:   {name}")
        print(f"  Extents:    {num_ext}")

        if num_ext > 0 and num_ext <= 100:
            extents = AgfaFS._parse_extents(page_data)
            # Also show the raw header page entry
            hdr_page = struct.unpack('>I', page_data[0x94:0x98])[0]
            print(f"    [header]  page {hdr_page}")
            for i, ext in enumerate(extents):
                print(f"    [{i}]       page {ext.start_page}, {ext.page_count} pages "
                      f"({ext.page_count * PAGE_SIZE} bytes)")

    elif magic == ROOT_MAGIC:
        print()
        print("Parsed root page:")
        print(f"  Root magic:      0x{magic:08X}")
        print(f"  Vol timestamp:   0x{struct.unpack('>I', page_data[0x08:0x0C])[0]:08X}")
        print(f"  AllocMap FID:    0x{struct.unpack('>I', page_data[0x10:0x14])[0]:08X}")
        print(f"  AllocMap page:   {struct.unpack('>I', page_data[0x14:0x18])[0]}")
        print(f"  Directory FID:   0x{struct.unpack('>I', page_data[0x1C:0x20])[0]:08X}")
        print(f"  Directory page:  {struct.unpack('>I', page_data[0x20:0x24])[0]}")
        print(f"  Root0 page:      {struct.unpack('>I', page_data[0x24:0x28])[0]}")
        print(f"  Root1 page:      {struct.unpack('>I', page_data[0x28:0x2C])[0]}")
        print(f"  Last modified:   0x{struct.unpack('>I', page_data[0x30:0x34])[0]:08X}")
        print(f"  Total pages:     {struct.unpack('>I', page_data[0x34:0x38])[0]}")


def cmd_verify(fs: AgfaFS, args):
    """Verify checksums on all file headers."""
    ok = 0
    bad = 0
    for entry in fs.files:
        if entry.header_page * PAGE_SIZE >= fs.image_size:
            print(f"  OUT OF RANGE  {entry.name} (page {entry.header_page})")
            bad += 1
            continue

        page_data = fs._read_page(entry.header_page)
        checksum = AgfaFS._page_checksum(page_data)
        magic = struct.unpack('>I', page_data[0:4])[0]

        if magic != FILE_MAGIC:
            print(f"  BAD MAGIC   {entry.name} (0x{magic:08X})")
            bad += 1
        elif checksum != 0:
            print(f"  BAD CHKSUM  {entry.name} (0x{checksum:08X})")
            bad += 1
        else:
            ok += 1

    # Also verify root pages
    root_page = fs._read_page(1)  # Root0 data page
    root_chk = AgfaFS._page_checksum(root_page)
    if root_chk == 0:
        ok += 1
    else:
        print(f"  BAD CHKSUM  Root0 data page (0x{root_chk:08X})")
        bad += 1

    print(f"\n{ok} pages OK, {bad} bad")


def main():
    parser = argparse.ArgumentParser(
        description="Agfa Compugraphic 9000PS filesystem tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Examples:\n"
               "  %(prog)s image.hda list\n"
               "  %(prog)s image.hda list -v 'fonts/*'\n"
               "  %(prog)s image.hda extract -o output/\n"
               "  %(prog)s image.hda extract -o output/ 'fonts/Times*'\n"
               "  %(prog)s image.hda info\n"
               "  %(prog)s image.hda dump Sys/Root0\n"
               "  %(prog)s image.hda dump --page 1\n"
               "  %(prog)s image.hda verify\n")

    parser.add_argument('image', help='Disk image file')

    subparsers = parser.add_subparsers(dest='command', help='Command')

    # list
    list_parser = subparsers.add_parser('list', aliases=['ls'],
                                        help='List files')
    list_parser.add_argument('-v', '--verbose', action='store_true',
                             help='Show detailed info including extents')
    list_parser.add_argument('pattern', nargs='?', default='*',
                             help='Glob pattern to filter files')

    # extract
    extract_parser = subparsers.add_parser('extract', aliases=['x'],
                                           help='Extract files')
    extract_parser.add_argument('-o', '--output', required=True,
                                help='Output directory')
    extract_parser.add_argument('pattern', nargs='?', default='*',
                                help='Glob pattern to filter files')

    # info
    subparsers.add_parser('info', help='Show volume information')

    # dump
    dump_parser = subparsers.add_parser('dump', help='Dump file or page header')
    dump_parser.add_argument('name', nargs='?', help='Filename to dump')
    dump_parser.add_argument('--page', type=int, default=None,
                             help='Page number to dump')

    # verify
    subparsers.add_parser('verify', help='Verify all checksums')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 1

    try:
        with AgfaFS(args.image) as fs:
            if args.command in ('list', 'ls'):
                cmd_list(fs, args)
            elif args.command in ('extract', 'x'):
                cmd_extract(fs, args)
            elif args.command == 'info':
                cmd_info(fs, args)
            elif args.command == 'dump':
                if args.name is None and args.page is None:
                    print("Error: specify a filename or --page number")
                    return 1
                cmd_dump(fs, args)
            elif args.command == 'verify':
                cmd_verify(fs, args)
    except (ValueError, FileNotFoundError) as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    return 0


if __name__ == '__main__':
    sys.exit(main() or 0)
