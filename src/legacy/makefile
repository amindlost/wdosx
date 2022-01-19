# ############################################################################
# ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
# ##                                                                        ##
# ## Released under the terms of the WDOSX license agreement.               ##
# ############################################################################
#
# $Header: E:/RCS/WDOSX/0.95/SRC/legacy/makefile 1.2 2001/04/07 19:04:36 MikeT Exp $
#
# ----------------------------------------------------------------------------
#
# $Log: makefile $
# Revision 1.2  2001/04/07 19:04:36  MikeT
# Allow to work under Win2k where DEL returns an error code.
#
# Revision 1.1  1999/02/07 18:17:22  MikeT
# Initial check in.
#
#
# ----------------------------------------------------------------------------
#
# Makefile for the the old Win32 PE loaders.
#
# Note: This code is no longer being maintained. The reason why it's still
# here is that it is used to build the floating application segment loaders
# for PE files as of WDOSX 0.93 and 0.94. If eventually noone is using this
# feature any more, this directory can be retired.
#
ASM = tasm.exe
AFLAGS = /m9
LINK = tlink.exe
LFLAGS = /3
CO = coo.exe

makefile : loadpe.raw loadpe.win

loadpe.win : loadwin.obj
    $(LINK) $(LFLAGS) loadwin
    ..\hacks\sh loadwin.exe loadpe.win

loadpe.raw : loadraw.obj
    $(LINK) $(LFLAGS) loadraw
    ..\hacks\sh loadraw.exe loadpe.raw

loadwin.obj : LOADPE.ASM IMPORTS.INC WIN32API.INC VARIANT.INC WIDECHR.INC \
              CONHELP.INC CONSOLE.ASI SEH.INC ADVAPI32.ASI LFUNS.ASI UTIL.INC \
              EXCEPT.INC RESRC.INC WINNLS.INC W32STRUC.INC TIME.INC \
              MEMSTAT.INC FATTRIB.INC
    $(ASM) $(AFLAGS) -DWIN32API loadpe.asm, loadwin.obj

#
# 2do: remove unnecessary dependencies from the non-API build
#
loadraw.obj : LOADPE.ASM IMPORTS.INC WIN32API.INC VARIANT.INC WIDECHR.INC \
              CONHELP.INC CONSOLE.ASI SEH.INC ADVAPI32.ASI LFUNS.ASI UTIL.INC \
              EXCEPT.INC RESRC.INC WINNLS.INC W32STRUC.INC TIME.INC \
              MEMSTAT.INC FATTRIB.INC
    $(ASM) $(AFLAGS) loadpe.asm, loadraw.obj


get :
    $(CO) LOADPE.ASM
    $(CO) IMPORTS.INC
    $(CO) WIN32API.INC
    $(CO) VARIANT.INC
    $(CO) WIDECHR.INC
    $(CO) CONHELP.INC
    $(CO) CONSOLE.ASI
    $(CO) SEH.INC
    $(CO) ADVAPI32.ASI
    $(CO) LFUNS.ASI
    $(CO) UTIL.INC
    $(CO) EXCEPT.INC
    $(CO) RESRC.INC
    $(CO) WINNLS.INC
    $(CO) W32STRUC.INC
    $(CO) TIME.INC
    $(CO) MEMSTAT.INC
    $(CO) FATTRIB.INC

clean :
    @IF EXIST *.obj DEL *.obj
    @IF EXIST *.exe DEL *.exe
    @IF EXIST *.map DEL *.map
    @IF EXIST loadpe.raw DEL loadpe.raw
    @IF EXIST loadpe.win DEL loadpe.win
