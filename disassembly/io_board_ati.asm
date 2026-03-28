; ======================================================================
; AGFA COMPUGRAPHIC 9000PS - IO ANNOTATED DISASSEMBLY
; ======================================================================
; IO board - Agfa Typesetter Interface ATI v2.2 (68000 @ 8MHz)
; ROM addresses: 0x00000 - 0x0FFFF
; Chunk size: 0xC00 bytes
; ======================================================================

; address ranges: 0x04000000 (IO board comm) and 0x07000000 (debug console).
; This IO board communicates with the main board via the 0x04000000 channel.

; === CHUNK 1: 0x00000-0x00040 ===

**Entry address:** 0x00000  
**Name:** `reset_vector_table`
**Purpose:** This is the 68000 exception vector table. The first 8 bytes contain the initial supervisor stack pointer (SSP) and program counter (PC) values loaded by the CPU after reset. All other exception vectors point to infinite loops (BRA.W to self), which is a common embedded systems strategy for handling unexpected exceptions - the processor will spin in place rather than executing random code or crashing unpredictably.  
**Format:** 64 bytes total (16 long words = 16 vectors × 4 bytes each)  
- 0x00000: 0x00014000 (Initial SSP = stack starts at 0x14000)
- 0x00004: 0x00000400 (Initial PC = code entry point at 0x400)
- 0x00008-0x0003F: 0x6000FFFE (BRA.W $+0 = infinite loop)

## DETAILED VECTOR TABLE

| Address | Vector Type           | Value      | Meaning                          |
|---------|-----------------------|------------|----------------------------------|
| 0x00000 | Initial SSP           | 0x00014000 | Stack starts at 0x14000          |
| 0x00004 | Initial PC            | 0x00000400 | Code starts at 0x400             |
| 0x00008 | Bus Error             | 0x6000FFFE | BRA.W 0x8 (infinite loop)        |
| 0x0000C | Address Error         | 0x6000FFFE | BRA.W 0xC (infinite loop)        |
| 0x00010 | Illegal Instruction   | 0x6000FFFE | BRA.W 0x10 (infinite loop)       |
| 0x00014 | Division by Zero      | 0x6000FFFE | BRA.W 0x14 (infinite loop)       |
| 0x00018 | CHK/CHK2              | 0x6000FFFE | BRA.W 0x18 (infinite loop)       |
| 0x0001C | TRAPV                 | 0x6000FFFE | BRA.W 0x1C (infinite loop)       |
| 0x00020 | Privilege Violation   | 0x6000FFFE | BRA.W 0x20 (infinite loop)       |
| 0x00024 | Trace                 | 0x6000FFFE | BRA.W 0x24 (infinite loop)       |
| 0x00028 | Line 1010 Emulator    | 0x6000FFFE | BRA.W 0x28 (infinite loop)       |
| 0x0002C | Line 1111 Emulator    | 0x6000FFFE | BRA.W 0x2C (infinite loop)       |
| 0x00030 | Unassigned            | 0x6000FFFE | BRA.W 0x30 (infinite loop)       |
| 0x00034 | Unassigned            | 0x6000FFFE | BRA.W 0x34 (infinite loop)       |
| 0x00038 | Unassigned            | 0x6000FFFE | BRA.W 0x38 (infinite loop)       |
| 0x0003C | Unassigned            | 0x6000FFFE | BRA.W 0x3C (infinite loop)       |

## KEY OBSERVATIONS

1. **Stack location confirmed:** Initial SSP = 0x00014000, which matches the known IO board memory map (stack top at 0x14000, global variables at 0x15000).

2. **Entry point:** Initial PC = 0x00000400, so the first executable code after reset will be at address 0x400. This is where system initialization begins.

3. **Exception handling strategy:** All exception vectors (except reset) point to themselves with BRA.W instructions, creating tight infinite loops. This is typical for embedded systems where unexpected exceptions should halt execution rather than risk corrupting hardware or data.

5. **Vector table completeness:** This covers the first 16 vectors (0-15) of the 68000's 256-vector table. The remaining vectors (16-255) would be located elsewhere in memory, likely starting at 0x000040 or later.

- **0x00000400:** System entry point - initialization code begins here.
- **0x00014000:** Stack top location - matches known memory map.
- **0x00015000:** Start of global variables region.

The raw disassembly shows:
0: 0001 4000    orib #0,%d1
4: 0000 0400    orib #0,%d0
- `0001` = ORI.B #0,D1 (opcode 0x0001)
- `4000` = NEGX.B D0 (opcode 0x4000)
- `0000` = ORI.B #0,D0 (opcode 0x0000)
- `0400` = SUBI.B #0,D0 (opcode 0x0400)

This is a classic case of data being misinterpreted as code. The correct interpretation is that these are 32-bit data values, not executable instructions.

; === CHUNK 2: 0x00400-0x01000 ===

1. **0x0400**: This is NOT the reset vector handler - it's actually the main entry point. The reset vector would be at 0x0000. This is the code that gets called after reset initialization.

3. **0x04B4**: This is NOT `handle_extended_command_with_retry` - it's actually `send_command_and_wait_for_ack`. The function sends command 5, formats a string, waits for ACK (104), then waits for response 100.

4. **0x055A**: This is correctly identified as the main command state machine dispatcher.

5. **0x0A4A**: This is correctly identified as a secondary command processor for ATI commands.

### DETAILED FUNCTION ANALYSIS:

#### 0x0400: `main_entry_point`
- **Entry**: 0x0400
- **Purpose**: Main system entry point after reset - initializes hardware and enters main loop
- **Arguments**: None (called after reset)
- **Return**: Never returns (infinite loop at 0x426)
- **Behavior**: 
  1. Sets stack pointer to 0x14000 (top of stack area)
  2. Sets A0 to shared memory base (0x1F000) + 4
  3. Stores A0 at 0x1F000 (sets up shared memory pointer)
  4. Clears frame pointer (A6 = 0)
  5. Calls 0x30BC (hardware initialization)
  6. Calls 0x1804 (system initialization)
  7. Enters infinite NOP loop at 0x426 (this is actually an error handler, not the main loop!)
- **Hardware**: Shared memory at 0x1F000
- **Call targets**: 0x30BC, 0x1804
- **Called by**: Reset initialization code

#### 0x042C: `initialize_and_run_system`
- **Entry**: 0x042C
- **Purpose**: Initializes SCSI, buffers, and enters the main command processing loop
- **Arguments**: None
- **Return**: Never returns (infinite loop)
- **Behavior**: 
  1. Saves D2/A2
  2. Sets A2 to 0x050026 (SCSI controller data port)
  3. Calls 0x1116 (SCSI initialization)
  4. Calls 0x1812 (buffer initialization)
  5. Calls 0x0FB0 (reset/init function)
  6. Polls status via 0x1B4E and 0x1B36
  7. Based on status, either initializes system or clears SCSI
  8. Sets resolution to 1200 (0x04B0) at 0x1501E
  9. Clears inverse flag at 0x15012
  10. Sets system state to 15 (0x0F) at 0x1500E
  11. Sends command 5 via 0x123E
  12. Enters main loop polling commands
- **Hardware**: 
  - SCSI controller at 0x050026 (A2)
  - RAM variables: 0x15012 (inverse flag), 0x1500E (system state), 0x1501E (resolution)
- **Call targets**: 0x1116, 0x1812, 0x0FB0, 0x1B4E, 0x1B36, 0x123E, 0x0BB2, 0x055A, 0x0A4A
- **Called by**: Main entry point (0x0400) after initialization

#### 0x04B4: `send_command_and_wait_for_ack`
- **Entry**: 0x04B4
- **Purpose**: Sends a command and waits for acknowledgment with retry logic
- **Arguments**: None
- **Return**: D0 = 0 on failure, 1 on success
- **Behavior**: 
  1. Saves D2/A2
  2. Sets A2 to 0x15016 (command state pointer)
  3. Sets system state to 3 at 0x1500E
  4. Sends command 5 via 0x123E
  5. Formats string at 0x17000 via 0x0E4C (sprintf-like function)
  6. Waits for ACK (104) via 0x0D6C
  7. If no ACK, returns failure
  8. Sets command state to -1
  9. Retry loop (up to 5 times) waiting for response 100
  10. If response 100 received, sends command 6, waits for 103, sends command 2
  11. Checks 0x1501A and sets system state accordingly
- **Hardware**: 
  - 0x15016: Command state
  - 0x1500E: System state
  - 0x1501A: Parsed value
  - 0x17000: String table
- **Call targets**: 0x123E, 0x0E4C, 0x0D6C, 0x0BB2
- **Called by**: Command state machine handlers

#### 0x055A: `dispatch_command_state_machine`
- **Entry**: 0x055A
- **Purpose**: Main command dispatcher using 15-state state machine (states 0-14)
- **Arguments**: None
- **Return**: Varies by state handler
- **Behavior**: 
  1. Sets up frame pointer (-8 bytes local)
  2. A2 = 0x1501A (current command value)
  3. A4 = 0x0E7E (error handler function)
  4. A3 = 0x15000 (message buffer pointer)
  5. Gets state from 0x15016
  6. Validates state (0-14)
  7. Uses jump table at 0x0590 to dispatch to state handlers
  8. Each state handler processes specific commands
- **State handlers** (based on jump table at 0x0590):
  - State 0: 0x05C4 (process command 4)
  - State 1: 0x0630 (process command 9/3/2/11/4)
  - State 2: 0x0698 (process command 4/2/11)
  - State 3: 0x0780 (process command 4)
  - State 4: 0x07DC (process command 4)
  - State 5: 0x084C (format and send response)  (PS dict operator)
  - State 6: 0x0890 (process resolution command)
  - State 7: 0x0936 (process command 4)
  - State 8: 0x0A06 (set inverse flag)
  - State 9: 0x0A12 (clear inverse flag)
  - State 10: 0x0A1C (check inverse flag)
  - State 11: 0x0A40 (cleanup and return)
  - State 12: 0x0A40 (cleanup and return)
  - State 13: 0x0A40 (cleanup and return)
  - State 14: 0x0A40 (cleanup and return)
- **Hardware**: 
  - 0x15016: Command state
  - 0x1501A: Current command value
  - 0x15000: Message buffer
- **Call targets**: Various state handlers, 0x0E7E (error handler)
- **Called by**: Main loop at 0x042C

#### 0x0A4A: `handle_ati_commands`
- **Entry**: 0x0A4A
- **Purpose**: Handles ATI (Agfa Typesetter Interface) specific commands
- **Arguments**: None
- **Return**: None
- **Behavior**: 
  1. Saves A2-A4
  2. A2 = 0x0E94 (cleanup function)
  3. A4 = 0x15012 (inverse flag pointer)
  4. A3 = 0x19BC (output function)
  5. Gets state from 0x15016
  6. Validates state (0-14)
  7. Uses jump table at 0x0A7C to dispatch to ATI command handlers
- **ATI command handlers**:
  - State 0: 0x0A9C (send command 15)  (PS dict operator)
  - State 1: 0x0AB0 (set resolution and inverse)
  - State 2: 0x0ADA (format and send string)  (PS dict operator)
  - State 3: 0x0AE2 (format and compare strings)
  - States 4-13: Various string formatting operations
  - State 14: 0x0B2C (check inverse flag)
- **Hardware**: 
  - 0x15016: Command state
  - 0x15012: Inverse flag
- **Call targets**: 0x12E4, 0x12F2, 0x131A, 0x12D6, 0x16D4, 0x21F2, 0x19BC
- **Called by**: Main loop at 0x042C

#### 0x0BB2: `receive_and_parse_scsi_message`
- **Entry**: 0x0BB2
- **Purpose**: Receives and parses messages from the main board via SCSI
- **Arguments**: None
- **Return**: None
- **Behavior**: 
  1. Saves D2/A2-A3
  2. A3 = 0x15016 (command state pointer)
  3. A2 = 0x15000 (message buffer pointer)
  4. Reads message via 0x18F8
  5. Parses message type (1, 2, or other)
  6. For type 1: Parses 3-character command, matches against table at 0x17112
  7. For type 2: Parses 4-character command, matches against table at 0x171AC
  8. Sets command state based on parsed command
  9. Handles special commands 104 (h), 103 (g), 101 (e)
- **Hardware**: 
  - 0x15016: Command state
  - 0x15000: Message buffer
  - 0x1501A: Parsed value
- **Call targets**: 0x18F8, 0x178C, 0x0F84, 0x0EAA, 0x1A04, 0xB4E, 0x1014, 0x1A70
- **Called by**: Many functions including main loop

#### 0x0D06: `wait_for_response_g_or_f`
- **Entry**: 0x0D06
- **Purpose**: Waits for response 103 (g) or 102 (f) with timeout
- **Arguments**: None
- **Return**: D0 = 0 on timeout, 1 on success
- **Behavior**: 
  1. Calls 0x0BB2 to receive message
  2. If response is 103 (g), returns success
  3. If response is 102 (f), checks byte at 0x15006+5
  4. If byte is '0' (0x30), returns success
  5. Otherwise formats error message and returns failure
- **Hardware**: 
  - 0x15016: Command state
  - 0x15006: Message data pointer
- **Call targets**: 0x0BB2, 0x055A, 0x21F2, 0x1A70
- **Called by**: Command state handlers

#### 0x0D6C: `wait_for_ack_with_timeout`
- **Entry**: 0x0D6C
- **Purpose**: Waits for ACK (104) with 5-retry timeout
- **Arguments**: None
- **Return**: D0 = 0 on timeout, 1 on success
- **Behavior**: 
  1. Saves D2
  2. Sets retry counter to 0
  3. Calls 0x0BB2 to receive message
  4. If response is 104 (h), returns success
  5. Retries up to 5 times
  6. On timeout, formats error message
- **Hardware**: 
  - 0x15016: Command state
- **Call targets**: 0x0BB2, 0x21F2, 0x1A70
- **Called by**: Command senders

#### 0x0DBE: `wait_for_response_e_with_timeout`
- **Entry**: 0x0DBE
- **Purpose**: Waits for response 101 (e) with 5-retry timeout
- **Arguments**: None
- **Return**: D0 = 0 on timeout, 1 on success
- **Behavior**: 
  1. Saves D2/A2
  2. A2 = 0x15032 (buffer for error messages)
  3. Sets retry counter to 0
  4. Calls 0x0BB2 to receive message
  5. If response is 101 (e), checks byte at 0x15006+5
  6. If byte is '0' (0x30), returns success
  7. Retries up to 5 times
  8. On timeout or error, formats error message
- **Hardware**: 
  - 0x15016: Command state
  - 0x15006: Message data pointer
  - 0x15032: Error message buffer
- **Call targets**: 0x0BB2, 0x21F2, 0x1A70
- **Called by**: Command state handlers

#### 0x0E4C: `format_and_send_string`
- **Entry**: 0x0E4C
- **Purpose**: Formats a string and sends it via output function
- **Arguments**: String pointer at SP@(8)
- **Return**: None
- **Behavior**: 
  1. Creates stack frame (-64 bytes)
  2. Gets string pointer from argument
  3. Formats string using vsprintf-like function at 0x21F2
  4. Sends formatted string via output function at 0x19BC
- **Call targets**: 0x21F2, 0x19BC
- **Called by**: Many command handlers

#### 0x0E7E: `handle_command_error`
- **Entry**: 0x0E7E
- **Purpose**: Handles command errors by sending error message
- **Arguments**: None
- **Return**: None
- **Behavior**: 
  1. Sends error string at 0x17188 via output function
- **Call targets**: 0x19BC
- **Called by**: Command state machine dispatcher

#### 0x0E94: `send_cleanup_message`
- **Entry**: 0x0E94
- **Purpose**: Sends cleanup/acknowledgment message
- **Arguments**: None
- **Return**: None
- **Behavior**: 
  1. Sends string at 0x1718E via output function
- **Call targets**: 0x19BC
- **Called by**: Command state handlers

#### 0x0EAA: `handle_parse_error`
- **Entry**: 0x0EAA
- **Purpose**: Handles message parsing errors
- **Arguments**: None
- **Return**: None
- **Behavior**: 
  1. Sets command state and parsed value to -1
  2. Formats error message with data from 0x15006
  3. Sends error message via 0x1A70
- **Hardware**: 
  - 0x15016: Command state
  - 0x1501A: Parsed value
  - 0x15006: Message data pointer
- **Call targets**: 0x21F2, 0x1A70
- **Called by**: Message parser (0x0BB2)

#### 0x0EE2: `convert_hex_string_to_decimal`
- **Entry**: 0x0EE2
- **Purpose**: Converts 8-character hex string to decimal string
- **Arguments**: Source pointer at SP@(20), dest pointer at SP@(24)
- **Return**: None
- **Behavior**: 
  1. Saves D2-D4/A2
  2. Converts 8 hex chars to 32-bit value
  3. Converts to decimal string with leading zeros
  4. Null-terminates result
- **Algorithm**: 
  - Reads 8 characters
  - Converts hex to binary (0-9, A-F)
  - Divides by powers of 10 (100000, 10000, etc.)
  - Converts digits to ASCII
- **Call targets**: 0x302E (signed modulus), 0x3090 (signed multiply)
- **Called by**: Command state handlers

#### 0x0F84: `parse_two_digit_decimal`
- **Entry**: 0x0F84
- **Purpose**: Parses two-digit decimal string to integer
- **Arguments**: String pointer at SP@(8)
- **Return**: D0 = parsed integer (0-99)
- **Behavior**: 
  1. Saves D2
  2. Reads two characters
  3. Converts from ASCII to integer: (digit1 × 10) + digit2
- **Called by**: Message parser (0x0BB2)

#### 0x0FB0: `reset_system_state`
- **Entry**: 0x0FB0
- **Purpose**: Resets system state variables to defaults
- **Arguments**: None
- **Return**: None
- **Behavior**: 
  1. Sets system state to 3
  2. Sets command state to -1
  3. Clears inverse flag
  4. Clears various counters (0x1502E, 0x15022, 0x1502A)
  5. Sets parsed value to 2
  6. Sends command 0
- **Hardware**: 
  - 0x1500E: System state
  - 0x15016: Command state
  - 0x15012: Inverse flag
  - 0x1501A: Parsed value
- **Call targets**: 0x123E
- **Called by**: System initialization (0x042C)

#### 0x0FEC: `parse_four_digit_decimal`
- **Entry**: 0x0FEC
- **Purpose**: Parses four-digit decimal string to integer
- **Arguments**: String pointer at SP@(8)
- **Return**: D0 = parsed integer (0-9999)
- **Behavior**: 
  1. Saves D2
  2. Reads four characters
  3. Converts from ASCII to integer: ((digit1 × 10 + digit2) × 10 + digit3) × 10 + digit4
- **Called by**: Resolution command handler (state 6 at 0x0890)

#### `command_state_jump_table_15_entries_2_by` — 0x0590-0x05AC: Command state jump table (15 entries × 2 bytes)
- 15 word offsets for states 0-14  struct field
- Used by dispatch_command_state_machine at 0x055A

#### `ati_command_jump_table_15_entries_2_byte` — 0x0A7C-0x0A98: ATI command jump table (15 entries × 2 bytes)
- 15 word offsets for ATI command states 0-14  struct field
- Used by handle_ati_commands at 0x0A4A

#### `system_state_jump_table_5_entries_2_byte` — 0x0B6E-0x0B76: System state jump table (5 entries × 2 bytes)
- Word offsets for system states 1-4 and 15  struct field
- Used by function at 0x0B4E

1. The system uses a sophisticated state machine with 15 states for command processing.

2. There are two parallel command processing systems:
   - Main command system (0x055A) for SCSI-based commands
   - ATI command system (0x0A4A) for Agfa Typesetter Interface commands

3. The message format includes:
   - Type 1: 3-character commands (matched against table at 0x17112)
   - Type 2: 4-character commands (matched against table at 0x171AC)

4. Common response codes:
   - 100-104: d, e, f, g, h (ACK/response codes)
   - Other codes map to specific command states

5. The system has extensive error handling and retry logic for communication.

6. String table starts at 0x17000 and contains various command strings and error messages.

; === CHUNK 3: 0x01000-0x01C00 ===

### Function at 0x1000: `parse_decimal_string`
**Purpose:** Converts an ASCII decimal string to an integer. Reads characters from A0 until non-digit, accumulating result in D2.
- Initializes D2 to 0 (caller's responsibility)
- For each character: if '0'-'9', subtract 0x30, add to D2
- Returns result in D0
**Arguments:** A0 points to null-terminated decimal string
**Return:** D0 = integer value
**Note:** This is a continuation from 0xFF6 (not shown here)

### Function at 0x1014: `process_ati_command`
**Purpose:** Processes ATI (Agfa Typesetter Interface) commands from the main board via SCC. Determines command type based on characters at offsets 5,6,10 in the command buffer.
- A2 = 0x150F2 (output buffer)
- A1 = 0x15022 (some flag variable)
- A3 = 0x15000 (command buffer base)
- Reads command byte at offset 10 (A3@(6)+10)  struct field
- Switch on ASCII value: '0'→sets flag, '1'→command 6, '3'→command 5
- Checks byte at offset 5 for 'W' (0x57)→command 4  struct field
- Checks byte at offset 6 for 'H' (0x48)→command 1  struct field
- Calls `send_hardware_command` (0x123E) with command number  (PS dict operator)
- Formats response string with status indicators
**Hardware:** Accesses SCC at 0x40000 (PS channel)
**Called by:** Main command loop

### Function at 0x1116: `init_serial_ports`
**Purpose:** Initializes all three Zilog 8530 SCC channels with specific baud rates and configurations.
- A0 = 0x40000 (VIA #1 - PS channel)
- A1 = 0x40010 (SCC (Z8530) - debug console)
- A2 = 0x50000 (SCC #3 - ATI to imagesetter)  (PS image operator)
- A3 = 0x40000 (base)
- Programs each SCC with control bytes:
  - WR5 = 0x22 (8 bits, DTR, RTS)
  - WR5 = 0x38 (8 bits, DTR, RTS, TX enable)
  - WR4 = 0x10 (×16 clock, 1 stop bit, no parity)
  - WR3 = 0x13 (Rx 8 bits, Rx enable)
  - WR3 = 0x17 (Rx 8 bits, Rx enable, auto enable)
  - WR14 = 0xBB (BRG enable, BRG source = PCLK)
  - WR9 = 0x14 (reset channel)
  - WR15 = 0xC0 (external/status interrupt enable)
  - WR13 = 0x3F (time constant low)
  - WR12 = 0x70 (time constant high = 9600 baud)
  - WR11 = 0x00 (clock mode)
  - WR6/7 = 0xFF (sync chars)
- If third SCC exists (test at 0x12C0), configures it similarly
- Delay loop of 10000 iterations
**Called by:** System initialization

### Function at 0x1206: `scc_receive_byte`
**Purpose:** Attempts to receive a byte from an SCC channel if data available.
**Arguments:** A0 = SCC base address, A1 = pointer to store byte
**Return:** D0 = 1 if byte received, 0 if no data
**Algorithm:** Checks RR0 bit 0 (Rx character available), reads from WR7/RR7
**Called by:** Multiple serial I/O functions

### Function at 0x1222: `scc_send_byte`
**Purpose:** Attempts to send a byte to an SCC channel if transmitter ready.
**Arguments:** A0 = SCC base address, D0.b = byte to send
**Return:** D0 = 1 if byte sent, 0 if transmitter busy
**Algorithm:** Checks RR0 bit 2 (Tx buffer empty), writes to WR7
**Called by:** Multiple serial I/O functions

### Function at 0x123E: `send_hardware_command`
**Purpose:** Sends a hardware control command (0-6) to the hardware control register.
**Arguments:** D1 = command number (0-6)
**Algorithm:** Uses jump table at 0x1258 to map command to control byte:
  - 0→0x40, 1→0x60, 2→0x80, 3→0xC0, 4→0xE0, 5→0x00, 6→0x20
- Writes to hardware register at 0x172E0+0x1F (control B)
- Also writes inverse to 0x172E0+0x1D (control A)
**Hardware:** 0x172E0 is hardware control register base
**Called by:** `process_ati_command` and others

### Function at 0x12AA: `check_hardware_status`
**Purpose:** Checks hardware status register bit 1.
**Return:** D0 = 0 if bit set, 1 if clear (inverted logic)
**Hardware:** Reads 0x172E0+0x1B (status register)

### Function at 0x12C0: `check_scc3_present`
**Purpose:** Tests if third SCC (ATI channel) exists by checking status bit 5.
**Return:** D0 = 0 if present, 1 if absent (inverted logic)
**Hardware:** Reads 0x172E0+0x1B (status register)

### Function at 0x12D6: `assert_reset_line`
**Purpose:** Asserts hardware reset line (control bit 4).
**Hardware:** Writes 0x04 to 0x172E0+0x1F

### Function at 0x12E4: `deassert_reset_line`
**Purpose:** Deasserts hardware reset line.
**Hardware:** Writes 0x04 to 0x172E0+0x1D

### Function at 0x12F2: `set_resolution`
**Purpose:** Sets imagesetter resolution (1200 or 2400 DPI).
**Arguments:** D0 = resolution (1200 or 2400)
**Algorithm:** 1200→write 0x01 to control A, 2400→write 0x01 to control B
**Hardware:** 0x172E0+0x1D/0x1F

### Function at 0x131A: `set_motor_direction`
**Purpose:** Sets motor direction (forward/reverse).
**Arguments:** D1 = direction (1=forward, other=reverse)
**Algorithm:** 1→write 0x02 to control B, other→write 0x02 to control A
**Hardware:** 0x172E0+0x1D/0x1F

### Function at 0x1340: `read_dip_switches`
**Purpose:** Reads DIP switch settings from hardware status register.
**Return:** D0 = DIP switch value (bits 2-4, inverted)
**Algorithm:** Reads 0x172E0+0x1B, shifts right 2, masks with 0x07, inverts
**Hardware:** 0x172E0+0x1B

### Function at 0x1360: `send_string_to_scc`
**Purpose:** Sends a null-terminated string to an SCC channel.
**Arguments:** D2 = SCC base address, A2 = string pointer
**Algorithm:** Calls `scc_send_byte` for each character until null
**Called by:** Debug output functions

### Functions 0x138C-0x141A: Serial I/O wrappers
- `0x138C`: `read_from_scc3` - Reads byte from SCC #3 (ATI channel)
- `0x13B2`: `write_to_scc3` - Writes byte to SCC #3
- `0x13D4`: `read_from_scc2` - Reads byte from SCC (Z8530) (debug console)
- `0x13FA`: `write_to_scc2` - Writes byte to SCC (Z8530)

### Functions 0x141C-0x14E6: Command handlers
These parse decimal arguments and call hardware functions:
- `0x141C`: `cmd_send_hardware` - Reads decimal, calls `send_hardware_command`  (PS dict operator)
- `0x1448`: `cmd_reset_line` - Reads decimal, asserts/deasserts reset
- `0x147A`: `cmd_set_resolution` - Reads 1200/2400, calls `set_resolution`
- `0x14BC`: `cmd_set_motor_dir` - Reads 1/other, calls `set_motor_direction`

### Functions 0x14E8-0x1518: Status display commands
- `0x14E8`: `cmd_show_dip_switches` - Prints DIP switch settings  (PS text operator)
- `0x1500`: `cmd_show_hardware_status` - Prints hardware status bit  (PS text operator)
- `0x1518`: `cmd_show_scc3_status` - Prints if SCC #3 present  (PS text operator)

### Functions 0x1530-0x1692: Serial port loopback tests
- `0x1530`: `test_serial_loopback_1_2` - Tests SCC1↔SCC2 loopback
- `0x15B8`: `test_serial_loopback_1_3` - Tests SCC1↔SCC3 loopback  
- `0x1626`: `test_serial_loopback_2_3` - Tests SCC2↔SCC3 loopback
**Algorithm:** Sends 0x03 (ETX) and checks echo

### Function at 0x1694: `system_init_and_test`
**Purpose:** Main initialization and self-test routine.
- Calls `init_serial_ports`
- Checks if SCC3 present
- If present: sends banner strings, enters command loop (0x2F8A)  (PS dict operator)
- If absent: calls error handler (0x042C)
**Called by:** Boot code

### Functions 0x16D4-0x1802: String utility functions
- `0x16D4`: `strlen` - Standard C strlen
- `0x16E4`: `strcpy` - Standard C strcpy
- `0x16F2`: `strcat` - Standard C strcat
- `0x1708`: `strncpy` - Standard C strncpy
- `0x1728`: `strncat` - Standard C strncat
- `0x1750`: `strchr` - Standard C strchr
- `0x1768`: `strrchr` - Standard C strrchr
- `0x178C`: `strncmp` - Standard C strncmp
- `0x17BE`: `str_to_upper` - Converts string to uppercase
- `0x17E8`: `streq` - String equality check

### Function at 0x1804: `reset_system_state`
**Purpose:** Resets system state variable and calls error handler.
**Hardware:** Clears 0x15112, calls 0x042C

### Function at 0x1812: `init_channel_structures`
**Purpose:** Initializes channel data structures for communication.
- Sets timeout value at 0x153EA to 100000
- Initializes 4 channel structures at 0x15126 and 0x15256 (each 76 bytes)
- Clears various state variables
- Sets default SCC addresses  (PS dict operator)
- Tests if SCC3 present, sets flag at 0x15116
- Prints initialization message
**Called by:** System initialization

1. **0x1000 is NOT "SCSI init"** - It's a decimal string parser
2. **0x1014 is NOT "init_serial_ports"** - That's at 0x1116
3. **0x1116 IS "init_serial_ports"** - Correctly identified
4. **Hardware commands are 0-6** (not 0-7 as previously thought)
5. **Three SCCs exist**: 0x40000 (PS), 0x40010 (debug), 0x50000 (ATI)
6. **Hardware register base is 0x172E0** with offsets:
   - +0x1B: Status register
   - +0x1D: Control A
   - +0x1F: Control B
7. **String utilities start at 0x16D4**, not earlier
8. **Channel structures are 76 bytes each** (not 72)

The code in this range is well-structured C-like 68000 code with clear function boundaries and standard calling conventions.

; === CHUNK 4: 0x01C00-0x02800 ===

1. **0x1c00-0x1c0c** is NOT a function - it's actually the tail end of a function that starts earlier. The code at 0x1c00 is:
   1c00: pea %a0@(12)
   1c04: jsr %pc@(0x1a70)  ; Calls some function
   1c08: addql #4,%sp
   1c0a: moveal %sp@+,%a2
   1c0c: rts
   This is clearly cleanup/return code, not a function entry point.

2. **0x1c0e** is the actual start of a function (has LINK instruction).

### 1. `0x1c0e` - `process_channel_input`
**Entry:** 0x1c0e  
**Purpose:** Main state machine for processing ATI command input from the main board. Reads characters from VIA#1, maintains per-channel state machines (76-byte structures at 0x15126+). Handles command framing with braces `{` and `}`, manages timeouts, and transitions between states (0=idle, 1=error?, 2=receiving command).  
**Returns:** Nothing (updates channel state)  
**Hardware:** Reads from 0x1511a (input buffer pointer), calls 0x1206 (read_char), uses timeout counter at 0x153ea  
**Call targets:** 0x1b4e (get current channel?), 0x1206 (read character), 0x1f88 (increment_and_wrap_counter), 0x1a70 (error logging)  
**Called by:** Likely main loop or interrupt handler

### 2. `0x1d98` - `process_response_input`
**Entry:** 0x1d98  
**Purpose:** State machine for processing typesetter responses. Similar to command processing but for responses coming back from the typesetter hardware. Handles numeric responses in hex, terminated by '!'. States: 0=idle, 3=receiving digits, 4=receiving '!' terminator.  
**Returns:** Nothing (updates response buffer and parsed value)  
**Hardware:** Reads from 0x1511e (response buffer pointer), calls 0x1206 (read_char)  
**Call targets:** 0x1b4e, 0x1206, 0x1fb8 (convert_response_to_binary), 0x1f88  
**Called by:** Likely interrupt handler for response channel

### 3. `0x1f88` - `increment_and_wrap_counter`
**Entry:** 0x1f88  
**Purpose:** Increments a circular buffer index with wrap-around at 4. Used for managing circular buffers in channel structures. Detects buffer full condition (when head == tail).  
**Arguments:** A2 points to counter structure (head index at offset 0, tail at offset 4)  
**Returns:** Updates counter in place, logs error if buffer full  
**Call targets:** 0x1a70 (error logging)  
**Called by:** 0x1c0e, 0x1d98

### 4. `0x1fb8` - `convert_response_to_binary`
**Entry:** 0x1fb8  
**Purpose:** Converts ASCII hex string in channel buffer to binary integer. Validates length (>=3 chars) and range (1-64). Used to parse parameter values from typesetter responses like `{SRE%123!}`.  
**Arguments:** D2 = channel index  
**Returns:** Binary value stored at 0x153e6  
**Hardware:** Accesses channel structures at 0x15256 base  
**Call targets:** 0x1b76 (reset_channel_state?), 0x1a70 (error logging)  
**Called by:** 0x1d98

### 5. `0x20b4` - `format_string_with_padding`
**Entry:** 0x20b4  
**Purpose:** Copies string from source to destination with width padding. If width > 0, pads on right; if width < 0, pads on left. Always pads with spaces.  
**Arguments:** A0=dest, A1=src, D0=width (negative for left padding)  
**Returns:** A0 points to end of formatted string  
**Algorithm:** Copies characters until null or width limit, then fills remaining width with spaces.

### 6. `0x20fc` - `format_number`
**Entry:** 0x20fc  
**Purpose:** Formats integer to ASCII string with specified base, width, and padding character. Handles sign, base conversion (decimal/hex), and left/right padding.  
**Arguments:** A2=dest buffer, D0=value, D2=width, D6=base (10, 16, etc.), stack arg=pad char  
**Returns:** A2 points to end of formatted string  
**Algorithm:** Converts number to string in reverse order, then reverses it. Handles negative numbers with '-' prefix. Supports bases 10 and 16.

### 7. `0x21f2` - `printf`
**Entry:** 0x21f2  
**Purpose:** Formatted output to debug console. Supports %d, %u, %x, %s, %c, %B, %W, %L, %N formats with width and padding options.  
**Arguments:** Format string pointer on stack, variable arguments  
**Returns:** Number of characters written  
**Call targets:** 0x224a (vsprintf), 0x13b2 (putchar)  
**Called by:** Various debug/status output functions

### 8. `0x2206` - `vprintf`
**Entry:** 0x2206  
**Purpose:** Formatted output to debug console with va_list argument.  
**Arguments:** Format string pointer, va_list pointer on stack  
**Returns:** Number of characters written  
**Call targets:** 0x224a (vsprintf), 0x13b2 (putchar)  
**Called by:** printf and other formatted output functions

### 9. `0x224a` - `vsprintf`
**Entry:** 0x224a  
**Purpose:** Format string into buffer. Full printf implementation with width, padding, and format specifiers.  
**Arguments:** A0=dest buffer, A2=format string, A3=va_list pointer  
**Returns:** Number of characters written (excluding null terminator)  
**Algorithm:** Parses format string, processes format specifiers, calls format_number or format_string_with_padding as needed.

### 10. `0x2432` - `char_to_digit`
**Entry:** 0x2432  
**Purpose:** Converts ASCII character to numeric digit value. Supports hex digits (0-9, A-F). Returns -1 for invalid characters, -2 for letters G-Z.  
**Arguments:** Character in low byte of D0  
**Returns:** Digit value (0-15) or error code (-1 or -2)  
**Called by:** 0x2520 (parse_number)

### 11. `0x247a` - `is_valid_digit`
**Entry:** 0x247a  
**Purpose:** Checks if character is a valid digit for number parsing. Accepts 0-9, A-F, '$', '&'.  
**Arguments:** Character in low byte of D0  
**Returns:** 0x6E (110) if valid, character code otherwise  
**Called by:** Number parsing routines

### 12. `0x24b0` - `skip_whitespace`
**Entry:** 0x24b0  
**Purpose:** Advances input pointer past whitespace characters (space and tab).  
**Arguments:** A1 points to input pointer (double indirection)  
**Returns:** First non-whitespace character in D0  
**Called by:** 0x24d6, 0x2520

### 13. `0x24d6` - `read_alnum_string`
**Entry:** 0x24d6  
**Purpose:** Reads alphanumeric string from input. Copies characters until non-alphanumeric encountered.  
**Arguments:** A2=dest buffer, D2=max length  
**Returns:** String copied to buffer, null-terminated  
**Call targets:** 0x24b0 (skip_whitespace)  
**Called by:** Command parsing

### 14. `0x2520` - `parse_number`
**Entry:** 0x2520  
**Purpose:** Parses number from input with optional base prefix ('$' for hex, '&' for decimal).  
**Arguments:** A2=pointer to store result, D2=default base (0 for auto-detect)  
**Returns:** 0 on success, -1 on error  
**Call targets:** 0x24b0 (skip_whitespace), 0x2432 (char_to_digit), 0x3090 (multiply)  
**Algorithm:** Skips whitespace, checks for base prefix, converts digits using specified base.

### 15. `0x25a6` - `read_line_with_editing`
**Entry:** 0x25a6  
**Purpose:** Reads a line from console with full editing support (backspace, cursor movement, history).  
**Arguments:** D2=file descriptor, A2=buffer, D3=buffer size  
**Returns:** Line in buffer  
**Algorithm:** Handles special keys: Backspace (0x08), Enter (0x0D), Escape (0x1B), Ctrl+X (0x18), arrow keys (ESC sequences), printable characters. Maintains history buffer at 0x1544a.

### 16. `0x2410` - `handle_percent_literal`
**Entry:** 0x2410 (within vsprintf)  
**Purpose:** Handles '%%' literal percent in format strings.  
**Arguments:** A0=output pointer  
**Returns:** Updated output pointer  
**Note:** This is not a standalone function but a code path within vsprintf.

### 17. `0x2418` - `handle_unknown_format`
**Entry:** 0x2418 (within vsprintf)  
**Purpose:** Handles unknown format specifiers by outputting '%' followed by the character.  
**Arguments:** A0=output pointer, D1=unknown format char  
**Returns:** Updated output pointer  
**Note:** This is not a standalone function but a code path within vsprintf.

**0x17346-0x17422**: Error and status message strings:
- 0x17346: Likely "Buffer full" or similar error
- 0x17368: Timeout error message  timeout counter
- 0x1737e: Response timeout error
- 0x17392: Circular buffer overflow error
- 0x173ac: Invalid response length error
- 0x173d0: Response out of range error
- 0x173f4: Prompt string (likely "> ")
- 0x173f8: Cursor movement string
- 0x173fc: Backspace with cursor movement
- 0x17400: Backspace without cursor movement
- 0x17406: Delete line/clear
- 0x1740a: Cursor forward
- 0x1740e: History display format
- 0x17418: History display format (different)

**0x1544a**: History buffer for command line editing (10 entries × 20 bytes each = 200 bytes)

The prior analysis mentioned 0x1511a and 0x1511e as buffer pointers - these are actually in RAM, not hardware registers. The actual SCC hardware addresses are at 0x040000 (PS channel) and 0x050000 (ATI channel).

The channel state machines (76 bytes each) contain:
- State (0, 1, 2, 3, 4, 5)
- Buffer indices (head/tail for circular buffer)
- Timeout counter  timeout counter
- Character buffer (likely 64 bytes + null terminator)

States observed:
- 0: Idle/waiting for start
- 1: Error state?
- 2: Receiving command (between '{' and '}')
- 3: Receiving response digits
- 4: Waiting for '!' terminator
- 5: Complete/ready to process

This refined analysis corrects the prior errors and provides complete coverage of all functions in the 0x1c00-0x2800 range.

; === CHUNK 5: 0x02800-0x03152 ===

### 1. `0x2800` - `insert_command_history`
**Entry:** 0x2800  
**Purpose:** Inserts a command string into a circular history buffer of 10 entries (76 bytes each). Uses bubble-sort-like shifting to make room for new entry at position 0.  
**Arguments:** A2 = pointer to null-terminated command string  
**Returns:** A2 preserved  
**Hardware:** Accesses command history array at 0x1544a (10 entries × 76 bytes)  
**Call targets:** 0x17e8 (strcmp), 0x16e4 (strcpy)  
**Called by:** Command processor after successful command execution

### 2. `0x28c0` - `execute_at_address`
**Entry:** 0x28c0  
**Purpose:** Reads a 4-byte hex address from input (16 hex chars), validates it, and executes code at that address via JSR. Used for debugging/jumping to arbitrary code.  
**Returns:** D0 = 0 on success, -1 on error  
**Hardware:** Calls 0x2520 (read_hex_value) to parse address  
**Call targets:** 0x2520, 0x2206 (vprintf_to_buffer)  
**Called by:** Command interpreter (likely via "G" or "GO" command)

### 3. `0x28f6` - `dump_memory_range`
**Entry:** 0x28f6  
**Purpose:** Interactive memory dump utility. Uses globals 0x17528 (start) and 0x1752c (length). Allows user to modify start/length via keyboard input. Displays 16 bytes per line with hex and ASCII.  
**Returns:** D0 = 0 on success, -1 on error  
**Hardware:** Uses 0x24b0 (get_char), 0x2520 (read_hex_value), prints via 0x2206  
**Call targets:** 0x24b0, 0x2520, 0x2206, 0x13b2 (put_char)  
**Called by:** 0x2e86 (conditional_dump) and command interpreter

### 4. `0x2aa8` - `disassemble_one_instruction`
**Entry:** 0x2aa8  
**Purpose:** Simple 68000 disassembler that decodes and prints one instruction. Handles basic instructions (MOVE, ADD, SUB, etc.) and calculates instruction length.  
**Returns:** D0 = 0 on success, -1 on error  
**Hardware:** Uses 0x2520 (read_hex_value), 0x247a (decode_opcode)  
**Call targets:** 0x2520, 0x247a, 0x25a6 (sprintf), 0x17be (strlen)  
**Called by:** Command interpreter (likely "D" or "DIS" command)

### 5. `0x2c6c` - `validate_srecord_checksums`
**Entry:** 0x2c6c  
**Purpose:** Parses Motorola S-records (S1-S9) from input, validates checksums, and loads data into memory. Format: "S3xxxxyyzz" where xxxx=address, yy=byte count, zz=checksum.  
**Returns:** D0 = 0 always  
**Hardware:** Uses 0x2206 (vprintf), 0x138c (get_char), 0x2432 (hex_char_to_value)  
**Call targets:** 0x2206, 0x138c, 0x2432  
**Called by:** Command interpreter (likely "S" or "LOAD" command)

### 6. `0x2e86` - `conditional_dump_if_enabled`
**Entry:** 0x2e86  
**Purpose:** Checks if command processing is enabled (0x17524 = 1) and if so, calls dump_memory_range. Used for automatic memory dumps during debugging.  
**Returns:** D0 = 0  
**Hardware:** Checks 0x17524 flag  
**Call targets:** 0x28f6 (dump_memory_range)  
**Called by:** Main loop or interrupt handler

### 7. `0x2e98` - `execute_command_from_buffer`
**Entry:** 0x2e98  
**Purpose:** Parses and executes a command from the input buffer. Searches command table (0x17644) for matching command name and calls its handler.  
**Arguments:** FP@(8) = pointer to command string  
**Returns:** D0 = 0 on success  
**Hardware:** Uses command table at 0x17644 (magic 0xBAFBAF11)  
**Call targets:** 0x17be (strlen), 0x24b0 (get_char), 0x24d6 (read_string), 0x17e8 (strcmp), 0x2206 (vprintf)  
**Called by:** Main command loop (0x2f8a)

### 8. `0x2f8a` - `main_command_loop`
**Entry:** 0x2f8a  
**Purpose:** Main interactive command loop. Initializes command history buffer, prints prompt, reads input, and executes commands.  
**Returns:** Never returns (infinite loop)  
**Hardware:** Uses command history buffer at 0x1544a  
**Call targets:** 0x25a6 (sprintf), 0x2e98 (execute_command_from_buffer)  
**Called by:** System initialization

### 9. `0x2fd0` - `signed_divide`
**Entry:** 0x2fd0  
**Purpose:** Performs 32-bit signed integer division (D0 ÷ D1). Handles negative numbers and returns quotient in D0.  
**Arguments:** D0 = dividend, D1 = divisor  
**Returns:** D0 = quotient  
**Called by:** Various math operations

### 10. `0x302e` - `signed_modulus`
**Entry:** 0x302e  
**Purpose:** Performs 32-bit signed integer modulus (D0 % D1). Handles negative numbers and returns remainder in D0.  
**Arguments:** D0 = dividend, D1 = divisor  
**Returns:** D0 = remainder  
**Called by:** Various math operations

### 11. `0x3090` - `signed_multiply`
**Entry:** 0x3090  
**Purpose:** Performs 32-bit signed integer multiplication (D0 × D1). Uses 16×16 multiply with carry propagation.  
**Arguments:** D0 = multiplicand, D1 = multiplier  
**Returns:** D0 = product  
**Called by:** Various math operations

### 12. `0x30bc` - `copy_memory_block`
**Entry:** 0x30bc  
**Purpose:** Copies a block of memory from one location to another. Wrapper function that sets up parameters for the actual copy routine.  
**Call targets:** 0x30da (actual copy routine)  
**Called by:** System initialization

### 13. `0x30da` - `memory_copy`
**Entry:** 0x30da  
**Purpose:** Actual memory copy routine. Copies D1 bytes from A1 to A0.  
**Arguments:** A0 = destination, A1 = source, D1 = byte count  
**Called by:** 0x30bc (copy_memory_block)

### 14. `0x30f2` - `unsigned_divide_or_modulus`
**Entry:** 0x30f2  
**Purpose:** Performs 32-bit unsigned integer division or modulus based on A0 flag. If A0=0, returns quotient; if A0=1, returns remainder.  
**Arguments:** D0 = dividend, D1 = divisor, A0 = mode flag (0=divide, 1=modulus)  
**Returns:** D0 = result (quotient or remainder)  
**Called by:** Various math operations

- **0x17422-0x1742a**: String literals for command history function
- **0x1742c**: Format string for execute_at_address ("Executing at %08X")
- **0x17434-0x17460**: Format strings for memory dump (address lines, hex bytes, ASCII)
- **0x17462-0x17492**: Format strings for disassembler (address, opcode, mnemonic)
- **0x174b4-0x174c4**: Format strings for S-record loader ("Loading S-records...", "Loaded %d bytes at %08X to %08X")
- **0x174ec-0x1751c**: Error and help strings for command interpreter

1. This region contains the **debug monitor command interpreter** for the IO board.
2. The command table at 0x17644 uses magic value 0xBAFBAF11 to identify valid command entries.
3. The system supports Motorola S-record loading for firmware updates.
4. There's a built-in 68000 disassembler for debugging.
5. Math functions handle both signed and unsigned operations with proper error checking.
6. The main command loop (0x2f8a) never returns, forming the core of the debug monitor.

## CORRECTIONS FROM PRIOR ANALYSIS:
- 0x2800 is NOT `sort_strings` - it's `insert_command_history`
- 0x2c6c is NOT `checksum_memory` - it's `validate_srecord_checksums`
- 0x2e86 is NOT `command_dispatcher` - it's `conditional_dump_if_enabled`
- Added missing math functions at 0x2fd0-0x3152
- All functions now have accurate descriptions based on actual disassembly

; === CHUNK 6: 0x0F000-0x0F648 ===

### 1. ATI Command Strings (0xF000-0xF11A) - **PARTIALLY CORRECT**
**Address:** 0xF000-0xF11A  
**Purpose:** Mixed ATI command strings and format strings with 0xFF terminators.

- 0xF000: "SS" followed by 0xFF - likely a short command
- 0xF01C: "{SRE%}" - ATI command for Set Raster Engine with parameter
- 0xF034: "{SRC$}" - ATI command for Set Raster something
- 0xF058: "{SRSP}" - ATI command
- 0xF066: "{SRGP}" - ATI command
- 0xF074: "%0d+" - Format string for decimal numbers with plus sign
- 0xF07E: "+normal" - Status indicator (correct)
- 0xF08C: "+inverse" - Status indicator (correct)
- 0xF0D0: "+idle" - Status indicator (correct)
- 0xF0DA: "+imaging" - Status indicator (correct)
- 0xF0E8: "+booting" - Status indicator (correct)
- 0xF0F2: "+boot failed" - Error status (correct)
- 0xF108: "+SIGSet" - Signal set indicator (correct)
- 0xF112: "{R" - Incomplete ATI command (likely "{RESET}" or similar)

### 2. Error Messages (0xF11A-0xF3D0) - **CORRECTED**
**Address:** 0xF11A-0xF3D0  
**Purpose:** Human-readable error messages for debugging and status reporting.

- 0xF11A: "ATIacti - Unknown device" - Actually reads as "ATIacti - Unknown device" (not "ATIacti")
- 0xF130: "ERROR DN compl. code = %c" - Densitometer completion code error
- 0xF148: "SH timed out" - Shutter timeout
- 0xF158: "PA timed out" - Paper Advance timeout
- 0xF166: "ERROR PA compl. code = %c" - Paper Advance completion code error
- 0xF17E: "{SR%}" - Partial ATI command string (NOT an error message)
- 0xF194: "Illegal msg : %s" - Invalid message format
- 0xF2B2: "Hello, this is the debug port" - Debug port greeting
- 0xF2E0: "Agfa T9000PS ATI v%2.2" - Actually "Agfa T9000PS ATI v%2.2" (not "Agfa T9000PS ATI v%2.2")
- 0xF300: "ERROR: illegal scanSwitch parameter" - Invalid scan switch parameter
- 0xF326: "UNLOCK-ERROR : too many unlocks" - Buffer unlock error
- 0xF346: "APIS-ERROR : illegal buffer flags" - API synchronization error
- 0xF368: "APIS-ERROR : timeout" - API timeout
- 0xF37E: "ATP-ERROR : timeout" - ATI protocol timeout
- 0xF392: "SCAN-ERROR : buffer full" - Scan buffer overflow
- 0xF3AC: "ATP-ERROR : illegal count received" - Invalid count in ATI protocol
- 0xF3D0: "ATP-ERROR : received count too big" - Count exceeds maximum

### 3. Command Response Jump Table (0xF1AC-0xF1E4) - **CORRECTED**
**Address:** 0xF1AC-0xF1E4  
**Size:** 15 entries × 4 bytes = 60 bytes (not 16 entries)  
**Format:** 32-bit pointers to response string addresses in RAM (0x17000-0x18000 range)

- 0x000171E8, 0x000171EE, 0x000171F4, 0x000171FA
- 0x00017200, 0x00017206, 0x0001720C, 0x00017212
- 0x00017218, 0x0001721E, 0x00017224, 0x0001722A
- 0x00017230, 0x00017236, 0x0001723C

### 4. ATI Response Strings (0xF1E8-0xF242) - **CORRECTED**
**Address:** 0xF1E8-0xF242  
**Purpose:** ATI response codes that are COPIED to RAM at boot time.

- 0xF1E8: "!STA" (START acknowledgement)
- 0xF1EE: "!L&S" (Load & Start)
- 0xF1F4: "!BEG" (BEGIN)
- 0xF1FA: "!END" (END)
- 0xF200: "!PWR" (POWER)
- 0xF206: "_GST" (GET STATUS)
- 0xF20C: "_CMD" (COMMAND)
- 0xF212: "_INF" (INFO)
- 0xF218: "_SET" (SET)
- 0xF21E: "_GET" (GET)
- 0xF224: "_MOD" (MODE)
- 0xF22A: "_NEG" (NEGATIVE)
- 0xF230: "_POS" (POSITIVE)
- 0xF236: "_GPR" (GET PARAMETER)
- 0xF23C: "_RES" (RESET)

### 5. Device Subsystem Table (0xF242-0xF268) - **NEW**
**Address:** 0xF242-0xF268  
**Size:** 5 entries × 4 bytes = 20 bytes  
**Format:** 32-bit pointers to device subsystem names in RAM

- 0x00017256, 0x0001725A, 0x0001725E, 0x00017262, 0x00017266

- 0xF256: "RE" (Raster Engine)
- 0xF25A: "PA" (Paper Advance)
- 0xF25E: "DN" (Densitometer)
- 0xF262: "MG" (Motor/Gantry)
- 0xF266: "SH" (Shutter)

### 6. Format Strings and Debug Messages (0xF268-0xF3F4) - **CORRECTED**
**Address:** 0xF268-0xF3F4  
**Purpose:** Various format strings for debugging and status display.

- 0xF26A: "Mode = $%02x" - Mode display format
- 0xF276: "Reset button = %d" - Reset button status
- 0xF28C: "Debug = %d" - Debug mode status
- 0xF298: "Hello, this is the debug port" - Debug port greeting (correct)
- 0xF2BC: "type ATI for normal operation" - User instruction
- 0xF2E0: "Agfa T9000PS ATI v%2.2" - Version string (correct)
- 0xF300: "ERROR: illegal scanSwitch parameter" - Scan switch error

### 7. Command Table (0xF534-0xF648) - **CORRECTED**
**Address:** 0xF534-0xF648  
**Size:** 16 entries × 12 bytes = 192 bytes  
**Format:** Each entry: [magic(4)][handler_addr(4)][command_name(4)]

1. 0xF534: Magic=0xBAFBAF11, Handler=0x141C, Name="LED"
2. 0xF540: Magic=0xBAFBAF11, Handler=0x1448, Name="VIDEO"
3. 0xF54C: Magic=0xBAFBAF11, Handler=0x147A, Name="RESOL"
4. 0xF558: Magic=0xBAFBAF11, Handler=0x14BC, Name="INVERS"
5. 0xF564: Magic=0xBAFBAF11, Handler=0x14E8, Name="MODE"
6. 0xF570: Magic=0xBAFBAF11, Handler=0x1500, Name="RESET"
7. 0xF57C: Magic=0xBAFBAF11, Handler=0x1518, Name="DEBUG"
8. 0xF588: Magic=0xBAFBAF11, Handler=0x1530, Name="TMD"
9. 0xF594: Magic=0xBAFBAF11, Handler=0x15B8, Name="TMD1"
10. 0xF5A0: Magic=0xBAFBAF11, Handler=0x1626, Name="TMD2"
11. 0xF5AC: Magic=0xBAFBAF11, Handler=0x042C, Name="ATI"
12. 0xF5B8: Magic=0xBAFBAF11, Handler=0x28C0, Name="GO"
13. 0xF5C4: Magic=0xBAFBAF11, Handler=0x28F6, Name="MD"
14. 0xF5D0: Magic=0xBAFBAF11, Handler=0x2AA8, Name="MM"
15. 0xF5DC: Magic=0xBAFBAF11, Handler=0x2C6C, Name="LO"
16. 0xF5E8: Magic=0xBAFBAF11, Handler=0x2E86, Name=""

### 8. Miscellaneous Data (0xF3F4-0xF534) - **NEW**
**Address:** 0xF3F4-0xF534  
**Purpose:** Various format strings and data constants.

- 0xF3F4: "%s" - Simple string format
- 0xF3F8: "[@ " - Console prompt prefix
- 0xF3FC: "[P " - Another prompt variant
- 0xF400: "[D " - Debug prompt
- 0xF406: "[C " - Command prompt
- 0xF40E: "[K%s]" - Keyboard input format
- 0xF418: "[K%s]" - Another keyboard format
- 0xF422: "[K%s]" - Yet another keyboard format
- 0xF42C: "GO %L" - Go command format
- 0xF432: "Memory dump from %L to %L" - Memory dump format
- 0xF44E: "%L %B" - Address and byte format
- 0xF460: "Memory modify at %L" - Memory modify prompt
- 0xF478: "%L %B?" - Address and byte query
- 0xF482: "Invalid number" - Error message
- 0xF48E: "Invalid command '%s'" - Command error
- 0xF4B4: "Load S-record %s" - S-record load message
- 0xF4C6: "Start address = %L (low=%L high=%L)" - Start address format
- 0xF4EE: "Syntax error" - Parser error
- 0xF4F8: "Unknown command '%s'" - Unknown command error

1. **0xF000-0xF11A**: Not just ATI commands - mixed with format strings and status indicators
2. **0xF1AC-0xF1E4**: Jump table points to RAM addresses (0x171E8-0x1723C), not ROM
3. **0xF1E8-0xF242**: Response strings in ROM that get copied to RAM
4. **0xF242-0xF268**: New device subsystem table (5 entries)
5. **0xF534-0xF648**: Command table for debug monitor, not general ATI commands

The region 0xF000-0xF648 is primarily **DATA**, not code. It contains:
- ATI command and response strings
- Error messages and format strings
- Jump tables for command dispatch
- Device subsystem names
- Debug monitor command table

All of this data is used by the IO board firmware for ATI protocol communication, error reporting, and debug monitor functionality.