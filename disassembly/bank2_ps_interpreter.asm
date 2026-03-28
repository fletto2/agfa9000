; ======================================================================
; AGFA COMPUGRAPHIC 9000PS - BANK2 ANNOTATED DISASSEMBLY
; ======================================================================
; PostScript interpreter: serial I/O, PS core, graphics, fonts, raster
; ROM addresses: 0x40000 - 0x5FFFF
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

; === CHUNK 1: 0x40000-0x40C00 ===

**0x40000-0x401E3: JUMP TABLE FOR POSTSCRIPT OPERATOR DISPATCH**
- This is NOT code but a jump table with 32-bit function pointers
- Contains pointers to PostScript operator handlers (e.g., 0x0003f230, 0x0003f23e)
- Likely used by the operator dispatcher at 0x46000
- Size: 0x1E4 bytes (484 bytes, ~121 entries)

**0x401F4-0x40203: STRING LITERALS**
0x401f4: "Serial\0Serial\0"
Two copies of "Serial" with null terminators
### FUNCTIONS:

**1. 0x40204-0x4024E: `get_serial_port_info`**
- Purpose: Retrieves serial port configuration information for a given port number. Accesses serial port configuration tables at 0x2000860 and 0x2000878. Validates port number is < 3.
- Arguments: D0 = port number (via stack at fp@(8)), A0 = output struct 1 (fp@(12)), A1 = output struct 2 (fp@(16))  stack frame parameter
- Return: Void, fills output structures  (PS paint operator)
- Hardware/RAM: 0x2000860 (serial port base addresses), 0x2000878 (serial port buffer sizes)  (register = size parameter)
- Calls: Error handler at 0x46334 if port >= 3
- Called by: Unknown (likely serial initialization code)

**2. 0x40250-0x40256: EMPTY STUB FUNCTION**
- Just LINK/UNLK/RTS - likely a placeholder for future development

**3. 0x40258-0x402F0: `init_serial_buffers`**
- Purpose: Allocates and initializes memory buffers for 3 serial ports (256 bytes each). Sets up serial port structures at 0x2000860-0x200087c.
- Hardware/RAM: 0x2017410 (memory size?), 0x2017414 (buffer pointer), 0x2000860-0x200087c (serial port structures)  (register = size parameter)
- Calls: malloc-like function at 0x4d98c, error handler at 0x46334
**4. 0x402F2-0x4034A: `serial_receive_handler` (SCC RX ISR)**
- Purpose: Handles SCC receive interrupts. Reads data from SCC, processes through state machine with jump table. Manages receive buffers.
- Arguments: Implicit via global pointers (SCC device structures at 0x2017400, 0x20173f8, 0x20173fc)
- Return: Status in D0
- Hardware/RAM: SCC hardware via pointers, 0x2017400 (VIA#1), 0x20173f8 (SCC), 0x20173fc (debug SCC)
- Calls: Handler functions via function pointer table in device struct
- Called by: SCC interrupt service routine

**5. 0x40352-0x403AA: `serial_transmit_handler` (SCC TX ISR)**
- Purpose: Handles SCC transmit interrupts. Manages transmit buffer, writes data to SCC data register.
- Arguments: Implicit via global pointers
- Return: Status in D0
- Hardware/RAM: Same SCC pointers as receive handler
- Calls: Handler functions via function pointer table
- Called by: SCC interrupt service routine

**6. 0x403AC-0x4042A: `serial_getc`**
- Purpose: Reads a byte from serial receive buffer. Uses translation table for character processing. Calls refill function when buffer empty.  (PS paint operator)
- Arguments: Implicit via global pointers (device selection)
- Return: Character in D0
- Hardware/RAM: SCC device structures, translation table at offset 0x14  struct field
- Calls: Refill function at offset 0x24 in device struct  (PS paint operator)
- Called by: Serial input routines

**7. 0x4042C-0x4043A: `serial_check_status`**
- Purpose: Checks SCC status register bit 2 (likely "receive buffer full" or similar).
- Arguments: A0 = device pointer (via stack at sp@(4))
- Return: Returns if bit not set (non-blocking check)
- Hardware/RAM: SCC status register at offset 0x3c in device struct  struct field
- Called by: Serial polling routines

**8. 0x4043C-0x4045A: `serial_emergency_reset`**
- Purpose: Emergency reset of SCC. Sends 0x10 to SCC command register (reset command). Calls error handler.  (PS dict operator)
- Arguments: None (uses global pointers)
- Hardware/RAM: 0x20173fc (debug SCC), 0x20173f8 (SCC)
- Calls: Function at offset 0x2c in device struct (error handler)  struct field
- Called by: System panic/failure routines

**9. 0x4045C-0x40486: `serial_write_buffer`**
- Purpose: Writes a buffer of data to SCC with interrupts disabled (SR=0x2600). Uses DMA-like transfer with busy-wait loops.
- Arguments: A0 = device pointer (sp@(4)), A1 = data buffer (sp@(8)), D0 = count (sp@(12))
- Hardware/RAM: SCC data register at offset 0x40 in device struct  struct field
- Called by: Serial output routines

**10. 0x40488-0x404A6: `serial_write_byte`**
- Purpose: Writes a single byte to SCC with interrupts disabled (SR=0x2600). Returns status register value.
- Arguments: A0 = device pointer (sp@(4)), D0 = byte to write (sp@(8))
- Return: SCC status in D0
- Hardware/RAM: SCC data register at offset 0x40, status register at offset 0x3c  struct field
- Called by: Serial output routines

**11. 0x404A8-0x404AC: `enable_interrupts`**
- Purpose: Sets SR to 0x2600 (enables interrupts at IPL 6).
- Called by: Various system functions

**12. 0x404AE-0x404B2: `disable_interrupts`**
- Purpose: Sets SR to 0x2000 (disables interrupts at IPL 0).
- Called by: Various system functions

**13. 0x404B4-0x404D0: `serial_is_debug_port`**
- Purpose: Checks if a given device pointer is the debug SCC port (0x20173fc). Returns true if not debug port or if debug port is ready.
- Arguments: A0 = device pointer (sp@(4))
- Return: Boolean in D0 (0=false, 1=true)
- Hardware/RAM: 0x20173fc (debug SCC)
- Called by: Serial output routines

**14. 0x404D2-0x40506: `serial_send_command`**
- Purpose: Sends a command packet to SCC. Formats command with header byte and optional high bit set. Uses `serial_write_buffer`.  (PS dict operator)  (Atlas monitor command dispatch)
- Arguments: A0 = device pointer (sp@(4)), D0 = command byte (sp@(8)), A1 = data buffer (sp@(12)), D1 = data length (sp@(16))
- Hardware/RAM: Command buffer at sp@(4)
- Calls: `serial_write_buffer` at 0x45c
- Called by: Serial command routines

**15. 0x40508-0x405B0: `postscript_init`**
- Purpose: Main PostScript interpreter initialization. Sets up memory, calls various subsystem initializers, installs interrupt handlers.
- Hardware/RAM: Multiple global addresses: 0x2000420-0x20223f0 (memory range), 0x200000c (RAM top), 0x2000890 (interrupt vector)
- Calls: Functions at 0x3bc8a, 0x90100, 0x8de50, 0x8e000, 0x898b8, 0x84c70, 0x812b4, 0x410c8, 0x81156
- Called by: System boot

**16. 0x405B2-0x405B6: `enable_interrupts_high`**
- Purpose: Sets SR to 0x2600 (same as 0x404A8).

**17. 0x405B8-0x405C0: `jump_to_interrupt_handler`**
- Purpose: Jumps to interrupt handler stored at 0x2000890.
- Return: Never returns (jumps)
- Hardware/RAM: 0x2000890 (interrupt vector)
- Called by: Interrupt dispatcher

**18. 0x405C2-0x405CE: `set_interrupt_handler`**
- Purpose: Sets interrupt handler at 0x2000890, returns previous handler.
- Arguments: D0 = new handler address (sp@(4))
- Return: Previous handler in D0
- Hardware/RAM: 0x2000890 (interrupt vector)
- Called by: System configuration

**19. 0x405D0-0x405D2: EMPTY STUB**
- Just RTS

**20. 0x405D4-0x405F0: `get_current_time`**
- Purpose: Retrieves current time from system clock structure at 0x2017464.
- Return: Time value in D0
- Hardware/RAM: 0x2017464 (system time structure)
- Calls: Function at 0x1be24
- Called by: Time-related functions

**21. 0x405F2-0x40626: `get_system_info`**
- Purpose: Retrieves system information (likely memory or configuration) from 0x2017464.
- Return: Pointer to info in D0 (0x20008b4)
- Hardware/RAM: 0x2017464 (system info), 0x20008b4 (output buffer)
- Calls: Function at 0x1554a
- Called by: System info routines

**22. 0x40628-0x4065C: `set_system_parameter`**
- Purpose: Sets system parameters (6 arguments). Passes to function at 0x1af1a.
- Arguments: 6 parameters on stack (fp@(8) to fp@(28))  stack frame parameter
- Return: Result from called function in D0
- Calls: Function at 0x1af1a
- Called by: System configuration

**23. 0x4065E-0x4067E: `get_font_dict_info`**
- Purpose: Retrieves font dictionary information from 0x2017354.
- Return: Pointer to info in D0 (0x20008bc)
- Hardware/RAM: 0x2017354 (font dictionary), 0x20008bc (output buffer)
- Called by: Font system

**24. 0x40680-0x406BE: `lookup_font_by_id`**
- Purpose: Looks up font by ID in font table. Checks cache first, then calls lookup function.
- Arguments: D0 = font ID (fp@(8)), D1 = unknown (fp@(12))  stack frame parameter
- Return: Font pointer in D0
- Hardware/RAM: 0x2017468 (font ID table), 0x2017428 (font pointer table)
- Calls: Function at 0x3862c if not in cache
- Called by: Font rendering  (PS dict operator)

**25. 0x406C0-0x406E0: `get_font_metrics`**
- Purpose: Retrieves font metrics from font structure at 0x2017354.
- Return: Pointer to metrics in D0 (0x20008c4)
- Hardware/RAM: 0x2017354 (font structure), 0x20008c4 (output buffer)
- Called by: Font rendering  (PS dict operator)

**26. 0x406E2-0x40702: `get_glyph_info`**
- Purpose: Retrieves glyph information from font structure at 0x2017354.
- Return: Pointer to info in D0 (0x20008cc)
- Hardware/RAM: 0x2017354 (font structure), 0x20008cc (output buffer)
- Called by: Glyph rendering  (PS dict operator)

**27. 0x40704-0x40728: `set_font_parameter`**
- Purpose: Sets font parameter (2 arguments). Passes to function at 0x1ae48.
- Arguments: D0 = param1 (fp@(8)), D1 = param2 (fp@(12))  stack frame parameter
- Return: Result from called function in D0
- Calls: Function at 0x1ae48
- Called by: Font configuration

**28. 0x4072A-0x40764: `validate_object`**
- Purpose: Validates an object (likely PostScript object). Calls validation function, returns error if invalid.
- Arguments: D0 = object pointer (fp@(8)), D1 = type (fp@(12))  stack frame parameter
- Return: Validated object pointer in D0
- Calls: Functions at 0x30100 (validate), 0x4640e (error)
- Called by: Object management

**29. 0x40766-0x4078A: `delete_object`**
- Purpose: Deletes an object. Passes to function at 0x1ad74.
- Arguments: D0 = object pointer (fp@(8)), D1 = flags (fp@(12))  stack frame parameter
- Return: Result from called function in D0
- Calls: Function at 0x1ad74
- Called by: Memory management

**30. 0x4078C-0x407C8: `check_system_state`**
- Purpose: Checks system state byte. Must have low nibble = 3, otherwise calls error.
- Return: State pointer in D0 (0x20008dc)
- Calls: Function at 0x365f8 (get state), 0x463d6 (error)
- Called by: System state checks

**31. 0x407CA-0x407F4: `get_string_char`**
- Purpose: Gets character from string with bounds checking.
- Arguments: A0 = string pointer (fp@(8)), D0 = string length (fp@(10)), D1 = index (fp@(18))  stack frame parameter
- Return: Character in D0
- Calls: Error at 0x463ba if index out of bounds
- Called by: String processing

**32. 0x407F6-0x4082E: `set_string_char`**
- Purpose: Sets character in string with bounds checking.
- Arguments: A0 = string pointer (fp@(8)), D0 = string length (fp@(10)), D1 = index (fp@(18)), D2 = character (fp@(23))  stack frame parameter
- Calls: Error at 0x463ba if index out of bounds, function at 0x473da
- Called by: String manipulation

**33. 0x40830-0x40856: `convert_object`**
- Purpose: Converts object between types. Calls conversion functions.
- Arguments: D0 = object pointer (fp@(8))  stack frame parameter
- Return: Converted object in D0
- Calls: Functions at 0x34096 (convert), 0x30f8c (type check)
- Called by: Type conversion routines

**34. 0x40858-0x40862: `return_second_arg`**
- Purpose: Simply returns the second argument (D0 = fp@(12)).  stack frame parameter
- Arguments: D0 = ignored (fp@(8)), D1 = return value (fp@(12))  stack frame parameter
- Return: D1 in D0
- Called by: Various (utility)

**35. 0x40864-0x40870: `trigger_error`**
- Purpose: Calls error handler at 0x4640e.
- Return: Never returns (error)
- Calls: Function at 0x4640e
- Called by: Error conditions

**36. 0x40872-0x408FA: `validate_executable_format`**
- Purpose: Validates executable file format (checks magic number 0x3399, header fields).
- Arguments: A0 = executable pointer (fp@(8))  stack frame parameter
- Return: Boolean in D0 (0=invalid, 1=valid)
- Algorithm: Checks magic=0x3399, header size=4, version=6, validates offsets and checksum  struct field  (register = size parameter)
- Called by: Executable loader

**37. 0x408FC-0x4094A: `relocate_executable`**
- Purpose: Relocates executable by adding base address to relocation entries.
- Arguments: A0 = executable pointer (fp@(8)), D0 = relocation delta (fp@(12))  stack frame parameter
- Algorithm: Processes relocation table, adds delta to each entry
- Called by: Executable loader

**38. 0x4094C-0x40966: `call_function_pair`**
- Purpose: Calls a function with two arguments from global table.
- Return: Result from called function in D0
- Hardware/RAM: 0x2000928-0x200092c (function pointer pair)
- Calls: Function at 0x30f8c
**39. 0x40968-0x40A4C: `load_and_relocate`**
- Purpose: Main executable loader. Validates format, checks CPU state, relocates, calls entry point.
- Arguments: None (or implicit)
- Return: Never returns (jumps to loaded code)
- Algorithm: Gets load address, validates format, checks CPU in supervisor mode, aligns if odd, relocates, calls entry
- Calls: Functions at 0x385c6, 0x39270, 0x3b9b4, 0x4dcf8, 0x40872 (validate), 0x408fc (relocate)
- Called by: System boot

**40. 0x40A4E-0x40AE0: `initialize_runtime`**
- Purpose: Initializes C runtime environment. Sets up jump table, loads executables.
- Arguments: D0 = entry point selector (fp@(8))  stack frame parameter
- Return: Depends on entry point  (PS dict operator)
- Hardware/RAM: 0x40dac (runtime table), 0x20008e4 (jump table)
- Algorithm: Sets up runtime table, attempts to load executable at 0x90000, calls entry
- Calls: 0x40872 (validate), loaded executable entry point
**0x40AE0-0x40C00: DATA - RUNTIME JUMP TABLE**
- Table of function pointers for C runtime
- Contains pointers to various system functions (malloc, free, I/O, etc.)
- Used by initialized runtime at 0x40A4E

2. **Function names were inaccurate** - Many functions were misnamed (e.g., "serial_receive_handler" instead of correct "serial_getc").

4. **Data/code confusion** - The region 0x40AE0-0x40C00 is a jump table, not code.

1. This region contains **serial I/O drivers** for the Zilog 8530 SCC chips.
2. It includes the **main PostScript interpreter initialization** at 0x40508.
3. There's a **sophisticated executable loader** at 0x40968 that validates and relocates code.
4. The **C runtime initialization** at 0x40A4E sets up function pointers for the rest of the system.
5. Many functions are **wrappers or thunks** that call into deeper system functions (bank 2-4 code).

The code follows standard C calling convention with frame pointers (LINK/UNLK), consistent with Sun C compiler output.

; === CHUNK 2: 0x40C00-0x41800 ===

### 0x40C00-0x40DAC: Function pointer table (likely PostScript operator dispatch)
- Contains 32-bit addresses pointing to various functions
- Values like 0x0007b8a4, 0x0007b7f6, etc. (these are in the 0x7xxxx range, not 0x3xxxx as previously stated)
- This appears to be a continuation of the operator dispatch table from earlier

### 1. 0x40DB0-0x40DEE: `check_ps_context_magic` or similar
- Entry: 0x40DB0
- Purpose: Validates the PostScript execution context by checking for magic value 'A' (0x41) at offset 4  struct field
- Arguments: None (uses global pointer at 0x2017354)
- Hardware/RAM: Accesses 0x2017354 (PS execution context pointer)
- Calls: 0x47066, 0x46334 (error handler), 0x4708a
- Called by: 0x40E36 (main entry)

### 2. 0x40DF0-0x40DF8: `always_return_true` (stub)
- Entry: 0x40DF0
- Purpose: Always returns 1 (true)
- Return value: D0 = 1
- Hardware/RAM: None
- Called by: 0x40DFA

### 3. 0x40DFA-0x40E34: `init_something_or_check` (unclear)
- Entry: 0x40DFA
- Purpose: Calls 0x40DF0, then if true, calls malloc (0x48078) and other initialization functions
- Return value: D0 = 0
- Hardware/RAM: Accesses 0x20173b8
- Calls: 0x40DF0, 0x48078 (malloc), 0x4dcf8, 0x40DB0
### 4. 0x40E36-0x40F6C: `postscript_main` or `ps_interpreter_entry`
- Entry: 0x40E36 (MAIN ENTRY POINT)
- Purpose: Main PostScript interpreter initialization and entry point
- Arguments: D0, D1 (passed from caller at 0x410C8)
- Return value: D0 = 0
  - Calls malloc-like functions: 0x4d95a, 0x4dee8, 0x4dafa
  - Sets up global pointers: 0x20174b0, 0x2017420, 0x201741c
  - Initializes buffers: 0x4849e, 0x4dc44
  - Sets up execution context stack: 0x20008f4
  - Calls initialization routines: 0x1624, 0x3652c (delay/timer), 0x46698
  - Sets up serial ports: 0x30350
- Calls: Many functions including 0x4d95a, 0x4dee8, 0x4dafa, 0x4849e, 0x4dc44, 0x4df1c, 0x1624, 0x3652c, 0x46698, 0x30350, 0x40F6E (error handler)
- Called by: 0x410C8

### 5. 0x40F6E-0x41064: `handle_postscript_error` or `ps_error_handler`
- Entry: 0x40F6E
- Purpose: Handles PostScript errors with different error codes (-6, -4, -2)
- Arguments: D0 = error code at fp@(8), A0 = error string at fp@(12)  stack frame parameter
  - Accesses 0x20008fc (execution context)
  - Checks 0x20174a8 (status flags)
  - Uses 0x20174ac (error context)
  - Checks 0x2000a08 (system flags)
- Calls: 0x31dbe, 0x4d8d8, 0x488c0, 0x31ddc, 0x31334, 0x410E4
- Called by: 0x40E36, 0x41066

### 6. 0x41066-0x410C6: `postscript_cleanup_or_exit`
- Entry: 0x41066
- Purpose: Cleanup or exit routine for PostScript interpreter
  - Accesses string at 0x41410
  - Checks 0x2000a04, 0x2000a00
- Calls: 0x4df80, 0x31334, 0x31dbe, 0x40F6E, 0x410E4
- Called by: 0x410C8

### 7. 0x410C8-0x410E2: `postscript_entry_wrapper`
- Entry: 0x410C8
- Purpose: Wrapper that calls main entry (0x40E36) then cleanup (0x41066)
- Arguments: D0, D1 from stack (fp@(8), fp@(12))  stack frame parameter
- Calls: 0x40E36, 0x41066
- Called by: External (likely monitor or boot code)

### 8. 0x410E4-0x4110A: `postscript_state_machine` or `ps_state_handler`
- Entry: 0x410E4
- Purpose: Main PostScript state machine handler
- Arguments: D0 = state code at fp@(8)  stack frame parameter
- Hardware/RAM: Accesses 0x20174b8 (state variable)
- Calls: 0x1480, 0x3877a, 0x41156
- Called by: 0x40F6E, 0x41066, 0x4110C, 0x4112C

### 9. 0x4110C-0x41132: `check_and_handle_system_flag`
- Entry: 0x4110C
- Purpose: Checks system flag at 0x20008f8 and handles it if set
- Hardware/RAM: Accesses 0x20008f8 (system flag)
- Calls: 0x4d8d8, 0x410E4
### 10. 0x41134-0x41148: `align_to_word_boundary`
- Entry: 0x41134
- Purpose: Aligns a value to word boundary (adds 3, masks to 4-byte boundary)
- Arguments: D0 = input value at fp@(8)  stack frame parameter
- Return value: D0 = aligned value
- Algorithm: (value + 3) & ~3
- Hardware/RAM: None
### 11. 0x4114A-0x41150: `empty_function` (stub)
- Entry: 0x4114A
- Hardware/RAM: None
### 12. 0x41152-0x411B4: `ps_state_machine_dispatcher`
- Entry: 0x41152 (actually 0x41156 is the real entry, 0x41152-0x41154 is padding)
- Purpose: Dispatches based on state code (0, 1, 2)
- Arguments: D0 = state code at fp@(8)  stack frame parameter
  - For state 0: Allocates 0x50 bytes, sets 0x2017354, clears 0x20174b8
  - For state 1: Calls 0x46a20, 0x469fa
  - For state 2: Calls 0x46948
- Calls: 0x48344, 0x46a20, 0x469fa, 0x46948
- Called by: 0x410E4

### 13. 0x411B6-0x411D0: `call_state_dispatcher_and_other`
- Entry: 0x411B6
- Purpose: Calls state dispatcher (0x41152) and another function (0x150c)
- Arguments: D0 = state code at fp@(8)  stack frame parameter
- Hardware/RAM: None
- Calls: 0x41152, 0x150c
### 14. 0x411D2-0x4140E: DATA REGION (character pattern data)
- This is NOT code but data - appears to be a pattern or lookup table
- Contains repeating byte patterns like 0x43, 0x6F, 0x70, etc.
- Likely used for font rendering or character patterns  (PS dict operator)

### 15. 0x41410-0x41424: `handle_system_signal`
- Entry: 0x41410
- Purpose: Handles system signals (2, 14) and sets error context
- Arguments: D0 = signal code at fp@(8)  stack frame parameter
  - Accesses 0x2000a10, 0x2000a14 (signal counters)
  - Sets 0x20174ac, 0x20174a8 (error context)
- Calls: 0x4df80, 0x31ddc, 0x46334
- Called by: 0x4148E

### 16. 0x41480-0x4148C: `increment_signal_counter`
- Entry: 0x41480
- Purpose: Increments signal counter at 0x2000a10
- Hardware/RAM: Accesses 0x2000a10
### 17. 0x4148E-0x414B8: `decrement_signal_counter`
- Entry: 0x4148E
- Purpose: Decrements signal counter and handles pending signal if counter reaches 0  (PS dict operator)
- Hardware/RAM: Accesses 0x2000a10, 0x2000a14
- Calls: 0x41410
### 18. 0x414BA-0x414CC: `clear_signal_counters`
- Entry: 0x414BA
- Purpose: Clears signal counters at 0x2000a10 and 0x2000a14
- Hardware/RAM: Accesses 0x2000a10, 0x2000a14
### 19. 0x414CE-0x414DA: `call_error_handler`
- Entry: 0x414CE
- Purpose: Simply calls error handler at 0x46334
- Calls: 0x46334
### 20. 0x414DC-0x414F2: `call_444d0_and_3bb98`
- Entry: 0x414DC
- Purpose: Calls 0x444d0, then passes result to 0x3bb98
- Calls: 0x444d0, 0x3bb98
### 21. 0x414F4-0x4150A: `call_44b48_and_3bb98`
- Entry: 0x414F4
- Purpose: Calls 0x44b48, then passes result to 0x3bb98
- Calls: 0x44b48, 0x3bb98
### 22. 0x4150C-0x41578: `handle_system_state`
- Entry: 0x4150C
- Purpose: Handles system state transitions (0, 1, 2)
- Arguments: D0 = state code at fp@(8)  stack frame parameter
  - State 0: Clears 0x2000a10, 0x2000a14
  - State 1: Sets up serial ports, calls initialization functions
  - State 2: Similar to state 1 but with different setup
- Calls: 0x46a20, 0x30350, 0x46948, 0x303bc, 0x469fa
### 23. 0x4157A-0x415AA: DATA REGION (function pointer table)
- Contains function addresses: 0x000415D0, 0x000414DC, etc.
- Likely a dispatch table for system operations

### 24. 0x415AC-0x415C2: DATA REGION (string pointers and addresses)
- Contains string pointers and hardware addresses
- Strings: "setuserdiskpercent", etc.

### 25. 0x415C4-0x41622: DATA REGION (string table)
- Contains various strings: "undefined", "usertime", "realtime", "disableinterrupt", "enableinterrupt", "clearinterrupt", "interrupt", "timeout", etc.  (PS dict operator)

### 26. 0x41624-0x4165A: `call_function_table`
- Entry: 0x41624
- Purpose: Iterates through a function table at 0x3c5a0 and calls each function
- Arguments: D0 = parameter at fp@(8)  stack frame parameter
- Hardware/RAM: Accesses function table at 0x3c5a0
- Calls: Functions from the table
### 27. 0x4165C-0x4168C: `get_disk_percent`
- Entry: 0x4165C
- Purpose: Gets disk percentage from hardware register 0x2000a28
- Return value: D0 = disk percentage (0-100)
- Hardware/RAM: Reads 0x2000a28 (disk percentage register)
- Calls: 0xffffd90c (likely converts raw value to percentage)
- Called by: 0x4168E, 0x417B6

### 28. 0x4168E-0x416A4: `call_get_disk_percent_and_3bb98`
- Entry: 0x4168E
- Purpose: Calls get_disk_percent, then passes result to 0x3bb98
- Calls: 0x4165C, 0x3bb98
### 29. 0x416A6-0x41744: `handle_disk_operation`
- Entry: 0x416A6
- Purpose: Handles disk operations with timeout and error checking
- Arguments: None (but uses global state)
  - Calls 0x3b626 (disk operation)
  - Sets up execution context at 0x20008f4
  - Handles errors and timeouts
- Calls: 0x3b626, 0xffffdef6, 0x463ba, 0x4df1c, 0xb4f4, 0x46382, 0x30f8c, 0xffffd94c  (PS dict operator)
### 30. 0x41746-0x417D0: `handle_system_command`
- Entry: 0x41746
- Purpose: Handles system commands (0, 2) for disk operations
- Arguments: D0 = command code at fp@(8)  stack frame parameter
  - Command 0: Sets disk percentage via 0xffffdb08
  - Command 2: Sets up serial ports and calls disk operations
- Calls: 0xffffdb08, 0x30350, 0x469fa, 0x303bc, 0x4df1c, 0x4165C, 0xb4f4
### 31. 0x417D2-0x417E0: DATA REGION (function pointer table)
- Contains function addresses for system commands

### 32. 0x417EC-0x417FE: DATA REGION (string)
- String: "setuserdiskpercent"

1. **Main Entry Point**: 0x40E36 is the main PostScript interpreter entry point
2. **Error Handling**: Comprehensive error handling at 0x40F6E with different error codes
3. **State Machine**: PostScript uses a state machine (0x410E4) with dispatcher at 0x41152
4. **Signal Handling**: System has signal counters and handlers (0x41410)
5. **Disk Operations**: Functions for disk percentage monitoring and operations
6. **System Commands**: Command handler for system operations (0x41746)

1. The data region at 0x411D2 is NOT code but character pattern data
2. Function at 0x41134 is an alignment function, not a system check
3. The function table at 0x40C00 continues operator dispatch, not initialization
This region contains critical PostScript interpreter initialization, error handling, and system management functions that form the core of the interpreter's runtime environment.

; === CHUNK 3: 0x41800-0x42400 ===

## REFINED ANALYSIS OF 0x41800-0x42400

### CORRECTIONS TO PRIOR ANALYSIS:

2. **Function at 0x41b84** is `debugmode_impl` - an internal implementation function for debug mode operations.

3. **Data region at 0x41aec-0x41b24** is a jump table of operator names, not code. Each entry is 4 bytes pointing to operator name strings.

## 1. `setdiskrecovery` (0x41800)
**Entry:** 0x41800  
**Name:** `setdiskrecovery` (string "setdiskrecovery" at 0x41800)  
**Purpose:** Sets disk recovery timeout parameters for SCSI operations. Reads three integers from PostScript stack (retry count, timeout1, timeout2), validates each is between 15 and 2147483 (0x20C49B). Adjusts each by subtracting values from RAM (0x0201739e, 0x020173a2) and calls `setint` (0xffffd94c) to program hardware timers.  
**Arguments:** Three integers from PostScript stack via `pop_int` (0x3b626)  
**Returns:** Nothing (RTS)  
**RAM access:** 0x0201739e, 0x020173a2 (subtraction values), 0x020173dc, 0x020173d2, 0x020173e2 (hardware register offsets)  
**Call targets:** 0xffffdef6 (unknown), 0x3b626 (pop_int), 0xffffd94c (setint), 0x463ba (error handler)  
**Called by:** PostScript operator dispatch

## 2. `getdiskrecovery` (0x418be)
**Entry:** 0x418be  
**Name:** `getdiskrecovery`  
**Purpose:** Gets current disk recovery parameters. Reads values from hardware via `getint` (0xffffd90c), adds offsets from RAM (0x0201739e, 0x020173a2), validates ranges, pushes results to PostScript stack via `push_int` (0x3bb98).  
**Returns:** Three integers on PostScript stack  
**RAM access:** Same as setdiskrecovery  
**Call targets:** 0xffffd90c (getint), 0x3bb98 (push_int)  
**Called by:** PostScript operator dispatch

## 3. `checkpageswait` (0x4196e)
**Entry:** 0x4196e  
**Name:** `checkpageswait` (string "checkpageswait" at 0x41b80)  
**Purpose:** Checks if page device (imagesetter) is ready. Tests pointer at 0x020173e8 (device structure), calls 0x365f8 (device status check), examines result byte. If device ready (bit 0x1 set), compares value from 0x020173da with computed value. If not ready, delays 1000ms (0x3e8) via 0x4453a.  
**Returns:** Pushes 1 (ready) or 0 (not ready) to PostScript stack via `push_bool` (0x3bc78)  
**RAM access:** 0x020173e8 (device ptr), 0x020173da (status value)  
**Call targets:** 0x365f8 (device status), 0x4453a (delay), 0x3bc78 (push_bool)  
**Called by:** `wait_page_device` and PostScript operators

## 4. `waitpageswait` (0x419ce)
**Entry:** 0x419ce  
**Name:** `waitpageswait` (string "waitpageswait" at 0x41b74)  
**Purpose:** Waits for page device with timeout. Gets timeout value from stack, calls `checkpageswait`, then calls 0x3677e (wait function). If wait successful, adjusts value using 0x020173da via `setint`.  
**Arguments:** Timeout integer from PostScript stack  
**Returns:** Nothing  
**RAM access:** 0x020173da  
**Call targets:** 0x3b626 (pop_int), 0x4196e (checkpageswait), 0x3677e (wait), 0xffffd94c (setint)  
**Called by:** PostScript operators

## 5. `getpagetype` (0x41a0a)
**Entry:** 0x41a0a  
**Name:** `getpagetype` (string "getpagetype" at 0x41b53)  
**Purpose:** Reads page type from hardware register. Reads word at 0x020173e4 (hardware address), calls 0x439d8 (hardware read), masks to byte, pushes to stack.  
**Returns:** Page type byte (0-255) on stack  
**Hardware:** 0x020173e4 (mapped to hardware register)  
**Call targets:** 0x439d8 (hw_read), 0x3bb98 (push_int)  
**Called by:** PostScript operators

## 6. `setpagetype` (0x41a34)
**Entry:** 0x41a34  
**Name:** `setpagetype` (string "setpagetype" at 0x41b5c)  
**Purpose:** Sets page type in hardware register. Reads integer from stack, masks to byte, writes to hardware via 0x43a08.  
**Arguments:** Page type integer from PostScript stack  
**Returns:** Nothing  
**Hardware:** 0x020173e4 (mapped to hardware register)  
**Call targets:** 0xffffdef6 (unknown), 0x3b626 (pop_int), 0x43a08 (hw_write)  
**Called by:** PostScript operators

## 7. `debugmode` (0x41a62)
**Entry:** 0x41a62  
**Name:** `debugmode` (string "debugmode" at 0x41b24)  
**Purpose:** Handles debug mode commands. Takes integer argument (1 or 5). For command 1 or 5: reads font dictionary stats from 0x02017354, prints debug info including current color space (0x020008f8), system flags (0x02000010), and calls debug output functions.  
**Arguments:** Integer command (1 or 5) from PostScript stack  
**Returns:** Nothing  
**RAM access:** 0x02017354 (font dict), 0x020008f8 (color space), 0x02000010 (sys flags)  
**Call targets:** 0xffffdef6 (unknown), 0x30350 (print), 0x34096 (format), 0x302de (print), 0x469fa (print), 0x303bc (print)  
**Called by:** PostScript operator dispatch

## 8. `debugmode_impl` (0x41b84)
**Entry:** 0x41b84  
**Name:** `debugmode_impl`  
**Purpose:** Internal implementation of debug mode. Reads input from buffer, processes debug commands, updates debug state at 0x02017030. Handles debug buffer of up to 127 bytes.  
**Returns:** 0 on success, -1 on error  
**RAM access:** 0x02017030 (debug state), 0x2000a3c (file structure)  
**Call targets:** 0x2a0a (read input), 0x43954 (check), 0x5b2 (unknown), 0x4dcf8 (copy), 0x5ac (unknown)  
**Called by:** `read_char_from_buffer` (0x41c02)

## 9. `read_char_from_buffer` (0x41c02)
**Entry:** 0x41c02  
**Name:** `read_char_from_buffer`  
**Purpose:** Reads a character from a buffered file structure. Handles file I/O with state machine, supports different buffer modes (0, 1000, 1001). Manages buffer pointers and calls debug mode when needed.  
**Arguments:** A5 points to file structure (12 bytes: current count, read ptr, write ptr, flags, etc.)  
**Returns:** Character in D0, or -1 on error/EOF  
**Structure format:** [count][read_ptr][write_ptr][flags][file_ptr]  
**Call targets:** 0x41b84 (debugmode_impl), 0x4203c (flush), 0x42924 (read operation), 0x4ded8 (min), 0x5b8 (unknown)  
**Called by:** File I/O subsystem

## 10. `unread_char` (0x41dd4)
**Entry:** 0x41dd4  
**Name:** `unread_char`  
**Purpose:** Pushes a character back into the buffer (ungetc). Checks if buffer has space, decrements read pointer, stores character.  
**Arguments:** A5=file structure, D0=character to unread  
**Returns:** Character in D0, or -1 if no space  
**Call targets:** None directly  
**Called by:** Lexer/scanner

## 11. `flush_input_buffer` (0x41e08)
**Entry:** 0x41e08  
**Name:** `flush_input_buffer`  
**Purpose:** Flushes input buffer by reading and discarding all characters until EOF.  
**Arguments:** A5=file structure  
**Returns:** 0  
**Call targets:** 0x41bfe (read_char_from_buffer wrapper)  
**Called by:** File I/O cleanup

## 12. `check_file_status` (0x41e36)
**Entry:** 0x41e36  
**Name:** `check_file_status`  
**Purpose:** Checks if file is in a valid state for reading. Returns 0 if ready, -1 if not.  
**Arguments:** A5=file structure  
**Returns:** 0 if ready, -1 if not  
**Called by:** File I/O subsystem

## 13. `init_file_buffer` (0x41e66)
**Entry:** 0x41e66  
**Name:** `init_file_buffer`  
**Purpose:** Initializes file buffer structure by clearing the count field.  
**Arguments:** A5=file structure  
**Returns:** Nothing  
**Called by:** File open routines

## 14. `reset_file_buffer` (0x41e7a)
**Entry:** 0x41e7a  
**Name:** `reset_file_buffer`  
**Purpose:** Resets file buffer to initial state: clears count, sets pointers to buffer start, clears flags.  
**Arguments:** A5=file structure  
**Returns:** 0  
**Called by:** File rewind operations

## 15. `fill_input_buffer` (0x41ebe)
**Entry:** 0x41ebe  
**Name:** `fill_input_buffer`  
**Purpose:** Fills input buffer from underlying file/device. Handles different file states, calls read operations, manages buffer pointers.  
**Arguments:** A5=file structure  
**Returns:** 0 on success, -1 on error  
**Call targets:** 0x5b8 (unknown), 0x4203c (flush), 0x43954 (check), 0x42a4a (read operation)  
**Called by:** `read_char_from_buffer`

## 16. `write_char_to_buffer` (0x41fd6)
**Entry:** 0x41fd6  
**Name:** `write_char_to_buffer`  
**Purpose:** Writes a character to output buffer. Calls fill if needed, then stores character.  
**Arguments:** A5=file structure, D0=character to write  
**Returns:** 0 on success, error code on failure  
**Call targets:** 0x41ebe (fill_input_buffer)  
**Called by:** Output routines

## 17. `flush_output_buffer` (0x42008)
**Entry:** 0x42008  
**Name:** `flush_output_buffer`  
**Purpose:** Flushes output buffer by resetting pointers and setting buffer size to 512 bytes.  
**Arguments:** A5=file structure  
**Returns:** Nothing  
**Called by:** Output completion routines

## 18. `flush_file` (0x4203c)
**Entry:** 0x4203c  
**Name:** `flush_file`  
**Purpose:** Flushes file buffer to device. Waits for device ready, writes buffer contents via 0x42b3a.  
**Arguments:** A5=file structure  
**Returns:** Nothing  
**Call targets:** 0x43954 (check), 0x42b3a (write operation)  
**Called by:** Various file operations

## 19. `close_file` (0x42072)
**Entry:** 0x42072  
**Name:** `close_file`  
**Purpose:** Closes a file handle. Saves execution context, flushes buffer, releases resources.  
**Arguments:** A5=file structure  
**Returns:** 0 on success, -1 on error  
**RAM access:** 0x020008f4 (execution context)  
**Call targets:** 0x4df1c (save context), 0x41ebe (fill_input_buffer), 0x4203c (flush), 0x4d8d8 (restore context)  
**Called by:** File close operations

## 20. `init_file_structure` (0x42126)
**Entry:** 0x42126  
**Name:** `init_file_structure`  
**Purpose:** Initializes a file structure with buffer pointers and sizes. Sets up read/write pointers and buffer size.  
**Arguments:** A5=parent structure, A4=file struct, A3=buffer, D7=buffer size  
**Returns:** Nothing  
**Called by:** File open routines

## 21. `setup_file_buffers` (0x4216a)
**Entry:** 0x4216a  
**Name:** `setup_file_buffers`  
**Purpose:** Sets up dual buffers for a file (input and output). Configures buffer pointers and calls init for both buffers.  
**Arguments:** A5=file structure  
**Returns:** 0 on success, error code on failure  
**RAM access:** 0x02017414 (heap pointer)  
**Call targets:** 0x4de50 (memcpy), 0x42126 (init_file_structure), 0x42756 (open file), 0x41b84 (debugmode_impl)  
**Called by:** File open operations

## 22. `alloc_file_handles` (0x421f4)
**Entry:** 0x421f4  
**Name:** `alloc_file_handles`  
**Purpose:** Allocates file handle structures from heap. Sets up linked structure with parent/child relationships.  
**Arguments:** A5=file structure  
**Returns:** 1 on success, 0 on failure  
**Call targets:** 0x48544 (malloc), 0x48584 (free)  
**Called by:** File open operations

## 23. `format_filename` (0x4225a)
**Entry:** 0x4225a  
**Name:** `format_filename`  
**Purpose:** Formats a filename with numeric suffix. Converts ASCII string, adds numeric suffix in special format.  
**Arguments:** A5=input string, A4=output buffer, D7=numeric suffix  
**Returns:** Nothing (output in buffer)  
**Call targets:** 0x4dcf8 (strcpy)  
**Called by:** File naming routines

## 24. `handle_file_error` (0x422ee)
**Entry:** 0x422ee  
**Name:** `handle_file_error`  
**Purpose:** Handles file system errors. Manages error state at 0x02000a34, cleans up resources on fatal errors.  
**Arguments:** Error code from stack  
**Returns:** Pushes error code to PostScript stack  
**RAM access:** 0x02000a34 (error state), 0x02000a3c (file struct)  
**Call targets:** 0x3b626 (pop_int), 0x4203c (flush), 0x48584 (free), 0x44604 (cleanup), 0x42bb4 (reset), 0x438b0 (init), 0x437a8 (open), 0x3bb98 (push_int)  
**Called by:** File error handling

## 25. `recover_file_system` (0x4238e)
**Entry:** 0x4238e  
**Name:** `recover_file_system`  
**Purpose:** Attempts to recover file system after error. Reinitializes file structures based on error state.  
**RAM access:** 0x02000a3c (file struct), 0x02000a34 (error state)  
**Call targets:** 0x4203c (flush), 0x4216a (setup_file_buffers), 0x421f4 (alloc_file_handles), 0x4225a (format_filename), 0x425d2 (unknown)  
**Called by:** Error recovery

1. **Operator name table** (0x41aec-0x41b24): 14 entries × 4 bytes each, pointing to operator name strings:
   - 0x41aec: 0x00041b30 → "setdefaulttimeouts"  (PS dict operator)
   - 0x41af0: 0x00041810 → ??? (not in this chunk)
   - 0x41af4: 0x00041b43 → "defaulttimeouts"  (PS dict operator)
   - 0x41af8: 0x000418be → ??? (not in this chunk)
   - 0x41afc: 0x00041b53 → "getpagetype"
   - 0x41b00: 0x00041a0a → ??? (not in this chunk)
   - 0x41b04: 0x00041b5c → "setpagetype"
   - 0x41b08: 0x00041a34 → ??? (not in this chunk)
   - 0x41b10: 0x00041b68 → "waitpageswait"
   - 0x41b14: 0x000419ce → ??? (not in this chunk)
   - 0x41b18: 0x00041b74 → "checkpageswait"
   - 0x41b1c: 0x0004196e → ??? (not in this chunk)

2. **String table** (0x41b24-0x41b84): Operator name strings:
   - 0x41b24: "debugmode"
   - 0x41b30: "setdefaulttimeouts"  (PS dict operator)
   - 0x41b43: "defaulttimeouts"  (PS dict operator)
   - 0x41b53: "getpagetype"
   - 0x41b5c: "setpagetype"
   - 0x41b68: "waitpageswait"
   - 0x41b74: "checkpageswait"

1. This region contains the **file I/O subsystem** for PostScript, with buffered input/output operations.
2. The file structure is complex with parent/child relationships and dual buffers.
3. Error recovery mechanism tracks state at 0x02000a34 (0=normal, 1=recovering, 2=fatal).
4. Debug mode provides internal diagnostics for font dictionary and system state.
5. Hardware interaction for page device (imagesetter) through `checkpageswait`/`waitpageswait`.
6. Disk recovery timeouts are configurable via `setdiskrecovery`/`getdiskrecovery`.

; === CHUNK 4: 0x42400-0x43000 ===

1. The code at 0x42400 is **NOT** the start of a function - it's a continuation from earlier (likely 0x423B0 based on the branch at 0x4243A).
2. The "jump table" at 0x425F4 is actually **DATA** - it's a table of 32-bit values that appear to be addresses in the 0x80000-0x8FFFF range (bank 4).
### 1. **Function continuation (0x42400-0x4248C)**
**Entry:** 0x42400 (continuation from ~0x423B0)  
**Name:** Likely part of `serial_io_handler` or `debug_command_processor`  
**Purpose:** Continuation of a serial I/O handling function with retry logic. Contains error handling for error code -1027 (0xFFFFFBFD) with retry counter in D6 (max 100 retries). Calls timeout function (0x44574) with 2000ms delay. Updates counters at 0x02000A34 and 0x02000A38. When counter at 0x02000A34 equals 2, performs file operations via 0x381de and processing via 0x365aa.  
**Arguments:** A5 points to a structure (offset 54 checked)  
**RAM access:** 0x02000A34 (counter), 0x02000A38 (last result), structure via A5  
**Cross-ref:** Calls 0x44574 (delay), 0x381de (file op), 0x365aa (process), 0x463f2 (error handler)  
**Stack frame:** Uses A6 frame pointer, saves D6-D7/A5

### 2. **`process_debug_command` (0x4248E-0x4256E)**
**Entry:** 0x4248E  
**Name:** `process_debug_command` (confirmed)  
**Purpose:** Processes debug commands from serial input. Extracts command type via BFEXTU (bits 1-3), validates length (< 96 bytes). Compares input against buffer at 0x02000A30. If mismatch, copies string using 0x4DCF8. Special handling when counter at 0x02000A34 equals 2: calls buffer operations at 0x42888/0x42878 with retry logic for error -1027.  
**Arguments:** Command structure on stack (type at -8, length at -6, data pointer at -4)  
**RAM access:** 0x02000A30 (command buffer), 0x02000A34 (counter), 0x02000A2C (buffer)  
**Cross-ref:** Calls 0x3B9B4 (get type), 0x324AC (process), 0x463BA (error), 0x4DCF8 (strcpy), 0x42888/0x42878  
### 3. **`init_debug_system` (0x42570-0x425F2)**
**Entry:** 0x42570  
**Name:** `init_debug_system` (confirmed)  
**Purpose:** Initializes debug system buffers if parameter = 1. Allocates: 102 bytes at 0x02000A2C, 97 bytes at 0x02000A30, 60 bytes at 0x02000A3C. Prints debug header via 0x30350 and format string at 0x42690.  
**Arguments:** D0 = init flag (1 = initialize)  
**Returns:** RTS if D0 ≠ 1  
**RAM access:** 0x02000A34 (cleared), buffer pointers at 0x02000A2C/A30/A3C  
**Cross-ref:** Calls 0x48344 (malloc), 0x30350 (print), 0x469FA (format), 0x303BC (flush)  
### 4. **DATA: Address table (0x425F4-0x426A4)**
**Address:** 0x425F4-0x426A4  
**Type:** Table of 32-bit values (likely addresses or offsets)  
**Format:** 32-bit little-endian values that appear to be addresses in bank 4 (0x80000-0x8FFFF range)  
**Examples:** 0x00088480, 0x00088494, 0x0008863C, etc.  
**Note:** This is **NOT** a jump table in the traditional sense - it's data referenced by code elsewhere.

### 5. **DATA: String table (0x426B0-0x426FE)**
**Address:** 0x426B0-0x426FE  
**Type:** ASCII strings (PostScript AppleTalk related)  
- 0x426B0: "**\n**" (separator)
- 0x426B8: "temp"
- 0x426BC: "AppleTalk"
- 0x426C6: "AppleTalk" (duplicate)
- 0x426D0: "initialk" (corrupted "initialtalk"?)
- 0x426DE: "opentalk"  
- 0x426EC: "setuptalkname" (PostScript AppleTalk setup)

### 6. **`check_serial_port` (0x42700-0x4271E)**
**Entry:** 0x42700  
**Name:** `check_serial_port`  
**Purpose:** Checks if port ID matches expected value at 0x02000900. If match, calls 0x4DFE2 with parameter 2 (likely port reset/init).  
**Arguments:** D0 = port ID to check  
**RAM access:** 0x02000900 (expected port ID)  
**Cross-ref:** Calls 0x4DFE2 (serial port operation)  
### 7. **`print_debug_info` (0x42720-0x42778)**
**Entry:** 0x42720  
**Name:** `print_debug_info`  
**Purpose:** Prints debug information if flag at 0x02017404 is set. Calls formatting functions at 0x48430 and 0x2A0A. Accesses structure at 0x02000904 and calls a function pointer within it.  
**RAM access:** 0x02017404 (debug flag), 0x02000904 (debug structure)  
**Cross-ref:** Calls 0x48430 (format), 0x2A0A (unknown), indirect call via structure  
### 8. **`handle_file_operation` (0x4277A-0x427B6)**
**Entry:** 0x4277A  
**Name:** `handle_file_operation`  
**Purpose:** Handles file operations - calls 0x48394, then performs file I/O via 0x381de, then processes via 0x384fa.  
**Arguments:** D0 = file handle or parameter  
**Cross-ref:** Calls 0x48394 (alloc/free?), 0x381de (file I/O), 0x384fa (process)  
### 9. **`process_buffered_data` (0x427B8-0x42802)**
**Entry:** 0x427B8  
**Name:** `process_buffered_data`  
**Purpose:** Processes data from buffers at 0x02000A40 and 0x02000A44 using file I/O (0x381de) and processing (0x365aa).  
**RAM access:** 0x02000A40, 0x02000A44 (buffer pointers)  
**Cross-ref:** Calls 0x381de (file I/O), 0x365aa (process)  
### 10. **`setup_debug_buffers` (0x42804-0x42890)**
**Entry:** 0x42804  
**Name:** `setup_debug_buffers`  
**Purpose:** Sets up debug buffers by calling 0x3B94A and 0x3B626, then processes existing buffers, calls 0x43FDC with callback functions, and updates buffer pointers.  
**RAM access:** 0x02000A40, 0x02000A44, 0x020174C0  
**Cross-ref:** Calls 0x3B94A, 0x3B626, 0x43FDC, 0x44930, 0x427B8  
### 11. **`clear_debug_buffers` (0x42892-0x428D2)**
**Entry:** 0x42892  
**Name:** `clear_debug_buffers`  
**Purpose:** Clears debug buffers by calling 0x4277A on buffers at 0x02000A40 and 0x02000A44, then zeros the pointers and flag at 0x020174C0.  
**RAM access:** 0x02000A40, 0x02000A44, 0x020174C0  
**Cross-ref:** Calls 0x4277A  
### 12. **`configure_debug_system` (0x428D4-0x4292A)**
**Entry:** 0x428D4  
**Name:** `configure_debug_system`  
**Purpose:** Configures debug system based on parameter (0 or 1). If 0, calls 0x4424E and clears buffers. If 1, prints debug header.  
**Arguments:** D0 = configuration mode (0=disable, 1=enable)  
**RAM access:** 0x020174C0, 0x02000A44, 0x02000A40  
**Cross-ref:** Calls 0x4424E, 0x30350, 0x469FA, 0x303BC  
### 13. **DATA: String table (0x4292C-0x42970)**
**Address:** 0x4292C-0x42970  
**Type:** ASCII strings and format strings  
**Content:** Various strings including "%[ ]", "open", "close", "cancel", etc.

### 14. **`handle_dialog_response` (0x42974-0x42A08)**
**Entry:** 0x42974  
**Name:** `handle_dialog_response`  
**Purpose:** Handles dialog responses - calls 0x308FA with parameters, checks response type (bit 0-3 = 5), calls 0x488C0 for formatting, and executes callback via function pointer.  
**Arguments:** Multiple on stack (callback, parameters, etc.)  
**Returns:** D0 = result  
**Cross-ref:** Calls 0x308FA, 0x488C0, indirect call via function pointer  
### 15. **`process_job_status` (0x42A0A-0x42ABE)**
**Entry:** 0x42A0A  
**Name:** `process_job_status`  
**Purpose:** Processes job status - calls 0x42974 multiple times with different string parameters from 0x02000A48-0x02000A5C.  
**Arguments:** D0 = context pointer  
**Returns:** D0 = status result  
**RAM access:** 0x02017404, 0x02000A48-0x02000A5C, 0x02017370  
**Cross-ref:** Calls 0x42974, 0x488C0  
### 16. **`update_job_state` (0x42AC0-0x42BEA)**
**Entry:** 0x42AC0  
**Name:** `update_job_state`  
**Purpose:** Updates job state - compares new state with current at 0x02017370, updates it, calls 0x308FA, performs calculations, calls 0x444F4 and 0x44B50, updates timeout value at 0x02000A60.  
**Arguments:** D0 = new job state  
**RAM access:** 0x02017370, 0x020174C8-CC, 0x02000A60, 0x020173EC-F0  
**Cross-ref:** Calls 0x308FA, 0x444F4, 0x44B50, 0x44B5C, 0x4DFE2, 0x31DBE, 0x44518, 0x4D8D8  
### 17. **`init_job_system` (0x42BEC-0x42C22)**
**Entry:** 0x42BEC  
**Name:** `init_job_system`  
**Purpose:** Initializes job system - prints string via 0x46A20, sets flag at 0x02017404, calls 0x42AC0.  
**Arguments:** D0 = initialization mode (1 or 5)  
**RAM access:** 0x02017404  
**Cross-ref:** Calls 0x46A20, 0x42AC0  
### 18. **DATA: String table (0x42C24-0x42CA4)**
**Address:** 0x42C24-0x42CA4  
**Type:** ASCII strings and configuration data  
**Content:** Strings like "jobname", "jobsource", "jobstate", "waittimeout", and pointer values.

### 19. **`init_sort_tables` (0x42CA6-0x42CB6)**
**Entry:** 0x42CA6  
**Name:** `init_sort_tables`  
**Purpose:** Initializes sort tables by clearing values at 0x02000D64 and 0x02000D68.  
**RAM access:** 0x02000D64, 0x02000D68  
### 20. **`insert_sorted_entry` (0x42CB8-0x42DE8)**
**Entry:** 0x42CB8  
**Name:** `insert_sorted_entry`  
**Purpose:** Inserts an entry into a sorted table. Performs binary search-like insertion with floating-point comparisons using 0x89980 (FP compare). Handles array shifting for insertion.  
**Arguments:** Multiple on stack (array pointer, index, values to insert)  
**Returns:** D0 = success (1) or failure (0)  
**Cross-ref:** Calls 0x89980 (FP compare), 0x89938, 0x89A88, 0x89A58, 0x899C8 (FP operations)  
### 21. **`add_to_sorted_table_a` (0x42DF0-0x42E56)**
**Entry:** 0x42DF0  
**Name:** `add_to_sorted_table_a`  
**Purpose:** Adds an entry to sorted table A (at 0x02000A64). Converts values using 0x899C8 (FP operation), calls 0x42CB8 for insertion.  
**Arguments:** Two floating-point value pairs on stack  
**RAM access:** 0x02000D64 (table A count)  
**Cross-ref:** Calls 0x46382 (error?), 0x899C8 (FP op), 0x42CB8 (insert)  
### 22. **`add_to_sorted_table_b` (0x42E58-0x42EBC)**
**Entry:** 0x42E58  
**Name:** `add_to_sorted_table_b`  
**Purpose:** Adds an entry to sorted table B (at 0x02000BE4). Similar to 0x42DF0 but for table B.  
**Arguments:** Two floating-point value pairs on stack  
**RAM access:** 0x02000D68 (table B count)  
**Cross-ref:** Calls 0x46382 (error?), 0x899C8 (FP op), 0x42CB8 (insert)  
### 23. **`compute_table_differences` (0x42EBE-0x42F18)**
**Entry:** 0x42EBE  
**Name:** `compute_table_differences`  
**Purpose:** Computes differences between consecutive entries in a table. Uses 0x89AB8 (FP subtract) and 0x899B0 (FP multiply).  
**Arguments:** Array pointer and count on stack  
**Cross-ref:** Calls 0x89AB8 (FP subtract), 0x899B0 (FP multiply)  
### 24. **`finalize_sort_tables` (0x42F1A-0x42F52)**
**Entry:** 0x42F1A  
**Name:** `finalize_sort_tables`  
**Purpose:** Finalizes both sorted tables by computing differences for each. Sets flag at 0x02000D6C.  
**RAM access:** 0x02000D64, 0x02000D68, 0x02000D6C  
**Cross-ref:** Calls 0x42EBE (compute differences)  
### 25. **`find_in_sorted_table` (0x42F54-0x43000+)**
**Entry:** 0x42F54  
**Name:** `find_in_sorted_table`  
**Purpose:** Performs binary search in a sorted table. Uses floating-point comparisons via 0x89968. Handles edge cases and performs interpolation.  
**Arguments:** Array pointer, index, search values on stack  
**Returns:** Result via FP operations  
**Cross-ref:** Calls 0x89A88, 0x89968 (FP compare), 0x89AB8 (FP subtract)  
**Note:** Function continues beyond 0x43000 (truncated in this chunk)

1. **Debug System:** This region contains extensive debug/development support code with buffered I/O, command processing, and job status tracking.

2. **Sorted Tables:** There's a sophisticated sorted table system with binary insertion (0x42CB8) and search (0x42F54) using floating-point comparisons. This is likely for some numerical processing or calibration data.

3. **Job Management:** Functions like `update_job_state` and `process_job_status` suggest a job queue system for print jobs.

4. **AppleTalk Support:** String table at 0x426B0 contains AppleTalk-related strings, indicating network printing support.

5. **Floating-Point Intensive:** Many functions use FPU operations (calls to 0x899xx addresses), suggesting numerical processing for graphics or calibration.

The code in this region appears to be part of a development/debugging subsystem with job management, sorted data tables for numerical processing, and AppleTalk network support.

; === CHUNK 5: 0x43000-0x43C00 ===

### 1. 0x43000 - `matrix_multiply_accumulate`
**Entry:** 0x43000  
**Purpose:** Performs matrix multiplication for PostScript CTM operations. Multiplies a 2x3 transformation matrix (stored at A5) with a point (x,y), accumulating results. Handles floating-point precision via software FPU calls.  
- A5: Pointer to 6-element matrix [a b c d tx ty]
- FP@(16,20): Point x,y as 64-bit float (two longwords)  stack frame parameter
- FP@(24): Result pointer  stack frame parameter
**Return:** Stores 64-bit float result at given pointer  
**Key calls:** 0x89a88 (float conversion), 0x89968 (float compare), 0x89aa0 (float multiply), 0x89920 (float add), 0x899c8 (float to int)  
**Called from:** Transformation setup routines  
**Algorithm:** Computes: result_x = a*x + c*y + tx, result_y = b*x + d*y + ty  

### 2. 0x430de - `transform_point_device_or_user`
**Entry:** 0x430de  
**Purpose:** Transforms a point based on current transformation mode (device vs. user space). Checks flags at 0x2000d64 and 0x2000d68 to determine which transformation matrix to use. Stores result to specified location.  
- FP@(8): X coordinate (32-bit fixed or float)  coordinate data  (font metric data)
- FP@(12): Y coordinate  coordinate data  (font metric data)
- FP@(16): Result pointer  stack frame parameter
**Hardware:** Accesses 0x2000d64 (device transform flag), 0x2000d68 (user transform flag), 0x2000a64 (device matrix), 0x2000be4 (user matrix)  
**Key calls:** 0x2f54 (apply specific transform)  
**Algorithm:** If device transform active, uses matrix at 0x2000a64; if user transform active, uses 0x2000be4; otherwise stores raw coordinates.

### 3. 0x4315c - `transform_and_store_to_d70`
**Entry:** 0x4315c  
**Purpose:** Wrapper for 0x430de that always stores result to fixed location 0x2000d70. Used as a common transformation output buffer.  
**Arguments:** FP@(8,12): X,Y coordinates  
**Return:** D0 = 0x2000d70 (pointer to result)  
**Hardware:** Stores to 0x2000d70 (transformation result buffer)  
**Key calls:** 0x30de (transform_point_device_or_user)

### 4. 0x4318c - `compare_transformed_values_eq`
**Entry:** 0x4318c  
**Purpose:** Reads two values from stack, transforms them, and checks if they're equal after transformation. Used for coordinate equality tests in path operations.  
**Return:** D0 = comparison result (true/false)  
**Key calls:** 0x3b81a (pop value), 0x2df2 (float equality test)  
**Algorithm:** Pops two values, converts to float, transforms via current CTM, compares results.

### 5. 0x431d0 - `compare_transformed_values_ne`  
**Entry:** 0x431d0  
**Purpose:** Similar to 0x4318c but tests for inequality (!=). Used for coordinate difference checks.  
**Return:** D0 = true if transformed values are not equal  
**Key calls:** 0x3b81a, 0x2e58 (float inequality test)

### 6. 0x43214 - `transform_and_process`
**Entry:** 0x43214  
**Purpose:** Reads a coordinate pair, transforms it, stores result, then processes it further (likely for path construction).  
**Key calls:** 0x3bce8 (pop coordinate pair), 0x30de (transform), 0x3bde2 (push result)  
**Algorithm:** Pops (x,y) pair, transforms via current CTM, pushes transformed result back onto stack.

### 7. 0x43248 - `render_path_with_clipping`
**Entry:** 0x43248  
**Purpose:** Main path rendering function with clipping and fill/stroke operations. Sets up graphics state, applies clipping path, and dispatches to appropriate rendering routine based on operation type.  
**Arguments:** FP@(8): Operation type, FP@(12): Additional parameter  
**Return:** D0 = success/failure code  
**Hardware:** Accesses 0x20008f4 (graphics state stack), 0x2017464 (current context)  
**Key calls:** 0x152fe (setup), 0x180e4 (gsave), 0x1ab70 (clip setup), 0x4df1c (unknown), 0x308fa (transform), 0x198ee (clip), 0x153b4 (clip apply), 0x46366 (error), 0x365aa (path), 0x3bb98 (stroke), 0x31334 (fill), 0x47858 (clip), 0x47656 (stroke), 0x18178 (grestore), 0x31ddc (cleanup)  
**Algorithm:** Saves graphics state, sets up clipping, checks operation type (0=fill, 1=stroke, 2=clip), dispatches to appropriate renderer, restores state.

### 8. 0x43418 - `set_line_width_with_cap`
**Entry:** 0x43418  
**Purpose:** Sets line width and cap style for stroke operations. Converts width to device coordinates, applies scaling, and stores result in graphics state.  
**Arguments:** FP@(8): Line width, FP@(12): Cap style, FP@(16,20,24): Additional parameters  
**Return:** D0 = transformed line width  
**Hardware:** Accesses 0x2017464 (graphics context)  
**Key calls:** 0x899c8 (float to int), 0x15526 (convert), 0x1b708 (scale), 0x3ce34 (unknown), 0x89ab8 (float divide), 0x899b0 (float multiply), 0x22f8a (transform), 0x1556e (store), 0x89a88 (int to float)  
**Algorithm:** Converts width to device coordinates, applies cap style adjustments, scales appropriately, stores in graphics state.

### 9. 0x43536 - `set_line_width_from_stack`
**Entry:** 0x43536  
**Purpose:** Reads line width from PostScript stack and calls 0x43418 to set it.  
**Key calls:** 0x3b81a (pop value), 0x89a88 (convert), 0x3418 (set_line_width_with_cap)  
**Algorithm:** Pops width from stack, converts to float, calls line width setter.

### 10. 0x43578 - `calculate_dash_pattern`
**Entry:** 0x43578  
**Purpose:** Calculates dash pattern parameters for stroked paths. Converts dash array to device coordinates.  
**Arguments:** FP@(8): Dash offset, FP@(12): Dash array pointer  
**Return:** D0,D1 = transformed dash parameters  
**Key calls:** 0x899c8, 0x15526, 0x1b708, 0x3ce34, 0x899b0, 0x22f8a, 0x1556e  
**Algorithm:** Similar to line width calculation but for dash patterns.

### 11. 0x43654 - `transform_angle_for_arcto`
**Entry:** 0x43654  
**Purpose:** Transforms an angle for arcto operations, handling quadrant adjustments and sign.  
**Arguments:** FP@(8,12): Angle, FP@(16): Result pointer  
**Return:** Stores transformed angle  
**Hardware:** Accesses 0x2000ec0 (angle flag), 0x20174d8 (reference angle)  
**Key calls:** 0x899c8, 0x3ce34, 0x89a40 (float absolute), 0x89a88, 0x89968, 0x899f8 (float negate), 0x89aa0, 0x89920  
**Algorithm:** Converts angle, checks quadrant, applies sign correction, stores result.

### 12. 0x43754 - `calculate_bezier_control_points`
**Entry:** 0x43754  
**Purpose:** Calculates control points for Bézier curves given endpoints and tension parameters.  
**Arguments:** FP@(8,12,16,20,24,28): Various curve parameters  
**Return:** Stores results in provided pointers  
**Hardware:** Accesses 0x2000ecc (curve flag)  
**Key calls:** 0x89aa0, 0x899c8, 0x15526, 0x89920, 0x89a58, 0x15502, 0x3654 (transform_angle_for_arcto), 0x1554a  
**Algorithm:** Computes intermediate control points using tension parameters and curve mathematics.

### 13. 0x43868 - `adjust_curve_parameters`
**Entry:** 0x43868  
**Purpose:** Adjusts curve parameters based on transformation state.  
**Arguments:** FP@(8,12,16,20,24): Curve parameters  
**Return:** Stores adjusted parameters  
**Hardware:** Accesses 0x2000ecc (curve flag)  
**Key calls:** 0x899c8, 0x15502, 0x89a88, 0x3654, 0x1554a  
**Algorithm:** Similar to 0x43754 but with different parameter handling.

### 14. 0x438e6 - `compute_curve_tension`
**Entry:** 0x438e6  
**Purpose:** Computes tension parameter for curve smoothing.  
**Arguments:** FP@(8,12,16,20,24,28): Curve parameters  
**Return:** Stores tension value  
**Key calls:** 0x89920, 0x89a58, 0x899c8, 0x15526, 0x386a (unknown), 0x89a88  
**Algorithm:** Calculates tension based on curve geometry and control points.

### 15. 0x439b4 - `transform_point_with_matrix`
**Entry:** 0x439b4  
**Purpose:** Transforms a point using a specific transformation matrix (A5 points to matrix).  
**Arguments:** A5: Matrix pointer, FP@(8): Point to transform  
**Return:** Transformed point in place  
**Hardware:** Accesses 0x2000ecc (transform flag), 0x2000eb8 (matrix flag), 0x2000ec8/0x2000ec4 (matrix)  
**Key calls:** 0x22f26 (matrix multiply), 0x30de (simple transform)  
**Algorithm:** Checks flags to determine which matrix to use, applies transformation.

### 16. 0x43a06 - `transform_point_wrapper`
**Entry:** 0x43a06  
**Purpose:** Wrapper for 0x439b4 that handles parameter passing.  
**Arguments:** FP@(8,12,16): Point coordinates  
**Return:** Transformed point  
**Key calls:** 0x39b4 (transform_point_with_matrix), 0x15502 (store)  
**Algorithm:** Calls transformation with appropriate parameters.

### 17. 0x43a34 - `clip_to_rectangle`
**Entry:** 0x43a34  
**Purpose:** Sets up rectangular clipping region.  
**Arguments:** FP@(8): Rectangle pointer, FP@(12): Clip mode  
**Key calls:** 0x46aec (rectangle setup), 0x19816 (apply clip)  
**Algorithm:** Sets up rectangle bounds and applies clipping.

### 18. 0x43a62 - `find_glyph_in_font`
**Entry:** 0x43a62  
**Purpose:** Searches for a glyph in a font dictionary.  
**Arguments:** FP@(8): Font pointer, FP@(12,16): Glyph coordinates, FP@(20): Result pointer  
**Return:** D0 = glyph index or -1 if not found  
**Hardware:** Accesses 0x2000eb4/0x2000eb0 (font data), 0x20174d4/0x20174d0 (glyph table)  
**Key calls:** 0x2f986 (font lookup), 0x308fa (transform), 0x46aec (glyph extract)  
**Algorithm:** Transforms coordinates, searches glyph table, returns index.

### 19. 0x43af0 - `render_glyph_outline`
**Entry:** 0x43af0  
**Purpose:** Renders a glyph outline using Bézier curves.  
**Arguments:** A5: Glyph data pointer, FP@(12,16,20,24): Rendering parameters  
**Key calls:** 0x4c1e4 (extract outline), 0x89a10 (int to float), 0x1554a (store), 0x22f26 (transform), 0x1556e (store)  
**Algorithm:** Extracts outline points, converts to device coordinates, applies transformations, renders curves.

### 20. 0x43bb4 - `check_path_intersection`
**Entry:** 0x43bb4  
**Purpose:** Checks if a path intersects with a given rectangle.  
**Arguments:** FP@(8,12,16,20): Rectangle coordinates  
**Return:** D0 = intersection result  
**Hardware:** Accesses 0x2000ddc/0x2000dd8 (path bounds)  
**Key calls:** 0x30708 (bounds check), 0x308fa (transform)  
**Algorithm:** Compares path bounds with rectangle, returns intersection status.

- 0x43338-0x43342: Jump table for operation dispatch (5 entries, 2 bytes each)
- 0x4374e-0x43754: Float constant 0.5 (3FE00000 00000000)
- 0x43862-0x43868: Float constant 0.5 (3FE00000 00000000)
- 0x439ac-0x439b2: Float constant 0.5 (3FE00000 00000000)

## CORRECTIONS FROM PRIOR ANALYSIS:
1. Function at 0x43248 is `render_path_with_clipping` not truncated as shown.
2. Function at 0x43418 is `set_line_width_with_cap` not generic line width setter.
3. Function at 0x43654 is `transform_angle_for_arcto` not generic angle transform.
4. Multiple curve-related functions (0x43754, 0x43868, 0x438e6) handle Bézier curve mathematics.
6. All code regions correctly identified (no data misidentified as code).

This region contains core PostScript graphics operations: transformation matrices, path rendering with clipping, line styling (width/dash), curve mathematics (Bézier control points), and font/glyph rendering. The functions use extensive software FPU calls (0x899xx-0x89axx) for floating-point operations. The code follows standard C calling conventions with LINK/UNLK frames.

; === CHUNK 6: 0x43C00-0x44800 ===

### 1. 0x43c00 - `process_object_or_name`
**Entry:** 0x43c00  
**Purpose:** Processes a PostScript object, specifically handling names (type 9) and operators (type 13). Validates the object type and subtype, then calls a processing function.  
- fp@(8): Object pointer  stack frame parameter
- fp@(12): Unknown parameter  stack frame parameter
- fp@(24): Callback/context parameter  stack frame parameter
- 0x30708: Type validation function  
- 0x308fa: Object transformation/conversion  
- 0x3a34: Object processing function  
1. Calls 0x30708 to validate object type  
2. If valid, calls 0x308fa to transform/convert the object  
3. Checks low 4 bits of result: type 9 (name) or 13 (operator)  
4. Validates subtype (word at offset -14) is ≥ 2  
5. Calls 0x3a34 with transformed object and callback  
**Note:** This is NOT a "graphics object" processor - it's a generic object processor for names and operators.

### 2. 0x43c70 - `create_graphics_state` (CORRECTED)
**Entry:** 0x43c70  
**Purpose:** Creates a graphics state structure (108 bytes) for rendering operations. Performs complex coordinate transformations, clipping calculations, and matrix operations.  
- A5: Pointer to transformation matrix (12 bytes: A,B,C,D,Tx,Ty)  
- fp@(12)-(28): Various coordinate parameters  coordinate data  (font metric data)
- fp@(44)-(52): Additional transformation parameters  stack frame parameter
**Return:** A4 points to newly allocated 108-byte graphics state structure  
- 0x899c8: Float conversion (likely integer to float)  
- 0x308fa: Coordinate transformation  
- 0x89a40: Float operation  
- 0x3a62: Unknown processing  
- 0x3bb4: Transformation application  
- 0x89a88/0x89aa0/0x89920: Float operations (convert, multiply, etc.)  
- 0xf35e: Lookup function  
- 0x3af0: Calculation function  
- 0xed64/0xedea: Geometric operations (likely vector math)  
- 0xe154: Setup/initialization  
- 0x48344: malloc(108 bytes)  
- 0x2000da0/da4: Current transformation state  
- 0x2017354: PostScript context pointer  
- 0x2000e28/e2c: Clipping bounds  
- 72-75: y-scale factor (fp@(-112))  (PS CTM operator)
- 76-79: x-scale factor (fp@(-116))  (PS CTM operator)
- 80-83: Matrix element C? (fp@(-100))  stack frame parameter
- 84-87: Matrix element A? (fp@(-104))  stack frame parameter
- 88-91: Matrix element D? (fp@(-108))  stack frame parameter
- 92-95: Transformed point 1 X  
- 96-99: Transformed point 1 Y  
- 100-103: Transformed point 2 X  
- 104-107: Transformed point 2 Y  
1. Converts input coordinates to floating point  
2. Applies current transformation matrix  
3. Calculates scaling factors for x and y axes  
4. Transforms clipping bounds  
5. Performs geometric calculations (likely for bounding boxes or paths)  
6. Allocates 108-byte structure and populates with transformation data

### 3. 0x4419a - FLOATING POINT CONSTANT (CORRECTED)
**Address:** 0x4419a  
**Type:** IEEE 754 single-precision floating point constant  
**Value:** 0x40000000 = 2.0  
**Note:** Referenced at 0x43f34 via `lea %pc@(0x419a),%a0` - used as scaling factor

### 4. 0x441a0 - `transform_rectangle_points`
**Entry:** 0x441a0  
**Purpose:** Transforms a rectangle defined by 6 points (24 bytes) using scaling factors. Reorders points based on geometric comparisons to maintain consistent winding order.  
- A5: Pointer to rectangle data (6 points = 24 bytes)  
- fp@(12)/(16): X and Y scaling factors  stack frame parameter  (PS graphics transform)
- fp@(20): First callback function (comparison/processing)  stack frame parameter
- fp@(24): Second callback function (final processing)  stack frame parameter
- 0x899c8: Float conversion  
- 0x89938: Float multiplication  
- 0x89a88: Float conversion (to double?)  
- Callback functions via A0  
- 0x2000ecc: Transformation flag (skip if zero)  
1. Checks if transformation needed (0x2000ecc flag)  
2. Scales all rectangle points by scaling factors  
3. Calls first callback to process transformed points  
4. Reorders points based on geometric comparisons (maintains clockwise order)  
5. Calculates differences between points and calls second callback

### 5. 0x44462 - `transform_rectangle_points_wrapper_1`
**Entry:** 0x44462  
**Purpose:** Wrapper function that calls `transform_rectangle_points` with specific callback addresses.  
- fp@(8): Rectangle pointer  stack frame parameter
- fp@(12)/(16): Scaling factors  stack frame parameter
- fp@(20): Unknown parameter  stack frame parameter
- 0x41a2: Actually calls `transform_rectangle_points` at 0x441a0  
**Note:** Passes callback addresses 0x2e58 and 0x38e6 to the main function.

### 6. 0x44486 - `transform_rectangle_points_wrapper_2`
**Entry:** 0x44486  
**Purpose:** Another wrapper function that calls `transform_rectangle_points` with different callback addresses.  
- fp@(8): Rectangle pointer  stack frame parameter
- fp@(12)/(16): Scaling factors  stack frame parameter
- fp@(20): Unknown parameter  stack frame parameter
- 0x41a2: Actually calls `transform_rectangle_points` at 0x441a0  
**Note:** Passes callback addresses 0x2df2 and 0x3756 to the main function.

### 7. 0x444aa - `extract_object_components`
**Entry:** 0x444aa  
**Purpose:** Extracts components from a PostScript object, handling different object types (1=int, 2=real, 4=bool, etc.). Returns count and component values.  
- fp@(8): Object pointer  stack frame parameter
- fp@(12): Unknown parameter  stack frame parameter
- fp@(16): Output array for components  stack frame parameter
- fp@(20): Pointer to store component count  stack frame parameter
- fp@(24): Pointer to store first component values  stack frame parameter
- fp@(28): Pointer to store second component values  stack frame parameter
- 0x30708: Type validation  
- 0x308fa: Object transformation  
- 0x19816: Processing for type 1 (integer)  
- 0x3a34: Object processing  
- 0x46366: Error handler  
1. Validates object type  
2. Transforms object  
3. Based on object type (low 4 bits), extracts components:  
   - Type 1 (int): Calls 0x19816, sets count=1  
   - Type 2 (real): Checks subtype (2 or 4), extracts 2 or 4 components  
   - Type 4 (bool): Similar logic  
4. Stores results in output parameters

### 8. 0x44650 - `extract_path_components`
**Entry:** 0x44650  
**Purpose:** Extracts path components from a PostScript object, handling different path types and counts.  
- fp@(8): Object pointer  stack frame parameter
- fp@(12): Unknown parameter  stack frame parameter
- fp@(16): Output array for first set of components  stack frame parameter
- fp@(20): Pointer to store first count  stack frame parameter
- fp@(24): Output array for second set of components  stack frame parameter
- fp@(28): Pointer to store second count  stack frame parameter
- 0x3072c: Type validation  
- 0x30958: Object transformation  
- 0x3a34: Object processing  
- 0x46366: Error handler  
1. Validates object type against first reference (0x2000db8/dbc)  
2. If valid, extracts components based on subtype (0-14)  
3. Processes first 2 components into first array  
4. Processes remaining components into second array  
5. Validates against second reference (0x2000e98/e9c)  
6. If valid, extracts additional components

### 9. 0x447b8 - `process_complex_object` (INCOMPLETE)
**Entry:** 0x447b8  
**Purpose:** Processes a complex object with multiple parameters, likely related to path or graphics operations.  
- fp@(8): Object pointer  stack frame parameter
- fp@(12): Unknown parameter  stack frame parameter
- fp@(20): Parameter 1  stack frame parameter
- fp@(28): Parameter 2  stack frame parameter
- fp@(32)/(36): Additional parameters  stack frame parameter
- 0x3072c: Type validation  
- 0x3578: Unknown function  
- 0x899c8: Float conversion  
**Note:** Function is truncated in the disassembly at 0x447fc.

3. **Data vs Code**: All addresses in this range appear to be valid code. The floating point constant at 0x4419a is embedded in the code section but correctly referenced via PC-relative addressing.

4. **Structure size**: The graphics state structure is confirmed to be 108 bytes (0x6c), allocated via malloc(108) at 0x44146.

5. **Callback system**: The rectangle transformation functions use a callback system where different wrapper functions provide different callback addresses for processing.

The analysis shows this region contains core graphics state management and object processing functions that are critical for PostScript rendering operations.

; === CHUNK 7: 0x44800-0x45400 ===

1. **0x44800 is NOT a function start** - This is correct. The code at 0x44800 begins with `subal %a0,%a4` which is clearly in the middle of a function.

2. **0x448b4 IS a function** - Has `linkw %fp,#-12` at 0x448b2-448b6.

3. **0x497e IS a function** - Has `linkw %fp,#-24` at 0x497e.

4. **0x4a00 IS a function** - Has `linkw %fp,#-84` at 0x4a00-4a04.

5. **0x4d76 IS a function** - Has `linkw %fp,#-128` and `moveml %d6-%d7/%a4-%a5,%sp@` at 0x4d76-4d7c.

### 1. Function at 0x448b4 (corrected from prior)
**Entry:** 0x448b4  
**Name:** `normalize_vector_2d`
**Purpose:** Normalizes a 2D vector (x,y) by computing its magnitude and adjusting signs. Handles special cases where components are negative by flipping sign bits. Computes sqrt(x² + y²) using floating-point operations.  
**Arguments:** A5 points to input vector (x at offset 0, y at offset 4), A0 points to output magnitude (via fp@(12)).  
**Return:** Magnitude stored at output pointer, no register return.  
**Hardware/RAM:** Calls 0x15526 (vector magnitude?), 0x89980 (float compare), 0x89a88 (int→float), 0x89920 (float multiply), 0x899c8 (float→int).  
**Key algorithm:** Computes max(|x|,|y|), normalizes, computes sqrt(x²+y²) with proper sign handling.

### 2. Function at 0x497e  
**Entry:** 0x497e  
**Name:** `check_normalized_vector_limit`
**Purpose:** Checks if a normalized vector's magnitude exceeds a limit (0.375). Creates test vectors (0.375,0) and (0,0.375), normalizes them, compares magnitudes. Returns true if input exceeds limit.  
**Return:** D0 = 1 if limit exceeded, 0 otherwise.  
**Hardware/RAM:** Calls 0x48b4 (normalize_vector_2d), 0x89980 (float compare), 0x89a88 (int→float), 0x89968 (float compare).  
**Key constants:** 0x447a0000 = 1000.0 (float), 0x40180000 = 2.375 (float).

### 3. Function at 0x4a00  
**Entry:** 0x4a00  
**Name:** `calculate_stroke_parameters`
**Purpose:** Calculates stroke width parameters for line drawing/rendering. Handles different stroke modes (butt, round, square caps). Computes miter limits, stroke scaling factors.  
**Arguments:** Multiple via stack: fp@(8,12)=coord1, fp@(16,20)=coord2, fp@(24,28)=output params.  
**Return:** Results stored in output pointers.  
**Hardware/RAM:** Accesses 0x2000ea0/ea4 (stroke params), 0x2017354 (graphics state), calls 0x308fa, 0x3072c, 0x30958, 0x3a34, 0x3be16, 0x3b81a, many float ops.  
**Key algorithm:** Checks stroke mode flags, computes scaling based on line angle, applies miter limits, handles special cases for horizontal/vertical lines.

### 4. Function at 0x4d76  
**Entry:** 0x4d76  
**Name:** `transform_stroke_coordinates`
**Purpose:** Transforms stroke coordinates through the CTM (Current Transformation Matrix). Handles arrays of coordinate pairs, applies clipping, and computes transformed bounds.  
**Arguments:** A5=coord array pointer, fp@(12,16)=array1 ptr/size, fp@(20,24)=array2 ptr/size, fp@(28)=CTM params.  
**Return:** Transformed coordinates in arrays.  
**Hardware/RAM:** Accesses 0x2000ecc/ebc (transform flags), calls 0x89a88 (int→float), 0x89920 (float multiply), 0x899c8 (float→int), 0x89938 (float add), 0x89ab8 (float subtract).  
**Key algorithm:** Loops through coordinate pairs (0x4e70-0x53cc), applies CTM, clips to bounds, handles sign changes.

### 5. Data at 0x5472 (NOT a function)
**Address:** 0x5472  
**Type:** Floating-point constant table  
- 0x5472: 0x3FD58793DD97F62B ≈ 0.3375 (double)
- 0x547a: 0x3FE0000000000000 = 0.5 (double)  
- 0x5482: 0x3FDCCCCCCCCCCCCD ≈ 0.45 (double)
- 0x548a: Likely continues with more constants

### 6. Code at 0x44800 (continuation of earlier function)
This is clearly in the middle of a function that started before 0x44800. The code:
- Uses A4, A0 registers
- Calls 0x89a88 (int→float), 0x89aa0 (float→double?), 0x89a58 (double multiply), 0x899c8 (float→int)
- Has loops at 0x4858-0x4878 and 0x4880-0x48a0
- Likely part of a coordinate transformation or scaling function  coordinate data  (font metric data)

### 7. Function at 0x448ac (data, not code)
**Address:** 0x448ac  
**Type:** Floating-point constant  
**Content:** 0x3FE0000000000000 = 0.5 (double)  
This is referenced by the code at 0x44826 via `lea %pc@(0x48ac),%a0`

### 8. Function at 0x44976 (data, not code)
**Address:** 0x44976  
**Type:** Floating-point constant  
**Content:** 0x3FD58793DD97F62B ≈ 0.3375 (double)  
This is referenced by the normalize_vector_2d function at 0x4491e

### 9. Function at 0x449f8 (data, not code)
**Address:** 0x449f8  
**Type:** Floating-point constant  
**Content:** 0x4018000000000000 = 2.375 (double)  
Used by check_normalized_vector_limit at 0x449d6

### 10. Function at 0x44d4c (data, not code)
**Address:** 0x44d4c  
**Type:** Floating-point constant table (multiple entries)
- 0x44d4c: 0x4024000000000000 = 2.5 (double)
- 0x44d54: 0x3FECCCCCCCCCCCCD ≈ 0.9 (double)
- 0x44d5c: 0x3FE0000000000000 = 0.5 (double)
- 0x44d64: 0x3FDCCCCCCCCCCCCD ≈ 0.45 (double)
- 0x44d6c: 0x4000000000000000 = 2.0 (double)

1. **Vector normalization** is a critical operation in this graphics subsystem, used for stroke calculations and coordinate transformations.

2. **Stroke parameter calculation** involves complex math with miter limits, stroke caps, and scaling factors based on line angles.

3. **Coordinate transformation** handles arrays of points through the CTM with clipping and bounds checking.

4. **Floating-point constants** are embedded throughout the code for various thresholds and scaling factors (0.3375, 0.5, 0.45, 2.375, etc.).

5. **The code heavily uses software floating-point emulation** (calls to 0x899xx, 0x89axx) even though the system has a 68881/68882 FPU option, suggesting this is fallback code or compiled with software FPU.

6. **Memory addresses 0x2000exxx** appear to be graphics state variables (stroke params, transform flags, etc.), while 0x2017354 is the graphics state structure pointer.

; === CHUNK 8: 0x45400-0x46000 ===

### 1. Function at 0x45400
**Entry:** 0x45400  
**Name:** `normalize_and_compare_coordinates`
**Purpose:** Normalizes coordinate values by handling sign bits (bit 31) and performs floating-point comparisons. It appears to process coordinate pairs for graphics operations, possibly for font rendering or path transformations. The function checks if values are negative and conditionally flips the sign bit.  
**Arguments:** Receives coordinate values via stack/frame pointer (fp@(-64), fp@(-60), fp@(-32)).  
**Return:** Result in D0 (floating-point comparison result).  
**Hardware/RAM:** Accesses fp@(-64), fp@(-60), fp@(-32) local variables.  
**Call targets:** 0x89a88 (float conversion), 0x386a (unknown), 0x2e58 (unknown).  
### 2. Data Region at 0x45472-0x4548E (NOT code)
**Address:** 0x45472-0x4548E  
**Format:** Floating-point constant table (likely double-precision values for graphics/math operations).  
**Content:** Contains IEEE 754 double-precision constants: 0x3FE0000000000000 (1.0), 0xBFDFEF9DB22D0E56 (~ -0.498), 0x3FDFEF9DB22D0E56 (~ 0.498), 0x4000000000000000 (2.0).

### 3. Function at 0x45490
**Entry:** 0x45490  
**Name:** `update_graphics_state_matrix`
**Purpose:** Updates the graphics state transformation matrix by extracting values from the system graphics state structure at 0x2017464. Performs normalization of matrix elements, selects the larger absolute value between pairs, and applies scaling/normalization operations. This is part of the PostScript graphics state management.  
**Hardware/RAM:** Accesses 0x2017464 (graphics state pointer), calls 0x15526 (normalize), 0x3ce34 (unknown), 0x89a88 (float conversion), 0x89a58, 0x89920, 0x899c8 (float ops), 0x1ef94 (store matrix).  
**Called by:** Graphics state update routines.

### 4. Data Region at 0x456B6-0x456BC
**Address:** 0x456B6-0x456BC  
**Format:** Floating-point constant (double-precision 1.0).  
**Content:** 0x3FE0000000000000 (1.0).

### 5. Function at 0x456BE
**Entry:** 0x456BE  
**Name:** `check_system_limits_and_flags`
**Purpose:** Checks various system configuration limits and flags to determine operational mode. Tests values against thresholds (likely for coordinate ranges or memory limits) and sets system flags at 0x2000ebc. Returns status code indicating which limit was exceeded.  
**Return:** D0 = -1 (first limit exceeded), 0 (within limits), 1 (second limit exceeded).  
**Hardware/RAM:** Accesses 0x2000ebc (system flag), calls 0x1522c (get value), 0x42ca4 (unknown), 0x89a88 (float conversion), 0x89968 (float compare).  
**Called by:** System initialization/configuration routines.

### 6. Data Region at 0x457F6-0x457FC
**Address:** 0x457F6-0x457FC  
**Format:** Floating-point constants (threshold values).  
**Content:** Two double-precision values used as comparison thresholds.

### 7. Function at 0x457FE
**Entry:** 0x457FE  
**Name:** `calculate_parameter_or_ratio`
**Purpose:** Calculates a parameter or ratio based on input coordinates. Checks if coordinates are valid (non-zero) and either computes a ratio or returns a default value. Used in graphics calculations for scaling or transformation ratios.  
**Arguments:** 8 parameters on stack (likely 4 coordinate pairs).  
**Return:** Result stored at address provided in fp@(32).  
**Hardware/RAM:** Calls 0x3072c (coordinate check), 0x30958 (ratio calculation), 0x19816 (unknown).  
### 8. Function at 0x45874
**Entry:** 0x45874  
**Name:** `validate_and_process_coordinates`
**Purpose:** Validates coordinate pairs and processes them through a secondary function. If validation fails, calls error handler at 0x46366.  
**Arguments:** 5 parameters on stack (coordinate pairs and a result pointer).  
**Hardware/RAM:** Calls 0x30708 (coordinate validation), 0x46366 (error handler), 0x308fa (coordinate processing).  
### 9. Function at 0x458BE
**Entry:** 0x458BE  
**Name:** `process_font_or_glyph_data`
**Purpose:** Complex function that processes font or glyph data, including coordinate transformations, matrix updates, and data validation. Appears to handle font rendering operations with extensive coordinate math and state management.  
**Arguments:** Multiple parameters on stack (likely font/glyph data pointers).  
**Return:** Unknown (complex multi-branch function).  
**Hardware/RAM:** Extensive use of local variables (348 bytes), accesses 0x2017354 (font dictionary), 0x20008f4 (execution context), calls many functions including 0x48344 (malloc), 0x4df1c (unknown), 0x3072c, 0x30958, 0x44aa, 0x4650, 0x47b8, 0x57fe, 0x4a00, 0x3862c, etc.  
**Called by:** Font rendering system.

### 10. Data Region at 0x45E9A-0x45F00
**Address:** 0x45E9A-0x45F00  
**Format:** Jump table for switch/case statement.  
**Content:** 16-bit offsets for a switch statement starting at 0x45E9A. The offsets point to various case handlers within the function at 0x458BE.

### 11. Switch Case Handlers (within 0x458BE function)
The function at 0x458BE contains a large switch statement with multiple case handlers. Some notable handlers:
- **Case 0 (0x45EA4):** Toggles system flag at 0x2000eb8
- **Case 1 (0x45F48):** Processes coordinate data from fp@(-196)
- **Case 2 (0x45F64):** Processes coordinate data from fp@(-200)
- **Case 3 (0x45F80):** Updates graphics state matrix based on fp@(-132) flag
- **Case 4 (0x45FE8):** Performs floating-point multiplication and normalization

2. The function at 0x456BE was misnamed - it's checking system limits, not just flags.
4. The data at 0x45E9A-0x45F00 is a jump table, not code.
5. The function at 0x45874 is separate from 0x457FE, not a continuation.

- The region contains significant floating-point math operations, indicating graphics/coordinate processing.  coordinate data  (font metric data)
- Multiple functions access the graphics state at 0x2017464, confirming this is part of the PostScript graphics subsystem.
- The function at 0x458BE is particularly complex (over 1KB) and appears to be a major font/glyph processing routine.
- The use of malloc (0x48344) suggests dynamic memory allocation for font/glyph data structures.  (PS font cache)

; === CHUNK 9: 0x46000-0x46C00 ===

### 1. Main Operator Dispatch Function: 0x46000-0x46942
**Name:** `operator_dispatch_monolithic`
**What it does:** This is NOT a dispatch function - it's a large monolithic function containing implementations of multiple PostScript operators. The code at 0x46944 is a jump table INSIDE this function, not a separate function. The function contains inline implementations of operators like `add`, `sub`, `mul`, `max`, `neg`, `conditional`, `dup`, `exch`, `roll`, `index`, `abs`, `ceiling`, etc.
**Arguments:** Takes operator code in D7 (based on usage at 0x47212-0x47240), with A3 as operand stack pointer, A4 as current transformation matrix pointer
**Return values:** Varies by operator
- 0x02017464 (current transformation matrix)
- 0x020174d8 (unknown RAM variable)
- 0x02000e50-0x02000ec8 (RAM data structures for literals)
- Calls to math routines at 0x89938 (add), 0x89ab8 (sub), 0x899b0 (mul), 0x89980 (compare)
- 0x65d8: Common cleanup/return path (sets A3 = A4)
- 0x68d8: Continue execution loop
- 0x7212: Dispatch via jump table at 0x46944

### 2. Jump Table Data: 0x46944-0x4698C
**What it is:** A jump table WITHIN the monolithic function at 0x46000. Contains 46 entries (0x00-0x2D) as word offsets from 0x4694c.
**Data structure:** Word offsets (16-bit signed) from 0x4694c
**Purpose:** Dispatches to specific operator implementations within the same function based on opcode in D7

### 3. Operator Implementations (within 0x46000-0x46942):

#### `arithmetic_operators` — Arithmetic Operators:
- **0x461f8**: `operator_add` - Adds two numbers: pops D1, D0 from stack, calls 0x89938 (add), pushes result
- **0x4620c**: `operator_sub` - Subtracts: pops D1, D0, calls 0x89ab8 (subtract), pushes result  
- **0x46220**: `operator_mul` - Multiplies: pops D1, D0, calls 0x899b0 (multiply), pushes result
- **0x46234**: `operator_max` - Maximum of two numbers: pops D5, compares with stack[-1], pushes larger
- **0x4625a**: `operator_neg` - Negates: flips bit 31 (sign bit) of stack[-1]
- **0x46264**: `operator_conditional` - Conditional execution: pops D5 (condition), D1 (false), D0 (true), compares, executes true branch if condition > 0

#### `stack_operators` — Stack Operators:
- **0x465c6**: `operator_dup` - Duplicates top stack element: pushes fp@(-12), fp@(-8) (saved values)
- **0x465d0**: `operator_exch` - Exchanges top two stack elements: pops to fp@(-8), fp@(-12)
- **0x464aa**: `operator_roll` - Rolls stack elements: swaps stack[-1] and stack[-2]
- **0x464bc**: `operator_index` - Indexes into stack: converts stack[-1] to integer, indexes back that many elements

#### `transformation_matrix_operators` — Transformation/Matrix Operators:
- **0x46000**: `operator_transform` - Coordinate transformation with matrix multiplication
- **0x46124**: `operator_concat` - Concatenate matrices: complex matrix math with calls to 0x89938, 0x89ab8, 0x899c8
- **0x46448**: `operator_currentmatrix` - Get current matrix: reads from A4, processes

#### `type_conversion` — Type Conversion:
- **0x46426**: `operator_cvi` - Convert to integer: calls 0x89a88 (convert to float?), then 0x3578, then 0x899c8

#### `math_functions` — Math Functions:
- **0x464da**: `operator_abs` - Absolute value: checks sign of A4@(4), negates if negative
- **0x46550**: `operator_ceiling` - Ceiling function: similar structure to abs but with different constants

#### `literal_operators` — Literal Operators (0x463c8-0x4641c):
- **0x463c8**: Pushes address 0x2000e10 to A0, branches to 0x7176
- **0x463d2**: Pushes address 0x2000e18 to A0, branches to 0x7176
- **0x463dc**: Pushes address 0x2000e20 to A0, branches to 0x7176
- **0x463e6**: Reads A4@, converts with 0x89a40, stores to 0x2017464+0xA4 with bfins
- **0x463fe-0x46422**: Similar literal pushes for addresses 0x2000e30, 0x2000e38, 0x2000e40, 0x2000e48

### 4. Byte Stream Decoding Section: 0x465de-0x46794
**What it does:** Decodes encrypted/encoded byte streams. This appears to be an eexec decryption routine for Adobe Type 1 fonts. Uses a PRNG with multiplier 0x3FC5CE6D and additive constant 0x0D8658BF (matches known Adobe eexec constants).
- Reads bytes from stream (either from A5 or via file handle at fp@(-176))  stack frame parameter
- Updates CRC-like state at fp@(-120)  stack frame parameter
- XORs bytes with PRNG state
- Builds 32-bit values from 4 bytes
**Hardware/RAM accessed:** fp@(-120) for PRNG state, fp@(-176) for file handle

### 5. Encoded Value Decoding: 0x46798-0x468d2
**What it does:** Decodes different types of encoded values from the stream:
- **0x46798-0x46826**: Handles values 251-254 (negative encoded integers)
- **0x4682a-0x468b6**: Handles values 247-250 (positive encoded integers)  
- **0x468b8-0x468d2**: Handles values 139-246 (small integers)
**Algorithm:** Reads additional bytes, combines with base value, converts to integer

### 6. Stream Reading Loop: 0x468d4-0x46942
**What it does:** Main loop for reading encoded bytes from stream. Reads next byte, updates PRNG state, branches to 0x7212 (which uses the jump table).
**Hardware/RAM accessed:** fp@(-120) for PRNG state, fp@(-176) for file handle, A5 for direct memory access

### 7. Post-Jump Table Code: 0x4698e-0x46c00
**What it is:** Continuation of operator implementations after the jump table:
- **0x4698e-0x46a06**: More matrix/transformation operations
- **0x46a0a-0x46abc**: Additional math operations with calls to 0x89938, 0x89ab8
- **0x46ac0-0x46b7a**: Coordinate transformation and matrix operations
- **0x46b7c-0x46bd0**: Complex matrix concatenation operations
- **0x46bd4-0x46be8**: Calls 0x1be24 with matrix address
- **0x46bec-0x46bfe**: Loop operator implementation (compares fp@(-220) to 10)

1. **NOT a dispatch function:** The code at 0x46000 is a monolithic function containing operator implementations, not a dispatch function that calls other functions.

2. **Jump table is internal:** The jump table at 0x46944 is INSIDE this function, not a separate function.

3. **Byte decoding is eexec:** The code at 0x465de-0x46794 is Adobe eexec decryption for Type 1 fonts, not generic "stream decoding".

4. **Operator implementations are inline:** Each operator (add, sub, mul, etc.) is implemented directly in this function, not as separate functions.

5. **Common return paths:** 0x65d8 and 0x68d8 are common return/continuation points within this function.

- This is a performance-critical section of the PostScript interpreter where common operators are implemented inline for speed
- The eexec decryption is built into the interpreter for handling encrypted Adobe Type 1 fonts
- The jump table allows efficient dispatch within this large function based on opcode in D7
- Matrix/transformation operations are complex and involve multiple floating-point calls

; === CHUNK 10: 0x46C00-0x47800 ===

1. **0x46C00 is NOT a separate function** - it's a continuation of the large operator handler function that starts at 0x46000
2. **The PRNG at 0x46CF6 is NOT the C runtime LCG** - it's a different algorithm used for PostScript byte stream decoding
3. **0x46944 is a jump table (data), not code** - it's referenced at 0x47218
4. **0x47390, 0x47420, and 0x47656 ARE separate functions** - they have LINK/UNLK and RTS

### 1. CONTINUATION OF OPERATOR HANDLER (0x46C00-0x47388)

**Entry:** 0x46C00 (continuation from 0x46000)
**Purpose:** This is the main operator dispatch and execution loop for PostScript operators. It handles byte stream decoding, operator execution, and control flow.
- Uses A4 as operand stack pointer, A3 as execution stack pointer
- Contains byte stream reading logic with two modes: direct memory access (0x46CB0-0x46CD4) and callback-based I/O (0x46CD6-0x46CE6)
- Implements a PRNG-like algorithm for decoding encrypted streams (0x46CF6-0x46D0A)
- Contains implementations for various PostScript operators
**Arguments:** Uses frame pointer (FP) offsets for local variables
**Hardware/RAM:** Accesses 0x2000DD0-DD4 (dictionary references), 0x2017464 (graphics state)
**Call targets:** 0x30958 (dictionary lookup), 0x2FA3E (object creation), 0x46366 (error handler)

#### `byte_stream_decoder` — Byte Stream Decoder (0x46C00-0x46D4E)
**Purpose:** Reads bytes from input stream with buffering and callback support
1. Checks if in direct mode (ff80 != 0) or callback mode
2. If direct: decrements count, reads byte from buffer pointer
3. If callback: calls function pointer at offset 0xE in stream structure
4. Updates PRNG state with byte value
**Hardware/RAM:** Stream structure at FP@(-176) with fields: count@0, ptr@4, callback@0xE

#### `postscript_prng` — PostScript PRNG (0x46CF6-0x46D0A)
**Purpose:** Generates pseudo-random numbers for eexec decryption
**Algorithm:** `state = (state + byte) * 0x3FC5CE6D + 0x0D8658BF`
**Note:** This is distinct from the C runtime LCG at 0x8D8A0 (multiplier 0x41C64E6D)

#### `operator_implementations_in_this_range` — Operator Implementations in this range:

**`setmatrix` (0x46E00-0x46FFC)**
**Purpose:** Sets the current transformation matrix (CTM)
1. Converts 6 matrix elements from fixed-point to floating-point
2. Updates CTM in graphics state at 0x2017464+44
3. Calls transformation update functions
**Arguments:** Takes [a b c d tx ty] from operand stack
**Call targets:** 0x89A88 (fix2float), 0x89A58 (float math), 0x899C8 (float math), 0x22F58 (matrix multiply), 0x1554A (matrix operations), 0x1AF1A (update CTM)

**`scale` (0x47004-0x470A8)**
**Purpose:** Scales the current transformation matrix
**Algorithm:** Multiplies CTM elements by sx and sy factors
**Arguments:** Takes sx, sy from operand stack
**Call targets:** 0x89938 (float multiply), 0x3A06 (matrix operations), 0x1AF1A (update CTM)

**`put` (0x47170-0x471B6)**
**Purpose:** Stores a value into an array or dictionary
1. Gets array/dict reference from 0x2000DE8
2. Calls lookup function at 0x30958
3. Stores value via function at 0x19816
**Arguments:** Takes key and value from execution stack (A3)
**Hardware/RAM:** 0x2000DE8 (array reference table)

**`astore` (0x471D8-0x471F4)**
**Purpose:** Stores array elements onto operand stack
**Algorithm:** Shifts array elements: [3]→[4], [2]→[3], [1]→[2], [0]→[1], clears [0]

**`aload` (0x471F6-0x47210)**
**Purpose:** Loads array elements from operand stack
**Algorithm:** Shifts array elements: [3]→[4], [2]→[3], [1]→[2], clears [1]

### 2. OPERATOR DISPATCH LOGIC (0x47212-0x47248)

**Purpose:** Dispatches to operator implementations based on opcode in D7
1. If opcode ≤ 31: dispatch via jump table at 0x46944
2. If opcode = 32: dispatch to 0x468B8
3. If opcode ≤ 247: dispatch to 0x682A
4. If opcode ≤ 251: dispatch to 0x6798
5. If opcode = 255: dispatch to 0x65DE
6. Otherwise: call error handler at 0x46334
**Hardware/RAM:** References jump table at 0x46944

### 3. SEPARATE FUNCTIONS (0x47390-0x47800)

**`execute_operator` (0x47390-0x4741E)**
**Entry:** 0x47390
**Purpose:** Executes a PostScript operator with error handling and context switching
1. Gets operator context at 0x365F8
2. Calls operator implementation at 0x3B626
3. Creates object for result at 0x2F986
4. Calls actual operator implementation at 0x47420
**Arguments:** Takes operator arguments from stack
**Call targets:** 0x365F8, 0x3B626, 0x3B6FA, 0x308FA, 0x2F986, 0x47420
**Return:** Result in D0

**`operator_implementation` (0x47420-0x47654)**
**Entry:** 0x47420
**Purpose:** Main implementation of a PostScript operator
1. Calls function at 0x58BE to process arguments
2. Saves current execution context at 0x20008F4
3. Sets up new context and calls various helper functions
4. Handles matrix transformations and graphics state updates
5. Restores execution context on completion
**Arguments:** Takes 5 arguments from stack
**Call targets:** 0x58BE, 0x4DF1C, 0x180E4, 0x308FA, 0x198EE, 0x195BE, 0x153B4, 0x15502, 0x1AD74, 0xFFD4, 0x18178, 0x4836C, 0x4D8D8
**Return:** Result in D0

**`process_font_operator` (0x47656-0x47800)**
**Entry:** 0x47656
**Purpose:** Processes font-related PostScript operators
1. Looks up font dictionary entries
2. Processes font metrics and character data
3. Handles font encoding and glyph extraction
4. Calls rendering functions for character output
**Arguments:** Takes font and character arguments from stack
**Call targets:** 0x5874, 0x30708, 0x3B1EC, 0x46366, 0x3A870, 0x7420
**Return:** Result in D0

### 4. DATA REGIONS (0x47362-0x4738C)

**Floating-point constants table (0x47362-0x4738C)**
**Format:** 8-byte IEEE 754 double-precision values
- 0x47362: 1.0 (0x3FF0000000000000)
- 0x4736A: 7.0 (0x401C000000000000)
- 0x47372: 0.080078125 (0x3FA4000000000000)
- 0x4737A: 0.740234375 (0x3FE0000000000000)
- 0x47382: 2.0 (0x4000000000000000)
- 0x4738A: 10.0 (0x4024000000000000)

1. **0x46C00-0x47388 is NOT separate functions** - it's all part of the monolithic operator handler
2. **The PRNG at 0x46CF6 is for eexec decryption**, not general random numbers
3. **0x47390, 0x47420, and 0x47656 ARE separate functions** with proper function prologues
4. **0x47362-0x4738C is a data table** of floating-point constants, not code
5. **Operator dispatch logic at 0x47212** handles opcodes 0-255 with specific ranges

; === CHUNK 11: 0x47800-0x48400 ===

### 1. 0x47800 - `process_font_metrics`
**Entry**: 0x47800  
**Purpose**: Processes font metrics by calling multiple font-related subroutines. This appears to be part of the font loading/rendering pipeline. It calls functions at 0x30350 (twice), 0x3bb98, 0x31334, and 0x303bc (twice).  
**Arguments**: Takes 3 arguments from stack: FP@(8), FP@(12), FP@(16)  
**Return**: Returns value from FP@(-44) in D0  
**Hardware access**: None directly visible  
**Call targets**: 0x30350, 0x3bb98, 0x31334, 0x303bc  
**Called by**: Unknown (likely font system)  
### 2. 0x47858 - `load_font_by_type`
**Entry**: 0x47858  
**Purpose**: Validates and loads a font based on type. Checks font type codes (5=Type 1, 9=Type 3, 13=Type 0 composite). For type 5, calls 0x7420; for types 9/13, processes differently. Handles font cache and metrics.  
**Arguments**: Multiple arguments including font pointer at FP@(20), type parameter at FP@(24)  
**Return**: Returns value from FP@(-28) in D0  
**Hardware access**: Reads 0x2000d8c, 0x2000d88 (font cache pointers)  
**Call targets**: 0x308fa, 0x30708, 0x46366, 0x7420, 0x30350, 0x3bb98, 0x31334, 0x303bc, 0x46334  
**Key branches**: 0x797a (error), 0x78fc (type 5), 0x791a (types 9/13)  
**Note**: This is a major font loading function, not just validation.

### 3. 0x47988 - `validate_font_cache`
**Entry**: 0x47988  
**Purpose**: Checks if cached font data is valid by verifying checksum. Reads font cache structure and validates against expected XOR value (0x3f8927b5). Invalidates cache if checksum fails.  
**Arguments**: None apparent (uses global font structures)  
**Return**: None (calls error handler if invalid)  
**Hardware access**: Reads 0x20173e8 (font cache), 0x2017354 (font structure)  
**Call targets**: 0x365f8, 0x365aa, 0x324ac  
**Called by**: Likely font loading system  
**Note**: The XOR constant 0x3f8927b5 is a checksum validation value.

### 4. 0x479ea - `init_system_tables`
**Entry**: 0x479ea  
**Purpose**: Initializes system tables based on mode (0, 1, 2). Mode 0 sets up floating-point constants and clears variables. Mode 1 registers callback functions. Mode 2 calls 0x47ffe with system variable table.  
**Arguments**: Mode parameter at FP@(8)  
**Return**: None  
**Hardware access**: Writes to many 0x2000xxx system variables  
**Call targets**: 0x46a20, 0x46948, 0x30350, 0x469fa, 0x303bc, 0x47ffe  
**Key branches**: 0x7a06 (mode 0), 0x7a46 (mode 1), 0x7a8c (mode 2)  
**Note**: This is system initialization, not just table setup.

### 5. 0x47aa0 - DATA TABLE: `system_variable_mapping_table`
**Address**: 0x47aa0-0x47bd7  
**Format**: Each entry is 8 bytes: 4-byte string offset (relative to 0x47c10 string table) followed by 4-byte variable address at 0x2000xxx  
**Size**: 0x138 bytes (39 entries)  
**Purpose**: Maps string names to system variable addresses for initialization  
### 6. 0x47bd8 - DATA TABLE: `callback_function_table`
**Address**: 0x47bd8-0x47c0f  
**Format**: Each entry is 8 bytes: 4-byte function pointer, 4-byte data pointer  
**Size**: 0x38 bytes (7 entries)  
**Purpose**: Table of callback functions for mode 1 initialization  
### 7. 0x47c10 - STRING TABLE: `postscript_internal_strings`
**Address**: 0x47c10-0x47da7  
**Content**: Null-terminated PostScript internal string literals for font metrics, operators, and system variables  
**Size**: 0x198 bytes  
Contiguous string table referenced by mapping table at 0x47aa0

### 8. 0x47da8 - `adjust_heap_size`
**Entry**: 0x47da8  
**Purpose**: Adjusts the heap size by allocating additional memory. Calculates new size requirements, checks if expansion is needed, and calls sbrk (0x1134) to allocate more memory. Updates heap management structures.  
**Arguments**: Size parameter at FP@(8)  
**Return**: None  
**Hardware access**: Reads/writes heap management structures at 0x2017574, 0x20175a8, 0x2017590, 0x2017528, 0x2017530  
**Call targets**: 0x1134 (sbrk), 0x48490, 0x46382, 0x47f50, 0x46334  
**Note**: This is part of the memory management system, not a general-purpose function.

### 9. 0x47f50 - `coalesce_free_blocks`
**Entry**: 0x47f50  
**Purpose**: Scans the heap and merges adjacent free blocks. Maintains the free list by combining contiguous free blocks marked with 'U' (0x55). Updates forward/backward pointers in the free list.  
**Return**: None  
**Hardware access**: Reads/writes heap structures at 0x2017574, 0x2017590, 0x20175c4  
**Call targets**: 0x46334, 0x4dcf8  
**Note**: Critical for heap fragmentation management. Called by malloc/free routines.

### 10. 0x480b0 - `malloc`
**Entry**: 0x480b0  
**Purpose**: Standard memory allocation function. Searches free list for block of appropriate size, splits if too large, updates free list. Calls coalesce_free_blocks and adjust_heap_size as needed.  
**Arguments**: Size at FP@(8), flag at FP@(12)  
**Return**: Pointer to allocated block in D0, or NULL if failed  
**Hardware access**: Reads/writes heap structures at 0x2017574, 0x20175c4, 0x20175a8, 0x2017528, 0x2017530  
**Call targets**: 0x47f50, 0x482ea, 0x46334, 0x48490, 0x482a2  
**Note**: This is the primary memory allocator for the PostScript interpreter.

### 11. 0x48208 - `free`
**Entry**: 0x48208  
**Purpose**: Standard memory deallocation function. Marks block as free ('U' = 0x55), updates free list, and attempts to merge with adjacent free blocks.  
**Arguments**: Pointer at FP@(8)  
**Return**: None  
**Hardware access**: Reads/writes heap structures at 0x2017574, 0x2017528  
**Call targets**: 0x46334, 0x482a2, 0x482ea  
**Note**: Companion to malloc, maintains heap integrity.

### 12. 0x482a2 - `insert_into_free_list`
**Entry**: 0x482a2  
**Purpose**: Inserts a block into the free list. Updates forward/backward pointers to maintain doubly-linked list structure.  
**Arguments**: Block pointer at FP@(8)  
**Return**: None  
**Hardware access**: Reads/writes 0x2017574, 0x20175c4  
**Call targets**: None  
**Note**: Helper function for malloc/free.

### 13. 0x482ea - `remove_from_free_list`
**Entry**: 0x482ea  
**Purpose**: Removes a block from the free list. Updates forward/backward pointers of adjacent blocks.  
**Arguments**: Block pointer at FP@(8)  
**Return**: None  
**Hardware access**: Reads/writes 0x2017574, 0x20175c4  
**Call targets**: 0x46334  
**Note**: Helper function for malloc/free.

### 14. 0x48384 - `allocate_from_freelist`
**Entry**: 0x48384  
**Purpose**: Secondary allocator that uses a free list index system (16-bit indices). Manages a pool of pre-allocated blocks with different sizes.  
**Arguments**: Unknown (likely size or type) at FP@(8)  
**Return**: Pointer in D0 or NULL  
**Hardware access**: Reads/writes 0x20175c8, 0x2017504  
**Call targets**: 0x48490, 0x46334  
**Note**: This appears to be a specialized allocator for small/frequent allocations.

1. **0x47da8**: Previously misidentified as part of init_system_tables. Actually `adjust_heap_size`.
2. **0x47f50**: Previously not identified. This is `coalesce_free_blocks`.
3. **0x480b0**: Previously not identified. This is `malloc`.
4. **0x48208**: Previously not identified. This is `free`.
5. **0x482a2**: Previously not identified. This is `insert_into_free_list`.
6. **0x482ea**: Previously not identified. This is `remove_from_free_list`.
7. **0x48384**: Previously not identified. This is `allocate_from_freelist`.

This region contains the core memory management system for the PostScript interpreter:
- **malloc/free** at 0x480b0/0x48208 with block structure: [24-bit size][marker 'U'=free/'*'=alloc][fwd ptr][back ptr]
- **Heap coalescing** at 0x47f50 to reduce fragmentation
- **Secondary allocator** at 0x48384 for small allocations
- **Font system** functions for loading and validating fonts
- **System initialization** tables and callbacks

The memory allocator uses a doubly-linked free list with markers 'U' (0x55) for free and '*' (0x2A) for allocated blocks. Block size is stored in the lower 24 bits of the first 32-bit word.

; === CHUNK 12: 0x48400-0x49000 ===

## FUNCTIONS IN 0x48400-0x49000:

### 1. 0x48400 - `release_object_slot`
- **Entry**: 0x48400
- **Suggested name**: `release_object_slot` or `free_object_handle`
- **Purpose**: Releases an object slot in the object table. Checks if the object is in use (high nibble of byte 4 ≠ 0), calls error handler if needed, then marks slot as free. Updates object table statistics.
- **Arguments**: Takes object handle/slot number in D0 (from FP@(-2) as word).
- **Return**: Returns nothing (void).
- **Hardware access**: Reads/writes 0x20175c8 (current object), 0x2017504 (object table base), 0x2017524 (object count).
- **Call targets**: Calls 0x46334 (error handler) if object is not allocated.
- **Called by**: Unknown, but likely object management routines.

### 2. 0x48434 - `allocate_object_slot`
- **Entry**: 0x48434
- **Suggested name**: `allocate_object_slot` or `get_object_handle`
- **Purpose**: Allocates an object slot from the object table. Validates the slot isn't already in use, marks it as allocated, updates linked list pointers.
- **Arguments**: Takes slot number in FP@(10) as word.
- **Return**: Returns allocated slot number in D0.
- **Hardware access**: Reads/writes 0x2017504, 0x2017508, 0x20175c8, 0x2017524.
- **Call targets**: Calls 0x46334 (error handler) if slot is already allocated.
- **Called by**: Object creation routines.

### 3. 0x48490 - `check_memory_pressure`
- **Entry**: 0x48490
- **Suggested name**: `check_memory_pressure` or `should_garbage_collect`
- **Purpose**: Checks memory pressure and determines if garbage collection should be triggered. Examines both LRU lists (active and inactive) to find candidates for eviction. Returns 1 if GC needed, 0 otherwise.
- **Arguments**: Takes mode (0,1,2) in FP@(8) and threshold size in FP@(12).
- **Return**: Returns boolean in D0 (1=need GC, 0=ok).
- **Hardware access**: Reads many system variables: 0x2017520, 0x20175a4, 0x2017584, 0x2017510, 0x201757c, 0x201758c, 0x201752c, 0x2017530, 0x2017528, 0x2017594, 0x2017524.
- **Call targets**: Calls 0x49056 (likely `evict_candidate`), 0x46334 (error).
- **Called by**: Memory allocation routines before allocating more memory.

### 4. 0x48608 - `allocate_memory_block`
- **Entry**: 0x48608
- **Suggested name**: `allocate_memory_block` or `malloc_internal`
- **Purpose**: Main memory allocator. First checks if GC needed via `check_memory_pressure`, then allocates from free list. Updates LRU chains and object table.
- **Arguments**: None apparent (uses global state).
- **Return**: Returns block handle in D0, or 0 if allocation failed.
- **Hardware access**: Reads/writes 0x20175cc (free list head), 0x2017584, 0x2017520.
- **Call targets**: Calls 0x8490 (`check_memory_pressure`), 0x46334 (error).
- **Called by**: Higher-level allocation routines.

### 5. 0x486ae - `free_memory_block`
- **Entry**: 0x486ae
- **Suggested name**: `free_memory_block` or `free_internal`
- **Purpose**: Frees a memory block. Validates block is allocated, calls callback for cleanup, removes from LRU chains, returns to free list.
- **Arguments**: Takes block handle in FP@(8), and cleanup flag in FP@(12).
- **Return**: Returns nothing (void).
- **Hardware access**: Reads/writes 0x2017584, 0x201757c, 0x2017558, 0x20175ce, 0x20175cc, 0x2017520.
- **Call targets**: Calls 0x46334 (error), 0x1537e (cleanup callback), 0x487e2 (`remove_from_lru`), 0x488aa (`update_free_list`).
- **Called by**: Object destruction and garbage collection.

### 6. 0x48742 - `insert_into_lru`
- **Entry**: 0x48742
- **Suggested name**: `insert_into_lru` or `add_to_lru_chain`
- **Purpose**: Inserts a memory block into the LRU (Least Recently Used) chain. Determines whether to insert into active or inactive list based on bit 7 of the block header. Updates forward/backward pointers to maintain doubly-linked list.
- **Arguments**: Takes block handle in FP@(8).
- **Return**: Returns nothing (void).
- **Hardware access**: Reads/writes 0x2017584, 0x20175a4 (active list head), 0x201752c (inactive list head).
- **Call targets**: Calls 0x46334 (error) if block already in LRU chain.
- **Called by**: Memory allocation and activation routines.

### 7. 0x487e2 - `remove_from_lru`
- **Entry**: 0x487e2
- **Suggested name**: `remove_from_lru` or `unlink_from_lru_chain`
- **Purpose**: Removes a memory block from the LRU chain. Updates forward/backward pointers of neighboring blocks, handles special case when block is at head of list.
- **Arguments**: Takes block handle in FP@(8).
- **Return**: Returns nothing (void).
- **Hardware access**: Reads/writes 0x2017584, 0x20175a4, 0x201752c.
- **Call targets**: Calls 0x46334 (error) if block not in LRU chain.
- **Called by**: `free_memory_block` and memory deactivation routines.

### 8. 0x488aa - `update_free_list`
- **Entry**: 0x488aa
- **Suggested name**: `update_free_list` or `link_into_free_list`
- **Purpose**: Updates free list pointers when a block is freed. Handles both active and inactive free lists based on bit 7 of block header. Maintains singly-linked free list with next pointer at offset 4.
- **Arguments**: Takes block handle in FP@(8).
- **Return**: Returns nothing (void).
- **Hardware access**: Reads/writes 0x2017584, 0x2017578 (active free list heads), 0x2017580 (inactive free list heads), 0x20175cc (free list head).
- **Call targets**: Calls 0x46334 (error) if free list structure is corrupted.
- **Called by**: `free_memory_block`.

### 9. 0x489ca - `compute_hash`
- **Entry**: 0x489ca
- **Suggested name**: `compute_hash` or `hash_function`
- **Purpose**: Computes a hash value for an object. Uses a complex algorithm involving multiple 32-bit values, XOR operations, and multiplication by constant 0x41C64E6D (1103515245). Similar to a linear congruential generator.
- **Arguments**: Takes pointer to data structure in A5 (FP@(12)), seed value in D7 (FP@(8)), and table size in FP@(16).
- **Return**: Returns 16-bit hash value in D0.
- **Hardware access**: Calls several helper functions at 0x89a88, 0x89a58, 0x899c8, 0x89a40, 0x3ce34.
- **Call targets**: Multiple math/helper functions.
- **Called by**: Hash table lookup/insertion routines.

### 10. 0x48b04 - `find_or_allocate_object`
- **Entry**: 0x48b04
- **Suggested name**: `find_or_allocate_object` or `lookup_or_create`
- **Purpose**: Main object lookup/creation function. Computes hash, searches hash chain, calls comparison callback. If not found, allocates new block and initializes it.
- **Arguments**: Takes key pointer in FP@(8), data pointer in FP@(12), size in FP@(16), comparison callback in FP@(28), flags in FP@(32).
- **Return**: Returns object handle in D0, or 0 if allocation failed.
- **Hardware access**: Reads/writes 0x2017514, 0x2017578, 0x2017580, 0x2017584, 0x201757c, 0x20175b0, 0x2017554.
- **Call targets**: Calls 0x89ca (`compute_hash`), 0x8608 (`allocate_memory_block`), 0x8742 (`insert_into_lru`), 0x48d4e (`activate_object`), 0x46334 (error).
- **Called by**: Object management and dictionary operations.

### 11. 0x48d4e - `activate_object`
- **Entry**: 0x48d4e
- **Suggested name**: `activate_object` or `move_to_active_list`
- **Purpose**: Activates an object by moving it from inactive to active LRU list. Updates LRU chain pointers and marks object as active.
- **Arguments**: Takes object handle in FP@(8).
- **Return**: Returns nothing (void).
- **Hardware access**: Reads/writes 0x2017584, 0x20175a4, 0x201752c.
- **Call targets**: Calls itself recursively, 0x87e2 (`remove_from_lru`), 0x8742 (`insert_into_lru`).
- **Called by**: `find_or_allocate_object` and object access routines.

### 12. 0x48de4 - `create_font_object`
- **Entry**: 0x48de4
- **Suggested name**: `create_font_object` or `load_font`
- **Purpose**: Creates a font object by loading font data, computing metrics, and registering in object table. Handles font transformation matrices and bounding boxes.
- **Arguments**: Takes font ID in FP@(8), font data pointer in FP@(12), metrics pointer in FP@(16).
- **Return**: Returns font object handle in D0.
- **Hardware access**: Reads/writes 0x201751c, 0x2017518, 0x20174fc, 0x20174f8, 0x20175d4, 0x20175d0, 0x2017564, 0x2017560.
- **Call targets**: Calls 0x308fa (font loading), 0x198ee (matrix operations), 0x191b8 (bounding box calculations), 0x30708 (font validation), 0x8b04 (`find_or_allocate_object`).
- **Called by**: Font loading subsystem.

### 13. 0x48fe8 - `check_object_slot`
- **Entry**: 0x48fe8
- **Suggested name**: `check_object_slot` or `validate_object_handle`
- **Purpose**: Checks if an object slot is valid and allocated. Looks up slot in object table and verifies its allocation status.
- **Arguments**: Takes slot number in D7 (FP@(10) as word).
- **Return**: Likely returns status in D0 (exact return unclear from snippet).
- **Hardware access**: Reads 0x2017508 (object table).
- **Call targets**: None visible in snippet.
- **Called by**: Object validation routines.

- **0x48afc**: Constant value 0x40900000 (likely floating-point constant 4.5 or similar).
- **0x48afe-0x48b02**: Padding/alignment bytes.

1. This region contains core memory management and object system functions for the PostScript interpreter.
2. The object system uses a hash table with separate chaining and LRU management for garbage collection.
3. Objects can be in active or inactive states, with different LRU lists for each.
4. Font objects have special handling with transformation matrices and bounding boxes.
5. The hash function uses a pseudo-random number generator algorithm (multiply by 0x41C64E6D).
6. Memory blocks appear to be 72 bytes each (8×8 + 8 = 72), based on the address calculation: `handle × 8 × 8 + handle × 8 = handle × 72`.

- Function names and purposes have been refined based on actual disassembly.
- Added missing functions 0x489ca (`compute_hash`), 0x48d4e (`activate_object`), 0x48de4 (`create_font_object`), and 0x48fe8 (`check_object_slot`).
- Corrected the understanding of the memory block size calculation.  (register = size parameter)

; === CHUNK 13: 0x49000-0x49C00 ===

## REFINED ANALYSIS OF 0x49000-0x49C00

### CORRECTIONS TO PRIOR ANALYSIS:
2. **0x4926c**: Called `clear_font_cache_chain` - clears the linked list of cached glyph data for a font.
3. **0x49380**: Called `reset_font_cache` - resets only the font cache, not the entire font system.
4. **0x49422**: This is `scan_font_dictionary` - scans the font dictionary for font entries.
5. **0x4957a**: This is `extract_font_type` - extracts font type from packed font ID.
6. **0x49590**: This is `validate_font_entry` - complex validation of font dictionary entries.
7. **0x49a4**: This is `process_font_definition` - handles font definition from PostScript.

### DETAILED FUNCTION ANALYSIS:

#### 1. 0x49000 - `remove_font_from_cache`
- **Entry**: 0x49000
- **Purpose**: Removes a font cache entry (8-byte structure) from the linked list of cached fonts. Walks through the font cache table starting at 0x2017504, finds the entry with matching font ID, and unlinks it by adjusting the "next" pointer in the previous entry.
- **Arguments**: Font ID in D7 (word)
- **Returns**: Nothing
- **RAM access**: 0x2017504 (font cache table base), 0x2017508 (font cache pointer array)
- **Calls**: 0x46334 (error handler if font not found)
- **Algorithm**: 
  1. Gets pointer to font cache entry from array at 0x2017508[font_id]
  2. Walks linked list via offset 6 (next pointer) in each 8-byte entry
  3. When matching font ID found at offset 4, updates previous entry's next pointer to skip this entry
  4. If not found, calls error handler
- **Callers**: Font cache management during font deletion/replacement

#### 2. 0x49056 - `free_font_resources`
- **Entry**: 0x49056
- **Purpose**: Deallocates all resources associated with a font ID. Handles complex font state including cache chains, allocation tables, and memory. Checks if font is built-in, walks cache chains, frees memory, updates linked lists.
- **Arguments**: Font ID at fp@(8) (long)
- **Returns**: Nothing
- **RAM access**: 0x2017584 (font descriptor table), 0x201757c (font state array), 0x2017504 (font cache table), 0x2017570 (font cache table end), 0x2017536 (system font ID), 0x2017534 (active font pointer)
- **Calls**: 0x86ae (update_font_state), 0x8fe8 (cache_management), 0x8434 (clear_font_cache_entry), 0x8208 (free_memory), 0x8d4e (cleanup_font_descriptor)
- **Algorithm**:
  1. Gets font descriptor (72-byte structure at 0x2017584 + font_id * 72)
  2. Checks if font is built-in (bit 0 of high word in descriptor)
  3. If built-in and active, returns early
  4. Walks font cache chain, freeing cached glyph data
  5. Updates linked lists and state flags
  6. Handles active font pointer updates
- **Callers**: Font system cleanup during font replacement

#### 3. 0x4926c - `clear_font_cache_chain`
- **Entry**: 0x4926c
- **Purpose**: Clears all cached glyph data for a font by walking its cache dependency chain. Frees memory allocated for cached glyph outlines or bitmaps.
- **Arguments**: Font ID at fp@(8) (long)
- **Returns**: Nothing
- **RAM access**: 0x2017584 (font descriptor table), 0x2017504 (font cache table), 0x2017574 (glyph cache base), 0x201757c (font state array)
- **Calls**: 0x8434 (clear_font_cache_entry), 0x8208 (free_memory)
- **Algorithm**:
  1. Gets font descriptor pointer
  2. Walks linked list starting at offset 0xA (next cached font)
  3. For each cache entry: frees memory, clears chain pointer
  4. Marks font as available in state array (sets high bit)
- **Callers**: 0x492e4, 0x49380, 0x49056

#### 4. 0x492e4 - `remove_font_from_active_list`
- **Entry**: 0x492e4
- **Purpose**: Removes a font from the active font linked list and updates global active font pointer. Used when a font is being replaced or deleted.
- **Arguments**: Font descriptor pointer at fp@(8)
- **Returns**: Nothing
- **RAM access**: 0x2017534 (active font pointer), 0x2017584 (font descriptor table)
- **Calls**: 0x926c (clear_font_cache_chain), 0x86ae (update_font_state)
- **Algorithm**:
  1. Walks active font linked list starting at 0x2017534
  2. Finds font with matching ID (from descriptor at offset 4)
  3. Updates previous font's "next" pointer (offset 4) to skip this font
  4. If this was the head of the list, updates 0x2017534
  5. Clears font cache chain and updates state
- **Callers**: Font replacement operations

#### 5. 0x49380 - `reset_font_cache`
- **Entry**: 0x49380
- **Purpose**: Resets the entire font cache system by clearing all cached fonts and resetting all font states. Used during system initialization or major state changes.
- **Arguments**: None
- **Returns**: Nothing
- **RAM access**: 0x2017534 (active font pointer), 0x2017584 (font descriptor table), 0x201757c (font state array), 0x201758c (font descriptor table end)
- **Calls**: 0x926c (clear_font_cache_chain), 0x86ae (update_font_state)
- **Algorithm**:
  1. Walks active font linked list, clearing each font's cache chain
  2. Sets active font pointer to NULL
  3. Iterates through all font descriptors (1 to max)
  4. For each font with cache chain, clears it
  5. Marks all fonts as available in state array (sets high bit)
- **Callers**: System initialization, major state resets

#### 6. 0x49422 - `scan_font_dictionary`
- **Entry**: 0x49422
- **Purpose**: Scans the PostScript font dictionary to find font entries and determine the maximum font ID needed. Used during font system initialization.
- **Arguments**: None
- **Returns**: Nothing (updates 0x2000FFC with max font ID)
- **RAM access**: 0x2000FFC (max font ID), 0x2017354 (font dictionary hash table), 0x20175B8/BC (dictionary bounds), 0x2017518/1C (font entry bounds)
- **Calls**: 0x30708 (dictionary lookup), 0x308FA (dictionary scan), 0x4957A (extract_font_type)
- **Algorithm**:
  1. Clears max font ID counter
  2. Scans font dictionary for entries
  3. For each entry, checks if it's a font (type 8 = font)
  4. Extracts font ID from packed value
  5. Updates max font ID if larger than current
- **Callers**: Font system initialization

#### 7. 0x4951c - `setup_font_descriptor`
- **Entry**: 0x4951c
- **Purpose**: Sets up a font descriptor structure with initial values. Called during font creation/validation.
- **Arguments**: 
  - fp@(8): font type (1, 2, or 3)  stack frame parameter
  - fp@(12): font ID  stack frame parameter
  - fp@(16): pointer to font descriptor structure  stack frame parameter
- **Returns**: Nothing (fills descriptor structure)
- **RAM access**: 0x20008F8 (current color space), 0x2000FFC (max font ID)
- **Algorithm**:
  1. If font type is 2, uses max font ID + 1 as font ID
  2. Copies template from 0x87CE0
  3. Sets color space from 0x20008F8
  4. Packs font type into high bits of descriptor
  5. Sets font ID in descriptor
- **Callers**: 0x49590 (validate_font_entry)

#### 8. 0x4957a - `extract_font_type`
- **Entry**: 0x4957a
- **Purpose**: Extracts font type from a packed font ID value (type in high 8 bits, ID in low 24 bits).
- **Arguments**: Packed font ID at fp@(8)
- **Returns**: Font type in D0 (0-255)
- **Algorithm**: Right shifts by 24 bits to extract type field
- **Callers**: 0x49422 (scan_font_dictionary), 0x49590 (validate_font_entry)

#### 9. 0x49590 - `validate_font_entry`
- **Entry**: 0x49590
- **Purpose**: Complex validation of a font dictionary entry. Checks font type, dependencies, and sets up font descriptor. This is the main font validation routine.
- **Arguments**:
  - fp@(8): key pointer (low)  stack frame parameter
  - fp@(12): key pointer (high)  stack frame parameter
  - fp@(16): font descriptor pointer  stack frame parameter
- **Returns**: Nothing (fills descriptor if valid)
- **RAM access**: Multiple font system tables (0x20174F0-0x20175DC), 0x20008F8 (color space), 0x2000FFC (max font ID)
- **Calls**: 0x308FA (dictionary scan), 0x30708 (dictionary lookup), 0x30958 (dictionary operations), 0x3072C (dictionary compare), 0x48344 (allocate memory), 0x4836C (free memory), 0x4957A (extract_font_type), 0x4951C (setup_font_descriptor)
- **Algorithm**:
  1. Checks if entry exists in font dictionary
  2. Validates entry type (must be type 1)
  3. Checks for font dependencies and circular references
  4. Validates font type (must be 1, 2, or 3)
  5. Scans for font resources and validates them
  6. Sets up font descriptor structure
  7. Handles built-in vs. user-defined fonts
- **Callers**: Font definition processing

#### 10. 0x49a4 - `process_font_definition`
- **Entry**: 0x49a4
- **Purpose**: Main entry point for processing a PostScript font definition. Handles the complete font definition workflow.
- **Arguments**: None (works with current dictionary/stack state)
- **Returns**: Nothing
- **RAM access**: Multiple font system tables, dictionary structures
- **Calls**: 0x3B6FA (get dictionary entry), 0x365F8 (dictionary operations), 0x30708 (dictionary lookup), 0x46366 (error handler), 0xA670 (font system init), 0x308FA (dictionary scan), 0x34050 (font processing), 0x49590 (validate_font_entry), 0x49D44 (font registration), 0x30A18 (dictionary operations), 0x30DA2 (dictionary update), 0x365AA (cleanup)
- **Algorithm**:
  1. Gets font dictionary entry
  2. Validates it's a font definition (not other types)
  3. Initializes font system if needed
  4. Scans font dictionary structure
  5. Validates font entry
  6. Registers font in system
  7. Updates dictionary with font descriptor
  8. Cleans up temporary structures
- **Callers**: PostScript interpreter when processing font definitions

1. **Font Cache Structure**: Each font has an 8-byte cache entry structure with: pointer to cached data (4 bytes), font ID (2 bytes), next pointer (2 bytes).
2. **Font Descriptor**: 72-byte structure containing font state, type, ID, cache chain pointer, and linked list pointers.
3. **Font Types**: Type 1=built-in, Type 2=user-defined (gets auto-assigned ID), Type 3=???
4. **Active Font List**: Linked list of currently active fonts, with head at 0x2017534.
5. **Font State Array**: At 0x201757c, tracks availability of font IDs (high bit set = available).
6. **Validation Complexity**: The `validate_font_entry` function is highly complex with multiple error paths and dependency checking.

### DATA STRUCTURES:
- **Font Cache Entry** (8 bytes): [data_ptr:4][font_id:2][next:2]
- **Font Descriptor** (72 bytes): Contains type, ID, cache chain, linked list pointers
- **Font State Entry** (4 bytes): High bit indicates availability

### ERROR HANDLING:
Multiple error conditions are checked:
- Font not found in cache (calls 0x46334)
- Invalid font type
- Circular dependencies  (PS dict operator)
- Invalid dictionary entries
- Resource validation failures

This region contains the core font management system for the PostScript interpreter, handling everything from cache management to complex font validation and registration.

; === CHUNK 14: 0x49C00-0x4A800 ===

### 1. 0x49C06 - `cleanup_font_cache_by_id`
- **Entry**: 0x49C06 (starts with LINK instruction)
- **Purpose**: Removes font entries from two font cache tables based on font ID. Walks through both tables and removes entries matching the specified font ID.
- **Arguments**: Font ID at fp@(8) in D7
- **Algorithm**: 
  1. Calls 0x957A to extract font type from packed descriptor
  2. Sets D4=1 if font type is 2 (Type 2 font)
  3. Iterates through first table (0x2017578 to 0x20175A0)
  4. For each entry, walks linked list of font IDs
  5. If font ID matches, either calls 0x86AE (free_font) or 0x1537E (update_font_cache)
  6. Repeats for second table (0x2017580 to 0x201750C)
- **RAM access**: 0x2017578, 0x20175A0, 0x2017580, 0x201750C, 0x2017584, 0x20175B0
- **Call targets**: 0x957A (extract_font_type), 0x86AE (free_font), 0x1537E (update_font_cache), 0x9056 (another font cleanup function)
- **Called by**: 0x49DF0

### 2. 0x49D44 - `delete_font_by_id`
- **Entry**: 0x49D44
- **Purpose**: Deletes a font by ID from the font system. Validates the font exists and is of correct type before removal.
- **Arguments**: Font ID at fp@(8)
- **Algorithm**:
  1. Scans font directory using 0x308FA
  2. Counts matching font entries (must be exactly 1)
  3. If count ≠ 1, calls error handler 0x46334
  4. Calls 0x49C06 to clean up cache
- **RAM access**: 0x20175BC, 0x20175B8, 0x2017354, 0x201751C, 0x2017518
- **Call targets**: 0x308FA (scan_directory), 0x46334 (error), 0x49C06 (cleanup_font_cache_by_id)
- **Key behavior**: Ensures exactly one font matches the ID before deletion

### 3. 0x49E00 - `purge_fonts_by_size`
- **Entry**: 0x49E00
- **Purpose**: Removes fonts below a specified size threshold from cache. Walks through font tables and removes fonts with size < threshold.
- **Arguments**: Size threshold in fp@(11) (byte)
- **Algorithm**:
  1. Scans font directory using 0x30708
  2. For each font entry of type 8 (font data)
  3. If font size < threshold, calls 0x49C06 to remove it
  4. Walks both font cache tables (0x2017578 and 0x2017580)
  5. For cached fonts with size < threshold, either updates cache or frees font
- **RAM access**: 0x20175BC, 0x20175B8, 0x2017354, 0x201751C, 0x2017518, 0x2017578, 0x20175A0, 0x2017580, 0x201750C, 0x2017584
- **Call targets**: 0x30708, 0x308FA, 0x49C06, 0x1537E, 0x86AE, 0x87E2
- **Key behavior**: Complex font cache management with size-based eviction

### 4. 0x4A082 - `free_font_cache_chain`
- **Entry**: 0x4A082
- **Purpose**: Frees all entries in a font cache chain. Walks linked list of font cache entries and releases memory.
- **Arguments**: Pointer to font cache structure at fp@(8)
- **Algorithm**:
  1. Gets head pointer from structure offset 0x12
  2. Walks linked list via offset 0x6 (next pointer)
  3. For each entry, checks if it's in use (offset 0x4 low bits)
  4. If not in use, calls 0x8434 to free it
  5. Otherwise checks reference count at 0x201757C
  6. If refcount=0, frees entry and adjusts heap
- **RAM access**: 0x2017504, 0x2017584, 0x201757C, 0x2017574
- **Call targets**: 0x8434 (free_memory), 0x8208 (adjust_heap)
- **Key behavior**: Manages font cache linked list with reference counting

### 5. 0x4A152-0x4A1AC - Font operator stubs
These are PostScript font operator implementations:

- **0x4A152**: `font_operator_1` - Calls function pointer at 0x2017538
- **0x4A162**: `font_operator_2` - Empty stub (just RTS)
- **0x4A16A**: `font_operator_3` - Returns 0
- **0x4A174**: `font_operator_4` - Returns 0
- **0x4A17E**: `font_operator_5` - Returns 0
- **0x4A188**: `font_operator_6` - Validates argument, calls function at 0x2017548
- **0x4A1A4**: `font_operator_7` - Empty stub
- **0x4A1AC**: `font_operator_8` - Returns 0

### 6. 0x4A1B6 - `initialize_font_system`
- **Entry**: 0x4A1B6
- **Purpose**: Initializes the font system based on mode parameter. Sets up font operator table and clears various font-related flags.
- **Arguments**: Mode at fp@(8) (0=normal, 1=extended)
- **Algorithm**:
  1. If mode=0: clears 0x2017534, copies 9 entries from 0x4A3D8 to 0x2017538
  2. If mode=1: calls 0x46A20 with string at 0x4A400, clears bits at 0x2017518, 0x20175D8, 0x20174E8, 0x20174D0, 0x2017568, 0x2017598
  3. Calls 0x46948 with 0x99A4 and 0xA460, calls 0x47632 with 0x9E00, calls 0x9422
- **RAM access**: 0x2017534, 0x2017538, 0x2017518, 0x20175D8, 0x20174E8, 0x20174D0, 0x2017568, 0x2017598
- **Call targets**: 0x46A20, 0x46948, 0x47632, 0x9422
- **Key behavior**: Two initialization modes with different setup paths

### 7. 0x4A242 - `setup_font_environment`
- **Entry**: 0x4A242
- **Purpose**: Sets up the font environment by calling multiple initialization functions.
- **Arguments**: Mode at fp@(8)
- **Algorithm**:
  1. Calls 0xA1B6 (initialize_font_system)
  2. Calls 0x1059E
  3. Calls 0x79EA
  4. Calls 0xAF84
- **Call targets**: 0xA1B6, 0x1059E, 0x79EA, 0xAF84
- **Key behavior**: Orchestrates multiple font system initialization steps

### 8. 0x4A278-0x4A3D6 - DATA: Font metric table
- **Address**: 0x4A278-0x4A3D6
- **Size**: 350 bytes
- **Format**: Array of byte values representing font metrics or character widths
- **Content**: Appears to be a table of character widths or spacing values (repeating patterns like 0x43, 0x6F, 0x70, etc.)

### 9. 0x4A3D8-0x4A45F - DATA: Font operator table
- **Address**: 0x4A3D8-0x4A45F
- **Size**: 136 bytes
- **Format**: Array of 9 function pointers (4 bytes each) followed by string data
- **Content**: 
  - 9 function pointers: 0x00086334, 0x0004A17E, 0x0004A174, 0x0004A188, 0x0004A70C, 0x0004A71A, 0x0004A1A4, 0x0004A16A, 0x0004A162, 0x0004A1AC
  - String data starting at 0x4A400: "definefont", "FontType", "FontMatrix", "ScaleMatrix", "FontDirectory", "FID", "UniqueID", "Private", "Encoding", "FontName", "FontInfo", "OrigFont"  (PS dict operator)

### 10. 0x4A460-0x4A4D5 - DATA: Font-related strings
- **Address**: 0x4A460-0x4A4D5
- **Size**: 117 bytes
- **Format**: Null-terminated strings
- **Content**: "definefont", "FontType", "FontMatrix", "ScaleMatrix", "FontDirectory", "FID", "UniqueID", "Private", "Encoding", "FontName", "FontInfo", "OrigFont"

### 11. 0x4A4D6-0x4A50C - `fixup_font_cache_pointers`
- **Entry**: 0x4A4D6
- **Purpose**: Adjusts pointers in font cache after memory relocation. Converts relative offsets to absolute addresses.
- **Arguments**: None
- **Algorithm**:
  1. Walks through font cache entries from 0x2017504+8 to 0x2017570
  2. For each entry with bit 1 set in byte 4, converts relative offset at entry[0] to absolute address
- **RAM access**: 0x2017504, 0x2017574, 0x2017570
- **Key behavior**: Memory relocation support for font cache

### 12. 0x4A50E-0x4A54E - `unfixup_font_cache_pointers`
- **Entry**: 0x4A50E
- **Purpose**: Converts absolute pointers back to relative offsets before memory relocation.
- **Arguments**: None
- **Algorithm**:
  1. Checks if 0x20175C0 is non-zero
  2. If so, walks through font cache entries
  3. For entries with bit 1 set in byte 4, converts absolute address at entry[0] to relative offset
- **RAM access**: 0x20175C0, 0x2017504, 0x2017574, 0x2017570
- **Key behavior**: Inverse of fixup_font_cache_pointers

### 13. 0x4A550-0x4A65E - `calculate_font_cache_size`
- **Entry**: 0x4A550
- **Purpose**: Calculates optimal font cache size based on available memory and parameters.
- **Arguments**: Total memory at fp@(8), cache size at fp@(12), other size at fp@(16)
- **Algorithm**:
  1. Gets current time, performs floating-point calculations
  2. Computes optimal cache parameters based on input sizes
  3. Ensures values are within bounds (5-1000 for one parameter, 10-80 for another)
  4. Calls 0x4A722 with calculated parameters
- **Call targets**: 0x4A722, various floating-point routines at 0x899F8, 0x89A58, 0x89920, 0x89A10, 0x89A88, 0x89998, 0x89A28
- **Key behavior**: Complex floating-point calculations for cache sizing

### 14. 0x4A670-0x4A70A - `auto_configure_font_cache`
- **Entry**: 0x4A670
- **Purpose**: Automatically configures font cache based on system parameters.
- **Arguments**: None
- **Algorithm**:
  1. Checks if 0x20175C0 is set, calls error if so
  2. Reads parameters from dictionary at 0x2017354+64
  3. Gets values with defaults (12500 and 1250)
  4. Calls 0xA550 with these parameters
- **RAM access**: 0x20175C0, 0x2017354, various dictionary offsets
- **Call targets**: 0x46334 (error), 0xA550
- **Key behavior**: Automatic font cache configuration based on system state

### 15. 0x4A70C - `enable_font_cache_relocation`
- **Entry**: 0x4A70C
- **Purpose**: Enables font cache pointer relocation by clearing a flag.
- **Arguments**: None
- **Algorithm**: Clears 0x20175C0
- **RAM access**: 0x20175C0
- **Key behavior**: Simple flag management

### 16. 0x4A71A - Empty function
- **Entry**: 0x4A71A
- **Purpose**: Empty stub (just LINK/UNLK/RTS)

### 17. 0x4A722-0x4A7FA - `configure_font_cache_tables`
- **Entry**: 0x4A722
- **Purpose**: Configures font cache tables based on calculated parameters.
- **Arguments**: Multiple parameters on stack
- **Algorithm**:
  1. Gets dictionary pointer from 0x2017354+56
  2. If 0x20175E0 is zero, clears all font cache chains
  3. Calculates table size based on parameter at fp@(12)
  4. Allocates and initializes font cache tables
  5. Sets up table pointers and sizes
- **RAM access**: 0x2017354, 0x20175E0, 0x2017514, 0x2017578, 0x20175A0, 0x2017588
- **Call targets**: 0x48344 (memory allocation)
- **Key behavior**: Final stage of font cache configuration

This region contains the core font cache management system for the PostScript interpreter:
- Font cache eviction (size-based and ID-based)  (register = size parameter)
- Font operator implementations
- Font system initialization
- Font cache memory management with relocation support
- Automatic cache sizing based on available memory
- Complex data structures with linked lists and hash tables  (data structure manipulation)

The font cache uses two separate tables (at 0x2017578 and 0x2017580) with different purposes, likely for active vs. cached fonts. The system supports memory relocation through pointer fixup functions, indicating it may be part of a dynamic loading system.

; === CHUNK 15: 0x4A800-0x4B400 ===

### 1. **0x4A800 - Continuation of `cache_initialize` function**
**Entry:** 0x4A800 (mid-function, continuation from earlier)  
**Purpose:** Continues cache initialization by allocating and initializing various cache data structures.  
- Allocates font hash table (0x2017580) with size = font_count × 4 bytes  (register = size parameter)
- Allocates font descriptor array (0x2017584) with size = font_count × 72 bytes (each entry 72 bytes)  (register = size parameter)
- Allocates additional font table (0x201757c) with size = font_count × 4 bytes  (register = size parameter)
- Allocates glyph cache table (0x2017504) with size = glyph_count × 8 bytes  (register = size parameter)
- Allocates glyph pointer table (0x2017508) with size = glyph_count × 4 bytes  (register = size parameter)
- Initializes sentinel values and linked list headers  (data structure manipulation)
- Sets up font descriptor flags (bit 7 = sentinel marker)
- Calls `build_glyph_cache_tables` (0x4AA7C) and `cache_initialize_pool` (0x4AE22)
**Arguments:** Uses stack parameters from earlier in the function (font count, glyph count, etc.)
- 0x2017580, 0x2017584, 0x201757c, 0x2017504, 0x2017508 - cache structure pointers
- 0x20175a4, 0x201752c, 0x20175cc - counters and flags
- 0x20175ce - sentinel value
**Call targets:** 0x48344 (memory allocator), 0x4AE22, 0x4AA7C
**Called by:** Cache initialization function starting earlier (likely 0x4A670)

### 2. **0x4AA7C - `build_glyph_cache_tables`**
**Entry:** 0x4AA7C  
**Purpose:** Processes built-in font data from ROM to populate cache structures. Walks through two tables: glyph descriptors at 0x35690 and font descriptors at 0x35698.  
1. Iterates through glyph descriptors at 0x35690 (terminated by null entry)
2. For each glyph: computes hash via 0x8384, sets up cache entry with glyph data pointer and metrics
3. Links glyph to its parent font structure via pointer at offset 6
4. Iterates through font descriptors at 0x35698
5. For each font: copies 76-byte descriptor to font cache, sets up hash table links
6. Marks unused font cache entries as free
- 0x2017504, 0x2017508 - glyph cache tables
- 0x2017578, 0x2017580 - font hash tables
- 0x2017520 - glyph count
- 0x201752c - some counter
**Call targets:** 0x8384 (hash function), 0x8742 (font processing)
**Called by:** Cache initialization function at 0x4A800 region

### 3. **0x4AC0C - `cache_allocate_space`**
**Entry:** 0x4AC0C  
**Purpose:** Allocates space from the cache memory pool with overflow checking and reclamation.  
1. Calls 0x3B626 (memory allocator) to get a block
2. If allocation fails (negative return), calls error handler 0x463BA
3. Calculates total size needed (size × 5, suggesting 5:1 overhead ratio for cache management)
4. If would exceed total cache size (0x2017530), calls reclaimer 0x46382
5. Otherwise, calls 0x7DA8 to update cache statistics
6. Logs the allocation via 0x47310 (debug logging)
**Arguments:** Size in D0 (passed from caller)
**Return value:** Allocation handle in D0 (or error)
- 0x2017530 - total cache size  (register = size parameter)
- 0x2017354 - main PostScript interpreter structure
**Call targets:** 0x3B626 (allocator), 0x463BA (error), 0x46382 (reclaimer), 0x7DA8, 0x47310 (logging)
**Called by:** Cache reclaimer (0x4AD18) and other cache management functions

### 4. **0x4AC8C - `cache_print_statistics`**
**Entry:** 0x4AC8C  
**Purpose:** Outputs cache statistics to debug console for monitoring and debugging.  
1. Prints current cache usage (0x2017528) via 0x3BB98
2. Prints total cache size minus 4 (0x2017530 - 4)
3. Prints glyph count (0x2017520)
4. Prints font count minus 1 (0x201758c - 1)
5. Prints some other counter (0x2017524)
6. Prints glyph cache size minus 1 (0x2017594 - 1)
7. Calls 0x365aa to output a string
- 0x2017528, 0x2017530, 0x2017520, 0x201758c, 0x2017524, 0x2017594 - cache statistics
- 0x2017354 - main interpreter structure
**Call targets:** 0x3BB98 (print function), 0x365aa (string output)
**Called by:** Cache management functions for debugging

### 5. **0x4AD18 - `cache_reclaim_entries`**
**Entry:** 0x4AD18  
**Purpose:** Reclaims space from cache by freeing entries based on some metric.  
1. Calls 0x369ea to get a count of entries to reclaim (returns in D0)
2. If count > 0, calls `cache_allocate_space` (0x4AC0C) for each entry
3. If allocation fails, tries alternative reclamation via 0x365f8
4. Continues until all requested entries are reclaimed
- 0x20173e8 - reclamation metric source
- Various cache statistics
**Call targets:** 0x369ea (get reclamation count), 0x4AC0C (allocate space), 0x365f8 (alternative reclamation)
**Called by:** Cache management when space is needed

### 6. **0x4ADAE - `cache_dump_state`**
**Entry:** 0x4ADAE  
**Purpose:** Dumps detailed cache state information for debugging.  
1. Sets up string pointer from 0x87cd0
2. Calls 0x365aa to output the string
3. Accesses interpreter structure at 0x2017354 to get more state
4. Calls 0x365aa two more times with different offsets
- 0x87cd0 - string table pointer
- 0x2017354 - main interpreter structure
**Call targets:** 0x365aa (string output, called 3 times)
**Called by:** Debugging functions

### 7. **0x4AE22 - `cache_initialize_pool`**
**Entry:** 0x4AE22  
**Purpose:** Initializes the cache memory pool with proper headers and sentinels.  
1. Calculates header sizes (32 bytes + alignment)
2. Allocates cache pool if not already allocated (0x2017574)
3. Sets up pool header with magic value 0x2A ('*') and size field
4. Creates free block with marker 'U' (85) and proper size
5. Sets up free list pointers
6. Updates cache statistics
**Arguments:** Two stack parameters: pool size and some other value
- 0x2017574 - cache pool pointer
- 0x2017530, 0x20175a8, 0x2017590, 0x20175c4, 0x2017528 - pool management variables
**Call targets:** 0x1134 (size calculation), 0x48344 (memory allocator)
**Called by:** Cache initialization function at 0x4A800

### 8. **0x4AF84 - `cache_control`**
**Entry:** 0x4AF84  
**Purpose:** Controls cache behavior based on command parameter.  
1. Checks command in D0: 0 = reset, 1 = initialize, other = no-op
2. For command 0: resets all cache pointers to null
3. For command 1: sets up command table at 0xAFE4 and calls 0x469fa
4. If cache not initialized (0x20175c0 = 0), calls initialization at 0xA670
**Arguments:** Command in D0 (0 = reset, 1 = initialize)
- 0x20175e0, 0x20175c0, 0x2017584, 0x2017578, 0x2017580, 0x2017504, 0x2017508, 0x2017574 - cache pointers
**Call targets:** 0x469fa (command processor), 0xA670 (cache initialization)
**Called by:** System initialization and control functions

### 9. **0x4AFE4 - Command Table**
**Address:** 0x4AFE4  
**Format:** Array of 8 command entries (4 bytes each: 2 bytes string offset, 2 bytes function offset)  
- 0xAFE4: 0x0004 0xB00C - "setcachelimit"
- 0xAFE8: 0x0004 0xAC0C - "cachealloc"
- 0xAFEC: 0x0004 0xB01A - "cachestatus"
- 0xAFF0: 0x0004 0xAC8C - "cachestats"
- 0xAFF4: 0x0004 0xB026 - "setcacheparams"
- 0xAFF8: 0x0004 0xAD18 - "cachereclaim"
- 0xAFFC: 0x0004 0xB035 - "currentcacheparams"

### 10. **0x4B00C - String Table**
**Address:** 0x4B00C  
**Format:** Null-terminated strings for cache command names  
- 0x4B00C: "setcachelimit"
- 0x4B01A: "cachestatus"
- 0x4B026: "setcacheparams"
- 0x4B035: "currentcacheparams"

### 11. **0x4B048 - `reset_cache_entry`**
**Entry:** 0x4B048  
**Purpose:** Resets a specific cache entry to empty state.  
1. Calculates entry offset: index × 18 bytes (0x12)
2. Clears two fields in the entry (offsets 0 and 12)
**Arguments:** Entry index in D0 (passed via stack)
**RAM accessed:** 0x2001000 - cache entry table base
**Called by:** Cache management functions

### 12. **0x4B07C - `check_cache_entry`**
**Entry:** 0x4B07C  
**Purpose:** Checks if a cache entry is valid/non-empty.  
1. Calculates entry offset: index × 18 bytes (0x12)
2. Calls 0x4BCF6 with entry pointers
3. Tests if the first field is non-zero
4. Returns boolean result
**Arguments:** Entry index in D0 (passed via stack)
**Return value:** D0 = 0 if empty, non-zero if valid
**RAM accessed:** 0x2001000 - cache entry table base
**Call targets:** 0x4BCF6 (entry validation)
**Called by:** Cache lookup functions

### 13. **0x4B0DC - `initialize_cache_table`**
**Entry:** 0x4B0DC  
**Purpose:** Allocates and initializes the cache entry table.  
1. Allocates table if not already allocated (size = font_count × 18 bytes)
2. Loops through all entries, clearing them
- 0x2001000 - cache entry table pointer
- 0x201758c - font count
**Call targets:** 0x48344 (memory allocator)
**Called by:** Cache initialization

### 14. **0x4B140 - `get_cache_debug_flag`**
**Entry:** 0x4B140  
**Purpose:** Returns cache debugging flag status.  
1. Checks debug flag at 0x20173BF
2. Returns 0x18 if set, 0 if clear
**Return value:** D0 = 0x18 if debugging enabled, 0 otherwise
**RAM accessed:** 0x20173BF - debug flag
**Called by:** Debugging functions

### 15. **0x4B156 - `cleanup_cache`**
**Entry:** 0x4B156  
**Purpose:** Frees all cache memory allocations.  
1. Frees font descriptor array (0x2017584) if allocated
2. Frees additional font table (0x201757c) if allocated
3. Frees font hash table 1 (0x2017578) if allocated
4. Frees font hash table 2 (0x2017580) if allocated
5. Frees glyph cache table (0x2017504) if allocated
6. Frees glyph pointer table (0x2017508) if allocated
7. Frees cache pool (0x2017574) if allocated
8. Frees cache entry table (0x2001000) if allocated
9. Resets cache active flag (0x20175c0 = 0)
**RAM accessed:** All cache structure pointers
**Call targets:** 0x4DE50 (memory deallocator)
**Called by:** System shutdown/cleanup

### 16. **0x4B26C - `unknown_function_1`**
**Entry:** 0x4B26C  
**Purpose:** Unknown - calls error/notification function with string at 0xD9A4 and code -9.  
**Call targets:** 0x4D8D8 (error/notification function)

### 17. **0x4B284 - `copy_memory_block`**
**Entry:** 0x4B284  
**Purpose:** Copies a block of memory (wrapper for 0x3EF2C).  
**Arguments:** Source, destination, size, and additional parameter on stack
**Call targets:** 0x3EF2C (memory copy function)

### 18. **0x4B2A6 - `read_memory_value`**
**Entry:** 0x4B2A6  
**Purpose:** Reads a value from memory (wrapper for 0x3EF0A).  
**Arguments:** Address and size on stack
**Return value:** D0 = read value
**Call targets:** 0x3EF0A (memory read function)

### 19. **0x4B2CC - `complex_memory_operation_1`**
**Entry:** 0x4B2CC  
**Purpose:** Performs complex memory operation with context saving.  
1. Saves current execution context
2. Calls 0x4DF1C to perform operation
3. If successful, calls several other functions (0x3DA5E, 0x3E6F0, 0x3DDC4)
4. Updates some counter at 0x2001028
5. Restores context
**Arguments:** One parameter on stack
**Call targets:** 0x4DF1C, 0x3DA5E, 0x3E6F0, 0x3DDC4, 0x4D8D8

### 20. **0x4B35C - `complex_memory_operation_2`**
**Entry:** 0x4B35C  
**Purpose:** Similar to previous but with different parameters.  
1. Saves current execution context
2. Calls 0x4DF1C to perform operation
3. If successful, calls 0x3DDC4
4. Updates counter at 0x2001028
5. Restores context
**Arguments:** Two parameters on stack
**Call targets:** 0x4DF1C, 0x3DDC4, 0x4D8D8

### 21. **0x4B3C8 - `calculate_and_allocate`**
**Entry:** 0x4B3C8  
**Purpose:** Calculates size difference and allocates memory.  
1. Calls 0x3E6F0 with parameters
2. Calculates difference between two values
3. Calls 0x4B406 (allocation function)
4. Calls 0x3E52A with original parameters
**Arguments:** Two parameters on stack
**Call targets:** 0x3E6F0, 0x4B406, 0x3E52A

1. **Cache Structure:** The cache system has multiple components:
   - Font descriptors (72 bytes each)
   - Glyph cache entries (8 bytes each)
   - Hash tables for font lookup
   - Memory pool with free list management
   - Cache entry table (18 bytes per entry)

2. **Memory Management:** Uses a buddy-style allocator with headers containing:
   - Size field (24 bits)
   - Marker byte ('*' = 0x2A for headers, 'U' = 0x55 for free blocks)

3. **Built-in Fonts:** ROM contains font and glyph descriptor tables at 0x35690 and 0x35698 that are processed at initialization.

4. **Debug Support:** Extensive debugging functions for cache statistics and state dumping.

5. **Error Handling:** Robust error checking with reclamation when cache is full.

The analysis shows a sophisticated caching system for font and glyph data with proper memory management, statistics tracking, and debugging support.

; === CHUNK 16: 0x4B400-0x4C000 ===

### 1. **0x4B406 - `allocate_memory_with_gc`**
**Entry:** 0x4B406  
**Purpose:** Attempts to allocate memory, triggering garbage collection if necessary. Checks if enough memory is available, and if not, calls the garbage collector to free space. Uses a timeout mechanism to prevent infinite loops.  
**Arguments:** Size in bytes at FP@(8)  
**Return value:** D0 = 1 if allocation successful, 0 if failed  
**RAM accessed:** 0x2001020, 0x200101C, 0x2001028, 0x200102C (memory management globals)  
**Call targets:** 0x405F0 (memory check), 0x89A10/0x89A88/0x89998/0x89A58/0x89A28 (floating point math), 0x4C486 (garbage collector)  
**Called by:** Many functions needing memory allocation

### 2. **0x4B4F2 - `open_or_create_file`**
**Entry:** 0x4B4F2  
**Purpose:** Opens an existing file or creates a new one. Handles file creation with retry logic and error checking. Uses the filesystem's LRU cache for file handles.  
**Arguments:** FP@(8)=filename pointer, FP@(12)=mode, FP@(16)=creation flags  
**Return value:** D0 = file handle or error code  
**RAM accessed:** 0x20008F4 (file handle table)  
**Call targets:** 0xB406 (allocate_memory_with_gc), 0x3DD3E (file open), 0x4DF1C (filesystem operation)  
**Called by:** File I/O operations

### 3. **0x4B5A2 - `read_file_with_retry`**
**Entry:** 0x4B5A2  
**Purpose:** Reads data from a file with automatic buffer expansion. If the read would exceed the current buffer size, it doubles the buffer and retries. Handles partial reads and file errors.  
**Arguments:** FP@(8)=file handle, FP@(12)=buffer structure pointer, FP@(16)=bytes to read  
**Return value:** D0 = bytes read or error code  
**RAM accessed:** 0x20008F4 (file handle table)  
**Call targets:** 0x4C486 (garbage collector), 0x4D8D8 (error handler), 0x3E6F0 (file read), 0x3E52A (buffer resize)  
**Called by:** File loading operations

### 4. **0x4B692 - `compare_strings_case`**
**Entry:** 0x4B692  
**Purpose:** Case-sensitive string comparison for PostScript name objects. Compares two strings of specified length, returning -1, 0, or 1 for less/equal/greater.  
**Arguments:** A5=string1, A4=string2, D7=length (in words?)  
**Return value:** D0 = comparison result (-1, 0, 1)  
**Call targets:** None (leaf function)  
**Called by:** Name table lookups, dictionary searches

### 5. **0x4B6CE - `compute_string_hash`**
**Entry:** 0x4B6CE  
**Purpose:** Computes a 32-bit hash value for a string using a custom algorithm. Handles strings of various lengths (1-4 bytes specially, longer with mixing). Uses a multiplicative hash with constant 0x41C64E6D.  
**Arguments:** D6=string length, A5=string pointer  
**Return value:** D0 = 32-bit hash value  
**Call targets:** None (leaf function)  
**Called by:** Dictionary operations, name lookup

### 6. **0x4B7AE - `find_or_create_font_entry`**
**Entry:** 0x4B7AE  
**Purpose:** Main font cache lookup/creation function. Searches for a font in the cache by computing a hash from font name and attributes. If not found, loads font from disk and creates new cache entry.  
**Arguments:** FP@(8)=font descriptor pointer  
**Return value:** D0 = font cache entry pointer or NULL  
**RAM accessed:** 0x200101C, 0x2001020 (font system flags), 0x2017504/0x2017508 (font cache tables), 0x20008F4 (file handle table)  
**Call targets:** 0x4D4E4 (font system init), 0x4DF1C (filesystem op), 0x33BD4 (compute font hash), 0xB6CE (compute_string_hash), 0xB2A6 (allocate memory), 0x3EF0A (read file), 0xB692 (compare_strings_case), 0xB5A2 (read_file_with_retry), 0x3E760 (file seek)  
**Called by:** Font loading operations

### 7. **0x4BB26 - `create_font_metrics`**
**Entry:** 0x4BB26  
**Purpose:** Creates font metrics structure from font data. Reads font header, extracts metrics information, and builds a metrics structure for rendering.  
**Arguments:** FP@(8)=font data pointer, FP@(12)=metrics buffer, FP@(16)=file handle, FP@(20)=font size  
**Return value:** D0 = success (1) or failure (0)  
**RAM accessed:** 0x20008F4 (file handle table)  
**Call targets:** 0x4DF1C (filesystem op), 0x48934 (string formatting), 0xB50C (open_or_create_file), 0x3E6F0 (file read), 0x3E760 (file seek), 0x3EF2C (file write), 0x3F15C (file close), 0x4D8D8 (error handler)  
**Called by:** Font loading operations

### 8. **0x4BC90 - `calculate_font_memory_usage`**
**Entry:** 0x4BC90  
**Purpose:** Calculates total memory usage for a specific font by scanning the font cache and summing allocated blocks.  
**Arguments:** FP@(8)=font index  
**Return value:** D0 = total memory used in bytes  
**RAM accessed:** 0x2017504 (font cache table), 0x2017574 (heap base)  
**Call targets:** None (leaf function)  
**Called by:** Font management operations

### 9. **0x4BCF6 - `load_font_metrics_and_glyphs`**
**Entry:** 0x4BCF6  
**Purpose:** Loads font metrics and glyph data from disk. Searches font cache, loads if not present, extracts metrics and glyph outlines.  
**Arguments:** FP@(8)=font index, FP@(12)=metrics output buffer, FP@(16)=glyph output buffer, FP@(20)=load glyphs flag  
**Return value:** D0 = success/failure  
**RAM accessed:** 0x200101C, 0x2001020 (font system flags), 0x20008F4 (file handle table), 0x2017584 (font data table)  
**Call targets:** 0x4D4E4 (font system init), 0x957A (check font status), 0x4DF1C (filesystem op), 0x89CA (read font data), 0xB2A6 (allocate memory), 0x3EF0A (file read), 0x19364 (parse font data), 0xB5A2 (read_file_with_retry), 0x3E760 (file seek), 0xBC90 (calculate_font_memory_usage), 0xBB26 (create_font_metrics), 0x3EF2C (file write), 0x4D8D8 (error handler)  
**Called by:** Font rendering operations

1. `allocate_memory_wrapper` at 0x4B4F2 — calls allocate_memory_with_gc and returns. Real file open at 0x4B50C.

2. **0x4B50C**: This is the actual `open_or_create_file` function (not 0x4B4F2). It handles file creation with retry logic.

3. At 0x4B692, D7 = length in 16-bit words (used as word counter in loop)

4. **0x4B6CE**: The hash constant is 0x41C64E6D (not 0x41C64E6D as previously stated - actually same, just confirming).

5. `create_font_metrics` at 0x4BB26 — creates font metrics from font data

6. `calc_font_memory` at 0x4BC90 — calculates font memory usage

7. **0x4BCF6**: This function was also missed. It's a major font loading function.

**0x4B4EC-0x4B4F1**: Floating point constant (0x4059000000000000 = 100.0 in IEEE 754 double precision). This is used in `allocate_memory_with_gc` for memory threshold calculations.

**0x4B6F0-0x4B6F5**: Jump table for `compute_string_hash` string length dispatch (4 entries for lengths 1-4).

## FUNCTION CALL RELATIONSHIPS:

- `allocate_memory_with_gc` (0x4B406) is called by many functions including `open_or_create_file` (0x4B50C)
- `open_or_create_file` (0x4B50C) is called by `create_font_metrics` (0xBB26)
- `read_file_with_retry` (0x4B5A2) is called by `load_font_metrics_and_glyphs` (0xBCF6)
- `compare_strings_case` (0x4B692) is called by `find_or_create_font_entry` (0xB7AE)
- `compute_string_hash` (0x4B6CE) is called by `find_or_create_font_entry` (0xB7AE)
- `find_or_create_font_entry` (0xB7AE) is the main font cache manager
- `create_font_metrics` (0xBB26) is called by `load_font_metrics_and_glyphs` (0xBCF6)
- `calculate_font_memory_usage` (0xBC90) is called by `load_font_metrics_and_glyphs` (0xBCF6)

This region (0x4B400-0x4C000) appears to be focused on font management and file I/O operations within the PostScript interpreter.

; === CHUNK 17: 0x4C000-0x4CC00 ===

1. **0x4C000 is NOT `handle_error_or_cleanup`** - This is actually the continuation of a function that started earlier (likely around 0x4B26C). The code at 0x4C000 is handling error conditions and cleanup.

4. **0x4C258 and 0x4C286 are correctly identified** - These are global variable pair operations.

5. **0x4C308 is NOT `font_cache_insert`** - This is actually `schedule_font_load` that manages a priority queue of font loads.

### 1. 0x4C000 - `error_handler_continuation` (part of larger function)
**Entry:** 0x4C000  
**Purpose:** Continuation of error handling logic from earlier function. Handles error code 25 (0x19) specifically, calls error reporting function at 0x4D8D8. Also performs filesystem operations (read/write/sync).  
**Arguments:** Error code in fp@(-232), error data in fp@(-236)  
**Returns:** None (unwinds stack)  
**Hardware:** Calls 0x4D8D8 (error reporting), 0x3EF2C (filesystem write), 0x3EF0A (filesystem read), 0x3F15C (filesystem sync)  
**Algorithm:** Checks if error code is 25, if so reports error. Otherwise performs cleanup operations including filesystem writes.

### 2. 0x4C0C8 - `hash_table_lookup`
**Entry:** 0x4C0C8  
**Purpose:** Looks up a key in a hash table. Computes hash index (key & 0x3F * 12), then follows linked list of hash entries until finding matching key or reaching end (0x7FFFFFFF).  
**Arguments:** Key in fp@(8), hash table pointer in fp@(12)  
**Returns:** Value in D0 or 0x7FFFFFFF if not found  
**Hardware:** Calls 0x3EF0A (filesystem read) to read hash entries  
**Callers:** Used by font loading system (0x4C690, 0x4C86C) (PS font subsystem)
**Algorithm:** Hash entries are 12 bytes: [next_offset(4), key(4), value(4)]

### 3. 0x4C126 - `hash_table_insert`
**Entry:** 0x4C126  
**Purpose:** Inserts or updates a key-value pair in hash table. Handles collisions via linked list, allocates new entries when needed.  
**Arguments:** Key in fp@(8), value in fp@(12), hash table in fp@(16)  
**Hardware:** Calls 0x3EF0A (read), 0x3EF2C (write), 0x46334 (error), 0x3E760 (filesystem), 0x3F15C (sync)  
**Algorithm:** Finds empty slot or existing key, updates or inserts new 12-byte entry

### 4. 0x4C258 - `set_global_pair`
**Entry:** 0x4C258  
**Purpose:** Sets two global variables at 0x2001034 and 0x2001038. Used as temporary storage during font operations.  
**Arguments:** Two values in fp@(8) and fp@(12)  
**Hardware:** Writes to 0x2001034/0x2001038, calls 0x46334 on error  
**Callers:** Font loading functions (0x4C690, 0x4C86C) (PS font subsystem)

### 5. 0x4C286 - `check_global_pair`
**Entry:** 0x4C286  
**Purpose:** Verifies global variables match expected values, clears them if correct.  
**Arguments:** Expected values in fp@(8) and fp@(12)  
**Returns:** None, calls error 0x46334 on mismatch  
**Hardware:** Reads 0x2001034/0x2001038

### 6. 0x4C2B8 - `parse_hex_string`
**Entry:** 0x4C2B8  
**Purpose:** Converts hexadecimal ASCII string to 32-bit integer. Handles both cases.  
**Arguments:** String pointer in fp@(8)  
**Returns:** Integer in D0  
**Algorithm:** Processes each char, converts '0-9'/'a-f'/'A-F' to 0-15, accumulates result

### 7. 0x4C308 - `schedule_font_load`
**Entry:** 0x4C308  
**Purpose:** Schedules font for loading into cache. Computes font ID hash, checks if already in cache, manages priority queue of 32 entries.  
**Arguments:** Font ID in fp@(8), font data pointer in fp@(12), queue pointer in fp@(16)  
**Returns:** 0 in D0  
**Hardware:** Accesses 0x2001038 (font cache), calls 0x4C56C (load font), 0x4E040 (timer)  
**Algorithm:** Each queue entry is 24 bytes: [timestamp(4), font_data_ptr(12), font_hash(4), priority(4)]. Finds insertion point based on timestamp, maintains sorted order.

### 8. 0x4C486 - `initialize_font_scheduler`
**Entry:** 0x4C486  
**Purpose:** Initializes font loading scheduler with 32 empty slots, registers callback.  
**Returns:** Boolean in D0 (success/failure)  
**Hardware:** Allocates memory via 0x48344, calls 0x3DB18 (register callback), 0x4C56C (load font)  
**Algorithm:** Allocates 32×24=768 byte queue, fills with -1, registers 0x4C308 as callback

### 9. 0x4C56C - `load_font_into_cache`
**Entry:** 0x4C56C  
**Purpose:** Loads font into cache, updates data structures, handles font metrics.  
**Arguments:** Font hash in fp@(8), font data pointer in fp@(12), timestamp in fp@(16)  
**Hardware:** Accesses 0x2001000 (font table), 0x2017584 (font metrics), calls 0xB2A6, 0x4CDBE, 0x48934 (string formatting)  
**Algorithm:** Searches font table for matching hash, clears old entries, updates font metrics, formats font name strings

### 10. 0x4C690 - `load_font_by_index`
**Entry:** 0x4C690  
**Purpose:** Loads font by index into font table, handles hash table insertion.  
**Arguments:** Font index in fp@(8), font table index in fp@(12), data offset in fp@(16)  
**Returns:** Boolean in D0 (success/failure)  
**Hardware:** Accesses 0x2001000 (font table), 0x20008F4 (execution context), calls 0x4D4E4, 0xBCF6, 0x4DF1C, 0xB7AE, 0xC0C8, 0xC258, 0x3E6F0, 0xB5A2, 0x3E760, 0x3EF2C, 0x3F15C, 0xC126, 0xC286  
**Algorithm:** Complex font loading with error handling, hash table management, and filesystem operations

### 11. 0x4C86C - `cache_font_data`
**Entry:** 0x4C86C  
**Purpose:** Caches font data in memory, manages allocation and metadata.  
**Arguments:** Font hash in fp@(8)  
**Returns:** Status in D0 (0=success, -1=error, -2=no space)  
**Hardware:** Accesses 0x20174E0 (cache structure), 0x20008F4 (execution context), calls 0x4D4E4, 0x4DF1C, 0xB7AE, 0xC0C8, 0x3EF0A, 0x7DA8, 0x8384, 0x80B0, 0x8434, 0x3EF0A, 0x4D8D8  
**Algorithm:** Manages font cache with LRU-like behavior, handles memory allocation failures

### 12. 0x4CAFC - `font_cache_cleanup_callback`
**Entry:** 0x4CAFC  
**Purpose:** Callback for font cache cleanup, called during system shutdown.  
**Arguments:** Unknown in fp@(8)  
**Returns:** 0 in D0  
**Hardware:** Calls 0x3DDC4  
**Callers:** Registered as callback by 0x4CB12

### 13. 0x4CB12 - `build_font_directory`
**Entry:** 0x4CB12  
**Purpose:** Builds font directory hash table with 512 buckets, initializes font system.  
**Hardware:** Accesses 0xD966, 0xD978 (filesystem pointers), calls 0x3DB18, 0xB50C, 0x3E6F0, 0x3E760, 0x3EF2C, 0xB284, 0x3F15C  
**Algorithm:** Creates 512-entry hash table (2060 bytes), initializes with empty entries (0x7FFFFFFF), sets up font system data structures

1. **Font system uses 12-byte hash entries** with linked list collision resolution
2. **Font cache has 32-entry priority queue** managed by `schedule_font_load`
3. **Global pair at 0x2001034/1038** used as temporary storage during font operations
4. **Font directory has 512 buckets** initialized by `build_font_directory`
5. **Error code 25 (0x19)** is a special font/system error reported via 0x4D8D8
6. **Filesystem integration** throughout - fonts stored on disk, loaded on demand

- **0x4C000-0x4C0C6**: Continuation of earlier function (not standalone)
- **Hash table entries**: 12 bytes each [next(4), key(4), value(4)]
- **Font queue entries**: 24 bytes each [timestamp(4), data_ptr(12), hash(4), priority(4)]
- **Global variables**: 0x2001034/1038 used as temporary font operation storage

## CORRECTIONS FROM PRIOR ANALYSIS:

- 0x4C308 is `schedule_font_load` not `font_cache_insert`
- 0x4C486 is `initialize_font_scheduler` not missed function
- 0x4CB12 is `build_font_directory` - a key initialization function
- The region contains complete font management subsystem

; === CHUNK 18: 0x4CC00-0x4D800 ===

2. **Function names**: Many were misidentified or too generic
3. **Missing functions**: Several important functions weren't identified

### 1. 0x4CC00 - `initialize_font_hash_table`
**Entry:** 0x4CC00
**What it does:** Initializes the font hash table by clearing all 512 entries to 0x7FFFFFFF (empty marker). Sets up the hash table structure for font lookup.
**Hardware:** Calls 0x3E760 (likely memset), 0x3EF2C (write to filesystem), 0xB284 (hash table init)
**Key logic:** Loops 512 times (0x200), setting each entry to 0x7FFFFFFF
**Callers:** Font system initialization (PS font subsystem)

### 2. 0x4CC6E - `reload_all_fonts`
**Entry:** 0x4CC6E
**What it does:** Reloads all fonts from disk into memory. Iterates through font cache, checks if fonts need reloading, and loads them via `load_font_to_memory`.
**Hardware:** Accesses 0x2017354 (PS context), 0x2017584 (font cache start), 0x2017500 (font cache end), 0x2017504 (font structures)
**Key data structures:** Font cache entries are 72 bytes (0x48), font structures at 0x2017504
**Call targets:** 0x4D4E4 (font system init), 0x4C690 (load_font_to_memory), 0x3F22A (error check)
**Callers:** Font system recovery/initialization (PS font subsystem)

### 3. 0x4CDBE - `verify_font_directory_entry`
**Entry:** 0x4CDBE
**What it does:** Verifies a font directory entry by checking its consistency and following hash chains. Handles hash collisions by walking linked list.
**Arguments:** Font ID in fp@(10) (word), expected value in fp@(12) (long)
**Returns:** Success/failure (implicit)
**Hardware:** Calls 0xB2A6 (malloc), 0x3EF0A (read from filesystem), 0xB284 (hash lookup)
**Key algorithm:** Reads directory entry, follows hash chain using next pointers (linked list)
**Callers:** Font validation during loading (PS font subsystem)

### 4. 0x4CECE - `mark_font_loaded`
**Entry:** 0x4CECE
**What it does:** Marks a font as loaded in the font directory by setting flags. Searches sorted font directory for matching ID.
**Arguments:** Font ID in fp@(8), directory size in fp@(12), flag type in fp@(16) (0=normal, 1=permanent)
**Returns:** D0=1 if found and marked, 0 if not found
**Hardware:** Accesses 0x2001024 (font directory pointer)
**Key logic:** Binary search through sorted font directory (8-byte entries: 4-byte ID, 2-byte index, 2-byte flags)
**Callers:** 0x4CF1A, 0x4CF84 (font registration) (PS font subsystem)

### 5. 0x4CF1A - `register_font_operator`
**Entry:** 0x4CF1A
**What it does:** PostScript operator implementation for `registerfont`. Converts font ID string to hash, marks font as loaded, handles errors.
**Arguments:** Font ID string in fp@(8), operator table in fp@(16)
**Hardware:** Calls 0xC2B8 (parse_hex_string), 0x4CECE (mark_font_loaded), 0x488C0 (error reporting), 0xB2CC (string cleanup)
**Key logic:** Parses hex string like "000001F4", converts to integer, marks font as temporarily loaded (flag 6)
**Callers:** PostScript operator dispatch

### 6. 0x4CF84 - `permanent_font_operator`
**Entry:** 0x4CF84
**What it does:** PostScript operator implementation for `permanentfont`. Similar to registerfont but marks font as permanently loaded.
**Arguments:** Font ID string in fp@(8), operator table in fp@(16)
**Hardware:** Same as 0x4CF1A but marks with flag 7 (permanent)
**Key logic:** Marks font with permanent flag to prevent unloading
**Callers:** PostScript operator dispatch

### 7. 0x4CFF2 - `count_fonts_callback`
**Entry:** 0x4CFF2
**What it does:** Callback function that counts fonts during directory traversal. Increments counter for each valid font entry.
**Arguments:** Directory entry pointer in fp@(12), callback data in fp@(16)
**Returns:** D0=0 (continue traversal)
**Hardware:** Calls 0x3E6F0 (directory traversal helper)
**Key logic:** Reads entry count from directory structure, adds to accumulator
**Callers:** Font directory traversal (PS font subsystem)

### 8. 0x4D01C - `build_font_directory`
**Entry:** 0x4D01C
**What it does:** Builds the font directory by reading from disk, allocating memory, sorting entries, and registering operators.
**Hardware:** Calls 0xB26C (error handler), 0x3EF0A (read from filesystem), 0x80B0 (malloc), 0x4DE50 (sort function), 0x8208 (free), 0x3DB18 (operator registration)
1. Reads directory header (12 bytes) to get entry count
2. Allocates memory for sorted directory (8 bytes per entry)
3. Reads hash table to count entries per bucket
4. Validates counts (max 1 per bucket)
5. Reads all entries into memory
6. Sorts entries by font ID (bubble sort)
7. Registers registerfont and permanentfont operators
8. Verifies and marks loaded fonts
**Callers:** Font system initialization (PS font subsystem)

### 9. 0x4D4E4 - `initialize_font_system`
**Entry:** 0x4D4E4
**What it does:** Initializes the entire font system, handling errors and recovery.
**Hardware:** Accesses 0x2001020 (font system flag), 0x20008F4 (execution context), calls 0x4DF1C (error handler), 0x3DA5E (string compare), 0xB2CC (string cleanup), 0x4D8D8 (error reporting)
1. Sets up error context
2. Attempts to build font directory
3. On failure, tries alternative paths (Sys/Fonts vs Sys/Fonts/)
4. Handles error 25 (directory not found) specially
5. Recovers and retries on failure
**Callers:** System initialization

### 10. 0x4D62C - `reset_font_system`
**Entry:** 0x4D62C
**What it does:** Resets the font system, optionally rebuilding it. Clears font cache and reloads fonts.
**Arguments:** Reset type in fp@(8) (0=soft, 1=hard)
**Hardware:** Calls 0x46334 (error), 0x2017548 (font cache clear), 0x4DF1C (error handler), 0x4D8D8 (error reporting), 0xA670 (unknown), 0x28938 (unknown)
- Soft reset (0): Clears loaded flags, resets font cache
- Hard reset (1): Rebuilds entire font directory from disk
**Callers:** System recovery, error handling

### 11. 0x4D738 - `handle_font_system_error`
**Entry:** 0x4D738
**What it does:** Handles font system errors, attempts recovery, and reports status.
**Hardware:** Calls 0x4DF1C (error handler), 0xB2CC (string cleanup), 0x4D8D8 (error reporting), 0x4D62C (reset_font_system), 0x488C0 (error reporting)
1. Sets up error context
2. Checks for error 25 (directory not found)
3. Performs soft reset
4. Reports "Fonts initialized" message
5. Performs hard reset
**Callers:** Error recovery path

### 12. 0x4D7DC - `count_loaded_fonts`
**Entry:** 0x4D7DC
**What it does:** Counts the number of loaded fonts by traversing the font directory.
**Hardware:** Accesses 0x2001028 (font count), calls 0x3DB18 (directory traversal)
**Key logic:** Uses callback 0x4CFF2 to count fonts during directory traversal
**Callers:** Font system status reporting (PS font subsystem)

**0xD958:** String "Sys/Fonts" (null-terminated)
**0xD96A:** String "Sys/Fonts/" (null-terminated)
**0xD978:** Global pointer (likely filesystem context)
**0xD9D7:** String "registerfont" (error message context)
**0xD9FA:** String "permanentfont" (error message context)
**0xDA1D:** String "registerfont" (operator name)
**0xDA25:** String "permanentfont" (operator name)
**0xDA2D:** Format string "%08lx" (for hex font ID)
**0xDA36:** String "registerfont %s" (error message)
**0xDA56:** Format string "%08lx" (for hex font ID)
**0xDA5F:** String "permanentfont %s" (error message)
**0xDA7F:** String "Sys" (directory name)
**0xDA81:** String "Fonts initialized" (status message)
**0xDAC2:** String "FontDirectory" (directory traversal root)

1. **Font directory structure:** 8-byte entries: 4-byte font ID, 2-byte index, 2-byte flags (bits 6 and 7 for loaded/permanent)
2. **Hash table:** 512 buckets, linear probing with linked list overflow
3. **Error handling:** Robust recovery with fallback paths (Sys/Fonts vs Sys/Fonts/)
4. **Two-stage initialization:** First attempts to build directory, falls back to alternative on failure
5. **Font flags:** Bit 6 = temporarily loaded (registerfont), Bit 7 = permanently loaded (permanentfont)

## CORRECTIONS FROM PRIOR ANALYSIS:

1. **0x4CDBE** was misidentified - it's actually verifying font directory entries by following hash chains
2. **0x4D01C** is the main `build_font_directory` function, not a generic initialization
3. **0x4D4E4** is `initialize_font_system` with error recovery, not just "font system init"
4. **0x4D62C** handles both soft and hard resets, not just "reset fonts"
5. Added missing functions: `count_fonts_callback`, `handle_font_system_error`, `count_loaded_fonts`

The font system is more sophisticated than initially analyzed, with proper error recovery, hash table management, and two types of font loading (temporary vs permanent).

; === CHUNK 19: 0x4D800-0x4E400 ===

## REFINED ANALYSIS OF 0x4D800-0x4E400

### 1. Function at 0x4d800 (tail end of larger function)
**Entry address:** 0x4d800  
**Name:** `cleanup_and_return`
**Purpose:** Cleans up stack frame and returns. This is the tail end of a larger function that has already performed its work. The code pops 16 bytes from stack (4 arguments), then does UNLK/RTS.  
**Call targets:** 0x3db18 (likely error handling or logging)  
**Called by:** Unknown (tail of another function)  

---

### 2. Function at 0x4d826 (font cache manager)
**Entry address:** 0x4d826  
**Name:** `font_cache_control`
**Purpose:** Manages font cache operations based on operation code: 0=clear cache, 1=flush cache to disk, 2=disk cache operation. For case 0, resets font cache control variables and copies default font matrix data from ROM. For case 1, checks cache dirty flag, saves execution context, flushes cache if needed. For case 2, handles disk cache operations.  
**Arguments:** fp@(8) = operation code (0, 1, or 2)  
- 0x2001034, 0x2001038, 0x200101c, 0x2001020, 0x2001030, 0x2001028 (font cache control)
- 0x20173bf (cache dirty flag), 0x20173be (disk cache flag)
- 0x20008f4 (execution context stack pointer)
**Call targets:** 0x4df1c, 0x3da5e, 0x36f46, 0x46948, 0xd4e4, 0xd7dc  
**Called by:** PostScript operators related to font cache management

---

### 3. Data region at 0x4d956-0x4dacc (error/status strings)
**Address range:** 0x4d956-0x4dacc  
**Format:** ASCII strings with some embedded pointers  
**Content:** Error messages and status strings for font cache operations:
- "FC/NameID" (0x4d956)
- "FC/MIDFile" (0x4d968)
- Font cache matrix defaults (0x4d97c-0x4d9a4) - 9 longwords (36 bytes) of matrix data  (PS dict operator)
- "FC/NO.%F/BM.%F" (0x4d9a4)
- "Deleting unreferenced file %s\n" (0x4d9d8)
- "FC: Deleting unreferenced file %s\n" (0x4d9fc)
- "FC/NO.%F/BM.%F" (0x4da1c)
- "FC: Deleting unmatched file %s\n" (0x4da38)
- "FC/NO.%F/BM.%F" (0x4da58)
- "FC: Deleting unmatched file %s\n" (0x4da7e)
- "Fatal disk error encountered -- reinitializing disk font cache.\n" (0x4da7e)
- "FC/%F/B%" (0x4dac4)
- "flushcache" (0x4dacc)

---

### 4. Function at 0x4dadc (font entry comparator)
**Entry address:** 0x4dadc  
**Name:** `compare_font_entries`
**Purpose:** Compares two font cache entries (6 longwords each, 24 bytes total) for exact equality. Uses floating-point comparison function at 0x89980. Returns 1 if all 6 pairs match, 0 otherwise.  
**Arguments:** fp@(8) = pointer to first font entry, fp@(12) = pointer to second font entry  
**Return value:** D0 = 1 if equal, 0 if not equal  
**Hardware/RAM accessed:** Calls 0x89980 (floating-point comparison)  
**Call targets:** 0x89980 (6 times)  
**Called by:** Font cache lookup functions

---

### 5. Function at 0x4db76 (font cache processor)
**Entry address:** 0x4db76  
**Name:** `process_font_cache_entry`
**Purpose:** Processes a font for caching: applies transformations, checks cache for existing entry, allocates new cache slot if needed, updates font data structures. Handles both transformed and untransformed font cases. Complex function with matrix operations and cache management logic.  
- fp@(8) = pointer to font object A  stack frame parameter
- fp@(12) = pointer to font object B (with flags at offset 7)  struct field
- fp@(16) = transform  stack frame parameter
- fp@(20) = pointer to result structure  stack frame parameter
- 0x201751c, 0x2017518, 0x20174fc, 0x20174f8, 0x2017564, 0x2017560, 0x20175d4, 0x20175d0 (font cache structures)
- 0x2017584 (font cache table base)
**Call targets:** 0x46366, 0x308fa, 0x198ee, 0x191b8, 0x30708, 0x8b04, 0x46da2, 0x47ffe, 0x19a20, 0x30a18  
**Called by:** Font loading and transformation functions

---

### 6. Function at 0x4dea4 (font cache lookup wrapper)
**Entry address:** 0x4dea4  
**Name:** `lookup_font_in_cache`
**Purpose:** Wrapper function that prepares arguments for `process_font_cache_entry`. Gets current transformation matrix and font object, then calls the main processing function.  
**Call targets:** 0x19b4e, 0x3b6fa, 0xdb76, 0x365aa  
**Called by:** Font loading operations

---

### 7. Function at 0x4dee8 (alternative font cache lookup)
**Entry address:** 0x4dee8  
**Name:** `lookup_font_in_cache_alt`
**Purpose:** Similar to 0x4dea4 but uses different transformation source (0x3b81a instead of 0x19b4e). May be for transformed fonts or special cases.  
**Call targets:** 0x3b81a, 0x3b6fa, 0xdb76, 0x365aa  
**Called by:** Font loading operations for transformed fonts

---

### 8. Function at 0x4df48 (matrix transformation calculator)
**Entry address:** 0x4df48  
**Name:** `calculate_font_transform`
**Purpose:** Computes font transformation matrix from four input points (8 floating-point values). Uses floating-point operations extensively. Converts points to vectors, performs cross products, and normalizes results.  
- fp@(8) = result pointer  stack frame parameter
- fp@(12-28) = 8 floating-point values (4 points as x,y pairs)  stack frame parameter
- fp@(44) = output vector 1  stack frame parameter
- fp@(48) = output vector 2  stack frame parameter
**Call targets:** 0x899c8, 0x89a88, 0x19dd8, 0x4ed64, 0x4edea  
**Called by:** Font transformation functions

---

### 9. Function at 0x4e154 (font transformation entry point)
**Entry address:** 0x4e154  
**Name:** `apply_font_transform`
**Purpose:** Entry point for font transformation operations. Calls two subfunctions: one for initial processing (0x4e18a) and another for the main transformation (0x4e21a).  
- fp@(8-12) = two floating-point values  stack frame parameter
- fp@(16-32) = 8 floating-point values (4 points)  stack frame parameter
**Call targets:** 0x4e18a, 0x4e21a  
**Called by:** PostScript font transformation operators

---

### 10. Function at 0x4e18a (font transformation setup)
**Entry address:** 0x4e18a  
**Name:** `setup_font_transform`
**Purpose:** Sets up font transformation by getting current transformation matrix, applying initial adjustments, and preparing for the main transformation.  
**Arguments:** fp@(8-12) = two floating-point values  
- 0x20174e0 (graphics state pointer)
- 0x2017464 (system flags)
**Call targets:** 0x4640e, 0x1522c, 0x19eae, 0x4ea90, 0x4c1e4  
**Called by:** 0x4e154

---

### 11. Function at 0x4e21a (main font transformation)
**Entry address:** 0x4e21a  
**Name:** `perform_font_transform`
**Purpose:** Main font transformation function. Handles complex font rendering with clipping, scaling, and cache management. Includes bounds checking, matrix operations, and font cache lookups.  
- fp@(8-32) = 10 floating-point values (transformation parameters)  stack frame parameter
- 0x20174e0 (graphics state pointer)
- 0x2017464 (system flags)
- 0x2017510, 0x2017354, 0x2017574, 0x20175a8 (font cache structures)
**Call targets:** 0x4640e, 0x4ea90, 0x7da8, 0x89980, 0x1522c, 0x89a88, 0xdf48, 0x89920, 0x498ac, 0x899c8, 0x89a10  
**Called by:** 0x4e154

---

### 12. Data region at 0x4e3c4 (floating-point constant)
**Address:** 0x4e3c4  
**Format:** 32-bit floating-point constant  
**Content:** Reference to 0xe812 (out of current range, likely a floating-point constant table)  
**Purpose:** Used in font transformation calculations (likely π/2 or similar trigonometric constant)

---

1. Added 6 missing functions: 0x4dea4, 0x4dee8, 0x4df48, 0x4e154, 0x4e18a, 0x4e21a
2. Corrected data/code boundary at 0x4e3c4 (it's a data reference, not code)
3. The region contains a complete font caching and transformation subsystem with:
   - Cache management (0x4d826)
   - Entry comparison (0x4dadc)
   - Cache processing (0x4db76)
   - Lookup wrappers (0x4dea4, 0x4dee8)
   - Matrix calculations (0x4df48)
   - Transformation pipeline (0x4e154, 0x4e18a, 0x4e21a)
4. All functions follow standard C calling convention with LINK/UNLK frames
5. Extensive use of floating-point library at 0x899xx for comparisons and math

; === CHUNK 20: 0x4E400-0x4F000 ===

### 1. Function at 0x4e400
**Entry address:** 0x4e400  
**Name:** `render_glyph_or_path`
**What it does:** Complex glyph rendering function that handles coordinate transformations, Bézier curve calculations, and font cache management. It appears to render either a glyph or a path segment with Bézier curves. The function performs floating-point operations, checks cache validity, allocates memory for glyph data, and handles both software and hardware rendering paths.  
- Multiple arguments on stack (complex function with many local variables)
- fp@(8), fp@(12), fp@(16), fp@(20), fp@(24) - various coordinate pairs and transformation matrices  coordinate data  (font metric data)
- 0x20175a8, 0x2017574, 0x2017464 (font cache structures)
- 0x2001818 (global state)
- Calls floating point routines at 0x89ab8, 0x89a88, 0x89920, 0x899c8, 0x89a10, 0x89980
- Calls functions at 0x498ac, 0x3ce34, 0x1556e, 0x15406, 0x14d40, 0x1a422
**Key branch targets:** 0xe72a (error/fallback path), 0xe80a (successful return)

### 2. Function at 0x4e828
**Entry address:** 0x4e828  
**Name:** `transform_and_render_bezier`
**What it does:** Transforms Bézier curve control points and calls the main rendering function. Gets current transformation matrices, applies them to Bézier control points, then calls the rendering function at 0xe154.  
- fp@(8), fp@(12), fp@(16), fp@(20), fp@(24), fp@(28) - Bézier control points (x1,y1,x2,y2,x3,y3)  stack frame parameter
- Calls 0x3bce8 (get transformation matrix) three times
- Calls 0xe154 (main Bézier rendering)  (PS dict operator)
**Key branch targets:** None (straight-line function)

### 3. Function at 0x4e87a
**Entry address:** 0x4e87a  
**Name:** `render_transformed_point`
**What it does:** Transforms a single point using current transformation and renders it. Gets current transformation, applies it to a point, and either renders directly or uses cached rendering.  
- fp@(8), fp@(12) - point coordinates (x,y)  coordinate data  (font metric data)
- 0x20174e0 (current graphics state)
- Calls 0x3bce8 (get transformation), 0xe18a (point rendering), 0x1a422 (fallback rendering), 0x1556e, 0x15406 (coordinate operations)  (PS dict operator)
**Key branch targets:** 0xe8ae (check if hardware rendering available)

### 4. Function at 0x4e8de
**Entry address:** 0x4e8de  
**Name:** `gsave_implementation`
**What it does:** Saves the current graphics state onto a stack. This is the implementation of PostScript's `gsave` operator. It saves the current state, allocates a new state block if needed, and updates global pointers.  
- 0x20174e0 (current graphics state)
- 0x2001818, 0x200181a (stack management)
- 0x2017510 (state pointer)
- Calls 0x46334 (state validation), 0x48344 (memory allocation), 0x4de50 (state copying)  (PS font cache)
**Key branch targets:** 0xe902 (stack full check), 0xe91c (allocate new state)

### 5. Function at 0x4e964
**Entry address:** 0x4e964  
**Name:** `grestore_implementation`
**What it does:** Restores a previously saved graphics state. This is the implementation of PostScript's `grestore` operator. It pops state from stack, updates global pointers, and frees memory if needed.  
- 0x20174e0 (current graphics state)
- 0x2001818 (stack management)
- 0x2017510 (state pointer)
- Calls 0x46334 (state validation), 0x4836c (memory deallocation)  (PS font cache)
**Key branch targets:** 0xe984 (stack empty check), 0xe9b0 (free memory if needed)

### 6. Function at 0x4e9b8
**Entry address:** 0x4e9b8  
**Name:** `update_glyph_cache_entry`
**What it does:** Updates a glyph cache entry with new transformation data. Copies transformation matrices and updates cache structures.  
- fp@(8) - pointer to transformation data  stack frame parameter
- 0x20174d0, 0x20174d4 (global transformation)
- 0x2017464 (cache structure)
- Calls 0x308fa (matrix operation)
**Key branch targets:** None

### 7. Function at 0x4ea00
**Entry address:** 0x4ea00  
**Name:** `apply_transformation_with_gsave`
**What it does:** Applies a transformation matrix with gsave/grestore protection. Saves state, applies transformation, performs operation, then restores state. Handles nested graphics states.  
- fp@(8), fp@(12) - transformation matrix  stack frame parameter
- 0x2001818 (global state)
- 0x20008f4 (execution context)
- Calls 0x4de50 (state copy), 0x4df1c (context check), 0xe8de (gsave), 0xeb7c (apply transform), 0xe964 (grestore)  (PS gstate operator)
**Key branch targets:** 0xea78 (error path)

### 8. Function at 0x4ea90
**Entry address:** 0x4ea90  
**Name:** `validate_coordinate_range_fixed`
**What it does:** Validates that coordinates are within a specified fixed-point range. Converts coordinates, checks bounds, returns success/failure.  
- fp@(8) - output buffer for coordinates  coordinate data  (font metric data)
- fp@(12), fp@(16) - first coordinate pair  coordinate data  (font metric data)
- fp@(20), fp@(24) - range limits (min, max)  stack frame parameter
- Calls 0x4c218 (coordinate conversion)  coordinate data  (font metric data)
**Return value:** D0 = 1 if in range, 0 if out of range
**Key branch targets:** 0xeaf8 (out of range), 0xeafc (in range)

### 9. Function at 0x4eb06
**Entry address:** 0x4eb06  
**Name:** `validate_coordinate_range_float`
**What it does:** Similar to 0x4ea90 but for floating-point coordinates. Validates that coordinates are within a specified floating-point range.  
- fp@(8) - output buffer for coordinates  coordinate data  (font metric data)
- fp@(12), fp@(16) - first coordinate pair (float)  coordinate data  (font metric data)
- fp@(20), fp@(24) - range limits (min, max as float)  stack frame parameter
- Calls 0x15872 (float coordinate conversion)  coordinate data  (font metric data)
**Return value:** D0 = 1 if in range, 0 if out of range
**Key branch targets:** 0xeb6e (out of range), 0xeb72 (in range)

### 10. Function at 0x4eb7c
**Entry address:** 0x4eb7c  
**Name:** `apply_current_transformation`
**What it does:** Applies the current transformation matrix to the graphics state. Handles complex transformation logic with hardware/software fallbacks.  
- 0x20174e0 (current graphics state)
- 0x2017464 (transformation cache)
- 0x2017510 (state pointer)
- Calls 0x324ac, 0x4639e, 0x1534e, 0x8d4e, 0x1583c, 0x4f452, 0x4f852, 0x4ff22
**Key branch targets:** 0xed5a (exit), 0xed54 (fallback path)

### 11. Function at 0x4ed64
**Entry address:** 0x4ed64  
**Name:** `max_of_two_floats`
**What it does:** Returns the maximum of two floating-point values. Uses floating-point comparison and selection.  
- fp@(8), fp@(12) - first float (value, exponent)  stack frame parameter
- fp@(16), fp@(20) - second float (value, exponent)  stack frame parameter
- fp@(24), fp@(28) - third float (value, exponent)  stack frame parameter
- fp@(32), fp@(36) - fourth float (value, exponent)  stack frame parameter
- Calls 0x89968 (float compare), 0x899c8 (float conversion), 0x89980 (float compare), 0x89a88 (float operation)
**Return value:** D0 = maximum float value
**Key branch targets:** 0xed86 (select second), 0xedb6 (select fourth), 0xeddc (select second max)

### 12. Function at 0x4edea
**Entry address:** 0x4edea  
**Name:** `min_of_two_floats`
**What it does:** Returns the minimum of two floating-point values. Similar to 0x4ed64 but for minimum.  
**Arguments:** Same as 0x4ed64
- Calls same floating-point routines as 0x4ed64
**Return value:** D0 = minimum float value
**Key branch targets:** 0xee0c (select second), 0xee3c (select fourth), 0xee62 (select second min)

### 13. Function at 0x4ee70
**Entry address:** 0x4ee70  
**Name:** `transform_and_render_with_gsave`
**What it does:** Wrapper that applies transformation and rendering with gsave/grestore protection. Similar to 0x4ea00 but for rendering operations.  
**Arguments:** Implicit (uses current transformation)
- 0x2001818, 0x20008f4 (global state)
- Calls 0x4de50, 0x4df1c, 0xe8de, 0x3b9b4, 0xeb7c, 0xe964, 0x4d8d8
**Key branch targets:** 0xeee4 (error path)

### 14. Function at 0x4eefc
**Entry address:** 0x4eefc  
**Name:** `stroke_path_implementation`
**What it does:** Implements path stroking (PostScript `stroke` operator). Sets up stroking state, applies transformations, performs stroking calculation.  
- 0x2001818, 0x20008f4 (global state)
- 0x20174e0 (graphics state)
- 0x2017464 (path data)
- Calls 0x4de50, 0x4df1c, 0xe8de, 0x3b9b4, 0xeb7c, 0x22f58, 0x1556e, 0x3bde2, 0xe964, 0x4d8d8
**Key branch targets:** 0xefca (error path)

### 15. Function at 0x4efe2
**Entry address:** 0x4efe2  
**Name:** `clip_path_implementation`
**What it does:** Implements path clipping (PostScript `clip` operator). Begins clipping operation with state protection.  
- 0x2001818 (global state)
- Calls 0x4de50 (state copy)
### 1. Floating-point constants at 0x4e812-0x4e826
**Address:** 0x4e812  
**Format:** Three 8-byte IEEE double-precision floating-point constants:
- 0x4e812: 5.0 (0x4014000000000000)
- 0x4e81a: 2.0 (0x4000000000000000)  
- 0x4e822: 1.5 (0x3FF8000000000000) or possibly 1.75 (needs verification)

1. **Graphics State Structure:** Confirmed as 106 bytes (0x6A) based on the allocation in `gsave`.

2. **Hardware Acceleration:** Multiple functions check bit 6 at 0x20174e0+18 to determine if hardware rendering is available, with fallbacks to 0x1a422.

3. **Transformation Pipeline:** Complex transformation system with caching at 0x2017464.

4. **PostScript Operators:** Clear implementations of `gsave` (0x4e8de), `grestore` (0x4e964), `stroke` (0x4eefc), and `clip` (0x4efe2).

5. **Coordinate Systems:** Both fixed-point (0x4ea90) and floating-point (0x4eb06) coordinate validation functions.

; === CHUNK 21: 0x4F000-0x4FC00 ===

### 1. Function at 0x4F000
**Entry:** 0x4F000  
**Name:** `makefont`
**What it does:** Creates a font by allocating memory for font metrics, initializing transformation matrices, and setting up font data structures. It handles error checking and sets font scaling flags. This appears to be the PostScript `makefont` operator implementation.  
**Arguments:** Likely takes font dictionary and matrix parameters on stack  
**Return:** Font object or error  
**Hardware/RAM:** Accesses 0x020174E0 (current font structure), calls 0x3B9B4 (matrix operation), 0x3B626 (allocation), 0x15526 (matrix multiplication)  
**Key branches:** 0xF0B6 (error path), 0xF0CA (success path)  
**Callers:** PostScript operator dispatcher  
**Notes:** Sets bit 5 at offset 0x12 in font structure (0x020174E0+18), indicating font is scaled

### 2. Function at 0x4F0CE
**Entry:** 0x4F0CE  
**Name:** `scalefont`
**What it does:** Scales an existing font by adjusting its transformation matrix. Similar to makefont but operates on an already created font. This appears to be the PostScript `scalefont` operator.  
**Arguments:** Font handle and scaling factor on stack  
**Return:** Scaled font object or error  
**Hardware/RAM:** Accesses 0x020174E0, calls 0x3B9B4, 0x3BCE8 (matrix operation), 0x15526  
**Key branches:** 0xF178 (error), 0xF18C (success)  
**Callers:** PostScript operator dispatcher  
**Notes:** Sets bit 4 at offset 0x12 in font structure, indicating horizontal scaling

### 3. Function at 0x4F190
**Entry:** 0x4F190  
**Name:** `cachedevice`
**What it does:** Sets up device caching for font rendering by initializing cache structures and enabling caching flags. This appears to be the PostScript `cachedevice` operator for Type 3 fonts.  
**Arguments:** Device parameters (width, height, matrix) on stack  
**Return:** Success/failure  
**Hardware/RAM:** Accesses 0x020174E0, calls 0x3B9B4, 0x3BA8E (cache setup)  
**Key branches:** 0xF224 (error), 0xF238 (success)  
**Callers:** PostScript operator dispatcher  
**Notes:** Sets bit 3 at offset 0x12 in font structure, indicating caching enabled

### 4. Function at 0x4F23C
**Entry:** 0x4F23C  
**Name:** `setcacheddevice`
**What it does:** Similar to cachedevice but with additional matrix operations and both horizontal/vertical scaling. Sets up cached device with transformation matrices. This appears to be the PostScript `setcacheddevice` operator.  
**Arguments:** Device parameters with caching flags on stack  
**Return:** Success/failure  
**Hardware/RAM:** Accesses 0x020174E0, calls 0x3B9B4, 0x3BCE8, 0x15526, 0x3B626  
**Key branches:** 0xF346 (error), 0xF35A (success)  
**Callers:** PostScript operator dispatcher  
**Notes:** Sets both bits 4 and 5 at offset 0x12 in font structure (horizontal and vertical scaling)

### 5. Function at 0x4F35E
**Entry:** 0x4F35E  
**Name:** `get_glyph_metrics`
**What it does:** Looks up glyph metrics from font data structure based on character code. Traverses linked list of glyph entries in the glyph cache. Returns pointer to glyph data or NULL if not found.  
**Arguments:** Character code in %fp@(10) (word)  
**Return:** Glyph data pointer in D0 (or 0 if not found)  
**Hardware/RAM:** Accesses 0x020174E0 (font struct), 0x02017504 (glyph table base), 0x02017510 (current glyph cache index)  
**Key branches:** 0xF3B0 (not found), 0xF3E4 (continue search)  
**Callers:** Glyph rendering functions (PS font rendering)
1. Gets font's encoding table pointer (offset 0x48)
2. Calculates index: charcode * 8
3. Checks if entry type is 3 (glyph reference)
4. Follows linked list through glyph cache (offset 0x06 in cache entries)
5. Returns pointer to glyph data if found in cache

### 6. Function at 0x4F3F4
**Entry:** 0x4F3F4  
**Name:** `check_rectangle_intersection`
**What it does:** Checks if two rectangles intersect by comparing their coordinates. Takes four rectangle coordinates as arguments and returns boolean result.  
**Arguments:** Four rectangle coordinates in %fp@(8), %fp@(12), %fp@(16), %fp@(20)  
**Return:** Boolean in D0 (0 = no intersection, -1 = intersection)  
**Hardware/RAM:** Calls 0x1583C (coordinate conversion), 0x1DCFE (rectangle intersection test)  
**Key branches:** None significant  
**Callers:** Glyph rendering functions (PS font rendering)
**Notes:** Uses coordinate conversion before intersection test

### 7. Function at 0x4F452
**Entry:** 0x4F452  
**Name:** `render_glyph_string`
**What it does:** Renders a string of glyphs by processing each character, looking up glyph metrics, and accumulating positions. Handles font scaling, caching, and clipping.  
**Arguments:** String pointer and length in stack, plus rendering flags  
**Return:** Number of glyphs rendered or error code (-1)  
**Hardware/RAM:** Accesses 0x020174E0 (font struct), 0x02017504 (glyph table), 0x02017510 (cache index), 0x0200103C (glyph buffer)  
**Key branches:** 0xF846 (error return), 0xF848 (success return)  
**Callers:** PostScript `show` operator  
1. Gets font structure and checks scaling flags
2. Processes each character in string
3. Looks up glyph in encoding table and cache
4. Updates current position based on glyph metrics
5. Handles clipping and rendering bounds
6. Accumulates glyphs in buffer at 0x0200103C

### 8. Function at 0x4F852
**Entry:** 0x4F852  
**Name:** `flush_glyph_buffer`
**What it does:** Flushes accumulated glyphs from the buffer to the rendering system. Processes each glyph in the buffer and updates current position.  
**Arguments:** Number of glyphs to flush in %fp@(8)  
**Hardware/RAM:** Accesses 0x0200103C (glyph buffer), 0x020174E0 (font struct), calls 0x16ABC (glyph rendering)  
**Key branches:** None significant  
**Callers:** Glyph rendering functions (PS font rendering)
**Notes:** Uses buffer at 0x0200103C with 12-byte entries (x, y, glyph data)

### 9. Function at 0x4F8D4
**Entry:** 0x4F8D4  
**Name:** `cache_glyph`
**What it does:** Caches a glyph in the glyph cache, handling cache management, LRU updates, and memory allocation.  
**Arguments:** Glyph data pointer and cache parameters in stack  
**Return:** Success/failure  
**Hardware/RAM:** Accesses 0x020174E0 (font struct), 0x02017504 (glyph table), 0x02017510 (cache index), 0x02017574 (cache memory)  
**Key branches:** 0xFC9A (success), 0xFD94 (error)  
**Callers:** Glyph rendering when glyph not in cache (PS font rendering)
1. Checks if glyph already in cache
2. Allocates cache entry if needed
3. Updates LRU chain
4. Copies glyph data to cache
5. Updates font metrics

### 1. Glyph buffer at 0x0200103C
**Size:** Variable, appears to be 12-byte entries  
**Format:** Each entry contains: x position (4 bytes), y position (4 bytes), glyph data pointer (4 bytes)  
**Used by:** `render_glyph_string` and `flush_glyph_buffer`

### 2. Font structure at 0x020174E0
**Size:** At least 80 bytes  
- 0x00: Current x position
- 0x04: Current y position  
- 0x12: Font flags (bits: 3=cache, 4=hscale, 5=vscale)  (PS CTM operator)
- 0x13: Last character code
- 0x18: String pointer
- 0x22: String length (word)
- 0x24: Horizontal offset  struct field
- 0x28: Vertical offset  struct field
- 0x2C: Scale matrix
- 0x48: Encoding table pointer
- 0x4C: Cache index (word)
- 0x4E: Cache memory pointer

1. The function at 0x4F3F4 is NOT `get_glyph_metrics` - that's at 0x4F35E. 0x4F3F4 is `check_rectangle_intersection`.

3. The glyph cache structure is more complex than previously described: entries are 8 bytes with forward pointer at offset 0x06, and there's an LRU management system.

4. The font structure size is confirmed to be at least 80 bytes based on the offsets accessed.

1. **Glyph caching system:** Uses a linked list per glyph with LRU management. Cache entries at 0x02017504 are 8 bytes each.

2. **Rendering pipeline:** Glyphs are accumulated in a buffer (0x0200103C) and flushed in batches for efficiency.

3. **Font scaling:** Separate flags for horizontal (bit 4) and vertical (bit 5) scaling in font structure.

4. **Coordinate system:** Uses fixed-point coordinates with 8 bits of fraction (as seen by the >>8 operations).

5. **Error handling:** Functions return -1 for errors, 0 for success in many cases.

; === CHUNK 22: 0x4FC00-0x50800 ===

### 1. Function at 0x4FC00 (continuation from earlier)
**Entry:** 0x4FC00 (actually part of a larger function starting earlier)  
**What it does:** This is part of a glyph rendering function that processes font metrics and updates bounding boxes. It handles font transformation matrices and glyph positioning.  
- Updates max x/y coordinates in a structure (at A2@(64) and A2@(68))  coordinate data  (font metric data)
- Processes font flags (bits 0-4) at A2@
- Handles transformation matrices for glyph positioning
- Calls 0x4C1E4 (matrix multiplication) and 0x22F26 (coordinate transformation)  coordinate data  (font metric data)

**Arguments:** Continuation from earlier function - uses A2, A3, A4, A5 registers  
**Hardware/RAM:** Accesses 0x02017584 (font cache structure), 0x02017574 (font data base), 0x020174E0 (font structure)  
**Call targets:** 0x4C1E4, 0x22F26, 0xEB06, 0x16ABC

### 2. Function at 0x4FF22 (corrected)
**Entry:** 0x4FF22  
**Name:** `render_glyph_cache`
**Purpose:** Iterates through all glyphs in the font cache and renders each one. Handles error checking and calls the actual glyph rendering function.  
**Hardware/RAM:** Accesses 0x020174E0 (font structure), calls 0x31DBE (error checking), 0x4D8D8 (error reporting), 0xF8D4 (glyph rendering)  
**Call targets:** Called from font rendering routines  
1. Gets glyph count from font structure at offset 22
2. Loops through all glyphs (0 to count-1)
3. For each glyph: checks for errors, looks up glyph metrics, calls render function
4. Handles font transformation if bit 6 is not set in font flags

### 3. Function at 0x4FFD4 (corrected)
**Entry:** 0x4FFD4  
**Name:** `setup_font_render_context`
**Purpose:** Sets up the font rendering context, handling nested rendering contexts and initializing transformation matrices.  
- fp@(8): First parameter (context type or flag)  stack frame parameter
- fp@(12): Second parameter (context data)  stack frame parameter
**Hardware/RAM:** Accesses 0x02001818 (rendering context depth), 0x020008F4 (context stack), 0x02017464 (graphics state), 0x02017510 (current font ID)  
**Call targets:** 0x4DE50, 0x4DF1C, 0xE8DE, 0x4639E, 0x1534E, 0xE9B8, 0x8D4E, 0xF8D4  
1. Checks if this is a nested rendering context (depth > 0)
2. If nested: saves current context to stack
3. Initializes font matrices from graphics state
4. Sets up current font ID and transformation
5. Calls initial glyph rendering

### 4. Function at 0x500F8 (corrected)
**Entry:** 0x500F8  
**Name:** `find_bitmap_bounds`
**Purpose:** Scans a bitmap to find the bounding box of non-zero pixels. Used for glyph bounding box calculation.  
- fp@(8): Bitmap structure pointer  stack frame parameter
- fp@(12): Pointer to store min coordinates (x,y)  coordinate data  (font metric data)
- fp@(16): Pointer to store max coordinates (x,y)  coordinate data  (font metric data)
**Return:** D0 = 1 if non-zero pixels found, 0 if empty bitmap  
**Hardware/RAM:** Accesses bitmap structure: 
  - A5@(2) = width in words  (font metric)
  - A5@(4) = height in rows  (font metric)
  - A5@(6) = data offset  struct field
**Call targets:** None (leaf function)  
1. Scans rows from top to find first non-zero row
2. Scans columns from left to find first non-zero column
3. Scans rows from bottom to find last non-zero row  
4. Scans columns from right to find last non-zero column
5. Uses bitmask tables at 0x5518C and 0x551AC for efficient bit scanning

### 5. Function at 0x5020E (corrected)
**Entry:** 0x5020E  
**Name:** `allocate_glyph_bitmap`
**Purpose:** Allocates and initializes memory for glyph bitmap rendering, handling compression and buffer management.  
**Arguments:** fp@(8): Boolean flag (0=use pre-allocated buffer, 1=allocate new)  
**Hardware/RAM:** Accesses 0x02017574 (font data base), 0x020175A8 (buffer pointer), 0x020174E0 (font structure), 0x02017354 (hash table)  
**Call targets:** 0x1134 (size calculation), 0x80B0 (malloc), 0x4DCF8 (copy function), 0x13D7A (compression function), 0x14D40 (rendering function), 0x180E4/0x18178 (hardware acceleration)  
1. Calculates bitmap dimensions and required memory
2. Allocates memory from heap or uses pre-allocated buffer
3. Handles compressed vs. uncompressed bitmap formats
4. Sets up bitmap header structure
5. Calls hardware acceleration if available

### 6. Function at 0x5059E (corrected)
**Entry:** 0x5059E  
**Name:** `set_font_cache_mode`
**Purpose:** Sets the font cache mode (0=normal, 1=debug). In debug mode, prints font cache statistics.  
**Arguments:** fp@(8): Mode (0 or 1)  
**Hardware/RAM:** Accesses 0x020174E0 (font structure)  
**Call targets:** 0x469FA (print function)  
1. If mode=0: sets font structure pointer to default location
2. If mode=1: calls print function with debug information
3. Otherwise: does nothing

### 7. Data Region at 0x505CC-0x50688
**Address:** 0x505CC  
**Size:** 188 bytes (0xBC)  
**Format:** String table with font-related operator names  
- 0x505CC: "makefont"
- 0x505D4: "scalefont"  (PS CTM operator)
- 0x505E0: "setcachedevice"
- 0x505F4: "setcharwidth"  (font metric)
- 0x50600: "show"  (PS text operator)
- 0x50606: "ashow"  (PS text operator)
- 0x5060C: "kshow"  (PS text operator)
- 0x50612: "widthshow"  (PS text operator)  (font metric)
- 0x5061C: "awidthshow"  (PS text operator)  (font metric)
- 0x50628: "stringwidth"  (font metric)
- 0x50634: "show" (duplicate, likely different context)  (PS text operator)

### 8. Function at 0x5068C (corrected)
**Entry:** 0x5068C  
**Name:** `init_font_subsystem`
**Purpose:** Initializes the font subsystem by setting up operator tables and data structures.  
**Arguments:** fp@(8): Boolean flag (0=normal init, 1=reinit)  
**Hardware/RAM:** Accesses 0x020174E0 (font structure)  
**Call targets:** 0x14FE6 (table initialization)  
1. If flag=0: returns immediately (already initialized)
2. If flag=1: calls table initialization function with operator name table

### 9. Data Region at 0x506AC-0x50738
**Address:** 0x506AC  
**Size:** 140 bytes (0x8C)  
**Format:** Jump table or function pointer table  
**Content:** Array of 20 function pointers (4 bytes each) pointing to various font-related functions

### 10. Data Region at 0x50704-0x50738
**Address:** 0x50704  
**Size:** 52 bytes (0x34)  
**Format:** Another function pointer table  
**Content:** Array of 13 function pointers (4 bytes each) for font operators

### 11. Function at 0x5073C (corrected)
**Entry:** 0x5073C  
**Name:** `calculate_bitmap_address`
**Purpose:** Calculates the memory address of a specific pixel in a bitmap given x,y coordinates.  
- fp@(8): X coordinate  coordinate data  (font metric data)
- fp@(12): Y coordinate  coordinate data  (font metric data)
**Return:** D0 = memory address  
**Hardware/RAM:** Accesses 0x02017364 (bitmap base), 0x020009C4 (bytes per row), 0x020009C0 (bitmap data pointer)  
1. Subtracts bitmap base from X coordinate
2. Multiplies by bytes per row
3. Adds bitmap data pointer
4. Divides Y coordinate by 16 (bits per word)
5. Returns final address

### 12. Function at 0x50770 (corrected)
**Entry:** 0x50770  
**Name:** `dummy_font_function`
**Purpose:** Empty placeholder function that does nothing.  
### 13. Function at 0x50778 (corrected)
**Entry:** 0x50778  
**Name:** `validate_bitmap_region`
**Purpose:** Validates that a bitmap region (x,y,width,height) is within bounds.  
- fp@(8): X coordinate  coordinate data  (font metric data)
- fp@(12): Y coordinate  coordinate data  (font metric data)
- fp@(16): Width  stack frame parameter
- fp@(20): Height  stack frame parameter
- fp@(24): Callback function  stack frame parameter
- fp@(28): Callback data  stack frame parameter
**Return:** D0 = 0 if valid, 2 if invalid  
**Hardware/RAM:** Accesses 0x020009C8 (bitmap width), 0x020009CC (bitmap height), 0x020009C0 (bitmap data)  
1. Checks all coordinates are non-negative
2. Verifies x+width <= bitmap width
3. Verifies y+height <= bitmap height
4. If valid: calculates address and calls callback
5. Returns status code

3. **Function at 0x5020E**: This is the real `allocate_glyph_bitmap` function, not the bounds scanner.

5. **Function at 0x5073C**: This is a bitmap address calculation utility, not part of the font system.

6. **Function at 0x50778**: This is a region validation function, not related to fonts.

This region contains a mix of:
1. Font rendering functions (0x4FC00-0x4FF20, 0x4FF22-0x4FFD2, 0x4FFD4-0x500F6)
2. Bitmap utilities (0x500F8-0x5020C, 0x5073C-0x5076E, 0x50778-0x50800)
3. Font cache management (0x5020E-0x5059C, 0x5059E-0x505CA)
4. Font operator initialization (0x5068C-0x506AA)
5. Data tables (0x505CC-0x50688, 0x506AC-0x50738)

The font system uses a complex caching mechanism with both software and hardware acceleration paths, and includes comprehensive error checking and validation.

; === CHUNK 23: 0x50800-0x51400 ===

### 1. Function at 0x50800-0x50826 (END OF PREVIOUS FUNCTION)
**Entry:** 0x50800 (function starts earlier at 0x107fa)  
**Name:** `fill_span_loop`  
**Purpose:** Inner loop for filling horizontal spans. Calls a per-pixel callback function for each scanline, adding the display stride (0x20009c8) to the current pointer each iteration. Used for pattern or solid fills.  
**Arguments:** %fp@(24)=callback function pointer, %fp@(20)=count (number of scanlines), %fp@(-4)=current display buffer pointer  
**Return:** D0=0  
**RAM accessed:** 0x20009c8 (display stride in bytes)  
**Call targets:** Indirect call to callback at %a0@  
**Called by:** Unknown (function starts before 0x50800, likely part of a larger fill routine)

### 2. Function at 0x50826-0x50e26 (MAJOR POLYGON FILL)
**Entry:** 0x50826  
**Name:** `draw_pattern_filled_polygon`  
**Purpose:** Rasterizes a polygon filled with a pattern using edge-walking algorithm. Handles:
- Clipping via `clip_line` (0x14470)  (PS clip operator)
- Pattern setup via `setup_pattern` (0x2dcee)
- Edge calculation via `calculate_edges` (0x1a038)
- Three fill modes based on slope (dx/dy):  (PS paint operator)
  1. Small slopes (|dx/dy| < 4): optimized inner loop with per-pixel stepping
  2. Medium slopes: uses Bresenham-like pixel stepping
  3. Large slopes: uses line stepping with edge masks
- Uses bitmask tables for left (0x5503c) and right (0x550e4) edge alignment
**Arguments:** Complex stack frame with 13+ parameters: %fp@(8,12)=x1,y1, %fp@(16,20)=x2,y2, %fp@(24,28)=pattern coordinates, %fp@(32)=edge data pointer, %fp@(36,40)=dx1,dy1, %fp@(44,48)=dx2,dy2, %fp@(52)=inversion flag (0=normal, non-zero=inverted)  
**RAM accessed:** 0x20009c4 (bytes per scanline?), 0x20009c0 (display buffer base), 0x20009d4 (maximum y coordinate), 0x20175ec (y offset), 0x2017364 (clip y minimum), 0x20175e8 (x offset)  
**Call targets:** 0x14470 (`clip_line`), 0x2dcee (`setup_pattern`), 0x1a038 (`calculate_edges`)  
**Called by:** PostScript fill operators (e.g., `fill`, `eofill` with patterns)

### 3. Function at 0x50e28-0x50e30
**Entry:** 0x50e28  
**Name:** `sync_display`  
**Purpose:** Calls 0x46334 which likely waits for vertical blank or synchronizes with display hardware. Short wrapper function.  
**Call targets:** 0x46334 (display synchronization routine)  
**Called by:** Graphics operations requiring display sync

### 4. Function at 0x50e30-0x5108e (IMAGE RECTANGLE DRAWING)
**Entry:** 0x50e30  
**Name:** `draw_image_rectangle`  
**Purpose:** Draws a rectangular image region with three modes: 0=normal, 1=inverted, -1=pattern-filled. Handles:
- Image caching (checks if image pointer is in cache range 0x2017504-0x2017570)  (PS image operator)
- Large images (>32768 pixels wide) via flag at 0x2017610  (PS image operator)
- Mask buffer ring management (0x2017600-0x201760c)
- Hardware inversion via display control register 0x06100000
- Optimized copying with unrolled loops for different widths  (font metric)
**Arguments:** %fp@(8)=image pointer, %fp@(12,16)=x,y coordinates, %fp@(20,24)=width,height, %fp@(23)=mode (0=normal, 1=inverted, -1=pattern-filled)  
**RAM accessed:** 0x2017504-0x2017570 (image cache), 0x20009d4 (max y), 0x20175ec (y offset), 0x2017364 (clip y min), 0x20009c8 (stride), 0x20009c0 (display buffer), 0x2000004 (display base?), 0x2017610 (large image flag), 0x2017600-0x201760c (mask buffer ring)  
**Hardware:** 0x06100000 (display control register for inversion)  
**Call targets:** 0x11848 (`draw_normal`), 0x119a2 (`draw_inverted`), 0x2ddec (`setup_pattern`), 0x277ac (`get_image_data`), 0x12914 (sync/coordination function)  
**Called by:** PostScript image operators (`image`, `imagemask`)

### 5. Function at 0x51090-0x512b4 (MASK RECTANGLE DRAWING)
**Entry:** 0x51090  
**Name:** `draw_mask_rectangle`  
**Purpose:** Draws a 1-bit mask (stencil) rectangle defined by runs of spans. Similar to image drawing but for monochrome masks. Handles normal and inverted modes. Mask data structure contains: word count, height, then arrays of (x_start, x_end) pairs per scanline.  
**Arguments:** %fp@(8)=mask pointer, %fp@(12,16)=x,y coordinates, %fp@(20)=height, %fp@(15)=mode (0=normal, -1=inverted)  
**RAM accessed:** 0x20175ec (y offset), 0x20009d4 (max y), 0x2017364 (clip y min), 0x20009c8 (stride), 0x20009c0 (display buffer), 0x2000004 (display base?), 0x2017600-0x201760c (mask buffer ring)  
**Hardware:** 0x06100000 (display control register for inversion)  
**Call targets:** 0x11c1c (`draw_normal_mask`), 0x2ddec (`setup_pattern`)  
**Called by:** PostScript mask operators (`imagemask` with 1-bit data)

### 6. Function at 0x512b6-0x51400 (PARTIAL - PATTERN-FILLED RECTANGLE)
**Entry:** 0x512b6  
**Name:** `draw_pattern_filled_rectangle`  
**Purpose:** Draws a rectangle filled with a pattern. Similar to polygon fill but optimized for rectangular regions. Handles normal and inverted modes. Uses clipping and pattern setup like the polygon function.  
**Arguments:** %fp@(8,12)=x1,y1, %fp@(16,20)=x2,y2, %fp@(24,28)=pattern coordinates, %fp@(35)=mode (0=normal, -1=inverted)  
**RAM accessed:** 0x20175ec (y offset), 0x20009d4 (max y), 0x2017364 (clip y min), 0x20009c8 (stride), 0x20009c0 (display buffer), 0x2000004 (display base?), 0x2017600-0x201760c (mask buffer ring)  
**Hardware:** 0x06100000 (display control register for inversion)  
**Call targets:** 0x12274 (rectangle drawing helper), 0x14470 (`clip_line`), 0x2ddec (`setup_pattern`)  
**Called by:** PostScript rectangle fill operators with patterns

1. **Function 0x50800**: Correctly identified as end of previous function, not a separate function.
2. **Function 0x50e28**: Simplified description - it's just a sync wrapper.
3. **Function 0x51090**: Clarified that mask data uses span runs, not just a bitmap.
4. **Function 0x512b6**: Corrected argument indexing (mode is at %fp@(35), not %fp@(23)).

- **Edge mask tables**: 0x5503c (left edge masks, 16 entries × 2 bytes) and 0x550e4 (right edge masks, 16 entries × 2 bytes) provide precomputed bitmasks for pixel alignment within 16-bit words.
- **Mask buffer ring**: Circular buffer at 0x2017600-0x201760c used for temporary storage during mask operations.
- **Large image handling**: Flag at 0x2017610 indicates images >32768 pixels wide, requiring special handling.
- **Pattern coordinate system**: Patterns are tiled and use modulo arithmetic for repetition.

## DATA REGIONS IN THIS RANGE:
- **0x5503c-0x5505c**: Left edge mask table (16 words)
- **0x550e4-0x55104**: Right edge mask table (16 words)

These tables contain precomputed bitmasks for aligning edges to pixel boundaries within 16-bit words, used by the polygon and rectangle fill routines.

; === CHUNK 24: 0x51400-0x52000 ===

### 1. Function at 0x51400-0x515aa (CONTINUATION)
**Entry:** 0x51400  
**Name:** `fill_span_with_pattern` (continuation)  
**Purpose:** This is a continuation of a larger pattern-filling function that started before 0x51400. It fills horizontal spans with pattern data, handling pattern alignment, edge masking, and pattern buffer ring management.  
- Uses pattern buffer ring at 0x2017600-0x201760c (0x2017604 = current pointer, 0x2017608 = start, 0x201760c = end)  (PS dict operator)
- Calculates pattern start/end masks using 16-word mask tables at 0x5053c and 0x50e4  (PS dict operator)
- Handles pattern repetition with modulo arithmetic using pattern buffer size  (register = size parameter)
- Writes pattern data to display buffer with proper edge masking for left/right edges
- Updates pattern buffer ring pointer after each span
**Args:** Continuation from earlier function - uses stack variables at fp@(-84) to fp@(28)
**RAM:** 0x20175e8 (x offset), 0x20009c8 (stride), 0x2017600-0x201760c (pattern buffer ring)
**Call targets:** None (this is a continuation)
**Called by:** Pattern filling functions (likely 0x512b6)

### 2. Function at 0x515ac-0x51816
**Entry:** 0x515ac  
**Name:** `blit_bitmap_to_display`  
**Purpose:** Copies a bitmap rectangle to the display buffer with optimized loops for different width cases. Handles bitmap cache lookup and coordinate transformation.  
1. Checks if bitmap pointer is in cache (0x2017504-0x2017570)
2. Extracts bitmap width/height from header (words at offset 2 and 4)
3. Updates max y coordinate (0x20009d4) if needed
4. Calculates destination address in display buffer using y offset and stride
5. Calls 0x52914 for hardware setup with x offset mask
6. Uses multiple optimized copy loops based on width parity (odd/even word count)
7. Handles three main cases: width odd (0x5163e), width even (0x51724), and special cases
- fp@(8): bitmap pointer  stack frame parameter
- fp@(12): x coordinate (integer)  coordinate data  (font metric data)
- fp@(16): y coordinate (integer)  coordinate data  (font metric data)
**RAM:** 0x2017504-0x2017570 (bitmap cache), 0x20009d4 (max y), 0x2017364 (y offset), 0x20009c8 (stride), 0x20009c0 (buffer base), 0x2000004 (display buffer)
**Call targets:** 0x52914 (hardware setup)
**Called by:** 0x51818, 0x51848

### 3. Function at 0x51818-0x51846
**Entry:** 0x51818  
**Name:** `blit_bitmap_inverted`  
**Purpose:** Same as blit_bitmap_to_display but with hardware inversion enabled during the copy.  
**Algorithm:** Sets inversion register (0x06100000) to 0, calls 0x515ac, then sets it back to -1 (0xFFFF).
**Args:** Same as 0x515ac: bitmap pointer, x, y
**HW:** 0x06100000 (inversion control register)
**Call targets:** 0x515ac
**Called by:** Image drawing functions that need inverted output

### 4. Function at 0x51848-0x519a0
**Entry:** 0x51848  
**Name:** `blit_large_bitmap`  
**Purpose:** Specialized bitmap blitter for bitmaps wider than 32768 pixels. Uses different logic for very large bitmaps.  
1. Checks bitmap dimensions (width at offset 2, height at offset 4)
2. If width < 32768, calls normal blit (0x515ac)
3. Otherwise, handles large bitmap with special logic
4. Checks 0x2017610 flag for large bitmap handling
5. If flag set, calls 0x13dc4 for large bitmap processing
6. Calls 0x277ac to get bitmap data pointer
7. Uses optimized copy loops similar to normal blit but with different setup
**Args:** Same as 0x515ac: bitmap pointer, x, y
**RAM:** 0x2017610 (large bitmap flag)
**Call targets:** 0x515ac, 0x13dc4, 0x277ac, 0x52914
**Called by:** 0x519a2

### 5. Function at 0x519a2-0x519d0
**Entry:** 0x519a2  
**Name:** `blit_large_bitmap_inverted`  
**Purpose:** Inverted version of large bitmap blit. Sets inversion register, calls 0x51848, then resets.  
**Args:** Same as 0x51848: bitmap pointer, x, y
**HW:** 0x06100000 (inversion control register)
**Call targets:** 0x51848
**Called by:** Image drawing functions needing inverted large bitmaps

### 6. Function at 0x519d2-0x519de
**Entry:** 0x519d2  
**Name:** `flush_display_buffer`  
**Purpose:** Calls 0x46334 to flush the display buffer to hardware.  
**Args:** None
**Call targets:** 0x46334
**Called by:** Display update functions

### 7. Function at 0x519e0-0x51b0c
**Entry:** 0x519e0  
**Name:** `fill_rectangle_with_masks`  
**Purpose:** Fills a rectangle with pattern using left/right edge masks for partial word boundaries.  
1. Converts coordinates to word boundaries (divides by 32 pixels)
2. Uses mask tables at 0x5055c (left masks) and 0x5104 (right masks)
3. Calculates destination address in display buffer
4. Handles three cases: single word (0x51a88), multiple words (0x51a54), and special edge cases
5. Uses optimized loops for filling with pattern data
- fp@(8): x1 (left)  stack frame parameter
- fp@(12): y1 (top)  stack frame parameter
- fp@(16): x2 (right)  stack frame parameter
- fp@(20): y2 (bottom)  stack frame parameter
**RAM:** 0x2017364 (y offset), 0x20009c8 (stride), 0x20009c0 (buffer base), 0x2000004 (display buffer)
**Called by:** 0x51b0e

### 8. Function at 0x51b0e-0x51b42
**Entry:** 0x51b0e  
**Name:** `fill_rectangle_with_masks_inverted`  
**Purpose:** Inverted version of fill_rectangle_with_masks. Sets inversion register, calls 0x519e0, then resets.  
**Args:** Same as 0x519e0: x1, y1, x2, y2
**HW:** 0x06100000 (inversion control register)
**Call targets:** 0x519e0
**Called by:** Rectangle filling functions needing inversion

### 9. Function at 0x51b44-0x51bea
**Entry:** 0x51b44  
**Name:** `fill_rectangle_edges_only`  
**Purpose:** Fills only the left and right edges of a rectangle (for partial word boundaries).  
1. Similar to fill_rectangle_with_masks but only fills first and last words of each row
2. Uses mask tables at 0x5055c (left) and 0x5104 (right)
3. Calculates destination address and fills only edge words
- fp@(8): y coordinate  coordinate data  (font metric data)
- fp@(12): x1 (left)  stack frame parameter
- fp@(16): x2 (right)  stack frame parameter
**RAM:** 0x2017364 (y offset), 0x20009c8 (stride), 0x20009c0 (buffer base), 0x2000004 (display buffer)
**Called by:** 0x51bec

### 10. Function at 0x51bec-0x51c1a
**Entry:** 0x51bec  
**Name:** `fill_rectangle_edges_only_inverted`  
**Purpose:** Inverted version of fill_rectangle_edges_only.  
**Args:** Same as 0x51b44: y, x1, x2
**HW:** 0x06100000 (inversion control register)
**Call targets:** 0x51b44
**Called by:** Edge filling functions needing inversion

### 11. Function at 0x51c1c-0x51cfc
**Entry:** 0x51c1c  
**Name:** `fill_polygon_scanlines`  
**Purpose:** Fills a polygon defined by scanline data structure.  
1. Reads polygon header: word count, y coordinate, then pairs of (x count, x start, x end) for each scanline
2. For each scanline, fills horizontal spans using edge masks
3. Uses mask tables at 0x5055c (left) and 0x5104 (right)
4. Handles single-word and multi-word spans
- fp@(8): polygon data pointer (structured as described)  stack frame parameter
**RAM:** 0x20175ec (y offset), 0x20175e8 (x offset), 0x20009d4 (max y), 0x20009c8 (stride), 0x20009c0 (buffer base), 0x2000004 (display buffer)
**Called by:** Polygon filling functions

### 12. Function at 0x51cfe-0x51d3c
**Entry:** 0x51cfe  
**Name:** `call_function_array`  
**Purpose:** Calls an array of functions with their arguments.  
1. Iterates through array of 12-byte entries (3 longwords each)
2. For each entry, pushes the 3 longwords as arguments and calls the function
3. Used for batched operations
- fp@(8): function array pointer  stack frame parameter
- fp@(12): count of functions to call  stack frame parameter
**RAM:** 0x2017368 (function table base)
**Call targets:** Functions from array via indirect call
**Called by:** Batched operation handlers

### 13. Function at 0x51d3e-0x51ff4 (INCOMPLETE - continues beyond 0x52000)
**Entry:** 0x51d3e  
**Name:** `draw_scaled_bitmap` (partial)  
**Purpose:** Draws a bitmap with scaling and clipping. Complex function that handles coordinate transformation, clipping, and pattern application.  
1. Converts fixed-point coordinates to integer (shifts right by 16)
2. Checks for special cases (identical source/dest, etc.)
3. Sets up clipping and transformation
4. Handles pattern filling vs. bitmap copying
5. Manages hardware inversion register
6. Complex logic continues beyond 0x52000
**Args:** Many arguments on stack (at least 8 longwords)
**RAM:** 0x20175fa, 0x20175ec, 0x20175e8, 0x20009d4, 0x2017364, 0x2017504-0x2017570 (bitmap cache), 0x2017610 (large bitmap flag), 0x2017600-0x201760c (pattern buffer)
**Call targets:** 0x14470, 0x12914, 0x13dc4, 0x277ac, 0x2ddec
**Called by:** Scaled bitmap drawing operations

1. **Function 0x519d2** was missed - it's a simple flush function.
2. **Function 0x51cfe** was missed - it's a batched function caller.
3. **Function 0x51d3e** continues beyond 0x52000 (incomplete in this chunk).
5. The polygon filler (0x51c1c) is more complex than initially described.

## DATA REGIONS REFERENCED:

1. **Mask tables:**
   - 0x5053c: Start mask table (16 words) - used in pattern filling  (PS paint operator)
   - 0x50e4: End mask table (16 words) - used in pattern filling  (PS paint operator)
   - 0x5055c: Left edge mask table (32 longwords) - used in rectangle filling  (PS paint operator)
   - 0x5104: Right edge mask table (32 longwords) - used in rectangle filling  (PS paint operator)

2. **Hardware registers:**
   - 0x06100000: Inversion control register (0 = invert, -1 = normal)

3. **RAM variables:**
   - 0x20175e8: X offset for coordinate transformation  coordinate data  (font metric data)
   - 0x20175ec: Y offset for coordinate transformation  coordinate data  (font metric data)
   - 0x20175fa: Unknown flag
   - 0x2017600-0x201760c: Pattern buffer ring management
   - 0x2017610: Large bitmap handling flag
   - 0x20009c0: Display buffer base address
   - 0x20009c8: Display buffer stride (bytes per row)
   - 0x20009d4: Maximum Y coordinate used (for buffer sizing)  coordinate data  (font metric data)

The code in this region is all valid 68020 machine code with no misidentified data sections. The functions are well-structured with proper stack frames (LINK/UNLK) and register preservation.

; === CHUNK 25: 0x52000-0x52C00 ===

### 1. Function at 0x52000 (entry: 0x52000)
**Name:** `fill_rectangle_with_pattern`
**What it does:** Fills a rectangle with a pattern, handling clipping and pattern alignment. The function processes rectangles row by row, applying pattern masks to edges and filling interiors. It uses bitwise operations to combine pattern with destination. Handles pattern state management including pattern wrap-around and edge masking.
- Stack arguments: rectangle coordinates (likely 4 coordinates at offsets 8-24), pattern info, clipping bounds  (PS clip operator)
- Uses large stack frame (-152 bytes) for local variables
- 0x20009c8 (frame buffer stride)
- 0x20009c0 (frame buffer offset)  struct field
- 0x2000004 (frame buffer base)
- 0x20175e8, 0x20175ec (coordinate system offsets)  coordinate data  (font metric data)
- 0x2017600, 0x2017604, 0x2017608, 0x201760c (pattern state: size, current pointer, start, end)  (PS dict operator)  (register = size parameter)
- 0x5503c, 0x550e4 (edge mask tables for left/right edges)
**Key branch targets:** 0x52024 (main loop), 0x52156 (skip drawing), 0x52254 (cleanup)
**Call targets:** Calls 0x277ac (likely pattern lookup), 0x12914 (cleanup routine)
**Called by:** Pattern fill operations in PostScript graphics

### 2. Function at 0x52274 (entry: 0x52274)
**Name:** `draw_line_entry`
**What it does:** Entry point for line drawing. Handles coordinate setup and calls appropriate line drawing algorithms based on line characteristics. Converts coordinates from PostScript fixed-point to pixel coordinates, applies coordinate system offsets, and handles clipping. Dispatches to specialized routines for horizontal, vertical, diagonal, and general lines.
- Stack: x1,y1,x2,y2 coordinates as words at offsets 8,12,16,20,24,28  coordinate data  (font metric data)
- 0x20175ec, 0x20175e8 (coordinate system offsets)  coordinate data  (font metric data)
- 0x20009d4 (max coordinate bound)  coordinate data  (font metric data)
**Key branch targets:** 0x522e8 (non-horizontal lines), 0x52320 (non-vertical lines), 0x5253e (general case)
**Call targets:** Calls 0x11b44 (horizontal line), 0x119e0 (vertical line)
**Called by:** PostScript line drawing operators (lineto, rlineto)

### 3. Code at 0x52338-0x5253a (within 0x52274 function)
**What it does:** Diagonal line drawing case (|dx| = |dy|). Implements Bresenham's algorithm for 45-degree lines. Handles both positive and negative slopes. Uses pattern mask tables at 0x5518c for pixel masks.
**Algorithm:** Specialized Bresenham for diagonal lines with error term calculation and pixel mask application.

### 4. Code at 0x5253e-0x52910 (within 0x52274 function)
**What it does:** General Bresenham line drawing for lines where |dx| ≠ |dy|. Handles all octants with proper error term calculations. Uses 32-bit masks for pixel operations (tables at 0x5505c and 0x55104).
**Algorithm:** Full Bresenham with error accumulation, handles both steep and shallow lines.

### 5. Function at 0x52944 (entry: 0x52944)
**Name:** `fill_rect_with_1bit_pattern`
**What it does:** Fills a rectangle with a 1-bit pattern. Processes pattern bits, expands them to word masks, and applies them to the destination buffer. Handles pattern alignment and clipping. Optimized for monochrome patterns with bitwise operations.
- Stack: destination buffer pointer, pattern pointer, rectangle dimensions, pattern info
- 0x2000004 (frame buffer base)
- 0x5503c, 0x550e4 (pattern mask tables for left/right edges)
**Key branch targets:** 0x1299c (pattern bit processing), 0x12a8a (main loop)
**Called by:** Pattern fill operations for monochrome patterns

### 6. Function at 0x52aa6 (entry: 0x52aa6)
**Name:** `transform_and_clip_coordinates`
**What it does:** Converts fixed-point coordinates to pixel coordinates with transformation, applies clipping bounds, and adjusts coordinates to fit within the display area. Handles coordinate system offsets and clipping rectangle boundaries.
- Stack: multiple coordinate pairs (likely 6 coordinates at offsets 8-28), clipping bounds at offsets 32-44  (PS clip operator)
- 0x20175e8, 0x20175ec (coordinate system offsets)  coordinate data  (font metric data)
**Key branch targets:** 0x52b44 (clipping checks), 0x52b7c (right bound check), 0x52b9a (top bound check)
**Called by:** Graphics primitives before rendering

### 7. Data at 0x52912-0x52942 (16 bytes)
**What it is:** Small code fragment or data table. Appears to be hardware control code for manipulating display registers.
**Content:** Contains instructions that write to hardware register 0x200181c and 0x6080000.
**Purpose:** Likely used for display hardware control or synchronization.

2. `transform_and_clip` at 0x52aa6 — coordinate transformation and clipping

3. **Data region at 0x52912:** This was incorrectly identified as part of the previous function. It's actually a small hardware control routine or data table.

1. **Pattern handling:** The system uses two pattern mask tables at 0x5503c and 0x550e4 for left and right edge masking respectively.

2. **Coordinate system:** Uses fixed-point coordinates with 8-bit fractional parts (as seen in the shift operations at 0x52ab2-0x52b20).

3. **Line drawing optimization:** Has specialized routines for horizontal, vertical, diagonal, and general lines for performance.

4. **Hardware acceleration:** The code at 0x52912-0x52942 shows direct hardware register manipulation for display control.

5. **Memory layout:** Frame buffer is accessed through base (0x2000004), offset (0x20009c0), and stride (0x20009c8) values.

; === CHUNK 26: 0x52C00-0x53800 ===

### 1. Function at 0x52C00 (continuation from 0x52AA6)
**Actual name:** `raster_op_complex` (continuation)
**What it does:** This is the continuation of the complex raster operation function that starts at 0x52AA6. It handles vertical scanline processing with pattern application, clipping, and hardware acceleration fallback. The function processes each scanline, applies patterns from a pattern buffer, handles edge clipping masks, and manages temporary buffers for complex operations that can't be handled directly by hardware.
**Arguments:** Already set up by caller at 0x52AA6:
- `%fp@(8)`, `%fp@(12)`: Source coordinates (x1,y1) in 16.16 fixed-point  coordinate data  (font metric data)
- `%fp@(16)`, `%fp@(20)`: Destination coordinates (x2,y2) in 16.16 fixed-point  coordinate data  (font metric data)
- `%fp@(24)`, `%fp@(28)`: Clipping bounds  stack frame parameter
- `%fp@(32)`: Pattern data structure pointer  stack frame parameter
- `%fp@(36)`: Operation mode  stack frame parameter
- `%fp@(44)`: Additional flags  stack frame parameter
- 0x20175EC: Coordinate offset (adds to device coordinates)  coordinate data  (font metric data)
- 0x20009D4: Maximum coordinate tracking (updates max y coordinate)  coordinate data  (font metric data)
- 0x2017368+offsets: Graphics state callback table (hardware acceleration)  struct field
- 0x5503C, 0x550E4: Edge mask tables for left/right clipping (16-bit masks)  (PS clip operator)
- 0x52C70: Calls clipping function at 0x14470 (computes clipped bounds)  (PS clip operator)
- 0x52F5C: Calls `fill_rect_with_pattern` at 0x52944 for simple pattern fills  (PS paint operator)
- 0x5309E: Calls memory free function at 0x4DB6C for temporary buffers
- Uses hardware acceleration callbacks at 0x2017368+0xC8 (get buffer) and +0xCC (release buffer)
1. Converts fixed-point coordinates to integer
2. Applies clipping bounds
3. For each vertical scanline:
   - Computes pattern offset based on y-coordinate  coordinate data  (font metric data)
   - Gets hardware buffer via callback
   - Applies edge masks for left/right clipping  (PS clip operator)
   - Either uses hardware acceleration or software fallback
   - Handles pattern cycling and transparency  (PS dash pattern state machine)
4. Manages temporary buffers for complex operations (>384 units wide)

### 2. Function at 0x530AA (NEW function)
**Actual name:** `raster_op_with_mask`
**What it does:** Performs raster operations with an explicit mask buffer. This handles transparency, stencil effects, and different blend modes for masked rendering operations. It supports both simple masks (copied to RAM) and complex masks (processed with pattern application).
- `%fp@(8)`, `%fp@(12)`: Source coordinates (x1,y1) in 16.16 fixed-point  coordinate data  (font metric data)
- `%fp@(16)`, `%fp@(20)`: Destination coordinates (x2,y2) in 16.16 fixed-point  coordinate data  (font metric data)
- `%fp@(24)`, `%fp@(28)`: Clipping bounds  stack frame parameter
- `%fp@(32)`: Mask buffer structure pointer  stack frame parameter
- `%fp@(36)`: Pattern data structure  stack frame parameter
- `%fp@(44)`: Operation mode  stack frame parameter
- `%fp@(52)`: Transparency flag (0=opaque, non-zero=transparent)  stack frame parameter
- 0x2001820-0x2001826: Mask buffer copy area in RAM (6 bytes for simple masks)
- 0x20175E8, 0x20175EC: Coordinate system offsets  struct field
- 0x2017600, 0x2017604, 0x2017608, 0x201760C: Pattern state variables (current position, start, end)  (PS dict operator)
- 0x5503C, 0x550E4, 0x5518C: Mask tables for edge handling (left, right, center)
- 0x530C0-0x530EC: Copies simple mask data to RAM buffer at 0x2001820 (if mask is simple, indicated by -1 in mask structure)
- 0x5311C: Calls `raster_op_complex` at 0x52AA6 for simple mask case
- 0x53182: Calls clipping function at 0x14470  (PS clip operator)
- 0x53236: Calls pattern setup function at 0x2DDEC (sets up pattern cycling)  (PS dash pattern state machine)
- 0x533E0: Calls graphics state callback for buffer allocation  (PS font cache)
- 0x53434: Calls coordinate transformation function at 0x1A038  coordinate data  (font metric data)
1. Checks if mask is simple (special marker -1 in mask structure)
2. If simple: copies mask to RAM and calls `raster_op_complex`
3. If complex:
   - Applies clipping  (PS clip operator)
   - Sets up pattern cycling based on y-coordinate  coordinate data  (PS dash pattern state machine)
   - For each scanline:
     - Gets hardware buffer
     - Computes mask application with edge clipping  (PS clip operator)
     - [PS raster] Applies pattern with transparency handling (halftone screen / PS image operator)
     - Uses pattern cycling state machine  (PS dash pattern state machine)

### 3. Data Region at 0x5369E-0x53800
**What it is:** Character width/advance table for a built-in font (354 bytes)
**Format:** Table of character metrics, likely for Courier or similar monospaced font used in system messages
- Bytes represent character widths or advance values in font units  (font metric)
- Pattern shows repeating values for character groups, indicating monospaced or near-monospaced font:  (PS text operator)
  - 0x43 (67) = 'C' width  (font metric)
  - 0x6F (111) = 'o' width  (font metric)
  - 0x70 (112) = 'p' width  (font metric)
  - 0x79 (121) = 'y' width  (font metric)
  - 0x72 (114) = 'r' width  (font metric)
  - 0x69 (105) = 'i' width  (font metric)
  - 0x67 (103) = 'g' width  (font metric)
  - 0x68 (104) = 'h' width  (font metric)
  - 0x74 (116) = 't' width  (font metric)
  - 0x20 (32) = space width  (font metric)
  - 0x28 (40) = '(' width  (font metric)
  - 0x29 (41) = ')' width  (font metric)
**Size:** 354 bytes (0x5369E to 0x53800 = 354 bytes)
**Purpose:** Used by the system for rendering text in error messages, status displays, or the built-in monitor/debug interface.

1. **Function boundary confirmed:** The code at 0x52C00 is indeed a continuation of the function at 0x52AA6, not a separate function. The function ends at 0x530A8.

2. **Mask handling clarified:** The function at 0x530AA handles two distinct cases:
   - Simple masks (indicated by -1 in mask structure offset 8): copied to fixed RAM location  struct field
   - Complex masks: processed inline with pattern application

3. **Pattern state machine:** The code references pattern state variables at 0x2017600-0x201760C which track:
   - Current pattern position  (PS dash pattern state machine)
   - Pattern start and end pointers  (PS dict operator)
   - Pattern cycling for tiled fills  (PS paint operator)

4. **Hardware acceleration:** Both functions use callbacks from the graphics state table at 0x2017368:
   - Offset 0xC8: Get hardware buffer  struct field
   - Offset 0xCC: Release hardware buffer  struct field
   This allows fallback to software rendering when hardware is busy or unavailable.

5. **Edge mask tables:** Three tables at 0x5503C, 0x550E4, and 0x5518C provide 16-bit masks for:
   - Left edge clipping (bits to preserve on left side)  (PS clip operator)
   - Right edge clipping (bits to preserve on right side)  (PS clip operator)
   - Center masks (for interior pixels)

1. **Rendering pipeline:** The system uses a hybrid hardware/software rendering approach with callbacks for hardware acceleration.

2. **Mask complexity:** Masks can be either simple (static) or complex (pattern-based), with different optimization paths.

3. **Coordinate system:** Uses 16.16 fixed-point coordinates internally, converted to integer for pixel operations.

4. **Pattern tiling:** Supports pattern cycling with state tracking for efficient tiled fills.

5. **Memory management:** Allocates temporary buffers for wide operations (>384 units) to avoid stack overflow.

The analysis shows a sophisticated raster graphics system with hardware acceleration, pattern support, and efficient clipping - appropriate for a high-end PostScript RIP.

; === CHUNK 27: 0x53800-0x54400 ===

## REFINED ANALYSIS OF 0x53800-0x54400

### 1. Function at 0x53800: `decode_bitmap_run`
**Entry:** 0x53800  
**Purpose:** Decodes run-length encoded bitmap data using two alternating 16-bit mask tables. Processes input mask words to determine runs of 0s and 1s, accumulating bits into 16-bit output words.  
- Maintains two mask table pointers: primary at 0x551ac, secondary at 0x5518c
- For each input mask word, ANDs with current mask table word, tests if result matches current run state (0 or 1)
- When state changes, writes accumulated word to output buffer
- Maximum output buffer size is 64 words (128 bytes)  (register = size parameter)
- A6@(8): output buffer pointer (word-aligned)
- A6@(12): input data pointer (word-aligned, contains run-length mask words)
- A6@(16): count of mask words to process
**Return:** D0 = number of words decoded, or -1 on overflow  
**Call targets:** None (leaf function)  
**Called from:** 0x539d2 (within `encode_glyph_outline`)

### 2. Function at 0x538c8: `encode_glyph_outline`
**Entry:** 0x538c8  
**Purpose:** Compresses glyph outline coordinates using Type 1 charstring-like encoding with four encoding schemes based on delta magnitude.  
- If A6@(12)=0: treats A6@(8) as glyph header, extracts outline data pointer from offset 6  struct field
- If A6@(12)≠0: treats A6@(12) as coordinate data pointer  (font metric data)
- Encodes coordinate deltas using one of four schemes:  coordinate data  (font metric data)
  1. 2-bit encoding: deltas in range [-2,-1,0,1,2] (code 0)
  2. 4-bit encoding: deltas in range [-8..-3, 3..7] (code 1)
  3. Variable-length: deltas outside ±127, encoded as 0x80 + multiple 127-byte chunks (code 2)
  4. Full coordinate: large deltas, encoded as 16-bit words (code 3)
- Uses jump table at 0x53afe with 4 entries for the encoding schemes
- A6@(8): glyph header pointer (if A6@(12)=0) or coordinate data pointer  (font metric data)
- A6@(12): coordinate data pointer (if A6@(8)=glyph header) or 0  (font metric data)
- A6@(16): output buffer pointer
- A6@(20): width parameter (used as base for relative encoding)  (font metric)
- A6@(24): height parameter  (font metric)
**Return:** D0 = compressed size in bytes, or -1 on error  
**RAM accessed:** Extensive local stack usage (612 bytes)  
**Call targets:** 0x53800 (`decode_bitmap_run`) at 0x539d2  
**Called from:** 0x53d7a (`encode_glyph_absolute`), 0x53d9c (`encode_glyph_relative`)

### 3. Function at 0x53d7a: `encode_glyph_absolute`
**Entry:** 0x53d7a  
**Purpose:** Wrapper for `encode_glyph_outline` that passes null as 4th argument, indicating absolute coordinate encoding.  
- A6@(8): glyph header pointer
- A6@(12): coordinate data pointer  (font metric data)
- A6@(16): output buffer pointer
- A6@(20): width parameter  (font metric)
- A6@(24): height parameter  (font metric)
**Return:** D0 = compressed size  
**Call targets:** 0x538c8 (`encode_glyph_outline`)

### 4. Function at 0x53d9c: `encode_glyph_relative`
**Entry:** 0x53d9c  
**Purpose:** Wrapper that extracts glyph width from header (offset 4) and passes it as the 4th argument to `encode_glyph_outline` for relative coordinate encoding.  
- A6@(8): glyph header pointer
- A6@(12): output buffer pointer  
- A6@(16): coordinate data pointer  (font metric data)
- A6@(20): height parameter  (font metric)
**Return:** D0 = compressed size  
**RAM accessed:** Reads glyph header at offset 4  
**Call targets:** 0x538c8 (`encode_glyph_outline`)

### 5. Function at 0x53dc4: `render_glyph_to_bitmap`
**Entry:** 0x53dc4  
**Purpose:** Renders a glyph outline to a bitmap using scanline conversion. Sets up rendering context in global structures, computes pointer to outline data, and calls scanline renderer in a loop.  
1. Validates glyph header (checks offset 4 for -32768)
2. Extracts outline data pointer from header offset 6
3. Stores outline pointer in global variable 0x20177a4
4. Computes scanline pointer offset based on bitmap width
5. Stores scanline pointer in global variable 0x2017618
6. Stores glyph height in global variable 0x201761c
7. Clears scanline counter at 0x2017614
8. Loops through each scanline, calling renderer at 0x277ac
- A6@(8): glyph header pointer
- A6@(12): bitmap width in pixels  (font metric)
- 0x20177a4: outline data pointer
- 0x2017618: scanline pointer
- 0x201761c: glyph height  (font metric)
- 0x2017614: scanline counter
**Call targets:** 0x277ac (scanline renderer) at 0x53e58  
**Called from:** Unknown (likely font rendering subsystem)

### 6. Data Region at 0x53e6e-0x54400: Encoding Tables
**Address:** 0x53e6e-0x54400  
**Format:** Multiple encoding/decoding tables for glyph compression/decompression:
- 0x53e6e-0x54070: 514-byte table (possibly delta encoding lookup)
- 0x54070-0x543f0: Complex table structure with repeating patterns of 0xFE, 0xFF, 0x00, 0x01 values
- 0x543f0-0x54400: Final table segment

2. Function at 0x53dc4 takes 2 arguments (glyph header and bitmap width)
3. The data region starting at 0x53e6e is much larger and more complex than previously described.

- The encoding scheme in `encode_glyph_outline` closely matches Type 1 charstring encoding with its 2-bit, 4-bit, variable-length, and full coordinate modes.  coordinate data  (font metric data)
- The jump table at 0x53afe has 4 entries corresponding to the 4 encoding schemes.
- The global variables at 0x2017614-0x201761c form a glyph rendering context used by the scanline renderer.  (PS dict operator)
- The large data tables suggest sophisticated encoding/decoding algorithms for efficient glyph storage.

; === CHUNK 28: 0x54400-0x55000 ===

### 1. Data table at 0x54400-0x5446F
**Address:** 0x54400-0x5446F  
**Size:** 112 bytes (28 longwords)  
**Format:** Lookup table of 16-bit values, likely for line clipping or coordinate transformation  
**Content:** Pattern appears to be pairs of values, possibly representing coordinate transformations or clipping codes  
**Note:** This is data, not code

### 1. Function at 0x54470
**Entry:** 0x54470  
**Name:** `clip_line_cohen_sutherland`
**Purpose:** Implements Cohen-Sutherland line clipping algorithm. Computes clipping codes for line endpoints, determines if line is completely inside, completely outside, or needs clipping. Calculates intersection points when clipping is required.  
- `fp@(8)`: x1  stack frame parameter
- `fp@(12)`: y1  stack frame parameter
- `fp@(16)`: x2  stack frame parameter
- `fp@(20)`: y2  stack frame parameter
- `fp@(24)`: clip rectangle min x  (PS clip operator)
- `fp@(28)`: clip rectangle min y  (PS clip operator)
- `fp@(32)`: clip rectangle max x  (PS clip operator)
- `fp@(36)`: clip rectangle max y  (PS clip operator)
- `fp@(40)`: pointer to delta x output  stack frame parameter
- `fp@(44)`: pointer to delta y output  stack frame parameter
- `fp@(48)`: pointer to accept flag  stack frame parameter
- `fp@(52)`: pointer to reject flag  stack frame parameter
**Call targets:** 0x4c07e (divide), 0x4bfe0 (multiply)  
**Called from:** Unknown, likely graphics rendering code

### 2. Function at 0x54582
**Entry:** 0x54582  
**Name:** `reset_font_cache`
**Purpose:** Resets the font cache by calling a function pointer from the font manager structure and clearing a cache counter. Part of font management system.  
- 0x2017368 (font manager pointer)
- 0x20009d4 (font cache counter)  
**Call targets:** Function pointer at offset 0xEC in font manager structure  
**Called from:** 0x54b62, 0x54c04

### 3. Function at 0x5459c
**Entry:** 0x5459c  
**Name:** `get_font_bbox`
**Purpose:** Retrieves font bounding box from font manager structure and pushes it onto PostScript stack.  
**RAM accessed:** 0x2017368 (font manager pointer)  
**Call targets:** 0x31334 (PS stack push)  
**Called from:** Unknown, likely PS operator implementation

### 4. Function at 0x545ba
**Entry:** 0x545ba  
**Name:** `calculate_font_cache_size`
**Purpose:** Calculates total font cache size in bytes (glyph count × bytes per glyph) and pushes result to PostScript stack.  
- 0x20009d4 (glyph count)
- 0x20009c8 (bytes per glyph)
- 0x20009c0 (cache base pointer)  
**Call targets:** 0x4de50 (PS stack operation)  
**Called from:** Unknown, likely PS operator

### 5. Function at 0x545e0
**Entry:** 0x545e0  
**Name:** `get_font_glyph_count`
**Purpose:** Returns the current font's glyph count from global variable.  
**Return:** D0 = glyph count from 0x20009cc  
**RAM accessed:** 0x20009cc  
### 6. Function at 0x545ee
**Entry:** 0x545ee  
**Name:** `copy_font_matrix`
**Purpose:** Copies font transformation matrix (6 values, 24 bytes) from font manager to destination buffer.  
**Arguments:** A1 = destination buffer pointer  
**RAM accessed:** 0x2017368 (font manager pointer)  
### 7. Function at 0x5460e
**Entry:** 0x5460e  
**Name:** `copy_font_bbox`
**Purpose:** Copies font bounding box (4 values, 16 bytes) from font manager to destination buffer.  
**Arguments:** A1 = destination buffer pointer  
**RAM accessed:** 0x2017368 (font manager pointer)  
### 8. Function at 0x5462e
**Entry:** 0x5462e  
**Name:** `pop_font_manager`
**Purpose:** Pops the current font manager from a stack, decrementing a counter and updating global font manager pointer. If counter reaches zero, sets font manager pointer to NULL.  
- 0x20009e8 (font manager stack counter)
- 0x2017368 (font manager pointer)
- 0x20009c0 (cache base pointer)
- 0x20009c4 (bytes per glyph / 2)
- 0x20009c8 (bytes per glyph)
- 0x20009d0 (glyph size in bytes)  (register = size parameter)
- 0x20009cc (glyph count)
- 0x20009d4 (cached glyph count)
- 0x2017364 (unknown font-related pointer)  
**Called from:** 0x546c2, 0x54b80

### 9. Function at 0x546c2
**Entry:** 0x546c2  
**Name:** `cleanup_font_manager`
**Purpose:** Pops font manager and calls cleanup function if font manager exists.  
**RAM accessed:** 0x2017368 (font manager pointer)  
**Call targets:** 0x5462e (pop_font_manager), function pointer at offset 0xA8 in font manager  
### 10. Function at 0x546e2
**Entry:** 0x546e2  
**Name:** `null_function`
**Purpose:** Empty function that does nothing (just returns).  
### 11. Function at 0x546ea
**Entry:** 0x546ea  
**Name:** `trigger_error`
**Purpose:** Triggers a PostScript error by calling error handler.  
**Call targets:** 0x46382 (error handler)  
### 12. Function at 0x546f8
**Entry:** 0x546f8  
**Name:** `init_font_manager_structure`
**Purpose:** Initializes a font manager structure with default values, copying template data from global tables.  
**Arguments:** A0 = pointer to font manager structure  
- 0x20018d0 (font template data pointer)
- 0x20018d4 (additional template data pointer)
- 0x2017364 (unknown font-related pointer)  
**Called from:** 0x54816, 0x54d40

### 13. Function at 0x5474c
**Entry:** 0x5474c  
**Name:** `push_font_manager`
**Purpose:** Pushes a new font manager onto stack, updating counters and initializing structure with glyph count and bytes per glyph.  
- `fp@(8)`: bytes per glyph  stack frame parameter
- `fp@(12)`: glyph count  stack frame parameter
- 0x2017368 (font manager pointer)
- 0x20009c0 (cache base pointer)
- 0x20009d4 (cached glyph count)
- 0x2017364 (unknown font-related pointer)
- 0x20009e8 (font manager stack counter)
- 0x20009cc (glyph count)
- 0x20009c8 (bytes per glyph)
- 0x20009c4 (bytes per glyph / 2)
- 0x20009d0 (glyph size in bytes)  (register = size parameter)
**Call targets:** 0x89a10 (malloc or allocation function)  
**Called from:** 0x54816, 0x54d40

### 14. Function at 0x54816
**Entry:** 0x54816  
**Name:** `create_font_manager`
**Purpose:** Creates a new font manager with specified parameters, initializes structure, and sets up font cache.  
- 0x20009e8 (font manager stack counter)
- 0x2017368 (font manager pointer)
- 0x20009d0 (glyph size in bytes)  (register = size parameter)
- 0x20018d0 (font template data pointer)
- 0x20018d4 (additional template data pointer)  
- 0x1a422 (unknown)
- 0x46382 (error handler)
- 0x365f8 (unknown)
- 0x3b626 (unknown, called twice)
- 0x19b4e (unknown)
- 0x5474c (push_font_manager)
- 0x89a10 (malloc or allocation function)  (PS font cache)
- 0x546f8 (init_font_manager_structure)  
### 15. Function at 0x548e0
**Entry:** 0x548e0  
**Name:** `update_font_metrics`
**Purpose:** Updates font metrics by calling a function with font manager's metrics data.  
**RAM accessed:** 0x2017368 (font manager pointer)  
**Call targets:** 0x16474 (font metrics update function)  
**Called from:** 0x54d40

### 16. Function at 0x548fc
**Entry:** 0x548fc  
**Name:** `ensure_font_cache_ready`
**Purpose:** Ensures font cache is ready for operations, managing a linked list of pending operations.  
- 0x20018cc (font cache control structure)
- 0x20175e8 (linked list head)  (data structure manipulation)
- 0x20175ec (linked list tail)  (data structure manipulation)
- 0x20018d0 (font template data pointer)  
**Call targets:** Function pointer at offset 0x28 in font template structure  
**Called from:** Many font operation functions (0x54980, 0x549b4, 0x54a28, 0x54a4a, 0x54a92, 0x54ae2, 0x54b2e)

### 17. Function at 0x54980
**Entry:** 0x54980  
**Name:** `font_operation_6_param`
**Purpose:** Performs a 6-parameter font operation after ensuring cache is ready.  
**Arguments:** 6 parameters on stack  
**RAM accessed:** 0x20018d0 (font template data pointer)  
**Call targets:** 0x548fc (ensure_font_cache_ready), function pointer at offset 0x0C in font template structure  
### 18. Function at 0x549b4
**Entry:** 0x549b4  
**Name:** `font_operation_3_param`
**Purpose:** Performs a 3-parameter font operation after ensuring cache is ready.  
**Arguments:** 3 parameters on stack  
**RAM accessed:** 0x20018d0 (font template data pointer)  
**Call targets:** 0x548fc (ensure_font_cache_ready), function pointer at offset 0x20 in font template structure  
### 19. Function at 0x549dc
**Entry:** 0x549dc  
**Name:** `queue_font_operation`
**Purpose:** Queues a font operation for later execution if cache is busy, otherwise executes immediately.  
**Arguments:** `fp@(8)`: operation data pointer  
- 0x20018cc (font cache control structure)
- 0x20175e8 (linked list head)  (data structure manipulation)
- 0x20175ec (linked list tail)  (data structure manipulation)
- 0x20018d0 (font template data pointer)  
**Call targets:** Function pointer at offset 0x28 in font template structure  
### 20. Function at 0x54a28
**Entry:** 0x54a28  
**Name:** `flush_font_cache_if_needed`
**Purpose:** Flushes font cache if there are pending operations.  
**RAM accessed:** 0x20018cc (font cache control structure)  
**Call targets:** 0x548fc (ensure_font_cache_ready)  
### 21. Function at 0x54a4a
**Entry:** 0x54a4a  
**Name:** `font_operation_10_param`
**Purpose:** Performs a 10-parameter font operation after ensuring cache is ready.  
**Arguments:** 10 parameters on stack  
**RAM accessed:** 0x20018d0 (font template data pointer)  
**Call targets:** 0x548fc (ensure_font_cache_ready), function pointer at offset 0x18 in font template structure  
### 22. Function at 0x54a92
**Entry:** 0x54a92  
**Name:** `font_operation_12_param`
**Purpose:** Performs a 12-parameter font operation after ensuring cache is ready.  
**Arguments:** 12 parameters on stack  
**RAM accessed:** 0x20018d0 (font template data pointer)  
**Call targets:** 0x548fc (ensure_font_cache_ready), function pointer at offset 0x14 in font template structure  
### 23. Function at 0x54ae2
**Entry:** 0x54ae2  
**Name:** `font_operation_11_param`
**Purpose:** Performs an 11-parameter font operation after ensuring cache is ready.  
**Arguments:** 11 parameters on stack  
**RAM accessed:** 0x20018d0 (font template data pointer)  
**Call targets:** 0x548fc (ensure_font_cache_ready), function pointer at offset 0x10 in font template structure  
### 24. Function at 0x54b2e
**Entry:** 0x54b2e  
**Name:** `font_operation_6_param_alt`
**Purpose:** Performs an alternative 6-parameter font operation after ensuring cache is ready.  
**Arguments:** 6 parameters on stack  
**RAM accessed:** 0x20018d0 (font template data pointer)  
**Call targets:** 0x548fc (ensure_font_cache_ready), function pointer at offset 0x3C in font template structure  
### 25. Function at 0x54b62
**Entry:** 0x54b62  
**Name:** `reset_font_system`
**Purpose:** Resets the entire font system, clearing cache and control structures.  
- 0x20018cc (font cache control structure)
- 0x20009d4 (font cache counter)  
**Call targets:** 0x54582 (reset_font_cache)  
**Called from:** 0x54d40

### 26. Function at 0x54b80
**Entry:** 0x54b80  
**Name:** `process_pending_font_operation`
**Purpose:** Processes a pending font operation from the queue, handling glyph caching and memory allocation.  
- 0x20018cc (font cache control structure)
- 0x2017354 (font dictionary hash table)
- 0x20009cc (glyph count)
- 0x20009c8 (bytes per glyph)
- 0x20009c0 (cache base pointer)
- 0x20009d4 (cached glyph count)
- 0x20175e8 (linked list head)  (data structure manipulation)
- 0x20175ec (linked list tail)  (data structure manipulation)
- 0x20018d0 (font template data pointer)  
- 0x13d9c (glyph caching function)
- 0x54582 (reset_font_cache)
- Function pointer at offset 0x28 in font template structure  struct field
- 0x5462e (pop_font_manager)  
### 27. Function at 0x54d36
**Entry:** 0x54d36  
**Name:** `font_dummy_return_zero`
**Purpose:** Dummy function that always returns zero.  
**Return:** D0 = 0  
### 28. Function at 0x54d40
**Entry:** 0x54d40  
**Name:** `setup_font_from_resource`
**Purpose:** Sets up a font from a resource structure, initializing font manager and cache.  
**Arguments:** `fp@(8)`: font resource pointer  
- 0x20009e8 (font manager stack counter)
- 0x2017464 (global font state structure)
- 0x20008f8 (current color space)
- 0x20018cc (font cache control structure)
- 0x20018d0 (font template data pointer)
- 0x20018d4 (additional template data pointer)
- 0x2017368 (font manager pointer)
- 0x20009c0 (cache base pointer)
- 0x20009cc (glyph count)  
- 0x46382 (error handler)
- 0x46334 (unknown error function)
- 0x5474c (push_font_manager)
- 0x89a10 (malloc or allocation function)  (PS font cache)
- 0x89938 (floating point conversion)
- 0x1522c (font matrix initialization)
- 0x546f8 (init_font_manager_structure)
- 0x54b62 (reset_font_system)
- 0x548e0 (update_font_metrics)  
### 29. Function at 0x54f86
**Entry:** 0x54f86  
**Name:** `set_font_manager_callback`
**Purpose:** Sets a callback function pointer in the font manager structure based on index.  
- `fp@(8)`: callback index (0-3)  stack frame parameter
- `fp@(12)`: callback function pointer  stack frame parameter
**RAM accessed:** 0x2017368 (font manager pointer)  
**Call targets:** 0x46334 (error handler for invalid index)  
### 30. Function at 0x54fe6
**Entry:** 0x54fe6  
**Name:** `set_font_template_pointers`
**Purpose:** Sets global font template data pointers for font system initialization.  
- `fp@(8)`: primary template data pointer  stack frame parameter
- `fp@(12)`: secondary template data pointer  stack frame parameter
- 0x20018d0 (font template data pointer)
- 0x20018d4 (additional template data pointer)  
1. **Function at 0x5462e** was incorrectly described as simple counter decrement. It's actually a full font manager stack pop operation that updates multiple global variables.

2. **Function at 0x54816** is more complex than previously described - it creates a complete font manager with initialization from global state.

3. **Function at 0x54b80** is a major font operation processor that handles pending operations, glyph caching, and memory management.

4. **Function at 0x54d40** is a comprehensive font setup function that initializes a font from a resource structure.

5. Font operation functions at 0x54980-0x54b2e handle various parameter counts

6. **The data table at 0x54400** is confirmed as data, not code.

This region contains the core font management system for the PostScript interpreter, including:
- Font manager stack management (push/pop)
- Font cache initialization and reset
- Font operation queuing and processing
- Glyph caching with memory allocation  (PS font cache)
- Font resource setup and initialization
- Multiple callback mechanisms for font operations

The font system uses a sophisticated caching mechanism with pending operation queues and template-based initialization.

; === CHUNK 29: 0x55000-0x55C00 ===

### DATA TABLES (0x55032-0x5522A):
**Address: 0x55032-0x5522A** - Bitmask tables for raster operations
- These are indeed lookup tables for bit manipulation:
  - 0x55032-0x5505A: 16-bit masks (0x7FFF, 0x3FFF, 0x1FFF, etc.)
  - 0x5505A-0x5509C: 32-bit masks with alternating patterns
  - 0x5509C-0x550DC: Progressive bit fills (0x0080C0E0...)  (PS paint operator)
  - 0x550DC-0x55146: Various bit patterns for raster operations
  - 0x55184-0x5522A: More complex bit patterns (0x80402010, etc.)

### FUNCTIONS:

#### 1. Function at 0x55000: `check_and_set_rendering_flags`
**Entry:** 0x55000  
**Purpose:** Checks a value in D0 against 0 and 1, sets various system flags based on the result. Sets hardware/software rendering mode flags at 0x2017368, 0x20009E8, and 0x2017610.
**Arguments:** D0 contains comparison value
**RAM access:** 0x2017368, 0x20009E8, 0x20018CC, 0x2017610
**Key:** This is actually the start of the code region, not data as previously thought.

#### 2. Function at 0x5522C: `copy_current_matrix_to_buffer`
**Entry:** 0x5522C  
**Purpose:** Copies 6 longwords (24 bytes) from the current transformation matrix at 0x2017464 to a destination buffer. This is the current transformation matrix (CTM) copy operation.
**Arguments:** A1 points to destination buffer (fp@8)
**RAM access:** 0x2017464 (global matrix pointer)
**Algorithm:** Simple loop copying 6 longwords using DBF.

#### 3. Function at 0x55246: `save_current_matrix_to_stack`
**Entry:** 0x55246  
**Purpose:** Saves current transformation matrix to local stack frame, then calls matrix composition function. Used for matrix stack operations like gsave.
**Calls:** 0x3BA8E (get current matrix), 0x19B70 (matrix composition)
**Stack frame:** -8 bytes for local matrix storage

#### 4. Function at 0x5526C: `transform_point_with_current_matrix`
**Entry:** 0x5526C  
**Purpose:** Transforms a point using the current transformation matrix. Calls through a function pointer at offset 0xA0 in the global graphics state structure.
**Arguments:** Pointer to point coordinates at fp@8
**Returns:** Transformed point (via indirect function call)
**RAM access:** 0x2017464, accesses function pointer at +0xA0
**Key:** Indirect call through graphics state dispatch table.

#### 5. Function at 0x55288: `compose_and_save_matrix`
**Entry:** 0x55288  
**Purpose:** Gets current matrix, transforms it with another matrix, saves result. Used for matrix concatenation operations.
**Calls:** 0x3BA8E (get current), 0x5526C (transform), 0x19B70 (compose)
**Stack frame:** -32 bytes for matrix storage

#### 6. Function at 0x552B4: `set_current_matrix_from_source`
**Entry:** 0x552B4  
**Purpose:** Sets current transformation matrix from source pointer, clears cache fields at offsets 0x18 (determinant cache) and 0x7C (inverse cache).
**Arguments:** Source matrix pointer at fp@8
**RAM access:** 0x2017464
**Key:** Clears cached values to force recomputation.

#### 7. Function at 0x552E2: `set_identity_matrix`
**Entry:** 0x552E2  
**Purpose:** Creates identity matrix and sets it as current transformation matrix.
**Calls:** 0x19B4E (create identity), 0x552B4 (set as current)

#### 8. Function at 0x552FE: `copy_matrix_to_fixed_buffer`
**Entry:** 0x552FE  
**Purpose:** Copies 2 longwords (8 bytes) from offset 0x24 in current matrix to fixed buffer at 0x2001940. Likely extracts translation components (tx, ty) from CTM.
**Returns:** D0 contains pointer to destination buffer (0x2001940)
**RAM access:** 0x2017464, 0x2001940

#### 9. Function at 0x55320: `process_matrix_translation`
**Entry:** 0x55320  
**Purpose:** Gets pointer to translation components (offset 0x24 in CTM) and calls function at 0x365AA to process them.
**Calls:** 0x365AA (process translation)
**RAM access:** 0x2017464

#### 10. Function at 0x5533C: `get_matrix_determinant`
**Entry:** 0x5533C  
**Purpose:** Returns cached determinant value from offset 0x18 in current transformation matrix.
**Returns:** D0 contains determinant value
**RAM access:** 0x2017464

#### 11. Function at 0x5534E: `compute_and_cache_determinant`
**Entry:** 0x5534E  
**Purpose:** Computes determinant of current matrix using function at 0x8DE4, caches result at offset 0x18 in matrix structure.
**Calls:** 0x8DE4 (determinant calculation)
**RAM access:** 0x2017464

#### 12. Function at 0x5537E: `clear_determinant_cache_if_matches`
**Entry:** 0x5537E  
**Purpose:** Iterates through matrix structures starting at 0x2020C08, clears determinant cache (offset 0x18) if it matches the provided value. Used to invalidate cached determinants.
**Arguments:** Value to match at fp@8
**RAM access:** 0x2020C08, 0x2017464
**Algorithm:** Iterates through linked list of matrix structures, each 0xA6 (166) bytes apart.

#### 13. Function at 0x553B4: `set_matrix_with_inverse_clear`
**Entry:** 0x553B4  
**Purpose:** Sets current matrix from source, clears both determinant and inverse caches. More comprehensive version of set_current_matrix_from_source.
**Arguments:** Source matrix pointer at fp@8
**Calls:** 0x191B8 (matrix set operation)
**RAM access:** 0x2017464

#### 14. Function at 0x553EA: `set_identity_matrix_with_clear`
**Entry:** 0x553EA  
**Purpose:** Creates identity matrix and sets it as current with cache clearing.
**Calls:** 0x19B4E (create identity), 0x553B4 (set with clear)

#### 15. Function at 0x55406: `scale_matrix_with_cache_preserve`
**Entry:** 0x55406  
**Purpose:** Scales current matrix while preserving determinant and inverse caches. Saves original cache values, performs scaling, restores caches.
**Arguments:** Scale factors at fp@8 and fp@12
**Calls:** 0x1901A (matrix scaling), 0x553B4 (set with clear)
**Stack frame:** -32 bytes for matrix and cache storage

#### 16. Function at 0x5545E: `rotate_matrix_with_cache_preserve`
**Entry:** 0x5545E  
**Purpose:** Rotates current matrix while preserving caches. Similar to scale function but for rotation.
**Arguments:** Rotation parameters at fp@8 and fp@12
**Calls:** 0x1905C (matrix rotation), 0x553B4 (set with clear)

#### 17. Function at 0x55486: `translate_matrix_with_inverse_preserve`
**Entry:** 0x55486  
**Purpose:** Translates current matrix while preserving inverse cache only (not determinant).
**Arguments:** Translation parameters at fp@8
**Calls:** 0x1909C (matrix translation), 0x553B4 (set with clear)
**Stack frame:** -28 bytes for matrix and cache storage

#### 18. Function at 0x554C0: `concat_two_matrices`
**Entry:** 0x554C0  
**Purpose:** Concatenates two matrices: first calls 0x19EAE to combine matrices, then calls 0x22F26 for additional processing.
**Arguments:** Two matrix pointers at fp@8 and fp@28, plus additional parameters
**Calls:** 0x19EAE (matrix concatenation), 0x22F26 (additional processing)

#### 19. Function at 0x55502: `concat_matrix_with_current`
**Entry:** 0x55502  
**Purpose:** Concatenates provided matrix with current transformation matrix.
**Arguments:** Source matrix pointer at fp@8, additional parameters at fp@12 and fp@16
**Calls:** 0x19DD8 (matrix concatenation with current)

#### 20. Function at 0x55526: `concat_matrix_with_current_alt`
**Entry:** 0x55526  
**Purpose:** Alternative matrix concatenation function using different algorithm.
**Arguments:** Similar to 0x55502
**Calls:** 0x19EAE (matrix concatenation)

#### 21. Function at 0x5554A: `concat_matrix_with_current_special`
**Entry:** 0x5554A  
**Purpose:** Specialized matrix concatenation for specific transformation types.
**Arguments:** Similar to previous functions
**Calls:** 0x19F60 (specialized concatenation)

#### 22. Function at 0x5556E: `concat_matrix_with_current_final`
**Entry:** 0x5556E  
**Purpose:** Final matrix concatenation variant.
**Arguments:** Similar to previous functions
**Calls:** 0x19FC0 (final concatenation)

#### 23. Function at 0x55592: `update_clip_region_if_needed`
**Entry:** 0x55592  
**Purpose:** Checks if clip region needs updating (word at offset 0x2C in graphics state), updates if necessary by calling 0x4639E, then processes clip region transformation.
**Calls:** 0x4639E (update clip), 0x5554A (matrix concat), 0x3BDE2 (clip processing)
**RAM access:** 0x2017464

#### 24. Function at 0x555D0: `transform_and_clear_caches`
**Entry:** 0x555D0  
**Purpose:** Transforms current matrix using function at 0x5526C, then clears determinant and inverse caches.
**Calls:** 0x5526C (transform point), clears caches at offsets 0x18 and 0x7C

#### 25. Function at 0x555F8: `set_matrix_components_from_fixed_point`
**Entry:** 0x555F8  
**Purpose:** Sets matrix components from fixed-point values. Converts multiple fixed-point pairs to floating point, then sets them into matrix structure at offset 0x44.
**Arguments:** 6 fixed-point pairs (12 parameters total)
**Calls:** 0x899C8 (fixed to float), 0x1AD74 (set matrix component), 0x1AE48 (set matrix component alt), 0x1BE24 (finalize matrix)
**Key:** Complex function handling matrix initialization from device coordinates.

#### 26. Function at 0x556F8: `set_matrix_from_fixed_point_pairs`
**Entry:** 0x556F8  
**Purpose:** Sets full 3x2 matrix from 6 fixed-point number pairs. Converts each to floating point, applies scaling factors from 0x20175F4/0x20175F0, then calls 0x555F8.
**Arguments:** 6 fixed-point pairs (12 parameters)
**Calls:** 0x55D8C (process fixed point), 0x89938 (float multiply), 0x89A88 (float operations), 0x555F8 (set matrix)
**RAM access:** 0x20175FA, 0x20175F4, 0x20175F0

#### 27. Function at 0x5583C: `convert_angle_to_matrix_component`
**Entry:** 0x5583C  
**Purpose:** Converts angle value to matrix rotation component. Uses trigonometric functions to compute sin/cos for matrix.
**Arguments:** Angle at fp@8, destination pointer at fp@12
**Returns:** Result stored at destination
**Calls:** 0x89A10 (trig function), 0x89A88 (float ops), 0x89998 (math), 0x899C8 (convert)

#### 28. Function at 0x55872: `clamp_matrix_component_to_range`
**Entry:** 0x55872  
**Purpose:** Clamps matrix component value to valid range [-2147483648, 2147483647]. Handles overflow/underflow for fixed-point representation.
**Arguments:** Source pointer at fp@8
**Returns:** D0 contains clamped value
**Calls:** 0x89A88 (float ops), 0x89A58 (compare), 0x899C8 (convert), 0x89980 (compare), 0x89A40 (convert back)
**Key:** Prevents matrix component overflow in fixed-point representation.

#### 29. Function at 0x558E2: `update_matrix_component_caches`
**Entry:** 0x558E2  
**Purpose:** Updates cached matrix components at offsets 0x5C, 0x60, 0x64, 0x68 in graphics state by clamping values from offsets 0x4A, 0x4E, 0x52, 0x56.
**Calls:** 0x55872 (clamp component) 4 times
**RAM access:** 0x2017464

#### 30. Function at 0x5595A: `update_device_transform_matrix`
**Entry:** 0x5595A  
**Purpose:** Updates device transformation matrix based on current graphics state. Gets current transform, processes it, updates cached values.
**Calls:** 0x2098C (unknown), 0x5526C via indirect call (transform), 0x1A7C2 (process matrix), 0x89A88 (float ops), 0x555F8 (set matrix), 0x558E2 (update caches)
**Key:** Sets bit 7 at offset 0xA4 in graphics state to indicate matrix update needed.

#### 31. Function at 0x55A14: `initialize_graphics_state_matrix`
**Entry:** 0x55A14  
**Purpose:** Initializes or resets graphics state matrix. Sets default values, updates clip region if needed, copies matrix to alternate buffer.
**Calls:** Indirect call at offset 0x34 in graphics state table, 0x56FAC (set value), 0x1AB70 (update), 0x1DF94 (process)
**RAM access:** 0x2017464

#### 32. Function at 0x55AAA: `gsave_and_update_matrices`
**Entry:** 0x55AAA  
**Purpose:** Performs gsave operation followed by matrix updates. Standard sequence for saving graphics state.
**Calls:** 0x580E4 (gsave), 0x5595A (update device transform), 0x55A14 (initialize matrix), 0x58178 (grestore)

#### 33. Function at 0x55AC6: `initialize_graphics_state_comprehensive`
**Entry:** 0x55AC6  
**Purpose:** Comprehensive graphics state initialization. Sets default matrix values, configures rendering flags, sets up function pointers.
**Calls:** 0x155D0 (transform and clear), 0x1AB70 (update), 0x5595A (update device transform)
**RAM access:** 0x2017464, 0x20008F8, 0x87CB0 (function table)

#### 34. Function at 0x55B66: `enable_hardware_rendering`
**Entry:** 0x55B66  
**Purpose:** Enables hardware rendering mode. Sets flags, checks hardware capability via indirect call, falls back to software if needed.
**Calls:** Indirect call at offset 0x38 in graphics state table, 0x55AC6 (init), 0x55A14 (init matrix)
**RAM access:** 0x20009D8, 0x20009DC

#### 35. Function at 0x55BA4: `check_hardware_capability`
**Entry:** 0x55BA4  
**Purpose:** Checks if hardware rendering is available via indirect call. Sets/clears flags based on result.
**Calls:** Indirect call at offset 0x38 in graphics state table
**RAM access:** 0x20009D8, 0x20009DC

#### 36. Function at 0x55BD4: `process_transform_with_validation`
**Entry:** 0x55BD4  
**Purpose:** Processes transformation with validation checks. Gets current transform via indirect call, validates components.
**Returns:** None (truncated in disassembly)
**Calls:** Indirect call at offset 0x4 in graphics state table
**Key:** Checks if transform component at offset -12 in stack frame is negative and non-zero.

This region (0x55000-0x55C00) contains core matrix manipulation functions for the PostScript graphics state:
- Matrix copying and composition operations
- Transformation matrix updates and caching
- Graphics state initialization
- Hardware/software rendering mode switching  (PS dict operator)
- Fixed-point to floating-point conversions for matrix components
- Determinant and inverse caching with invalidation logic

The functions work with the 108-byte graphics state structure at 0x2017464, particularly the transformation matrix components and their caches.

; === CHUNK 30: 0x55C00-0x56800 ===

### 1. Function at 0x55C00: `compute_fixed_point_scale_factor`
**Entry:** 0x55C00 (no LINK instruction, so this is a continuation from earlier code)
**Purpose:** Computes a scaling factor for fixed-point arithmetic by comparing absolute values of four floating-point numbers. Takes the maximum absolute value among two pairs, then takes the maximum of those two, converts to integer, and computes a shift count (0-15) such that value << scale >= 16384.
**Arguments:** Uses stack variables at fp offsets: -12, -8, -4, -16, -20 (floating-point values)
**Returns:** None directly, but stores scale factor in word at 0x20175F8
**Calls:** 0x89980 (floating-point compare), 0x89A40 (float to int conversion)
- [PS floating-point] Uses BCHG #31 to get absolute values (clears IEEE 754 sign bit)
- Compares pairs: fp@(-12) vs fp@(-20), fp@(-8) vs fp@(-16)  stack frame parameter
- Takes maximum of each pair, then maximum of those two
- Converts to integer, adds 20 (for rounding?), then doubles until >= 16384
- Stores shift count (0-15) in 0x20175F8

### 2. Function at 0x55D42: `scale_to_fixed_point`
**Entry:** 0x55D42 (LINKW %fp,#0)
**Purpose:** Converts two floating-point values to fixed-point with scaling. Calls 0x3C644C (likely multiplies them), adds 655360 (0xA0000 = 10<<16), shifts left by scale factor, adds 32768 for rounding, then shifts right by 16.
**Arguments:** fp@8, fp@12 (two floating-point values)
**Returns:** D0 = scaled fixed-point result (32-bit)
**Calls:** 0x3C644C, uses scale factor at 0x20175F8
**Algorithm:** ((func(arg1, arg2) + 655360) << scale) + 32768) >> 16

### 3. Function at 0x55D72: `unscale_from_fixed_point`
**Entry:** 0x55D72 (LINKW %fp,#0)
**Purpose:** Reverse operation of scale_to_fixed_point. Converts scaled fixed-point back to unscaled value.
**Arguments:** fp@8 (scaled fixed-point value)
**Returns:** D0 = unscaled value
**Algorithm:** (input >> scale) - 655360

### 4. Function at 0x55D8C: `unscale_and_combine`
**Entry:** 0x55D8C (LINKW %fp,#-8)
**Purpose:** Unscales first argument, then calls 0x3C643E with the unscaled value and second argument.
**Arguments:** fp@8 (scaled value), fp@12 (floating-point)
**Returns:** D0 = result
**Calls:** 0x55D72 (unscale_from_fixed_point), 0x3C643E
**Saves:** D7 on stack

### 5. Function at 0x55DB4: `convert_rectangle_to_fixed`
**Entry:** 0x55DB4 (LINKW %fp,#-4)
**Purpose:** Converts rectangle coordinates (first point only) from floating-point to fixed-point. Takes pointer to rectangle (4 floats), converts first point using 0x89A88 (float to fixed?), then calls 0x3B5546.
**Arguments:** fp@8 (pointer to rectangle: 4 floats = x1,y1,x2,y2)
**Returns:** D0 = result (likely success flag or converted value)
**Calls:** 0x89A88, 0x3B5546
**Stack frame:** -4 bytes for local variable

### 6. Function at 0x55DDE: `update_clip_bounds`
**Entry:** 0x55DDE (LINKW %fp,#0)
**Purpose:** Updates global clipping bounds from two floating-point values. Converts to fixed-point, rounds to multiples of 32, stores bounds and their reciprocals, and sets a flag if both are zero.
**Arguments:** fp@8 (pointer to first float), fp@12 (pointer to second float)
**Calls:** 0x89A40 (float to int), 0x89A10 (int to float for reciprocal)
- 0x20175E8: first bound (width)  (font metric)
- 0x20175EC: second bound (height)  (font metric)
- 0x20175F0: reciprocal of first
- 0x20175F4: reciprocal of second
- 0x20175FA: flag (1 if both zero, 0 otherwise)

### 7. Function at 0x55E6A: `set_clip_from_rectangle`
**Entry:** 0x55E6A (LINKW %fp,#0)
**Purpose:** Sets clipping bounds from a rectangle. Checks if rectangle is very small (compared to constant at PC+0x1841C), and if so, resets clipping to zero. Otherwise calls update_clip_bounds with rectangle width/height.
**Arguments:** fp@8 (pointer to rectangle: 4 floats = x1,y1,x2,y2)
**Calls:** 0x89980 (float compare), 0x55DDE (update_clip_bounds)
**Key logic:** If rectangle width and height are both < constant (likely epsilon), set clipping to zero with flag=1; otherwise compute width/height and update clipping.

### 8. Function at 0x55ED6: `update_clipped_corners`
**Entry:** 0x55ED6 (LINKW %fp,#-8)
**Purpose:** Updates four corner coordinates by multiplying them with clipping reciprocals, then calls 0x563FA for each pair.
**Calls:** 0x22C8C, 0x89AB8 (float multiply), 0x563FA
- 0x20220C8, 0x20220CC, 0x2017F60, 0x20221D8 (corner coordinates)  coordinate data  (font metric data)
- 0x20175F0, 0x20175F4 (clipping reciprocals)  (PS clip operator)
**Algorithm:** For each corner: corner *= reciprocal, then call 0x563FA with appropriate pairs

### 9. Function at 0x55F90: `set_clip_flag`
**Entry:** 0x55F90 (LINKW %fp,#0)
**Purpose:** Sets a flag at 0x200192C to 1.
**RAM access:** 0x200192C = flag

### 10. Function at 0x55FA0: `setup_clipping_region`
**Entry:** 0x55FA0 (LINKW %fp,#-24)
**Purpose:** Main clipping setup function. Takes optional rectangle, computes scaling factor, sets up clipping region, and updates global clipping state.
**Arguments:** fp@8 (flag), fp@12 (pointer to rectangle or null)
**Returns:** D0 = result (0=success, 1=error)
**Calls:** 0x1FF7E, 0x55E6A (set_clip_from_rectangle), 0x89980 (float compare), 0x89A88, 0x89920, 0x899C8, 0x55DB4 (convert_rectangle_to_fixed), 0x55DDE (update_clip_bounds), 0x55ED6 (update_clipped_corners)
- If rectangle pointer is null, uses current graphics state rectangle
- Computes maximum dimension for scaling
- Sets scale factor based on dimension size (0-15)  (PS CTM operator)  (register = size parameter)
- Updates global clipping bounds and corner coordinates  (PS clip operator)
- Handles special flag at 0x200192C

### 11. Function at 0x562EE: `adjust_clipping_for_scale`
**Entry:** 0x562EE (LINKW %fp,#0) - Actually starts at 0x562EE, but appears to be continuation
**Purpose:** Adjusts clipping bounds based on scale factor. Multiplies bounds by constants, compares with stored values, and updates if needed.
**Returns:** D0 = result (0=success, 1=error)
**Calls:** 0x89AB8 (float multiply), 0x89938 (float divide?), 0x89980 (float compare), 0x1FF7E, 0x55DDE (update_clip_bounds), 0x55ED6 (update_clipped_corners)
- 0x20220C8, 0x20220CC, 0x2017F60, 0x20221D8 (corner coordinates)  coordinate data  (font metric data)
- 0x2001930-0x200193C (stored rectangle bounds)

### 12. Function at 0x563FA: `process_corner_pair`
**Entry:** 0x563FA (LINKW %fp,#0)
**Purpose:** Processes two corner coordinates by converting to fixed-point, scaling, and calling 0x20F5E.
**Arguments:** fp@8, fp@12 (two floating-point corner coordinates)
**Calls:** 0x89A88, 0x55D42 (scale_to_fixed_point), 0x20F5E
**Algorithm:** Convert both to fixed-point, scale them, then call 0x20F5E with results

### 13. Function at 0x56436: `increment_ref_count`
**Entry:** 0x56436 (LINKW %fp,#0)
**Purpose:** Increments reference count in a structure if pointer is not null.
**Arguments:** fp@8 (pointer to structure with ref count at offset 80)
**Key operation:** If pointer != null, increment word at offset 80

### 14. Function at 0x5644C: `decrement_ref_count`
**Entry:** 0x5644C (LINKW %fp,#0)
**Purpose:** Decrements reference count in a structure, calls callback if count reaches zero.
**Arguments:** fp@8 (pointer to structure)
- If pointer != null, decrement word at offset 80  struct field
- If count becomes zero, call function at offset 64  struct field
**Structure layout:** offset 64 = callback, offset 80 = ref count

### 15. Function at 0x56474: `swap_graphics_state`
**Entry:** 0x56474 (LINKW %fp,#0)
**Purpose:** Swaps current graphics state with new one, updating references and calling setup functions.
**Arguments:** fp@8 (pointer to new graphics state)
**Calls:** 0x5644C (decrement_ref_count), 0x56436 (increment_ref_count), 0x15BD4, 0x155D0, 0x1595A
**RAM access:** 0x2017464 (current graphics state pointer)
- Decrement ref count of old state at offset 160  struct field
- Increment ref count of new state
- Store new state at 0x2017464+160
- Call three setup functions

### 16. Function at 0x564AA: `compare_rectangles`
**Entry:** 0x564AA (LINKW %fp,#0)
**Purpose:** Compares two rectangles for overlap/containment relationships.
**Arguments:** fp@8 (pointer to rectangle A), fp@12 (pointer to rectangle B)
**Returns:** D0 = relationship code (0=disjoint, 1=overlap, 2=contain)
**Calls:** 0x89980 (float compare)
**Algorithm:** Compares rectangle coordinates to determine spatial relationship

### 17. Function at 0x56774: `validate_path_structure`
**Entry:** 0x56774 (LINKW %fp,#-48)
**Purpose:** Validates a linked list path structure by checking node types and connections.
**Arguments:** fp@8 (pointer to path structure)
**Returns:** D0 = validation result (0=invalid, 1=valid)
- Traverses linked list starting from given pointer  (data structure manipulation)
- Checks node types (1=line, 3=curve)
- Validates coordinate relationships between consecutive nodes  coordinate data  (font metric data)
- Ensures proper termination

### 18. Function at 0x567A6: `check_path_intersection`
**Entry:** 0x567A6 (LINKW %fp,#-32)
**Purpose:** Checks if current path intersects with clipping region.
**Arguments:** fp@8 (flag)
**Returns:** D0 = intersection result
**Calls:** 0x2098C, 0x564AA (compare_rectangles)
**RAM access:** 0x2017464 (graphics state)
- Gets current path bounds from graphics state
- Compares with clipping rectangle  (PS clip operator)
- Checks intersection based on flag and graphics state flags

### 1. Floating-point constants at 0x562E0:
- 0x562E0: 0x40340000 (float 20.0)
- 0x562E4: 0x00000000 (padding)

### 2. Floating-point constants at 0x562E8:
- 0x562E8: 0x40200000 (float 2.5)
- 0x562EC: 0x00000000 (padding)

3. The function at 0x55FA0 is much more complex than described - it's the main clipping setup function.

4. The data regions at 0x562E0 and 0x562E8 contain floating-point constants used for scaling.

5. The function at 0x55ED6 doesn't just update corners - it multiplies them by reciprocals and processes pairs.

This region contains the clipping subsystem for the PostScript interpreter:
- Fixed-point scaling system with dynamic scale factor (0-15)  (PS CTM operator)  (PS graphics transform)
- Clipping bounds management with width/height and reciprocals  (font metric)
- Rectangle comparison and intersection testing
- Graphics state swapping with reference counting
- Path structure validation
- Coordinate transformation for clipping corners  (PS clip operator)

The clipping system uses fixed-point arithmetic with a dynamic scale factor to maintain precision while avoiding overflow. The scale factor is computed based on the maximum dimension of the clipping region.

; === CHUNK 31: 0x56800-0x57400 ===

### 1. 0x56800 - `set_color_space` (CORRECTED)
**What it does:** Main color space configuration function. Checks if color is enabled (fp@(-4) = 1) and sets up appropriate color transformation matrices and device procedures. If color is disabled (0), configures grayscale mode. Manages transitions between color modes, saving/restoring color state. The function has two main paths: color mode (sets up RGB/CMYK transformations) and grayscale mode (simplified processing).
**Arguments:** fp@(8) - device context pointer, fp@(-4) - color enable flag (0=grayscale, 1=color)
**Hardware/RAM:** Accesses 0x2017464 (global color structure), calls 0x1a7c2, 0x1a80e, 0x15fa0, 0x22c72, 0x1caa0, 0x1da80, 0x22b10
**Call targets:** 0x162f0, 0x158e2, 0x16574
### 2. 0x56a10 - `set_color_space_false` (CORRECT)
**What it does:** Simple wrapper that calls 0x167a6 with argument 0 to disable color space (set grayscale mode).
**Hardware/RAM:** Calls 0x167a6(0)
**Call targets:** 0x167a6
**Called by:** PostScript operators

### 3. 0x56a20 - `set_color_space_true` (CORRECT)
**What it does:** Simple wrapper that calls 0x167a6 with argument 1 to enable color space (set color mode).
**Hardware/RAM:** Calls 0x167a6(1)
**Call targets:** 0x167a6
**Called by:** PostScript operators

### 4. 0x56a32 - `call_device_color_proc` (CORRECT)
**What it does:** Calls a device-specific color procedure with 6 color components. Converts each component from float to fixed-point using 0x15d72 before passing to the device procedure. Used for CMYK or other multi-component color spaces.
**Arguments:** fp@(8)-fp@(28) - 6 color component values (floats)
**Hardware/RAM:** Accesses 0x2017464+0x90 (color proc pointer), 0x200194c/1948/1950 (color values), calls 0x15d72 six times
**Call targets:** 0x15d72 (float-to-fixed conversion), indirect call to [0x2017464+0xa0]+0x18 (device color proc)
**Called by:** 0x56abc (setcolor) via callback mechanism

### 5. 0x56abc - `setcolor` (ENHANCED)
**What it does:** Main color setting function with comprehensive bounds checking and color space conversion. Handles both RGB and CMYK color spaces with clipping to [0,1] range. Has three main execution paths: 1) Color mode with device color procedures, 2) Grayscale mode, 3) Direct hardware color setting. Performs matrix transformations for device color space conversion and gamma correction.
**Arguments:** fp@(8) - color object pointer, fp@(12), fp@(16) - color components (type depends on color space)
**Hardware/RAM:** Accesses 0x2017504, 0x2017570 (bounds), 0x2017464 (color structure), calls 0x89a10, 0x89938 (floating point ops), 0x164aa, 0x15fa0, 0x22c72, 0x1cb7a, 0x1da80, 0x1d018, 0x1d36a, 0x22b10, 0x162f0, 0x1df50
**Call targets:** Many - see above
**Called by:** PostScript setcolor/setrgbcolor/setcmykcolor operators

### 6. 0x56f3e - `set_color_transform_matrix` (CORRECT)
**What it does:** Sets a 2x2 color transformation matrix at 0x2017464+0x24. Only updates if the new matrix differs from current (calls 0x3b1ec for comparison). Used for color space conversions.
**Arguments:** fp@(8), fp@(12) - matrix values (2x2 matrix)
**Hardware/RAM:** Accesses 0x2017464+0x24/0x28, calls 0x3b1ec (matrix comparison)
**Call targets:** 0x3b1ec
**Called by:** 0x56f8c

### 7. 0x56f8c - `get_and_set_color_matrix` (CORRECT)
**What it does:** Gets a color matrix from 0x3b6fa and passes it to 0x56f3e for setting. Likely retrieves a default or current color transformation matrix.
**Hardware/RAM:** Calls 0x3b6fa, then 0x56f3e
**Call targets:** 0x3b6fa, 0x56f3e
**Called by:** Unknown (color initialization)

### 8. 0x56fac - `set_gray_color` (ENHANCED)
**What it does:** Converts a floating-point gray value (0.0-1.0) to 8-bit gamma-corrected value. Applies gamma correction using lookup table at 0x20220d8 if gamma is enabled. Stores result in color structure at 0x2017464+0x8c-0x8f.
**Arguments:** fp@(8) - pointer to float gray value
**Hardware/RAM:** Accesses 0x2017464+0xa4 (bit 4 check), 0x20220d8 (gamma LUT), 0x2017464+0x8c-0x8f (color components)
**Call targets:** 0x4640e, 0x3ce34, 0x89a70, 0x89a40
**Called by:** 0x57070

### 9. 0x57070 - `set_gray_from_float` (CORRECT)
**What it does:** Wrapper that converts float to internal format (0x3b81a) then calls set_gray_color.
**Arguments:** fp@(8) - pointer to float gray value
**Hardware/RAM:** Calls 0x3b81a, then 0x56fac
**Call targets:** 0x3b81a, 0x56fac
**Called by:** PostScript setgray operator

### 10. 0x5708e - `convert_device_to_hsb` (CORRECT)
**What it does:** Converts device RGB (0x2017464+0x8c-0x8e) to HSB color space. Uses gamma-corrected values from color structure, applies transformation matrices at 0x200191c/1920/1924, and returns HSB value.
**Arguments:** fp@(8) - pointer to store HSB result
**Hardware/RAM:** Accesses 0x2017464+0x8c-0x8e, 0x200191c/1920/1924 (gamma matrices), calls 0x89a10, 0x89938, 0x89a70, 0x899b0
**Call targets:** Various floating point routines
**Called by:** 0x57166

### 11. 0x57166 - `set_gray_from_rgb` (CORRECT)
**What it does:** Converts RGB to grayscale using convert_device_to_hsb, then applies additional transformation (0x3be16).
**Arguments:** fp@(8) - pointer to float gray value
**Hardware/RAM:** Calls 0x5708e, then 0x3be16
**Call targets:** 0x5708e, 0x3be16
**Called by:** PostScript operators needing RGB-to-gray conversion

### 12. 0x57184 - `set_rgb_color` (ENHANCED)
**What it does:** Sets RGB color from three float components. Converts each component to 8-bit with gamma correction, applies transformation matrices, and stores in color structure. Handles gamma lookup table if enabled.
**Arguments:** fp@(8), fp@(12), fp@(16) - pointers to R, G, B float values
**Hardware/RAM:** Accesses 0x200191c/1920/1924 (gamma matrices), 0x20220d8 (gamma LUT), 0x2017464+0x8c-0x8f (color components)
**Call targets:** 0x89a70, 0x89a88, 0x89920, 0x89a28 (floating point ops)
**Called by:** PostScript setrgbcolor operator

### 13. 0x572c2 - DATA: Floating point constant 0.5
**What it is:** IEEE 754 single-precision floating point constant 0.5 (0x3FE00000)
**Address:** 0x572c2
**Format:** 0x3FE00000

### 14. 0x572c8 - `set_cmyk_color` (ENHANCED)
**What it does:** Sets CMYK color from four float components. Converts each component with bounds checking (clips to [0,1]), applies gamma correction if enabled, and stores in color structure. Uses separate gamma correction for each channel.
**Arguments:** fp@(8), fp@(12), fp@(16), fp@(20) - pointers to C, M, Y, K float values
**Hardware/RAM:** Accesses 0x2017464+0xa4 (bit 4 check), calls 0x3b81a (float conversion), 0x4640e, 0x89a88, 0x89968, 0x899c8
**Call targets:** 0x3b81a, 0x4640e, various floating point routines
**Called by:** PostScript setcmykcolor operator

### 15. 0x5740e - DATA: Floating point constant 0.0
**What it is:** IEEE 754 single-precision floating point constant 0.0 (0x00000000)
**Address:** 0x5740e
**Format:** 0x00000000

### 16. 0x57412 - DATA: Floating point constant 0.0 (duplicate)
**What it is:** Another 0.0 constant (0x00000000)
**Address:** 0x57412
**Format:** 0x00000000

### 17. 0x57416 - DATA: Floating point constant 1.0
**What it is:** IEEE 754 single-precision floating point constant 1.0 (0x3F800000)
**Address:** 0x57416
**Format:** 0x3F800000

### 18. 0x5741a - DATA: Floating point constant 1.0 (duplicate)
**What it is:** Another 1.0 constant (0x3F800000)
**Address:** 0x5741a
**Format:** 0x3F800000

## CORRECTIONS AND ADDITIONS:

1. `set_rgb_color` at 0x57184 (not set_cmyk_color)

2. **Data regions identified:** Four floating point constants at 0x572c2 (0.5), 0x5740e/0x57412 (0.0), and 0x57416/0x5741a (1.0). These are used for bounds checking in color conversion functions.

3. **Gamma correction system:** The color system uses a gamma lookup table at 0x20220d8 (256 bytes) when gamma is enabled (checked via bit 4 at 0x2017464+0xa4). This is applied in `set_gray_color` and `set_rgb_color`.

4. **Color structure layout confirmed:** 
   - 0x2017464+0x8c: Blue component
   - 0x2017464+0x8d: Green component  
   - 0x2017464+0x8e: Red component
   - 0x2017464+0x8f: Gray/Alpha component
   - 0x2017464+0xa4: Flags (bit 4 = gamma enabled, bit 7 = color mode)

5. **Gamma matrices:** Three 4x4 transformation matrices at 0x200191c, 0x2001920, 0x2001924 used for RGB-to-HSB conversion.

6. **The analysis correctly identifies all functions in this range.** No code was misidentified as data except for the floating point constants which are embedded in the code section.

7. **Calling convention:** All functions use standard C calling convention with LINK/UNLK and preserve registers as needed.

This region contains the core color management system for the PostScript interpreter, handling RGB, CMYK, and grayscale color spaces with gamma correction and device-specific color transformations.

; === CHUNK 32: 0x57400-0x58000 ===

### 1. 0x57400 - `convert_device_rgb_to_color_space`
**What it does:** Converts device RGB color values (stored at 0x2017464+0x8C-0x8E) to color space values. It reads three byte values (R, G, B) from the global color structure, converts them to floating point, scales them by 255.0 (0x437F0000), and pushes them onto the PostScript stack via 0x3BE16.
**Hardware/RAM:** Accesses 0x2017464+0x8C, +0x8D, +0x8E (device RGB bytes), calls 0x89A10 (byte to float), 0x89938 (negate if negative), 0x899B0 (multiply by 255.0), 0x3BE16 (push to stack)
**Cross-references:** Called by color conversion routines

### 2. 0x574F8 - `set_rgb_color`
**What it does:** Sets an RGB color from three PostScript stack values. Gets three color components from stack via 0x3B81A, applies gamma correction if enabled (bit 4 at 0x2017464+0xA4), clamps values to [0,1], applies color transformation matrix, and calls 0x17184 to set the color.
**Arguments:** Three color components on stack (fp@(-40), fp@(-8), fp@(-4) after retrieval)
**Hardware/RAM:** Accesses 0x2017464+0xA4 (gamma flag), calls 0x4640E (gamma correction), 0x3B81A (get from stack), 0x89A88 (float operations), 0x89968 (compare), 0x899C8 (convert), 0x89A40 (floor), 0x89A10 (convert to int), 0x89AB8 (subtract), 0x89A70 (multiply), 0x89AA0 (divide), 0x17184 (set color)
**Cross-references:** Complex RGB color setting with gamma and matrix transformation

### 3. 0x57870 - `convert_device_rgb_to_hsb`
**What it does:** Converts device RGB to HSB (Hue, Saturation, Brightness). Reads RGB bytes, converts to float [0,1], finds min/max, computes hue, saturation, brightness, and pushes results to stack.
**Hardware/RAM:** Accesses 0x2017464+0x8C-0x8E, calls 0x89A10, 0x89938, 0x899B0 (scale by 255), 0x89980 (compare), 0x89AB8 (subtract), 0x899B0 (multiply), 0x89A88 (float convert), 0x89920 (add), 0x89AA0 (divide), 0x89998 (atan2), 0x89968 (compare), 0x3BE16 (push to stack)
**Algorithm:** Standard RGB to HSB conversion: brightness = max(R,G,B), saturation = (max-min)/max, hue computed via atan2

### 4. 0x57BC8 - `set_color_space_matrix`
**What it does:** Sets the color space transformation matrix. Checks gamma flag, updates matrix at 0x2017464+0x94 (148 bytes), clears dirty flag, and converts current device color through the matrix.
**Arguments:** fp@(20) - pointer to new matrix
**Hardware/RAM:** Accesses 0x2017464+0xA4 (gamma flag), 0x2017464+0x96 (word flag), 0x2017464+0xA5 (dirty flag), 0x2001928, calls 0x4640E (gamma), 0x2F540 (matrix update), converts device RGB via 0x89A10, 0x89938, 0x899B0, calls 0x17184
**Cross-references:** Called when color space matrix changes

### 5. 0x57CE8 - `init_default_color_matrix`
**What it does:** Initializes default color transformation matrix to identity. Sets up a 5x5 matrix with default values from 0x87CB8 and current color space from 0x20008F8.
**Hardware/RAM:** Accesses 0x87CB8 (default matrix), 0x20008F8 (color space), calls 0x3BA8E (get matrix), 0x17BCA (set_color_space_matrix)
**Cross-references:** Called during color system initialization

### 6. 0x57D38 - `get_current_color_matrix`
**What it does:** Returns the current color transformation matrix (148 bytes at 0x2017464+0x94).
**Return value:** Pointer to matrix in D0
**Hardware/RAM:** Accesses 0x2017464+0x94, calls 0x365AA (copy matrix)
**Cross-references:** Wrapper for 0x365AA

### 7. 0x57D56 - `set_cmyk_color`
**What it does:** Sets a CMYK color from four PostScript stack values. Gets four color components from stack via 0x3BA8E, applies color transformation matrix, and calls 0x17BCA to set the color.
**Arguments:** Four color components on stack (CMYK values)
**Hardware/RAM:** Calls 0x3BA8E (get from stack) five times, 0x17BCA (set_color_space_matrix)
**Cross-references:** CMYK color setting with matrix transformation

### 8. 0x57DB6 - `init_color_system`
**What it does:** Initializes the entire color system. Sets up default color matrix from 0x87CB8, initializes color space, clears various color-related flags and values.
**Hardware/RAM:** Accesses 0x87CB8 (default matrix), 0x20008F8 (color space), calls 0x365AA (copy matrix) multiple times, initializes gamma to 1.0 (0x3F800000)
**Cross-references:** Called during system initialization

### 9. 0x57E24 - `gamma_correction_helper`
**What it does:** Helper function for gamma correction. Takes input value, applies gamma correction using lookup table or calculation.
**Arguments:** fp@(8) - input value, fp@(12) - gamma value, fp@(16) - pointer to result
**Hardware/RAM:** Calls 0x4DCF8 (gamma calculation)
**Cross-references:** Used by gamma correction routines

### 10. 0x57E4E - `apply_gamma_correction`
**What it does:** Applies gamma correction to color values. Uses callback function at 0x2017464+0xA0+0x3C to apply gamma correction.
**Arguments:** Multiple parameters for gamma correction
**Return value:** D0 contains error code (0 for success)
**Hardware/RAM:** Accesses 0x2017464+0xA0 (gamma callback table), calls error handlers 0x46382/0x463BA on failure
**Cross-references:** Called when gamma correction is needed

### 11. 0x57EA6 - `set_gamma`
**What it does:** Sets the gamma correction value. Gets gamma value from stack, clamps it to range [0.1, 3.2], and stores it at 0x2017464+0x9C.
**Arguments:** Gamma value on stack
**Hardware/RAM:** Accesses 0x2017464+0x9C (gamma value), calls 0x3B81A (get from stack), 0x89968 (compare), 0x899C8 (convert)
**Cross-references:** PostScript operator for setting gamma

### 12. 0x57F3A - `get_gamma`
**What it does:** Returns the current gamma correction value by pushing it onto the PostScript stack.
**Hardware/RAM:** Accesses 0x2017464+0x9C (gamma value), calls 0x3BE16 (push to stack)
**Cross-references:** PostScript operator for getting gamma

### 13. 0x57F5A - `init_color_system_complete`
**What it does:** Completes color system initialization. Sets up default color matrix, initializes color space, clears flags, sets default gamma to 1.0.
**Hardware/RAM:** Accesses 0x87C58 (default values), 0x20008F8 (color space), calls 0x1A580 (initialize), sets gamma to 1.0 (0x3F800000)
**Cross-references:** Final color system initialization

### 1. 0x5785A-0x5786F - Float constants table
**Format:** Three 8-byte IEEE double precision floating point constants:
- 0x5785A: 0.0 (0x00000000 00000000)
- 0x57862: 1.0 (0x3FF00000 00000000)  
- 0x5786A: 6.0 (0x40180000 00000000)

### 2. 0x57BAA-0x57BC7 - HSB conversion constants
**Format:** Four 8-byte IEEE double precision floating point constants:
- 0x57BAA: 5.0 (0x40140000 00000000)
- 0x57BB2: 1.0 (0x3FF00000 00000000)
- 0x57BBA: 3.0 (0x40080000 00000000)
- 0x57BC2: 6.283185307179586 (2π, 0x401921FB 54442D18)

### 3. 0x57F2C-0x57F39 - Gamma range constants
**Format:** Two 8-byte IEEE double precision floating point constants:
- 0x57F2C: 0.1 (0x3FC99999 9999999A)
- 0x57F34: 3.2 (0x40590000 00000000)

1. The color system uses a 5x5 transformation matrix (148 bytes at 0x2017464+0x94).

2. Gamma correction is controlled by bit 4 at 0x2017464+0xA4.

3. Gamma values are clamped to range [0.1, 3.2] as seen in the constants at 0x57F2C-0x57F39.

4. The system supports both RGB and CMYK color spaces with matrix transformations.

5. Color conversion includes device RGB to HSB conversion for color space operations.

6. The initialization functions set up default identity matrices and clear various color-related flags.

; === CHUNK 33: 0x58000-0x58C00 ===

2. **Function boundaries**: Several functions were misidentified. The actual functions in this range are:
   - 0x58000: `ps_initmatrix` (PostScript `initmatrix` operator)
   - 0x580E4: `ps_gsave` (PostScript `gsave` operator)  (PS gstate operator)
   - 0x58178: `ps_grestore` (PostScript `grestore` operator)  (PS gstate operator)
   - 0x5817A: `ps_grestoreall` (PostScript `grestoreall` operator)  (PS gstate operator)
   - 0x582A4: `ps_setgstate` (PostScript `setgstate` operator)
   - 0x582E2: `ps_currentgstate` (PostScript `currentgstate` operator)
   - 0x5832C: `init_graphics_system` (internal initialization)
   - 0x58640: `register_graphics_operators` (operator registration)
   - 0x58814: `allocate_rendering_buffer` (memory allocation)  (PS dict operator)  (PS font cache)
   - 0x5884C: `null_callback` (empty callback function)
   - 0x58856: `enable_hardware_rendering` (HW acceleration)  (PS dict operator)
   - 0x58888: `setup_hardware_callbacks` (HW callback table)
   - 0x588E4: `initialize_rendering_engine` (rendering init)  (PS dict operator)
   - 0x589CE-0x58BA2: Hardware acceleration wrapper functions

   - Floating-point constants at 0x580DC-0x580E2 (2 double values: 64.0 and 0.0)
   - Operator registration table at 0x58424-0x58504 (17 entries × 8 bytes)
   - String table at 0x5850C-0x5863E (PostScript operator names)
   - Character width table at 0x586B4-0x58812 (ASCII 0x43-0x7E, 60 entries)  (font metric)

#### **1. Function at 0x58000 - `ps_initmatrix`**
- **Entry**: 0x58000
- **Name**: `ps_initmatrix` (PostScript `initmatrix` operator)
- **Purpose**: Initializes the current transformation matrix to identity. Sets up the graphics state matrix at 0x2017464, clears flags, loads default matrix values, and calls matrix initialization routines.
- **Arguments**: None (PostScript operator called from interpreter)
- **Return**: None
- **RAM access**: 
  - 0x2017464: Current graphics state pointer
  - 0x20008f8: Unknown byte value (possibly default matrix flag)  (PS dict operator)
  - 0x2017354: Execution context
- **Calls**: 
  - 0x1a422: `setmatrix` or matrix copy
  - 0x34096: Floating point conversion (converts 64.0 to float)
  - 0x308fa: Matrix multiplication or transformation
  - 0x2efd2: Matrix operation (likely identity matrix setup)
  - 0x15ac6: Unknown (matrix finalization)
- **Algorithm**: 
  1. Clears bits 5 and 4 at offset 0xA4 in graphics state (matrix flags)
  2. Copies identity matrix from 0x87cb8 to graphics state offset 0x94
  3. Sets byte at offset 0x95 from 0x20008f8 (default matrix flag)
  4. Clears various fields (offsets 0x96, 0x98, 0xA5)
  5. Converts 64.0 to floating point (for default user space units)
  6. Calls matrix initialization functions with floating point values
- **Note**: This implements the PostScript `initmatrix` operator which resets the CTM to identity.

#### **2. Function at 0x580E4 - `ps_gsave`**
- **Entry**: 0x580E4
- **Name**: `ps_gsave` (PostScript `gsave` operator)
- **Purpose**: Saves current graphics state on stack. Increments stack depth, copies 166-byte state block, sets save flags.
- **Arguments**: None
- **Return**: None
- **RAM access**:
  - 0x20221dc: Graphics stack depth counter
  - 0x2017464: Current graphics state pointer
- **Calls**:
  - 0x46382: Stack overflow error (max 32 levels)
  - 0x16436: Path save operation
  - 0x2e264: Clipping path save
- **Algorithm**:
  1. Checks stack depth (max 32), calls error if full
  2. Adds 166 bytes to graphics state pointer (allocates new state)
  3. Increments stack depth counter at 0x20221dc
  4. Copies 41 long words + 1 word (166 bytes) from old to new state
  5. Sets flags at offsets 0x42 and 0x5A to 1 (save markers)
  6. Saves clipping path and current path
  7. Increments save count at offset 0xA5
- **Note**: The 166-byte block includes graphics state plus additional context.

#### **3. Function at 0x58178 - `ps_grestore`**
- **Entry**: 0x58178
- **Name**: `ps_grestore` (PostScript `grestore` operator)
- **Purpose**: Restores graphics state from stack. Checks bounds, restores state, handles clipping path restoration.
- **Arguments**: None
- **Return**: None
- **RAM access**:
  - 0x20018d8: Current stack level index
  - 0x20221dc: Stack depth
  - 0x2017464: Graphics state pointer
  - 0x2001928: Clip flag
- **Calls**:
  - 0x46334: Stack underflow error
  - 0x1644c: Path restore
  - 0x2e284: Clipping path restore
  - 0x1a7c2: Matrix operation (restores CTM)
  - 0x2098c: Unknown (clip state update)  (PS clip operator)
  - 0x2f540: Clipping update
- **Algorithm**:
  1. Checks if current depth matches saved level, errors if underflow
  2. Checks if this is outermost restore (save count == 0)
  3. If not outermost and clip stack not empty, clears clip flag
  4. Restores path and clipping path
  5. Calls matrix operations at offsets 0x2C and 0x44 (CTM restoration)
  6. If clip flag at offset 0x5A is 0, calls unknown function
  7. Subtracts 166 bytes from graphics state pointer (pops state)
  8. Decrements stack depth
  9. If outermost restore and clip stack not empty, updates clipping

#### **4. Function at 0x5817A - `ps_grestoreall`**
- **Entry**: 0x5817A (actually starts at 0x5817A, but label at 0x58178 covers both)
- **Name**: `ps_grestoreall` (PostScript `grestoreall` operator)
- **Purpose**: Restores all saved graphics states (pops until matching saved level).
- **Arguments**: None
- **Return**: None
- **Algorithm**:
  1. Loops calling `grestore` until stack depth matches saved level
  2. Final `grestore` to restore the target state

#### **5. Function at 0x582A4 - `ps_setgstate`**
- **Entry**: 0x582A4
- **Name**: `ps_setgstate` (PostScript `setgstate` operator)
- **Purpose**: Sets current graphics state from saved state dictionary.
- **Arguments**: D0 (stack argument count), A6 frame with parameter
- **Return**: None
- **RAM access**:
  - 0x20018d8: Current stack level index
  - 0x20221dc: Stack depth
- **Calls**:
  - 0x46334: Stack underflow error
  - 0x180E4: `gsave` (to save current state)  (PS gstate operator)
- **Algorithm**:
  1. Checks argument count matches saved level
  2. Calls `gsave` to push new state
  3. Sets new stack level index
  4. Updates saved stack depth for this level

#### **6. Function at 0x582E2 - `ps_currentgstate`**
- **Entry**: 0x582E2
- **Name**: `ps_currentgstate` (PostScript `currentgstate` operator)
- **Purpose**: Creates dictionary representing current graphics state.
- **Arguments**: D0 (stack argument count), A6 frame with parameter
- **Return**: None
- **RAM access**:
  - 0x20018d8: Current stack level index
  - 0x20221dc: Stack depth
- **Algorithm**:
  1. Checks target level is less than current level
  2. Calculates target stack depth
  3. Sets new current level
  4. Loops calling `grestore` until reaching target depth

#### **7. Function at 0x5832C - `init_graphics_system`**
- **Entry**: 0x5832C
- **Name**: `init_graphics_system`
- **Purpose**: Initializes graphics subsystem, sets up default values, registers operators.
- **Arguments**: D0 (mode: 0=full init, 1=reinit)
- **Return**: None
- **RAM access**:
  - 0x2017464: Graphics state pointer
  - 0x20221dc: Stack depth
  - 0x20018d8: Stack level index
  - 0x200191c/0x2001920: Default gamma values (0.3, 0.59)
  - 0x2001924: Calculated gamma product
  - Various hardware acceleration structures
- **Calls**:
  - 0x89938, 0x89a88, 0x89aa0, 0x899c8: Floating point operations
  - 0x17f5a: `init_color_system` (from earlier analysis)
  - 0x182a4: `ps_setgstate`
  - 0x469fa, 0x475fe, 0x47632: Operator registration functions
- **Algorithm**:
  1. If mode=0: Full initialization
     - Sets graphics state pointer to 0x2020c08
     - Clears stack depth, sets level index to -1
     - Sets default gamma values (0.3, 0.59)  (PS dict operator)
     - [PS color/transfer] Calculates gamma product (0.3 × 0.59) for NTSC luminance weighting
     - Clears various hardware structures
  2. If mode=1: Reinitialization
     - Calls `init_color_system`
     - Calls `ps_setgstate` with argument 0
     - Registers graphics operators
  3. Registers `setgstate`, `currentgstate`, and other operators

#### **8. Function at 0x58640 - `register_graphics_operators`**
- **Entry**: 0x58640
- **Name**: `register_graphics_operators`
- **Purpose**: Registers all graphics-related PostScript operators.
- **Arguments**: A0 (registration table pointer)
- **Return**: None
- **Calls**:
  - 0x1a438, 0x22ce0, 0x1a298, 0x275d8, 0x1f452, 0x2d43c, 0x2f618, 0x1832c, 0x14ffe: Various operator registration functions
- **Note**: Calls 9 different registration functions for different operator categories.

#### **9. Function at 0x58814 - `allocate_rendering_buffer`**
- **Entry**: 0x58814
- **Name**: `allocate_rendering_buffer`
- **Purpose**: Allocates and aligns rendering buffer memory.
- **Arguments**: D0 (size parameter)
- **Return**: D0 (aligned buffer address)
- **RAM access**:
  - 0x2017368: Memory allocation table  (PS font cache)
  - 0x20009cc: Minimum buffer address
  - 0x20221e8: Maximum buffer address
  - 0x20221e0: Alignment mask
- **Algorithm**:
  1. Calls memory allocator via function pointer at 0x2017368+0xE8
  2. Ensures address ≥ 0x20009cc
  3. Caps address at 0x20221e8
  4. Aligns address using mask 0x20221e0

#### **10. Function at 0x5884C - `null_callback`**
- **Entry**: 0x5884C
- **Name**: `null_callback`
- **Purpose**: Empty callback function (returns 0).
- **Arguments**: None
- **Return**: D0 = 0
- **Note**: Used as placeholder for unimplemented hardware callbacks.

#### **11. Function at 0x58856 - `enable_hardware_rendering`**
- **Entry**: 0x58856
- **Name**: `enable_hardware_rendering`
- **Purpose**: Enables hardware acceleration for rendering operations.
- **Arguments**: None
- **Return**: None
- **RAM access**:
  - 0x20009e4: Hardware rendering flag  (PS dict operator)
- **Calls**:
  - 0x58814: `allocate_rendering_buffer`  (PS dict operator)
  - 0x588e4: `initialize_rendering_engine`  (PS dict operator)
  - 0x28250: Hardware initialization
- **Algorithm**:
  1. Allocates rendering buffer with size 1
  2. Calls rendering engine initialization
  3. Calls hardware init function
  4. Sets hardware rendering flag to 1

#### **12. Function at 0x58888 - `setup_hardware_callbacks`**
- **Entry**: 0x58888
- **Name**: `setup_hardware_callbacks`
- **Purpose**: Sets up hardware acceleration callback table.
- **Arguments**: None
- **Return**: None
- **RAM access**:
  - 0x2001edc: Hardware callback table
  - 0x2017368: Function pointer table
- **Calls**:
  - 0x22ef4: Finalize hardware setup
- **Algorithm**:
  1. Copies function pointers from 0x2017368 to hardware callback table at 0x2001edc
  2. Copies 21 long words (84 bytes) of callback functions
  3. Calls final hardware setup

#### **13. Function at 0x588E4 - `initialize_rendering_engine`**
- **Entry**: 0x588E4
- **Name**: `initialize_rendering_engine`
- **Purpose**: Initializes the rendering engine with buffer allocation and tiling.
- **Arguments**: None
- **Return**: None
- **RAM access**:
  - 0x20009e4: Rendering engine structure  (PS dict operator)
  - 0x20221e4: Buffer alignment shift
  - 0x20221e0: Alignment mask
  - 0x20009e0: Tile size  (register = size parameter)
- **Calls**:
  - 0x58814: `allocate_rendering_buffer`  (PS dict operator)
  - 0x444f4, 0x44518: Tile initialization functions
  - 0x281fa: Tile rendering setup  (PS dict operator)
  - 0x58888: `setup_hardware_callbacks`
- **Algorithm**:
  1. Allocates aligned rendering buffer
  2. Calculates tile boundaries based on buffer size
  3. Initializes tiles (either full buffer or tiled)
  4. Sets up tile rendering callbacks
  5. Sets up hardware callbacks

#### `hardware_acceleration_wrappers` — Hardware Acceleration Wrappers (0x589CE-0x58BA2)
These functions provide software fallbacks with hardware acceleration when available:
- **0x589CE**: `hw_fill_rectangle` - 8 parameters
- **0x58A3A**: `hw_fill_polygon` - 6 parameters  
- **0x58A96**: `hw_draw_line` - 3 parameters
- **0x58ADA**: `hw_fill_triangle` - 5 parameters
- **0x58B2E**: `hw_clear_rectangle` - 1 parameter
- **0x58B5E**: `hw_copy_rectangle` - 3 parameters
- **0x58BA2**: `hw_transform_rectangle` - 11 parameters

1. Calls software implementation (e.g., 0x294d2 for `fill_rectangle`)
2. Checks if hardware rendering is enabled (0x20009e4)
3. If enabled, calls corresponding hardware callback from 0x20221ec

### **DATA REGIONS:**

#### `floating_point_constants` — Floating-point constants (0x580DC-0x580E2)
- 0x580DC: `4052000000000000` = 64.0 (double)
- 0x580E4: `0000000000000000` = 0.0 (double)

#### `operator_registration_table` — Operator registration table (0x58424-0x58504)
17 entries × 8 bytes each:
- First 4 bytes: Operator name string offset (relative to 0x5850C)  struct field
- Next 4 bytes: Function address
Operators: initmatrix, currentmatrix, defaultmatrix, setmatrix, concat, initclip, clip, clippath, currentpoint, gsave, grestore, grestoreall, setgstate, currentgstate, setfont, currentfont, setgray

#### `string_table` — String table (0x5850C-0x5863E)
PostScript operator names:
- initmatrix, currentmatrix, defaultmatrix, setmatrix, concat, initclip, clip, clippath, currentpoint, gsave, grestore, grestoreall, setgstate, currentgstate, setfont, currentfont, setgray, currentgray, setrgbcolor, currentrgbcolor, sethsbcolor, currenthsbcolor, setcmykcolor, currentcmykcolor, settransfer, currenttransfer, setcolortransfer, currentcolortransfer, setstrokeadjust, currentstrokeadjust, setflat, currentflat, setlinewidth, currentlinewidth, setlinecap, currentlinecap, setlinejoin, currentlinejoin, setmiterlimit, currentmiterlimit, setdash, currentdash, setcolorscreen, currentcolorscreen, sethalftone, currenthalftone, setundercolorremoval, currentundercolorremoval, setblackgeneration, currentblackgeneration, setoverprint, currentoverprint, setrenderingintent, currentrenderingintent, settrapping, currenttrapping, setcolortransform, currentcolortransform, setgraphicsstate, currentgraphicsstate, initgraphics, erasepage, copypage, showpage  (PS paint operator)  (font metric)

#### `character_width_table` — Character width table (0x586B4-0x58812)
60 entries for ASCII characters 0x43 ('C') through 0x7E ('~'):
- Each entry is 1 byte representing character width in some unit  (font metric)
- Pattern shows grouping by character type (letters, digits, punctuation)  (PS text operator)

### **KEY INSIGHTS:**

1. **Graphics state management**: The system uses a 166-byte state block (not just 108-byte graphics state) that includes additional context like paths and clipping.

2. **Hardware acceleration**: The system has a sophisticated hardware acceleration layer with software fallbacks. When hardware is available (0x20009e4 = 1), calls are routed to hardware callbacks at 0x20221ec.

3. **Tile-based rendering**: The rendering engine uses tiling with 40-byte tiles (0x20009e0 = 40), allowing large images to be processed in chunks.

4. **Operator registration**: Graphics operators are registered in batches, with this module handling core graphics state operators.

5. **Memory alignment**: Rendering buffers are carefully aligned using masks (0x20221e0) for hardware efficiency.

The code in this range implements core PostScript graphics state management with hardware acceleration support for the Agfa 9000PS RIP's specialized rendering hardware.

; === CHUNK 34: 0x58C00-0x59800 ===

### 1. **Function at 0x58C00** (hardware callback wrapper)
- **Entry**: 0x58C00
- **Name**: `hw_callback_18`
- **Purpose**: Calls hardware acceleration callback at offset 0x18 in the callback table (0x20221EC). This is a simple wrapper that pushes 11 parameters from the stack and calls the hardware function.
- **Arguments**: 11 longword parameters on stack (fp@(8) through fp@(48))
- **Return value**: Whatever the hardware callback returns (in D0)
- **RAM access**: 0x20221EC (hardware callback table base)
- **Call target**: Indirect call through callback table offset 0x18
- **Key behavior**: 
  - No LINK instruction (unusual for C code - suggests hand-written assembly)
  - Pushes 11 parameters (44 bytes) in reverse order  (C calling convention — stack args)
  - Calls hardware function via callback table
  - Cleans up stack (44 bytes) and returns

### 2. **Function at 0x58C26** (hardware callback wrapper)
- **Entry**: 0x58C26
- **Name**: `hw_callback_10`
- **Purpose**: Calls hardware acceleration callback at offset 0x10 in the callback table. Takes 12 parameters.
- **Arguments**: 12 longword parameters on stack (fp@(8) through fp@(52))
- **Return value**: Whatever the hardware callback returns
- **RAM access**: 0x20221EC (hardware callback table)
- **Call target**: Indirect call through callback table offset 0x10
- **Key behavior**: 
  - Uses LINK A6,#0 (standard C convention)
  - Calls 0x18856 first (likely some setup/validation)
  - Pushes 12 parameters (48 bytes)  (C calling convention — stack args)
  - Calls hardware function, cleans up stack, returns

### 3. **Function at 0x58C72** (hardware callback wrapper)
- **Entry**: 0x58C72
- **Name**: `hw_callback_14`
- **Purpose**: Calls hardware acceleration callback at offset 0x14 in the callback table. Takes 13 parameters.
- **Arguments**: 13 longword parameters on stack (fp@(8) through fp@(56))
- **Return value**: Whatever the hardware callback returns
- **RAM access**: 0x20221EC (hardware callback table)
- **Call target**: Indirect call through callback table offset 0x14
- **Key behavior**: 
  - Similar to 0x58C26 but with 13 parameters (52 bytes)
  - Also calls 0x18856 first

### 4. **Function at 0x58CC2** (render/flush function)
- **Entry**: 0x58CC2
- **Name**: `flush_graphics` or `render_complete`
- **Purpose**: Flushes pending graphics operations to hardware. Checks software rendering flag, processes pending operations in a loop, calls hardware completion callback.
- **Arguments**: None
- **Return value**: None
- **RAM access**: 
  - 0x20009E4 (SW/HW rendering flag)  (PS dict operator)
  - 0x20009D4 (pending operations count)  (PS dict operator)
  - 0x20221E8 (some threshold/flag)
  - 0x20221EC (hardware callback table)
- **Calls**: 
  - 0x28250 (if software rendering flag is set)  (PS dict operator)
  - 0x444F4 (in loop)
  - 0x58814 (process one operation)
  - 0x44518 (after loop)
  - Hardware callback offset 0x34  struct field
- **Key algorithm**:
  1. Check if software rendering flag at 0x20009E4 is non-zero
  2. If so, call 0x28250 with the flag value
  3. Check pending operations count at 0x20009D4
  4. While count > 0:
     - Call 0x58814 with parameter 0 (process one operation)
     - Compare result with threshold at 0x20221E8
     - If not equal, call 0x444F4 and continue loop
  5. Call 0x44518
  6. Call hardware completion callback at offset 0x34

### 5. **Function at 0x58D16** (hardware callback wrapper)
- **Entry**: 0x58D16
- **Name**: `hw_callback_3c`
- **Purpose**: Calls hardware acceleration callback at offset 0x3C in the callback table. Takes 6 parameters.
- **Arguments**: 6 longword parameters on stack (fp@(8) through fp@(28))
- **Return value**: Whatever the hardware callback returns
- **RAM access**: 0x20221EC (hardware callback table)
- **Call target**: Indirect call through callback table offset 0x3C
- **Key behavior**: 
  - Similar pattern to other wrappers
  - Calls 0x18856 first (setup/validation)
  - Pushes 6 parameters (24 bytes)  (C calling convention — stack args)
  - Calls hardware function, cleans up stack, returns

### 6. **Function at 0x58D4A** (graphics state save/restore)
- **Entry**: 0x58D4A
- **Name**: `save_graphics_state` or `gsave_implementation`
- **Purpose**: Saves current graphics state to a stack. Checks if there's a graphics state stack (0x20009D8), and if so, copies current state from 0x2017368 to the current stack frame at 0x2001ED8.
- **Arguments**: None
- **Return value**: Returns a value from 0x1459C (likely a success/failure code)
- **RAM access**: 
  - 0x20009D8 (graphics state stack flag)
  - 0x2001ED8 (current graphics state pointer)
  - 0x2017368 (global graphics state structure)
- **Calls**: 0x1459C (get current context?)
- **Key algorithm**:
  1. Call 0x1459C, store result in local variable
  2. Check if graphics state stack exists (0x20009D8)
  3. If stack exists:
     - Copy various fields from global state (0x2017368) to current stack frame (0x2001ED8)
     - Fields copied: offset 0xB4 to offset 0x50, 0xA4 to 0x40, 0xA8 to 0x44  struct field
     - Copy 22 longwords (88 bytes) from offset 0x64 of global state to stack frame  struct field
  4. Return the value from 0x1459C

### 7. **Function at 0x58DB6** (graphics state pop)
- **Entry**: 0x58DB6
- **Name**: `pop_graphics_state` or `grestore_implementation`
- **Purpose**: Pops a graphics state from the stack by decrementing the stack counter and calling a helper function.
- **Arguments**: None
- **Return value**: None
- **RAM access**: 0x2001ED4 (graphics state stack counter)
- **Calls**: 0x2867A (restore graphics state from stack)
- **Key behavior**:
  1. Decrement graphics state stack counter at 0x2001ED4
  2. Call 0x2867A to restore state from stack
  3. Return

### 8. **Function at 0x58DCA** (graphics state push setup)
- **Entry**: 0x58DCA
- **Name**: `push_graphics_state_setup`
- **Purpose**: Sets up pointers for a new graphics state on the stack before pushing. Calculates memory addresses for current and previous stack frames.
- **Arguments**: None
- **Return value**: None
- **RAM access**: 
  - 0x2001ED4 (graphics state stack counter)
  - 0x2001ED8 (current graphics state pointer)
  - 0x2001EDC (previous graphics state pointer)
- **Calls**: 0x286A0 (initialize new graphics state?)
- **Key algorithm**:
  1. Calculate offset = (counter - 1) × 108 bytes (0x6C)
  2. Set 0x2001ED8 = 0x2001954 + offset (current frame)
  3. Set 0x2001EDC = 0x20019AC + offset (previous frame)
  4. Call 0x286A0 (likely initializes the new state)
  5. Return

### 9. **Function at 0x58E18** (graphics state push complete)
- **Entry**: 0x58E18
- **Name**: `push_graphics_state_complete`
- **Purpose**: Completes pushing a new graphics state onto the stack. Sets up function pointers and copies state data.
- **Arguments**: 5 parameters on stack (likely transformation matrix components)
- **Return value**: None
- **RAM access**: 
  - 0x2001ED4 (graphics state stack counter)
  - 0x2001ED8 (current graphics state pointer)
  - 0x2001EDC (previous graphics state pointer)
  - 0x2017368 (global graphics state structure)
- **Calls**: 0x286C6 (apply transformation?)
- **Key algorithm**:
  1. Calculate offset = counter × 108 bytes (0x6C)
  2. Set 0x2001ED8 = 0x2001954 + offset
  3. Set 0x2001EDC = 0x20019AC + offset
  4. Increment stack counter
  5. Copy 22 longwords (88 bytes) from global state offset 0x64 to previous frame
  6. Call 0x286C6 with 5 parameters (apply transformation matrix)
  7. Set up numerous function pointers in the graphics state structure:
     - 0x58D4A -> offset 0x9C (156)  struct field
     - 0x58CC2 -> offset 0x98 (152)  struct field
     - 0x58DB6 -> offset 0xA4 (164)  struct field
     - 0x58DCA -> offset 0xA8 (168)  struct field
     - Plus 10+ other function pointers at various offsets  struct field
  8. Copy 22 longwords back from current frame to global state offset 0x64

### 10. **Function at 0x58FDA** (initialize 2D vector)
- **Entry**: 0x58FDA (actually starts at 0x58FDC after data)
- **Name**: `init_vector_2d`
- **Purpose**: Initializes a 2D vector structure with default values (1.0 in Z component, 0 in X and Y).
- **Arguments**: A0 = pointer to vector structure
- **Return value**: None
- **RAM access**: None
- **Key behavior**:
  1. Sets vector.z = 1.0 (0x3F800000 in IEEE 754)
  2. Sets vector.x = vector.z (so x = 1.0)
  3. Sets vector.y = 0
  4. Sets vector.dx = vector.y (so dx = 0)
  5. Sets vector.dy = vector.dx (so dy = 0)
  - Note: This appears to initialize a homogeneous coordinate vector  coordinate data  (font metric data)

### 11. **Function at 0x5901A** (initialize 2D point)
- **Entry**: 0x5901A
- **Name**: `init_point_2d`
- **Purpose**: Initializes a 2D point structure with given X and Y coordinates, Z=1.0.
- **Arguments**: 
  - fp@(8): X coordinate pointer  coordinate data  (font metric data)
  - fp@(12): Y coordinate pointer  coordinate data  (font metric data)
  - fp@(16): Point structure pointer  stack frame parameter
- **Return value**: None
- **RAM access**: None
- **Key behavior**:
  1. Sets point.z = 1.0 (0x3F800000)
  2. Sets point.x = point.z (x = 1.0 initially)
  3. Sets point.y = 0
  4. Sets point.dx = point.y (dx = 0)
  5. Sets point.dy = point.dx (dy = 0)
  6. Copies actual X from parameter to point.x
  7. Copies actual Y from parameter to point.y

### 12. **Function at 0x5905C** (initialize 2D point with Z)
- **Entry**: 0x5905C
- **Name**: `init_point_2d_with_z`
- **Purpose**: Initializes a 2D point structure with given X, Y, and Z coordinates.
- **Arguments**:
  - fp@(8): X coordinate pointer  coordinate data  (font metric data)
  - fp@(12): Y coordinate pointer  coordinate data  (font metric data)
  - fp@(16): Point structure pointer  stack frame parameter
- **Return value**: None
- **RAM access**: None
- **Key behavior**:
  1. Copies X coordinate to point.x
  2. Sets point.y = 0
  3. Sets point.dx = point.y (dx = 0)
  4. Sets point.dy = point.dx (dy = 0)
  5. Copies Y coordinate to point.z
  - Note: This seems to use Z field for Y coordinate, which is unusual  coordinate data  (font metric data)

### 13. **Function at 0x5909C** (convert integer to floating matrix)
- **Entry**: 0x5909C
- **Name**: `int_to_float_matrix`
- **Purpose**: Converts an integer value to a floating-point transformation matrix. Handles special cases for common angles.
- **Arguments**:
  - fp@(8): Input integer pointer  stack frame parameter
  - fp@(12): Output matrix pointer (6×4 bytes = 24 bytes)  stack frame parameter
- **Return value**: None
- **RAM access**: None
- **Calls**: Various floating-point routines at 0x899xx
- **Key algorithm**:
  1. Check if input is negative, handle two's complement if needed
  2. Convert integer to float
  3. If value < 90°, use fast path with precomputed sin/cos tables
  4. Otherwise, compute sin and cos using floating-point math
  5. Build 2D rotation matrix: [[cos, -sin], [sin, cos]]
  6. Store in output structure with additional fields set to 0

### 14. **Function at 0x591B0** (matrix multiplication)
- **Entry**: 0x591B0
- **Name**: `multiply_matrices_2d`
- **Purpose**: Multiplies two 2D transformation matrices (3×3 in homogeneous coordinates).
- **Arguments**:
  - fp@(8): First matrix pointer  stack frame parameter
  - fp@(12): Second matrix pointer  stack frame parameter
  - fp@(16): Result matrix pointer  stack frame parameter
- **Return value**: D2 preserved
- **RAM access**: None
- **Calls**: Floating-point multiply and add routines at 0x899xx
- **Key algorithm**:
  1. Performs full 3×3 matrix multiplication for homogeneous coordinates
  2. Computes each element as sum of products
  3. Handles all 9 elements (though structure appears to have 6 fields)
  4. Stores result in output structure

### 15. **Function at 0x59364** (matrix comparison)
- **Entry**: 0x59364
- **Name**: `compare_matrices_2d`
- **Purpose**: Compares two 2D transformation matrices for equality within tolerance.
- **Arguments**:
  - fp@(8): First matrix pointer  stack frame parameter
  - fp@(12): Second matrix pointer  stack frame parameter
- **Return value**: D0 = 1 if equal, 0 if not equal
- **RAM access**: None
- **Calls**: Floating-point comparison routines at 0x899xx
- **Key algorithm**:
  1. Compares each of the 6 matrix elements (floats)
  2. For each element, checks if |a-b| < epsilon
  3. Uses epsilon values stored in code (likely 1e-6)
  4. Returns 1 only if all elements are within tolerance

### 16. **Function at 0x595C2** (matrix inversion)
- **Entry**: 0x595C2
- **Name**: `invert_matrix_2d`
- **Purpose**: Inverts a 2D transformation matrix. Uses caching for performance.
- **Arguments**:
  - fp@(8): Input matrix pointer  stack frame parameter
  - fp@(12): Output matrix pointer  stack frame parameter
- **Return value**: None
- **RAM access**: 
  - 0x2001EE0-0x2001EF4 (cached input matrix)
  - 0x2001EF8-0x2001F0C (cached inverse matrix)
- **Calls**: Floating-point arithmetic routines at 0x899xx
- **Key algorithm**:
  1. Check if input matches cached matrix at 0x2001EE0
  2. If match, copy cached inverse from 0x2001EF8
  3. Otherwise, compute inverse:
     - Calculate determinant
     - Handle near-zero determinant case
     - Compute adjugate matrix divided by determinant
     - Cache both input and result
  4. Copy result to output

2. **Function at 0x58D4A**: Prior analysis called this "render/flush" but it's actually graphics state save/restore (gsave implementation).

4. **Function at 0x58DCA and 0x58E18**: These work together to push graphics states onto a stack.

6. **Functions 0x5909C-0x595C2**: These are floating-point matrix operations (conversion, multiplication, comparison, inversion) that prior analysis didn't identify.

7. **The region contains significant floating-point math code** for 2D transformations, which makes sense for a PostScript interpreter handling coordinate transformations.

This region (0x58C00-0x59800) contains:
1. **Hardware acceleration wrappers** (0x58C00-0x58D48)
2. **Graphics state stack management** (0x58D4A-0x58E18) for gsave/grestore
3. **2D vector/matrix utilities** (0x58FDA-0x595C2) for coordinate transformations

The matrix operations are crucial for PostScript's coordinate system transformations. The caching in the matrix inversion function (0x595C2) is a performance optimization since matrices are frequently inverted during rendering.

; === CHUNK 35: 0x59800-0x5A400 ===

**0x59800-0x5980D:** Uninitialized data or padding (contains `51c8 fffc` which is a `dbf` instruction but appears to be leftover data)

**0x5980E-0x59815:** Floating-point constant `3FF0000000000000` (1.0 in IEEE double-precision)

**0x5A2D8-0x5A2EB:** Floating-point constants for matrix operations:
- 0x5A2D8: `00000000 3F800000` (1.0 as float)
- 0x5A2E0: `00000000 BF800000` (-1.0 as float)
- 0x5A2E8: `00000005 A34C` (likely a pointer or small data)

**0x5A2F0-0x5A344:** PostScript operator dispatch table (11 entries, 4 bytes each):
- 0x5A2F0: `0005 9B92` → `initmatrix` (0x59B92)
- 0x5A2F4: `0005 A353` → operator name "matrix" (0x5A353)
- 0x5A2F8: `0005 9BC2` → `defaultmatrix` (0x59BC2)  (PS dict operator)
- 0x5A2FC: `0005 A35F` → operator name "defaultmatrix" (0x5A35F)  (PS dict operator)
- 0x5A300: `0005 9BEE` → `concatmatrix` (0x59BEE)  (PS CTM operator)
- 0x5A304: `0005 A36C` → operator name "concatmatrix" (0x5A36C)  (PS CTM operator)
- 0x5A308: `0005 9C38` → `invertmatrix` (0x59C38)
- 0x5A30C: `0005 A379` → operator name "invertmatrix" (0x5A379)
- 0x5A310: `0005 9C72` → `translate` (0x59C72)  (PS CTM operator)
- 0x5A314: `0005 A383` → operator name "translate" (0x5A383)  (PS CTM operator)
- 0x5A318: `0005 9CEC` → `scale` (0x59CEC)  (PS CTM operator)
- 0x5A31C: `0005 A389` → operator name "scale" (0x5A389)  (PS CTM operator)
- 0x5A320: `0005 9D66` → `rotate` (0x59D66)  (PS CTM operator)
- 0x5A324: `0005 A390` → operator name "rotate" (0x5A390)  (PS CTM operator)
- 0x5A328: `0005 A088` → `transform` (0x5A088)
- 0x5A32C: `0005 A39A` → operator name "transform" (0x5A39A)
- 0x5A330: `0005 A10C` → `itransform` (0x5A10C)
- 0x5A334: `0005 A3A5` → operator name "itransform" (0x5A3A5)
- 0x5A338: `0005 A190` → `dtransform` (0x5A190)
- 0x5A33C: `0005 A3B0` → operator name "dtransform" (0x5A3B0)
- 0x5A340: `0005 A214` → `idtransform` (0x5A214)
- 0x5A344: `0005 A3B6` → operator name "idtransform" (0x5A3B6)

**0x5A34C-0x5A3B6:** PostScript operator name strings (null-terminated):
- 0x5A34C: "matrix"
- 0x5A353: "defaultmatrix"  (PS dict operator)
- 0x5A35F: "concatmatrix"  (PS CTM operator)
- 0x5A36C: "invertmatrix"
- 0x5A379: "translate"  (PS CTM operator)
- 0x5A383: "scale"  (PS CTM operator)
- 0x5A389: "rotate"  (PS CTM operator)
- 0x5A390: "transform"
- 0x5A39A: "itransform"
- 0x5A3A5: "dtransform"
- 0x5A3B0: "idtransform"

### FUNCTIONS:

#### 1. 0x59816: `store_matrix_element`
**Purpose:** Stores a matrix element based on type. Checks low nibble of first argument: 1=float (calls 0x89A10 to convert to integer), 2=integer (stores directly). Used by matrix conversion functions to handle both float and integer matrix elements.
**Arguments:** Type in low nibble of byte at fp+8, value at fp+12, destination pointer at fp+16
**Hardware:** Calls 0x89A10 (float-to-integer conversion routine)
**Cross-refs:** Called from 0x598EE (convert_matrix_to_device_coords) at 0x5994C, 0x59972, 0x59998, 0x599C0, 0x599E8, 0x59A10

#### 2. 0x59856: `read_matrix_from_memory`
**Purpose:** Reads a 6-element matrix (24 bytes) from memory by calling 0x4C218 six times with increasing offsets (0, 4, 8, 12, 16, 20). Stores results in a 6-element array. This is a utility function for reading matrix data from arbitrary memory locations.
**Arguments:** Source address at fp+8, destination array at fp+12
**Hardware:** Calls 0x4C218 (memory read function) six times
**Cross-refs:** Not directly called in this chunk, but likely used elsewhere in matrix operations

#### 3. 0x598EE: `convert_matrix_to_device_coords`
**Purpose:** Converts a PostScript matrix to device coordinates. Validates matrix type (9 or 13 in low nibble) and size (must be 6 elements). Uses 0x46AEC for coordinate transformation, then calls `store_matrix_element` for each of the 6 elements. Handles the full 3×3 transformation matrix conversion.
**Arguments:** Source matrix at fp+8, destination at fp+12
**Hardware:** Calls 0x46AEC (coordinate transform), 0x463D6 (typecheck error), 0x463BA (rangecheck error)
**Cross-refs:** Called from 0x59B66 (within `get_current_matrix`)

#### 4. 0x59A20: `apply_matrix_to_device`
**Purpose:** Applies a matrix transformation to device coordinates. Validates matrix type (must be 9) and size (6 elements). Calls 0x47310 six times (once per matrix element) with different selector values (0-5). This performs the actual matrix multiplication for coordinate transformation.
**Arguments:** Source coordinates at fp+8, matrix at fp+12, destination at fp+16
**Hardware:** Calls 0x47310 (matrix apply function), accesses 0x20008F8 (device state byte)
**Cross-refs:** Called from 0x59B7C (within `set_current_matrix`)

#### 5. 0x59B4E: `get_current_matrix`
**Purpose:** Gets the current transformation matrix by calling 0x3BA8E and converts it to device coordinates via `convert_matrix_to_device_coords`. Returns the matrix in a form suitable for device rendering.
**Arguments:** Destination buffer at fp+8
**Hardware:** Calls 0x3BA8E (get current matrix)
**Cross-refs:** Called from 0x59C02, 0x59C0C, 0x5A0B8

#### 6. 0x59B70: `set_current_matrix`
**Purpose:** Sets the current transformation matrix by applying it to device coordinates then calling 0x365AA. This is the inverse operation of `get_current_matrix`.
**Arguments:** Matrix at fp+8, destination at fp+12
**Hardware:** Calls 0x365AA (set matrix function)
**Cross-refs:** Called from 0x59BBA, 0x59C32, 0x59CC6, 0x59D40, 0x59DB4

#### 7. 0x59B92: `initmatrix` (PostScript operator)
**Purpose:** PostScript `initmatrix` operator implementation. Gets identity matrix via 0x47FFE, pushes it via 0x58FDC, then sets it as current. Resets the current transformation matrix to identity.
**Hardware:** Calls 0x47FFE (get identity), 0x58FDC (push matrix)
**Cross-refs:** PostScript operator table at 0x5A2F0

#### 8. 0x59BC2: `defaultmatrix` (PostScript operator)
**Purpose:** PostScript `defaultmatrix` operator. Gets default matrix via 0x3BA8E, pushes it, then sets it as current. Restores the default transformation matrix.
**Hardware:** Calls 0x3BA8E (get default matrix)
**Cross-refs:** PostScript operator table at 0x5A2F8

#### 9. 0x59BEE: `concatmatrix` (PostScript operator)
**Purpose:** PostScript `concatmatrix` operator. Concatenates two matrices (current and operand) by calling 0x191B8 (matrix multiplication), then sets the result as current. Performs matrix multiplication: C = A × B.
**Arguments:** Two matrices on operand stack
**Hardware:** Calls 0x191B8 (matrix multiply)
**Cross-refs:** PostScript operator table at 0x5A300

#### 10. 0x59C38: `invertmatrix` (PostScript operator)
**Purpose:** PostScript `invertmatrix` operator. Inverts the current transformation matrix by calling 0x195BE (matrix inversion), then sets the inverse as current. Computes the matrix inverse for coordinate transformations.
**Arguments:** Matrix on operand stack
**Hardware:** Calls 0x195BE (matrix invert)
**Cross-refs:** PostScript operator table at 0x5A308

#### 11. 0x59C72: `translate` (PostScript operator)
**Purpose:** PostScript `translate` operator. Applies translation to the current matrix. If matrix is type 9, performs specialized translation; otherwise calls 0x15406 (general translation). Handles both device and user space translations.
**Arguments:** dx, dy on operand stack
**Hardware:** Calls 0x3677E, 0x365F8, 0x3BCE8, 0x1901A, 0x15406
**Cross-refs:** PostScript operator table at 0x5A310

#### 12. 0x59CEC: `scale` (PostScript operator)
**Purpose:** PostScript `scale` operator. Applies scaling to the current matrix. If matrix is type 9, performs specialized scaling; otherwise calls 0x1545E (general scaling). Handles uniform and non-uniform scaling.
**Arguments:** sx, sy on operand stack
**Hardware:** Calls 0x3677E, 0x365F8, 0x3BCE8, 0x1905C, 0x1545E
**Cross-refs:** PostScript operator table at 0x5A318

#### 13. 0x59D66: `rotate` (PostScript operator)
**Purpose:** PostScript `rotate` operator. Applies rotation to the current matrix. If matrix is type 9, performs specialized rotation; otherwise calls 0x15486 (general rotation). Handles angle in degrees.
**Arguments:** angle on operand stack
**Hardware:** Calls 0x3677E, 0x365F8, 0x3B81A, 0x1909C, 0x15486
**Cross-refs:** PostScript operator table at 0x5A320

#### 14. 0x59DD8: `matrix_multiply_accumulate`
**Purpose:** Performs matrix multiplication with accumulation: result = (A × B) + C. Used internally for transformation calculations. Handles 2×2 matrices with translation components.
**Arguments:** A at fp+8, B at fp+12, C at fp+16, result at fp+20
**Hardware:** Calls 0x89A70 (multiply), 0x89938 (add)
**Cross-refs:** Called from 0x59E7A, 0x59F60, 0x59FC0

#### 15. 0x59E7A: `transform_points` (PostScript operator helper)
**Purpose:** Transforms points using matrix multiplication and stores result at 0x2001F10. Wrapper for `matrix_multiply_accumulate` that stores results in a fixed memory location.
**Arguments:** x at fp+8, y at fp+12, matrix at fp+16
**Return:** Pointer to result in D0 (0x2001F10)
**Hardware:** Writes to 0x2001F10-0x2001F18
**Cross-refs:** Called from transform operator implementations

#### 16. 0x59EAE: `matrix_multiply_no_accumulate`
**Purpose:** Performs matrix multiplication without accumulation: result = A × B. Similar to `matrix_multiply_accumulate` but without the additive term.
**Arguments:** A at fp+8, B at fp+12, C at fp+16, result at fp+20
**Hardware:** Calls 0x89A70 (multiply), 0x89938 (add)
**Cross-refs:** Called from 0x59F2C

#### 17. 0x59F2C: `itransform_points` (PostScript operator helper)
**Purpose:** Inverse transform points using matrix multiplication and stores result at 0x2001F18. Wrapper for `matrix_multiply_no_accumulate`.
**Arguments:** x at fp+8, y at fp+12, matrix at fp+16
**Return:** Pointer to result in D0 (0x2001F18)
**Hardware:** Writes to 0x2001F18-0x2001F20
**Cross-refs:** Called from itransform operator implementations

#### 18. 0x59F60: `transform_with_translation`
**Purpose:** Transforms points with explicit translation component. First inverts a matrix, then applies `matrix_multiply_accumulate`.
**Arguments:** x at fp+8, y at fp+12, matrix1 at fp+16, matrix2 at fp+20
**Hardware:** Calls 0x195BE (matrix invert), 0x59DD8 (matrix_multiply_accumulate)
**Cross-refs:** Called from 0x59F8E

#### 19. 0x59F8E: `dtransform_points` (PostScript operator helper)
**Purpose:** Delta transform points and stores result at 0x2001F20. Wrapper for `transform_with_translation`.
**Arguments:** x at fp+8, y at fp+12, matrix at fp+16
**Return:** Pointer to result in D0 (0x2001F20)
**Hardware:** Writes to 0x2001F20-0x2001F28
**Cross-refs:** Called from dtransform operator implementations

#### 20. 0x59FC0: `transform_with_matrix_copy`
**Purpose:** Transforms points with matrix copy and translation. Copies matrix, clears translation, inverts, then applies `matrix_multiply_accumulate`.
**Arguments:** x at fp+8, y at fp+12, matrix at fp+16, result at fp+20
**Hardware:** Calls 0x195BE (matrix invert), 0x59DD8 (matrix_multiply_accumulate)
**Cross-refs:** Called from 0x5A006

#### 21. 0x5A006: `idtransform_points` (PostScript operator helper)
**Purpose:** Inverse delta transform points and stores result at 0x2001F28. Wrapper for `transform_with_matrix_copy`.
**Arguments:** x at fp+8, y at fp+12, matrix at fp+16
**Return:** Pointer to result in D0 (0x2001F28)
**Hardware:** Writes to 0x2001F28-0x2001F30
**Cross-refs:** Called from idtransform operator implementations

#### 22. 0x5A038: `apply_affine_transform`
**Purpose:** Applies affine transformation: x' = a*x + c*y + tx, y' = b*x + d*y + ty. Optimized integer arithmetic for device coordinates.
**Arguments:** x at fp+8, y at fp+12, matrix at fp+16, result at fp+20
**Hardware:** Uses MULS.L for 32-bit multiplication
**Cross-refs:** Called from transform operator implementations

#### 23. 0x5A088: `transform` (PostScript operator)
**Purpose:** PostScript `transform` operator. Transforms a point using the current matrix. Handles both regular and device matrices.
**Arguments:** x, y on operand stack
**Return:** Transformed x, y on stack
**Hardware:** Calls 0x3677E, 0x3BA8E, 0x3BCE8, 0x59DD8, 0x15502, 0x3BDE2
**Cross-refs:** PostScript operator table at 0x5A328

#### 24. 0x5A10C: `itransform` (PostScript operator)
**Purpose:** PostScript `itransform` operator. Inverse transforms a point using the current matrix.
**Arguments:** x, y on operand stack
**Return:** Inverse transformed x, y on stack
**Hardware:** Calls 0x3677E, 0x3BA8E, 0x3BCE8, 0x59EAE, 0x15526, 0x3BDE2
**Cross-refs:** PostScript operator table at 0x5A330

#### 25. 0x5A190: `dtransform` (PostScript operator)
**Purpose:** PostScript `dtransform` operator. Transforms a distance vector (ignoring translation).
**Arguments:** dx, dy on operand stack
**Return:** Transformed dx, dy on stack
**Hardware:** Calls 0x3677E, 0x3BA8E, 0x3BCE8, 0x59F60, 0x1554A, 0x3BDE2
**Cross-refs:** PostScript operator table at 0x5A338

#### 26. 0x5A214: `idtransform` (PostScript operator)
**Purpose:** PostScript `idtransform` operator. Inverse transforms a distance vector.
**Arguments:** dx, dy on operand stack
**Return:** Inverse transformed dx, dy on stack
**Hardware:** Calls 0x3677E, 0x3BA8E, 0x3BCE8, 0x59FC0, 0x1556E, 0x3BDE2
**Cross-refs:** PostScript operator table at 0x5A340

#### 27. 0x5A298: `set_matrix_type`
**Purpose:** Sets matrix type based on argument. If 0, pushes identity matrices; if 1, calls error handler.
**Arguments:** type at fp+8
**Hardware:** Calls 0x58FDC (push matrix), 0x469FA (error handler)
**Cross-refs:** Likely used for matrix initialization

#### 28. 0x5A3C2: `push_matrix` (wrapper)
**Purpose:** Wrapper for 0x58FDC to push matrix onto operand stack.
**Arguments:** matrix pointer at fp+8
**Hardware:** Calls 0x58FDC
**Cross-refs:** Simple wrapper function

#### 29. 0x5A3D0: `init_identity_matrix`
**Purpose:** Initializes a matrix structure as identity matrix (sets all cross-diagonal elements to 0, diagonal to 1).
**Arguments:** matrix pointer at fp+8
**Cross-refs:** Matrix initialization utility

#### 30. 0x5A3F8: `empty_function`
**Purpose:** Empty function (just returns). May be a placeholder or stub.
**Cross-refs:** Likely unused or placeholder

### CORRECTIONS TO PRIOR ANALYSIS:

1. **0x59800-0x5980D is DATA, not CODE**: The `dbf` instruction at 0x59800 is actually data, not executable code. This is padding or leftover data.

3. **Matrix operator implementations**: The chunk contains the full set of PostScript matrix operators: `initmatrix`, `defaultmatrix`, `concatmatrix`, `invertmatrix`, `translate`, `scale`, `rotate`, `transform`, `itransform`, `dtransform`, `idtransform`.

4. **Memory locations**: Several functions store results at fixed memory locations (0x2001F10, 0x2001F18, 0x2001F20, 0x2001F28) which are likely global transformation result buffers.

5. **Error handling**: Functions call standard error handlers (0x463D6 for typecheck, 0x463BA for rangecheck) when matrix validation fails.

This region is primarily focused on PostScript matrix and transformation operations, which are critical for graphics rendering in the PostScript interpreter.

; === CHUNK 36: 0x5A400-0x5B000 ===

### 1. 0x5A400: `return_false`
**Purpose:** Returns boolean false (0). Simple helper function.
**Return:** D0 = 0
### 2. 0x5A40A: `return_true`
**Purpose:** Returns boolean true (1). Simple helper function.
**Return:** D0 = 1
### 3. 0x5A414: `trigger_rangecheck_error`
**Purpose:** Triggers a PostScript rangecheck error by calling the error handler at 0x46382.
**Call targets:** 0x46382 (rangecheck error handler)
**Called by:** Functions in this pool management system when out of free blocks

### 4. 0x5A422: `init_pool_structures`
**Purpose:** Initializes the pool management data structures at 0x2001F30-0x2001F88. Sets up function pointers and creates circular linked list relationships between pool entries.
**Hardware/RAM:** Writes to 0x2001F30-0x2001F88
- Clears 0x2001F80-0x2001F86 (6 bytes)
- Sets function pointers at various offsets (0x5A3BC, 0x5A3D0, 0x5A40A, 0x5A400, 0x5A414, 0x5A3F8)  struct field
- Creates circular references: each entry points to the next, forming a complete circle
**Note:** This appears to be setting up callback functions for the pool management system.

### 5. 0x5A438: `dispatch_pool_init`
**Purpose:** Dispatches to either `init_pool_structures` (0x5A422) or `register_null_device` (0x5A522) based on argument.
**Arguments:** D0 = argument (0 or 1)
**Call targets:** 0x5A422 (if D0=0), 0x5A522 (if D0=1)
**Algorithm:** If D0=0, calls init_pool_structures; if D0=1, calls register_null_device; otherwise returns.

### 6. 0x5A522: `register_null_device`
**Purpose:** Registers a "null" device handler by pushing two function pointers to a registration function at 0x46948.
**Call targets:** 0x46948 (device registration function)
**Data:** String "null" at 0x5A536-0x5A541 (6 bytes: "null" + null terminator)
**Note:** This is the actual device registration, separate from pool management.

### 7. 0x5A546: `init_memory_pool`
**Purpose:** Initializes a free list of 24-byte blocks starting at index 0x8C94 (-29548). Creates linked list entries in the pool array at 0x2017F68.
- Sets 0x2001F88 (free list head) to 0x8C94
- Builds linked list in 0x2017F68+ (pool array)  (data structure manipulation)
1. Set initial index to 0x8C94
2. While index != 0:
   - Calculate block address = 0x2017F68 + index  (filesystem block calculation)
   - Set block's "next" field (offset 8) to current index - 12  struct field
   - Continue until index reaches 0
**Structure:** Each block is 24 bytes (0x18), with "next" pointer at offset 8.

### 8. 0x5A580: `clear_memory_block`
**Purpose:** Clears/initializes a 24-byte memory block structure to zero/default values.
**Arguments:** A0 = pointer to block (fp@8)
- 0x0: word - current index
- 0x2: word - previous index  
- 0x4: word - next index
- 0x6: long - data pointer 1 (min X bound?)
- 0xA: long - data pointer 2 (min Y bound?)
- 0xE: long - data pointer 3 (max X bound?)
- 0x12: long - data pointer 4 (max Y bound?)
- 0x16: byte - flag 1 (active/in-use?)
- 0x17: byte - flag 2 (dirty/needs processing?)

### 9. 0x5A5CC: `allocate_or_update_block`
**Purpose:** Main allocation function for the block pool. Allocates a new block or updates an existing one based on parameters.
- fp@8: target block pointer  stack frame parameter
- fp@12: X coordinate value  coordinate data  (font metric data)
- fp@16: Y coordinate value  coordinate data  (font metric data)
- fp@22: mode flag (0, 1, or 2)  stack frame parameter
**Call targets:** 0x5A580 (clear_memory_block), 0x5A80E (update_chain), 0x89980 (compare function)
1. If target block's flag at offset 0x16 is set, save current index, clear block, and update chain
2. If mode flag is 0 and target has a previous block (offset 0x2), check if that block is free
3. If free block found, use it; otherwise allocate from free list
4. If free list empty, trigger rangecheck error
5. Update block with new coordinates
6. If target is at graphics state + 44 (0x2017464 + 44), also update graphics state
7. Update min/max bounds based on comparisons
**Note:** This function manages a linked list of blocks with bounding box coordinates.

### 10. 0x5A79E: `insert_into_free_list`
**Purpose:** Inserts a block index into the free list at 0x2001F88.
**Arguments:** fp@10 = block index to insert
**Hardware/RAM:** Updates 0x2001F88 and the index array at 0x2017F70
**Algorithm:** Sets the block's next pointer in the index array to current free list head, then makes this block the new head.

### 11. 0x5A7C2: `release_block_chain`
**Purpose:** Releases an entire chain of blocks back to the free list.
**Arguments:** fp@8 = starting block pointer
**Call targets:** 0x5A79E (insert_into_free_list), 0x5A580 (clear_memory_block)
1. If block's flag at offset 0x16 is not set
2. Follow the chain through the "next" pointers (offset 0x8)
3. Insert each block index into free list
4. Clear the starting block

### 12. 0x5A80E: `update_chain`
**Purpose:** Updates an entire chain of blocks with new coordinate values.
- fp@10 = starting block index  stack frame parameter
- fp@12 = target block pointer  stack frame parameter
**Call targets:** 0x5A5CC (allocate_or_update_block)
**Algorithm:** Iterates through the chain using "next" pointers, calling allocate_or_update_block for each block with the new coordinates.

### 13. 0x5A858: `merge_blocks`
**Purpose:** Merges two blocks' bounding boxes together.
- fp@8 = destination block pointer  stack frame parameter
- fp@12 = source block pointer  stack frame parameter
**Call targets:** 0x5A580 (clear_memory_block), 0x5A80E (update_chain), 0x89980 (compare function)
1. If source block is empty, return
2. If destination block's flag at offset 0x16 is set, save state, clear it, and update chain
3. If destination has a previous block (offset 0x2) and it's not the same as current, handle chain updates
4. Copy source bounds to destination, expanding min/max as needed
5. OR together the flag bytes at offset 0x17
6. Clear source block

### 14. 0x5AA46: `scale_block_coordinates`
**Purpose:** Scales all coordinates in a block chain by given X and Y factors.
- fp@8 = block pointer  stack frame parameter
- fp@12 = X scale factor  (PS CTM operator)
- fp@16 = Y scale factor  (PS CTM operator)
**Call targets:** 0x5A580 (clear_memory_block), 0x5A80E (update_chain), 0x89938 (multiply function)
1. If block is empty or scale factors are 1.0 (0x10000 in fixed-point), return
2. If block's flag at offset 0x16 is set, save state, clear it, and update chain
3. Iterate through chain, multiplying all coordinate values by scale factors
4. Also scale the min/max bounds stored in the block itself

### 15. 0x5AB50: `copy_graphics_state_bounds`
**Purpose:** Copies bounding box from graphics state offset 50 to target block.
**Arguments:** fp@8 = target block pointer
**Hardware/RAM:** Reads from 0x2017464 + 50 (graphics state)
**Algorithm:** Copies 16 bytes (4 long words) from graphics state to target block.

### 16. 0x5AB70: `reset_device_bounds`
**Purpose:** Resets device bounds by clearing the block at graphics state offset 44.
**Call targets:** 0x5A7C2 (release_block_chain)
**Hardware/RAM:** Accesses 0x2017464 (graphics state)
1. Releases the block chain at graphics state + 44
2. Copies a flag from offset 164 to offset 67 in graphics state
3. Clears values at offsets 112 and 108 in graphics state

### 17. 0x5ABB6: `calculate_bounding_box`
**Purpose:** Calculates a bounding box from current graphics state.
**Call targets:** 0x5ABE2 (internal calculation), 0x3BDE2 (unknown function, twice)
**Algorithm:** Calls internal calculation function twice with different parameters.

### 18. 0x5ABE2: `calculate_bounding_box_internal`
**Purpose:** Internal bounding box calculation from graphics state coordinates.
**Arguments:** fp@8 = result pointer (16 bytes for min/max X/Y)
**Call targets:** 0x1554A (vector math), 0x89980 (compare function)
1. Checks if graphics state at offset 44 is initialized
2. Reads 4 coordinate pairs from graphics state offsets 50-62
3. Performs vector calculations on each pair
4. Finds min/max X and Y values across all points
5. Stores results in 4 long words: minX, maxX, minY, maxY

### 19. 0x5AD74: `update_bounds_simple`
**Purpose:** Updates bounds with a single X,Y coordinate pair.
- fp@8 = target block pointer  stack frame parameter
- fp@12 = X coordinate  coordinate data  (font metric data)
- fp@16 = Y coordinate  coordinate data  (font metric data)
- fp@22 = mode (0)  stack frame parameter
**Call targets:** 0x5A5CC (allocate_or_update_block)
**Algorithm:** Wrapper that calls allocate_or_update_block with mode 0.

### 20. 0x5AD92: `update_current_path_bounds`
**Purpose:** Updates current path bounds in graphics state.
**Call targets:** 0x3BCE8 (get current point), 0x19DD8 (path operation), 0x5AD74 (update_bounds_simple)
**Algorithm:** Gets current point, performs path operation, then updates bounds.

### 21. 0x5ADDC: `update_device_bounds`
**Purpose:** Updates device bounds in graphics state.
**Call targets:** 0x3BCE8 (get current point), 0x154C0 (device operation), 0x5AD74 (update_bounds_simple)
**Algorithm:** Similar to update_current_path_bounds but for device bounds.

### 22. 0x5AE48: `update_bounds_with_flag`
**Purpose:** Updates bounds with a single X,Y coordinate pair and mode flag.
- fp@8 = target block pointer  stack frame parameter
- fp@12 = X coordinate  coordinate data  (font metric data)
- fp@16 = Y coordinate  coordinate data  (font metric data)
- fp@22 = mode (1)  stack frame parameter
**Call targets:** 0x5A5CC (allocate_or_update_block)
**Algorithm:** Wrapper that calls allocate_or_update_block with mode 1.

### 23. 0x5AE76: `update_current_path_bounds_flag`
**Purpose:** Updates current path bounds with flag.
**Call targets:** 0x3BCE8 (get current point), 0x19DD8 (path operation), 0x5AE48 (update_bounds_with_flag)
**Algorithm:** Gets current point, performs path operation, then updates bounds with flag.

### 24. 0x5AEC0: `update_device_bounds_flag`
**Purpose:** Updates device bounds with flag.
**Call targets:** 0x3BCE8 (get current point), 0x154C0 (device operation), 0x5AE48 (update_bounds_with_flag)
**Algorithm:** Similar to update_current_path_bounds_flag but for device bounds.

### 25. 0x5AF1A: `update_bounds_three_points`
**Purpose:** Updates bounds with three X,Y coordinate pairs.
- fp@8,12 = point 1 (X,Y)  stack frame parameter
- fp@16,20 = point 2 (X,Y)  stack frame parameter
- fp@24,28 = point 3 (X,Y)  stack frame parameter
- fp@32 = target block pointer  stack frame parameter
**Call targets:** 0x5A5CC (allocate_or_update_block)
**Algorithm:** Calls allocate_or_update_block three times with mode 2 for each point.

### 26. 0x5AF78: `update_current_path_bounds_three_points`
**Purpose:** Updates current path bounds with three points.
**Call targets:** 0x3BCE8 (get current point, three times), 0x19DD8 (path operation), 0x5AF1A (update_bounds_three_points)
**Algorithm:** Gets three current points, performs path operations, then updates bounds with all three.

### 0x5A536-0x5A541: String "null"
**Content:** "null" + null terminator
**Used by:** register_null_device function

1. **Block Structure:** The 24-byte blocks form a linked list structure for managing bounding boxes in the graphics system.

2. **Three Update Modes:** The system uses modes 0, 1, and 2 for different types of bound updates (simple, with flag, three points).

3. **Graphics State Integration:** Many functions interact with the graphics state at 0x2017464, particularly offsets 44-62 for bounds management.

4. **Fixed-Point Math:** Coordinate values use fixed-point representation (0x10000 = 1.0).

5. **Error Handling:** Rangecheck errors are triggered when the free list is exhausted.

6. **Device vs Path Bounds:** Separate functions handle device bounds and current path bounds, indicating different coordinate spaces.

The code in this range implements a sophisticated bounding box management system for PostScript graphics operations, with efficient memory management through a block pool and linked list structures.

; === CHUNK 37: 0x5B000-0x5BC00 ===

### 1. Function at 0x5B000
**Entry address:** 0x5B000  
**Name:** `call_curve_operation`
**Purpose:** Simple wrapper that pushes 6 arguments from its stack frame onto the stack and calls the main curve operation at 0x1AF1A. The arguments are coordinate pairs (x1,y1,x2,y2,x3,y3) for curve operations.  
**Arguments:** 6 arguments in stack frame at offsets -4, -8, -12, -16, -20, -24 from FP (three coordinate pairs).  
**Return value:** Returns whatever 0x1AF1A returns.  
**Call targets:** 0x1AF1A (main curve operation).  
**Called by:** Unknown, likely PostScript curve operators.

### 2. Function at 0x5B024
**Entry address:** 0x5B024  
**Name:** `transform_and_call_curve`
**Purpose:** Loads transformation matrix data from global structure at 0x2017464+108, applies transformations to three coordinate pairs using 0x3BCE8 (coordinate transformation), then calls 0x154C0 three times (likely for matrix application), and finally calls the main curve operation at 0x1AF1A. This applies the current transformation matrix to curve control points before rendering.  
**Arguments:** Uses global PostScript interpreter structure at 0x2017464.  
**Return value:** Returns result from 0x1AF1A.  
**Hardware/RAM accessed:** 0x2017464 (global PostScript interpreter structure).  
**Call targets:** 0x3BCE8 (coordinate transformation), 0x154C0 (matrix application), 0x1AF1A (curve operation).  
**Called by:** PostScript curve operators after transformation.

### 3. Function at 0x5B0FC
**Entry address:** 0x5B0FC  
**Name:** `bezier_curve_subdivision`
**Purpose:** Implements recursive Bezier curve subdivision (de Casteljau algorithm) with floating-point math. Handles clockwise/counterclockwise curves based on flag at FP+40. The function: 1) Loads current transformation matrix, 2) Calculates curve parameters, 3) Performs recursive subdivision with flatness test, 4) Generates line segments for rendering. Contains loops for subdivision and calls to math routines for trigonometric calculations.  
**Arguments:** FP+8,12: first control point; FP+16,20: second; FP+24,28: third; FP+32,36: fourth?; FP+40: direction flag (0=CW, 1=CCW); FP+44: rendering context pointer.  
**Hardware/RAM accessed:** 0x2017464 (global structure), many math routines at 0x899xx (software FPU).  
**Call targets:** 0x1901A, 0x1905C, 0x1909C (vector math), 0x191B8 (matrix multiplication), 0x19DD8 (coordinate transformation), 0x1AD74, 0x1AE48 (line segment rendering), 0x1AF1A (curve operation).  
**Called by:** 0x1B664 (setup wrapper).

### 4. DATA REGION at 0x5B614-0x5B662 (FLOATING-POINT CONSTANTS)
**Address range:** 0x5B614-0x5B662  
**Format:** IEEE 754 double-precision floating-point constants (8 bytes each)  
- 0x5B614: 0x4056800000000000 = 90.0 (π/2 in degrees)
- 0x5B61C: 0xC056800000000000 = -90.0 (-π/2 in degrees)
- 0x5B624: 0x4076800000000000 = 360.0 (2π in degrees)
- 0x5B62C: 0x3F91DF46A2529D39 = ~0.017453292519943295 (π/180)
- 0x5B634: 0x4000000000000000 = 2.0
- 0x5B63C: 0x3FE1A9FBE76C8B44 = ~0.541196100146197 (cos(π/4)?)
- 0x5B644: 0xBFE1A9FBE76C8B44 = ~-0.541196100146197
- 0x5B64C: 0x3FF0000000000000 = 1.0
- 0x5B654: 0xBFF0000000000000 = -1.0
- 0x5B65C: 0x3FF555554C62AF22 = ~1.3333333333333333 (4/3)

**Note:** These are mathematical constants used by the curve subdivision algorithm, NOT code.

### 5. Function at 0x5B664
**Entry address:** 0x5B664  
**Name:** `setup_bezier_subdivision`
**Purpose:** Wrapper that prepares arguments for bezier_curve_subdivision. Calls 0x3B81A three times to get coordinate pairs, calls 0x3BCE8 for transformation, then converts coordinates to floating-point using 0x89A88 (integer to float conversion), and finally calls bezier_curve_subdivision.  
**Arguments:** FP+8: direction flag (0=CW, 1=CCW).  
**Hardware/RAM accessed:** 0x2017464 (global structure).  
**Call targets:** 0x3B81A (get coordinate), 0x3BCE8 (coordinate transformation), 0x89A88 (integer to float), 0x1B0FC (bezier_curve_subdivision).  
**Called by:** 0x1B6E6 and 0x1B6F8 (CCW and CW curve operators).

### 6. Function at 0x5B6E6
**Entry address:** 0x5B6E6  
**Name:** `draw_ccw_curve`
**Purpose:** Simple wrapper that pushes 1 (CCW direction) and calls setup_bezier_subdivision. Implements PostScript "curveto" operator for counterclockwise curves.  
**Call targets:** 0x1B664 (setup_bezier_subdivision).  
**Called by:** PostScript "curveto" operator.

### 7. Function at 0x5B6F8
**Entry address:** 0x5B6F8  
**Name:** `draw_cw_curve`
**Purpose:** Simple wrapper that pushes 0 (CW direction) and calls setup_bezier_subdivision. Implements PostScript "curveto" operator for clockwise curves.  
**Call targets:** 0x1B664 (setup_bezier_subdivision).  
**Called by:** PostScript "curveto" operator.

### 8. Function at 0x5B708
**Entry address:** 0x5B708  
**Name:** `calculate_atan2`
**Purpose:** Computes arctangent of y/x (atan2(y,x)) using floating-point math. Handles special cases for negative values and quadrant determination. Uses 0x4B990 for arctan calculation.  
**Arguments:** FP+8: x coordinate, FP+12: y coordinate.  
**Return value:** D0: floating-point result (angle in radians).  
**Hardware/RAM accessed:** Math routines at 0x899xx.  
**Call targets:** 0x89980 (float comparison), 0x89998 (float load), 0x89968 (float comparison), 0x89A88 (integer to float), 0x89A70 (float multiplication), 0x89938 (float division), 0x4B990 (arctan).  
**Called by:** 0x1B926 (arc calculation).

### 9. Function at 0x5B818
**Entry address:** 0x5B818  
**Name:** `calculate_hypotenuse`
**Purpose:** Computes hypotenuse sqrt(x² + y²) using floating-point math. Uses 0x89920 for square root calculation.  
**Arguments:** FP+8: x coordinate, FP+12: y coordinate.  
**Return value:** D0: floating-point result (distance).  
**Hardware/RAM accessed:** Math routines at 0x899xx.  
**Call targets:** 0x89980 (float comparison), 0x89998 (float load), 0x89920 (square root), 0x89A88 (integer to float).  
**Called by:** Unknown, likely geometry calculations.

### 10. Function at 0x5B8C4
**Entry address:** 0x5B8C4  
**Name:** `calculate_average_abs`
**Purpose:** Computes (|x| + |y|) / 2 using integer arithmetic. Takes absolute values of inputs, finds max/min, then computes average with rounding.  
**Arguments:** FP+8: x value, FP+12: y value.  
**Return value:** D0: integer result.  
**Called by:** Unknown, likely for approximation calculations.

### 11. Function at 0x5B926
**Entry address:** 0x5B926  
**Name:** `draw_arc_segment`
**Purpose:** Draws an arc segment using Bezier curve approximation. Calculates control points for cubic Bezier approximation of circular arcs. Handles transformation and rendering of arc segments.  
**Arguments:** Complex - uses many local variables for arc parameters.  
**Hardware/RAM accessed:** 0x2017464 (global structure), math routines at 0x899xx.  
**Call targets:** 0x3B81A (get coordinate), 0x3BCE8 (coordinate transformation), 0x4639E (error check), 0x1554A (vector operation), 0x22F58 (geometry calculation), 0x1B708 (atan2), 0x22F8A (geometry calculation), 0x1AE48 (line segment rendering), 0x4B990 (arctan).  
**Called by:** PostScript arc operators.

4. **Function 0x5B708 is NOT "setup_bezier_subdivision"** - that's at 0x5B664. Function 0x5B708 is `calculate_atan2`.

This region contains PostScript curve and arc rendering functions:
- **Bezier curve subdivision** (0x5B0FC): Implements de Casteljau algorithm for curve flattening
- **Arc approximation** (0x5B926): Uses cubic Bezier curves to approximate circular arcs
- **Mathematical helpers** (0x5B708, 0x5B818, 0x5B8C4): Provide atan2, hypotenuse, and average calculations
- **Operator wrappers** (0x5B6E6, 0x5B6F8): Interface between PostScript operators and internal rendering functions

The floating-point constants at 0x5B614-0x5B662 are critical mathematical values used by these algorithms, including π/180 for degree-radian conversion and the 4/3 constant for Bezier arc approximation.

; === CHUNK 38: 0x5BC00-0x5C800 ===

### 1. Function at 0x5BC00: `bezier_subdivide_or_flatten`
**Entry address:** 0x5BC00  
**Purpose:** Implements cubic Bezier curve subdivision with coordinate transformation. Takes 8 coordinates (x1,y1,x2,y2,x3,y3,x4,y4) and performs de Casteljau subdivision with transformation. The function computes intermediate control points, applies transformation matrices, and calls curve rendering functions.  
**Arguments:** Stack arguments (FP+8 through FP+36) for 8 coordinates, plus transformation parameters at FP+40+.  
**Hardware/RAM accessed:** 0x2017464 (global PostScript structure), many FPU emulation calls.  
**Call targets:** 0x89938 (fadd), 0x89980 (fcmp), 0x89998 (fdiv), 0x899C8 (fmul), 0x89A58 (fsub), 0x89A70 (fadd), 0x89A88 (float), 0x89AA0 (fsub), 0x89AB8 (fabs), 0x15502 (vector/matrix operation), 0x1AE48 (curve operation), 0x1AF1A (curve operation), 0x3BDE2 (cleanup).  
**Called by:** Unknown, likely PostScript path operators like `curveto`.

### 2. Data at 0x5BE0C-0x5BE22: Floating-point constants
**Address:** 0x5BE0C-0x5BE22  
**Format:** IEEE 754 double-precision:
- 0x5BE0C: 0x3FF0000000000000 = 1.0
- 0x5BE14: 0xBFF0000000000000 = -1.0  
- 0x5BE1C: 0x3FF5555555555555 = 1.3333333333333333 (4/3)
**Note:** Used in curve calculations (4/3 is the magic number for cubic Bezier subdivision).

### 3. Function at 0x5BE24: `update_transform_if_needed`
**Entry address:** 0x5BE24  
**Purpose:** Checks if a transformation structure needs updating. Tests word at offset 2, compares against value 3, and calls 0x1A5CC (transform update) if not equal. Updates offset 4 with offset 2 value. This appears to manage cached transformation states.  
**Arguments:** Pointer to transformation structure at FP+8.  
**Hardware/RAM accessed:** 0x2017F72, 0x2017F68 (lookup tables for transformation types).  
**Call targets:** 0x1A5CC (transform update function).  
**Called by:** 0x5BE82 (wrapper).

### 4. Function at 0x5BE82: `update_current_transform_wrapper`
**Entry address:** 0x5BE82  
**Purpose:** Wrapper that gets current transform from global structure at 0x2017464+44 and calls 0x5BE24.  
**Hardware/RAM accessed:** 0x2017464 (global PostScript structure).  
**Call targets:** 0x5BE24.  
**Called by:** Unknown, likely during graphics state changes.

### 5. Function at 0x5BE9A: `recursive_bezier_subdivide`
**Entry address:** 0x5BE9A  
**Purpose:** Complex recursive Bezier subdivision with flatness testing (adaptive subdivision). Implements de Casteljau algorithm: checks if curve is "flat enough" (control points within tolerance), otherwise subdivides at midpoint and recurses on both halves. Uses extensive floating-point math and geometric tests.  
**Arguments:** 8 coordinates (x1,y1,x2,y2,x3,y3,x4,y4) at FP+8 through FP+36, and pointer to control structure at FP+40 containing recursion counter and callback function pointer.  
**Hardware/RAM accessed:** Many FPU calls, accesses control structure.  
**Call targets:** Self-recursive, 0x89938 (fadd), 0x89980 (fcmp), 0x89998 (fdiv), 0x899C8 (fmul), 0x89A70 (fadd), 0x89A88 (float), 0x89AB8 (fabs).  
**Called by:** Self, 0x5C43E (wrapper).

- Lines 0x5BEAA-0x5BF00: Compute differences and cross products for flatness test
- Lines 0x5BF76-0x5BFFA: Flatness tests (check if control points are within tolerance)
- Lines 0x5BFFE-0x5C076: Compute maximum deviation from chord
- Lines 0x5C078-0x5C1AE: Compare deviation against tolerance (from control structure)
- Lines 0x5C1B2-0x5C3A0: Compute subdivision points (midpoints of control polygon)
- Lines 0x5C3B2-0x5C428: Recursively call self on both halves

### 6. Data at 0x5C430-0x5C43C: Floating-point constants
**Address:** 0x5C430-0x5C43C  
**Format:** IEEE 754 double-precision:
- 0x5C430: 0x3FF0000000000000 = 1.0
- 0x5C438: 0x4000000000000000 = 2.0
**Note:** Used in flatness calculations (likely for tolerance scaling).

### 7. Function at 0x5C43E: `bezier_subdivide_wrapper`
**Entry address:** 0x5C43E  
**Purpose:** Wrapper function that sets up control structure for recursive Bezier subdivision. Takes 8 coordinates plus tolerance and callback parameters, creates control structure on stack, and calls recursive_bezier_subdivide.  
**Arguments:** 8 coordinates (FP+8 through FP+36), tolerance (FP+40,44), callback pointer (FP+48).  
**Hardware/RAM accessed:** Stack for control structure.  
**Call targets:** 0x899C8 (fmul), 0x5BE9A (recursive_bezier_subdivide).  
**Called by:** Unknown, likely higher-level curve rendering functions.

### 8. Function at 0x5C492: `bezier_subdivide_fixed_point`
**Entry address:** 0x5C492  
**Purpose:** Fixed-point integer Bezier subdivision algorithm. Converts floating-point coordinates to 16.16 fixed-point, performs adaptive subdivision with integer math, and calls callback for final segments. More efficient than floating-point version for hardware rendering.  
**Arguments:** 8 coordinates (FP+8 through FP+36), reference point (FP+44,48), control structure pointer (FP+40).  
**Hardware/RAM accessed:** Stack for temporary arrays, control structure.  
**Call targets:** 0x3CEBC (coordinate transformation), callback via control structure.  
**Called by:** Unknown, likely hardware-accelerated path rendering.

- Lines 0x5C49E-0x5C506: Convert coordinates to fixed-point relative to reference  coordinate data  (font metric data)
- Lines 0x5C514-0x5C524: Clamp subdivision depth to maximum 8
- Lines 0x5C530-0x5C5BA: Flatness test using bounding box checks
- Lines 0x5C5C2-0x5C68A: More precise flatness test using cross products
- Lines 0x5C68A-0x5C74A: Compute subdivision midpoints (de Casteljau)
- Lines 0x5C764-0x5C7AC: Convert back to device coordinates and call callback  coordinate data  (font metric data)

### 9. Function at 0x5C7BE: `bezier_subdivide_fixed_point_simple`
**Entry address:** 0x5C7BE  
**Purpose:** Simplified fixed-point Bezier subdivision for shallow curves. Checks recursion depth, and if shallow enough, transforms coordinates and calls callback directly without subdivision.  
**Arguments:** 8 coordinates (FP+8 through FP+36), control structure pointer (FP+40).  
**Hardware/RAM accessed:** Stack for temporary coordinates, control structure.  
**Call targets:** 0x3CEBC (coordinate transformation), callback via control structure.  
**Called by:** Unknown, likely for very flat curves.

**Note:** The function appears incomplete in the disassembly (cuts off at 0x5C800). The full function likely continues beyond this address range.

1. **Function at 0x5C43E** was previously described as "Data at 0x5C43E-0x5C43C" - this was incorrect. It's clearly a function (starts with LINK instruction).

2. **Data at 0x5C430-0x5C43C** contains only 2 double-precision constants (1.0 and 2.0), not 3 as previously suggested.

3. **Function at 0x5C492** is a major fixed-point Bezier subdivision algorithm that was not mentioned in the prior analysis. This is a significant omission.

4. **Function at 0x5C7BE** is another fixed-point Bezier function that was not mentioned.

This region contains **three distinct Bezier subdivision implementations**:
1. **Floating-point recursive** (0x5BE9A): High precision, uses FPU emulation
2. **Fixed-point adaptive** (0x5C492): Optimized for hardware, uses integer math
3. **Fixed-point simple** (0x5C7BE): Fast path for shallow curves

The presence of both floating-point and fixed-point implementations suggests the system supports both software rendering (high precision) and hardware acceleration (fast integer math). The fixed-point version converts coordinates to 16.16 format relative to a reference point, which is typical for rasterization hardware.

The control structure passed to these functions (at FP+40) appears to contain:
- Recursion counter (offset 0)  struct field
- Tolerance/flatness value (offset 4)  struct field
- Callback function pointer (offset 12)  struct field

This modular design allows the same subdivision logic to be used with different rendering backends.

; === CHUNK 39: 0x5C800-0x5D400 ===

## REFINED ANALYSIS OF 0x5C800-0x5D400

2. The function at 0x5c9f2 is `draw_bezier_curve_wrapper` (correct).
4. The Bézier algorithm uses a flatness test based on bounding box dimensions, comparing the difference between min and max against a threshold in D4.

### 1. Function at 0x5c800 - `bezier_subdivide_or_draw`
**Entry:** 0x5c800  
**Purpose:** Recursively subdivides a cubic Bézier curve using the de Casteljau algorithm. Computes bounding boxes for X and Y coordinates separately, checks if both dimensions are "flat" (difference ≤ threshold in D4), and if so, draws the curve via 0x1c492. Otherwise, subdivides at midpoint and recurses on both halves.  
- fp@(8)-(36): 8 coordinates (x1,y1,x2,y2,x3,y3,x4,y4)  coordinate data  (font metric data)
- fp@(40): recursion depth counter (pointer, decremented before recursion)  stack frame parameter
1. Compute min/max of x coordinates (x1,x2,x3,x4), check if (max-min) ≤ D4
2. Compute min/max of y coordinates (y1,y2,y3,y4), check if (max-min) ≤ D4  
3. If both flat: call 0x1c492 (draw line segments)
4. Else: compute 7 subdivision points via midpoint averaging, decrement depth, recurse on first half (0x1c7be), then second half  
**Calls:** 0x1c492 (draw flattened curve), 0x1c7be (recursive call)  
**Called by:** 0x5c9f2 (wrapper)  
**RAM:** None directly, uses stack for intermediate points

### 2. Function at 0x5c9f2 - `draw_bezier_curve_wrapper`
**Entry:** 0x5c9f2  
**Purpose:** Wrapper that sets up a local structure on stack for Bézier recursion state and calls the main Bézier function.  
**Arguments:** fp@(8)-(36): 8 coordinates, fp@(40): recursion limit, fp@(44): state pointer  
**Stack frame:** Creates 16-byte structure at fp@(-16) containing state pointer and recursion limit  
**Calls:** 0x1c7be (which is actually 0x5c800 - the disassembler mislabeled the offset)  
**Called by:** PostScript curveto operator implementation

### 3. Function at 0x5ca38 - `transform_coordinates_multiply`
**Entry:** 0x5ca38  
**Purpose:** Multiplies the four transformation matrix elements (0x2002060,64,68,6C) by corresponding coordinate values (0x20175f0,75f4). Used to apply scaling transformations.  
- 0x2002060,64,68,6C: Transformation matrix [a b c d]
- 0x20175f0,75f4: X and Y scale factors  (PS CTM operator)
**Calls:** 0x89ab8 (fixed-point multiplication)  
**Called by:** 0x5caa0, 0x5cb78, 0x5cc44 when 0x20175fa is false

### 4. Function at 0x5caa0 - `set_transform_from_font_metrics`
**Entry:** 0x5caa0  
**Purpose:** Sets up transformation matrix from font metrics. Reads font structure at 0x2017464, extracts metrics at offsets 0x4a,56,52,4e, and computes transformation values.  
- 0x2017464: Font structure pointer
- Font offsets: 0x4a (likely font matrix a), 0x56 (d), 0x52 (c), 0x4e (b)  struct field
- 0x200203c,38,34,30: Transformation state flags (set to 1)
- 0x2002060,64,68,6C: Transformation matrix output
- 0x20175fa: Flag (if 0, calls transform_coordinates_multiply)  coordinate data  (font metric data)
**Calls:** 0x89a88 (convert), 0x89aa0/0x89920 (add/subtract), 0x899c8 (store), 0x5ca38  
**Constants:** Uses 0x40200000 (2.5) at 0x5cb72 as reference value

### 5. Function at 0x5cb78 - `set_transform_from_user_space`
**Entry:** 0x5cb78  
**Purpose:** Similar to font version but uses user space coordinates from different RAM locations.  
- 0x20220c8, 0x20221d8, 0x20220cc, 0x2017f60: User space coordinates  coordinate data  (font metric data)
- Same transformation state and matrix addresses as above  
**Calls:** Same math routines as 0x5caa0  
**Constants:** Uses 0x40200000 at 0x5cc3c

### 6. Function at 0x5cc44 - `set_transform_from_struct`
**Entry:** 0x5cc44  
**Purpose:** Sets transformation matrix from a structure pointer passed as argument. Reads 4 values from the structure (offsets 0,4,8,12) and processes them similarly to the font/user space versions.  
**Arguments:** fp@(8): pointer to structure containing 4 transformation values  
- Same transformation state and matrix addresses as above
- 0x20175fa: Flag (if 0, calls transform_coordinates_multiply)  coordinate data  (font metric data)
**Calls:** Same math routines as 0x5caa0  
**Constants:** Uses 0x40200000 at 0x5cd0c

### 7. Function at 0x5cd12 - `transform_and_draw_y_axis`
**Entry:** 0x5cd12  
**Purpose:** Transforms Y-coordinate values using the transformation matrix element at 0x200206c (d), compares with previous value, and conditionally draws lines. Handles caching of transformed coordinates to avoid redundant calculations.  
**Arguments:** fp@(8): x coordinate, fp@(12): y coordinate  
1. Compares y coordinate with 0x200206c using 0x89980 (comparison)
2. Sets boolean flag based on comparison result
3. Checks transformation state at 0x200203c
4. If state is active, stores coordinates and flag, returns
5. Otherwise, computes transformed values and draws if flag indicates  
- 0x200206c: Transformation matrix element d
- 0x200203c: Transformation state flag
- 0x2002020,2024,2028,202c,2058,205c: Cached coordinate values and flags  coordinate data  (font metric data)
**Calls:** 0x89980 (compare), 0x89ab8 (multiply), 0x89a70 (add), 0x899b0 (subtract), 0x89938 (store), 0x163fa (draw line)  
**Called by:** 0x5ce18, 0x5d2d4

### 8. Function at 0x5ce18 - `transform_and_draw_x_axis`
**Entry:** 0x5ce18  
**Purpose:** Similar to transform_and_draw_y_axis but for X-coordinate using transformation matrix element at 0x2002068 (c).  
**Arguments:** fp@(8): x coordinate, fp@(12): y coordinate  
- 0x2002068: Transformation matrix element c
- 0x2002038: Transformation state flag
- 0x2002010,2014,2018,201c,2050,2054: Cached coordinate values and flags  coordinate data  (font metric data)
**Calls:** Same math routines as 0x5cd12, calls 0x5cd14 (which is actually 0x5cd12)  
**Called by:** 0x5cf18, 0x5d240

### 9. Function at 0x5cf18 - `transform_and_draw_second_y_axis`
**Entry:** 0x5cf18  
**Purpose:** Similar to transform_and_draw_y_axis but uses transformation matrix element at 0x2002064 (b).  
**Arguments:** fp@(8): x coordinate, fp@(12): y coordinate  
- 0x2002064: Transformation matrix element b
- 0x2002034: Transformation state flag
- 0x2002000,2004,2008,200c,2048,204c: Cached coordinate values and flags  coordinate data  (font metric data)
**Calls:** Same math routines, calls 0x5ce18  
**Called by:** 0x5d018, 0x5d1ac

### 10. Function at 0x5d018 - `transform_and_draw_second_x_axis`
**Entry:** 0x5d018  
**Purpose:** Similar to transform_and_draw_x_axis but uses transformation matrix element at 0x2002060 (a).  
**Arguments:** fp@(8): x coordinate, fp@(12): y coordinate  
- 0x2002060: Transformation matrix element a
- 0x2002030: Transformation state flag
- 0x2001ff0,1ff4,1ff8,1ffc,2040,2044: Cached coordinate values and flags  coordinate data  (font metric data)
**Calls:** Same math routines, calls 0x5cf18  
**Called by:** 0x5d118

### 11. Function at 0x5d118 - `flush_x_transform_cache`
**Entry:** 0x5d118  
**Purpose:** Flushes cached X-axis transformation values if the cached flag (0x2002040) differs from current flag (0x2002044). Computes transformed coordinates and draws line.  
- 0x2002040,2044: Cached and current flags for X-axis
- 0x2002060,1ff0,1ff4,1ff8,1ffc: Transformation values and cached coordinates  coordinate data  (font metric data)
**Calls:** 0x89ab8 (multiply), 0x89a70 (add), 0x899b0 (subtract), 0x89938 (store), 0x5cf18 (draw)  
**Called by:** 0x5d36a

### 12. Function at 0x5d1ac - `flush_second_y_transform_cache`
**Entry:** 0x5d1ac  
**Purpose:** Flushes cached second Y-axis transformation values if flags differ (0x2002048 vs 0x200204c).  
- 0x2002048,204c: Cached and current flags for second Y-axis
- 0x2002064,2000,2004,2008,200c: Transformation values and cached coordinates  coordinate data  (font metric data)
**Calls:** Same math routines, calls 0x5ce18  
**Called by:** 0x5d36a

### 13. Function at 0x5d240 - `flush_x_axis_transform_cache`
**Entry:** 0x5d240  
**Purpose:** Flushes cached X-axis transformation values if flags differ (0x2002050 vs 0x2002054).  
- 0x2002050,2054: Cached and current flags for X-axis
- 0x2002068,2010,2014,2018,201c: Transformation values and cached coordinates  coordinate data  (font metric data)
**Calls:** Same math routines, calls 0x5cd14 (0x5cd12)  
**Called by:** 0x5d36a

### 14. Function at 0x5d2d4 - `flush_y_axis_transform_cache`
**Entry:** 0x5d2d4  
**Purpose:** Flushes cached Y-axis transformation values if flags differ (0x2002058 vs 0x200205c).  
- 0x2002058,205c: Cached and current flags for Y-axis
- 0x200206c,2020,2024,2028,202c: Transformation values and cached coordinates  coordinate data  (font metric data)
**Calls:** Same math routines, calls 0x163fa (draw line)  
**Called by:** 0x5d36a

### 15. Function at 0x5d36a - `flush_all_transform_caches`
**Entry:** 0x5d36a  
**Purpose:** Calls all four flush functions to ensure all cached transformation values are processed, then resets all transformation state flags to 1 (active).  
**Calls:** 0x5d118, 0x5d1ac, 0x5d240, 0x5d2d4, 0x21058 (unknown function)  
- 0x200203c,38,34,30: All transformation state flags (set to 1)

### 16. Function at 0x5d3ae - `process_font_glyph` (partial, continues beyond range)
**Entry:** 0x5d3ae  
**Purpose:** Processes font glyph data, initializes multiple coordinate structures, and handles font-specific transformations. Only the beginning of this function is within the current range.  
**Arguments:** Unknown (function continues beyond 0x5d400)  
**Stack frame:** Large frame (-172 bytes)  
**Calls:** 0x365f8 (initialize coordinate structure, called 4 times)  
- 0x2017464: Font structure pointer
- Checks byte at offset 0x43 (font flag)  struct field

- 0x5cb72: Constant 0x40200000 (2.5 in IEEE 754 single precision)
- 0x5cc3c: Constant 0x40200000 (2.5)
- 0x5cd0c: Constant 0x40200000 (2.5)

1. This region contains the core Bézier curve rendering engine with recursive subdivision.
2. There's a sophisticated transformation caching system with four separate transformation pipelines (a, b, c, d matrix elements).
3. The transformation system uses state flags to avoid redundant calculations.
4. Multiple flush functions ensure cached values are processed when transformation states change.
5. The code handles both font-specific and user-space transformations.

; === CHUNK 40: 0x5D400-0x5E000 ===

### 1. Function at 0x5d400 - `render_path_with_clipping` (CORRECTED)
**Entry:** 0x5d400 (no LINK instruction, uses MOVEML to save A4-A5 at 0x5d604)
**Purpose:** Main path rendering function that traverses a PostScript path structure, applies clipping tests, and renders visible segments. It handles all four path segment types (moveto, lineto, curveto, closepath) with coordinate transformations and clipping boundary checks.
**Arguments:** Path structure pointer (likely in A0 or on stack, but prologue is missing).
**Stack frame:** Uses fp@(-164) for saved execution context, fp@(-84) for temporary storage.
- 0x20008f4: Current execution context pointer (saved/restored)
- 0x2017464: Font/graphics context structure
- 0x2017f68: Path element array base (calculated as base + index*?)
- 0x20175fa: Transformation matrix active flag
1. Saves current execution context at 0x20008f4 (0x5d426-0x5d438)
2. Gets path element count from font structure at 0x2017464+44 (0x5d44e-0x5d45a)
3. Iterates through path elements using index in fp@(-2) (0x5d462-0x5d5bc)
4. For each element, calculates address: 0x2017f68 + index (0x5d472-0x5d478)
5. Switch on segment type (0-3) at 0x5d488 using jump table at 0x5d490
6. Processes coordinates, applies clipping test at 0x31334
7. If clipping test passes, calls drawing function at 0x3bde2
8. Handles Bézier curves (type 2) with three control points (0x5d50c-0x5d586)
9. On error (code -6), calls error handler at 0x31ddc
- 0x195be: Initialize path processing
- 0x1a580: Setup coordinate transformation  coordinate data  (font metric data)
- 0x4df1c: Clipping region test
- 0x1a80e: Get path element count
- 0x19dd8: Process path segment coordinates  coordinate data  (font metric data)
- 0x3bde2: Draw line/curve segment
- 0x31334: Clipping test for specific coordinates  coordinate data  (font metric data)
- 0x1a7c2: Cleanup transformation
- 0x31dbe: Check for errors
- 0x31ddc: Handle errors
- 0x4d8d8: Alternative rendering (when clipping test fails)  (PS dict operator)
**Return:** Presumably void (no explicit return value visible)
**Note:** This is a low-level rendering driver that works with the path element linked list structure.

### 2. Function at 0x5d60e - `iterate_path_with_callbacks` (CORRECTED)
**Entry:** 0x5d60e (LINKW %fp,#-124)
**Purpose:** Generalized path iterator that walks through path elements and calls user-provided callback functions for different operations. This is used for both rendering and path analysis (like bounding box calculation).
- fp@(8): Path structure pointer  stack frame parameter
- fp@(12): Callback for line drawing (called with x,y coordinates)  coordinate data  (font metric data)
- fp@(16): Unknown callback (possibly for curve drawing)  stack frame parameter
- fp@(20): Callback called before processing segment  stack frame parameter
- fp@(24): Callback called after processing segment  stack frame parameter
- fp@(28): Boolean callback (called with 0/1 argument)  stack frame parameter
- fp@(36), fp@(40): Additional parameters (possibly transformation context)  stack frame parameter
- fp@(44): Flag indicating whether to apply transformation  stack frame parameter
- fp@(-2): Current path index  stack frame parameter
- fp@(-8): Current element pointer  stack frame parameter
- fp@(-32), fp@(-28): Current coordinates (x,y)  coordinate data  (font metric data)
- fp@(-40), fp@(-36): Next coordinates  coordinate data  (font metric data)
- fp@(-48), fp@(-44): Following coordinates (for curves)  coordinate data  (font metric data)
- fp@(-88): Boolean flag (fp@(-88) = 1 initially)  stack frame parameter
- fp@(-92): Curve flattening decision flag  stack frame parameter
- fp@(-84): Result from callback setup  stack frame parameter
1. Initializes fp@(-88) = 1 (some flag) at 0x5d614
2. Gets starting index from path structure at 0x5d618-0x5d61c
3. While index != 0: (loop from 0x5d624 to 0x5da68)
   - Calculate element address: 0x2017f68 + index at 0x5d62a-0x5d630
   - Apply coordinate transformation if fp@(44) is true and 0x20175fa is 0 (0x5d640-0x5d672)  coordinate data  (font metric data)
   - Switch on segment type (0-3) at 0x5d688 using jump table at 0x5d690:
     - Case 0 (moveto?): Updates current point, calls callbacks (0x5d69a-0x5d6f8)  (PS path operator)
     - Case 1 (lineto?): Draws line, calls callbacks (0x5d6c4-0x5d6f8)  (PS path operator)
     - Case 2 (curveto): Complex Bézier curve handling with flattening decision (0x5d6fc-0x5d9e8)  (PS path operator)
     - Case 3 (closepath?): Special handling (0x5da1a-0x5da4c)  (PS path operator)
4. For curves, decides whether to flatten based on bounding box size (0x5d6fc-0x5d858)
5. If flattening needed, calls `draw_bezier_curve` at 0x1c9f2 (0x5d986)
6. Otherwise calls alternative curve handler at 0x1c440 (0x5d9e0)
**Return:** Void (no return value)

### 3. Function at 0x5da80 - `setup_path_iteration`
**Entry:** 0x5da80 (LINKW %fp,#0)
**Purpose:** Sets up parameters for path iteration by calling `iterate_path_with_callbacks` with specific callbacks for rendering operations.
- fp@(8): Path structure pointer  stack frame parameter
- fp@(12): Unknown parameter  stack frame parameter
- fp@(16): Unknown parameter  stack frame parameter
1. Gets bounding box from path structure at 0x2017464+156 (0x5da8e-0x5da92)
2. Calls math function at 0x89a88 (likely converts fixed-point to float)
3. Pushes multiple parameters on stack (0x5da98-0x5dab6)
4. Calls `iterate_path_with_callbacks` at 0x5d60e with callback address 0x5a3f8
**Return:** Result from `iterate_path_with_callbacks`

### 4. Function at 0x5dac6 - `call_path_callback_a` (NEW)
**Entry:** 0x5dac6 (LINKW %fp,#0)
**Purpose:** Wrapper function that converts multiple fixed-point coordinates to floating-point and calls a path callback from the graphics context.
- fp@(8) to fp@(28): Six coordinate pairs (12 parameters total)  coordinate data  (font metric data)
1. Converts each fixed-point coordinate to float using 0x15d72 (6 calls)
2. Gets callback pointer from graphics context at 0x2017464+160+12 (0x5d71e-0x5d72c)
3. Calls the callback with all converted coordinates
**Return:** Result from the callback

### 5. Function at 0x5db36 - `call_path_callback_b` (NEW)
**Entry:** 0x5db36 (LINKW %fp,#0)
**Purpose:** Similar to `call_path_callback_a` but uses different callback from graphics context and includes additional parameters from the context.
- fp@(8) to fp@(28): Six coordinate pairs  coordinate data  (font metric data)
1. Gets two values from graphics context at 0x2017464+144 and +140 (0x5db3a-0x5db4e)
2. Converts each fixed-point coordinate to float using 0x15d72 (6 calls)
3. Gets callback pointer from graphics context at 0x2017464+160+8 (0x5dba8-0x5dbb0)
4. Calls the callback with context values and converted coordinates
**Return:** Result from the callback

### 6. Function at 0x5dbba - `call_path_callback_c` (NEW)
**Entry:** 0x5dbba (LINKW %fp,#0)
**Purpose:** Simplified callback wrapper that uses only one parameter.
- fp@(8): Single parameter  stack frame parameter
1. Gets two values from graphics context at 0x2017464+144 and +140
2. Gets callback pointer from graphics context at 0x2017464+160+44
3. Calls the callback with context values and the parameter
**Return:** Result from the callback

### 7. Function at 0x5dbee - `should_flatten_curve` (CORRECTED)
**Entry:** 0x5dbee (LINKW %fp,#-20, saves D5-D7/A5)
**Purpose:** Determines whether a Bézier curve should be flattened (approximated with line segments) based on its bounding box size and complexity.
- fp@(8): Pointer to curve control points structure  stack frame parameter
- fp@(12): Boolean flag (possibly for special handling)  stack frame parameter
1. Checks if curve width <= 1500 units (0x5dbfc-0x5d81a)
2. If fp@(12) is true, uses 600 as threshold instead (0x5d820-0x5d826)
3. Checks if curve height <= threshold (0x5d828-0x5d846)
4. If height > 75 units and fp@(12) is true, performs additional checks (0x5d848-0x5d856)
5. Traverses path elements to count segments (0x5d85a-0x5d88a)
6. Returns 1 if curve should be flattened, 0 otherwise
**Return:** D0 = 1 (flatten) or 0 (don't flatten)

### 8. Function at 0x5dca6 - `update_cached_rectangle` (CORRECTED)
**Entry:** 0x5dca6 (LINKW %fp,#0)
**Purpose:** Updates a cached rectangle structure if all coordinates match the current cached values.
- fp@(8) to fp@(28): Rectangle coordinates (x1,y1,x2,y2,x3,y3,x4,y4)  coordinate data  (font metric data)
1. Checks if cache is active (0x2002078 != 0) at 0x5dcaa
2. Compares new coordinates with cached values at 0x2002084-0x200208c
3. If all match, updates x1 coordinate in cache (0x5dce2-0x5dce8)
4. Otherwise, clears cache flag (0x5dcec)
5. Sets 0x200207c = 1 (cache valid flag)
**Return:** Void

### 9. Function at 0x5dcfe - `render_rectangle` (CORRECTED)
**Entry:** 0x5dcfe (LINKW %fp,#-32, saves A2)
**Purpose:** Main rectangle rendering function with transformation, clipping, and hardware acceleration.
- fp@(8): Pointer to rectangle coordinates structure  coordinate data  (font metric data)
1. Sets up error message pointers (0x5dd04-0x5dd12)
2. Checks if rectangle is valid (0x5dd14-0x5dd2c)
3. Checks if hardware acceleration is enabled (0x5dd36-0x5dd3c)
4. If invalid or HW accel disabled, returns error (0x5dd3e-0x5dd48)
5. Attempts to lock resources (0x5dd54-0x5dd76)
6. If locking fails, sets different error messages (0x5dd78-0x5dd90)
7. Locks rendering (0x5dd92-0x5dd9c)
8. Applies coordinate transformation if needed (0x5ddc4-0x5de22)
9. Converts coordinates and updates cache (0x5de24-0x5df0c)
10. Calls hardware acceleration via callback at 0x22b10 (0x5df12-0x5df1c)
11. Checks result and returns status code
**Return:** D0 = 0 (success), 1 (error), or 2 (fallback to software)

### 10. Function at 0x5df50 - `flush_rectangle_cache` (NEW)
**Entry:** 0x5df50 (LINKW %fp,#0)
**Purpose:** Flushes any cached rectangle data to hardware.
1. Calls 0x2087a (check if rendering is possible)
2. If not possible, sets up error messages and calls 0x1da80
3. Calls 0x20722 (flush operation)
**Return:** Void

### 11. Function at 0x5df94 - `render_polygon` (NEW - partial, continues beyond 0x5E000)
**Entry:** 0x5df94 (LINKW %fp,#-8)
**Purpose:** Renders a polygon path with clipping and transformation.
- fp@(8): Polygon path structure pointer  stack frame parameter
1. Checks if path is empty (0x5df9c)
2. Checks if hardware acceleration is enabled (0x5dfa8-0x5dfae)
3. If enabled, processes path elements (0x5dfb0-0x5dfe2)
4. Otherwise, validates path and sets up rendering (0x5dfe6-0x5dffa)
**Note:** Function continues beyond 0x5E000

### Jump Table at 0x5d490:
- Size: 8 bytes (4 × 16-bit offsets)  struct field
- Format: Offsets for segment type dispatch in `render_path_with_clipping`  (PS dict operator)
- Values: 0x0008, 0x0042, 0x007c, 0x010e

### Jump Table at 0x5d690:
- Size: 8 bytes (4 × 16-bit offsets)  struct field
- Format: Offsets for segment type dispatch in `iterate_path_with_callbacks`  struct field
- Values: 0x0008, 0x0034, 0x006c, 0x038a

### Data at 0x5da70-0x5da7e:
- Appears to be constant data used by rendering functions  (PS dict operator)
- 0x5da70: Word value 0x40d0
- 0x5da72-0x5da7d: Zero padding
- 0x5da7e: Word value 0x0000

1. **Function at 0x5d400** does NOT use MOVEML at entry - it saves A4-A5 at the END (0x5d604) before returning. The function starts directly with code.

2. **Function at 0x5d60e** was partially correct but missed many details about the callback mechanism and curve flattening logic.

3. **Multiple functions were missed** between 0x5da80 and 0x5df94 that handle path iteration setup and various callback wrappers.

5. **Data regions** at 0x5d490 and 0x5d690 are jump tables, not code.

6. **Function at 0x5df94** continues beyond 0x5E000, so only the beginning is visible in this chunk.

1. The rendering system uses a sophisticated callback mechanism for path processing, allowing different operations (rendering, hit testing, bounding box calculation) to use the same path traversal logic.

2. Curve flattening decisions are based on both size thresholds (1500×600 units maximum) and complexity (more than 8 segments triggers flattening).

3. Rectangle rendering has a caching mechanism to avoid redundant hardware operations when the same rectangle is drawn repeatedly.

4. The coordinate transformation system checks 0x20175fa to determine if transformations should be applied.

5. Hardware acceleration is controlled by bit 7 at 0x2017464+164 (0x5dd36-0x5dd3c checks this).

; === CHUNK 41: 0x5E000-0x5EC00 ===

### 1. 0x5E000 - `process_path_operation` (CORRECTED)
**Entry:** 0x5E000 (no LINK - continuation from earlier code)  
**Purpose:** Main dispatcher for PostScript path operations (stroke, fill, clip). Checks if clipping is active (bit 7 at offset 0xA4 in graphics state). Has two main execution paths:
- **Emergency/clip path** (0x5E014-0x5E092): When clipping is active and operation is clipping (mode=2), enters emergency mode and executes clipping operation.
- **Normal rendering path** (0x5E096-0x5E1D0): Validates path, allocates rendering buffers, sets up callbacks, and executes the operation.
- fp@(8): Path object pointer  stack frame parameter
- fp@(12): Operation mode (0=fill, 1=stroke, 2=clip)  (PS paint operator)
**Return:** D0 = success (0) or failure (1)
- 0x02017464: Global graphics state structure
- 0x020008F4: Stack pointer save area
- Checks bit 7 at offset 0xA4 (164) for clipping flag  (PS clip operator)
- 0x15E6A: `validate_path_object`
- 0x1FD28: `enter_emergency_mode`
- 0x1DA80: `setup_path_rendering_context`  (PS dict operator)
- 0x1F6A4: `execute_path_operation`
- 0x15FA0: `check_path_validity`
- 0x22C72: `allocate_rendering_buffer`  (PS dict operator)
**Callers:** PostScript operator dispatcher for `stroke`, `fill`, `eoclip`, `clip` operations.

### 2. 0x5E1D4 - `reset_path_state`
**Entry:** 0x5E1D4 (LINKW %fp,#0)  
**Purpose:** Clears current path state by calling two functions with flag=0. Resets path cache and prepares for new path definition.
- 0x1DF94: `clear_path` (with flag=0)
- 0x1AB70: `reset_path_cache`
**Callers:** PostScript `newpath` operator, path initialization routines.

### 3. 0x5E1F4 - `activate_path_state`
**Entry:** 0x5E1F4 (LINKW %fp,#0)  
**Purpose:** Activates a path by calling same functions as `reset_path_state` but with flag=1. Used when reusing or activating an existing path.
- 0x1DF94: `clear_path` (with flag=1)
- 0x1AB70: `reset_path_cache`
**Callers:** Path activation routines, possibly `gsave`/`grestore`.

### 4. 0x5E216 - `transform_coordinate_pair`
**Entry:** 0x5E216 (LINKW %fp,#-28)  
**Purpose:** Applies coordinate transformation based on system flags. Checks bit 6 at offset 0xA4 in graphics state:
- If set (complex transform): Uses 0x271DE with matrix at 0x02001FA8
- If clear (simple transform): Uses 0x268F0 with buffer at 0x02001F90
Handles both fixed-point and floating-point coordinate systems.
**Arguments:** fp@(8): Pointer to coordinate pair (x,y)
**Return:** D0 = Pointer to transformed coordinates (in buffer at 0x02001F90)
- 0x02017464 + 0xA4: Transformation flags
- 0x02001FA8: Complex transform matrix present flag
- 0x02001F90: Simple transform buffer (24 bytes)
- 0x5E26E: Simple transform path
- 0x5E228: Complex transform path
**Callers:** Coordinate transformation routines, path building functions.

### 5. 0x5E280 - `line_to_callback`
**Entry:** 0x5E280 (LINKW %fp,#0)  
**Purpose:** Callback function for PostScript `lineto` operator. Passes coordinates to line drawing function with rendering context buffer.
- fp@(8): X coordinate  coordinate data  (font metric data)
- fp@(12): Y coordinate  coordinate data  (font metric data)
**Hardware/RAM:** Uses rendering buffer at 0x02002090
**Key calls:** 0x1AD74: `draw_line_segment`
**Callers:** Installed as callback in `setup_path_rendering_context`.

### 6. 0x5E29E - `move_to_callback`
**Entry:** 0x5E29E (LINKW %fp,#0)  
**Purpose:** Callback for PostScript `moveto` operator. Sets current point in path.
- fp@(8): X coordinate  coordinate data  (font metric data)
- fp@(12): Y coordinate  coordinate data  (font metric data)
**Key calls:** 0x1AE48: `set_current_point`
**Callers:** Installed as callback in `setup_path_rendering_context`.

### 7. 0x5E2BC - `close_path_callback`
**Entry:** 0x5E2BC (LINKW %fp,#0)  
**Purpose:** Callback for PostScript `closepath` operator. Closes current subpath by connecting back to starting point.
**Hardware/RAM:** Uses rendering buffer at 0x02002090
**Key calls:** 0x1BE24: `close_current_subpath`
**Callers:** Installed as callback in `setup_path_rendering_context`.

### 8. 0x5E2D0 - `compute_bezier_control_points` (CORRECTED NAME)
**Entry:** 0x5E2D0 (LINKW %fp,#-72)  
**Purpose:** Computes Bézier curve control points for PostScript `curveto` operator. Takes three control points and generates the actual curve segments. Saves/restores execution context and sets up callbacks for curve drawing.
- fp@(8): First control point (x1,y1)  stack frame parameter
- fp@(12): Second control point (x2,y2)  stack frame parameter
- fp@(16): Third control point (x3,y3)  stack frame parameter
**Return:** D0 = Pointer to computed control points (at 0x020020A8)
- 0x02002090: Rendering context buffer  (PS dict operator)
- 0x020020A7: Path state flag (from offset 23 of first control point)  struct field
- 0x020008F4: Execution context stack pointer
- 0x1A580: `init_curve_computation`
- 0x4DF1C: `check_curve_validity`
- 0x1D60E: `compute_bezier_segments` (with callbacks for moveto, lineto, closepath)  (PS path operator)
- 0x1A7C2: `finalize_curve_computation`
- 0x4D8D8: `handle_curve_error`
**Callers:** PostScript `curveto` operator implementation.

### 9. 0x5E382 - `transform_and_update_current_point`
**Entry:** 0x5E382 (LINKW %fp,#-28)  
**Purpose:** Transforms the current point using the current transformation matrix and updates the path state. Retrieves current point from graphics state (offset 156), transforms it, and stores back.
- 0x02017464 + 0x9C (156): Current point coordinates  coordinate data  (font metric data)
- 0x02001F90: Transformation buffer
- 0x89A88: Floating-point conversion (__ftol)
- 0x1E2D0: `compute_bezier_control_points` (actually transform point)
- 0x1A7C2: `update_path_state`
**Callers:** Path transformation routines after coordinate changes.

### 10. 0x5E3EE - `compute_bezier_subdivision` (NEW FUNCTION)
**Entry:** 0x5E3EE (LINKW %fp,#-32)  
**Purpose:** Implements Bézier curve subdivision algorithm (de Casteljau). Handles both flatness testing and recursive subdivision. Computes intermediate control points and generates curve segments.
- fp@(8): dx1  stack frame parameter
- fp@(12): dy1  stack frame parameter
- fp@(16): dx2  stack frame parameter
- fp@(20): dy2  stack frame parameter
- fp@(24): flatness tolerance  stack frame parameter
**Return:** D0 = Pointer to computed points (at 0x020020C0)
1. Computes cross product to test flatness (|dx1×dy2 - dy1×dx2| < tolerance)
2. If flat enough (or small), outputs line segments
3. Otherwise recursively subdivides and outputs both halves
- 0x02001FB4-0x02001FE8: Bézier control point workspace
- 0x02002070: Curve drawing callback
- 0x020020C0: Output buffer
- 0x4C022: Fixed-point multiplication
- 0x4C07E: Fixed-point division
- 0x3CEBC: Vector interpolation
- 0x1B8C2: Distance calculation
**Callers:** `compute_bezier_control_points` via recursive subdivision.

### 11. 0x5E61C - `init_bezier_computation`
**Entry:** 0x5E61C (LINKW %fp,#0)  
**Purpose:** Initializes Bézier curve computation by setting up control points and flag. Stores first two control points and sets computation active flag.
- fp@(8): First control point (x,y)  stack frame parameter
- fp@(12): Second control point (x,y)  stack frame parameter
- 0x02001FAC-0x02001FB0: First control point
- 0x02001FB4-0x02001FB8: Second control point  
- 0x02001FEC: Computation active flag (set to 1)
**Key calls:** 0x3CE8E: `store_vector_points`
**Callers:** Bézier curve setup before subdivision.

### 12. 0x5E656 - `update_current_vector` (CORRECTED)
**Entry:** 0x5E656 (LINKW %fp,#-56)  
**Purpose:** Updates current drawing vector for line/curve rendering. Computes vector from last point to new point, handles special cases (near-vertical/horizontal lines), and calculates Bézier control parameters.
- fp@(8): New X coordinate  coordinate data  (font metric data)
- fp@(12): New Y coordinate  coordinate data  (font metric data)
1. Computes delta vector (dx, dy)
2. Special cases: |dx|<64 or |dy|<64 → near axis-aligned
3. For large deltas (>650): sets control points for straight lines
4. Otherwise computes Bézier parameters using arctangent approximation
5. Updates control point workspace
- 0x02001FB4-0x02002008: Vector workspace
- 0x02001FEC: Update pending flag  (PS dict operator)
- 0x3CE8E: `compute_vector`
- 0x4C0CA: Fixed-point arctangent approximation
- 0x4C022: Fixed-point multiplication
- 0x4C136: Square root approximation
- 0x1E3EE: `compute_bezier_subdivision` (if pending)  (PS dict operator)
**Callers:** Line drawing routines before curve generation.

### 13. 0x5E90E - `flush_pending_curve`
**Entry:** 0x5E90E (LINKW %fp,#0)  
**Purpose:** Flushes any pending Bézier curve computation. If a curve is pending (flag at 0x02001FEC), completes the curve computation and calls the rendering callback.
- 0x02001FEC: Pending curve flag  (PS dict operator)
- 0x02002070: Rendering callback  (PS dict operator)
- 0x02002074: Secondary callback
- 0x1E656: `update_current_vector` (finalize)
- 0x1E3EE: `compute_bezier_subdivision` (generate curve)
- Indirect call via 0x02002070/74
**Callers:** Path flushing routines before stroke/fill operations.

### 14. 0x5E970 - `process_curve_operation` (NEW FUNCTION)
**Entry:** 0x5E970 (LINKW %fp,#-132)  
**Purpose:** Main handler for PostScript `curveto` operator. Validates curve parameters, computes transformations, and generates Bézier curve segments.
- fp@(8): Path object  stack frame parameter
- fp@(12): x1  stack frame parameter
- fp@(16): y1  stack frame parameter
- fp@(20): x2  stack frame parameter
- fp@(24): y2  stack frame parameter
- fp@(28): x3  stack frame parameter
- fp@(32): y3  stack frame parameter
**Return:** D0 = Success status
1. Validates path object
2. Checks if transformations are needed (bit 6 at 0xA4)
3. Validates curve parameters (non-zero lengths)
4. Computes transformation matrices
5. Sets up emergency mode if clipping active
6. Initializes Bézier computation
7. Generates curve segments
- 0x02017464: Graphics state
- 0x02001FDC-0x02001FE0: Transformation scale factors  (PS CTM operator)
- 0x02002070/74: Callback pointers
- 0x15E6A: `validate_path_object`
- 0x1DF94: `clear_path`
- 0x164AA: `check_curve_parameters`
- 0x1DBEE: `validate_clipping_state`  (PS clip operator)
- 0x4C1C0: Fixed-point conversion
- 0x89A70/88/98/B8/C8: Floating-point operations
- 0x1FD28: `enter_emergency_mode`
- 0x15F90: `setup_curve_rendering`  (PS dict operator)
**Callers:** PostScript `curveto` operator dispatcher.

- **0x5EF7C-0x5EF90**: Floating-point constants for curve computation
  - 0x5EF7C: Constant A (likely 1.0 or π)
  - 0x5EF80: Constant B  
  - 0x5EF84: Constant C
  - 0x5EF88: Constant D
  - 0x5EF8C: Constant E
  - 0x5EF90: Constant F

## CORRECTIONS FROM PRIOR ANALYSIS:
1. **0x5E2D0** was incorrectly described as "curve_to_callback" - it's actually `compute_bezier_control_points`
2. **0x5E3EE** was missed entirely - it's the core Bézier subdivision algorithm
3. **0x5E61C** was missed - initializes Bézier computation
4. **0x5E970** was missed - main `curveto` operator handler
5. Fixed function names to be more accurate (e.g., `update_current_vector` not `update_current_point`)
6. Added detailed algorithm descriptions for Bézier functions

This region contains the complete Bézier curve rendering subsystem for PostScript:
- **Path operations** (stroke/fill/clip) at 0x5E000
- **Basic path callbacks** (moveto/lineto/closepath) at 0x5E280-0x5E2BC
- **Bézier curve computation** at 0x5E2D0-0x5E90E
- **Complete curveto operator** at 0x5E970

The Bézier implementation uses:
1. De Casteljau subdivision with flatness testing
2. Fixed-point arithmetic for performance
3. Special handling for near-axis-aligned lines
4. Callback architecture for rendering integration

; === CHUNK 42: 0x5EC00-0x5F800 ===

The prior analysis had several inaccuracies:
1. **0x5EF7C-0x5EF95 is NOT a data table** - It's actually code that was misidentified. The bytes starting at 0x5EF7C are valid 68020 instructions.
2. **0x5EF96 is NOT `transform_path_coordinates`** - The actual function starts at 0x5EF98 after the LINK instruction.
3. Several function boundaries were in

### 1. 0x5EC00 - `render_path_segments`
**Entry:** 0x5EC00
**Name:** `render_path_segments`
**Purpose:** Processes a linked list of path segments for rendering. Handles different segment types (lines, curves), applies transformations, and manages rendering state. Contains a state machine that walks through path segments, applying coordinate transformations and calling appropriate rendering functions based on segment type. The function appears to handle both regular rendering and special cases like clipping paths.
**Arguments:** Pointer to path structure at fp@(8), mode/flag at fp@(12)
**Return value:** D2 contains status/result (0x5EF74 shows D2 being moved to return)
**Hardware/RAM:** Accesses 0x02017464 (global graphics state), 0x020175FA (transform flag), 0x020175F0/F4 (transform matrix), 0x02017F68+ (path segment table)
**Call targets:** 0x15FA0, 0x1DF50, 0x1CB7A, 0x22C72, 0x1DA80, 0x1E656, 0x1E90E, 0x3CE8E, 0x1C9F2, 0x1E61C, 0x1F6A4, 0x22B10
- Uses a jump table at 0x5ECFE for segment type dispatch (4 cases: 0x5ED00, 0x5ED2C, 0x5ED60, 0x5EEA8)
- Handles coordinate transformation via software FPU calls (0x89AB8 = multiply)  coordinate data  (font metric data)
- Manages linked list traversal with next pointers at offset 8 in segment structures  struct field  (data structure manipulation)
- Has error handling and cleanup paths
- Special handling for clipping paths (checks at 0x5EEF6-0x5EF2A)  (PS clip operator)

### 2. 0x5EF7C - Continuation of `render_path_segments`
**Address:** 0x5EF7C-0x5EF95
**Note:** This is NOT a data table but continuation of the previous function. The bytes are actually instructions:
- 0x5EF7C: `movew %sr,%a0@` (40D0 0000)
- 0x5EF80: `orib #0,%d0` (0000 0000)
- 0x5EF84: `orib #0,%d0` (4000 0000)
- 0x5EF88: `orib #0,%d0` (0000 0000)
- 0x5EF8C: `orib #-16,%d0` (3FF0 0000)
- 0x5EF90: `orib #0,%d0` (0000 0000)
- 0x5EF94: `orib #86,%d0` (4E56 FFF0)

### 3. 0x5EF98 - `transform_path_coordinates`
**Entry:** 0x5EF98 (after LINK at 0x5EF96)
**Name:** `transform_path_coordinates`
**Purpose:** Applies coordinate transformation to all points in a path segment chain. Walks through linked list of path segments, multiplying each coordinate point by transformation values using software FPU. This appears to be a simpler transformation function that applies scaling factors to x and y coordinates.
**Arguments:** Pointer to path head at fp@(8), x-scale at fp@(12), y-scale at fp@(16)
**Hardware/RAM:** Accesses path segment table at 0x02017F68
**Call targets:** 0x89A40 (FPU convert?), 0x89A10, 0x89938 (FPU multiply)
- Uses software FPU for floating-point multiplication
- Processes both x and y coordinates for each segment  coordinate data  (font metric data)
- Simple linked list traversal using next pointers at offset 8  struct field  (data structure manipulation)
- Preserves registers D7 and A5

### 4. 0x5F002 - `remove_path_segment`
**Entry:** 0x5F002
**Name:** `remove_path_segment`
**Purpose:** Removes a segment from a doubly-linked path segment list. Handles updating next/prev pointers and maintains list integrity. Special handling when removing from the current path in graphics state. The function manages multiple linked lists (head, tail, current) and handles various edge cases.
**Arguments:** Pointer to segment pointer structure at fp@(8) (contains head, tail, current pointers)
**Hardware/RAM:** Accesses 0x02017464 (graphics state), 0x02017F68+ (path segment table), 0x02017F70 (segment pointer array)
- Handles doubly-linked list removal with prev/next pointer updates  (data structure manipulation)
- Special case for removing from current path in graphics state (0x5F1B4-0x5F1E8)
- Uses jump table at 0x5F0BA for segment type dispatch (3 cases: 0x5F0BC, 0x5F0BE, 0x5F0C0)
- Manages head/tail/current pointers in the path structure

### 5. 0x5F1EE - `clear_current_path`
**Entry:** 0x5F1EE
**Name:** `clear_current_path`
**Purpose:** Clears the current path from the graphics state by calling `remove_path_segment` on the current path structure. This is a wrapper function that gets the current path pointer from the graphics state and removes it.
**Hardware/RAM:** Accesses 0x02017464 (graphics state)
**Call targets:** 0x5F002 (`remove_path_segment`)

### 6. 0x5F208 - `begin_path_rendering`
**Entry:** 0x5F208
**Name:** `begin_path_rendering`
**Purpose:** Initiates path rendering by setting up rendering context, managing graphics state flags, and preparing for path operations. Handles both regular rendering and clipping paths. This appears to be the entry point for starting a new path rendering operation.
**Hardware/RAM:** Accesses 0x020008F4 (execution context), 0x02017464 (graphics state), 0x02001FA8/0x02001F90 (rendering buffers)
**Call targets:** 0x3B94A, 0x1A580, 0x4DF1C, 0x3B9B4, 0xEA00, 0x1A858, 0x1A7C2, 0x4D8D8
- Sets up execution context stack (0x5F240-0x5F252)
- Manages graphics state flags (bit 6 at offset 0xA4)  struct field
- Handles error conditions and cleanup
- Calls path processing functions

### 7. 0x5F2D8 - `setup_path_rendering_state`
**Entry:** 0x5F2D8
**Name:** `setup_path_rendering_state`
**Purpose:** Configures the path rendering state by initializing path structure pointers and setting up rendering parameters. This function prepares the graphics state for path operations.
**Hardware/RAM:** Accesses 0x02017464 (graphics state)
**Call targets:** 0x1AB70, 0x1A80E
- Initializes path structure in graphics state
- Sets up path rendering parameters  (PS dict operator)
- Configures line width and other rendering attributes  (PS dict operator)  (font metric)

### 8. 0x5F31A - `sort_and_clip_rectangle`
**Entry:** 0x5F31A
**Name:** `sort_and_clip_rectangle`
**Purpose:** Takes two rectangles (defined by min/max coordinates) and sorts them to find the bounding box (union) and intersection (clip). This is used for rectangle clipping operations in the rendering pipeline.
**Arguments:** 8 coordinate values (x1,y1,x2,y2,x3,y3,x4,y4) and 2 rectangle pointers
**Call targets:** 0x89980 (FPU compare)
- Uses FPU compare (0x89980) to sort coordinates  coordinate data  (font metric data)
- Computes union (bounding box) and intersection of rectangles
- Stores results in output rectangle structures
- Handles all 4 coordinate comparisons  coordinate data  (font metric data)

### 9. 0x5F452 - `handle_path_operation`
**Entry:** 0x5F452
**Name:** `handle_path_operation`
**Purpose:** Dispatches path operations based on operation code. Handles different path operations like newpath, moveto, lineto, curveto, etc. Contains a jump table for operation dispatch.
**Arguments:** Operation code at fp@(8)
**Hardware/RAM:** Accesses 0x02001F8C (operation state)
**Call targets:** 0x4C136, 0x5A544, 0x469FA
- Operation dispatch via jump table at 0x5F490
- Handles operation code 0 (newpath) and 1 (other operations)
- For operation 0: calls 0x4C136 and 0x5A544
- For operation 1: sets up operation table and calls 0x469FA

### 10. 0x5F490 - Path Operation Name Table
**Address:** 0x5F490-0x5F524
**Type:** Data table (jump table/string pointers)
**Format:** Array of 16-bit operation codes followed by 32-bit addresses
**Size:** 148 bytes (37 entries × 4 bytes)
**Content:** Maps operation codes to handler addresses for path operations

### 11. 0x5F530 - Path Operation String Table
**Address:** 0x5F530-0x5F5C8
**Type:** Data table (string table)
**Format:** Null-terminated ASCII strings
**Content:** Path operation names:
- "newpath"
- "moveto"  (PS path operator)
- "rmoveto"  (PS path operator)
- "lineto"  (PS path operator)
- "rlineto"  (PS path operator)
- "curveto"  (PS path operator)
- "rcurveto"  (PS path operator)
- "arc"
- "arcn"
- "arct"
- "closepath"  (PS path operator)
- "flattenpath"
- "reversepath"
- "charpath"  (PS font operator)
- "fill"  (PS paint operator)
- "eofill"  (PS paint operator)
- "stroke"  (PS paint operator)
- "pathbbox"
- "clip"  (PS clip operator)
- "eoclip"  (PS clip operator)
- "pathforall"
- "initclip"  (PS clip operator)
- "clippath"  (PS clip operator)

### 12. 0x5F5CC - `sort_path_segments`
**Entry:** 0x5F5CC
**Name:** `sort_path_segments`
**Purpose:** Sorts a linked list of path segments using what appears to be an insertion sort algorithm. Compares segment Y-coordinates (or some other metric at offset 6) to maintain sorted order.
**Arguments:** Pointer to linked list head at fp@(8)
**Return value:** Pointer to sorted list head in D0
- Uses insertion sort algorithm
- Compares values at offset 6 in segment structures (likely Y-coordinates)  coordinate data  (font metric data)
- Maintains sorted linked list  (data structure manipulation)
- Preserves registers A2-A5

### 13. 0x5F630 - `merge_path_segments`
**Entry:** 0x5F630
**Name:** `merge_path_segments`
**Purpose:** Merges two sorted linked lists of path segments into a single sorted list. Uses merge algorithm common for linked lists, comparing values at offset 6.
**Arguments:** Two list pointers at fp@(8) and fp@(12)
**Return value:** Pointer to merged list head in D0
- Standard linked list merge algorithm  (data structure manipulation)
- Compares values at offset 6 in segment structures  struct field
- Handles empty list cases
- Preserves registers A2-A5

### 14. 0x5F6A4 - `process_active_segments`
**Entry:** 0x5F6A4
**Name:** `process_active_segments`
**Purpose:** Processes active path segments for scanline rendering. Manages active edge list, handles segment activation/deactivation, and processes segments for a given scanline. This is part of the scanline rendering algorithm for filled paths.
**Arguments:** Implicit from global state
**Hardware/RAM:** Accesses 0x020020E8 (active segment list), 0x020020E0/E4 (rendering buffers)
- Manages active edge list for scanline rendering  (PS dict operator)
- Handles segment activation based on Y-coordinate  coordinate data  (font metric data)
- Processes Bresenham-style line algorithm for segments
- Updates segment state (active/inactive)
- Complex state machine with multiple loops

### 1. 0x5ECFE - Segment Type Jump Table
**Address:** 0x5ECFE-0x5ED06
**Type:** Jump table
**Format:** 4 × 16-bit offsets
**Content:** Offsets to segment type handlers: 0x0008, 0x002E, 0x0062, 0x01AA

### 2. 0x5F0BA - Removal Type Jump Table
**Address:** 0x5F0BA-0x5F0C2
**Type:** Jump table
**Format:** 3 × 16-bit offsets
**Content:** Offsets to removal type handlers: 0x0008, 0x004C, 0x004C, 0x0082

1. **Path Segment Structure:** Based on the code, path segments appear to have this structure:
   - Offset 0: X-coordinate (32-bit float)  coordinate data  (font metric data)
   - Offset 4: Y-coordinate (32-bit float)  coordinate data  (font metric data)
   - Offset 8: Next segment index/pointer (16-bit)  struct field
   - Offset 10: Segment type (16-bit)  struct field
   - Additional fields at offsets 12-26 for curve control points and rendering state  (PS dict operator)

2. **Rendering Pipeline:** The code shows a complete rendering pipeline:
   - Path construction and transformation (0x5EF98)
   - Segment sorting and merging (0x5F5CC, 0x5F630)
   - Active edge list management (0x5F6A4)
   - Scanline processing and rendering  (PS dict operator)

3. **Coordinate System:** Uses floating-point coordinates with software FPU emulation when hardware FPU is not present.

4. **Linked List Management:** Extensive use of doubly-linked lists for path segments with head/tail/current pointers.

5. **Error Handling:** Robust error handling with cleanup paths and state restoration.

The analysis shows this region contains core graphics rendering functionality for the PostScript interpreter, specifically path rendering operations that are fundamental to PostScript's graphics capabilities.

; === CHUNK 43: 0x5F800-0x60000 ===

## REFINED ANALYSIS OF 0x5F800-0x60000

2. **0x5F9F4** is correctly identified as `create_edge_record`.
3. **0x5FBE0** is correctly identified as `alloc_edge_node`.
4. **0x5FC0A** is correctly identified as `insert_edge_into_active_list`.
5. **0x5FD28** is correctly identified as `reset_edge_system`.
6. **0x5FD68** is correctly identified as `add_edge_to_path`.
7. **0x5FDE2** is correctly identified as `close_path`.
8. **0x5FE1A** is correctly identified as `configure_edge_system`.
9. **0x5FEB6** is correctly identified as `init_scanline_buffers`.
10. **0x5FEF8** is correctly identified as `reset_raster_state`.
11. **0x5FF7E** is correctly identified as `init_raster_system`.
12. **0x5FFC8** is correctly identified as `compare_color_values`.

- The function at 0x5F800 is the **main rasterization loop** that processes contour segments.
- The edge system uses **two memory pools**: 28-byte edge records (0x20020CC-0x20020D0) and 14-byte BST nodes (0x20020D8-0x20020DC).
- The raster buffer is at 0x20020E0-0x20020E4.
- Active edge list is maintained as a **binary search tree** with head at 0x20020EC and tail at 0x20020E8.
- The code implements a **scanline fill algorithm** with edge activation/deactivation.  (PS paint operator)

---

### 1. Function Continuation at 0x5F800 (from 0x5F6EC)
**Actual entry:** 0x5F6EC (based on branch at 0x5F99A)
**Name:** `rasterize_contour_segments`
**Purpose:** Processes a linked list of contour segments for rasterization. Implements scanline algorithm: walks through segments sorted by Y, maintains active edge list, handles horizontal/vertical segments specially, accumulates spans in a buffer, and calls a callback function to output filled regions. Uses fixed-point 16.16 coordinates.
**Arguments (from context):** A5 = segment list pointer, fp@(12) = callback function, D6 = current scanline, D7 = max Y bound
- 0x20020E0: raster buffer pointer
- 0x20020CC-0x20020D0: edge record pool
- 0x20020D8-0x20020DC: BST node pool
- 0x20020E8-0x20020EC: active edge list head/tail
- 0x46334: error/cleanup handler
- 0x5F5CC: segment processing function
- 0x46382: allocation failure (via called functions)  (PS font cache)
**Called by:** Likely `rasterize_path` or similar high-level rasterization function
- Maintains active edge list as BST sorted by X-intercept
- Processes segments until Y > current scanline
- Accumulates horizontal spans in buffer
- Calls callback when buffer fills or at end of scanline  (PS paint operator)
- Handles winding rule via edge direction flags

### 2. Function at 0x5F9F4
**Entry:** 0x5F9F4  
**Name:** `create_edge_record`
**Purpose:** Allocates and initializes a 28-byte edge record from pool. Converts endpoint coordinates from 16.16 fixed-point to integer scanlines, computes slope (dx/dy) for Bresenham-like scan conversion, calculates error term. Handles special cases: horizontal edges (dy=0), vertical edges (dx=0), and general edges. Swaps endpoints if needed to ensure y1 ≤ y2 (top to bottom).
- fp@(8)=x1 (16.16 fixed)  stack frame parameter
- fp@(12)=y1 (16.16 fixed)  stack frame parameter
- fp@(16)=x2 (16.16 fixed)  stack frame parameter
- fp@(20)=y2 (16.16 fixed)  stack frame parameter
**Return value:** D0 = pointer to 28-byte edge record
- 0-1: current X (integer)  (PS path — current point tracking)
- 2-3: (unused?)
- 4-5: y_top (integer)
- 6-7: x_start (integer)
- 8-9: x_end (integer)  (PS dict operator)
- 10-11: y_bottom (integer)
- 12-15: dx (fixed-point slope numerator)
- 16-19: dy (fixed-point slope denominator)
- 20-23: error term (Bresenham)
- 24-25: direction flag (1=right, 0=left)
- 26-27: flags/status
- 0x20020CC/0x20020D0: edge pool current/limit
- Calls 0x46382 on pool exhaustion
**Call targets:** 0x4BFE0 (divide function)
**Called by:** `add_edge_to_path` (0x5FD68), `close_path` (0x5FDE2)
- Swaps endpoints if y1 > y2 (ensures top-to-bottom)  (PS dict operator)
- Converts 16.16 to integer by masking with 0xFFFF0000 and shifting right 16
- For horizontal edges (dy=0): sets dx=0, stores min/max X
- For vertical edges (dx=0): sets dy=0, error=-1
- For general edges: computes dx/dy, reduces precision if values too large (checks bit 30)
- Computes Bresenham error term using division: error = ((y1_frac * dx) - (x1_frac * dy)) / dy
- Adjusts starting X based on error accumulation

### 3. Function at 0x5FBE0
**Entry:** 0x5FBE0  
**Name:** `alloc_edge_node`
**Purpose:** Allocates a 14-byte BST node from the edge node pool for active edge list management.
**Return value:** D0 = pointer to 14-byte BST node
- 0-1: Y coordinate (sort key)  coordinate data  (font metric data)
- 2-5: pointer to edge record
- 6-9: pointer to left child
- 10-13: pointer to right child
- 0x20020D8/0x20020DC: BST node pool current/limit
- Calls 0x46382 on pool exhaustion
**Call targets:** 0x46382 (allocation failure)
**Called by:** `insert_edge_into_active_list` (0x5FC0A)

### 4. Function at 0x5FC0A
**Entry:** 0x5FC0A  
**Name:** `insert_edge_into_active_list`
**Purpose:** Inserts an edge record into the active edge BST, maintaining sort order by Y coordinate (scanline), then by X coordinate for edges starting on same scanline.
**Arguments:** fp@(8) = pointer to edge record
- 0x20020EC: BST root pointer
- 0x20020E8: BST tail pointer (for sequential access)
**Call targets:** `alloc_edge_node` (0x5FBE0)
**Called by:** `add_edge_to_path` (0x5FD68), `close_path` (0x5FDE2)
- Searches BST for insertion point based on edge's Y_top
- Creates new node with `alloc_edge_node`
- Maintains parent/child links
- For edges with same Y_top, sorts by X coordinate (edge record field at offset 6)  coordinate data  (font metric data)
- Updates root/tail pointers as needed
- Implements standard BST insertion with duplicate handling

### 5. Function at 0x5FD28
**Entry:** 0x5FD28  
**Name:** `reset_edge_system`
**Purpose:** Resets the edge rasterization system: clears active edge list, resets memory pools to their base addresses, and reinitializes the "first point" flag.
- 0x20020EC/0x20020E8: BST root/tail pointers (cleared)
- 0x20020F0: first point flag (set to 1)
- 0x20020CC/0x20020D8: pool current pointers reset to base addresses
- 0x20020C8/0x20020D4: pool base addresses
**Call targets:** Graphics state function via indirect call (0x2017464→+0xA0→+0x30)
**Called by:** Path rendering functions when starting new path
**Note:** The indirect call likely flushes any pending rendering or resets graphics state.

### 6. Function at 0x5FD68
**Entry:** 0x5FD68  
**Name:** `add_edge_to_path`
**Purpose:** Adds a line segment to the current path by creating an edge record between the current point and a new point. Handles the "first point" case specially.
- fp@(8) = x2 (16.16 fixed)  stack frame parameter
- fp@(12) = y2 (16.16 fixed)  stack frame parameter
- 0x20020F0: first point flag (1=first, 0=subsequent)
- 0x20020F4/0x20020F8: previous point coordinates  coordinate data  (font metric data)
- 0x20020FC/0x2002100: first point coordinates (when flag is set)  coordinate data  (font metric data)
- 0x4C218 (coordinate conversion)  coordinate data  (font metric data)
- `create_edge_record` (0x5F9F4)
- `insert_edge_into_active_list` (0x5FC0A)
**Called by:** Path construction operators (lineto, etc.)
- Converts coordinates via 0x4C218 (likely from user to device space)  coordinate data  (font metric data)
- If first point (flag=1), stores coordinates as first point  coordinate data  (font metric data)
- Otherwise, creates edge from previous point to new point  (PS path — polygon fill)
- Updates previous point coordinates  coordinate data  (font metric data)
- Maintains closed path tracking

### 7. Function at 0x5FDE2
**Entry:** 0x5FDE2  
**Name:** `close_path`
**Purpose:** Closes the current path by creating an edge from the last point back to the first point, then resets the first point flag.
- 0x20020FC/0x2002100: first point coordinates  coordinate data  (font metric data)
- 0x20020F4/0x20020F8: last point coordinates  coordinate data  (font metric data)
- 0x20020F0: first point flag (set to 1 after closing)
- `create_edge_record` (0x5F9F4)
- `insert_edge_into_active_list` (0x5FC0A)
**Called by:** Path construction operator "closepath"
- Creates edge from last point to first point  (PS path — polygon fill)
- Inserts edge into active list
- Sets first point flag to 1 (ready for new path)

### 8. Function at 0x5FE1A
**Entry:** 0x5FE1A  
**Name:** `configure_edge_system`
**Purpose:** Configures the edge rasterization system memory pools and buffers based on mode parameter.
**Arguments:** fp@(8) = mode (0=reset, 1=?, 2=configure from parameters)
- 0x20020C8/0x20020CC/0x20020D0: edge pool base/current/limit
- 0x20020D4/0x20020D8/0x20020DC: BST node pool base/current/limit
- 0x20020E0/0x20020E4: raster buffer base/limit
**Call targets:** 0x22C9C (parameter retrieval function)
**Called by:** System initialization or page setup
- Mode 0: resets active edge list (clears BST)
- Mode 2: retrieves 6 parameters (3 base/size pairs) via 0x22C9C:  (register = size parameter)
  - Edge record pool (base, size in words)  (register = size parameter)
  - Raster buffer (base, size in words)  (register = size parameter)
  - BST node pool (base, size in words)  (register = size parameter)
- Converts word sizes to byte counts (×2)  (register = size parameter)
- Sets up pool limits

### 9. Function at 0x5FEB6
**Entry:** 0x5FEB6  
**Name:** `init_scanline_buffers`
**Purpose:** Initializes a linked list of scanline buffer descriptors in a pre-allocated array.
- 0x20132A4: free list head pointer
- 0x20132B0: allocation count (cleared)  (PS font cache)
- Buffer array at 0x2012304 (3980 bytes, 199 entries × 20 bytes)
**Called by:** `reset_raster_state` (0x5FEF8) when buffers needed
- Builds singly-linked list of 20-byte buffer descriptors  (data structure manipulation)
- Each descriptor: first word = link to next (offset from 0x2012304)  struct field
- Initializes with 199 entries (3980/20 - 1)
- Sets free list head to first entry

### 10. Function at 0x5FEF8
**Entry:** 0x5FEF8  
**Name:** `reset_raster_state`
**Purpose:** Resets all rasterization state variables to their defaults, including color, clipping, and buffer management.
**Hardware/RAM:** Numerous state variables:
- 0x200D0D4, 0x200D0D0, 0x200D0E8: clipping bounds  (PS clip operator)
- 0x200D0CC: default color (30 = 0x1E?)  (PS dict operator)
- 0x20122F8: unknown state (14)
- 0x20161CC: flag byte
- 0x2016194: counter (8)
- 0x201619C/0x2016198: position counters
- 0x20132A8: buffer index
- 0x20161BC: unknown pointer
- 0x20161B0/0x20161C8: rendering state flags  (PS dict operator)
- 0x20161C0/0x20161C4: position accumulators
- `init_scanline_buffers` (0x5FEB8) if buffers allocated
- 0x6098C (rendering function) if rendering active  (PS dict operator)
**Called by:** `init_raster_system` (0x5FF7E) and page setup

### 11. Function at 0x5FF7E
**Entry:** 0x5FF7E  
**Name:** `init_raster_system`
**Purpose:** Initializes the entire rasterization system: resets graphics state, allocates edge record pool, initializes raster state, and sets up color bounds.
- 0x2002104: edge record pool (size from 0x200D0CC)  (register = size parameter)
- 0x20161DC/0x20161E0/0x20161E4: color comparison bounds
- Graphics state reset (indirect call via 0x2017464)
- 0x4DE50 (memory allocation)  (PS font cache)
- `reset_raster_state` (0x5FEF8)
**Called by:** System initialization
- Calls graphics state reset
- Allocates edge record pool based on 0x200D0CC value
- Initializes raster state
- Sets color bounds: min = 0, max = 0x7FFFFFFF, current = 0

### 12. Function at 0x5FFC8
**Entry:** 0x5FFC8  
**Name:** `compare_color_values`
**Purpose:** Compares two color values (likely CMYK or RGB tuples) lexicographically.
- fp@(8) = pointer to first color  stack frame parameter
- fp@(12) = pointer to second color  stack frame parameter
**Return value:** D0 = -1 (first < second), 0 (equal), 1 (first > second)
**Called by:** Color sorting/selection functions
- Compares 4 color components (likely CMYK)
- Skips 8-byte header (probably color space identifier)
- Returns at first differing component
- Uses 16-bit comparisons (colors likely stored as 0-65535)

---

- **0x5FEB6-0x5FEB9**: Appears to be misaligned code (oridata 0x0000 4E56). The function actually starts at 0x5FEBA based on the LINK instruction.
- **No string tables or jump tables** in this range - all executable code.

- All function identifications and descriptions were accurate.
- Added detailed algorithm descriptions for each function.

This region contains the core rasterization engine for the PostScript interpreter. It implements:
1. **Edge-based scanline fill algorithm** with active edge list (BST)
2. **Path construction** (add_edge_to_path, close_path)
3. **Memory pool management** for edges and BST nodes
4. **System initialization** for raster operations
5. **Color comparison** for rendering decisions

The code is highly optimized 68020 assembly with careful fixed-point arithmetic for coordinate transformations and edge slope calculations.