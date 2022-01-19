; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/win32/K32SPAWN.ASM 1.6 1999/05/27 21:46:18 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: K32SPAWN.ASM $
; Revision 1.6  1999/05/27 21:46:18  MikeT
; Chaged last error extern to DWORD instead of NEAR.
;
; Revision 1.5  1999/05/27 21:45:05  MikeT
; Actually set last error in CreateProcess and remove the comment that
; suggested we should do so in the future.
;
; Revision 1.4  1999/03/10 21:12:06  MikeT
; Change the command tail in CreateProcess from ASCIZ to the actual PSP
; image format.
;
; Revision 1.3  1999/02/07 21:11:38  MikeT
; Updated copyright.
;
; Revision 1.2  1998/09/26 16:53:51  MikeT
; Fixed command line processing.
; Verified to work now with Borland's TVDEMO.EXE.
;
; Revision 1.1  1998/09/16 22:19:31  MikeT
; Initial check in. Still needs testing.
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## Win32 - Spawn- type functions.                                         ##
; ############################################################################

.386p
.model flat

include w32struc.inc

.code

		PUBLICDLL	CreateProcessA
		PUBLICDLL	GetExitCodeProcess

		EXTRN		LastError: DWORD

;+----------------------------------------------------------------------------
; Win32 - CreateProcessA
;
CreateProcessA PROC NEAR
		sub	eax, eax			; assume error
		pushad
		mov	ebp, [esp + 28 + 32]
		test	ebp, ebp
		jne	@@gotEnv

		mov	ah, 62h
		int	21h
		push	ds
		mov	ds, ebx
		mov	bx, ds:[2Ch]
		pop	ds
		mov	ax, 6
		int	31h
		shrd	ebp, edx, 16
		shrd	ebp, ecx, 16

@@gotEnv:
		mov	edx, [esp + 4 + 32]
		mov	ecx, [esp + 8 + 32]
		test	edx, edx
		jne	@@gotFileName

		mov	edx, ecx

@@gotFileName:
		test	ecx, ecx
		jne	@@scanCmdLine

		mov	ecx, edx

@@scanCmdline:
;
; If ecx != edx then we do already have a valid program name and command line.
; Otherwise we have to split these.
;
		sub	eax, eax
		cmp	ecx, edx
		sete	ah


@@scanCmdLoop:
		cmp	BYTE PTR [ecx], 21h
		inc	ecx
		jnc	@@scanCmdLoop
;
; ECX -> DOS command tail ASCIZ
;
		test	ah, ah
		jz	@@twoPointers

		mov	al, [ecx - 1]
		mov	BYTE PTR [ecx - 1], 0

@@twoPointers:
		push	eax			; save character
		push	ecx			; save ->
		sub	al, 1			; CF if already 0
		sbb	ecx, 0			; point to 0 +  if so
		mov	esi, ecx		; SRC
		sub	esp, 128		; local buffer for cmd tail
		mov	edi, esp
		mov	eax, ds
		shl	eax, 16
		push	eax
		add	esp, 2
		push	edi
		push	eax
		add	esp, 2
		push	ebp
;
; Copy command tail
;
		sub	ecx, ecx

@@cmd2local:
		mov	al, [esi]
		inc	esi
		test	al, al
		jz	@@setSz

		mov	[edi + ecx + 1], al
		inc	ecx
		jmp	@@cmd2local

@@setSz:
		mov	WORD PTR [edi + ecx + 1], 000Dh
		mov	[edi], cl
		mov	ax, 4B00h
		mov	ebx, esp
		int	21h
		lea	esp, [esp + 12 + 128]
		sbb	ecx, ecx		; Create mask for error code
		movzx	eax, al			; Only low byte matters
		and	eax, ecx		; Will set eax to 0 if nc
		mov	LastError, eax		; Set last error
		add	eax, ecx		; restore carry flag
		pop	ecx
		pop	eax
		dec	ah			; Don't modify carry flag
		jnz	@@backFixDone

		mov	[ecx - 1], al

@@backFixDone:
		mov	eax, [esp + 32 + 40]
		mov	ebx, 12345678h
		mov	[eax], ebx
		mov	[eax + 4], ebx
		mov	[eax + 8], ebx
		mov	[eax + 12], ebx
		popad
		setnc	al
		retn	40
CreateProcessA ENDP

;+----------------------------------------------------------------------------
; Win32 - GetExitCodeProcess
;
GetExitCodeProcess PROC NEAR
		sub	eax, eax
		cmp	DWORD PTR [esp + 4], 12345678h
		jne	@@exit

		mov	edx, [esp + 8]
		mov	ah, 4Dh
		int	21h
		sub	ah, ah
		mov	[edx], eax
		mov	al, 1

@@exit:
		retn	8
GetExitCodeProcess ENDP

END
