# ############################################################################
# ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
# ##                                                                        ##
# ## Released under the terms of the WDOSX license agreement.               ##
# ############################################################################
#
# $Header: E:/RCS/WDOSX/0.95/SRC/kernel/makefile 1.5 2001/04/07 18:43:44 MikeT Exp $
#
# ----------------------------------------------------------------------------
#
# $Log: makefile $
# Revision 1.5  2001/04/07 18:43:44  MikeT
# Allow to work under Win2k where DEL returns an error code.
#
# Revision 1.4  1999/02/07 17:44:01  MikeT
# Use AFLAGS and LFLAGS, updated copyright.
#
# Revision 1.3  1999/02/06 16:24:16  MikeT
# make wdxinfo.inc local.
#
# Revision 1.2  1999/02/06 15:16:41  MikeT
# Corrected GET target
#
# Revision 1.1  1999/02/06 15:15:41  MikeT
# Initial check in
#
#
# ----------------------------------------------------------------------------
#
# Makefile for the WDOSX kernel
#
ASM = tasm32.exe
AFLAGS = /m9 /l
LINK = tlink.exe
LFLAGS = /3
CO = coo.exe

makefile : wdosx.dx wdosxle.exe

wdosx.dx : wdosx.exe
    @IF EXIST wdosx.dx DEL wdosx.dx
    REN wdosx.exe wdosx.dx

wdosx.exe : wdosx.obj
    $(LINK) $(LFLAGS) wdosx.obj
    ..\hacks\sh wdosx.exe wdosx.exe
    ..\hacks\wdcomp wdosx.exe

wdosxle.exe : wdosxle.obj
    $(LINK) $(LFLAGS) wdosxle.obj
    ..\hacks\sh wdosxle.exe wdosxle.exe
    ..\hacks\wdcomp wdosxle.exe

wdosx.obj : wdosx.asm
    $(ASM) $(AFLAGS) wdosx

wdosxle.obj : wdosx.asm loadle.inc
    $(ASM) $(AFLAGS) /D__WATCOM__ wdosx, wdosxle

loadle.inc : loadle.exe
    ..\hacks\toinc loadle.exe loadle.inc

loadle.exe : loadle.asm leheader.inc
    $(ASM) $(AFLAGS) loadle
    $(LINK) $(LFLAGS) loadle

get :
    $(CO) wdosx.asm
    $(CO) leheader.inc
    $(CO) loadle.asm
    $(CO) wdxinfo.inc

clean :
    @IF EXIST *.LST DEL *.LST
    @IF EXIST *.obj DEL *.obj
    @IF EXIST *.exe DEL *.exe
    @IF EXIST loadle.inc DEL loadle.inc
    @IF EXIST *.map DEL *.map
    @IF EXIST wdosx.dx DEL wdosx.dx
