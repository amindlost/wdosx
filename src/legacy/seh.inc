; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/legacy/SEH.INC 1.1 1999/02/07 18:14:32 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: SEH.INC $
; Revision 1.1  1999/02/07 18:14:32  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
;
; Old floating segment PE code which I'm too lazy to maintain any longer or to
; even comment on. It should stay as is and eventually die.
;


RaiseException:
IFDEF DEBUG
		push	offset RaiseException_s
		call	output0string
ENDIF
		push	ebp
		mov	ebp,esp

		; build ExceptionRecord on Stack

		mov	edx,[ebp+20]	; pointer to arguments
		mov	ecx,[ebp+16]	; number of arguments
		mov	eax,ecx
		jecxz	@@ReNoCpy
@@ReDoCpy:
		push	dword ptr [ecx*4-4+edx]
		loop	short @@ReDoCpy

@@ReNoCpy:
		push	eax		; Num args
		push	Cntx.CntEip
		push	0
		push	dword ptr [ebp+12]	; flags
		push	dword ptr [ebp+8]	; code

		; traverse handler chain

		mov	edx,fs:[ecx]

@@ReCallHandler:
		cmp	edx,-1
		jz	@@ReNoHandler		; should never happen

		mov	eax,esp
		push	edx


		push	edx
		push	offset Cntx
		push	edx
		push	eax
		call	pEhandler[edx]

		; calling conventions?
		; !!!

		add	esp,16

		pop	edx
		mov	edx,pPrevious[edx]
		test	eax,eax			; did the handler do something?
		jnz	short @@ReCallHandler

		; yep, restore count

@@ReNoHandler:
		mov	esp,ebp
		pop	ebp
		retn	16

; ############################################################################

UnhandledExceptionFilter:
IFDEF DEBUG
		push	offset	UnhandledExceptionFilter_s
		call	output0string
ENDIF
		sub	eax,eax		; "EXCEPTION_CONTINUE_EXECUTION"
		retn	4

; ############################################################################

InitSeh		proc	near

		; Initialize passing of CPU exceptions

		mov	FlatDataSel,ds
		mov	Cntx.ContextFlags,OUR_CNT

		mov	eax,cs
		lsl	eax,eax

		; check whether debugger is present

		cmp	eax,esp
		adc	IsDebugger,0

		; get old exception handlers

		mov	edi,offset OldExcHandlers
		sub	ebx,ebx

GetOldExc:
		mov	eax,202h
		int	31h
		mov	[edi],edx
		mov	[edi+4],ecx
		add	edi,8
		inc	ebx
		cmp	bl,01fh
		jna	GetOldExc

		; set new exception handlers

		mov	ecx,cs
		sub	ebx,ebx
		lea	edx,StartEhand
SetNewExc:
		mov	eax,0203h
		int	31h
		inc	ebx
		add	edx,(offset EndEhand - offset StartEhand)/32
		cmp	bl,01fh
		jna	SetNewExc
		ret
InitSeh		endp

IsDebugger	db	0
IsFPUExc	db	0
; UExceptStr	db	'Unhandled CPU exception. Exiting',0dh,0ah,0
align	4
EcodeTab	label	dword

		dd	STATUS_INTEGER_DIVIDE_BY_ZERO
		dd	STATUS_SINGLE_STEP
		dd	STATUS_NONCONTINUABLE_EXCEPTION
		dd	STATUS_BREAKPOINT
		dd	STATUS_INTEGER_OVERFLOW
		dd	STATUS_ARRAY_BOUNDS_EXCEEDED
		dd	STATUS_ILLEGAL_INSTRUCTION
		dd	STATUS_NONCONTINUABLE_EXCEPTION
		dd	STATUS_NONCONTINUABLE_EXCEPTION
		dd	STATUS_NONCONTINUABLE_EXCEPTION 
		dd	STATUS_NONCONTINUABLE_EXCEPTION
		dd	STATUS_NONCONTINUABLE_EXCEPTION
		dd	STATUS_STACK_OVERFLOW
		dd	STATUS_PRIVILEGED_INSTRUCTION
		dd	STATUS_ACCESS_VIOLATION
EAddress	dd	0

BackTrans	label	dword
		dd	STATUS_INTEGER_DIVIDE_BY_ZERO
		dd	STATUS_SINGLE_STEP
		dd	STATUS_NONCONTINUABLE_EXCEPTION
		dd	STATUS_BREAKPOINT
		dd	STATUS_INTEGER_OVERFLOW
		dd	STATUS_ARRAY_BOUNDS_EXCEEDED
		dd	STATUS_ILLEGAL_INSTRUCTION
		dd	STATUS_STACK_OVERFLOW
		dd	STATUS_PRIVILEGED_INSTRUCTION
		dd	STATUS_ACCESS_VIOLATION
		dd	STATUS_NO_MEMORY
		dd	STATUS_CONTROL_C_EXIT
		dd	STATUS_FLOAT_DENORMAL_OPERAND
		dd	STATUS_FLOAT_DIVIDE_BY_ZERO
		dd	STATUS_FLOAT_INEXACT_RESULT
		dd	STATUS_FLOAT_INVALID_OPERATION
		dd	STATUS_FLOAT_OVERFLOW
		dd	STATUS_FLOAT_STACK_CHECK
		dd	STATUS_FLOAT_UNDERFLOW
		dd	0

BackString	label	near
		dd	offset ExcStr0
		dd	offset ExcStr1
		dd	offset ExcStr2
		dd	offset ExcStr3
		dd	offset ExcStr4
		dd	offset ExcStr5
		dd	offset ExcStr6
		dd	offset ExcStr7
		dd	offset ExcStr8
		dd	offset ExcStr9
		dd	offset ExcStr10
		dd	offset ExcStr11
		dd	offset ExcStr12
		dd	offset ExcStr13
		dd	offset ExcStr14
		dd	offset ExcStr15
		dd	offset ExcStr16
		dd	offset ExcStr17
		dd	offset ExcStr18
		dd	offset ExcStrUnavail

ExcStr0		db	'Integer divide by zero',0
ExcStr1		db	'Single step',0
ExcStr2		db	'Noncontiunuable exception',0
ExcStr3		db	'Breakpoint',0
ExcStr4		db	'Integer overflow',0
ExcStr5		db	'Array bounds exceeded',0
ExcStr6		db	'Illegeal instruction',0
ExcStr7		db	'Stack overflow',0
ExcStr8		db	'Privileged instruction',0
ExcStr9		db	'Access violation',0
ExcStr10	db	'No memory',0
ExcStr11	db	'Control C exit',0
ExcStr12	db	'Float denormal operand',0
ExcStr13	db	'Float divide by zero',0
ExcStr14	db	'Float inexact result',0
ExcStr15	db	'Float invalid operation',0
ExcStr16	db	'Float overflow',0
ExcStr17	db	'Float stack check',0
ExcStr18	db	'Float underflow',0

; ############################################################################

StartEhand	label	near

i = 0
REPT	32
	elabel	CATSTR <Exception>,%i
elabel:
		push	i
		jmp	short @@UnwindException
	i = i + 1
ENDM

EndEhand	label	near

@@UnwindException:

		push	ds

		; if load is in progress, don't call the exception handler


		mov	ds,cs:[FlatDataSel]	; so we can write data too

		cmp	dword ptr ds:[0],-1
		jz	short @@ChainDebugger

		; if the exception wasn't raised within our default code
		; segment, we pass it to the old handler

		push	eax
		mov	eax,cs
		cmp	ax,[esp+28]
		pop	eax
		jnz	short @@ChainDebugger


		; if the debugger is running, pass control to the debugger
		; first

		cmp	IsDebugger,0
		jz	short @@NoDebugger

		; If it's been a breakpoint or single step, don't raise
		; an API exception if a debugger is present

		cmp	byte ptr [esp+4],1
		jz	short @@ChainDebugger

		cmp	byte ptr [esp+4],3
		jz	short @@ChainDebugger

		; Exception triggered the first time?

		push	eax
		mov	eax,[esp+24]
		xchg	eax,EAddress
		cmp	eax,EAddress
		pop	eax

		jz	short @@NoDebugger

@@ChainDebugger:

		; put the address to jump to on the stack

		pop	ds
		xchg	eax,[esp]
		push	dword ptr cs:[offset OldExcHandlers+eax*8]
		mov	eax,dword ptr cs:[offset OldExcHandlers+eax*8+4]
		xchg	eax,[esp+4]
		retf

@@NoDebugger:

		; save general registers

		mov	Cntx.CntEax,eax
		mov	Cntx.CntEbx,ebx
		mov	Cntx.CntEcx,ecx
		mov	Cntx.CntEdx,edx
		mov	Cntx.CntEsi,esi
		mov	Cntx.CntEdi,edi
		mov	Cntx.CntEbp,ebp

		; save segment registers

		mov	eax,[esp]
		mov	Cntx.CntSegDs,eax
		mov	Cntx.CntSegEs,es
		mov	Cntx.CntSegFs,fs
		mov	Cntx.CntSegGs,gs

		; get things pushed on stack by the DPMI host

;		mov	eax,[esp+16]
;		mov	LastErrorCode,eax
		mov	eax,[esp+20]
		mov	Cntx.CntEip,eax
		mov	Erec.ExceptionAddress,eax
		mov	eax,[esp+24]
		mov	Cntx.CntSegCs,eax
		mov	eax,[esp+28]
		mov	Cntx.CntEflags,eax
		mov	eax,[esp+32]
		mov	Cntx.CntEsp,eax
		mov	eax,[esp+36]
		mov	Cntx.CntSegSs,eax

		; get exception number

		mov	eax,[esp+4]
		cmp	al,16
		jnz	short @@NoFPUExc
		call	FPUSetError
@@NoFPUExc:
		cmp	al,7
		jnz	short @@AsUsual
		cmp	IsFPUExc,0
		jz	@@AsUsual
		mov	IsFPUExc,0
		mov	eax,cs
		lar	eax,eax
		test	ah,60h
		jnz	short @@Exc7TryWin
@@ExcTryHarder:
		mov	eax,cr0
		nop
		and	al,NOT 4
		or	al,2
		mov	cr0,eax
		jmp	short @@Exc7WinDone
@@Exc7TryWin:
		mov	eax,0e01h
		push	ebx
		mov	bl,1
		int	31h
		pop	ebx
		jc	short @@ExcTryHarder
@@Exc7WinDone:
		mov	eax,16

@@AsUsual:
		cmp	al,16
		jz	short @@ExcNocode

		; translate into Win32 exception code

		mov	eax,ECodeTab[eax*4]
		mov	Erec.ExceptionCode,eax

		mov	Erec.NumParams,1
;		cmp	eax,0c0000005h
;		jnz	short @@ExcNocode

		mov	eax,[esp+16]
		mov	dword ptr ds:[offset Erec.ExceptionInfo],eax
;		mov	Erec.NumParams,2
;		mov	eax,cr2
;		mov	dword ptr ds:[offset Erec.ExceptionInfo+4],eax
@@ExcNocode:


		; initialize segment registers

		mov	es,FlatDataSel
		mov	fs,FlatDataSel

		; manipulate the stack frame

		mov	dword ptr [esp+20],offset CPUExceptionHandler
		add	esp,8			; skip exception number and ds
		retf				; terminate exception handler

; ############################################################################

; Translate bit positions in FPU error code to Win 32

FPUExcTable		db	90h,8dh,8eh,91h,93h,8fh,92h

FPUSetError	proc	near
		push	eax
		push	edx
		push	0
		fnstsw	[esp]
		mov	eax,[esp]
		fnstcw	[esp]
		fnclex
		pop	edx
		not	edx
		or	edx,1000000b
		and	eax,1111111b
		and	edx,eax
		bsf	eax,edx
		mov	edx,0c0000000h
		mov	dl,FPUExcTable[eax]
		mov	Erec.ExceptionCode,edx
		pop	edx
		pop	eax
		retn
FPUSetError	endp

FPUHandlerPIC:

; This one is really horrible, but it seems to be the only way to get it done
; in Windows

		; make the next ESC opcode cause an exception

		push	eax
		push	ds
		mov	ds,cs:FlatDataSel
		call	FPUSetError
		mov	eax,cs
		lar	eax,eax
		test	ah,60h
		jnz	short @@FPUTryWin
@@FPUTryHarder:
		mov	eax,cr0
		nop
		and	al,NOT 2
		or	al,4
		mov	cr0,eax
		jmp	short @@FPUCr0Done
@@FPUTryWin:
		push	ebx
		mov	eax,0e01h
		mov	bl,2
		int	31h
		pop	ebx
		jc	short @@FPUTryHarder
@@FPUCr0Done:
		mov	IsFPUExc,1

		; clear the PIC

		mov	al,20h
		out	0a0h,al
		out	020h,al


		pop	ds
		pop	eax
		iretd

; ############################################################################


CPUExceptionHandler	proc	near

			push	offset Erec.ExceptionInfo
			push	Erec.Numparams
			push	NOT_CONTINUABLE
			push	Erec.ExceptionCode
			call	RaiseException

			; if this one returns, terminate the program

;			push	offset UExceptStr
;			call	Output0String

			mov	ah,0fh
			int	10h
			and	al,7fh
			cmp	al,3
			jz	short EAbortSuppVmode
			mov	eax,3
			int	10h
EAbortSuppVmode:
			push	offset Erec
			push	offset Cntx
			call	DumpCntx
			mov	eax,4cffh
			int	21h

CPUExceptionHandler	endp

; ############################################################################
; ## Number display etc.                                                    ##
; ############################################################################

OutHex4		proc	near
		mov	ecx,[esp+4]
		mov	eax,30000200h
		ror	ecx,12
@@oh401:
		mov	dl,cl
		and	dl,0fh
		cmp	dl,0ah
		jc	short @@oh400
		add	dl,7
@@oh400:
		add	dl,30h
		int	21h
		rol	ecx,4
		sub	eax,10000000h
		jnc	short @@oh401
		
		retn	4
OutHex4		endp

OutHex8		proc	near
		mov	eax,[esp+4]
		shr	eax,16
		push	eax
		call	OutHex4
		push	dword ptr [esp+4]
		call	OutHex4
		retn	4
OutHex8		endp

OutSel		proc	near
		push	ebx
		mov	ebx,[esp+8]
		push	ebx
		call	OutHex4
		mov	eax,6
		int	31h
		jnc	short @@os001
		push	offset ExcStrUnavail
		call	OutStr
		pop	ebx
		retn	4
@@os001:
		push	edx
		push	ecx
		push	offset ExcStrBase
		call	OutStr
		call	OutHex4
		call	OutHex4		
		push	offset ExcStrLimit
		call	OutStr
		lsl	eax,ebx
		push	eax
		call	OutHex8
		push	offset ExcStrAcc
		call	OutStr
		lar	eax,ebx
		shr	eax,8
		push	eax
		call	OutHex4
		pop	ebx
		retn	4
OutSel		endp

OutStr		proc	near
		mov	ecx,[esp+4]
@@ost001:
		mov	dl,[ecx]
		inc	ecx
		test	dl,dl
		jz	short @@ost000
		mov	ah,2
		int	21h
		jmp	short @@ost001
@@ost000:
		retn	4
OutStr		endp

DumpCntx	proc	near
		push	esi
		push	edi
		push	ebp
		mov	esi,[esp+16]
		mov	ebp,[esp+20]
		mov	edi,offset ExcStrContext
		mov	eax,CntEIP[esi]
		push	eax
		sub	eax,rva2offset
		push	eax
		smsw	ax		; actually: smsw eax
		push	eax
		push	CntEflags[esi]
		push	dword ptr CntSegSS[esi]
		push	dword ptr CntSegGS[esi]
		push	dword ptr CntSegFS[esi]
		push	dword ptr CntSegES[esi]
		push	dword ptr CntSegDS[esi]
		push	dword ptr CntSegCS[esi]
		push	CntESP[esi]
		push	CntEBP[esi]
		push	CntEDI[esi]
		push	CntESI[esi]
		push	CntEDX[esi]
		push	CntECX[esi]
		push	CntEBX[esi]
		push	CntEAX[esi]
		mov	eax,[ebp]
		sub	edx,edx
@@dc00a0:
		cmp	eax,BackTrans[edx]
		jz	short @@dc00aa
		test	dword ptr BackTrans[edx],-1
		jz	short @@dc00aa
		add	edx,4
		jmp	short @@dc00a0
@@dc00aa:
		push	dword ptr BackString[edx]
		push	eax
@@dc0000:
		mov	dl,[edi]
		inc	edi
		test	dl,dl
		jz	@@dc0001
		cmp	dl,'%'
		jnz	@@dc0002
		mov	dl,[edi]
		inc	edi
		cmp	dl,'4'
		jnz	@@dc0003
		call	OutHex4
		jmp	short @@dc0000
@@dc0003:
		cmp	dl,'8'
		jnz	@@dc0004
		call	OutHex8
		jmp	short @@dc0000
@@dc0004:
		cmp	dl,'a'
		jnz	@@dc0005
		call	OutStr
		jmp	short @@dc0000
@@dc0005:
		call	OutSel
		jmp	short @@dc0000

@@dc0002:
		mov	ah,2
		int	21h
		jmp	short @@dc0000
@@dc0001:
		pop	ebp
		pop	edi
		pop	esi		
		retn	8
DumpCntx	endp


ExcStrContext	db	'WDOSX Win32 subsystem: Abort from unhandled exception.',0dh,0ah
		db	'EXCEPTION_RECORD: Code = %8  Description = %a',0dh,0ah
		db	'CONTEXT dump:',0dh,0ah
		db	'EAX = %8  EBX = %8  ECX = %8  EDX = %8',0dh,0ah
		db	'ESI = %8  EDI = %8  EBP = %8  ESP = %8',0dh,0ah
		db	'CS = %s',0dh,0ah
		db	'DS = %s',0dh,0ah
		db	'ES = %s',0dh,0ah
		db	'FS = %s',0dh,0ah
		db	'GS = %s',0dh,0ah
		db	'SS = %s',0dh,0ah
		db	'EFL = %8  CR0 = %8  '
		db	'RVA = %8  EIP = %8',0dh,0ah,0
ExcStrUnavail	db	'  N/A',0
ExcStrBase	db	'   Base = ',0
ExcStrLimit	db	'  Limit = ',0
ExcStrAcc	db	'  Type/Acc = ',0
