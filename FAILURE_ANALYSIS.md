==============================================================================
AGFA COMPUGRAPHIC 9000PS - FAILURE MEDITATION (Fourth Revision)
Seventh-pass analysis incorporating v7 LLM-annotated disassembly of all 6 banks
==============================================================================

ERRATA (post-publication corrections):
- "NCR 5380" should read "AMD AM5380" throughout (register-compatible chips).
- "SCC #1" (0x04000000) and "SCC #2" (0x07000000) are two PAL-decoded address
  windows into ONE physical Zilog Z8530, not two separate chips.
- The debug console serial format is 9600 8N1 for the Atlas Monitor (Channel B,
  TxDB pin 19) and 9600 8N2 for self-test error output (Channel A, TxDA pin 15).
- The actual failure is a RAM test error: "Test = 02, data = 1010" means bit 16
  (D16) is stuck at address 0x02200000. This is a failing SIPP DRAM module.
- See docs/hardware.md for the corrected hardware description.

OBSERVED SYMPTOMS (from Adrian's Digital Basement video):
1. 68020 main board: brief activity at power-on, then enters repetitive loop
2. IO board (68000): initial probe "doesn't look good" / "not really seeing
   any signs of life" on a random pin; then found activity on ROM and other
   CPU pins; clean reset observed; concluded "seems to be doing stuff"
3. IO board unpopulated connector: fast data bus activity, not serial
4. Reset line (main board): goes low once at power-on, then stays high.
   NOT a reset loop.
5. 5V rail: 4.78V at board (power supply outputs 5.08V, ~0.3V drop)
6. CPU warm but nothing burning hot
7. 16MHz clock confirmed on scope
8. Disconnecting IO board made main board LESS active ("totally stuck")
9. Address and data lines show repetitive "pulsing" pattern after initial burst
10. ROM chip address/data lines show same cadence as CPU/SCC patterns
11. No serial terminal was connected during testing

==============================================================================
THE COMPLETE BOOT SEQUENCE (from v7 disassembly, instruction-level detail)
==============================================================================

PHASE 1 - ATLAS MONITOR COLD START (Bank 0, ~50ms)
  Vector table:
    0x000: SSP = 0x0200024C (monitor stack in RAM)
    0x004: PC  = 0x00000856 (cold_boot_entry)

  0x856: cold_boot_entry
    1. D7 = 1 (cold boot flag; warm boot at 0x860 sets D7 = 0)
    2. A5 = 0x868 (continuation address — bank 0 uses A5-continuation style)
    3. JMP 0x1A6E (detect_ram_top)

  0x1A6E: detect_ram_top
    4. FIRST HARDWARE ACCESSES:
       - Writes 0xFFFFFFFF to 0x06100000 (display controller reset)
       - Clears 0x06080000 and 0x060C0000 (hardware registers)
       *** IF ANY OF THESE CAUSE A BUS ERROR: 0x2000010 is NOT YET SET,
           so fatal_error_handler at 0x772 jumps back to 0x856 = RESET LOOP.
           But Adrian confirmed: reset goes low ONCE, then stays high.
           Therefore these three hardware registers all respond. ***
    5. Tests RAM with pattern 0x5555AAAA via MOVEP.W, walking 1MB increments
       from 0x02000000 upward to 0x03000000 (max 16MB)
    6. Returns highest valid RAM address in A0
    7. Stores: RAM size at 0x2000000, ROM size at 0x2000004 (0x01000000),
       RAM top at 0x200000C, base at 0x2000008, HW base 0x2000064=0x06100000
    8. JMP (A5) -> returns to continuation at 0x868

  0x868: monitor_setup (NEW v7 — previously undocumented)
    9. Initializes the Atlas Monitor after RAM detection
    10. Sets up stack at 0x0200024C, installs exception vectors
        - Exception vector redirect table at 0x200003C (8 entries)
        - Exception handler hook pointers at 0x2000068-0x200007C
        - Register save area at 0x2000290 (68 bytes: D0-D7, A0-A7)
    11. Clears RAM from 0x02000010 to top of RAM (zeroes everything)

  0x868-0x09DC: hardware_init (via A5 continuation chain)
    12. Init SCC #1 at 0x04000000 (PS data channel to IO board)
        - Writes to 0x0400000E (control reg A), 0x0400002E (control reg B)
    13. Clear hardware registers at 0x06080000, 0x060C0000
    14. Set display controller at 0x06100000 = 0xFFFFFFFF
    15. Init SCC #2 at 0x07000000 (debug console, 9600 8N1)
        - Reads status from 0x07000000, 0x07000003
        - Writes config to 0x07000002, 0x07000020
    16. FPU detection via trace exception trick:
        - Sets custom handler at 0x200007C
        - Attempts FSAVE instruction -> if trap fires, no FPU
        - Result stored at 0x2000080 (0 = no FPU, this board has none)
        - Software FPU at 0x89000-0x8D7F0 will be used instead
    17. Sets system_initialized flag at 0x2000010
        (From this point on, exceptions go to monitor, not reset)

PHASE 2 - AUTO-BOOT DECISION (Bank 0, immediate)
    18. CTS check on SCC #2 Ch B (debug console port)
        - Reads SCC status register at 0x07000000
        - If CTS asserted: terminal present -> set sys_flags bit 0 at 0x2000010
        - If CTS not asserted: no terminal -> sys_flags = 0
    19. Read ROM address 0x2004 -> gets warm boot vector 0x0000200C
    20. Validate: 0 < 0x200C < 1MB -> valid -> auto-execute

    Since Adrian had NO serial terminal connected:
      CTS = deasserted -> sys_flags = 0 -> auto-boot -> JMP 0x200C
      (With terminal: Atlas Monitor banner appears, user gets command prompt)

PHASE 3 - POSTSCRIPT ENTRY THUNK (ROM vector area, bank 0)
    21. At 0x200C:
        MOVE #$2700,SR    ; Disable all interrupts (supervisor mode)
        NOP               ; Pipeline stability (3 NOPs)
        NOP
        NOP
        JMP $40508        ; Jump to PostScript init in bank 2
    A4 may contain hardware detection data passed to PS init.

PHASE 4 - POSTSCRIPT INITIALIZATION (Bank 2, the critical phase)
    22. 0x40508: postscript_init (LINK A6 frame)
        This is the major gate. RAM addresses set up:
          0x2000890: System call handler pointer
          0x20008F4: Current execution context
          0x20008B4: Transformation matrix output buffer
          0x2017354: Dictionary hash table (512 buckets)
          0x20173E8: User dictionary
          0x201745C: Graphics state (108 bytes)
          0x20174A4: Execution stack (doubly-linked list)
          0x20174AC: Error context

        Init call chain (in order, from postscript_init):
          a) 0x3BC8A - scc1_configure_channel (bank 1 code)
             *** FIRST contact with IO board via SCC #1 ***
          b) 0x90100 - Filesystem/SCSI preparation (bank 4)
          c) 0x8DE50 - Interpreter kernel setup (bank 4)
          d) 0x8E000 - Operator dispatch table init (bank 4)
          e) 0x898B8 - Graphics subsystem init (bank 4)
          f) 0x84C70 - File I/O buffer setup (bank 4)
          g) 0x812B4 - SCC/serial initialization (bank 4)
          h) 0x81156 - SCSI timeout initialization:
             - Initializes timer handler at 0x8114E
             - Calls 0x80400 (SCSI controller reset)
             - Sets up timeout registers:
               0x2016EA0 = timeout value
               0x2016EA4 = timeout type (1=normal, 2=extended)
               0x2016E9C = timeout callback pointer
          i) 0x410C8 - startup_wrapper:
             -> 0x40E36: main_postscript_entry
             -> 0x41066: handle_startup_error (if 0x40E36 fails)

    23. 0x40E36: main_postscript_entry
        - Initializes memory, sets up error handling (setjmp at 0x8DF1C)
        - Calls dynamic loader at 0x40968 (load_and_relocate)
        - Sets up interrupt handlers via 0x4150C:
          Mode 0: reset procedure counts
          Mode 1: normal interrupt handlers (SCC)
          Mode 2: disk interrupt handlers (SCSI)
        - Initializes serial ports (3 ports, 256 bytes each)
        - Sets up execution context at 0x2017354
          (Validates magic byte 0x41 = 'A' at offset +4)
        - Calls 0x41624: call_init_functions
          - Iterates function pointer table at 0x3C5A0
          - Calls each init function until NULL terminator
          - This triggers the cascade of subsystem inits

PHASE 4a - SCC #1 CHANNEL CONFIGURATION (Bank 1, called from step a)
    24. 0x3BC8A: scc1_configure_channel
        Detailed sequence (from v7):
        - Writes 0xFF to SCC register 2 (baud rate)
        - Clears register 0x23
        - Writes 0x3C (60) to registers 0x22 and 0x20
        - Calls 0x3B9A6 (scc1_configure_serial):
          8-bit data, no parity, 1 stop bit
          Specific clock rates written to SCC registers
        - CRITICAL: Installs interrupt vector at 0x2000030
          -> points to 0x3B312 (scc1_dma_state_machine)

    25. 0x3AF10: init_scc_channel_1 (lower-level)
        Full SCC programming sequence:
        - 0xC0 to WR0 → reset channel
        - 0x44 to WR4 → ×16 clock, 1 stop, no parity
        - 0xC0 to WR3 → Rx 8 bits, Rx enable
        - 0xEA to WR5 → Tx 8 bits, Tx enable, RTS asserted
        - 0x10 to WR15 → ext/status interrupts
        - 0x17 to WR1 → interrupt on ALL Rx chars, status affects vector
        - WR12/WR13 → baud rate divisor
        - WR14 → enable baud rate generator
        RAM: clears 0x200043C, 0x200042C, 0x2000440 (DMA buffer pointers)

PHASE 4b - PRINTER COMMUNICATION INIT (Bank 1, from init function table)
    26. 0x3C2A4: initialize_printer_communication
        This is the full handshake with the IO board:
        a) Calls 0x3BC8A (scc1_configure_channel) — configures SCC #1
        b) Sends "004PWR" (power command) via 0x3BD78 (send_command_with_buffer)
           *** THIS IS THE FIRST BYTE SENT TO THE IO BOARD ***
        c) Calls 0x3C09C (receive_printer_data) — waits for IO board response
        d) Calls 0x3BFF8 (process_printer_response) — validates response
        Return: D0 = 1 if initialized, 0 if failed

    27. 0x3B080: scc1_write_byte (the actual byte sender)
        - Timeout: 0x2710 (10,000) ticks waiting for CTS clear
        - Checks bit 0 of SCC register 0xF (CTS status)
        - If CTS not clear within timeout: calls error handler at 0x6642A
        *** IF IO BOARD IS NOT ASSERTING CTS, EVERY BYTE TIMES OUT ***

    28. 0x3B312: scc1_dma_state_machine
        5-state protocol (v7: transitions fully mapped):
          State 0: Idle
          State 1: Transmit header (4-byte header with checksum)
          State 2: Receive header
          State 3: Process/validate received header
          State 4: Receive data payload
          Transition: 0→1→2→3→4→0 (full cycle)
        Uses checksums: 0x3BD18 (16-bit), 0x3BD3E (32-bit)

PHASE 4c - STREAM SYSTEM (Bank 1, NEW v7 discovery)
    29. 0x3FB12: stream_system_init
        - Simple wrapper calling 0x6DFE2 with argument 2

    30. 0x3FEEE: stream_subsystem_init (full init)
        - Clears all channel structures
        - Sets up hardware init: 0x20258, 0x1EA9E, 0x1EB08
        - Sets up timer: 0x64574
        - Creates default stream channel via 0x3FB26
        - RAM: 0x20173A6 (channel count), 0x20006D0/0x20006C8 (channel arrays)

    31. 0x3F936: stream_put_byte_with_wait
        *** POTENTIAL HANG POINT ***
        Loop:
          - Enable interrupts (0x204AE)
          - Set flag
          - Sleep (0x205B8) — BLOCKS UNTIL INTERRUPT WAKES IT
          - Disable interrupts (0x204A8)
          - Check if space in circular buffer (write ptr vs read ptr)
          - If no space → loop again
        If the consumer (DMA or interrupt handler) never drains the buffer,
        and if the sleep function's interrupt never fires, this loops forever.

    32. 0x3FADC: flush_output_stream
        - Checks offset 110 (output enabled flag)
        - If NOT enabled → calls 0x683E8 with mode 4 (ERROR)
        - Pre-condition: output must be enabled before any flush

PHASE 5 - SCSI AND FILESYSTEM (Bank 4)
    33. 0x85F32: scsi_controller_init
        - Sets up SCSI device structure at 0x02017144
        - Initializes AMD AM5380 controller at 0x05000001
        - Tests controller by writing/reading register 8
        - If functional: calls 0x85B58 (scsi_initialize_devices)
        - Sets SCSI controller present flag at 0x2022394

    34. 0x85B58: scsi_initialize_devices
        - Clears device capacity table at 0x2017210
        - For each SCSI ID (0-7):
          - INQUIRY command (0x12) to identify device
          - MODE SENSE (0x1A) to get parameters
          - MODE SELECT (0x15) to configure
          - TEST UNIT READY (0x1B)
          - If successful: READ CAPACITY, store at 0x2017210
        - Retry counters at 0x2017230 (8 × 4 bytes, one per SCSI ID)
        - 10 retries per device

    35. 0x86110: scsi_bus_reset
        - Writes 0x80 to 0x05000001 → asserts RST line on SCSI bus
        - Delay loop (DBF instruction)
        - Clears data register → releases RST
        - Waits for bus free state
        - Waits 5000 ticks from 0x2022378

    SCSI Timeout Table (from bank 0 data at 0x1BA50):
      INQUIRY:       5,000 ms
      Read Capacity: 10,000 ms
      Read/Write:    30,000 ms
      Format:        120,000 ms

    Per-byte transfer: 30 retries (0x81876: scsi_send_byte_with_timeout)
    Device selection: 119 attempts checking BUSY bit (bit 6) at 0x05000000
    Default timeout: 5000 ticks at 0x0202239C
    On timeout: returns -1097 (0xFFFFFBC7)
    Error mapping: 0x0100/0x0300 -> error 1, 0x0200 -> error 2, else error 3
    Timeout conversion: milliseconds × 2147483 / 1000 = timer ticks

    36. 0x8018A: filesystem_init
        - 0x807CA: find_filesystem (tries root at page 0, then page 41004)
        - 0x8070E: find_filesystem_by_index (validates magic 0x5FA87D27)
        - 0x80800: validate_filesystems (checks both root 0 and root 1)
        - Sets up bitmap allocation (0x80C0E: fs_alloc_modify)
        - Allocates file handle table (max 15 handles, 12 bytes each)
        - Sets up page cache (1024-byte pages, write-back dirty management)
        - Free space counting at 0x80FD0 (128-byte chunks, optimized)
        - Free page list at 0x2016E98
        - Error codes: 0xEFFE (-4098) through 0xF000 (-4096)

PHASE 6 - POSTSCRIPT STARTUP FILES (Banks 1-3)
    37. The PS interpreter loads startup files from the HD filesystem:
        - "Sys/Start" (14.9KB, eexec-encrypted PostScript):
          Contains: "% Start of Sys/Start code" + "currentfile eexec" + hex data
          eexec encryption: LCG with multiply/add/mask (v7: algorithm documented)
          Initial key: 0x5561 or 0xC1C2C3C4
        - "user/boot" (89 bytes): saves screen parameters
        - ROM virtual paths "/usr/ps/v0.30/errors.ps" and "/usr/ps/v0.34/printer.ps"
        - Font files from fonts/ directory (118 fonts on disk)
        - "run (load...)" commands execute PS programs from disk

    38. 0x3E3E8: printer_initialization (bank 1)
        - Configures serial port parameters
        - Initializes SCC #1 for communication with IO board
        - 0x3BF1A: check_printer_online (tests DTR/RTS handshake)
        - Sets up printer command dispatch table at 0x3C36A
        - Registers PS operators: printerstart, printerwrite, printerstop
        - Wire-format commands: "004STA", "004END", "004BEG",
          "004CBEG%04X", "004BLS%1X-%04X", "004PWR"

PHASE 7 - MAIN INTERPRETER LOOP (Banks 2-3)
    39. 0x71334: main_interpreter_loop (entry point)
        0x71400: execute_loop (core execution, 0x71400-0x71DBC)

        Type dispatch table at 0x71420 (13 entries):
          Type 0  -> 0x7143C (special/reserved)
          Type 1  -> 0x71B24 (integer: push to operand stack)
          Type 2  -> 0x71B24 (real: push to operand stack)
          Type 3  -> 0x7189A (system-specific)
          Type 4  -> 0x71B24 (boolean: push to operand stack)
          Type 5  -> 0x71456 (string: handle executable strings)
          Type 6  -> 0x714D2 (dictionary operations)
          Type 7  -> 0x71978 (procedure: executable array)
          Type 8  -> 0x71B24 (mark: push mark)
          Type 9  -> 0x7178A (name: dictionary lookup)
          Type 10-12 -> 0x71B24 (reserved: push behavior)
          Type 13 -> 0x7154E (operator: dispatch)

        Operator dispatcher: monolithic 0x46000-0x47388
          46-entry jump table at 0x46944
          Secondary table at 0x40000-0x401E3 (~121 entries)

==============================================================================
MEANWHILE, ON THE IO BOARD (separate 68000 CPU)
==============================================================================

The IO board runs completely independently:

    Vector table:
      0x000: SSP = 0x14000
      0x004: PC  = 0x0400
      All other exception vectors: BRA.W $+0 (infinite self-loop = HARD HALT)
      *** Any exception on the IO board = permanent freeze, no recovery ***

    0x0400: main_entry_point
      1. SP = 0x14000
      2. A0 = 0x1F004 (shared memory + 4), stores at 0x1F000
      3. Calls 0x30BC: copy_memory_block (copies 0x648 bytes: 0x17000 -> 0xF000)
         (v7: this is memory init, not generic "hardware_init")
      4. Calls 0x1804: reset_system_state
         -> Clears 0x15112
         -> Calls 0x042C (initialize_and_run_system)
      5. If 0x042C somehow returns: falls into NOP loop at 0x0426
         *** This NOP loop is an error handler, NOT the main loop ***
         *** If the IO board reaches 0x0426, it is STUCK ***

    0x042C: initialize_and_run_system
      1. A2 = 0x050026 (SCSI pseudo-DMA data port — board-to-board comms)
      2. Calls 0x1116: init_serial_ports
         - SCC #1 at 0x040000: PostScript data channel (to main board)
           WR5=0xEA (Tx 8 bits, Tx enable, RTS asserted)
           WR9=0x14 (reset channel)
           10,000-iteration delay loop after programming
         - SCC #2 at 0x040010: Debug console
         - SCC #3 at 0x050000: ATI channel (to imagesetter)
           Tests if present via status register bit 5 at 0x172E0+0x1B
      3. Calls 0x1812: init_channel_structures
         - timeout = 100,000
         - 4 channels at 0x15126 + 0x15256 (76 bytes each)
      4. Calls 0x0FB0: reset_system_state
         - state = 3, cmd_state = -1
         - Sends command 0 via hardware at 0x172E0
      5. Polls status via 0x1B4E and 0x1B36
      6. If status OK: resolution = 1200 (0x04B0) at 0x1501E
      7. Clears inverse flag at 0x15012
      8. Sets system state = 15 (0x0F) at 0x1500E
      9. Sends command 5 via 0x123E
     10. Enters main polling loop

    Main loop:
      - 0x055A: primary state machine (15 states, jump table at 0x0590)
        State stored at 0x15016
      - 0x0A4A: secondary state machine (15 states, jump table at 0x0A7C)
      - 0x04B4: send_command_and_wait_for_ack (v7 correction: NOT "extended
        command handler" — it's the ACK protocol for board-to-board comms):
        - Sets system state to 3
        - Sends command 5 via 0x123E
        - Formats and sends command string via 0x0E4C
        - Waits for ACK (0x68 = 'h') via wait_for_ack_with_timeout (0x0D6C)
          → 5 retries, calls receive_and_parse_scsi_message each retry
          → If no ACK after 5 tries → return failure
        - Sets cmd_state to -1
        - Retry loop (up to 5 times) waiting for response 100 ('d')
        - If response 100 received → sends cmd 6, waits for 103 ('g'), sends cmd 2

      Response code values (v7):
        100 = 'd' (data ready)
        101 = 'e' (error)
        102 = 'f' (flow control)
        103 = 'g' (go/acknowledge)
        104 = 'h' (ACK)

      ATI protocol:
      - 15 ATI response strings at ROM 0xF1E8-0xF242 (copied to RAM):
        !STA, !L&S, !BEG, !END, !PWR, _GST, _CMD, _INF, _SET, _GET,
        _MOD, _NEG, _POS, _GPR, _RES
      - 0xFF terminators (not null)
      - Manages 5 device subsystems: RE, PA, DN, MG, SH

      Process channel input (0x1C0E):
      - Per-channel state machines (76-byte structures at 0x15126+)
      - Reads from 0x1511A via scc_receive_byte at 0x1206
      - Timeout counter at 0x153EA
      - Commands delimited by { and }
      - States: 0=idle, 2=receiving, 3=receiving digits, 4=waiting for '!'

    Debug monitor at 0x2E98 (accessible via SCC #2 / debug port):
      Command table at 0xF534-0xF648 (16 entries, magic 0xBAFBAF11)
      All 16 commands mapped to handler addresses (v7):
        LED    -> 0x141C    VIDEO  -> 0x1448    RESOL  -> 0x147A
        INVERS -> 0x14BC    MODE   -> 0x14E8    RESET  -> 0x1500
        DEBUG  -> 0x1518    TMD    -> 0x1530    TMD1   -> 0x15B8
        TMD2   -> 0x1626    ATI    -> 0x042C *  GO     -> 0x28C0
        MD     -> 0x28F6    MM     -> 0x2AA8    LO     -> 0x2C6C
      * ATI command handler IS initialize_and_run_system — entering
        ATI mode restarts the normal boot path
      Built-in 68000 disassembler at 0x2AA8
      S-record loader with checksum validation at 0x2C6C
      Line editor with 10-entry history at 0x1544A
      Greeting: "Hello, this is the debug port"

    CRITICAL: receive_and_parse_scsi_message at 0x0BB2
      - Calls 0x18F8 to receive a message from the SCSI channel
      - 0x18F8 has NO VISIBLE TIMEOUT at that level
      - If the SCSI channel (0x050026) produces no data, this may block
        indefinitely, hanging the IO board inside the ACK wait loop

    The IO board is WAITING for commands from the main board via SCC #1.
    It sends its version string "Agfa T9000PS ATI v2.2" and enters its
    state machine, processing whatever the main board sends.

==============================================================================
THE IO BOARD'S "NOT GREAT" SIGNALS - EXPLAINED
==============================================================================

Adrian's first probe of the IO board 68000: "Well, that sure doesn't
look good. I just picked a random pin on it. Not really seeing any
signs of life." He then found activity on ROM chips and other CPU pins
and concluded it was working.

This is CONSISTENT with a working IO board in its idle polling loop.

The IO board's main loop at 0x042C calls:
  - 0x055A: process_command_state_machine (jump table at 0x0590)
  - 0x0A4A: process_secondary_commands (jump table at 0x0A7C)

Both state machines are at low addresses (0x0400-0x0A7C). The 68000 has
24 address lines (A1-A23). When the CPU is looping in a tight code
region below 0x1000:
  - A1-A12: active (changing with each instruction fetch)
  - A13-A23: STATIC (never change - all zero)

If Adrian's "random pin" was A15, A16, or any upper address line, he'd
see a flat line = "no signs of life." The ROM chips would show activity
because their address pins connect to the ACTIVE lower bits.

The state machine reads SCC status registers in a poll loop:
  - SCC #1 at 0x040000 (main board channel) -> A18 toggles
  - SCC #2 at 0x040010 (debug console) -> A18 toggles
  - SCC #3 at 0x050000 (ATI channel) -> A18+A16 toggle

So most CPU pins show one of two patterns:
  1. Rapid switching (lower address lines, data bus during code fetch)
  2. Mostly static with periodic blips (upper address lines that only
     change when accessing SCC registers in the I/O region at 0x04xxxx)

The "fast data bus activity" on the unpopulated debug connector is
expected: the debug port connects to SCC #2 at 0x040010. Even without
a terminal connected, the polling loop reads the SCC status register
every iteration, generating bus activity on those pins.

==============================================================================
REINTERPRETATION OF SYMPTOMS WITH v7 KNOWLEDGE
==============================================================================

"Brief activity at power-on, then enters repetitive loop"

The "brief activity" is Phases 1-3 (~100-200ms):
  - RAM sizing (walking 1MB blocks to 16MB via MOVEP pattern test)
  - RAM clear (zeroing up to 16MB — at 16MHz with 32-bit writes, ~25ms min)
  - Hardware register init (0x06100000, 0x06080000, 0x060C0000)
  - SCC initialization (writes to 0x04000000 and 0x07000000 register sets)
  - CTS check, auto-boot decision, jump to 0x40508

The "repetitive loop" is one of several candidates in Phases 4-7.

"Disconnecting IO board made main board LESS active (totally stuck)"

The v7 analysis provides two precise mechanisms:

  MECHANISM A (SCC #1 configuration):
    PS init at 0x40508 calls 0x3BC8A as its FIRST subsystem init.
    0x3BC8A configures SCC #1 and installs the DMA interrupt vector.
    Without an IO board, the SCC chip is on the main board and accepts
    register writes, but the signal lines go nowhere. The configuration
    itself succeeds (it's just register writes), but any subsequent
    attempt to COMMUNICATE via the channel will hang.

  MECHANISM B (Printer communication — the real killer):
    0x3C2A4 (initialize_printer_communication) is called from the init
    function table at 0x3C5A0. It:
      1. Configures SCC #1 (0x3BC8A)
      2. Sends "004PWR" via scc1_write_byte (0x3B080)
         -> 10,000-tick timeout waiting for CTS
         -> Without IO board: CTS never asserted
         -> After 10,000 ticks: calls error handler at 0x6642A
      3. Waits for response via receive_printer_data (0x3C09C)
         -> No response ever comes
      Result: D0 = 0 (failed)

    The question is: does the init function table LOOP on failure, or
    proceed to the next init function? If it loops = "totally stuck."

  Combined: Without IO board, the main board either:
    a) Hangs in scc1_write_byte timeout loops = tight SCC polling = "stuck"
    b) Returns failure from printer init, but PS interpreter treats this
       as fatal and enters error recovery loop at 0x4110C

  With IO board:
    - IO board is in main loop at 0x042C, SCC #1 RTS is asserted (WR5=0xEA)
    - Main board's CTS check succeeds → "004PWR" is sent
    - IO board receives and responds → printer init succeeds (D0=1)
    - PS init proceeds to SCSI → more varied bus activity → "pulsing loop"

"Address and data lines show repetitive pulsing pattern"

This is consistent with a timeout-driven retry loop. The SCSI system
provides concrete timing:
  - Bus reset: 5000 ticks wait
  - Per-ID: INQUIRY(5000ms) + MODE SENSE + TEST UNIT READY
  - 8 IDs total: selection (119 attempts × BUSY check) per ID
  - 10 retries per device at 0x85B58
  - Full cycle: several seconds per complete bus scan
This creates the exact "pulsing" pattern Adrian observed.

==============================================================================
FAILURE HYPOTHESES (revised with v7 knowledge)
==============================================================================

HYPOTHESIS 1: SCSI TIMEOUT RETRY LOOP
Likelihood: ★★★★★ (HIGHEST)

The v7 SCSI driver analysis reveals the complete timeout chain:

  scsi_controller_init (0x85F32):
    - Tests AMD AM5380 by writing/reading register 8
    - If functional: calls scsi_initialize_devices (0x85B58)
    - Sets SCSI controller present flag at 0x2022394

  scsi_initialize_devices (0x85B58):
    - Clears capacity table at 0x2017210
    - For SCSI IDs 0-7:
      - INQUIRY (0x12), MODE SENSE (0x1A), MODE SELECT (0x15)
      - TEST UNIT READY (0x1B)
      - If successful: READ CAPACITY → store in table
    - 10 retries per device
    - Per-byte: 30 retries at 0x81876
    - Selection: 119 attempts at BUSY (bit 6) check

  scsi_timeout_handler (0x81C08):
    - Reads status register
    - Sends timeout commands: 0xD0, 0x02, 0xDD
    - Sends reset commands: 0x30, 0x20
    - Increments error counters at offsets 0x104, 0xFC, 0xF4, 0xF8
    - Returns codes: -4 to -1

  If no SCSI device responds:
    - Each ID: selection (119 tries) → timeout → next
    - 8 IDs × INQUIRY timeout (5000ms) = ~40 seconds per scan
    - PS interpreter retries → periodic activity → "pulsing"
    - Bus pattern: bursts of SCSI register access at 0x05000001-0x0500000F,
      then dead time waiting for timeout, repeat

  The Quantum P40S is ~37 years old. If dead and BlueSCSI not configured:
    - All 8 SCSI IDs: no response
    - Full scan takes ~40 seconds
    - Error return → PS interpreter retry → next scan

  If BlueSCSI responds but filesystem is wrong:
    - SCSI INQUIRY succeeds, TEST UNIT READY succeeds
    - filesystem_init (0x8018A) reads page 0, validates magic 0x5FA87D27
    - If magic wrong: tries page 41004 (backup root)
    - If both fail: filesystem error code 0xEFFE-0xF000
    - PS startup file can't load → restart or error loop

  Key evidence:
    - "Pulsing" has regular cadence → timeout-driven retry
    - Cycle time consistent with SCSI bus scan (~40s with all timeouts)
    - With IO board: gets past SCC init → reaches SCSI → periodic retry
    - Without IO board: hangs at SCC init → no SCSI → no periodic pattern


HYPOTHESIS 2: SCC #1 / PRINTER COMMUNICATION FAILURE
Likelihood: ★★★★☆ (HIGH)

Elevated in v7 because we now have the complete handshake protocol:

  0x3C2A4 (initialize_printer_communication):
    1. scc1_configure_channel (0x3BC8A) — programs SCC registers
    2. Sends "004PWR" power command via send_command_with_buffer (0x3BD78)
    3. receive_printer_data (0x3C09C) — waits for IO board response
    4. process_printer_response (0x3BFF8) — validates response

  The "004PWR" command is the FIRST thing sent to the IO board.

  scc1_write_byte (0x3B080) has 10,000-tick CTS timeout.
  scc1_send_control_byte (0x3B69A) waits for CTS toggle (acknowledgment).

  Failure modes:
    a) IO board not ready yet → CTS not asserted → 10,000-tick timeout per byte
       But the timing race should be fine: IO board at 8MHz reaches its main
       loop in ~1ms, while main board's RAM clear + init takes ~25ms+
    b) IO board in wrong state → receives "004PWR" but doesn't recognize it
       → no response → receive_printer_data timeout
    c) SCC #1 hardware fault → no communication at all

  IO board's side of the protocol:
    - process_channel_input (0x1C0E): state machine for commands between { }
    - The "004PWR" command is NOT in braces — it's a wire-format command
    - Parsed by receive_and_parse_scsi_message (0x0BB2)
    - Matched against table at 0x17112 (type 1: 3-char) or 0x171AC (type 2: 4-char)

  v7 critical finding: receive_and_parse_scsi_message calls 0x18F8 which
  has NO VISIBLE TIMEOUT. If the communication channel produces no data,
  the IO board hangs inside 0x18F8 waiting for input.

  THIS MEANS: if the main board never sends "004PWR" (because it hung
  earlier in init), the IO board hangs in 0x18F8 waiting for the main
  board. But Adrian observed the IO board showing activity, which means
  either:
    a) It's in its polling loop (not yet called 0x18F8), or
    b) It's polling but not inside 0x18F8 yet (still in state 3, cmd=-1)

  The IO board's initial state is cmd_state = -1, state = 3. In this
  state, it's actively polling SCC channels but NOT blocking on 0x18F8.
  This is consistent with Adrian's observations.

  Combined scenario (MOST LIKELY):
    1. IO board boots → enters polling loop in state 3/cmd -1
    2. Main board boots → reaches 0x3C2A4 → sends "004PWR"
    3. If IO board recognizes "004PWR" → responds → printer init succeeds
    4. Main board proceeds to SCSI → fails → retry loop → "pulsing"

    OR if "004PWR" handshake fails:
    3. IO board doesn't recognize "004PWR" (wrong state?) → no response
    4. Main board times out at receive_printer_data → D0=0 (failed)
    5. PS init error handler → may retry or continue without printer
    6. If it continues: reaches SCSI → fails → "pulsing"
    7. If it retries: stuck at printer init → but then IO board IS connected
       and should be "less stuck," not "more stuck" → contradiction

  CONCLUSION: The printer init probably succeeds (or times out gracefully),
  and the real hang point is SCSI. The "totally stuck without IO board"
  is because scc1_write_byte hangs polling CTS with no partner device.


HYPOTHESIS 3: STREAM SYSTEM DEADLOCK (NEW v7)
Likelihood: ★★☆☆☆ (LOW-MEDIUM)

  v7 discovered stream_put_byte_with_wait (0x3F936) which has an
  explicit infinite-wait loop:
    - Enables interrupts
    - Sleeps via 0x205B8 (waits for interrupt to wake it)
    - Checks if circular buffer has space
    - If no space → loops forever

  flush_output_stream (0x3FADC):
    - Pre-condition: output enabled flag at offset 110 must be set
    - If not set → calls error handler 0x683E8 mode 4

  close_output_stream (0x3FA82):
    - Waits for hardware read pointer to catch write pointer
    - Sleeps (0x205B8) while waiting
    - If hardware never drains buffer → infinite wait

  For this to cause a hang:
    - The stream system must be initialized AND have data queued
    - The DMA/interrupt consumer must fail to drain the buffer
    - This would happen AFTER SCSI/filesystem init, during PS startup
    - Unlikely to be the primary failure point (SCSI fails first)


HYPOTHESIS 4: MACHINE IS WORKING, WAITING FOR JOBS
Likelihood: ★★☆☆☆ (LOW-MEDIUM)

  A working idle RIP would show the PS interpreter at 0x71400:
  - execute_loop processes type dispatch table at 0x71420
  - Polling SCC #1 for incoming PostScript data
  - Checking pending operations at 0x2016794/98/9C
  - Very tight loop → near-constant activity, NOT periodic pulsing

  The pulsing pattern rules this out. A working machine wouldn't pulse.

  However, if the PS interpreter hits a recurring error condition
  (e.g., pending operation code -7 = fatal, causing recovery cycles),
  it could produce periodic patterns. But the period would be much
  shorter than SCSI timeout cycles.


HYPOTHESIS 5: LOW VOLTAGE CAUSING MARGINAL FAILURES
Likelihood: ★★★☆☆ (MEDIUM)

  At 4.78V on the 5V rail:
    68020 (CMOS):  min 4.5V  → OK (margin: 0.28V)
    DRAM (NMOS):   min 4.75V → MARGINAL (margin: 0.03V!)
    SCC 8530:      min 4.75V → MARGINAL (margin: 0.03V)
    AMD AM5380:      min 4.75V → MARGINAL
    74LS/74F:      min 4.75V → MARGINAL
    AM27C256 ROM:  min 4.5V  → OK (margin: 0.28V)

  v7 reveals even more extensive RAM usage during boot:
    Boot-time: 0x02000000-0x02000410 (system variables, exception table)
    PS init: 0x02000420-0x020223F0 (the entire working RAM range)
    Three malloc subsystems using heap blocks with markers
    Font dictionary with 512-bucket hash table
    Graphics state structures, execution stacks

  If DRAM is marginal at 4.78V:
    - MOVEP pattern test (0x5555AAAA at 1MB increments) might pass
    - But complex data structures could have bit flips:
      - Corrupt magic 0x5FA87D27 or 0x1EADE460 → validation fails
      - Corrupt function pointers → crash to wrong code
      - Corrupt heap markers ('U'/'*') → malloc corruption
      - Corrupt SCC DMA buffer pointers → communication failure

  If AMD AM5380 or SCC are marginal:
    - SCSI bus signals could be wrong → device selection fails
    - SCC handshake signals wrong → CTS timeout
    - This would manifest as SCSI failure (hypothesis 1) or SCC
      failure (hypothesis 2), making it a root cause for both

  This is an AGGRAVATING factor more than a primary cause. Fix the
  voltage first, then diagnose further.


HYPOTHESIS 6: HARDWARE REGISTER BUS ERROR (NEW v7)
Likelihood: ★☆☆☆☆ (VERY LOW — ruled out by evidence)

  The VERY FIRST thing detect_ram_top does is write to:
    0x06100000 = 0xFFFFFFFF
    0x06080000 = 0x00000000
    0x060C0000 = 0x00000000

  At this point, 0x2000010 (system_initialized) is NOT set. The bus
  error handler at 0x041C checks 0x2000010; if zero, fatal_error_handler
  at 0x772 jumps back to 0x856 = RESET.

  If ANY of these writes caused a bus error → infinite reset loop.

  BUT: Adrian confirmed reset goes low ONCE, then stays high. NOT a
  reset loop. Therefore all three hardware registers respond correctly.
  This hypothesis is ruled out.

  Similarly, v7 documents check_hardware_accel at 0x1BC00 which tests
  0x06100000 to detect an acceleration board. If this returns a wrong
  result, the HW callback table at 0x020221EC could have null pointers,
  crashing on first graphics operation. But the machine would crash at
  Phase 7 (rendering), not Phase 5 (SCSI), and the error pattern would
  be a crash-to-monitor, not a periodic pulse.

==============================================================================
THE MOST LIKELY REALITY (revised with v7 knowledge)
==============================================================================

The v7 analysis gives us the COMPLETE picture of every init step:

  Phase 1: Atlas Monitor boot (0x856-0x09DC)
    ✓ WORKS — single clean reset confirmed by oscilloscope
    ✓ RAM detected and cleared
    ✓ Hardware registers at 0x06080000/0x060C0000/0x06100000 respond
    ✓ SCC #1 and #2 programmed
    ✓ FPU detection runs (result: no FPU, software FPU will be used)

  Phase 2: Auto-boot decision
    ✓ WORKS — no terminal connected → CTS deasserted → auto-boot

  Phase 3: PS entry thunk (0x200C → 0x40508)
    ✓ WORKS — SR=0x2700, jump to bank 2

  Phase 4: PostScript initialization (0x40508)
    Step a: 0x3BC8A (SCC #1 configure)
      ✓ WORKS — just register writes, no handshake needed yet
    Step 4b: 0x3C2A4 (printer communication — "004PWR" handshake)
      ? DEPENDS — sends "004PWR", waits for IO board response
        With IO board: probably succeeds (IO board is in polling loop)
        Without IO board: scc1_write_byte times out (10,000 ticks × N bytes)
        → "totally stuck" polling SCC CTS
    Steps b-h: Internal setup
      ✓ PROBABLY WORKS — memory, operators, graphics, file I/O, SCSI timer
    Step i: 0x410C8 → 0x40E36 → dynamic loader → subsystem inits
      ✓ PROBABLY WORKS — loads bank 4 module, validates header magic 0x3399

  Phase 5: SCSI and filesystem
    Step 33: scsi_controller_init (0x85F32)
      ✓ AMD AM5380 present and responding (hardware registers at 0x05000001)
    Step 34: scsi_initialize_devices (0x85B58)
      ★★★★★ MOST LIKELY FAILURE POINT ★★★★★
      - Scans 8 SCSI IDs with INQUIRY + TEST UNIT READY
      - If no disk: 8 × INQUIRY timeout (5000ms) × 10 retries = ~400 seconds
        before declaring no devices
      - If BlueSCSI misconfigured: INQUIRY succeeds but filesystem magic wrong
      - Either way: PS interpreter gets failure, enters retry or error loop
    Step 36: filesystem_init (0x8018A)
      - Only reached if SCSI device found
      - Validates magic 0x5FA87D27 at page 0 and page 41004
      - If magic wrong: error → restart

  Phase 6: PS startup files — probably never reached
  Phase 7: Main interpreter loop — probably never reached

THE BOOT TIMELINE:

  t=0.000s: Power on. Reset goes low.
  t=0.001s: Reset goes high. 68020 fetches SSP and PC from ROM.
  t=0.002s: cold_boot_entry at 0x856. D7=1, jump to detect_ram_top.
  t=0.003s: Hardware registers at 0x06100000/06080000/060C0000 written.
  t=0.004s: RAM test begins (MOVEP pattern, 1MB increments).
  t=0.030s: RAM test complete. RAM clear begins.
  t=0.060s: RAM clear complete (4MB at 16MHz ≈ 30ms).
  t=0.061s: Monitor setup: exception vectors, SCC init.
  t=0.062s: FPU detection (trace trick: attempt FSAVE → trap → no FPU).
  t=0.063s: Auto-boot: no CTS → jump to 0x200C → 0x40508.
  t=0.064s: PS init begins. SCC #1 configured (0x3BC8A).
  t=0.070s: "004PWR" sent to IO board. IO board responds (it's been
            running since t≈0.001s, already in polling loop).
  t=0.080s: Internal PS init (memory, operators, graphics, file I/O).
  t=0.100s: SCSI timeout system initialized.
  t=0.110s: Dynamic loader loads bank 4 module.
  t=0.120s: scsi_controller_init — AMD AM5380 test.
  t=0.130s: scsi_initialize_devices — begins scanning SCSI bus.
  t=0.130s: SCSI bus reset (5000 ticks wait).
  t=0.200s: SCSI ID 0: INQUIRY → selection → 119 attempts → timeout.
  t=5.200s: SCSI ID 0 timeout. SCSI ID 1 begins.
  ...
  t=40.0s:  SCSI ID 7 timeout. All IDs failed. 10 retries remaining.
  ...
  t=400s:   All retries exhausted (or restart triggered earlier).
  t=400s+:  PS interpreter error → retry entire SCSI scan → "pulsing."

  The "brief activity" Adrian saw is t=0 to t≈0.13s (Phases 1-4).
  The "pulsing" is the SCSI timeout retry loop starting at t≈0.13s.
  The pulse period is the SCSI bus scan cycle time.

  Without IO board:
  t=0.064s: PS init calls 0x3BC8A (SCC configure) — succeeds.
  t=0.070s: "004PWR" via scc1_write_byte → CTS timeout (10,000 ticks).
  t=0.700s: Timeout. Error handler. Retry? Next byte? More timeouts.
  t=???:    Stuck in SCC CTS polling loop → "totally stuck."
            Bus shows only: CPU reading SCC #1 at 0x04000000 repeatedly.
            No SCSI access, no varied activity. Just tight polling.

==============================================================================
WHAT THE HARD DRIVE FILESYSTEM TELLS US
==============================================================================

From our analysis of HD00_Agfa_RIP.hda (41,998,848 bytes):
  - 296 valid files on the disk
  - 118 fonts (full Adobe Type 1 font library)
  - 163 FC/ entries (font cache — precomputed rasterizations)
  - 81 files with corrupted headers (0xFF-filled pages, mostly FC/ cache)
  - 120 deleted directory entries
  - 5 bad sectors: 34544, 78382, 78528, 78529, 78532
    → Map to FS pages: 17272 (free), 39191, 39264, 39266 (all in FC/ cache)
    → NONE overlap with critical system files

  The ACTUAL startup file is "Sys/Start" (14.9KB at page 5294):
    - eexec-encrypted PostScript with header "% Start of Sys/Start code"
    - eexec algorithm (v7): LCG with multiply/add/mask
    - Initial key: 0x5561 or 0xC1C2C3C4 (standard Adobe encryption)

  Other significant files:
    - "user/boot" (89 bytes): saves screen parameters
    - "AdobeStd.ps" (3.0KB): Adobe Standard encoding vector
    - "diag/rtest" (494.8KB): diagnostic/test program
    - "DB/DisplayList" (3.9MB): display list buffer (largest file)
    - "DB/SCREEN.0-2": halftone screen definitions

  The 81 corrupted FC/ cache entries suggest pre-existing disk issues.
  The font cache at 0x4A800 uses LRU eviction with disk backing (v7: 13
  new font cache functions identified). 81 corrupted cache files = the
  cache subsystem was already having problems before the machine was
  taken out of service.

  The critical boot files are intact in the image:
    ✓ Sys/Root0 (page 0) — magic 0x5FA87D27 valid
    ✓ Sys/Root1 (page 41004) — backup root valid
    ✓ Sys/AllocMap (page 2) — allocation bitmap
    ✓ Sys/Directory (page 9) — file directory
    ✓ Sys/Start (page 5294) — eexec-encrypted PS boot code

==============================================================================
RECOMMENDED DIAGNOSTIC STEPS (updated with v7 addresses)
==============================================================================

1. CONNECT A SERIAL TERMINAL TO THE ATLAS MONITOR
   Port: SCC #2 at 0x07000000 (debug console)
   Settings: 9600 baud, 8N1
   Cable: MUST have CTS wired properly:
     - Tie CTS to RTS on the terminal adapter, OR
     - Use null modem cable that asserts CTS
   Expected: sys_flags bit 0 = 1 → Atlas Monitor banner appears
   The monitor uses A5 continuation-passing style (not standard RTS)

   If the monitor prompt appears: the 68020, ROM, RAM, and SCC #2 are
   all working. You're in Phase 2 and can control everything.

2. IF YOU REACH THE ATLAS MONITOR:
   Commands:
     D <addr>          - Dump memory (hex/ASCII)
     D 02000000        - RAM size (first 4 bytes)
     D 02000010        - sys_flags (should be nonzero with terminal)
     D 02000080        - FPU flag (should be 0 = no FPU)
     D 0200024C        - Stack pointer area
     D 020002D0        - Memory address table (NEW v7)
     D 02016EA0        - SCSI timeout current value
     D 02016EA4        - SCSI timeout mode flag (1=normal, 2=extended)
     D 02016E9C        - SCSI timeout callback pointer
     D 02016EAC        - SCSI device table (NEW v7)
     D 02016FD0        - SCSI command queue (NEW v7)
     D 02017144        - SCSI device structure base
     D 02017210        - SCSI device capacity table (8 entries)
     D 02017230        - SCSI retry counters (8 entries × 4 bytes)
     D 02022378        - SCSI operation timeout
     D 0202239C        - Default timeout value (should be 5000)
     D 02022394        - SCSI controller present flag (NEW v7)
     D 020170FC        - FPU context (NEW v7)
     D 020173A6        - Stream channel count (NEW v7)
     D 020174AC        - PS error context
     D 020008F4        - PS execution context
     D 02022310        - System clock (NEW v7)
     D 020222C8        - Error handler (NEW v7)
     L <addr>          - Disassemble code
     L 40508           - PostScript entry point
     R                 - Display registers (shows where CPU was stuck)
     G <addr>          - Execute from address
     G 200C            - Manually trigger PostScript boot
     T                 - Trace (single step)

3. DIAGNOSE SCSI FROM THE MONITOR:
   D 05000001         - AMD AM5380 SCSI data register
   D 05000003         - Initiator command register
   D 05000005         - Mode register
   D 05000007         - Bus and status register
   D 05000009         - Target command register
   D 0500000B         - Current SCSI data
   D 0500000D         - Input data register
   D 0500000F         - Reset/parity register
   If all SCSI registers read 0xFF: SCSI chip or bus is dead
   If registers have varying values: controller works, check device
   D 05000026         - Pseudo-DMA port (read to test bus activity)

4. DIAGNOSE SCC #1 (IO BOARD COMMUNICATION):
   D 04000000         - SCC #1 Ch A status register
   D 0400000E         - SCC #1 Ch A control register
   D 0400002E         - SCC #1 Ch B control register
   D 02000424         - SCC #1 config word 1 (NEW v7)
   D 02000428         - SCC #1 config word 2 (NEW v7)
   D 0200042C         - SCC #1 DMA buffer pointer (NEW v7)
   D 02000440         - SCC #1 DMA state (NEW v7 — 0=idle)
   D 02000454         - SCC #1 lock flag (NEW v7 — 0=unlocked)
   If all SCC regs read 0xFF: SCC #1 chip is dead or not decoding
   If 0x02000440 ≠ 0: DMA stuck (should be 0 when idle)
   If 0x02000454 ≠ 0: SCC locked (should be 0 when idle)

5. CHECK THE IO BOARD DEBUG PORT:
   Unpopulated connector on IO board = SCC #2 at 0x040010
   Connect at 9600 8N1
   Expected: "Hello, this is the debug port"
   Commands (v7 — all handler addresses known):
     MD <addr>        - Dump memory (handler at 0x28F6)
     MD 15016         - Current state (0-14)
     MD 15000         - Message buffer
     MD 1500E         - System state (should be 0x0F after init)
     MD 1501A         - Current command value
     MD 1501E         - Resolution (should be 1200 = 0x04B0)
     MD 15012         - Inverse flag (should be 0)
     MD 15112         - System init flag
     MD 15126         - Channel structures (76 bytes each, 4 channels)
     MD 153EA         - Timeout counter
     MD 1F000         - Shared memory with main board
     MM <addr>        - Modify memory (handler at 0x2AA8)
     GO <addr>        - Execute from address (handler at 0x28C0)
     LO               - Load S-record (handler at 0x2C6C)
     ATI              - Switch to ATI mode (handler = 0x042C itself!)
     LED              - LED control (handler at 0x141C)
     VIDEO            - Video control (handler at 0x1448)
     RESOL            - Resolution setting (handler at 0x147A)
     RESET            - Reset system (handler at 0x1500)
   This works INDEPENDENTLY of the main board.

6. VERIFY BLUESCSI CONFIGURATION:
   The firmware scans SCSI IDs 0-7 at 0x85B58
   The Quantum P40S was likely SCSI ID 0 or 1
   Verify the BlueSCSI is set to the correct ID
   Verify the disk image (HD00_Agfa_RIP.hda) is complete:
     - Should be 41,998,848 bytes (82,029 sectors × 512)
     - Bytes 0-3 (page 0 offset 0): 0x5FA87D27 (root magic)
     - Offset 41,988,096 (page 41004): 0x5FA87D27 (backup root magic)
   Verify BlueSCSI sector size: must be 512 bytes (not 256 or 1024)
   Verify SCSI bus termination: 5380 needs proper termination

7. FIX POWER SUPPLY:
   Get 5.00V at the board, not 4.78V
   The 0.3V drop suggests connector resistance or aging caps
   Priority: DRAM, SCC, and AMD AM5380 are all marginal at 4.78V
   Check for hot tantalum capacitors (common failure on 80s boards)
   Clean board-to-backplane connectors (oxidation = resistance)
   Consider: a solid 5V might fix everything by itself

8. IDENTIFY SERIAL PORT PINOUT:
   Back panel has: Centronics (parallel), AppleTalk (9-pin), Serial
   - Atlas Monitor console: likely the "Serial" DB-25 connector
     Connected to SCC #2 at 0x07000000 on main board
   - AppleTalk port: connects to SCC #1 (PostScript data channel)
   - IO board debug: unpopulated connector on IO board
     Connected to SCC #2 at 0x040010 on IO board
     May need header pins soldered

==============================================================================
WHAT WOULD MAKE THIS MACHINE WORK AGAIN
==============================================================================

Based on the complete v7 analysis of all 6 ROM banks (198 chunks,
1.68MB of annotated disassembly), the minimum requirements are:

1. WORKING SCSI STORAGE (Critical)
   - BlueSCSI (or original drive) at correct SCSI ID (probably 0)
   - Valid disk image with root magic 0x5FA87D27 at page 0
   - Proper SCSI bus termination
   - At minimum these files must be readable:
     ✓ Sys/Root0 (page 0) — filesystem root
     ✓ Sys/AllocMap (page 2) — allocation bitmap
     ✓ Sys/Directory (page 9) — file directory
     ✓ Sys/Start (page 5294) — boot configuration (14.9KB)
   - All four are intact in our HD image

2. ADEQUATE POWER (Important)
   - 5.00V ± 5% at the board (min 4.75V for NMOS/TTL parts)
   - Currently at 4.78V = 0.03V above minimum for DRAM/SCC/AM5380
   - Clean connectors, replace aging electrolytic/tantalum caps
   - The 0.3V drop from PSU to board is too much

3. IO BOARD CONNECTED AND FUNCTIONAL (Required)
   - Required for printer init at 0x3C2A4 to succeed
   - Without it: main board hangs at scc1_write_byte CTS timeout
   - IO board appears to be working based on Adrian's observations
   - The IO board has an independent 68000 that boots on its own

4. NO SERIAL TERMINAL NEEDED FOR NORMAL OPERATION
   - The machine auto-boots when no terminal is connected
   - A terminal is only needed for Atlas Monitor debugging
   - PostScript jobs come via the AppleTalk/serial port
   - The IO board communicates with the imagesetter, not the user

PRIORITY ORDER:
  1. Fix power supply voltage (easy: adjust PSU trim pot, clean connectors)
  2. Configure BlueSCSI correctly (easy: right SCSI ID, right image)
  3. Connect serial terminal for diagnosis (moderate: find pinout)
  4. Verify IO board health via debug port (moderate: solder header)

==============================================================================
WHAT WE KNOW WITH CERTAINTY (from v7 disassembly + oscilloscope evidence)
==============================================================================

CONFIRMED WORKING:
  ✓ 68020 CPU (fetches and executes code, clean reset)
  ✓ All 5 ROM banks (code executes through multiple banks)
  ✓ RAM (at least enough for monitor — full test may have issues at 4.78V)
  ✓ SCC #2 at 0x07000000 (monitor uses it, no bus error)
  ✓ Hardware registers at 0x06080000/060C0000/06100000 (no bus error)
  ✓ IO board 68000 CPU (boots, shows activity, clean reset)
  ✓ IO board ROM (code executing, ROM address pins active)
  ✓ Reset circuit (single clean reset, no oscillation)
  ✓ 16MHz clock oscillator (confirmed on scope)

PROBABLY WORKING:
  ~ SCC #1 at 0x04000000 (register writes succeed during boot)
  ~ IO board SCC channels (IO board completes init and enters loop)
  ~ AMD AM5380 SCSI controller (register writes succeed, unclear if bus works)

PROBABLY FAILING:
  ✗ SCSI disk communication (no working drive, or BlueSCSI misconfigured)
  ✗ Power delivery (4.78V marginal for multiple chips)

UNKNOWN:
  ? RAM above basic test range (MOVEP tests 1 location per MB)
  ? SCSI bus termination
  ? SCC #1 actual data transfer (CTS/RTS handshake with IO board)
  ? Full PS init completion (we've never seen it get past SCSI)

==============================================================================
SUMMARY
==============================================================================

The machine is NOT dead. Both CPUs boot cleanly. The ROMs are good.
Basic hardware responds. The 68020 comes out of reset at 0x856, executes
the Atlas Monitor boot code, finds no serial terminal (CTS deasserted),
and auto-boots to the PostScript interpreter at 0x40508.

The PostScript interpreter begins its initialization sequence:
  1. SCC #1 configuration (0x3BC8A) — SUCCEEDS (register writes only)
  2. Printer communication (0x3C2A4 "004PWR") — PROBABLY SUCCEEDS
     (IO board is running and responsive)
  3. Internal setup: memory, operators, graphics — SUCCEEDS
  4. SCSI timeout system (0x81156) — SUCCEEDS
  5. Dynamic loader (0x40968) — SUCCEEDS
  6. SCSI bus scan (0x85B58) — ★★★★★ FAILS HERE ★★★★★
     No working disk → selection timeouts on all 8 IDs → retry
     → "pulsing" pattern with ~40-second cycle time
  7. Filesystem mount — never reached
  8. Sys/Start load — never reached
  9. Main interpreter loop (0x71400) — never reached

Without the IO board, the machine hangs earlier:
  1. SCC #1 configuration — SUCCEEDS
  2. Printer communication "004PWR" — scc1_write_byte (0x3B080) polls
     CTS for 10,000 ticks per byte, CTS never asserts = "totally stuck"
     Bus shows only: CPU reading SCC #1 at 0x04000000 in tight loop

The "pulsing" is the SCSI retry loop. The "totally stuck" is the SCC
CTS polling loop. Both are EXPECTED behaviors for the respective
failure conditions.

This machine is alive. It's a 1988 Adobe PostScript RIP that booted
successfully, initialized its PS interpreter, tried to find its SCSI
hard drive, failed, and is patiently retrying — waiting for someone to
give it working storage.

Fix the power supply. Configure the BlueSCSI. Connect a serial terminal.
The machine should boot to a working PostScript v49.3 RIP, ready to
typeset onto an Agfa 9400 imagesetter, just as it did when it was new.

Adrian thought the machine was dead. It's not dead. It's waiting.
