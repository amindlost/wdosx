/*
  ############################################################################
  ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
  ##                                                                        ##
  ## Released under the terms of the WDOSX license agreement.               ##
  ############################################################################

  $Header: E:/RCS/WDOSX/0.95/SRC/UTIL/WDXINFO.H 1.1 1999/02/07 18:25:03 MikeT Exp $

  ----------------------------------------------------------------------------

  $Log: WDXINFO.H $
  Revision 1.1  1999/02/07 18:25:03  MikeT
  Initial check in. Taken from the source root and moved up here.

 
  ----------------------------------------------------------------------------
*/

/*

 Theory of operation
 ----------------------------------------------------------------------------

 Due to the need to provide a zero based memory model for all fully
 relocatable executable formats, we need a means for parametrizing the
 execution of WdosX.

 The solution is to define a structure WdxInfo and locate it at offset 0
 of the executable image of wdosx.dx (the DOS extender kernel)

 Not all of the information in this structure is actually processed by the
 kernel but rather meant to be taken care of by an executable loader.

 The structure will be initialized with default values to allow for 100%
 backward compatibility with earlier versions of WdosX and a pretty good
 level of backward compatibility even with the BASE0- feature turned ON.

 Since the Watcom- variant of WdosX runs zero- based since day one, the BASE0
 ON/OFF setting will be ignored by the executable loader.

 If the revision is incremented, the meaning of all earlier defined fields in
 the structure MUST NOT CHANGE to allow for future backward compatibility.

 Algorithm for accessing the WdxInfo structure:

 1: Open executable file
 2: Read executable header
 3: Read header size from header
 4: Set file pointer to after the header
 5: Read in at least 4 bytes (you might want to read in all of the structure
    at once)
 6: If these four bytes match the string '$WdX', then WdxInfo is present
 ----------------------------------------------------------------------------
*/

#define WDXINFO_FLAGS_BASE0 1

#define STUB_CLASS_WDX 1
#define STUB_CLASS_WATCOM 2
#define STUB_CLASS_PE 3
#define STUB_CLASS_RDOFF 4
#define STUB_CLASS_DOS32 5
/* just for completeness */
#define STUB_CLASS_COFF	6

typedef struct {
   unsigned long Signature;
   unsigned short Revision;
   unsigned char Flags;
   unsigned char StubClass;
   unsigned long XMemReserve;
   unsigned long XMemAlloc;
   unsigned long WfseStart;	/* Revision 2+ */
} WdxInfo;
