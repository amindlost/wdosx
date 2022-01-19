/*
  ############################################################################
  ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
  ##                                                                        ##
  ## Released under the terms of the WDOSX license agreement.               ##
  ############################################################################

  $Header: E:/RCS/SRCREL/wdosx/0.95/SRC/TOOLSRC/toh.c 1.1 1999/02/06 20:14:22 MikeT Exp MikeT $

  ----------------------------------------------------------------------------

  $Log: toh.c $
  Revision 1.1  1999/02/06 20:14:22  MikeT
  Initial check in.

 
  ----------------------------------------------------------------------------

  What this does: Convert a binary file into an .h. Certain assumptions being
  made so don't use unless you are me!

*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>

FILE *InFile;
FILE *OutFile;

int InSize;
int LinePos;

unsigned char *Buffer;

const char EWarn[] = "/* This is a program generated file. Do not edit! */\n";

/* No error checking and stuff, since *I* probably know what I'm doing !?!? */

int main (int argc, char *argv[]) {
  if (!(Buffer = malloc(0x40000))) {
    printf ("Not enough memory\n");
    return(1);
  }
  if (argc != 4) {
    printf ("Usage: toh infile outfile labelname\n");
    return(1);
  }
  if (!(InFile = fopen (argv[1],"rb"))) {
    printf ("Error opening input file %s\n", argv[1]);
    return(1);
  }
  InSize = fread (Buffer,1,0x40000,InFile);
  fclose (InFile);
  if (!(OutFile = fopen (argv[2],"w"))) {
    printf ("Error opening output file %s\n", argv[2]);
    return(1);
  }
  fprintf (OutFile,EWarn);
  fprintf (OutFile,"char %s[] = {\n", argv[3]);
  while (InSize--) {
    fprintf (OutFile,"0x%X",Buffer[0]);
    Buffer++;
    LinePos++;
    if (InSize) fprintf (OutFile,","); else fprintf (OutFile,"};\n");
    if (LinePos > 14) {
      fprintf (OutFile,"\n");
      LinePos = 0;
    };
  };
  fclose (OutFile);
  return (0);
}
