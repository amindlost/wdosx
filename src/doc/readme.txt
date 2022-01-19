##############################################################################
##                                                                          ##
##                          WDOSX 0.97                                      ##
##                                                                          ##
##############################################################################


 1. INTRODUCTION


 2. GETTING STARTED

  2.1 Getting started using plain assembly
   2.1.1 Getting started with TASM
     2.1.1.1 What if I really want to use MZ?
     2.1.1.2 I'd rather go for PE!
   2.1.2 Getting started with NASM
     2.1.2.1 Just in case, how does the binary stuff work, anyway?
     2.1.2.2 Oh no! I rather use RDOFF!

  2.2 Getting started with HLL compilers
   2.2.1 The WDOSX Win32 API emulation
   2.2.2 Getting started with Borland Delphi 2,3,4
   2.2.3 Getting started with Borland C/C++
   2.2.4 Getting started with MSVC++

  2.3 Getting started with Watcom C++

  2.4 Getting Started with DJGPP


 3. TECH STUFF

  3.1 The built-in DPMI host

  3.2 Main program memory layout and the WDMEM utility

  3.3 What is WFSE?


 4. THE WDOSX API

  4.1 The extended DOS API
   4.1.1 Overview INT 21h
   4.1.2 Detailed list of WDOSX extended DOS API functions:

  4.2 Extended mouse functions (INT 33h)

  4.3 The WFSE API

  4.4 Other WDOSX functions


 5. THE END



 1. INTRODUCTION

 This documentation is a  complete mess because  I am a  programmer, not a
 tech writer.  If  there  should be  someone  out  there  with appropriate
 writing skills  and a decent  understanding of  the matter willing  to do
 something about this at no charge...

 Nevertheless, I think this document contains all the information you need
 to use WDOSX for your projects, experiments, whatever.

 For these who accidentally downloaded the package:

 WDOSX is a free 32 bit DOS extender.

 WDOSX  supports RAW/XMS/VCPI/DPMI  memory  allocation.  It  has  built in
 support for almost all  of the DPMI  0.9 API functions.  It also provides
 extended versions of the  most frequently used DOS  INT 21H functions and
 it extends some functions of the mouse driver INT33H too.

 WDOSX comes with WUDEBUG, a 32 bit DPMI full screen debugger.

 WDOSX extended programs have been  tested or reported to successfully run
 under all kinds of DOS 3.3 or better such as MS-DOS, DR-DOS, PC-DOS, PTS-
 DOS, Novell DOS, Caldera OpenDOS, DOS- boxes of Windows (3.x, 95, 98, NT,
 ME, 2K, XP), OS/2 and the DOS emulator of Linux.

 This allows  WDOSX extended  programs  to run  on like  99%  of currently
 installed PC!

 WDOSX now provides support for the following executable file formats:

 -------------------------------------------------------------------------
 Executable file    Development            Additional features supported
 format             environment            C = EXE compression,
                                           D = DLL support
                                           T = True flat model
 -------------------------------------------------------------------------
 32 bit  DOS "MZ"   TASM, MASM...          * obsolete! *

 32 bit  plain      NASM                   * obsolete! *
         binary

 RDOFF1, RDOFF2     NASM                   T C

 DOS32   "Adam"     TMT Pascal, ASM +      T C
                    DLINK                  Limited INT 31/EExx API support
                                           provided
 COFF               DJGPP v2.0             C

 LE                 Watcom C++             T C

 Raw PE (no Win32   TASM, MASM, NASM...    T C
         API)

 PE     (Win32 API  Borland C++ 4.0+       T C D
         support)   Borland Delphi 2.0+
                    Borland C++ Builder
                    MSVC++ 4.0+
 -------------------------------------------------------------------------

 If you  do not  know what  "True Flat"  or  "Floating Segment"  means, no
 worries! In that case  it was not  something you already  ran into. "True
 Flat" means that  the code and  data segment your  program runs  in has a
 fixed linear base address of  just zero, which means  that you can access
 anything with  just  near  offsets. No  additional  zero  base selectors,
 negative  offset calculation  to  access  DOS/BIOS  memory,  video memory
 ...and so... anymore!

 When starting a new project,  do not bother to  even remotely consider MZ
 or Flat Form Binary as a potential  choice. These formats really suck and
 there are better alternatives for both.

 All you need to  convert one of the  above executables into a  32 bit DOS
 program is  to run  STUBIT.EXE  on them.  Subject  to some  more  or less
 obvious restrictions, that is. No special linking, parameter setting etc,
 In short: No user serviceable parts inside! This makes WDOSX very easy to
 use, I think.


 Opening the box...

 The BIN directory contains all the generic tools you need for creating 32
 bit DOS application with WDOSX.

 STUBIT.EXE: This is the stub manager that selects the appropriate modules
             to add to your application program, adds these and compresses
             the final binary.

 WUDEBUG.EXE: A debugger you can use to debug any WDOSX application.
 
 KERNEL32.WDL: kernel32 module of the Win32 emulator
 USER32.WDL:   user32 module of the Win32 emulator
 OLEAUT32.WDL: oleaut32 module of the Win32 emulator
 ADVAPI32.WDL: advapi32 module of the Win32 emulator

 WDIR.EXE: Lets you display a listing of all modules in a WDOSX executable

 WADD.EXE: Lets you add new modules to a WDOSX executable (see "WFSE")

 WDMEM.EXE: Lets you restrict the extended memory usage of a WDOSX program



 Author Contact:

 Michael Tippach (mtippach@gmx.net)

 ! Please don't send any more email to the following addresses: !

      wuschel@geocities.com - gone
      wdosx@wuschel.demon.co.uk - gone soon
      michael_tippach@phoenix.com - gone

 To subscribe to the WDOSX mailing list, send an email to:

      wdosx-subscribe@yahoogroups.com

 You will be asked for confirmation and all that stuff to avoid abuse.  In
 either case you may want to stay in touch with the WWW site I maintain on
 the subject at:

      http://michael.tippach.bei.t-online.de/wdosx/
      http://wdosx.homeip.net/wdosx/

 The latter should only be seen as a backup - due to bandwidth constraints
 resuting from this one being merely a bedroom machine connected via ADSL.
 

 ! Please don't link to any one of the following URLs anymore: !

      http://www.wuschel.demon.co.uk/ - gone soon
      http://www.geocities.com/SiliconValley/Park/4493/ - gone

 WDOSX is freeware. Then again, if you really, really feel like sending me
 money, beer or so, I certainly won't complain. See the file "license.txt"
 for the stuff that makes lawyers happy.


 Credits

 (In no defined order)

 James Budiono,  Chet  Simpson,  Niklas Martinsson,  Johan  Prins,   Eriks
 Aleksans, Mark  Junker, Marko  "Otti" Guth,  Patrick Gleichmann,   Stefan
 Hoffmeister, Paul  Robson, Gaz  Jones,  Alejandro Balliva,    Urmas Haud,
 Christian Helmis, Matt Currie, Peter Kouwenhoven,  Oleg Prokhorov,  Pedro
 Gimeno, Tony Low...

 Thank you  for reporting  bugs, making  constructive suggestions  and for
 going through all the hassles of testing the preliminary stuff  I came up
 with ... and so on!  (You all probably know what "so on" means)

 Simon Tahtham/ Julian Hall

 The authors of NASM.  With their kind permission  I use their instruction
 decode routine in the debugger. Thanks for NASM anyway!

 Joergen Ibsen

 Who gave us WDOSX- PACK, a much better compression than we had in version
 0.95, along with the permission to make it an integral part of WDOSX

 Ralf Brown  (Well, we all know...)

 I'm sure I forgot someone.  Murphy's law (or its  derivatives) say that I
 forgot the  one who helped  me the  most... Well, you  know who  you are,
 don't you?

 If you feel your name should be listed here, let me know...

 Generally: Thanks to all people giving away something useful for free!



 2. GETTING STARTED

 2.1 Getting started using plain assembly

 2.1.1 Getting started with TASM

 Note that  with MASM  it is  basically the  same. You  should be  able to
 figure it out yourself without significant difficulties.

 There are  two ways  to go  with TASM.  You could  create a  "32-bit Tiny
 Model" executable in DOS "MZ"  format or you could  decide that using the
 ".model flat"--  directive and linking  to a  PE executable would  be the
 better choice.

 Using PE instead of MZ will give you:

 1.    A true flat memory model (INT 21/FFFF will be unavailable, though).
 2.    Executable compression.
 3.    DLL support.
 4.    A  BSS  section. That means: uninitialized data storage that is
       automatically allocated for you at load time.
 5.    No size/ address restrictions as towards the executable and the
       program entry point and so on.
 6.    Some C style ARGC, ARGV[] and ENV[] support.
 7.    A much cleaner approach. For the whole concept of  MZ is not really
       suited to build 32 bit programs with advanced features.

 However, WDOSX supports both formats, but please, switch to PE as soon as
 you can as this will save you and me a lot of unnecessary grief!


 2.1.1.1 What if I really want to use MZ?

 To get a 32 bit DOS "MZ" executable, you would have to write your code as
 follows:


 .386
 code SEGMENT USE32
 ASSUME cs:code,ds:code,ss:code

 hwstring  db 'HELLO WORLD!',0dh,0ah,'$'

 start:
 ;
 ; enable virtual interrupts
 ;
           mov ax, 0901h
           int 31h
 ;
 ; Print a message using WDOSX extended DOS API
 ;
           mov  edx, OFFSET hwstring
           mov  ah, 9
           int  21h
 ;
 ; Terminate
 ;
           mov  ax, 4C00h
           int  21h
 code ENDS
 END start


 Make sure there's only one segment, don't use ".model flat"!

 TASM it: "TASM mycode.asm"
 TLINK it: "TLINK /3 mycode"
 STUB it: "STUBIT mycode.exe"

 "mycode.exe" will be your DOS extended program now.

 WDOSX will start your  "32-bit MZ" executable program  with the following
 entry conditions:


 CS:EIP          ...take a wild guess!
 DS, SS          Data aliases of CS
 ES              Selector to the program's PSP
 ESP             (Size of your program code and initialized data) + 1024,
                 DWORD aligned
 All other       Undefined
 registers
 Virtual         Disabled
 Interrupts



 2.1.1.2 I'd rather go for PE!

 Smart decision, your "Hello, world!" program could look like this:


 .386
 .model flat
 .code

 start:
 ;
 ; Print the hello world thing
 ;
           lea  edx, HwString
           mov  ah, 9
           int  21h
 ;
 ; Terminate
 ;
           mov  eax, 4C00h
           int  21h

 .data

 HwString db 'Hello, world',0dh,0ah,'$'

 END start


 TASM it: "TASM example.asm" ( or "TASM32 example.asm" for that matter )
 LINK it "TLINK32 example"
 STUB it "stubit example.exe"

 WDOSX will start your "32-bit PE" executable program  with the following
 entry conditions:


 CS          Base 0 4G descriptor
 DS, SS      Data aliases of CS
 ES          Selector to the program's PSP
 ESP         Top of memory block that is at least STACK_COMMIT in size
             (see PE spec.)
 ESI         The number of command line arguments, where the path and
             filename of the program itself does count also, IOW argc
             cannot be 0. The same as "argc" in a C program.
 EDI         Near pointer to an array of near pointers,  terminated by a
             NULL pointer, pointing to one of the command line arguments
             each. The same as "argv" in a C program.
 EBP         Near pointer to an array of near pointers, terminated by a
             NULL pointer, pointing to one of the environment strings
             each. The same as "env" in a C program.
 All other   Undefined
 registers
 Virtual     Enabled
 Interrupts


 Even if  you are  not dealing  with C  at all,  this  argc, argv  and env
 support saves  lots  of programming  work.  The easiest  way  to  write a
 startup code that calls a C _main function could look like that:


           push ds
           pop  es
           push ebp       ; env
           push edi       ; argv
           push esi       ; argc
           call _main
           mov  ah, 4Ch
           int  21h


 Note that "argc", "argv" and "env" are only available to a PE executable.
 For 32 bit  "MZ" executables, esi,  edi and  ebp do  not contain anything
 meaningful!

 As of WDOSX 0.95,  you CAN use dynamic  linking and even  create your own
 DLLs in whatever language you prefer. In case you do not already know how
 to do that, have  a look at the  source code of the  Win32 API emulation-
 straight TASM code! Keep in mind that, if you  want to use DLLs, you need
 the KERNEL32.WDL module,  either as part  of the  executable image ("wadd
 myexe.exe kernel32.wdl") or as part of your distribution package. This is
 because  KERNEL32.WDL contains  the  routines  for  load  time/ run  time
 linking of  DLLs.  If you  use  the latter  approach,  the  program entry
 conditions are  different from  these of  am  "API-less" PE,  they rather
 resemble these used by a true Win32- executable.  WDOSX will  start  your
 "Win32 API- PE"  executable program  with the following entry conditions:


 CS:EIP         Base 0 4G descriptor
 DS, SS, ES     Data aliases of CS
 ESP            Top of memory block that is at least STACK_COMMIT in size
                (see PE spec.)
 FS             Selector to Thread Information Block (TIB)
 All other      Undefined
 registers
 Virtual        Enabled
 Interrupts


 To get access to  command line arguments, environment  strings and so on,
 there are no parameters passed  in registers though, but  you now can use
 API functions like GetCommandLine(), GetEnvironmentVariable() and so on.

 To load a WDL, either make it a load time linked library, by referring to
 any function of  that library in  your .DEF file  or load the  WDL at run
 time  using   LoadLibraryA()   or   LoadLibraryExA(),  GetModuleHandle(),
 GetProcAddress() etc.

 A .WDL is a  normal Win 32 format  DLL renamed to  .WDL. Translation from
 WDL to .DLL extension will be done by  the WDOSX run time internally. So,
 if you want to load  the physical file MYDLL.WDL, you  still would try to
 load the .DLL e.g.


 .data
 MydllStr db 'MYDLL.DLL', 0

 .code
 LoadTheLib:
           push OFFSET MydllStr
           call LoadLibraryA    ; loads "MYDLL.WDL"


 Also, if you declare imports, do not import from xxxx.WDL, do just as you
 would under real Windows, i.e., the module name for your imports is still
 xxxx.DLL. Never use IMPLIB on a .DLL after you renamed it to .WDL!


 2.1.2 Getting started with NASM


 Occasionally, there are people complaining about NASM.EXE bombing out
 with "Not enough memory" or so. OTOH, NASMW.EXE would give you something
 along the lines of "This program requires Win32" when run from DOS,
 right?

 Wrong! You've got NASM (tested with NASM 0.97) and you've got a DOS
 extender that can deal with Win32 executables, right?

 Right! So why not (just in case) make a backup copy of your NASMW.EXE and
 type in:

 > STUBIT NASMW.EXE
 You might also want to marvel about the fact that NASMW.EXE now is only
 about half the size of the original file. There are two ways to  go with 
 NASM. You could create  a Flat Form Binary or you are as smart as to use
 RDOFF instead.

 Using RDOFF instead of just binary will give you:

 1.    A true flat memory model (INT 21/FFFF will be unavailable, though).
 2.    Executable compression.
 3.    A BSS section. That means: uninitialized data storage that is
       automatically allocated for you at load time.
 4.    No address restrictions WRT the program entry point.
 5.    Some C style ARGC, ARGV[] and ENV[] support.
 6.    A much cleaner approach as the entire concept of loading straight
       binaries is a complete mess.


 2.1.2.1 Just in case, how does the binary stuff work, anyway?

 If you  still think binary  was a  good choice your  code should  look as
 follows:


 [BITS 32]
 [ORG 0]
 ;
 ; Enable interrupts
 ;
           mov  ax, 901h
           int  31h
 ;
 ; Print message
 ;
           mov  edx, hwstring
           mov  ah, 9
           int  21h
 ;
 ; Terminate
 ;
           mov ax, 4c00h
           int 21h

 hwstring db 'HELLO WORLD!',0dh,0ah,'$'



 NASM it: "NASM mycode.asm"
 STUB it: "stubit mycode"

 You will get a warning message. Don't  be confused because of that. There
 is no way to tell a flat form binary file  from a bitmap, textfile and so
 on...That's what  the warning  is all  about. I  mean WDOSX  will execute
 anything you throw at it and sometimes this will get you some interesting
 effects.

 "ren mycode mycode.exe"

 where "mycode.exe" will be your executable program. WDOSX will start your
 32-bit flat form binary executable program with the following entry
 conditions:


 CS:EIP      ...take a wild guess!
 DS, SS      Data aliases of CS
 ES          Selector to the program's PSP
 ESP         (Size of your program code and initialized data) + 1024,
             DWORD aligned
 All other   Undefined
 registers
 Virtual     Disabled
 Interrupts



 2.1.2.2 Oh no! I rather use RDOFF!

 Good choice! Here's how your "Hello, world!" should look like:


 [BITS 32]
 [section .text]
 GLOBAL _WdosxStart
 ;
 ; This is the entry point. It does not necessarily have to be at offset 0
 ; any more, WDOSX will look for the label _WdosxStart and pass control
 ; over there.
 ;
 _WdosxStart:
 ;
 ; Print message
 ;
           mov  edx, hwstring
           mov  ah, 9
           int  21h
 ;
 ; Terminate
 ;
           mov  ax, 4C00h
           int 21h

 [section .data]

 hwstring  db 'HELLO WORLD!',0dh,0ah,'$'



 _WdosxStart  is  your  program  entry  point  because  the  RDOFF  format
 specification is lacking the definition of an "entry point record" or the
 like. Make sure you make that  label "GLOBAL", because otherwise it would
 not appear in the  RDOFF header. WDOSX would  not find it  and start your
 executable at .code:0. This  sort of fall- through-  option has been left
 in as  a default and  I really  don't know why  I did  that in  the first
 place... I will probably remove  it soon, so the loader  will bomb out if
 there  is no  "_WdosxStart"  defined.  For  your  convenience, it's  CaSe
 InSeNsItIvE,  this  means  that   "_wdosxstart"  is  fine   as  would  be
 "_wDoSxStArT" (for the k3wL d00dz).  Entry conditions for RDF executables
 under WDOSX:


 CS          Base 0 4G descriptor
 DS, SS      Data aliases of CS
 ES          Selector to the program's PSP
 ESP         Top of memory block that is at least 64k in size.
 ESI         The number of command line arguments, where the path and
             filename of the program itself does count also, IOW argc
             cannot be 0. The same as "argc" in a C program.
 EDI         Near pointer to an array of near pointers,  terminated by a
             NULL pointer, pointing to one of the command line arguments
             each. The same as "argv" in a C program.
 EBP         Near pointer to an array of near pointers, terminated by a
             NULL pointer, pointing to one of the environment strings
             each. The same as "env" in a C program.
 All other   Undefined
 registers
 Virtual     Enabled
 Interrupts



 The loader  tries to align  .CODE .DATA  and .BSS sections  on a  4k page
 boundary each. This  will succeed if  the DPMI  host is  WDOSX or Windows
 (any flavor), it may be different when running under other DPMI hosts.

 Create your executable as follows:

 "nasm -f rdf -o quake3.exe quake3.asm"
 "stubit quake3.exe"

 There is also  the possibility to  create PE executables.  I mean without
 using a product you  would have to pay  for. This is possible  due to the
 file  "LNK100.EXE",  somewhere  at  Microsoft's,   which  contains  a  PE
 executable linker  update. They  might remove  it  from their  ftp server
 someday, so please do not shout it out too loudly!

 Also, there is ALINK, a freeware linker available at:

      http://www.geocities.com/SiliconValley/Network/4311/index.html

 that creates PE's as well.


 2.2 Getting started with HLL compilers

 2.2.1 The WDOSX Win32 API emulation

 Probably the most advanced feature of WDOSX  is its emulation of a subset
 of the Win32 API, making it work  with compilers that were not originally
 designed to create 32 bit DOS programs.

 As of current, the  following Win32 API functions  are emulated by WDOSX,
 either completely, in parts or as stubs:

 (Note: This table is a bit out of date and reflects the status of WDOSX
 0.95. I've got more important things to do at the moment.)


 Module    Exports

 KERNEL32  AllocConsole, AreFileApisANSI, Beep, CloseHandle,
           CompareStringA, CreateConsoleScreenBuffer, CreateDirectoryA,
           CreateDirectoryW, CreateFileA, CreateFileW, CreateProcessA,
           DebugBreak, DeleteCriticalSection, DeleteFileA, DeleteFileW,
           DosDateTimeToFileTime, EnterCriticalSection, EnumCalendarInfoA,
           ExitProcess, FileTimeToDosDateTime, FileTimeToLocalFileTime,
           FileTimeToSystemTime, FillConsoleOutputAttribute,
           FillConsoleOutputCharacterA, FindClose, FindFirstFileA,
           FindNextFileA, FlushConsoleInputBuffer, FlushFileBuffers,
           FormatMessageA, FreeConsole, FreeEnvironmentStringsA,
           FreeEnvironmentStringsW, FreeLibrary, GetACP, GetCPInfo,
           GetCommandLineA, GetConsoleCP, GetConsoleCursorInfo,
           GetConsoleMode, GetConsoleOutputCP, GetConsoleScreenBufferInfo,
           GetCurrentDirectoryA, GetCurrentProcess, GetCurrentThreadId,
           GetCurrentTime, GetDateFormatA, GetDiskFreeSpaceA,
           GetDriveTypeA, GetEnvironmentStrings, GetEnvironmentStringsA,
           GetEnvironmentStringsW, GetEnvironmentVariableA,
           GetExitCodeProcess, GetFileAttributesA, GetFileAttributesW,
           GetFileInformationByHandle, GetFileSize, GetFileTime,
           GetFileType, GetFullPathNameA, GetLargestConsoleWindowSize,
           GetLastError, GetLocalTime, GetLocaleInfoA, GetLogicalDrives,
           GetModuleFileNameA, GetModuleHandleA,
           GetNumberOfConsoleInputEvents, GetNumberOfConsoleMouseButtons,
           GetOEMCP, GetPrivateProfileStringA, GetProcAddress,
           GetStartupInfoA, GetStdHandle, GetStringTypeA, GetStringTypeW,
           GetSystemDefaultLCID, GetSystemInfo, GetSystemTime,
           GetTempFileNameA, GetThreadLocale, GetTickCount,
           GetTimeZoneInformation, GetVersion, GetVersionExA,
           GetVersionExW, GetVolumeInformationA, GlobalAlloc, GlobalFlags,
           GlobalFree, GlobalHandle, GlobalLock, GlobalMemoryStatus,
           GlobalReAlloc, GlobalSize, GlobalUnlock, HeapAlloc, HeapCreate,
           HeapDestroy, HeapFree, HeapReAlloc, HeapSize,
           InitializeCriticalSection, InterlockedDecrement,
           InterlockedExchange, InterlockedIncrement, IsBadCodePtr,
           IsBadHugeReadPtr, IsBadHugeWritePtr, IsBadReadPtr,
           IsBadWritePtr, LCMapStringA, LCMapStringW,
           LeaveCriticalSection, LoadLibraryA, LoadLibraryExA, LocalAlloc,
           LocalFileTimeToFileTime, LocalFree, LocalReAlloc, MoveFileA,
           MultiByteToWideChar, OutputDebugString, PeekConsoleInputA,
           QueryPerformanceCounter, QueryPerformanceFrequency,
           RaiseException, ReadConsoleA, ReadConsoleInputA, ReadFile,
           RemoveDirectoryA, RemoveDirectoryW, RtlUnwind,
           ScrollConsoleScreenBufferA, SetConsoleCtrlHandler,
           SetConsoleCursorInfo, SetConsoleCursorPosition, SetConsoleMode,
           SetConsoleScreenBufferSize, SetConsoleWindowInfo,
           SetCurrentDirectoryA, SetCurrentDirectoryW, SetEndOfFile,
           SetEnvironmentVariableA, SetFileAttributesA,
           SetFileAttributesW, SetFilePointer, SetFileTime,
           SetHandleCount, SetLastError, SetStdHandle,
           SetUnhandledExceptionFilter, Sleep, SystemTimeToFileTime,
           TerminateProcess, TlsAlloc, TlsFree, TlsGetValue, TlsSetValue,
           UnhandledExceptionFilter, VirtualAlloc, VirtualFree,
           VirtualQuery, WaitForSingleObject, WideCharToMultiByte,
           WriteConsoleA, WriteConsoleOutputA, WriteFile,
           WritePrivateProfileStringA, _hread, _hwrite, _lclose, _lcreat,
           _llseek, _lopen, _lread, _lwrite,  lstrcat, lstrcatA, lstrcmp,
           lstrcmpA, lstrcmpi, lstrcmpiA, lstrcpy, lstrcpyA, lstrcpyn,
           lstrcpynA, lstrlen, lstrlenA
 USER32    CharToOemA, CharToOemBuffA, CharToOemW, EnumThreadWindows,
           GetKeyboardType, GetSystemMetrics, IsCharAlphaNumericA,
           LoadStringA, MessageBoxA, MessageBoxExA, OemToCharA,
           OemToCharBuffA, OemToCharW
 OLEAUT32  SysAllocStringLen, SysFreeString, SysStringLen,
           VariantChangeType, VariantChangeTypeEx, VariantClear,
           VariantCopy, VariantCopyInd, VariantInit
 ADVAPI32  RegCloseKey, RegOpenKeyA, RegOpenKeyExA, RegQueryValueExA


 As a general rule  for Win32- compilers,  you compile to  a Win32 console
 (non- GUI)  target.  Having  done so,  run  STUBIT.EXE  with  your Win32-
 executable. Your final executable  may not be able  to run independently.
 This is because  you need to  either incorporate the  necessary Win32 API
 emulation modules into your executable  image or distribute them together
 with your application. In the BIN  directory, you will find the following
 modules:

 KERNEL32.WDL
 USER32.WDL
 OLEAUT32.WDL
 ADVAPI32.WDL

 These four modules actually represent the  Win32 API emulation. A .WDL is
 nothing but  a  .DLL  with a  different  extension.  You  use  your Win32
 compiler to create your  own DLLs and just  rename them to  .WDL. You can
 keep WDLs as standalone files or you can bind them to the main executable
 image using WADD or the  STUBIT.EXE autoadd feature. At  the time you use
 STUBIT.EXE  with  your  program,   it will look  for all load time linked
 libraries in the following search order:

 1.    Current directory
 2.    Home directory of  STUBIT.EXE

 If it finds the module in question, it will automatically compress it and
 add it to your  final executable image. If  it does NOT  find the module,
 STUBIT will issue  a warning message.  You still can  add missing modules
 later by using the WADD utility or just keep them as separate files.

 At load time/ run time,  WDLs will be looked for  in the following search
 order:

 1.    WFSE (bound to the executable)
 2.    Current directory
 3.    Home directory of your program's .EXE Most common Win32- Errors:

 Things that can go wrong:

 o At runtime you see an   "Unsupported function call"  error message and
   the program aborts. This means that your program uses a Win32 API call
   Windows would support while WDOSX does not.

 o At runtime you get an  EXCEPTION 03 and the  program aborts. This means
   your program called a function I never thought it would be called ever.
   Memorize the module name and RVA displayed  on the screen as this might
   help finding out what function has been called.

 o Some API functions are implemented  as phantom calls since your program
   wants to import them. However, they do not get called ever, usually...
   
 o You get a  runtime error that  indicates a CPU  exception has happened.
   Since I  would not really claim that WDOSX be absolutely bug free, this
   may not have  been your fault,  especially if  the same  code runs fine
   under native Win32  (where  possible). Make sure your  code is O.K. and
   report the bug to me if it still crashes.

 o It just bombs. This means that something else went wrong and nobody has
   a clue. Try Wudebug + Good luck!
 

 2.2.2 Getting started with Borland Delphi 2,3,4

 WDOSX has  been designed  to execute  Turbo  Pascal (DOS)  style programs
 compiled with the Borland  Delphi 2-4 compiler. In  addition, things that
 were not  in the language  as of  Turbo Pascal, like  classes, exceptions
 etc. are also supported now.

 Note that  even  when  running  in a  DOS-  box  under  Windows,  the API
 emulation is used   (as opposed  to the true  Win32 API  present in these
 cases), so  WDOSX- extended programs  will run  as true DOS-  programs in
 either case, making it possible for them to  do anything a DOS program is
 supposed to do in  a DOS box  (using interrupts, writing  directly to the
 screen memory and so on).

 Compile: "dcc32 yourprog.pas"
 Make it a DOS executable: "stubit yourprog.exe"

 "yourprog.exe" now is a DOS- program. Easy, isn't it?

 Alternatively you should be able to build  your project from the IDE, but
 PLEASE: clean up the USES clause from  all that FORMS related rubbish and
 do not forget  to delete the  main form too!  If WDOSX  complains that it
 cannot  register  your window  class,  OLE  server  or  whatever,  that's
 entirely your fault!

 WDOSX 0.95 comes with a  CRT and a DOS unit, where  the latter also fixes
 the missing "port[]" and "mem[]" issues. Note that mem[] addresses linear
 memory starting at 0, e.g.,  the start of the graphics  VGA memory can be
 addressed with "mem[$A0000]"  as opposed  to "mem[$A000:0000]"  in 16 bit
 Borland Pascal.

 Note that the Delphi  compiler does not generate  FPU emulation code. You
 need either an  FPU or  a 32 bit  FPU emulator  to run  programs that use
 floating point types on machines without an FPU (386, 486SX, NX586 etc).


 2.2.3 Getting started with Borland C/C++

 From the IDE, select  Win32 console executable as  target in your project
 options and make sure to have "static libraries" selected as well. ANSI C
 programs should not cause  any problems. You may  want to experiment with
 the Borland  extensions to the  language. Feel  free to  do so  and don't
 forget to tell me how it works!

 A  good idea  would  be  to  create  a  "Tools"  menu  entry "Create  DOS
 executable" so anything is a matter of a few mouse clicks.

 From the command line (for a simple program):

 "BCC32 mycode.c"
 "stubit mycode.exe"

 As a side note: "stubit.exe" itself has been written  in Borland C 5 as a
 Win32 application and then basically been stubbed by itself.

 try {} catch  () {} and  related language  constructs should  work now as
 well as  signal(). Unhandled  exceptions will  end  up (hopefully)  at an
 internal handler causing a  register dump/program abort.  Note that under
 WDOSX there is no guard page, meaning a null pointer unfortunately points
 to valid memory and  will not cause an  access violation if dereferenced.
 Workaround is to avoid dereferencing null pointers.


 2.2.4 Getting started with MSVC++

 Sad, but  true,  as  a matter  of  fact  we do  now  support  a Microsoft
 compiler. So far,  support for MSVC++  4 and  5 has  been implemented. It
 should also work  with  MSVC 6 now but I need  some more feedback on this
 one.

 Please note the three important issues when using WDOSX with MSVC++:

 o WDOSX will only work with the RELEASE version of your project, not with
   the DEBUG version.

 o Because of the different  memory allocation strategy of  the MSVC++ run
   time library you need to  specify the maximum memory  size that will be
   dynamically allocated by your program using the /HEAP linker option. As
   an example, if  your  program mallocs up to 4MB of  memory, you need to
   set it to:
       /HEAP 0x400000, 0x400000
       (Yes, WDOSX uses HeapCommit, not HeapReserve!)

 o Make sure  you do  not  create a  "fixed"  PE executable,  that  is, an
   executable that has the relocation info stripped off. MSVC++ allows you
   to create these kinds of executables. Don't.


 2.3 Getting started with Watcom C++

 There are two possible ways  to go if you like to  use WDOSX with WATCOM.
 If you already have an executable  that uses <whatever> DOS extender, you
 may just do the  obvious: "stubit doom.exe".  Then again, if  you want to
 incorporate WDOSX into your executable at link  time, you need to throw a
 stub file at WLINK:

 Type: "stubit -extract" and there will be 3 new files:

 - wdosx.dx
 - pestub.exe
 - wdosxle.exe

 ...where the first two can be deleted and wdosxle.exe is exactly the stub
 file for use with WLINK. There is not much more to say.


 2.4 Getting Started with DJGPP

 The DJGPP run time requires merely a DPMI server. To prepend WDOSX as the
 DPMI server/loader to your executable,  just run "stubit MyProg.exe". The
 result is a stand alone compressed 32 bit DOS executable.


 3. TECH STUFF

 3.1 The built-in DPMI host

 Currently,  almost all  DPMI  functions  as  described  in  the DPMI  0.9
 specification are supported by WDOSX.  Plus, I included DPMI 1.0 function
 801h due to popular demand.

 If you're not familiar with DPMI, pull the spec from:

 ftp://x2ftp.oulu.fi/pub/msdos/programming/specs/dpmispec.arj


 DPMI 0.9 FUNCTIONS SUPPORTED

 0000h                         alloc ldt descriptors
 0001h                         free ldt descriptors
 0002h                         segment -> selector
 0003h                         get selector increment
 0006h                         get segment base
 0007h                         set segment base
 0008h                         set segment limit
 0009h                         set access rights
 000ah                         create alias
 000bh                         get descriptor
 000ch                         set descriptor
 0100h                         alloc dos- mem
 0101h                         free dos- mem
 0102h                         modify dos- mem
 0200h                         get realmode interrupt vector
 0201h                         set realmode interrupt vector
 0202h                         get exception handler
 0203h                         set exception handler
 0204h                         get pm interrupt vector
 0205h                         set pm interrupt vector
 0300h                         simulate real mode interrupt
 0301h                         call realmode procedure (retf)
 0302h                         call realmode procedure (iret)
 0303h                         allocate realmode callback
 0304h                         free realmode callback
 0400h                         get dpmi version
 0500h                         get free mem
 0501h                         alloc mem
 0502h                         free mem
 0503h                         resize mem
 0600h                         lock linear region
 0601h                         unlock linear region
 0602h                         unlock realmode region
 0603h                         relock realmode region
 0604h                         get physical page size
 0702h                         mark page pageable
 0703h                         discard page
 0800h                         map physical region
 0801h                         unmap physical region
 0900h                         get and disable vi state
 0901h                         get and enable vi state
 0902h                         get vi state




 If an exception handler  has been installed  by your program,  it will be
 called in  a DPMI compliant  manner. Otherwise  the default  handler will
 take over,  causing a either  a register  dump or  a total  system crash,
 depending on  the phases  of the  moon. If  you're  running in  plain DOS
 without a  DPMI host,  WDOSX will  install its  built  in DPMI  host. The
 following section  describes  the  behavior of  the  WDOSX  DPMI  host in
 certain situations. While running under Windows etc. things are depending
 on the DPMI host the system provides.
 If a  protected mode  IRQ  handler has  been installed  by  your program,
 hardware interrupts occurring in real  mode or V86 mode  are passed up to
 it. Otherwise the real (V86) mode handler is called.

 WDOSX can handle a maximum  mode switch nesting level of  16. This may be
 important to know when doing mode switches  from within an IRQ handler or
 even allowing an IRQ handler to be interrupted again.

 All software interrupts up to 0Fh are interpreted as exceptions, so doing
 an INT 5 to  invoke the printscreen  handler will trigger  a bounds check
 exception instead. You may  want to use the  DPMI translation services to
 get INT 5 doing the expected things.

 Unlike the DPMI spec says,  exceptions 0..7 are not  passed down to their
 real mode handlers.

 Because your program is running on privilege level 0 when WDOSX installed
 its own DPMI host, there  will be no stack switch done  by the CPU itself
 if an exception occurs. This will cause the system to crash with a triple
 fault if  your program's  stack is  corrupted at  this point.  Most stack
 faults will crash the machine either way because of this.

 Exception 0F will  be passed down  to real mode  under any circumstances.
 This is because of a nice feature  of the interrupt controller being able
 to generate spurious IRQ 7's.


 3.2 Main program memory layout and the WDMEM utility

 For any program  written in a  HLL such as  C/ C++ or  Delphi, the memory
 model is rue Flat and memory allocation should be done using the run time
 library  i.e.   malloc()/free()  or  getmem()/freemem()   functions.  The
 following applies to pure ASM code:

 The cs:  ds: (=  ss:) descriptors  are initialized  with  a limit  of 4G.
 However, Windows NT 3.5,  for instance, does alter  the descriptor limits
 internally. So,  if  you  like  to know  the  true  limits,  use  the LSL
 instruction.

 Never call INT 31/0503 to resize the segment you're currently running in!
 To keep you away from doing this with  your initial segment, I just don't
 tell you  the handle  the  DPMI host  returned when  WDOSX  allocated the
 memory block.

 For "MZ" and NASM  "Flat From Binary"  formats WDOSX provides  an easy to
 use API function (INT 21/FFFF) that lets you resize your initial segment.
 It MUST be called from within your initial segment, too!

 For all other formats,  the preferred approach is  to use either implicit
 .BSS memory  allocation, INT  31h/0501h  for allocation  of  large memory
 blocks (64k or  bigger) and a  set of  own routines  for finer allocation
 granularity if desired.

 If your program spawns another DPMI-  program, the spawnee might not have
 sufficient extended memory available to it.  This is because the internal
 DPMI host of WDOSX allocates all extended memory available on the system.

 However,  there is a way how you can override this default setting and to
 limit the memory usage of the WDOSX DPMI host.

 First, you have to figure out the peak memory usage of your main program.
 There is no automated way to do this for you,  you have to calculate this
 manually. You might want to at least round up the result and/or add some-
 what more for good measure. If the Win32 emulator is used,  remember that
 it needs some space too.

 Basically,  this would be about the value  you'd have to give to the user
 of your program as a "minimum free extended memory" requirement anyway.

 Then use the WDMEM utility to write that new paramter into your .EXE e.g.

 > WDMEM myexe.exe 1C0000

 - sets the anticipated peak memory requirement of your program to 1.75 MB.

 Note that the actual memory usage of your  program is somewhat higher than
 the value specified. This is because WDOSX needs 4kB page table memory for
 every 4MB memory in use. WDMEM makes these calculations internally, so you
 do not have to care about that.


 3.3 What is WFSE?

 WFSE stands for "Wdosx  File System Extensions" and  provides a mechanism
 to add arbitrary files to any WDOSX extended executable image. Once bound
 to the  EXE, WFSE files  can be  accessed through the  WFSE API  (see API
 documentation below).

 The WFSE API is very similar to the way you would access files by calling
 DOS. WFSE files  are usually compressed,  but that's  something you don't
 have to care  about as compression/  decompression of WFSE  files is done
 transparently for the application that uses the WFSE API. The compression
 ratio is not  all that  great, but acceptable,  I think.

 This is  because  presenting  compressed modules  as  files  requires the
 ability to  seek to  any position  within that  file  and read  data from
 there. Normal  compression  schemes will  not  allow for  this  without a
 considerable  time  penalty.   WFSE  uses  4k   blocks,  each  compressed
 independently. Accesses will be  cached such that  subsequent accesses to
 the  same 4k  block  will  be  served  from  memory.  This makes  loading
 executables, DLLs etc. possible at  virtually no time delay compared with
 uncompressed data.

 There are two simple tools supplied to support WFSE:

 o WADD.EXE adds a file to the internal WFSE file system of an executable.
 o WDIR.EXE just displays all the modules already bound to an executable.

 WADD can be  used, for instance,  to add  more WDL's  to your executable,
 e.g.

 > wadd MyExe.exe MyDLL.wdl

 Try running "wdir stubit.exe"! The output will look like this:

 > wdir stubit.exe
 WdosxMain
 KERNEL32.WDl
 USER32.WDl

 >

 Right! WdosxMain  is the  compressed main  executable, recognized  by the
 loader under exactly that name. As you can  see, WFSE file names need not
 necessarily to be  in 8.3. They  can be up  to 255  characters long, case
 insensitive.

 Furthermore, we learn from this example  that any WFSE file name starting
 with "WDOSX" is reserved for internal use.

 To create a WFSE attachment called "This_is_my_first_WFSE_file_ever", you
 need to  give  WADD.EXE  a third  parameter.  Imagine  MyExe.Exe  is your
 executable image  and file.xyz is  the file  you want  to add  under that
 name:

 > wadd MyExe.Exe file.xyz This_is_my_first_WFSE_file_ever

 So much about the concept.  Problem now was how to ram  it down your, the
 user's throats without creating more confusion than necessary.

 First  thing:  For virgin  (i.e.  unstubbed  or  at  least  un-  WFSE'ed)
 executables,  STUBIT.EXE  will  automatically  take  care  of  executable
 compression.

 If your .EXE is  PE and has Win32  API references in  it, STUBIT.EXE will
 try to  resolve these  by adding  WDL's it  finds  either in  the current
 directory or in  its own home  directory. It will  issue a  warning if it
 could not resolve something that way, even single functions.

 If you like to have some fun, try stubbing a real Windows EXE, not really
 made for  WDOSX,  and watch  STUBIT.EXE  puke to  death  about unresolved
 imports.


 4. THE WDOSX API

 The WDOSX API consists of an extended INT  21H DOS API, an extended mouse
 INT 33H API and other (proprietary) functions, including WFSE.

 Currently,  almost  all  DPMI  functions  as  described  in  the  DPMI0.9
 specification are supported by WDOSX.  Plus, I included function 801h due
 to popular demand. If you're not familiar with DPMI, pull the spec from:

      ftp://x2ftp.oulu.fi/pub/msdos/programming/specs/dpmispec.arj

 The extended  INT  21H is  implemented  in  a way  similar  to  other DOS
 extenders that provide an extended INT 21H DOS API. Just to answer a FAQ:
 DOS  functions that  do  not  need  segment  register  passing in  either
 direction can be called directly and are thus supported "by nature"! This
 may sound obvious to some of you, but it just isn't to everyone.


 4.1 The extended DOS API

 4.1.1 Overview INT 21h


 Function 09h  Write string to console
 Function 1Ah  Set disk transfer area address
 Function 1Bh  Get allocation information for default drive
 Function 1Ch  Get allocation information for specific drive
 Function 1Fh   Get drive parameter block for default drive
 Function 25h  Set interrupt vector
 Function 2Fh  Get disk transfer area address
 Function 32h  Get drive parameter block for specific drive
 Function 34h  Get address of InDos flag
 Function 35h  Get interrupt vector
 Function 39h  Create subdirectory
 Function 3Ah  Remove subdirectory
 Function 3Bh  Change current directory
 Function 3Ch  Create new file
 Function 3Dh  Open existing file
 Function 3Fh  Read from file
 Function 40h  Write to file
 Function 41h  Delete file
 Function 43h  Get/set file attributes
 Function 44h  IOCTL
 Function 47h  Get current directory
 Function 48h  Allocate DOS memory block
 Function 49h  Free DOS memory block
 Function 4Ah  Resize DOS memory block
 Function 4Bh  Load and execute child program
 Function 4Eh  Find first matching file
 Function 4Fh  Find next matching file
 Function 56h  Rename file
 Function 5Ah  Create temporary file
 Function 5Bh  Create new file




 4.1.2 Detailed list of WDOSX extended DOS API functions:


 Function 09h - Write string to console
 --------------------------------------

  AH = 09h
  DS:EDX -> '$'-terminated string

 Note: The size of the string must be less or  equal 16k since this is the
 transfer buffer size of WDOSX.


 Function 1Ah - Set disk transfer area address
 ---------------------------------------------

  AH = 1Ah
  DS:EDX -> Disk Transfer Area

 Note: WDOSX  will keep  an internal  buffer for  the  DTA. Upon  any Find
 First/ Find Next call, WDOSX does the necessary copying to make this call
 transparent for the user program.


 Function 1Bh - Get allocation information for default drive
 -----------------------------------------------------------

  AH = 1Bh

 Returns

  AL = sectors per cluster
  CX = bytes per sector
  DX = total number of clusters
  DS:EBX -> media ID byte


 Function 1Ch - Get allocation information for specific drive
 ------------------------------------------------------------

  AH = 1Bh
  DL = drive (0 = default, 1 = A: etc.)

 Returns

  AL = sectors per cluster
  CX = bytes per sector
  DX = total number of clusters
  DS:EBX -> media ID byte


 Function 1Fh - Get drive parameter block for default drive
 ----------------------------------------------------------

  AH = 1Fh

 Returns

  AL = status (0 = success, -1 = invalid drive)
  DS:EBX -> Drive Parameter Block


 Function 25h - Set interrupt vector
 -----------------------------------  AH = 25h
  AL = interrupt number
  DS:EDX -> new interrupt handler

 Note: This function sets  the protected mode interrupt  vector using DPMI
 call 0205h.


 Function 2Fh - Get disk transfer area address
 ---------------------------------------------

  AH = 2Fh

 Returns

  ES:EBX -> Disk Transfer Area

 Note: If no DTA address  is set, the default DTA  address at PSP:80h will
 be returned, otherwise the return  pointer is the same  as last passed to
 function 1Ah.


 Function 32h - Get drive parameter block for specific drive
 -----------------------------------------------------------

  AH = 32h
  DL = drive number (0 = default, 1 = A: etc.)

 Returns

  AL = status (0 = success, -1 = invalid drive)
  DS:EBX -> Drive Parameter Block


 Function 34h - Get address of InDos flag
 ----------------------------------------

  AH = 34h

 Returns

  ES:EBX -> InDos flag


 Function 35h - Get interrupt vector
 -----------------------------------

  AH = 35h
  AL = interrupt number

 Returns

  ES:EBX -> address of interrupt handler

 Note: This function returns  the address of the  protected mode interrupt
 handler as obtained using DPMI call 0204h.


 Function 39h - Create subdirectory
 ----------------------------------

  AH = 39h
  DS:EDX -> ASCIZ pathname

 Returns

  CF = clear on success, set on error (AX = error code)


 Function 3Ah - Remove subdirectory
 ----------------------------------

  AH = 3Ah
  DS:EDX -> ASCIZ pathname

 Returns
  CF = clear on success, set on error (AX = error code)


 Function 3Bh - Change current directory
 ---------------------------------------

  AH = 3Bh
  DS:EDX -> ASCIZ pathname

 Returns

  CF = clear on success, set on error (AX = error code)


 Function 3Ch - Create new file
 ------------------------------

  AH = 3Ch
  CX = file attributes
  DS:EDX -> ASCIZ filename

 Returns

  CF = clear on success (AX = file handle)
  CF = set on error (AX = error code)


 Function 3Dh - Open existing file
 ---------------------------------

  AH = 3Dh
  AL = access mode
  DS:EDX -> ASCIZ filename

 Returns

  CF = clear on success (AX = file handle) set on error (AX = error code)


 Function 3Fh - Read from file
 -----------------------------

  AH = 3Fh
  BX = file handle
  ECX = number of bytes to read
  DS:EDX -> data buffer

 Returns

  CF = clear on success (EAX = number of bytes actually read)
  CF = set on error (AX = error code)

 Note: This  function allows for  reading up  to 4  gigabytes at  once (in
 theory, that is.) There is no 64k limitation as in pure DOS.


 Function 40h - Write to file
 ----------------------------

  AH = 40h
  BX = file handle
  ECX = number of bytes to write
  DS:EDX -> data buffer

 Returns

  CF = clear on success (EAX = number of bytes actually written)
  CF = set on error (AX = error code)

 Note: This  function allows for  writing up  to 4  gigabytes at  once (in
 theory, that is.) There is no 64k limitation as in pure DOS.


 Function 41h - Delete file
 --------------------------

  AH = 41h
  DS:EDX -> ASCIZ filename

 Returns

  CF = clear on success, set on error (AX = error code)


 Function 43h - Get/set file attributes
 --------------------------------------

  AH = 43h
  AL = subfunction (0 = get, 1 = set)
  DS:EDX -> ASCIZ filename

  IF AL = 1: CX = file attributes

 Returns

  CF = clear on success, set on error (AX = error code)
  CX = file attributes


 Function 44h - IOCTL
 --------------------

  AH = 44h
  AL = subfunction

 The following subfunctions are extended:

  AL = 2 (read from character device control channel)
  BX = file handle
  ECX = number of bytes to read
  DS:EDX -> buffer

 Returns

  CF = clear on success (EAX = number of bytes actually read)
  CF = set on error (AX = error code)

 Note: This  function allows for  reading up  to 4  gigabytes at  once (in
 theory, that  is.) There  is no  64k limitation  as  in pure  DOS. Before
 calling the actual DOS function, max  (ECX,16k) bytes will be copied from
 DS:EDX into the  real mode transfer  buffer to allow  for passing request
 structures.

  AL = 3 (write to character device control channel)
  BX = file handle
  ECX = number of bytes to write
  DS:EDX -> data buffer

 Returns

  CF = clear on success (EAX = number of bytes actually written)
  CF = set on error (AX = error code)

 Note: This function allows for writing up to 4 gigabytes at once (in
 theory, that is.) There is no 64k limitation as in pure DOS.

  AL = 4 (read from block device control channel)
  BL = drive number (0 = default, 1 = A: etc.)
  ECX = number of bytes to read
  DS:EDX -> buffer

 Returns

  CF = clear on success (EAX = number of bytes actually read)
  CF = set on error (AX = error code)

 Note: This  function allows for reading up  to 4  gigabytes at  once (in
 theory, that  is.) There  is no  64k limitation  as  in pure  DOS. Before
 calling the actual DOS function, max  (ECX,16k) bytes will be copied from
 DS:EDX into the  real mode transfer  buffer to allow  for passing request
 structures.

  AL = 5 (write to block device control channel)
  BL = drive number (0 = default, 1 = A: etc.)
  ECX = number of bytes to write
  DS:EDX -> data buffer

 Returns

  CF = clear on success (EAX = number of bytes actually written)
  CF = set on error (AX = error code)

 Note: This  function allows for  writing up  to 4  gigabytes at  once (in
 theory, that is.) There is no 64k limitation as in pure DOS.


 Function 47h - Get current directory
 ------------------------------------

  AH = 47h
  DL = drive number (0 = default, 1 = A: etc.)
  DS:ESI -> 64 byte buffer to receive ASCIZ pathname

 Returns

  CF = clear on success, set on error (AX = error code)


 Function 48h - Allocate DOS memory block
 ----------------------------------------

  AH = 48h
  BX = number of paragraphs to allocate

 Returns

  CF = clear on success, (AX = selector of allocated block)
  CF = set on error, (AX = error code, bx = size of largest block)


 Function 49h - Free DOS memory block
 ------------------------------------

  AH = 49h
  ES = selector of block to free

 Returns

  CF = clear on success, set on error (AX = error code)


 Function 4Ah - Resize DOS memory block
 --------------------------------------

  AH = 4Ah
  BX = new size in paragraphs
  ES = selector of block to resize

 Returns

  CF = clear on success set on error, (AX = error code, bx = max. size
  available)


 Function 4Bh - Load and execute child program
 ---------------------------------------------

  AH = 4BH
  AL = 0 (other subfunctions NOT supported)
  DS:EDX -> ASCIZ filename of the program to execute
  ES:EBX -> parameter block (see below)

 Returns

  CF clear on success, set on error (AX = error code)

 Note: Unlike  under pure  DOS, under  WDOSX the  format of  the parameter
 block is as follows:

 Offset 00000000: 48 bit protected mode far pointer to environment string
 Offset 00000006: 48 bit protected mode far pointer to command tail

 This is the method most other DOS extenders  also use, so there should be
 no significant compatibility problems.


 Function 4Eh - Find first matching file
 ---------------------------------------

  AH = 4Eh
  AL = flag used by APPEND
  CX = attribute mask
  DS:EDX -> ASCIZ file name (may include path and wildcards)

 Returns

  CF = clear on success (DTA as set with function 1Ah filled)
  CF = set on error (AX = error code)


 Function 4Fh - Find next matching file
 --------------------------------------

  AH = 4Fh
  DTA as set with function 1Ah contains information from previous Find
  First call (function 4Eh)

 Returns

  CF = clear on success (DTA as set with function 1Ah filled)
  CF = set on error (AX = error code)


 Function 56h - Rename file
 --------------------------

  AH = 56h
  DS:EDX -> ASCIZ filename
  ES:EDI -> ASCIZ new filename

 Returns

  CF = clear on success, set on error (AX = error code)


 Function 5Ah - Create temporary file
 ------------------------------------

  AH = 5Ah
  CX = attributes
  DS:EDX -> buffer containing path name ending with "\" + 13 zero bytes

 Returns

  CF = clear on success, filename appended to path name in buffer (AX =
  file handle)
  CF = set on error (AX = error code)


 Function 5Bh - Create new file
 ------------------------------

  AH = 5Bh
  CX = attributes
  DS:EDX -> ASCIZ filename Returns

  CF = clear on success, (AX = file handle)
  CF = set on error (AX = error code)



 4.2 Extended mouse functions (INT 33h)

 WDOSX extends the following INT 33H functions:

 AX = 0009H Define Graphics Cursor
 AX = 000CH Set Custom Event Handler
 AX = 0016H Save Mouse Driver State
 AX = 0017H Restore Mouse Driver State


 Function 0009H Define Graphics Cursor
 -------------------------------------

  AX = 0009H
  ES:EDX -> mouse pointer bitmap
  BX = hot spot column
  CX = hot spot row


 Function 000CH Set Custom Event Handler
 ---------------------------------------

  AX = 000CH
  ES:EDX -> FAR routine
  CX = call mask

 Note: To  uninstall any handler  installed using  this function,  issue a
 mouse driver reset (function 0000h). If  a handler remains in place after
 the application has been terminated, the system might crash.


 Function 0016H Save Mouse Driver State
 --------------------------------------

  AX = 0016H
  ES:EDX -> state save buffer
  BX = size of buffer


 Function 0017H Restore Mouse Driver State
 -----------------------------------------

  AX = 0017H
  ES:EDX -> buffer containing saved state
  BX = size of buffer



 4.3 The WFSE API

 The WDOSX  file  system  extensions use  INT  21h,  function  0FFFDh. The
 subfunction number is passed in  the high word of EAX.  Unless there is a
 value returned in EAX, EAX may be destroyed by these functions. All other
 registers, unless they contain return values, are preserved.


 INT 21 EAX=0000FFFDh - WFSE installation check
 ----------------------------------------------

 In:
  EAX = 0000FFFDh

 Out:
  CF clear if WFSE present
  EAX=57465345h ('WFSE')
  EBX=Version number (currently 1)
  CF set on error


 INT 21 EAX=3D00FFFDh - WFSE open file
 -------------------------------------

 In:
  EAX = 3D00FFFDh
  DS:EDX -> Address of file name (long file names up to 255 characters,
  including the terminating 0, are allowed!)

 Out:
  CF clear on success
  AX = File handle
  Virtual File Pointer set to zero
  CF clear on error
  (no error code returned)

 Note: In any case, the file will be opened "read only" To avoid hate
 emails, the file name handling will be case insensitive.


 INT 21 EAX=3ExxFFFDh - WFSE close file
 --------------------------------------

 In:
  EAX = 3ExxFFFDh
  BX = File handle obtained from function 3D00FFFD

 Out:
  CF clear on success, set on error


 INT 21 EAX=3FxxFFFDh - WFSE read from file
 ------------------------------------------

 In:
  EAX = 3FxxFFFDh
  BX = file handle obtained from function 3D00FFFD
  ECX = bytes to read
  DS:EDX -> address of buffer

 Out:
  CF clear on success
  EAX = bytes actually read
  CF set on error
  (no error code returned)


 INT 21 EAX=420xFFFDh - WFSE lseek
 ---------------------------------

 In:
  EAX = 420xFFFDh
  BX = file handle obtained from function 3D00FFFD
  CX:DX = file pointer
  x = 0: seek from the beginning of the file
  x = 1: seek relative to current file position
  x = 2: seek relative to EOF

 Out:
  CF clear on success
  DX:AX = new file pointer
  CF set on error
  (no error code returned)


 INT 21 EAX=FE00FFFDh - WFSE Alternate File Attach
 -------------------------------------------------

 In:
  EAX = FE00FFFDh
  DS:EDX = Pointer to ASCIZ path and file name of alternate file

 Out:  CF clear on success
  CF set on error
  (no error code returned)

 Note: This  function has been  present since  WDOSX version  0.95, albeit
 undocumented. It provides  a means for  a WDOSX'ed  application to access
 the WFSE file attachments  of another WDOSX'ed  application. The debugger
 that comes with WDOSX, for instance,  makes use of this function. Passing
 a pointer to an empty string will cause WFSE to detach from whatever file
 it currently is attached to, without attaching to another file. Which, in
 the default case, means  that the main program's  EXE file, normally held
 open read-only,  is being closed.  This may  be useful  if a  program for
 whatever reason needs full access to its own EXE file.


 4.4 Other WDOSX functions


 INT 21H / AX = 0FFFFH "Resize Initial Memory Block"
 ---------------------------------------------------

  AX = 0FFFFH
  EDX = new size in bytes

 Returns

  CF = clear on success, memory block size changed and selectors fixed
  CF = set on error

 Note: This  function is  obsolete and  can only  be used  by applications
 running in  a floating segment  such as  "MZ" and  Flat Form  Binary. For
 advanced  executable formats,  DPMI  function  0501h  should  be used  to
 allocate extra memory. If WDOSX is used if  anything but not ASM, use the
 memory allocation  functionality of the  compiler's run  time environment
 e.g. malloc()


 INT 31H / AX = EEFFH "DOS Extender Identification Call"
 --------------------------------------------------------

  AX = EEFFh

 Returns

  CF = clear
  EAX = 'WDSX'
  ES:EBX = far pointer to ASCIZ copyright string
  CH = memory allocation type (0=INT15, 1=XMS, 2=VCPI, 3=DPMI)
  CL = CPU (3=386, 4=486, ... )
  DH = extender major version ( currently 0 )
  DL = extender minor version ( currently 96 decimal )

 Note: This call is also supported by some other DOS extenders so it might
 provide a reasonable  solution for a  program to  identify the underlying
 DOS extender at runtime.



 5. THE END

 Augsburg, 17 June 2003
 Michael Tippach a.k.a. Wuschel
