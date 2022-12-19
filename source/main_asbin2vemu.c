#include <stdlib.h>
#include <stdio.h>

#define TRUE 1
#define FALSE 0

main(int argc, char** argv)
{
  int ch;
  int index;
  FILE* f;

  if (argc == 0)
  {
    printf("EXE <as_bin_file> > result.txt\n");
    exit(-1);
  }

  f = fopen(argv[1], "rb");  // read-binary
  if (f)
  {
    index = 0;
    while (TRUE)
    {
      ch = fgetc(f);
      if (feof(f))
      {
        break;  // done parsing
      }
      else
      {
        ++index;
        if (index == 1)
        {
          printf("Q 0 ");
        }
        // print ch as hex
        printf("%02X", ch);
        if (index == 2)
        {
          index = 0;
          printf("\n");
        }
      }
    }
    fclose(f);
  }
}