/*
   emu5110
	-------
	An emulator for the IBM 5110
	(C) 2007-2008 Christian Corti

  Adapted to Wintel (using winpthread and pdcurses) by Steve Lewis - 2022
	
	Global header file
*/

#ifndef _EMU_H
#define _EMU_H

#include <curses.h>

#ifdef LITTLE_ENDIAN
#define SWAB(x1)		(USHORT)(((x1<<8)|(x1>>8)))
#else
#define SWAB(x1)		x1
#endif

#ifndef TRUE
#define TRUE -1
#define FALSE 0
#endif

enum {
 MODE_RWS=0, 
 MODE_BUP, 
 MODE_ROS
};

extern int level;
extern int mode[4];

extern short step_mode;
extern short disasm_trace;
extern unsigned long int do_step;
extern long int start_step_at;  // -1 to break at 0B00
extern char str_command_input[255];
extern char str_binary_load[255];

WINDOW* win_disasm;
extern unsigned long long int instr_count[4];

typedef unsigned char UCHAR;
typedef unsigned char UBYTE;
typedef unsigned short USHORT;

struct sIOCB
{
	UBYTE		DA, Sub;
	UBYTE		Cmd, Flags;
	USHORT	BA, BS;
	USHORT	CI1, WA, Ret, CI2;
	USHORT	Stat1, Stat2;
};

#define IO_SENSE			0
#define IO_READ			1
#define IO_WRITE			2
#define IO_WRITELAST		3
#define IO_FIND			4
#define IO_MARK			5
#define IO_WRITEHEADER	11
#define IO_SCAN			12
#define IO_FINDID			16
#define IO_INITHEAD		17

/* display_x11.c */
extern int DisplayInit(void);
extern void UpdateScreen(void);
extern int DoEvents(void);

/* tape_io.c */
extern void TapeSetup(void);

/* printer_io.c */
extern int PrinterAttach(void);
extern void PrinterDetach(void);

/* emu.c */
extern int emu_init(void);
extern void emu_reset(void);
extern int emu_fetch(void);
extern int emu_do(void);
extern void emu_keyboard(UBYTE code);
extern void dump_regs(void);
extern void emu_toggle_dump(void);
extern void emu_select_lang(int lang);

extern UBYTE *RWSb;
extern USHORT *curr_regs;
extern int int1, int2, int3;
extern int emuvar_display;
extern unsigned long emuvar_timer;

#endif
