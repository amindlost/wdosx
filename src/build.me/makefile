# ############################################################################
# ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
# ##                                                                        ##
# ## Released under the terms of the WDOSX license agreement.               ##
# ############################################################################
#
# $Header: E:/RCS/WDOSX/0.95/SRC/BUILD.ME/makefile 1.4 2001/04/07 19:25:03 MikeT Exp $
#
# ----------------------------------------------------------------------------
#
# $Log: makefile $
# Revision 1.4  2001/04/07 19:25:03  MikeT
# Also fix MD returning an error code for Win2k.
#
# Revision 1.3  2001/04/07 18:40:42  MikeT
# Allow to work under Win2k where DEL returns an error code.
#
# Revision 1.2  2000/05/28 12:39:35  MikeT
# Add wdmem utility.
#
# Revision 1.1  1999/02/07 20:47:22  MikeT
# Initial check in.
#
#
# ----------------------------------------------------------------------------
#
# Build all the WDOSX binaries
#

CO = coo.exe

makefile : stubit.exe wudebug.exe wadd.exe wdir.exe kernel32.wdl user32.wdl \
           oleaut32.wdl advapi32.wdl wdmem.exe

stubit.exe : ..\util\stubit.exe
    COPY ..\util\stubit.exe

wudebug.exe : ..\deb\wudebug.exe
    COPY ..\deb\wudebug.exe

wadd.exe : ..\tools\wadd.exe
    COPY ..\tools\wadd.exe
 
wdir.exe : ..\tools\wdir.exe
    COPY ..\tools\wdir.exe

wdmem.exe : ..\tools\wdmem.exe
    COPY ..\tools\wdmem.exe

kernel32.wdl : ..\win32\kernel32.wdl
    COPY ..\win32\kernel32.wdl

user32.wdl : ..\win32\user32.wdl
    COPY ..\win32\user32.wdl

oleaut32.wdl : ..\win32\oleaut32.wdl
    COPY ..\win32\oleaut32.wdl

advapi32.wdl : ..\win32\advapi32.wdl
    COPY ..\win32\advapi32.wdl


..\util\stubit.exe :
    CD ..\util
    nmake stubit.exe
    CD ..\build.me

..\deb\wudebug.exe :
    CD ..\deb
    nmake wudebug.exe
    CD ..\build.me

..\tools\wadd.exe :
    CD ..\tools
    nmake wadd.exe
    CD ..\build.me

..\tools\wdir.exe :
    CD ..\tools
    nmake wdir.exe
    CD ..\build.me

..\tools\wdmem.exe :
    CD ..\tools
    nmake wdmem.exe
    CD ..\build.me

..\win32\kernel32.wdl :
    CD ..\win32
    nmake kernel32.wdl
    CD ..\build.me

..\win32\user32.wdl :
    CD ..\win32
    nmake user32.wdl
    CD ..\build.me

..\win32\oleaut32.wdl :
    CD ..\win32
    nmake oleaut32.wdl
    CD ..\build.me

..\win32\advapi32.wdl :
    CD ..\win32
    nmake advapi32.wdl
    CD ..\build.me

get :
    @IF NOT EXIST ..\win32 MD ..\win32
    CD ..\win32
    $(CO) makefile
    make get
    @IF NOT EXIST ..\util MD ..\util
    CD ..\util
    $(CO) makefile
    nmake get
    @IF NOT EXIST ..\tools MD ..\tools
    CD ..\tools
    $(CO) makefile
    nmake get
    @IF NOT EXIST ..\deb MD ..\deb
    CD ..\deb
    $(CO) makefile
    nmake get
    CD ..\build.me

clean :
    CD ..\util
    nmake clean
    CD ..\win32
    nmake clean
    CD ..\tools
    nmake clean
    CD ..\deb
    nmake clean
    CD ..\build.me
    @if exist *.exe DEL *.exe
    @if exist *.wdl DEL *.wdl
