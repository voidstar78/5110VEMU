#include "emu.h"

const UBYTE EBCDIC2ASCII[256] =
{
	32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
	32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
	32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
	32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
	' ', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
	'H', 'I', '�', '.', '<', '(', '+', '|',
	'&', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
	'Q', 'R', '�', '$', '*', ')', ';', '�',
	'-', '/', 'S', 'T', 'U', 'V', 'W', 'X',
	'Y', 'Z', '�', ',', '%', '_', '>', '?',
	'&', '^',  32,  32, '�',  32,  32,  32,
	 32, '`', ':', '#', '@',  39, '=', '"',
	 32, 'a', 'b', 'c', 'd', 'e', 'f', 'g',
	 'h', 'i',  32,  32, '',  32,  32,  32,
	 32, 'j', 'k', 'l', 'm', 'n', 'o', 'p',
	 'q','r',  32,  32, '�',  32,  32,  32,
	 32, '�', 's', 't', 'u', 'v', 'w', 'x',
	 'y', 'z', '�',  32,  32, '[', '�', '�',
	'�', '�',  32,  32,  32,  32,  32, '\\',
	'�',  39,  32,  32,  32, ']',  32, '|',
	'�', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
	'H', 'I',  32,  32,  32, '�',  32,  32,
	'�', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
	'Q', 'R',  32, '!',  32,  32,  32,  32,
	'�', '�', 'S', 'T', 'U', 'V', 'W', 'X',
	'Y', 'Z',  32,  32,  32,  32,  32,  32,
	'0', '1', '2', '3', '4', '5', '6', '7',
	'8', '9', '|',  32,  32,  32, '�', '�'
};

#if 0 /* not used in this program */
static const UBYTE ASCII2EBCDIC[256] =
{
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64,
	0x5a, 0x7f, 0x7b, 0x5b, 0x6c, 0x50, 0x7d, 0x4d,
	0x5d, 0x5c, 0x4e, 0x6b, 0x60, 0x4b, 0x61, 0xf0,
	0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
	0xf9, 0x7a, 0x5e, 0x4c, 0x7e, 0x6e, 0x6f, 0x7c,
	0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8,
	0xc9, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7,
	0xd8, 0xd9, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7,
	0xe8, 0xe9, 0xad, 0xe0, 0xbd, 0x71, 0x6d, 0x79,
	0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88,
	0x89, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
	0x98, 0x99, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
	0xa8, 0xa9, 0xc0, 0x6a, 0xd0, 0xa1, 64, 64,
	0xd0, 0xc0, 0x81, 0xc0, 0x7c, 0x81, 0xe0, 0x85,
	0x85, 0xd0, 0x89, 0x89, 0x89, 0x4a, 0xc1, 0xc5,
	0xc0, 0xc0, 0x96, 0xe0, 0x96, 0xa4, 0x6a, 0xa8,
	0x6a, 0x5a, 0x4a, 0x40, 0x5b, 0x5b, 0x86, 0x81,
	0x89, 0x96, 0xa4, 0x6a, 0x7b, 0x40, 0x40, 0x40,
	0x40, 0x5f, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,
	0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,
	0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,
	0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,
	0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,
	0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,
	0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,
	0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,
	0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,
	0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,
	0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40
};
#endif
