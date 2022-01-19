# ############################################################################
# ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
# ##                                                                        ##
# ## Released under the terms of the WDOSX license agreement.               ##
# ############################################################################
#
# $Header: E:/RCS/WDOSX/0.95/SRC/coff/makefile 1.2 2001/04/07 18:48:24 MikeT Exp $
#
# ----------------------------------------------------------------------------
#
# $Log: makefile $
# Revision 1.2  2001/04/07 18:48:24  MikeT
# Allow to work under Win2k where DEL returns an error code.
#
# Revision 1.1  1999/02/06 16:54:02  MikeT
# Initial check in.
#
#
# ----------------------------------------------------------------------------
#
# Makefile for the DJGPP v2 .COFF loader
#
ASM = tasm.exe
AFLAGS = /m9
LINK = tlink.exe
LFLAGS = /3
CO = coo.exe

makefile : stubc.cof

stubc.cof : stubcf.exe
    ..\hacks\sh stubcf.exe stubc.cof

stubcf.exe : stubcf.obj

stubcf.obj : stubcf.asm

.obj.exe :
    $(LINK) $(LFLAGS) $<

.asm.obj :
    $(ASM) $(AFLAGS) $<

get :
    $(CO) stubcf.asm

clean :
    @IF EXIST *.exe DEL *.exe
    @IF EXIST *.obj DEL *.obj
    @IF EXIST *.cof DEL *.cof
    @IF EXIST *.map DEL *.map
