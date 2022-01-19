# ############################################################################
# ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
# ##                                                                        ##
# ## Released under the terms of the WDOSX license agreement.               ##
# ############################################################################
#
# $Header: E:/RCS/WDOSX/0.95/SRC/DEB/makefile 1.3 2001/04/07 19:06:00 MikeT Exp MikeT $
#
# ----------------------------------------------------------------------------
#
# $Log: makefile $
# Revision 1.3  2001/04/07 19:06:00  MikeT
# Allow to work under Win2k where DEL returns an error code.
#
# Revision 1.2  1999/02/13 14:26:32  MikeT
# Moved the debugger to true flat memory model. Do not use -m_float
# anymore when stubbing WUDEBUG.
#
# Revision 1.1  1999/02/07 20:03:59  MikeT
# Initial check in.
#
#
# ----------------------------------------------------------------------------
#
# Makefile for WUDEBUG.EXE
#
ASM = tasm.exe
AFLAGS = /m9
LINK = tlink32.exe
LFLAGS =
CO = coo.exe

makefile : wudebug.exe

wudebug.exe : DISASM.OBJ INSNSD.OBJ SYNC.OBJ SDEBUG.OBJ MAIN.OBJ SLIB.OBJ \
              ..\util\stubit.exe
    $(LINK) $(LFLAGS) DISASM.OBJ INSNSD.OBJ SYNC.OBJ SDEBUG.OBJ MAIN.OBJ \
 SLIB.OBJ,wudebug.exe
 ..\util\stubit wudebug.exe

#
# 2do: work out include dependencies
#
main.obj : main.asm
slib.obj : slib.asm
sdebug.obj : sdebug.asm loadle.inc

disasm.obj : disasm.ob
    copy disasm.ob disasm.obj

insnsd.obj : insnsd.ob
    copy insnsd.ob insnsd.obj

sync.obj : sync.ob
    copy sync.ob sync.obj

loadle.inc : ..\kernel\loadle.inc
    COPY ..\kernel\loadle.inc

..\kernel\loadle.inc :
    CD ..\kernel
    make loadle.inc
    CD ..\deb

..\util\stubit.exe :
    CD ..\util
    make stubit.exe
    CD ..\deb

.ob.obj :
    COPY $< *.obj

.asm.obj :
    $(ASM) $(AFLAGS) $<

get :
    $(CO) DEBUG.INC
    $(CO) FLAGS.INC
    $(CO) LOADER.ASM
    $(CO) HELP.INC
    $(CO) MAIN.ASM
    $(CO) SCREEN.ASM
    $(CO) SDEBUG.ASM
    $(CO) SLIB.ASM
    $(CO) IFIELD.INC
    $(CO) INBOX.INC
    $(CO) KEYS.INC
    $(CO) KEYTAB.INC
    $(CO) MEMWIN.INC
    $(CO) REGWIN.INC
    $(CO) SEGDEF.INC
    $(CO) UPDATE.INC
    $(CO) KEYBOARD.ASM
    $(CO) STACKWIN.INC
    $(CO) NFIELDS.INC
    $(CO) HELPSCR.INC
    $(CO) sync.ob
    $(CO) disasm.ob
    $(CO) insnsd.ob

clean :
    @IF EXIST *.obj DEL *.obj
    @IF EXIST *.map DEL *.map
    @IF EXIST *.exe DEL *.exe
    @IF EXIST *.bak DEL *.bak
    @IF EXIST loadle.inc DEL loadle.inc
