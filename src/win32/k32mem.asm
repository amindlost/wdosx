; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/win32/K32MEM.ASM 1.1 2000/03/18 18:37:12 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: K32MEM.ASM $
; Revision 1.1  2000/03/18 18:37:12  MikeT
; New file
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## Win32 - Generic mem functions                                          ##
; ############################################################################

.386p
.model flat

include w32struc.inc

.code

		PUBLICDLL	RtlMoveMemory
		PUBLICDLL	RtlFillMemory
		PUBLICDLL	RtlZeroMemory

;+----------------------------------------------------------------------------
; Win32 - RtlMoveMemory
;
RtlMoveMemory PROC NEAR

		push	esi
		push	edi
		cld
		mov	esi, [esp + 4 + 8]
		mov	edi, [esp + 8 + 8]
		mov	ecx, [esp +12 + 8]
		cmp	esi, edi
		jnc	mmCopy

		std
		sub	eax, eax
		cmp	ecx, 4
		adc	eax, eax
		cmp	ecx, 4
		adc	eax, eax
		lea	esi, [esi + ecx - 4]
		lea	edi, [edi + ecx - 4]
		add	esi, eax
		add	edi, eax

mmCopy:
		shr	ecx, 2
		rep	movsd
		mov	ecx, [esp +12 + 8]
		and	ecx, 3
		rep	movsb
		cld
		pop	edi
		pop	esi
		retn	12

RtlMoveMemory ENDP

;+----------------------------------------------------------------------------
; Win32 - RtlFillMemory
;
RtlFillMemory PROC NEAR

		push	edi
		mov	edi, [esp + 4 + 4]
		mov	ecx, [esp + 8 + 4]
		cld
		movzx	eax, BYTE PTR [esp +12]
		mov	edx, eax
		shl	eax, 16
		or	eax, edx
		mov	edx, eax
		shl	edx, 8
		or	eax, edx
		shr	ecx, 2
		rep	stosd
		mov	ecx, [esp + 8 + 4]
		and	ecx, 3
		rep	stosb
		pop	edi
		retn	12

RtlFillMemory ENDP

;+----------------------------------------------------------------------------
; Win32 - RtlZeroMemory
;
RtlZeroMemory PROC NEAR

		push	edi
		mov	edi, [esp + 4 + 4]
		mov	ecx, [esp + 8 + 4]
		sub	eax, eax
		cld
		shr	ecx, 2
		rep	stosd
		mov	ecx, [esp + 8 + 4]
		and	ecx, 3
		rep	stosb
		pop	edi
		retn	8

RtlZeroMemory ENDP

END
