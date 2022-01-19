# ############################################################################
# ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
# ##                                                                        ##
# ## Released under the terms of the WDOSX license agreement.               ##
# ############################################################################
#
# $Header: E:/RCS/WDOSX/0.95/SRC/tools/makefile 1.4 2001/04/07 19:02:42 MikeT Exp MikeT $
#
# ----------------------------------------------------------------------------
#
# $Log: makefile $
# Revision 1.4  2001/04/07 19:02:42  MikeT
# Allow to work under Win2k where DEL returns an error code.
#
# Revision 1.3  2000/05/28 12:34:55  MikeT
# Add wdmem utility.
#
# Revision 1.2  1999/06/20 15:51:26  MikeT
# Use Joergen Ibsen's WPACK compressor instead of the old LZ77 one.
#
# Revision 1.1  1999/02/07 19:04:25  MikeT
# Initial check in.
#
#
# ----------------------------------------------------------------------------
#
# Makefile for the WADD and WDIR utilities.
#
ASM = tasm.exe
AFLAGS = /m9 /mx
LINK = tlink32.exe
LFLAGS =
CO = coo.exe

makefile : wdir.exe wadd.exe wdmem.exe

wdir.exe : wdirw.exe ..\util\stubit.exe
    ..\util\stubit wdirw.exe
    @IF EXIST wdir.exe DEL wdir.exe
    REN wdirw.exe wdir.exe

wadd.exe : waddw.exe ..\util\stubit.exe
    ..\util\stubit waddw.exe
    @IF EXIST wadd.exe DEL wadd.exe
    REN waddw.exe wadd.exe

wdmem.exe : wdmemw.exe ..\util\stubit.exe
    ..\util\stubit wdmemw.exe
    @IF EXIST wdmem.exe DEL wdmem.exe
    REN wdmemw.exe wdmem.exe

wdirw.exe : wdirw.obj
    $(LINK) $(LFLAGS) wdirw

wdirw.obj : wdir.asm wdxinfo.inc
    $(ASM) $(AFLAGS) wdir.asm,wdirw.obj

waddw.exe : waddw.obj adc.obj ..\wpack\wpack.obj
    $(LINK) $(LFLAGS) waddw ..\wpack\wpack.obj adc,waddw

waddw.obj : wadd.asm wdxinfo.inc
    $(ASM) $(AFLAGS) wadd.asm,waddw.obj

..\wpack\wpack.obj :
    CD ..\wpack
    make wpack.obj
    CD ..\tools

adc.obj : dualmode.inc general.inc adc.asm wdxinfo.inc
    $(ASM) $(AFLAGS) adc.asm

wdmemw.exe : wdmemw.obj
    $(LINK) $(LFLAGS) wdmemw

wdmemw.obj : wdmem.asm wdxinfo.inc
    $(ASM) $(AFLAGS) wdmem.asm,wdmemw.obj

..\util\stubit.exe :
    CD ..\util
    make stubit.exe
    CD ..\tools

get :
    $(CO) wadd.asm
    $(CO) wdir.asm
    $(CO) wdxinfo.inc
    $(CO) wdmem.asm
    $(CO) dualmode.inc
    $(CO) general.inc
    $(CO) adc.asm
    CD ..\wpack
    $(CO) makefile
    make get
    CD ..\tools

clean :
    @IF EXIST *.map DEL *.map
    @IF EXIST *.exe DEL *.exe
    @IF EXIST *.obj DEL *.obj
    @IF EXIST *.bak DEL *.bak
    CD ..\wpack
    make clean
    CD ..\tools

