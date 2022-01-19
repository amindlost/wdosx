/*
  ############################################################################
  ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
  ##                                                                        ##
  ## Released under the terms of the WDOSX license agreement.               ##
  ############################################################################

  $Header: E:/RCS/WDOSX/0.95/SRC/TOOLSRC/toinc.c 1.2 1999/02/06 16:49:55 MikeT Exp MikeT $

  ----------------------------------------------------------------------------

  $Log: toinc.c $
  Revision 1.2  1999/02/06 16:49:55  MikeT
  Some cosmetics.

  Revision 1.1  1999/02/06 16:48:52  MikeT
  Initial check in.

 
  ----------------------------------------------------------------------------

  What this does: Convert the meat of an MZ.EXE into an .inc. Certain
  assumptions being made so don't use unless you are me!

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

const char EWarn[] = ";\n; This is a program generated file. Do not edit!\n;\n";

/* No error checking and stuff, since *I* probably know what I'm doing !?!? */

int main (int argc, char *argv[]) {
  if (!(Buffer = malloc(0x10000))) {
    printf ("Not enough memory\n");
    return(1);
  }
  if (argc != 3) {
    printf ("Usage: toinc infile outfile (offset)\n");
    return(1);
  }
  if (!(InFile = fopen (argv[1],"rb"))) {
    printf ("Error opening input file %s\n", argv[1]);
    return(1);
  }
  fseek(InFile, 512, 0); /* skip exe header */
  InSize = fread (Buffer,1,0x10000,InFile);
  fclose (InFile);
  if (!(OutFile = fopen (argv[2],"w"))) {
    printf ("Error opening output file %s\n", argv[2]);
    return(1);
  }
  fprintf (OutFile,EWarn);
  fprintf (OutFile,"db ");
  while (InSize--) {
    fprintf (OutFile,"0%Xh",Buffer[0]);
    Buffer++;
    LinePos++;
    if (!(InSize)) {
      fprintf (OutFile,"\n");
    } else {
      if (LinePos > 14) {
        fprintf (OutFile,"\ndb ");
        LinePos = 0;
      } else fprintf (OutFile,",");
    }
  }
  fclose (OutFile);
  return (0);
}
