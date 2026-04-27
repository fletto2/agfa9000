# VERA Fast Bus Interface — GAL22V10 Decode

Bypass the slow VIA socket PAL (/DSACK at ~1MHz) with a registered
GAL22V10 that decodes a custom address range and generates /DSACK1
after 1 wait state (~250ns per byte, 4× faster).

## Target Timing

68020 @ 16MHz, 8-bit port (VERA):
- CLK period = 62.5ns
- 1 wait state: /DSACK1 asserted at S4 = 250ns total cycle
- VERA sync requirement: 120-160ns (met with margin)

## GAL22V10 Pin Assignment

```
                 GAL22V10
              +-----------+
     CLK  1 --|>          |-- 24  Vcc
    /AS   2 --|           |-- 23  /DSACK1 (registered)
    R/W   3 --|           |-- 22  /CS_VERA (combinational)
    A31   4 --|           |-- 21  /WR_VERA (combinational)
    A30   5 --|           |-- 20  /RD_VERA (combinational)
    A29   6 --|           |-- 19  A4_VERA (active low accent)
    A28   7 --|           |-- 18  A3_VERA
    A27   8 --|           |-- 17  A2_VERA
    A26   9 --|           |-- 16  A1_VERA
    A25  10 --|           |-- 15  A0_VERA  (active low accent accent)
    A24  11 --|           |-- 14  (unused)
    GND  12 --|           |-- 13  (unused)
              +-----------+
```

## Address Decode

Map VERA to $08000000-$0800001F (32 bytes, 5-bit address).

Address match: A31=0, A30=0, A29=0, A28=0, A27=1, A26=0, A25=0, A24=0
(= $08xxxxxx)

For the minimal decode (ignoring A23-A5):

```
MATCH = /A31 * /A30 * /A29 * /A28 * A27 * /A26 * /A25 * /A24
```

## GAL Equations (CUPL/WinCUPL format)

```cupl
Name     VERA_FAST;
PartNo   01;
Date     2026-03-31;
Designer Agfa9000;
Company  ;
Assembly ;
Location ;
Device   g22v10;

/* Inputs */
Pin 1  = CLK;        /* 68020 CLK (16MHz) */
Pin 2  = !AS;        /* 68020 /AS (active low) */
Pin 3  = RW;         /* 68020 R/W (1=read, 0=write) */
Pin 4  = A31;
Pin 5  = A30;
Pin 6  = A29;
Pin 7  = A28;
Pin 8  = A27;
Pin 9  = A26;
Pin 10 = A25;
Pin 11 = A24;

/* Outputs */
Pin 23 = !DSACK1;    /* /DSACK1 to 68020 (REGISTERED - 1 wait state) */
Pin 22 = !CS_VERA;   /* /CS to VERA (active low, COMBINATIONAL) */
Pin 21 = !WR_VERA;   /* /WR to VERA (active low, COMBINATIONAL) */
Pin 20 = !RD_VERA;   /* /RD to VERA (active low, COMBINATIONAL) */

/* Address match: $08xxxxxx */
MATCH = !A31 & !A30 & !A29 & !A28 & A27 & !A26 & !A25 & !A24;

/* /CS_VERA: active when address matches and /AS is asserted */
CS_VERA = AS & MATCH;

/* /WR_VERA: write strobe */
WR_VERA = CS_VERA & !RW;

/* /RD_VERA: read strobe */
RD_VERA = CS_VERA & RW;

/* /DSACK1 (registered output, clocked by CLK):
 * The registered output is delayed by 1 CLK cycle from when
 * CS_VERA goes active. This creates exactly 1 wait state.
 *
 * On CLK rising edge:
 *   If CS_VERA is active, DSACK1 goes active on the NEXT clock.
 *   If CS_VERA is inactive, DSACK1 goes inactive.
 *
 * Timing:
 *   S0: CPU outputs address
 *   S1: /AS falls → CS_VERA goes active (combinational)
 *   S1→S2 CLK edge: GAL registers CS_VERA → DSACK1 goes active
 *   S2: CPU samples /DSACK1 = active → 0 wait states!
 *
 * Actually for 1 wait state, we need DSACK1 to be active at S4,
 * not S2. Use a 2-stage pipeline:
 */

/* Stage 1: detect access (registered) */
Pin 14 = STAGE1;   /* internal registered node */
STAGE1.D = CS_VERA & !STAGE1;  /* set on first clock after CS */

/* Stage 2: assert DSACK (registered) */
DSACK1.D = STAGE1;  /* delayed by one more clock = 2 clocks total */

/* Reset both stages when /AS deasserts */
STAGE1.AR = !AS;
DSACK1.AR = !AS;
```

## Timing Diagram

```
CLK     ‾‾|__|‾‾|__|‾‾|__|‾‾|__|‾‾|__|‾‾|__|‾‾
         S0   S1   S2   S3   S4   S5
/AS     ‾‾‾‾‾‾\____________________________/‾‾‾
MATCH   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
CS_VERA _______/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_____
STAGE1  _____________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\______
/DSACK1 ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\______________/‾‾‾‾‾
                            ^ asserted at S4 = 1 wait state
Data    ----------------------< valid >----------
```

## Data Bus Connection

VERA is 8-bit. The 68020 dynamically sizes based on /DSACK:
- /DSACK1=low, /DSACK0=high → 8-bit port on D31-D24

VERA's D0-D7 connects to the 68020's D24-D31 (upper byte lane).
Address lines A0-A4 (from 68020 A1-A5) connect to VERA's A0-A4.

**Important**: The 68020 uses A0-A1 for byte selection within a
32-bit word. For an 8-bit device with /DSACK1, the CPU puts the
byte on D31-D24 regardless of A0-A1. VERA's register select uses
the 68020's A1-A5 mapped to VERA A0-A4.

## Bill of Materials

| Qty | Part | Notes |
|-----|------|-------|
| 1 | GAL22V10-15 | 15ns speed grade (faster is fine) |
| 1 | 74HC245 | Bidirectional bus buffer (data bus isolation) |
| 1 | 50-pin IDC connector | Connects to PRINTER ribbon |
| 1 | Prototype PCB | Small board for GAL + buffer |
| - | Wire, headers | As needed |

## Wiring Summary

**From 68020 (tap at CPU socket or nearby vias):**
- CLK (pin 1 of GAL)
- /AS
- R/W
- A24-A31 (8 address lines for decode)
- D24-D31 (8 data lines to 74HC245)

**From GAL to VERA (via 50-pin IDC or direct):**
- /CS_VERA
- /WR_VERA
- /RD_VERA

**From 74HC245 to VERA:**
- D0-D7 (VERA data bus)

**From 68020 to VERA (direct or via IDC):**
- A1-A5 → VERA A0-A4 (register select)

**Back to 68020:**
- /DSACK1 from GAL pin 23
- /DSACK0 directly to Vcc via pull-up (always high = not asserted)

## Software Change

```c
/* Old (VIA socket, 1MHz) */
#define VERA_BASE ((volatile uint8_t *)0x04000020)

/* New (GAL decode, 4MHz) */
#define VERA_BASE ((volatile uint8_t *)0x08000000)
```

That's the entire software change. All existing Doom/AW code works
at 4× speed.

## Expected Performance

| Metric | VIA Socket | GAL Decode | Improvement |
|--------|-----------|------------|-------------|
| Byte write | ~1000ns | ~250ns | 4× |
| Full frame (64KB) | 64ms | 16ms | 4× |
| Doom FPS (est.) | 2 fps | 8-10 fps | 4-5× |
| Pixel throughput | 1 MB/s | 4 MB/s | 4× |

## Safety Notes

- Build external to the main board first
- Use ribbon cables, don't solder to the board
- The GAL decode is at $08000000 which is unused address space
- /DSACK0 needs a pull-up (10K to Vcc) if not actively driven
- Add 100nF decoupling caps on GAL and buffer Vcc pins
- Test with a simple register read/write before running Doom

---

# Option B: TTL-Only Version (No GAL)

Same function, built entirely from 74-series logic. No programmer needed.

## Chip List

| Chip | Function | Notes |
|------|----------|-------|
| U1: 74HC688 | 8-bit address comparator | Decodes A31-A24 = $08 |
| U2: 74HC74 | Dual D flip-flop | 2-stage /DSACK1 delay |
| U3: 74HC245 | Bidirectional bus buffer | Data D24-D31 ↔ VERA D0-D7 |
| U4: 74HC08 | Quad AND gate | Combine signals |
| U5: 74HC04 | Hex inverter | Signal polarity |

5 chips total. All available as DIP or SOIC.

## Circuit Description

### Address Decode (U1: 74HC688)

The 74HC688 compares 8 inputs (P0-P7) against 8 reference (Q0-Q7).
Output /P=Q goes low when all bits match.

```
P0-P7 = A24-A31 (from 68020 address bus)
Q0-Q7 = tied to match $08:
  Q0 (A24) = GND (0)
  Q1 (A25) = GND (0)
  Q2 (A26) = GND (0)
  Q3 (A27) = Vcc (1)
  Q4 (A28) = GND (0)
  Q5 (A29) = GND (0)
  Q6 (A30) = GND (0)
  Q7 (A31) = GND (0)
/G (enable) = GND (always enabled)

Output: /P=Q = low when A31-A24 = $08
```

### Chip Select (U4a: 74HC08 AND gate)

```
/CS_VERA = /P=Q (address match, active low) OR /AS (bus active)

Using AND gate with active-low logic:
  CS_ACTIVE = NOT(/P=Q) AND NOT(/AS)    [U5a inverts /P=Q, U5b inverts /AS]
  /CS_VERA  = NOT(CS_ACTIVE)             [U5c inverts]

Or simpler: /CS_VERA = /P=Q OR /AS (active low OR = both must be low)
  Use 74HC08: CS_ACTIVE = INV(/P=Q) & INV(/AS)  [two inverters + AND]
  /CS_VERA = INV(CS_ACTIVE)
```

Simplified with a 74HC32 (OR gate) instead:
```
/CS_VERA = /P=Q | /AS     ← 74HC32 OR gate, direct
```

Actually simplest: **replace U4 (74HC08) with U4: 74HC32 (quad OR)**

```
/CS_VERA = /P=Q OR /AS    (U4a: 74HC32)
```
Both /P=Q and /AS are active-low. OR'ing two active-low signals:
output is low ONLY when BOTH inputs are low = address match AND bus active. ✓

### Write/Read Strobes (U4b, U4c: 74HC32)

```
/WR_VERA = /CS_VERA OR R/W      (U4b)  — low only when /CS active AND R/W=0 (write)
/RD_VERA = /CS_VERA OR /R/W     (U4c)  — low only when /CS active AND R/W=1 (read)
                                          (need U5d to invert R/W)
```

Wait — for /WR_VERA: we want it low when CS is active and R/W=0.
`/WR_VERA = /CS_VERA | R/W` — if /CS_VERA=0 and R/W=0, output = 0. ✓
If either is high, output = high (inactive). ✓

For /RD_VERA: we want it low when CS is active and R/W=1.
`/RD_VERA = /CS_VERA | INV(R/W)` — need one inverter (U5d).

### /DSACK1 Timing (U2: 74HC74 dual D flip-flop)

Two D flip-flops in series, clocked by the 68020 CLK (16MHz).
This creates a 2-clock delay from /CS_VERA assertion to /DSACK1.

```
U2a (FF1):
  CLK = 68020 CLK (16MHz)
  D   = CS_ACTIVE (inverted /CS_VERA, from U5e)
  /PR = Vcc (no preset)
  /CLR = /AS inverted? No: /CLR = AS_RAW (active low clear when /AS high)
         Actually: /CLR connects to /AS directly.
         When /AS is HIGH (no bus cycle), /CLR is HIGH = no clear.
         When /AS goes LOW (bus cycle starts)... wait, /CLR is active LOW.
         /CLR = HIGH means "don't clear". /CLR = LOW means "force Q=0".
         We want FF cleared when NO bus cycle (/AS = HIGH).
         So: /CLR = INV(/AS) = AS_active.
         When /AS=HIGH (idle): /CLR=LOW → Q forced to 0. ✓
         When /AS=LOW (active): /CLR=HIGH → FF operates normally. ✓
         Use U5e for this inversion.
  Q   → D input of U2b (FF2)

U2b (FF2):
  CLK = 68020 CLK (16MHz)
  D   = Q of U2a
  /PR = Vcc
  /CLR = same as U2a (INV(/AS))
  /Q  → /DSACK1 (active low output)
```

### Timing

```
CLK     ‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾
          S0  S1  S2  S3  S4  S5
/AS     ‾‾‾‾‾\_________________________/‾
/CS     ‾‾‾‾‾‾\_________________________/‾  (combinational, ~10ns after /AS)
FF1 Q   ______/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_____    (1 CLK after /CS, at S2 edge)
FF2 /Q  ‾‾‾‾‾‾‾‾‾‾‾‾‾\______________/‾‾    (1 CLK after FF1, at S4 edge)
/DSACK1 ‾‾‾‾‾‾‾‾‾‾‾‾‾\______________/‾‾    = FF2 /Q → 1 wait state
```

FF1 captures CS_ACTIVE on the first CLK rising edge after /AS falls (S1→S2).
FF2 captures FF1's Q on the next CLK edge (S3→S4).
FF2's /Q goes LOW at S4 = /DSACK1 asserted = 1 wait state. ✓

Both FFs are cleared when /AS goes high (end of cycle), resetting for next access.

## Schematic (ASCII)

```
                                   +5V
                                    |
  A24-A31 ──┐                    10K R
             │                      |
        ┌────┴────┐           ┌─────┴─── /DSACK0 (pulled high, not used)
        │ 74HC688 │           │
        │  P=Q    │      ┌────┴────┐
  $08 ──┤ Q0-Q7   │      │ 74HC74  │
        │         │      │  FF1    FF2
        │  /P=Q ──┼──┐   │ D  Q──D  /Q ────── /DSACK1 (to 68020)
        └─────────┘  │   │    │         │
                     │   │ CLK│    CLK  │
   /AS ──────────┐   │   │  ↑ │     ↑   │
                 │   │   │  │ │     │   │
                 │   │   │  └─┼─────┘   │
                 │   │   │  CLK(16MHz)  │
                 │   │   │              │
                 ├───┤   │ /CLR  /CLR   │
                 │   │   │  ↑     ↑     │
                 │   │   └──┼─────┘     │
                 │   │      │           │
                 │   │   ┌──┴──┐        │
                 │   │   │INV  │← /AS   │
                 │   │   │(U5e)│        │
                 │   │   └─────┘        │
                 │   │                  │
              ┌──┴───┴──┐               │
              │ 74HC32  │               │
              │  OR     │               │
     /AS ─────┤A     Y ├───── /CS_VERA  │
    /P=Q ─────┤B       │               │
              │        │               │
     R/W ─────┤A     Y ├───── /WR_VERA  │
   /CS_V ─────┤B       │               │
              │        │               │
   INV(R/W)──┤A     Y ├───── /RD_VERA  │
   /CS_V ─────┤B       │               │
              └────────┘               │
                                       │
              ┌────────┐               │
  D24-D31 ════╡74HC245 ╞════ VERA D0-D7
              │  DIR←──┤← R/W
              │  /OE←──┤← /CS_VERA
              └────────┘

  A1-A5 ─────────────────── VERA A0-A4 (direct, active accent  accent  no buffer needed)
```

## TTL Bill of Materials

| Qty | Part | Package | Function |
|-----|------|---------|----------|
| 1 | 74HC688 | DIP-20 | Address comparator ($08 decode) |
| 1 | 74HC74 | DIP-14 | Dual D-FF (/DSACK1 timing) |
| 1 | 74HC245 | DIP-20 | Data bus buffer |
| 1 | 74HC32 | DIP-14 | Quad OR gate (/CS, /WR, /RD) |
| 1 | 74HC04 | DIP-14 | Hex inverter (R/W, /AS polarity) |
| 1 | 10KΩ resistor | | /DSACK0 pull-up |
| 5 | 100nF ceramic | | Decoupling caps |
| 1 | Prototype board | | ~3cm × 5cm |

Total: 5 chips + passives. All through-hole DIP, hand-solderable.

## Comparison: GAL vs TTL

| | GAL Version | TTL Version |
|---|------------|-------------|
| Chips | 2 (GAL + buffer) | 5 (688 + 74 + 245 + 32 + 04) |
| Needs programmer | Yes (GAL22V10) | No |
| Board space | Smaller | ~2× larger |
| Flexibility | Reprogram timing | Rewire to change |
| Speed | Identical | Identical |
| Availability | GAL22V10 getting rare | All parts common |
