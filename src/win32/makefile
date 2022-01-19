# ############################################################################
# ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
# ##                                                                        ##
# ## Released under the terms of the WDOSX license agreement.               ##
# ############################################################################
#
# $Header: E:/RCS/WDOSX/0.95/SRC/WIN32/makefile 1.7 2001/04/07 18:39:58 MikeT Exp $
#
# ----------------------------------------------------------------------------
#
# $Log: makefile $
# Revision 1.7  2001/04/07 18:39:58  MikeT
# Allow to work under Win2k where DEL returns an error code.
#
# Revision 1.6  2000/03/18 18:38:58  MikeT
# Add k32mem.asm
#
# Revision 1.5  1999/03/06 23:24:59  MikeT
# Add u32nls.asm, user32.def and move nls.lib to user32 target.
#
# Revision 1.4  1999/03/06 18:00:03  MikeT
# Include k32nls.asm, which will contain character conversion routines
#
# Revision 1.3  1999/03/06 16:59:47  MikeT
# Also build NLS search library (NLS.LIB).
#
# Revision 1.2  1999/02/06 16:18:25  MikeT
# Some cosmetics.
#
# Revision 1.1  1999/02/06 16:17:04  MikeT
# Initial check in.
#
#
# ----------------------------------------------------------------------------
#
# Makefile for the WDOSX Win32 API emulation
#
ASM = tasm.exe
AFLAGS = /m9 /mx
LINK = tlink32.exe
LFLAGS = -Tpd
CO = coo.exe
LIB = tlib.exe

makefile : kernel32.wdl user32.wdl oleaut32.wdl advapi32.wdl ole32.wdl

kernel32.wdl : kernel32.dll
    @IF EXIST kernel32.wdl DEL kernel32.wdl
    REN kernel32.dll kernel32.wdl

user32.wdl : user32.dll
    @IF EXIST user32.wdl DEL user32.wdl
    REN user32.dll user32.wdl

oleaut32.wdl : oleaut32.dll
    @IF EXIST oleaut32.wdl DEL oleaut32.wdl
    REN oleaut32.dll oleaut32.wdl

advapi32.wdl : advapi32.dll
    @IF EXIST advapi32.wdl DEL advapi32.wdl
    REN advapi32.dll advapi32.wdl

ole32.wdl : ole32.dll
    @IF EXIST ole32.wdl DEL ole32.wdl
    REN ole32.dll ole32.wdl

K32OB =  kernel32.obj k32load.obj k32lfuns.obj k32vmem.obj k32file.obj \
         k32misc.obj k32heap.obj k32spawn.obj console.obj k32nls.obj k32mem.obj


K32O =  kernel32 k32load k32lfuns k32vmem k32file k32misc k32heap k32spawn \
        console k32nls k32mem

kernel32.dll : $(K32OB)
    $(LINK) $(LFLAGS) $(K32O),kernel32.dll

kernel32.obj : kernel32.asm
k32load.obj : k32load.asm
k32lfuns.obj : k32lfuns.asm
k32vmem.obj : k32vmem.asm
k32file.obj : k32file.asm
k32misc.obj : k32misc.asm
k32heap.obj : k32heap.asm
k32spawn.obj : k32spawn.asm
console.obj : console.asm
k32nls.obj : k32nls.asm
k32mem.obj : k32mem.asm


user32.dll : user32.obj u32nls.obj nls.lib
    $(LINK) $(LFLAGS) user32 u32nls,user32.dll,,nls.lib,user32.def

user32.obj : user32.asm
u32nls.obj : u32nls.asm

nls.lib : 847.obj 866.obj 857.obj 852.obj 775.obj 720.obj 932.obj 1258.obj \
          437.obj 737.obj 850.obj 855.obj 862.obj
   $(LIB) nls /C +847.obj +866.obj +857.obj +852.obj +775.obj +720.obj +932.obj
   $(LIB) nls /C +1258.obj +437.obj +737.obj +850.obj +855.obj  +862.obj

847.obj : 847.ASM
866.obj : 866.ASM
857.obj : 857.ASM
852.obj : 852.ASM
775.obj : 775.ASM
720.obj : 720.ASM
932.obj : 932.ASM
1258.obj : 1258.ASM
437.obj : 437.ASM
737.obj : 737.ASM
850.obj : 850.ASM
855.obj : 855.ASM
862.obj : 862.ASM


advapi32.dll : advapi32.obj
    $(LINK) $(LFLAGS) advapi32,advapi32.dll

advapi32.obj : advapi32.asm

oleaut32.dll : oleaut32.obj
    $(LINK) $(LFLAGS) oleaut32,oleaut32.dll

oleaut32.obj : oleaut32.asm

ole32.dll : ole32.obj
    $(LINK) $(LFLAGS) ole32,ole32.dll

ole32.obj : ole32.asm


.asm.obj :
    $(ASM) $(AFLAGS) $<

get :
    $(CO) K32SPAWN.ASM
    $(CO) CONSOLE.ASM
    $(CO) K32VMEM.ASM
    $(CO) OLEAUT32.ASM
    $(CO) K32LOAD.ASM
    $(CO) K32LFUNS.ASM
    $(CO) ADVAPI32.ASM
    $(CO) OLE32.ASM
    $(CO) USER32.ASM
    $(CO) K32FILE.ASM
    $(CO) K32HEAP.ASM
    $(CO) K32MISC.ASM
    $(CO) KERNEL32.ASM
    $(CO) K32NLS.ASM
    $(CO) K32MEM.ASM
    $(CO) U32NLS.ASM
    $(CO) W32STRUC.INC
    $(CO) 847.ASM
    $(CO) 866.ASM
    $(CO) 857.ASM
    $(CO) 852.ASM
    $(CO) 775.ASM
    $(CO) 720.ASM
    $(CO) 932.ASM
    $(CO) 1258.ASM
    $(CO) 437.ASM
    $(CO) 737.ASM
    $(CO) 850.ASM
    $(CO) 855.ASM
    $(CO) 862.ASM
    $(CO) USER32.DEF

clean :
    @IF EXIST *.wdl DEL *.wdl
    @IF EXIST *.dll DEL *.dll
    @IF EXIST *.obj DEL *.obj
    @IF EXIST *.map DEL *.map
    @IF EXIST *.lib DEL *.lib
    @IF EXIST *.bak DEL *.bak
