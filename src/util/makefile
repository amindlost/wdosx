# ############################################################################
# ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
# ##                                                                        ##
# ## Released under the terms of the WDOSX license agreement.               ##
# ############################################################################
#
# $Header: E:/RCS/WDOSX/0.95/SRC/UTIL/makefile 1.8 2001/04/07 19:29:36 MikeT Exp MikeT $
#
# ----------------------------------------------------------------------------
#
# $Log: makefile $
# Revision 1.8  2001/04/07 19:29:36  MikeT
# Also fix MD returning an error code for Win2k.
#
# Revision 1.7  2001/04/07 18:41:15  MikeT
# Allow to work under Win2k where DEL returns an error code.
#
# Revision 1.6  1999/06/20 15:52:43  MikeT
# Use Joergen Ibsen's WPACK compressor instead of the old LZ77 one.
#
# Revision 1.5  1999/02/07 18:29:52  MikeT
# Legacy directory is now being build and not just the binaries pulled
# from there.
#
# Revision 1.4  1999/02/06 19:57:33  MikeT
# Get the makefile for the Win32 directory first, before using it...
#
# Revision 1.3  1999/02/06 19:50:14  MikeT
# Also create ..\kernel directory on GET.
#
# Revision 1.2  1999/02/06 19:48:57  MikeT
# Create source directories if not already there.
#
# Revision 1.1  1999/02/06 19:29:49  MikeT
# Initial check in.
#
#
# ----------------------------------------------------------------------------
#
# Makefile for stubit.exe
#
ASM = tasm.exe
AFLAGS = /m9 /mx
CC = bcc32.exe
CCFLAGS = -O2 -5
CO = coo.exe

makefile : stubit.exe

stubit.exe : si.exe ..\win32\kernel32.wdl ..\win32\user32.wdl
    COPY ..\win32\kernel32.wdl
    COPY ..\win32\user32.wdl
    COPY si.exe stubit.exe
    stubit si.exe
    si stubit.exe

..\win32\kernel32.wdl :
    CD ..\win32
    nmake kernel32.wdl
    CD ..\util

..\win32\user32.wdl :
    CD ..\win32
    nmake user32.wdl
    CD ..\util

si.exe : dosext.h load_hll.h load_cof.h load_asm.h load_le.h load_rdf.h \
             load_pe0.h load_d32.h stubit.c addfile.obj import.obj \
             ..\wpack\wpack.obj
    $(CC) $(CCFLAGS) -esi.exe stubit.c addfile.obj import.obj ..\wpack\wpack.obj

..\wpack\wpack.obj :
    cd ..\wpack
    nmake wpack.obj
    cd ..\util

addfile.obj : addfile.asm

import.obj : import.asm

dosext.h : ..\kernel\wdosx.dx
    ..\hacks\toh ..\kernel\wdosx.dx dosext.h wdosx_bin

..\kernel\wdosx.dx :
    CD ..\kernel
    nmake wdosx.dx
    CD ..\util

load_hll.h : ..\legacy\loadpe.win
    ..\hacks\toh ..\legacy\loadpe.win load_hll.h winPE_bin

..\legacy\loadpe.win :
    CD ..\legacy
    nmake loadpe.win
    CD ..\util

load_cof.h : ..\coff\stubc.cof
    ..\hacks\toh ..\coff\stubc.cof load_cof.h coff_bin

..\coff\stubc.cof :
    CD ..\coff
    nmake stubc.cof
    CD ..\util

load_asm.h : ..\legacy\loadpe.raw
    ..\hacks\toh ..\legacy\loadpe.raw load_asm.h rawPE_bin

..\legacy\loadpe.raw :
    CD ..\legacy
    nmake loadpe.raw
    CD ..\util

load_le.h : ..\kernel\wdosxle.exe
    ..\hacks\toh ..\kernel\wdosxle.exe load_le.h LE_bin

..\kernel\wdosxle.exe :
    CD ..\kernel
    nmake wdosxle.exe
    CD ..\util

load_rdf.h : ..\rdoff\rdoff.rd
    ..\hacks\toh ..\rdoff\rdoff.rd load_rdf.h rdfload_bin

..\rdoff\rdoff.rd :
    CD ..\rdoff
    nmake rdoff.rd
    CD ..\util

load_pe0.h : ..\pe\loadpe.ra0
    ..\hacks\toh ..\pe\loadpe.ra0 load_pe0.h peload_ra0

..\pe\loadpe.ra0 :
    CD ..\pe
    nmake loadpe.ra0
    CD ..\util

load_d32.h : ..\dos32\wdx32dx
    ..\hacks\toh ..\dos32\wdx32.dx load_d32.h dos32_bin

..\dos32\wdx32dx :
    CD ..\dos32
    nmake wdx32.dx
    CD ..\util

.asm.obj :
    $(ASM) $(AFLAGS) $<

get :
    $(CO) ADDFILE.ASM
    $(CO) GENERAL.INC
    $(CO) WDXINFO.INC
    $(CO) DUALMODE.INC
    $(CO) W32STRUC.INC
    $(CO) IMPORT.ASM
    $(CO) STUBIT.C
    $(CO) WDXINFO.H
    @IF NOT EXIST ..\dos32 MD ..\dos32
    CD ..\dos32
    $(CO) makefile
    nmake get
    @IF NOT EXIST ..\rdoff MD ..\rdoff
    CD ..\rdoff
    $(CO) makefile
    nmake get
    @IF NOT EXIST ..\pe MD ..\pe
    CD ..\pe
    $(CO) makefile
    nmake get
    @IF NOT EXIST ..\coff MD ..\coff
    CD ..\coff
    $(CO) makefile
    nmake get
    @IF NOT EXIST ..\kernel MD ..\kernel
    CD ..\kernel
    $(CO) makefile
    nmake get
    @IF NOT EXIST ..\win32 MD ..\win32
    CD ..\win32
    $(CO) makefile
    nmake get
    @IF NOT EXIST ..\legacy MD ..\legacy
    CD ..\legacy
    $(CO) makefile
    nmake get
    @IF NOT EXIST ..\wpack MD ..\wpack
    CD ..\wpack
    $(CO) makefile
    nmake get
    CD ..\util

clean :
    @if exist dosext.h del dosext.h
    @if exist load_hll.h del load_hll.h
    @if exist load_cof.h del load_cof.h
    @if exist load_asm.h del load_asm.h
    @if exist load_le.h del load_le.h
    @if exist load_rdf.h del load_rdf.h
    @if exist load_pe0.h del load_pe0.h
    @if exist load_d32.h del load_d32.h
    @if exist *.obj del *.obj
    @if exist *.exe del *.exe
    @if exist *.map del *.map
    @if exist *.wdl del *.wdl
    @if exist *.bak del *.bak
    CD ..\dos32
    nmake clean
    CD ..\rdoff
    nmake clean
    CD ..\pe
    nmake clean
    CD ..\coff
    nmake clean
    CD ..\kernel
    nmake clean
    CD ..\win32
    nmake clean
    CD ..\legacy
    nmake clean
    CD ..\wpack
    nmake clean
    CD ..\util
