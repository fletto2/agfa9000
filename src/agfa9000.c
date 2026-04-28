/*
 * agfa9000.c -- Agfa Compugraphic 9000PS Emulator
 *
 * Emulates the Agfa 9000PS PostScript RIP (dual-CPU):
 *   - Main board: Motorola 68020 @ 16MHz (via Musashi)
 *   - IO board: Motorola 68000 @ 8MHz (MC68681 DUART + MK4501N FIFO)
 *   - 640KB ROM (5 banks), up to 16MB RAM
 *   - Zilog Z8530 SCC at 0x07000000 (Ch A RS-232, Ch B RS-422)
 *   - 2x R6522 VIA at 0x04000000/0x04000020 (IO board communication)
 *   - AMD AM5380 SCSI at 0x05000000 (full bus phase state machine)
 *   - Xicor X2804AP EEPROM (512 bytes, persistent)
 *   - VERA video module (optional, replaces VIA #2)
 *   - Hardware registers at 0x06xxxxxx
 *
 * Usage:
 *   agfa9000 <rom_dir> [options]
 *   agfa9000 <rom_dir> -hd <image>       Mount HD image at SCSI ID 0
 *   agfa9000 <rom_dir> -ram 6            Set RAM to 6MB
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <stdarg.h>
#include <pthread.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <errno.h>
#include <signal.h>
#include <sys/file.h>

#ifdef ENABLE_VERA_SDL
#include <SDL2/SDL.h>
static SDL_Window *sdl_window = NULL;
static SDL_Renderer *sdl_renderer = NULL;
static SDL_Texture *sdl_texture = NULL;
static uint32_t vera_fb[640 * 480];
static SDL_AudioDeviceID sdl_audio_dev = 0;

/* Audio callback — SDL calls this from a separate thread to fill the output buffer.
 * We render VERA PSG+PCM at the native ~48828 Hz rate and let SDL resample. */
extern void vera_audio_render(int16_t *buf, int num_samples);

static void sdl_audio_callback(void *userdata, Uint8 *stream, int len) {
    (void)userdata;
    int16_t *buf = (int16_t *)stream;
    int num_samples = len / (2 * sizeof(int16_t));
    vera_audio_render(buf, num_samples);
}
#endif

#include "musashi/m68k.h"
#include "scc.h"
#include "scsi.h"
#include "ioboard.h"

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


/* Hardware registers */
static unsigned char bus_ctl_latch = 0x31;
static unsigned char gfx_ctl_latch = 0;
static unsigned short fifo_ctl = 0;
static unsigned int  display_ctl = 0;

/* Peripherals */
static scc_t scc;
static ncr5380_t scsi;

/* R6522 VIA #1 (0x04000000) + VIA #2 (0x04000020) — IO board communication */
#include "via.h"
static via6522_t via[2];
static int via_last_cycles[2] = {0, 0};
/* DSACK bus stall for VIA1 / VERA accesses.
 *
 * Real hardware: any access in the $04000000-$0400003F range (VIA #1 at
 * $04000000-$0400001F, VIA #2 socket / VERA at $04000020-$0400003F) holds
 * /DSACK for 16 clocks total before the bus cycle terminates.  At
 * 16 MHz that's 1 µs per byte access — same speed as the M6800-family
 * E-clock the original PAL was designed around.
 *
 * Musashi normally charges ~4 clocks for a memory access, so we owe an
 * extra 12 clocks per byte hit.  We charge it by directly decrementing
 * `m68ki_remaining_cycles` — the cleanest way to model bus wait states
 * at the access point.  m68k_execute()'s return value (initial -
 * remaining) goes up by exactly the amount we charged, so VIA timer
 * accounting and PCM rate calculations both see real wall time.
 *
 * 16-bit and 32-bit accesses to this region fall through to two/four
 * byte handlers in the m68k_read_memory_16/32 / m68k_write_memory_16/32
 * fall-through paths, so a single charge in the 8-bit handler covers
 * everything correctly. */
extern int m68ki_remaining_cycles;
#define DSACK_STALL_EXTRA 12
static inline void bus_stall_dtack(void) {
    m68ki_remaining_cycles -= DSACK_STALL_EXTRA;
}

/* SCSI bandwidth throttle — 1 MB/s at 16 MHz = 16 cycles/byte.  Musashi
 * already charges ~4 clocks per access, so we owe 12 extra cycles per
 * data byte.  Applied to the pseudo-DMA port (0x05000020, bulk path)
 * and to IDATA/ODATA register access during DATA_IN/DATA_OUT phases. */
#define SCSI_STALL_EXTRA 12
static inline void scsi_stall(void) {
    m68ki_remaining_cycles -= SCSI_STALL_EXTRA;
}

/* Deferred binary load (survives monitor RAM test) */
static const char *deferred_load_file = NULL;
static uint32_t deferred_load_addr = 0;
static int deferred_load_done = 0;

/* Auto-boot: when set, the emulator overwrites the CPU PC with this
 * address after AGFA-MON has finished its RAM test (same threshold
 * as -load).  Used to skip the monitor handshake and jump straight
 * to a guest OS — typically 0x20000 (CP/M) or 0x40000 (Minix).
 * Set via -boot cpm / -boot minix / -boot 0x40000. */
static uint32_t auto_boot_addr = 0;
static int auto_boot_done = 0;

/* VERA video module — replaces VIA #2 when enabled with -vera flag */
#include "vera.h"
static vera_t vera;
static int vera_enabled = 0;
static int nosound = 0;
static FILE *trace_file = NULL;

/* Xicor X2804AP EEPROM — 512 bytes, persisted to file.
 * Real hardware: $071F0000 (PAL decodes entire $07xxxxxx range).
 * Emulator decodes at $07100000 (firmware reads work at any $07xx offset). */
static uint8_t eeprom[512];
static const char *eeprom_file = "eeprom.bin";

static void eeprom_load(void) {
    FILE *f = fopen(eeprom_file, "rb");
    if (f) { fread(eeprom, 1, 512, f); fclose(f); }
    else {
        /* Create initial erased EEPROM file */
        memset(eeprom, 0xFF, 512);
        f = fopen(eeprom_file, "wb");
        if (f) { fwrite(eeprom, 1, 512, f); fclose(f); }
    }
}

static void eeprom_write_byte(int offset, uint8_t val) {
    FILE *f = fopen(eeprom_file, "r+b");
    if (!f) f = fopen(eeprom_file, "w+b");
    if (!f) return;
    if (fseek(f, offset, SEEK_SET) == 0)
        fwrite(&val, 1, 1, f);
    fclose(f);
}

/* Synchronize VIA timer to current CPU cycle within the m68k_execute() slice.
 * Called from memory callbacks before VIA register reads/writes.
 * Uses m68k_cycles_run() to compute elapsed E-clock ticks since last sync.
 * If the timer fires (underflow), calls m68k_end_timeslice() to force
 * m68k_execute() to return early so the main loop can assert the IRQ. */
static void via_sync(int num)
{
    int now = m68k_cycles_run();
    int delta = now - via_last_cycles[num];
    if (delta > 0) {
        int e_ticks = delta / 10;  /* E clock = CPU / 10 */
        if (e_ticks > 0) {
            int irq = via_tick(&via[num], e_ticks);
            via_last_cycles[num] = now;
            if (irq) {
                /* Timer fired — end the timeslice so the main loop
                 * can assert the interrupt before the next execute(). */
                m68k_end_timeslice();
            }
        }
    }
}

/* IO board */
static ioboard_t ioboard;
static xfifo_t fifo_main_to_io;
static xfifo_t fifo_io_to_main;
extern ioboard_t *current_io_ptr;  /* defined in ioboard.c */

/* CPU dispatch: 0 = main 68020, 1 = IO board 68000 */
int emu_current_cpu = 0;

/* Cycle counter */
static unsigned long long total_cycles = 0;
int verbose = 0;

/* Sys/Start injection: feed the boot PS file through SCC after XON */
static unsigned char *sysstart_data = NULL;
static int sysstart_len = 0;
static int sysstart_pos = 0;

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
    t.c_lflag &= ~(ICANON | ECHO | ISIG);
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

static int irq_count = 0;
static void scc_irq_handler(int state, void *ctx)
{
    /* SCC interrupt: Level 6 autovector on the Agfa 9000PS.
     * Note: main loop unified IRQ block also handles SCC IRQs directly. */
    if (state) {
        m68k_set_irq(6);
        irq_count++;
    } else {
        m68k_set_irq(0);
    }
}

/* Check host stdin for input → feed to SCC RX */
/* Track which SCC channel has been read from (= active console).
 * Referenced by scc.c to auto-detect on first RX data read. */
int console_channel = -1;  /* -1 = unknown, feed both */

static void check_host_input(void)
{
    /* Throttle stdin reads to ~100/sec to reduce syscall overhead.
     * At 6K+ main loop iterations/sec, checking every 64th saves 98% of reads. */
    static int input_skip = 0;
    if (++input_skip < 64) return;
    input_skip = 0;

    unsigned char c;

    /* Only feed characters when the SCC receiver is enabled (WR3 bit 0).
     * This prevents stdin bytes from being consumed before the BIOS
     * initializes the SCC — on real hardware, characters wait in the
     * line buffer until the receiver is ready. */
    int a_rx_en = scc.ch[SCC_CH_A].wr[3] & 0x01;
    int b_rx_en = scc.ch[SCC_CH_B].wr[3] & 0x01;
    { static int input_trace = 0;
      if (input_trace == 0 && (a_rx_en || b_rx_en)) {
          if(0) fprintf(stderr, "[INPUT-EN] a_wr3=0x%02X b_wr3=0x%02X ch=%d\n",
                  scc.ch[SCC_CH_A].wr[3], scc.ch[SCC_CH_B].wr[3], console_channel);
          input_trace = 1;
      }
    }
    /* Skip WR3 gate — Minix WR3 writes don't reach the emulator
     * (probable Musashi issue with move.b to memory-mapped I/O).
     * Feed stdin once the first SCC data write has occurred. */
    { static int saw_tx = 0;
      if (!saw_tx) {
          /* Check if any TX data has been written (boot messages) */
          extern unsigned long long total_cycles;
          if (total_cycles < 1000000) return;  /* very early — SCC not ready */
          saw_tx = 1;
      }
    }

    if (console_channel >= 0) {
        if (scc.ch[console_channel].rx_fifo_count < 16) {
            if (read(0, &c, 1) == 1) {
                scc_rx_char(&scc, console_channel, c);
            }
        }
    } else {
        int a_room = a_rx_en && scc.ch[SCC_CH_A].rx_fifo_count < 16;
        int b_room = b_rx_en && scc.ch[SCC_CH_B].rx_fifo_count < 16;
        if (a_room || b_room) {
            if (read(0, &c, 1) == 1) {
                if (a_room) scc_rx_char(&scc, SCC_CH_A, c);
                if (b_room) scc_rx_char(&scc, SCC_CH_B, c);
            }
        }
    }
}

/* ================================================================== */
/* Musashi memory callbacks                                           */
/* ================================================================== */

/* Forward declarations for IO board memory access */
extern uint8_t ioboard_read8(unsigned int addr);
extern void ioboard_write8(unsigned int addr, uint8_t val);

/* Crash trace: circular buffer of last 4096 PCs.
 * When CPU reads address 0 (reset vector fetch = crash), dump the buffer. */
static unsigned int pc_history[4096];
static int pc_hist_idx = 0;

/* ─── Profiler ──────────────────────────────────────────────────────────
 * Per-PC execution count and cycle count.  Two flat tables, indexed by
 * (addr >> 1) since 68k instructions are 2-byte aligned.
 *
 *   ROM region:  0x00000000 - 0x000FFFFF  (1 MB,  524288 slots)
 *   RAM region:  0x02000000 - 0x023FFFFF  (4 MB, 2097152 slots)  [or larger]
 *
 * Each slot is 4 bytes count + 4 bytes cycles = 8 bytes per address.
 * For a 4 MB RAM build: 4 MB (ROM table) + 16 MB (RAM table) ≈ 20 MB.
 * Allocated only when -profile is passed; otherwise zero overhead.
 */
static int profiler_enabled = 0;
#define PROF_ROM_BASE   0x00000000u
#define PROF_ROM_SIZE   0x00100000u   /* 1 MB covers all 5 ROM banks */
#define PROF_RAM_BASE   0x02000000u
static uint64_t *prof_rom_count = NULL;
static uint64_t *prof_rom_cycles = NULL;
static uint64_t *prof_ram_count = NULL;
static uint64_t *prof_ram_cycles = NULL;
static uint32_t  prof_ram_slots = 0;
static unsigned int prof_last_pc = 0xFFFFFFFFu;
static int          prof_last_cyc = 0;
static unsigned long long prof_total_instrs = 0;
static unsigned long long prof_total_cycles = 0;

static inline void profiler_account(unsigned int pc, int delta_cycles)
{
    if (delta_cycles < 0) delta_cycles = 0;
    prof_total_instrs++;
    prof_total_cycles += (unsigned)delta_cycles;
    if (pc < PROF_ROM_BASE + PROF_ROM_SIZE) {
        unsigned int idx = (pc - PROF_ROM_BASE) >> 1;
        prof_rom_count[idx]++;
        prof_rom_cycles[idx] += (uint64_t)delta_cycles;
    } else if (pc >= PROF_RAM_BASE && pc < PROF_RAM_BASE + (prof_ram_slots << 1)) {
        unsigned int idx = (pc - PROF_RAM_BASE) >> 1;
        prof_ram_count[idx]++;
        prof_ram_cycles[idx] += (uint64_t)delta_cycles;
    }
    /* PCs outside ROM/RAM (e.g. peripheral space) are silently dropped. */
}

static void profiler_reset_all(void)
{
    if (!profiler_enabled) return;
    memset(prof_rom_count, 0, (PROF_ROM_SIZE >> 1) * sizeof(uint32_t));
    memset(prof_rom_cycles, 0, (PROF_ROM_SIZE >> 1) * sizeof(uint32_t));
    memset(prof_ram_count, 0, prof_ram_slots * sizeof(uint32_t));
    memset(prof_ram_cycles, 0, prof_ram_slots * sizeof(uint32_t));
    prof_last_pc = 0xFFFFFFFFu;
    prof_last_cyc = 0;
    prof_total_instrs = 0;
    prof_total_cycles = 0;
}

/* pc_history_record removed — instruction hook records PCs directly */

/* ─── Divide-instruction logger ─────────────────────────────────────────
 * One-shot profile of all DIV* opcodes executed by the guest.  Captures
 * (op_class, dividend, divisor) for each call and aggregates by count.
 * Goal: identify (dividend, divisor) pairs that repeat unusually often
 * and could be replaced by a lookup table in the guest code.
 *
 * Enabled via -divlog <path>.  Adds ~30 cycles to every instruction
 * hook call (one memory read + a few mask/compare).  Dumped on
 * SIGINT or via the debug socket "div" command.
 */
static int   divlog_enabled = 0;
static const char *divlog_path = NULL;
static uint64_t divlog_seen_divw = 0;     /* DIV.W opcodes encountered */
static uint64_t divlog_seen_divl = 0;     /* DIV.L opcodes encountered */
static uint64_t divlog_skipped_ea = 0;    /* Encountered but EA mode unsupported */

#define DIV_OP_DIVU_W 0
#define DIV_OP_DIVS_W 1
#define DIV_OP_DIVU_L 2
#define DIV_OP_DIVS_L 3

typedef struct {
    uint8_t  used;
    uint8_t  op_class;     /* DIV_OP_* */
    uint8_t  is_64bit;     /* DIV.L 64-bit dividend variant */
    uint8_t  pad;
    int64_t  dividend;     /* signed for DIVS, raw bits otherwise */
    int32_t  divisor;
    uint64_t count;
} div_entry_t;

#define DIVLOG_TABLE_SIZE  (1 << 20)   /* 1M slots × 32 bytes ≈ 32 MB */
static div_entry_t *divlog_table = NULL;
static uint64_t divlog_collisions = 0;
static uint64_t divlog_total_events = 0;

static void divlog_record(int op_class, int is_64, int64_t dividend, int32_t divisor)
{
    /* Mix the inputs into a 64-bit hash, then probe linearly. */
    uint64_t h = (uint64_t)dividend * 11400714819323198485ULL;
    h ^= ((uint64_t)(uint32_t)divisor) * 14695981039346656037ULL;
    h ^= (uint64_t)op_class * 1099511628211ULL;
    h ^= (uint64_t)is_64 * 32479L;
    size_t i = (size_t)(h & (DIVLOG_TABLE_SIZE - 1));
    divlog_total_events++;
    for (size_t probe = 0; probe < 64; probe++) {
        div_entry_t *e = &divlog_table[(i + probe) & (DIVLOG_TABLE_SIZE - 1)];
        if (!e->used) {
            e->used = 1;
            e->op_class = (uint8_t)op_class;
            e->is_64bit = (uint8_t)is_64;
            e->dividend = dividend;
            e->divisor = divisor;
            e->count = 1;
            return;
        }
        if (e->op_class == op_class && e->is_64bit == is_64 &&
            e->dividend == dividend && e->divisor == divisor) {
            e->count++;
            return;
        }
        divlog_collisions++;
    }
    /* If we get here, the table is full at this hash chain — drop. */
}

int divlog_cmp_count_desc(const void *a, const void *b) {
    uint64_t ca = ((const div_entry_t *)a)->count;
    uint64_t cb = ((const div_entry_t *)b)->count;
    if (cb > ca) return 1;
    if (cb < ca) return -1;
    return 0;
}

static void divlog_dump_to_path(const char *path)
{
    if (!divlog_table) return;
    FILE *f = fopen(path, "w");
    if (!f) {
        fprintf(stderr, "divlog: cannot open %s for write: %s\n",
                path, strerror(errno));
        return;
    }
    /* Collect non-empty entries */
    size_t n = 0;
    for (size_t i = 0; i < DIVLOG_TABLE_SIZE; i++)
        if (divlog_table[i].used) n++;
    div_entry_t *flat = (div_entry_t *)malloc(n * sizeof(div_entry_t));
    size_t k = 0;
    for (size_t i = 0; i < DIVLOG_TABLE_SIZE; i++)
        if (divlog_table[i].used) flat[k++] = divlog_table[i];

    /* Sort descending by count via qsort (insertion sort was O(n²)
     * and hung on large unique-tuple counts). */
    int divlog_cmp_count_desc(const void *a, const void *b);
    qsort(flat, n, sizeof(div_entry_t), divlog_cmp_count_desc);

    fprintf(f, "# divlog: %llu total events, %zu unique tuples, %llu collisions\n",
            (unsigned long long)divlog_total_events, n,
            (unsigned long long)divlog_collisions);
    fprintf(f, "# raw counters: divw=%llu divl=%llu skipped_ea=%llu\n",
            (unsigned long long)divlog_seen_divw,
            (unsigned long long)divlog_seen_divl,
            (unsigned long long)divlog_skipped_ea);
    fprintf(f, "# op_class       dividend          divisor      count\n");
    static const char *names[4] = { "DIVU.W ", "DIVS.W ", "DIVU.L ", "DIVS.L " };
    for (size_t i = 0; i < n; i++) {
        const char *name = names[flat[i].op_class & 3];
        fprintf(f, "%s%s 0x%016llx  0x%08x  %llu\n",
                name,
                flat[i].is_64bit ? "64" : "  ",
                (unsigned long long)flat[i].dividend,
                (unsigned)flat[i].divisor,
                (unsigned long long)flat[i].count);
    }
    fclose(f);
    free(flat);
    fprintf(stderr, "divlog: wrote %zu unique tuples (%llu events) to %s\n",
            n, (unsigned long long)divlog_total_events, path);
}

static void divlog_atexit_handler(void) {
    if (divlog_enabled && divlog_path) divlog_dump_to_path(divlog_path);
}
static void atexit_divlog(void) {
    atexit(divlog_atexit_handler);
    /* No signal handlers — fopen/malloc/fprintf are not async-signal
     * -safe.  Use the debug-socket "divdump" command (added to the
     * profiler socket) to trigger an explicit dump while the
     * emulator is still running. */
}

/* Musashi instruction hook — called BEFORE every instruction */
static unsigned int last_vbr = 0;
static unsigned int irq_trace[128];
static int irq_trace_idx = 0;
static int irq_trace_armed = 0;

void agfa_instr_hook(unsigned int pc)
{
    /* Fast path: record PC in ring buffer (always) */
    pc_history[pc_hist_idx & 4095] = pc;
    pc_hist_idx++;

    /* Profiler: account the *previous* instruction with its cycle delta. */
    if (__builtin_expect(profiler_enabled, 0)) {
        int now = m68k_cycles_run();
        if (prof_last_pc != 0xFFFFFFFFu) {
            int delta = now - prof_last_cyc;
            profiler_account(prof_last_pc, delta);
        }
        prof_last_pc = pc;
        prof_last_cyc = now;
    }

    /* Divide-instruction logger.  Decode the opcode at PC and, if it's
     * a DIV*, capture the inputs into the aggregation table. */
    if (__builtin_expect(divlog_enabled, 0)) {
        unsigned int op = m68k_read_memory_16(pc);
        /* DIV.W (16-bit divides): 1000 nnn 011/111 mmm rrr */
        if ((op & 0xF1C0) == 0x80C0 || (op & 0xF1C0) == 0x81C0) {
            divlog_seen_divw++;
            int signed_op = ((op >> 8) & 1);          /* bit 8: 0=DIVU 1=DIVS */
            int dq = (op >> 9) & 7;
            int ea_mode = (op >> 3) & 7;
            int ea_reg = op & 7;
            int32_t dividend = (int32_t)m68k_get_reg(NULL, M68K_REG_D0 + dq);
            int32_t divisor;
            int decoded = 1;
            if (ea_mode == 0) {  /* Dn */
                int32_t v = (int32_t)m68k_get_reg(NULL, M68K_REG_D0 + ea_reg);
                divisor = signed_op ? (int16_t)v : (uint16_t)v;
            } else if (ea_mode == 7 && ea_reg == 4) {  /* #imm */
                int32_t v = (int16_t)m68k_read_memory_16(pc + 2);
                divisor = signed_op ? v : (uint16_t)v;
            } else if (ea_mode == 7 && ea_reg == 0) {  /* (xxx).W abs */
                uint32_t a = (int16_t)m68k_read_memory_16(pc + 2);
                int16_t v = (int16_t)m68k_read_memory_16(a);
                divisor = signed_op ? v : (uint16_t)v;
            } else {
                decoded = 0;
                divlog_skipped_ea++;
            }
            if (decoded) {
                divlog_record(signed_op ? DIV_OP_DIVS_W : DIV_OP_DIVU_W,
                              0, (int64_t)dividend, divisor);
            }
        }
        /* DIV.L (68020 long divides): 0100 1100 01 mmm rrr + ext word */
        else if ((op & 0xFFC0) == 0x4C40) {
            divlog_seen_divl++;
            unsigned int op2 = m68k_read_memory_16(pc + 2);
            int dq = (op2 >> 12) & 7;
            int is_64 = (op2 >> 10) & 1;
            int signed_op = (op2 >> 11) & 1;
            int dr = op2 & 7;
            int ea_mode = (op >> 3) & 7;
            int ea_reg = op & 7;
            int64_t dividend;
            if (is_64) {
                uint32_t lo = (uint32_t)m68k_get_reg(NULL, M68K_REG_D0 + dq);
                int32_t hi = (int32_t)m68k_get_reg(NULL, M68K_REG_D0 + dr);
                dividend = ((int64_t)hi << 32) | lo;
            } else {
                dividend = (int64_t)(int32_t)m68k_get_reg(NULL, M68K_REG_D0 + dq);
            }
            int32_t divisor;
            int decoded = 1;
            if (ea_mode == 0) {
                divisor = (int32_t)m68k_get_reg(NULL, M68K_REG_D0 + ea_reg);
            } else if (ea_mode == 7 && ea_reg == 4) {  /* #imm.L */
                /* Extension word is at pc+2, immediate at pc+4 */
                divisor = (int32_t)((m68k_read_memory_16(pc+4) << 16)
                                    | m68k_read_memory_16(pc+6));
            } else if (ea_mode == 7 && ea_reg == 1) {  /* (xxx).L abs */
                uint32_t a = ((m68k_read_memory_16(pc+4) << 16)
                              | m68k_read_memory_16(pc+6));
                divisor = (int32_t)m68k_read_memory_32(a);
            } else {
                decoded = 0;
                divlog_skipped_ea++;
            }
            if (decoded) {
                divlog_record(signed_op ? DIV_OP_DIVS_L : DIV_OP_DIVU_L,
                              is_64, dividend, divisor);
            }
        }
    }

    /* Trace file: full disassembly of every instruction (expensive, off by default) */
    if (__builtin_expect(trace_file != NULL, 0)) {
        char dis[128];
        unsigned int sr = m68k_get_reg(NULL, M68K_REG_SR);
        m68k_disassemble(dis, pc, M68K_CPU_TYPE_68020);
        fprintf(trace_file, "%08X %04X  %s\n", pc, sr, dis);
    }

    /* PS stream hooks — only fire at specific addresses in ROM bank 2 */
    if (__builtin_expect(pc < 0x3F5F0 || pc > 0x405C0, 1))
        return;

    /* PS stream refill hook at 0x3F5F8: inject serial input via pushback byte. */
    if (pc == 0x3F5F8) {
        check_host_input();
        int ch = scc.ch[SCC_CH_B].rx_fifo_count + scc.ch[SCC_CH_A].rx_fifo_count;
        if (ch > 0) {
            int use = (scc.ch[SCC_CH_B].rx_fifo_count > 0) ? 1 : 3;
            uint8_t byte = scc_compact_read(&scc, use);
            uint32_t stream_off = 0x730;
            ram[stream_off + 0x88] = byte;
        }
    }

    if (pc == 0x3F5F8 || pc == 0x3F614) {
        check_host_input();
        int ch_b = scc.ch[SCC_CH_B].rx_fifo_count;
        int ch_a = scc.ch[SCC_CH_A].rx_fifo_count;
        if (ch_b > 0 || ch_a > 0) {
            unsigned int a5 = m68k_get_reg(NULL, M68K_REG_A5);
            if (a5 >= 0x02000000 && a5 < 0x02400000) {
                uint32_t s = a5 - 0x02000000;
                uint32_t bufstart = (ram[s+0x72]<<24)|(ram[s+0x73]<<16)|(ram[s+0x74]<<8)|ram[s+0x75];
                uint32_t bufend = (ram[s+0x7A]<<24)|(ram[s+0x7B]<<16)|(ram[s+0x7C]<<8)|ram[s+0x7D];
                scc_channel_t *ch = (ch_b > 0) ? &scc.ch[SCC_CH_B] : &scc.ch[SCC_CH_A];
                int use_addr = (ch_b > 0) ? 1 : 3;

                if (bufstart >= 0x02000000 && bufend > bufstart && bufend < 0x02400000) {
                    uint32_t ptr = bufstart;
                    int count = 0;
                    while (ch->rx_fifo_count > 0 && ptr < bufend) {
                        uint8_t byte = scc_compact_read(&scc, use_addr);
                        ram[ptr - 0x02000000] = byte;
                        ptr++;
                        count++;
                    }
                    if (count > 0) {
                        ram[s+0x1C]=(bufstart>>24)&0xFF; ram[s+0x1D]=(bufstart>>16)&0xFF;
                        ram[s+0x1E]=(bufstart>>8)&0xFF;  ram[s+0x1F]=bufstart&0xFF;
                        uint32_t lim = bufstart + count;
                        ram[s+0x7E]=(lim>>24)&0xFF; ram[s+0x7F]=(lim>>16)&0xFF;
                        ram[s+0x80]=(lim>>8)&0xFF;  ram[s+0x81]=lim&0xFF;
                        ram[s+0x20]=0; ram[s+0x21]=0;
                        ram[s+0x22]=(count>>8)&0xFF; ram[s+0x23]=count&0xFF;
                    }
                }
            }
        }
    }

    if (pc == 0x405B8) {
        check_host_input();
        int ch_b = scc.ch[SCC_CH_B].rx_fifo_count;
        int ch_a = scc.ch[SCC_CH_A].rx_fifo_count;
        if (ch_b > 0 || ch_a > 0) {
            int use_ch = (ch_b > 0) ? 1 : 3;
            scc_channel_t *ch = (ch_b > 0) ? &scc.ch[SCC_CH_B] : &scc.ch[SCC_CH_A];

            uint32_t s = 0x730;
            uint32_t bufstart = (ram[s+0x72]<<24)|(ram[s+0x73]<<16)|(ram[s+0x74]<<8)|ram[s+0x75];
            uint32_t bufend = (ram[s+0x7A]<<24)|(ram[s+0x7B]<<16)|(ram[s+0x7C]<<8)|ram[s+0x7D];

            if (bufstart >= 0x02000000 && bufend > bufstart && bufend < 0x02400000) {
                /* Reset buffer pointer to start */
                uint32_t ptr = bufstart;
                int count = 0;
                while (ch->rx_fifo_count > 0 && ptr < bufend) {
                    uint8_t byte = scc_compact_read(&scc, use_ch);
                    ram[ptr - 0x02000000] = byte;
                    ptr++;
                    count++;
                }
                if (count > 0) {
                    /* Update stream structure */
                    /* bufptr (offset 0x1C) = bufstart */
                    ram[s+0x1C]=(bufstart>>24)&0xFF; ram[s+0x1D]=(bufstart>>16)&0xFF;
                    ram[s+0x1E]=(bufstart>>8)&0xFF;  ram[s+0x1F]=bufstart&0xFF;
                    /* buflim (offset 0x7E) = bufstart + count */
                    uint32_t lim = bufstart + count;
                    ram[s+0x7E]=(lim>>24)&0xFF; ram[s+0x7F]=(lim>>16)&0xFF;
                    ram[s+0x80]=(lim>>8)&0xFF;  ram[s+0x81]=lim&0xFF;
                    /* count (offset 0x20) = count */
                    ram[s+0x20]=(count>>24)&0xFF; ram[s+0x21]=(count>>16)&0xFF;
                    ram[s+0x22]=(count>>8)&0xFF;  ram[s+0x23]=count&0xFF;

                    static int fill_trace = 0;
                    if (fill_trace < 5) {
                        fprintf(stderr, "[YIELD-FILL] %d bytes into stream buffer at 0x%08X\n",
                                count, bufstart);
                        fill_trace++;
                    }
                }
            }
        }
    }

    /* Trace the PS interpreter's serial refill callback.
     * At 0x4041A: jsr A1@ where A1 = the refill function pointer.
     * Log A1 to find what function is called, then log the next 10 PCs. */
    {
        static int refill_trace = 0;
        static int refill_countdown = 0;
        if (pc == 0x4041A && refill_trace < 3) {
            unsigned int a1 = m68k_get_reg(NULL, M68K_REG_A1);
            unsigned int a0 = m68k_get_reg(NULL, M68K_REG_A0);
            {
                /* Stream struct fields that matter: */
                uint8_t flag134 = m68k_read_memory_8(a0 + 0x86);
                uint32_t bufptr = m68k_read_memory_32(a0 + 0x1C);
                uint32_t bufend = m68k_read_memory_32(a0 + 0x7A);
                uint32_t buflim = m68k_read_memory_32(a0 + 0x7E);
                uint32_t count  = m68k_read_memory_32(a0 + 0x20);
                fprintf(stderr, "\n[REFILL] A0=0x%08X A1=0x%08X flag134=0x%02X buf=0x%08X end=0x%08X lim=0x%08X count=%d\n",
                        a0, a1, flag134, bufptr, bufend, buflim, count);
            }
            refill_trace++;
            refill_countdown = 30;
        }
        if (refill_countdown > 0) {
            fprintf(stderr, "[REFILL-PC] 0x%08X\n", pc);
            refill_countdown--;
        }
    }

    /* Detect reset: when PC hits the reset vector entry (0x856) after boot,
     * dump the last 64 PCs to show what caused the crash. */
    {
        static int boot_done = 0;
        static int reset_count = 0;
        if (!boot_done && pc > 0x2000) boot_done = 1;
        /* Detect actual reset: PC at cold boot entry (0x856) or warm boot (0x860). */
        if (boot_done && (pc == 0x856 || pc == 0x860) && reset_count < 3) {
            reset_count++;
            fprintf(stderr, "\n=== RESET #%d DETECTED at cycle %llu ===\n", reset_count, total_cycles);
            fprintf(stderr, "Last 64 PCs before reset:\n");
            for (int i = 63; i >= 0; i--) {
                int idx = (pc_hist_idx - 1 - i) & 4095;
                fprintf(stderr, "  PC[-%02d] = 0x%08X\n", i, pc_history[idx]);
            }
            fprintf(stderr, "=== END RESET DUMP ===\n\n");
        }
    }

    /* Shell at 0x02045D00: text=0x3114, total=0x14D70 (334 clicks)
     * Text: 0x02045D00 - 0x02048E14
     * Data/BSS/Stack: 0x02048E14 - 0x0205AB00
     * Crash at 0x0205AAEC = executing shell's stack */
    if (pc >= 0x02048E14 && pc < 0x0205B000) {
        static int bad_pc = 0;
        if (bad_pc == 0) {
            bad_pc = 1;
            /* Wild PC detected — debug disabled for clean output */
        }
    }

    /* After the timer IRQ fires, record the next 128 raw instruction PCs */
    if (irq_trace_armed == 1) {
        irq_trace[irq_trace_idx++] = pc;
        if (irq_trace_idx >= 128) {
            fprintf(stderr, "\n=== 128 instructions after timer IRQ ===\n");
            for (int i = 0; i < 128; i++)
                fprintf(stderr, "  [%3d] 0x%08X\n", i, irq_trace[i]);
            fprintf(stderr, "=== END ===\n");
            irq_trace_armed = 2;
        }
    }

    /* Detect VBR changes */
    unsigned int vbr = m68k_get_reg(NULL, M68K_REG_VBR);
    if (vbr != last_vbr) {
        unsigned int v29 = m68k_read_memory_32(vbr + 29*4);
        unsigned int v24 = m68k_read_memory_32(vbr + 24*4);
        unsigned int v32 = m68k_read_memory_32(vbr + 32*4);
        fprintf(stderr, "[VBR] changed: 0x%08X -> 0x%08X at PC=0x%08X v24=0x%08X v29=0x%08X v32=0x%08X\n",
                last_vbr, vbr, pc, v24, v29, v32);
        last_vbr = vbr;
    }
}

static void crash_dump(void)
{
    FILE *f = fopen("crash.log", "a");
    if (!f) return;
    fprintf(f, "--- CRASH (read from addr 0x00000000) at cycle %llu ---\n", total_cycles);
    int i;
    for (i = 0; i < 64; i++) {
        unsigned int pc = pc_history[(pc_hist_idx + i) & 63];
        fprintf(f, "  PC[-%02d] = 0x%08X\n", 63 - i, pc);
    }
    fprintf(f, "\n");
    fclose(f);
    fprintf(stderr, "[CRASH] PC trace dumped to crash.log\n");
}

unsigned int m68k_read_memory_8(unsigned int addr)
{
    /* Crash detection: only triggers on 32-bit reads from address 0
     * when the PC is also 0 (actual reset/double-fault). Normal code
     * can read address 0 legitimately (it's valid ROM). */

    /* IO board CPU active? */
    if (emu_current_cpu == 1)
        return ioboard_read8(addr);

    /* ROM */
    if (addr < ROM_TOTAL)
        return rom[addr];

    /* RAM */
    if (addr >= 0x02000000 && addr < 0x02000000 + ram_size)
        return ram[addr - 0x02000000];

    /* R6522 VIA #1 at 0x04000000 and VIA #2 / VERA at 0x04000020.
     * PAL direct-register decode: A4 is don't-care (mirror confirmed).
     * With -vera flag: VIA #2 replaced by VERA (32 regs, 0x20-0x3F).
     * The board PAL holds /DSACK for 16 clocks per byte access — see
     * bus_stall_dtack() above. */
    if (addr >= 0x04000000 && addr <= 0x0400003F) {
        int offset = addr & 0x3F;
        bus_stall_dtack();
        if (vera_enabled && offset >= 0x20) {
            return vera_read(&vera, offset - 0x20);
        }
        int via_num = (offset & 0x20) ? 1 : 0;
        int reg = offset & 0x0F;
        return via_read(&via[via_num], reg);
    }

    /* SCSI AM5380: stride-1. Adrian verified 0x05000000-0x05000007.
     * PS firmware uses base 0x05000001 (regs at 0x05000001-0x05000008).
     * Accept full range 0x05000000-0x0500000F, reg = addr & 7. */
    if (addr >= 0x05000000 && addr <= 0x0500000F) {
        int reg = addr & 7;
        /* Throttle data-register PIO reads (IDATA reg 6) the same as
         * pseudo-DMA so PIO-mode drivers see the same 1 MB/s ceiling. */
        if (reg == 6 && scsi.phase == SCSI_PHASE_DATA_IN)
            scsi_stall();
        return ncr5380_read(&scsi, reg);
    }

    /* SCSI pseudo-DMA (firmware uses 0x5000020, docs say 0x5000026) */
    if (addr >= 0x05000020 && addr <= 0x05000027) {
        scsi_stall();
        return ncr5380_dma_read(&scsi);
    }

    /* Bus control latch */
    if (addr == 0x06000000) return bus_ctl_latch;
    if (addr == 0x06080000) return gfx_ctl_latch;
    if (addr == 0x060C0000) return fifo_ctl >> 8;
    if (addr == 0x060C0001) return fifo_ctl & 0xFF;
    if (addr >= 0x06100000 && addr <= 0x06100003)
        return (display_ctl >> (8 * (3 - (addr & 3)))) & 0xFF;

    /* Z8530 SCC at 0x07000000 (compact byte-addressed) */
    if (addr >= 0x07000000 && addr <= 0x07000003)
        return scc_compact_read(&scc, addr & 3);

    /* SCC reset strobe */
    if (addr == 0x07000020)
        return 0;

    /* Xicor X2804AP EEPROM at $07100000-$071001FF (512 bytes)
     * (real hardware at $071F0000, but PAL decodes entire $07xxxxxx range) */
    if (addr >= 0x07100000 && addr <= 0x071001FF) {
        return eeprom[addr - 0x07100000];
    }

    return 0;
}

unsigned int m68k_read_memory_16(unsigned int addr)
{
    /* Fast path: ROM */
    if (addr + 1 < ROM_TOTAL && emu_current_cpu == 0)
        return (rom[addr] << 8) | rom[addr + 1];
    /* Fast path: RAM */
    if (addr >= 0x02000000 && addr + 1 < 0x02000000 + ram_size && emu_current_cpu == 0) {
        unsigned int off = addr - 0x02000000;
        return (ram[off] << 8) | ram[off + 1];
    }
    return (m68k_read_memory_8(addr) << 8) | m68k_read_memory_8(addr + 1);
}

unsigned int m68k_read_memory_32(unsigned int addr)
{
    /* Crash detection: 32-bit read from address 0 = reset SSP fetch.
     * This only happens during actual CPU reset or double bus fault. */
    if (addr == 0 && emu_current_cpu == 0) {
        unsigned int pc = m68k_get_reg(NULL, M68K_REG_PC);
        /* Only trigger if PC suggests we're in a reset/exception cascade,
         * not normal code reading ROM address 0 */
        if (pc < 0x100 || pc > 0x02100000) {
            static int crash_count = 0;
            if (crash_count < 5) {
                crash_dump();
                crash_count++;
            }
        }
    }

    /* IO board dispatch (must be before fast paths!) */
    if (emu_current_cpu == 1)
        return (m68k_read_memory_16(addr) << 16) | m68k_read_memory_16(addr + 2);

    /* Fast path: ROM (main board only) */
    if (addr + 3 < ROM_TOTAL)
        return (rom[addr] << 24) | (rom[addr+1] << 16)
             | (rom[addr+2] << 8) | rom[addr+3];

    /* Fast path: RAM (main board only) */
    if (addr >= 0x02000000 && addr + 3 < 0x02000000 + ram_size) {
        unsigned int off = addr - 0x02000000;
        return (ram[off] << 24) | (ram[off+1] << 16)
             | (ram[off+2] << 8) | ram[off+3];
    }

    return (m68k_read_memory_16(addr) << 16) | m68k_read_memory_16(addr + 2);
}

void m68k_write_memory_8(unsigned int addr, unsigned int val)
{
    if (emu_current_cpu == 1) {
        ioboard_write8(addr, val);
        return;
    }
    if (addr >= 0x02000000 && addr < 0x02000000 + ram_size) {
        ram[addr - 0x02000000] = val;
        return;
    }
    /* R6522 VIA #1 (0x04000000) + VIA #2 / VERA (0x04000020) — see
     * bus_stall_dtack() above for the 16-clock /DSACK hold. */
    if (addr >= 0x04000000 && addr <= 0x0400003F) {
        int offset = addr & 0x3F;
        bus_stall_dtack();
        if (vera_enabled && offset >= 0x20) {
            vera_write(&vera, offset - 0x20, val);
            return;
        }
        int via_num = (offset & 0x20) ? 1 : 0;
        int reg = offset & 0x0F;
        /* Save old ORB for edge detection */
        uint8_t old_orb = via[via_num].orb;

        via_write(&via[via_num], reg, val);

        /* SCC2691 emulation: when VIA #1 ORB changes and DDRA=0 (input),
         * put the appropriate SCC2691 register value on PA pins immediately.
         * This ensures the main board sees the right value when it reads ORA. */
        if (via_num == 0 && reg == VIA_ORB && via[0].ddra == 0x00) {
            int scc2691_reg = (via[0].orb >> 5) & 7;
            switch (scc2691_reg) {
            case 1: { /* SRA — status register */
                uint8_t sra = 0x0C;  /* TXRDY + TXEMT */
                if (fifo_io_to_main.count > 0)
                    sra |= 0x01;  /* RXRDY */
                via_set_pa(&via[0], sra);
                break;
            }
            case 5: { /* ISR — interrupt status
                      * Bit 0=TxRDY, Bit 1=RxRDY/FFULL, Bit 2=counter ready,
                      * Bit 3=delta break. Firmware checks bit 2 in DMA receive. */
                uint8_t isr = 0x05;  /* TxRDY + counter ready (bit 2) */
                if (fifo_io_to_main.count > 0)
                    isr |= 0x02;  /* RxRDY */
                via_set_pa(&via[0], isr);
                break;
            }
            case 3: /* RHR — receive data */
                if (fifo_io_to_main.count > 0) {
                    uint8_t byte;
                    xfifo_get(&fifo_io_to_main, &byte);
                    via_set_pa(&via[0], byte);
                } else {
                    via_set_pa(&via[0], 0x00);
                }
                break;
            default:
                via_set_pa(&via[0], 0x00);
                break;
            }
        }

        /* Inter-board wiring: VIA #1 ↔ IO board data transfer.
         *
         * The DMA protocol uses ORB as a clocked handshake:
         *   1. Set DDRA=0xFF (output), write data byte to ORA
         *   2. Toggle ORB bits (AND masks clear clock phases)
         *   3. OR 0xFC restores idle → this completes the clock cycle
         *   4. Data byte is now latched by IO board hardware
         *
         * For receive:
         *   1. Set DDRA=0x00 (input)
         *   2. Toggle ORB bits (different mask pattern)
         *   3. Read ORA-nh to get the byte from IO board
         *
         * Trigger: when ORB transitions to idle (bits 2-7 all set after
         * being partially cleared), the clock cycle is complete. */
        if (via_num == 0 && reg == VIA_ORB) {
            uint8_t new_orb = via[0].orb;
            /* Detect idle-restore: bits 2-7 going from partially cleared to all set.
             * The OR 0xFC pattern sets bits 2-7 = 0xFC mask on the ORB. */
            int was_active = (old_orb & 0xFC) != 0xFC;
            int now_idle = (new_orb & 0xFC) == 0xFC;
            if (was_active && now_idle) {
                /* Clock cycle complete.
                 * ORB bits 7-5 encode the SCC2691 register being accessed:
                 *   0=MRA, 1=CSRA, 2=CRA, 3=THR/RHR, 4=ACR, 5=IMR, 6=CTU, 7=CTL
                 * Only register 3 (THR) writes are actual data bytes.
                 * All others are SCC2691 configuration — don't forward to DUART. */
                int scc2691_reg = (old_orb >> 5) & 7;

                if (via[0].ddra == 0xFF && scc2691_reg == 3) {
                    /* Write to SCC2691 THR (TX Holding Register):
                     * This is an actual data byte for the IO board.
                     * Forward to DUART RX via the serial cross-connect. */
                    xfifo_put(&fifo_main_to_io, via[0].ora);
                } else if (via[0].ddra == 0x00 && scc2691_reg == 3) {
                    /* Read from SCC2691 RHR (RX Holding Register):
                     * IO board sent data back. VIA PA pins already set
                     * from fifo_io_to_main in the main loop tick. */
                }
            }
        }
        return;
    }
    if (addr >= 0x05000000 && addr <= 0x0500000F) {
        int reg = addr & 7;
        if (reg == 0 && scsi.phase == SCSI_PHASE_DATA_OUT)
            scsi_stall();
        ncr5380_write(&scsi, reg, val);
        return;
    }
    if (addr >= 0x05000020 && addr <= 0x05000027) {
        scsi_stall();
        ncr5380_dma_write(&scsi, val);
        return;
    }
    if (addr == 0x06000000) {
        uint8_t old = bus_ctl_latch;
        bus_ctl_latch = val;
        /* Adrian verified 0x06000000 is NOT SCSI on real hardware.
         * However, the original PS firmware uses this latch for SCSI
         * selection (doesn't use the NCR5380's ICR_SEL at all).
         * Keep the latch-based selection for PS firmware compatibility.
         * Adrian's own code uses standard NCR5380 ICR selection. */
        if (!(val & 0x20) && (old & 0x20)) {
            /* SEL asserted (active-LOW: bit 5 going 1→0) */
            uint8_t data = scsi.output_data;
            int id;
            for (id = 0; id < 8; id++) {
                if ((data & (1 << id)) && scsi.devices[id].present) {
                    scsi.selected_id = id;
                    scsi.phase = SCSI_PHASE_COMMAND;
                    scsi.cmd_pos = 0;
                    scsi.cmd_len = 0;
                    break;
                }
            }
        }
        return;
    }
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
    /* Xicor X2804AP EEPROM write */
    if (addr >= 0x07100000 && addr <= 0x071001FF) {
        int off = addr - 0x07100000;
        eeprom[off] = val;
        eeprom_write_byte(off, val);
        return;
    }
    /* Ignore: ROM writes, SCC strobe, unmapped */
}

void m68k_write_memory_16(unsigned int addr, unsigned int val)
{
    /* Fast path: RAM */
    if (addr >= 0x02000000 && addr + 1 < 0x02000000 + ram_size && emu_current_cpu == 0) {
        unsigned int off = addr - 0x02000000;
        ram[off]   = (val >> 8) & 0xFF;
        ram[off+1] = val & 0xFF;
        return;
    }
    m68k_write_memory_8(addr, (val >> 8) & 0xFF);
    m68k_write_memory_8(addr + 1, val & 0xFF);
}

void m68k_write_memory_32(unsigned int addr, unsigned int val)
{
    if (emu_current_cpu == 1) {
        m68k_write_memory_16(addr, (val >> 16) & 0xFFFF);
        m68k_write_memory_16(addr + 2, val & 0xFFFF);
        return;
    }
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
    fprintf(stderr, "  -rom <image>      Load flat ROM image (e.g. CP/M combined binary)\n");
    fprintf(stderr, "  -roms <dir>       Load split EPROMs from directory (Uxxx_LANEn.bin)\n");
    fprintf(stderr, "  -io <io.bin>      Load IO board ROM (68000, enables dual-CPU)\n");
    fprintf(stderr, "  -sysstart <file>  Inject Sys/Start file through SCC after boot\n");
    fprintf(stderr, "  -debug            Enable debug sockets (/tmp/agfa9000*.sock)\n");
    fprintf(stderr, "  -profile          Enable per-PC execution + cycle profiler (implies -debug)\n");
    fprintf(stderr, "  -divlog <path>    Log every DIV* opcode's (dividend, divisor) and dump aggregated\n");
    fprintf(stderr, "                    counts to <path> at exit (one-shot profiling tool)\n");
    fprintf(stderr, "  -boot <target>    Auto-boot to a guest OS after AGFA-MON RAM test:\n");
    fprintf(stderr, "                      cpm     → PC=0x20000 (CP/M-68K, bank 1)\n");
    fprintf(stderr, "                      minix   → PC=0x40000 (Minix 2.0.4, bank 2)\n");
    fprintf(stderr, "                      ps      → PC=0x40508 (PostScript init, bank 2 in PS ROM)\n");
    fprintf(stderr, "                      <addr>  → arbitrary hex/dec address\n");
    fprintf(stderr, "  -v                Verbose logging\n");
    fprintf(stderr, "\nExamples:\n");
    fprintf(stderr, "  %s roms/ -hd HD00_Agfa_RIP.hda     (Agfa PostScript firmware)\n", prog);
    fprintf(stderr, "  %s -rom image.bin                   (flat ROM image)\n", prog);
    fprintf(stderr, "  %s -roms cpm_test/                  (split EPROMs by socket)\n", prog);
    exit(1);
}

/* Ring buffer for Doom process PCs */
static unsigned int doom_pc_ring[64];
static int doom_pc_idx = 0;
static int doom_trace_active = 0;

static void doom_instr_hook(unsigned int pc) {
    /* Record all kernel+user PCs for crash diagnosis */
    if (pc >= 0x02001000 && pc < 0x02400000) {
        doom_pc_ring[doom_pc_idx & 63] = pc;
        doom_pc_idx++;
    }
    /* Detect entry to gentrp (0x02001522) = trap/exception handler */
    if (pc == 0x02001522 && doom_pc_idx > 2) {
        fprintf(stderr, "\n*** TRAP HANDLER ENTERED — last 48 PCs: ***\n");
        int start = doom_pc_idx > 48 ? doom_pc_idx - 48 : 0;
        for (int i = start; i < doom_pc_idx; i++)
            fprintf(stderr, "  [%d] 0x%08X\n", i - start, doom_pc_ring[i & 63]);
        fprintf(stderr, "  D0=%08X A4=%08X A5=%08X SR=%04X\n",
            m68k_get_reg(NULL,M68K_REG_D0),
            m68k_get_reg(NULL,M68K_REG_A4),
            m68k_get_reg(NULL,M68K_REG_A5),
            m68k_get_reg(NULL,M68K_REG_SR));
    }
}

static int illg_instr_cb(int opcode) {
    unsigned int pc = m68k_get_reg(NULL, M68K_REG_PC);
    if (pc > 0x02050000) {
        fprintf(stderr, "\n*** ILLEGAL INSTR 0x%04X at PC=0x%08X ***\n", opcode, pc);
    }
    return 1;
}

/* ─── Debug socket threads ─── */

static int debug_srv_create(const char *path) {
    int srv = socket(AF_UNIX, SOCK_STREAM, 0);
    if (srv < 0) return -1;
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, path, sizeof(addr.sun_path) - 1);
    if (bind(srv, (struct sockaddr *)&addr, sizeof(addr)) < 0) { close(srv); return -1; }
    listen(srv, 1);
    return srv;
}

/* Register dump: connect to get CPU state */
static void *debug_socket_thread(void *arg) {
    (void)arg;
    int srv = debug_srv_create("/tmp/agfa9000.sock");
    if (srv < 0) return NULL;
    for (;;) {
        int cl = accept(srv, NULL, NULL);
        if (cl < 0) continue;
        char buf[1024];
        int n = sprintf(buf,
            "PC=%08X  SR=%04X\n"
            "D0=%08X D1=%08X D2=%08X D3=%08X\n"
            "D4=%08X D5=%08X D6=%08X D7=%08X\n"
            "A0=%08X A1=%08X A2=%08X A3=%08X\n"
            "A4=%08X A5=%08X A6=%08X SP=%08X\n"
            "USP=%08X  cycles=%llu\n",
            m68k_get_reg(NULL, M68K_REG_PC),
            m68k_get_reg(NULL, M68K_REG_SR),
            m68k_get_reg(NULL, M68K_REG_D0), m68k_get_reg(NULL, M68K_REG_D1),
            m68k_get_reg(NULL, M68K_REG_D2), m68k_get_reg(NULL, M68K_REG_D3),
            m68k_get_reg(NULL, M68K_REG_D4), m68k_get_reg(NULL, M68K_REG_D5),
            m68k_get_reg(NULL, M68K_REG_D6), m68k_get_reg(NULL, M68K_REG_D7),
            m68k_get_reg(NULL, M68K_REG_A0), m68k_get_reg(NULL, M68K_REG_A1),
            m68k_get_reg(NULL, M68K_REG_A2), m68k_get_reg(NULL, M68K_REG_A3),
            m68k_get_reg(NULL, M68K_REG_A4), m68k_get_reg(NULL, M68K_REG_A5),
            m68k_get_reg(NULL, M68K_REG_A6), m68k_get_reg(NULL, M68K_REG_A7),
            m68k_get_reg(NULL, M68K_REG_USP), total_cycles);
        /* Stack trace: walk A6 frame chain, also dump raw stack */
        unsigned int sp = m68k_get_reg(NULL, M68K_REG_A7);
        n += sprintf(buf + n, "Stack:");
        for (int i = 0; i < 16 && n < 900; i++)
            n += sprintf(buf + n, " %08X", m68k_read_memory_32(sp + i*4));
        n += sprintf(buf + n, "\nFrames:");
        { unsigned int fp = m68k_get_reg(NULL, M68K_REG_A6);
          for (int i = 0; i < 12 && fp > 0x02000000 && fp < 0x02400000 && n < 900; i++) {
              unsigned int ret = m68k_read_memory_32(fp + 4);
              n += sprintf(buf + n, " %08X", ret);
              fp = m68k_read_memory_32(fp);
          }
        }
        n += sprintf(buf + n, "\n");
        write(cl, buf, n);
        close(cl);
    }
    return NULL;
}

/* Memory read: send "ADDR LEN\n" (hex), get hex dump back */
static void *mem_socket_thread(void *arg) {
    (void)arg;
    int srv = debug_srv_create("/tmp/agfa9000_mem.sock");
    if (srv < 0) return NULL;
    for (;;) {
        int cl = accept(srv, NULL, NULL);
        if (cl < 0) continue;
        char req[64];
        int nr = read(cl, req, sizeof(req) - 1);
        if (nr > 0) {
            req[nr] = '\0';
            unsigned int addr = 0, len = 16;
            sscanf(req, "%x %x", &addr, &len);
            if (len > 4096) len = 4096;
            char buf[16384];
            int n = 0;
            for (unsigned int i = 0; i < len; i += 16) {
                n += sprintf(buf + n, "%08X:", addr + i);
                for (unsigned int j = 0; j < 16 && i + j < len; j++)
                    n += sprintf(buf + n, " %02X", m68k_read_memory_8(addr + i + j));
                n += sprintf(buf + n, "\n");
            }
            write(cl, buf, n);
        }
        close(cl);
    }
    return NULL;
}

/* ─── Profiler socket ───────────────────────────────────────────────────
 * Commands (newline-terminated, ASCII):
 *   stats                — total instrs/cycles, hottest slot
 *   top [N]              — top N hot addresses by execution count (default 50)
 *   topcyc [N]           — top N hot addresses by cycles (default 50)
 *   range HEX HEX        — dump every executed addr in [start,end) as CSV
 *   dump PATH            — write full CSV (addr,count,cycles) to PATH
 *   reset                — zero the tables
 */

typedef struct { uint32_t addr; uint64_t count; uint64_t cycles; } prof_entry_t;

static int prof_cmp_count_desc(const void *a, const void *b) {
    uint64_t ca = ((const prof_entry_t *)a)->count;
    uint64_t cb = ((const prof_entry_t *)b)->count;
    if (cb > ca) return 1;
    if (cb < ca) return -1;
    return 0;
}
static int prof_cmp_cycles_desc(const void *a, const void *b) {
    uint64_t ca = ((const prof_entry_t *)a)->cycles;
    uint64_t cb = ((const prof_entry_t *)b)->cycles;
    if (cb > ca) return 1;
    if (cb < ca) return -1;
    return 0;
}

/* Collect every executed slot into a flat array (caller frees). */
static prof_entry_t *prof_collect(size_t *out_n) {
    size_t cap = 0;
    size_t rom_slots = PROF_ROM_SIZE >> 1;
    for (size_t i = 0; i < rom_slots; i++) if (prof_rom_count[i]) cap++;
    for (size_t i = 0; i < prof_ram_slots; i++) if (prof_ram_count[i]) cap++;
    prof_entry_t *e = (prof_entry_t *)malloc(cap * sizeof(prof_entry_t));
    if (!e) { *out_n = 0; return NULL; }
    size_t k = 0;
    for (size_t i = 0; i < rom_slots; i++) {
        if (prof_rom_count[i]) {
            e[k].addr = (uint32_t)(PROF_ROM_BASE + (i << 1));
            e[k].count = prof_rom_count[i];
            e[k].cycles = prof_rom_cycles[i];
            k++;
        }
    }
    for (size_t i = 0; i < prof_ram_slots; i++) {
        if (prof_ram_count[i]) {
            e[k].addr = (uint32_t)(PROF_RAM_BASE + (i << 1));
            e[k].count = prof_ram_count[i];
            e[k].cycles = prof_ram_cycles[i];
            k++;
        }
    }
    *out_n = k;
    return e;
}

static void prof_send_top(int cl, int by_cycles, int n) {
    size_t total = 0;
    prof_entry_t *e = prof_collect(&total);
    if (!e) { dprintf(cl, "out of memory\n"); return; }
    qsort(e, total, sizeof(prof_entry_t),
          by_cycles ? prof_cmp_cycles_desc : prof_cmp_count_desc);
    if ((size_t)n > total) n = (int)total;
    dprintf(cl, "# total_unique=%zu  total_instrs=%llu  total_cycles=%llu\n",
            total, prof_total_instrs, prof_total_cycles);
    dprintf(cl, "# addr             count          cycles\n");
    for (int i = 0; i < n; i++)
        dprintf(cl, "0x%08X  %14llu  %14llu\n", e[i].addr,
                (unsigned long long)e[i].count,
                (unsigned long long)e[i].cycles);
    free(e);
}

static void *prof_socket_thread(void *arg) {
    (void)arg;
    int srv = debug_srv_create("/tmp/agfa9000_prof.sock");
    if (srv < 0) return NULL;
    for (;;) {
        int cl = accept(srv, NULL, NULL);
        if (cl < 0) continue;
        char req[512];
        int nr = read(cl, req, sizeof(req) - 1);
        if (nr <= 0) { close(cl); continue; }
        req[nr] = '\0';
        /* trim trailing whitespace */
        while (nr > 0 && (req[nr-1] == '\n' || req[nr-1] == '\r' || req[nr-1] == ' ')) req[--nr] = 0;

        /* divdump is allowed even without -profile (only needs -divlog) */
        if (!profiler_enabled && strncmp(req, "divdump", 7) != 0) {
            dprintf(cl, "profiler not enabled\n");
            close(cl); continue;
        }

        if (!strncmp(req, "stats", 5)) {
            size_t total = 0;
            prof_entry_t *e = prof_collect(&total);
            dprintf(cl, "instrs=%llu cycles=%llu unique_addrs=%zu cpi=%.2f\n",
                    prof_total_instrs, prof_total_cycles, total,
                    prof_total_instrs ? (double)prof_total_cycles / (double)prof_total_instrs : 0.0);
            free(e);
        } else if (!strncmp(req, "top", 3)) {
            int by_cyc = !strncmp(req, "topcyc", 6);
            int n = 50;
            const char *p = req + (by_cyc ? 6 : 3);
            while (*p == ' ') p++;
            if (*p) n = atoi(p);
            if (n <= 0) n = 50;
            prof_send_top(cl, by_cyc, n);
        } else if (!strncmp(req, "range", 5)) {
            /* range START END [MIN_COUNT] */
            unsigned int s = 0, e_ = 0;
            unsigned long long min_count = 1;
            if (sscanf(req + 5, "%x %x %llu", &s, &e_, &min_count) >= 2 && e_ > s) {
                dprintf(cl, "# addr,count,cycles (min_count=%llu)\n", min_count);
                for (unsigned int a = s & ~1u; a < e_; a += 2) {
                    uint64_t c = 0, y = 0;
                    if (a < PROF_ROM_BASE + PROF_ROM_SIZE) {
                        c = prof_rom_count[(a - PROF_ROM_BASE) >> 1];
                        y = prof_rom_cycles[(a - PROF_ROM_BASE) >> 1];
                    } else if (a >= PROF_RAM_BASE && a < PROF_RAM_BASE + (prof_ram_slots << 1)) {
                        c = prof_ram_count[(a - PROF_RAM_BASE) >> 1];
                        y = prof_ram_cycles[(a - PROF_RAM_BASE) >> 1];
                    }
                    if (c >= min_count)
                        dprintf(cl, "0x%08X,%llu,%llu\n", a,
                                (unsigned long long)c, (unsigned long long)y);
                }
            } else {
                dprintf(cl, "usage: range <start_hex> <end_hex> [min_count]\n");
            }
        } else if (!strncmp(req, "dump", 4)) {
            /* dump PATH [MIN_COUNT] */
            char path[256] = {0};
            unsigned long long min_count = 1;  /* skip zero by default */
            if (sscanf(req + 4, "%255s %llu", path, &min_count) < 1) {
                dprintf(cl, "usage: dump <path> [min_count]\n"); close(cl); continue;
            }
            FILE *f = fopen(path, "w");
            if (!f) { dprintf(cl, "fopen %s: %s\n", path, strerror(errno)); close(cl); continue; }
            fprintf(f, "# agfa9000 profiler dump\n");
            fprintf(f, "# total_instrs=%llu total_cycles=%llu min_count=%llu\n",
                    prof_total_instrs, prof_total_cycles, min_count);
            fprintf(f, "addr,count,cycles\n");
            size_t written = 0;
            size_t rom_slots = PROF_ROM_SIZE >> 1;
            for (size_t i = 0; i < rom_slots; i++) {
                if (prof_rom_count[i] >= min_count) {
                    fprintf(f, "0x%08X,%llu,%llu\n",
                            (unsigned)(PROF_ROM_BASE + (i << 1)),
                            (unsigned long long)prof_rom_count[i],
                            (unsigned long long)prof_rom_cycles[i]);
                    written++;
                }
            }
            for (size_t i = 0; i < prof_ram_slots; i++) {
                if (prof_ram_count[i] >= min_count) {
                    fprintf(f, "0x%08X,%llu,%llu\n",
                            (unsigned)(PROF_RAM_BASE + (i << 1)),
                            (unsigned long long)prof_ram_count[i],
                            (unsigned long long)prof_ram_cycles[i]);
                    written++;
                }
            }
            fclose(f);
            dprintf(cl, "wrote %zu rows to %s (min_count=%llu)\n", written, path, min_count);
        } else if (!strncmp(req, "reset", 5)) {
            profiler_reset_all();
            dprintf(cl, "ok\n");
        } else if (!strncmp(req, "divdump", 7)) {
            /* Dump the divlog table to a path.  Usage: divdump <path> */
            const char *p = req + 7;
            while (*p == ' ') p++;
            if (!divlog_enabled) {
                dprintf(cl, "divlog not enabled (use -divlog at startup)\n");
            } else if (!*p) {
                dprintf(cl, "usage: divdump <path>\n");
            } else {
                divlog_dump_to_path(p);
                dprintf(cl, "ok — see %s\n", p);
            }
        } else {
            dprintf(cl, "commands: stats | top [N] | topcyc [N] | range S E [MIN] | dump PATH [MIN] | reset | divdump PATH\n");
        }
        close(cl);
    }
    return NULL;
}

int main(int argc, char **argv)
{
    /* Single-instance lock: refuse to start if another emulator is already
     * running. Prevents accidentally fork-bombing the host with multiple
     * SDL+audio+CPU instances. Override with --force if you really need
     * to run two copies side by side. */
    int force_multi = 0;
    for (int ai = 1; ai < argc; ai++) {
        if (!strcmp(argv[ai], "--force")) { force_multi = 1; break; }
    }
    if (!force_multi) {
        int lock_fd = open("/tmp/agfa9000.lock", O_CREAT | O_RDWR, 0644);
        if (lock_fd >= 0) {
            if (flock(lock_fd, LOCK_EX | LOCK_NB) < 0) {
                fprintf(stderr,
                    "agfa9000: another instance is already running "
                    "(lock /tmp/agfa9000.lock held).\n"
                    "          Use --force to start anyway.\n");
                close(lock_fd);
                return 1;
            }
            /* Leak fd intentionally — kernel releases the flock on exit. */
        }
    }

    /* Redirect debug output to log file instead of terminal */
    FILE *logf = fopen("agfa9000.log", "w");
    if (logf) {
        dup2(fileno(logf), 2);  /* stderr → log file */
        fclose(logf);
    }

    const char *rom_dir = NULL;
    const char *rom_image = NULL;   /* flat 640KB ROM image (e.g. CP/M) */
    const char *split_roms_dir = NULL;  /* directory of Uxxx_LANEn.bin split EPROMs */
    const char *hd_image = NULL;
    const char *io_rom = NULL;
    const char *sysstart_file = NULL;
    int hd_block_size = 512;
    int debug_sockets = 0;
    int i;

    for (i = 1; i < argc; i++) {
        if (argv[i][0] != '-') {
            rom_dir = argv[i];
        } else if (!strcmp(argv[i], "-rom") && i+1 < argc) {
            rom_image = argv[++i];
        } else if (!strcmp(argv[i], "-roms") && i+1 < argc) {
            split_roms_dir = argv[++i];
        } else if (!strcmp(argv[i], "-hd") && i+1 < argc) {
            hd_image = argv[++i]; hd_block_size = 512;
        } else if (!strcmp(argv[i], "-hd1024") && i+1 < argc) {
            hd_image = argv[++i]; hd_block_size = 1024;
        } else if (!strcmp(argv[i], "-ram") && i+1 < argc) {
            ram_size = atoi(argv[++i]) * 1024 * 1024;
            if (ram_size > RAM_MAX) ram_size = RAM_MAX;
        } else if (!strcmp(argv[i], "-io") && i+1 < argc) {
            io_rom = argv[++i];
        } else if (!strcmp(argv[i], "-sysstart") && i+1 < argc) {
            sysstart_file = argv[++i];
        } else if (!strcmp(argv[i], "-load") && i+2 < argc) {
            /* Deferred load binary into RAM: -load <file> <hex_addr>
             * Loaded after monitor boot completes (to survive RAM test).
             * The actual injection happens in the main loop below. */
            deferred_load_file = argv[++i];
            deferred_load_addr = strtoul(argv[++i], NULL, 16);
        } else if (!strcmp(argv[i], "-vera")) {
            vera_enabled = 1;
        } else if (!strcmp(argv[i], "--nosound")) {
            nosound = 1;
        } else if (!strcmp(argv[i], "--trace") && i + 1 < argc) {
            trace_file = fopen(argv[++i], "w");
            if (!trace_file) { fprintf(stderr, "Can't open trace file: %s\n", argv[i]); exit(1); }
        } else if (!strcmp(argv[i], "-debug")) {
            debug_sockets = 1;
        } else if (!strcmp(argv[i], "-profile")) {
            profiler_enabled = 1;
            debug_sockets = 1;   /* profiler implies debug sockets */
        } else if (!strcmp(argv[i], "-divlog") && i+1 < argc) {
            divlog_enabled = 1;
            divlog_path = argv[++i];
            debug_sockets = 1;   /* divlog dump is exposed via the prof socket */
        } else if (!strcmp(argv[i], "-boot") && i+1 < argc) {
            const char *arg = argv[++i];
            if (!strcmp(arg, "cpm") || !strcmp(arg, "CPM")) {
                auto_boot_addr = 0x20000;
            } else if (!strcmp(arg, "minix") || !strcmp(arg, "MINIX")) {
                auto_boot_addr = 0x40000;
            } else if (!strcmp(arg, "ps") || !strcmp(arg, "postscript")) {
                auto_boot_addr = 0x40508;  /* PS init entry from boot thunk */
            } else {
                auto_boot_addr = strtoul(arg, NULL, 0);
            }
            if (auto_boot_addr == 0) {
                fprintf(stderr, "-boot: bad target '%s' (use cpm | minix | ps | <hex addr>)\n", arg);
                exit(1);
            }
        } else if (!strcmp(argv[i], "-autocpm")) {
            auto_boot_addr = 0x20000;
        } else if (!strcmp(argv[i], "-autominix")) {
            auto_boot_addr = 0x40000;
        } else if (!strcmp(argv[i], "-v")) {
            verbose = 1;
        } else {
            usage(argv[0]);
        }
    }
    if (!rom_dir && !rom_image && !split_roms_dir) usage(argv[0]);

    /* Load Sys/Start file for injection */
    if (sysstart_file) {
        FILE *f = fopen(sysstart_file, "rb");
        if (f) {
            fseek(f, 0, SEEK_END);
            sysstart_len = ftell(f);
            fseek(f, 0, SEEK_SET);
            sysstart_data = malloc(sysstart_len);
            fread(sysstart_data, 1, sysstart_len, f);
            fclose(f);
            fprintf(stderr, "Loaded Sys/Start: %s (%d bytes)\n", sysstart_file, sysstart_len);
        } else {
            fprintf(stderr, "Cannot open Sys/Start: %s\n", sysstart_file);
        }
    }

    /* Init peripherals */
    scc_init(&scc);
    scc_set_tx_callback(&scc, SCC_CH_A, scc_tx_handler, NULL);
    scc_set_tx_callback(&scc, SCC_CH_B, scc_tx_handler, NULL);
    /* Assert DCD on both channels — serial console has no modem.
     * Without DCD, Minix's rs_read sends SIGHUP and drops all input. */
    scc_set_dcd(&scc, SCC_CH_A, 1);
    scc_set_dcd(&scc, SCC_CH_B, 1);
    /* SCC interrupt state is polled directly in the main loop (see the
     * unified IRQ priority block).  A callback that mutates the IPL
     * outside that block would race: it could clear a pending level-1
     * (VERA AFLOW) the main loop just asserted, leaving the VERA IRQ
     * line quiescent forever and the kernel AFLOW dispatcher never
     * entered. */
    (void)scc_irq_handler;
    /* CTS on Channel B: deasserted by default (auto-boots to PostScript,
     * matching Adrian's hardware). Use -cts to assert it and get the
     * Atlas Monitor prompt instead. */
    scc_set_cts(&scc, SCC_CH_B, 0);

    ncr5380_init(&scsi);

    /* Init R6522 VIAs for IO board communication */
    via_init(&via[0], "VIA1");
    if (vera_enabled) {
        vera_init(&vera);
#ifdef ENABLE_VERA_SDL
        setvbuf(stderr, NULL, _IONBF, 0);
        setvbuf(stdout, NULL, _IONBF, 0);
        printf("=== SDL audio: nosound=%d, calling SDL_Init(VIDEO%s) ===\n",
            nosound, nosound ? "" : "|AUDIO");
        fflush(stdout);
        fprintf(stderr, "=== SDL audio: nosound=%d, calling SDL_Init(VIDEO%s) ===\n",
            nosound, nosound ? "" : "|AUDIO");
        fflush(stderr);
        int sdl_rc = SDL_Init(SDL_INIT_VIDEO | (nosound ? 0 : SDL_INIT_AUDIO));
        if (sdl_rc != 0) {
            fprintf(stderr, "SDL audio: SDL_Init FAILED: %s\n", SDL_GetError());
        }
        if (sdl_rc == 0) {
            sdl_window = SDL_CreateWindow("Agfa 9000PS + VERA",
                SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                640, 480, 0);
            if (sdl_window) {
                /* No PRESENTVSYNC: blocking on host vsync stalls the 68020
                 * emulation loop for up to a full refresh (~16ms @ 60Hz).
                 * We pace frames ourselves and let SDL present immediately. */
                sdl_renderer = SDL_CreateRenderer(sdl_window, -1,
                    SDL_RENDERER_ACCELERATED);
                sdl_texture = SDL_CreateTexture(sdl_renderer,
                    SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
                    640, 480);
                vera.framebuffer = vera_fb;
                /* Enable text input events so plain ASCII keys (letters,
                 * digits, punctuation) come through as SDL_TEXTINPUT and
                 * get forwarded to the SCC.  Without this, only the keys
                 * we hard-code in the SDL_KEYDOWN switch (RETURN, ESC,
                 * arrows, …) reach the guest — every letter is dead. */
                SDL_StartTextInput();
            }

            /* Open audio device */
            if (!nosound) {
            SDL_AudioSpec want, have;
              memset(&want, 0, sizeof(want));
              want.freq = 11025;
              want.format = AUDIO_S16SYS;
              want.channels = 2;
              want.samples = 256;
              want.callback = sdl_audio_callback;
              sdl_audio_dev = SDL_OpenAudioDevice(NULL, 0, &want, &have, 0);
              if (sdl_audio_dev > 0) {
                  vera_set_output_rate(have.freq);
                  SDL_PauseAudioDevice(sdl_audio_dev, 0);
                  fprintf(stderr, "=== ");
                  fflush(stderr);
                  fprintf(stderr,
                      "SDL audio: opened dev=%u  freq=%d ch=%d fmt=0x%04x samples=%u "
                      "(wanted %d/%d/0x%04x/%u)\n",
                      (unsigned)sdl_audio_dev, have.freq, have.channels,
                      (unsigned)have.format, (unsigned)have.samples,
                      want.freq, want.channels, (unsigned)want.format,
                      (unsigned)want.samples);
                  fprintf(stderr, "SDL audio: driver=\"%s\"\n",
                      SDL_GetCurrentAudioDriver() ? SDL_GetCurrentAudioDriver() : "(none)");
              } else {
                  fprintf(stderr, "=== ");
                  fflush(stderr);
                  fprintf(stderr,
                      "SDL audio: SDL_OpenAudioDevice FAILED: %s\n"
                      "  (VERA PCM FIFO will not drain via host audio — "
                      "use -nosound or fix audio backend)\n",
                      SDL_GetError());
              }
            } else {
              fprintf(stderr, "SDL audio: disabled (--nosound) — "
                              "FIFO drain emulated from CPU cycles\n");
              extern int silent_pcm_drain;
              silent_pcm_drain = 1;
            } /* !nosound */
        }  /* SDL_Init */
#endif
        fprintf(stderr, "VERA video module enabled (replaces VIA2 at 0x04000020)\n");
    } else {
        via_init(&via[1], "VIA2");
    }

    /* VIA #2 Timer 1 will be started by the firmware during boot/calibration.
     * Don't pre-start it — let the firmware configure it properly. */

    /* Init cross-connect FIFOs for IO board communication */
    xfifo_init(&fifo_main_to_io);
    xfifo_init(&fifo_io_to_main);

    /* Load ROMs */
    fprintf(stderr, "Agfa 9000PS Emulator\n");
    fprintf(stderr, "RAM: %d MB\n", ram_size / (1024 * 1024));
    if (rom_image) {
        /* Load flat ROM image (e.g. CP/M) */
        FILE *f = fopen(rom_image, "rb");
        if (!f) { fprintf(stderr, "Cannot open %s\n", rom_image); return 1; }
        size_t n = fread(rom, 1, ROM_TOTAL, f);
        fclose(f);
        fprintf(stderr, "Loaded ROM image: %s (%zu bytes)\n", rom_image, n);
        if (n < 8) { fprintf(stderr, "ROM image too small\n"); return 1; }
    } else if (split_roms_dir) {
        /* Load split EPROM images and interleave into combined ROM.
         * Socket map for Agfa main board (5 banks x 4 byte lanes): */
        static const struct { const char *socket; int bank; int lane; } eprom_map[] = {
            {"U291", 0, 0}, {"U294", 0, 1}, {"U283", 0, 2}, {"U281", 0, 3},
            {"U303", 1, 0}, {"U300", 1, 1}, {"U305", 1, 2}, {"U297", 1, 3},
            {"U306", 2, 0}, {"U304", 2, 1}, {"U287", 2, 2}, {"U284", 2, 3},
            {"U295", 3, 0}, {"U292", 3, 1}, {"U301", 3, 2}, {"U298", 3, 3},
            {"U16",  4, 0}, {"U20",  4, 1}, {"U19",  4, 2}, {"U17",  4, 3},
        };
        static const char *lane_names[] = {"HH", "HM", "LM", "LL"};
        memset(rom, 0xFF, ROM_TOTAL);  /* blank = 0xFF */
        int loaded = 0;
        for (int e = 0; e < 20; e++) {
            char path[512];
            snprintf(path, sizeof(path), "%s/%s_%s%d.bin",
                     split_roms_dir, eprom_map[e].socket,
                     lane_names[eprom_map[e].lane], eprom_map[e].bank);
            FILE *f = fopen(path, "rb");
            if (!f) continue;  /* missing = blank (0xFF) */
            unsigned char eprom[32768];
            size_t n = fread(eprom, 1, 32768, f);
            fclose(f);
            if (n != 32768) {
                fprintf(stderr, "Warning: %s is %zu bytes (expected 32768)\n", path, n);
            }
            /* Interleave into combined ROM: each EPROM byte maps to
             * rom[bank*128K + i*4 + lane] */
            int bank = eprom_map[e].bank;
            int lane = eprom_map[e].lane;
            for (size_t i = 0; i < n; i++) {
                rom[bank * 131072 + i * 4 + lane] = eprom[i];
            }
            loaded++;
        }
        fprintf(stderr, "Loaded %d split EPROMs from %s\n", loaded, split_roms_dir);
        rom_image = split_roms_dir;  /* flag as non-Agfa for interrupt gating */
    } else {
        if (load_all_roms(rom_dir) < 0) return 1;
    }

    /* Mount HD image */
    if (hd_image) {
        if (ncr5380_attach_image(&scsi, 0, hd_image, hd_block_size) < 0)
            return 1;
    }

    /* Patch self-test to return immediately (D0=0 = pass).
     * The self-test at 0x84658 fills/verifies all of RAM which takes
     * forever at emulated speed. Patch entry: moveq #0,d0; rts */
    /* ROM verified intact. The function at 0x898B8 exists and starts with
     * LINK A6, #0 (proper C function prologue). Previous analysis
     * confused file offset 0x198B8 (= address 0x998B8, which IS zeros)
     * with the correct offset 0x98B8 (= address 0x898B8, which has code). */

    /* Init both CPUs using the Plexus dual-CPU pattern:
     * allocate context, set_context, set_cpu_type, m68k_init, pulse_reset, get_context */

    void *main_ctx = calloc(1, m68k_context_size());
    void *io_ctx = NULL;

    /* Main CPU: 68020 (matches real Agfa 9000PS hardware) */
    m68k_set_context(main_ctx);
    m68k_set_cpu_type(M68K_CPU_TYPE_68020);
    m68k_init();
    m68k_set_illg_instr_callback(illg_instr_cb);
    eeprom_load();
    emu_current_cpu = 0;
    m68k_pulse_reset();

    /* -boot: skip AGFA-MON entirely.  Pulse_reset just loaded SSP and
     * PC from the reset vectors at 0x00000000 (= AGFA-MON entry).
     * Override PC to jump straight to the guest OS.  SSP stays as
     * AGFA-MON's reset value, but the guest OS (CP/M, Minix, PS) sets
     * up its own stack within the first few instructions, so it
     * doesn't matter.  Skips the ~18 s RAM test. */
    if (auto_boot_addr) {
        m68k_set_reg(M68K_REG_PC, auto_boot_addr);
        fprintf(stderr, "Auto-boot: PC ← 0x%08X (skipping AGFA-MON)\n",
                auto_boot_addr);
        auto_boot_done = 1;   /* don't re-trigger from the main loop */
    }

    m68k_get_context(main_ctx);

    fprintf(stderr, "Main CPU: SSP=0x%08X PC=0x%08X\n",
            m68k_read_memory_32(0), m68k_read_memory_32(4));

    /* IO board CPU: 68000 */
    if (io_rom) {
        ioboard_init(&ioboard, &fifo_main_to_io, &fifo_io_to_main);
        if (ioboard_load_rom(&ioboard, io_rom) == 0) {
            io_ctx = calloc(1, m68k_context_size());
            m68k_set_context(io_ctx);
            m68k_set_cpu_type(M68K_CPU_TYPE_68000);
            m68k_init();
            emu_current_cpu = 1;
            extern ioboard_t *current_io_ptr;  /* from ioboard.c */
            current_io_ptr = &ioboard;
            m68k_pulse_reset();

            /* Verify IO board CPU state immediately after reset */
            fprintf(stderr, "[IO] After reset: PC=0x%08X SP=0x%08X\n",
                    m68k_get_reg(NULL, M68K_REG_PC),
                    m68k_get_reg(NULL, M68K_REG_A7));

            /* Run a few instructions to verify */
            m68k_execute(10);
            fprintf(stderr, "[IO] After 10 cycles: PC=0x%08X SP=0x%08X\n",
                    m68k_get_reg(NULL, M68K_REG_PC),
                    m68k_get_reg(NULL, M68K_REG_A7));

            m68k_get_context(io_ctx);
            memcpy(ioboard.cpu_ctx, io_ctx, m68k_context_size());
            ioboard.loaded = 1;

            fprintf(stderr, "[IO] CPU: SSP=0x%08X PC=0x%08X\n",
                (ioboard.rom[0]<<24)|(ioboard.rom[1]<<16)|(ioboard.rom[2]<<8)|ioboard.rom[3],
                (ioboard.rom[4]<<24)|(ioboard.rom[5]<<16)|(ioboard.rom[6]<<8)|ioboard.rom[7]);

            /* Restore main CPU */
            emu_current_cpu = 0;
            current_io_ptr = NULL;
            m68k_set_context(main_ctx);
        }
    }

    /* Allocate profiler tables (only with -profile flag) */
    if (profiler_enabled) {
        size_t rom_slots = PROF_ROM_SIZE >> 1;
        prof_ram_slots = ram_size >> 1;
        prof_rom_count  = (uint64_t *)calloc(rom_slots, sizeof(uint64_t));
        prof_rom_cycles = (uint64_t *)calloc(rom_slots, sizeof(uint64_t));
        prof_ram_count  = (uint64_t *)calloc(prof_ram_slots, sizeof(uint64_t));
        prof_ram_cycles = (uint64_t *)calloc(prof_ram_slots, sizeof(uint64_t));
        if (!prof_rom_count || !prof_rom_cycles || !prof_ram_count || !prof_ram_cycles) {
            fprintf(stderr, "profiler: out of memory allocating tables\n");
            exit(1);
        }
        fprintf(stderr, "Profiler enabled: ROM %zu KB, RAM %zu KB tables\n",
                (rom_slots * sizeof(uint32_t) * 2) / 1024,
                ((size_t)prof_ram_slots * sizeof(uint32_t) * 2) / 1024);
    }

    /* Allocate divlog table (only with -divlog flag) */
    if (divlog_enabled) {
        divlog_table = (div_entry_t *)calloc(DIVLOG_TABLE_SIZE, sizeof(div_entry_t));
        if (!divlog_table) {
            fprintf(stderr, "divlog: out of memory\n");
            exit(1);
        }
        fprintf(stderr, "Divlog enabled: %zu MB hashtable, output → %s\n",
                (size_t)(DIVLOG_TABLE_SIZE * sizeof(div_entry_t)) / (1024*1024),
                divlog_path);
        atexit_divlog();
    }

    /* Start debug socket server (only with -debug flag) */
    if (debug_sockets) {
        unlink("/tmp/agfa9000.sock");
        unlink("/tmp/agfa9000_mem.sock");
        unlink("/tmp/agfa9000_prof.sock");
        pthread_t dbg_tid, mem_tid;
        pthread_create(&dbg_tid, NULL, debug_socket_thread, NULL);
        pthread_detach(dbg_tid);
        pthread_create(&mem_tid, NULL, mem_socket_thread, NULL);
        pthread_detach(mem_tid);
        fprintf(stderr, "Debug sockets enabled:\n");
        fprintf(stderr, "  socat - /tmp/agfa9000.sock       — dump registers\n");
        fprintf(stderr, "  echo ADDR LEN | socat - /tmp/agfa9000_mem.sock — read memory\n");
        if (profiler_enabled || divlog_enabled) {
            pthread_t prof_tid;
            pthread_create(&prof_tid, NULL, prof_socket_thread, NULL);
            pthread_detach(prof_tid);
            fprintf(stderr, "  echo CMD | socat - /tmp/agfa9000_prof.sock     — profiler / divlog\n");
            fprintf(stderr, "    commands: stats | top [N] | topcyc [N] | range S E [MIN] | dump PATH [MIN] | reset | divdump PATH\n");
        }
    }

    fprintf(stderr, "Running... (Ctrl+\\ to quit, Ctrl+C sent to guest)\n---\n");

    term_raw_on();
    atexit(term_raw_off);

    /* Main loop: time-slice between main CPU (68020 @ 16MHz) and
     * IO board CPU (68000 @ 8MHz). Run in 10ms slices:
     * Main: 160,000 cycles, IO: 80,000 cycles (half clock speed) */
    {
        unsigned long long last_report = 0;
        for (;;) {
            /* Interrupt delivery — compute highest pending level:
             * Level 1: VIA #2 (or VERA VSYNC if -vera)
             * Level 4: VIA #1 (IO board communication, timer)
             * Level 6: Z8530 SCC (serial RX/TX/ext status)
             * m68k_set_irq must be called with the HIGHEST active level,
             * not individual levels (it replaces, not OR's).
             * SCC2691 IRQs are handled via VIA #1 register access. */
            {
                int irq_level = 0;
                if (vera_enabled ? vera_irq_active(&vera) : via_irq_active(&via[1])) irq_level = 1;
                if (via_irq_active(&via[0]))
                    irq_level = 4;
                if (scc.irq_state)
                    irq_level = 6;
                m68k_set_irq(irq_level);
                { static unsigned long dbg_lvl_cnt[8];
                  static unsigned long long dbg_last_report;
                  dbg_lvl_cnt[irq_level & 7]++;
                  if (total_cycles > dbg_last_report + 16000000ULL) {
                      fprintf(stderr, "IRQLVL: 0=%lu 1=%lu 4=%lu 6=%lu\n",
                          dbg_lvl_cnt[0], dbg_lvl_cnt[1], dbg_lvl_cnt[4], dbg_lvl_cnt[6]);
                      fflush(stderr);
                      dbg_last_report = total_cycles;
                  }
                }
            }

            /* Run main CPU */
            emu_current_cpu = 0;
            /* Feed stdin before execute so the firmware sees RX data
             * when it polls RR0 during the slice. */
            check_host_input();

            /* (-boot is handled at startup right after pulse_reset,
             * not here, so it skips the AGFA-MON RAM test entirely.) */

            /* Deferred binary load: inject after AGFA-MON's RAM test
             * has finished walking the entire 4 MB region, otherwise the
             * test pattern overwrites whatever we just loaded.  300M
             * cycles ≈ 18 s emulated = comfortable margin past Ready. */
            if (deferred_load_file && !deferred_load_done && total_cycles > 300000000) {
                FILE *lf = fopen(deferred_load_file, "rb");
                if (lf) {
                    fseek(lf, 0, SEEK_END); long ls = ftell(lf); fseek(lf, 0, SEEK_SET);
                    uint32_t la = deferred_load_addr;
                    if (la >= 0x02000000 && la + ls <= 0x02000000 + ram_size) {
                        fread(ram + (la - 0x02000000), 1, ls, lf);
                        fprintf(stderr, "Loaded %s at 0x%08X (%ld bytes) [deferred]\n",
                                deferred_load_file, la, ls);
                    }
                    fclose(lf);
                }
                deferred_load_done = 1;
            }

            via_last_cycles[0] = 0;
            via_last_cycles[1] = 0;
            unsigned int _pcb = m68k_get_reg(NULL, M68K_REG_PC);
            /* Profiler: m68k_cycles_run() resets at the start of each
             * m68k_execute() slice, so we must flush the previous slice's
             * trailing instruction now (we have no way to know its real
             * cycle cost — charge it 0) and rebase the delta tracker. */
            if (profiler_enabled) {
                prof_last_pc = 0xFFFFFFFFu;
                prof_last_cyc = 0;
            }
            int cycles = m68k_execute(10000);
            if (profiler_enabled && prof_last_pc != 0xFFFFFFFFu) {
                /* Charge the last instruction of this slice with the
                 * remaining cycle delta. */
                int delta = m68k_cycles_run() - prof_last_cyc;
                profiler_account(prof_last_pc, delta);
                prof_last_pc = 0xFFFFFFFFu;
            }
            /* m68k_execute()'s return value already includes the
             * 12-cycle DSACK stalls charged via bus_stall_dtack() at
             * each VIA1/VERA access — see the helper above.  No
             * separate "penalty" accumulator needed. */
            int wall_cycles = cycles;
            total_cycles += wall_cycles;
            { unsigned int _pca = m68k_get_reg(NULL, M68K_REG_PC);
              if ((_pca < 0x1000 && _pcb > 0x02050000) || (_pca < 0x02000000 && _pcb > 0x02050000)) {
                fprintf(stderr, "\n*** WILD JUMP: PC 0x%08X -> 0x%08X ***\n", _pcb, _pca);
                fprintf(stderr, "  D0=%08X D1=%08X D2=%08X D3=%08X D4=%08X D5=%08X\n",
                    m68k_get_reg(NULL,M68K_REG_D0), m68k_get_reg(NULL,M68K_REG_D1),
                    m68k_get_reg(NULL,M68K_REG_D2), m68k_get_reg(NULL,M68K_REG_D3),
                    m68k_get_reg(NULL,M68K_REG_D4), m68k_get_reg(NULL,M68K_REG_D5));
                fprintf(stderr, "  A0=%08X A1=%08X A2=%08X A3=%08X A4=%08X A5=%08X A6=%08X SP=%08X\n",
                    m68k_get_reg(NULL,M68K_REG_A0), m68k_get_reg(NULL,M68K_REG_A1),
                    m68k_get_reg(NULL,M68K_REG_A2), m68k_get_reg(NULL,M68K_REG_A3),
                    m68k_get_reg(NULL,M68K_REG_A4), m68k_get_reg(NULL,M68K_REG_A5),
                    m68k_get_reg(NULL,M68K_REG_A6), m68k_get_reg(NULL,M68K_REG_A7));
                unsigned int sp = m68k_get_reg(NULL, M68K_REG_A7);
                fprintf(stderr, "  Stack:");
                for (int i = 0; i < 16; i++)
                    fprintf(stderr, " %08X", m68k_read_memory_32(sp + i*4));
                fprintf(stderr, "\n  USP=%08X\n", m68k_get_reg(NULL, M68K_REG_USP));
                if (doom_pc_idx > 0) {
                    fprintf(stderr, "  Last Doom PCs (%d total):\n", doom_pc_idx);
                    int start = doom_pc_idx > 32 ? doom_pc_idx - 32 : 0;
                    for (int i = start; i < doom_pc_idx; i++)
                        fprintf(stderr, "    [%d] 0x%08X\n", i, doom_pc_ring[i & 63]);
                }
              }
            }
            /* Run IO board CPU (68000 @ 8MHz = half main board speed).
             * Scale IO cycles to match: 5000 main cycles → 2500 IO cycles. */
            if (ioboard.loaded)
                ioboard_run(&ioboard, cycles / 2);

            /* Sys/Start injection: feed one byte per slice into the
             * SCC RX FIFO (both channels). The PS interpreter reads
             * PostScript source from the serial port at 0x07000000. */
            if (sysstart_data && sysstart_pos < sysstart_len) {
                /* Only feed when Channel B FIFO is empty (interpreter
                 * reads from Channel B via 0x07000000/01) */
                if (scc.ch[SCC_CH_B].rx_fifo_count == 0) {
                    scc_rx_char(&scc, SCC_CH_B, sysstart_data[sysstart_pos]);
                    scc_rx_char(&scc, SCC_CH_A, sysstart_data[sysstart_pos]);
                    sysstart_pos++;
                }
                if (sysstart_pos >= sysstart_len) {
                    fprintf(stderr, "[EMU] Sys/Start fully injected (%d bytes)\n", sysstart_len);
                    sysstart_data = NULL;  /* Don't inject again */
                }
            }

            scc_tick_n(&scc, wall_cycles);
            ncr5380_tick(&scsi);

            /* Tick VIA timers (VIAs run at 1MHz, CPU at 16MHz → divide by 16) */
            via_tick(&via[0], wall_cycles / 10);

#ifdef ENABLE_VERA_SDL
            /* Real-time throttle: 16MHz = 16M cycles/sec.
             * Every 160,000 cycles = 10ms of emulated time.
             * Compare against wall clock and sleep if ahead. */
            { static uint32_t rt_base_ticks = 0;
              static unsigned long long rt_base_cycles = 0;
              if (rt_base_ticks == 0) {
                  rt_base_ticks = SDL_GetTicks();
                  rt_base_cycles = total_cycles;
              }
              uint32_t emu_ms = (uint32_t)((total_cycles - rt_base_cycles) / 16000);
              uint32_t wall_ms = SDL_GetTicks() - rt_base_ticks;
              if (emu_ms > wall_ms + 2) {
                  SDL_Delay(emu_ms - wall_ms);
              } else if (wall_ms > emu_ms + 250) {
                  /* Fell more than 250ms behind (host stall, window drag,
                   * GC, etc.). Rebase so we don't try to "catch up" hours
                   * of missed wall time by running flat-out forever. */
                  rt_base_ticks = SDL_GetTicks();
                  rt_base_cycles = total_cycles;
              }
            }
#endif

            if (vera_enabled) {
                int old_frame = vera.frame_count;
                vera_tick(&vera, wall_cycles);
#ifdef ENABLE_VERA_SDL
                /* Render + present on new VERA frame. SDL_RenderPresent
                 * no longer blocks on host vsync (PRESENTVSYNC removed),
                 * so this is cheap and bounded by VERA's own ~60Hz tick. */
                if (vera.frame_count != old_frame && sdl_renderer) {
                    vera_render_frame(&vera);
                    SDL_UpdateTexture(sdl_texture, NULL, vera_fb, 640 * 4);
                    SDL_RenderCopy(sdl_renderer, sdl_texture, NULL, NULL);
                    SDL_RenderPresent(sdl_renderer);
                }
#endif
            } else {
                via_tick(&via[1], wall_cycles / 10);
            }

#ifdef ENABLE_VERA_SDL
            /* Process SDL events every slice — independent of whether a
             * new VERA frame was rendered. This keeps SDL_QUIT and
             * keyboard input alive even when rendering stalls (Doom load,
             * CP/M monitor, no-VERA workloads, etc.). */
            if (sdl_window) {
                SDL_Event ev;
                while (SDL_PollEvent(&ev)) {
                    if (ev.type == SDL_QUIT) goto quit;
                    if (ev.type == SDL_TEXTINPUT) {
                        int ch = console_channel >= 0 ? console_channel : SCC_CH_A;
                        unsigned char c = ev.text.text[0];
                        if (c >= 0x20 && c < 0x7F)
                            scc_rx_char(&scc, ch, c);
                    }
                    if (ev.type == SDL_KEYDOWN) {
                        int ch = console_channel >= 0 ? console_channel : SCC_CH_A;
                        SDL_Keycode k = ev.key.keysym.sym;
                        if (k == SDLK_RETURN) scc_rx_char(&scc, ch, '\r');
                        else if (k == SDLK_ESCAPE) scc_rx_char(&scc, ch, 0x1B);
                        else if (k == SDLK_TAB) scc_rx_char(&scc, ch, '\t');
                        else if (k == SDLK_BACKSPACE) scc_rx_char(&scc, ch, 0x7F);  /* DEL — matches host xterm/PuTTY default */
                        else if (k == SDLK_UP) scc_rx_char(&scc, ch, 0x1B), scc_rx_char(&scc, ch, '['), scc_rx_char(&scc, ch, 'A');
                        else if (k == SDLK_DOWN) scc_rx_char(&scc, ch, 0x1B), scc_rx_char(&scc, ch, '['), scc_rx_char(&scc, ch, 'B');
                        else if (k == SDLK_LEFT) scc_rx_char(&scc, ch, 0x1B), scc_rx_char(&scc, ch, '['), scc_rx_char(&scc, ch, 'D');
                        else if (k == SDLK_RIGHT) scc_rx_char(&scc, ch, 0x1B), scc_rx_char(&scc, ch, '['), scc_rx_char(&scc, ch, 'C');
                    }
                }
            }
#endif

            /* (IRQ generation moved to unified block before m68k_execute) */

            /* Inter-board wiring: IO board → main board.
             *
             * The SCC2691 on the IO board sits between DUART and main VIA.
             * When the main board reads SCC2691 registers via VIA:
             *   - SRA (reg 1): status register (bit 0=RXRDY, bit 2=TXRDY)
             *   - RHR (reg 3): received data byte
             *
             * We emulate the SCC2691 by maintaining its register state on
             * the VIA PA input pins. The main board reads by setting DDRA=0
             * and toggling ORB with the register address, then reading ORA. */
            {
                /* SCC2691 emulated status: always TX ready.
                 * RX ready if IO board sent response data. */
                uint8_t scc2691_sra = 0x04;  /* TXRDY always */
                if (fifo_io_to_main.count > 0)
                    scc2691_sra |= 0x01;  /* RXRDY */

                /* When DDRA=0 (input mode), put appropriate value on PA
                 * based on the register being read (ORB bits 7-5). */
                if (via[0].ddra == 0x00) {
                    int scc2691_reg = (via[0].orb >> 5) & 7;
                    switch (scc2691_reg) {
                    case 1:  /* SRA — status register */
                        via_set_pa(&via[0], scc2691_sra);
                        break;
                    case 5:  /* ISR — interrupt status register */
                        /* Bit 0 = TxRDY, bit 1 = RxRDY/FFULL, bit 2 = delta break,
                         * bit 3 = counter ready, bit 4 = reserved */
                        {
                            uint8_t isr = 0x01;  /* TxRDY always set */
                            if (fifo_io_to_main.count > 0)
                                isr |= 0x02;  /* RxRDY */
                            via_set_pa(&via[0], isr);
                        }
                        break;
                    case 3:  /* RHR — receive holding register */
                        if (fifo_io_to_main.count > 0) {
                            uint8_t byte;
                            xfifo_get(&fifo_io_to_main, &byte);
                            via_set_pa(&via[0], byte);
                            if (verbose) {
                                static int rx_trace = 0;
                                if (rx_trace < 20)
                                    if(0) fprintf(stderr, "[SCC2691-RX] byte=0x%02X '%c' remaining=%d\n",
                                            byte, byte >= 0x20 && byte < 0x7F ? byte : '.',
                                            fifo_io_to_main.count);
                                rx_trace++;
                            }
                        } else {
                            via_set_pa(&via[0], 0x00);
                        }
                        break;
                    default:
                        /* Other registers: return 0 or last written value */
                        break;
                    }
                }

                /* Assert CA1 when IO board has data available */
                if (fifo_io_to_main.count > 0) {
                    via_set_ca1(&via[0], 0);  /* Falling edge */
                } else {
                    via_set_ca1(&via[0], 1);  /* Release */
                }
            }

            { static int loop_trace = 0;
              if (loop_trace == 2000) {
                if(0) fprintf(stderr, "[LOOP] cycle=%llu rom_image=%p\n", total_cycles, (void*)rom_image);
              }
              loop_trace++;
            }



            /* Agfa firmware-specific interrupt generation.
             * Skip when running a flat ROM image (e.g. CP/M) which
             * doesn't use the Agfa's timer/SCC interrupt scheme. */
            if (!rom_image) {
            /* (Removed: old hack that asserted SCC interrupts manually.
             * VIA timer and SCC now handle interrupts through proper
             * hardware models in via.c and scc.c.) */
            } /* end if (!rom_image) — Agfa-specific interrupts */

            /* Milestone tracing: log when PC hits key addresses */
            {
                unsigned int pc = m68k_get_reg(NULL, M68K_REG_PC);
                static unsigned int last_milestone = 0;
                if (pc != last_milestone) {
                    const char *name = NULL;
                    /* Use ranges instead of exact addresses — tight loops
                     * mean we rarely land exactly on the entry point */
                    if (pc >= 0x40508 && pc < 0x40520) name = "PS init entry";
                    else if (pc >= 0x84658 && pc < 0x84670) {
                        static int st_count = 0;
                        if (++st_count <= 10)
                            fprintf(stderr, "[MILE] self-test entry #%d (cycle %llu)\n", st_count, total_cycles);
                    }
                    else if (pc >= 0x84790 && pc < 0x847A0) name = "self-test exit";
                    else if (pc >= 0x84C70 && pc < 0x84C80) {
                        name = "timer calibration";
                        /* After calibration completes, the result is stored
                         * at 0x02022310. Read and display it. */
                        static int cal_count = 0;
                        if (++cal_count == 2) {
                            /* Second hit = return from first calibration.
                             * Check what was stored. */
                            uint32_t cal = m68k_read_memory_32(0x02022310);
                            uint32_t tmr = (m68k_read_memory_8(0x04000025) << 8)
                                         | m68k_read_memory_8(0x04000024);
                            fprintf(stderr, "[CAL] Stored calibration at 0x02022310: 0x%08X (%d)\n"
                                    "[CAL] Timer reload value: 0x%04X\n", cal, cal, tmr);
                        }
                    }
                    /* PS init milestones (non-overlapping, address order) */
                    else if (pc >= 0x40528 && pc < 0x40540) name = "PS init: memset";
                    else if (pc >= 0x40560 && pc < 0x40574) name = "PS init: before FPU";
                    else if (pc >= 0x40574 && pc < 0x4057A) name = "PS init: FPU init call";
                    else if (pc >= 0x4057A && pc < 0x40580) name = "PS init: timer cal call";
                    else if (pc >= 0x40580 && pc < 0x40586) name = "PS init: FILESYSTEM call";
                    else if (pc >= 0x40586 && pc < 0x40594) {
                        name = "PS init: IRQ ENABLED (counter check)";
                        /* Periodically dump the timer counter */
                        /* Dump timer chain state after interrupts are enabled */
                        static int irq_dump_done = 0;
                        if (!irq_dump_done) {
                            irq_dump_done = 1;
                            uint32_t chain = m68k_read_memory_32(0x0202237C);
                            uint32_t counter = m68k_read_memory_32(0x02022378);
                            uint32_t cal = m68k_read_memory_32(0x02022310);
                            uint32_t handler = m68k_read_memory_32(0x02000020);
                            fprintf(stderr, "[TIMER] chain=0x%08X counter=0x%08X cal=0x%08X handler=0x%08X\n",
                                    chain, counter, cal, handler);
                            if (chain >= 0x02000000 && chain < 0x02400000) {
                                /* Dump first timer chain entry */
                                uint32_t next = m68k_read_memory_32(chain);
                                uint32_t tick = m68k_read_memory_32(chain + 8);
                                uint32_t cb = m68k_read_memory_32(chain + 12);
                                fprintf(stderr, "[TIMER] Entry: next=0x%08X ticks=%d callback=0x%08X\n",
                                        next, tick, cb);
                            }
                        }
                    }
                    else if (pc >= 0x40594 && pc < 0x4059C) name = "PS init: push args";
                    else if (pc >= 0x4059C && pc < 0x405A4) name = "PS init: SERIAL BUF INIT";
                    else if (pc >= 0x405A4 && pc < 0x405AA) name = "PS init: LAST INIT";
                    else if (pc >= 0x405A4 && pc <= 0x405AC) {
                        static int trap_dump = 0;
                        if (!trap_dump) {
                            trap_dump = 1;
                            fprintf(stderr, "[TRAP] At PC=0x%X: RAM 0x2000070=0x%08X "
                                    "0x2000014=0x%08X 0x2000080=0x%08X\n",
                                    pc,
                                    m68k_read_memory_32(0x2000070),
                                    m68k_read_memory_32(0x2000014),
                                    m68k_read_memory_32(0x2000080));
                        }
                        name = "*** NEAR ILLEGAL! ***";
                    }
                    else if (pc >= 0x4059C && pc < 0x405A4) name = "PS init: SERIAL BUF call";
                    else if (pc >= 0x405A4 && pc < 0x405AA) name = "PS init: LAST INIT call";
                    else if (pc >= 0x405AA && pc < 0x405AC) name = "*** PS ILLEGAL TRAP ***";
                    /* Subroutine targets */
                    else if (pc >= 0x812B0 && pc < 0x812C0) name = "filesystem init (0x812B4)";
                    else if (pc >= 0x81150 && pc < 0x81160) name = "unknown init (0x81156)";
                    else if (pc >= 0x410C0 && pc < 0x410D0) name = "serial buf init (0x410C8)";
                    else if (pc >= 0x8E000 && pc < 0x8E010) name = "init 0x8E000";
                    else if (pc >= 0x8E038 && pc < 0x8E042) name = "0x8E000 RETURNING";
                    else if (pc >= 0x898B0 && pc < 0x898C0) name = "FPU init (0x898B8)";
                    else if (pc >= 0x90100 && pc < 0x90110) name = "init 0x90100";
                    else if (pc >= 0x84AFC && pc < 0x84B10) name = "init_via_ioboard_and_scsi";
                    else if (pc >= 0x85B58 && pc < 0x85B70) name = "SCSI device scan";
                    else if (pc >= 0x86020 && pc < 0x86030) name = "SCSI scan one device";
                    else if (pc >= 0x85770 && pc < 0x85790) name = "SCSI probe device";
                    else if (pc >= 0x8601A && pc < 0x86022) {
                        static int exit_count = 0;
                        if (++exit_count <= 3)
                            fprintf(stderr, "[SCSI] Timer wait EXIT (counter=%d)\n",
                                    m68k_read_memory_32(0x02022378));
                        name = "SCSI timer wait EXIT";
                    }
                    else if (pc >= 0x8600E && pc < 0x8601A) name = "SCSI timer wait";
                    else if (pc >= 0x3C2A4 && pc < 0x3C2C0) name = "printer_init";
                    else if (pc >= 0x3BC8A && pc < 0x3BCA0) name = "scc_channel_config";
                    else if (pc >= 0x71330 && pc < 0x71410) name = "*** PS INTERPRETER ***";
                    else if (pc >= 0x40E30 && pc < 0x40E40) name = "PS main entry";
                    else if (pc >= 0x5A550 && pc < 0x5A570) name = "bank2 PS code";
                    /* Exception handlers */
                    else if (pc >= 0x460 && pc < 0x475) name = "exception handler (0x468)";
                    else if (pc >= 0x770 && pc < 0x790) name = "FATAL handler (0x772)";
                    else if (pc >= 0x8DF50 && pc < 0x8DF70) name = "PS exec handler";
                    /* Boot points */
                    else if (pc >= 0x856 && pc < 0x870) name = "COLD/WARM BOOT";
                    else if (pc >= 0x200C && pc < 0x2020) name = "PS boot thunk";
                    if (name) {
                        fprintf(stderr, "[MILE] 0x%05X: %s\n", pc, name);
                        last_milestone = pc;
                    }
                }
            }

            /* Periodic debug dumps — disabled for clean output.
             * Re-enable for PS firmware or Minix debugging. */
#if 0
            if (!rom_image) {
                static unsigned long long last_counter_dump = 0;
                if (total_cycles - last_counter_dump > 100000000) {
                    uint32_t counter = m68k_read_memory_32(0x02022378);
                    uint32_t handler = m68k_read_memory_32(0x02000020);
                    fprintf(stderr, "[CTR] counter=%d handler=0x%08X\n",
                            counter, handler);
                    last_counter_dump = total_cycles;
                }
            }
            { static unsigned long long last_status = 0;
              extern int console_channel;
              if (total_cycles - last_status > 5000000) {
                unsigned int pc = m68k_get_reg(NULL, M68K_REG_PC);
                unsigned int sr = m68k_get_reg(NULL, M68K_REG_SR);
                /* Read TTY state from RAM: tty_table[0] at 0x0200B204 */
                unsigned int tty_base = 0x0200B304;
                int tty_ev = (int)m68k_read_memory_32(tty_base + 0);
                int tty_ic = (int)m68k_read_memory_32(tty_base + 12);
                int tty_ec = (int)m68k_read_memory_32(tty_base + 16);
                int tty_mn = (int)m68k_read_memory_32(tty_base + 28);
                int tty_il = (int)m68k_read_memory_32(tty_base + 72);
                int tty_to = (int)m68k_read_memory_32(0x0200F734);
                int rxcnt = (int)m68k_read_memory_32(0x021FFFF0);
                int rscnt = (int)m68k_read_memory_32(0x021FFFF4);
                int stored = (int)m68k_read_memory_32(0x021FFFE0);
                int storedic = (int)m68k_read_memory_32(0x021FFFE4);
                unsigned int tp_ptr = m68k_read_memory_32(0x021FFFE8);
                {
                    unsigned int cur_pc = m68k_get_reg(NULL, M68K_REG_PC);
                    uint32_t ram_top = (ram[0x0C] << 24) | (ram[0x0D] << 16) | (ram[0x0E] << 8) | ram[0x0F];
                    fprintf(stderr, "[STATUS] cyc=%llu PC=0x%08X ramtop=0x%08X tp=0x%X\n",
                        total_cycles, cur_pc, ram_top, tp_ptr);
                    fprintf(stderr, "[STATUS] cyc=%llu PC=0x%08X ev=%d ic=%d ec=%d il=%d rx=%d st=%d sic=%d tp=0x%X tbl=0x%X\n",
                        total_cycles, cur_pc, tty_ev, tty_ic, tty_ec, tty_il, rxcnt, stored, storedic, tp_ptr, tty_base);
                }
                /* Dump tty_table[0] offsets 0-160 to map struct layout */
                if (total_cycles < 100000000) {
                    fprintf(stderr, "[TTY-DUMP0]");
                    for (int k = 0; k < 80; k += 4)
                        fprintf(stderr, " %d:%08X", k, m68k_read_memory_32(tty_base + k));
                    fprintf(stderr, "\n[TTY-DUMP1]");
                    for (int k = 80; k < 160; k += 4)
                        fprintf(stderr, " %d:%08X", k, m68k_read_memory_32(tty_base + k));
                    fprintf(stderr, "\n");
                }
                last_status = total_cycles;
              }
            }
#endif
            if (verbose && total_cycles - last_report > 16000000) {
                unsigned int pc = m68k_get_reg(NULL, M68K_REG_PC);
                fprintf(stderr, "[%llu] PC=0x%08X", total_cycles, pc);
                if (ioboard.loaded) {
                    /* Must switch context to read IO board registers */
                    void *save = calloc(1, m68k_context_size());
                    m68k_get_context(save);
                    m68k_set_context(ioboard.cpu_ctx);
                    unsigned int io_pc = m68k_get_reg(NULL, M68K_REG_PC);
                    m68k_set_context(save);
                    free(save);
                    fprintf(stderr, " IO=0x%04X", io_pc & 0xFFFFFF);
                }
                fprintf(stderr, "\n");
                last_report = total_cycles;
            }
        }
    }

#ifdef ENABLE_VERA_SDL
quit:
    if (sdl_texture) SDL_DestroyTexture(sdl_texture);
    if (sdl_renderer) SDL_DestroyRenderer(sdl_renderer);
    if (sdl_window) SDL_DestroyWindow(sdl_window);
    SDL_Quit();
#endif
    return 0;
}

/* Detect infinite loop (panic) and dump PC history */
static unsigned int prev_pc_for_loop = 0;
static int same_pc_count = 0;

void check_stuck(void) {
    unsigned int pc = m68k_get_reg(NULL, M68K_REG_PC);
    if (pc == prev_pc_for_loop) {
        same_pc_count++;
        if (same_pc_count == 100) {
            fprintf(stderr, "\n=== STUCK at PC=0x%08X, dumping last 64 PCs ===\n", pc);
            /* Dump PC history with symbol lookup from nm */
            for (int i = 4095; i >= 0; i--) {
                int idx = (pc_hist_idx - 1 - i) & 4095;
                fprintf(stderr, "  PC[-%02d] = 0x%08X\n", i, pc_history[idx]);
            }
            fprintf(stderr, "=== END TRACE ===\n");
            _exit(1);
        }
    } else {
        prev_pc_for_loop = pc;
        same_pc_count = 0;
    }
}

void trap_debug(int t, unsigned v, unsigned vbr, unsigned sp) {
    static FILE *f = NULL;
    if (!f) f = fopen("/tmp/trap_log.txt", "w");
    if (f) {
        unsigned addr = (v<<2)+vbr;
        unsigned val = m68k_read_memory_32(addr);
        fprintf(f, "[TRAP#%d] vec=%u VBR=%08X addr=%08X -> %08X SP=%08X\n",
            t, v, vbr, addr, val, sp);
        fflush(f);
    }
}
