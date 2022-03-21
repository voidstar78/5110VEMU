/*
   emu5110
	-------
	An emulator for the IBM 5110
	(C) 2007-2008 Christian Corti

  Adapted to Wintel (using winpthread and pdcurses) by Steve Lewis - 2022
	
	Tape I/O
*/

#include <stdio.h>
#include <string.h>
//#include <unistd.h>  // Unix Standard
#include <errno.h>
#include "emu.h"
#include "tape_io.h"
#include "debug.h"

#define NUM_DRIVES 8
FILE *tapefile[NUM_DRIVES];
int tape_mounted[NUM_DRIVES];			/* boolean list of mounted tapes */
long tape_filepos[NUM_DRIVES];		/* current position in tape image file */

int tape_mode;								/* current mode of adapter (init etc.) */
int tape_bitmode;							/* indicates whether bit or byte mode */
UBYTE tdrive;								/* drive byte as sent from host */
int tdrv;									/* drive number 0..7 */
int tape_bits;								/* current bit position during bit mode */
UBYTE tape_rbyte;							/* contents of the read data latch */
UBYTE tape_wbyte;							/* value from a PUTB */
UBYTE tape_status, tape_ctrl;			/* adapter status and control byte */
int tape_bot;								/* TRUE if BOT hole has passed during rewind/reverse */
int tape_seek;								/* 1 seek fwd, -1 seek rev, 0 stop */

UBYTE tape_byte;							/* current byte read from tape image or to be written */
UBYTE tbuf[TAPEIMG_CHUNK];				/* buffer for one tape image chunk */

unsigned long tape_irq_counter;
int tape_irq_delay;

int TapeAttach(int d, char *name)
{
	UBYTE tmp[4];
	int i, j;

	if(d<0 || d>NUM_DRIVES-1 || !name)
		return FALSE;
		
	if(tapefile[d] && tape_mounted[d])
	{
		fclose(tapefile[d]);
		tape_mounted[d] = FALSE;
	}
		
	if(!(tapefile[d] = fopen(name, "rb+")))
	{
		if((errno==ENOENT) && !(tapefile[d] = fopen(name, "wb+")))
			return FALSE;
		else if(errno != ENOENT)
			return FALSE;
	}
	fseek(tapefile[d], 0, SEEK_SET);
	tape_filepos[tdrv] = 0L;
	tape_bot = FALSE;

	tape_mounted[d] = TRUE;
	return TRUE;
}

void TapeDetach(int d)
{
	if(d<0 || d>NUM_DRIVES-1 || !tapefile[d])
		return;
		
	fclose(tapefile[d]);
	tapefile[d] = NULL;
	tape_mounted[d] = FALSE;
}

void TapeSetup()
{
	int i;
	
	for(i=0; i<NUM_DRIVES; i++)
	{
		tape_mounted[i] = FALSE;
		tapefile[i] = NULL;
		tape_filepos[i] = 0L;
	}
	
	tape_irq_delay = TAPE_BIT_DELAY;
}

/***************/

int TapeReadByte()
{
	DEBUG_MSG("TAPE READ BYTE: %02X %ld\n", tape_ctrl, tape_filepos[tdrv]);

	if(tape_filepos[tdrv] < 0)
	{
		tape_status &= ~0x01;
		tape_bot = TRUE;
		DEBUG_MSG("TAPE READ BYTE ERROR: filepos < 0\n");
		return FALSE;
	}

	if(tape_ctrl & TF_REVERSE)
	{
		/* Backward Read */
		if(fseek(tapefile[tdrv], tape_filepos[tdrv], SEEK_SET) < 0)
		{
			return FALSE;
		}
		
		tape_filepos[tdrv] -= TAPEIMG_CHUNK;
	}
	else
	{
		/* Forward Read */
		if(fseek(tapefile[tdrv], tape_filepos[tdrv], SEEK_SET) < 0)
		{
			return FALSE;
		}
		
		tape_filepos[tdrv] += TAPEIMG_CHUNK;
	}

	if(fread(tbuf, 1, TAPEIMG_CHUNK, tapefile[tdrv]) != TAPEIMG_CHUNK)
	{
		tbuf[0] = 0;
		tbuf[1] = 0;
	}

	tape_byte = tbuf[1];
	if(tape_ctrl & TF_CHANNEL1)
	{
		if(tbuf[0] & 0x80)		/* data on channel 1 available? */
			return TRUE;
	}
	else
	{
		if(tbuf[0] & 0x40)		/* data on channel 0 available? */
			return TRUE;
	}

	return FALSE;
}

void TapeWriteByte()
{
	if(tape_ctrl & TF_CHANNEL1)
	{
		tbuf[0] = 0x40;
	}
	else
	{
		tbuf[0] = 0x80;
	}
	tbuf[1] = tape_byte;
	
	if(tape_filepos[tdrv] < 0)
	{
		DEBUG_MSG("TAPE WRITE BYTE ERROR: filepos < 0\n");
		return;
	}

	DEBUG_MSG("TAPE WRITE BYTE: %02X %02X %ld\n", tbuf[0], tbuf[1], tape_filepos[tdrv]);
	
	if(tape_ctrl & TF_REVERSE)
	{
		/* Backward Write (not sure whether used at all) */
		if(fseek(tapefile[tdrv], tape_filepos[tdrv], SEEK_SET) < 0)
		{
			return;
		}
		
		tape_filepos[tdrv] -= TAPEIMG_CHUNK;
	}
	else
	{
		/* Forward Write */
		if(fseek(tapefile[tdrv], tape_filepos[tdrv], SEEK_SET) < 0)
		{
			return;
		}
		
		tape_filepos[tdrv] += TAPEIMG_CHUNK;
	}
	
	fwrite(tbuf, 1, TAPEIMG_CHUNK, tapefile[tdrv]);
	fflush(tapefile[tdrv]);
}

int TapeRead()
{
	if(!tape_mounted[tdrv] || tape_mode!=TAPEMODE_READ)
		return FALSE;
		
	if(tape_bitmode)
	{
		/* hack; see TapePUTB */
		if(tape_wbyte & 0x80)
		{
			tape_wbyte &= 0x7F;
			tape_bits = 0;
		}
		
		if(tape_bits <= 0)
		{
			/* no bits left, read new byte from image */
			if(!TapeReadByte())
				return FALSE;
			else
				DEBUG_MSG(" -- TAPE READ BIT MODE(%02X): %02X %ld PC:%04X\n", tape_ctrl, tape_byte, tape_filepos[tdrv], curr_regs[0]);
			tape_bits = 7;
			tape_rbyte = tape_byte >> 7;
		}
		else
		{
			tape_bits--;
			tape_rbyte = (tape_rbyte<<1) | ((tape_byte&(1<<tape_bits))>>tape_bits);
		}
	}
	else
	{
		if(!TapeReadByte())
			return FALSE;

		tape_rbyte = tape_byte;
		DEBUG_MSG(" -- TAPE READ BYTE MODE(%02X): %02X %ld PC:%04X\n", tape_ctrl, tape_rbyte, tape_filepos[tdrv], curr_regs[0]);
	}
	
	return TRUE;
}

void TapeWrite()
{
	if(tape_bits <= 0)
	{
		tape_bits = 7;		/* remaining bits */
		tape_byte = (tape_wbyte & 1);
	}
	else
	{
		tape_byte <<= 1;
		tape_byte |= (tape_wbyte & 1);

		tape_bits--;
		if(tape_bits <= 0)
		{
			/* assembled one byte, write to image */
			TapeWriteByte();
		}
	}
}

/***************/

void TapeReset()
{
	DEBUG_MSG("\nTAPE RESET\n");

	tape_mode = TAPEMODE_INIT;
	tdrv = 0;
	tdrive = 0;
	tape_status = 0x05;
	tape_ctrl   = 0xFF;
	tape_bitmode = TRUE;
	tape_irq_delay = TAPE_BIT_DELAY;
	tape_bits    = 0;
	tape_bot     = FALSE;
	emuvar_timer = 0;

	tape_seek = FALSE;
}

UBYTE TapeSTAT(UBYTE c)
{
	UBYTE val;

	if(tape_seek)
	{
		if(tape_ctrl & TF_REVERSE)
		{
			tape_filepos[tdrv] -= TAPEIMG_CHUNK;
			if(tape_filepos[tdrv] < 0)
			{
				tape_filepos[tdrv] = 0;
				tape_status &= ~0x01;
				tape_bot = TRUE;
			}
		}
		else
		{
			tape_filepos[tdrv] += TAPEIMG_CHUNK;
		}
	}

	if(c & 0x80)
	{
		/* Read Data Latch */
		val = tape_rbyte;
	}
	else if(c & 0x40)
	{
		/* Status */
		if(tape_mounted[tdrv])
			tape_status |= 0x10;
		else
			tape_status &= ~0x10;

		val = tape_status;
	}
	else
		val = 0xF7;
	
	return val;
}

UBYTE TapeGETB()
{
	UBYTE val;
	
	if(tape_mode == TAPEMODE_IDLE)
	{
		val = ~tdrive;
	}
	else
		val = 0x00;
		
	/* GETB resets some status bits (see IBM 5100 MIM page 5-23) */
	tape_status |= 0x11; /* 0x13 */

	int2 = FALSE;		/* GETB resets interrupt */		
	return val;
}

void TapePUTB(UBYTE c)
{
	if(tape_ctrl & TF_READ)
	{
		tape_bits = 0;

		if(c & 0x20)
		{
			tape_bitmode = TRUE;
			tape_irq_delay = TAPE_BIT_DELAY;
			
			c |= 0x80; 	/* hack; flag to reset tape_bits */
		}
		else
		{
			tape_bitmode = FALSE;
			tape_irq_delay = TAPE_BYTE_DELAY;
		}
	}

	tape_wbyte = c;
	
	if(!(c & 0x02))
	{
		/* First Transition */
		tape_bits = 0;
	}

	TapeWrite();
}

void TapeCTRL(UBYTE c)
{
	DEBUG_MSG("\nTAPE CTRL:%02X PC:%04X %ld\n", c, curr_regs[0], tape_filepos[tdrv]);
	
	if(tape_mode == TAPEMODE_INIT)
	{
		tdrive = c;
		tdrv = -1;
		while(c&0xFF)
		{
			c <<= 1;
			tdrv++;
		}
		tdrv &= (1<<NUM_DRIVES)-1;

		tape_mode = TAPEMODE_IDLE;
		return;
	}

	else
	{
		if(!(c & TF_STOP))
		{
			if(c & TF_READ)
			{
				tape_mode = TAPEMODE_READ;

				if(c & TF_NO_IRQ)
				{
					if(c & TF_REVERSE)
					{
						if(tape_filepos[tdrv] >= TAPEIMG_CHUNK)
						{
							tape_filepos[tdrv] -= 5*TAPEIMG_CHUNK;
						}
						else
						{
							tape_filepos[tdrv] = 0;
							tape_status &= ~0x01;
							tape_bot = TRUE;			/* on the wrong side of BOT... */
						}
					}
					else
					{
						if(tape_bot)
						{
							tape_filepos[tdrv] = 0;
							tape_status &= ~0x01;
							tape_bot = FALSE;			/* we're on the right side again */
						}
					}
					
					tape_seek = TRUE;		/* tape in motion and no read/write */
				}
				else
					tape_seek = FALSE;	/* IRQ means read/write, not seek */
			}
			else
			{
				tape_mode = TAPEMODE_WRITE;
				tape_irq_counter = 0;
				tape_irq_delay = TAPE_BIT_DELAY;
				int2 = FALSE;
				
				tape_seek = FALSE;		/* never seek when writing */
			}
				
			tape_status |= 0x20;		/* tape running */
		}
		else
		{
			tape_status &= ~0x20;	/* tape stopped */
			tape_seek = FALSE;
		}
		
		if((c&0x0C) != 0x0C)
		{
			/* Erase On */
			tape_status |= 0x08;
		}
		else
			tape_status &= ~0x08;
			
		if(c & TF_NO_IRQ)
		{
			int2 = FALSE;
		}
	}

	tape_ctrl = c;
}

void TapeIRQ()
{
	if(tape_ctrl & (TF_NO_IRQ | TF_STOP))
		return;
		
	tape_irq_counter++;

	if(tape_irq_counter > tape_irq_delay)
	{
		tape_irq_counter = 0;

		if(tape_mode == TAPEMODE_READ)
		{
			if(!TapeRead())
				return;
		}

		int2 = TRUE;
	}
}
