; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/DEB/sdebug.asm 1.7 2003/07/31 21:44:03 MikeT Exp MikeT $
;
; ----------------------------------------------------------------------------
;
; $Log: sdebug.asm $
; Revision 1.7  2003/07/31 21:44:03  MikeT
; Fix no WDL/Loader source display under NT, 2K, XP etc.
;
; Revision 1.6  2000/06/13 16:12:46  MikeT
; Fixed the storage of DPMI memory blocks again, such that the handle is
; written to the correct location in memory.
;
; Revision 1.5  2000/06/08 17:25:45  MikeT
; Fixed INT 31 function 0501 hook writing segment information to the wrong
; places. This documented itself in implicit breakpoints not being reset and
; showing up in the code dump instead.
;
; Revision 1.4  1999/02/13 13:44:50  MikeT
; Moved the debugger to true flat. This is in anticipation of the removal
; of the STUBIT -m_float option and the obsolete PESTUB.EXE thing.
; Removed some code to obtain a zero based selector for we already got
; one in DS now. Commented out some code that used to lock the debugger
; memory and that doesn't work anymore in true flat.
;
; Revision 1.3  1999/02/13 13:01:37  MikeT
; Increase MaxDpmiMemBlocks to 512 in order to reflect kernel change.
;
; Revision 1.2  1999/02/07 20:00:38  MikeT
; Fix for the initialization routine zeroing out random memory.
;
; Revision 1.1  1998/08/03 03:14:04  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
;
; WinNT patch added to avoid page faults in a NT DOS box (NT DPMI "bug")
;
; Increased the number of DPMI memory blocks we can have at a time as the
; WDOSX kernel now supports up to 128.
;
; some fixes have been done since the release of WDOSX 0.93, Should run o.k.
; now in a Win31 DOS box.

; comment out the next line if you have some really buggy (S)VGA BIOS

;VESA = 1

; the lowest level routines of the debugger are living here


			; max. breakpoints

MaxBreakpoints		equ	32	; increase if you like, but note that
					; they are bubble sorted ;-)

MaxDpmiMemBlocks	equ	512	; same as in WDOSX kernel

Breakpoint		struc
			BpLinearAd	dd	?
			BpOldByte	dd	?
Breakpoint		ends

MemSegment		struc
			MsLinearAd	dd	?
			MsSize		dd	?
			MsHandle	dd	?
MemSegment		ends

; Return codes for Execute()

StatusTerminated	equ	80000000h
StatusFault		equ	40000000h
StatusTrap		equ	20000000h
StatusErrBP		equ	10000000h

; Dpmi error codes

StatusDpmiError		equ	80000000h

public	_Initialize
public	_IsDebugVideo

public	_GetLinear
public	_ReadByte
public	_WriteByte

public	_GetBreakpoint
public	_SetBreakpoint
public	_KillBreakpoint

public	_SetUserScreen
public	_SetDebScreen

public	_SingleStep
public	_Here
public	_Run

public	_LoadProgram

public	_GetExceptionName

public	_Deax
public	_Debx
public	_Decx
public	_Dedx
public	_Desi
public	_Dedi
public	_Debp
public	_Desp

public	_Dcs
public	_Dss
public	_Dds
public	_Des
public	_Dfs
public	_Dgs

public	_Deip
public	_Deflags

extrn	_disasm:near

include	segdef.inc


_TEXT SEGMENT PARA PUBLIC USE32  'CODE'

include loader.asm
include screen.asm
include keyboard.asm

_Initialize	proc

		pushad

		mov	TopOfStack,esp

		; store our data selector

		mov	FlatDataSel,ds

		; NT patch: get version

		mov	ax,3306h
		int	21h
		cmp	bx,3205h
		sete	RunningNT

		mov	ebx, ds
		mov	ZeroDataSel,ebx
		mov	gs,ebx

		; get the true limit

		lsl	ebx,ebx
		mov	ZeroSelLimit,ebx


;		; lock the entire debugger memory
;
; 2do: does not work that way in true flat
;
;		mov	ebx,ds
;		mov	eax,6
;		int	31h
;		
;		mov	ebx,ecx
;		mov	ecx,edx
;
;		mov	edi,esp
;		shld	esi,edi,16
;
;		mov	eax,600h
;		int	31h
;		jc	@@error

		; get old exception handlers

		mov	edi,offset OldExcHandlers
		sub	ebx,ebx

GetOldExc:
		mov	eax,202h
		int	31h
		jc	@@error
		mov	[edi],edx
		mov	[edi+4],ecx
		add	edi,8
		inc	ebx
		cmp	bl,0fh
		jc	GetOldExc

; Workaround for a Win95 bug: set a dummy int 1 handler and call it until
; the INT 1 is reflected to our handler

		mov	ecx,cs
		mov	ebx,1
		mov	edx,offset InitDummyInt1
		mov	eax,0203h
		int	31h
		jc	@@error

		; now do the looping

		mov	ecx,1000000h
		mov	edx,esp
@@LoopWin95:
		pushfd
		or	dword ptr [esp],100h
		popfd
		loop	@@LoopWin95
		jmp	@@error
ReadyWin95:

		; set new exception handlers

		mov	edi,offset OurExcHandlers
		mov	ecx,cs
		sub	ebx,ebx

SetNewExc:
		mov	edx,[edi]
		add	edi,4
		mov	eax,0203h
		int	31h
		jc	@@error
		inc	ebx
		cmp	bl,0fh
		jc	SetNewExc

		; get old handlers for the interesting interrupts

		; keyboard hardware interrupt ( pic mapping! )

		mov	ax,400h
		int	31h
		sub	ebx,ebx
		mov	bl,dh	
		mov	Pic1Map,ebx
		inc	ebx
		mov	eax,0204h
		int	31h
		jc	@@error
		mov	[ebx*8+offset UserInts],edx
		mov	[ebx*8+offset UserInts+4],ecx
		mov	[ebx*8+offset DebugInts],edx
		mov	[ebx*8+offset DebugInts+4],ecx
		cmp	bl,9
		jz	NoPicRemap

		mov	bl,9
		mov	eax,0204h
		int	31h
		jc	@@error
		mov	[ebx*8+offset UserInts],edx
		mov	[ebx*8+offset UserInts+4],ecx
		mov	[ebx*8+offset DebugInts],edx
		mov	[ebx*8+offset DebugInts+4],ecx

NoPicRemap:

		mov	bl,21h
		mov	eax,0204h
		int	31h
		jc	@@error
		mov	ds:OldInt21o,edx
		mov	ds:OldInt21s,ecx

		mov	bl,31h
		mov	eax,0204h
		int	31h
		jc	@@error
		mov	ds:OldInt31o,edx
		mov	ds:OldInt31s,ecx


		; set new handlers for the interesting interrupts

		mov	ecx,cs

		mov	bl,21h
		mov	eax,205h
		mov	edx,offset NewInt21
		int	31h
		jc	@@error

		mov	bl,31h
		mov	eax,205h
		mov	edx,offset NewInt31
		int	31h
		jc	@@error

		; zero out some bss stuff

		sub	edx,edx
		sub	eax,eax
		mov	ecx,2048
@@zero00:
		mov	[edx+offset AllocSelectors],eax
		add	edx,4
		loop	@@zero00

IFDEF VESA

;		mov	ah,0fh
;		int	10h
;		and	al,7fh
;		mov	ebx,8000h
;		mov	bl,al
;		mov	eax,4f02h
;		int	10h
;		cmp	eax,4fh
;		jnz	@@SkipVesa

		; get realmode segment size to store video state

		mov	ecx,0fh
		mov	eax,4f04h
		sub	edx,edx
		int	10h
		cmp	eax,04fh
		jz	@@useSVga
@@SkipVesa:

ENDIF
		mov	ecx,7
		mov	eax,1c00h
		mov	SaveMethod,eax
		int	10h
		cmp	al,01ch
		jnz	@@error
@@UseSVga:
		shl	ebx,2	; in para

		mov	eax,100h
		int	31h
		jc	@@error
		mov	RmCallSeg,eax
		mov	RmCallSel,edx

; set the interrupt 3 vector to satisfy Win31

                mov	ecx,cs
		mov	edx,offset Win31Int3
		mov	bl,3
		mov	eax,205h
		int	31h

		popad
		sub	eax,eax
		ret

@@error:	popad
		mov	eax,StatusDpmiError
		ret
_Initialize	endp

InitDummyInt1	proc
		mov	dword ptr [esp+12],offset ReadyWin95
		and	dword ptr [esp+20],NOT 100h
		mov	dword ptr [esp+24],edx
		retf
InitDummyInt1	endp


_ReadByte	proc
; int _cdecl ReadByte ( unsigned long LinAdd )

		mov	edx,[esp+4]
		sub	eax,eax
		call	ReadByte
		jnc	@@crbdone
		sbb	eax,eax
@@crbdone:
		ret
_ReadByte	endp

_GetLinear	proc
; unsigned long _cdecl ( unsigned long selector )
; returns 0xffffffff if selector is invalid

		push	ebx
		mov	ebx,[esp+8]
		mov	eax,6
		int	31h
		sbb	eax,eax
		jc	@@glerr
		shl	edx,16
		shrd	edx,ecx,16
		mov	eax,edx
@@glerr:
		pop	ebx
		ret

_GetLinear	endp


; error codes for breakpoints

BpAccessError	equ	80000000h
BpNoMoreFree	equ	40000000h


FindBreakpoint	proc

; returns the offset to the Bp struc (for linear address in edx) in eax or zero

		mov	eax,offset BpArray
		mov	ecx,NumBreakpoints
		jecxz	@@find00
@@findloop:
		cmp	edx,[eax]
		jb	@@find00
		je	@@find01
		add	eax,8
		dec	ecx
		jnz	@@findloop

@@find00:
		sub	eax,eax
@@find01:
		ret
FindBreakpoint	endp

BpSort		proc

; sorts the breakpoint array
; no flames about the bubble sort, for small numbers and almost sorted
; sets it's the best fit, besides, I'm a lazy guy ;-)

		mov	edx,NumBreakpoints
@@bsNew:
		cmp	edx,2
		jc	@@bs00

		mov	ecx,NumBreakpoints
		sub	edx,edx
		dec	ecx
@@bs02:
		mov	eax,[ecx*8+offset BpArray-8]
		cmp	eax,[ecx*8+offset BPArray]
		jna	@@bs01

		xchg	eax,[ecx*8+offset BpArray]
		mov	[ecx*8+offset BpArray-8],eax
		mov	eax,[ecx*8+offset BpArray+4]
		xchg	eax,[ecx*8+offset BpArray-4]
		mov	[ecx*8+offset BpArray+4],eax
		or	edx,2
@@bs01:
		loop	@@bs02
		jmp	@@bsNew
@@bs00:
		ret
BpSort		endp

_GetExceptionName	proc
;char *GetExceptionName(int ExceptionNumber)

			mov	eax,[esp+4]
			cmp	eax,15
			jnc	@@gen00			
			mov	eax,[eax*4+offset ExceptionNames]
			ret
@@gen00:		
			sub	eax,eax
			ret
_GetExceptionName	endp

_SetBreakpoint	proc
; int _cdecl SetBreakpoint(unsigned long cs,unsigned long eip)

		; get linear address

		push	dword ptr [esp+4]
		call	_GetLinear
		add	esp,4
		inc	eax
		jnz	@@sbp00
		mov	eax,BpAccessError
		ret
@@sbp00:
		dec	eax

		; check if at the given address a breakpoint already exists

		mov	edx,[esp+8]
		add	edx,eax
		call	FindBreakpoint
		test	eax,eax
		jnz	@@sbpDone

		; does not exist, try to read the byte there

		call	ReadByte
		jnc	@@sbp01
		mov	eax,BpAccessError
		ret
@@sbp01:
		mov	ecx,NumBreakpoints
		cmp	ecx,MaxBreakpoints
		jc	@@sbp02
		mov	eax,BpNoMoreFree
		ret
@@sbp02:
		mov	BpLinearAd[ecx*8+offset BpArray],edx
		mov	BpOldByte[ecx*8+offset BpArray],eax

		inc	NumBreakPoints
		call	BpSort

@@sbpDone:
		sub	eax,eax
		ret
_SetBreakpoint	endp


_GetBreakpoint	proc
; int _cdecl GetBreakpoint(unsigned long cs,unsigned long eip)

		push	dword ptr [esp+4]
		call	_GetLinear
		add	esp,4
		inc	eax
		jnz	@@gbp00
		ret
@@gbp00:
		dec	eax

; checks if the breakpoint at the given address exists, returns 0 if not

		mov	edx,[esp+8]
		add	edx,eax
		call	FindBreakpoint
		ret
_GetBreakpoint	endp


_KillBreakpoint	proc
; void _cdecl KillBreakpoint(unsigned long cs,unsigned long eip)

		push	dword ptr [esp+4]
		call	_GetLinear
		add	esp,4
		inc	eax
		jz	@@kbp00
		dec	eax
		mov	edx,[esp+8]
		add	edx,eax
		call	FindBreakpoint
		test	eax,eax
		jz	@@kbp00

		mov	dword ptr [eax],-1
		call	BpSort		; this one will move it to the end
		dec	NumBreakpoints
@@kbp00:
		ret
_KillBreakpoint	endp

_KillAllBp	proc
; void _cdecl KillAllBp(void)

		; Kills all Breakpoints, this one is easy, though ;-)

		mov	NumBreakpoints,0
		ret
_KillAllBp	endp


PokeBreakpoints	proc
		pushad
		push	_Dcs
		call	_GetLinear
		add	esp,4
		mov	ebp,_Deip
		add	ebp,eax
		mov	ecx,NumBreakpoints
		jecxz	@@pbp00
		mov	ebx,offset BpArray
@@pbp01:
		mov	edx,BpLinearAd[ebx]
		call	ReadByte
		sbb	ah,ah
		mov	BpOldByte[ebx],eax
		jc	@@pbp02
		mov	al,0cch
		call	WriteByte
@@pbp02:
		add	ebx,8
		loop	@@pbp01
@@pbp00:
		popad
		ret
PokeBreakpoints	endp

RstBreakpoints	proc
		pushad
		mov	ecx,NumBreakpoints
		jecxz	@@rbp00
		mov	ebx,offset BpArray
@@rbp01:
		mov	edx,BpLinearAd[ebx]
		mov	eax,BpOldByte[ebx]
		test	ah,ah
		jnz	@@rbp02
		call	WriteByte
@@rbp02:
		add	ebx,8
		loop	@@rbp01
@@rbp00:
		popad
		ret
RstBreakpoints	endp

_SingleStep	proc

		and	_Deflags,0111011010111b

		; set TF

		or	_Deflags,100h

		; chain into Execute

		call	Execute

		ret
_SingleStep	endp

_Here		proc
; unsigned long Here(unsigned long cs,unsigned long eip);

		and	_Deflags,0111011010111b

		; get linear address to go to

		push	dword ptr [esp+4]
		call	_GetLinear
		add	esp,4
		inc	eax
		jz	@@herr

		dec	eax
		mov	edx,[esp+8]
		add	edx,eax

		; try to read the location

		call	ReadByte
		jc	@@herr

		; if the byte is already CC, skip set_bp

		cmp	al,0cch
		jz	@@hskip

		; try to set bp

		push	eax
		mov	al,0cch
		call	WriteByte
		pop	eax
		jc	@@herr

		; mark "here"- bp set

		or	eax,80000000h
		mov	HereBpByte,eax
		mov	HereBpLin,edx

		; chain into Execute
@@hskip:
		call	Execute

		; if breakpoint has been set, restore

		push	eax
		sub	eax,eax
		xchg	eax,HereBpByte
		test	eax,eax
		jns	@@hskip2
		mov	edx,HereBpLin
		call	WriteByte
@@hskip2:
		pop	eax
		ret

@@herr:		or	eax,StatusErrBP
		ret
_Here		endp

_Run		proc
; unsigned long _cdecl Run (void)

		and	_Deflags,0111011010111b
		call	Execute
		ret

_Run		endp

Execute		proc

		test	Bpflags,80h
		jnz	@error

		pushad

		mov	TopOfStack,esp

		; disable interrupts

;		mov	eax,0900h
;		int	31h

		; set user kbd

		call	SetUserKeyb

		call	PokeBreakpoints

		; mark user code active for software interrupt handlers

		mov	BpFlags,0ch

		; load general registers

		mov	eax,_Deax
		mov	ebx,_Debx
		mov	ecx,_Decx
		mov	edx,_Dedx
		mov	esi,_Desi
		mov	edi,_Dedi
		mov	ebp,_Debp

		; load segment registers

		mov	es,_Des
		mov	fs,_Dfs
		mov	gs,_Dgs

		; Q: Why does even Win 95 allow one to set / reset the NT flag?

		push	0
		popfd

		; switch stacks

		lss	esp, pword ptr ds:[offset _Desp]

		; build iretd stack frame

		push	_Deflags
		push	_Dcs
		push	_Deip

		; load ds

		mov	ds,_Dds

		; jump to user code

		iretd

; ------------- Execute the code now and see what happens... ------------------

HandleFault:
		mov	BpFlags,1

		call	RstBreakpoints

		call	SetDebKeyb
		popad
		mov	eax,0901h
		int	31h
		mov	eax,LastException
		add	eax,StatusFault
		ret
HandleTrap:
		mov	BpFlags,1

		call	RstBreakpoints

		call	SetDebKeyb
		popad
		mov	eax,0901h
		int	31h
		mov	eax,LastException
		cmp	al,3
		jnz	@@t01
		dec	_Deip		; set to beginning int 3 instruction
@@t01:
		add	eax,StatusTrap
		ret
OnTerminate:
		push	eax
		call	SetDebKeyb
		pop	eax
		mov	ds,cs:FlatDataSel
		mov	_Deax,eax
		mov	eax,[esp+4]
		mov	_Deip,eax
		mov	eax,[esp+8]
		mov	_Dcs,eax
		mov	ss,FlatDataSel
		mov	esp,TopOfStack
		mov	es,FlatDataSel
		mov	fs,FlatDataSel
		mov	gs,ZeroDataSel

		call	RstBreakpoints

		mov	BpFlags,81h
		mov	eax,0901h
		int	31h
		popad

@error:		mov	eax,StatusTerminated
		ret
Execute		endp

; -----------------------------------------------------------------------------

CrashTheSession:

		mov	BpFlags,0
		mov	eax,3
		int	10h
		push	offset CrashMsg1
		call	DisplayString
		mov	eax,LastException
		mov	eax,[eax*4+offset ExceptionNames]
		push	eax
		call	DisplayString
		push	offset CrashMsg2
		call	DisplayString
		push	_Dcs
		call	DisplayHex4
		push	offset CrashMsg3
		call	DisplayString
		push	_Deip
		call	DisplayHex8
		call	CrLf
		call	CrLf		
		push	offset CrashMsg4
		call	DisplayString
		push	_Deax
		call	DisplayHex8
		call	Space2
		push	offset CrashMsg5
		call	DisplayString
		push	_Debx
		call	DisplayHex8
		call	Space2
		push	offset CrashMsg6
		call	DisplayString
		push	_Decx
		call	DisplayHex8
		call	Space2
		push	offset CrashMsg7
		call	DisplayString
		push	_Dedx
		call	DisplayHex8
		call	crlf
		push	offset CrashMsg8
		call	DisplayString
		push	_Desi
		call	DisplayHex8
		call	Space2
		push	offset CrashMsg9
		call	DisplayString
		push	_Dedi
		call	DisplayHex8
		call	Space2
		push	offset CrashMsg10
		call	DisplayString
		push	_Debp
		call	DisplayHex8
		call	Space2
		push	offset CrashMsg11
		call	DisplayString
		push	_Desp
		call	DisplayHex8
		call	crlf
		call	crlf
		push	offset CrashMsg12
		call	DisplayString
		push	_Dds
		call	DisplayHex4
		call	space2
		push	offset CrashMsg13
		call	DisplayString
		push	_Des
		call	DisplayHex4
		call	space2
		push	offset CrashMsg14
		call	DisplayString
		push	_Dfs
		call	DisplayHex4
		call	space2
		push	offset CrashMsg15
		call	DisplayString
		push	_Dgs
		call	DisplayHex4
		call	space2
		push	offset CrashMsg16
		call	DisplayString
		push	_Dss
		call	DisplayHex4
		call	CrLf
		call	CrLf

		; try to read the offending instruction

		mov	ebx,_Dcs
		mov	eax,6
		int	31h
		jc	@@ctsnoda
		shl	edx,16
		shrd	edx,ecx,16
		add	edx,_Deip
		mov	ecx,16
		mov	esi,offset UserInts	; abuse this
@@ctsrloop:
		call	ReadByte
		jc	@@ctsnoda
		mov	[esi],al
		inc	edx
		inc	esi
		loop	@@ctsrloop

		push	0
		push	_Deip
		mov	eax,_Dcs
		lar	eax,eax
		test	eax,400000h
		mov	eax,16
		jz	@@ctsno32
		add	eax,eax
@@ctsno32:
		push	eax
		push	offset DebugInts
		push	offset UserInts
		call	_disasm
		add	esp,20
		test	eax,eax
		jz	@@ctsnoda
		push	offset CrashMsg20
		call	DisplayString
		push	offset DebugInts
		call	DisplayString
		call	CrLf
		call	CrLf
@@ctsnoda:
		mov	eax,4cffh
		int	21h

; -----------------------------------------------------------------------------

; NT patch

NTPatch		proc	near
; in     :             EDX = linear address to read from
; return : CF clear -> OK to try reading the byte
;          CF set   -> don't!
		cmp	RunningNT,0
		jz	NTPatchOut

		cmp	edx, 100000h
		cmc	
		jnc	short NTPatchOut

		push	ecx
		push	ebx
		push	eax
		mov	ebx,offset UserSegs
		mov	ecx,NumSegments

NTPatchLoop:
		mov	eax,MsLinearAd[ebx]
		cmp	edx,eax
		jl	short NTPatchNext
		add	eax,MsSize[ebx]
		cmp	edx,eax
		jl	NTPatchSuccess

NTPatchNext:
		add	ebx,12
		loop	short NTPatchLoop
		stc
		jmp	short NTPatchFail

NTPatchSuccess:
		clc

NTPatchFail:
		pop	eax
		pop	ebx
		pop	ecx

NTPatchOut:
		ret
NTPatch		endp


; -----------------------------------------------------------------------------

ReadByte	proc	near

; in     :             EDX = linear address to read from
; return : CF clear -> AL  = byte read
;          CF set   -> read failed
		call	NTPatch
		jc	ReadFailed
		cmp	edx,ZeroSelLimit
		ja	ReadFailed
TryRead:	mov	al,gs:[edx]
		clc
		ret
ReadFailed:	stc
		ret

ReadByte	endp

; -----------------------------------------------------------------------------

_WriteByte:
WriteByte	proc	near

; in     : EDX      = linear address to write to
;          AL       = byte to write
; return : CF clear -> write o.k.
;          CF set   -> write failed
		call	NTPatch
		jc	WriteFailed
		cmp	edx,ZeroSelLimit
		ja	WriteFailed
TryWrite:	mov	gs:[edx],al
		clc
		ret
WriteFailed:	stc
		ret

WriteByte	endp

CrLf		proc	near
		push	eax
		push	edx
		mov	dl,0dh
		mov	ah,2
		int	21h
		mov	dl,0ah
		mov	ah,2
		int	21h
		pop	edx
		pop	eax
		retn
CrLf		endp

Space2		proc	near
		push	eax
		push	edx
		mov	dl,20h
		mov	ah,2
		int	21h
		mov	dl,20h
		mov	ah,2
		int	21h
		pop	edx
		pop	eax
		retn
Space2		endp


DisplayString	proc	near
		push	esi
		mov	esi,[esp+8]
		push	edx
		push	eax
@@dsnext:
		mov	dl,[esi]
		inc	esi
		test	dl,dl
		jz	@@dsdone
		mov	ah,2
		int	21h
		jmp	@@dsnext
@@dsdone:	pop	eax
		pop	edx
		pop	esi
		retn	4
DisplayString	endp

DisplayHex8	proc	near
		push	edx
		push	eax
		push	ecx
		mov	ecx,8
		jmp	disph
DisplayHex8	endp

DisplayHex4	proc	near
		push	edx
		push	eax
		push	ecx
		mov	ecx,4
		shl	dword ptr [esp+16],16
disph:		rol	dword ptr [esp+16],4
		mov	dl,[esp+16]
		and	dl,0fh
		cmp	dl,10
		sbb	dh,dh
		xor	dh,0ffh
		and	dh,7
		add	dl,dh
		add	dl,30h
		mov	ah,2
		int	21h
		loop	disph
		pop	ecx
		pop	eax
		pop	edx
		retn	4
DisplayHex4	endp

; -----------------------------------------------------------------------------

NewInt21	proc

		; Called from within our own code?

		test	cs:BpFlags,8
		jz	@@ChainOld21


		; called from user code

		push	ds
		mov	ds,cs:FlatDataSel

		; remove indicator

		and	BpFlags,NOT 8

		; check the function called

		cmp	ah,4ch
		jz	OnTerminate
		cmp	ax,0ffffh
		jnz	@@notffff

		; trash ds on stack

		add	esp,4

		; get return address

		pop	dword ptr ds:[offset scratch_offset]

		; trash cs on stack

		add	esp,4

		pop	dword ptr ds:[offset scratch_flags]

		mov	scratch_esp,esp
		push	ds
		pop	ss
		mov	esp,TopOfStack
		push	es
		push	fs
		push	gs
		pushad

		; set carry by default

		or	byte ptr ds:[offset scratch_flags],1

		mov	ax,word ptr ds:[offset UserCodeSel]
		mov	word ptr ds:[offset scratch_sel],ax

		mov	ecx,edx
		shld	ebx,edx,16
		mov	ax,0503h
		mov	di,word ptr ds:[offset UserMemHnd]
		mov	si,word ptr ds:[offset UserMemHnd+2]
		pushfd
		push	cs
		call	NewInt31
;		int	31h
		jc	@@21fffferr

		mov	word ptr ds:[offset UserMemHnd],di
		mov	word ptr ds:[offset UserMemHnd+2],si

		mov	edx,ecx
		mov	ecx,ebx
		mov	ebx,UserCodeSel
		mov	eax,7
		pushfd
		push	cs
		call	NewInt31
;		int	31h
		jc	@@21fffferr
		mov	ebx,UserDataSel
		pushfd
		push	cs
		call	NewInt31
;		int	31h
		jc	@@21fffferr
		and	byte ptr ds:[offset scratch_flags],0feh

@@21fffferr:
		popad

		; check if the saved esp value is too big
		; it would crash on single stepping the mov esp,edx or so as
		; a next insruction

		cmp	edx,scratch_esp
		jae	@@21ffffdone
		mov	scratch_esp,edx
@@21ffffdone:
		pop	gs
		pop	fs
		pop	es
		or	BpFlags,8
		push	scratch_flags
		popfd
		mov	ss,UserDataSel
		mov	esp,scratch_esp
		mov	ds,UserDataSel
		db	0eah
scratch_offset	dd	?
scratch_sel	dd	?

@@notffff:

		; set indicator

		or	BpFlags,8
		pop	ds

@@ChainOld21:	db	0eah
OldInt21o	dd	?
OldInt21s	dd	?

NewInt21	endp

NewInt31	proc

		; Called from within our own code?
		test	cs:BpFlags,4
		jz	@@ChainOld31


		; called from user code

		push	ds
		mov	ds,cs:FlatDataSel

		; remove indicator

		and	BpFlags,NOT 4

		; check the function called

		cmp	ax,503h
		jnz	@@i3101

		; set carry flag by default

		or	byte ptr [esp+12],1

		push	eax
		push	ebp

		; get pointer to memory segment 2do: put in a procedure

		mov	ebp,NumSegments		; we have at least one
		mov	eax,offset UserSegs
@@i31fsloop:
		cmp	word ptr MsHandle[eax],di
		jne	@@i31fsnext
		cmp	word ptr MsHandle[eax+2],si
		je	@@i31fsfound
@@i31fsnext:
		add	eax,12
		dec	ebp
		jne	@@i31fsloop

		; fail
@@i31503fail:
		pop	ebp
		pop	eax
		or	BpFlags,4
		pop	ds
		iretd

@@i31fsfound:
		push	MsSize[eax]
		mov	MsSize[eax],ecx
		mov	word ptr MsSize[eax+2],bx
		push	eax
		mov	eax,503h
		pushfd
		push	cs
;		int	31h
		call	NewInt31
		pop	eax
		pop	ebp
		jc	@@i31503fail

		; bx:cx new start, ebp old size, save old start

		push	edx
		mov	edx,MsLinearAd[eax]

		; update start

		mov	MsLinearAd[eax],ecx
		mov	word ptr MsLinearAd[eax+2],bx

		; update handle

		mov	word ptr MsHandle[eax],di
		mov	word ptr MsHandle[eax+2],si


		push	esi
		push	edi


		; calculate fixup ( new base - old base )
		; calculate end address of Bp's to fix

		mov	esi,MsLinearAd[eax]
		lea	edi,[edx+ebp]
		sub	esi,edx

		; esi = fixup value
		; edx = min address of Bp's to fix
		; edi = max address + 1 of Bp's to fix

		push	ecx
		mov	ecx,NumBreakpoints
		jecxz	@@i31503fudone
		sub	eax,eax

@@i31503bploop:
		cmp	edx,BpLinearAd[eax*8+offset BpArray]
		ja	@@i31503nextbp
		cmp	edi,BpLinearAd[eax*8+offset BpArray]
		jna	@@i31503fudone
		add	BpLinearAd[eax*8+offset BpArray],esi
@@i31503nextbp:
		inc	eax
		loop	@@i31503bploop
@@i31503fudone:

		; special fixup for _Here Breakpoint

		cmp	edx,HereBpLin
		ja	@@i31503lfud
		cmp	edi,HereBpLin
		jna	@@i31503lfud
		add	HereBpLin,esi
@@i31503lfud:
		call	BpSort
		pop	ecx
		pop	edi
		pop	esi
		pop	edx
		pop	ebp
		pop	eax
		and	byte ptr [esp+12],0feh
		or	BpFlags,4
		pop	ds
		iretd

@@i3101:
		cmp	ax,501h
		jnz	@@i3102

		; fail by default

		or	byte ptr [esp+12],1
		cmp	NumSegments,MaxDpmiMemBlocks
		jnc	@@i31501fail

		push	eax
		mov	eax,NumSegments
		imul	eax, 12
		mov	word ptr MsSize[eax+offset UserSegs],cx
		mov	word ptr MsSize[eax+offset UserSegs+2],bx
		pop	eax

		pushfd
		push	cs
		call	NewInt31
		jc	@@i31501fail

		; bx:cx linear address, si:di handle

		push	eax
		mov	eax,NumSegments
		imul	eax, 12
		mov	word ptr MsLinearAd[eax+offset UserSegs],cx
		mov	word ptr MsLinearAd[eax+offset UserSegs+2],bx
		mov	word ptr MsHandle[eax+offset UserSegs],di
		mov	word ptr MsHandle[eax+offset UserSegs+2],si
		inc	NumSegments
		pop	eax
		and	byte ptr [esp+12],0feh
@@i31501fail:
		or	BpFlags,4
		pop	ds
		iretd

@@i3102:

		; 2 do: handle 502 !!!!

		; set indicator

		or	BpFlags,4
		pop	ds

@@ChainOld31:	db	0eah
OldInt31o	dd	?
Oldint31s	dd	?

NewInt31	endp

; -------------- Exception Handlers -------------------------------------------

i = 0
REPT	14
	elabel	CATSTR <Exception>,%i
elabel:
		push	i
		jmp	@@UnwindException
	i = i + 1
ENDM

		; special page fault handler

Exception14:
		push	eax
		mov	eax,cs
		cmp	word ptr [esp+20],ax
		jnz	@@TruePageFault
		cmp	dword ptr [esp+16],offset TryRead
		jnz	@@CheckTryWrite
		mov	dword ptr [esp+16],offset ReadFailed
		pop	eax
		retf

@@CheckTryWrite:
		cmp	dword ptr [esp+16],offset TryWrite
		jnz	@@TruePageFault
		mov	dword ptr [esp+16],offset WriteFailed
		pop	eax
		retf

@@TruePageFault:
		pop	eax
		push	14

@@UnwindException:

		push	ds
		mov	ds,cs:FlatDataSel	; so we can write data too
		bts	BpFlags,0		; ready to invoke the debugger?
		jnc	short @@DoTheBp

		; not ready, if 01 or 03 skip exception, else forward it to the
		; default handler that will terminate the entire session

		cmp	byte ptr [esp+4],1	; this will only happen if
		jz	@@SkipException		; we somehow managed to set the
						; trap flag _inside_ the
						; debugger code

		cmp	byte ptr [esp+4],3	; this may happen if there was
		jz	@@SkipException		; a breakpoint set in an ISR

		; set crash indicator since this should never happen

		or	BpFlags,2
		jmp	@@DoTheBp

@@SkipException:
		pop	ds			; restore ds
		add	esp,4			; remove return address
		retf				; terminate exception handler
@@DoTheBp:

		; save general registers

		mov	_Deax,eax
		mov	_Debx,ebx
		mov	_Decx,ecx
		mov	_Dedx,edx
		mov	_Desi,esi
		mov	_Dedi,edi
		mov	_Debp,ebp

		; save segment registers

		mov	eax,[esp]
		mov	_Dds,eax
		mov	_Des,es
		mov	_Dfs,fs
		mov	_Dgs,gs

		; get things pushed on stack by the DPMI host

		mov	eax,[esp+16]
		mov	LastErrorCode,eax
		mov	eax,[esp+20]
		mov	_Deip,eax
		mov	eax,[esp+24]
		mov	_Dcs,eax
		mov	eax,[esp+28]
		mov	_Deflags,eax
		mov	eax,[esp+32]
		mov	_Desp,eax
		mov	eax,[esp+36]
		mov	_Dss,eax

		; get exception number

		mov	eax,[esp+4]
		mov	LastException,eax

		; initialize segment registers

		mov	es,FlatDataSel
		mov	fs,FlatDataSel
		mov	gs,ZeroDataSel

		mov	eax,HandlerTable[eax*4]

		; check whether crash indicator set

		test	BpFlags,2
		jz	@@SetReturnInfo

		mov	eax,offset CrashTheSession

@@SetReturnInfo:

		; manipulate the stack frame

		mov	[esp],ds		; our data segment
		mov	[esp+20],eax		; where to return
		mov	[esp+24],cs
		sub	eax,eax			; zero out eflags
		mov	[esp+28],eax		; on return
		mov	eax,TopOfStack		; use the default stack
		mov	[esp+32],eax
		mov	[esp+36],ds		; new ss = new ds

		pop	ds			; restore DS
		add	esp,4			; skip exception number
		retf				; terminate exception handler

; -----------------------------------------------------------------------------

; Since Win 3.1 doesn't report int 3's to the breakpoint exception handler,
; we introduce this one, which is a interrupt service routine instead.

Win31Int3:

; On Stack: ESP+0: EIP
;           ESP+4: CS
;           ESP+8: EFLAGS
;           _DESP = ESP + 12
;
; Note that this is a hack for those masochists running the debugger in a Win31
; DOS box. Not that I would care much about it, but anyway...

		push	ds
		mov	ds,cs:FlatDataSel

		mov	LastException,3

		; save general registers

		mov	_Deax,eax
		mov	_Debx,ebx
		mov	_Decx,ecx
		mov	_Dedx,edx
		mov	_Desi,esi
		mov	_Dedi,edi
		mov	_Debp,ebp

		; save segment registers

		pop	_Dds
		pop	_Deip
		pop	_Dcs
		pop	_Deflags
		mov	_Des,es
		mov	_Dfs,fs
		mov	_Dgs,gs
		mov	_Dss,ss
		mov	_Desp,esp

		; initialize segment registers

		mov	es,FlatDataSel
		mov	fs,FlatDataSel
		mov	gs,ZeroDataSel

		; set up stack and jmp to the debugger code

		mov	ss,FlatDataSel
		mov	esp,TopOfStack
		jmp	HandlerTable[12]


_TEXT ENDS

_DATA SEGMENT PARA PUBLIC USE32  'DATA'

; bit 0 set indicates that we're running debugger code
; bit 1 used internally, must be reset on start
; bit 2 set indicates that the INT31 routine has been invoked by user code
; bit 3 set indicates that the INT21 routine has been invoked by user code
; bit 7 set indicates that the program has been terminated

BpFlags		dd	1			; exceptions not welcome

HereBpByte	dd	0			; bit 31 set: BP set on "here"

NumBreakPoints	dd	0			; number od breakpoints set

NumSegments	dd	0			; number of memory blocks alloc

ActiveScreen	dd	0			; 0 = User 1 = Debugger

SaveMethod	dd	4f04h			; Screen save / restore method

OurExcHandlers	label	dword

i = 0
REPT	15
	elabel	CATSTR <Exception>,%i
		dd	offset elabel
	i = i+1
ENDM

align 4

HandlerTable	label	dword

		dd	offset	HandleFault	; divide by zero
		dd	offset	HandleTrap	; debug
		dd	offset	CrashTheSession	; NMI
		dd	offset	HandleTrap	; Breakpoint
		dd	offset	HandleFault	; into
		dd	offset	HandleFault	; bound
		dd	offset	HandleFault	; invalid opcode
		dd	offset	HandleFault	; FPU n/a
		dd	offset	HandleFault	; double fault
		dd	offset	HandleFault	; FPU segment overrun
		dd	offset	HandleFault	; invalid TSS
		dd	offset	HandleFault	; segment not present
		dd	offset	HandleFault	; stack fault
		dd	offset	HandleFault	; GPF
		dd	offset	HandleFault	; page fault

ExceptionNames	label	dword

		dd	offset	StrExc0
		dd	offset	StrExc1
		dd	offset	StrExc2
		dd	offset	StrExc3
		dd	offset	StrExc4
		dd	offset	StrExc5
		dd	offset	StrExc6
		dd	offset	StrExc7
		dd	offset	StrExc8
		dd	offset	StrExc9
		dd	offset	StrExcA
		dd	offset	StrExcB
		dd	offset	StrExcC
		dd	offset	StrExcD
		dd	offset	StrExcE

StrExc0		db	'Divide Overflow',0
StrExc1		db	'Debug Exception',0	; never used
StrExc2		db	'NMI',0
StrExc3		db	'Breakpoint',0		; never used
StrExc4		db	'INTO: Overflow',0
StrExc5		db	'BOUND: Out Of Range',0
StrExc6		db	'Invalid Opcode',0
StrExc7		db	'FPU not Available',0
StrExc8		db	'Double Fault',0
StrExc9		db	'FPU Segment Overrun',0
StrExcA		db	'Invalid TSS',0
StrExcB		db	'Segment Not Present',0
StrExcC		db	'Stack Fault',0
StrExcD		db	'General Protection Fault',0
StrExcE		db	'Page Fault',0

CrashMsg1	db	' Your debugger session has been crashed by some unexpected event.'
		db	0dh,0ah,' Thanks for playing + enjoy the register dump!',0dh,0ah,0dh,0ah,0
CrashMsg2	db	' at ',0
CrashMsg3	db	':',0
CrashMsg4	db	' eax = ',0
CrashMsg5	db	' ebx = ',0
CrashMsg6	db	' ecx = ',0
CrashMsg7	db	' edx = ',0
CrashMsg8	db	' esi = ',0
CrashMsg9	db	' edi = ',0
CrashMsg10	db	' ebp = ',0
CrashMsg11	db	' esp = ',0
CrashMsg12	db	' ds  = ',0
CrashMsg13	db	' es  = ',0
CrashMsg14	db	' fs  = ',0
CrashMsg15	db	' gs  = ',0
CrashMsg16	db	' ss  = ',0
CrashMsg17	db	' base = ',0
CrashMsg18	db	' limit = ',0
CrashMsg19	db	' type/acc = ',0
CrashMsg20	db	'Offending instruction was: ',0
ThatsMe		db	'TIPPACH',0

RunningNT	db	0

_DATA ENDS

_BSS SEGMENT PARA PUBLIC USE32  'BSS'

Pic1Map		dd	?
RmCallSeg	dd	?
RmCallSel	dd	?
scratch_esp	dd	?
scratch_flags	dd	?
TopOfStack	dd	?		; where to set the stack pointer
FlatDataSel	dd	?		; our data selector
ZeroDataSel	dd	?		; Data selector with base 0 limit 4G
ZeroSelLimit	dd	?		; True limit of the above selector
LastException	dd	?		; as the name says
LastErrorCode	dd	?		; ditto
UserCodeSel	dd	?
UserDataSel	dd	?
UserMemHnd	dd	?

Buffer32	db	32 dup (?)

; ------------- CPU state of the user program ---------------------------------

_Deax		dd	?
_Debx		dd	?
_Decx		dd	?
_Dedx		dd	?
_Desi		dd	?
_Dedi		dd	?
_Debp		dd	?


; ------------- keep these together -------------------

_Deip		dd	?
_Dcs		dd	?

_Desp		dd	?
_Dss		dd	?

; -----------------------------------------------------

_Deflags	dd	?

_Dds		dd	?
_Des		dd	?
_Dfs		dd	?
_Dgs		dd	?

OldExcHandlers	label	dword

		dd	15 * 2 dup (?)

; Linear address of "here" breakpoint

HereBpLin	dd	?

; allocated selectors

AllocSelectors	db	8092 dup (?)

; allocated DOS memory

AllocRMSegs	dw	256 dup (?)

; for swapping interrupt vectors

UserInts	dq	256 dup (?)
DebugInts	dq	256 dup (?)

UserSegs	MemSegment	MaxDpmiMemBlocks dup (<?>,<?>,<?>)

; Breakpoints

BpArray		Breakpoint	MaxBreakPoints	dup (<?,?>)

; Screen save Area

SaveScreen	db	80*50*2 dup (?)


Dpmireg	label	dword

_edi	label	dword
_di	dw	?
	dw	?
_esi	label	dword
_si	dw	?
	dw	?
_ebp	label	dword
_bp	dw	?
	dw	?
_esp	label	dword
_spl	dw	?
	dw	?
_ebx	label	dword
_bx	label	word
_bl	db	?
_bh	db	?
	dw	?
_edx	label	dword
_dx	label	word
_dl	db	?
_dh	db	?
	dw	?
_ecx	label	dword
_cx	label	word
_cl	db	?
_ch	db	?
	dw	?
_eax	label	dword
_ax	label	word
_al	db	?
_ah	db	?
	dw	?
_oldesp	label	dword
;appendix for realmode call structure
_flags	dw	?
_es	dw	?
_oldss	label	word
_ds	dw	?
_fs	dw	?
_gs	dw	?
_ip	dw	?
_cs	dw	?
_sp	dw	?
_ss	dw	?	

_BSS ENDS

END