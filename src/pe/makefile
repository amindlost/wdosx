# ############################################################################
# ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
# ##                                                                        ##
# ## Released under the terms of the WDOSX license agreement.               ##
# ############################################################################
#
# $Header: E:/RCS/WDOSX/0.95/SRC/pe/makefile 1.2 2001/04/07 18:47:12 MikeT Exp $
#
# ----------------------------------------------------------------------------
#
# $Log: makefile $
# Revision 1.2  2001/04/07 18:47:12  MikeT
# Allow to work under Win2k where DEL returns an error code.
#
# Revision 1.1  1999/02/06 17:12:56  MikeT
# Initial check in.
#
#
# ----------------------------------------------------------------------------
#
# Makefile for the WDOSX PE loader
#
ASM = tasm.exe
AFLAGS = /m9
LINK = tlink.exe
LFLAGS = /3
CO = coo.exe

makefile : loadpe.ra0

loadpe.ra0 : loadpe.exe
    ..\hacks\sh loadpe.exe loadpe.ra0

loadpe.exe : loadpe.obj

loadpe.obj : loadpe.asm

.obj.exe :
    $(LINK) $(LFLAGS) $<

.asm.obj :
    $(ASM) $(AFLAGS) $<

get :
    $(CO) loadpe.asm

clean :
    @IF EXIST *.exe DEL *.exe
    @IF EXIST *.obj DEL *.obj
    @IF EXIST *.ra0 DEL *.ra0
    @IF EXIST *.map DEL *.map
