/*
   emu5110
	-------
  Based on:
	An emulator for the IBM 5110
	(C) 2007-2008 Christian Corti

  Adapted to Wintel (using winpthread and pdcurses) by Steve Lewis - 2022
  (this file was previously display_x11.c where it used the X11 GUI interface)
	
  Display (pdcurses version)
*/

#include <stdio.h>
//#include <X11/Xlib.h>
//#include <X11/Xutil.h>
#include <curses.h>
#include <stdio.h>
#include "emu.h"

#define WIN_TITLE "IBM 5110 emulator"
#define WIN_NAME "display"
#define WIN_CLASS "emu5110"
#define WIN_WIDTH (64*10)
#define WIN_HEIGHT (16*24)

// The bottom portion of the display defaults to showing the portion of RWS mapped to the display.  This can be adjusted using the {, } keys after startup.
long int rws_start_address_to_display = 0x0200;

// The 5100/5110/5120 system has a concept of "key compositions" where when certain keys are entered "on top of each other", they get converted
// into something else.  One example is entering the "!" symbol, which is "'" overwritten by "." (it can actually be done in either order).
// There are likely more sequences (especially for APL), and so this design below is prepared to expand to more compositions.   For now, sequences
// up to 3 characters are supported - we're not yet sure if there are longer sequences, but if so, they could also be supported with minor changes.
#define MAX_SEQUENCE_COMPOSITION_INDEX 3
char sequence_composition[2][3] = {
  { '\'', 4, '.' },   // "!"
  { 0   , 0, 0   }
};
// The following two variables are used to signal when a composition is being specified.   "sequence_composer" of 0 means no
// sequence, but when >0 when the sequence to be composed is sequence_composer-1.   The sequence proceeds until the composer_index
// reaches the MAX_SEQUENCE_COMPOSITION_INDEX.
unsigned int sequence_composer = 0;
unsigned int sequence_composer_index = 0;

#ifdef SUN_KBD
/* keyboard codes for SUN Type 4 keyboard */
#define MAX_KEYCODE 143
static unsigned char scancodes_normal[] =
{
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	/* 00 */
	0x36,	0x00,	0x00,	0x00,	0x34,	0xB4,	0x00,	0x00,	/* 08 */
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00, /* 16 */
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00, /* 24 */
	0x00,	0x00,	0x00,	0x00,	0xB6,	0x4D,	0x0F,	0xCF, /* 32 */
	0xAF,	0x2F,	0xEF,	0x6F,	0x7F,	0xFF,	0x8F,	0x3F, /* 40 */
	0xBF,	0x30,	0x00,	0x00,	0x00,	0x9F,	0x9D,	0x00, /* 48 */
	0x00,	0x19,	0x00,	0x00,	0x00,	0x0D,	0xCD,	0xAD, /* 56 */
	0x2D,	0xED,	0x6D,	0x7D,	0xFD,	0x8D,	0x3D,	0xBD, /* 64 */
	0x32,	0x00,	0x00,	0x5F,	0xDD,	0x1F,	0x9B,	0x34, /* 72 */
	0xB4,	0x00,	0x00,	0x00,	0x0B,	0xCB,	0xAB,	0x2B, /* 80 */
	0xEB,	0x6B,	0x7B,	0xFB,	0x8B,	0x3B,	0xBB,	0x4B, /* 88 */
	0xB2,	0x00,	0x5D,	0xDB,	0x1D,	0x59,	0xDF,	0x00, /* 96 */
	0x4F,	0x00,	0x00,	0x09,	0xC9,	0xA9,	0x29,	0xE9, /* 104 */
	0x69,	0x79,	0xF9,	0x89,	0xB9,	0x00,	0x00,	0x5B, /* 112 */
	0xD9,	0x1B,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00, /* 120 */
	0x39,	0x00,	0x00,	0x00,	0x99,	0x00,	0x00,	0x00, /* 128 */
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00, /* 136 */
};
static unsigned char scancodes_shift[] =
{
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	/* 00 */
	0x76,	0x00,	0x00,	0x00,	0x74,	0xF4,	0x00,	0x00,	/* 08 */
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00, /* 16 */
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00, /* 24 */
	0x00,	0x00,	0x00,	0x00,	0xF6,	0x4C,	0x0E,	0xCE, /* 32 */
	0xAE,	0x2E,	0xEE,	0x6E,	0x7E,	0xFE,	0x8E,	0x3E, /* 40 */
	0xBE,	0x70,	0x00,	0x00,	0x00,	0x9E,	0x9C,	0x00, /* 48 */
	0x00,	0x18,	0x00,	0x00,	0x00,	0x0C,	0xCC,	0xAC, /* 56 */
	0x2C,	0xEC,	0x6C,	0x7C,	0xFC,	0x8C,	0x3C,	0xBC, /* 64 */
	0xF2,	0x00,	0x00,	0x5E,	0xDC,	0x1E,	0x9A,	0x74, /* 72 */
	0xF4,	0x00,	0x00,	0x00,	0x0A,	0xCA,	0xAA,	0x2A, /* 80 */
	0xEA,	0x6A,	0x7A,	0xFA,	0x8A,	0x3A,	0xBA,	0x4A, /* 88 */
	0xF2,	0x00,	0x5C,	0xDA,	0x1C,	0x58,	0xDE,	0x00, /* 96 */
	0x4E,	0x00,	0x00,	0x08,	0xC8,	0xA8,	0x28,	0xE8, /* 104 */
	0x68,	0x78,	0xF8,	0x88,	0xB8,	0x00,	0x00,	0x5A, /* 112 */
	0xD8,	0x1A,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00, /* 120 */
	0x38,	0x00,	0x00,	0x00,	0x98,	0x00,	0x00,	0x00, /* 128 */
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00, /* 136 */
};
static unsigned char scancodes_cmd[] =
{
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	/* 00 */
	0x16,	0x00,	0x00,	0x00,	0x14,	0x94,	0x00,	0x00,	/* 08 */
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00, /* 16 */
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00, /* 24 */
	0x00,	0x00,	0x00,	0x00,	0x96,	0x45,	0x07,	0xC7, /* 32 */
	0xA7,	0x27,	0xE7,	0x67,	0x77,	0xF7,	0x87,	0x37, /* 40 */
	0xB7,	0x10,	0x00,	0x00,	0x00,	0x97,	0x95,	0x00, /* 48 */
	0x00,	0x11,	0x00,	0x00,	0x00,	0x05,	0xC5,	0xA5, /* 56 */
	0x25,	0xE5,	0x65,	0x75,	0xF5,	0x85,	0x35,	0xB5, /* 64 */
	0x12,	0x00,	0x00,	0x57,	0xD5,	0x17,	0x93,	0x14, /* 72 */
	0x94,	0x00,	0x00,	0x00,	0x03,	0xC3,	0xA3,	0x23, /* 80 */
	0xE3,	0x63,	0x73,	0xF3,	0x83,	0x33,	0xB3,	0x43, /* 88 */
	0x92,	0x00,	0x55,	0xD3,	0x15,	0x51,	0xD7,	0x00, /* 96 */
	0x47,	0x00,	0x00,	0x01,	0xC1,	0xA1,	0x21,	0xE1, /* 104 */
	0x61,	0x71,	0xF1,	0x81,	0xB1,	0x00,	0x00,	0x53, /* 112 */
	0xD1,	0x13,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00, /* 120 */
	0x31,	0x00,	0x00,	0x00,	0x91,	0x00,	0x00,	0x00, /* 128 */
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00, /* 136 */
};

#else

/* Keyboard codes for PC MF-10[1245] keyboard */
#define MAX_KEYCODE 127
// When translating keys, we use an INDEX from 0 to 255.  For now only up to 128 keys
// are actually used.  These map to the scancodes directly described in the IBM 5110
// MIM 2-36 (e.g 0x4D is index 10, which maps to "1", or 0x4C if shift is pressed ("), or 0x45 is CMD is pressed).
// translate_sequence is used to map IBM PC ASCII keycodes over into IBM 5110 scancodes.  In the docs folder
// is a list of which index maps to which scancode.
static unsigned char scancodes_normal[128] =
{
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	/* 00 */
	0x00,	0xB6,	0x4D,	0x0F,	0xCF,	0xAF,	0x2F,	0xEF,	/* 08 */
	0x6F,	0x7F,	0xFF,	0x8F,	0x3F,	0xBF,	0x00,	0x00,	/* 16 */
	0x0D,	0xCD,	0xAD,	0x2D,	0xED,	0x6D,	0x7D,	0xFD,	/* 24 */
	0x8D,	0x3D,	0xBD,	0x32,	0xB2,	0x00,	0x0B,	0xCB,	/* 32 */
	0xAB,	0x2B,	0xEB,	0x6B,	0x7B,	0xFB,	0x8B,	0x3B,	/* 40 */
	0xBB,	0x00,	0x00,	0x30,	0x09,	0xC9,	0xA9,	0x29,	/* 48 */
	0xE9,	0x69,	0x79,	0xF9,	0x89,	0xB9,	0x00,	0x9D,	/* 56 */
	0x00,	0x39,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	/* 64 */
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x5F,	/* 72 */
	0xDD,	0x1F,	0x9B,	0x5D,	0xDB,	0x1D,	0x99,	0x5B,	/* 80 */
	0xD9,	0x1B,	0x59,	0x19,	0x00,	0x00,	0x4B,	0x00,	/* 88 */
	0x00,	0x00,	0xDF,	0x00,	0x34,	0x00,	0xB4,	0x00,	/* 96 */
	0x4F,	0x00,	0x00,	0x00,	0x00,	0x00,	0x36,	0x00,	/* 104 */
	0x9F,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	/* 112 */
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	/* 120 */
};
static unsigned char scancodes_shift[128] =
{
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	/* 00 */
	0x00,	0xF6,	0x4C,	0x0E,	0xCE,	0xAE,	0x2E,	0xEE,	/* 08 */
	0x6E,	0x7E,	0xFE,	0x8E,	0x3E,	0xBE,	0x00,	0x00,	/* 16 */
	0x0C,	0xCC,	0xAC,	0x2C,	0xEC,	0x6C,	0x7C,	0xFC,	/* 24 */
	0x8C,	0x3C,	0xBC,	0x72,	0xF2,	0x00,	0x0A,	0xCA,	/* 32 */
	0xAA,	0x2A,	0xEA,	0x6A,	0x7A,	0xFA,	0x8A,	0x3A,	/* 40 */
	0xBA,	0x00,	0x00,	0x70,	0x08,	0xC8,	0xA8,	0x28,	/* 48 */
	0xE8,	0x68,	0x78,	0xF8,	0x88,	0xB8,	0x00,	0x9C,	/* 56 */
	0x00,	0x38,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	/* 64 */
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x5E,	/* 72 */
	0xDC,	0x1E,	0x9A,	0x5C,	0xDA,	0x1C,	0x98,	0x5A,	/* 80 */
	0xD8,	0x1A,	0x58,	0x18,	0x00,	0x00,	0x4A,	0x00,	/* 88 */
	0x00,	0x00,	0xDE,	0x00,	0x74,	0x00,	0xF4,	0x00,	/* 96 */
	0x4E,	0x00,	0x00,	0x00,	0x00,	0x00,	0x76,	0x00,	/* 104 */
	0x9E,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	/* 112 */
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	/* 120 */
};
static unsigned char scancodes_cmd[128] =
{
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	/* 00 */
	0x00,	0x96,	0x45,	0x07,	0xC7,	0xA7,	0x27,	0xE7,	/* 08 */
	0x67,	0x77,	0xF7,	0x87,	0x37,	0xB7,	0x00,	0x00,	/* 16 */
	0x05,	0xC5,	0xA5,	0x25,	0xE5,	0x65,	0x75,	0xF5,	/* 24 */
	0x85,	0x35,	0xB5,	0x12,	0x92,	0x00,	0x03,	0xC3,	/* 32 */
	0xA3,	0x23,	0xE3,	0x63,	0x73,	0xF3,	0x83,	0x33,	/* 40 */
	0xB3,	0x00,	0x00,	0x10,	0x01,	0xC1,	0xA1,	0x21,	/* 48 */
	0xE1,	0x61,	0x71,	0xF1,	0x81,	0xB1,	0x00,	0x95,	/* 56 */
	0x00,	0x31,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	/* 64 */
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x57,	/* 72 */
	0xD5,	0x17,	0x93,	0x55,	0xD3,	0x15,	0x91,	0x53,	/* 80 */
	0xD1,	0x13,	0x51,	0x11,	0x00,	0x00,	0x43,	0x00,	/* 88 */
	0x00,	0x00,	0xD7,	0x00,	0x14,	0x00,	0x94,	0x00,	/* 96 */
	0x47,	0x00,	0x00,	0x00,	0x00,	0x00,	0x16,	0x00,	/* 104 */
	0x97,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	/* 112 */
	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	0x00,	/* 120 */
};
#endif

int blackColor;
int whiteColor;
//Display *dpy;  // Display is some X11 stuff
//Window win;  // Window is some X11 stuff
//GC gc, clear_gc;
//XEvent e;
//XFontStruct *font;

WINDOW* win_main;       // main CRT 64 col x 16 row display (top left)
//WINDOW* win_inputs;     // mini-window to show mapping of PC keycodes over to IBM 5110 scancodes as they are typed 
//WINDOW* win_mode;     // "modes" used to be in a window, but they are static position so more efficient to just draw the updated mode values (no scroll)
WINDOW* win_registers;  // the IBM 5110 has a "registers" key to view the first 512 bytes.  On a modern PC, we can show both the CRT display and these registers at the same time.  This is converted to the IBM 5110 big endian format, to better match the actual 5110 register display.
WINDOW* win_screen_ram; // a "raw" view of the RWS array is display at the bottom, in an expanded hex view.  This will be in the Intel little endian format for performance.
//WINDOW* win_status;   // like win_mode, I used to have a window for this - but its more efficient to just draw the status updates (no scroll)
int win_main_height;
int win_main_width;
//int win_inputs_height;
//int win_inputs_width;
//int win_mode_height;
//int win_mode_width;
int win_registers_height;
int win_registers_width;
int win_screen_ram_height;
int win_screen_ram_width;
//int win_status_height;
//int win_status_width;

// The ROS handles keystroke inputs and the display is given some hex code to display.
char font_translate[] = {
  191,  // 000
  191,  // 001
  191,  // 002 
  191,  // 003
  191,  // 004
  191,  // 005 
  191,  // 006
  191,  // 007
  191,  // 008
  191,  // 009
  191,  // 010
  191,  // 011
  191,  // 012
  191,  // 013
  191,  // 014
  191,  // 015 
  191,  // 016
  191,  // 017
  191,  // 018
  191,  // 019 
  191,  // 020
  191,  // 021
  191,  // 022 
  191,  // 023
  191,  // 024
  191,  // 025
  191,  // 026
  191,  // 027
  191,  // 028
  191,  // 029
  191,  // 030
  191,  // 031
  191,  // 032 
  191,  // 033
  191,  // 034
  191,  // 035
  191,  // 036 
  191,  // 037
  191,  // 038
  191,  // 039 
  191,  // 040
  191,  // 041
  191,  // 042
  191,  // 043
  191,  // 044
  191,  // 045
  191,  // 046
  191,  // 047
  191,  // 048
  191,  // 049 
  191,  // 050
  191,  // 051
  191,  // 052
  191,  // 053 
  191,  // 054
  191,  // 055
  191,  // 056 
  191,  // 057
  191,  // 058
  191,  // 059
  191,  // 060
  191,  // 061
  191,  // 062
  191,  // 063
  ' ',  // 064  SPACE
  'A',  // 065  underscore versions
  'B',  // 066 
  'C',  // 067
  'D',  // 068
  'E',  // 069
  'F',  // 070 
  'G',  // 071
  'H',  // 072
  'I',  // 073 
  191,  // 074
  '.',  // 075
  '<',  // 076
  '(',  // 077
  '+',  // 078
  ' ',  // 079
  '&',  // 080
  'J',  // 081
  'K',  // 082
  'L',  // 083 
  'M',  // 084
  'N',  // 085
  'O',  // 086
  'P',  // 087 
  'Q',  // 088
  'R',  // 089
  '!',  // 090 
  '$',  // 091
  '*',  // 092
  ')',  // 093
  ';',  // 094
  191,  // 095
  '-',  // 096
  '/',  // 097
  'S',  // 098
  'T',  // 099
  'U',  // 100 
  'V',  // 101
  'W',  // 102
  'X',  // 103
  'Y',  // 104 
  'Z',  // 105
  ':',  // 106
  ',',  // 107 
  '%',  // 108
  '_',  // 109
  '>',  // 110
  '?',  // 111
  '&',  // 112  underscore
  191,  // 113
  '"',  // 114
  191,  // 115
  '-',  // 116
  191,  // 117 
  191,  // 118
  191,  // 119
  191,  // 120
  '`',  // 121 
  ':',  // 122
  '#',  // 123
  '@',  // 124 
  '\'',  // 125
  '=',  // 126
  191,  // 127
  191,  // 128
  'a',  // 129
  'b',  // 130
  'c',  // 131
  'd',  // 132
  'e',  // 133
  'f',  // 134 
  'g',  // 135
  'h',  // 136
  'i',  // 137
  '^',  // 138  ADA up arrow 
  191,  // 139
  191,  // 140
  191,  // 141 
  191,  // 142
  187,  // 143  >> right pointing arrow
  191,  // 144
  'j',  // 145
  'k',  // 146
  'l',  // 147
  'm',  // 148
  'n',  // 149
  'o',  // 150
  'p',  // 151 
  'q',  // 152
  191,  // 153
  191,  // 154
  191,  // 155 
  191,  // 156
  191,  // 157
  191,  // 158 
  171,  // 159 << left pointing arrow
  '-',  // 160
  191,  // 161
  's',  // 162
  't',  // 163
  'u',  // 164
  'v',  // 165
  'w',  // 166
  'x',  // 167
  'y',  // 168 
  'z',  // 169
  191,  // 170
  191,  // 171
  191,  // 172 
  '[',  // 173
  191,  // 174
  191,  // 175 
  191,  // 176
  191,  // 177
  191,  // 178
  191,  // 179
  191,  // 180
  191,  // 181
  'x',  // 182
  '\\',  // 183
  247,  // 184
  191,  // 185 
  191,  // 186
  191,  // 187
  191,  // 188
  ']',  // 189 
  191,  // 190
  191,  // 191
  191,  // 192 
  'A',  // 193
  'B',  // 194
  'C',  // 195
  'D',  // 196
  'E',  // 197
  'F',  // 198
  'G',  // 199
  'H',  // 200
  'I',  // 201
  191,  // 202 
  191,  // 203
  191,  // 204
  191,  // 205
  191,  // 206 
  191,  // 207
  191,  // 208
  'J',  // 209 
  'K',  // 210
  'L',  // 211
  'M',  // 212
  'N',  // 213
  'O',  // 214
  'P',  // 215
  'Q',  // 216
  'R',  // 217
  191,  // 218
  '!',  // 219  0xDB
  191,  // 220
  191,  // 221
  191,  // 222
  191,  // 223 
  191,  // 224
  191,  // 225
  'S',  // 226 
  'T',  // 227
  'U',  // 228
  'V',  // 229
  'W',  // 230
  'X',  // 231
  'Y',  // 232
  'Z',  // 233
  191,  // 234
  191,  // 235
  191,  // 236 
  191,  // 237
  191,  // 238
  191,  // 239
  '0',  // 240 
  '1',  // 241
  '2',  // 242
  '3',  // 243 
  '4',  // 244
  '5',  // 245
  '6',  // 246
  '7',  // 247
  '8',  // 248
  '9',  // 249
  191,  // 250
  191,  // 251
  191,  // 252
  '*',  // 253 
  191,  // 254
  '#'   // 255
};

int DisplayInit()
{
  //initscr();  // pdcurses, this doesn't seem to be required.

  resize_term(42, 200);  // this should change the size of the terminal window as-needed.  This should work in full-screen mode also.
  // if the above has some issues, then try:
  //resize_window(w_term, 50, 220);
  //wresize(w_term, 50, 220);
  //wrefresh(w_term);

  start_color();  // hopefully no effect if user is actually using MDA or monochrome output
  curs_set(0);  // turn off the local/native blinkng cursor

  // PD curses works by defining COLOR PAIRS, which the application then references these by the index specified below.
  init_pair(1, COLOR_WHITE, COLOR_BLUE);
  init_pair(2, COLOR_YELLOW, COLOR_BLACK);
  init_pair(3, COLOR_CYAN, COLOR_BLACK);
  init_pair(4, COLOR_MAGENTA, COLOR_BLACK);
  init_pair(5, COLOR_YELLOW, COLOR_BLUE);

  win_main_height = 16;
  win_main_width = 64;
  win_main = newwin(win_main_height, win_main_width, 0, 0);  

  /*
  win_inputs_height = 5;
  win_inputs_width = 11;
  win_inputs = newwin(win_inputs_height, win_inputs_width, 1, 65);
  scrollok(win_inputs, 1);
  mvprintw(0, 65, "idx -> scan");
  */

  // Instead of drawing this fixed text over and over, draw it once.  During UpdateDisplay, we'll redraw just the actual modes per level
  /*
  mvprintw( 7, 65, "LVL  MODE");
  mvprintw( 8, 65, "0 -> ");
  mvprintw( 9, 65, "1 -> ");
  mvprintw(10, 65, "2 -> ");
  mvprintw(11, 65, "3 -> ");
  */

/*
  win_mode_height = 5;
  win_mode_width = 11;
  win_mode = newwin(win_mode_height, win_mode_width, 10, 65);
  */

  win_registers_height = 7;
  win_registers_width = 72;
  win_registers = newwin(win_registers_height, win_registers_width, 0, 65);

  win_screen_ram_height = 18;
  win_screen_ram_width = 200;
  win_screen_ram = newwin(win_screen_ram_height, win_screen_ram_width, 22, 0);

/*
  win_status_height = 16;
  win_status_width = 30;
  win_status = newwin(win_status_height, win_status_width, 0, 160);
*/

  wbkgd(win_main, COLOR_PAIR(1));
  //wbkgd(win_inputs, COLOR_PAIR(1));
  //wbkgd(win_mode, COLOR_PAIR(1));
  wbkgd(win_registers, COLOR_PAIR(1));
  wbkgd(win_screen_ram, COLOR_PAIR(1));
  //wbkgd(win_status, COLOR_PAIR(1));

  mvprintw(16, 0, "TAB = CMD-ATTN (use to activate DIAG DCP during startup ROS CRC check)");
  mvprintw(17, 0, "ESC = ATTN (clear/cancel/stop), \"GO\" to resume");
  mvprintw(18, 0, " `  = HOLD (buggy)     CTRL-C = EXIT EMULATOR");
  mvprintw(19, 0, "CTRL-TAB    = CMD-MINUS (enter DCP, use HOLD first)");
  mvprintw(20, 0, "SHIFT-TAB   = CMD-PLUS  (exit DCP, resume language)");
  mvprintw(21, 0, "SHIFT-` (~) = CMD-MULTIPLY (enter DIAG DCP from DCP)");
  
  mvprintw(16, 88, "CTRL-BACKSPACE = CMD-LEFT ARROW (delete)");
  mvprintw(17, 88, "     BACKSPACE = LEFT ARROW");

  attron(COLOR_PAIR(4) | A_BOLD);
  mvprintw(17, 50, "DIAG DCP: C = Show Test Control Menu");
  mvprintw(18, 50, "DIAG DCP: BR/BX/BE = Branch RWS/Extended/Executive Run");
  mvprintw(19, 50, "     DCP: D = Display Address");
  mvprintw(20, 50, "     DCP: A = Alter Address");

  attron(COLOR_PAIR(3));
  mvprintw(19, 88, "{ or } = EXAMINE +/- 512 BYTES of RWS");
  mvprintw(20, 88, "F5     = STEP MODE TOGGLE / F4 DISASM TRACE TOGGLE");
  mvprintw(21, 88, "F6-F10 = STEP 1/100/1000/10000/100000");

  attron(COLOR_PAIR(2));
  mvprintw(16, 140, "BE 00A0: run opcode test");
  mvprintw(17, 140, "BX 000A: run language (BX is even address only)");
  mvprintw(18, 140, "BR 0B00: run RWS code (typical address)");
  mvprintw(19, 140, "UTIL DIR,D80     list disk D80/D40/D20/D10");
  mvprintw(20, 140, "UTIL DIR,E80     list tape E80/E40 (slow!)");
  mvprintw(21, 140, "REWIND           rewind the tape");
  attron(COLOR_PAIR(0));

  /*
  // win_status      12345678901234567890
  mvprintw( 0, 172, "INSTALLED RWS 0xAA");
  mvprintw( 1, 172, "AVAILABLE RWS 0xA8");
  mvprintw( 2, 172, "LAST KEY      0xB0");
  mvprintw( 3, 172, "TAPE STATUS   0x8F");
  mvprintw( 4, 172, "PRINTER A     0x55");
  mvprintw( 5, 172, "PRINTER B     0x57");
  mvprintw( 6, 172, "DISK A        0xE8");
  mvprintw( 7, 172, "DISK B        0xE9");
  mvprintw( 8, 172, "STATUS 1 key  0x69");
  mvprintw( 9, 172, "STATUS 2 disp 0x6B");
  mvprintw(10, 172, "STATUS 3 ???  0x73");  
  */

  timeout(2);  // required to add a timeout on how long getch waits for a keypress (0 seems to work fine, it's still some fraction of a second)
  noecho();  // this disables the local console from echo'ing/repeating keystrokes
  keypad(stdscr, 1);  // this is needed to enable reading of arrow keys
//  refresh();  // doesn't seem to be required, the display gets refreshed soon anyway

  //wrefresh(win_inputs);
  //wrefresh(win_mode);

  /*
	XClassHint class_hint;

	if ((dpy = XOpenDisplay(NULL)) == NULL)
	{
		printf("Unable to open display\n");
		return 1;
	}

	blackColor = BlackPixel(dpy, DefaultScreen(dpy));
	whiteColor = WhitePixel(dpy, DefaultScreen(dpy));
	
	win = XCreateSimpleWindow(dpy, DefaultRootWindow(dpy), 0, 0,
				WIN_WIDTH, WIN_HEIGHT, 0,
				blackColor, blackColor);
	gc = XCreateGC(dpy, win, 0, NULL);
	XSetForeground(dpy, gc, whiteColor);
	XSetBackground(dpy, gc, blackColor);
	clear_gc = XCreateGC(dpy, win, 0, NULL);
	XSetForeground(dpy, clear_gc, blackColor);
	XSetBackground(dpy, clear_gc, blackColor);
	XSetFillStyle(dpy, clear_gc, FillSolid);
        
	XStoreName(dpy, win, WIN_TITLE);
        
	class_hint.res_name = WIN_NAME;
	class_hint.res_class = WIN_CLASS;
	XSetClassHint(dpy, win, &class_hint);
	XMapWindow(dpy, win);
	XFlush(dpy);
	
	font = XLoadQueryFont(dpy, "ibm5110");
	if(!font)
	{
		fprintf(stderr, "ERROR: Font 'ibm5110' not found\n");
		XDestroyWindow(dpy, win);
		return 2;
	}

	XSetFont(dpy, gc, font->fid);
	XSelectInput(dpy, win, ExposureMask|KeyPressMask);
*/	
	return 0;
}

void UpdateScreen()
{
	int i, x;
	unsigned char *ptr, *ptr_ram;

  unsigned int status_installed_rws;
  unsigned int status_available_rws;
  unsigned int status_last_key_press;
  unsigned int status_tape_status;
  unsigned int status_printerA;
  unsigned int status_printerB;
  unsigned int status_diskA;
  unsigned int status_diskB;
  unsigned int status_key1;
  unsigned int status_key2;
  unsigned int status_key3;

  ptr = &RWSb[0x0200];  // 0x0200 is address of screen buffer

  ptr_ram = &RWSb[rws_start_address_to_display];
	
	if(emuvar_display)
	{
    mvwprintw(win_screen_ram, 17, 0, "0x%04X %05u", rws_start_address_to_display, rws_start_address_to_display);

		// display is turned on, draw 16 lines of text
		for(i=0; i<=15; i++, ptr+=64, ptr_ram+=64)
		{
			//XDrawImageString(dpy, win, gc, 0, (i*24)-4, ptr, 64);


      if ( (ptr_ram-RWSb) >= 0xFFFF )
      {
        ptr_ram = RWSb;
      }

//      if (ptr_ram-RWSb < 0xFFFF)
      {
        mvwprintw(win_screen_ram, i, 0, "%04X", ptr_ram-RWSb);
      }
  //    else
      {
    //    mvwprintw(win_screen_ram, i, 0, "????");
      }

      for (x = 0; x < 64; ++x)
      {
        //printf("%c", font_translate[ptr[x]]);

        mvwprintw(win_main, i, x, "%c", font_translate[ptr[x]]);

        mvwprintw(win_screen_ram, i, x*3+8, "%02X", ptr_ram[x]);
        if (x % 8 == 0)
        {
          mvwprintw(win_screen_ram, i, x*3+7, "|");
        }
      }
      //printf("\n");

      //printf("%c", *ptr);
		}
    wrefresh(win_main);
    wrefresh(win_screen_ram);

    //printf("---END\n");
	}
	else
	{
		// display is turned off, clear window 
		//XFillRectangle(dpy, win, clear_gc, 0, 0, WIN_WIDTH, WIN_HEIGHT);
    wclear(win_main);
    wrefresh(win_screen_ram);
	}

  ptr = &RWSb[0x00AA];  // installed RWS
  status_installed_rws = (ptr[0] << 8) | ptr[1];
  ptr = &RWSb[0x00A8];  // available RWS
  status_available_rws = (ptr[0] << 8) | ptr[1];
  ptr = &RWSb[0x00B0];  // MIM 3-43, think this is just momentarily in the executive ROS, but happens so fast before it gets transferred to one of the addresses below

  // TBD: not sure if these are quite right, maybe adjusted for LITTLE_ENDIAN
  status_last_key_press = RWSb[0xB0];  // dec 176
  status_tape_status = RWSb[0x8F-1];  // dec 143
  status_printerA = RWSb[0x55-1];     // dec  85
  status_printerB = RWSb[0x57-1];     // dec  87
  status_diskA = RWSb[0xE7-1];        // dec 232  0xE8
  status_diskB = RWSb[0xE9];        // dec 232
  status_key1 = RWSb[0x69-1];         // dec 105
  status_key2 = RWSb[0x6B-1];         // dec 107
  status_key3 = RWSb[0x73-1];         // dec 115

  /*
  mvprintw( 0, 192, "%02X\n", status_installed_rws);
  mvprintw( 1, 192, "%02X\n", status_available_rws);
  mvprintw( 2, 192, "%02X\n", status_last_key_press);
  mvprintw( 3, 192, "%02X\n", status_tape_status);
  mvprintw( 4, 192, "%02X\n", status_printerA);
  mvprintw( 5, 192, "%02X\n", status_printerB);
  mvprintw( 6, 192, "%02X\n", status_diskA);
  mvprintw( 7, 192, "%02X\n", status_diskB);
  mvprintw( 8, 192, "%02X %03d\n", status_key1, status_key1);
  mvprintw( 9, 192, "%02X %03d\n", status_key2, status_key2);
  mvprintw(10, 192, "%02X %03d\n", status_key3, status_key3);
	*/

  // SHOW THE REGISTERS
  ptr = &RWSb[0x0000];   
	{
    wclear(win_registers);
    wprintw(win_registers, "ADDR R0  R1  R2  R3  R4  R5  R6  R7   R8  R9  RA  RB  RC  RD  RE  RF\n");

    i = 0;  // address to start
    // 0 2 4 6 8 10
    // 0 1 2 3 4 5
    //   2   6   10
    while (1)
    {
      wattron(win_registers, COLOR_PAIR(1));
      wprintw(win_registers, "%04X ", i);

      x = 16;  // cols to show per row
      while (x > 0)
      {
        if (i < 128)
        {
          if (((i / 2) % 2) == 0)
          {  
            wattron(win_registers, COLOR_PAIR(1) | A_BOLD);
          }
          else
          {
            wattron(win_registers, COLOR_PAIR(5) | A_BOLD);  // YELLOW
          }
        }
        else
        {
            wattron(win_registers, COLOR_PAIR(1) | A_BOLD);
        }

        // show registers in "big endian" addressing
        wprintw(win_registers, "%02X", ptr[i+1]);

        wprintw(win_registers, "%02X", ptr[i]);
        i += 2;

        if ((i % 16) == 0)  // show a "split" between left 16 and rigth 16
        {
          wprintw(win_registers, " ");
        }

        --x;

        //if (x == 8)
        {
          //wprintw(win_registers,"| ");
        }
      }
      if (i > 32*(win_registers_height-2))  // show max 16 bytes win_registers rows-1
      {
        break;
      }
      wprintw(win_registers, "\n");
    }

    wrefresh(win_registers);

    //printf("---END\n");
	}

  /*
  x = 8;
  for (i = 0; i < 4; ++i)
  {
    if (mode[i] == MODE_RWS)
    {
      mvprintw( x, 70, "RWS");
    }
    else if (mode[i] == MODE_BUP)
    {
      mvprintw( x, 70, "BUP");
    }
    else if (mode[i] == MODE_ROS)
    {
      mvprintw( x, 70, "ROS");
    }
    ++x;
  }
  */
  //mvprintw( 8, 70, "%d", mode[0]);
  //mvprintw( 9, 70, "%d", mode[1]);
  //mvprintw(10, 70, "%d", mode[2]);
  //mvprintw(11, 70, "%d", mode[3]);
  /*
  mvwprintw(win_mode, 0, 0, "MODE 0 = %d\n", mode[0]);
  mvwprintw(win_mode, 1, 0, "MODE 1 = %d\n", mode[1]);
  mvwprintw(win_mode, 2, 0, "MODE 2 = %d\n", mode[2]);
  mvwprintw(win_mode, 3, 0, "MODE 3 = %d\n", mode[3]);
  wrefresh(win_mode);*/

  //XFlush(dpy);
 
}


#define ShiftMask	(1<<0)
#define LockMask	(1<<1)
#define ControlMask	(1<<2)

// Sort of pretending to be X11, re-using similar X11 structures
typedef struct {
	int type;		/* KeyPress or KeyRelease */
	unsigned long serial;	/* # of last request processed by server */
	//Bool send_event;	/* true if this came from a SendEvent request */
	//Display *display;	/* Display the event was read from */
	//Window window;		/* ``event'' window it is reported relative to */
	//Window root;		/* root window that the event occurred on */
	//Window subwindow;	/* child window */
	//Time time;		/* milliseconds */
	int x, y;		/* pointer x, y coordinates in event window */
	int x_root, y_root;	/* coordinates relative to root */
	unsigned int state;	/* key or button mask */
	unsigned int keycode;	/* detail */
	//Bool same_screen;	/* same screen flag */
} XKeyEvent;

// NOTE: pdcurses does support mouse and having push buttons (not exercised in this build)
typedef union _XEvent {
	int type;	/* must not be changed */
	//XAnyEvent xany;
	XKeyEvent xkey;
	//XButtonEvent xbutton;
	//XMotionEvent xmotion;
	//XCrossingEvent xcrossing;
	//XFocusChangeEvent xfocus;
	//XExposeEvent xexpose;
	//XGraphicsExposeEvent xgraphicsexpose;
	//XNoExposeEvent xnoexpose;
	//XVisibilityEvent xvisibility;
	//XCreateWindowEvent xcreatewindow;
	//XDestroyWindowEvent xdestroywindow;
	//XUnmapEvent xunmap;
	//XMapEvent xmap;
	//XMapRequestEvent xmaprequest;
	//XReparentEvent xreparent;
	//XConfigureEvent xconfigure;
	//XGravityEvent xgravity;
	//XResizeRequestEvent xresizerequest;
	//XConfigureRequestEvent xconfigurerequest;
	//XCirculateEvent xcirculate;
	//XCirculateRequestEvent xcirculaterequest;
	//XPropertyEvent xproperty;
	//XSelectionClearEvent xselectionclear;
	//XSelectionRequestEvent xselectionrequest;
	//XSelectionEvent xselection;
	//XColormapEvent xcolormap;
	//XClientMessageEvent xclient;
	//XMappingEvent xmapping;
	//XErrorEvent xerror;
	//XKeymapEvent xkeymap;
	long pad[24];
} XEvent;

unsigned int translate_sequence(char ch, unsigned int* state_ptr)
{
  unsigned int result;

  (*state_ptr) = 0;

  // http://www.bitsavers.org/pdf/ibm/5110/SY31-0550-2_IBM_5110_Computer_Maintenance_Information_Manual_Feb1979.pdf
  // MIM 2-26 keycodes

  // the result here is an INDEX into the scancodes table (which are then converted into IBM 5110 scan codes)
  switch (ch)
  {
  case '!':  // modern PC keyboard has "!" symbol, but this is input using a sequence on the IBM 5110
    {
      sequence_composer = 1;  // 0 == no composer, 1 is used to indicate applying the first composition sequence
      sequence_composer_index = 0;
      result = 0;
    }
    break;

  case '{':  // move DOWN N addresses in the RWS/RAM viewer
    {
      rws_start_address_to_display -= 512;
      while (rws_start_address_to_display < 0)
      {
        rws_start_address_to_display += 65535;
      }
      result = 0;
    }
    break;
  case '}':  // move UP N addresses in the RWS/RAM viewer
    {
      rws_start_address_to_display += 512;
      while (rws_start_address_to_display > 65535)
      {
        rws_start_address_to_display -= 65535;
      }
      result = 0;
     }
    break;

  // This is here in case we are processing a scripted input file.
  case -52: result = 0; break;  // early EOF (end of file)

  case 12:  // F4 set disassembler trace
    {
      disasm_trace = !disasm_trace;
      result = 0;
      break;
    }

  case 13:    // F5 toggle step mode
    {
      step_mode = !step_mode;
      do_step = 0;
      result = 0;
    }
    break;  // F5
  case 14:  if (do_step == 0) do_step = 1; result = 0; break;  // F6, 1 number of steps
  case 15:  if (do_step == 0) do_step = 100; result = 0; break;  // F7, 100 is number of steps
  case 16:  if (do_step == 0) do_step = 1000; result = 0; break;  // F8, 1000 is number of steps
  case 17:  if (do_step == 0) do_step = 10000; result = 0; break;  // F9, 10000 is number of steps
  case 18:  if (do_step == 0) do_step = 100000; result = 0; break;  // F10, 100000 is number of steps

  case '`':  result = 110; break;   // ~/` --> HOLD key
  case -30: result = 82; (*state_ptr) = ControlMask; break;  // CTRL-TAB --> CMD-MINUS
  case 95:  result = 86; (*state_ptr) = ControlMask; break;  // SHIFT-TAB --> CMD-PLUS
  case '~': result = 63; (*state_ptr) = ControlMask; break;  // ~ --> CMD-MULTIPLY
  case 127: result = 100; (*state_ptr) = ControlMask; break;   // CTRL-BACKSPACE --> CMD-LEFT ARROW
      
  case 3:   result = 98; break;   // UP
  case 2:   result = 104; break;  // DOWN
  case 4:   result = 100; break;  // LEFT
  case 5:   result = 102; break;  // RIGHT
  case 27:  result = 9; break;    // ESCAPE --> ATTN
  case 9:   result = 9; (*state_ptr) = ControlMask; break;  // TAB --> CMD-ATTN

  case '*': result = 63; break;  // KEYPAD MULTIPLY
  case '-': result = 82; break;  // KEYPAD MINUS
  case '/': result = 61; break;  // SLASH /  (on bottom next to $, NOT keypad)
  case '\\': result = 61; (*state_ptr) = ShiftMask; break; // BLACKSASH (shifted version on bottom)
  case '+': result = 86; break;  // KEYPAD PLUS  (could also use result = 20)
  case '$': result = 94; break;  // DOLLAR SIGN
  case '<': result = 12; (*state_ptr) = ShiftMask; break;
  case '>': result = 16; (*state_ptr) = ShiftMask; break;

  case ',': result = 59; break;
  case ';': result = 59; (*state_ptr) = ShiftMask; break;

  case '.': result = 60; break;  // DOT (on bottom near ,   NOT keypad)
  case ':': result = 60; (*state_ptr) = ShiftMask; break;

  case '#': result = 51; break;
  case '@': result = 51; (*state_ptr) = ShiftMask; break;
  //case '^': result = xx; break;
  case '&': result = 94; (*state_ptr) = ShiftMask; break;  // &
  //case '\\': result = xx; break;
  case '?': result = 24; (*state_ptr) = ShiftMask; break;   // SHIFT-Q

  case ' ': result = 65; break;  // SPACE

  case 10:  result = 36; break;  // RETURN

  case '\'': result = 45;  (*state_ptr) = ShiftMask; break;
  case '"': result = 10;  (*state_ptr) = ShiftMask; break;
  case 8:   result = 100; break;  // BACKSPACE

  case '=': result = 35; break;

  case '[': result = 47; break; 
  case ']': result = 48; break;
  case '(': result = 47;  (*state_ptr) = ShiftMask; break;
  case ')': result = 48;  (*state_ptr) = ShiftMask; break;

  case 'a':
  case 'A': result = 38; break;
  case 'b':
  case 'B': result = 56; break;
  case 'c':
  case 'C': result = 54; break;
  case 'd':
  case 'D': result = 40; break;
  case 'e':
  case 'E': result = 26; break;
  case 'f':
  case 'F': result = 41; break;
  case 'g':
  case 'G': result = 42; break;
  case 'h':
  case 'H': result = 43; break;
  case 'i':
  case 'I': result = 31; break;
  case 'j':
  case 'J': result = 44; break;
  case 'k':
  case 'K': result = 45; break;
  case 'l':
  case 'L': result = 46; break;
  case 'm':
  case 'M': result = 58; break;
  case 'n':
  case 'N': result = 57; break;
  case 'o':
  case 'O': result = 32; break;
  case 'p':
  case 'P': result = 33; break;
  case 'q':
  case 'Q': result = 24; break;
  case 'r':
  case 'R': result = 27; break;
  case 's':
  case 'S': result = 39; break;
  case 't':
  case 'T': result = 28; break;
  case 'u':
  case 'U': result = 30; break;
  case 'v':
  case 'V': result = 55; break;
  case 'w':
  case 'W': result = 25; break;
  case 'x':
  case 'X': result = 53; break;
  case 'y':
  case 'Y': result = 29; break;
  case 'z':
  case 'Z': result = 52; break;
    
  case '0': result = 19; break;
  case '1': result = 10; break;
  case '2': result = 11; break;
  case '3': result = 12; break;
  case '4': result = 13; break;
  case '5': result = 14; break;
  case '6': result = 15; break;
  case '7': result = 16; break;
  case '8': result = 17; break;
  case '9': result = 18; break;

  default:  
    result = 0; 
    break;
  }

  return result;
}

char queued_keys[10];

int DoEvents()
{
	unsigned char c;
  int ch_kbd;
  unsigned char ch;
  unsigned short code;
  static short sequence_mode = 0;

  static FILE* f;
  static int first = TRUE;  // duing the first entry into DoEvents, we'll look for the command input script and process it.  This variable is used to mark that first entry.
  static unsigned int delay_count = 0;

  XEvent e;
  e.xkey.state = 0;
  e.xkey.keycode = MAX_KEYCODE + 1;

  if (first == TRUE)
  {
    f = fopen(str_command_input, "rb");
    first = FALSE;  // clear the "first" flag, opening and reading the command input script is a one-time only event
  }

  if (delay_count > 0)
  {
    // The script input command has to been to issue a delay before input of other commands.
    // This is generally to allow for the ROS to finish some other processing, or to observe something before proceeding.
    // The amount of delay necessary may depend on the runtime performance of the host system running the emulator.
    --delay_count;
  } 
  else if (sequence_composer > 0)  // if a composition was issued (whether from scripted input or from regular keyboard input)...
  {
    e.xkey.keycode = translate_sequence(sequence_composition[sequence_composer-1][sequence_composer_index], &e.xkey.state);
    ++sequence_composer_index;
    if (sequence_composer_index >= MAX_SEQUENCE_COMPOSITION_INDEX)
    {
      // end the sequence
      sequence_composer = 0;
      sequence_composer_index = 0;
    }
  }
  else if (f)  // if a scripted input is still active...
  {
    if (sequence_mode == 1)
    {
      // read each remaining character of the current row as an input (but translating modern ASCII to native 5110 scancodes)
      fscanf(f, "%c", &ch);
      if (ch == '\n')
      {
        sequence_mode = 0;
        e.xkey.keycode = 0;
        delay_count = 2;  // give time for processor to move to next sequence
      }
      else if (ch == '\r')
      {
        e.xkey.keycode = 0;
      }
      else
      {
        e.xkey.keycode = translate_sequence(ch, &e.xkey.state);
      }
    }
    else if (sequence_mode == 2)
    {
      // read each remaining character of the current row as an input (but translating modern ASCII to native 5110 scancodes)
      fscanf(f, "%c", &ch);
      if (ch == '\n')
      {
        sequence_mode = 0;
        e.xkey.keycode = translate_sequence(10, &e.xkey.state);  // press the ENTER
        delay_count = 0;  // press the key immediately
      }
      else if (ch == '\r')
      {
        e.xkey.keycode = 0;
      }
      else
      {
        e.xkey.keycode = translate_sequence(ch, &e.xkey.state);
      }
    }
    else
    {
      fscanf(f, "%c %u", &ch, &e.xkey.keycode);
      switch (ch)
      {
      case 'Q':  
      case 'q':  // SEQUENCE mode (stops when reached \n, newline is interpreted as 0 - no input)
        sequence_mode = 1;
        break;

      case 'A':
      case 'a':  // like Q but will newline at the end
        fscanf(f, "%c", &ch);  // read the blankspace after the A to avoid it being part of the scripted input
        sequence_mode = 2;
        break;

      case 'D':
      case 'd':  // DELAY
        delay_count = e.xkey.keycode;  // the second argument isn't really a keycode, but is a DELAY COUNT
        break;

      case 'S':
      case 's':  // shift
        e.xkey.state = ShiftMask;
        break;

      case 'C':
      case 'c':  // CMD/CTRL
        e.xkey.state = ControlMask;
        break;

      case 'Z':
      case 'z':  // shift and CMD at same time
        e.xkey.state = ShiftMask | ControlMask;
        break;

      case ';':
        ch = 0;
        e.xkey.state = 0;
        break;

      case 'N':
      default:  // anything else is "normal" key
        e.xkey.state = 0;
        break;
      }

      // read anything remaining on the current line as extra comments
      if (sequence_mode == 0)
      {
        while (!feof(f))
        {
          fscanf(f, "%c", &ch);
          if (ch == '\n')   // \r\n  \r will happen first...
          {
            break;
          }
        }
      }
    }

    if (feof(f))
    {
      fclose(f);
      f = 0;
    }
  }
  else
  {
    // check for keyboard input
    {
      ch_kbd = getch();
      if (ch_kbd == ERR)
      {
        // do nothing
      }
      else
      {
        e.xkey.state = 0;  // clear out any prior keyboard-state adjustments, just in case
        e.xkey.keycode = translate_sequence(ch_kbd, &e.xkey.state);
      }
    }
  }

  if (delay_count == 0)  // scripted inputs can have a DELAY specified; if no delay is active, ....
  {
    if (e.xkey.keycode > MAX_KEYCODE)
    {
      // do nothing
    }
    else
    {
      switch(e.xkey.state & (ShiftMask|ControlMask))
      {
	      case 0:
		      c = scancodes_normal[e.xkey.keycode];
		      if(c)
			      emu_keyboard(c);
		      break;
						
	      case ControlMask: 
		      c = scancodes_cmd[e.xkey.keycode];
		      if(c)
			      emu_keyboard(c);
		      break;
						
	      case ShiftMask:
		      c = scancodes_shift[e.xkey.keycode];
		      if(c)
			      emu_keyboard(c);
		      break;

        default:   // BOTH ?
          break;
      }

      //wprintw(win_inputs, "\n%3u -> %3u", e.xkey.keycode, c);
      //wrefresh(win_inputs);

      if (step_mode == 1)
      {
        delay_count = 1;
      }
      else
      {
        delay_count = 1;  // give some time for the keypress to get acknowledged by the processor
      }

      return 1;
    }
  }

  /*
	if(XPending(dpy))
	{
		XNextEvent(dpy, &e);
		switch(e.type)
		{
			case MapNotify:
			case Expose:
				UpdateScreen();
				break;

			case KeyPress: 
				if(e.xkey.keycode > MAX_KEYCODE)
					break;
				switch(e.xkey.state & (ShiftMask|ControlMask))
				{
					case 0:
						c = scancodes_normal[e.xkey.keycode];
						if(c)
							emu_keyboard(c);
						break;
						
					case ControlMask:
						c = scancodes_cmd[e.xkey.keycode];
						if(c)
							emu_keyboard(c);
						break;
						
					case ShiftMask:
						c = scancodes_shift[e.xkey.keycode];
						if(c)
							emu_keyboard(c);
						break;
				}
				break;
		}
		
		return 1;
	}
	*/
	return 0;
}
