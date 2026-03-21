/*
 * demon_agfa.c -- Demon Attack for Agfa 9000PS bare metal (68020 @ 16MHz)
 *
 * Adapted from demon_sysv.c (K&R C, VT100 output).
 * All Unix dependencies replaced with direct Z8530 SCC hardware access.
 * Runs on Channel A (TxDA pin 15) at 9600 8N2.
 *
 * Build: make (see Makefile)
 * Load:  S-record upload via Atlas Monitor, or burn into ROM bank 0.
 */

/* ---- Hardware I/O (provided by crt0.S) ---- */
extern scc_putc();
extern scc_getc();
extern scc_poll();     /* returns char+1 if available, 0 if not */
extern scc_puts();
extern delay_ms();

/* ---- Minimal libc replacements ---- */

static int
strlen(s)
    char *s;
{
    int n;
    n = 0;
    while (s[n]) n++;
    return n;
}

static char *
memset(s, c, n)
    char *s;
    int c, n;
{
    int i;
    for (i = 0; i < n; i++)
        s[i] = c;
    return s;
}

static char *
memcpy(d, s, n)
    char *d;
    char *s;
    int n;
{
    int i;
    for (i = 0; i < n; i++)
        d[i] = s[i];
    return d;
}

/* Integer to decimal string, right-justified with leading zeros */
static void
itoa_pad(buf, val, width)
    char *buf;
    int val, width;
{
    int i;
    if (val < 0) val = 0;
    for (i = width - 1; i >= 0; i--)
    {
        buf[i] = '0' + (val % 10);
        val /= 10;
    }
    buf[width] = 0;
}

/* Simple sprintf replacement -- supports %d and %0Nd only */
static void
fmt_str(buf, fmt, val)
    char *buf;
    char *fmt;
    int val;
{
    char *p;
    char tmp[12];
    int w, i, len;

    p = buf;
    while (*fmt)
    {
        if (*fmt == '%')
        {
            fmt++;
            w = 0;
            if (*fmt == '0') fmt++;
            while (*fmt >= '0' && *fmt <= '9')
                w = w * 10 + (*fmt++ - '0');
            if (*fmt == 'd')
            {
                fmt++;
                if (w == 0) w = 1;
                itoa_pad(tmp, val, w);
                len = strlen(tmp);
                for (i = 0; i < len; i++)
                    *p++ = tmp[i];
            }
        }
        else
        {
            *p++ = *fmt++;
        }
    }
    *p = 0;
}

/* ---- ROM tables (from demon_sysv.c) ---- */

static int shot_speed[] = { 3, 4, 5, 5, 6, 6 };
static int action_max[] = { 8, 6, 6, 3, 5, 4, 5, 4, 5, 4, 5, 4 };
static unsigned char wave_tab[] = { 0x80, 0xC0, 0xA0, 0xE0, 0xB0, 0xF0 };
static unsigned char vert_mot[] = { 0x40, 0x80, 0xC0, 0xF0, 0xF0, 0xC0, 0x80, 0x40 };
static unsigned char horiz_mot[] = { 0xFF, 0xC0, 0xA0, 0x80, 0x80, 0xA0, 0xC0, 0xFF };
static unsigned char score_tab[] = { 0x10, 0x15, 0x20, 0x25, 0x30, 0x35 };

#define W 160
#define H 192
#define COLS 80
#define ROWS 24

/* Screen buffers */
static char cur[ROWS][COLS];
static char prev[ROWS][COLS];
static char outbuf[2048];
static int outlen;

/* Game state */
static int player_x, lives, score, level, frame, mode;
static int ship_expl;
static int shot_active, shot_x, shot_y;
static int enemy_x[3], enemy_y[3], enemy_alive[3];
static int enemy_dir[3], enemy_vdir[3], enemy_anim[3];
static unsigned enemy_ha[3], enemy_va[3];
static int enemy_actr[3];
static int eshot_act[3], eshot_x[3], eshot_y[3];
static int sdemon_act, sdemon_x, sdemon_y, sdemon_dir;
static unsigned sdemon_ha;
static unsigned char rng;

/* ---- Output buffering ---- */

static void
flush_out()
{
    int i;
    for (i = 0; i < outlen; i++)
        scc_putc(outbuf[i]);
    outlen = 0;
}

static void
emit(s, n)
    char *s;
    int n;
{
    if (outlen + n > sizeof(outbuf))
        flush_out();
    memcpy(outbuf + outlen, s, n);
    outlen += n;
}

static void
emits(s)
    char *s;
{
    emit(s, strlen(s));
}

static void
beep()
{
    scc_putc(7);
}

/* ---- Screen drawing ---- */

static void
put(x, y, ch)
    int x, y;
    char ch;
{
    if (x >= 0 && x < COLS && y >= 0 && y < ROWS)
        cur[y][x] = ch;
}

static void
puts_at(x, y, s)
    int x, y;
    char *s;
{
    while (*s)
        put(x++, y, *s++);
}

static void
putf(x, y, fmt, val)
    int x, y, val;
    char *fmt;
{
    char buf[80];
    fmt_str(buf, fmt, val);
    puts_at(x, y, buf);
}

static void
clear_scr()
{
    int y, x;
    for (y = 0; y < ROWS; y++)
        for (x = 0; x < COLS; x++)
            cur[y][x] = ' ';
}

/* Differential refresh — only send changed characters */
static void
refresh()
{
    int x, y, lx, ly;
    char buf[16];
    int n;
    lx = ly = -1;

    for (y = 0; y < ROWS; y++)
        for (x = 0; x < COLS; x++)
        {
            if (cur[y][x] == prev[y][x])
                continue;
            if (ly != y || lx != x)
            {
                /* Build cursor-position escape: ESC[row;colH */
                buf[0] = 27;
                buf[1] = '[';
                n = 2;
                /* Row (y+1) */
                if (y + 1 >= 10)
                    buf[n++] = '0' + ((y + 1) / 10);
                buf[n++] = '0' + ((y + 1) % 10);
                buf[n++] = ';';
                /* Col (x+1) */
                if (x + 1 >= 10)
                    buf[n++] = '0' + ((x + 1) / 10);
                buf[n++] = '0' + ((x + 1) % 10);
                buf[n++] = 'H';
                emit(buf, n);
            }
            emit(&cur[y][x], 1);
            lx = x + 1;
            ly = y;
            prev[y][x] = cur[y][x];
        }
    flush_out();
}

/* ---- Input ---- */

static int
getkey()
{
    int c, r;
    r = scc_poll();
    if (r == 0) return 0;
    c = r - 1;     /* scc_poll returns char+1 */
    if (c == 27)
    {
        /* Try to read escape sequence */
        delay_ms(20);
        r = scc_poll();
        if (r == 0) return 27;
        r = scc_poll();
        if (r == 0) return 27;
        c = r - 1;
        if (c == 'A') return 256;  /* up */
        if (c == 'B') return 257;  /* down */
        if (c == 'C') return 259;  /* right */
        if (c == 'D') return 258;  /* left */
        return 27;
    }
    return c & 0x7F;
}

/* ---- Game logic (from demon_sysv.c, unchanged) ---- */

static unsigned char
next_rng(r)
    unsigned char r;
{
    unsigned char fb;
    fb = ((r << 1) ^ r) & 0x80;
    return (r << 1) | (fb >> 7);
}

static int
myabs(x)
    int x;
{
    return x < 0 ? -x : x;
}

static void
wave_init()
{
    int i, vs;
    vs = 44 - 2 * level;
    if (vs < 15) vs = 15;
    for (i = 0; i < 3; i++)
    {
        enemy_x[i] = 73 + i * 13;
        enemy_y[i] = 20 + i * vs;
        enemy_alive[i] = 1;
        enemy_dir[i] = (i & 1) ? -1 : 1;
        enemy_vdir[i] = 1;
        enemy_anim[i] = 0;
        eshot_act[i] = 0;
        enemy_ha[i] = enemy_va[i] = 0;
        enemy_actr[i] = 0;
    }
    sdemon_act = shot_active = 0;
    sdemon_ha = 0;
}

static void
game_init()
{
    memset(cur, ' ', sizeof(cur));
    memset(prev, ' ', sizeof(prev));
    lives = 3; player_x = 80; rng = 0xA5; mode = 0;
    score = 0; level = 0; frame = 0;
}

static void
start_game()
{
    score = 0; lives = 3; level = 0;
    mode = 1; player_x = 80; ship_expl = 0;
    wave_init();
}

static void
tick(jl, jr, fire)
    int jl, jr, fire;
{
    int i, wt, midx, pts, si, old;

    frame++;
    rng = next_rng(rng);
    if (mode != 1) return;

    /* Ship explosion */
    if (ship_expl > 0)
    {
        ship_expl--;
        if (ship_expl == 0)
        {
            lives--;
            if (lives <= 0) { mode = 2; return; }
            player_x = 80;
        }
        return;
    }

    /* Player movement */
    if (jl && player_x > 16) player_x -= 2;
    if (jr && player_x < 140) player_x += 2;

    /* Fire */
    if (fire && !shot_active)
    {
        shot_active = 1;
        shot_x = player_x + 4;
        shot_y = 3;
        beep();
    }

    wt = wave_tab[(level / 2) % 6];

    /* Shot movement */
    if (shot_active)
    {
        si = level / 2;
        if (si > 5) si = 5;
        shot_y += shot_speed[si];
        if (shot_y >= 160) shot_active = 0;
    }

    /* Enemy movement */
    for (i = 0; i < 3; i++)
    {
        if (!enemy_alive[i]) continue;
        midx = (frame + i * 3) & 7;

        enemy_ha[i] += horiz_mot[midx];
        if (enemy_ha[i] & 0x100)
        {
            enemy_x[i] += enemy_dir[i];
            enemy_ha[i] &= 0xFF;
            if (i == 2 && (wt & 0x10))
                enemy_x[i] += (player_x > enemy_x[i]) ? 1 : -1;
        }
        if (enemy_x[i] < 73) { enemy_x[i] = 73; enemy_dir[i] = 1; }
        if (enemy_x[i] > 113) { enemy_x[i] = 113; enemy_dir[i] = -1; }

        enemy_va[i] += vert_mot[midx];
        if (enemy_va[i] & 0x100)
        {
            enemy_y[i] += enemy_vdir[i];
            enemy_va[i] &= 0xFF;
        }
        if (enemy_y[i] > 150) { enemy_y[i] = 150; enemy_vdir[i] = -1; }
        if (enemy_y[i] < 15) { enemy_y[i] = 15; enemy_vdir[i] = 1; }

        if ((frame & 7) == 0)
            enemy_anim[i] = (enemy_anim[i] + 1) % 3;

        /* Enemy shoots */
        if ((wt & 0x40) && !eshot_act[i])
        {
            enemy_actr[i]++;
            if (enemy_actr[i] >= action_max[level % 12])
            {
                enemy_actr[i] = 0;
                if ((rng & 3) == 0)
                {
                    eshot_act[i] = 1;
                    eshot_x[i] = enemy_x[i] + 3;
                    eshot_y[i] = enemy_y[i] + 6;
                }
            }
        }
    }

    /* Enemy shots */
    for (i = 0; i < 3; i++)
    {
        if (!eshot_act[i]) continue;
        eshot_y[i] += 2;
        if (eshot_y[i] > H) eshot_act[i] = 0;
    }

    /* Small demon */
    if (sdemon_act)
    {
        midx = (frame * 2) & 7;
        sdemon_ha += horiz_mot[midx] * 2;
        if (sdemon_ha & 0xFF00) { sdemon_x += sdemon_dir; sdemon_ha &= 0xFF; }
        sdemon_y++;
        if (sdemon_x < 5 || sdemon_x > W - 10) sdemon_dir *= -1;
        if (sdemon_y > H - 20) sdemon_act = 0;
    }

    /* Collision: shot vs enemy */
    if (shot_active)
        for (i = 0; i < 3; i++)
        {
            if (!enemy_alive[i]) continue;
            if (myabs(shot_x - enemy_x[i]) < 8 && myabs(shot_y - enemy_y[i]) < 8)
            {
                enemy_alive[i] = 0;
                shot_active = 0;
                si = (level / 2) % 6;
                pts = ((score_tab[si] >> 4) * 10) + (score_tab[si] & 0xF);
                old = score; score += pts;
                if (score / 10000 > old / 10000 && lives < 6)
                    { lives++; beep(); beep(); beep(); }
                else
                    { beep(); beep(); }
                if ((wt & 0x20) && !sdemon_act)
                {
                    sdemon_act = 1;
                    sdemon_x = enemy_x[i];
                    sdemon_y = enemy_y[i];
                    sdemon_dir = 1;
                    sdemon_ha = 0;
                }
                break;
            }
        }

    /* Shot vs small demon */
    if (shot_active && sdemon_act)
        if (myabs(shot_x - sdemon_x) < 6 && myabs(shot_y - sdemon_y) < 6)
            { sdemon_act = 0; shot_active = 0; score += 50; }

    /* Enemy shots vs player */
    if (ship_expl == 0)
    {
        for (i = 0; i < 3; i++)
            if (eshot_act[i] && myabs(eshot_x[i] - player_x) < 8
                && myabs(eshot_y[i] - (H - 16)) < 6)
                { ship_expl = 0x40; eshot_act[i] = 0; }
        if (sdemon_act && myabs(sdemon_x - player_x) < 8
            && myabs(sdemon_y - (H - 16)) < 8)
            { ship_expl = 0x40; sdemon_act = 0; }
    }

    /* Wave complete */
    {
        int dead;
        dead = 1;
        for (i = 0; i < 3; i++)
            if (enemy_alive[i]) dead = 0;
        if (sdemon_act) dead = 0;
        if (dead) { level++; wave_init(); }
    }
}

/* ---- Rendering ---- */

static int
gx(x)
    int x;
{ return x * COLS / W; }

static int
gy(y)
    int y;
{ return 1 + y * (ROWS - 2) / H; }

static int
gy_inv(y)
    int y;
{ return 1 + (H - y) * (ROWS - 2) / H; }

static void
render()
{
    int i, sx, sy, f, ground_y, ss;
    /* Shape table indices: 6 enemy types x 3 animation frames */
    /* Each shape is 4 chars wide */
    static char shapes[18][5];
    static int shapes_init = 0;

    if (!shapes_init)
    {
        /* Initialize shape strings (can't use string literal arrays in K&R easily) */
        memcpy(shapes[0],  "/\\/\\", 5);
        memcpy(shapes[1],  "/  \\", 5);
        memcpy(shapes[2],  "\\/\\/", 5);
        memcpy(shapes[3],  "<-->", 5);
        memcpy(shapes[4],  ">  <", 5);
        memcpy(shapes[5],  "<-->", 5);
        memcpy(shapes[6],  "*--*", 5);
        memcpy(shapes[7],  "*  *", 5);
        memcpy(shapes[8],  "*--*", 5);
        memcpy(shapes[9],  "{==}", 5);
        memcpy(shapes[10], "{  }", 5);
        memcpy(shapes[11], "{==}", 5);
        memcpy(shapes[12], "@/\\@", 5);
        memcpy(shapes[13], "@  @", 5);
        memcpy(shapes[14], "@\\/@", 5);
        memcpy(shapes[15], "#/\\#", 5);
        memcpy(shapes[16], "#  #", 5);
        memcpy(shapes[17], "#\\/#", 5);
        shapes_init = 1;
    }

    clear_scr();
    putf(1, 0, "SCORE:%06d", score);
    putf(COLS / 2 - 3, 0, "WAVE:%d", level + 1);
    putf(COLS - 10, 0, "LIVES:%d", lives);

    if (mode == 0)
    {
        puts_at(COLS/2 - 10, ROWS/2 - 4, "=== DEMON ATTACK ===");
        puts_at(COLS/2 - 14, ROWS/2 - 2, "Agfa Compugraphic 9000PS Edition");
        puts_at(COLS/2 - 10, ROWS/2, "PRESS ENTER TO START");
        puts_at(COLS/2 - 13, ROWS/2 + 2, "A/D:Move  Space:Fire  Esc:Quit");
        puts_at(COLS/2 - 14, ROWS/2 + 4, "Arrow keys also work (VT100 mode)");
        return;
    }
    if (mode == 2)
    {
        puts_at(COLS/2 - 5, ROWS/2, "GAME  OVER");
        putf(COLS/2 - 7, ROWS/2 + 2, "SCORE: %06d", score);
        puts_at(COLS/2 - 11, ROWS/2 + 4, "PRESS ENTER TO RESTART");
        return;
    }

    /* Ground */
    ground_y = gy(H - 8);
    for (i = 0; i < COLS; i++) put(i, ground_y, '=');

    /* Enemies */
    ss = (level / 2) % 6;
    for (i = 0; i < 3; i++)
    {
        if (!enemy_alive[i]) continue;
        f = enemy_anim[i] % 3;
        puts_at(gx(enemy_x[i]), gy(enemy_y[i]), shapes[ss * 3 + f]);
    }

    /* Small demon */
    if (sdemon_act)
        puts_at(gx(sdemon_x), gy(sdemon_y), "<>");

    /* Player ship */
    sx = gx(player_x);
    sy = gy(H - 16);
    if (ship_expl > 0)
        puts_at(sx, sy, "***");
    else
    {
        puts_at(sx, sy - 1, " /\\ ");
        puts_at(sx, sy,     "/  \\");
        puts_at(sx, sy + 1, "====");
    }

    /* Player shot */
    if (shot_active)
    {
        sx = gx(shot_x);
        sy = gy_inv(shot_y);
        if (sy >= 1 && sy < ROWS - 1) put(sx, sy, '|');
        if (sy - 1 >= 1) put(sx, sy - 1, '|');
    }

    /* Enemy shots */
    for (i = 0; i < 3; i++)
    {
        if (!eshot_act[i]) continue;
        sx = gx(eshot_x[i]);
        sy = gy(eshot_y[i]);
        if (sy >= 1 && sy < ROWS - 1)
        {
            put(sx, sy, 'V');
            if (sx > 0) put(sx - 1, sy, '\\');
            if (sx + 1 < COLS) put(sx + 1, sy, '/');
        }
        if (sy - 1 >= 1) put(sx, sy - 1, '|');
    }
}

/* ---- Main loop ---- */

main()
{
    int key, jl, jr, jf, tk, running;

    game_init();
    jl = jr = jf = 0;
    running = 1;

    while (running)
    {
        /* Run game ticks, polling input */
        for (tk = 0; tk < 15; tk++)
        {
            key = getkey();
            if (key)
                switch (key)
                {
                case 27: running = 0; break;
                case 'a': case 'A': case 258: jl = 6; jr = 0; break;
                case 'd': case 'D': case 259: jr = 6; jl = 0; break;
                case ' ': jf = 3; break;
                case 13: case 10:
                    if (mode != 1) start_game();
                    jf = 3;
                    break;
                }

            tick(jl > 0, jr > 0, jf > 0);

            if (jl > 0) jl--;
            if (jr > 0) jr--;
            if (jf > 0) jf--;
        }

        render();
        refresh();

        /* Frame pacing: ~250ms per display frame = ~4 fps */
        delay_ms(250);
    }

    /* Restore terminal */
    scc_puts("\033[?25h\033[0m\033[2J\033[H");
    scc_puts("Demon Attack ended. System halted.\r\n");

    for (;;)
        ;  /* halt */
}
