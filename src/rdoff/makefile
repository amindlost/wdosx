# ############################################################################
# ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
# ##                                                                        ##
# ## Released under the terms of the WDOSX license agreement.               ##
# ############################################################################
#
# $Header: E:/RCS/WDOSX/0.95/SRC/rdoff/makefile 1.2 2001/04/07 18:45:36 MikeT Exp $
#
# ----------------------------------------------------------------------------
#
# $Log: makefile $
# Revision 1.2  2001/04/07 18:45:36  MikeT
# Allow to work under Win2k where DEL returns an error code.
#
# Revision 1.1  1999/02/06 18:00:20  MikeT
# Initial check in.
#
#
# ----------------------------------------------------------------------------
#
# Makefile for the WDOSX RDOFF loader
#
ASM = tasm.exe
AFLAGS = /m9
LINK = tlink.exe
LFLAGS = /3
CO = coo.exe

makefile : rdoff.rd

rdoff.rd : rdoff.exe
    ..\hacks\sh rdoff.exe rdoff.rd

rdoff.exe : rdoff.obj

rdoff.obj : rdoff.asm

.obj.exe :
    $(LINK) $(LFLAGS) $<

.asm.obj :
    $(ASM) $(AFLAGS) $<

get :
    $(CO) rdoff.asm

clean :
    @IF EXIST *.exe DEL *.exe
    @IF EXIST *.obj DEL *.obj
    @IF EXIST *.rd DEL *.rd
    @IF EXIST *.map DEL *.map
