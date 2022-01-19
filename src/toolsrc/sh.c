/*
  ############################################################################
  ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
  ##                                                                        ##
  ## Released under the terms of the WDOSX license agreement.               ##
  ############################################################################

  $Header: E:/RCS/WDOSX/0.95/SRC/TOOLSRC/sh.c 1.2 1999/02/06 16:50:19 MikeT Exp MikeT $

  ----------------------------------------------------------------------------

  $Log: sh.c $
  Revision 1.2  1999/02/06 16:50:19  MikeT
  Some cosmetics.

  Revision 1.1  1999/02/06 16:47:10  MikeT
  Initial check in.

 
  ----------------------------------------------------------------------------

  What this does: It shrinks the .EXE header of an .EXE that must not contain
  fixups down to 32 bytes and inserts the "TIPPACH" signature. Certain
  assumptions are being made thus it should not be used with anything else
  than the WDOSX build.

*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>

FILE *InFile;
FILE *OutFile;

const char ThatsMe[] = ">TIPPACH";

int InSize;

unsigned char *Buffer;
unsigned short * Header;
unsigned short wtemp;

int main (int argc, char *argv[]) {
  if (!(Buffer = malloc(0x10000))) {
    printf ("Not enough memory\n");
    return(1);
  }
  Header = &Buffer[0];
  if (argc != 3) {
    printf ("Usage: sh infile outfile\n");
    return(1);
  }
  if (!(InFile = fopen (argv[1],"rb"))) {
    printf ("Error opening input file %s\n", argv[1]);
    return(1);
  }
  InSize = fread (Buffer,1,0x10000,InFile) - 512;
  fclose (InFile);

  /* Update header size */

  Header[4] = 2;

  /* Update file size */

  wtemp = (Header[2] << 9) - (( - Header[1]) & 511) - 512 + 32;
  Header[1] = wtemp & 511;
  Header[2] = (wtemp + 511) >> 9;

  /* Write signature */

  memcpy (&Buffer[24], ThatsMe, 8);
  if (!(OutFile = fopen (argv[2],"wb"))) {
    printf ("Error opening output file %s\n", argv[2]);
    return(1);
  }
  if ((fwrite (Buffer,1,32,OutFile)) != 32) {
    printf ("Error writing output file %s\n", argv[2]);
    return(1);
  }
  if ((fwrite (&Buffer[512],1,InSize,OutFile)) != InSize) {
    printf ("Error writing output file %s\n", argv[2]);
    return(1);
  }
  fclose (OutFile);
  return (0);
};
