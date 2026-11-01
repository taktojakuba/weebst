/* See LICENSE file for copyright and license details. */

/* Appearance */
#define DEFAULTFONTSIZE 13

static int borderpx = 0;

/* Shell */
static char *shell = "/usr/bin/bash";
char *utmp = NULL;
char *scroll = NULL;
char *stty_args = "stty raw pass8 nl -echo -iexten -cstopb 38400";

/* Identification sequence returned in DA and DECID */
char *vtiden = "\033[?6c";

/* Kerning / character bounding-box multipliers */
static float cwscale = 1.0;
static float chscale = 1.0;

/* Word delimiters */
wchar_t *worddelimiters = L" │┃|:`'\"()[]{}┃";
wchar_t *snap_line_delimiters = L"│┃";

/* Selection timeouts (ms) */
static unsigned int doubleclicktimeout = 300;
static unsigned int tripleclicktimeout = 600;

/* Alt screens */
int allowaltscreen = 0;

/* Key repeat timeouts (ms) */
static unsigned int keyrepeatdelay = 500;
static unsigned int keyrepeatinterval = 25;

/* Allow non-interactive window operations such as setting the clipboard */
int allowwindowops = 1;

/* Draw latency range (ms) */
static double minlatency = 2;
static double maxlatency = 33;

/* Synchronized-update timeout (ms) */
static uint su_timeout = 200;

/* Blinking timeout (0 disables blinking) */
static unsigned int blinktimeout = 100;

/* Thickness of underline and bar cursors */
static unsigned int cursorthickness = 2;

/* Default TERM value */
char *termname = "weebst";

/* Default class */
char *termclass = "terminal";

/* Spaces per tab */
unsigned int tabspaces = 8;

/* Alpha defaults (the alpha patch is disabled; kept for the man page) */
#define DEFAULT_ALPHA 1.0
float alpha = DEFAULT_ALPHA;
uint8_t term_alpha = (uint8_t)(DEFAULT_ALPHA * 255.0);
float alphaUnfocused = 1.0;
int unfocusedpanebg = 0x0a0a0a;

/* Terminal colors (16 first used in escape sequence) */
static const char *colorname[] = {
    /* normal */
    [0] = "#1e1e1e",
    [1] = "#6b6b6b",
    [2] = "#8f8f8f",
    [3] = "#b3b3b3",
    [4] = "#5a5a5a",
    [5] = "#7d7d7d",
    [6] = "#696969",
    [7] = "#c9c9c9",

    /* bright */
    [8] = "#3f3f3f",
    [9] = "#8c8c8c",
    [10] = "#a8a8a8",
    [11] = "#d0d0d0",
    [12] = "#767676",
    [13] = "#9c9c9c",
    [14] = "#848484",
    [15] = "#f0f0f0",

    [255] = 0,

    /* extra colors */
    "#f0f0f0", /* cursor */
    "#3f3f3f", /* reverse cursor */
    "#121212", /* background */
    "#d6d6d6", /* foreground */
};

/* Default colors: background, foreground, cursor, reverse cursor */
unsigned int defaultbg = 258;
unsigned int defaultfg = 259;
unsigned int defaultcs = 256;
unsigned int defaultrcs = 257;

/* Selection colors */
unsigned int selectionfg = 258;
unsigned int selectionbg = 259;

/* Cursor style: 0-1 blinking block, 2 steady block, 3-4 underline, 5-6 bar */
static unsigned int cursorstyle = 1;
static Rune stcursor = 0x2603;

/* Default columns and rows */
static unsigned int cols = 140;
static unsigned int rows = 40;

/* Default mouse cursor shape */
static char *mouseshape = "xterm";

/* Color used for font attributes when fontconfig falls back */
static unsigned int defaultattr = 11;

/* Scrollwheel shortcuts */
static Axiskey ashortcuts[] = {
    {MOD_MASK_SHIFT, AXIS_VERTICAL, +1, ttysend, {.s = "\033[5;2~"}},
    {MOD_MASK_SHIFT, AXIS_VERTICAL, -1, ttysend, {.s = "\033[6;2~"}},
    {MOD_MASK_ANY, AXIS_VERTICAL, +1, ttysend, {.s = "\031"}},
    {MOD_MASK_ANY, AXIS_VERTICAL, -1, ttysend, {.s = "\005"}},
};

/* Internal keyboard shortcuts */
#define MODKEY MOD_MASK_ALT
#define TERMMOD (MOD_MASK_CTRL | MOD_MASK_SHIFT)

static Shortcut shortcuts[] = {
    {MOD_MASK_ANY, XKB_KEY_Break, sendbreak, {.i = 0}},
    {MOD_MASK_CTRL, XKB_KEY_Print, toggleprinter, {.i = 0}},
    {MOD_MASK_SHIFT, XKB_KEY_Print, printscreen, {.i = 0}},
    {MOD_MASK_ANY, XKB_KEY_Print, printsel, {.i = 0}},
    {TERMMOD, XKB_KEY_Prior, zoom, {.f = +1}},
    {TERMMOD, XKB_KEY_Next, zoom, {.f = -1}},
    {TERMMOD, XKB_KEY_Home, zoomreset, {.f = 0}},
    {TERMMOD, XKB_KEY_C, clipcopy, {.i = 0}},
    {TERMMOD, XKB_KEY_V, clippaste, {.i = 0}},
    {MOD_MASK_NONE, XKB_KEY_F11, fullscreen, {.i = 0}},
    {TERMMOD, XKB_KEY_Y, clippaste, {.i = 0}},
    {MOD_MASK_SHIFT, XKB_KEY_Insert, clippaste, {.i = 0}},
    {MOD_MASK_CTRL, XKB_KEY_Insert, clipcopy, {.i = 0}},
    {TERMMOD, XKB_KEY_Num_Lock, numlock, {.i = 0}},
};

/* State bits to ignore when matching key or button events */
static uint ignoremod = 0;

/* Override mouse-select while mask is active (MODE_MOUSE) */
static uint forceselmod = MOD_MASK_SHIFT;

/* Selection types' masks */
static uint selmasks[] = {
    [SEL_RECTANGULAR] = MOD_MASK_ALT,
};

/* Printable ASCII, used to estimate the advance width of wide characters */
static char ascii_printable[] = " !\"#$%&'()*+,-./0123456789:;<=>?"
                                "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_"
                                "`abcdefghijklmnopqrstuvwxyz{|}~";
