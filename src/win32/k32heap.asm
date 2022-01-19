; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/win32/K32HEAP.ASM 1.8 2000/02/10 19:30:20 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: K32HEAP.ASM $
; Revision 1.8  2000/02/10 19:30:20  MikeT
; Implemented stub for GetProcessHeap.
;
; Revision 1.7  1999/05/27 21:55:41  MikeT
; HeapAlloc now also passes the zeroinit flag on to LocalAlloc. This is
; supposed to fix an issue with MSVC++ 's calloc()
;
; Revision 1.6  1999/02/14 17:53:22  MikeT
; Added HeapSize for improved VC++ 6.0 supported.
;
; Revision 1.5  1999/02/07 21:06:54  MikeT
; Updated copyright.
;
; Revision 1.4  1998/12/14 23:30:51  MikeT
; Test implementation of HeapReAlloc - not verified yet!
;
; Revision 1.3  1998/11/01 18:39:03  MikeT
; Fixed LocalAlloc() not correctly dealing with holes.
; Added LocalReAlloc().
;
; Revision 1.2  1998/08/23 14:17:30  MikeT
; Add Heap* funs
;
; Revision 1.1  1998/08/03 01:41:22  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## k32heap.asm - Very simplistic local heap manager                       ##
; ############################################################################

.386

include w32struc.inc

.model flat
.code
;
; Dummy's
;
		PUBLICDLL	GlobalAlloc
		PUBLICDLL	GlobalReAlloc
		PUBLICDLL	GlobalFree
		PUBLICDLL	GlobalLock
		PUBLICDLL	GlobalUnlock
		PUBLICDLL	GlobalSize
		PUBLICDLL	GlobalFlags
		PUBLICDLL	GlobalHandle
;
; These are experimental
;
		PUBLICDLL	GetProcessHeap
		PUBLICDLL	HeapCreate
		PUBLICDLL	HeapDestroy
		PUBLICDLL	HeapAlloc
		PUBLICDLL	HeapReAlloc
		PUBLICDLL	HeapFree
		PUBLICDLL	HeapSize
;
; These are for real
;
		PUBLICDLL	LocalAlloc
		PUBLICDLL	LocalReAlloc
		PUBLICDLL	LocalFree

		PUBLIC		initHeap

		EXTRN		VirtualAlloc: NEAR
		EXTRN		GenericError: NEAR
		EXTRN		CPUExceptionHandler: NEAR

.data
		EXTRN		MainModuleHandle: DWORD

.data?
		EXTRN		Cntx: ContextRecord
		EXTRN		Erec: ExceptionRecord

.code

;-----------------------------------------------------------------------------
; These are stubbed out so far
;
GlobalAlloc LABEL NEAR
		sub	eax, eax
		retn	8

GlobalReAlloc LABEL NEAR
		sub	eax, eax
		retn	12

GlobalFree LABEL NEAR
GlobalLock LABEL NEAR
GlobalUnlock LABEL NEAR
GlobalSize LABEL NEAR
GlobalHandle LABEL NEAR
		sub	eax, eax
		retn	4

GlobalFlags LABEL NEAR
		mov	eax, GMEM_INVALID_HANDLE
		retn	4

;+----------------------------------------------------------------------------
; Win32 - LocalFree
;
LocalFree PROC NEAR

		mov	eax, [esp + 4]
		sub	eax, 8
		mov	edx, OFFSET StartOfHeap

lf_next_mcb:
		cmp	eax, [edx]			; next one?
		jz	short lf_found

		mov	edx, [edx]
		test	edx, edx			; not an mcb anymore?
		jnz	lf_next_mcb

		mov	eax, [esp + 4]
		retn	4

lf_found:
;
; Check if we can concatenate with previous one
;
		cmp	edx, OFFSET StartOfHeap	; is there?
		jz	short lf_check_behind
		test	DWORD PTR [edx.mcb_desc], mcb_free
		jz	short lf_check_behind
;
; can concatenate
;
		mov	ecx, [eax]
		mov	[edx], ecx
;
; Check if block behind next block also free
;
		test	ecx, ecx			; something behind?
		jz	short lf_done

lf_testnext:
		test	dword ptr [ecx.mcb_desc], mcb_free
		jz	short lf_done
;
; Can concatenate now
;
		mov	eax, [ecx]
		mov	[edx], eax
		jmp	short lf_done

lf_check_behind:
		or	dword ptr [eax.mcb_desc], mcb_free
		mov	edx, eax
		mov	ecx, [eax]
		test	ecx, ecx
		jnz	lf_testnext

lf_done:
		sub	eax, eax
		retn	4

LocalFree ENDP

;+----------------------------------------------------------------------------
; Win32 - HeapReAlloc
;
; This is a very lazy and incomplete implementation
;
HeapReAlloc PROC NEAR
		sub	eax, eax
		pushad
		mov	eax, [esp + 12 + 32]		; get handle
		sub	eax, 8
		mov	edx, OFFSET StartOfHeap

hra_next_mcb:
		cmp	eax, [edx]			; next one?
		jz	short hra_found

		mov	edx, [edx]
		test	edx, edx			; not an mcb anymore?
		jnz	hra_next_mcb

		jmp	hra_exit			; no such block

hra_found:
;
; eax now is a pointer to the mcb in question.
; Get the maximum size the block could be extended to.
;
		mov	edx, [eax]			; get ptr to next block
		mov	edx, [edx]			; get next block size
		test	edx, edx
		jz	hra_islast

hra_trymove:
		mov	esi, eax			; save MCB handle
		test	BYTE PTR [esp + 32 + 8 ], 10h	; ...IN_PLACE_ONLY ?
		jnz	hra_exit

		push	DWORD PTR [esp + 32 + 16]	; new size
		push	40h				; zeroinit
		call	LocalAlloc
		test	eax, eax
		jz	hra_exit

		mov	edi, eax
		mov	[esp + 28], eax
		mov	ecx, [esi]
		add	esi, 8
		sub	ecx, esi
		cmp	ecx, [esp + 32 + 16]
		jna	hra_sizok

		mov	ecx, [esp + 32 + 16]

hra_sizok:
		cld
		rep	movsb
		push	DWORD PTR [esp + 32 + 12]
		call	LocalFree
		jmp	hra_exit

hra_islast:
		mov	ecx, [esp + 32 + 16]
		lea	ecx, [ecx + eax + 8]
		cmp	ecx, EndOfHeap
		jnc	hra_trymove

		mov	DWORD PTR [ecx], 0
		mov	DWORD PTR [ecx + 4], mcb_free
		xchg	ecx, [eax]
		lea	esi, [eax + 8]
		mov	[esp + 28], esi
		mov	edi, ecx
		sub	ecx, [eax]
		jnc	hra_exit

		neg	ecx
		cld
		sub	eax, eax
		rep	stosb
		jmp	hra_exit		

hra_gotmaxsize:
		sub	edx, 8
		sub	edx, eax
;
; EDX = maximum block size
;
hra_exit:
		popad
		test	BYTE PTR [esp + 8], 4	; HEAP_GENERATE_EXCEPTIONS ?
		jz	hra_done

		test	eax, eax
		jnz	hra_done
;
; Shit hits the fan: we have to generate an exception
;
		mov     Cntx.ContextFlags, CONTEXT_X86
                mov     eax, [esp + 4]
                mov     Erec.ExceptionAddress, eax
                mov     Erec.ExceptionCode, STATUS_NO_MEMORY
                mov     Erec.NumParams, 1
		call	CPUExceptionHandler

hra_done:
		retn	16
HeapReAlloc ENDP



;+----------------------------------------------------------------------------
; Win32 - LocalReAlloc
;
; This is a very lazy and incomplete implementation
;
LocalReAlloc PROC NEAR
		sub	eax, eax
		pushad
		mov	eax, [esp + 4 + 32]		; get handle
		sub	eax, 8
		mov	edx, OFFSET StartOfHeap

lra_next_mcb:
		cmp	eax, [edx]			; next one?
		jz	short lra_found

		mov	edx, [edx]
		test	edx, edx			; not an mcb anymore?
		jnz	lra_next_mcb

		jmp	lra_exit			; no such block

lra_found:
;
; eax now is a pointer to the mcb in question.
; Get the maximum size the block could be extended to.
;
		mov	edx, [eax]			; get ptr to next block
		mov	edx, [edx]			; get next block size
		test	edx, edx
		jz	lra_islast

lra_trymove:
		mov	esi, eax			; save MCB handle
		push	DWORD PTR [esp + 32 + 8]	; new size
		push	40h				; zeroinit
		call	LocalAlloc
		test	eax, eax
		jz	lra_exit

		mov	edi, eax
		mov	[esp + 28], eax
		mov	ecx, [esi]
		add	esi, 8
		sub	ecx, esi
		cmp	ecx, [esp + 32 + 8]
		jna	lra_sizok

		mov	ecx, [esp + 32 + 8]

lra_sizok:
		cld
		rep	movsb
		push	DWORD PTR [esp + 32 + 4]
		call	LocalFree
		jmp	lra_exit

lra_islast:
		mov	ecx, [esp + 32 + 8]
		lea	ecx, [ecx + eax + 8]
		cmp	ecx, EndOfHeap
		jnc	lra_trymove

		mov	DWORD PTR [ecx], 0
		mov	DWORD PTR [ecx + 4], mcb_free
		xchg	ecx, [eax]
		lea	esi, [eax + 8]
		mov	[esp + 28], esi
		mov	edi, ecx
		sub	ecx, [eax]
		jnc	lra_exit

		neg	ecx
		cld
		sub	eax, eax
		rep	stosb
		jmp	lra_exit		

lra_gotmaxsize:
		sub	edx, 8
		sub	edx, eax
;
; EDX = maximum block size
;
lra_exit:
		popad
		retn	12
LocalReAlloc ENDP

;+----------------------------------------------------------------------------
; Win32 - LocalAlloc
;
LocalAlloc PROC NEAR
;
; find a memory block of desired size
; 2do: best fit rather than first fit ???
;
		mov	edx, [esp + 8]		; get size
		add	edx, 8 + 3		; add mcb size & roundoff
;
; 2do: other allocation granularity ???
;
		and	dl, 0FCh
		mov	ecx, StartOfHeap

@@laexam_mcb:
		cmp	[ecx.mcb_next], 0	; last one?
		jz	short @@latry_end
;
; check if free
;
		test	[ecx.mcb_desc], mcb_free
		jnz	short @@lacheck_size
;
; get next
;
@@laget_next:
		mov	ecx, [ecx.mcb_next]
		jmp	short @@laexam_mcb

@@lacheck_size:
		mov	eax, [ecx.mcb_next]
		sub	eax, ecx
;
; actual size in eax
;
		cmp	eax, edx
		jc	short @@laget_next
;
; After all, it fits
;
		lea	edx, [ecx + 8]
		and	[ecx.mcb_desc], not mcb_free	; mark as used
		jmp	short @@lasuccess

@@latry_end:
		lea	eax, [ecx+edx+8]
		cmp	eax, EndOfHeap
		jnc	short @@laerror
;
; Initialize new mcb
;
		sub	eax, 8
		mov	[ecx.mcb_next], eax
		mov	[eax.mcb_next], 0		; mark as last in chain
		and	[ecx.mcb_desc], not mcb_free	; mark as used
		lea	edx, [ecx + 8]
@@lasuccess:
;
; handle in edx
; check for zeroinit
;
		test	byte ptr [esp + 4], 40h
		jz	short @@laexit

		push	edi
		cld
		mov	edi, edx
		mov	ecx, [esp + 12]
		add	ecx, 3
		shr	ecx, 2
		sub	eax, eax
		rep	stosd
		pop	edi

@@laexit:
		mov	eax, edx
		retn	8

@@laerror:
		sub	eax, eax
		retn	8

LocalAlloc ENDP

;+---------------------------------------------------------------------------
; Win32 - GetProcessHeap
;
GetProcessHeap PROC NEAR
		mov     eax, 2                  ; "handle"
		retn
GetProcessHeap ENDP


;+---------------------------------------------------------------------------
; Win32 - HeapCreate
;
HeapCreate PROC NEAR
		mov	eax, 1			; "handle"
		retn	12
HeapCreate ENDP


;+---------------------------------------------------------------------------
; Win32 - HeapDestroy
;
HeapDestroy PROC NEAR
		mov	eax, 1			; "o.k."
		retn	4
HeapDestroy ENDP

;+---------------------------------------------------------------------------
; Win32 - HeapAlloc
;
HeapAlloc PROC NEAR
		pop	edx
		pop	eax
		pop	eax		; get flags
		and	eax, 8		; isolate HEAP_ZERO_INIT
		shl	eax, 3		; convert into LMEM_ZEROINIT
		push	eax		; back on the stack
		push	edx
		jmp	LocalAlloc
HeapAlloc ENDP

;+---------------------------------------------------------------------------
; Win32 - HeapFree
;
HeapFree PROC NEAR
		pop	edx
		pop	eax
		pop	eax
		push	edx
		jmp	LocalFree
HeapFree ENDP


;++--------------------------------------------------------------------------
; Win32 - HeapSize
;
HeapSize PROC NEAR
		mov	eax, [esp + 12]
		sub	eax, 8
		mov	edx, OFFSET StartOfHeap

hs_next_mcb:
		cmp	eax, [edx]			; next one?
		jz	short hs_found

		mov	edx, [edx]
		test	edx, edx			; not an mcb anymore?
		jnz	hs_next_mcb

		sub	eax, eax
		retn	12

hs_found:
		sub	eax, [eax]
		neg	eax
		sub	eax, 8
		retn	12
HeapSize ENDP



; ############################################################################
; ## Initialization for this one                                            ##
; ############################################################################

initHeap PROC NEAR
;
; Get application's HeapCommit. We take this as a measure for how much heap
; space to reserve. Not that this would be even remotely correct mind you.
;
		pushad
		mov	eax, MainModuleHandle
		mov	esi, [eax+60]
		mov	esi, [esi+eax+6Ch]
		add	esi, 0FFFFh
		sub	si, si
		push	PAGE_EXECUTE_READWRITE
		push	MEM_RESERVE + MEM_COMMIT
		push	esi
		push	0
		call	VirtualAlloc
		test	eax, eax
		jnz	@@initCont

		push	esi
		push	OFFSET strError
		call	GenericError

@@initCont:
		mov	StartOfHeap, eax
		add	eax, esi
		mov	EndOfHeap, eax
		popad
		ret

initHeap ENDP


.data

strError	db	'FATAL: Could not allocate %8 bytes local application heap!',0Dh, 0Ah, 0

.data?
	ALIGN 4

StartOfHeap		dd	?
EndOfHeap		dd	?

	END
