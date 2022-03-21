/*
   emu5110
	-------
	An emulator for the IBM 5110
	(C) 2007-2008 Christian Corti

  Adapted to Wintel (using winpthread and pdcurses) by Steve Lewis - 2022
	
	Main program
*/

#include <stdio.h>
#include <string.h>

//#include <unistd.h>  // Unix Standard
#include <windows.h>
#include <winnt.h>
#ifdef _MSC_VER 
#define PATH_MAX 200
#define strncasecmp _strnicmp
#define strcasecmp _stricmp
#endif


#include <limits.h>
#include <time.h>
#include <stdlib.h>
//#include <pthread.h>
#include <winpthreads.h>
//#include <readline/readline.h>
//#include <readline/history.h>

#include "emu.h"

#define ERR_EMU_INIT 10
#define ERR_EMU_DISPLAY 20
#define ERR_PRINTER_OUT 21

pthread_mutex_t emu_mutex;
pthread_cond_t emu_cond_run;

int quit;
int run;

/* Windows sleep in 100ns units */
BOOLEAN nanosleep(LONGLONG ns)
{
	/* Declarations */
	HANDLE timer;	/* Timer handle */
	LARGE_INTEGER li;	/* Time defintion */
	/* Create timer */
//  CreateWaitableTimerEx(NULL, NULL, CREATE_WAITABLE_TIMER_HIGH_RESOLUTION);
	if(!(timer = CreateWaitableTimer(NULL, TRUE, NULL)))
		return FALSE;
	/* Set timer properties */
	li.QuadPart = -ns;
	if(!SetWaitableTimer(timer, &li, 0, NULL, NULL, FALSE)){
		CloseHandle(timer);
		return FALSE;
	}
	/* Start & wait for timer */
	WaitForSingleObject(timer, INFINITE);
	/* Clean resources */
	CloseHandle(timer);
	/* Slept without problems */
	return TRUE;
}

void LoadFile(char *cmdline)
{
	FILE *infile;
	char *fname, *base;
	unsigned long baseval;

	fname = strchr(cmdline, ' ');
	if(!fname)
	{
		printf("No file specified.\n");
		return;
	}
	fname++;

	base = strchr(fname, ' ');
	if(!base)
		baseval = 0x0B00;
	else
	{
		*base++ = '\0';
		baseval = strtol(base, NULL, 0);
	}
		
	if(baseval < 0x200)
	{
		printf("Illegal load address %lu.\n", baseval);
		return;
	}
	
	infile = fopen(fname, "rb");
	if(!infile)
	{
		fprintf(stderr, "Can't open '%s': ", fname);
		perror(NULL);
		return;
	}
	fread(&RWSb[baseval], 65536-baseval, 1, infile);
	fclose(infile);
	printf("Done.\n");
}

void Halt()
{
	pthread_mutex_lock(&emu_mutex);
  	run = 0;  // clear RUN state indicator
	  pthread_cond_signal(&emu_cond_run);  // signal RUN condition...
	pthread_mutex_unlock(&emu_mutex);
}

void Run()
{
	pthread_mutex_lock(&emu_mutex);
	  run = 1;  // set RUN state indicator
	  emu_start();  // clear HALT state
	  pthread_cond_signal(&emu_cond_run);  // signal RUN condition...
	pthread_mutex_unlock(&emu_mutex);
}

void *DisplayThread(void *threadid)
{
	//struct timespec ts;

	while(!quit)
	{
		if(DoEvents())
			continue;
#if 0
		usleep(50000);		usleep is not thread-safe on Solaris
#else
		//ts.tv_sec = 0;
		//ts.tv_nsec = 50000000L;	// simulate a 50HZ display refresh rate
		//nanosleep(&ts, NULL);
    nanosleep(50);
#endif
		UpdateScreen();
	}
	pthread_exit(0);
}

void *EmuThread(void *threadid)
{
	while (!quit)
	{
    {
		  pthread_mutex_lock(&emu_mutex);
		  if (!run)
			  pthread_cond_wait(&emu_cond_run, &emu_mutex);  // wait for the RUN condition...
		  pthread_mutex_unlock(&emu_mutex);
    }
		
		if (run)
		{
			if (emu_do() == TRUE)  // execute batch of instruction... (fetch and execute 50 opcodes)
				Halt();
		}
	}

	pthread_exit(0);
}

int main(int argc, char *argv[])
{
	pthread_t threads[10];
  // threads[0] == EmuThread core emulation runtime
  // threads[1] == DisplayThread  update display out of the screen/machine state

	int num_threads=0;
	int i, retval;
	char *cmd;

	/* Initialize emulator and I/O */

	if (emu_init())  // if NOT 0...then error
		return ERR_EMU_INIT;

	emu_select_lang(0);  // 0 is BASIC, non-zero is APL
	emu_reset();

	if (DisplayInit())  // if NOT 0... then error
		return ERR_EMU_DISPLAY;

	if(!PrinterAttach())
	{
		fprintf(stderr, "ERROR: Can't open printer output file\n");
		return ERR_PRINTER_OUT;
	}

	DiskSetup();
	TapeSetup();

	quit = 0;
	run = 0;

	pthread_mutex_init(&emu_mutex, NULL);

	pthread_cond_init(&emu_cond_run, NULL);

  // Attach some hard-coded images for now
  i = DiskAttach(0, "csf.dsk");
  i = TapeAttach(0, "csf.tap");

  /* Create and start threads */

	retval = pthread_create(&threads[0], NULL, EmuThread, (void *)num_threads++);
	if(retval)
	{
		fprintf(stderr, "ERROR: Can't create emulation thread\n");
		return 30;
	}
	retval = pthread_create(&threads[1], NULL, DisplayThread, (void *)num_threads++);
	if(retval)
	{
		fprintf(stderr, "ERROR: Can't create display thread\n");
		return 31;
	}

	/* MAIN LOOP */
  if (argc != 4)
  {
    printf("\nCommand-line arguments:\n\n");
    printf("5110emu <a|b> <n> <script>\n");
    printf("<a|b>    use \"a\" for APL, \"b\" for BASIC\n");
    printf("<n>      start step mode at cycle N (0 for none)\n");
    printf("<script> text file input (or \"none\" if no initial input)\n\n");
    printf("example: 5110emu b 0 command_input_salvo1_BAS.txt\n");
    printf("example: 5110emu a 0 command_input_ball_bounce_ASM.txt\n");
    printf("example: 5110emu b 170000 none\n");
    printf("\nStarting default as BASIC, no step, no script.\n");

    // statup with a set of defaults
    cmd = "basic";
    start_step_at = 0;
    str_command_input[0] = '\0';
  }
  else
  {
    // parse the 4 command line arguments
    if (argv[1][0] == 'a')
      cmd = "apl";
    else if (argv[1][0] == 'b')
      cmd = "basic";
    else
    {
      printf("invalid language specified");
      exit(-2);
    }

    sscanf(argv[2], "%d", &start_step_at);

    strcpy(str_command_input, argv[3]);
  }

	//using_history();
	while (!quit)
	{
	  //cmd = readline("emu5110> ");
		//add_history(cmd);
		switch(cmd[0])
		{
			case 'a':
				if(!strncasecmp(cmd, "apl", 3))
				{
					Halt();
					emu_select_lang(1);
					emu_reset();
					Run();
				}
				else if(!strncasecmp(cmd, "attach", 3))
				{
					char *cc, name[PATH_MAX+1];
					int drv;

					cc = strchr(cmd, ' ');
					if(!cc)
					{
						printf("Syntax: ATTACH drive filename\n");
						break;
					}
					cc++;
					sscanf(cc, "%d %s", &drv, name);
					if(drv<1 || drv>6)
					{
						printf("Invalid drive number %d, use 1..4 for D80..D10 and 5..6 for E80..E40\n", drv);
						break;
					}
					if(!name[0])
					{
						printf("No filename specified.\n");
						break;
					}
					
					if(drv < 5)
					{
						if(!DiskAttach(--drv, name))
							perror("ATTACH failed for disk");
					}
					else
					{
						if(!TapeAttach(drv-5, name))
							perror("ATTACH failed for tape");
					}
				}
				break;

			case 'b':
				if(!strncasecmp(cmd, "basic", 3))
				{
					Halt();
					emu_select_lang(0);
					emu_reset();
					Run();
				}
				break;
				
			case 'd':
				if(!strncasecmp(cmd, "detach", 3))
				{
					char *cc, name[PATH_MAX+1];
					int drv;

					cc = strchr(cmd, ' ');
					if(!cc)
					{
						printf("Syntax: DETACH drive\n");
						break;
					}
					cc++;
					sscanf(cc, "%d", &drv);
					if(drv<1 || drv>6)
					{
						printf("Invalid drive number %d, use 1..4 for D80..D10 and 5..6 for E80..E40\n", drv);
						break;
					}
					
					if(drv < 5)
						DiskDetach(--drv);
					else
						TapeDetach(drv-5);
				}
				else if(!strncasecmp(cmd, "dump", 2))
				{
					emu_toggle_dump();
				}
				break;
				
			case 'g':
				Run();
				break;

			case 'h':
				Halt();
				break;
				
			case 'l':
				LoadFile(cmd);
				break;
				
			case 'm':  // defaults to mem.dmp (full 1 to 64K)
				emu_dump_mem();
				break;

			case 'q':
				Halt();
				quit = 1;
				break;
				
			case 'r':
				emu_reset();
				break;
				
			case 's':
				Halt();
				emu_fetch();
				dump_regs();
				break;
				
		}
		cmd = "";
	}	

	pthread_cond_broadcast(&emu_cond_run);

  // Wait for all threads to finish
	for(i=0; i<num_threads; i++)
		pthread_join(threads[i], NULL);

	PrinterDetach();

	return 0;
}
