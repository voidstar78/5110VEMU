/*
   emu5110
	-------
	An emulator for the IBM 5110
	(C) 2007-2008 Christian Corti

  Adapted to Wintel (using winpthread and pdcurses) by Steve Lewis - 2022

*/

#ifndef DEBUG_H
#define DEBUG_H

#ifdef DEBUG
#define DEBUG_MSG(...)	fprintf(stderr, __VA_ARGS__)
#else
#define DEBUG_MSG(...)
#endif

#endif
