; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/deb/MAIN.ASM 1.3 1999/02/13 13:40:26 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: MAIN.ASM $
; Revision 1.3  1999/02/13 13:40:26  MikeT
; Move WUDEBUG to true flat. This is in anticipation of getting rid of
; the STUBIT -m_loat option and the obsolete PESTUB.EXE thing.
; Usage of INT 21 function FFFF for getting space for the debuggee's
; Environment block has been changed into static BSS allocation of a 32k
; memory block.
;
; Revision 1.2  1999/02/07 20:11:50  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:14:04  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ##          This file is part of the Wudebug 0.1 aplha sourcecode         ##
; ##                 Copyright (C) 1997, Michael Tipppach                   ##
; ############################################################################

; Some improvements done by Mark Junker:
;
; - Parameter passing to DisAsm() fixed so it would work with the NDISASM
;   sources compiled with another compiler than Borland C/C++
; - Display of "db xx" instead of "???" for code that would not disassemble
;   to anything valid

DOWRD           equ     DWORD   ; anyone else the same typing habit?

DisAsmX         equ     0
DisAsmY         equ     0
DisAsmDx        equ     64
DisAsmDy        equ     14

RegisterX       equ     64
RegisterY       equ     0
RegisterDx      equ     80-RegisterX
RegisterDy      equ     14

; include segment definitions and externals

include debug.inc
include keys.inc

; structure definition for numeric fields


.code

NumField        struc
                LocX            dd      ?
                LocY            dd      ?
                Color           dd      ?
                FieldName       dd      ?
                Value           dd      ?
                DepValue        dd      ?
                UpdateProc      dd      ?
                OnEnterProc     dd      ?
NumField        ends


include ifield.inc
include update.inc
include regwin.inc
include flags.inc
include memwin.inc
include stackwin.inc
include inbox.inc
include help.inc

start:

                ; early out

                cmp     esi,2
                jnc     HaveParam
                mov     edx,offset MsgInit
                mov     ah,9
                int     21h
                mov     edx,offset MsgUsage
                mov     ah,9
                int     21h
                mov     eax,4cffh
                int     21h
HaveParam:

                ; save "main" command line args

                mov     argc,esi
                mov     argv,edi
                mov     environ,ebp
                mov     eax,ebp
                mov     eax,[eax]
                mov     EnvBlock,eax

                ; save psp selector

                mov     eax,es:[2ch]
                mov     EnvSel,eax
                mov     PspSel,es
                push    ds
                pop     es

                ; print init msg

                mov     edx,offset MsgInit
                mov     ah,9
                int     21h

                ; scan environment for space needed

                sub     eax,eax
                mov     ecx,-1
                mov     edi,environ
                cld
                repne   scasd
                cmp     ecx,-2
                mov     ecx,0
                jz      NoEnvString
                push    dword ptr [edi-8]
                call    GetStrSize
                pop     ecx
                add     ecx,eax

                sub     ecx,EnvBlock
NoEnvString:
;
; copy environment
;
                mov     edi,OFFSET StartOfHeap
                mov     esi,EnvBlock

                rep     movs byte ptr es:[edi],ds:[esi]
                mov     eax,010000h
                stosd
                mov     PrgFilename,edi

                ; get fake evironment selector

                mov     es,PspSel

                sub     eax,eax
                mov     ecx,1
                int     31h
                jc      InitFail

                ; store fake environment selector

                mov     es:[2ch],ax

                ; set its base address

                mov     edx,OFFSET StartOfHeap
                shld    ecx,edx,16
                mov     ebx,eax
                mov     eax,7
                int     31h
                jc      InitFail

                ; set its limit

                mov     edx,PrgFilename
                add     edx,260
                sub     edx, OFFSET StartOfHeap
                shld    ecx,edx,16
                mov     eax,8
                int     31h
                jc      InitFail

                ; remove the first parameter from command tail in psp

                ; build command tail starting from argv[2] ...

                mov     ebp,argc
                mov     byte ptr es:[80h],0
                mov     edi,82h

                ; must have at least 3 to do any copy

                sub     ebp,2
                jna     NoPrg

                mov     ebx,argv
                mov     eax,1
ArgsLoop:
                inc     eax
                mov     esi,[eax*4+ebx]
                mov     byte ptr es:[edi-1],' '
CopyArgs:
                mov     dl,[esi]
                inc     esi
                mov     es:[edi],dl
                inc     edi
                test    dl,dl
                jnz     CopyArgs
                dec     ebp
                jnz     ArgsLoop

                lea     eax,[edi-82h]

                mov     es:[80h],al

NoPrg:
                push    ds
                pop     es

                call    Initialize
                test    eax,eax
                jz      initOk
InitFail:
                mov     edx,offset MsgInitFail
                mov     ah,9
                int     21h
DebExit:
                mov     es,PspSel
                mov     eax,EnvSel
                mov     es:[2ch],ax
                mov     eax,4cffh
                int     21h

                ; this is a hack allowing the program to be reloaded

DebReload:
                mov     eax,3
                int     10h
                mov     es,PspSel
                mov     eax,EnvSel
                mov     es:[2ch],ax
                mov     eax,4cf2h
                int     21h

initOk:
                mov     eax,PspSel
                mov     Des,eax

                call    SetDebScreen

                ; Try to load the program

                cmp     argc,2
                jc      NoArgument

                mov     eax,argv
                mov     eax,[eax+4]

                push    eax
;
; Try to init user WFSE
;
		mov	edx, eax
		mov	eax, 0FE00FFFDh
		int	21h

                call    LoadAProgram
                add     esp,4

                test    eax,eax
                jz      LoadSuccess
                call    SetUserScreen
                mov     edx,offset MsgLoadFail
                mov     ah,9
                int     21h
                jmp     DebExit

LoadSuccess:

                ; Program loaded now, initialize UI

                mov     ActiveWindow,AwDaWindow

                mov     eax,Deip
                mov     DaOrigin,eax
                mov     DaCurAdd,eax
                mov     DaCurLin,0
                push    0
                push    Dds
                call    GetLinear
                add     esp,8
                mov     MemOriginLin,eax
                call    RegSaveState
                call    FlagsSaveState
                call    DaUpdateView
                call    UpdateAll
                call    MainLoop

; This is all: 2do 2do 2do 2do...!!!!!

NoArgument:
AppExit:
                mov     eax,3
                int     10h
                jmp     DebExit



MainLoop        proc
@@infinite:
                sub     eax,eax
                int     16h

                ; process key handler tables

                ; check desktop first

                mov     edx,offset KtDesktop-8
@@mlDtLoop:
                add     edx,8
                cmp     dword ptr [edx],0
                jz      @@mlDtNope
                cmp     eax,[edx]
                jnz     @@mlDtLoop
                push    eax
                call    dword ptr [edx+4]
                add     esp,4
                jmp     @@infinite
@@mlDtNope:

                ; find active window

                cmp     ActiveWindow,AwDaWindow
                jnz     @@mlDt01
                mov     edx,offset KtDisAsm-8
@@mlDaLoop:
                add     edx,8
                cmp     dword ptr [edx],0
                jz      @@infinite
                cmp     eax,[edx]
                jnz     @@mlDaLoop
                push    eax
                call    dword ptr [edx+4]
                add     esp,4
                jmp     @@infinite

@@mlDt01:
                cmp     ActiveWindow,AwRegWindow
                jnz     @@mlDt02
                mov     edx,offset KtRegisters-8
@@mlRegLoop:
                add     edx,8
                cmp     dword ptr [edx],0
                jz      @@infinite
                cmp     eax,[edx]
                jnz     @@mlRegLoop
                push    eax
                call    dword ptr [edx+4]
                add     esp,4
                jmp     @@infinite

@@mlDt02:

                cmp     ActiveWindow,AwFlagWindow
                jnz     @@mlDt03
                mov     edx,offset KtFlags-8
@@mlFlagLoop:
                add     edx,8
                cmp     dword ptr [edx],0
                jz      @@infinite
                cmp     eax,[edx]
                jnz     @@mlFlagLoop
                push    eax
                call    dword ptr [edx+4]
                add     esp,4
                jmp     @@infinite

@@mlDt03:
                cmp     ActiveWindow,AwMemWindow
                jnz     @@mlDt04
                mov     edx,offset KtMem-8
@@mlMemLoop:
                add     edx,8
                cmp     dword ptr [edx],0
                jz      @@infinite
                cmp     eax,[edx]
                jnz     @@mlMemLoop
                push    eax
                call    dword ptr [edx+4]
                add     esp,4
                jmp     @@infinite

@@mlDt04:

                cmp     ActiveWindow,AwStackWindow
                jnz     @@mlDt05
                mov     edx,offset KtStack-8
@@mlStackLoop:
                add     edx,8
                cmp     dword ptr [edx],0
                jz      @@infinite
                cmp     eax,[edx]
                jnz     @@mlStackLoop
                push    eax
                call    dword ptr [edx+4]
                add     esp,4
                jmp     @@infinite

@@mlDt05:

                ; 2do

                jmp     @@infinite

MainLoop        endp

DtOnTab         proc
                cmp     ActiveWindow,AwDaWindow
                jnz     @@ontab00
                mov     ActiveWindow,AwRegWindow
                jmp     @@ontabDone
@@ontab00:
                cmp     ActiveWindow,AwRegWindow
                jnz     @@ontab01
                mov     ActiveWindow,AwFlagWindow
                jmp     @@ontabDone
@@ontab01:
                cmp     ActiveWindow,AwFlagWindow
                jnz     @@ontab02
                mov     ActiveWindow,AwStackWindow
                jmp     @@ontabDone
@@ontab02:
                cmp     ActiveWindow,AwStackWindow
                jnz     @@ontab03
                mov     ActiveWindow,AwMemWindow
                jmp     @@ontabDone
@@ontab03:
                cmp     ActiveWindow,AwMemWindow
                jnz     @@ontab04
                mov     ActiveWindow,AwDaWindow
                jmp     @@ontabDone
@@ontab04:

@@ontabDone:
                call    DaUpdateView
                call    UpdateAll
                ret
DtOnTab         endp


DtOnShiftTab    proc
                cmp     ActiveWindow,AwDaWindow
                jnz     @@onstab00
                mov     ActiveWindow,AwMemWindow
                jmp     @@onstabDone
@@onstab00:
                cmp     ActiveWindow,AwRegWindow
                jnz     @@onstab01
                mov     ActiveWindow,AwDaWindow
                jmp     @@onstabDone
@@onstab01:
                cmp     ActiveWindow,AwFlagWindow
                jnz     @@onstab02
                mov     ActiveWindow,AwRegWindow
                jmp     @@onstabDone
@@onstab02:

                cmp     ActiveWindow,AwMemWindow
                jnz     @@onstab03
                mov     ActiveWindow,AwStackWindow
                jmp     @@onstabDone
@@onstab03:
                cmp     ActiveWindow,AwStackWindow
                jnz     @@onstab04
                mov     ActiveWindow,AwFlagWindow
                jmp     @@onstabDone
@@onstab04:

@@onstabDone:
                call    DaUpdateView
                call    UpdateAll
                ret
DtOnShiftTab    endp


DaExecute       proc

                mov     eax,[esp+4]

                cmp     eax,Key_F9
                jnz     @@dax01
                call    RegSaveState
                call    FlagsSaveState
                call    DoRun
                jmp     @@dax00
@@dax01:
                cmp     eax,Key_F8
                jnz     @@dax02
                call    RegSaveState
                call    FlagsSaveState
                call    DoStep
                jmp     @@dax00
@@dax02:
                cmp     eax,Key_F7
                jnz     @@dax03
                call    RegSaveState
                call    FlagsSaveState
                call    DoTrace
                jmp     @@dax00
@@dax03:
                cmp     eax,Key_F4
                jnz     @@daxDone
                call    RegSaveState
                call    FlagsSaveState
                call    DoHere
@@dax00:
                test    eax,eax
                jns     @@daxGoOn
                call    UpdateAll
                push    offset MsgTerminated
                call    GetStrSize
                push    3
                add     eax,2
                push    eax
                call    MsgBox
                add     esp,12
                ret
@@daxGoOn:
                push    eax
                call    UpdateAll
                pop     eax
                cmp     al,1
                jz      @@daxDone
                cmp     al,3
                jz      @@daxDone
                and     eax,0fh
                push    eax
                call    GetExceptionName
                add     esp,4
                push    eax
                call    GetStrSize
                push    3
                add     eax,2
                push    eax
                call    MsgBox
                add     esp,12
@@daxDone:
                ret
DaExecute       endp

;------------------------------------------------------------------------------
;               key procedures
;------------------------------------------------------------------------------

DoNothing       proc
                sub     eax,eax
                ret
DoNothing       endp

UpdateAll       proc
;               call    DaUpdateView
                call    RegUpdateView
                call    FlagsUpdateView
                call    StackUpdateView
                call    MemUpdateView
                ret
UpdateAll       endp

DaUpdateView    proc
                push    DaOrigin
                call    DisAsmScreen
                add     esp,4
                ret
DaUpdateView    endp

RegUpdateView   proc
                call    IsDebugVideo
                test    eax,eax
                jz      @@skip002
                call    ShowRegisters
@@skip002:
                ret
RegUpdateView   endp

DaAdjustCursor  proc
; DaUpdateView must have been called before!
                mov     eax,DaEipLin
                inc     eax
                lea     eax,[eax-1]
                mov     DaCurLin,eax
                jnz     @@dac00

                mov     eax,Deip
                mov     DaCurLin,0
                mov     DaOrigin,eax
                mov     DaEipLin,0
@@dac00:
                call    DaUpdateView
                sub     eax,eax
                ret
DaAdjustCursor  endp

DoToggleScreen  proc
                call    SetUserScreen
                sub     eax,eax
                int     16h
                call    SetDebScreen
                call    DaUpdateView
                call    UpdateAll
                sub     eax,eax
                ret
DoToggleScreen  endp


DoRun           proc
                call    SetUserScreen
                ; check whether breakpoint set
                push    Deip
                push    Dcs
                call    GetBreakpoint
                add     esp,8
                test    eax,eax
                jz      @@dr01
                push    eax
                push    Deip
                push    Dcs
                call    KillBreakpoint
                push    1
                call    DoStep0
                add     esp,4
                mov     [esp+8],eax
                call    SetBreakpoint
                add     esp,8
                pop     eax

                cmp     al,1
                jz      @@dr01
                cmp     al,3
                jnz     @@dr02
@@dr01:
                call    Run
@@dr02:
                push    eax
                call    SetDebScreen
                call    DaUpdateView
                call    DaAdjustCursor
                pop     eax
                ret
DoRun           endp

DaCursorUp      proc
                cmp     DaCurLin,0
                jnz     @@dacu00
                push    1
                push    DaOrigin
                call    GetDaStart
                add     esp,8
                mov     DaOrigin,eax
                jmp     @@dacu01
@@dacu00:
                dec     DaCurLin
@@dacu01:
                call    DaUpdateView
@@skip003:
                sub     eax,eax
                ret
DaCursorUp      endp

DaCursorDown    proc
                mov     eax,DaCurLin
                inc     eax
                cmp     eax,DisAsmDy
                jc      @@dacd00
                push    DaOrigin
                call    GetIncrement
                add     esp,4
                cmp     eax,1
                adc     DaOrigin,eax
                jmp     @@dacd01
@@dacd00:
                inc     DaCurLin
@@dacd01:
                call    DaUpdateView
                sub     eax,eax
                ret
DaCursorDown    endp

DaPageUp        proc
                mov     eax,DisAsmDy
;               dec     eax
                push    eax
                push    DaOrigin
                call    GetDaStart
                add     esp,8
                mov     DaOrigin,eax
                call    DaUpdateView
                sub     eax,eax
                ret
DaPageUp        endp

DaPageDown      proc
                mov     eax,DaNextPage
                mov     DaOrigin,eax
                call    DaUpdateView
                sub     eax,eax
                ret
DaPageDown      endp

DaOnGoto        proc    near
                push    offset MsgGoto
                push    10
                call    InputBox8
                pop     edx
                pop     edx
                jc      @@dog00
                mov     DaOrigin,eax
                mov     DaCurLin,0
                call    DaUpdateView
@@dog00:
                ret
DaOnGoto        endp


DaGotoOrigin    proc
                call    DaAdjustCursor
                sub     eax,eax
                ret
DaGotoOrigin    endp


DaGotoAddress   proc
                call    DaUpdateView
                sub     eax,eax
                ret
DaGotoAddress   endp

DaToggleBp      proc
                push    DaCurAdd
                push    Dcs
                call    GetBreakpoint
                test    eax,eax
                jnz     @@dtbp00
                call    SetBreakpoint
                jmp     @@dtbp01
@@dtbp00:
                call    KillBreakpoint
@@dtbp01:
                add     esp,8
                call    DaUpdateView
                sub     eax,eax
                ret
DaToggleBp      endp

DaNewEip        proc
                mov     eax,DaCurAdd
                mov     Deip,eax
                call    DaUpdateView
                sub     eax,eax
                ret
DaNewEip        endp

DoHere          proc
                call    SetUserScreen
                push    eax     ; placeholder
                ; check whether breakpoint set
                push    Deip
                push    Dcs
                call    GetBreakpoint
                add     esp,8
                test    eax,eax
                mov     al,1
                jz      @@dh01
                push    Deip
                push    Dcs
                call    KillBreakpoint
                push    1
                call    DoStep0
                add     esp,4
                mov     [esp+8],eax
                call    SetBreakpoint
                add     esp,8
                mov     eax,[esp]
                cmp     al,1
                jz      @@dh01
                cmp     al,3
                jnz     @@dh04
@@dh01:
                push    DaCurAdd
                mov     eax,DaCurLin
                cmp     eax,DaEipLin
                mov     al,1
                jnz     @@dh00
                call    SingleStep
@@dh00:
                push    Dcs
                mov     [esp+8],eax
                cmp     al,1
                jz      @@dh03
                cmp     al,3
                jnz     @@dh02
@@dh03:
                call    Here
                mov     [esp+8],eax
@@dh02:
                add     esp,8
@@dh04:
                call    SetDebScreen
                call    DaUpdateView
                call    DaAdjustCursor
                pop     eax
                ret
DoHere          endp

; -----------------------------------------------------------------------------

LoadAProgram    proc
;int LoadAProgram (char *FileName)

                push    ebx
                push    esi
                push    edi

                mov     eax,[esp+16]

                push    eax
                mov     edi,PrgFilename

                ; check whether drive specified

                cmp     byte ptr [eax+1],':'
                jnz     DriveNo

                mov     dx,[eax]
                add     eax,2
                mov     [edi],dx
                add     edi,2
                jmp     DriveDone

DriveNo:
                push    eax
                mov     ah,19h
                int     21h
                mov     dl,al
                add     al,'A'
                mov     dl,al
                pop     eax
                mov     dh,':'
                mov     [edi],dx
                add     edi,2
DriveDone:

                ; Check if absolute path specified

                cmp     byte ptr [eax],'\'
                jz      PathDone

                mov     byte ptr [edi],'\'
                inc     edi
                mov     esi,edi
                mov     dl,[edi-3]
                or      dl,20h
                sub     dl,('a'- 1)
                push    eax
                mov     ah,47h
                int     21h
                pop     eax

ScanPath:
                cmp     byte ptr [edi],0
                lea     edi,[edi+1]
                jnz     ScanPath
                dec     edi
                cmp     byte ptr [edi],'\'
                jz      PathDone
                cmp     byte ptr [edi-1],'\'
                jz      PathDone
                mov     byte ptr [edi],'\'
                inc     edi

PathDone:
                mov     dl,[eax]
                mov     [edi],dl
                inc     eax
                inc     edi
                test    dl,dl
                jnz     PathDone

                call    LoadProgram
                add     esp,4
                pop     edi
                pop     esi
                pop     ebx
                ret
LoadAProgram    endp

GetStrSize      proc
                mov     eax,[esp+4]
@@gssloop:
                cmp     byte ptr [eax],0
                jz      @@gss00
                inc     eax
                jmp     @@gssloop
@@gss00:
                sub     eax,[esp+4]
                ret
GetStrSize      endp

;-----------------------------------------------------------------------------

; if there is a breakpoint at current CS:EIP we have to temporary remove it

DoStep          proc    near
                push    eax
                push    Deip
                push    Dcs
                call    GetBreakpoint
                test    eax,eax
                jz      @@dsnormal
                call    KillBreakpoint
                push    0
                call    DoStep0
                add     esp,4
                mov     [esp+8],eax
                call    SetBreakpoint
                add     esp,8
                call    DaUpdateView
                call    DaAdjustCursor
                pop     eax
                ret
@@dsnormal:
                add     esp,12
                push    0
                call    DoStep0
                add     esp,4
                push    eax
                call    DaUpdateView
                call    DaAdjustCursor
                pop     eax
                ret
DoStep          endp

DoStep0         proc    near
                push    Deip
                call    GetIncrement
                add     esp,4
                test    eax,eax
                jz      @@DsTrace
                add     eax,Deip
                push    eax
                push    offset DummyBuffer
                push    offset JString
                call    FindString
                add     esp,4
                test    eax,eax
                jnz     @@DsIsBranch
                push    offset RString
                call    FindString
                add     esp,4
                test    eax,eax
                jnz     @@DsIsBranch
                push    offset IString
                call    FindString
                add     esp,4
                test    eax,eax
                jnz     @@DsIsBranch
                add     esp,4
                cmp     dword ptr [esp+8],0
                jnz     @@DsNoScr00
                call    SetUserScreen
@@DsNoScr00:
                push    Dcs
                call    Here
                add     esp,8
                push    eax
                cmp     dword ptr [esp+8],0
                jnz     @@DsNoScr01
                call    SetDebScreen
@@DsNoScr01:
                pop     eax
                ret
@@DsIsBranch:
                add     esp,8
@@DsTrace:
                call    SingleStep
                ret
DoStep0         endp


DoTrace         proc    near
                push    eax
                push    Deip
                push    Dcs
                call    GetBreakpoint
                test    eax,eax
                jz      @@dtnormal
                call    KillBreakpoint
                call    DoTrace0
                mov     [esp+8],eax
                call    SetBreakpoint
                add     esp,8
                call    DaUpdateView
                call    DaAdjustCursor
                pop     eax
                ret
@@dtnormal:
                add     esp,12
                call    DoTrace0
                push    eax
                call    DaUpdateView
                call    DaAdjustCursor
                pop     eax
                ret
DoTrace         endp


DoTrace0        proc    near

                push    Deip
                call    GetIncrement
                add     esp,4
                test    eax,eax
                jz      @@DtTrace
                add     eax,Deip
                push    eax
                push    offset DummyBuffer
                push    offset IntString
                call    FindString
                add     esp,8
                test    eax,eax
                jz      @@DtNoBranch
                call    SetUserScreen
                push    Dcs
                call    Here
                add     esp,8
                push    eax
                call    SetDebScreen
                pop     eax
                ret
@@DtNoBranch:
                add     esp,4
@@DtTrace:
                call    SingleStep
                ret
DoTrace0        endp


DisAsmScreen    proc    near
; void _cdecl DisAsmScreen(unsigned long Eip)

GetDBValue macro
                ; very shitty and specialised macro :]
                push ebx
                add eax,3
                mov dword ptr [eax],'00x0'
                add eax,2
                mov dl,[edx]
                movzx ebx,dl
                shr ebx,4
                mov bl,[ebx+offset HexChars]
                mov [eax],bl
                inc eax
                mov bl,dl
                and bl,0Fh
                mov bl,[ebx+offset HexChars]
                mov [eax],bl
                inc eax
                pop ebx
endm

                ; invalidate Eip line

                mov     DaEipLin,-1

                ; clear the offscreen buffer

                push    7
                cmp     ActiveWindow,AwDaWindow
                jnz     @@colorset
                mov     byte ptr [esp],30h
@@colorset:
                push    DisAsmDy
                push    DisAsmDx
                push    DisAsmY
                push    DisAsmX
                call    FillColor
                mov     byte ptr [esp+16],0
                call    FillChar

                ; initialize line counter

                push    DisAsmDy

                ; get properties of current cs

                ; get linear address

                push    Dcs
                call    GetLinear
                add     eax,[esp+32]    ; Get linear start
                mov     [esp],eax       ; on stack

                push    0               ; sync stuff for disasm
                push    dword ptr [esp+36]

                lar     eax,Dcs
                test    eax,400000h     ; check for D bit
                mov     eax,16
                jz      @@dadef
                add     eax,eax         ; default is use32 if set
@@dadef:
                push    eax
                push    (DisAsmX * DisAsmY) + offset ScreenChars + 10

                push    offset DaBuffer ; temp buffer


@@daLoop:
                ; display the offset

                mov     eax,[esp+12]
                mov     ecx,8
                mov     edx,[esp+4]
@@doloop:
                rol     eax,4
                push    eax
                and     al,0fh
                add     al,30h
                cmp     al,3ah
                sbb     ah,ah
                not     ah
                and     ah,7
                add     al,ah
                mov     [edx-10],al
                inc     edx
                pop     eax
                loop    @@doloop

                ; check if either BP or eip here
                push    dword ptr [esp+12]
                push    Dcs
                call    GetBreakpoint
                add     esp,8
                test    eax,eax
                jz      @@datesteip

                mov     edx,[esp+4]
                mov     ecx,DisAsmDx
@@Bpcolor:
                mov     byte ptr [edx+(offset ScreenColors-offset ScreenChars)-10],4fh
                inc     edx
                loop    @@Bpcolor
@@datesteip:

                mov     eax,DisAsmDy
                sub     eax,[esp+24]
                cmp     eax,DaCurLin
                jnz     @@daarrow

                mov     eax,[esp+12]
                mov     DaCurAdd,eax

                cmp     ActiveWindow,AwDaWindow
                jnz     @@daarrow

                mov     ecx,DisAsmDx
                mov     edx,[esp+4]
@@Eipcolor:
                mov     byte ptr [edx+(offset ScreenColors-offset ScreenChars)-10],1fh
                inc     edx
                loop    @@Eipcolor

@@daarrow:
                mov     eax,Deip
                cmp     eax,[esp+12]
                jnz     @@daeipdone
                mov     edx,[esp+4]
                mov     word ptr [edx-2],'>-'
                mov     eax,DisAsmDy
                sub     eax,[esp+24]
                mov     DaEipLin,eax
@@daeipdone:

                ; fill the temp buffer

                mov     ecx,16          ; readbyte does not modify ecx
                mov     edx,dword ptr [esp+20]
                push    ebx
                mov     ebx,offset DaBuffer
@@darbloop:
                push    edx
                call    ReadByte
                pop     edx
                test    eax,eax
                jns     @@havebyte
                pop     ebx
                jmp     @@invopc
@@havebyte:
                mov     [ebx],al
                inc     ebx
                inc     edx
                loop    @@darbloop
                pop     ebx

                push dword ptr [esp+4*4]
                push dword ptr [esp+4*4]
                push dword ptr [esp+4*4]
                push dword ptr [esp+4*4]
                push dword ptr [esp+4*4]
                call    disasm
                add esp,4*5

                ; eax = current instruction length

                test    eax,eax
                ja      @@DaValid       ; > 0

                mov     eax,[esp+4]
                mov     dword ptr [eax],'  bd'
                mov     edx,[esp]

                GetDBValue
                mov eax,1
                jmp @@DaValid

@@invopc:
                ; invalid opcode, increment eip, write ??? adjust screen
                ; next run

                mov     eax,[esp+4]
                mov     dword ptr [eax],'??? '
                mov     eax,1                   ; instruction length=1 if error

@@DaValid:
                ; Deip is a sync point, check for this...

                mov     edx,Deip
                cmp     edx,[esp+12]
                jng     @@danosync
                sub     edx,eax
                cmp     edx,[esp+12]
                jnl     @@danosync

                ; act as it was an invalid instruction

                mov     eax,[esp+4]
                mov     dword ptr [eax],'  bd'
                mov     edx,[esp]
                GetDBValue

                mov     ecx,DisAsmDx
                sub     ecx,13
@@zaploop:
                mov     byte ptr [eax],0
                inc     eax
                loop    @@zaploop

                mov     eax,1                   ; instruction length=1 if error

@@danosync:
;                push eax
;                mov eax,[esp+8]
;                add eax,30
;                mov edx,esp
;                GetDBValue
;                pop eax

                add     [esp+20],eax
                add     [esp+12],eax

                mov     eax,ScreenX
                add     [esp+4],eax

                dec     dword ptr [esp+24]
                jnz     @@daLoop

                mov     eax,[esp+12]
                mov     DaNextPage,eax

                add     esp,28

                call    SetRectangle

                add     esp,20
                ret

DisAsmScreen    endp


GetIncrement    proc    near
; abuse the disasm routine to get the instruction increment from a given loc
; int _cdecl GetIncrement(unsigned long eip)

                mov     byte ptr [offset DummyBuffer],' '
                push    ebx
                mov     ebx,Dcs
                mov     eax,6
                int     31h
                jc      @@gierr
                shl     edx,16
                shrd    edx,ecx,16
                add     edx,[esp+8]
                mov     ecx,16
                mov     ebx,offset DaBuffer
@@giloop:
                push    edx
                call    ReadByte
                pop     edx
                test    eax,eax
                js      @@gierr
                mov     [ebx],al
                inc     edx
                inc     ebx
                loop    @@giloop

                push    0
                push    dword ptr [esp+12]
                mov     eax,Dcs
                lar     eax,eax
                test    eax,400000h
                mov     eax,16
                jz      @@gino32
                add     eax,eax
@@gino32:
                push    eax
                push    offset DummyBuffer+1
                push    offset DaBuffer
                call    disasm
                add     esp,20
                pop     ebx
                ret
@@gierr:
                sub     eax,eax
                pop     ebx
                ret
GetIncrement    endp

GetRectangle    proc    near
; void _cdecl GetRectangle(int x, int y, int dx, int dy)

                mov     edx,[esp+8]
                imul    edx,ScreenX
                add     edx,[esp+4]
                mov     ecx,[esp+16]
@@getR00:
                push    ecx
                mov     ecx,[esp+16]
@@getR01:
                mov     ax,gs:[edx*2+0b8000h]
                mov     [edx+offset ScreenChars],al
                mov     [edx+offset ScreenColors],ah
                inc     edx
                loop    @@getR01
                add     edx,ScreenX
                sub     edx,[esp+16]
                pop     ecx
                loop    @@getR00
                ret
GetRectangle    endp


SetRectangle    proc    near
; void _cdecl SetRectangle(int x, int y, int dx, int dy)

                mov     edx,[esp+8]
                imul    edx,ScreenX
                add     edx,[esp+4]
                mov     ecx,[esp+16]
@@setR00:
                push    ecx
                mov     ecx,[esp+16]
@@setR01:
                mov     al,[edx+offset ScreenChars]
                mov     ah,[edx+offset ScreenColors]
                mov     gs:[edx*2+0b8000h],ax
                inc     edx
                loop    @@setR01
                add     edx,ScreenX
                sub     edx,[esp+16]
                pop     ecx
                loop    @@setR00
                ret
SetRectangle    endp

FillColor       proc    near
; void _cdecl FillColor(int x, int y, int dx, int dy, int color)

                mov     eax,[esp+20]
                mov     edx,[esp+8]
                imul    edx,ScreenX
                add     edx,[esp+4]
                mov     ecx,[esp+16]
@@fillC00:
                push    ecx
                mov     ecx,[esp+16]
@@fillC01:
                mov     [edx+offset ScreenColors],al
                inc     edx
                loop    @@fillC01
                add     edx,ScreenX
                sub     edx,[esp+16]
                pop     ecx
                loop    @@fillC00
                ret
FillColor       endp


FillChar        proc    near
; void _cdecl FillChar(int x, int y, int dx, int dy, int chr)

                mov     eax,[esp+20]
                mov     edx,[esp+8]
                imul    edx,ScreenX
                add     edx,[esp+4]
                mov     ecx,[esp+16]
@@fillb00:
                push    ecx
                mov     ecx,[esp+16]
@@fillb01:
                mov     [edx+offset ScreenChars],al
                inc     edx
                loop    @@fillb01
                add     edx,ScreenX
                sub     edx,[esp+16]
                pop     ecx
                loop    @@fillb00
                ret
FillChar        endp


FillString      proc    near
; void _cdecl FillString(int x, int y, char *string)

                mov     edx,[esp+8]
                imul    edx,ScreenX
                add     edx,[esp+4]
                mov     ecx,[esp+12]
@@fs00:
                mov     al,[ecx]
                inc     ecx
                test    al,al
                jz      @@fs01
                mov     [edx+offset ScreenChars],al
                inc     edx
                jmp     @@fs00
@@fs01:
                ret
FillString      endp

SwapRectangle   proc    near
; void _cdecl SwapRectangle(int x, int y, int dx, int dy)

                mov     edx,[esp+8]
                imul    edx,ScreenX
                add     edx,[esp+4]
                mov     ecx,[esp+16]
@@swapR00:
                push    ecx
                mov     ecx,[esp+16]
@@swapR01:
                mov     al,[edx+offset ScreenChars]
                mov     ah,[edx+offset ScreenColors]
                shl     eax,16
                mov     ax,gs:[edx*2+0b8000h]
                ror     eax,16
                mov     gs:[edx*2+0b8000h],ax
                shr     eax,16
                mov     [edx+offset ScreenChars],al
                mov     [edx+offset ScreenColors],ah
                inc     edx
                loop    @@swapR01
                add     edx,ScreenX
                sub     edx,[esp+16]
                pop     ecx
                loop    @@swapR00
                ret
SwapRectangle   endp

MsgBox          proc    near

MbColor         equ     4fh     ; test

; void _cdecl MsgBox(int dx, int dy, char *str1,...)
; dy MUST be the number of strings + 2

                ; get coordinates to draw (dy = numStrings + 2)
                ; x = (ScreenX - dx) / 2
                ; y = (ScreenY - dy) / 2

                mov     edx,[esp+8]     ; dy
                mov     eax,[esp+4]     ; dx
                push    MbColor
                push    edx
                push    eax
                neg     edx
                neg     eax
                add     edx,ScreenY
                add     eax,ScreenX
                shr     edx,1
                shr     eax,1
                push    edx
                push    eax
                call    FillColor
                mov     dword ptr [esp+16],0
                call    FillChar

                ; leave the stuff on stack

                mov     eax,[esp]       ; x
                mov     edx,[esp+4]     ; y
                mov     ecx,[esp+12]    ; dy
                inc     eax             ; x of first string
                inc     edx             ; y of first string
                sub     ecx,2           ; loopcounter
                push    ecx
                lea     ecx,[esp+36]
                push    ecx
                sub     esp,4
                push    edx             ; y
                push    eax             ; x
@@mbprint:
                mov     eax,[esp+12]
                mov     eax,[eax]
                mov     [esp+8],eax
                call    FillString
                inc     dword ptr [esp+4]
                add     dword ptr [esp+12],4
                dec     dword ptr [esp+16]
                jnz     @@mbprint
@@mb00:
                add     esp,20          ; remove locals
                call    SwapRectangle   ; on screen

@@MbWaitReturn:
                sub     eax,eax
                int     16h             ; wait for keypress
                cmp     eax,Key_Return
                jnz     @@MbWaitReturn

                call    SetRectangle

                add     esp,20          ; remove locals
                ret
MsgBox          endp


GetDaStart      proc    near
; unsigned long GetDaStart (unsigned long eip, int NumLines)

                push    ebp
                mov     ebp,esp
                push    ebx
                mov     eax,-15
                imul    eax,[ebp+12]
                sub     eax,45
                add     eax,[ebp+8]
                push    eax
                call    BackSync
                add     esp,4
                pop     ebx
                pop     ebp
                ret
GetDaStart      endp

BackSync        proc
                push    dword ptr [esp+4]
                call    GetIncrement
                add     esp,4
                cmp     eax,1
                adc     eax,[esp+4]
                cmp     eax,[ebp+8]
                jge     @@SyncDone
                push    eax
                call    BackSync
                inc     ebx
                cmp     ebx,[ebp+12]
                pop     edx
                jnz     @@SyncEnd
                mov     eax,edx
@@SyncEnd:
                ret
@@SyncDone:
                sub     ebx,ebx
                ret
BackSync        endp

RegSaveState    proc    near
                mov     edx,offset DlRegisters
@@rssloop:
                mov     ecx,[edx]
                test    ecx,ecx
                jz      @@rssdone
                mov     eax,DepValue[ecx]
                mov     eax,[eax]
                mov     Value[ecx],eax
                add     edx,4
                jmp     @@rssloop
@@rssdone:
                ret
RegSaveState    endp

ShowRegisters   proc    near
                push    7
                cmp     ActiveWindow,AwRegWindow
                jnz     @@srcolor
                mov     byte ptr [esp],30h
@@srcolor:
                push    RegisterDy-7
                push    RegisterDx-3
                push    RegisterY
                push    RegisterX
                call    FillColor
                push    dword ptr [esp+16]
                push    7
                push    RegisterDx
                push    RegisterY+7
                push    RegisterX
                call    FillColor
                mov     byte ptr [esp+16],0
                call    FillChar
                add     esp,20
                mov     byte ptr [esp+16],0
                call    FillChar
                push    7
                push    RegisterDx
                push    RegisterY+7
                push    RegisterX


                mov     edx,offset DlRegisters
@@srloop:
                mov     ecx,[edx]
                test    ecx,ecx
                jz      @@srdone
                push    edx
                mov     eax,7
                cmp     ActiveWindow,AwRegWindow
                jnz     @@srcolor1
                mov     eax,30h

                ; check displaylist if this is where the cursor is

                mov     edx,RegCurrentY

                cmp     ecx,[edx*4+offset DlRegisters]
                jnz     @@srcolor2
                mov     eax,1fh
                jmp     @@srcolor2
@@srcolor1:
                ; reset x,y

                mov     RegCurrentY,0
@@srcolor2:
                mov     Color[ecx],eax
                push    ecx
                call    UpdateProc[ecx]
                pop     ecx
                pop     edx
                add     edx,4
                jmp     @@srloop
@@srdone:
                call    SetRectangle
                add     esp,16
                call    SetRectangle
                add     esp,20
                ret
ShowRegisters   endp

FindString      proc    near
; char * _cdecl FindString (char *what, char *where)

                push    esi
                push    edi
                cld

                ; get size of "where"

                mov     edi,[esp+16]
                mov     ecx,-1
                sub     eax,eax
                repne   scasb
                lea     ecx,[edi-1]
                sub     ecx,[esp+16]
                jna     @@FsDone
                push    ecx

                ; get size of "what"

                mov     edi,[esp+16]
                mov     ecx,-1
                repne   scasb
                lea     edi,[edi-1]
                sub     edi,[esp+16]
                pop     ecx
                jna     @@FsDone
                sub     ecx,edi
                jc      @@FsDone

                ; edi = size of what
                ; ecx = max. position for possible match

                mov     edx,edi
                mov     edi,[esp+16]    ; where
                inc     ecx

@@FsNext:
                push    ecx
                push    edi

                mov     ecx,edx         ; how many?
                mov     esi,[esp+20]    ; what
                repe    cmpsb

                pop     edi
                pop     ecx

                je      @@FsFound
                inc     edi
                loop    @@FsNext
                sub     edi,edi

@@FsFound:
                mov     eax,edi
@@FsDone:
                pop     edi
                pop     esi
                ret
FindString      endp


Hex4ToStr       proc    near
; ax -> DummyBuffer
                mov     edx,offset DummyBuffer
                shl     eax,16
                mov     ecx,4
@@h4s:
                rol     eax,4
                push    eax
                and     al,0fh
                add     al,30h
                cmp     al,3ah
                sbb     ah,ah
                not     ah
                and     ah,7
                add     al,ah
                mov     [edx],al
                inc     edx
                pop     eax
                loop    @@h4s
                mov     [edx],cl
                ret
Hex4ToStr       endp

Hex8ToStr       proc    near
; eax -> DummyBuffer
                mov     edx,offset DummyBuffer
                mov     ecx,8
@@h8s:
                rol     eax,4
                push    eax
                and     al,0fh
                add     al,30h
                cmp     al,3ah
                sbb     ah,ah
                not     ah
                and     ah,7
                add     al,ah
                mov     [edx],al
                inc     edx
                pop     eax
                loop    @@h8s
                mov     [edx],cl
                ret
Hex8ToStr       endp

.data

include keytab.inc
include nfields.inc

HexChars        db      '0123456789ABCDEF'
ScreenX         dd      80      ; default
ScreenY         dd      25      ; default
RegCurrentY     dd      0
FlagsCurrentY   dd      0
MemOriginLin    dd      0
MemCurrentX     dd      0
MemCurrentY     dd      0

MemSelNone      equ     0
MemSelCs        equ     1
MemSelDs        equ     2
MemSelEs        equ     3
MemSelFs        equ     4
MemSelGs        equ     5

MemCurrentSNum  dd      MemSelDs
MemCurrentSel   dd      offset Dds
MemCurrentOfs   dd      0

MsgInit         db      'WUDEBUG 0.1 build: ',??date,' ',??time
;			,0dh,0ah
                db      '    Copyright (c) 1997, Michael Tippach',0dh,0ah,0dh,0ah,'$'
MsgInitFail     db      'Error initializing the debugger kernel',0dh,0ah,'$'
MsgInvSel       db      'Invalid selector!',0
MsgInvVal       db      'Invalid value!',0
MsgUsage        db      'Usage:   WUDEBUG <Filename.Extension> [Optional:Arguments]',0dh,0ah,0dh,0ah,'$'
MsgLoadFail     db      'Error loading program!',0dh,0ah,'$'
MsgGoto         db      ' Go to:',0

; "SingleStep" instead of "Here(n+1)" ( branching instructions )

JString         db      ' j',0
RString         db      ' ret',0
IString         db      ' iret',0

IntString       db      ' int ',0       ; "Here(n+1)" instead of "SingleStep"

StrCs           db      'cs',0
StrDs           db      'ds',0
StrEs           db      'es',0
StrFs           db      'fs',0
StrGs           db      'gs',0
StrSs           db      'ss',0

StrEax          db      'eax',0
StrEbx          db      'ebx',0
StrEcx          db      'ecx',0
StrEdx          db      'edx',0
StrEsi          db      'esi',0
StrEdi          db      'edi',0
StrEbp          db      'ebp',0
StrEsp          db      'esp',0

MsgTerminated   db      'Program terminated',0

include helpscr.inc

.data?

argc            dd      ?
argv            dd      ?
environ         dd      ?

; ... as in int main(int argc,...

EnvBlock        dd      ?       ; environ[0]

PspSel          dd      ?
EnvSel          dd      ?
PrgFilename     dd      ?       ; location of user prg path+filename in env.
DaOrigin        dd      ?       ; start address of disassembly
DaNextPage      dd      ?       ; end address of disassembly
DaCursor        dd      ?       ; address where the cursor is
DaCurLin        dd      ?       ; current cursor line relativ to disasm start
DaCurAdd        dd      ?       ; current cursor address
DaEipLin        dd      ?       ; last visible line of Eip, - 1 if outside
SaveEflags      dd      ?       ; previous Eflags state

; 2do

AwDaWindow      equ     1
AwRegWindow     equ     2
AwFlagWindow    equ     3
AwStackWindow   equ     4
AwFpuWindow     equ     5
AwMemWindow     equ     6

ActiveWindow    dd      ?

StackCurrentY   dd      ?
StackCurrentOfs dd      ?

DaBuffer        db      16 dup (?)
DummyBuffer     db      80 dup (?)
ScreenChars     db      80*50 dup (?)
ScreenColors    db      80*50 dup (?)

		align	4
StartOfHeap     db	8000h dup (?)

end     start
