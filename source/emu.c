/*
   emu5110
	-------
	An emulator for the IBM 5110
	(C) 2007-2008 Christian Corti

  Adapted to Wintel (using winpthread and pdcurses) by Steve Lewis - 2022
	
	Emulator core
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include "emu.h"
#include "disk_io.h"
#include "printer_io.h"
#include "tape_io.h"

// TBD - BAD PRACTICE TO COUPLE LOGIC TO DISPLAY...
#include <curses.h>
//WINDOW* win_cpu;
//int win_cpu_height;
//int win_cpu_width;
//WINDOW* win_addr;
//int win_addr_height;
//int win_addr_width;
#define DEBUG 0
WINDOW* win_disasm;
int win_disasm_height;
int win_disasm_width;

WINDOW* win_disasm_long;
int win_disasm_long_height;
int win_disasm_long_width;

/* select default mode */
/*#define APL*/
#define BASIC

#if defined(APL) && defined(BASIC)
#error Only one of APL or BASIC may be defined!
#endif

/* file names of the individual ROS images */
#define EXECROS_NAME		"execros.bin"  // Executive ROS                32KB
#define COMMONROS_NAME	"comros.bin"   // Common ROS                   16KB            CommonROS
#define BASNXROS_NAME	  "basicnx.bin"  // BASIC non-executive ROS      72KB            BASNXROS  (16-bit addresses instead of 8-bit)
#define BASROS_NAME		  "basicros.bin" // BASIC ROS                    16KB
#define APLNXROS_NAME	  "aplnx.bin"    // APL non-executive ROS       128KB (64KB x2)  APLNXROS  (16-bit addresses instead of 8-bit)
#define APLROS_NAME		  "aplros.bin"   // APL ROS                      20KB



void emu_reset(void);
void emu_start(void);
int emu_fetch(void);
int emu_do(void);
void emu_keyboard(UBYTE code);
void emu_dump_mem(void);
int emu_main(void);

void trace_apl(UBYTE b, int x);
void trace_basic(UBYTE b, int x);
void dump_regs(void);
int load_ros(void);

void check_int(void);
void Opcode0(void);
void OpcodeC(void);
void OpcodeE(void);
void DoCTRL(int dev, int imm);
void DoPUTB(int dev, UBYTE c);
UBYTE DoGETB(int dev);

#define INT_ENA	0x80
#define INT_3		0x04
#define INT_2		0x02
#define INT_1		0x01

enum {
 ERR_NOERR=0,
 ERR_RWS_ALLOC,
 ERR_EXECROS_FILE, 
 ERR_EXECROS_ALLOC, 
 ERR_EXECROS_READ,
 ERR_COMMONROS_FILE, 
 ERR_COMMONROS_ALLOC, 
 ERR_COMMONROS_READ,
 ERR_APLROS_FILE, 
 ERR_APLROS_ALLOC, 
 ERR_APLROS_READ,
 ERR_APLNXROS_FILE, 
 ERR_APLNXROS_ALLOC, 
 ERR_APLNXROS_READ,
 ERR_BASROS_FILE, 
 ERR_BASROS_ALLOC, 
 ERR_BASROS_READ,
 ERR_BASNXROS_FILE, 
 ERR_BASNXROS_ALLOC, 
 ERR_BASNXROS_READ,
};

#define POSTCREMENT \
	if(n3<4) \
		curr_regs[n2] += n3+1; \
	else if(n3<8) \
		curr_regs[n2] -= n3-3;

#ifdef LITTLE_ENDIAN
#define REGHI(reg)	curr_regsb[(reg<<1)+1]
#define REGLO(reg)	curr_regsb[(reg<<1)]
#else
#define REGLO(reg)	curr_regsb[(reg<<1)+1]
#define REGHI(reg)	curr_regsb[(reg<<1)]
#endif

#define IMM				(OP&0xFF)
#define INC_PC			curr_regs[0]+=2

#if DEBUG
#ifdef APL
#define TRACE(a,b)	trace_apl(a,b)
#else
#define TRACE(a,b)	trace_basic(a,b)
#endif
#else
#define TRACE(a,b)
#endif

/* The individual Executable ROS areas and the RWS */
USHORT *RWS, *ExecROS, *APLROS, *BASROS;
USHORT *curr_ros, *language_ros;
UBYTE *RWSb;					/* RWS with byte addressing */

/* The non-executable ROS areas */
USHORT *CommonROS, *BASNXROS, *APLNXROS;
USHORT *nxros, nxros_addr, nxros_waddr;
int nxros_rtoggle, nxros_wtoggle, nxros_xtoggle;

int emuvar_display;
unsigned long emuvar_timer;

/* Interrupt handling */
int int_mask, int1, int2, int3;
UBYTE kbdcode;

/* Registers */
USHORT *curr_regs;			/* current level register set; word... */
UBYTE *curr_regsb;			/* ... and byte addressing */

/* Instruction handling */
USHORT OP;						/* current opcode */
USHORT OP_addr;       /* address of current opcode */
USHORT OP_next;       /* the next op code */
UBYTE n1, n2, n3;				/* last three nibbles of opcode */
int level;  // interrupt level (0 is normal, then 1 2 or 3)
  // level 0 == normal operation
  // level 1 == BSCA and async. comm
  // level 2 == tape, disk, printer, serial I/O
  // level 3 == keyboard
int halt; // boolean to indicate HALTE state
short step_mode;
short disasm_trace;
unsigned long int do_step;
long int start_step_at;
char str_command_input[255];
char str_binary_load[255];

int mode[4];  
  // mode[0] can be in any of MODE_RWS, MODE_BUP, MODE_ROS
  // mode[1] can be in any of MODE_RWS,           MODE_ROS  (set by PUTB)
  // mode[2] can be in any of MODE_RWS,           MODE_ROS  (set by PUTB)
  // mode[3] can be in any of MODE_RWS,           MODE_ROS  (set by PUTB)

/* CPU dump */
int dump;
FILE *dumpfile;

/********************/

void emu_reset()
{
	level = 0;

	curr_ros = ExecROS;

	mode[0] = MODE_BUP;	/* in 'bring up program' mode */
	mode[1] = MODE_ROS;
	mode[2] = MODE_ROS;
	mode[3] = MODE_ROS;

	halt = FALSE;

	nxros = CommonROS;

	nxros_rtoggle = 0;
	nxros_wtoggle = 0;
	nxros_xtoggle = 0;

	int_mask = INT_ENA | INT_1 | INT_2 | INT_3;
	int1 = FALSE;
	int2 = FALSE;
	int3 = FALSE;
	
	curr_regs  = RWS;
	curr_regsb = (UBYTE *)RWS;

#ifdef LITTLE_ENDIAN
	curr_regs[0] = (((UBYTE *)ExecROS)[0])<<8 | ((UBYTE *)ExecROS)[1];
#else
	curr_regs[0] = ExecROS[0];
#endif

	emuvar_display = 1;		/* display on */
	emuvar_timer = 0;
}

// ********************************************** FROM disasm.c
typedef enum { None, Reg, Reg1, Reg2, Immediate, ByteAddr, WordAddr, Device } tParams;

struct tOpcode
{
	char *Mnemonic;
	tParams Nibble1, Nibble2;
};

struct tOpcode Op_0[16] =
{
	{ "DEC2", Reg, Reg },
	{ "DEC", Reg, Reg },
	{ "INC", Reg, Reg },
	{ "INC2", Reg, Reg },
	{ "MOVE", Reg, Reg },
	{ "AND", Reg, Reg },
	{ "OR", Reg, Reg },
	{ "XOR", Reg, Reg },
	{ "ADD", Reg, Reg },
	{ "SUB", Reg, Reg },
	{ "ADDH", Reg, Reg },
	{ "ADDH2", Reg1, Reg2 },
	{ "MHL", Reg, Reg },
	{ "MLH", Reg, Reg },
	{ "GETB", Reg2, Device },
	{ "GETA", Reg2, Device }
};

struct tOpcode Op_C[16] =
{
	{ "SLE", Reg1, Reg2 },
	{ "SLT", Reg1, Reg2 },
	{ "SE", Reg1, Reg2 },
	{ "SZ", Reg1, None },
	{ "SS", Reg1, None },
	{ "SBS", Reg1, Reg2 },
	{ "SBC", Reg, Reg },
	{ "SBSH", Reg1, Reg2 },
	{ "SGT", Reg1, Reg2 },
	{ "SGE", Reg1, Reg2 },
	{ "SNE", Reg1, Reg2 },
	{ "SNZ", Reg1, None },
	{ "SNS", Reg1, None },
	{ "SNBS", Reg1, Reg2 },
	{ "SNBC", Reg1, Reg2 },
	{ "SNBSH", Reg1, Reg2 }
};

const char *HalfTicks[16] =
{
	"'", "+", "+'", "++", "~", "-", "-~", "--",
	"", "", "", "", "", "", "", ""
};

const char *FullTicks[16] =
{
	"+", "++", "+++", "++++", "-", "--", "---", "----",
	"", "", "", "", "", "", "", ""
};

int disasm(WINDOW* out_win, unsigned short n0, unsigned short addr, unsigned short n0_next)
{
  int result;
	unsigned char n1, n2, n3, n4;
	//unsigned short n0;
	tParams p1, p2;
	int iscall;
  int callreg;
	int extranl;

  result = 2;  // normal instruction, otherwise return 4 if "extended instruction"

  // **************
  /*
  static unsigned short prev_n0 = 0xFFFF;
  static unsigned short prev_addr = 0xFFFF;

  if ((n0 == prev_n0) && (prev_addr == addr)) 
  {
    // if the address has not changed, and the opcode has not changed, then nothing new to disassemble...
    return;
  }
  prev_n0 = n0;
  prev_addr = addr;
  */
  // ****************

	iscall = 0;

	//while(!feof(datei))
	{
		//if(!fread(&n0, 2, 1, datei))
		//	continue;

		//n0 = (n0 >> 8) | ((n0 & 0xFF) << 8);  //<-- is this reversing it for endian?

		n1 = (n0 & 0xF000) >> 12;
		n2 = (n0 & 0x0F00) >> 8;
		n3 = (n0 & 0x00F0) >> 4;
		n4 = (n0 & 0x000F);

		p1 = None;
		p2 = None;
		extranl = 0;

    /*
		if(iscall && !(n1==13 && n2==0 && n3==callreg && n4==1))
		{
			wprintw(out_win, "  INC2 R%X, R0\n", callreg);
			iscall = 0;
		}
    */

		//if(!iscall)
		{
			wprintw(out_win, "%04X ", addr);
			wprintw(out_win, "%04X", n0);
			if(n1!=0 && n1!=13)
				wprintw(out_win, "  ");
		}
		//else
		//	wprintw(out_win, " %04X ", n0);

/*
		if(iscall)
			printf(" ");
		else if(n1 != 0)
			printf("\t\t\t");
*/

		switch(n1)
		{
			case 0:
				if(n0 == 0)
				{
					wprintw(out_win, "      HALT");
				}
				else if(n0 == 0x0004)
					wprintw(out_win, "      NOP");
				else if(n3==0x00 && n4==0x03)
				{
          wprintw(out_win, "      INC2 ");
          p1 = Reg1;
          p2 = Reg2;

					iscall = 1;
					callreg = n2;
				}
				else if(n2==0x00 && n4==0x04)
				{
					wprintw(out_win, "      RET ");
					p1 = Reg2;
					extranl = 1;
				}
				else
				{
					wprintw(out_win, "      %s ", Op_0[n4].Mnemonic);
					p1 = Op_0[n4].Nibble1;
					p2 = Op_0[n4].Nibble2;
				}
				break;

			case 1:
				wprintw(out_win, "    CTRL ");
				p1 = Device;
				p2 = Immediate;
				break;

			case 2:
				if(n2 == 0)
				{
					n0 = ((n3 << 4) | n4) << 1;
					wprintw(out_win, "    JMP ($%04X)", n0);
					extranl = 1;
				}
				else
				{
					wprintw(out_win, "    MOVE ");
					p1 = Reg1;
					p2 = WordAddr;
				}
				break;

			case 3:
				wprintw(out_win, "    MOVE ");
				p1 = WordAddr;
				p2 = Reg1;
				break;

			case 4:
				wprintw(out_win, "    PUTB $%X, (R%X)%s", n2, n3, FullTicks[n4]);
				break;

			case 5:
				wprintw(out_win, "    MOVE (R%X)%s, R%X", n3, HalfTicks[n4], n2);
				break;

			case 6:
				wprintw(out_win, "    MOVB R%X, (R%X)%s", n2, n3, FullTicks[n4]);
				break;

			case 7:
				wprintw(out_win, "    MOVB (R%X)%s, R%X", n3, FullTicks[n4], n2);
				break;

			case 8:
				wprintw(out_win, "    LBI ");
				p1 = Reg1;
				p2 = Immediate;
				break;

			case 9:
				wprintw(out_win, "    CLR ");
				p1 = Reg1;
				p2 = Immediate;
				break;

			case 10:
				n0 = (n3 << 4) | n4;
				n0++;
				if(n2 == 0)
				{
/*					printf("JMP $%02X(R0)\t\t; JMP $%04X", n0, addr+2+n0); */
					wprintw(out_win, "    BRA $%04X  ; $%02X(R0)", addr+2+n0, n0);
					extranl = 1;
				}
				else
					wprintw(out_win, "    ADD R%X, #$%02X", n2, n0);
				break;

			case 11:
				wprintw(out_win, "    SET ");
				p1 = Reg1;
				p2 = Immediate;
				break;

			case 12:
				wprintw(out_win, "    %s ", Op_C[n4].Mnemonic);
				p1 = Op_C[n4].Nibble1;
				p2 = Op_C[n4].Nibble2;
				break;

			case 13:  // 'D'
				if(n3==0 && n4==1)
				{
          n0 = n0_next;
          result = 4;
					//fread(&n0, 2, 1, datei);  // TBD read the next word
					//n0 = (n0 >> 8) | ((n0 & 0xFF) << 8);
					if(n2 == 0)
					{
							wprintw(out_win, " %04X JMP $%04X", n0, n0);
							extranl = 1;
					}
					else
						wprintw(out_win, " %04X LWI R%X, #$%04X", n0, n2, n0);

					addr += 2;
				}
				else if(n2==0 && n3==0 && n4==8)
				{
          n0 = n0_next;
          result = 4;
					//fread(&n0, 2, 1, datei);
					//n0 = (n0 >> 8) | ((n0 & 0xFF) << 8);
					wprintw(out_win, " %04X JMP $%04X", n0, n0);
					addr += 2;
					extranl = 1;
				}
				else
				{
					if(iscall)  // <-- won't happen but if prior OP is like D021
					{
            n0 = n0_next;
            result = 4;
						//fread(&n0, 2, 1, datei);
						//n0 = (n0 >> 8) | ((n0 & 0xFF) << 8);
						wprintw(out_win, "%04X CALL $%04X, R%X", n0, n0, callreg);
						addr += 2;

                  iscall = 0;
					}
					else if(n2 == 0)
						wprintw(out_win, "      JMP (R%X)%s", n3, HalfTicks[n4]);
					else
						wprintw(out_win, "      MOVE R%X, (R%X)%s", n2, n3, HalfTicks[n4]);
				}
				break;

			case 14:
				switch(n4)
				{
					case 12:
						if(n2 == 0)
							wprintw(out_win, "    SHR R%X", n3);
						break;

					case 13:
						if(n2 == 0)
							wprintw(out_win, "    ROR R%X", n3);
						break;

					case 14:
						if(n2 == 0)
							wprintw(out_win, "    ROR3 R%X", n3);
						break;

					case 15:
						if(n2 == 0)
							wprintw(out_win, "    SWAP R%X", n3);
						else
							wprintw(out_win, "    STAT R%X, $%X", n3, n2);
						break;
				}
				break;

			case 15:
				n0 = (n3 << 4) | n4;
				n0++;
				if(n2 == 0)
				{
/*					printf("JMP -$%02X(R0)\t\t; JMP $%04X", n0, addr+2-n0); */
					wprintw(out_win, "    BRA $%04X  ; -> -$%02X(R0)", addr+2-n0, n0);
					extranl = 1;
				}
				else
					wprintw(out_win, "    SUB R%X, #$%02X", n2, n0);
				break;
		}

		switch(p1)
		{
			case Reg1:
			case Reg:
				wprintw(out_win, "R%X", n2);
				break;

			case Reg2:
				wprintw(out_win, "R%X", n3);
				break;

			case Device:
				wprintw(out_win, "$%X", n2);
				break;

			case Immediate:
				wprintw(out_win, "#$%02X", (n3 << 4) | n4);
				break;

			case WordAddr:
				wprintw(out_win, "$%02X", ((n3 << 4) | n4) << 1);
				break;
		}

		switch(p2)
		{
			case Reg1:
				wprintw(out_win, ", R%X", n2);
				break;

         case Reg2:
			case Reg:
				wprintw(out_win, ", R%X", n3);
				break;

			case Immediate:
				wprintw(out_win, ", #$%02X", (n3 << 4) | n4);
				break;

			case Device:
				wprintw(out_win, ", $%X", n2);
				break;

			case WordAddr:
				wprintw(out_win, ", $%02X", ((n3 << 4) | n4) << 1);
				break;
		}

//    if(!iscall)
			wprintw(out_win, "\n");

//		if(extranl)
	//		wprintw(out_win, "\n");
		//addr += 2;
	}

  return result;
}
// **********************************************

int emu_fetch()
{
#ifdef LITTLE_ENDIAN
	USHORT swptmp;
#endif
  //static int prev_level = 99;
//  static USHORT prev_OP = 0xFFFF;
  static unsigned long long int instr_count[4] = {0,0,0,0};
  static char loaded_binary = FALSE;
	FILE *infile;
	char *fname, *base;
	unsigned long baseval;
  USHORT OP_temp;
  USHORT OP_temp_next;
  unsigned int OP_addr_long;
  USHORT a;
  int disasm_result;
  static unsigned short prev_n0 = 0xFFFF;
  static unsigned short prev_addr = 0xFFFF;

  if (loaded_binary == FALSE)
  {                   
    // only do this after the startup memory checks
    // because those checks overwrite RWS.
    // the following value was determined by trial and error (can be a little lower when BASIC used)
    if (instr_count[0] > 10000000)  
    {
      baseval = 0x0B00;

      // do LoadFile
	    infile = fopen(str_binary_load, "rb");
	    if(infile)
	    {
	      fread(&RWSb[baseval], 65536-baseval, 1, infile);
	      fclose(infile);
	    }
      loaded_binary = TRUE;  // or at least attempted to be loaded
    }
  }

  if ((step_mode == 1) || (disasm_trace != 0))
  {
    if (do_step == 0)
    {
      /*
      wclear(win_addr);

      wprintw(win_addr, "currROS ");
      if (curr_ros == ExecROS)
      {
        wprintw(win_addr, "EXECUTIVE\n");
      } 
      else if (curr_ros == APLROS)
      {
        wprintw(win_addr, "APL\n");
      }
      else if (curr_ros == CommonROS)
      {
        wprintw(win_addr, "COMMON\n");
      }
      else if (curr_ros == BASROS)
      {
        wprintw(win_addr, "BASIC\n");
      }
      else if (curr_ros == BASNXROS)
      {
        wprintw(win_addr, "BASIC NX\n");
      }
      else if (curr_ros == APLNXROS)
      {
        wprintw(win_addr, "APL NX\n");
      }
      else
      {
        wprintw(win_addr, "???\n");
      }

      wprintw(win_addr, "langROS ");
      if (language_ros == ExecROS)
      {
        wprintw(win_addr, "EXECUTIVE\n");
      } 
      else if (language_ros == APLROS)
      {
        wprintw(win_addr, "APL\n");
      }
      else if (language_ros == CommonROS)
      {
        wprintw(win_addr, "COMMON\n");
      }
      else if (language_ros == BASROS)
      {
        wprintw(win_addr, "BASIC\n");
      }
      else if (language_ros == BASNXROS)
      {
        wprintw(win_addr, "BASIC NX\n");
      }
      else if (language_ros == APLNXROS)
      {
        wprintw(win_addr, "APL NX\n");
      }
      else
      {
        wprintw(win_addr, "???\n");
      }

      wprintw(win_addr, "nx  ROS ");
      if (nxros == ExecROS)
      {
        wprintw(win_addr, "EXECUTIVE\n");
      } 
      else if (nxros == APLROS)
      {
        wprintw(win_addr, "APL\n");
      }
      else if (nxros == CommonROS)
      {
        wprintw(win_addr, "COMMON\n");
      }
      else if (nxros == BASROS)
      {
        wprintw(win_addr, "BASIC\n");
      }
      else if (nxros == BASNXROS)
      {
        wprintw(win_addr, "BASIC NX\n");
      }
      else if (nxros == APLNXROS)
      {
        wprintw(win_addr, "APL NX\n");
      }
      else
      {
        wprintw(win_addr, "???\n");
      }

      wprintw(win_addr, "OP = %04X\n%012lu", OP, instr_count[level]);
      wrefresh(win_addr);
      */

      // show disassembled opcode
      if (disasm_trace == 1)
      {
        // will show it later
      }
      else
      {

        if ((OP == prev_n0) && (prev_addr == OP_addr)) 
        {
          // if the address has not changed, and the opcode has not changed, then nothing new to disassemble...
          // nothing to do
        }
        else
        {
          prev_n0 = OP;
          prev_addr = OP_addr;

          //disasm_result = disasm(win_disasm, OP, OP_addr, OP_next); 
          wrefresh(win_disasm);
// ***********************************
          wclear(win_disasm_long);
          OP_addr_long = OP_addr-16;
          while ( OP_addr_long < OP_addr+16 )
          {
	  OP_temp = 
      ((mode[level] == MODE_RWS) ? 
        // "true", the current level is in RWS MODE
        RWS   // next instruction address always written to beginning of RWS (language ROS must be handling that)?
      : 
        // "false", the current level is not RWS MODE... examine further...
        (level ? 
          // "true" (1,2,3), force executive ROS
          ExecROS 
        : 
          // "false", index into the designated ROS for level 0
          curr_ros))[OP_addr_long >> 1];   // does >>1 imply a ROS can't be larger than 32K ?  (this limitation does not apply to non-executable ROS)

	  OP_temp_next = 
      ((mode[level] == MODE_RWS) ? 
        // "true", the current level is in RWS MODE
        RWS   // next instruction address always written to beginning of RWS (language ROS must be handling that)?
      : 
        // "false", the current level is not RWS MODE... examine further...
        (level ? 
          // "true" (1,2,3), force executive ROS
          ExecROS 
        : 
          // "false", index into the designated ROS for level 0
          curr_ros))[(OP_addr_long >> 1)+1];   // does >>1 imply a ROS can't be larger than 32K ?  (this limitation does not apply to non-executable ROS)



  #ifdef LITTLE_ENDIAN
	  OP_temp = SWAB(OP_temp);
	  OP_temp_next = SWAB(OP_temp_next);
  #endif

  //          OP_temp = RWS[OP_addr_long];
            if (OP_addr_long == OP_addr)
            {
              wattron(win_disasm_long, COLOR_PAIR(0) | A_BOLD);  // "bright" white
            }
            else if (OP_addr_long == OP_addr+disasm_result)
            { 
              wattron(win_disasm_long, COLOR_PAIR(5) | A_BOLD);  // yellow
            }
            else
            {
              wattroff(win_disasm_long, COLOR_PAIR(5) | A_BOLD);  // back to normal white
            }
            disasm_result = disasm(win_disasm_long, OP_temp, OP_addr_long, OP_temp_next);
          
            OP_addr_long += disasm_result;
            a = 0;
          }
  // ***********************************
          wrefresh(win_disasm_long);
        }

        
      }

      if (disasm_trace != 0)
      {
        // proceed
      }
      else
      {
        return 0;
      }
    }
  }

  check_int();		/* check for pending interrupts */

  /*
  if (level != prev_level)
  {
    wprintw(win_cpu, "%d", level);
    wrefresh(win_cpu);
    prev_level = level;
  }
  */

//  mvprintw(2, 160, "a");
//  mvprintw(2, 150, "test");  //%04X", &RWS);

  OP_addr = RWS[level * 16];
  if (OP_addr == 0x0B00)
  {
    if (start_step_at == -1)
    {
      start_step_at = instr_count[level]+1;
      wprintw(win_disasm, "[0x0B00 @ %lu]\n", instr_count[level]);
      wprintw(win_disasm, "[0x0B00 @ %lu]\n", instr_count[level]);
      wprintw(win_disasm, "[0x0B00 @ %lu]\n", instr_count[level]);
    }
  }

	OP = 
    ((mode[level] == MODE_RWS) ? 
      // "true", the current level is in RWS MODE
      RWS   // next instruction address always written to beginning of RWS (language ROS must be handling that)?
    : 
      // "false", the current level is not RWS MODE... examine further...
      (level ? 
        // "true" (1,2,3), force executive ROS
        ExecROS 
      : 
        // "false", index into the designated ROS for level 0
        curr_ros))[curr_regs[0] >> 1];   // does >>1 imply a ROS can't be larger than 32K ?  (this limitation does not apply to non-executable ROS)

	OP_next = 
    ((mode[level] == MODE_RWS) ? 
      // "true", the current level is in RWS MODE
      RWS   // next instruction address always written to beginning of RWS (language ROS must be handling that)?
    : 
      // "false", the current level is not RWS MODE... examine further...
      (level ? 
        // "true" (1,2,3), force executive ROS
        ExecROS 
      : 
        // "false", index into the designated ROS for level 0
        curr_ros))[(curr_regs[0] >> 1)+1];   // does >>1 imply a ROS can't be larger than 32K ?  (this limitation does not apply to non-executable ROS)


#ifdef LITTLE_ENDIAN
	OP = SWAB(OP);
	OP_next = SWAB(OP_next);
#endif

  if (start_step_at == instr_count[level]+1)
  {
    wprintw(win_disasm, "startup OP count reached...\n");

    step_mode = 1;
    start_step_at = 0;
  }

  //prev_OP = OP;
  if (step_mode == 1)  
  {
    if (do_step == 0)
    {
      return 0;
    }
    else  // do_step == 1
    {
      --do_step;
    }
  }
  ++instr_count[level];
  if (instr_count[level] == ULLONG_MAX)
  {
    instr_count[level] = 0;
  }

  // OP is short (16-bit)
  //  _ _ _ _  _ _ _ _ | _ _ _ _  _ _ _ _
  //             n1        n2       n3                        

  // nibbles of opcode
  n1 = (OP&0x0F00)>>8;
	n2 = (OP&0x00F0)>>4;
	n3 = (OP&0x000F);

	/* some kludges */
	if(!level && mode[0]==MODE_ROS && curr_ros==ExecROS)
	{
		if(curr_regs[0]==0x42CC)
		{
			/* ring the bell when the Screen I/O routine "beep" is called */
			fprintf(stderr, "\007");
		}
		else if(curr_regs[0]==0x4A00)
		{
			/* the Printer I/O supervisor is completely emulated */
			PrinterIO(curr_regs[3]);
			curr_regs[0] = 0x5142;
		}
	}


	INC_PC;
	emuvar_timer++;

	switch(OP>>12)
	{
		case 0:
			Opcode0();
			break;

		case 1:		/* CTRL */
			DoCTRL(n1, IMM);
			break;
			
		case 2:		/* MOVE Rx, i' */
#ifdef LITTLE_ENDIAN
			if(IMM < 0x0040)
				curr_regs[n1] = RWS[IMM];
			else
				curr_regs[n1] = SWAB(RWS[IMM]);
#else
			curr_regs[n1] = RWS[IMM];
#endif
			break;
			
		case 3:		/* MOVE i', Rx */
#ifdef LITTLE_ENDIAN
			if(IMM < 0x0040)
				RWS[IMM] = curr_regs[n1];
			else
				RWS[IMM] = SWAB(curr_regs[n1]);
#else
			RWS[IMM] = curr_regs[n1];
#endif

			break;
			
		case 4:		/* PUTB i, (Rx)* */
#ifdef LITTLE_ENDIAN
			swptmp = curr_regs[n2];
			if(swptmp < 0x0080)
				swptmp ^= 1;
			DoPUTB(n1, RWSb[swptmp]);
#else
			DoPUTB(n1, RWSb[curr_regs[n2]]);
#endif
			POSTCREMENT
			break;
			
		case 5:		/* MOVE (Ry)*, Rx */
#ifdef LITTLE_ENDIAN
			swptmp = curr_regs[n2];
			if(swptmp < 0x0080)
				RWS[swptmp>>1] = curr_regs[n1];
			else
				RWS[swptmp>>1] = SWAB(curr_regs[n1]);
#else
			RWS[curr_regs[n2]>>1] = curr_regs[n1];
#endif
			POSTCREMENT
			break;
			
		case 6:		/* MOVB Rx, (Ry)* */
#ifdef LITTLE_ENDIAN
			swptmp = curr_regs[n2];
			if(swptmp < 0x0080)
				swptmp ^= 1;
			curr_regs[n1] = (USHORT)(RWSb[swptmp]);
#else
			/* This is correct, since Hi(Rx) must be set to 0 */
			curr_regs[n1] = (USHORT)(RWSb[curr_regs[n2]]);
#endif
			if(n1 != n2)
				POSTCREMENT
			break;

		case 7:		/* MOVB (Ry)*, Rx */
#ifdef LITTLE_ENDIAN
			swptmp = curr_regs[n2];
			if(swptmp < 0x0080)
				swptmp ^= 1;
			RWSb[swptmp] = REGLO(n1);
#else
			RWSb[curr_regs[n2]] = REGLO(n1);
#endif
			POSTCREMENT
			break;
			
		case 8:		/* LBI Rx, i */
			REGLO(n1) = IMM;
			break;
			
		case 9:		/* CLR Rx, i */
			REGLO(n1) &= ~IMM;
			break;
			
		case 10:		/* ADD Rx, i */
			curr_regs[n1] += IMM+1;
			break;
			
		case 11:		/* SET Rx, i */
			REGLO(n1) |= IMM;
			break;
			
		case 12:		/* Skip instructions */
			OpcodeC();
			break;
			
		case 13:		/* MOVE Rx, (Ry)* */
#ifdef LITTLE_ENDIAN
			swptmp = curr_regs[n2];
			if(swptmp < 0x0080)
				curr_regs[n1] = RWS[swptmp>>1];
			else
				curr_regs[n1] = SWAB(RWS[swptmp>>1]);
#else
			curr_regs[n1] = RWS[curr_regs[n2]>>1];
#endif
			if(n1 != n2)
				POSTCREMENT
			break;
			
		case 14:		/* STAT or Shift/Rotate */
			OpcodeE();
			break;
			
		case 15:		/* SUB Rx, i */
			curr_regs[n1] -= (IMM+1);
			break;
	}

  if (disasm_trace != 0)
  {
        if ((OP == prev_n0) && (prev_addr == OP_addr)) 
        {
          // if the address has not changed, and the opcode has not changed, then nothing new to disassemble...
          // nothing to do
        }
        else
        {
          prev_n0 = OP;
          prev_addr = OP_addr;

          disasm(win_disasm, OP, OP_addr, OP_next); 
          wrefresh(win_disasm);
        }
  }

	TRACE(0, 0);

	return halt;
}

void trace_apl(UBYTE b, int x)
{
	if(!dump || level || mode[0]!=MODE_ROS || curr_ros!=APLROS)
		return;

	if(curr_regs[0]==0x01FE)
	{
		fprintf(dumpfile, "\n%05X(%04X):", nxros_addr<<1, nxros_addr);
	}
	else if(curr_regs[0]==0x020E)
	{
		fprintf(dumpfile, "\n%05X(RWS): %02X %02X", curr_regs[14]-2,
				REGHI(4), REGLO(4));
	}
	else if(curr_regs[0]==0x0208 || curr_regs[0]==0x0218)
	{
		fprintf(dumpfile, " (->%04X)", SWAB(RWS[curr_regs[2]>>1]));
	}
	else if(curr_regs[0] == 0x03D4)
	{
		fprintf(dumpfile, "\n***Access Exception:");
		dump_regs();
	}
	else if(curr_regs[0] == 0x03C0)
	{
		fprintf(dumpfile, "\n***Data Exception:");
		dump_regs();
	}
	else if(x)
	{
		fprintf(dumpfile, " %02X", b);
	}
}

void trace_basic(UBYTE b, int x)
{
	if(!dump || level || mode[0]!=MODE_ROS || curr_ros!=BASROS)
		return;

	if(curr_regs[0] == 0x019A)
	{
		fprintf(dumpfile, "\n%05X(%04X):", nxros_addr<<1, nxros_addr);
	}
	else if(x)
	{
		fprintf(dumpfile, " %02X", b);
		dump_regs();
	}
}

void check_int()
{
	DiskIRQ();
	TapeIRQ();
/*	PrinterIRQ(); */

	if(int_mask&INT_ENA && (int1||int2||int3))
	{
		/* interrupt occured, select level by priority */

		if(int3 && int_mask&INT_3)
		{
			level = 3;
		}
		else if(int2 && int_mask&INT_2)
		{
			level = 2;
		}
		else if(int1 && int_mask&INT_1)
		{
			level = 1;
		}

		curr_regs = &RWS[level<<4];  // the register file for the current interrupt level is stored in RWS first 128-bytes/64-words (32 registers per interrupt level)
    // level 0 == 00 0000    0 (to 15)
    // level 1 == 01 0000   16 (to 31)
    // level 2 == 10 0000   32 (to 47)
    // level 3 == 11 0000   48 (to 63)

		curr_regsb = (UBYTE *)curr_regs;
	}
	else if(level != 0)
	{
		/* interrupt cleared, switch back to level 0 */
		level = 0;
		curr_regs = RWS;
		curr_regsb = (UBYTE *)RWS;
	}
}

void emu_start()
{ 
  halt = FALSE; 
}

int emu_do()
{
	int i;
	
	i = 0;
	while(i++<50 && !emu_fetch());

	return halt;
}		

void dump_regs()
{
	int i;
	FILE *x;
	
	if(dump)
		x=dumpfile;
	else
		x=stderr;
		
	fprintf(x, "\n");
#ifdef LITTLE_ENDIAN
	for(i=0; i<8; i++)
		fprintf(x, "R%02d:%02X%02X  ", i, REGHI(i), REGLO(i));
	fprintf(x, "\n");
	for(i=8; i<16; i++)
		fprintf(x, "R%02d:%02X%02X  ", i, REGHI(i), REGLO(i));
	fprintf(x, "\n");
#else
	for(i=0; i<8; i++)
		fprintf(x, "R%02d:%04X  ", i, curr_regs[i]);
	fprintf(x, "\n");
	for(i=8; i<16; i++)
		fprintf(x, "R%02d:%04X  ", i, curr_regs[i]);
	fprintf(x, "\n");
#endif
}

void Opcode0()
{
	UBYTE tmp;
	
	switch(n3)
	{
		case 0:		/* DEC2 */
			curr_regs[n1] = curr_regs[n2] - 2;
			break;
		case 1:		/* DEC */
			curr_regs[n1] = curr_regs[n2] - 1;
			break;
		case 2:		/* INC */
			curr_regs[n1] = curr_regs[n2] + 1;
			break;
		case 3:		/* INC2 */
			curr_regs[n1] = curr_regs[n2] + 2;
			break;
		case 4:		/* MOVE Rx, Ry */
			curr_regs[n1] = curr_regs[n2];
			break;
		case 5:		/* AND Rx, Ry */
			REGLO(n1) &= REGLO(n2);
			break;
		case 6:		/* OR Rx, Ry */
			REGLO(n1) |= REGLO(n2);
			break;
		case 7:		/* XOR Rx, Ry */
			REGLO(n1) ^= REGLO(n2);
			break;
		case 8:		/* ADD Rx, Ry */
			curr_regs[n1] += (UBYTE)REGLO(n2);
			break;
		case 9:		/* SUB Rx, Ry */
			curr_regs[n1] -= (USHORT)REGLO(n2);
			break;
		case 10:		/* ADDH Rx, Ry */
			curr_regs[n1] = (USHORT)REGHI(n1) + (USHORT)REGLO(n2);
			break;
		case 11:		/* ADDH2 Rx, Ry */
			curr_regs[n1] = (USHORT)REGHI(n1) + (USHORT)REGLO(n2);
			curr_regs[n1] -= 0x100;
			break;
		case 12:		/* MHL Rx, Ry */
			REGLO(n1) = REGHI(n2);
			break;
		case 13:		/* MLH Rx, Ry */
			REGHI(n1) = REGLO(n2);
			break;
		case 14:		/* GETB Ry, i */
			REGLO(n2) = DoGETB(n1);
			break;
		case 15:		/* GETADD Ry, i */
			tmp = DoGETB(n1);
			if((tmp&0xFE) == 0xFE)
			{
				/* add zero */
			}
			else if((tmp&0xFE) == 0xFC)
				curr_regs[n2] += 2;
			else if((tmp&0xFC) == 0xF8)
				curr_regs[n2] += 4;
			else if((tmp&0xF8) == 0xF0)
				curr_regs[n2] += 6;
			else if((tmp&0xF0) == 0xE0)
				curr_regs[n2] += 8;
			else if((tmp&0xE0) == 0xC0)
				curr_regs[n2] += 10;
			else if((tmp&0xC0) == 0x80)
				curr_regs[n2] += 12;
			else if((tmp&0x80) == 0x00)
				curr_regs[n2] += 14;

			break;
	}
}

void OpcodeC()
{
	switch(n3)
	{
		case 0:		/* SLE */
			if(REGLO(n1) <= REGLO(n2))
				INC_PC;
			else
				curr_regs[1] = curr_regs[0] + 2;
			break;
			
		case 1:		/* SLT */
			if(REGLO(n1) < REGLO(n2))
				INC_PC;
			else
				curr_regs[1] = curr_regs[0] + 2;
			break;
			
		case 2:		/* SE */
			if(REGLO(n1) == REGLO(n2))
				INC_PC;
			else
				curr_regs[1] = curr_regs[0] + 2;
			break;
			
		case 3:		/* SZ */
			if(REGLO(n1) == 0)
				INC_PC;
			else
				curr_regs[1] = curr_regs[0] + 2;
			break;
			
		case 4:		/* SS */
			if(REGLO(n1) == 0xFF)
				INC_PC;
			else
				curr_regs[1] = curr_regs[0] + 2;
			break;
			
		case 5:		/* SBS */
			if((REGLO(n1)&REGLO(n2)) == REGLO(n2))
				INC_PC;
			else
				curr_regs[1] = curr_regs[0] + 2;
			break;

		case 6:		/* SBC */
			if((REGLO(n1)&REGLO(n2)) == 0)
				INC_PC;
			else
				curr_regs[1] = curr_regs[0] + 2;
			break;

		case 7:		/* SBSH */
			if((REGHI(n1)&REGLO(n2)) == REGLO(n2))
				INC_PC;
			else
				curr_regs[1] = curr_regs[0] + 2;
			break;

		case 8:		/* SGT */
			if(REGLO(n1) > REGLO(n2))
				INC_PC;
			else
				curr_regs[1] = curr_regs[0] + 2;
			break;
			
		case 9:		/* SGE */
			if(REGLO(n1) >= REGLO(n2))
				INC_PC;
			else
				curr_regs[1] = curr_regs[0] + 2;
			break;
			
		case 10:		/* SNE */
			if(REGLO(n1) != REGLO(n2))
				INC_PC;
			else
				curr_regs[1] = curr_regs[0] + 2;
			break;
			
		case 11:		/* SNZ */
			if(REGLO(n1) != 0)
				INC_PC;
			else
				curr_regs[1] = curr_regs[0] + 2;
			break;
			
		case 12:		/* SNS */
			if(REGLO(n1) != 0xFF)
				INC_PC;
			else
				curr_regs[1] = curr_regs[0] + 2;
			break;
			
		case 13:		/* SNBS */
			if((REGLO(n1)&REGLO(n2)) != REGLO(n2))
				INC_PC;
			else
				curr_regs[1] = curr_regs[0] + 2;
			break;

		case 14:		/* SNBC */
			if((REGLO(n1)&REGLO(n2)) != 0)
				INC_PC;
			else
				curr_regs[1] = curr_regs[0] + 2;
			break;

		case 15:		/* SNBSH */
			if((REGHI(n1)&REGLO(n2)) != REGLO(n2))
				INC_PC;
			else
				curr_regs[1] = curr_regs[0] + 2;
			break;
	}
}

void OpcodeE()
{
	if(n1 == 0)
	{
		/* Shift/Rotate */
		switch(n3)
		{
			case 12:		/* SHR Rx */
				REGLO(n2) = (REGLO(n2)>>1) | (REGHI(n2)<<7);
				break;
				
			case 13:		/* ROR Rx */
				REGLO(n2) = (REGLO(n2)>>1) | (REGLO(n2)<<7);
				break;
				
			case 14:		/* ROR3 Rx */
				REGLO(n2) = (REGLO(n2)>>3) | (REGLO(n2)<<5);
				break;
			
			case 15:		/* SWAP Rx */
				REGLO(n2) = (REGLO(n2)>>4) | (REGLO(n2)<<4);
		}
	}
	else
	{
		/* GETB/STAT */

		if(n3 >= 0xC)
		{
			/* STAT */
			switch(n1)
			{
				case 1:	/* Common/Language ROS */
					if(!nxros_xtoggle)
						REGLO(n2) = nxros_addr >> 8;
					else
						REGLO(n2) = nxros_addr & 0xFF;
					nxros_xtoggle = 1-nxros_xtoggle;
					break;
					
				case 2:	/* Executable ROS */
					if(REGLO(n2) == 0x80)
						REGLO(n2) = 0xF0;
					else if(REGLO(n2) == 0x40)
						REGLO(n2) = 0xC0;
					else if(REGLO(n2) == 0x20)
						REGLO(n2) = 0x80;
					break;
					
				case 4:	/* Keyboard */
					if(REGLO(n2) == 0x80)
					{
						/* Read status */
						if(language_ros == BASROS)
							REGLO(n2) = 0x76;
						else
							REGLO(n2) = 0x36;

						if(kbdcode)
							REGLO(n2) |= 0x08;
					}
					else if(REGLO(n2) == 0x40)
					{
						/* Read scancode */
						REGLO(n2) = kbdcode;
						kbdcode = 0;
					}
					break;
					
				case 5:	/* Printer */
					REGLO(n2) = PrinterSTAT();
					break;
					
				case 13:	/* Diskette */
					REGLO(n2) = DiskSTAT();
					break;
					
				case 14:	/* Tape */
					REGLO(n2) = TapeSTAT(REGLO(n2));
					break;
					
				default:
					REGLO(n2) = 0xFF;
			}
		}
		else
		{
			/* GETB */
#ifdef LITTLE_ENDIAN
			USHORT swptmp;

			swptmp = curr_regs[n2];
			if(swptmp < 0x0080)
				swptmp ^= 1;
			RWSb[swptmp] = DoGETB(n1);
#else
			RWSb[curr_regs[n2]] = DoGETB(n1);
#endif
			POSTCREMENT
		}
	}
}

void DoCTRL(int dev, int imm)
{
	switch(dev)
	{
		case 0:	/* Processor/Display */
			if(!(imm&0x40))
				int_mask &= ~INT_ENA;
			else if(!(imm&0x20))
				int_mask |= INT_ENA;

			if(!(imm&0x10))
				emuvar_display = 0;
			else if(!(imm&0x08))
				emuvar_display = 1;
				
			if(!(imm&4))
			{
				if(mode[0] == MODE_ROS)
				{
					mode[0] = MODE_RWS;
				}
				else
				{
					/* We're either in MODE_BUP or MODE_RWS */
					mode[0] = MODE_ROS;
				}
			}
			break;
			
		case 1:	/* Common/Language ROS */
			if((imm & 2)==2)
				nxros = CommonROS;
			else if((imm & 4)==4)
				nxros = APLNXROS;
			else if((imm & 8)==8)
				nxros = BASNXROS;
			nxros_rtoggle = 0;
			nxros_wtoggle = 0;
			nxros_xtoggle = 0;
			break;
			
		case 2:	/* Executable ROS */
			if(imm == 0xBF)
			{
				/* Switch to interpreter ROS */
				curr_ros = language_ros;
			}
			else if(imm == 0x7F)
			{
				/* Switch to Executable ROS */
				curr_ros = ExecROS;
			}
			break;
			
		case 4:	/* Keyboard */
			if(!(imm&0x40))
				int3 = FALSE;
			if(!(imm&0x01))
				int_mask |= INT_3;
			else
				int_mask &= ~INT_3;
			break;
			
		case 5:	/* Printer */
			PrinterCTRL(imm);
			break;
			
		case 13:	/* Diskette */
			DiskCTRL(imm);
			break;
			
		case 14:	/* Tape */
			TapeCTRL(imm);
			break;
			
		case 15:	/* Adapter reset */
			if(imm & 0x80)
			{
				/* Async. communications/Serial I/O */
			}
			if(imm & 0x40)
			{
				/* Tape adapter */
				TapeReset();
			}
			if(imm & 0x20)
			{
				/* Keyboard */
				int3 = FALSE;
				int_mask &= ~INT_3;
				kbdcode = 0;
			}
			if(imm & 0x10)
			{
				/* Printer */
				PrinterReset();
			}
			if(imm & 0x08)
			{
				/* Display adapter */
				emuvar_display = 1;
			}
			if(imm & 0x04)
			{
				/* Device B */
			}
			if(imm & 0x02)
			{
				/* Device C */
			}
			if(imm & 0x01)
			{
				/* Diskette adapter */
				DiskReset();
			}
			break;
	}
}

void DoPUTB(int dev, UBYTE c)
{
	switch(dev)
	{
		case 0:	/* Processor */
			if(c&0x40)
				mode[1] = MODE_RWS;
			else
				mode[1] = MODE_ROS;
			
			if(c&0x20)
				mode[2] = MODE_RWS;
			else
				mode[2] = MODE_ROS;
				
			if(c&0x10)
				mode[3] = MODE_RWS;
			else
				mode[3] = MODE_ROS;
				
			break;
			
		case 1:	/* Common|Language ROS */
			if(!nxros_wtoggle)
			{
				nxros_addr = ((USHORT)c) << 8;
				nxros_wtoggle = 1;
			}
			else
			{
				nxros_addr |= (USHORT)c;
				nxros_wtoggle = 0;
			}
			nxros_rtoggle = 0;
			nxros_xtoggle = 0;
			break;

		case 5:	/* Printer */
			PrinterPUTB(c);
			break;
			
		case 13:	/* Diskette */
			DiskPUTB(c);
			break;
			
		case 14:	/* Tape */
			TapePUTB(c);
			break;
	}
}

UBYTE DoGETB(int dev)
{
	UBYTE val;
	
	switch(dev)
	{
		case 1:	/* Common|Language ROS */
#ifdef LITTLE_ENDIAN
			if(!nxros_rtoggle)
				val = nxros[nxros_addr] & 0xFF;
			else
			{
				val = nxros[nxros_addr] >> 8;
				nxros_addr++;
			}
#else
			if(!nxros_rtoggle)
				val = nxros[nxros_addr] >> 8;
			else
			{
				val = nxros[nxros_addr] & 0xFF;
				nxros_addr++;
			}
#endif
			nxros_rtoggle = 1-nxros_rtoggle;
			TRACE(val, 1);
			break;

		case 5:	/* Printer */
			val = PrinterGETB();
			break;
			
		case 13:	/* Diskette */
			val = DiskGETB();
			break;
			
		case 14:	/* Tape */
			val = TapeGETB();
			break;
			
		default:
			val = 0xFF;
	}

	return val;
}

void emu_keyboard(UBYTE code)
{
	int3 = TRUE;
	kbdcode = code;
}

void emu_dump_mem()
{
	FILE *outfile;
	
	outfile = fopen("mem.dmp", "wb");
	if(!outfile)
		return;
	fwrite(RWS, 1, 65536, outfile);
	fclose(outfile);
}

void emu_toggle_dump()
{
	if(!dump)
	{
		dumpfile = fopen("emu.dmp", "w");
		if(dumpfile)
			dump = 1;
	}
	else
	{
		dump = 0;
		fclose(dumpfile);
	}
}

void emu_select_lang(int lang)
{
	if(lang)
		language_ros = APLROS;
	else
		language_ros = BASROS;
}

int load_ros()
{
	int err;
	FILE *infile;
	size_t rossize;

	ExecROS = NULL;
	APLROS = NULL;
	BASROS = NULL;
	CommonROS = NULL;
	APLNXROS = NULL;
	BASNXROS = NULL;

	infile = fopen(EXECROS_NAME, "rb");
	if(!infile)
		return ERR_EXECROS_FILE;
	fseek(infile, 0, SEEK_END);
	rossize = ftell(infile);
	fseek(infile, 0, SEEK_SET);
	printf("Size of Executable ROS: %d\n", rossize);
	ExecROS = (USHORT *)malloc(rossize);
	if(!ExecROS)
		return ERR_EXECROS_ALLOC;
	if(fread(ExecROS, 1, rossize, infile) != rossize)
		return ERR_EXECROS_READ;
	fclose(infile);

	infile = fopen(COMMONROS_NAME, "rb");
	if(!infile)
		return ERR_COMMONROS_FILE;
	fseek(infile, 0, SEEK_END);
	rossize = ftell(infile);
	fseek(infile, 0, SEEK_SET);
	printf("Size of Common ROS: %d\n", rossize);
	CommonROS = (USHORT *)malloc(65536*2);
	if(!CommonROS)
		return ERR_COMMONROS_ALLOC;
	memset(CommonROS, 0, 65536*2);
	if(fread(CommonROS, 1, rossize, infile) != rossize)
		return ERR_COMMONROS_READ;
	fclose(infile);

	infile = fopen(BASNXROS_NAME, "rb");
	if(!infile)
		return ERR_BASNXROS_FILE;
	fseek(infile, 0, SEEK_END);
	rossize = ftell(infile);
	fseek(infile, 0, SEEK_SET);
	printf("Size of NX BASIC ROS: %d\n", rossize);
	BASNXROS = (USHORT *)malloc(65536*2);
	if(!BASNXROS)
		return ERR_BASNXROS_ALLOC;
	memset(BASNXROS, 0, 65536*2);
	if(fread(BASNXROS, 1, rossize, infile) != rossize)
		return ERR_BASNXROS_READ;
	fclose(infile);

	infile = fopen(BASROS_NAME, "rb");
	if(!infile)
		return ERR_BASROS_FILE;
	fseek(infile, 0, SEEK_END);
	rossize = ftell(infile);
	fseek(infile, 0, SEEK_SET);
	printf("Size of BASIC ROS: %d\n", rossize);
	BASROS = (USHORT *)malloc(rossize);
	if(!BASROS)
		return ERR_BASROS_ALLOC;
	if(fread(BASROS, 1, rossize, infile) != rossize)
		return ERR_BASROS_READ;
	fclose(infile);

	infile = fopen(APLNXROS_NAME, "rb");
	if(!infile)
		return ERR_APLNXROS_FILE;
	fseek(infile, 0, SEEK_END);
	rossize = ftell(infile);
	fseek(infile, 0, SEEK_SET);
	printf("Size of NX APL ROS: %d\n", rossize);
	APLNXROS = (USHORT *)malloc(65536*2);
	if(!APLNXROS)
		return ERR_APLNXROS_ALLOC;
	memset(APLNXROS, 0, 65536*2);
	if(fread(APLNXROS, 1, rossize, infile) != rossize)
		return ERR_APLNXROS_READ;
	fclose(infile);

	infile = fopen(APLROS_NAME, "rb");
	if(!infile)
		return ERR_APLROS_FILE;
	fseek(infile, 0, SEEK_END);
	rossize = ftell(infile);
	fseek(infile, 0, SEEK_SET);
	printf("Size of APL ROS: %d\n", rossize);
	APLROS = (USHORT *)malloc(rossize);
	if(!APLROS)
		return ERR_APLROS_ALLOC;
	if(fread(APLROS, 1, rossize, infile) != rossize)
		return ERR_APLROS_READ;
	fclose(infile);

	return 0;
}

int emu_init()
{
	int err;

  step_mode = 0;
  disasm_trace = 0;
  do_step = 0;
  start_step_at = 0;

  initscr();
  resize_term(42, 200);

  start_color();
  curs_set(0);
  
  init_pair(1, COLOR_WHITE, COLOR_BLUE);

  /*
  win_cpu_height = 1;
  win_cpu_width = 19;
  win_cpu = newwin(win_cpu_height, win_cpu_width, 0, 150);  
  scrollok(win_cpu, 1);
  wbkgd(win_cpu, COLOR_PAIR(1));
  */

  /*
  win_addr_height = 6;
  win_addr_width = 19;
  win_addr = newwin(win_addr_height, win_addr_width, 3, 150);
  wbkgd(win_addr, COLOR_PAIR(1));
  */
  win_disasm_height = 8;
  win_disasm_width = 72;
  win_disasm = newwin(win_disasm_height, win_disasm_width, 8, 65);
  wprintw(win_console, "VEMU5110\n");
  scrollok(win_disasm, 1);
  wbkgd(win_disasm, COLOR_PAIR(1));

  win_disasm_long_height = 16;
  win_disasm_long_width = 56;
  win_disasm_long = newwin(win_disasm_long_height, win_disasm_long_width, 0, 140);
  scrollok(win_disasm_long, 0);
  wbkgd(win_disasm_long, COLOR_PAIR(1));

	dump = 0;
	
	RWS = (USHORT *)malloc(65536);  // all processing modes have access to 16-bit addresses
	if(!RWS)
	{
		err = ERR_RWS_ALLOC;
		goto error;
	}
  memset(RWS, 0, 65536);
	RWSb = (UBYTE *)RWS;
		
	err = load_ros();

error:
	if(err)
		printf("ERROR: ");
	switch(err)
	{
		case ERR_RWS_ALLOC:
			printf("Could not allocate memory for Read/Write Storage\n");
			break;
		case ERR_EXECROS_FILE:
			printf("Could not open Executable ROS file %s\n", EXECROS_NAME);
			break;
		case ERR_EXECROS_ALLOC:
			printf("Could not allocate memory for Executable ROS\n");
			break;
		case ERR_EXECROS_READ:
			printf("Error reading Executable ROS\n");
			break;
		case ERR_COMMONROS_FILE:
			printf("Could not open Common ROS file %s\n", COMMONROS_NAME);
			break;
		case ERR_COMMONROS_ALLOC:
			printf("Could not allocate memory for Common ROS\n");
			break;
		case ERR_COMMONROS_READ:
			printf("Error reading Common ROS\n");
			break;
		case ERR_APLROS_FILE:
			printf("Could not open APL ROS file %s\n", APLROS_NAME);
			break;
		case ERR_APLROS_ALLOC:
			printf("Could not allocate memory for APL ROS\n");
			break;
		case ERR_APLROS_READ:
			printf("Error reading APL ROS\n");
			break;
		case ERR_APLNXROS_FILE:
			printf("Could not open APL NX ROS file %s\n", APLNXROS_NAME);
			break;
		case ERR_APLNXROS_ALLOC:
			printf("Could not allocate memory for APL NX ROS\n");
			break;
		case ERR_APLNXROS_READ:
			printf("Error reading APL NX ROS\n");
			break;
		case ERR_BASROS_FILE:
			printf("Could not open BASIC ROS file %s\n", BASROS_NAME);
			break;
		case ERR_BASROS_ALLOC:
			printf("Could not allocate memory for BASIC ROS\n");
			break;
		case ERR_BASROS_READ:
			printf("Error reading BASIC ROS\n");
			break;
		case ERR_BASNXROS_FILE:
			printf("Could not open BASIC NX ROS file %s\n", BASNXROS_NAME);
			break;
		case ERR_BASNXROS_ALLOC:
			printf("Could not allocate memory for BASIC NX ROS\n");
			break;
		case ERR_BASNXROS_READ:
			printf("Error reading BASIC NX ROS\n");
			break;
	}
	
	return err;
}

void emu_cleanup()
{
	halt = TRUE;

	if(RWS) free(RWS);
	if(APLROS) free(APLROS);
	if(APLNXROS) free(APLNXROS);
	if(BASROS) free(BASROS);
	if(BASNXROS) free(BASNXROS);
	if(CommonROS) free(CommonROS);
	if(ExecROS) free(ExecROS);
}
