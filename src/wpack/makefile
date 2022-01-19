# ############################################################################
# ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
# ##                                                                        ##
# ## Released under the terms of the WDOSX license agreement.               ##
# ############################################################################
#
# $Header: E:/RCS/WDOSX/0.95/SRC/wpack/makefile 1.2 2001/04/07 19:06:54 MikeT Exp $
#
# ----------------------------------------------------------------------------
#
# $Log: makefile $
# Revision 1.2  2001/04/07 19:06:54  MikeT
# Allow to work under Win2k where DEL returns an error code.
#
# Revision 1.1  1999/06/20 15:44:13  MikeT
# Initial check in.
#
#
# ----------------------------------------------------------------------------
#
# Makefile for WPACK
#
CC = bcc32.exe
CCFLAGS = -c -O2 -5
CO = coo.exe

makefile : wpack.obj

wpack.obj : wpack.c wpack.h
    $(CC) $(CCFLAGS) wpack.c

get :
    $(CO) WPACK.C
    $(CO) WPACK.H

clean :
    @IF EXIST wpack.obj DEL wpack.obj
