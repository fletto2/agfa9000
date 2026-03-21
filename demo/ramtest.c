/*
 * ramtest.c -- Comprehensive RAM diagnostic for Agfa 9000PS (68020 @ 16MHz)
 *
 * Burns into bank 0 ROM. Outputs detailed test results on SCC Channel A
 * (TxDA pin 15) at 9600 8N2 — the same channel the self-test uses.
 *
 * Tests performed (in order):
 *   1. RAM detection (1MB increments, 0x02000000-0x02FFFFFF)
 *   2. Data bus test (stuck-at, short between bits)
 *   3. Address bus test (power-of-2 offsets)
 *   4. Pattern fill/verify (0x00000000, 0xFFFFFFFF, 0xAAAAAAAA, 0x55555555)
 *   5. Walking ones (each bit individually)
 *   6. Walking zeros (complement)
 *   7. Address-as-data (catches address line faults)
 *   8. Byte-lane isolation (tests each byte lane independently)
 *
 * Reports:
 *   - Exact failing address
 *   - Expected vs actual value
 *   - XOR (failing bit mask)
 *   - Byte lane identification (HH/HM/LM/LL)
 *   - SIPP module location guidance
 *
 * Stack and variables use 0x02000400-0x0200FFFF (first 64KB).
 * Tests run on 0x02010000 to top of detected RAM.
 */

extern scc_putc();
extern scc_puts();
extern delay_ms();

/* ---- Minimal libc ---- */

static char *
memset(s, c, n)
    char *s;
    int c, n;
{
    int i;
    for (i = 0; i < n; i++) s[i] = c;
    return s;
}

/* ---- Output helpers ---- */

static void
print(s)
    char *s;
{
    scc_puts(s);
}

static void
print_hex_nibble(n)
    int n;
{
    n &= 0xF;
    scc_putc(n < 10 ? '0' + n : 'A' - 10 + n);
}

static void
print_hex8(val)
    unsigned long val;
{
    int i;
    for (i = 28; i >= 0; i -= 4)
        print_hex_nibble(val >> i);
}

static void
print_hex4(val)
    unsigned int val;
{
    print_hex_nibble(val >> 12);
    print_hex_nibble(val >> 8);
    print_hex_nibble(val >> 4);
    print_hex_nibble(val);
}

static void
print_hex2(val)
    unsigned int val;
{
    print_hex_nibble(val >> 4);
    print_hex_nibble(val);
}

static void
print_dec(val)
    int val;
{
    char buf[12];
    int i, neg;
    neg = 0;
    if (val < 0) { neg = 1; val = -val; }
    i = 11;
    buf[i] = 0;
    if (val == 0) buf[--i] = '0';
    while (val > 0) { buf[--i] = '0' + (val % 10); val /= 10; }
    if (neg) buf[--i] = '-';
    print(buf + i);
}

static void
nl()
{
    print("\r\n");
}

/* ---- RAM access (volatile to prevent optimization) ---- */

static void
ram_write(addr, val)
    unsigned long addr;
    unsigned long val;
{
    *(volatile unsigned long *)addr = val;
}

static unsigned long
ram_read(addr)
    unsigned long addr;
{
    return *(volatile unsigned long *)addr;
}

/* ---- Test state ---- */

static int total_errors;
static int test_errors;
static unsigned long first_fail_addr;
static unsigned long first_fail_expected;
static unsigned long first_fail_actual;
static unsigned long fail_bit_union;  /* OR of all failing bit masks */

static void
report_fail(addr, expected, actual)
    unsigned long addr, expected, actual;
{
    unsigned long xor_val;
    xor_val = expected ^ actual;

    if (test_errors == 0)
    {
        first_fail_addr = addr;
        first_fail_expected = expected;
        first_fail_actual = actual;
    }
    fail_bit_union |= xor_val;
    test_errors++;
    total_errors++;

    /* Print first 8 failures per test, then just count */
    if (test_errors <= 8)
    {
        print("  FAIL @ 0x");
        print_hex8(addr);
        print(": wrote 0x");
        print_hex8(expected);
        print(" read 0x");
        print_hex8(actual);
        print(" XOR 0x");
        print_hex8(xor_val);
        nl();
    }
    else if (test_errors == 9)
    {
        print("  (suppressing further errors for this test...)\r\n");
    }
}

/* ---- Test 1: Detect installed RAM ---- */

static unsigned long ram_top;
static int ram_mb;

static void
detect_ram()
{
    unsigned long addr, save, probe;
    int mb;

    print("\r\n=== RAM Detection ===\r\n");
    ram_top = 0x02000000;
    mb = 0;

    for (addr = 0x02000000; addr < 0x03000000; addr += 0x100000)
    {
        save = ram_read(addr);
        ram_write(addr, 0x5555AAAA);
        /* Clear a nearby location to catch aliases */
        ram_write(addr + 0x300, 0);
        probe = ram_read(addr);
        ram_write(addr, save);

        if (probe == 0x5555AAAA)
        {
            print("  0x");
            print_hex8(addr);
            print("-0x");
            print_hex8(addr + 0xFFFFF);
            print(": OK (1MB)\r\n");
            ram_top = addr + 0x100000;
            mb++;
        }
        else
        {
            print("  0x");
            print_hex8(addr);
            print("-0x");
            print_hex8(addr + 0xFFFFF);
            print(": not present (read 0x");
            print_hex8(probe);
            print(")\r\n");
        }
    }

    ram_mb = mb;
    print("Total: ");
    print_dec(mb);
    print(" MB detected (top = 0x");
    print_hex8(ram_top);
    print(")\r\n");
}

/* ---- Test 2: Data bus test ---- */

static void
test_data_bus(base)
    unsigned long base;
{
    unsigned long pat, read;
    int bit;

    print("\r\n=== Data Bus Test (at 0x");
    print_hex8(base);
    print(") ===\r\n");
    test_errors = 0;

    /* Walking ones */
    for (bit = 0; bit < 32; bit++)
    {
        pat = 1UL << bit;
        ram_write(base, pat);
        read = ram_read(base);
        if (read != pat)
            report_fail(base, pat, read);
    }

    /* Walking zeros */
    for (bit = 0; bit < 32; bit++)
    {
        pat = ~(1UL << bit);
        ram_write(base, pat);
        read = ram_read(base);
        if (read != pat)
            report_fail(base, pat, read);
    }

    if (test_errors == 0)
        print("  PASS\r\n");
    else
    {
        print("  ");
        print_dec(test_errors);
        print(" errors\r\n");
    }
}

/* ---- Test 3: Address bus test ---- */

static void
test_addr_bus(base, size)
    unsigned long base, size;
{
    unsigned long mask, offset, test_offset;
    unsigned long pat, anti_pat, read;

    print("\r\n=== Address Bus Test (0x");
    print_hex8(base);
    print(" - 0x");
    print_hex8(base + size - 1);
    print(") ===\r\n");
    test_errors = 0;

    pat = 0xAAAAAAAA;
    anti_pat = 0x55555555;
    mask = size - 1;  /* assumes power of 2 -- we'll round down */

    /* Write pattern to each power-of-2 offset */
    ram_write(base, anti_pat);
    for (offset = 4; offset & mask; offset <<= 1)
        ram_write(base + offset, pat);

    /* Check that base still has anti_pat (no address bit stuck high) */
    read = ram_read(base);
    if (read != anti_pat)
        report_fail(base, anti_pat, read);

    /* Check each offset still has pat (no address bit stuck low or shorted) */
    for (test_offset = 4; test_offset & mask; test_offset <<= 1)
    {
        /* Write anti_pat to base to check for aliasing */
        ram_write(base, anti_pat);
        read = ram_read(base + test_offset);
        if (read != pat)
            report_fail(base + test_offset, pat, read);
    }

    if (test_errors == 0)
        print("  PASS\r\n");
    else
    {
        print("  ");
        print_dec(test_errors);
        print(" errors (possible address line fault)\r\n");
    }
}

/* ---- Test 4: Pattern fill/verify ---- */

static void
test_pattern(base, size, pattern, name)
    unsigned long base, size, pattern;
    char *name;
{
    unsigned long addr, end, read;

    print("  Pattern 0x");
    print_hex8(pattern);
    print(" (");
    print(name);
    print(")... fill...");

    end = base + size;

    /* Fill */
    for (addr = base; addr < end; addr += 4)
        ram_write(addr, pattern);

    print(" verify...");

    /* Verify */
    for (addr = base; addr < end; addr += 4)
    {
        read = ram_read(addr);
        if (read != pattern)
        {
            report_fail(addr, pattern, read);
            if (test_errors > 16)
            {
                print(" (stopping early)\r\n");
                return;
            }
        }
    }

    if (test_errors == 0)
        print(" PASS\r\n");
    else
    {
        print(" ");
        print_dec(test_errors);
        print(" errors\r\n");
    }
}

static void
test_all_patterns(base, size)
    unsigned long base, size;
{
    print("\r\n=== Pattern Tests (0x");
    print_hex8(base);
    print(" - 0x");
    print_hex8(base + size - 1);
    print(") ===\r\n");

    test_errors = 0;
    test_pattern(base, size, 0x00000000, "all zeros");
    test_errors = 0;
    test_pattern(base, size, 0xFFFFFFFF, "all ones");
    test_errors = 0;
    test_pattern(base, size, 0xAAAAAAAA, "checkerboard");
    test_errors = 0;
    test_pattern(base, size, 0x55555555, "inv checkerboard");
}

/* ---- Test 5: Walking bit tests ---- */

static void
test_walking_bits(base, size)
    unsigned long base, size;
{
    unsigned long addr, end, pat, read;
    int bit, pass;

    print("\r\n=== Walking Bit Tests ===\r\n");

    for (pass = 0; pass < 2; pass++)
    {
        test_errors = 0;
        if (pass == 0)
            print("  Walking ones...");
        else
            print("  Walking zeros...");

        end = base + size;
        bit = 0;

        for (addr = base; addr < end; addr += 4)
        {
            if (pass == 0)
                pat = 1UL << (bit & 31);
            else
                pat = ~(1UL << (bit & 31));
            ram_write(addr, pat);
            bit++;
        }

        /* Verify */
        bit = 0;
        for (addr = base; addr < end; addr += 4)
        {
            if (pass == 0)
                pat = 1UL << (bit & 31);
            else
                pat = ~(1UL << (bit & 31));
            read = ram_read(addr);
            if (read != pat)
            {
                report_fail(addr, pat, read);
                if (test_errors > 16) break;
            }
            bit++;
        }

        if (test_errors == 0)
            print(" PASS\r\n");
        else
        {
            print(" ");
            print_dec(test_errors);
            print(" errors\r\n");
        }
    }
}

/* ---- Test 6: Address-as-data ---- */

static void
test_addr_as_data(base, size)
    unsigned long base, size;
{
    unsigned long addr, end, read;

    print("\r\n=== Address-as-Data Test ===\r\n");
    test_errors = 0;
    end = base + size;

    print("  Fill (addr -> [addr])...");
    for (addr = base; addr < end; addr += 4)
        ram_write(addr, addr);

    print(" verify...");
    for (addr = base; addr < end; addr += 4)
    {
        read = ram_read(addr);
        if (read != addr)
        {
            report_fail(addr, addr, read);
            if (test_errors > 16) break;
        }
    }

    if (test_errors == 0)
        print(" PASS\r\n");
    else
    {
        print(" ");
        print_dec(test_errors);
        print(" errors\r\n");
    }

    /* Inverse */
    test_errors = 0;
    print("  Fill (~addr -> [addr])...");
    for (addr = base; addr < end; addr += 4)
        ram_write(addr, ~addr);

    print(" verify...");
    for (addr = base; addr < end; addr += 4)
    {
        read = ram_read(addr);
        if (read != ~addr)
        {
            report_fail(addr, ~addr, read);
            if (test_errors > 16) break;
        }
    }

    if (test_errors == 0)
        print(" PASS\r\n");
    else
    {
        print(" ");
        print_dec(test_errors);
        print(" errors\r\n");
    }
}

/* ---- Test 7: Byte lane isolation ---- */

static void
test_byte_lanes(base, size)
    unsigned long base, size;
{
    unsigned long addr, end, pat, read;
    int lane;
    static char *lane_name[4];
    static unsigned long lane_pat[4];
    static int init_done;

    if (!init_done)
    {
        lane_name[0] = "LL (bits 0-7)  ";
        lane_name[1] = "LM (bits 8-15) ";
        lane_name[2] = "HM (bits 16-23)";
        lane_name[3] = "HH (bits 24-31)";
        lane_pat[0] = 0x000000FF;
        lane_pat[1] = 0x0000FF00;
        lane_pat[2] = 0x00FF0000;
        lane_pat[3] = 0xFF000000;
        init_done = 1;
    }

    print("\r\n=== Byte Lane Isolation Test ===\r\n");
    end = base + size;

    for (lane = 0; lane < 4; lane++)
    {
        test_errors = 0;
        pat = lane_pat[lane];
        print("  Lane ");
        print(lane_name[lane]);
        print(" pattern 0x");
        print_hex8(pat);
        print("...");

        /* Fill with only this lane active */
        for (addr = base; addr < end; addr += 4)
            ram_write(addr, pat);

        /* Verify */
        for (addr = base; addr < end; addr += 4)
        {
            read = ram_read(addr);
            if (read != pat)
            {
                report_fail(addr, pat, read);
                if (test_errors > 8) break;
            }
        }

        if (test_errors == 0)
            print(" PASS\r\n");
        else
        {
            print(" ");
            print_dec(test_errors);
            print(" errors\r\n");
        }
    }
}

/* ---- Per-megabyte quick test ---- */

static int mb_status[16];  /* 0=untested, 1=pass, 2=fail */

static void
test_per_mb()
{
    unsigned long base, read;
    int mb, bit, errors;

    print("\r\n=== Per-Megabyte Quick Test ===\r\n");

    for (mb = 0; mb < ram_mb; mb++)
    {
        base = 0x02000000 + (unsigned long)mb * 0x100000;
        if (mb == 0) base = 0x02010000;  /* skip stack area */

        print("  MB ");
        print_dec(mb);
        print(" (0x");
        print_hex8(base);
        print("): ");

        errors = 0;

        /* Quick: write 0xFFFFFFFF, verify, write 0x00000000, verify */
        /* Test start, middle, end of each MB */
        {
            unsigned long addrs[6];
            unsigned long end_addr;
            int naddr, a;

            end_addr = 0x02000000 + (unsigned long)(mb + 1) * 0x100000 - 4;
            addrs[0] = base;
            addrs[1] = base + 0x40000;
            addrs[2] = base + 0x80000;
            addrs[3] = base + 0xC0000;
            addrs[4] = end_addr - 0x40000;
            addrs[5] = end_addr;
            naddr = 6;

            for (a = 0; a < naddr; a++)
            {
                if (addrs[a] < base || addrs[a] >= end_addr + 4) continue;

                for (bit = 0; bit < 32; bit++)
                {
                    unsigned long pat;
                    pat = 1UL << bit;
                    ram_write(addrs[a], pat);
                    read = ram_read(addrs[a]);
                    if (read != pat) errors++;

                    pat = ~pat;
                    ram_write(addrs[a], pat);
                    read = ram_read(addrs[a]);
                    if (read != pat) errors++;
                }
            }
        }

        if (errors == 0)
        {
            print("PASS\r\n");
            mb_status[mb] = 1;
        }
        else
        {
            print("FAIL (");
            print_dec(errors);
            print(" errors)\r\n");
            mb_status[mb] = 2;
        }
    }
}

/* ---- Summary ---- */

static void
print_summary()
{
    int bit, lane, mb;
    unsigned long mask;

    print("\r\n");
    print("============================================================\r\n");
    print("                     TEST SUMMARY\r\n");
    print("============================================================\r\n\r\n");

    if (total_errors == 0)
    {
        print("ALL TESTS PASSED -- RAM appears healthy.\r\n");
        print("Total RAM: ");
        print_dec(ram_mb);
        print(" MB\r\n");
        return;
    }

    print("Total errors: ");
    print_dec(total_errors);
    nl();

    if (first_fail_addr)
    {
        print("First failure at: 0x");
        print_hex8(first_fail_addr);
        nl();
        print("  Expected: 0x");
        print_hex8(first_fail_expected);
        nl();
        print("  Actual:   0x");
        print_hex8(first_fail_actual);
        nl();
        print("  XOR:      0x");
        print_hex8(first_fail_expected ^ first_fail_actual);
        nl();
    }

    if (fail_bit_union)
    {
        print("\r\nFailing data bus bits (union of all errors):\r\n  ");
        for (bit = 31; bit >= 0; bit--)
        {
            if (fail_bit_union & (1UL << bit))
                scc_putc('X');
            else
                scc_putc('.');
            if (bit == 24 || bit == 16 || bit == 8)
                scc_putc(' ');
        }
        nl();
        print("  HH       HM       LM       LL\r\n");
        print("  D31..D24 D23..D16 D15..D8  D7..D0\r\n\r\n");

        print("Affected byte lanes:\r\n");
        for (lane = 3; lane >= 0; lane--)
        {
            mask = 0xFFUL << (lane * 8);
            if (fail_bit_union & mask)
            {
                print("  ");
                switch (lane)
                {
                case 3: print("HH (bits 24-31)"); break;
                case 2: print("HM (bits 16-23)"); break;
                case 1: print("LM (bits 8-15)"); break;
                case 0: print("LL (bits 0-7)"); break;
                }
                print(" -- FAILING bits: ");
                for (bit = lane * 8 + 7; bit >= lane * 8; bit--)
                    if (fail_bit_union & (1UL << bit))
                    {
                        print("D");
                        print_dec(bit);
                        print(" ");
                    }
                nl();
            }
        }
    }

    print("\r\nPer-megabyte status:\r\n");
    for (mb = 0; mb < ram_mb; mb++)
    {
        print("  MB ");
        print_dec(mb);
        print(" (0x");
        print_hex8(0x02000000 + (unsigned long)mb * 0x100000);
        print("): ");
        switch (mb_status[mb])
        {
        case 0: print("not tested"); break;
        case 1: print("PASS"); break;
        case 2: print("FAIL"); break;
        }
        nl();
    }

    print("\r\n");
    print("SIPP module identification:\r\n");
    print("  The 68020 has a 32-bit data bus with 4 byte lanes.\r\n");
    print("  Each SIPP DRAM module covers one byte lane.\r\n");
    print("  Module layout (left to right, component side):\r\n");
    print("    HH (D31-D24) | HM (D23-D16) | LM (D15-D8) | LL (D7-D0)\r\n");
    print("  Replace the module(s) for the failing lane(s) listed above.\r\n");

    print("\r\n============================================================\r\n");
}

/* ---- Main ---- */

main()
{
    unsigned long test_base, test_size;

    total_errors = 0;
    first_fail_addr = 0;
    fail_bit_union = 0;
    memset(mb_status, 0, sizeof(mb_status));

    print("\r\n");
    print("============================================================\r\n");
    print("  Agfa Compugraphic 9000PS - RAM Diagnostic\r\n");
    print("  68020 @ 16MHz, SCC Channel A (pin 15), 9600 8N2\r\n");
    print("============================================================\r\n");

    /* Step 1: Detect RAM */
    detect_ram();

    if (ram_mb == 0)
    {
        print("\r\n*** NO RAM DETECTED ***\r\n");
        print("Check SIPP DRAM modules and power supply.\r\n");
        goto done;
    }

    /* Step 2: Quick per-MB test */
    test_per_mb();

    /* Step 3: Data bus test (use address in first good MB) */
    test_base = 0x02010000;
    test_data_bus(test_base);

    /* Step 4: Address bus test */
    test_size = ram_top - test_base;
    /* Round down to power of 2 for address test */
    {
        unsigned long p2;
        p2 = 1;
        while (p2 * 2 <= test_size) p2 *= 2;
        test_addr_bus(test_base, p2);
    }

    /* Step 5: Full pattern tests */
    test_all_patterns(test_base, ram_top - test_base);

    /* Step 6: Walking bit tests */
    test_walking_bits(test_base, ram_top - test_base);

    /* Step 7: Address-as-data */
    test_addr_as_data(test_base, ram_top - test_base);

    /* Step 8: Byte lane isolation */
    test_byte_lanes(test_base, ram_top - test_base);

    /* Summary */
    print_summary();

done:
    print("\r\nDiagnostic complete. System halted.\r\n");
    print("Power cycle to run again.\r\n");

    /* Halt */
    for (;;)
        ;
}
