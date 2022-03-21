#include <stdio.h>

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

void disasm(FILE *datei, unsigned short addr)
{
	unsigned char n1, n2, n3, n4;
	unsigned short n0;
	tParams p1, p2;
	int iscall, callreg;
	int extranl;

	iscall = 0;

	while(!feof(datei))
	{
		if(!fread(&n0, 2, 1, datei))
			continue;

		n0 = (n0 >> 8) | ((n0 & 0xFF) << 8);

		n1 = (n0 & 0xF000) >> 12;
		n2 = (n0 & 0x0F00) >> 8;
		n3 = (n0 & 0x00F0) >> 4;
		n4 = (n0 & 0x000F);

		p1 = None;
		p2 = None;
		extranl = 0;

		if(iscall && !(n1==13 && n2==0 && n3==callreg && n4==1))
		{
			printf("\t\tINC2 R%d, R0\n", callreg);
			iscall = 0;
		}

		if(!iscall)
		{
			printf("%04X\t", addr);
			printf("%04X", n0);
			if(n1!=0 && n1!=13)
				printf("\t\t");
		}
		else
			printf(" %04X ", n0);

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
					printf("\t\tHALT");
				}
				else if(n0 == 0x0004)
					printf("\t\tNOP");
				else if(n3==0x00 && n4==0x03)
				{
					iscall = 1;
					callreg = n2;
				}
				else if(n2==0x00 && n4==0x04)
				{
					printf("\t\tRET ");
					p1 = Reg2;
					extranl = 1;
				}
				else
				{
					printf("\t\t%s ", Op_0[n4].Mnemonic);
					p1 = Op_0[n4].Nibble1;
					p2 = Op_0[n4].Nibble2;
				}
				break;

			case 1:
				printf("CTRL ");
				p1 = Device;
				p2 = Immediate;
				break;

			case 2:
				if(n2 == 0)
				{
					n0 = ((n3 << 4) | n4) << 1;
					printf("JMP ($%04X)", n0);
					extranl = 1;
				}
				else
				{
					printf("MOVE ");
					p1 = Reg1;
					p2 = WordAddr;
				}
				break;

			case 3:
				printf("MOVE ");
				p1 = WordAddr;
				p2 = Reg1;
				break;

			case 4:
				printf("PUTB $%X, (R%d)%s", n2, n3, FullTicks[n4]);
				break;

			case 5:
				printf("MOVE (R%d)%s, R%d", n3, HalfTicks[n4], n2);
				break;

			case 6:
				printf("MOVB R%d, (R%d)%s", n2, n3, FullTicks[n4]);
				break;

			case 7:
				printf("MOVB (R%d)%s, R%d", n3, FullTicks[n4], n2);
				break;

			case 8:
				printf("LBI ");
				p1 = Reg1;
				p2 = Immediate;
				break;

			case 9:
				printf("CLR ");
				p1 = Reg1;
				p2 = Immediate;
				break;

			case 10:
				n0 = (n3 << 4) | n4;
				n0++;
				if(n2 == 0)
				{
/*					printf("JMP $%02X(R0)\t\t; JMP $%04X", n0, addr+2+n0); */
					printf("BRA $%04X\t\t; $%02X(R0)", addr+2+n0, n0);
					extranl = 1;
				}
				else
					printf("ADD R%d, #$%02X", n2, n0);
				break;

			case 11:
				printf("SET ");
				p1 = Reg1;
				p2 = Immediate;
				break;

			case 12:
				printf("%s ", Op_C[n4].Mnemonic);
				p1 = Op_C[n4].Nibble1;
				p2 = Op_C[n4].Nibble2;
				break;

			case 13:
				if(n3==0 && n4==1)
				{
					fread(&n0, 2, 1, datei);
					n0 = (n0 >> 8) | ((n0 & 0xFF) << 8);
					if(n2 == 0)
					{
							printf(" %04X\tJMP $%04X", n0, n0);
							extranl = 1;
					}
					else
						printf(" %04X\tLWI R%d, #$%04X", n0, n2, n0);

					addr += 2;
				}
				else if(n2==0 && n3==0 && n4==8)
				{
					fread(&n0, 2, 1, datei);
					n0 = (n0 >> 8) | ((n0 & 0xFF) << 8);
					printf(" %04X\tJMP $%04X", n0, n0);
					addr += 2;
					extranl = 1;
				}
				else
				{
					if(iscall)
					{
						fread(&n0, 2, 1, datei);
						n0 = (n0 >> 8) | ((n0 & 0xFF) << 8);
						printf("%04X\tCALL $%04X, R%d", n0, n0, callreg);
						addr += 2;

                  iscall = 0;
					}
					else if(n2 == 0)
						printf("\t\tJMP (R%d)%s", n3, HalfTicks[n4]);
					else
						printf("\t\tMOVE R%d, (R%d)%s", n2, n3, HalfTicks[n4]);
				}
				break;

			case 14:
				switch(n4)
				{
					case 12:
						if(n2 == 0)
							printf("SHR R%d", n3);
						break;

					case 13:
						if(n2 == 0)
							printf("ROR R%d", n3);
						break;

					case 14:
						if(n2 == 0)
							printf("ROR3 R%d", n3);
						break;

					case 15:
						if(n2 == 0)
							printf("SWAP R%d", n3);
						else
							printf("STAT R%d, $%X", n3, n2);
						break;
				}
				break;

			case 15:
				n0 = (n3 << 4) | n4;
				n0++;
				if(n2 == 0)
				{
/*					printf("JMP -$%02X(R0)\t\t; JMP $%04X", n0, addr+2-n0); */
					printf("BRA $%04X\t\t; -> -$%02X(R0)", addr+2-n0, n0);
					extranl = 1;
				}
				else
					printf("SUB R%d, #$%02X", n2, n0);
				break;
		}

		switch(p1)
		{
			case Reg1:
			case Reg:
				printf("R%d", n2);
				break;

			case Reg2:
				printf("R%d", n3);
				break;

			case Device:
				printf("$%X", n2);
				break;

			case Immediate:
				printf("#$%02X", (n3 << 4) | n4);
				break;

			case WordAddr:
				printf("$%02X", ((n3 << 4) | n4) << 1);
				break;
		}

		switch(p2)
		{
			case Reg1:
				printf(", R%d", n2);
				break;

         case Reg2:
			case Reg:
				printf(", R%d", n3);
				break;

			case Immediate:
				printf(", #$%02X", (n3 << 4) | n4);
				break;

			case Device:
				printf(", $%X", n2);
				break;

			case WordAddr:
				printf(", $%02X", ((n3 << 4) | n4) << 1);
				break;
		}

		if(!iscall)
			printf("\n");

		if(extranl)
			printf("\n");

		addr += 2;
	}
}

main(int argc, char **argv)
{
	FILE *in_file;
	unsigned short startaddr=0;

	if(argc < 2)
	{
		printf("Aufruf: disasm <Bin„rdatei> [Startadresse]\n\n");
		exit(5);
	}

	if(argc > 2)
		sscanf(argv[2], "%x", &startaddr);

	in_file = fopen(argv[1], "rb");
	if(!in_file)
	{
		printf("Datei %s konnte nicht ge”ffnet werden\n\n", argv[1]);
		exit(10);
	}

	disasm(in_file, startaddr);

	fclose(in_file);

	printf("Fertig!\n\n");

	return 0;
}
