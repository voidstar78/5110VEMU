/*
   emu5110
	-------
	An emulator for the IBM 5110
	(C) 2007-2008 Christian Corti

  Adapted to Wintel (using winpthread and pdcurses) by Steve Lewis - 2022
	
	Disk I/O
*/

#include <stdio.h>
#include <string.h>
//#include <unistd.h>  // Unix Standard
#include "emu.h"
#include "disk_io.h"

#define NUM_DRIVES 4
FILE *dskfile[NUM_DRIVES];
int mounted[NUM_DRIVES];

int TRK2ACCESS[4] = { 2, 1, 3, 0 };
UBYTE access_lines[77] =
{
	3, 1, 0, 2, 3, 1, 0, 2, 3, 1, 0, 2, 3, 1, 0, 2,
	3, 1, 0, 2, 3, 1, 0, 2, 3, 1, 0, 2, 3, 1, 0, 2,
	3, 1, 0, 2, 3, 1, 0, 2, 3, 1, 0, 2, 3, 1, 0, 2,
	3, 1, 0, 2, 3, 1, 0, 2, 3, 1, 0, 2, 3, 1, 0, 2,
	3, 1, 0, 2, 3, 1, 0, 2, 3, 1, 0, 2, 3
};

UBYTE track_id[] =
{
	/* ID field */
	0xFE, 0, 0, 7, 0, 0xCC, 0xCC,
	/* GAP 2 */
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
};
UBYTE track_data[1040];	/* buffer that contains the data field of a sector */
long track_offsets[NUM_DRIVES][77][2];		/* file offsets to beginning of tracks */
UBYTE *dskdata_ptr;		/* pointer to next controller data byte */
int dskdata_field;		/* 0=read ID field, 1=read data field */

int track[NUM_DRIVES], sides[NUM_DRIVES];
int side, sector, num_secs, sec_len;
int data_available;		/* 1=read successful, trigger interrupt */

int dsk_mode;				/* current mode of adapter */
UBYTE drive;				/* drive byte as sent from host */
int drv;						/* drive number 0..3 */
UBYTE access_sense[NUM_DRIVES], dsk_sense;
UBYTE dsk_wbyte, dsk_rbyte;
int rw_crc, wr_am;

unsigned long irq_counter;

int DiskAttach(int d, char *name)
{
	UBYTE tmp[4];
	int i, j;
  size_t n;

	if(d<0 || d>3 || !name)
		return FALSE;
		
	if(dskfile[d])
		fclose(dskfile[d]);
		
	if(!(dskfile[d] = fopen(name, "rb+")))
	{
		mounted[d] = FALSE;
		return FALSE;
	}

	track[d] = 0;
	side = 0;
	num_secs = 0;
	sec_len = 0;

	/* read first header which contains number of sides instead of
	   current side number */
  n = fread(tmp, 1, 4, dskfile[d]);
	if(n != 4)
		return FALSE;
	sides[d] = tmp[1];	/* number of sides instead of side number */

	/* preset track offset table */
	for(i=0; i<77; i++)
	{
		track_offsets[d][i][0] = -1;
		track_offsets[d][i][1] = -1;
	}

	/*
	   Read all track headers (one header per track) and put their
	   offsets relative to the beginning of the image file into
		the track_offsets table. The table is used for seeks and
		head selects
	*/

	tmp[1] = 0;				/* put actual side number into header */
	for(;;)
	{
		track_offsets[d][tmp[0]][tmp[1]] = ftell(dskfile[d]) - 4;
		
		if(fseek(dskfile[d], tmp[2]*((128<<tmp[3])+1), SEEK_CUR) < 0)
			break;
		if(fread(tmp, 1, 4, dskfile[d]) != 4)
			break;
			
		if(tmp[0]>77 || tmp[1]>1 || tmp[2]>26 || tmp[3]>3)
			break;
	}

	access_sense[d] = 0x83;
	if(sides[d] > 1)
		dsk_sense = 0x14;
	else
		dsk_sense = 0x10;

	mounted[d] = TRUE;
	return TRUE;
}

void DiskDetach(int d)
{
	access_sense[d] |= 0x80;		/* set New Media */

	if(d<0 || d>3 || !dskfile[d])
		return;
		
	fclose(dskfile[d]);
	dskfile[d] = NULL;
	mounted[d] = FALSE;
}

void DiskSetup()
{
	int i;
	
	for(i=0; i<NUM_DRIVES; i++)
	{
		mounted[i] = FALSE;
		dskfile[i] = NULL;
	}
}

/***************/

int TrackHeader()
{
	UBYTE tmp[4];

	if(!mounted[drv])
		return FALSE;

	side = (access_sense[drv]&4)?1:0;
	if(track_offsets[drv][track[drv]][side] < 0)
		return FALSE;		/* No track data */

	if(fseek(dskfile[drv], track_offsets[drv][track[drv]][side], SEEK_SET) < 0)
		return FALSE;
	if(fread(tmp, 1, 4, dskfile[drv]) != 4)
		return FALSE;

	num_secs	= tmp[2];
	sec_len	= tmp[3] & 0x0F;
	sector	= 1;

	return TRUE;
}

int NextID()
{
	if(!mounted[drv] || num_secs==0)
		return FALSE;

	if(++sector > num_secs)
		sector = 1;
	
	track_id[1] = track[drv];
	track_id[2] = side;
	track_id[3] = sector;
	track_id[4] = sec_len;
	
	return TRUE;
}

int NextDATA()
{
	long offset;

	if(!mounted[drv])
		return FALSE;
	
	offset = track_offsets[drv][track[drv]][side] + 4 + ((128<<sec_len)+1)*(sector-1);
	if(fseek(dskfile[drv], offset, SEEK_SET) < 0)
		return FALSE;
		
	if(fread(track_data, (128<<sec_len)+1, 1, dskfile[drv]) != 1)
		return FALSE;
		
	if(*track_data == 0x40)
		*track_data = 0xFB;
	else
		*track_data = 0xF8;
		
	return TRUE;
}

void WriteDATA()
{
	long offset;
	UBYTE *d;

	if(!mounted[drv])
		return;
	
	offset = track_offsets[drv][track[drv]][side] + 4 + ((128<<sec_len)+1)*(sector-1);
	if(fseek(dskfile[drv], offset, SEEK_SET) < 0)
		return;
		
	/* skip sync and additional AM bytes */
	if(access_sense[drv] & 0x40)
		/* MFM */
		d = track_data + 15;
	else
		/* FM */
		d = track_data + 6;

	if(*d == 0xFB)
		*d = 0x40;
	else
		*d = 0x00;

	fwrite(d, (128<<sec_len)+1, 1, dskfile[drv]);
}

/***************/

void DiskReset()
{
/* fprintf(stderr, "\nRESET\n");*/

	dsk_mode = DSKMODE_INIT;
	drive = 0;
	drv = 0;

	dskdata_field = 0;
	
	emuvar_timer = 0;
}

UBYTE DiskSTAT()
{
	if(mounted[drv])
	{
		if(!(dsk_sense&0x10) && emuvar_timer>0x3700*7)
		{
			dsk_sense |= 0x10;		/* INDEX on */
			emuvar_timer = 0;
		}
		else if((dsk_sense&0x10) && emuvar_timer>0x0630*4)
		{
			dsk_sense &= 0xEF;		/* INDEX off */
			emuvar_timer = 0;
		}
	}
	else
		dsk_sense |= 0x10;			/* INDEX always on when no disk in drive */

	return dsk_sense;
}

UBYTE DiskGETB()
{
	if(dsk_mode == DSKMODE_ACCESS)
		return access_sense[drv];

	if(dsk_mode == DSKMODE_INIT)
	{
		dsk_rbyte = ~drive;
		dsk_mode = DSKMODE_ACCESS;
	}
	else if(dsk_mode == DSKMODE_READ)
		dsk_rbyte = *dskdata_ptr++;

	int2 = FALSE;		/* GETB resets interrupt */		
	return dsk_rbyte;
}

void DiskPUTB(UBYTE c)
{
	UBYTE dir;

	if(dsk_mode == DSKMODE_ACCESS)
	{
		if((c&3) != (access_sense[drv]&3))
		{
			dir = (TRK2ACCESS[c&3] - TRK2ACCESS[access_sense[drv]&3]) & 2;
			if(dir)
				track[drv]--;
			else
				track[drv]++;

			if(track[drv] > 76)
				track[drv] = 76;
			else if(track[drv] < 0)
				track[drv] = 0;
		}

		if(sides[drv] < 2)
			c &= 0xFB;
		access_sense[drv] = (access_sense[drv]&0x80) | (c&0x7C) |
									(access_lines[track[drv]]);

		/* reset New Media bit if disk is mounted */
		if(TrackHeader() && c&0x80 && mounted[drv])
			access_sense[drv] &= 0x7F;
	}

	else if(dsk_mode == DSKMODE_WRITE)
	{
		*dskdata_ptr++ = c;
		int2 = FALSE;
	}
}

void DiskCTRL(UBYTE c)
{
	if(dsk_mode == DSKMODE_INIT)
	{
		drive = c;
		drv = -1;
		while(c&0xFF)
		{
			c <<= 1;
			drv++;
		}
		drv &= 3;

		return;
	}

	if(c & 0x01)
	{
		/* Reset Read/Write */

		if(dsk_mode == DSKMODE_WRITE)
		{
			/* flush sector */
			WriteDATA();
			data_available = FALSE;
			int2 = FALSE;
		}
		
		dsk_mode = DSKMODE_ACCESS;
		dsk_sense &= 0x14;
	}
	else if(c & 0x80)
	{
		/* Write Mode */
		dsk_mode = DSKMODE_WRITE;
		dsk_sense |= 0x80;
		
		if(dskdata_field)
		{
			data_available = 1;
			dskdata_ptr = track_data;
			dskdata_field = 0;
		}
	}
	else if(c & 0x40)
	{
		/* Read Mode */
		dsk_mode = DSKMODE_READ;
		dsk_sense |= 0x40;

		data_available = FALSE;
		if(dskdata_field)
		{
			if(NextDATA())
				data_available = TRUE;
			dskdata_ptr = track_data;
			dskdata_field = 0;
		}
		else
		{
			if(NextID())
				data_available = TRUE;
			dskdata_ptr = track_id;
			dskdata_field = 1;
		}		

		irq_counter = 0;
	}

	/* Erase Gate Sense */
	dsk_sense = (dsk_sense&0xF7) | (c&0x08);

	if(c & 0x02)
	{
		wr_am = TRUE;
		dsk_sense |= 0x08;	/* set Erase Gate */
	}
	else
		wr_am = FALSE;

	if(c & 0x04)
		rw_crc = TRUE;
	else
		rw_crc = FALSE;	
}

void DiskIRQ()
{
	irq_counter++;
	if(irq_counter > 20)
	{
		irq_counter = 0;
		if((dsk_mode==DSKMODE_READ || dsk_mode==DSKMODE_WRITE) && data_available)
			int2 = TRUE;
		if(dsk_mode != DSKMODE_WRITE)
			dsk_sense &= 0xF7;	/* reset Erase Gate */
	}
}
