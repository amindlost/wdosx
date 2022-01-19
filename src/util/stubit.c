/*
  ############################################################################
  ## WDOSX DOS Extender           Copyright (c) 1996, 2005, Michael Tippach ##
  ##                                                                        ##
  ## Released under the terms of the WDOSX license agreement.               ##
  ############################################################################

  $Header: E:/RCS/WDOSX/0.95/SRC/UTIL/stubit.c 1.16 2003/06/17 02:38:21 MikeT Exp MikeT $

  ----------------------------------------------------------------------------

  $Log: stubit.c $
  Revision 1.16  2003/06/17 02:38:21  MikeT
  Updated year in copyright.

  Revision 1.15  2003/06/17 02:18:19  MikeT
  0.97 beta 2 release.

  Revision 1.14  2002/10/18 00:52:18  MikeT
  0.97 beta release formalisms.

  Revision 1.13  2001/02/22 22:18:16  MikeT
  Prepared for final 0.96 release.

  Revision 1.12  2000/05/28 13:35:15  MikeT
  Prepared for beta 1 release (really, this time!)

  Revision 1.11  2000/05/28 13:32:56  MikeT
  Updated copyright year.

  Revision 1.10  1999/06/27 21:45:55  MikeT
  Prepared for beta 1 release. Removed check for RDOFF version number, thus
  enabling it to work with RDOFF2.

  Revision 1.9  1999/06/20 16:58:53  MikeT
  Change version to test release and update copyright.

  Revision 1.8  1999/05/05 19:53:16  MikeT
  Implemented suggested changes by Tim Adam in order to allow stubit.exe to
  work with path names that contain an"..". Changed some type casting that has
  been reported to generate errors under BC 4.5.

  Revision 1.7  1999/03/21 17:38:24  MikeT
  Change title message for alpha 2 release.

  Revision 1.6  1999/02/21 23:21:30  MikeT
  Prepare copyright and version output for 0.96 alpha1 release

  Revision 1.5  1999/02/13 14:55:25  MikeT
  If used with a fixed PE image we now yell at the user. This doesn't
  fix anything for fixed PEs though it certainly cuts down on the number
  of emails I get concerning PEs crashing when stubbed with WDOSX.

  Revision 1.4  1999/02/06 19:13:00  MikeT
  Make wdxinfo.h local to this directory.

  Revision 1.3  1999/01/10 16:33:07  MikeT
  Updated version and copyright. Put in development warning.

  Revision 1.2  1999/01/06 01:14:30  MikeT
  Fixed an issue where subsequent stubbing of the same executable would
  result in a loss of the StubClass field content and, as a result, the
  executable would be treated as a flat form binary.

  Revision 1.1  1998/08/03 02:53:11  MikeT
  Initial check in

 
  ----------------------------------------------------------------------------
*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <windows.h>
#include "dosext.h"
#include "load_asm.h"
#include "load_hll.h"
#include "load_le.h"
#include "load_rdf.h"
#include "load_pe0.h"
#include "load_d32.h"
#include "load_cof.h"
#include "wdxinfo.h"

#define WdosxVersion "0.97"

FILE *InFile;
FILE *OutFile;
char *DotPos;
char *SlashPos;
char *AFileName;
char FNSpace[80];
char *Buffer;
int InSize;
int ExeType = 0;
unsigned long HeaderPos = 0;
unsigned short *UsPtr;
unsigned long *UlPtr;
unsigned long HeaderOffset = 0;
unsigned long Ho2RVA = 0;
unsigned long OldWfsePtr = 0;
unsigned long NewWfsePtr = 0;
const char FnWdosx[] = "wdosx.dx\0";
const char FnWustub[] = "pestub.exe\0";
const char FnWdosxW[] = "wdosxle.exe\0";
char Targ[10] = "\0\0\0\0\0\0\0\0\0\0";
int i;
char *targp;
char *filename;
int isTrueFlat = 1;
int isWin32 = 1;
int StubClass = 0;
int CanCompress = 0;
int NoWfseSwitch = 0;

unsigned long WdosxAddfile (char *hostfile, char *src, char *wfsenmae, \
                            unsigned long srcoffset, unsigned long wfseflags);

unsigned long WdosxAddWdls (char *hostfile, char *src, unsigned long srcoff, char *av);

int main (int argc, char *argv[]) {

  printf ("\n"
"WDOSX V " WdosxVersion " Stub Manager\n"
"Copyright (c) 1996, 2005, Michael Tippach\n"
"WDOSX-PACK compressor\n"
"Copyright (c) 1999, 2001, Joergen Ibsen\n"
"=========================================\n");
#ifdef development
  printf ("       ----------- Development version - DO NOT REDISRIBUTE! ----------\n\n");
#endif

  if (GetProcAddress(GetModuleHandle("KERNEL32.dll\0"), "Borland32\0")) {
    isWin32 = 0;
  } 
  if (!(Buffer = malloc(0x4000))) {
    printf ("Not enough memory\n");
    return(255);
  }
  memset(Buffer,0,0x4000);
  if (argc < 2) {
    printf ("\nUsage:  STUBIT {-m_float/-nowfse} <filename>\n"
            "          prepend DOS extender stub to <filename>\n"
            "          The -m_float option forces a floating application segment for PE's\n"
            "          that do not use the Win32 API as opposed to a zero based memory model\n"
            "          which is the new default for these kind of executables. This option\n"
            "          exists only for backwards compatibility and might disappear in future\n"
            "          versions!\n"
            "          The -nowfse option disables compression and .WDL auto-attachments.\n\n"
            "        STUBIT -extract\n"
            "          extract WDOSX.DX PESTUB.EXE and WDOSXLE.EXE binaries\n"
            "          Only necessary if you use WLINK or prefer the copy /b method!\n");
    return(1);
  }
  targp=argv[1];
  filename=argv[1];
  for (i=0;((i<10)&&(targp[0]>0));i++,targp++) {
    Targ[i]=toupper(targp[0]);
  }
  if (!strcmp(Targ,"-EXTRACT")) {
    if (!(OutFile=fopen("wdosx.dx","wb"))) {
      printf ("\nError: could not create file wdosx.dx\n");
      return (255);
    }
    if (!fwrite(&wdosx_bin,sizeof(wdosx_bin),1,OutFile)) {
      printf ("\nError writing file wdosx.dx\n");
      fclose (OutFile);
      remove ("wdosx.dx");
      return (255);
    }
    fclose (OutFile);
    if (!(OutFile=fopen("pestub.exe","wb"))) {
      printf ("\nError: could not create file pestub.exe\n");
      return (255);
    }
    if (!fwrite(&wdosx_bin,sizeof(wdosx_bin),1,OutFile)) {
      printf ("\nError writing file pestub.exe\n");
      fclose (OutFile);
      remove ("pestub.exe");
      return (255);
    }
    if (!fwrite(&winPE_bin,sizeof(winPE_bin),1,OutFile)) {
      printf ("\nError writing file pestub.exe\n");
      fclose (OutFile);
      remove ("pestub.exe");
      return (255);
    }
    fclose (OutFile);

    if (!(OutFile=fopen("wdosxle.exe","wb"))) {
      printf ("\nError: could not create file wdosxle.exe\n");
      return (255);
    }
    if (!fwrite(&LE_bin,sizeof(LE_bin),1,OutFile)) {
      printf ("\nError writing file wdosxle.exe\n");
      fclose (OutFile);
      remove ("wdosxle.exe");
      return (255);
    }
    fclose (OutFile);
  } else {
    if (!strcmp(Targ,"-M_FLOAT")) {
       if (argc<3) {
          printf ("\nError: File name missing. Type 'stubit' without paramaters for syntax!\n");
          return(255);
       }
       filename = argv[2];
       isTrueFlat = 0;
    } else {
       if (!strcmp(Targ,"-NOWFSE")) {
          if (argc<3) {
             printf ("\nError: File name missing. Type 'stubit' without paramaters for syntax!\n");
             return(255);
         }
         filename = argv[2];
         NoWfseSwitch = 1;
       }
    }
    AFileName = &FNSpace[0];
    AFileName = strcpy (AFileName,filename);
    if (!(SlashPos = strrchr (AFileName,'\\')))
      SlashPos = AFileName;
    if (DotPos = strrchr (SlashPos,'.')) DotPos[0] = '\0';
    AFileName = strcat(AFileName,".bak");
    remove(AFileName);
    if (rename(filename,AFileName)) {
      printf ("\nError opening file %s\n",filename);
      return (2);
    }
    if (!(InFile = fopen (AFileName,"rb"))) {
      printf ("\nError opening file %s\n",AFileName);
      return (3);
    }
    if (!(OutFile = fopen (filename,"wb"))) {
      printf ("\nError creating file %s\n",filename);
      fclose (InFile);
      return (4);
    }
    InSize = fread(Buffer,1,0x4000,InFile);
    UsPtr = &Buffer[0];
    if ((InSize > 32) && (Buffer[0] == 'M') && (Buffer[1] == 'Z')) {
      Buffer[0] = Buffer[32];
      Buffer[32] = '\0';
      if (!(strcmp(&Buffer[25],"TIPPACH"))) {
        Buffer[32] = Buffer[0];
        HeaderPos = (((unsigned long) UsPtr[2])<<9)
                     - (((unsigned long) 512-((unsigned long) UsPtr[1]))&511);

/* Preserve WFSE pointer, if present */

        UlPtr = &Buffer[0];
        Buffer[32+4]='\0';
        if ( (InSize > (32 + sizeof(WdxInfo))) && (!(strcmp(&Buffer[32],"$WdX")))) {
            OldWfsePtr = UlPtr[12];
            StubClass = Buffer[39];
            *(unsigned char *) &wdosx_bin[39] = StubClass; 
        }
        fseek (InFile,HeaderPos,0);
        printf ("Info: Old DOS extender stub will be replaced\n");
        if (!(InSize = fread(Buffer,1,0x4000,InFile))) {
          printf ("Error: No program appended to existing stub\n");
          fclose (InFile);
          fclose (OutFile);
          remove (filename);
          rename (AFileName,filename);
          return (6);
        }
        if ((InSize > 32) && (Buffer[0] == 'W') && (Buffer[1] == 'F') && \
            (Buffer[2] == 'S') && (Buffer[3] == 'E') && \
            (StubClass == STUB_CLASS_WATCOM) && (OldWfsePtr == HeaderPos)) {
           ExeType = 4;
        } else {
          if ((InSize > 32) && (Buffer[0] == 'M') && (Buffer[1] == 'Z')) {
            Buffer[32] = '\0';
            if (!(strcmp(&Buffer[25],"TIPPACH"))) {
              HeaderPos += (((unsigned long) UsPtr[2])<<9)
                         - (((unsigned long) 512-((unsigned long) UsPtr[1]))&511);
              printf ("Info: Old executable loader will be replaced\n");
              fseek (InFile,HeaderPos,0);   
              if (!(InSize = fread(Buffer,1,0x4000,InFile)) || (InSize < 33)) {
                printf ("Error: No program appended to existing loader\n");
                fclose (InFile);
                fclose (OutFile);
                remove (filename);
                rename (AFileName,filename);
                return (7);
              }
              /* Check whether we can go the easy way */

              if ((Buffer[0] == 'W') && (Buffer[1] == 'F') && \
                 (Buffer[2] == 'S') && (Buffer[3] == 'E') && \
                 (OldWfsePtr == HeaderPos)) {
                if (!(isTrueFlat)) printf ("Warning: -m_float option ignored for WFSE linked executable!\n");
                isTrueFlat = 1;   /* force true flat */
                switch (StubClass) {
                  case STUB_CLASS_PE: {
                     ExeType = 3;
                  }
                  break;
                  case STUB_CLASS_DOS32: {
                     ExeType = 6;
                  }
                  break;
                  case STUB_CLASS_COFF: {
                     ExeType = 7;
                  }
                  break;
                  case STUB_CLASS_RDOFF: {
                     ExeType = 5;
                  }
                }
              }
            }
          }
        }
      } else if (!(StubClass)) {
        /* no wdosx.dx */
        HeaderOffset = (((unsigned long) UsPtr[2])<<9)
                     - (((unsigned long) 512-((unsigned long) UsPtr[1]))&511);
        fseek (InFile,HeaderOffset,0);
        if (InSize = fread(Buffer,1,0x4000,InFile)) {
          if ((InSize > 36) && (Buffer[0] == 'B') && (Buffer[1] =='W')) {
            UlPtr = &Buffer[28];
            HeaderOffset=UlPtr[0];
            fseek (InFile,HeaderOffset,0);
            if (InSize = fread(Buffer,1,0x4000,InFile)) {
              if ((InSize > 32) && (Buffer[0] == 'M') && (Buffer[1] =='Z')) {
                HeaderOffset += (((unsigned long) UsPtr[2])<<9)
                   - (((unsigned long) 512-((unsigned long) UsPtr[1]))&511);
                fseek (InFile,HeaderOffset,0);
                if (InSize = fread(Buffer,1,0x4000,InFile)) {
        int bar=0;
                  while ((!Buffer[bar]) && (bar<16)) bar+=1;
                  if ((bar<16) && (Buffer[bar]=='L') && (Buffer[bar+1]=='E')) {
                     HeaderPos = HeaderOffset+bar;
                     printf ("Info: Old DOS extender/loader will be replaced\n");
                     ExeType = 4;
                  }
                }
              } else if ((InSize > 32) && (Buffer[0] == 'B') && (Buffer[1] =='W')) {
                UlPtr = &Buffer[28];
                HeaderOffset=UlPtr[0];
                fseek (InFile,HeaderOffset,0);
                if (InSize = fread(Buffer,1,0x4000,InFile)) {
                  if ((InSize > 32) && (Buffer[0] == 'M') && (Buffer[1] =='Z')) {
                  HeaderOffset += (((unsigned long) UsPtr[2])<<9)
                   - (((unsigned long) 512-((unsigned long) UsPtr[1]))&511);
                  fseek (InFile,HeaderOffset,0);
                  if (InSize = fread(Buffer,1,0x4000,InFile)) {
           int bar=0;
                    while ((!Buffer[bar]) && (bar<16)) bar+=1;
                    if ((bar<16) && (Buffer[bar]=='L') && (Buffer[bar+1]=='E')) {
                      HeaderPos = HeaderOffset+bar;
                      printf ("Info: Old DOS extender/loader will be replaced\n");
                      ExeType = 4;
                      }
                    }
                  }
                }
              }
            }
          } else if (InSize > 36) {
            if ((Buffer[0]  == 'A') && (Buffer[1]  == 'd')
                                     && (Buffer[2]  == 'a')
                                     && (Buffer[3]  == 'm')) { 
               ExeType = 6;
               printf("Info: Old executable stub will be replaced\n");
               HeaderPos = HeaderOffset;
            } else {
              if ((Buffer[0]  == 0x4C) && (Buffer[1]  == 1)
                                       && (Buffer[20]  == 0xB)
                                       && (Buffer[21]  == 1)) { 
              ExeType = 7;
              printf("Info: Old executable stub will be replaced\n");
              HeaderPos = HeaderOffset;
              } else {
                int foo=0;
                while ((!Buffer[foo]) && (foo<16)) foo+=1;
                if ((foo<16) && (Buffer[foo]=='L') && (Buffer[foo+1]=='E')) {
                printf ("Info: Old executable stub will be replaced\n");
                ExeType = 4;
                HeaderPos = HeaderOffset+foo;
                  
                }
              }
            }
          }
	}
      }
    }
    fseek (InFile,HeaderPos,0);
    if (!(InSize = fread(Buffer,1,0x4000,InFile))) {
      printf ("Error: Not an executable ( zero size )\n");
      fclose (InFile);
      fclose (OutFile);
      remove (filename);
      rename (AFileName,filename);
      return (5);
    }
    if ((InSize > 32) && (Buffer[0] == 'M') && (Buffer[1] == 'Z') && (ExeType != 6)) {
      ExeType = 1;
      if (InSize > 511) {
        UlPtr = &Buffer[60];
        HeaderOffset = UlPtr[0];
        if (HeaderOffset > 0x3ffc) {
          fseek (InFile,HeaderPos+HeaderOffset,0);
          fread(Buffer,1,0x4000,InFile);
          Ho2RVA = HeaderOffset;
          UlPtr = &Buffer[0];
        } else UlPtr = &Buffer[HeaderOffset];
        if (UlPtr[0] == 0x4550) {
          if (UlPtr[5] & 0x10000) {
	    printf ("Error: This PE does not contain relocation info (fixed executable).\n");
	    printf ("       Please refer to your compiler/linker's manual on how to create\n");
	    printf ("       non- fixed Win32 executables!\n");
	    fclose (InFile);
	    fclose (OutFile);
	    remove (filename);
	    rename (AFileName,filename);
	    return (16);
          }
          HeaderOffset = UlPtr[0x20] + Ho2RVA;
          ExeType = 2;
          if (UlPtr[0x20]) {
            if (HeaderOffset > (0x3ffc + Ho2RVA)) {
              fseek (InFile,HeaderPos+HeaderOffset,0);
              fread(Buffer,1,0x4000,InFile);
              UlPtr = &Buffer[0];
            } else UlPtr = &Buffer[HeaderOffset];
            if (UlPtr[0]) ExeType = 3;
          }
        }
      }
    } else if ((InSize > 32) && (Buffer[0] == 'L') && (Buffer[1] == 'E'))
      ExeType = 4;
      else if ((InSize > 32) && (Buffer[0]  == 'R')
    			     && (Buffer[1]  == 'D')
    			     && (Buffer[2]  == 'O')
    			     && (Buffer[3]  == 'F')
    			     && (Buffer[4]  == 'F')
/*    			     && (Buffer[5]  == '1') */ ) {
      ExeType = 5;
    } 
      else if ((InSize > 32) && (Buffer[0]  == 'A')
    			  		   && (Buffer[1]  == 'd')
					   && (Buffer[2]  == 'a')
					   && (Buffer[3]  == 'm')) {
      ExeType = 6;
    }
    else if ((InSize > 32) && (Buffer[0]  == 0x4C)
   			  		   && (Buffer[1]  == 1)
					   && (Buffer[20]  == 0xB)
					   && (Buffer[3]  == 1)) {
      ExeType = 7;
    }
    if ((ExeType == 2) && (isTrueFlat)) ExeType = 3;

    /* check whether we can compress the main executable */

    if ( (!(OldWfsePtr)) &&       \
         (!(isWin32)) &&          \
          (!(NoWfseSwitch)) &&    \
         (                        \
           (ExeType == 3)         \
           || (ExeType == 4)      \
           || (ExeType == 5)      \
           || (ExeType == 6)      \
           || (ExeType == 7)      \
         )                        \
        ) {
      CanCompress = 1;
      OldWfsePtr = 1;          /* To make the following math work */
      switch (ExeType) {
        case 3: StubClass = STUB_CLASS_PE; break;
        case 5: StubClass = STUB_CLASS_RDOFF; break;
        case 6: StubClass = STUB_CLASS_DOS32; break;
	case 7: StubClass = STUB_CLASS_COFF; break;
      }
    }                      /* compress */
    if (ExeType != 4) {
       NewWfsePtr = sizeof(wdosx_bin);
       switch (ExeType) {
          case 2: NewWfsePtr+=sizeof(rawPE_bin);break;
     /*   case 3: NewWfsePtr+=sizeof(winPE_bin);break; */
          case 3: NewWfsePtr+=sizeof(peload_ra0);break;
          case 5: NewWfsePtr+=sizeof(rdfload_bin);break;
          case 6: NewWfsePtr+=sizeof(dos32_bin);break;
          case 7: NewWfsePtr+=sizeof(coff_bin);break;
       }
       if (!(CanCompress)) {
          NewWfsePtr -= HeaderPos;
          NewWfsePtr += OldWfsePtr;
       }
       UlPtr=&wdosx_bin[0];
       if (OldWfsePtr) {
          UlPtr[12] = NewWfsePtr;
          if (CanCompress) {
            *(unsigned char *) &wdosx_bin[39] = StubClass; 
          }
          else printf("Info: WFSE extension relocated\n");
       }
       if (!(fwrite(&wdosx_bin,sizeof(wdosx_bin),1,OutFile))) {
          printf ("Error writing output file\n");
          fclose (InFile);
          fclose (OutFile);
          remove (filename);
          rename (AFileName,filename);
          return (255);
       }
    }
   
    switch (ExeType) {

      case 0: printf ("Warning: input file has no .exe header,"
                      " assuming flat form binary\n");break;

      case 1: printf ("Info: File is DOS MZ executable\n");break;

      case 2: printf ("Info: File is PE executable not using Win32 API\n");
              if (isTrueFlat) {
                 printf ("Info: Using zero based flat memory model\n");
                 if (!(fwrite(&peload_ra0,sizeof(peload_ra0),1,OutFile))) {
                    printf ("Error writing output file\n");
                    fclose (InFile);
                    fclose (OutFile);
                    remove (filename);
                    rename (AFileName,filename);
                    return (255);
                 }
              } else {
                 printf ("Info: Using obsolete floating segment memory model\n");
                 if (!(fwrite(&rawPE_bin,sizeof(rawPE_bin),1,OutFile))) {
                   printf ("Error writing output file\n");
                   fclose (InFile);
                   fclose (OutFile);
                   remove (filename);
                   rename (AFileName,filename);
                   return (255);
                 }
              }break;
      case 3: printf ("Info: File is Win32 executable\n");
/*              if (!(fwrite(&winPE_bin,sizeof(winPE_bin),1,OutFile))) { */
/*              printf ("Warning: This ALPHA version does not automatically add WDLs, Use ADDFILE!\n"); */
              if (!(fwrite(&peload_ra0,sizeof(peload_ra0),1,OutFile))) {
                printf ("Error writing output file\n");
                fclose (InFile);
                fclose (OutFile);
                remove (filename);
                rename (AFileName,filename);
                return (255);
              }break;

      case 4: printf ("Info: File is LE executable\n");
             NewWfsePtr = sizeof(LE_bin);
             if (!(CanCompress)) NewWfsePtr += OldWfsePtr - HeaderPos;
             UlPtr=&LE_bin[0];
             if (OldWfsePtr) {
                UlPtr[12] = NewWfsePtr;
                if (!(CanCompress)) printf("Info: WFSE extension relocated\n");
             }
             if (!(fwrite(&LE_bin,sizeof(LE_bin),1,OutFile))) {
                printf ("Error writing output file\n");
                fclose (InFile);
                fclose (OutFile);
                remove (filename);
                rename (AFileName,filename);
                return (255);
              }break;

      case 5: printf ("Info: File is RDOFF executable\n");
              if (!(fwrite(&rdfload_bin,sizeof(rdfload_bin),1,OutFile))) {
                printf ("Error writing output file\n");
                fclose (InFile);
                fclose (OutFile);
                remove (filename);
                rename (AFileName,filename);
                return (255);
              }break;

      case 6: printf ("Info: File is DOS32- format executable\n");
              if (!(fwrite(&dos32_bin,sizeof(dos32_bin),1,OutFile))) {
                printf ("Error writing output file\n");
                fclose (InFile);
                fclose (OutFile);
                remove (filename);
                rename (AFileName,filename);
                return (255);
              }break;

      case 7: printf ("Info: File is DJGPP v2 - COFF executable\n");
              if (!(fwrite(&coff_bin,sizeof(coff_bin),1,OutFile))) {
                printf ("Error writing output file\n");
                fclose (InFile);
                fclose (OutFile);
                remove (filename);
                rename (AFileName,filename);
                return (255);
              }break;
    }
    if (CanCompress) {
       /* Get libraries from InFile */
       fclose (InFile);
       fclose (OutFile);
       printf ("Compressing main executable");
       if (!(WdosxAddfile(filename, AFileName, "WdosxMain", HeaderPos, \
          StubClass | 0x10))) {
          printf ("Error writing output file\n");
          remove (filename);
          rename (AFileName,filename);
          return (255);
       }
       printf("\n");
    /* add libs if necessary */
    if (ExeType == 3) {
       if (!(WdosxAddWdls(filename, AFileName, HeaderPos, argv[0]))) printf ("Error: Auto-add of WDLs failed.\n");
    }

    } else {
      fseek (InFile,HeaderPos,0);
      HeaderOffset = 0;
      while (fread(Buffer,0x4000,1,InFile)) {
        HeaderOffset += 0x4000;
        if (!(fwrite(Buffer,0x4000,1,OutFile))) {
          printf ("Error writing output file\n");
          fclose (InFile);
          fclose (OutFile);
          remove (filename);
          rename (AFileName,filename);
          return (255);
        }
      }
      fseek (InFile,HeaderPos+HeaderOffset,0);
      if (InSize=fread(Buffer,1,0x4000,InFile)) {
        if (!((fwrite(Buffer,1,InSize,OutFile))==InSize)) {
          printf ("Error writing output file\n");
          fclose (InFile);
          fclose (OutFile);
          remove (filename);
          rename (AFileName,filename);
          return (255);
        }
      }
      fclose (InFile);
      fclose (OutFile);
    }
  }
  printf ("Seems like we are done...\n");
  return (0);
}
