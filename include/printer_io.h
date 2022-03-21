/*
   emu5110
	-------
	An emulator for the IBM 5110
	(C) 2007-2008 Christian Corti

  Adapted to Wintel (using winpthread and pdcurses) by Steve Lewis - 2022
	
	Printer I/O header file
*/

#ifndef _PRINTER_IO_H
#define _PRINTER_IO_H

#include <stdio.h>
#include <string.h>
//#include <unistd.h>  // Unix Standard
#include "emu.h"

void PrinterIO(USHORT iocbptr);
void PrinterReset(void);
void PrinterPUTB(UBYTE c);
void PrinterCTRL(UBYTE c);
UBYTE PrinterGETB(void);
UBYTE PrinterSTAT(void);
void PrinterIRQ(void);

#endif
