# WDOSX DOS EXTENDER

This repository contains the source code and binaries of Wuschel's DOS eXtender v0.97 (Final), released in 2005-02, for the purpose of archival and preservation. As of 2022-01, the original host website is still [functional](http://tippach.business.t-online.de/wdosx/).

No changes have been made aside from converting all file and directory names  to lowercase, and the addition of this readme. 

This software is Copyright &copy; 1996-2005, Michael Tippach, with portions Copyright &copy; 1999-2003, Joergen Ibsen.

## Overview

WDosX is a free 32 bit DOS extender. Supported memory allocation schemes are:

* RAW (BIOS INT 0x15)
* XMS
* VCPI
* DPMI

While running under WDosX your program has access to a fair subset of DPMI 0.9 functions as well as an extended DOS INT 21 API. WDosX comes with some libraries, example programs and a full screen debugger. It features a true flat (zero based) memory model and support for DLLs as well as executable compression.

The following programming environments are supported by WDosX 0.97:

| Assembler / Compiler | Supported target executable formats |
| -------------------- | ----------------------------------- |
| NASM | Flat form binary, RDOFF, RDOFF 2 (NEW!) |
| TASM | 32 bit "MZ", PE |
| MASM | 32 bit "MZ", PE |
| MSVC++ 4/5 (NEW! MSVC 6) | Win32 - PE |
| Borland C++ 4.xx/5.xx | Win32 - PE |
| Borland C++ Builder | Win32 - PE |
| Borland Delphi 2, 3 and 4 | Win32 - PE |
| Watcom C++ | Watcom style LE |
| DJGPP v2 | COFF |

Different target executable formats are supported with different feature sets:

| EXE format | DLL Support | True Flat | EXE compression |
| ---------- | :---------: | :-------: | :-------------: |
| Plain Binary | NO | NO | NO |
| 32 bit "MZ" | NO | NO | NO |
| PE | YES | YES[1] | YES |
| LE | NO | YES | YES |
| RDOFF | NO | YES | YES |
| COFF | NO | NO | YES |
| DOS32 | NO | YES[2] | YES |

[1] Floating segment also available but without support for DLLs and compression.

[2] True flat only if relocation info found. There are four different sub formats.

## WDOSX License Agreement

THIS SOFTWARE IS PROVIDED "AS IS". IN NO EVENT SHALL I, THE AUTOR, BE LIABLE
FOR ANY KIND OF LOSS OR DAMAGE ARISING OUT OF THE USE, ABUSE OR THE INABILITY
TO USE THIS SOFTWRAE, NEITHER SHALL CO-AUTHORS AND CONTRIBUTORS. USE IT AT YOUR
OWN RISK!

THIS SOFTWARE COMES WITHOUT ANY KIND OF WARRANTY, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY OR
FITNESS FOR A PARTICULAR PURPOSE.

THIS SOFTWARE IS FREEWARE. NON- EXCLUSIVE PERMISSION TO USE THIS SOFTWARE IN
ITS UNMODIFIED FORM FOR THE SOLE PURPOSE OF BUILDING PROTECTED MODE DOS
APPLICATIONS HEREBY GRANTED.

YOU MAY FURTHER REDISTRIBUTE COPIES OF THIS SOFTWARE PROVIDED YOU INCLUDE ALL
OF THE FILES THAT CAME WITH THE ORIGNAL PACKAGE. YOU ARE NOT ALLOWED TO
REDISTRIBUTE MODIFIED COPIES OF THE SOFTWARE OR MERE PARTS OF IT.

YOU MAY FURTHER SELL APPLICATIONS USING A DOS EXTENDER STUB FROM THIS PACKAGE,
BUT YOU ARE NOT ALLOWED TO SELL THIS SOFTWARE AS A STAND ALONE PRODUCT OR AS
PART OF A SOFTWARE COMPILATION, EXCEPT FOR A SMALL, USUAL FEE COVERING THE
REDISTRIBUTION ITSELF.

THE SOURCE CODE CONTAINED IN THIS PACKAGE MAY BE MODIFIED FOR YOUR OWN USE.
HOWEVER, MODIFIED VERSIONS OF THE SOURCE CODE OR BINARIES COMPILED FROM
MODIFIED VERSIONS OF THE SOURCE CODE MUST NOT BE REDISTRIBUTED WITHOUT PRIOR
PERMISSION, WITH ONE EXCEPTION: YOU MAY REDISTRIBUTE BINARIES OBTAINED FROM
MODIFIED VERSIONS OF THE SOURCE CODE AS PART OF AN APPLICATION THAT USES WDOSX
AS ITS DOS EXTENDER IF MODIFICATIONS WERE NECESSARY TO FIX BUGS OR ADD MISSING
FUNCTIONALITY FOR THE NEEDS OF YOUR PARTICULAR APPLICATION.

EITHER WAY, THE PREFERRED APPROACH IS THAT YOU CONTACT THE AUTHOR (ME) IF YOU
FEEL THE CHANGES YOU MADE TO THE SOURCE CODE SHOULD BE INCORPORATED INTO
FUTURE VERSIONS.

IF YOU DON'T AGREE WITH THIS TERMS OR IF YOUR JURISTDICTION DOES NOT ALLOW THE
EXCLUSION OF WARRANTY AND LIABILITY AS STATED ABOVE YOU ARE NOT ALLOWED TO USE
THIS SOFTWARE AT ALL.

THIS SOFTWARE IS COPYRIGHT (C)1996-2005 MICHAEL TIPPACH, ALL RIGHTS RESERVED.

ENGLISH: IF YOU MAKE ME WISH I NEVER HAD RELEASED IT, YOU SHOULD ROT IN HELL!


Author contact:

Michael Tippach
Alpenrosenstrasse 25
86179 Augsburg
Germany
e-mail: mtippach@gmx.net
