/*
   emu5110
	-------
	An emulator for the IBM 5110
	(C) 2007-2008 Christian Corti

  Adapted to Wintel (using winpthread and pdcurses) by Steve Lewis - 2022
	
	Printer I/O
*/

#include <stdio.h>
#include <string.h>
//#include <unistd.h>  // Unix Standard
#include "emu.h"
#include "printer_io.h"

#define PRINTER_DEBUG 0

extern UBYTE EBCDIC2ASCII[];

int prt_diag;
int prt_timerints, prt_timer;
int irq_counter;

UBYTE prt_stat;

FILE *prtfile;

int PrinterAttach()
{
	prtfile = fopen("printer.out", "a");
	if(!prtfile)
		return FALSE;
		
	return TRUE;
}

void PrinterDetach()
{
	if(prtfile)
		fclose(prtfile);
	prtfile = NULL;
}

void PrinterIO(USHORT iocbptr)
{
	struct sIOCB *IOCB;
	int i, len;
	UCHAR c;
	
	IOCB = (struct sIOCB *)&RWSb[iocbptr];
	
	switch(IOCB->Cmd)
	{
		case IO_SENSE:
#if PRINTER_DEBUG
			fprintf(stderr, "\nIOCB Printer Sense\n");
#endif

			/* Preset the buffer size to 132 characters/line.
			   This is *very* important since BASIC does not
                           set it on its own 
			*/
			IOCB->BS = SWAB(132);

			/* This status is expected by e.g. the BASIC interpreter */
			/* (refer to execros.asm 4A00-4A24) */
			IOCB->Stat1 = SWAB(0x4824);
			
			IOCB->WA = 0;
			IOCB->Ret = 0;

			break;
			
		case IO_WRITELAST:
		case IO_WRITE:
			len = SWAB(IOCB->BS);
			if(prt_diag)
				printf("%05d: ", len);
			for(i=0; i<len; i++)
			{
				c = RWSb[SWAB(IOCB->BA)+i];
				if(prt_diag)
					printf("%02X ", c);
				else
					putc(EBCDIC2ASCII[c], prtfile);
			}

			/* Do line feeds */
			len = SWAB(IOCB->CI1);
			if(IOCB->Flags & 0x02)
				len = len >> 4;
			for(i=0; i<len; i++)
				putc('\n', prtfile);
			fflush(prtfile);
			
			IOCB->Ret = 0;
			break;
			
		default:
			fprintf(stderr, "\nUnknown IOCB Printer Command: %d\n", IOCB->Cmd);
			IOCB->Ret = SWAB(0xF0F2);
	}
}

void PrinterReset()
{
#if PRINTER_DEBUG
	fprintf(stderr, "\nPrinter Reset\n");
#endif
	prt_stat = 0x44;
	prt_diag = 0;
}

void PrinterPUTB(UBYTE c)
{
#if PRINTER_DEBUG
	fprintf(stderr, "\nPrinter PUTB: %02X\n", c);
#endif
}

void PrinterCTRL(UBYTE c)
{
#if PRINTER_DEBUG
	fprintf(stderr, "\nPrinter CTRL: %02X\n", c);
#endif

	switch(c)
	{
		case 0xD1:	/* Enable timer interrupts */
			prt_timerints = TRUE;
			break;
			
		case 0x51:	/* Disable timer interrupts */
			prt_timerints = FALSE;
			break;
			
		case 0x52:	/* Reset timer interrupt */
			int2 = FALSE;
			prt_stat &= 0xFE;
			/* fall through */
			
		case 0xD8:	/* Preset timer counter */
			irq_counter = 0;
			break;
	}
}

UBYTE PrinterSTAT()
{
#if PRINTER_DEBUG
	fprintf(stderr, "\nPrinter STAT\n");
#endif
	
	return prt_stat;
}

UBYTE PrinterGETB()
{
#if PRINTER_DEBUG
	fprintf(stderr, "\nPrinter GETB\n");
#endif

	return 0x02;
}

void PrinterIRQ()
{
	irq_counter++;
	if(irq_counter > 100)
	{
		if(prt_timerints)
		{
			int2 = TRUE;
			prt_stat |= 0x01;
		}
	}
}
