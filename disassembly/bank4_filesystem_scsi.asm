; ======================================================================
; AGFA COMPUGRAPHIC 9000PS - BANK4 ANNOTATED DISASSEMBLY
; ======================================================================
; Filesystem, SCSI driver, C runtime (Sun CC), software FPU, 3 malloc subsystems
; ROM addresses: 0x80000 - 0x9FFFF
; Chunk size: 0xC00 bytes
; ======================================================================
;
; HARDWARE CORRECTIONS (verified by Adrian, 2026-03):
;   0x04000000 = R6522 VIA #1 (IO board communication, NOT SCC)
;   0x04000020 = R6522 VIA #2 (IO board communication)
;   0x05000000 = NCR/AM5380 SCSI (stride-1, regs 0-7)
;   0x05000020 = NCR 5380 pseudo-DMA port
;   0x06000000 = Bus control latch (NOT SCSI — rendering/FIFO)
;   0x07000000 = Z8530 SCC (ONLY SCC on main board)
;     Channel A (+2/+3) = RS-232 console @ 9600 8N1
;     Channel B (+0/+1) = RS-422
;   IRQ levels: VIA1=IPL4, VIA2=IPL1, SCC=IPL6 (autovector)
; Previously labeled "SCC #1" — now corrected to VIA #1.
; SCSI controller is AMD AM5380 (register-compatible with NCR 5380).

; === CHUNK 1: 0x80000-0x80C00 ===

### 1. `add_page_to_free_list` (0x80000)
**Entry:** 0x80000  
**Purpose:** Adds a page number to a sorted free page list. Maintains a list of free pages (page number + count pairs) in sorted order. Checks if page already exists, finds insertion point, and adds if not found. Used by filesystem for tracking free disk pages.  
**Arguments:** Page number in D7 (from fp@(12)), filesystem structure pointer in A5 (from fp@(8))  
**RAM accessed:** 0x2016e98 (free list structure), 0x20008f4 (stack pointer save area)  
**Calls:** 0x5354 (error handler)  
**Key behavior:** Maintains count of free blocks and total free space in the free list structure at 0x2016e98. Each entry is 8 bytes: page number (4 bytes) + count (4 bytes).

### 2. `fill_buffer_with_random_data` (0x80084)
**Entry:** 0x80084  
**Purpose:** Fills a buffer with pseudo-random data using a linear congruential generator (LCG). Used during filesystem initialization/formatting to write random data to disk.  
**Arguments:** Structure pointer at fp@(8), size at fp@(12)  
**RAM accessed:** 0x2016e94 (random seed)  
**Calls:** 0xd98c (malloc), 0xdb6c (free), 0x5354 (error)  
**Key behavior:** Uses LCG: seed = seed * 1103515245 + 907633129 (same as ANSI C rand()). Allocates 0x400 bytes buffer, fills with random longs in batches of 256.

### 3. `filesystem_init` (0x8018a)
**Entry:** 0x8018a  
**Purpose:** Initializes filesystem structures. Sets up root directory magic (0x5FA87D27), allocates buffers, initializes SCSI, sets up file allocation tables, bitmap allocation, and directory structures.  
**Arguments:** Filesystem structure pointer at fp@(8), parameter at fp@(12)  
**RAM accessed:** 0x2016e98 (free list), 0x20008f4 (stack pointer)  
**Calls:** 0x80590 (flush), 0xd818 (malloc), 0xdf1c (SCSI init), 0x807ca (find filesystem), 0x8089e (write), 0x5354 (error)  
**Key behavior:** Extensive filesystem setup including setting magic numbers, calculating sizes, allocating free list (0x7e4 bytes), initializing SCSI, writing root directory, setting up allocation bitmap.

### 4. `flush_filesystem` (0x80590)
**Entry:** 0x80590  
**Purpose:** Flushes filesystem buffers to disk. Checks if filesystem is dirty, writes back if needed, resets dirty flag. Also updates allocation table if needed.  
**Arguments:** Filesystem structure pointer at fp@(8)  
**RAM accessed:** Filesystem structure fields  
**Calls:** 0xf178 (write), 0x806de (sync), 0xd8d0 (SCSI command)  
**Key behavior:** Conditional write-back based on dirty flag at offset 0x3C. Updates allocation table pointer at offset 0x2C if needed.

### 5. `get_filesystem_info` (0x805f0)
**Entry:** 0x805f0  
**Purpose:** Copies filesystem statistics/info to a buffer. Copies 5 fields (20 bytes) from filesystem structure to output buffer.  
**Arguments:** Source structure at fp@(8), dest buffer at fp@(12)  
**Key behavior:** Copies fields at offsets: 0x3C (dirty flag), 0x40 (unknown), 0x44 (total pages), 0x34 (allocated pages?), 0x6E (unknown).

### 6. `log_scsi_command` (0x80626)
**Entry:** 0x80626  
**Purpose:** Logs SCSI command details to a buffer. Formats SCSI command information (opcode, LUN, etc.) into a string for debugging.  
**Arguments:** SCSI command structure at fp@(8), buffer at fp@(12)  
**Calls:** 0x88c0 (sprintf/format)  
**Key behavior:** Checks SCSI opcode (0x7a90, 0x7a91) and selects appropriate string. Formats command details including disk address, memory address, file ID, page count.

### 7. `log_scsi_status` (0x80692)
**Entry:** 0x80692  
**Purpose:** Logs SCSI command completion status to a buffer. Appends status information after command log.  
**Arguments:** SCSI command structure at fp@(8), buffer at fp@(12)  
**Calls:** 0x80626 (log_scsi_command), 0x88c0 (sprintf)  
**Key behavior:** Formats status information including last status value at offset 0x9C in SCSI command structure.

### 8. `sync_filesystem` (0x806de)
**Entry:** 0x806de  
**Purpose:** Synchronizes filesystem metadata to disk. Writes allocation table and other metadata structures.  
**Arguments:** Filesystem structure pointer at fp@(8)  
**Calls:** 0x807ca (find filesystem), 0x8089e (write)  
**Key behavior:** Finds filesystem root, writes metadata page (page 1).

### 9. `find_filesystem_page` (0x8070e)
**Entry:** 0x8070e  
**Purpose:** Finds and loads a specific filesystem page from disk. Handles SCSI errors and validates filesystem magic.  
**Arguments:** Filesystem structure pointer at fp@(8), page number at fp@(12)  
**Returns:** Pointer to loaded page in D0, or NULL on error  
**RAM accessed:** 0x20008f4 (stack pointer)  
**Calls:** 0xdf1c (SCSI init), 0xf076 (read), 0x809c0 (checksum), 0xd8d8 (error handler), 0x5354 (error)  
**Key behavior:** Validates filesystem magic (0x5FA87D27), calculates checksum, handles SCSI errors with retry logic.

### 10. `find_filesystem_root` (0x807ca)
**Entry:** 0x807ca  
**Purpose:** Searches for and loads the root filesystem page. Tries both possible locations (pages 0 and 1).  
**Arguments:** Filesystem structure pointer at fp@(8)  
**Returns:** Pointer to root page in D0  
**Calls:** 0x8070e (find_filesystem_page), 0x5354 (error)  
**Key behavior:** Tries pages 0 and 1, validates filesystem magic, returns first valid root page found.

### 11. `validate_filesystem` (0x80800)
**Entry:** 0x80800  
**Purpose:** Validates filesystem integrity by checking all filesystem pages.  
**Arguments:** Filesystem structure pointer at fp@(8)  
**Calls:** 0x8070e (find_filesystem_page), 0xf0ac (free_page), 0x5354 (error)  
**Key behavior:** Checks each filesystem page, validates size and magic, frees invalid pages.

### 12. `write_filesystem_page` (0x8089e)
**Entry:** 0x8089e  
**Purpose:** Writes a filesystem page to disk with checksum calculation.  
**Arguments:** Filesystem structure pointer at fp@(8), page number at fp@(12)  
**Calls:** 0xf076 (read), 0x809e8 (update_timestamp), 0xdcf8 (memcpy), 0x809c0 (checksum), 0xdf1c (SCSI init), 0xf090 (read_page), 0xf0ac (free_page)  
**Key behavior:** Updates timestamp, calculates checksum, writes page to disk, handles SCSI errors.

### 13. `calculate_checksum` (0x809c0)
**Entry:** 0x809c0  
**Purpose:** Calculates a simple checksum of a 256-byte buffer (64 longs).  
**Arguments:** Buffer pointer at fp@(8)  
**Returns:** Checksum in D0  
**Key behavior:** Sums 64 long words (256 bytes), returns 32-bit sum.

### 14. `update_timestamp` (0x809e8)
**Entry:** 0x809e8  
**Purpose:** Updates filesystem timestamp and flushes if needed.  
**Arguments:** Filesystem structure pointer at fp@(8)  
**Returns:** Current timestamp in D0  
**Calls:** 0xe040 (get_time), 0x806de (sync_filesystem)  
**Key behavior:** Gets current time, updates timestamp in filesystem structure, flushes if timestamp exceeds threshold.

### 15. **MISSED FUNCTION: `wildcard_match` (0x80ab0)**
**Entry:** 0x80ab0  
**Purpose:** Compares two strings with wildcard support ('*' and '?'). Used for filename pattern matching.  
**Arguments:** Pattern string at fp@(8), target string at fp@(12)  
**Returns:** Boolean match result in D0 (1=match, 0=no match)  
**Key behavior:** Handles '*' (match zero or more characters) and '?' (match exactly one character). Recursive for '*'.

### 16. **MISSED FUNCTION: `initialize_file_handle` (0x80b12)**
**Entry:** 0x80b12  
**Purpose:** Initializes a file handle structure. Sets default values for a new file handle.  
**Arguments:** Filesystem pointer at fp@(8), file handle structure at fp@(12)  
**Key behavior:** Sets file pointer to -1, clears flags, zeroes position fields.

### 17. **MISSED FUNCTION: `close_file_handle` (0x80b3e)**
**Entry:** 0x80b3e  
**Purpose:** Closes a file handle, flushing any pending writes.  
**Arguments:** File handle structure at fp@(8)  
**Calls:** 0xf0ac (free_page)  
**Key behavior:** Checks if file is open, flushes if dirty, resets handle to closed state.

### 18. **MISSED FUNCTION: `seek_file` (0x80b84)**
**Entry:** 0x80b84  
**Purpose:** Seeks to a position within a file, loading the appropriate page if needed.  
**Arguments:** File handle structure at fp@(8), position at fp@(12)  
**Calls:** 0x80b3e (close_file_handle), 0xf076 (read), 0xded8 (allocate_buffer)  
**Key behavior:** Calculates page number, loads page if different from current, updates buffer pointers.

### 19. **String table (0x80a24-0x80ac9)**
**Address:** 0x80a24  
**Size:** 0xA5 bytes  
**Format:** Null-terminated strings for debugging and filesystem paths:
- 0x80a24: "Sys/Root%04d" (root directory path format)
- 0x80a30: "Sys/AllocMap" (allocation bitmap file)  (PS font cache)
- 0x80a3c: "Sys/Directory" (directory file)
- 0x80a4a: "read"
- 0x80a4f: "write"
- 0x80a55: "?" (unknown command)
- 0x80a58: "command=%s; diskAddr=%d; memAddr=0x%X; fileID=%d; pageCount=%d\n" (SCSI log format)
- 0x80a9d: "last status=%d\n" (status log format)

2. **0x80ab0**: This is `wildcard_match`, not part of the string table as previously implied.

3. **0x80b12, 0x80b3e, 0x80b84**: These are file handle management functions that were completely missed in the prior analysis.

5. The function at 0x809c0 is a checksum calculator, not a "checksum verifier" as previously described.

6. The function at 0x809e8 updates timestamps, not just "gets time".

All code in this range has been properly identified - there are no regions where code was misidentified as data or vice versa. The analysis now correctly covers all functions from 0x80000 to 0x80c00.

; === CHUNK 2: 0x80C00-0x81800 ===

### 1. `set_bitmap_range` (0x80C0E)
**Entry:** 0x80C0E  
**Purpose:** Sets or clears a range of bits in a filesystem bitmap. Used for allocating/freeing blocks. Takes a bitmap structure, starting bit, count, and operation (set=1/clear=0).  
- A5: bitmap structure pointer (fp@8)  stack frame parameter
- D7: starting bit index (fp@12)  stack frame parameter
- D6: count (fp@16)  stack frame parameter
- fp@23: operation (1=set, 0=clear)  stack frame parameter
1. Validates range against bitmap size (checks at 0xC22-0xC32)
2. For small ranges (<8 bits): uses bit-by-bit manipulation with bitmask
3. For larger ranges: uses byte-at-a-time optimization
4. Marks bitmap as dirty (sets byte at offset 20)
**Calls:** 0xB84 (get_bitmap_byte), 0xB3E (mark_bitmap_dirty), 0x5354 (error)
**Called from:** 0x80F52, 0x80FB8

### 2. `test_bit` (0x80D20)
**Entry:** 0x80D20  
**Purpose:** Tests if a specific bit is set in a bitmap. Returns boolean.  
- A5: bitmap structure (fp@8)  stack frame parameter
- D7: bit index (fp@12)  stack frame parameter
**Returns:** D0 = 1 if bit set, 0 if clear
1. Calls 0xB84 to get byte containing the bit
2. Creates mask (1 << (bit % 8))
3. Tests bit with AND
**Calls:** 0xB84 (get_bitmap_byte)

### 3. `find_free_bits` (0x80D5C)
**Entry:** 0x80D5C  
**Purpose:** Searches for a contiguous range of free bits in a bitmap. Used to find free blocks for allocation.  
- A5: bitmap structure (fp@8)  stack frame parameter
- D7: starting search position (fp@12)  stack frame parameter
- D6: minimum required bits (fp@16)  stack frame parameter
- fp@20: maximum search limit  stack frame parameter
**Returns:** D0 = starting bit of found range, or -1 if not found
1. Searches forward from start position
2. Skips over allocated bits (1s)
3. When finds free bit (0), counts contiguous free bits
4. Updates bitmap's "last found" position (offsets 22, 26) for optimization
**Calls:** 0xB84 (get_bitmap_byte)
**Called from:** 0x80E56, 0x80E6E, 0x80E94, 0x80F34

### 4. `allocate_bits` (0x80E02)
**Entry:** 0x80E02  
**Purpose:** Allocates a contiguous range of bits from a bitmap. Main allocation function for filesystem blocks.  
- fp@8: filesystem structure  stack frame parameter
- fp@12: pointer to store allocated starting bit  stack frame parameter
- fp@16: number of bits to allocate  stack frame parameter
**Returns:** D7 = actual number allocated (may be less than requested)
1. Sets up local bitmap context (calls 0x80B14)
2. Saves/restores interrupt context (uses 0x20008F4 stack)
3. Calls SCSI init (0xDF1C) - likely for disk access
4. Tries to find free bits starting from requested position
5. If not found, searches from beginning
6. If still not found, tries to allocate just 1 bit
7. Marks bits as allocated (calls 0xC0E = set_bitmap_range)
8. Updates filesystem free count (offset 110)
**Calls:** 0x80B14, 0xDF1C (SCSI), 0xD5C (find_free_bits), 0xC0E (set_bitmap_range), 0xB3E, 0xD8D8
**Called from:** Filesystem allocation routines

### 5. `free_bits` (0x80F96)
**Entry:** 0x80F96  
**Purpose:** Frees a previously allocated range of bits in a bitmap.  
- fp@8: filesystem structure  stack frame parameter
- fp@12: starting bit  stack frame parameter
- fp@16: count  stack frame parameter
1. Sets up local bitmap context
2. Calls set_bitmap_range with clear operation (0)
3. Updates filesystem free count (adds to offset 110)
**Calls:** 0x80B14, 0xC0E (set_bitmap_range)

### 6. `count_free_bits` (0x80FD0)
**Entry:** 0x80FD0  
**Purpose:** Counts total number of free bits in a bitmap (free blocks in filesystem).  
**Arguments:** A5: bitmap structure (fp@8)
**Returns:** D0 = count of free bits
1. Iterates through bitmap in 1024-bit chunks (128 bytes)
2. For each chunk, reads the bitmap data via 0xF076 (likely a disk read)
3. Counts free bits using bitwise operations
4. Uses optimization: skips fully allocated chunks (0xFF bytes)
**Calls:** 0xF076 (read bitmap chunk), 0xF0AC (release/cleanup)
**Called from:** Filesystem status queries

### 7. `mark_bitmap_dirty` (0x81152)
**Entry:** 0x81152  
**Purpose:** Marks a bitmap as dirty (needs to be written to disk).  
**Arguments:** A5: bitmap structure (fp@8)
**Algorithm:** Sets byte at offset 20 to 1
**Called from:** 0x80C0E (set_bitmap_range)

### 8. `scsi_timeout_start` (0x81156)
**Entry:** 0x81156  
**Purpose:** Initializes SCSI timeout system. Sets up callback and starts timer.  
1. Sets callback to 0x8114E (empty function)
2. Calls 0x8514 (timer setup)
3. Calls 0x80400 (SCSI initialization)
**Calls:** 0x8514, 0x80400

### 9. `scsi_timeout_set` (0x81178)
**Entry:** 0x81178  
**Purpose:** Sets a SCSI timeout with specified duration and mode.  
- fp@8: timeout duration in milliseconds  stack frame parameter
- fp@15: mode (1=normal, 2=extended)  (PS dict operator)
1. Checks current mode at 0x2016EA4
2. Calls appropriate timer function (0x44D0 or 0x4B48)
3. Converts ms to timer ticks (×1000/500)
4. Sets timeout value at 0x2016EA0
5. If duration > 0, sets callback and mode
**Calls:** 0x44D0, 0x4B48
**Called from:** 0x8123E, 0x81256

### 10. `scsi_timeout_set_normal` (0x81232)
**Entry:** 0x81232  
**Purpose:** Wrapper for scsi_timeout_set with mode=1 (normal).  
**Arguments:** fp@8: timeout in ms
**Calls:** 0x81178

### 11. `scsi_timeout_set_extended` (0x8124A)
**Entry:** 0x8124A  
**Purpose:** Wrapper for scsi_timeout_set with mode=2 (extended).  
**Arguments:** fp@8: timeout in ms
**Calls:** 0x81178

### 12. `scsi_timeout_check` (0x81262)
**Entry:** 0x81262  
**Purpose:** Checks if SCSI timeout has expired. Returns remaining time or error.  
**Returns:** D0 = remaining time in ms, or 0x7FFFFFFF if expired
1. Checks mode at 0x2016EA4
2. If mode=2, calls 0x44D0 to get current time
3. Calculates remaining time
4. If expired, clears mode and calls error handler
**Calls:** 0x44D0, error handler at 0x20222C8
**Called from:** SCSI command processing

### 13. `scsi_timeout_cancel` (0x812B4)
**Entry:** 0x812B4  
**Purpose:** Cancels pending SCSI timeout.  
1. Clears mode at 0x2016EA4
2. Sets callback to 0x81262 (timeout check)
3. Stores callback pointer at 0x2016E9C
**Calls:** 0x4574 (timer callback setup)

### 14. **SCC INTERRUPT HANDLER JUMP TABLE** (0x812DA)
**Address:** 0x812DA  
**Size:** 14 entries × 4 bytes = 56 bytes  
**Format:** Jump table for SCC interrupt vectors. Each entry is a 4-byte address.
- 0x812DA: 0x00004C00 (likely placeholder)
- 0x812DE: 0x00000000
- 0x812E2: 0x0000112A (handler at 0x8112A)
- 0x812E6: 0x02AC0018
- 0x812EA: 0x027602AC
- 0x812EE: 0x042E6D70
- ... (continues beyond 0x81800)

### 15. `scc_interrupt_handler` (0x812F4)
**Entry:** 0x812F4  
**Purpose:** Main SCC interrupt dispatcher. Handles Zilog 8530 SCC interrupts.  
1. Gets SCC base pointer from 0x2016EA8
2. Reads interrupt vector (RR2)
3. Dispatches via jump table based on vector
4. Handles various SCC conditions: transmit, receive, special
**Hardware:** Accesses SCC at 0x040000 (PS channel)
**Called from:** Hardware interrupt vector

### 16. `scc_configure_channel` (0x81378)
**Entry:** 0x81378  
**Purpose:** Configures an SCC channel with given parameters.  
- D1: configuration byte
- A1: parameter pointer
**Returns:** D0 = status (0=success)
1. Disables interrupts
2. Finds free channel (0-11)
3. Writes configuration to SCC register
4. Sets up parameter pointer
**Hardware:** Writes to SCC registers 0-15
**Called from:** 0x8136C

### 17. `scc_send_byte` (0x813D4)
**Entry:** 0x813D4  
**Purpose:** Sends a byte via SCC with handshaking.  
- D1: byte to send  (PS dict operator)
- D2: channel index
**Returns:** D0 = status (0=success)
1. Waits for channel to be ready
2. Writes byte to SCC data register
3. Handles handshaking signals
**Hardware:** Writes to SCC data register

### 18. `scc_receive_handler` (0x814A0)
**Entry:** 0x814A0  
**Purpose:** Handles SCC receive interrupts. Processes incoming data.  
1. Gets channel index from SCC
2. Checks for matching channel configuration
3. Processes received data based on protocol
4. Updates checksums and buffers
**Called from:** SCC interrupt handler

### 19. `scc_transmit_handler` (0x814FE)
**Entry:** 0x814FE  
**Purpose:** Handles SCC transmit interrupts. Sends queued data.  
1. Checks transmit buffer status
2. Sends next byte from buffer
3. Updates buffer pointers
4. Handles flow control
**Called from:** SCC interrupt handler

### 20. `scc_error_handler` (0x81544)
**Entry:** 0x81544  
**Purpose:** Handles SCC error conditions (framing, parity, overrun).  
1. Reads error status from SCC
2. Logs error type
3. Resets channel if necessary
4. Updates error counters
**Called from:** SCC interrupt handler

### 21. `scc_dma_handler` (0x81552)
**Entry:** 0x81552  
**Purpose:** Handles SCC DMA transfers between main memory and SCC.  
1. Checks DMA status
2. Transfers data block via DMA
3. Updates DMA pointers
4. Handles completion/interrupt
**Hardware:** Uses SCC DMA controller
**Called from:** SCC interrupt handler

1. **0x81152 is NOT `mark_bitmap_dirty`** - This is actually an empty function (just LINK/UNLK/RTS). The real `mark_bitmap_dirty` is at 0x80B3E (called from 0x80C0E).

2. **0x81156-0x812B4 are SCSI timeout functions**, not bitmap functions. These manage timeouts for SCSI operations.

3. **0x812DA is a JUMP TABLE**, not code. It's the SCC interrupt vector table.

4. **0x812F4-0x81800 are SCC interrupt handlers**, not bitmap functions. This is the Zilog 8530 SCC driver.

## NEW FUNCTIONS IDENTIFIED:

- **SCC interrupt system** (0x812F4-0x81800): Complete SCC driver with configuration, send/receive, error handling, and DMA support.

- **SCSI timeout management** (0x81156-0x812B4): Sophisticated timeout system with normal/extended modes and callbacks.

- **SCC jump table** (0x812DA): Hardware interrupt vector mapping.

- **SCC registers**: Accessed at 0x040000 (PS channel)
- **SCSI timeout registers**: 0x2016E9C-0x2016EA4
- **Timer functions**: 0x44D0, 0x4B48, 0x4574
- **Error handler**: 0x20222C8

This region contains critical I/O drivers: filesystem bitmap management (0x80C00-0x81150) and SCC serial communication (0x81156-0x81800). The SCC driver is particularly complex with full interrupt handling, DMA, and error recovery.

; === CHUNK 3: 0x81800-0x82400 ===

This region contains SCSI interrupt handling, timeout management, and some filesystem-related functions. The code is clearly part of the SCSI subsystem with interrupt handling, timeout management, and data transfer routines.

### 1. `scsi_interrupt_handler` (0x81800)
**Entry:** 0x81800  
**Purpose:** Main SCSI interrupt handler entry point. Saves status register, calls timeout handler at 0x81c08, increments error counter at A2@(276), and branches back to 0x17ba (likely main interrupt dispatch).  
**Returns:** Via RTS from interrupt  
**Hardware:** Accesses SCSI controller  
**Call targets:** 0x81c08 (timeout handler)  
**Called by:** Hardware interrupt

### 2. `scsi_save_context` (0x81810)
**Entry:** 0x81810  
**Purpose:** Saves context for SCSI operations. Saves registers A0-A2 and D7/A5-A6, restores FPU context from 0x20170fc.  
**Returns:** None (preserves context)  
**Hardware:** Accesses VIA#1 at 0x4000004 for timing  
**Call targets:** FPU context save/restore  
**Called by:** SCSI phase handlers

### 3. `scsi_calc_timing` (0x8185c)
**Entry:** 0x8185c  
**Purpose:** Calculates SCSI timing parameters. Multiplies value at A2@(160) by 773, adds 1, shifts left 8 bits, stores result back. Used for pseudo-DMA timing.  
**Arguments:** A2 = SCSI device structure  
**Returns:** Timing value in A2@(160)  
**Called by:** SCSI data transfer routines

### 4. `scsi_send_byte_with_timeout` (0x81876)
**Entry:** 0x81876  
**Purpose:** Sends a byte to SCSI controller with timeout. Uses 30 retries, checks status bit 2 at A0@.  
**Arguments:** D3 = byte to send, A1 = SCSI data register pointer  
**Returns:** Status in D1 (0 = timeout, non-zero = success)  
**Hardware:** SCSI controller data register at A1  
**Call targets:** FPU function via JSR %fp@  
**Called by:** Various SCSI send routines

### 5. `scsi_command_phase` (0x8188c)
**Entry:** 0x8188c  
**Purpose:** Handles SCSI command phase. Sets up pointer at 0x1872, sends 4 bytes via routine at 0x1980.  
**Arguments:** A2 = device structure  
**Hardware:** VIA#1 at 0x4000004 for timing, SCSI controller  
**Call targets:** 0x1980 (send routine)  
**Called by:** SCSI phase state machine

### 6. `scsi_phase_state_machine` (0x818ba)
**Entry:** 0x818ba  
**Purpose:** Main SCSI phase state machine. Saves context, processes phase table at A4, handles command/data/status phases.  
**Arguments:** A2 = device structure, A4 = phase table pointer  
**Returns:** Via context restore  
**Hardware:** SCSI controller  
**Call targets:** 0x188c (command phase), 0x197a (data phase), 0x1940 (status phase)  
**Called by:** SCSI interrupt handler

### 7. `scsi_send_message` (0x8191e)
**Entry:** 0x8191e  
**Purpose:** Sends SCSI message. Calls command phase setup, sends message byte D2, handles response.  
**Arguments:** D2 = message byte, A2 = device structure  
**Returns:** Status in condition codes  
**Hardware:** SCSI controller  
**Call targets:** 0x188c, 0x1876, 0x81940  
**Called by:** Message handling routines

### 8. `scsi_status_phase` (0x81940)
**Entry:** 0x81940  
**Purpose:** Handles SCSI status phase. Waits for status byte, sends acknowledge.  
**Arguments:** A2 = device structure  
**Returns:** Status byte received  
**Hardware:** SCSI controller, VIA#1 for timing  
**Call targets:** FPU functions via JSR %fp@  
**Called by:** Phase state machine

### 9. `scsi_data_phase_send` (0x8197a)
**Entry:** 0x8197a  
**Purpose:** Sends data during SCSI data phase. Sends 6 bytes from A2@(226).  
**Arguments:** A2 = device structure  
**Hardware:** SCSI controller  
**Called by:** Data phase handler

### 10. `scsi_receive_byte` (0x81988)
**Entry:** 0x81988  
**Purpose:** Receives a byte from SCSI controller. Loads SCC pointer from 0x2016ea8, increments receive counter, saves context, reads byte from A0@(1) to A3@+.  
**Arguments:** A0 = SCSI data register pointer  
**Returns:** Byte in D0  
**Hardware:** SCSI controller, VIA#1 at 0x4000004  
**Call targets:** FPU functions via JSR %fp@  
**Called by:** SCSI receive routines

### 11. `scsi_timeout_handler` (0x81c08)
**Entry:** 0x81c08  
**Purpose:** Main SCSI timeout handler. Calls error handler at 0x81c42, sends timeout commands (0xD0, 0x02, 0xDD), sends reset commands (0x30, 0x20).  
**Hardware:** SCSI controller  
**Call targets:** 0x81c42, 0x81c38  
**Called by:** scsi_interrupt_handler

### 12. `scsi_send_command` (0x81c38)
**Entry:** 0x81c38  
**Purpose:** Sends a command byte to SCSI controller. Sends 0x03 then the command byte in D1.  
**Arguments:** D1 = command byte  
**Hardware:** SCSI controller  
**Called by:** scsi_timeout_handler

### 13. `scsi_read_status` (0x81c42)
**Entry:** 0x81c42  
**Purpose:** Reads status from SCSI controller. Sends 0x01 command, reads status byte from A0@.  
**Returns:** Status byte in D1  
**Hardware:** SCSI controller  
**Called by:** scsi_timeout_handler, error handlers

### 14. `scsi_error_handler` (0x81c4c)
**Entry:** 0x81c4c  
**Purpose:** Handles SCSI errors. Checks bit 5 of status, increments appropriate error counter (0x104, 0xFC, 0xF4, 0xF8), returns error code (-4 to -1).  
**Arguments:** D1 = status byte  
**Returns:** Error code in D0 (-4 to -1)  
**Call targets:** scsi_timeout_handler  
**Called by:** Various error paths

### 15. `scsi_receive_data` (0x81c74)
**Entry:** 0x81c74  
**Purpose:** Receives data block from SCSI. Saves context, reads D1 bytes into buffer at A3.  
**Arguments:** D1 = byte count, A3 = buffer pointer  
**Returns:** Status in D0 (0 = success)  
**Hardware:** SCSI controller, VIA#1 at 0x4000004  
**Call targets:** 0x81ba2 (error check)  
**Called by:** SCSI data transfer routines

### 16. `scsi_receive_with_length` (0x81cd8)
**Entry:** 0x81cd8  
**Purpose:** Receives data with length adjustment. Similar to scsi_receive_data but handles D1 != D3 case.  
**Arguments:** D1 = total bytes, D3 = bytes to read, A3 = buffer  
**Returns:** Status in D0  
**Hardware:** SCSI controller  
**Call targets:** 0x81ba2, scsi_timeout_handler  
**Called by:** SCSI data transfer routines

### 17. `scsi_check_error` (0x81ba2)
**Entry:** 0x81ba2  
**Purpose:** Checks for SCSI errors. Reads status, calls error handler, checks for various error conditions.  
**Returns:** Status in D0 (0 = success)  
**Hardware:** SCSI controller, VIA#1 at 0x4000004  
**Call targets:** 0x81c42, 0x81c4c  
**Called by:** scsi_receive_data, scsi_receive_with_length

### 18. `handle_scsi_message` (0x81a88)
**Entry:** 0x81a88  
**Purpose:** Handles incoming SCSI messages. Processes message byte in D0 (high bit set), handles commands 0x80-0x85.  
**Arguments:** D0 = message byte  
**Hardware:** SCSI controller  
**Call targets:** 0x81ba2, 0x8191e  
**Called by:** SCSI message processing

### 19. `scsi_device_select` (0x81eb6)
**Entry:** 0x81eb6  
**Purpose:** Selects SCSI device based on ID in D2. Returns pointer to device structure in A1.  
**Arguments:** D2 = SCSI ID  
**Returns:** A1 = device structure pointer  
**Called by:** Device selection routines

### 20. `scsi_init_device` (0x81ecc)
**Entry:** 0x81ecc  
**Purpose:** Initializes SCSI device structure. Sets up command timeout, device ID, etc.  
**Arguments:** A0 = device structure, D1 = device ID  
**Call targets:** 0x81dfc  
**Called by:** Device initialization

### 21. `scsi_queue_command` (0x81dfc)
**Entry:** 0x81dfc  
**Purpose:** Queues SCSI command for execution. Adds command to linked list at 0x2016fd0.  
**Arguments:** A1 = command structure  
**Call targets:** Command processor  
**Called by:** scsi_init_device

### 22. `scsi_process_queue` (0x81f2a)
**Entry:** 0x81f2a  
**Purpose:** Processes SCSI command queue. Sets lock bit, processes all queued commands.  
**Returns:** Status in D0 (0 = success)  
**Call targets:** 0x81e66 (remove from queue)  
**Called by:** SCSI interrupt handler

### 23. `scsi_remove_from_queue` (0x81e66)
**Entry:** 0x81e66  
**Purpose:** Removes command from SCSI queue. Searches for command at A0, removes from linked list.  
**Arguments:** A0 = command to remove, A1 = queue head  
**Returns:** Status in D0 (0 = success, -1 = not found)  
**Called by:** scsi_process_queue

### 24. `scsi_add_to_queue` (0x81e3c)
**Entry:** 0x81e3c  
**Purpose:** Adds command to SCSI queue. Inserts at head of linked list.  
**Arguments:** A0 = command to add, A1 = queue head  
**Called by:** scsi_queue_command

### 25. `string_compare` (0x823d0)
**Entry:** 0x823d0  
**Purpose:** Compares two strings with case-insensitive option. Handles ASCII letter case conversion.  
**Arguments:** A0 = string1, A1 = string2, D1 = length  
**Returns:** D0 = 0 if equal, 1 if not equal  
**Called by:** Filesystem name matching

### 26. `to_lowercase` (0x823f4)
**Entry:** 0x823f4  
**Purpose:** Converts character to lowercase if it's an uppercase letter.  
**Arguments:** D0 = character  
**Returns:** D0 = lowercase character  
**Called by:** string_compare

### 1. SCSI Phase Table (0x81f92)
**Address:** 0x81f92  
**Format:** Array of 7 16-bit offsets  
**Content:** 0x005a, 0x008e, 0x0188, 0x0126, 0x0090, 0x026c, 0x0028

### 2. SCSI Command Jump Table (0x81c72)
**Address:** 0x81c72  
**Size:** Variable  
**Format:** Jump table for SCSI commands  
**Content:** Branch to 0x81cd8

2. **0x81810-0x8185a**: This is scsi_save_context, not "scsi context save". It saves FPU context from 0x20170fc.

3. **0x8185c-0x81870**: This is scsi_calc_timing, not "calculate timing". It multiplies by 773 (0x0305) for timing calculations.

4. **0x81876-0x8188a**: Correctly identified as scsi_send_byte_with_timeout with 30 retries.

5. **0x818ba-0x8191c**: This is the main scsi_phase_state_machine, not just "phase state machine". It handles the complete SCSI phase processing.

6. **0x81988-0x81c06**: This is a large receive/data handling function that was incorrectly split into multiple functions. It's actually scsi_receive_byte and related handlers.

7. **0x81c08-0x81c70**: This is the scsi_timeout_handler and related command sending functions.

8. **0x81eb6-0x81f28**: These are SCSI device management and queue handling functions, not part of the core SCSI protocol.

9. **0x823d0-0x82400**: String comparison utilities for filesystem operations.

1. The SCSI subsystem uses a queue system at 0x2016fd0 for command processing.
2. Error counters are maintained at various offsets in the SCSI device structure (0xFC, 0xF4, 0xF8, 0x104, etc.).
3. Timing calculations use multiplier 773 (0x0305) for pseudo-DMA timing.
4. The code handles SCSI messages 0x80-0x85 (command complete, disconnect, etc.).
5. String comparison is case-insensitive for filesystem operations.
6. The SCSI timeout handler sends specific command sequences (0xD0, 0x02, 0xDD) for recovery.

; === CHUNK 4: 0x82400-0x83000 ===

1. **Address range is wrong**: The prior analysis says 0x81800-0x83000, but the actual disassembly starts at 0x82400.

2. **Function names are speculative**: Many functions were given generic names without evidence from the code.

3. **Data misidentified as code**: The prior analysis didn't properly identify data tables.

Let me analyze this properly:

### 1. `scsi_init_device` (0x82406)
**Entry:** 0x82406  
**Purpose:** Initializes SCSI device communication. Sets up device parameters, configures timing, and performs device discovery/selection.  
**Arguments:** Uses global pointer at 0x2016ea8 in A2, D0/D1 contain device parameters  
**Hardware:** SCSI controller at 0x05000001, VIA#1 at 0x04000004 for timing  
- Sets device ID in A2@(160)  
- Configures baud rates via SCC  
- Performs device selection with timeout (119 retries)  
- Sets up callback tables at A2@(226), A2@(110), A2@(140)  
**Calls:** 0x82580 (calculate timing), 0x1d8e (SCC init), 0x253e (SCC config), 0x185c (SCSI command)  
**Returns:** D0=0, D1=device ID

### 2. `scsi_send_command_wrapper` (0x824f2)
**Entry:** 0x824f2  
**Purpose:** Wrapper function to send SCSI command with specific parameters. Sets up command block on stack.  
**Arguments:** Command parameters pushed on stack before call  
**Behavior:** Builds 18-byte command structure, calls 0x8252a (SCSI send), waits for completion flag at A2@(166)  
**Calls:** 0x8252a, polls A2@(166) for completion  
**Returns:** When command completes

### 3. `scsi_start_command` (0x8252a)
**Entry:** 0x8252a  
**Purpose:** Initiates SCSI command transfer. Sets command active flag.  
**Calls:** 0x158a (SCSI phase handler)  
**Sets:** A2@(166) = active flag  
**Returns:** After starting command

### 4. `scsi_device_select` (0x82534)
**Entry:** 0x82534  
**Purpose:** Selects SCSI device for communication.  
**Calls:** 0x1592 (device selection routine)  
**Clears:** A2@(166) = command complete  
**Returns:** After selection

### 5. `configure_scc_baud` (0x82580)
**Entry:** 0x82580  
**Purpose:** Calculates and configures SCC baud rate divisors based on system clock.  
**Arguments:** A2 points to global data, uses table at 0x25b8  
**Algorithm:** Reads clock value from 0x2022310, multiplies by table values, divides by 1000 to get baud rate divisors  
**Hardware:** Configures SCC at 0x0400000b and 0x0400000e  
**Returns:** Stores 16-bit divisors in A2@(204)+

### 6. `filesystem_mount` (0x825d8)
**Entry:** 0x825d8  
**Purpose:** Mounts a filesystem volume. Allocates and initializes volume structure.  
- Checks if volume already mounted at 0x201702c  
- Allocates memory via 0x3958 if needed  
- Reads superblock via 0x2d76+0x280c  
- Sets up volume parameters  
**Calls:** 0x3958 (malloc), 0x2d76 (SCSI setup), 0x280c (read superblock), 0x1d60 (SCSI command)  
**Returns:** D0=status, D1=8 (error code)

### 7. `read_superblock_callback` (0x82654)
**Entry:** 0x82654  
**Purpose:** Callback handler after reading superblock. Processes superblock data.  
**Arguments:** A0 points to command buffer, A1 points to volume structure  
- Validates superblock magic/version  
- Checks device capacity  
- Sets up file allocation table  (PS font cache)
**Calls:** 0x2dd0 (validate device), 0x26fc (setup FAT)  
**Returns:** Via continuation

### 8. `setup_file_allocation_table` (0x826fc)
**Entry:** 0x826fc  
**Purpose:** Initializes file allocation table structure.  
**Arguments:** A0 points to source data, A3 points to destination FAT  
**Algorithm:** Copies 48 bytes (24 words) from A0 to A3 in reverse order  
**Sets up:** FAT header with magic numbers 0x00fc (252) and 0x0101 (257)  
**Returns:** FAT structure initialized

### 9. `handle_device_capacity_response` (0x82718)
**Entry:** 0x82718  
**Purpose:** Processes SCSI device capacity response. Builds device capacity table entry.  
**Arguments:** A0 points to command buffer, D2/D3 contain device parameters  
- Stores device ID and capacity in table  
- Copies SCSI inquiry data from 0x2017030  
- Sets up capacity table entry structure  
**Calls:** 0x1d60 (SCSI command)  
**Returns:** After building capacity entry

### 10. `initialize_device_capacity_table` (0x82756)
**Entry:** 0x82756  
**Purpose:** Initializes a device capacity table entry for a SCSI device.  
**Arguments:** A3 points to capacity table, D2/D3 contain parameters  
- Allocates memory for capacity table entry  
- Sets up device parameters and capacity  
- Configures SCSI command for capacity inquiry  
**Calls:** 0x2d76 (SCSI setup), 0x2d96 (allocate entry), 0x2dec (allocate memory), 0x1d60 (SCSI command)  
**Returns:** D0=status

### 11. `process_capacity_inquiry_response` (0x827c2)
**Entry:** 0x827c2  
**Purpose:** Callback for SCSI capacity inquiry response. Processes capacity data.  
**Arguments:** A0 points to response buffer, A1 points to volume structure  
- Clears device busy flag at A1@(275)  
- Processes capacity response data  
- Sets up next command for device initialization  
**Calls:** 0x2718 (handle capacity response)  
**Returns:** Via continuation

### 12. `build_scsi_command_buffer` (0x8280c)
**Entry:** 0x8280c  
**Purpose:** Builds a SCSI command buffer with checksum calculation.  
**Arguments:** A3 points to command data, A1 points to volume structure  
- Calculates checksum of first 3 bytes  
- Allocates buffer with size = data length + 9  (register = size parameter)
- Copies command data with header  
**Calls:** 0x2dec (allocate memory)  
**Returns:** D3 points to allocated buffer

### 13. `send_scsi_command_with_buffer` (0x82878)
**Entry:** 0x82878  
**Purpose:** Sends a SCSI command using dynamically built buffer.  
**Arguments:** A3 points to command data  
- Builds command buffer via 0x8280c  
- Sends SCSI command  (PS dict operator)
**Calls:** 0x2d76 (SCSI setup), 0x8280c (build buffer)  
**Returns:** D0=status, D1=4 (error code)

### 14. `send_scsi_test_unit_ready` (0x82888)
**Entry:** 0x82888  
**Purpose:** Sends SCSI TEST UNIT READY command.  
**Arguments:** D3 contains device parameters  
- Builds and sends TEST UNIT READY command (opcode 0x00)  (PS dict operator)
**Calls:** 0x2d76 (SCSI setup), 0x283a (build command)  
**Returns:** D0=status, D1=4 (error code)

### 15. `initialize_file_handle` (0x8289c)
**Entry:** 0x8289c  
**Purpose:** Initializes a file handle structure for file operations.  
**Arguments:** A2 points to file handle structure  
- Sets up SCSI command buffers for file operations  
- Configures callback handlers for file I/O  
- Sets up timeout values (7200 = 2 hours in seconds?)  
**Calls:** 0x1d60 (SCSI command)  
**Returns:** Sets up callback at 0x2d50

### 16. `open_file` (0x82924)
**Entry:** 0x82924  
**Purpose:** Opens a file on the filesystem.  
**Arguments:** Multiple parameters on stack: A3=callback, A0=filename?, D1-D3=parameters  
- Validates file handle  
- Allocates buffer for file data  
- Sets up file handle structure  
- Initiates file open operation  (filesystem open operation)
**Calls:** 0x2d76 (SCSI setup), 0x2dd0 (validate), 0x2dec (allocate), 0x1d60 (SCSI command)  
**Returns:** D0=status

### 17. `file_open_callback` (0x829fa)
**Entry:** 0x829fa  
**Purpose:** Callback handler for file open operation completion.  
**Arguments:** A0 points to response buffer, A1 points to volume structure  
- Processes file open response  (filesystem open operation)
- Updates file handle with file size and position  (filesystem)
- Clears pending operation flags  (PS dict operator)
**Calls:** 0x2dd0 (validate), 0x2e20 (queue operation)  
**Returns:** Via continuation

### 18. `read_file_blocks` (0x82a4a)
**Entry:** 0x82a4a  
**Purpose:** Reads blocks from an open file.  
**Arguments:** Multiple parameters on stack: A3=callback, A0=buffer, D1-D3=block parameters  
- Validates file handle and parameters  
- Calculates block addresses  (filesystem block calculation)
- Builds SCSI READ command  
- Initiates read operation  
**Calls:** 0x2d76 (SCSI setup), 0x2dd0 (validate), 0x2dec (allocate), 0x1d60 (SCSI command)  
**Returns:** D0=status

### 19. `file_read_callback` (0x82b1e)
**Entry:** 0x82b1e  
**Purpose:** Callback handler for file read operation completion.  
**Arguments:** A0 points to response buffer  
- Clears read operation flag  
- Updates read completion status  
- Calls completion callback  
**Calls:** 0x2e20 (queue operation)  
**Returns:** Via continuation

### 20. `close_file` (0x82b3a)
**Entry:** 0x82b3a  
**Purpose:** Closes an open file handle.  
**Arguments:** D3 contains file handle parameters  
- Validates file handle  
- Clears file handle structure  
- Frees associated resources  
**Calls:** 0x2d76 (SCSI setup), 0x2b4a (close operation), 0x2dd0 (validate)  
**Returns:** D0=status, D1=4 (error code)

### 21. `perform_file_close` (0x82b4a)
**Entry:** 0x82b4a  
**Purpose:** Performs actual file close operation.  
**Arguments:** D3 contains device ID  
- Checks if device matches current volume  
- Clears device busy flag if match  
- Validates device handle  
**Calls:** 0x2dd0 (validate)  
**Returns:** D0=status

### 22. `flush_file_buffers` (0x82b5a)
**Entry:** 0x82b5a  
**Purpose:** Flushes file buffers to disk.  
**Arguments:** A2 points to file handle  
- Saves current file handle state  
- Builds flush command  
- Sends SCSI SYNCHRONIZE CACHE command  (PS dict operator)
**Calls:** 0x2bfe (send flush), 0x2e20 (queue operation), 0x2dba (cleanup)  
**Returns:** D0=status

### 23. `unmount_volume` (0x82bb4)
**Entry:** 0x82bb4  
**Purpose:** Unmounts a filesystem volume.  
- Closes all open file handles (4 iterations)  
- Sends final SCSI command to flush buffers  (PS dict operator)
- Frees volume structure memory  
**Calls:** 0x2d76 (SCSI setup), 0x2b4a (close), 0x399c (free), 0x3958 (malloc wrapper)  
**Returns:** D0=0 (success)

### 24. `send_flush_command` (0x82bfe)
**Entry:** 0x82bfe  
**Purpose:** Sends SCSI flush/synchronize command.  
**Arguments:** A2 points to file handle  
- Configures SCC for command  
- Builds appropriate SCSI command based on file type  
- Handles pending operations cleanup  (PS dict operator)
**Calls:** 0x1d7a (SCC config), 0x1d60 (SCSI command)  
**Returns:** After sending command

### 25. `file_operation_callback` (0x82c96)
**Entry:** 0x82c96  
**Purpose:** General callback for file operations.  
**Arguments:** A0 points to response buffer, A1 points to volume structure  
- Processes operation completion status  
- Updates file handle state  
- Handles different operation types (3=read, 6=special)  
- Manages operation retry logic  
**Calls:** 0x1d60 (SCSI command)  
**Returns:** Via continuation or sets pending operation flag

### 26. `queue_scsi_operation` (0x82d76)
**Entry:** 0x82d76  
**Purpose:** Sets up context and queues a SCSI operation.  
**Arguments:** Saves registers to volume structure  
- Saves D2-D3, A2-A4 to volume structure  
- Jumps to address in A2 (continuation)  
**Returns:** Via jump to continuation

### 27. `handle_scsi_error` (0x82d88)
**Entry:** 0x82d88  
**Purpose:** Handles SCSI operation errors.  
**Arguments:** A4=error handler, D0=error code, D1=error type  
- Restores saved registers from volume structure  
- Adjusts stack based on error type  
- Jumps to error handler  
**Returns:** Via jump to error handler

### 28. `allocate_file_handle_entry` (0x82d96)
**Entry:** 0x82d96  
**Purpose:** Allocates a file handle entry in the volume structure.  
- Searches for free slot in file handle table (4 entries)  
- Allocates memory for file handle structure  
- Returns pointer to allocated handle  
**Calls:** 0x2dec (allocate memory)  
**Returns:** D0=status, A0=handle pointer

### 29. `validate_device_handle` (0x82dba)
**Entry:** 0x82dba  
**Purpose:** Validates a device handle pointer.  
**Arguments:** A0 points to potential handle  
- Searches handle table for matching pointer  
- Clears entry if found  (data structure cleanup)
**Calls:** 0x2e20 (cleanup)  
**Returns:** Nothing

### 30. `get_device_handle` (0x82dd0)
**Entry:** 0x82dd0  
**Purpose:** Retrieves a device handle from the table.  
**Arguments:** D3 contains device index  
- Validates index range  
- Retrieves handle pointer from table  
- Returns handle or error if not found  
**Returns:** D0=status, A2=handle pointer

### 31. `allocate_memory_from_pool` (0x82dec)
**Entry:** 0x82dec  
**Purpose:** Allocates memory from the filesystem memory pool.  
**Arguments:** D0 contains size in bytes  
- Disables interrupts during allocation  (PS font cache)
- Manages free memory list at A1@(26)  
- Allocates from pool or calls system malloc if pool empty  
**Calls:** 0x399c (free existing), 0x3958 (system malloc)  
**Returns:** D0=status, A0=allocated pointer

### 32. `queue_operation_for_completion` (0x82e20)
**Entry:** 0x82e20  
**Purpose:** Queues an operation for asynchronous completion.  
**Arguments:** A0 points to operation structure  
- Adds operation to completion queue  
- Manages linked list of pending operations  (PS dict operator)  (data structure manipulation)
**Returns:** Nothing

## DATA TABLES:

### 1. SCC Configuration Table (0x82556-0x8257e)
**Address:** 0x82556  
**Format:** Series of 16-bit SCC register values (register number in high byte, value in low byte)  
**Purpose:** SCC channel configuration data for SCSI timing

### 2. Baud Rate Table (0x825b8-0x825cc)
**Address:** 0x825b8  
**Format:** 10 16-bit values for baud rate calculation  
**Values:** 0x0064, 0x00c8, 0x0077, 0x0220, 0x0046, 0x0064, 0x001e, 0x0008, 0x001e, 0x0000  
**Purpose:** Multipliers for baud rate calculation based on system clock

### 3. Jump Table for Command Dispatch (0x82f0e-0x82f1a)
**Address:** 0x82f0e  
**Format:** 6 16-bit offsets  
**Purpose:** Dispatch table for different SCSI command types based on opcode

1. **Filesystem Structure**: The code reveals a filesystem with:
   - Volume structure at 0x201702c
   - File handle table with 4 entries
   - 1024-byte block size (0x0200)  (register = size parameter)
   - Memory pool for filesystem operations

2. **SCSI Command Flow**: 
   - Commands are built on stack or in allocated buffers
   - Asynchronous completion via callbacks
   - Error handling via centralized error handler

3. **Memory Management**: 
   - Filesystem has its own memory pool separate from system malloc
   - Pool managed as linked list at A1@(26)  (data structure manipulation)
   - Falls back to system malloc (0x3958) when pool exhausted

4. **Error Codes**: 
   - 0xEFFE (-4098): File handle in use
   - 0xEFFD (-4099): Invalid block number
   - 0xEFFC (-4100): Operation failed
   - 0xF000 (-4096): No free file handles

The code in this region is primarily focused on filesystem operations and SCSI command handling, with a well-structured callback system for asynchronous I/O completion.

; === CHUNK 5: 0x83000-0x83C00 ===

### 1. **0x83000: linked_list_insert** (NOT scsi_command_handler)
- **Entry**: 0x83000
- **Purpose**: Inserts a node into a doubly-linked list. Uses A2 as base pointer with offset 0xC6 to get list head. Critical section protected by disabling interrupts (SR=0x2600).
- **Arguments**: A0 = node to insert, A2 = context pointer
- **Returns**: None (void)
- **Hardware**: Disables interrupts (SR=0x2600), accesses RAM at A2@(0xC6)
- **Algorithm**: Walks to end of list, inserts node, updates forward/backward pointers
- **Call targets**: 0x1DA4 (error handler), 0x2EAC (completion routine)

### 2. **0x8305a: allocate_memory_block** (NOT filesystem_open)
- **Entry**: 0x8305a
- **Purpose**: Allocates a memory block from a pool. Uses A0 as parameter block with size at offset 0x2C, type at 0x2D. Calls 0x3762 to get free pool.
- **Arguments**: A0 = allocation parameters (size at 0x2C, type at 0x2D, etc.)
- **Returns**: D0 = error code (0 for success, -1100 for error)
- **Call targets**: 0x3762 (get_pool), 0x323e (setup_block), 0x37a2 (release_pool)
- **Algorithm**: Gets pool, sets up block header, builds allocation structure with DMA pointers

### 3. **0x830e4: find_memory_block** (NOT find_file_entry)
- **Entry**: 0x830e4
- **Purpose**: Searches for a memory block by ID. Scans through 8 entries starting at A2@(0x66).
- **Arguments**: D1 = block ID (low byte), D0 = additional identifier
- **Returns**: A1 = found block pointer or NULL
- **Call targets**: 0x8310c (compare_block)
- **Algorithm**: Linear search through fixed array of 8 entries, each 12 bytes

### 4. **0x8310c: compare_memory_block** (NOT compare_filename)
- **Entry**: 0x8310c
- **Purpose**: Compares memory block identifiers. Checks both 32-bit and 16-bit IDs.
- **Arguments**: A1 = block pointer, D3 = comparison value
- **Returns**: Z flag set if match
- **Algorithm**: Checks A1@(0) == D3, then A1@(2) == D3, handles special cases

### 5. **0x83122: initialize_memory_block** (NOT filesystem_read)
- **Entry**: 0x83122
- **Purpose**: Initializes a memory block with parameters from A0. Sets up control structures.
- **Arguments**: A0 = parameter block
- **Returns**: D0 = status (0 success, -1100 error)
- **Call targets**: 0x3762 (get_pool), 0x32e4 (setup_params), 0x323e (build_structure), 0x37a2 (release_pool)
- **Algorithm**: Gets pool, sets up parameters, builds structure, releases pool

### 6. **0x831b0: setup_memory_pool** (NOT scsi_init)
- **Entry**: 0x831b0
- **Purpose**: Initializes a memory pool. Waits for pool availability, sets up pool structures.
- **Arguments**: None explicit (uses global A2)
- **Returns**: D0 = status (-1097 timeout, 0 success)
- **Call targets**: 0x3762 (get_pool), 0x3288 (submit_command), 0x37a2 (release_pool)
- **Algorithm**: Waits for pool free (5 attempts), gets pool, submits initialization command (0x00F8)

### 7. **0x8323e: build_command_structure** (NOT build_scsi_cdb)
- **Entry**: 0x8323e
- **Purpose**: Builds a command structure at A3 based on parameters in A0. Sets up DMA pointers and control fields.
- **Arguments**: A0 = source parameters, A3 = destination command structure
- **Returns**: None (void)
- **Algorithm**: Copies parameters, sets up DMA addresses at offset 0x3A, configures control bytes

### 8. **0x83288: submit_system_command** (NOT submit_scsi_command)
- **Entry**: 0x83288
- **Purpose**: Submits a system command to hardware. Saves registers, sets up completion handler at 0x32AE.
- **Arguments**: D0 = command code (0x00F6, 0x00F7, 0x00F8), D1 = parameter
- **Returns**: D0 = status
- **Call targets**: 0x1D60 (hardware submission)
- **Algorithm**: Saves registers to A3@(34), sets completion handler, calls hardware submission

### 9. **0x832ae: command_completion_handler**
- **Entry**: 0x832ae
- **Purpose**: Handles completion of system command. Restores registers, checks status.
- **Arguments**: A0 = completion context
- **Returns**: D0 = status
- **Algorithm**: Restores registers from A0@(34), returns status in D0

### 10. **0x832c8: build_pool_command** (NOT setup_dma_transfer)
- **Entry**: 0x832c8
- **Purpose**: Builds a pool command structure at A3. Sets command byte with bit 4 cleared.
- **Arguments**: A0 = parameters, D2 = index
- **Returns**: None (void)
- **Algorithm**: Builds command at A3@(96), sets command byte (0x40 + A0@(0x1D)), clears bit 4

### 11. **0x832f6: process_pending_operations** (NOT scsi_timeout_handler)
- **Entry**: 0x832f6
- **Purpose**: Processes pending operations in a pool. Scans through 6 slots, handles timeouts.
- **Arguments**: A0 = context
- **Returns**: None (void)
- **Call targets**: 0x3762 (get_pool), 0x32c8 (build_pool_command), 0x323e (build_structure), 0x37a2 (release_pool)
- **Algorithm**: Scans 6 slots, decrements timeout counters, handles expired operations

### 12. **0x833c6: find_block_by_id** (NOT scsi_find_device)
- **Entry**: 0x833c6
- **Purpose**: Finds a memory block by ID. Searches through 6 slots.
- **Arguments**: A0 = parameter block with ID at 0x2E
- **Returns**: D0 = status (-1102 if not found)
- **Call targets**: 0x3762 (get_pool), 0x3288 (submit_command), 0x37a2 (release_pool)
- **Algorithm**: Searches 6 slots for matching ID, gets pool, submits command (0x00F7)

### 13. **0x83420: release_memory_block** (NOT scsi_release_device)
- **Entry**: 0x83420
- **Purpose**: Releases a memory block. Finds block by ID, clears it, calls completion handler.
- **Arguments**: A0 = parameter block with ID at 0x2E
- **Returns**: D0 = status
- **Call targets**: 0x30e4 (find_block), 0x33ac (call_completion)
- **Algorithm**: Finds block, clears it, calls completion handler with status -1105

### 14. **0x8343e: interrupt_handler_entry**
- **Entry**: 0x8343e
- **Purpose**: Entry point for interrupt handler. Clears D3, jumps to handler via A4.
- **Arguments**: None (interrupt context)
- **Returns**: None
- **Algorithm**: Clears D3, jumps to handler at A4@(2)

### 15. **0x83446: decode_interrupt_command**
- **Entry**: 0x83446
- **Purpose**: Decodes interrupt command byte. Handles different command types.
- **Arguments**: D0 = command byte
- **Returns**: None
- **Algorithm**: Checks command byte, dispatches to appropriate handler

### 16. **0x834b0: main_interrupt_handler**
- **Entry**: 0x834b0
- **Purpose**: Main interrupt handler. Processes command stream from hardware.
- **Arguments**: A3 = command stream pointer
- **Returns**: None
- **Call targets**: Various via A4@(2)
- **Algorithm**: Processes command stream, handles different opcodes

### 17. **0x835d6: restore_interrupt_state**
- **Entry**: 0x835d6
- **Purpose**: Restores interrupt state from saved value.
- **Arguments**: A1 = saved state pointer
- **Returns**: None
- **Algorithm**: Gets saved SR from A1@(28), restores it

### 18. **0x835e6: handle_completion**
- **Entry**: 0x835e6
- **Purpose**: Handles operation completion. Updates data structures.
- **Arguments**: A3 = completion data
- **Returns**: None
- **Algorithm**: Processes completion data, updates memory blocks

### 19. **0x836f2: calculate_checksum** (NOT verify_data_integrity)
- **Entry**: 0x836f2
- **Purpose**: Calculates a checksum over data. Used for verification.
- **Arguments**: A2 = data pointer
- **Returns**: D0 = status (0 if checksum matches), D1 = calculated checksum
- **Algorithm**: Processes data in chunks, calculates rolling checksum

### 20. **0x83762: get_memory_pool**
- **Entry**: 0x83762
- **Purpose**: Gets an available memory pool from 3 possible pools.
- **Arguments**: None (uses global A2)
- **Returns**: A3 = pool pointer, D0 = status (0 success, -1104 if no pool available)
- **Algorithm**: Checks 3 pools at offsets 0xDA, 0x142, 0x1AA from A2, returns first available

### 21. **0x837a2: release_memory_pool**
- **Entry**: 0x837a2
- **Purpose**: Releases a memory pool by clearing its busy flag.
- **Arguments**: A3 = pool pointer
- **Returns**: None
- **Algorithm**: Clears busy flag at A3@(24)

### 22. **0x837a8: system_initialization** (MAJOR FUNCTION)
- **Entry**: 0x837a8
- **Purpose**: Main system initialization function. Sets up memory structures, hardware.
- **Arguments**: None
- **Returns**: D0 = status
- **Call targets**: 0xde50 (memory clear), 0x4590 (setup something), 0x4b48 (random seed), 0x2406 (math), 0x2e58 (more init)
- **Algorithm**: Clears memory, sets up global pointers, initializes hardware, sets up interrupt vectors

### 23. **0x838b0: system_shutdown**
- **Entry**: 0x838b0
- **Purpose**: System shutdown/cleanup function.
- **Arguments**: None
- **Returns**: None
- **Call targets**: 0x4604 (cleanup), 0x839c0 (free_all_memory)
- **Algorithm**: Restores hardware state, cleans up memory

### 24. **0x83958: malloc_wrapper** (HIGH-LEVEL MALLOC)
- **Entry**: 0x83958
- **Purpose**: High-level memory allocator wrapper. Uses linked list of blocks.
- **Arguments**: D0 = size
- **Returns**: A0 = allocated memory or NULL, D0 = status
- **Call targets**: 0xd818 (low-level alloc)
- **Algorithm**: Allocates block with 8-byte header, inserts into global free list

### 25. **0x8399c: free_wrapper**
- **Entry**: 0x8399c
- **Purpose**: High-level memory deallocator.
- **Arguments**: A0 = memory to free
- **Returns**: D0 = status
- **Call targets**: 0xdb6c (low-level free)
- **Algorithm**: Removes from linked list, calls low-level free

### 26. **0x839c0: free_all_memory**
- **Entry**: 0x839c0
- **Purpose**: Frees all allocated memory blocks.
- **Arguments**: None
- **Returns**: None
- **Algorithm**: Walks global free list, frees all blocks

## KEY CORRECTIONS FROM PRIOR ANALYSIS:

1. **This is NOT SCSI code** - It's memory management and system initialization
2. **Three malloc systems**: 
   - Low-level at 0x83958/0x8399c (C runtime)
   - Mid-level pool management at 0x83762/0x837a2
   - High-level wrapper at 0x83958
3. **Interrupt handling** at 0x8343e-0x835e6
4. **System init/shutdown** at 0x837a8/0x838b0
5. **Command processing** via hardware submission at 0x83288

- **0x83902-0x8391e**: String data "??@??P" (hardcoded message)
- **0x8394e**: Small utility function (calls 0x1f2a)
- **Global pointers at 0x2016ea8**: System context structure

The code shows a sophisticated memory management system with pool allocation, interrupt-driven command processing, and proper system initialization/shutdown sequences.

; === CHUNK 6: 0x83C00-0x84800 ===

This section contains C runtime functions, memory management (malloc/free equivalents), and circular buffer management for the Agfa 9000PS RIP.

### 1. **0x83c00: buffer_get_available_space**
- **Entry**: 0x83c00
- **Purpose**: Calculates available space in a circular buffer. Checks if buffer has been idle for too long (10+ reads), then computes free space between write pointer (0x2022348) and read pointer (0x2022374).
- **Arguments**: None (uses global buffer pointers)
- **Returns**: Available space in D7
- **Hardware**: Accesses RAM variables at 0x2022348 (write ptr), 0x2022374 (read ptr), 0x202236c (buffer size)
- **Key logic**: If idle count > 10, sets flag at 0x202235c. Computes distance between pointers, handles wrap-around.

### 2. **0x83c48: buffer_put_byte**
- **Entry**: 0x83c48
- **Purpose**: Puts a byte into a circular buffer. Writes 0xFF as sentinel, then the actual byte.
- **Arguments**: Byte in D0 (low byte)
- **Returns**: None
- **Hardware**: Updates 0x2022348 (write ptr), 0x202234c (available space), 0x2022324 (idle counter)
- **Algorithm**: Writes 0xFF sentinel, increments pointer, writes actual byte, updates counters.

### 3. **0x83c94: buffer_get_byte**
- **Entry**: 0x83c94
- **Purpose**: Gets a byte from a circular buffer with timeout/blocking.
- **Arguments**: A5 points to buffer control structure (12 bytes: count, read_ptr, flags)
- **Returns**: Byte in D0, or -1 on EOF/error
- **Hardware**: Uses semaphore at 0x4924/0x492a (enter/exit critical section)
- **Algorithm**: Waits for data, reads byte, handles 0xFF sentinel (skip), 0x04 marks EOF.

### 4. **0x83dc4: buffer_unget_byte**
- **Entry**: 0x83dc4
- **Purpose**: Pushes a byte back into the buffer (ungetc equivalent).
- **Arguments**: A5=buffer control, D0=byte to push back
- **Returns**: Byte in D0, or -1 on error
- **Algorithm**: Decrements read pointer, stores byte.

### 5. **0x83dfa: buffer_get_available**
- **Entry**: 0x83dfa
- **Purpose**: Returns number of bytes available to read in buffer.
- **Arguments**: A0=buffer control structure
- **Returns**: Available count in D0
- **Algorithm**: Computes distance between write pointer and read pointer.

### 6. **0x83e34: buffer_flush**
- **Entry**: 0x83e34
- **Purpose**: Reads and discards all bytes until EOF marker.
- **Arguments**: A0=buffer control structure
- **Returns**: 0 in D0
- **Algorithm**: Calls buffer_get_byte in loop until EOF bit set.

### 7. **0x83e5c: buffer_rewind**
- **Entry**: 0x83e5c
- **Purpose**: Resets buffer read pointer to current write position.
- **Arguments**: A5=buffer control structure
- **Returns**: 0 in D0
- **Algorithm**: Sets read pointer = write pointer, clears counters.

### 8. **0x83e86: buffer_init**
- **Entry**: 0x83e86
- **Purpose**: Initializes buffer control structure.
- **Arguments**: A5=buffer control structure
- **Returns**: None
- **Algorithm**: Sets read/write pointers, clears flags and counters.

### 9. **0x83ec0: stdio_flush_buffers**
- **Entry**: 0x83ec0
- **Purpose**: Flushes standard I/O buffers (stdin/stdout equivalents).
- **Arguments**: None
- **Returns**: None
- **Algorithm**: If stdin buffer exists, flushes it. Sets EOF flag.

### 10. **0x83eee: fclose**
- **Entry**: 0x83eee
- **Purpose**: Closes a file/stream.
- **Arguments**: File handle in D0 (at fp@8)
- **Returns**: 0 in D0
- **Algorithm**: Calls free/memory deallocation function at 0x8584.

### 11. **0x83f0e: fopen / freopen helpers**
- **Entries**: 0x83f0e, 0x83f34, 0x83f58
- **Purpose**: Initialize file control structures for different modes.
- **Arguments**: A0/A1 points to file control structure
- **Returns**: File handle or 0
- **Note**: These set up buffer pointers from global variables at 0x2022330/0x2022334

### 12. **0x83f7c: free_file_handle**
- **Entry**: 0x83f7c
- **Purpose**: Frees a file handle structure.
- **Arguments**: File handle pointer at fp@8
- **Returns**: 0 in D0
- **Algorithm**: Calls free at 0x8584, clears global pointer at 0x2022318.

### 13. **0x83f98: fopen_helper_4args**
- **Entry**: 0x83f98
- **Purpose**: Another fopen helper with 4 arguments.
- **Arguments**: A0 points to file control structure
- **Returns**: File handle in D0
- **Algorithm**: Similar to 0x83f0e but with different argument layout.

### 14. **0x83fbe: dummy_return_zero**
- **Entry**: 0x83fbe
- **Purpose**: Simple function that returns 0.
- **Arguments**: None
- **Returns**: 0 in D0

### 15. **0x83fc8: trigger_something**
- **Entry**: 0x83fc8
- **Purpose**: Triggers something with argument 2.
- **Arguments**: None
- **Returns**: None
- **Algorithm**: Calls function at 0xdfe2 with argument 2.

### 16. **0x83fdc: initialize_stdio_system**
- **Entry**: 0x83fdc
- **Purpose**: Main initialization of stdio system.
- **Arguments**: Three arguments at fp@8, fp@12, fp@20
- **Returns**: Pointer to initialized structure in D0
- **Algorithm**: Allocates and initializes stdin/stdout structures, sets up buffer pointers, installs interrupt handler.

### 17. **0x8414e: cleanup_stdio_system**
- **Entry**: 0x8414e
- **Purpose**: Cleans up stdio system.
- **Arguments**: Two file handles at fp@8 and fp@12
- **Returns**: None
- **Algorithm**: Frees stdin/stdout structures if they match global pointers.

### 18. **0x8419c: stdio_interrupt_handler**
- **Entry**: 0x8419c
- **Purpose**: Interrupt handler for stdio system.
- **Arguments**: Unknown at fp@8
- **Returns**: 0 in D0
- **Algorithm**: Checks flags at 0x2022328, handles different interrupt types (3=stdin, 20=stdout).

### 19. **0x8424e: setup_stdio_buffers**
- **Entry**: 0x8424e
- **Purpose**: Sets up stdio buffer structures.
- **Arguments**: None
- **Returns**: None
- **Algorithm**: Initializes buffer pointers, clears globals, installs timer handler.

### 20. **0x842cc: configure_buffer_pointers**
- **Entry**: 0x842cc
- **Purpose**: Configures buffer pointers based on input.
- **Arguments**: Pointer at fp@8
- **Returns**: None
- **Algorithm**: Calculates buffer end pointers based on start and size.

### 21. **0x84326-0x84426: DATA REGION**
- **Address**: 0x84326-0x84426
- **Size**: 256 bytes
- **Format**: Mixed data - appears to be function pointer table or configuration data
- **Note**: Contains values like 0x0004, 0x0800, 0x0C00, 0x0010, etc.

### 22. **0x84426-0x844c2: FUNCTION POINTER TABLE**
- **Address**: 0x84426-0x844c2
- **Size**: 156 bytes
- **Format**: Array of function pointers (likely for stdio operations)
- **Entries**: Each appears to be 2 bytes (addresses in bank 4)
- **Examples**: 0x3AE0, 0x3AEE, 0x3B54, 0x3B14, 0x3B00, etc.

### 23. **0x844c4-0x844cc: STRING DATA**
- **Address**: 0x844c4-0x844cc
- **Size**: 8 bytes
- **Content**: "EnIn\0EnOut\0" (likely "Enter Input"/"Enter Output" or similar)

### 24. **0x844d0: get_buffer_status**
- **Entry**: 0x844d0
- **Purpose**: Gets buffer status flag.
- **Arguments**: None
- **Returns**: Status in D0
- **Algorithm**: Checks flag at 0x20170ec, returns appropriate value.

### 25. **0x844f4: set_buffer_status_active**
- **Entry**: 0x844f4
- **Purpose**: Sets buffer status to active.
- **Arguments**: None
- **Returns**: None
- **Algorithm**: Sets flag at 0x20170ec to 1.

### 26. **0x84518: clear_buffer_status**
- **Entry**: 0x84518
- **Purpose**: Clears buffer status flag.
- **Arguments**: None
- **Returns**: None
- **Algorithm**: Clears flag at 0x20170ec.

### 27. **0x8453a: buffer_operation_with_status**
- **Entry**: 0x8453a
- **Purpose**: Performs buffer operation with status preservation.
- **Arguments**: Pointer at fp@8
- **Returns**: Unknown in D0
- **Algorithm**: Saves status, calls functions at 0x4b50 and 0x4b5c.

### 28. **0x84574: schedule_timer_handler**
- **Entry**: 0x84574
- **Purpose**: Schedules a timer handler.
- **Arguments**: Function pointer at fp@8, interval at fp@12
- **Returns**: None
- **Algorithm**: Wrapper for function at 0x84590.

### 29. **0x84590: install_timer_handler**
- **Entry**: 0x84590
- **Purpose**: Installs a timer handler in priority queue.
- **Arguments**: Function pointer at fp@8, data at fp@12, priority at fp@18 (word)
- **Returns**: Pointer to handler structure in D0
- **Algorithm**: Allocates structure, inserts into priority-sorted linked list at 0x202237c.

### 30. **0x84604: remove_timer_handler**
- **Entry**: 0x84604
- **Purpose**: Removes a timer handler from queue.
- **Arguments**: Handler pointer at fp@8
- **Returns**: None
- **Algorithm**: Removes from linked list, frees memory.

### 31. **0x84646: update_timer_handler_data**
- **Entry**: 0x84646
- **Purpose**: Updates timer handler data.
- **Arguments**: Handler at fp@8, new data at fp@12
- **Returns**: None
- **Algorithm**: Updates data field in handler structure.

### 32. **0x84658: MEMORY CHECKSUM/VERIFICATION ROUTINE**
- **Entry**: 0x84658
- **Purpose**: Performs memory checksum/verification.
- **Arguments**: None (self-contained)
- **Returns**: Status in D0 (0=OK, 1=error, 2=error with details)
- **Algorithm**: Computes checksums over memory regions, compares with expected values.
- **Key sections**: 
  - 0x84658-0x846be: Simple checksum of low memory
  - 0x846be-0x84796: Complex checksum with multiple test patterns
  - 0x84798-0x84800: Final verification and error reporting

### 33. **0x84798-0x84800: ERROR REPORTING AND HALT**
- **Purpose**: Reports checksum errors and halts system
- **Algorithm**: Prints error messages, enters infinite loop
- **Calls**: 0x8484e (print string), 0x84874 (print hex), 0x84868 (print decimal)

1. **0x83f0e, 0x83f34, 0x83f58**: These are not "fopen/freopen helpers" but rather buffer initialization functions for different file modes.

2. **0x83fdc**: This is the main stdio system initialization, not just a buffer init.

3. **0x8419c**: This is an interrupt handler, not a regular function.

4. **0x84426-0x844c2**: This is a function pointer table for stdio operations, not code.

5. **0x84658**: This is a comprehensive memory verification routine, not just a simple checksum.

7. The error reporting/halt code at the end was not properly identified.

1. **Three-level buffer system**: There are buffer management functions, stdio wrapper functions, and timer-based interrupt handling.

2. **Timer handler queue**: A priority-sorted linked list at 0x202237c manages timed events.

3. **Memory verification**: The system includes a comprehensive memory checksum routine that runs multiple test patterns.

4. **Error handling**: Detailed error reporting with hex/decimal output functions.

5. **Interrupt-driven I/O**: The stdio system uses interrupt handlers for efficient I/O processing.

This section represents a complete I/O subsystem with buffer management, interrupt handling, timer scheduling, and system verification.

; === CHUNK 7: 0x84800-0x85400 ===

1. **0x84800-0x8483A**: This is DATA, not code. It contains various patterns and strings.
2. **0x8483C**: This is indeed `scc_check_tx_ready` (correct in prior analysis).
3. **0x84A0E**: This is `scsi_clear_flags_and_signals` (not `scsi_bus_free`).
4. **0x84B46**: This is `get_scsi_timeout_value` (not `get_scsi_timeout`).
5. Many function boundaries were slightly off in the prior analysis.

**0x84800-0x8483A**: Mixed data patterns and strings
- 0x84800-0x84808: Unknown data (possibly padding)
- 0x8480C-0x84816: Pattern data (0xFFFF, 0xAAAA, 0x5555)
- 0x84818-0x8483A: ASCII strings: "*&*FAIL: data = *", "*&*\r\n"

**0x848F4-0x84908**: SCC initialization data table (14 bytes)
- Values: 0x0100, 0x03c1, 0x044c, 0x056a, 0x090a, 0x0b50, 0x0c0a, 0x0d00, 0x0e01, 0x0f00
- Used by `scc_init_debug` at 0x848B6

**0x84C60-0x84C6E**: SCC command sequences
- 0x84C60-0x84C6B: 11-byte sequence: 0x0CFE, 0x0DFF, 0x0E01, 0x0F02, 0x0101, 0x0010, 0x0100
- 0x84C6E-0x84C70: 3-byte sequence: 0x0F00

### FUNCTIONS:

#### 1. **0x8483C**: `scc_check_tx_ready`
- Checks if SCC transmitter is ready for debug console
- Tests bit 2 of SCC status register at 0x020170F0
- Returns: Z flag set if not ready, cleared if ready
- Called by: `scc_tx_byte` at 0x84844

#### 2. **0x84844**: `scc_tx_byte`
- Transmits byte to SCC (Z8530) (debug console)
- Args: byte in low byte of d0 (from stack at sp@(4))
- Calls `scc_check_tx_ready` in busy-wait loop
- Writes byte to SCC data register at 0x020170F0+1
- Called by: `scc_print_string` at 0x84860

#### 3. **0x8484E**: `scc_print_string`
- Prints null-terminated string to debug console
- Args: string pointer in a0 (from stack at sp@(4))
- Loops through string, calls `scc_tx_byte` for each character
#### 4. **0x84868**: `scc_print_hex_long`
- Prints 32-bit value as 8 hex digits
- Args: value in d0 (from stack at sp@(4))
- Uses d2 as counter (4 iterations for 4 bytes)
- Swaps d0 to print high word first
- [SCC debug console] Calls `scc_print_hex_nibble` via loop (Atlas monitor hex output)
#### 5. **0x84874**: `scc_print_hex_word`
- Prints 16-bit value as 4 hex digits
- Args: value in d0 (from stack at sp@(4))
- Uses d2 as counter (2 iterations for 2 bytes)
- Rotates d0 right by 8 bits to print high byte first
- Calls `scc_print_hex_nibble` via loop
#### 6. **0x84880**: `scc_print_hex_nibble`
- Converts nibble to ASCII hex digit
- Args: nibble in low 4 bits of d0 (rotated in)  (PS CTM operator)
- Converts 0-9 to '0'-'9', A-F to 'A'-'F'
- Calls `scc_tx_byte` to transmit
- Called by: `scc_print_hex_long` and `scc_print_hex_word`

#### 7. **0x848B6**: `scc_init_debug`
- Initializes SCC (Z8530) for debug console (9600 8N1)
- Sets up pointers: 0x020170F0 = 0x07000000, 0x020170F4 = 0x07000000
- Configures SCC registers using table at 0x848F4
- Uses coroutine style: jumps to continuation in a5
- Hardware: SCC (Z8530) at 0x07000000

#### 8. **0x84908**: `scc1_enable_tx`
- Enables VIA #1 transmitter (PostScript data channel)
- Writes 0x03 to 0x0400000D (WR0 pointer + WR5)
- Writes 0x83 to 0x0400000E (WR0 pointer + WR3)
#### 9. **0x8491A**: `scc1_disable_tx`
- Disables VIA #1 transmitter
- Writes 0x03 to 0x0400000E (WR0 pointer + WR3)
#### 10. **0x84924**: `disable_interrupts`
- Sets SR to 0x2400 (supervisor mode, interrupts disabled)
#### 11. **0x8492A**: `enable_interrupts`
- Sets SR to 0x2000 (supervisor mode, interrupts enabled)
#### 12. **0x84930**: `scsi_control_bus`
- Controls SCSI bus signals via shadow register
- Args: d0 = control bits to set/clear, d1 = mask (which bits to change)
- Bit 3: BSY (busy), Bit 1: SEL (select), Bit 0: RST (reset)
- Updates shadow register at 0x020170F8
- Writes to SCSI controller at 0x06000000
#### 13. **0x84A0E**: `scsi_clear_flags_and_signals`
- Clears flags in SCSI control structure and updates SCSI bus
- Accesses SCSI structure at 0x02022340
- Clears bytes at offsets 0x1C and 0x1D  struct field
- Updates SCSI control shadow register at 0x020170F8
- Writes to SCSI controller at 0x06000000
#### 14. **0x84A48**: `scc1_interrupt_handler`
- Handles VIA #1 interrupts (PostScript data channel)
- Checks SCC status register at 0x0400000D
- Bit 0: transmit interrupt, Bit 1: receive interrupt
- Calls appropriate handler from table at offset 0x14  struct field
#### 15. **0x84AFC**: `init_scc1_and_scsi`
- Initializes VIA #1 and SCSI controller
- Sets interrupt vector at 0x0200002C to 0x00084A48
- Configures VIA #1: writes 0x03 to 0x0400000E
- Initializes SCSI control shadow: 0x31 to 0x020170F8
- Writes to SCSI controller at 0x06000000
#### 16. **0x84B46**: `get_scsi_timeout_value`
- Returns current SCSI timeout value
- Reads from 0x02022378
- Returns: timeout value in d0
- Called by: timeout checking functions

#### 17. **0x84B50**: `add_to_scsi_timeout`
- Adds value to SCSI timeout counter
- Args: value to add in sp@(4)
- Reads from 0x02022378, adds argument
- Returns: new timeout value in d0

#### 18. **0x84B5C**: `check_scsi_timeout_elapsed`
- Checks if SCSI timeout has elapsed
- Args: timeout value in sp@(4)
- Reads from 0x02022378, subtracts argument
- Returns: d0 = 1 if timeout elapsed, 0 if not
- Used for timeout detection

#### 19. **0x84B70**: `timer_interrupt_handler`
- Timer interrupt handler (called at regular intervals)
- Checks hardware register at 0x0400002D bit 6
- Increments timeout counter at 0x02022378
- Checks timer chain structure at 0x0202237C
- Calls timeout callbacks when timer expires
#### 20. **0x84BEA**: `calibrate_timer`
- Calibrates system timer
- Disables interrupts, reads timer value
- Performs calculation: (timer_value * 3686 - 32768) >> 16
- Writes calibrated value to hardware registers
- Sets up timer interrupt vector at 0x02000020
#### 21. **0x84CF4**: `init_display_controller`
- Initializes display/rendering controller  (PS dict operator)
- Args: various display parameters on stack
- Configures display controller structure at 0x02017108
- Sets up hardware registers at 0x04000020-0x0400002F
- Initializes rendering callback system  (PS dict operator)
#### 22. **0x84E0E**: `register_rendering_callback`
- Registers a rendering callback function  (PS dict operator)
- Args: callback pointer in a0, data pointer in sp@(12)
- Adds to callback list at 0x02017118
- Returns: d0 = 0 if successful, error code if not

#### 23. **0x84E46**: `check_rendering_callback`
- Checks if address is a valid rendering callback  (PS dict operator)
- Args: address in sp@(4)
- Compares with registered callbacks at 0x02017118 and 0x02017124
- Returns: d0 = 1 if valid callback, 0 if not

#### 24. **0x84E6C**: `disable_rendering_system`
- Disables rendering callback system  (PS dict operator)
- Clears callback pointers and flags
- Updates hardware register at 0x04000020
#### 25. **0x84EA0**: `rendering_engine_main`
- Main rendering engine loop  (PS dict operator)
- Reads hardware registers, processes rendering commands  (PS dict operator)
- Handles display synchronization and timing  (display hardware)
- Calls registered rendering callbacks  (PS dict operator)
- Uses coroutine-style programming with A5 as continuation
- Returns: nothing (runs continuously)

1. **Interrupt Handling**: The code shows sophisticated interrupt handling for SCC channels and timers.

2. **Rendering System**: There's a complete rendering callback system with registration, validation, and main loop.

3. **SCSI Control**: Functions for precise SCSI bus control with shadow registers.

4. **Debug Console**: Full debug output system with hex and string printing.

5. **Timer Calibration**: Hardware timer calibration with mathematical calculations.

6. **Coroutine Style**: Some functions (like `scc_init_debug` and `rendering_engine_main`) use A5 as a continuation address instead of standard RTS returns.

; === CHUNK 8: 0x85400-0x86000 ===

### FUNCTIONS:

#### 1. **0x85400**: `scsi_select_device`
- Purpose: Selects a SCSI device by ID, handles bus arbitration and selection protocol
- Algorithm:
  - Starts timeout timer (0x4B50)
  - Checks SCSI BUSY bit (bit 6 at 0x05000004)
  - If busy, waits with timeout (0x4B5C)
  - Sends selection command to SCSI controller (0x6230)  (PS dict operator)
  - Handles various timeout and error conditions
- Arguments: Device ID in a5 (likely pointer to device structure)
- Return: Success (0) or error in d0
- Hardware: SCSI controller registers at 0x05000000-0x05000004
- Calls: 0x4B50 (add_scsi_timeout), 0x4B5C (check_scsi_timeout), 0x6110 (scsi_reset?), 0x6230 (scsi_send_command)  (PS dict operator)
- Called by: SCSI command execution routines

#### 2. **0x8552E**: `scsi_execute_command`
- Purpose: Executes a SCSI command block and handles the response
- Algorithm:
  - Validates SCSI device ID (0x201720c must be 0-7)
  - Sets up command structure at fp@(-5)  stack frame parameter
  - Sends command via SCSI bus (0x6168)  (PS dict operator)
  - Checks status, handles errors
  - For certain command types (0x03), sets special status
  - Processes SCSI sense data if needed
- Arguments: Command structure pointer in a5 (from fp@(8))  stack frame parameter
- Return: Status in d0 (0=success)
- Hardware: SCSI controller
- Calls: 0x6168 (scsi_transfer), 0x5384 (scsi_prepare_command), 0xdcf8 (memcpy), 0xde50 (memset)
- Called by: Various SCSI operations (read_capacity, test_unit_ready, etc.)

#### 3. **0x85696**: `scsi_decode_status`
- Purpose: Converts SCSI status word to standardized error code
- Algorithm:
  - Checks if status is negative (error)
  - Extracts status bits 8-11 (mask 0x0F00)
  - Maps: 0x0100/0x0300 → error 1, 0x0200 → error 2, others → error 3
- Arguments: Status word in fp@(10)  stack frame parameter
- Return: Error code in d0 (1, 2, or 3)
- Hardware: None
- Called by: SCSI error handling in 0x85860

#### 4. **0x856D4**: `scsi_read_capacity`
- Purpose: SCSI READ CAPACITY command (0x25) to get device size in blocks  (register = size parameter)
- Algorithm:
  - Sets up SCSI command block with opcode 0x25
  - Sends command, reads 8-byte capacity response  (PS dict operator)
  - Calculates capacity = (returned value + 1) / 2
- Arguments: Buffer pointer likely in fp@(8) (not used in this function)  stack frame parameter
- Return: Device capacity in blocks in d0, or 0 on error
- Hardware: SCSI controller
- Calls: 0xde50 (memset), 0x5384 (scsi_prepare_command), 0x6230 (scsi_send_command), 0x552E (scsi_execute_command)  (PS dict operator)
- Called by: Device initialization at 0x85D80

#### 5. **0x85772**: `scsi_test_unit_ready`
- Purpose: SCSI TEST UNIT READY command (0x1B) with retry logic
- Algorithm:
  - Validates device ID (0-7)
  - Sends TEST UNIT READY command up to 2 times  (PS dict operator)
  - If fails, sends REQUEST SENSE to get error details  (PS dict operator)
  - Returns device readiness status
- Arguments: None (uses local structure at fp@(-16))  stack frame parameter
- Return: 1 if ready, 0 if not in d0
- Hardware: SCSI controller
- Calls: 0x6110 (scsi_reset?), 0xde50 (memset), 0x5384, 0x552E, 0x5696
- Called by: Device initialization or health checking

#### 6. **0x8583C**: `scsi_set_queue_pointer`
- Purpose: Sets global SCSI I/O request queue pointer
- Algorithm:
  - Checks if queue pointer already set (0x2017250)
  - If set, calls error handler (0x8609E)
  - Otherwise stores pointer at 0x2017250
- Arguments: Queue pointer in fp@(12)  stack frame parameter
- Return: None
- Hardware: None
- Calls: 0x8609E (error handler)
- Called by: SCSI initialization

#### 7. **0x85860**: `scsi_process_io_request` (MAJOR CORRECTION - this is NOT "scsi_decode_status")
- Purpose: Processes SCSI I/O requests from a queue
- Algorithm:
  - Gets queue pointer from 0x2017250
  - Processes requests in the queue structure
  - Handles different request types (read/write)
  - Manages retry counters at 0x2017230 (10 retries per device)
  - Updates statistics at 0x2022390
- Arguments: Pointer to SCSI device structure in a5 (fp@(8))  stack frame parameter
- Return: Pointer to queue structure in d0, or 0 on error
- Hardware: SCSI controller
- Calls: 0xded8 (divide?), 0xde50 (memset), 0x5384 (scsi_prepare_command), 0x6168/0x6230 (scsi_transfer), 0x552E (scsi_execute_command), 0x5696 (scsi_decode_status)
- Called by: Filesystem I/O operations

#### 8. **0x85B58**: `scsi_initialize_devices`
- Purpose: Initializes all SCSI devices and builds device table
- Algorithm:
  - Clears device capacity table at 0x2017210
  - For each SCSI ID (0-7):
    - Sends INQUIRY command (0x12) to identify device  (PS dict operator)
    - Sends MODE SENSE command (0x1A) to get parameters  (PS dict operator)
    - Sends MODE SELECT command (0x15) to configure  (PS dict operator)
    - Sends TEST UNIT READY (0x1B)  (PS dict operator)
    - If successful, reads capacity and stores in table
- Arguments: Pointer to device structure in fp@(8)  stack frame parameter
- Return: Success/failure in d0
- Hardware: SCSI controller
- Calls: 0xde50 (memset), 0x5384 (scsi_prepare_command), 0x6168/0x6230 (scsi_transfer), 0x552E (scsi_execute_command), 0x56D4 (scsi_read_capacity)
- Called by: SCSI initialization

#### 9. **0x85E32**: `scsi_log_command`
- Purpose: Logs SCSI command details for debugging
- Algorithm:
  - Formats command structure fields into debug string
  - Calls printf-like function (0x88C0)
  - Logs opcode, LBA, length, status, etc.
- Arguments: Command structure pointer in a5 (fp@(8)), format string pointer in fp@(12)  stack frame parameter
- Return: None
- Hardware: None
- Calls: 0x88C0 (printf-like function)
- Called by: Debug/error handling code

#### 10. **0x85E98**: `scsi_reset_devices`
- Purpose: Resets all SCSI devices (sends TEST UNIT READY to each)  (PS dict operator)
- Algorithm:
  - For each SCSI ID (0-7):
    - Sends TEST UNIT READY command  (PS dict operator)
    - Clears device status
- Arguments: Magic value in fp@(8) (must be 0x02017144)  stack frame parameter
- Return: Success (1) or failure (0) in d0
- Hardware: SCSI controller
- Calls: 0xde50 (memset), 0x5384 (scsi_prepare_command), 0x552E (scsi_execute_command)
- Called by: SCSI error recovery

#### 11. **0x85F32**: `scsi_controller_init` (MAJOR CORRECTION - this is the main SCSI init)
- Purpose: Initializes the SCSI controller and sets up data structures
- Algorithm:
  - Saves current execution context
  - Initializes SCSI controller hardware
  - Sets up function pointers in device structure
  - Tests controller by writing/reading register 8
  - Initializes devices if controller is functional
- Return: None
- Hardware: SCSI controller at 0x05000000
- Calls: 0xDF1C (context save?), 0x52C4 (scsi_lowlevel_init?), 0xDCB0 (strcpy?), 0x5B58 (scsi_initialize_devices)
#### `0x860b8_format_string_for_scsi_log_comma` — 0x860B8**: Format string for scsi_log_command
- Content: "op=%02x lun=%01x lba=%06x len=%02x"
- Used by: 0x85E32 (scsi_log_command)

#### `0x860e9_second_format_string_for_scsi_lo` — 0x860E9**: Second format string for scsi_log_command
- Content: " status=%04x result=%08x" (likely)
- Used by: 0x85E32 (scsi_log_command)

#### `0x86106_string_scsi` — 0x86106**: String "SCSI"
- Content: "SCSI"
- Used by: 0x85F32 (scsi_controller_init) for identification

### KEY CORRECTIONS FROM PRIOR ANALYSIS:

1. **0x85860 is NOT "scsi_decode_status"** - It's actually `scsi_process_io_request`, a complex function that processes I/O requests from a queue.

2. **0x85F32 is the main SCSI initialization** - Not a minor helper function. It sets up the entire SCSI subsystem.

3. **Address references were wrong** - The prior analysis referenced addresses like 0x552E, 0x5696, etc., but these are actually function entry points within this same code segment (0x8552E, 0x85696).

4. **Hardware addresses corrected** - SCSI controller is at 0x05000000, not 0x5000000.

5. **Function purposes were misidentified** - Several functions were described with incorrect algorithms.

### HARDWARE INTERACTION:

- **SCSI Controller**: AMD AM5380 at 0x05000000
  - Register 0: Data output
  - Register 1: Initiator command
  - Register 4: Status (bits: 5=REQ, 6=BUSY, etc.)

- **Memory-mapped variables**:
  - 0x201720C: Current SCSI device ID
  - 0x2017210: Device capacity table (8 entries × 4 bytes)
  - 0x2017230: Retry counters (8 entries × 4 bytes)
  - 0x2017250: I/O request queue pointer
  - 0x2022394: SCSI controller present flag

scsi_controller_init (0x85F32)
  ├── scsi_initialize_devices (0x85B58)
  │     ├── scsi_test_unit_ready (0x85772)
  │     │     └── scsi_execute_command (0x8552E)
  │     │           └── scsi_select_device (0x85400)
  │     └── scsi_read_capacity (0x856D4)
  │           └── scsi_execute_command (0x8552E)
  └── scsi_set_queue_pointer (0x8583C)

scsi_process_io_request (0x85860)
  ├── scsi_execute_command (0x8552E)
  └── scsi_decode_status (0x85696)
This analysis corrects the significant errors in the prior analysis and provides accurate function boundaries, purposes, and relationships for the SCSI driver code in this address range.

; === CHUNK 9: 0x86000-0x86C00 ===

### 1. 0x86000-0x8609c: `scsi_scan_devices`
- **Entry**: 0x86000
- **Purpose**: Scans SCSI bus for devices (IDs 0-7). For each ID, tests if device is ready (0x5772), and if so, reads its capacity (0x56d4). Stores capacities in table at 0x2017210 and accumulates total capacity in A5@(68). If device not found, clears entry. Sets device count to -1 (0xFFFFFFFF) when done.
- **Arguments**: Context pointer in A5 (PostScript execution context).
- **Returns**: In D0: 0 if no devices found, or pointer to context (A5) if devices found.
- **RAM access**: 
  - 0x2022398: timer value
  - 0x2022378: timeout value (default 5000)  (PS dict operator)
  - 0x201720c: device counter (0-7 during scan, -1 when done)
  - 0x2017210: device capacity table (8 entries × 4 bytes)
- **Calls**: 0x4574 (likely `delay` or `timer_init`), 0x5772 (`scsi_test_unit_ready`), 0x56d4 (`scsi_read_capacity`), 0x5248 (unknown).
- **Key algorithm**: 
  1. Waits for timeout (5000 ticks)
  2. Clears device counter
  3. For IDs 0-7: test unit ready, if OK read capacity and store
  4. Sets counter to -1 (0xFFFFFFFF)
  5. Returns context pointer if total capacity > 0

### 2. 0x8609e-0x860b6: `scsi_execute_command`
- **Entry**: 0x8609e
- **Purpose**: Executes a SCSI command. First calls initialization (0x6330), then dispatches command (0x5354).
- **Arguments**: Command structure pointer at FP@(8).
- **Returns**: Unknown (likely status in D0).
- **Calls**: 0x6330 (`scsi_init_transfer`), 0x5354 (`scsi_command_dispatcher`).

### 3. 0x860b8-0x8610e: **DATA SECTION - SCSI error strings**
- **Address**: 0x860b8-0x8610e (86 bytes)
- **Content**: ASCII strings for error reporting:
  - "SCSI I/O error=%d; " (0x860b8)
  - "SCSI code=%d; " (0x860de)  
  - "SCSI error=%x; state=%x" (0x860f0)
  - "/sci/" (0x86108) - pathname prefix for SCSI-related files
- **Note**: These are NOT code - they're string constants used by error reporting functions.

### 4. 0x86110-0x86150: `scsi_bus_reset`
- **Entry**: 0x86110
- **Purpose**: Performs a SCSI bus reset using AMD AM5380 controller. Sets bus to "bus free" state, asserts reset line, waits, then releases reset.
- **Hardware**: 
  - 0x05000001 (NCR 5380 ICR) data output register
  - 0x05000007: SCSI status register
- **Algorithm**:
  1. Sets SCSI data register to 0x80 (asserts RST line)
  2. Delay loop (dbf instruction)
  3. Clears data register (releases RST)
  4. Waits for bus free state (checks status register)
  5. Waits timeout (5000 ticks from 0x2022378)
- **Returns**: RTS (void function)

### 5. 0x86152-0x86166: `scsi_dma_complete_handler`
- **Entry**: 0x86152
- **Purpose**: Checks if DMA transfer completed successfully. If DMA status (0x2017258) is non-zero, stores it in device structure at offset 22.
- **RAM**: 
  - 0x2017258: DMA completion status/error code
  - 0x2022380: pointer to current SCSI device structure
- **Returns**: 0 in D0 (success indicator).

### 6. 0x86168-0x86186: `scsi_wait_timeout`
- **Entry**: 0x86168
- **Purpose**: Waits for SCSI operation with timeout. Uses timeout value at 0x202239c (defaults to 5000 if zero).
- **Arguments**: None (uses global timeout).
- **Calls**: 0x84646 (`delay` function).

### 7. 0x86188-0x86212: `scsi_pseudo_dma_read`
- **Entry**: 0x86188
- **Purpose**: Performs pseudo-DMA read from SCSI bus. Uses AMD AM5380's pseudo-DMA mode to transfer data from SCSI to memory.
- **Arguments**: 
  - FP@(4): destination buffer pointer  stack frame parameter
  - FP@(8): byte count  stack frame parameter
  - FP@(14): mode/flags  stack frame parameter
- **Hardware**:
  - 0x05000026: SCSI pseudo-DMA data port
  - 0x05000002-0x05000007: SCSI control/status registers
- **Algorithm**:
  1. Sets up DMA error code (0x86212 = 0x86212)
  2. Configures SCSI mode register
  3. Waits for DMA request
  4. Reads bytes from pseudo-DMA port
  5. Handles timeout/errors
- **Returns**: -1 in D0 on success, clears DMA status

### 8. 0x86214-0x8622e: `scsi_pseudo_dma_read_error_handler`
- **Entry**: 0x86214
- **Purpose**: Error handler for pseudo-DMA read. Clears DMA status and returns error code.
- **Returns**: Error code in D0 (composed from SCSI status registers).

### 9. 0x86230-0x862dc: `scsi_pseudo_dma_write`
- **Entry**: 0x86230
- **Purpose**: Performs pseudo-DMA write to SCSI bus. Transfers data from memory to SCSI device.
- **Arguments**:
  - FP@(4): source buffer pointer  stack frame parameter
  - FP@(8): byte count  stack frame parameter
  - FP@(14): mode/flags  stack frame parameter
- **Hardware**: Same as read function
- **Algorithm**: Similar to read but writes to SCSI data port
- **Returns**: -1 in D0 on success

### 10. 0x862de-0x86302: `scsi_pseudo_dma_write_error_handler`
- **Entry**: 0x862de
- **Purpose**: Error handler for pseudo-DMA write.
- **Returns**: Error code in D0.

### 11. 0x86304-0x86330: `scsi_check_status`
- **Entry**: 0x86304
- **Purpose**: Checks SCSI controller status. If mode bits in argument are 0, checks SCSI status register and DMA status.
- **Arguments**: Mode bits at FP@(20)
- **Returns**: Status in D0 or stores DMA error at FP@(22)

### 12. 0x86332-0x86364: `scsi_init_transfer` (actually starts at 0x86332, not 0x6330)
- **Entry**: 0x86332
- **Purpose**: Initializes SCSI transfer. Sets up error handling and calls initialization functions.
- **Arguments**: Unknown (likely transfer structure)
- **Calls**: 0x88c0, 0x877a, 0x1140

### 13. 0x86366-0x86444: **Filesystem initialization functions** (8 similar functions)
These functions initialize various filesystem data structures by calling 0xffff0f8c with pairs of addresses:
- 0x86366: Initializes 0x2000940/0x2000944
- 0x86382: Initializes 0x2000958/0x200095c
- 0x8639e: Initializes 0x2000960/0x2000964
- 0x863ba: Initializes 0x2000968/0x200096c
- 0x863d6: Initializes 0x2000988/0x200098c
- 0x863f2: Initializes 0x2000998/0x200099c
- 0x8640e: Initializes 0x2000990/0x2000994
- 0x8642a: Initializes 0x20009a0/0x20009a4
- 0x86446: Initializes 0x20009b8/0x20009bc

### 14. 0x86462-0x86480: `filesystem_error_handler`
- **Entry**: 0x86462
- **Purpose**: Handles filesystem errors. If error code is 1, calls 0x6a20 with string pointer.
- **Arguments**: Error code at FP@(8)
- **Calls**: 0x6a20 (error reporting)

### 15. 0x86482-0x86538: **DATA SECTION - Filesystem error jump table**
- **Address**: 0x86482-0x86538 (182 bytes)
- **Content**: Table of 19 entries, each 8 bytes: [address][error code offset]
- **Purpose**: Maps error codes to handler addresses/offsets

### 16. 0x86544-0x86694: **DATA SECTION - Filesystem error strings**
- **Address**: 0x86544-0x86694 (336 bytes)
- **Content**: ASCII error messages:
  - "Fatal system error @ 0x%X\n" (0x86544)
  - "dictfull" (0x8655e)
  - "dictstackoverflow" (0x86568)
  - "dictstackunderflow" (0x8657a)
  - "execstackoverflow" (0x8658e)
  - "invalidaccess" (0x865a0)
  - "invalidexit" (0x865ae)
  - "invalidfile" (0x865ba)
  - "invalidfileaccess" (0x865cc)
  - "invalidfont" (0x865de)
  - "ioerror" (0x865ee)
  - "limitcheck" (0x865f6)
  - "nocurrentpoint" (0x86602)
  - "rangecheck" (0x86610)
  - "stackoverflow" (0x8661c)
  - "stackunderflow" (0x8662e)
  - "syntaxerror" (0x86640)
  - "typecheck" (0x8664e)
  - "undefined" (0x86658)  (PS dict operator)
  - "undefinedfilename" (0x86662)  (PS dict operator)
  - "undefinedresult" (0x86676)  (PS dict operator)
  - "unmatchedmark" (0x86688)
  - "VMerror" (0x86696)

### 17. 0x8669a-0x866dc: `clear_all_file_handles`
- **Entry**: 0x8669a
- **Purpose**: Clears all file handles in the filesystem. Iterates through file handle table and resets each handle.
- **RAM**: 0x2017354: filesystem structure pointer
- **Algorithm**: Loops through file handle array, clearing each entry

### 18. 0x866de-0x8670e: `close_all_files`
- **Entry**: 0x866de
- **Purpose**: Closes all open files. Walks linked list of open files and closes each one.
- **Arguments**: File handle pointer at FP@(8)
- **Calls**: 0xfffca082 (file close function)

### 19. 0x86710-0x86748: `set_file_slot`
- **Entry**: 0x86710
- **Purpose**: Sets a file slot entry in the file slot table.
- **Arguments**: 
  - FP@(10): slot index  stack frame parameter
  - FP@(12): file structure pointer (8 bytes)  stack frame parameter
- **RAM**: 0x2022264: file slot table pointer

### 20. 0x8674a-0x86764: `init_file_slot_9b0`
- **Entry**: 0x8674a
- **Purpose**: Initializes file slot at 0x20009b0/0x20009b4
- **Calls**: 0xffff0f8c

### 21. 0x86766-0x867b0: `allocate_file_slot`
- **Entry**: 0x86766
- **Purpose**: Allocates a new file slot from the file slot table.
- **Returns**: Slot index in D0
- **Calls**: 0x6382, 0x708a

### 22. 0x867b2-0x867f0: `init_file_slot_entry`
- **Entry**: 0x867b2
- **Purpose**: Initializes a file slot entry with default values.
- **Arguments**:
  - FP@(10): slot index  stack frame parameter
  - FP@(12): file structure pointer  stack frame parameter

### 23. 0x867f2-0x868dc: `create_file_handle`
- **Entry**: 0x867f2
- **Purpose**: Creates a new file handle with specified access mode.
- **Arguments**:
  - FP@(8): filename pointer  stack frame parameter
  - FP@(12): file structure pointer  stack frame parameter
  - FP@(16): access mode  stack frame parameter
  - FP@(20): file handle pointer  stack frame parameter
- **Returns**: File handle initialized
- **Calls**: Multiple filesystem functions

### 24. 0x868de-0x868fa: `create_file_handle_simple`
- **Entry**: 0x868de
- **Purpose**: Simplified version of create_file_handle with default access mode.
- **Arguments**: Similar to above but with default access

### 25. 0x868fc-0x86946: `find_file_slot`
- **Entry**: 0x868fc
- **Purpose**: Finds a file slot by filename.
- **Arguments**:
  - FP@(8): filename pointer  stack frame parameter
  - FP@(12): file structure pointer  stack frame parameter
  - FP@(16): result pointer  stack frame parameter
- **Returns**: File slot if found

### 26. 0x86948-0x869f8: `open_file`
- **Entry**: 0x86948
- **Purpose**: Opens a file by filename.
- **Arguments**:
  - FP@(8): filename pointer  stack frame parameter
  - FP@(12): file structure pointer  stack frame parameter
- **Returns**: File handle

### 27. 0x869fa-0x86a1e: `close_multiple_files`
- **Entry**: 0x869fa
- **Purpose**: Closes multiple files from an array of file structures.
- **Arguments**: Array pointer at FP@(8)

### 28. 0x86a20-0x86a46: `resolve_multiple_filenames`
- **Entry**: 0x86a20
- **Purpose**: Resolves multiple filenames from an array.
- **Arguments**: Array pointer at FP@(8)

### 29. 0x86a48-0x86aea: `init_file_slot_table`
- **Entry**: 0x86a48
- **Purpose**: Initializes the file slot table. Allocates memory and sets up default entries.
- **Arguments**: Mode at FP@(8) (1=allocate, 2=deallocate/check)
- **RAM**: 0x2022260: file slot table size, 0x2022264: file slot table pointer
- **Calls**: 0x8344 (memory allocation)

### 30. 0x86aee-0x86b48: `get_file_slot_entry`
- **Entry**: 0x86aee
- **Purpose**: Retrieves an entry from a file slot.
- **Arguments**:
  - FP@(8): file slot pointer  stack frame parameter
  - FP@(12): result pointer  stack frame parameter
- **Returns**: File slot entry

### 31. 0x86b4a-0x86bb0: `add_to_file_handle_list`
- **Entry**: 0x86b4a
- **Purpose**: Adds a file handle to the linked list of open files.
- **Arguments**: File handle pointer at FP@(8)
- **RAM**: 0x20223b0: filesystem global structure

### 32. 0x86bb2-0x86bfc: `add_to_file_cache_list`
- **Entry**: 0x86bb2
- **Purpose**: Adds a file to the cache list.
- **Arguments**: File structure pointer at FP@(8)
- **RAM**: 0x20223b0: filesystem global structure

## KEY CORRECTIONS FROM PRIOR ANALYSIS:

1. **Addressing**: The disassembly shows absolute addresses (0x86000+), which correspond to bank 4 offset 0x6000.
2. **Data regions**: 0x860b8-0x8610e and 0x86482-0x86694 are data, not code.
3. **Function boundaries**: Many more functions exist than previously identified.
4. **SCSI functions**: The pseudo-DMA read/write functions are complex state machines with error handling.
5. **Filesystem**: This region contains extensive filesystem management code, not just SCSI drivers.

The code shows a mix of SCSI low-level drivers and higher-level filesystem management, consistent with bank 4's role as the filesystem/SCSI driver module.

; === CHUNK 10: 0x86C00-0x87800 ===

- Memory copy functions (memcpy-like)
- String manipulation functions (strcpy, strncpy)
- Memory set functions (memset-like)
- Memory allocation and management  (PS font cache)
- Callback registration functions

### 1. 0x86c00-0x86c48: `memory_alloc_or_link` (likely `malloc` or linked list insertion)
- **Entry**: 0x86c00
- **Purpose**: Allocates memory or inserts into a linked list. Calls 0x8304 (likely `malloc`), then manipulates linked list pointers at 0x20223b0+102.
- **Arguments**: One parameter at FP@(8).
- **Returns**: Pointer in D0.
- **RAM access**: 0x20223b0 (global structure), offset 102 (0x66) for linked list.
- **Calls**: 0x8304 (malloc).
- **Key behavior**: Allocates 10 bytes (0xA), sets up forward/backward links in a doubly-linked list.

### 2. 0x86c4a-0x86d7c: `memory_copy_with_flags` (complex memory operation)
- **Entry**: 0x86c4a
- **Purpose**: Complex memory copy/management function with flags checking. Handles overlapping regions, validates permissions via bitfield extraction.
- **Arguments**: Multiple parameters on stack (at least 5).
- **Returns**: None (void).
- **RAM access**: 0x20008f8 (permission/flag byte), 0x20223ac (memory boundary).
- **Calls**: 0xffff24ac (error handler), 0xffff059c, 0x63ba, 0x8717e.
- **Key behavior**: Uses bfextu/bfins for bitfield operations, copies 20 bytes (5 longs) from source to local buffer, handles linked list traversal.

### 3. 0x86d7e-0x86da0: `memory_copy_forward` (wrapper)
- **Entry**: 0x86d7e
- **Purpose**: Wrapper that calls 0x86c4a with specific parameters (last arg = 0).
- **Arguments**: 4 parameters.
- **Calls**: 0x86c4a.
- **Returns**: None.

### 4. 0x86da2-0x86dc6: `memory_copy_backward` (wrapper)
- **Entry**: 0x86da2
- **Purpose**: Wrapper that calls 0x86c4a with specific parameters (second arg = 0, last arg = 1).
- **Arguments**: 5 parameters.
- **Calls**: 0x86c4a.
- **Returns**: None.

### 5. 0x86dc8-0x86eb0: `memory_move_blocks` (block copy with overlap handling)
- **Entry**: 0x86dc8
- **Purpose**: Copies blocks of memory with overlap detection. Similar to memmove for structured data.
- **Arguments**: Source, destination, count, and flags.
- **Returns**: None.
- **RAM access**: 0x20223ac (memory boundary), 0x20008f8 (permission byte).
- **Calls**: 0xffff24ac (error), 0x6446 (bounds check), 0x6b4a (permission check).
- **Key behavior**: Handles forward/backward copying based on addresses, copies 8-byte blocks, validates permissions.

### 6. 0x86eb2-0x86f32: `memory_copy_bytes` (byte-oriented copy)
- **Entry**: 0x86eb2
- **Purpose**: Byte-oriented memory copy (like memcpy). Handles overlap correctly.
- **Arguments**: Source, destination, count, flags.
- **Returns**: None.
- **RAM access**: 0x20223ac, 0x20008f8.
- **Calls**: 0xffff24ac (error), 0x6446 (bounds), 0xdcf8 (likely optimized copy).
- **Key behavior**: Uses either manual byte copy or calls optimized routine at 0xdcf8.

### 7. 0x86f34-0x86f84: `memory_set_bytes` (memset-like)
- **Entry**: 0x86f34
- **Purpose**: Sets memory to a value (like memset). Takes source byte pattern.
- **Arguments**: Destination, count, source byte, flags.
- **Returns**: None.
- **RAM access**: 0x20008f8.
- **Calls**: 0xffff24ac (error).
- **Key behavior**: Null-terminates destination, copies byte pattern.

### 8. 0x86f86-0x86ff8: `string_copy_limited` (strncpy-like)
- **Entry**: 0x86f86
- **Purpose**: String copy with length limit. Checks source length first.
- **Arguments**: Destination, count, source, flags.
- **Returns**: None.
- **RAM access**: 0x20223ac, 0x20008f8.
- **Calls**: 0xdcd4 (strlen-like), 0xffff24ac (error), 0x6446 (bounds).
- **Key behavior**: Gets source length first, copies min(count, strlen(source)) bytes.

### 9. 0x86ffa-0x8703c: `create_string_descriptor`
- **Entry**: 0x86ffa
- **Purpose**: Creates a string descriptor structure. Copies template from 0x7c88.
- **Arguments**: String pointer at FP@(8), destination descriptor at FP@(12).
- **Returns**: None.
- **RAM access**: 0x20008f8 (permission byte), 0x20223a8 (string base).
- **Calls**: 0xdcd4 (strlen-like).
- **Key behavior**: Creates 8-byte descriptor with length and offset from base.

### 10. 0x8703e-0x87064: `create_string_descriptor_at_global`
- **Entry**: 0x8703e
- **Purpose**: Creates string descriptor at global location 0x20172b8.
- **Arguments**: String pointer at FP@(8).
- **Returns**: Pointer to descriptor in D0.
- **Calls**: 0x86ffa (create_string_descriptor).
- **Key behavior**: Creates descriptor in local buffer, copies to global location.

### 11. 0x87066-0x87088: `copy_global_structure_out`
- **Entry**: 0x87066
- **Purpose**: Copies 80 bytes (20 longs) from global structure at 0x20223ac+12 to destination.
- **Arguments**: Destination pointer at FP@(8).
- **Returns**: None.
- **RAM access**: 0x20223ac (global structure base).
- **Key behavior**: Copies 80-byte structure.

### 12. 0x8708a-0x870ac: `copy_to_global_structure`
- **Entry**: 0x8708a
- **Purpose**: Copies 80 bytes (20 longs) from source to global structure at 0x20223ac+12.
- **Arguments**: Source pointer at FP@(8).
- **Returns**: None.
- **RAM access**: 0x20223ac (global structure base).
- **Key behavior**: Inverse of previous function.

### 13. 0x870ae-0x870e6: `update_structure_field`
- **Entry**: 0x870ae
- **Purpose**: Updates field in a structure (offset 20, byte 28).
- **Arguments**: Structure pointer at FP@(8), value at FP@(16).
- **Returns**: None.
- **RAM access**: 0x20008f8 (permission byte).
- **Calls**: 0x6bfe (permission check).
- **Key behavior**: Updates specific field with permission checking.

### 14. 0x870e8-0x8717c: `copy_structure_with_alloc`
- **Entry**: 0x870e8
- **Purpose**: Copies structure with allocation if needed. Handles permission byte at offset 5.
- **Arguments**: Source at FP@(8), data at FP@(12).
- **Returns**: None.
- **RAM access**: 0x20008f8, 0x20223b0 (global), 0x20223ac (bounds).
- **Calls**: 0x6334 (error), 0x8304 (malloc), 0x6446 (bounds).
- **Key behavior**: Allocates 24 bytes (0x18) if permission byte differs, copies 16 bytes of data.

### 15. 0x8717e-0x8722a: `copy_large_structure_with_alloc`
- **Entry**: 0x8717e
- **Purpose**: Similar to previous but for larger structures (28 bytes).
- **Arguments**: Base at FP@(8), source at FP@(12), data at FP@(16).
- **Returns**: None.
- **RAM access**: Same as previous.
- **Calls**: Same as previous.
- **Key behavior**: Allocates 28 bytes (0x1c), copies 20 bytes (5 longs).

### 16. 0x8722c-0x872ac: `update_structure_with_data`
- **Entry**: 0x8722c
- **Purpose**: Updates structure with new data, checking permissions at offsets 1 and 9.
- **Arguments**: Structure at FP@(8), data at FP@(12).
- **Returns**: None.
- **RAM access**: 0x20008f8, 0x20223ac.
- **Calls**: 0x6446 (bounds), 0x6b4a (permission check).
- **Key behavior**: Copies 16 bytes of data after permission checks.

### 17. 0x872ae-0x8730e: `update_structure_field_only`
- **Entry**: 0x872ae
- **Purpose**: Updates only specific fields in structure (offset 8).
- **Arguments**: Structure at FP@(8), data at FP@(12).
- **Returns**: None.
- **RAM access**: Same as previous.
- **Calls**: Same as previous.
- **Key behavior**: Updates 8-byte field at offset 8.

### 18. 0x87310-0x87382: `update_array_element`
- **Entry**: 0x87310
- **Purpose**: Updates element in array (8-byte elements).
- **Arguments**: Base at FP@(8), index at FP@(16), data at FP@(20).
- **Returns**: None.
- **RAM access**: 0x20008f8, 0x20223ac.
- **Calls**: 0xffff24ac (error), 0x6446 (bounds), 0x6b4a (permission).
- **Key behavior**: Calculates element address (base + index*8), updates with permission check.

### 19. 0x87384-0x873d8: `update_hash_table_entry`
- **Entry**: 0x87384
- **Purpose**: Updates entry in hash table at 0x2017354+56.
- **Arguments**: Index at FP@(8), data at FP@(12).
- **Returns**: None.
- **RAM access**: 0x2017354 (hash table), 0x20008f8.
- **Calls**: 0x6bb2 (permission check).
- **Key behavior**: Updates 8-byte hash table entry.

### 20. 0x873da-0x87416: `set_byte_in_structure`
- **Entry**: 0x873da
- **Purpose**: Sets byte at offset in structure.
- **Arguments**: Structure at FP@(8), offset at FP@(16), value at FP@(23).
- **Returns**: None.
- **RAM access**: 0x20008f8, 0x20223ac.
- **Calls**: 0xffff24ac (error), 0x6446 (bounds).
- **Key behavior**: Sets single byte with bounds and permission checking.

### 21. 0x87418-0x8745a: `remove_low_priority_items`
- **Entry**: 0x87418
- **Purpose**: Removes items from linked list where priority byte (offset 9) < threshold.
- **Arguments**: List head at FP@(8), threshold at FP@(15).
- **Returns**: None.
- **RAM access**: None specific.
- **Key behavior**: Traverses linked list, removes items with priority < threshold.

### 22. 0x8745c-0x874f6: `cleanup_multiple_lists`
- **Entry**: 0x8745c
- **Purpose**: Cleans up multiple linked lists based on priority threshold.
- **Arguments**: Base structure at FP@(8), threshold at FP@(15).
- **Returns**: None.
- **RAM access**: 0x20175b0 (free list), various offsets.
- **Calls**: 0x66de (free-like).
- **Key behavior**: Cleans up lists at offsets 98, 102, 106 with different field offsets.

### 23. 0x874f8-0x87542: `cleanup_list_at_106`
- **Entry**: 0x874f8
- **Purpose**: Cleans up linked list at offset 106 with field at offset 13.
- **Arguments**: Base at FP@(8), threshold at FP@(15).
- **Returns**: None.
- **RAM access**: None specific.
- **Key behavior**: Similar to previous but for specific list.

### 24. 0x87544-0x87586: `cleanup_list_at_110`
- **Entry**: 0x87544
- **Purpose**: Cleans up linked list at offset 110 with field at offset 14.
- **Arguments**: Base at FP@(8), threshold at FP@(15).
- **Returns**: None.
- **RAM access**: None specific.
- **Key behavior**: Similar to previous.

### 25. 0x87588-0x875c6: `execute_callbacks_forward`
- **Entry**: 0x87588
- **Purpose**: Executes callbacks in forward order from table.
- **Arguments**: Priority byte at FP@(11).
- **Returns**: None.
- **RAM access**: 0x201725c (callback table), 0x20172ac (count).
- **Key behavior**: Calls each callback in table with priority as argument.

### 26. 0x875c8-0x875fc: `execute_callbacks_reverse`
- **Entry**: 0x875c8
- **Purpose**: Executes callbacks in reverse order from table.
- **Arguments**: Priority byte at FP@(11).
- **Returns**: None.
- **RAM access**: 0x2017284 (callback table), 0x20172b0 (count).
- **Key behavior**: Calls callbacks in reverse order.

### 27. 0x875fe-0x87630: `register_forward_callback`
- **Entry**: 0x875fe
- **Purpose**: Registers callback in forward table.
- **Arguments**: Callback pointer at FP@(8).
- **Returns**: None.
- **RAM access**: 0x201725c, 0x20172ac.
- **Calls**: 0x6334 (error on overflow).
- **Key behavior**: Adds callback to table, checks for overflow (max 10).

### 28. 0x87632-0x87664: `register_reverse_callback`
- **Entry**: 0x87632
- **Purpose**: Registers callback in reverse table.
- **Arguments**: Callback pointer at FP@(8).
- **Returns**: None.
- **RAM access**: 0x2017284, 0x20172b0.
- **Calls**: 0x6334 (error on overflow).
- **Key behavior**: Same as previous but for reverse table.

### 29. 0x87666-0x876ce: `find_in_linked_list`
- **Entry**: 0x87666
- **Purpose**: Searches linked list for item with matching priority and type.
- **Arguments**: List head at FP@(8), priority at FP@(15).
- **Returns**: Pointer in D0 if found, NULL otherwise.
- **RAM access**: 0x20174a4 (comparison address).
- **Key behavior**: Searches for item with priority >= threshold and specific type codes.

### 30. 0x876d0-0x87730: `check_priority_in_lists`
- **Entry**: 0x876d0
- **Purpose**: Checks if priority exists in multiple linked lists.
- **Arguments**: Priority byte at FP@(11).
- **Returns**: None.
- **RAM access**: 0x20173e8, 0x20174bc, 0x20174a4 (list heads).
- **Calls**: 0x87666 (find_in_linked_list), 0xffff0f8c (error handler).
- **Key behavior**: Checks three different lists, calls error handler if found.

### 31. 0x87732-0x877fa: `process_priority_request` (incomplete - continues beyond 0x87800)
- **Entry**: 0x87732
- **Purpose**: Main function for processing priority-based requests. Complex state machine.
- **Arguments**: Priority at FP@(11), optional data at FP@(12).
- **Returns**: Unknown (function continues beyond analyzed range).
- **RAM access**: 0x20223b0, 0x20223a4, 0x20008f8, 0x20008f4, 0x20172b4, many others.
- **Calls**: 0x6334 (error), 0x76d0 (check_priority_in_lists), 0x75c8 (execute_callbacks_reverse), 0xdf1c (unknown).
- **Key behavior**: Sets up execution context, processes priority, searches in linked lists, manages callbacks.

- **0x7c88**: String descriptor template (referenced at 0x87004)
- **0x201725c**: Forward callback table (10 entries max)
- **0x2017284**: Reverse callback table (10 entries max)
- **0x20172ac**: Forward callback count
- **0x20172b0**: Reverse callback count
- **0x20172b4**: Some flag
- **0x20172b8**: Global string descriptor location
- **0x2017354**: Hash table base (PostScript font dictionary)
- **0x20173e8, 0x20174a4, 0x20174bc**: Linked list heads
- **0x20175b0**: Free list pointer
- **0x20223a4, 0x20223a8, 0x20223ac, 0x20223b0**: Global memory management structures

1. This region implements a sophisticated memory management system with permission checking (byte at 0x20008f8).
2. There's a callback registration system for forward and reverse execution orders.
3. The code handles multiple linked lists for different purposes (free lists, priority queues).
4. String descriptors are used to represent strings with length and offset from base.
5. The permission system uses bitfield operations (bfextu/bfins) to check access rights.
6. Error handling is consistent with calls to 0xffff24ac for permission errors and 0x6334 for other errors.

## CORRECTIONS FROM PRIOR ANALYSIS:
- This is NOT SCSI/filesystem code - it's memory management and C runtime
- Functions are more complex than simple memcpy/strcpy - they include permission checking
- The callback system is more elaborate than previously described
- Linked list management is a key theme throughout this region

; === CHUNK 11: 0x87800-0x88400 ===

### 1. Function at 0x87800: `file_operation_handler`
**Entry:** 0x87800  
**Purpose:** Main dispatcher for file operations. Takes an operation code (0-11) and calls four sub-handlers sequentially. Validates operation code range, copies 80 bytes (20 longs) from file structure to buffer at 0x2017354, updates filesystem structures, manages memory allocation size (sets to 1024 bytes if needed), and handles file context switching.  
- `fp@(-8)`: File descriptor pointer  stack frame parameter
- `fp@(11)`: Operation code (byte)  stack frame parameter
- 0x2017354: File operation buffer
- 0x20223a4: Filesystem root structure
- 0x2022270: Memory management structure
- 0x2022274: Memory allocation size (set to 1024)  (PS font cache)
- 0x20008f4: Saved file context pointer
- 0x20008f8: Current file handle
- 0x20175b1: Mirror of current file handle  
**Call targets:** 0x6334 (error), 0x7418, 0x745c, 0x74f8, 0x7544 (operation handlers), 0x708a (filesystem function), 0xd8d8 (unknown), 0x87a90 (update_file_position)  
### 2. Function at 0x87926: `allocate_file_descriptor`
**Entry:** 0x87926  
**Purpose:** Allocates a new file descriptor structure (114 bytes). Checks if current file handle count (max 15) is exceeded, increments count, allocates memory, initializes structure with zeros, copies 80-byte template from 0x2017354, sets up linked list pointers, and calls initialization functions.  
**Return:** `D0` = pointer to new file descriptor  
- 0x20008f8: Current file handle count
- 0x20175b1: Mirror of file handle count
- 0x20223a4: Filesystem root
- 0x20223b0: File descriptor linked list head  (data structure manipulation)
- 0x2017354: Template data  
**Call targets:** 0x6382 (error), 0x8304 (malloc), 0x708a (filesystem init), 0x7588 (file handle init)  
**Called by:** 0x87a04 (save_file_context)

### 3. Function at 0x87a04: `save_file_context`
**Entry:** 0x87a04  
**Purpose:** Saves current file execution context for coroutine-style switching. Saves current file handle, allocates new descriptor, sets up context structure with continuation address and data, and jumps to another bank (0xffff65aa).  
- 0x20008f8: Current file handle
- 0x7cd8: Data table (contains continuation addresses)  
**Call targets:** 0x7926 (allocate_file_descriptor), 0xffff65aa (bank switch/coroutine)  
**Called by:** Likely from PostScript yield/save operations

### 4. Function at 0x87a44: `restore_file_context`
**Entry:** 0x87a44  
**Purpose:** Restores a previously saved file context. Validates operation code (must be 11), checks file handle bounds, and calls 0x7732 to restore context.  
- 0x20008f8: Current file handle count
- 0xffff65f8: Bank switch/coroutine restore  
**Call targets:** 0x63d6 (error), 0x63ba (error), 0x7732 (restore context)  
**Called by:** Likely from PostScript restore operations

### 5. Function at 0x87a90: `update_file_position`
**Entry:** 0x87a90  
**Purpose:** Updates file position and memory allocation. Adjusts memory management structures based on new position, ensures position is within bounds, sets allocation size to 1024 bytes, and updates global file position.  
- `fp@(8)`: New file position  stack frame parameter  (filesystem)
- `fp@(12)`: Unknown parameter  stack frame parameter
- 0x2022270: Memory management structure
- 0x20223a4: Filesystem root
- 0x2022274: Memory allocation size  (PS font cache)
- 0x20009ec: Global file position  (filesystem)
**Call targets:** 0x6334 (error), 0xde50 (unknown)  
**Called by:** 0x87800 (file_operation_handler), 0x87b14 (set_file_position)

### 6. Function at 0x87b14: `set_file_position`
**Entry:** 0x87b14  
**Purpose:** Sets file position with validation. Checks if position is valid, updates memory management, and may trigger context switching.  
- `fp@(8)`: New file position  stack frame parameter  (filesystem)
- 0x20223a4: Filesystem root
- 0x20172b4: Unknown flag
- 0x20008f8: Current file handle  
**Call targets:** 0x6382 (error), 0x7a90 (update_file_position), 0x7310 (unknown)  
### 7. Function at 0x87bac: `file_system_mode_switch`
**Entry:** 0x87bac  
**Purpose:** Switches between different filesystem modes (0, 1, 2). Mode 0 resets context, mode 1 sets up save/restore handlers, mode 2 triggers context switching.  
- `fp@(8)`: Mode (0, 1, or 2)  stack frame parameter
- 0x20172b4: Unknown flag
- 0x20175b4: Context pointer
- 0x20175b0: Context data
- 0x20008f8: Current file handle  
**Call targets:** 0x6948 (register handler), 0x7a04 (save_file_context), 0x7a44 (restore_file_context), 0x7310 (unknown)  
**Called by:** 0x87bac (self via 0x7bac call)

### 8. Data Table at 0x87c5e-0x87cd6
**Address:** 0x87c5e  
**Format:** Array of 15 entries, each 8 bytes (2 longs). First long appears to be a code/flag, second long is likely a pointer or data. This is a file operation code table mapping operation codes to handlers or data structures.

### 9. String Table at 0x87ce6-0x87cf6
**Address:** 0x87ce6  
**Format:** Two null-terminated strings: "save" (0x73617665) and "restore" (0x726573746F7265). Used for context switching operations.

### 10. Function at 0x87cf8: `initialize_file_system`
**Entry:** 0x87cf8  
**Purpose:** Initializes the filesystem by calling multiple setup functions in sequence.  
- `fp@(8)`: Unknown parameter  stack frame parameter
**Call targets:** 0x6a48, 0x8380, 0x8210, 0x7bac (file_system_mode_switch), 0x6462  
**Called by:** System initialization

### 11. Data Table at 0x87d3c-0x87e86
**Address:** 0x87d3c  
**Format:** Large table of byte values (0x43, 0x6F, 0x70, 0x79, etc.). Appears to be character pattern data or a lookup table, not code. Contains repeating patterns that suggest it's font or display data.

### 12. Function at 0x87e88: `allocate_small_buffer`
**Entry:** 0x87e88  
**Purpose:** Allocates a small buffer (30 bytes) using malloc.  
**Return:** `D0` = pointer to allocated buffer  
**Call targets:** 0x8304 (malloc)  
### 13. Function at 0x87ea0: `setup_file_context_structure`
**Entry:** 0x87ea0  
**Purpose:** Sets up a file context structure with proper alignment and initialization. Handles special case when memory management structures are equal.  
- `fp@(10)`: Size parameter (word)  stack frame parameter
- `fp@(12)`: Pointer to context structure  stack frame parameter
- 0x2022270: Memory management structure
- 0x20223a4: Filesystem root
- 0x20008f8: Current file handle
- 0x20175b0: Context data  
**Call targets:** 0x8304 (malloc), 0x82ba (align_and_allocate)  
### 14. Function at 0x87fb6: `setup_simple_context_structure`
**Entry:** 0x87fb6  
**Purpose:** Sets up a simpler context structure with basic initialization.  
- `fp@(10)`: Size parameter (word)  stack frame parameter
- `fp@(12)`: Pointer to context structure  stack frame parameter
- 0x20008f8: Current file handle  
**Call targets:** 0x82ba (align_and_allocate)  
### 15. Function at 0x87ffe: `setup_array_context_structure`
**Entry:** 0x87ffe  
**Purpose:** Sets up a context structure for arrays, allocating memory and initializing elements.  
- `fp@(10)`: Array size (word)  stack frame parameter  (register = size parameter)
- `fp@(12)`: Pointer to context structure  stack frame parameter
- 0x20008f8: Current file handle
- 0x20175b0: Context data  
**Call targets:** 0x8304 (malloc)  
### 16. Function at 0x88078: `initialize_memory_management`
**Entry:** 0x88078  
**Purpose:** Initializes memory management structures with fixed addresses and sizes. Sets up heap boundaries and calls decompression routine.  
- 0x20223b4: Heap start (8220)
- 0x20223a8: Unknown
- 0x20223bc: Current heap pointer
- 0x20223c8: Heap end (8220)  (PS dict operator)
- 0x20223ac: Calculated offset  struct field
- 0x20223b8: Heap size  (register = size parameter)
- 0x20223a4: Filesystem root (set to 0x20b5a58)
- 0x2022270: Memory management structure  
**Call targets:** 0x880f8 (decompress_and_copy)  
**Called by:** System initialization

### 17. Function at 0x880f8: `decompress_and_copy`
**Entry:** 0x880f8  
**Purpose:** Decompresses data using a simple run-length encoding scheme and copies it to destination.  
- `fp@(8)`: Source pointer  stack frame parameter
- `fp@(12)`: Destination pointer  stack frame parameter
- `fp@(16)`: Size  stack frame parameter
**Algorithm:** Reads bytes from source, high nibble = repeat count-1, low nibble = literal count. If low nibble = 15, read next byte as extended count.  
**Call targets:** 0xde50 (memory copy)  
**Called by:** 0x88078 (initialize_memory_management)

### 18. Function at 0x8814c: `copy_string_to_buffer`
**Entry:** 0x8814c  
**Purpose:** Copies a string of specified length to a newly allocated buffer.  
- `fp@(10)`: Length (word)  stack frame parameter
- `fp@(12)`: Source string pointer  stack frame parameter
**Return:** `D0` = pointer to allocated buffer with copied string  
**Call targets:** 0x82ba (align_and_allocate)  
### 19. Function at 0x8818e: `flush_memory_buffer`
**Entry:** 0x8818e  
**Purpose:** Flushes memory buffer if allocation size is zero, otherwise ensures buffer is written.  
- 0x2022274: Memory allocation size  (PS font cache)
- 0x2022270: Memory management structure  
**Call targets:** 0x6334 (error), 0x818e (write_buffer)  
**Called by:** 0x8829c (ensure_buffer_space)

### 20. Function at 0x881c0: `update_file_statistics`
**Entry:** 0x881c0  
**Purpose:** Updates file statistics by calling a function three times with different parameters.  
- 0x20008f8: Current file handle
- 0x20223a4: Filesystem root
- 0x20223ac: Offset value  struct field
**Call targets:** 0xffffbb98 (unknown statistics function)  
### 21. Function at 0x88210: `configure_memory_pool`
**Entry:** 0x88210  
**Purpose:** Configures memory pool based on mode (0 or 1). Mode 0 sets up initial pool, mode 1 updates current position.  
- `fp@(8)`: Mode (0 or 1)  stack frame parameter
- 0x20223c4: Pool start (22000)
- 0x20223cc: Pool size (204800)  (register = size parameter)
- 0x20223b8: Current pool size  (register = size parameter)
- 0x20223ac: Current offset  struct field
- 0x20223c0: Pool end  (PS dict operator)
- 0x2022274: Allocation size (1024)  (register = size parameter)
- 0x20009ec: Global file position  (filesystem)
- 0x20223a4: Filesystem root  
**Call targets:** 0x6948 (register handler), 0x81c0 (update_file_statistics)  
**Called by:** 0x87cf8 (initialize_file_system)

### 22. String at 0x8828e-0x8829a
**Address:** 0x8828e  
**Format:** Null-terminated string "vmstatus" (0x766D737461747573). Used for status reporting.

### 23. Function at 0x8829c: `ensure_buffer_space`
**Entry:** 0x8829c  
**Purpose:** Ensures there's enough space in the buffer for an allocation request. Calls flush if needed.  
- 0x2022274: Memory allocation size  (PS font cache)
**Call targets:** 0x6334 (error), 0x818e (flush_memory_buffer)  
**Called by:** 0x82ba (align_and_allocate)

### 24. Function at 0x882ba: `align_and_allocate`
**Entry:** 0x882ba  
**Purpose:** Allocates aligned memory from the buffer, ensuring proper alignment and flushing if necessary.  
- `fp@(8)`: Size to allocate  stack frame parameter
**Return:** `D0` = pointer to allocated memory  
- 0x2022270: Memory management structure
- 0x2022274: Memory allocation size  (PS font cache)
**Call targets:** 0x829c (ensure_buffer_space)  
**Called by:** Many functions including 0x87ea0, 0x87fb6, 0x8814c

### 25. Function at 0x88304: `malloc_aligned`
**Entry:** 0x88304  
**Purpose:** malloc wrapper that ensures alignment based on 0x20173bc alignment value.  
- `fp@(8)`: Size to allocate  stack frame parameter
**Return:** `D0` = pointer to allocated memory  
- 0x20173bc: Alignment value
- 0x2022270: Memory management structure  
**Call targets:** 0x82ba (align_and_allocate)  
**Called by:** Many functions including 0x87926, 0x87ea0, 0x87ffe

### 26. Function at 0x88344: `find_resource`
**Entry:** 0x88344  
**Purpose:** Looks up a resource by name and type. Returns pointer or error.  
- `fp@(8)`: Resource name  stack frame parameter
- `fp@(12)`: Resource type  stack frame parameter
**Return:** `D0` = pointer to resource or NULL  
**Call targets:** 0xd818 (resource lookup), 0x6382 (error)  
### 27. Function at 0x8836c: `release_resource`
**Entry:** 0x8836c  
**Purpose:** Releases a previously allocated resource.  
- `fp@(8)`: Resource pointer  stack frame parameter
**Call targets:** 0xd858 (resource release)  
### 28. Function at 0x88380: `validate_mode`
**Entry:** 0x88380  
**Purpose:** Validates that a mode value is either 0 or 1.  
- `fp@(8)`: Mode value  stack frame parameter
**Return:** Sets condition codes (Z flag for 0, other for 1)  
### 29. Function at 0x88392: `clear_file_flags`
**Entry:** 0x88392  
**Purpose:** Clears specific flags in a file structure.  
- `fp@(8)`: File structure pointer  stack frame parameter
### 30. Function at 0x883b0: `read_byte_from_buffer`
**Entry:** 0x883b0  
**Purpose:** Reads a byte from a buffer structure, handling underflow by calling a handler function.  
- `fp@(8)`: Buffer structure pointer  stack frame parameter
**Return:** `D0` = byte read (zero-extended)  
**Algorithm:** Decrements count, increments pointer, reads byte. If count goes negative, calls handler via function pointer at offset 14.  
### 31. Function at 0x883e8: `read_byte_with_context`
**Entry:** 0x883e8  
**Purpose:** Similar to 0x883b0 but with different structure layout. Reads byte from context buffer.  
- `fp@(12)`: Context buffer pointer  stack frame parameter
**Return:** `D0` = byte read  
**Algorithm:** Similar to 0x883b0 but structure offsets differ.  
2. The large data table at 0x87d3c is NOT code - it's character pattern data.
3. Function at 0x880f8 is a decompression routine, not just a copy function.
4. The three malloc-related functions (0x882ba, 0x88304, 0x88344) are part of the memory management subsystem.
5. The file context switching functions (0x87a04, 0x87a44) use bank switching addresses (0xffff65aa, 0xffff65f8) for coroutine-style execution.

- This region contains the filesystem context management and memory allocation subsystems.  (PS font cache)
- The system uses a coroutine model for file operations with save/restore context switching.
- Memory allocation has alignment requirements and automatic buffer flushing.  (PS font cache)
- There's a simple RLE decompression scheme used during initialization.
- File operations use a dispatch table with 15 operation codes.

; === CHUNK 12: 0x88400-0x89000 ===

### 1. Function at 0x88400
**Entry:** 0x88400  
**Name:** `call_file_method`
**Purpose:** Calls a method from a file object's vtable. Takes a file object pointer and method index, looks up the method pointer from the vtable at offset 14, and calls it with the provided argument. This is part of the file I/O abstraction layer.  
- `fp@(8)`: File object pointer  stack frame parameter
- `fp@(11)`: Method index (byte)  stack frame parameter
- `fp@(12)`: Argument to pass to method  stack frame parameter
**Return:** Returns whatever the method returns (in D0).  
**Call targets:** Indirect call through vtable at offset 14+4.  
### 2. Function at 0x8842e
**Entry:** 0x8842e  
**Name:** `write_string_to_buffer`
**Purpose:** Writes a null-terminated string to a buffered output stream. Handles buffered output when buffer has space, and calls the underlying write method when buffer is full. Similar to fputs() for custom buffered streams.  
- `fp@(8)`: String pointer (source)  stack frame parameter
- `fp@(12)`: Buffer structure pointer (dest)  stack frame parameter
**Return:** Returns the last character written or error code (in D0).  
**Call targets:** Indirect call through buffer's write method (vtable at offset 14+4).  
**Called by:** Likely printf/formatted output functions.

### 3. Stub functions at 0x88480, 0x8848a, 0x88494
**Entries:** 0x88480, 0x8848a, 0x88494  
**Suggested names:** `stub_return_minus1`, `stub_return_minus1_2`, `stub_return_zero`  
**Purpose:** Simple stub functions that return constant values (-1, -1, 0 respectively). These are likely placeholder functions or default implementations for file operations.  
**Return:** D0 = -1 or 0.  
### 4. Function at 0x8849e
**Entry:** 0x8849e  
**Name:** `init_file_handles`
**Purpose:** Initializes a table of file handle structures. Allocates memory for 26-byte structures (20 file handles × 26 bytes = 520 bytes), calculates table bounds, and initializes global pointers to the table. Sets up free list pointers.  
- 0x20172c0: Base of file handle table
- 0x20172c4: End of file handle table  
- 0x20008fc, 0x2000900, 0x2000904: Free list pointers  
- 0xd818: Memory allocator (malloc)
- 0x88584: Function to initialize a file handle entry  
**Called by:** System initialization.

### 5. Function at 0x88514
**Entry:** 0x88514  
**Name:** `flush_all_file_handles`
**Purpose:** Iterates through all file handles in the table and calls their close/flush method (vtable offset 24). Used during system shutdown or cleanup.  
- 0x20172c0: File handle table base
- 0x20172c4: File handle table end  (PS dict operator)
**Call targets:** Indirect call through each handle's close method (vtable offset 24).  
**Called by:** System shutdown/cleanup.

### 6. Function at 0x88544
**Entry:** 0x88544  
**Name:** `find_file_handle_by_vtable`
**Purpose:** Searches the file handle table for an entry with a specific vtable pointer (0x88884), and replaces it with a new vtable pointer. Returns the found handle or NULL.  
**Arguments:** `fp@(8)`: New vtable pointer  
**Return:** D0 = pointer to found file handle, or NULL if not found.  
- 0x20172c0: File handle table base
- 0x20172c4: File handle table end  (PS dict operator)
### 7. Function at 0x88584
**Entry:** 0x88584  
**Name:** `init_file_handle_entry`
**Purpose:** Initializes a single file handle entry by zeroing 26 bytes and setting its vtable pointer to 0x88884.  
**Arguments:** `fp@(8)`: Pointer to file handle entry  
- 0xde50: Memory zeroing function (likely memset)  
**Called by:** `init_file_handles` at 0x884d8.

### 8. Function at 0x885a8
**Entry:** 0x885a8  
**Name:** `read_formatted_data`
**Purpose:** Reads formatted data from a buffered input stream. Handles reading with buffering, calling the underlying read method when buffer is empty. Supports reading multiple items with size/count parameters.  
- `fp@(8)`: Destination buffer  stack frame parameter
- `fp@(12)`: Size of each item  stack frame parameter
- `fp@(16)`: Number of items  stack frame parameter
- `fp@(20)`: Buffer structure pointer  stack frame parameter
**Return:** D0 = number of items successfully read.  
- 0xdcf8: Memory copy function (likely memcpy)  
**Called by:** Likely fread() or similar formatted input functions.

### 9. Function at 0x8863c
**Entry:** 0x8863c  
**Name:** `write_formatted_data`
**Purpose:** Writes formatted data to a buffered output stream. Handles writing with buffering, calling the underlying write method when buffer is full. Supports writing multiple items with size/count parameters.  
- `fp@(8)`: Source buffer  stack frame parameter
- `fp@(12)`: Size of each item  stack frame parameter
- `fp@(16)`: Number of items  stack frame parameter
- `fp@(20)`: Buffer structure pointer  stack frame parameter
**Return:** D0 = number of items successfully written.  
- 0xdcf8: Memory copy function (likely memcpy)  
**Called by:** Likely fwrite() or similar formatted output functions.

### 10. Function at 0x886d6
**Entry:** 0x886d6  
**Name:** `put_char_to_buffer`
**Purpose:** Puts a single character to a buffered output stream. Handles buffering and calls the underlying write method when buffer is full. Checks for special EOF value (-1).  
- `fp@(8)`: Character to write (as int)  stack frame parameter
- `fp@(12)`: Buffer structure pointer  stack frame parameter
**Return:** D0 = character written, or -1 on error.  
**Called by:** Likely putc() or fputc() equivalents.

### 11. Data table at 0x88734-0x8887e
**Address:** 0x88734  
**Size:** 330 bytes (0x88734 to 0x8887e)  
**Format:** Character classification table (likely for ctype.h functions like isdigit, isalpha, etc.)
**Content:** 256-byte table with bit flags for character classification. The table appears to be indexed by character value and contains flags for different character classes.

### 12. Vtable at 0x88880-0x888b4
**Address:** 0x88880  
**Size:** 52 bytes (0x88880 to 0x888b4)  
**Format:** Vtable structure with 13 function pointers (4 bytes each)
**Content:** Function pointers for file operations. The first entry at 0x88884 points to the vtable itself (common pattern for object-oriented C).

### 13. String at 0x888b6
**Address:** 0x888b6  
**Content:** "Closed" (null-terminated string)

### 14. Function at 0x888be
**Entry:** 0x888be  
**Name:** `fprintf`
**Purpose:** Formatted output to a file stream. Takes a format string and variable arguments, formats them, and writes to the specified file stream.  
- `fp@(8)`: File stream pointer  stack frame parameter
- `fp@(12)`: Format string  stack frame parameter
- Variable arguments starting at `fp@(16)`  stack frame parameter
**Return:** D0 = number of characters written, or -1 on error.  
- 0x8998: Core printf implementation  
**Called by:** Various formatted output functions.

### 15. Function at 0x888f8
**Entry:** 0x888f8  
**Name:** `printf`
**Purpose:** Formatted output to standard output. Takes a format string and variable arguments, formats them, and writes to stdout.  
- `fp@(8)`: Format string  stack frame parameter
- Variable arguments starting at `fp@(12)`  stack frame parameter
**Return:** D0 = number of characters written, or -1 on error.  
- 0x2000904: Standard output file handle pointer  
- 0x8998: Core printf implementation  
**Called by:** Various formatted output functions.

### 16. Function at 0x88934
**Entry:** 0x88934  
**Name:** `sprintf`
**Purpose:** Formatted output to a string buffer. Takes a destination buffer, format string, and variable arguments, formats them, and writes to the buffer.  
- `fp@(8)`: Destination buffer  stack frame parameter
- `fp@(12)`: Format string  stack frame parameter
- Variable arguments starting at `fp@(16)`  stack frame parameter
**Return:** D0 = pointer to destination buffer.  
- 0x8998: Core printf implementation  
**Called by:** Various formatted output functions.

### 17. Function at 0x88998
**Entry:** 0x88998  
**Name:** `_doprnt`
**Purpose:** Core implementation of formatted output. Handles format string parsing, argument processing, and output generation for all printf-family functions.  
- `fp@(8)`: Output function/context structure  stack frame parameter
- `fp@(12)`: Format string  stack frame parameter
- `fp@(16)`: Argument pointer (va_list)  stack frame parameter
**Return:** D0 = number of characters written.  
**Hardware/RAM accessed:** Various local stack variables.  
- 0x9624: Helper function (likely for argument processing)
- 0xdcd4: String length function (likely strlen)
- 0xc264, 0xc28c, 0xb1be, 0x89968: Various helper functions for floating point and formatting
- Indirect calls through output function pointers  
**Called by:** `fprintf`, `printf`, `sprintf` at 0x888d8, 0x88912, 0x88962.

**Note:** This is a large, complex function (over 1500 bytes) that implements the full printf functionality including:
- Format specifier parsing (flags, width, precision, length modifiers)  (font metric)
- Integer formatting (decimal, octal, hexadecimal)
- Floating point formatting (with scientific notation)
- String and character output
- Padding and alignment

The function continues beyond 0x89000, so the analysis of this region is incomplete. The code at 0x89000 appears to be in the middle of the `_doprnt` function, handling floating-point formatting cases.

2. **Data regions misidentified:** The prior analysis didn't identify the character classification table at 0x88734 or the vtable at 0x88880.

3. **Function boundaries incorrect:** The prior analysis ended at 0x88584 but there's significant code after that.

4. **Incomplete analysis:** The `_doprnt` function at 0x88998 is a major component of the C runtime library and extends well beyond 0x89000.

This region contains the core I/O buffering system and formatted output implementation for the C runtime library, which is consistent with bank 4 being the C runtime and filesystem code.

; === CHUNK 13: 0x89000-0x89C00 ===

1. **0x89622-0x8962E** is indeed **DATA** - it's a function prologue/epilogue template used by the compiler for small functions.
2. **0x8991E-0x89BCA** contains the **FPU emulation dispatch table** (24 entries) followed by **hardware FPU wrappers**.
### 1. **Entry: 0x89000** 
**Name:** `format_float_specifier`
**What it does:** Handles floating-point format specifiers ('f', 'e', 'g') in a printf-like function. Converts double-precision values to string representation with precision, width, and padding control. Handles special cases: NaN, Infinity, denormals. Implements rounding, decimal point placement, and exponent formatting. Contains multiple code paths for different format types and edge cases.
**Arguments:** Uses frame pointer with many local variables. Stack args include: fp@(8) = output function pointer, fp@(12) = format string pointer, fp@(16) = va_list pointer.
**Return value:** D0 = number of characters output (or -1 on error)
**Hardware accessed:** None directly.
**Call targets:** 0xb1e6, 0xc28c, 0xb1be, 0x89968, 0xdcd4 (string length, float classification, conversion routines)
**Called by:** Main printf/sprintf implementation (not in this chunk).
**Key algorithm:** Handles width/precision specifiers, left/right justification, zero padding, sign display. For 'f' format: converts to decimal with specified precision. For 'e' format: scientific notation. For 'g' format: chooses between 'f' and 'e' based on exponent range.

### 2. **Entry: 0x89630**
**Name:** `call_double_indirect`
**What it does:** Calls a function through a double-indirect function pointer. First loads a pointer from offset 0xE, then from offset 0x10 within that structure, then calls it with one argument. Used for C++ virtual function dispatch or callback systems.
**Arguments:** fp@(8) = base pointer to structure, fp@(12) = argument
**Return value:** D0 = function return value
**Call targets:** Function pointer at offset 0x10 from offset 0xE
### 3. **Entry: 0x89662**
**Name:** `call_triple_indirect`
**What it does:** Calls a function through a function table at offset 0x28 with three arguments. Similar to 0x89630 but for functions with three parameters.
**Arguments:** fp@(8) = base pointer, fp@(12) = arg1, fp@(16) = arg2
**Return value:** D0 = function return value
**Call targets:** Function pointer at offset 0x28 from offset 0xE

### 4. **Entry: 0x89688**
**Name:** `call_single_indirect`
**What it does:** Calls a function through a function table at offset 0x2C with one argument. Simpler version of the indirect call pattern.
**Arguments:** fp@(8) = base pointer
**Return value:** D0 = function return value
**Call targets:** Function pointer at offset 0x2C from offset 0xE

### 5. **Entry: 0x896a4**
**Name:** `fpu_round_to_nearest`
**What it does:** Implements IEEE 754 round-to-nearest (ties to even) for double-precision floating-point. Handles all IEEE special cases: denormals, overflow, underflow, NaN, infinity. For normal numbers, adds rounding bits based on guard/round/sticky bits, then normalizes result.
**Arguments:** D0-D1 = double-precision value (D0 = high word, D1 = low word)
**Return value:** D0-D1 = rounded double-precision value
**Algorithm:** Checks exponent range, handles denormals by adding rounding bits, implements tie-breaking (round to even when guard=1 and round=sticky=0). Uses D2-D4 as scratch registers.
**Hardware accessed:** None (pure software FPU).

### 6. **Entry: 0x89764**
**Name:** `fpu_round_toward_zero`
**What it does:** Implements IEEE 754 round-toward-zero (truncation) for double-precision floating-point. Simply discards fractional bits without rounding up. Similar structure to 0x896a4 but always truncates.
**Arguments:** D0-D1 = double-precision value
**Return value:** D0-D1 = truncated double-precision value
**Algorithm:** Masks out fractional bits based on exponent, handles special cases.
### 7. **Entry: 0x897e8**
**Name:** `fpu_round_to_minus_infinity`
**What it does:** Implements IEEE 754 round-toward-negative-infinity for double-precision floating-point. Always rounds down toward more negative values.
**Arguments:** D0-D1 = double-precision value
**Return value:** D0-D1 = rounded double-precision value
**Algorithm:** Similar to previous rounding functions but with different rounding direction logic.

### 8. **Entry: 0x8984a**
**Name:** `fpu_round_to_plus_infinity`
**What it does:** Implements IEEE 754 round-toward-positive-infinity for double-precision floating-point. Always rounds up toward more positive values.
**Arguments:** D0-D1 = double-precision value
**Return value:** D0-D1 = rounded double-precision value
**Algorithm:** Calls 0x897e8 (round-to-minus-infinity) then adjusts based on sign.

### 9. **Entry: 0x898b8**
**Name:** `fpu_init`
**What it does:** Initializes the FPU emulation/hardware system. Checks if hardware FPU is present (at 0x2000080) and sets up appropriate dispatch tables. Initializes FPU control registers and status flags.
**Hardware accessed:** Checks 0x2000080 (FPU present flag), writes to 0x20223d0, 0x20223e8, 0x20223d8 (FPU control registers)
**Call targets:** 0xd558 (software FPU initialization if no hardware FPU)
**Called by:** System initialization code

### 10. **DATA REGION: 0x89622-0x8962E**
**Format:** Function prologue/epilogue template
**Content:** `0000 4e56 0000 202e 0008 4e5e 4e75`
**Interpretation:** This is a template for small functions: `linkw %fp,#0` (4e56 0000), `movel %fp@(8),%d0` (202e 0008), `unlk %fp` (4e5e), `rts` (4e75). The compiler may use this for code generation.

### 11. **DATA REGION: 0x894d0-0x89620**
**Format:** String tables and format specifier data
**Content:** Includes:
- 0x894d0: Format specifier characters: "-+ 0"
- 0x894d6: Hex digits uppercase: "0123456789ABCDEF"
- 0x894e8: Hex digits lowercase: "0123456789abcdef"  (PS dict operator)
- 0x894f8: "0x", "0X" prefixes
- 0x8950a: "Infinity" string
- 0x89514: "NaN" string  
- 0x89518: "(null)" string
- 0x8951e: ASCII character classification table (256 bytes)

### 12. **FPU DISPATCH TABLE: 0x8991e-0x89bc9**
**Format:** 24 entries × 12 bytes each, followed by hardware FPU wrappers
**Structure:** Each entry: `2f30 89f3 0202 23d8 0008 XXXX 4e75` where XXXX is the target address.
**Entries map to:** Various FPU operations (add, sub, mul, div, compare, convert, etc.)
**Hardware FPU wrappers (0x89af6-0x89bca):** Use 68881/68882 FPU instructions if hardware present.

1. **Three rounding modes implemented:** round-to-nearest (0x896a4), round-toward-zero (0x89764), round-to-minus-infinity (0x897e8), round-to-plus-infinity (0x8984a).

2. **FPU system is hybrid:** Can use software emulation or hardware FPU (68881/68882). The initialization function at 0x898b8 detects hardware and sets up appropriate dispatch.

3. **The printf float formatting is complex:** Handles all IEEE 754 special cases and multiple format specifiers with full width/precision control.

4. **Indirect call functions (0x89630, 0x89662, 0x89688):** Suggest C++ virtual function dispatch or callback system in the PostScript interpreter.

5. **Data at 0x89622 is NOT code:** It's a compiler template for generating small functions.

; === CHUNK 14: 0x89C00-0x8A800 ===

### 1. **Entry: 0x89C00**
**Name:** `fpu_square`
**What it does:** Squares a floating-point number (multiplies it by itself). Loads double-precision value from stack into FP0, multiplies FP0 by itself, stores result back to stack.
**Arguments:** Double-precision value passed on stack (SP@)
**Return value:** Double-precision result on stack (SP@)
**Hardware accessed:** FPU only (fmoved, fmulx)
**Call targets:** None (leaf function)
**Called by:** Unknown, likely math library users

### 2. **Entry: 0x89C12**
**Name:** `fpu_add_mem`
**What it does:** Adds a double-precision value from memory (A0@) to a value on stack. Saves/restores FPCR with rounding mode set to extended precision (bit 7).
**Arguments:** D0-D1 contain value on stack, A0 points to memory operand
**Return value:** Double-precision result on stack
**Hardware accessed:** FPU control register (FPCR)
### 3. **Entry: 0x89C40**
**Name:** `fpu_sub_mem`
**What it does:** Subtracts a double-precision value from memory (A0@) from value on stack. Similar to fpu_add_mem but with fsubd.
**Arguments:** D0-D1 contain value on stack, A0 points to memory operand
**Return value:** Double-precision result on stack
**Hardware accessed:** FPU control register (FPCR)
### 4. **Entry: 0x89C6E**
**Name:** `fpu_mul_mem`
**What it does:** Multiplies value on stack by double-precision value from memory (A0@).
**Arguments:** D0-D1 contain value on stack, A0 points to memory operand
**Return value:** Double-precision result on stack
**Hardware accessed:** FPU control register (FPCR)
### 5. **Entry: 0x89C9C**
**Name:** `fpu_div_mem`
**What it does:** Divides value on stack by double-precision value from memory (A0@).
**Arguments:** D0-D1 contain value on stack, A0 points to memory operand
**Return value:** Double-precision result on stack
**Hardware accessed:** FPU control register (FPCR)
### 6. **Entry: 0x89CCA**
**Name:** `fpu_scale`
**What it does:** Performs fscalel instruction - scales floating-point value by power of two (2^n where n is integer from memory at A0@).
**Arguments:** D0-D1 contain value on stack, A0 points to integer scale factor
**Return value:** Double-precision result on stack
### 7. **Entry: 0x89CE0**
**Name:** `fpu_set_fpcr`
**What it does:** Sets FPU control register (FPCR) and returns old value. Simple wrapper for fmovel.
**Arguments:** D0 contains new FPCR value
**Return value:** D0 contains old FPCR value
**Hardware accessed:** FPU control register
### 8. **Entry: 0x89CEC**
**Name:** `fpu_set_fpsr`
**What it does:** Sets FPU status register (FPSR) and returns old value.
**Arguments:** D0 contains new FPSR value
**Return value:** D0 contains old FPSR value
**Hardware accessed:** FPU status register
### 9. **Entry: 0x89CF8**
**Name:** `fpu_compare_single`
**What it does:** Compares two single-precision floating-point values and sets condition codes. Uses lookup table at 0x89D12 to map FPSR comparison results to CCR flags.
**Arguments:** D0 and D1 contain single-precision values to compare
**Return value:** Condition codes set appropriately
**Hardware accessed:** FPU status register
### 10. **Entry: 0x89D12**
**Data region:** CCR lookup table for FPU comparisons
**Size:** 16 bytes (8 words)
**Format:** 8 words mapping FPSR condition codes (bits 24-27) to CCR flags

### 11. **Entry: 0x89D32**
**Name:** `fpu_compare_double_mem`
**What it does:** Compares double-precision value on stack with value at A0@. Similar to fpu_compare_single but for double-precision.
**Arguments:** D0-D1 contain value on stack, A0 points to memory operand
**Return value:** Condition codes set appropriately
**Hardware accessed:** FPU status register
### 12. **Entry: 0x89D50**
**Name:** `fpu_truncate_to_int`
**What it does:** Truncates double-precision value to integer using fintrzd (round toward zero).
**Arguments:** D0-D1 contain double-precision value on stack
**Return value:** Double-precision integer result on stack
### 13. **Entry: 0x89D62**
**Name:** `fpu_round_to_int`
**What it does:** Rounds double-precision value to integer using fintd (round according to current rounding mode).
**Arguments:** D0-D1 contain double-precision value on stack
**Return value:** Double-precision integer result on stack
### 14. **Entry: 0x89D74**
**Name:** `fpu_round_to_int_round_up`
**What it does:** Rounds double-precision value to integer with rounding mode set to round up (toward +∞).
**Arguments:** D0-D1 contain double-precision value on stack
**Return value:** Double-precision integer result on stack
**Hardware accessed:** FPU control register
### 15. **Entry: 0x89D9E**
**Name:** `fpu_round_to_int_round_down`
**What it does:** Rounds double-precision value to integer with rounding mode set to round down (toward -∞).
**Arguments:** D0-D1 contain double-precision value on stack
**Return value:** Double-precision integer result on stack
**Hardware accessed:** FPU control register
### 16. **Entry: 0x89DC8**
**Name:** `fpu_round_to_int_nearest`
**What it does:** Rounds double-precision value to nearest integer, with ties rounding to even (banker's rounding).
**Arguments:** D0-D1 contain double-precision value on stack
**Return value:** Double-precision integer result on stack
**Hardware accessed:** FPU control register
### 17. **Entry: 0x89E16**
**Name:** `fpu_sqrt`
**What it does:** Computes square root of double-precision value.
**Arguments:** D0-D1 contain double-precision value on stack
**Return value:** Double-precision square root on stack
### 18. **Entry: 0x89E28**
**Name:** `fpu_hypot`
**What it does:** Computes hypotenuse: sqrt(x² + y²) where x is on stack and y is at A0@.
**Arguments:** D0-D1 contain x on stack, A0 points to y
**Return value:** Double-precision result on stack
### 19. **Entry: 0x89E4E**
**Name:** `fpu_mod`
**What it does:** Computes floating-point modulus: x mod y = x - y*trunc(x/y).
**Arguments:** D0-D1 contain x on stack, A0 points to y
**Return value:** Double-precision modulus on stack
### 20. **Entry: 0x89E64**
**Name:** `fpu_remainder`
**What it does:** Computes IEEE remainder: x REM y = x - y*round(x/y).
**Arguments:** D0-D1 contain x on stack, A0 points to y
**Return value:** Double-precision remainder on stack
### 21. **Entry: 0x89E7A**
**Name:** `float_to_int_single`
**What it does:** Converts single-precision float to 32-bit integer with special handling for large values.
**Arguments:** D0 contains single-precision float
**Return value:** D0 contains 32-bit integer
### 22. **Entry: 0x89EA8**
**Name:** `float_to_int_double`
**What it does:** Converts double-precision float to 32-bit integer with special handling for large values.
**Arguments:** D0-D1 contain double-precision float
**Return value:** D0 contains 32-bit integer
### 23. **Entry: 0x89ED6**
**Name:** `fabs`
**What it does:** Computes absolute value of double-precision float.
**Arguments:** D0-D1 contain double-precision value
**Return value:** D0-D1 contain absolute value
**Call targets:** 0x89968 (compare), 0x8A0D4 (atan)
### 24. **Entry: 0x89F34**
**Name:** `atan2`
**What it does:** Computes arctangent of y/x (atan2 function).
**Arguments:** D0-D1 contain y, A0 points to x
**Return value:** D0-D1 contain result in radians
**Call targets:** 0x89920 (add), 0x89968 (compare), 0x89998 (multiply), 0x89AA0 (subtract), 0x8A0D4 (atan)
### 25. **Entry: 0x8A0D4**
**Name:** `atan`
**What it does:** Computes arctangent (inverse tangent) using polynomial approximation.
**Arguments:** D0-D1 contain double-precision value
**Return value:** D0-D1 contain result in radians
**Call targets:** 0x89920 (add), 0x89968 (compare), 0x89998 (multiply), 0x89AA0 (subtract), 0x8A1B6 (atan_core)
**Called by:** fabs, atan2

### 26. **Entry: 0x8A1B6**
**Name:** `atan_core`
**What it does:** Core arctangent computation using polynomial approximation with range reduction.
**Arguments:** D0-D1 contain double-precision value (|x| ≤ 1)
**Return value:** D0-D1 contain arctan(x) in radians
**Call targets:** 0x89920 (add), 0x89998 (multiply), 0x89A58 (divide)
**Called by:** atan

### 27. **Entry: 0x8A338**
**Name:** `log`
**What it does:** Computes natural logarithm (ln) using range reduction and polynomial approximation.
**Arguments:** D0-D1 contain double-precision value
**Return value:** D0-D1 contain ln(x)
**Call targets:** 0x89920 (add), 0x89968 (compare), 0x89998 (multiply), 0x89A58 (divide), 0x899F8 (float_to_int), 0xB314 (unknown)
### 28. **Entry: 0x8A56E**
**Name:** `log10`
**What it does:** Computes base-10 logarithm using log(x) * log10(e).
**Arguments:** D0-D1 contain double-precision value
**Return value:** D0-D1 contain log10(x)
**Call targets:** 0x89998 (multiply), 0x8A338 (log)
### 29. **Entry: 0x8A5E0**
**Name:** `pow`
**What it does:** Computes x^y using exp(y * log(x)).
**Arguments:** D0-D1 contain x, A0 points to y
**Return value:** D0-D1 contain x^y
**Call targets:** 0x89920 (add), 0x89968 (compare), 0x89998 (multiply), 0x89A58 (divide), 0x89A28 (unknown), 0x899F8 (float_to_int), 0x8A338 (log), 0xD59C (exp)
### 30. **Entry: 0x8A72A**
**Name:** `cos`
**What it does:** Computes cosine using range reduction and polynomial approximation.
**Arguments:** D0-D1 contain double-precision angle in radians
**Return value:** D0-D1 contain cos(x)
**Call targets:** 0x89968 (compare), 0x8A7A0 (sin_cos_core)
### 31. **Entry: 0x8A784**
**Name:** `sin`
**What it does:** Computes sine using range reduction and polynomial approximation.
**Arguments:** D0-D1 contain double-precision angle in radians
**Return value:** D0-D1 contain sin(x)
**Call targets:** 0x8A7A0 (sin_cos_core)
### 32. **Entry: 0x8A7A0**
**Name:** `sin_cos_core`
**What it does:** Core sine/cosine computation with range reduction to [0, π/4].
**Arguments:** D0-D1 contain angle, SP@(16) contains quadrant adjustment flag
**Return value:** D0-D1 contain sin(x) or cos(x) depending on quadrant
**Call targets:** 0x89920 (add), 0x89968 (compare), 0x89998 (multiply), 0x89A58 (divide)
**Called by:** sin, cos

### 1. **0x89D12-0x89D31**: CCR lookup table for FPU comparisons
**Size:** 16 bytes (8 words)
**Format:** Words mapping FPSR condition codes to CCR flags

### 2. **0x89EA4**: Single-precision constant 0x4F000000 (2^32)
### 3. **0x8A1AE-0x8A1B3**: Double-precision constant 1.0
### 4. **0x8A2C6-0x8A337**: Various double-precision constants for math functions
**Contains:** Constants for atan, log, sin/cos approximations

2. The functions at 0x89ED6, 0x89F34, 0x8A0D4, 0x8A1B6, 0x8A338, 0x8A56E, 0x8A5E0, 0x8A72A, 0x8A784, and 0x8A7A0 are transcendental math functions (abs, atan2, atan, log, log10, pow, cos, sin) that were missed in the prior analysis.

3. The region contains a complete math library with:
   - Basic FPU operations (add, sub, mul, div, sqrt, mod, remainder)
   - Type conversions (float to int)
   - Transcendental functions (trig, log, pow)  (PS dict operator)
   - FPU control operations

4. All functions follow C calling convention with proper stack frame setup (LINK/UNLK).

5. The code uses both hardware FPU instructions (when available) and software emulation for complex operations.

6. The math functions use polynomial approximations with range reduction for accuracy across the full domain.

; === CHUNK 15: 0x8A800-0x8B400 ===

## CORRECTIONS AND REFINEMENTS:

### 1. `0x8a800` - `_dscale` (scale double by power of 10)
**Entry:** 0x8a800
**Purpose:** Scales a floating-point number by a power of 10. This is a helper function for string-to-float conversion that handles decimal scaling. It multiplies/divides by powers of 10 based on an exponent value. The function appears to handle both positive and negative scaling exponents.
- fp@(8), fp@(12): double value to scale  (PS CTM operator)
- fp@(16): exponent adjustment (signed integer)  stack frame parameter
- fp@(20): flag (bit 0 indicates rounding?)  stack frame parameter
**Return:** Scaled double in D0/D1.
**Key calls:** 0x89968 (fp compare), 0xb68c (fp multiply?), 0x899f8 (load constant), 0x89920 (fp add), 0x89a58 (fp multiply), 0x89aa0 (fp divide), 0x89a28 (fp normalize)
**Callers:** Likely called from string-to-float conversion routines.
### 2. `0x8aaac` - `_dpack` (pack double from decimal components)
**Entry:** 0x8aaac
**Purpose:** Packs a floating-point number from decimal string components into IEEE 754 double format. Takes sign, exponent, mantissa digits, and string buffer. Handles normalization, rounding, and special cases (zero, denormalized, overflow). Limits digit count to 17 (max precision for double).
- fp@(8): pointer to digit buffer (ASCII digits)  stack frame parameter
- fp@(12): number of digits  stack frame parameter
- fp@(16): decimal exponent adjustment  stack frame parameter
- fp@(20): sign (0=positive, 1=negative)  stack frame parameter
**Return:** Packed double in D0/D1.
**Key calls:** 0xb8de (convert string to integer), 0xbaa0 (normalize), 0xbaf8 (multiply)
**Callers:** 0x8aca4 (_atod)
### 3. `0x8aca4` - `_atod` (ASCII to double)
**Entry:** 0x8aca4  
**Purpose:** Main string-to-float parser. Parses optional sign, integer part, decimal point, fractional part, and optional exponent (E/e). Accumulates up to 100 digits into buffer and calls `_dpack` to assemble the double. Handles leading/trailing zeros.
**Arguments:** String pointer in fp@(8) (passed by reference, updated).
**Return:** Double in D0/D1.
**Key calls:** 0x8aaac (_dpack)
**Callers:** Likely called from `strtod()` implementation. (C runtime string-to-double)
**Note:** The function has a 124-byte digit buffer on stack (fp@(-124)).

### 4. `0x8ae34` - `_dexp` (get decimal exponent from packed format)
**Entry:** 0x8ae34
**Purpose:** Extracts and decodes the exponent from a packed floating-point number in 10-byte extended format (not IEEE double). The format appears to be: word[0]: exponent+sign bits, long[2]: mantissa high, long[6]: mantissa low. Returns exponent as signed integer.
**Arguments:** Pointer to packed float in fp@(8).
**Return:** Exponent in D0 (signed).
**Callers:** 0x8aeb4 (_dtoa)
**Note:** This is NOT extracting exponent from IEEE double - it's from an internal packed format used during conversion.

### 5. `0x8ae6e` - `_bmove` (backward memory move)
**Entry:** 0x8ae6e
**Purpose:** Copies memory backward (high to low addresses). Used for shifting decimal strings during formatting. Fills with '0' if destination extends beyond source. Similar to memmove but backward.
- fp@(8): destination pointer (A5)  stack frame parameter
- fp@(12): source offset (D7)  struct field
- fp@(16): count (D6)  stack frame parameter
**Callers:** 0x8aeb4 (_dtoa)

### 6. `0x8aeb4` - `_dtoa` (double to ASCII)
**Entry:** 0x8aeb4
**Purpose:** Main float-to-string conversion routine. Converts IEEE double to decimal string with specified precision. Handles special cases (zero, denormalized, infinity). Uses internal packed format (10 bytes) and calls `_dexp` for exponent extraction. Implements rounding and digit generation.
- fp@(8), fp@(12): double value  stack frame parameter
- fp@(16): precision (max digits)  stack frame parameter
- fp@(20): pointer to store exponent  stack frame parameter
- fp@(24): pointer to store sign (0=positive, 1=negative)  stack frame parameter
- fp@(28): flag (0=exponential format, 1=fixed format)  stack frame parameter
**Return:** Pointer to string buffer (0x020172c8) in D0.
**Key calls:** 0x8ae34 (_dexp), 0xbaa0 (normalize), 0xbaf8 (multiply), 0xbc24 (divide?), 0xb7e8 (compare?), 0xb80e (subtract?), 0x8ae6e (_bmove)
**Callers:** 0x8b1be, 0x8b1e6
**Note:** Returns pointer to static buffer at 0x020172c8.

### 7. `0x8b1be` - `_ecvt` (convert double to string with exponent)
**Entry:** 0x8b1be
**Purpose:** Standard C library `ecvt()` function. Converts double to string with specified digits, returns exponent and sign. Always uses exponential format (flag=1).
- fp@(8), fp@(12): double value  stack frame parameter
- fp@(16): number of digits  stack frame parameter
- fp@(20): pointer to decimal point position (exponent)  stack frame parameter
- fp@(24): pointer to sign (0=positive, 1=negative)  stack frame parameter
**Return:** Pointer to string buffer.
**Key calls:** 0x8aeb4 (_dtoa)
**Callers:** Standard C library callers.

### 8. `0x8b1e6` - `_fcvt` (convert double to string with fixed format)
**Entry:** 0x8b1e6
**Purpose:** Standard C library `fcvt()` function. Converts double to string with specified digits after decimal point. Uses fixed format (flag=0) and handles rounding.
- fp@(8), fp@(12): double value  stack frame parameter
- fp@(16): number of digits after decimal  stack frame parameter
- fp@(20): pointer to decimal point position  stack frame parameter
- fp@(24): pointer to sign (0=positive, 1=negative)  stack frame parameter
**Return:** Pointer to string buffer.
**Key calls:** 0x8aeb4 (_dtoa)
**Callers:** Standard C library callers.

### 9. `0x8b316` - `_frexp` (extract mantissa and exponent)
**Entry:** 0x8b316
**Purpose:** Standard C library `frexp()` function. Splits a floating-point number into normalized fraction and exponent such that: value = fraction × 2^exponent, with 0.5 ≤ |fraction| < 1.
- fp@(8), fp@(12): double value  stack frame parameter
- fp@(16): pointer to store exponent  stack frame parameter
**Return:** Fraction in D0/D1.
**Key calls:** 0xc896 (extract components), 0xc8e6 (normalize)
**Callers:** Standard C library callers.

### 10. `0x8b366` - `_abs` (absolute value of long)
**Entry:** 0x8b366
**Purpose:** Returns absolute value of a 32-bit integer. Handles edge case of -2147483648.
**Arguments:** D1 = value
**Return:** Absolute value in D0.
**Callers:** Various math functions.

### 11. `0x8b380` - `_div` (signed 32-bit division)
**Entry:** 0x8b380
**Purpose:** Signed 32-bit integer division. Handles sign correction and calls unsigned division routine.
**Arguments:** D0 = dividend, D1 = divisor
**Return:** Quotient in D0.
**Key calls:** 0x8b39a (unsigned division)
**Callers:** Various math functions.

### 12. `0x8b39a` - `_udiv` (unsigned 32-bit division)
**Entry:** 0x8b39a
**Purpose:** Unsigned 32-bit integer division. Implements long division algorithm with optimizations for small divisors.
**Arguments:** D0 = dividend, D1 = divisor
**Return:** Quotient in D0.
**Callers:** 0x8b380 (_div)

### 1. `0x8aa3c-0x8aaa8` - Floating-point constants table
**Address:** 0x8aa3c
**Format:** Array of IEEE double constants used by `_dscale`:
- 0x8aa3c: 0x40dfff00 0x00000000 (approx 3.0e4)
- 0x8aa44: 0x3fd00000 0x00000000 (0.25)
- 0x8aa4c: 0x40100000 0x00000000 (4.0)
- 0x8aa54: 0x3ff00000 0x00000000 (1.0)
- 0x8aa5c: 0x3fe45f30 0x6dc9c883 (0.6375?)
- 0x8aa64: 0x4169e64b 0x1f521d58 (1.0e7?)
- 0x8aa6c: 0xc152db0f 0x06753134 (negative constant)
- 0x8aa74: 0x411adc9c 0x36d28a98 (1.0e6?)
- 0x8aa7c: 0xc0cb0ba2 0xe1463542 (negative constant)
- 0x8aa84: 0x40623f00 0xbe243f71 (150.0?)
- 0x8aa8c: 0x41607cf9 0xd4e4bdcd (1.0e7?)
- 0x8aa94: 0x4118e9cc 0xe6a3d405 (1.0e6?)
- 0x8aa9c: 0x40c27b8c 0x4d0e21da (1.0e4?)
- 0x8aaa4: 0x406094e9 0x65b3fc28 (150.0?)

### 2. `0x8b28a-0x8b314` - Powers of 10 table
**Address:** 0x8b28a
**Format:** Array of 17 double values representing powers of 10 from 10^0 to 10^16:
- 0x8b28a: 0x3ff00000 0x00000000 (1.0 = 10^0)
- 0x8b292: 0x40240000 0x00000000 (10.0 = 10^1)
- 0x8b29a: 0x40590000 0x00000000 (100.0 = 10^2)
- 0x8b2a2: 0x408f4000 0x00000000 (1000.0 = 10^3)
- 0x8b2aa: 0x40c38800 0x00000000 (10000.0 = 10^4)
- 0x8b2b2: 0x40f86a00 0x00000000 (100000.0 = 10^5)
- 0x8b2ba: 0x412e8480 0x00000000 (1000000.0 = 10^6)
- 0x8b2c2: 0x416312d0 0x00000000 (10000000.0 = 10^7)
- 0x8b2ca: 0x4197d784 0x00000000 (100000000.0 = 10^8)
- 0x8b2d2: 0x41cdcd65 0x00000000 (1000000000.0 = 10^9)
- 0x8b2da: 0x4202a05f 0x20000000 (10000000000.0 = 10^10)
- 0x8b2e2: 0x42374876 0xe8000000 (100000000000.0 = 10^11)
- 0x8b2ea: 0x426d1a94 0xa2000000 (1000000000000.0 = 10^12)
- 0x8b2f2: 0x42a2309c 0xe5400000 (10000000000000.0 = 10^13)
- 0x8b2fa: 0x42d6bcc4 0x1e900000 (100000000000000.0 = 10^14)
- 0x8b302: 0x430c6bf5 0x26340000 (1000000000000000.0 = 10^15)
- 0x8b30a: 0x4341c379 0x37e08000 (10000000000000000.0 = 10^16)

## KEY CORRECTIONS FROM PRIOR ANALYSIS:

1. **0xb68c is NOT "fp multiply?"** - It's a function that multiplies by powers of 10 (likely used in scaling).
2. **0xb8de is NOT "convert string to integer"** - It converts a digit buffer to binary integer for `_dpack`.
3. **`_dexp` works on internal packed format** (10 bytes), not IEEE double.
4. **`_dtoa` returns pointer to static buffer** at 0x020172c8, not a newly allocated string.
5. **The data at 0x8b28a is powers of 10 table**, not random data.
6. **Functions 0x8b1be and 0x8b1e6 are standard C library `ecvt()` and `fcvt()`**, not custom functions.

- `0x8b316` - `_frexp` (standard C library function)
- `0x8b366` - `_abs` (absolute value)
- `0x8b380` - `_div` (signed division)
- `0x8b39a` - `_udiv` (unsigned division)

These are all part of the C runtime library (Sun CC implementation).

; === CHUNK 16: 0x8B400-0x8C000 ===

### 1. `0x8b400` - `unsigned_long_divide_normalized`
**Entry:** 0x8b400  
**Purpose:** Performs unsigned 64-bit by 32-bit division using normalization. The function normalizes the divisor to the range [0x8000, 0xFFFF] by counting leading zeros, performs the division using 16-bit operations, and then denormalizes the result. It handles remainder correction and returns the quotient in D0:D1.  
**Arguments:** D0:D1 = dividend (64-bit), D1 = divisor (32-bit)  
**Return:** D0:D1 = quotient (64-bit)  
**Call targets:** None (leaf function)  
**Called from:** Unknown (likely from floating-point library or math routines)  
**Algorithm:** Saves registers D2-D5/A0, normalizes divisor by counting leading zeros, performs division using 16-bit DIVU instructions, handles remainder correction with a final adjustment if remainder ≥ divisor.

### 2. `0x8b44c` - `count_leading_zeros_32`
**Entry:** 0x8b44c  
**Purpose:** Counts leading zeros in a 32-bit value using a lookup table approach. Returns 0-32 based on the input value. Used by division routines for normalization.  
**Arguments:** D1 = 32-bit value  
**Return:** D4 = count of leading zeros  
**Called from:** Division routines (0x8b400, 0x8b500)  
**Algorithm:** Checks high word first (adds 16 if zero), then uses lookup table at 0x8b6b8 for byte-level counting. The table contains precomputed leading zero counts for each byte value (0-255).

### 3. `0x8b470` - DATA: Copyright string
**Address:** 0x8b470-0x8b49e  
**Format:** ASCII string: "Copyright (c) 1983 Sun Microsystems"  
### 4. `0x8b4a0` - `signed_long_divide`
**Entry:** 0x8b4a0  
**Purpose:** Performs signed 64-bit by 32-bit division with sign handling. Converts negative inputs to positive, calls unsigned division, then restores sign to the quotient.  
**Arguments:** D0:D1 = dividend (64-bit), D1 = divisor (32-bit)  
**Return:** D0:D1 = quotient (64-bit)  
**Call targets:** 0x8b4ca (unsigned division)  
**Algorithm:** Checks signs of dividend and divisor, negates if necessary, calls unsigned division at 0x8b4ca, then negates result if signs differ.

### 5. `0x8b4ca` - `unsigned_long_divide_simple`
**Entry:** 0x8b4ca  
**Purpose:** Simple unsigned 64-bit by 32-bit division for cases where divisor fits in 16 bits or dividend high word is small. Handles special cases and calls hardware DIVU when possible.  
**Arguments:** D0:D1 = dividend, D1 = divisor  
**Return:** D0:D1 = quotient  
**Called from:** 0x8b4a0  
**Algorithm:** Checks if divisor high word is zero, handles different cases based on dividend high word, uses hardware DIVU instruction when appropriate (when dividend high word < divisor).

### 6. `0x8b500` - `unsigned_long_divide_with_remainder`
**Entry:** 0x8b500  
**Purpose:** Unsigned 64-bit by 32-bit division that returns both quotient and remainder. Similar to 0x8b400 but with different register usage and optimized for remainder calculation.  
**Arguments:** D0:D1 = dividend, D1 = divisor  
**Return:** D0 = remainder, D1 = quotient  
**Call targets:** 0x8b44c (count_leading_zeros_32)  
**Algorithm:** Similar to 0x8b400 but optimized for remainder calculation, handles power-of-two divisors specially using bit masking.

### 7. `0x8b592` - DATA: Another copyright string
**Address:** 0x8b592-0x8b5c0  
**Format:** ASCII string: "Copyright (c) 1983 Sun Microsystems"  
**Note:** Duplicate copyright string, likely padding or from different compilation unit.

### 8. `0x8b5c4` - `unsigned_long_multiply`
**Entry:** 0x8b5c4  
**Purpose:** Performs unsigned 64-bit by 32-bit multiplication using 16-bit partial products. Handles simple cases where both operands fit in 16 bits.  
**Arguments:** D0:D1 = multiplicand (64-bit), D1 = multiplier (32-bit)  
**Return:** D0:D1 = product (64-bit)  
**Algorithm:** Checks for simple cases (16-bit operands using MULU), then uses 4 partial products with MULU instructions for full 64×32 multiplication.

### 9. `0x8b5e2` - `signed_long_multiply`
**Entry:** 0x8b5e2  
**Purpose:** Performs signed 64-bit by 32-bit multiplication with sign handling. Converts negative inputs to positive, calls unsigned multiplication, then restores sign.  
**Arguments:** D0:D1 = multiplicand (64-bit), D1 = multiplier (32-bit)  
**Return:** D0:D1 = product (64-bit)  
**Call targets:** 0x8b602 (unsigned multiplication core)  
**Algorithm:** Checks signs, negates if necessary, calls unsigned multiplication core at 0x8b602, then negates result if signs differ.

### 10. `0x8b602` - `unsigned_long_multiply_core`
**Entry:** 0x8b602  
**Purpose:** Core unsigned 64-bit by 32-bit multiplication routine using 16-bit partial products. Called by both unsigned and signed multiplication functions.  
**Arguments:** D0:D1 = multiplicand (64-bit), D1 = multiplier (32-bit)  
**Return:** D0:D1 = product (64-bit)  
**Called from:** 0x8b5c4, 0x8b5e2  
**Algorithm:** Performs 4 partial products: low×low, low×high, high×low, high×high, accumulating results with proper shifting.

### 11. `0x8b65a` - DATA: Another copyright string
**Address:** 0x8b65a-0x8b68a  
**Format:** ASCII string: "Copyright (c) 1983 Sun Microsystems"  
**Note:** Third copyright string, likely more padding.

### 12. `0x8b68c` - `double_negate`
**Entry:** 0x8b68c  
**Purpose:** Negates a double-precision floating-point number by toggling the sign bit. Uses the software FPU library.  
**Arguments:** FP@(8) = double value to negate, FP@(16) = pointer to store result  
**Call targets:** 0x899e0 (software FPU operation), 0x89aa0 (software FPU operation)  
**Algorithm:** Loads the double value, calls software FPU to manipulate it, toggles the sign bit (bit 31), stores result.

### 13. `0x8b6b8` - DATA: Leading zero count lookup table
**Address:** 0x8b6b8-0x8b7b6  
**Format:** Byte table containing leading zero counts for values 0-255  
**Note:** Used by `count_leading_zeros_32` at 0x8b44c. Table values: 0x01, 0x01, 0x02, 0x02, 0x02, 0x02, 0x03, 0x03, ... up to 0x07.

### 14. `0x8b7b8` - DATA: Another copyright string
**Address:** 0x8b7b8-0x8b7e4  
**Format:** ASCII string: "Copyright (c) 1983 Sun Microsystems"  
**Note:** Fourth copyright string.

### 15. `0x8b7e8` - `compare_doubles`
**Entry:** 0x8b7e8  
**Purpose:** Compares two double-precision floating-point numbers, returning -1, 0, or 1.  
**Arguments:** FP@(8) = pointer to first double, FP@(12) = pointer to second double  
**Return:** D0 = -1 (first < second), 0 (equal), 1 (first > second)  
**Algorithm:** Compares the two 64-bit values as raw IEEE doubles (including sign handling).

### 16. `0x8b80e` - `unsigned_long_to_decimal_string`
**Entry:** 0x8b80e  
**Purpose:** Converts an unsigned 64-bit integer to a decimal ASCII string. Uses repeated division by 10.  
**Arguments:** FP@(8) = pointer to 64-bit value, FP@(12) = pointer to output buffer  
**Return:** D0 = pointer to end of string (null terminator)  
**Called from:** Unknown (likely printf/sprintf family)  
**Algorithm:** Repeatedly divides the 64-bit value by 10, storing remainders as ASCII digits, reverses digits for correct order.

### 17. `0x8b8de` - `decimal_string_to_unsigned_long`
**Entry:** 0x8b8de  
**Purpose:** Converts a decimal ASCII string to an unsigned 64-bit integer. Handles up to 9 digits at a time efficiently.  
**Arguments:** FP@(8) = pointer to input string, FP@(12) = max digits to process, FP@(16) = pointer to store 64-bit result  
**Called from:** Unknown (likely scanf/atoi family)  
**Algorithm:** Processes digits in groups of up to 9 (fits in 32-bit), uses multiply-by-10 via shift-and-add, accumulates result.

### 18. `0x8b964` - DATA: Another copyright string
**Address:** 0x8b964-0x8b98c  
**Format:** ASCII string: "Copyright (c) 1983 Sun Microsystems"  
**Note:** Fifth copyright string.

### 19. `0x8b990` - `double_multiply`
**Entry:** 0x8b990  
**Purpose:** Multiplies two double-precision floating-point numbers using software FPU emulation. Handles special cases (NaN, infinity, zero).  
**Arguments:** D0:D1 = first double, D2:D3 = second double  
**Return:** D0:D1 = product  
**Algorithm:** Unpacks exponents and mantissas, handles sign combination, normalizes inputs, performs 64-bit multiplication using the integer multiply routines, normalizes result, handles overflow/underflow.

### 20. `0x8ba9e` - `normalize_double`
**Entry:** 0x8ba9e  
**Purpose:** Normalizes a denormalized double-precision floating-point number by shifting mantissa and adjusting exponent.  
**Arguments:** FP@(8) = pointer to denormalized double  
**Called from:** Unknown (likely FPU emulation routines)  
**Algorithm:** Checks for denormalized numbers (exponent=0, mantissa≠0), shifts mantissa left while decrementing exponent until normalized.

### 21. `0x8baf8` - `double_add`
**Entry:** 0x8baf8  
**Purpose:** Adds two double-precision floating-point numbers using software FPU emulation.  
**Arguments:** FP@(8) = pointer to first double, FP@(12) = pointer to second double, FP@(16) = pointer to store result  
**Algorithm:** Aligns exponents by shifting mantissas, adds/subtracts mantissas based on signs, normalizes result, handles overflow/underflow.

### 22. `0x8bc24` - `shift_right_double`
**Entry:** 0x8bc24  
**Purpose:** Shifts a double-precision floating-point number right by a specified number of bits (up to 62). Used for exponent alignment in add/subtract operations.  
**Arguments:** FP@(8) = pointer to double to shift  
**Called from:** Unknown (likely within double_add/double_subtract)  
**Algorithm:** Shifts 64-bit mantissa right with proper rounding (round-to-nearest, ties to even).

### 23. `0x8bc7c` - DATA: Another copyright string
**Address:** 0x8bc7c-0x8bca8  
**Format:** ASCII string: "Copyright (c) 1983 Sun Microsystems"  
**Note:** Sixth copyright string.

### 24. `0x8bcac` - DATA: Powers of 10 table for double conversion
**Address:** 0x8bcac-0x8be46  
**Format:** Table of double-precision values for 10^0 to 10^37  
**Note:** Used for floating-point to/from string conversion. Each entry is 8 bytes (double).

### 25. `0x8be48` - DATA: Negative powers of 10 table
**Address:** 0x8be48-0x8bfe6  
**Format:** Table of double-precision values for 10^-1 to 10^-37  
**Note:** Used for floating-point to/from string conversion. Each entry is 8 bytes (double).

### 26. `0x8bfe8` - `round_double`
**Entry:** 0x8bfe8  
**Purpose:** Rounds a double-precision floating-point number according to the current rounding mode.  
**Arguments:** D0:D1 = double value to round  
**Return:** D0:D1 = rounded double  
**Called from:** Unknown (likely within FPU emulation)  
**Algorithm:** Checks rounding mode, adjusts mantissa and exponent accordingly, handles overflow to infinity.

2. The function at 0x8b68c is `double_negate`, not a generic FPU operation.
3. The table at 0x8b6b8 is a leading zero count lookup table, not random data.
4. The functions at 0x8b80e and 0x8b8de are conversion routines between 64-bit integers and decimal strings.
5. The large tables at 0x8bcac and 0x8be48 are powers of 10 for floating-point conversion.
This region contains the Sun Microsystems C runtime library's 64-bit integer arithmetic routines (division, multiplication) and double-precision floating-point emulation routines. The code is characterized by:
- Multiple copyright strings from Sun Microsystems (1983)
- Software FPU emulation for systems without hardware FPU
- 64-bit integer operations using 32-bit hardware instructions
- Conversion routines between binary and decimal representations
- [C runtime] Tables for efficient computation (leading zeros, powers of 10) — Sun Microsystems software FPU support

; === CHUNK 17: 0x8C000-0x8CC00 ===

1. **0x8C000-0x8C062**: These are **floating-point normalization helpers**, not general shift routines.
2. **0x8C136**: This is **floating-point mantissa normalization** (correctly identified).
3. **0x8C2BE-0x8C2EE**: This is **double-precision unpacking** (correct).
4. **0x8C2F0-0x8C3C8**: This is **double-precision comparison** (correct).
5. **0x8C3CA-0x8C4E2**: This is **double-precision addition/subtraction** (correct).
6. **0x8C4EC-0x8C512**: This is **double-precision normalization** (correct).
7. **0x8C514-0x8C66A**: This is **single-precision addition/subtraction** (correct).
8. **0x8C6F6-0x8C798**: This is **single-precision to double-precision conversion** (correct).
9. **0x8C79A-0x8C7E6**: This is **single-precision unpacking** (correct).
10. **0x8C7E8-0x8C894**: This is **single-precision packing** (correct).
11. **0x8C896-0x8C8E4**: This is **double-precision unpacking** (correct).
12. **0x8C8E6-0x8C9C0**: This is **double-precision packing** (correct).
13. **0x8C9C2-0x8CA06**: This is **single-precision classification** (correct).
14. **0x8CA08-0x8CA2A**: These are **exponent extraction** routines (correct).
15. **0x8CA2C-0x8CA4A**: These are **global variable accessors** (correct).
16. **0x8CA4C-0x8CB84**: These are **floating-point to integer conversion** routines (correct).

#### **1. 0x8C000 - `__fp_normalize_left`**
**Entry:** 0x8C000  
**Purpose:** Normalize floating-point mantissa by shifting left with overflow detection  
**Algorithm:** Shifts D0 left by D1 bits (0-31), checks for overflow using `bvss` (branch on overflow set)  
**Arguments:** D0 = mantissa, D1 = shift count (from stack at SP@(4))  
**Returns:** D0 = normalized mantissa, CCR overflow flag set if overflow  
**Hardware:** Uses 68020 `bvss` instruction for overflow detection  
**Call targets:** 0x8C064 (overflow handler) on overflow  
**Called by:** Floating-point normalization routines

#### **2. 0x8C022 - `__fp_normalize_right`**
**Entry:** 0x8C022  
**Purpose:** Normalize floating-point mantissa by shifting right with rounding  
**Algorithm:** Shifts D0 right by D1 bits, rounds toward nearest even (IEEE 754 standard)  
**Arguments:** D0 = mantissa, D1 = shift count (from stack at SP@(4))  
**Returns:** D0 = normalized and rounded mantissa  
**Key logic:** 0x8C038 (rounding up), 0x8C044 (no rounding needed)  
**Call targets:** 0x8C064 (overflow handler) on overflow

#### **3. 0x8C064 - `__fp_overflow_handler`**
**Entry:** 0x8C064  
**Purpose:** Handle overflow from normalization operations  
**Behavior:** Returns extreme values based on sign: 0x7FFFFFFF for positive, 0x80000000 for negative  
**Arguments:** D0 = original value, D1 = sign indicator (bit 31 set for negative)  
**Returns:** D0 = saturated value  
**Data references:** 0x8C076 (0x7FFFFFFF), 0x8C07A (0x80000000)  
**Called by:** 0x8C012, 0x8C054, 0x8C0BE, 0x8C0FC, 0x8C100

#### **4. 0x8C07C - `__divsi3`**
**Entry:** 0x8C07C  
**Purpose:** Signed 32-bit integer division (Sun CC runtime library)  
**Algorithm:** Takes absolute values, uses hardware DIVS, restores sign  
**Arguments:** D0 = dividend (from stack at SP@(8)), D1 = divisor (from stack at SP@(12))  
**Returns:** D0 = quotient  
**Registers used:** D2-D3 preserved  
**Call targets:** 0x8C0BE (division by zero/overflow handler)  
**Note:** Standard Sun CC runtime function for 68000/68020

#### **5. 0x8C0CA - `__modsi3`**
**Entry:** 0x8C0CA  
**Purpose:** Signed 32-bit integer remainder (Sun CC runtime library)  
**Algorithm:** Similar to division but returns remainder instead of quotient  
**Arguments:** D0 = dividend (from stack at SP@(8)), D1 = divisor (from stack at SP@(12))  
**Returns:** D0 = remainder  
**Registers used:** D2-D3 preserved  
**Note:** Standard Sun CC runtime function

#### **6. 0x8C0E0 - `__udivsi3`**
**Entry:** 0x8C0E0  
**Purpose:** Unsigned 32-bit integer division  
**Algorithm:** Uses hardware DIVUL instruction for unsigned division  
**Arguments:** D0 = dividend (from stack at SP@(4)), D1 = divisor (from stack at SP@(8))  
**Returns:** D0 = quotient  
**Call targets:** 0x8C064 (overflow handler) on division by zero or overflow

#### **7. 0x8C106 - `__umodsi3`**
**Entry:** 0x8C106  
**Purpose:** Unsigned 32-bit integer remainder  
**Algorithm:** Uses hardware DIVUL instruction, returns remainder  
**Arguments:** D0 = dividend (from stack at SP@(4)), D1 = divisor (from stack at SP@(8))  
**Returns:** D0 = remainder  
**Call targets:** Returns 0x7FFFFFFF on error (0x8C130)

#### **8. 0x8C136 - `__fp_normalize_mantissa`**
**Entry:** 0x8C136  
**Purpose:** Normalize floating-point mantissa using iterative algorithm  
**Algorithm:** 31 iterations of shift-subtract-restore to find leading 1 bit  
**Arguments:** D3 = mantissa value (from stack at SP@(20))  
**Returns:** D0 = normalized mantissa, D2 = exponent adjustment count  
**Registers used:** D2-D5 preserved  
**Algorithm detail:** Uses double-word arithmetic (D2:D3) for precision

#### **9. 0x8C170 - `__extendsfdf2` (float to double)**
**Entry:** 0x8C170  
**Purpose:** Convert single-precision float to double-precision  
**Algorithm:** Unpacks float, adjusts exponent bias (127 to 1023), pads mantissa  
**Arguments:** D0 = single-precision float (from stack at SP@(4))  
**Returns:** D0:D1 = double-precision result  
**Call targets:** 0x99F8 (likely `__fp_unpack_single`)  
**Note:** Standard C runtime function name for float to double conversion

#### **10. 0x8C186 - `__truncdfsf2` (double to float)**
**Entry:** 0x8C186  
**Purpose:** Convert double-precision to single-precision with truncation  
**Algorithm:** Unpacks double, adjusts exponent bias (1023 to 127), rounds/truncates mantissa  
**Arguments:** D0 = double-precision high word (from stack at SP@(4))  
**Returns:** D0 = single-precision result  
**Call targets:** 0x99F8 (likely `__fp_unpack_double`)  
**Note:** Standard C runtime function name

#### **11. 0x8C19C - `__adddf3` (double addition)**
**Entry:** 0x8C19C  
**Purpose:** Double-precision floating-point addition  
**Algorithm:** Unpacks operands, aligns exponents, adds mantissas, normalizes result  
**Arguments:** D0:D1 = first operand, D2:D3 = second operand (from stack)  
**Returns:** D0:D1 = sum  
**Call targets:** 0x9A28 (likely `__fp_add_sub_double`)  
**Note:** Standard C runtime function name

#### **12. 0x8C1C0 - `__subdf3` (double subtraction)**
**Entry:** 0x8C1C0  
**Purpose:** Double-precision floating-point subtraction  
**Algorithm:** Similar to addition but subtracts mantissas  
**Arguments:** D0:D1 = first operand, D2:D3 = second operand (from stack)  
**Returns:** D0:D1 = difference  
**Call targets:** 0x9A28 (likely `__fp_add_sub_double`)  
**Note:** Standard C runtime function name

#### **13. 0x8C1E4 - `__addsf3` (float addition)**
**Entry:** 0x8C1E4  
**Purpose:** Single-precision floating-point addition  
**Algorithm:** Unpacks operands, aligns exponents, adds mantissas, normalizes result  
**Arguments:** D0 = first operand, D1 = second operand (from stack)  
**Returns:** D0 = sum  
**Call targets:** 0x9A10 (likely `__fp_add_sub_single`)  
**Note:** Standard C runtime function name

#### **14. 0x8C1FE - `__subsf3` (float subtraction)**
**Entry:** 0x8C1FE  
**Purpose:** Single-precision floating-point subtraction  
**Algorithm:** Similar to float addition but subtracts mantissas  
**Arguments:** D0 = first operand, D1 = second operand (from stack)  
**Returns:** D0 = difference  
**Call targets:** 0x9A10 (likely `__fp_add_sub_single`)  
**Note:** Standard C runtime function name

#### **15. 0x8C218 - `__mulsf3` (float multiplication)**
**Entry:** 0x8C218  
**Purpose:** Single-precision floating-point multiplication  
**Algorithm:** Unpacks operands, multiplies mantissas, adds exponents, normalizes  
**Arguments:** D0 = first operand (from memory at A0), D1 = second operand (from stack)  
**Returns:** D0 = product  
**Call targets:** 0x9A40 (likely `__fp_mul_single`)  
**Note:** Standard C runtime function name

#### **16. 0x8C238 - `__divsf3` (float division)**
**Entry:** 0x8C238  
**Purpose:** Single-precision floating-point division  
**Algorithm:** Unpacks operands, divides mantissas, subtracts exponents, normalizes  
**Arguments:** D0 = dividend (from memory at A0), D1 = divisor (from stack)  
**Returns:** D0 = quotient  
**Call targets:** 0x9A40 (likely `__fp_div_single`)  
**Note:** Standard C runtime function name

#### **17. 0x8C258 - `__fp_invalid_operation`**
**Entry:** 0x8C258  
**Purpose:** Handle invalid floating-point operations (NaN, infinity)  
**Algorithm:** Returns appropriate NaN value based on sign bit  
**Arguments:** D1 = sign/exponent field  
**Returns:** D0 = NaN value (0x7FFFFFFF or 0xFFFFFFFF)  
**Called by:** Various floating-point routines on error

#### **18. 0x8C264 - `__unorddf2` (unordered double comparison)**
**Entry:** 0x8C264  
**Purpose:** Check if two doubles are unordered (either is NaN)  
**Algorithm:** Tests for NaN values in double-precision format  
**Arguments:** D0:D1 = first double, D2:D3 = second double (from stack via FP)  
**Returns:** D0 = 1 if unordered, 0 if ordered  
**Note:** Standard C runtime function for unordered comparison

#### **19. 0x8C28C - `__unordsf2` (unordered float comparison)**
**Entry:** 0x8C28C  
**Purpose:** Check if two floats are unordered (either is NaN)  
**Algorithm:** Tests for NaN values in single-precision format  
**Arguments:** D0 = first float, D1 = second float (from stack via FP)  
**Returns:** D0 = 1 if unordered, 0 if ordered  
**Note:** Standard C runtime function

#### **20. 0x8C2BE - `__fp_unpack_double`**
**Entry:** 0x8C2BE  
**Purpose:** Unpack double-precision floating-point number into components  
**Algorithm:** Extracts sign, exponent, and mantissa from IEEE 754 double format  
**Arguments:** D0:D1 = double-precision value  
**Returns:** D2:D3 = mantissa, D6 = exponent, D7 = sign/type flags  
**Registers used:** D4-D7  
**Called by:** Double-precision arithmetic routines

#### **21. 0x8C2F0 - `__cmpdf2` (double comparison)**
**Entry:** 0x8C2F0  
**Purpose:** Compare two double-precision floating-point numbers  
**Algorithm:** Handles special cases (NaN, infinity, zero), compares mantissas  
**Arguments:** D0:D1 = first double, A0 points to second double  
**Returns:** CCR flags set for less, equal, greater, or unordered  
**Call targets:** 0x8C3AA (NaN check), 0x8C3B2 (infinity check)  
**Note:** Sets CCR directly, no value in D0

#### **22. 0x8C3CA - `__fp_add_sub_double`**
**Entry:** 0x8C3CA  
**Purpose:** Core double-precision addition/subtraction implementation  
**Algorithm:** Unpacks operands, aligns exponents, adds/subtracts mantissas, normalizes  
**Arguments:** D0:D1 = first operand, A0 points to second operand  
**Returns:** D0:D1 = result  
**Registers used:** D2-D7 preserved  
**Call targets:** 0x8C2C0 (unpack), 0x8C916 (normalize), 0x8C940 (pack), 0x8C982 (special case)

#### **23. 0x8C4EC - `__fp_normalize_double`**
**Entry:** 0x8C4EC  
**Purpose:** Normalize double-precision mantissa  
**Algorithm:** Shifts mantissa left until leading 1 is in bit 20 (hidden bit position)  
**Arguments:** D0:D1 = mantissa, D4 = exponent adjustment mask  
**Returns:** D0:D1 = normalized mantissa, D7 = exponent adjustment  
**Called by:** Double-precision arithmetic routines

#### **24. 0x8C514 - `__fp_add_sub_single`**
**Entry:** 0x8C514  
**Purpose:** Core single-precision addition/subtraction implementation  
**Algorithm:** Unpacks operands, aligns exponents, adds/subtracts mantissas, normalizes  
**Arguments:** D0 = first operand, D1 = second operand  
**Returns:** D0 = result  
**Registers used:** D2-D7 preserved  
**Note:** Handles both addition and subtraction based on sign bits

#### **25. 0x8C66C - `__cmpsf2` (float comparison)**
**Entry:** 0x8C66C  
**Purpose:** Compare two single-precision floating-point numbers  
**Algorithm:** Handles special cases (NaN, infinity, zero), compares mantissas  
**Arguments:** D0 = first float, D1 = second float  
**Returns:** CCR flags set for less, equal, greater, or unordered  
**Note:** Similar to double comparison but for single precision

#### **26. 0x8C6F6 - `__fp_sp_to_dp`**
**Entry:** 0x8C6F6  
**Purpose:** Convert single-precision to double-precision (alternative implementation)  
**Algorithm:** Direct conversion without full unpacking for common cases  
**Arguments:** D0 = single-precision float  
**Returns:** D0:D1 = double-precision result  
**Call targets:** 0x8C896 (unpack), 0x8C7E8 (pack)  
**Note:** Optimized path for normal numbers

#### **27. 0x8C79A - `__fp_unpack_single`**
**Entry:** 0x8C79A  
**Purpose:** Unpack single-precision floating-point number into components  
**Algorithm:** Extracts sign, exponent, and mantissa from IEEE 754 single format  
**Arguments:** D0 = single-precision value  
**Returns:** D0:D1 = mantissa, D2 = exponent, D3 = sign/type flags  
**Called by:** Single-precision arithmetic routines

#### **28. 0x8C7E8 - `__fp_pack_single`**
**Entry:** 0x8C7E8  
**Purpose:** Pack components into single-precision floating-point format  
**Algorithm:** Normalizes mantissa, applies exponent bias, rounds, packs into IEEE 754 format  
**Arguments:** D0:D1 = mantissa, D2 = exponent, D3 = sign/type flags  
**Returns:** D0 = single-precision float  
**Call targets:** 0x8C832 (rounding helper)

#### **29. 0x8C896 - `__fp_unpack_double_alt`**
**Entry:** 0x8C896  
**Purpose:** Alternative double-precision unpacking routine  
**Algorithm:** Similar to 0x8C2BE but with different register usage  
**Arguments:** D0:D1 = double-precision value  
**Returns:** D0:D1 = mantissa, D2 = exponent, D3 = sign/type flags  
**Registers used:** D2-D4

#### **30. 0x8C8E6 - `__fp_pack_double`**
**Entry:** 0x8C8E6  
**Purpose:** Pack components into double-precision floating-point format  
**Algorithm:** Normalizes mantissa, applies exponent bias, rounds, packs into IEEE 754 format  
**Arguments:** D0:D1 = mantissa, D2 = exponent, D3 = sign/type flags  
**Returns:** D0:D1 = double-precision value  
**Call targets:** 0x8C916 (normalize), 0x8C940 (pack helper)

#### **31. 0x8C9C2 - `__fp_classify_single`**
**Entry:** 0x8C9C2  
**Purpose:** Classify single-precision floating-point number  
**Algorithm:** Returns constant values for different classes (normal, subnormal, zero, infinity, NaN)  
**Arguments:** D0 = single-precision float  
**Returns:** D0 = classification code (1-5)  
**Note:** Used for fpclassify()-like functionality

#### **32. 0x8CA08 - `__fp_extract_exp_single`**
**Entry:** 0x8CA08  
**Purpose:** Extract exponent from single-precision float  
**Algorithm:** Masks exponent bits, converts from biased to unbiased form  
**Arguments:** D0 = single-precision float  
**Returns:** D0 = unbiased exponent (-127 to 128)

#### **33. 0x8CA1A - `__fp_extract_exp_double`**
**Entry:** 0x8CA1A  
**Purpose:** Extract exponent from double-precision float  
**Algorithm:** Masks exponent bits, converts from biased to unbiased form  
**Arguments:** D0 = double-precision high word  
**Returns:** D0 = unbiased exponent (-1023 to 1024)

#### **34. 0x8CA2C - `__fp_get_rounding_mode` / `__fp_set_rounding_mode`**
**Entry:** 0x8CA2C  
**Purpose:** Get and set floating-point rounding mode  
**Algorithm:** Accesses global variable at 0x20223D4  
**Arguments:** D0 = new rounding mode (for set)  
**Returns:** D0 = current rounding mode  
**Note:** Two functions in one - get when called, set when D0 provided

#### **35. 0x8CA3C - `__fp_get_exception_flags` / `__fp_set_exception_flags`**
**Entry:** 0x8CA3C  
**Purpose:** Get and set floating-point exception flags  
**Algorithm:** Accesses global variable at 0x20223DC  
**Arguments:** D0 = new exception flags (for set)  
**Returns:** D0 = current exception flags  
**Note:** Two functions in one

#### **36. 0x8CA4C - `__fixsfsi` (float to int)**
**Entry:** 0x8CA4C  
**Purpose:** Convert single-precision float to 32-bit integer with truncation  
**Algorithm:** Extracts exponent and mantissa, shifts based on exponent, handles overflow  
**Arguments:** D0 = single-precision float  
**Returns:** D0 = 32-bit integer  
**Note:** Standard C runtime function name

#### **37. 0x8CA98 - `__fixdfsi` (double to int)**
**Entry:** 0x8CA98  
**Purpose:** Convert double-precision float to 32-bit integer with truncation  
**Algorithm:** Similar to float version but with double-precision unpacking  
**Arguments:** D0:D1 = double-precision float  
**Returns:** D0 = 32-bit integer  
**Note:** Standard C runtime function name

#### **38. 0x8CB0A - `__fixunssfsi` (float to unsigned int)**
**Entry:** 0x8CB0A  
**Purpose:** Convert single-precision float to unsigned 32-bit integer  
**Algorithm:** Similar to signed version but with unsigned overflow handling  
**Arguments:** D0 = single-precision float  
**Returns:** D0 = unsigned 32-bit integer  
**Registers used:** D2-D4 preserved  
**Note:** Standard C runtime function name

#### **39. 0x8CB86 - `__fixunsdfsi` (double to unsigned int)**
**Entry:** 0x8CB86  
**Purpose:** Convert double-precision float to unsigned 32-bit integer  
**Algorithm:** Similar to signed double version but with unsigned overflow handling  
**Arguments:** D0:D1 = double-precision float  
**Returns:** D0 = unsigned 32-bit integer  
**Registers used:** D2-D4 preserved  
**Note:** Standard C runtime function name

### **KEY OBSERVATIONS:**

1. **Complete IEEE 754 Implementation**: This is a full software FPU implementation supporting single and double precision, all basic operations, conversions, and comparisons.

2. **Standard C Runtime Names**: Many functions follow standard Sun CC/GCC runtime library naming conventions (e.g., `__adddf3`, `__divsi3`).

3. **Global Variables**: Floating-point control/status registers at 0x20223D4 (rounding mode) and 0x20223DC (exception flags).

4. **Optimized Paths**: Functions have fast paths for common cases (normal numbers) and fallbacks for special cases (NaN, infinity, denormals).

5. **Register Usage**: Consistent with 68020 calling conventions, preserving D2-D7/A2-A6 where needed.

6. **Error Handling**: Returns appropriate NaN values or saturated integers on overflow/underflow.

This region represents a complete software floating-point library for systems without hardware FPU support, essential for PostScript's extensive use of floating-point arithmetic in graphics operations.

; === CHUNK 18: 0x8CC00-0x8D800 ===

### 1. 0x8CC00 - `__fixunsdfsi` (double to unsigned int conversion)
**Entry:** 0x8CC00  
**Purpose:** Convert double-precision floating-point to unsigned 32-bit integer  
**Behavior:** Checks for overflow (≥ 2³²) at 0x8CB7A, handles negative values by clearing sign bit  
**Arguments:** D0:D1 = double value (D0 high word, D1 low word)  
**Returns:** D0 = unsigned integer result  
**Key targets:** 0x8CB7A (overflow handler), 0x8CC0C (clear sign bit with bclr #0,%d0)  
**Algorithm:** Uses exponent bias 158 (127+31), normalizes mantissa, rounds

### 2. 0x8CC14 - `__fixdfsi` (double to signed int conversion)
**Entry:** 0x8CC14  
**Purpose:** Convert double-precision floating-point to signed 32-bit integer  
**Behavior:** Handles sign, calls 0x8CC2E for conversion, preserves sign in bit 31  
**Arguments:** D0:D1 = double value  
**Returns:** D0 = signed integer result  
**Key targets:** 0x8CC2E (core conversion), 0x8CC22 (handle negative with negl %d0, bset #31,%d0)

### 3. 0x8CC2E - `__fixdfsi` core conversion routine
**Entry:** 0x8CC2E  
**Purpose:** Extract integer from normalized double  
**Behavior:** Extracts exponent, normalizes mantissa, rounds to integer  
**Arguments:** D0 = high word of double (sign+exponent)  
**Returns:** D0 = integer value  
**Algorithm:** Uses exponent bias 158, normalizes mantissa with dbcs loop, rounds with addil #256,%d0

### 4. 0x8CC74 - `__fixsfsi` (float to signed int conversion)
**Entry:** 0x8CC74  
**Purpose:** Convert single-precision floating-point to signed 32-bit integer  
**Behavior:** Similar to double version but for single precision  
**Arguments:** D0 = float value (high word contains sign+exponent)  
**Returns:** D0 = signed integer result  
**Key targets:** 0x8CC92 (core conversion), 0x8CC84 (handle negative with andiw #32767,%d1, negl %d0)

### 5. 0x8CC92 - `__fixsfsi` core conversion routine
**Entry:** 0x8CC92  
**Purpose:** Extract integer from normalized float  
**Behavior:** Extracts 8-bit exponent (bias 127), 23-bit mantissa  
**Arguments:** D1 = exponent field, D0 = mantissa field  
**Returns:** D0 = integer value  
**Algorithm:** Handles denormals, overflow returns 0 at 0xCCCC

### 6. 0x8CCD0 - `__floatsidf` (signed int to double conversion)
**Entry:** 0x8CCD0  
**Purpose:** Convert signed 32-bit integer to double-precision  
**Behavior:** Handles sign, normalizes, packs into IEEE 754 format  
**Arguments:** D0 = signed integer (from stack at 0xCCD0: movel %sp@+,%d0)  
**Returns:** D0:D1 = double value  
**Key targets:** 0x8CCF6 (handle zero/small), 0x8CD08 (pack result)

### 7. 0x8CD14 - `__floatsisf` (signed int to float conversion)
**Entry:** 0x8CD14  
**Purpose:** Convert signed 32-bit integer to single-precision  
**Behavior:** Similar to double version but with 8-bit exponent  
**Arguments:** D0 = signed integer  
**Returns:** D0 = float value  
**Key targets:** 0x8CD26 (range check: cmpil #1056964608,%d1), 0x8CD08 (pack result)

### 8. 0x8CD56 - `__floatunsisf` (unsigned int to float conversion)
**Entry:** 0x8CD56  
**Purpose:** Convert unsigned 32-bit integer to single-precision  
**Behavior:** Handles unsigned values, similar to signed version  
**Arguments:** D0 = unsigned integer  
**Returns:** D0 = float value  
**Key targets:** 0x8CD68 (range check), 0x8CD08 (pack result)

### 9. 0x8CDBC - `__adddf3` (double addition)
**Entry:** 0x8CDBC  
**Purpose:** Add two double-precision floating-point numbers  
**Behavior:** Full IEEE 754 addition with denormal handling, rounding  
**Arguments:** D0:D1 = first double, A0 points to second double (D2:D3)  
**Returns:** D0:D1 = sum  
**Key targets:** 0x8CE76 (normalize/round), 0x8CF66 (division step for alignment)  
**Algorithm:** Unpacks exponents, aligns mantissas, adds, normalizes result

### 10. 0x8CF8C - `__muldf3` (double multiplication)
**Entry:** 0x8CF8C  
**Purpose:** Multiply two double-precision floating-point numbers  
**Behavior:** Full IEEE 754 multiplication with denormal handling, rounding  
**Arguments:** D0:D1 = first double, A0 points to second double (D2:D3)  
**Returns:** D0:D1 = product  
**Key targets:** 0x8CE76 (normalize/round), 0x8D022 (unpack exponents)  
**Algorithm:** Unpacks exponents, multiplies 53-bit mantissas, normalizes result

### 11. 0x8D14C - `__addsf3` (float addition)
**Entry:** 0x8D14C  
**Purpose:** Add two single-precision floating-point numbers  
**Behavior:** Full IEEE 754 single-precision addition  
**Arguments:** D0 = first float, A0 points to second float (D1)  
**Returns:** D0 = sum  
**Key targets:** 0x8C896 (unpack), 0x8C8E6 (pack)  
**Algorithm:** Similar to double addition but with 24-bit mantissa

### 12. 0x8D196 - `__mulsf3` (float multiplication)
**Entry:** 0x8D196  
**Purpose:** Multiply two single-precision floating-point numbers  
**Behavior:** Full IEEE 754 single-precision multiplication  
**Arguments:** D0 = first float, D1 = second float  
**Returns:** D0 = product  
**Key targets:** 0x8C832 (pack), 0x8D21A (unpack exponents)  
**Algorithm:** Unpacks exponents, multiplies 24-bit mantissas, normalizes result

### 13. 0x8D2A4 - `__divsf3` (float division)
**Entry:** 0x8D2A4  
**Purpose:** Divide two single-precision floating-point numbers  
**Behavior:** Full IEEE 754 single-precision division  
**Arguments:** D0 = dividend, D1 = divisor  
**Returns:** D0 = quotient  
**Key targets:** 0x8C832 (pack), 0x8D310 (unpack exponents)  
**Algorithm:** Unpacks exponents, divides 24-bit mantissas using restoring division

### 14. 0x8D402 - `__subsf3` (float subtraction)
**Entry:** 0x8D402  
**Purpose:** Subtract two single-precision floating-point numbers  
**Behavior:** Full IEEE 754 single-precision subtraction  
**Arguments:** D0 = minuend, D1 = subtrahend  
**Returns:** D0 = difference  
**Key targets:** 0x8C79C (unpack), 0x8C7E8 (pack)  
**Algorithm:** Similar to addition but with sign handling

### 15. 0x8D452 - `__truncdfsf2` (double to float truncation)
**Entry:** 0x8D452  
**Purpose:** Convert double-precision to single-precision with rounding  
**Behavior:** Truncates 53-bit mantissa to 24-bit with proper rounding  
**Arguments:** D0:D1 = double value  
**Returns:** D0 = float value  
**Key targets:** 0x8C79C (unpack), 0x8C8E6 (pack)  
**Algorithm:** Handles overflow/underflow, rounds to nearest even

### 16. 0x8D4BC - `__fixunssfsi` (float to unsigned int conversion)
**Entry:** 0x8D4BC  
**Purpose:** Convert single-precision floating-point to unsigned 32-bit integer  
**Behavior:** Similar to signed version but for unsigned  
**Arguments:** D0 = float value  
**Returns:** D0 = unsigned integer result  
**Key targets:** 0x8D4F2 (exponent check), 0x8D4FA (shift right for small values)

### 17. 0x8D500 - `__fixunsdfdi` (double to unsigned long long conversion)
**Entry:** 0x8D500  
**Purpose:** Convert double-precision to unsigned 64-bit integer  
**Behavior:** Handles 64-bit result in D0:D1  
**Arguments:** D0:D1 = double value  
**Returns:** D0:D1 = unsigned 64-bit integer  
**Key targets:** 0x8D53A (exponent check), 0x8D53E (shift right for small values)

### 18. 0x8D556 - Data region (not code)
**Address:** 0x8D556-0x8D57F  
**Purpose:** Contains data constants and small code fragments  
**Format:** Mixed data and code - appears to be part of a larger structure

### 19. 0x8D580 - `atan2` (arctangent of y/x)
**Entry:** 0x8D580  
**Purpose:** Compute arctangent of y/x (two-argument arctangent)  
**Behavior:** Full double-precision atan2 implementation  
**Arguments:** D0:D1 = y, stack contains x (double)  
**Returns:** D0:D1 = arctangent result in radians  
**Key targets:** 0x89968 (compare), 0x89A58 (multiply), 0x89AA0 (add)  
**Algorithm:** Uses polynomial approximation with range reduction

### 20. 0x8D7F0 - `__pow` (power function)
**Entry:** 0x8D7F0  
**Purpose:** Compute x^y (x raised to power y)  
**Behavior:** Double-precision power function  
**Arguments:** D0:D1 = x, A0 points to y (double)  
**Returns:** D0:D1 = x^y  
**Key targets:** 0x8D800 (main power computation)  
**Algorithm:** Uses identity x^y = exp(y * ln(x))

## KEY CORRECTIONS TO PRIOR ANALYSIS:

1. **0x8CF8C is `__muldf3` (double multiplication)**, not continuation of addition
2. **0x8D14C is `__addsf3` (float addition)**, not a continuation
3. **0x8D196 is `__mulsf3` (float multiplication)**, not data
4. **0x8D2A4 is `__divsf3` (float division)**, not continuation
5. **0x8D402 is `__subsf3` (float subtraction)**, not continuation
6. **0x8D452 is `__truncdfsf2` (double to float)**, not continuation
7. **0x8D4BC is `__fixunssfsi` (float to unsigned int)**, not continuation
8. **0x8D500 is `__fixunsdfdi` (double to unsigned long long)**, not continuation
9. **0x8D556-0x8D57F is data**, not code
10. **0x8D580 is `atan2` function**, not data
11. **0x8D7F0 is `__pow` function**, not data

1. **0x8D78E-0x8D7EF**: Constant table for math functions
   - Contains double-precision constants for π/2, π, etc.
   - Used by atan2 and pow functions

## FUNCTION CALL PATTERNS:

- Arguments passed in registers (D0-D1 for floats/doubles, A0 for pointers)
- Return values in D0 (float) or D0:D1 (double)
- Uses moveml to save/restore registers
- Many functions call helper routines at 0x8Cxxx for unpacking/packing

No direct hardware access in this region - these are pure software floating-point emulation routines for the 68020 when no FPU is present.

; === CHUNK 19: 0x8D800-0x8E277 ===

### 1. 0x8d800-0x8d856: `calloc` - allocate and zero memory
**Entry:** 0x8d800  
**Name:** `calloc`  
**Purpose:** Standard C library calloc() implementation. Multiplies count × size, calls malloc (0xd98c), then calls memset (0xde50) to clear the memory to zero. Returns NULL if allocation fails.  
**Arguments:** `fp@(8)` = count (number of elements), `fp@(12)` = size (bytes per element)  
**Return:** `D0` = pointer to allocated memory (or NULL)  
**Hardware:** Calls 0xd98c (malloc), 0xde50 (memset)  
**Callers:** C code needing zero-initialized arrays  
**Note:** Uses Sun C calling convention with LINK/UNLK.

### 2. 0x8d858-0x8d86a: `free` - deallocate memory
**Entry:** 0x8d858  
**Name:** `free`  
**Purpose:** Standard C library free() implementation. Simple wrapper that calls the internal free function at 0xdb6c.  
**Arguments:** `fp@(8)` = pointer to memory to free  
**Hardware:** Calls 0xdb6c (internal free function)  
**Callers:** C code freeing memory

### 3. 0x8d86c-0x8d884: `list_init` - initialize doubly-linked list
**Entry:** 0x8d86c  
**Name:** `list_init`  
**Purpose:** Initializes a doubly-linked list header by making it circular (next and prev pointers point to itself). Standard empty list initialization.  
**Arguments:** `fp@(8)` = pointer to list header (8 bytes: next, prev)  
**Callers:** List management code

### 4. 0x8d886-0x8d8aa: `list_remove` - remove node from list
**Entry:** 0x8d886  
**Name:** `list_remove`  
**Purpose:** Removes a node from a doubly-linked list by updating neighbor pointers (A->next->prev = A->prev, A->prev->next = A->next), then nulls the node's pointers.  
**Arguments:** `fp@(8)` = pointer to node to remove  
**Callers:** List management code

### 5. 0x8d8ac-0x8d8d6: `list_insert_after` - insert node after another
**Entry:** 0x8d8ac  
**Name:** `list_insert_after`  
**Purpose:** Inserts node A4 after node A5 in a doubly-linked list. Updates pointers: A4->prev = A5, A4->next = A5->next, A5->next->prev = A4, A5->next = A4.  
**Arguments:** `fp@(8)` = A5 (existing node), `fp@(12)` = A4 (new node to insert after A5)  
**Callers:** List management code

### 6. 0x8d8d8-0x8d958: `signal` - set signal/exception handler
**Entry:** 0x8d8d8  
**Name:** `signal`  
**Purpose:** Unix-style signal() implementation for exception handling. Checks system flags at 0x20174b0, prints debug message if bit 0 set. Stores handler address at A5@(68) and data at A5@(64). Calls 0xdf2e (setjmp) to save context.  
**Arguments:** `fp@(8)` = handler function address, `fp@(12)` = signal data  
**Hardware:** Accesses 0x20008f4 (signal handler pointer), 0x20174b0 (system flags), calls 0x88c0 (printf), 0x1140/0x1156 (debug functions), 0xdf2e (setjmp)  
**String at 0xd970:** "Unexpected exception: %d, %s\n"  
**Note:** This is part of the C runtime's exception handling system.

### 7. 0x8d95a-0x8d96c: `clear_signal_handler` - reset signal handler
**Entry:** 0x8d95a  
**Name:** `clear_signal_handler`  
**Purpose:** Clears the signal handler pointer at 0x20008f4 and system flags at 0x20174b0. Used to disable exception handling.  
**Hardware:** Writes to 0x20008f4, 0x20174b0

### 8. 0x8d98c-0x8daf8: `malloc` - memory allocator
**Entry:** 0x8d98c  
**Name:** `malloc`  
**Purpose:** Main memory allocator with free list management. Uses heap structures at 0x201732c-0x2017340. Allocates blocks with 4-byte headers using first-fit algorithm. Rounds size up to next multiple of 4, adds 4 for header. Maintains free list with LSB as "in-use" flag.  
**Arguments:** `fp@(8)` = size in bytes  
**Return:** `D0` = pointer to allocated memory (or NULL)  
**Hardware:** Accesses heap pointers at 0x201732c-0x2017340  
**Algorithm:** First-fit free list search with coalescing. Uses sentinel nodes at heap boundaries.  
**Callers:** calloc, realloc, and other C code

### 9. 0x8dafa-0x8db6a: `init_heap_block` - initialize heap block
**Entry:** 0x8dafa  
**Name:** `init_heap_block`  
**Purpose:** Initializes a new heap block for the malloc system. Aligns size to 4-byte boundary, sets up block headers, and links into free list. Updates heap boundary pointers at 0x2017338.  
**Arguments:** `fp@(8)` = base address, `fp@(12)` = size in bytes  
**Hardware:** Updates 0x2017338 (heap boundary pointer)  
**Callers:** malloc when expanding heap

### 10. 0x8db6c-0x8db98: `free_internal` - internal free function
**Entry:** 0x8db6c  
**Name:** `free_internal`  
**Purpose:** Internal free implementation called by the public free() wrapper. Clears the in-use bit in the block header and updates free list pointers. May coalesce with adjacent free blocks.  
**Arguments:** `fp@(8)` = pointer to memory to free  
**Hardware:** Updates 0x2017334 (free list head)  
**Callers:** free (0x8d858), realloc (0x8db9a)

### 11. 0x8db9a-0x8dc42: `realloc` - reallocate memory
**Entry:** 0x8db9a  
**Name:** `realloc`  
**Purpose:** Standard C library realloc() implementation. If new size is smaller, may shrink block in-place. Otherwise allocates new block, copies data, and frees old block.  
**Arguments:** `fp@(8)` = old pointer, `fp@(12)` = new size  
**Return:** `D0` = new pointer (or NULL if allocation fails)  
**Hardware:** Calls 0xdb6c (free_internal), 0xd98c (malloc)  
**Callers:** C code resizing allocations (memory allocator)

### 12. 0x8dc44-0x8dc52: `srand` - seed random number generator
**Entry:** 0x8dc44  
**Name:** `srand`  
**Purpose:** Sets the seed for the C runtime random number generator at 0x2017344.  
**Arguments:** `fp@(8)` = seed value  
**Hardware:** Writes to 0x2017344  
**Callers:** C code initializing RNG

### 13. 0x8dc54-0x8dc7a: `rand` - generate random number
**Entry:** 0x8dc54  
**Name:** `rand`  
**Purpose:** Standard linear congruential generator: seed = seed × 1103515245 + 12345, returns seed & 0x7FFFFFFF.  
**Return:** `D0` = random number (0 to 2^31-1)  
**Hardware:** Reads/writes 0x2017344  
**Callers:** C code needing random numbers

### 14. 0x8dc7c-0x8dca4: `strcmp` - compare strings
**Entry:** 0x8dc7c  
**Name:** `strcmp`  
**Purpose:** Standard C library strcmp() implementation. Compares two null-terminated strings byte by byte.  
**Arguments:** `fp@(8)` = string1, `fp@(12)` = string2  
**Return:** `D0` = 0 if equal, <0 if string1 < string2, >0 if string1 > string2  
**Callers:** C code comparing strings

### 15. 0x8dcae-0x8dcd0: `strcpy` - copy string
**Entry:** 0x8dcae  
**Name:** `strcpy`  
**Purpose:** Standard C library strcpy() implementation. Copies null-terminated string from source to destination.  
**Arguments:** `fp@(8)` = destination, `fp@(12)` = source  
**Return:** `D0` = destination pointer  
**Callers:** C code copying strings

### 16. 0x8dcd2-0x8dcf4: `strlen` - string length
**Entry:** 0x8dcd2  
**Name:** `strlen`  
**Purpose:** Standard C library strlen() implementation. Counts bytes in null-terminated string.  
**Arguments:** `fp@(8)` = string pointer  
**Return:** `D0` = length in bytes  
**Callers:** C code measuring strings

### 17. 0x8dcf6-0x8de4e: `memcpy` - copy memory
**Entry:** 0x8dcf6  
**Name:** `memcpy`  
**Purpose:** Optimized memory copy routine. Handles aligned and unaligned cases, forward/backward copying for overlapping regions. Uses moveml for bulk transfers.  
**Arguments:** `sp@(4)` = destination, `sp@(8)` = source, `sp@(12)` = length  
**Callers:** C code copying memory blocks

### 18. 0x8de50-0x8dec4: `memset` - fill memory
**Entry:** 0x8de50  
**Name:** `memset`  
**Purpose:** Optimized memory fill routine. Fills memory with specified byte value. Uses moveml for bulk fills when possible.  
**Arguments:** `sp@(4)` = destination, `sp@(8)` = fill byte, `sp@(12)` = length  
**Callers:** calloc, other C code

### 19. 0x8dec6-0x8ded6: `min` - minimum of two values
**Entry:** 0x8dec6  
**Name:** `min`  
**Purpose:** Returns the smaller of two 32-bit values.  
**Arguments:** `sp@(4)` = value1, `sp@(8)` = value2  
**Return:** `D0` = minimum value  
**Callers:** C code needing min()

### 20. 0x8ded8-0x8dee6: `max` - maximum of two values
**Entry:** 0x8ded8  
**Name:** `max`  
**Purpose:** Returns the larger of two 32-bit values.  
**Arguments:** `sp@(4)` = value1, `sp@(8)` = value2  
**Return:** `D0` = maximum value  
**Callers:** C code needing max()

### 21. 0x8dee8-0x8df1a: `sbrk` - extend heap
**Entry:** 0x8dee8  
**Name:** `sbrk`  
**Purpose:** Unix-style sbrk() system call. Increments the program break pointer at 0x201741c. Returns previous break or -1 on error.  
**Arguments:** `fp@(8)` = increment in bytes  
**Return:** `D0` = previous break address or -1  
**Hardware:** Reads/writes 0x201741c, checks against 0x2017420 (heap limit)  
**Callers:** malloc when expanding heap

### 22. 0x8df1c-0x8df2c: `setjmp` - save execution context
**Entry:** 0x8df1c  
**Name:** `setjmp`  
**Purpose:** Saves processor context (registers D2-D7, A2-A6, SP) to jmp_buf structure. Returns 0.  
**Arguments:** `sp@(4)` = jmp_buf pointer  
**Return:** `D0` = 0  
**Callers:** signal handler setup

### 23. 0x8df2e-0x8df54: `longjmp` - restore execution context
**Entry:** 0x8df2e  
**Name:** `longjmp`  
**Purpose:** Restores processor context from jmp_buf and returns specified value. Checks stack pointer validity.  
**Arguments:** `sp@(4)` = jmp_buf pointer, `sp@(8)` = return value  
**Hardware:** Checks against 0x2022380 (stack limit)  
**Callers:** Exception handling

### 24. 0x8df56-0x8df7c: `exception_handler` - hardware exception handler
**Entry:** 0x8df56  
**Name:** `exception_handler`  
**Purpose:** Generic hardware exception handler. Looks up handler in vector table at 0x2022290 and calls it.  
**Arguments:** Exception frame on stack  
**Hardware:** Vector table at 0x2022290  
**Callers:** Hardware exceptions

### 25. 0x8df7e-0x8dfca: `signal_install` - install signal handler
**Entry:** 0x8df7e  
**Name:** `signal_install`  
**Purpose:** Installs a handler in the exception vector table. Validates signal number (0-31).  
**Arguments:** `fp@(8)` = signal number, `fp@(12)` = handler address  
**Return:** `D0` = previous handler address  
**Hardware:** Vector table at 0x2022290, error code at 0x202226c  
**Callers:** signal() function

### 26. 0x8dfcc-0x8dfd2: `default_signal_handler` - default handler
**Entry:** 0x8dfcc  
**Name:** `default_signal_handler`  
**Purpose:** Default empty signal handler. Does nothing and returns.  
**Callers:** Installed as default in vector table

### 27. 0x8dfd4-0x8dfe0: `debug_signal_handler` - debug handler
**Entry:** 0x8dfd4  
**Name:** `debug_signal_handler`  
**Purpose:** Debug signal handler that calls debug function at 0x1140.  
**Hardware:** Calls 0x1140  
**Callers:** Installed for specific signals

### 28. 0x8dfe2-0x8dffe: `signal_raise` - raise signal
**Entry:** 0x8dfe2  
**Name:** `signal_raise`  
**Purpose:** Calls a signal handler directly from the vector table.  
**Arguments:** `fp@(8)` = signal number  
**Hardware:** Vector table at 0x2022290  
**Callers:** C code raising signals

### 29. 0x8e000-0x8e03e: `init_signal_handlers` - initialize signal system
**Entry:** 0x8e000  
**Name:** `init_signal_handlers`  
**Purpose:** Initializes all 32 signal vector entries to default handler (0x8dfcc). Sets specific handlers for signals 2 and 4.  
**Hardware:** Vector table at 0x2022290  
**Callers:** System initialization

### 30. 0x8e040-0x8e092: `time` - get current time
**Entry:** 0x8e040  
**Name:** `time`  
**Purpose:** Gets current time in seconds since epoch. Uses hardware timer at 0x4b48, adds to base at 0x2017348. Handles 32-bit overflow.  
**Arguments:** `fp@(8)` = pointer to store time (optional)  
**Return:** `D0` = current time in seconds  
**Hardware:** Calls 0x4b48 (timer read), accesses 0x2017348/0x201734c  
**Callers:** C code needing time()

### 31. 0x8e094-0x8e0c0: `settime` - set system time
**Entry:** 0x8e094  
**Name:** `settime`  
**Purpose:** Sets system time base. Calculates offset from current timer reading.  
**Arguments:** `fp@(8)` = pointer to new time value  
**Hardware:** Calls 0x4b48 (timer read), updates 0x2017348/0x201734c  
**Callers:** Time setting code

### 32. 0x8e0c2-0x8e116: `gettimeofday` - get time with microseconds
**Entry:** 0x8e0c2  
**Name:** `gettimeofday`  
**Purpose:** Gets current time with microsecond resolution. Returns seconds and microseconds in separate fields.  
**Arguments:** `fp@(8)` = timeval struct for seconds, `fp@(12)` = timeval struct for microseconds  
**Return:** `D0` = 0 (success)  
**Hardware:** Calls 0x4b48 (timer read), accesses 0x2017348  
**Callers:** C code needing high-resolution time (system timer)

### 33. 0x8e118-0x8e276: DATA - character width table
**Entry:** 0x8e118  
**Name:** `char_width_table`  
**Purpose:** Lookup table for character widths in pixels (likely for built-in font). Contains 256 entries of 1 byte each.  
**Format:** Array of unsigned char  
**Note:** This is DATA, not code. Values range from 0x20 to 0x7e (printable ASCII).

1. **0x8d96e-0x8d98a**: Previously identified as part of signal() function, actually contains the format string "Unexpected exception: %d, %s\n" used by signal().
2. **0x8e118-0x8e276**: Previously thought to be code continuation, actually a 256-byte character width table.
3. **Function names**: Corrected to standard C library names (calloc, free, malloc, realloc, strcmp, strcpy, strlen, memcpy, memset, sbrk, setjmp, longjmp, time, settime, gettimeofday).
4. **Missing functions**: Added min(), max(), init_heap_block(), free_internal(), and various signal handling functions.
5. **Hardware addresses**: Corrected vector table address to 0x2022290 (not 0x2022298).

- This region contains the core C runtime library for the system.
- Three distinct memory management systems: C heap (this region), PS VM (bank 2), and high-level wrapper (bank 4).
- Signal/exception handling system with vector table at 0x2022290.
- Time functions use hardware timer at 0x4b48 with 32-bit second counter and microsecond resolution.
- Optimized memcpy/memset routines use moveml for bulk transfers.
- Character width table suggests built-in monospaced or proportionally-spaced font.  (font metric)

; === CHUNK 20: 0x8FFE0-0x90222 ===

2. **PC-relative address calculations were wrong** - The correct calculation for the PC-relative accesses at 0x9006C and 0x90078 is:
   - PC at instruction execution = address of instruction + 2 (for the displacement word)
   - For 0x9006C: PC = 0x90072, displacement = 0x17201F7, offset = 0x8C  struct field
   - Target = 0x90072 + 0x17201F7 + 0x8C = **0x2027265** (not 0xA720258)
   - For 0x90078: PC = 0x9007E, displacement = 0x17201F7, offset = 0x168  struct field
   - Target = 0x9007E + 0x17201F7 + 0x168 = **0x20272E1**

3. **The repeating 0x4AFC is the ILLEGAL instruction** - Not padding, but likely used as a breakpoint marker or debug trap.

### 1. Encrypted/Compressed Data Block
**Address:** 0x8FFE0 - 0x8FFFF  
**Format:** Likely encrypted Adobe Type 1 font data (eexec) or compressed code  
**Note:** The repeating 0xF0F0 pattern at the end suggests padding or a marker for end of data. This is consistent with the eexec-encrypted font data found elsewhere in bank 4.

### 2. String Literal
**Address:** 0x90200 - 0x90222  
**Size:** 35 bytes (including null terminator)  
**Content:** ASCII string "status/customstring true put\n"  
**Purpose:** PostScript command string for setting a custom status string variable. This would be executed by the PostScript interpreter to set the `status/customstring` dictionary entry to `true`. The `put` operator stores a key-value pair in a dictionary.

### 1. Function at 0x90000 (Memory Copy Routine)
**Entry:** 0x90000  
**Name:** `memcpy_large_block`
**Purpose:** Copies a large block of memory using move instructions with post-increment addressing. The routine appears to copy 4 longwords (16 bytes) per iteration, with the loop count determined by the value at 0x90002-0x90006.  
**Arguments:** Likely takes source address in A0, destination in A1, and count in D0  
**Return:** Unknown (likely returns with destination pointer in A1)  
**Hardware access:** None directly visible  
1. Loads parameters from memory (likely count and stride)
2. Sets up source (A0) and destination (A1) pointers
3. Copies data using `movel %a0@+, %a1@+` instructions
4. Loops based on count value
**Note:** This is actual code, not data. The bytes starting with 0xAADD3399 decode to valid 68020 instructions.

### 2. Function at 0x90028 (Main Conditional Function)
**Entry:** 0x90028  
**Name:** `set_custom_status_if_arg2`
**Purpose:** Checks if the argument equals 2. If true, it retrieves a PostScript object reference for the string at 0x90200, extracts two values from the returned structure, sets bit 7 of the first value, and calls a PostScript execution function with the modified values. If the argument is not 2, it returns immediately.  
**Arguments:** One 32-bit integer argument at %fp@(12)  
**Hardware access:** None directly visible  
**Call targets:** Calls functions at 0x90078 and 0x9006c  
1. Compare argument to 2
2. If not equal, return (0x90034-0x90038)
3. Push address 0x90200 (string) onto stack (0x9003A-0x90040)
4. Call function at 0x90078 (gets PostScript object reference) (0x90040)
5. Extract two 32-bit values from offsets 0 and 4 of returned structure (0x90046-0x90052)
6. Set bit 7 of the first value (offset 0) using `bset #7` (0x90056)
7. Push both values onto stack (0x9005C-0x90064)
8. Call function at 0x9006c (executes PostScript) (0x90064)
9. Clean up stack and return (0x90068-0x9006A)

### 3. Function at 0x9006C (PostScript Execute Trampoline)
**Entry:** 0x9006C  
**Name:** `call_ps_execute_function`
**Purpose:** Retrieves a function pointer from memory at address 0x2027265 and calls it. This is a trampoline function that loads a PostScript execution function pointer from a fixed location in RAM and jumps to it.  
**Return:** Returns whatever the target function returns  
**Hardware access:** Reads from RAM address 0x2027265  
**Call targets:** Calls function pointer at 0x2027265  
1. Load function pointer from 0x2027265 using PC-relative addressing
2. Push it onto stack (effectively preparing for RTS)
3. Return, which will jump to the loaded function pointer

### 4. Function at 0x90078 (PostScript Object Lookup)
**Entry:** 0x90078  
**Name:** `get_ps_object_for_string`
**Purpose:** Retrieves a PostScript object reference for a string. Loads a function pointer from memory at address 0x20272E1 and calls it. This is likely a PostScript interpreter function that converts a C string to a PostScript string object.  
**Arguments:** Expects string pointer on stack (pushed by caller)  
**Return:** Returns PostScript object reference in D0  
**Hardware access:** Reads from RAM address 0x20272E1  
**Call targets:** Calls function pointer at 0x20272E1  
1. Load function pointer from 0x20272E1 using PC-relative addressing
2. Push it onto stack (effectively preparing for RTS)
3. Return, which will jump to the loaded function pointer

### 5. Function at 0x90100 (Simple Return)
**Entry:** 0x90100  
**Name:** `null_function`
**Purpose:** Simple RTS instruction. Could be padding, an unused function stub, or a target for patching.  
**Return:** Returns to caller  
1. **PostScript Integration:** The functions at 0x90028-0x9006A demonstrate tight integration between C code and the PostScript interpreter. The function retrieves PostScript function pointers from fixed RAM locations (0x2027265 and 0x20272E1) and calls them.

2. **Status String Setting:** The overall purpose appears to be setting a PostScript status string when a specific condition (argument == 2) is met. This could be part of a larger configuration or initialization routine.

3. **Memory Layout:** The PC-relative addressing reveals that important PostScript interpreter function pointers are stored in RAM at addresses around 0x2027000, which is consistent with the RAM base address of 0x02000000.

4. **Code Structure:** The region shows a mix of:
   - Data (encrypted/compressed at 0x8FFE0)
   - Code (functions at 0x90000, 0x90028, 0x9006C, 0x90078, 0x90100)
   - String literal (0x90200)

5. **Debug Markers:** The ILLEGAL instructions (0x4AFC) at 0x90102-0x90104 are likely debug breakpoints or markers, not padding.

- 0x90000-0x90026 is code, not a jump table
- PC-relative targets are 0x2027265 and 0x20272E1, not 0xA720258
- The function at 0x90028 has a clear conditional check (arg == 2)
- Bit manipulation (bset #7) modifies the PostScript object before execution
- The string is a complete PostScript command, not just a status message