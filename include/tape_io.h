/*
   emu5110
	-------
	An emulator for the IBM 5110
	(C) 2007-2008 Christian Corti

  Adapted to Wintel (using winpthread and pdcurses) by Steve Lewis - 2022
	
	Tape I/O header file
*/

#ifndef _TAPEIO_H
#define _TAPEIO_H

#define TAPEIMG_CHUNK 2

#define TAPE_BIT_DELAY	16
#define TAPE_BYTE_DELAY	(TAPE_BIT_DELAY*8)

enum
{
	TAPEMODE_INIT, TAPEMODE_IDLE, TAPEMODE_READ, TAPEMODE_WRITE
};

#define TF_STOP			0x80
#define TF_REVERSE		0x40
#define TF_CHANNEL1		0x20
#define TF_READ			0x10
#define TF_NO_ERASE_0	0x08
#define TF_NO_ERASE_1	0x04
#define TF_NO_DIAG		0x02
#define TF_NO_IRQ			0x01

void TapeReset(void);
UBYTE TapeSTAT(UBYTE c);
UBYTE TapeGETB(void);
void TapePUTB(UBYTE c);
void TapeCTRL(UBYTE c);
void TapeIRQ(void);

#endif
