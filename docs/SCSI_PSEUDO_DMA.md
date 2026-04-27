# NCR 5380 Pseudo-DMA on Agfa 9000PS

## Register Map (stride-1 at 0x05000000)

| Address      | Read                        | Write                        |
|--------------|-----------------------------|------------------------------|
| 0x05000000   | CSD (Current SCSI Data)     | OD (Output Data)             |
| 0x05000001   | ICR (Initiator Command)     | ICR                          |
| 0x05000002   | MR (Mode Register)          | MR                           |
| 0x05000003   | TCR (Target Command)        | TCR                          |
| 0x05000004   | CSB (Current Bus Status)    | SER (Select Enable)          |
| 0x05000005   | BSR (Bus & Status)          | SDS (Start DMA Send)         |
| 0x05000006   | IDR (Input Data)            | SDT (Start DMA Target Rx)    |
| 0x05000007   | RPI (Reset Parity/IRQ)      | SDI (Start DMA Init Rx)      |
| **0x05000020** | **Pseudo-DMA Read**       | **Pseudo-DMA Write**         |

## Key Bits

| Register | Bit | Mask | Name             | Description                              |
|----------|-----|------|------------------|------------------------------------------|
| MR       | 1   | 0x02 | DMA Mode         | Enable DMA handshake engine              |
| BSR      | 7   | 0x80 | End of DMA       | DMA transfer complete                    |
| BSR      | 4   | 0x10 | Phase Mismatch   | Target changed phase (transfer done)     |
| CSB      | 5   | 0x20 | REQ              | Target requesting data transfer          |
| CSB      | 4:2 |      | Phase            | 001=DATA_IN, 000=DATA_OUT, 011=STATUS    |
| ICR      | 0   | 0x01 | Assert DBUS      | Drive data bus                           |
| ICR      | 4   | 0x10 | Assert ACK       | Acknowledge byte transfer                |

## Current PIO Approach (~7 register ops per byte)

This is what the Minix SCSI driver currently does in `pio_read()`:

```
for each byte:
    poll CSB until REQ set           ; wait for target
    TCR = (CSB & 0x1C) >> 2         ; phase interlock (required by AM5380)
    check phase == DATA_IN           ; abort if phase changed
    byte = read CSD (reg 0)          ; read the data byte
    ICR = 0x10                       ; assert ACK
    poll CSB until REQ cleared       ; wait for target to see ACK
    ICR = 0x00                       ; release ACK
```

~7 bus transactions per byte. For 512 bytes = ~3,500 bus cycles.
For a 4.2MB WAD file = ~29 million bus transactions.

## Pseudo-DMA Approach (1 bus access per byte)

The NCR 5380 has an internal DMA engine that handles REQ/ACK handshaking
automatically. The host just reads/writes the pseudo-DMA port at 0x05000020.
Each access transfers one byte with automatic handshake.

### DATA_IN (Read) Sequence

```
; Prerequisites: target selected, command sent, target is in DATA_IN phase

    ; 1. Wait for REQ
    poll CSB until REQ set (bit 5)

    ; 2. TCR interlock for DATA_IN phase
    MOVE.B  $05000004,D0           ; read CSB
    LSR.B   #2,D0
    AND.B   #0x07,D0
    MOVE.B  D0,$05000003           ; write TCR

    ; 3. Enable DMA mode
    MOVE.B  $05000002,D0           ; read MR
    OR.B    #0x02,D0               ; set DMA mode bit
    MOVE.B  D0,$05000002           ; write MR

    ; 4. Start DMA Initiator Receive
    MOVE.B  #0x00,$05000007        ; write SDI (any value)

    ; 5. Fast read loop — one bus access per byte
    LEA     $05000020,A0           ; pseudo-DMA port
    LEA     buffer,A1              ; destination RAM
    MOVE.W  #511,D0                ; 512 bytes - 1 (for DBRA)
.loop:
    MOVE.B  (A0),(A1)+             ; read byte with auto REQ/ACK
    DBRA    D0,.loop

    ; 6. Check for end condition
    MOVE.B  $05000005,D0           ; read BSR
    BTST    #4,D0                  ; phase mismatch = transfer done

    ; 7. Disable DMA mode
    MOVE.B  $05000002,D0           ; read MR
    AND.B   #0xFD,D0               ; clear DMA mode bit
    MOVE.B  D0,$05000002           ; write MR

    ; 8. Proceed to STATUS phase as normal (PIO for status + message bytes)
```

### DATA_OUT (Write) Sequence

```
    ; Same setup but:
    ; - Use SDS (Start DMA Send) instead of SDI: write to reg 5
    ; - Write bytes to pseudo-DMA port: MOVE.B (A1)+,(A0)
    ; - Same end detection via BSR phase mismatch
```

## Expected Performance

| Method     | Bus ops/byte | 512-byte sector | 4.2MB WAD file |
|------------|-------------|-----------------|----------------|
| PIO        | ~7          | ~3,500 ops      | ~29M ops       |
| Pseudo-DMA | 1           | 512 ops         | ~4.2M ops      |
| Speedup    | **~7x**     |                 |                |

At 16MHz with ~4 clock cycles per bus access:
- PIO: ~875 us/sector, ~7.3 sec for 4.2MB
- Pseudo-DMA: ~128 us/sector, ~1.1 sec for 4.2MB

## Test Plan

### Step 1: Probe the pseudo-DMA port

From the monitor, try reading 0x05000020 with no SCSI activity:
```
D 5000020 10
```
If bus error → port doesn't have DTACK (might only respond during DMA mode).
If returns data → port is always accessible.

### Step 2: PIO baseline read

1. Select SCSI ID 0
2. Send READ(6) for sector 0, count=1
3. PIO read 512 bytes with VIA1 timer
4. Record time and hexdump first 16 bytes

### Step 3: Pseudo-DMA read

1. Select SCSI ID 0
2. Send READ(6) for sector 1, count=1
3. Wait for DATA_IN phase
4. Set TCR interlock
5. MR |= 0x02 (DMA mode)
6. Write to SDI (reg 7)
7. Read 512 bytes from 0x05000020 in tight loop
8. Check BSR for phase mismatch
9. MR &= ~0x02 (DMA mode off)
10. Record time and hexdump first 16 bytes

### Step 4: Multi-sector read

If step 3 works, try reading 16 sectors (8KB) in one command
with a single pseudo-DMA loop of 8192 bytes.

## Key Unknowns

1. **Does 0x05000020 respond with DTACK?** — It might only generate DTACK
   when DMA mode is active and REQ is asserted.

2. **Byte lane** — The pseudo-DMA port might present data on a different
   byte lane (D8-D15 vs D0-D7) than the standard registers. Test with
   both `MOVE.B (A0),Dn` and `MOVE.B 1(A0),Dn`.

3. **Wait states** — The pseudo-DMA port might insert wait states until
   REQ is asserted, making the tight loop self-throttling. Or it might
   return stale data if read too fast.

4. **End of transfer** — Need to determine if the loop should poll BSR
   between bytes or just blast through the count and check after.

5. **Multi-sector** — Does the 5380 stay in DATA_IN across sector
   boundaries within a single READ command? (Should yes, per SCSI spec.)

## Files

- Current PIO driver: `minix/agfa-port/kernel/agfascsi.c` (pio_read at line 413)
- Emulator SCSI: `src/scsi.c` (pseudo-DMA port at 0x05000020)
- Adrian's SCSI reference: `scsi.m68` (polled PIO, matches current driver)
