# ############################################################################
# ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
# ##                                                                        ##
# ## Released under the terms of the WDOSX license agreement.               ##
# ############################################################################
#
# $Header: E:/RCS/WDOSX/0.95/SRC/dos32/makefile 1.1 1999/02/06 17:04:55 MikeT Exp $
#
# ----------------------------------------------------------------------------
#
# $Log: makefile $
# Revision 1.1  1999/02/06 17:04:55  MikeT
# Initial check in.
#
#
# ----------------------------------------------------------------------------
#
# Makefile for the DOS32 loader
#
ASM = tasm.exe
AFLAGS = /m9
LINK = tlink.exe
LFLAGS = /3
CO = coo.exe

makefile : wdx32.dx

wdx32.dx : dos32.exe
    ..\hacks\sh dos32.exe wdx32.dx

dos32.exe : dos32.obj

dos32.obj : dos32.asm

.obj.exe :
    $(LINK) $(LFLAGS) $<

.asm.obj :
    $(ASM) $(AFLAGS) $<

get :
    $(CO) dos32.asm

clean :
    DEL *.exe
    DEL *.obj
    DEL *.dx
    DEL *.map
