/*
 * agfa9000.c -- Agfa Compugraphic 9000PS Emulator
 *
 * Emulates the Agfa 9000PS PostScript RIP main board:
 *   - Motorola 68020 @ 16MHz (via Musashi)
 *   - 640KB ROM (5 banks)
 *   - Up to 16MB RAM with optional stuck-bit fault injection
 *   - Zilog Z8530 SCC (proper register emulation, dual address decode)
 *   - AMD AM5380 SCSI (full bus phase state machine, HD image support)
 *   - Hardware registers at 0x06xxxxxx
 *
 * Usage:
 *   agfa9000 <rom_dir> [options]
 *   agfa9000 <rom_dir> -hd <image>       Mount HD image at SCSI ID 0
 *   agfa9000 <rom_dir> -stuck 16         Inject D16 stuck-low fault
 *   agfa9000 <rom_dir> -ram 6            Set RAM to 6MB
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>

#include "musashi/m68k.h"
#include "scc.h"
#include "scsi.h"

/* ================================================================== */
/* Memory                                                             */
/* ================================================================== */

#define ROM_SIZE    (128 * 1024)
#define ROM_BANKS   5
#define ROM_TOTAL   (ROM_SIZE * ROM_BANKS)
#define RAM_MAX     (16 * 1024 * 1024)

static unsigned char rom[ROM_TOTAL];
static unsigned char ram[RAM_MAX];
static unsigned int  ram_size = 4 * 1024 * 1024;

/* Stuck-bit fault injection */
static unsigned int  stuck_mask = 0;
static unsigned int  stuck_value = 0;
static unsigned int  stuck_addr_start = 0x02200000;
static unsigned int  stuck_addr_end   = 0x02300000;

/* Hardware registers */
static unsigned char bus_ctl_latch = 0x31;
static unsigned char gfx_ctl_latch = 0;
static unsigned short fifo_ctl = 0;
static unsigned int  display_ctl = 0;

/* Peripherals */
static scc_t scc;
static ncr5380_t scsi;

/* Cycle counter */
static unsigned long long total_cycles = 0;
static int verbose = 0;

/* Terminal */
static struct termios orig_termios;
static int terminal_raw = 0;

/* ================================================================== */
/* Terminal I/O                                                       */
/* ================================================================== */

static void term_raw_on(void)
{
    struct termios t;
    tcgetattr(0, &orig_termios);
    t = orig_termios;
    t.c_lflag &= ~(ICANON | ECHO);
    t.c_cc[VMIN] = 0;
    t.c_cc[VTIME] = 0;
    tcsetattr(0, TCSANOW, &t);
    fcntl(0, F_SETFL, fcntl(0, F_GETFL) | O_NONBLOCK);
    terminal_raw = 1;
}

static void term_raw_off(void)
{
    if (terminal_raw) {
        fcntl(0, F_SETFL, fcntl(0, F_GETFL) & ~O_NONBLOCK);
        tcsetattr(0, TCSANOW, &orig_termios);
        terminal_raw = 0;
    }
}

/* ================================================================== */
/* SCC TX callback — sends serial output to host stdout               */
/* ================================================================== */

static void scc_tx_handler(int channel, uint8_t data, void *ctx)
{
    /* Output from both channels goes to stdout */
    char c = data;
    write(1, &c, 1);
}

/* Check host stdin for input → feed to SCC RX */
static void check_host_input(void)
{
    unsigned char c;
    if (read(0, &c, 1) == 1) {
        /* Feed to both channels */
        scc_rx_char(&scc, SCC_CH_A, c);
        scc_rx_char(&scc, SCC_CH_B, c);
    }
}

/* ================================================================== */
/* RAM with stuck-bit fault injection                                 */
/* ================================================================== */

static inline unsigned char apply_stuck_byte(unsigned int addr, unsigned char val)
{
    if (stuck_mask && addr >= stuck_addr_start && addr < stuck_addr_end) {
        int byte_pos = 3 - (addr & 3);
        unsigned char byte_mask = (stuck_mask >> (byte_pos * 8)) & 0xFF;
        if (byte_mask) {
            if (stuck_value) val |= byte_mask;
            else val &= ~byte_mask;
        }
    }
    return val;
}

/* ================================================================== */
/* Musashi memory callbacks                                           */
/* ================================================================== */

unsigned int m68k_read_memory_8(unsigned int addr)
{
    /* ROM */
    if (addr < ROM_TOTAL)
        return rom[addr];

    /* RAM */
    if (addr >= 0x02000000 && addr < 0x02000000 + ram_size)
        return apply_stuck_byte(addr, ram[addr - 0x02000000]);

    /* SCC #1 at 0x04000000 (register-per-address PAL decode) */
    if (addr >= 0x04000000 && addr <= 0x0400002F)
        return scc_pal_read(&scc, addr & 0x3F);

    /* SCSI at 0x05000001 (odd byte lane) */
    if (addr >= 0x05000001 && addr <= 0x0500000F && (addr & 1))
        return ncr5380_read(&scsi, (addr - 0x05000001) >> 1);

    /* SCSI pseudo-DMA */
    if (addr == 0x05000026)
        return ncr5380_dma_read(&scsi);

    /* Bus control latch */
    if (addr == 0x06000000) return bus_ctl_latch;
    if (addr == 0x06080000) return gfx_ctl_latch;
    if (addr == 0x060C0000) return fifo_ctl >> 8;
    if (addr == 0x060C0001) return fifo_ctl & 0xFF;
    if (addr >= 0x06100000 && addr <= 0x06100003)
        return (display_ctl >> (8 * (3 - (addr & 3)))) & 0xFF;

    /* SCC #2 at 0x07000000 (compact byte-addressed) */
    if (addr >= 0x07000000 && addr <= 0x07000003)
        return scc_compact_read(&scc, addr & 3);

    /* SCC reset strobe */
    if (addr == 0x07000020)
        return 0;

    return 0;
}

unsigned int m68k_read_memory_16(unsigned int addr)
{
    return (m68k_read_memory_8(addr) << 8) | m68k_read_memory_8(addr + 1);
}

unsigned int m68k_read_memory_32(unsigned int addr)
{
    /* Fast path: ROM */
    if (addr + 3 < ROM_TOTAL)
        return (rom[addr] << 24) | (rom[addr+1] << 16)
             | (rom[addr+2] << 8) | rom[addr+3];

    /* Fast path: RAM */
    if (addr >= 0x02000000 && addr + 3 < 0x02000000 + ram_size) {
        unsigned int off = addr - 0x02000000;
        unsigned int val = (ram[off] << 24) | (ram[off+1] << 16)
                         | (ram[off+2] << 8) | ram[off+3];
        if (stuck_mask && addr >= stuck_addr_start && addr < stuck_addr_end) {
            if (stuck_value) val |= stuck_mask;
            else val &= ~stuck_mask;
        }
        return val;
    }

    return (m68k_read_memory_16(addr) << 16) | m68k_read_memory_16(addr + 2);
}

void m68k_write_memory_8(unsigned int addr, unsigned int val)
{
    if (addr >= 0x02000000 && addr < 0x02000000 + ram_size) {
        ram[addr - 0x02000000] = val;
        return;
    }
    if (addr >= 0x04000000 && addr <= 0x0400002F) {
        scc_pal_write(&scc, addr & 0x3F, val);
        return;
    }
    if (addr >= 0x05000001 && addr <= 0x0500000F && (addr & 1)) {
        ncr5380_write(&scsi, (addr - 0x05000001) >> 1, val);
        return;
    }
    if (addr == 0x05000026) { ncr5380_dma_write(&scsi, val); return; }
    if (addr == 0x06000000) { bus_ctl_latch = val; return; }
    if (addr == 0x06080000) { gfx_ctl_latch = val; return; }
    if (addr == 0x060C0000) { fifo_ctl = val << 8; return; }
    if (addr == 0x060C0001) { fifo_ctl = (fifo_ctl & 0xFF00) | val; return; }
    if (addr >= 0x06100000 && addr <= 0x06100003) {
        int shift = 8 * (3 - (addr & 3));
        display_ctl = (display_ctl & ~(0xFF << shift)) | (val << shift);
        return;
    }
    if (addr >= 0x07000000 && addr <= 0x07000003) {
        scc_compact_write(&scc, addr & 3, val);
        return;
    }
    /* Ignore: ROM writes, SCC strobe, unmapped */
}

void m68k_write_memory_16(unsigned int addr, unsigned int val)
{
    m68k_write_memory_8(addr, (val >> 8) & 0xFF);
    m68k_write_memory_8(addr + 1, val & 0xFF);
}

void m68k_write_memory_32(unsigned int addr, unsigned int val)
{
    if (addr >= 0x02000000 && addr + 3 < 0x02000000 + ram_size) {
        unsigned int off = addr - 0x02000000;
        ram[off]   = (val >> 24) & 0xFF;
        ram[off+1] = (val >> 16) & 0xFF;
        ram[off+2] = (val >> 8) & 0xFF;
        ram[off+3] = val & 0xFF;
        return;
    }
    m68k_write_memory_16(addr, (val >> 16) & 0xFFFF);
    m68k_write_memory_16(addr + 2, val & 0xFFFF);
}

/* ================================================================== */
/* ROM loading                                                        */
/* ================================================================== */

static int load_rom(const char *dir, int bank, const char *name)
{
    char path[512];
    FILE *f;
    size_t n;
    snprintf(path, sizeof(path), "%s/%s", dir, name);
    f = fopen(path, "rb");
    if (!f) { fprintf(stderr, "Cannot open %s\n", path); return -1; }
    n = fread(rom + bank * ROM_SIZE, 1, ROM_SIZE, f);
    fclose(f);
    if (n != ROM_SIZE) {
        fprintf(stderr, "Short read on %s: %zu/%d bytes\n", path, n, ROM_SIZE);
        return -1;
    }
    fprintf(stderr, "Loaded %s -> bank %d (0x%05X-0x%05X)\n",
            name, bank, bank * ROM_SIZE, (bank + 1) * ROM_SIZE - 1);
    return 0;
}

static int load_all_roms(const char *dir)
{
    static const char *names[] = {"0.bin", "1.bin", "2.bin", "3.bin", "4.bin"};
    int i;
    for (i = 0; i < ROM_BANKS; i++)
        if (load_rom(dir, i, names[i]) < 0) return -1;
    return 0;
}

/* ================================================================== */
/* Main                                                               */
/* ================================================================== */

static void usage(const char *prog)
{
    fprintf(stderr, "Agfa 9000PS Emulator\n\n");
    fprintf(stderr, "Usage: %s <rom_dir> [options]\n\n", prog);
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  -hd <image>       Mount HD image at SCSI ID 0 (512-byte sectors)\n");
    fprintf(stderr, "  -hd1024 <image>   Mount HD image at SCSI ID 0 (1024-byte sectors)\n");
    fprintf(stderr, "  -ram <MB>         Set RAM size (1-16, default 4)\n");
    fprintf(stderr, "  -stuck <bit>      Inject stuck-LOW fault on data bit (0-31)\n");
    fprintf(stderr, "  -stuck-high <bit> Inject stuck-HIGH fault\n");
    fprintf(stderr, "  -stuck-range <start> <end>  Fault address range (hex)\n");
    fprintf(stderr, "  -v                Verbose logging\n");
    fprintf(stderr, "\nExample: %s roms/ -stuck 16 -hd HD00_Agfa_RIP.hda\n", prog);
    exit(1);
}

int main(int argc, char **argv)
{
    const char *rom_dir = NULL;
    const char *hd_image = NULL;
    int hd_block_size = 512;
    int stuck_bit = -1;
    int stuck_high = 0;
    int i;

    for (i = 1; i < argc; i++) {
        if (argv[i][0] != '-') {
            rom_dir = argv[i];
        } else if (!strcmp(argv[i], "-hd") && i+1 < argc) {
            hd_image = argv[++i]; hd_block_size = 512;
        } else if (!strcmp(argv[i], "-hd1024") && i+1 < argc) {
            hd_image = argv[++i]; hd_block_size = 1024;
        } else if (!strcmp(argv[i], "-ram") && i+1 < argc) {
            ram_size = atoi(argv[++i]) * 1024 * 1024;
            if (ram_size > RAM_MAX) ram_size = RAM_MAX;
        } else if (!strcmp(argv[i], "-stuck") && i+1 < argc) {
            stuck_bit = atoi(argv[++i]);
        } else if (!strcmp(argv[i], "-stuck-high") && i+1 < argc) {
            stuck_bit = atoi(argv[++i]); stuck_high = 1;
        } else if (!strcmp(argv[i], "-stuck-range") && i+2 < argc) {
            stuck_addr_start = strtoul(argv[++i], NULL, 16);
            stuck_addr_end = strtoul(argv[++i], NULL, 16);
        } else if (!strcmp(argv[i], "-v")) {
            verbose = 1;
        } else {
            usage(argv[0]);
        }
    }
    if (!rom_dir) usage(argv[0]);

    /* Fault injection */
    if (stuck_bit >= 0 && stuck_bit < 32) {
        stuck_mask = 1U << stuck_bit;
        stuck_value = stuck_high ? 1 : 0;
        fprintf(stderr, "Fault: D%d stuck %s at 0x%08X-0x%08X\n",
                stuck_bit, stuck_high ? "HIGH" : "LOW",
                stuck_addr_start, stuck_addr_end);
    }

    /* Init peripherals */
    scc_init(&scc);
    scc_set_tx_callback(&scc, SCC_CH_A, scc_tx_handler, NULL);
    scc_set_tx_callback(&scc, SCC_CH_B, scc_tx_handler, NULL);
    /* CTS on Channel B: deasserted by default (auto-boots to PostScript,
     * matching Adrian's hardware). Use -cts to assert it and get the
     * Atlas Monitor prompt instead. */
    scc_set_cts(&scc, SCC_CH_B, 0);

    ncr5380_init(&scsi);

    /* Load ROMs */
    fprintf(stderr, "Agfa 9000PS Emulator\n");
    fprintf(stderr, "RAM: %d MB\n", ram_size / (1024 * 1024));
    if (load_all_roms(rom_dir) < 0) return 1;

    /* Mount HD image */
    if (hd_image) {
        if (ncr5380_attach_image(&scsi, 0, hd_image, hd_block_size) < 0)
            return 1;
    }

    /* Init CPU */
    m68k_init();
    m68k_set_cpu_type(M68K_CPU_TYPE_68020);
    m68k_pulse_reset();

    fprintf(stderr, "CPU: SSP=0x%08X PC=0x%08X\n",
            m68k_read_memory_32(0), m68k_read_memory_32(4));
    fprintf(stderr, "Running... (Ctrl+C to quit)\n---\n");

    term_raw_on();
    atexit(term_raw_off);

    /* Main loop: 16MHz = 160K cycles per 10ms slice */
    {
        unsigned long long last_report = 0;
        for (;;) {
            int cycles = m68k_execute(160000);
            total_cycles += cycles;

            check_host_input();
            scc_tick(&scc);
            ncr5380_tick(&scsi);

            if (verbose && total_cycles - last_report > 16000000) {
                unsigned int pc = m68k_get_reg(NULL, M68K_REG_PC);
                fprintf(stderr, "[%llu] PC=0x%08X\n", total_cycles, pc);
                last_report = total_cycles;
            }
        }
    }

    return 0;
}
