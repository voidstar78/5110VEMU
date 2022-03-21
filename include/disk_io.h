/*
   emu5110
	-------
	An emulator for the IBM 5110
	(C) 2007-2008 Christian Corti

  Adapted to Wintel (using winpthread and pdcurses) by Steve Lewis - 2022
	
	Disk I/O header file
*/

#ifndef _DISKIO_H
#define _DISKIO_H

enum
{
	DSKMODE_INIT, DSKMODE_ACCESS, DSKMODE_READ, DSKMODE_WRITE
};

void DiskReset(void);
UBYTE DiskSTAT(void);
UBYTE DiskGETB(void);
void DiskPUTB(UBYTE c);
void DiskCTRL(UBYTE c);
void DiskIRQ(void);

#endif
