; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/win32/K32LFUNS.ASM 1.4 1999/05/27 21:33:56 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: K32LFUNS.ASM $
; Revision 1.4  1999/05/27 21:33:56  MikeT
; Bug report from the field: In lstrcpyn we need to remove 3 arguments from the
; stack as opposed to 2. Changed the retn 8 into retn 12.
;
; Revision 1.3  1999/03/21 15:46:38  MikeT
; Use file handle translation between DOS and Windows.
;
; Revision 1.2  1999/02/07 21:10:37  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 01:42:15  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ##                  A bunch of those "l.." functions                      ##
; ############################################################################

.386
.model flat

INCLUDE	w32struc.inc

.code

		PUBLICDLL		lstrcat
		PUBLICDLL		lstrcatA
		PUBLICDLL		lstrcmp
		PUBLICDLL		lstrcmpA
		PUBLICDLL		lstrcmpi
		PUBLICDLL		lstrcmpiA
		PUBLICDLL		lstrcpy
		PUBLICDLL		lstrcpyA
		PUBLICDLL		lstrcpyn
		PUBLICDLL		lstrcpynA
		PUBLICDLL		lstrlen
		PUBLICDLL		lstrlenA
		PUBLICDLL		_hread
		PUBLICDLL		_hwrite
		PUBLICDLL		_lclose
		PUBLICDLL		_lcreat
		PUBLICDLL		_llseek
		PUBLICDLL		_lopen
		PUBLICDLL		_lread
		PUBLICDLL		_lwrite

		EXTRN	SetFilePointer: NEAR
		EXTRN	LastError: DWORD

; ############################################################################

lstrlen:
lstrlenA:
		mov	edx, [esp+4]
		sub	eax, eax

lstrlen00:
		cmp	byte ptr [edx+eax], 0
		jz	short lstrlen01

		inc	eax
		jmp	short lstrlen00

lstrlen01:
		retn	4

; ############################################################################

lstrcpy:
lstrcpyA:
		mov	edx, [esp+4]
		mov	ecx, [esp+8]

lstrcpy00:
		mov	al, [ecx]
		inc	ecx
		mov	[edx], al
		inc	edx
		test	al, al
		jnz	short lstrcpy00

		mov	eax, [esp+4]
		retn	8

; ############################################################################

lstrcpyn:
lstrcpynA:
		push	ebx
		mov	edx, [esp+8]
		mov	ecx, [esp+12]
		mov	ebx, [esp+16]
		sub	eax, eax
		dec	ebx
		js	short lstrcpyn02

		jz	short lstrcpyn01

lstrcpyn00:
		mov	al, [ecx]
		inc	ecx
		mov	[edx], al
		inc	edx
		dec	ebx
		jnz	short lstrcpyn00

lstrcpyn01:
		mov	[edx], bl
		mov	eax, [esp+8]

lstrcpyn02:
		pop	ebx
		retn	12

; ############################################################################

lstrcat:
lstrcatA:
		push	dword ptr [esp+4]
		call	lstrlen
		add	eax, [esp+4]
		push	dword ptr [esp+8]
		push	eax
		call	lstrcpy
		mov	eax, [esp+4]
		retn	8

; ############################################################################

; Not entirely correct ( should be word sort thingy )

lstrcmp:
lstrcmpA:
		mov	edx, [esp+4]
		mov	ecx, [esp+8]
		sub	eax, eax

lstrcmp00:
		mov	al, [edx]
		sub	al, [ecx]
		sbb	ah, ah
		cmp	byte ptr [edx], 0
		jz	short lstrcmp01

		cmp	byte ptr [ecx], 0
		jz	short lstrcmp01

		inc	edx
		inc	ecx
		test	eax, eax
		jz	short lstrcmp00

lstrcmp01:
		movsx	eax, ax
		retn	8

; ############################################################################

lstrcmpi:
lstrcmpiA:
		mov	edx, [esp+4]
		mov	ecx, [esp+8]
		sub	eax, eax

lstrcmpi00:
		mov	al, [edx]
		cmp	al, 'A'

		jc	short lstrcmpi001
		cmp	al, 'Z'

		ja	short lstrcmpi001
		or	al, 20h

lstrcmpi001:
		mov	ah, [ecx]
		cmp	ah, 'A'
		jc	short lstrcmpi002

		cmp	ah, 'Z'
		ja	short lstrcmpi002

		or	ah, 20h

lstrcmpi002:
		sub	al, ah
		sbb	ah, ah
		cmp	byte ptr [edx], 0
		jz	short lstrcmpi01

		cmp	byte ptr [ecx], 0
		jz	short lstrcmpi01

		inc	edx
		inc	ecx
		test	eax, eax
		jz	short lstrcmpi00

lstrcmpi01:
		movsx	eax, ax
		retn	8

; ############################################################################
;
; ... yet some legacy file functions
;
; ############################################################################

_hread:
_lread:
		push	ebx
		mov	ebx, [esp+8]
		HANDLE_W2D ebx
		mov	edx, [esp+12]
		mov	ecx, [esp+16]
		mov	eax, 3F00h
		int	21h
		sbb	ecx, ecx
		mov	LastError, ecx
		and	LastError, eax
		or	eax, ecx
		pop	ebx
		retn	12

; ############################################################################

_hwrite:
_lwrite:
		push	ebx
		mov	ebx, [esp+8]
		HANDLE_W2D ebx
		mov	edx, [esp+12]
		mov	ecx, [esp+16]
		mov	eax, 4000h
		int	21h
		sbb	ecx, ecx
		mov	LastError, ecx
		and	LastError, eax
		or	eax, ecx
		pop	ebx
		retn	12

; ############################################################################

_lcreat:
		mov	edx, [esp+4]
		mov	ecx, [esp+8]
		mov	ah, 3Ch
		int	21h
		sbb	ecx, ecx
		jc	cNoFix

		HANDLE_D2W eax

cNoFix:
		mov	LastError, ecx
		and	LastError, eax
		or	eax, ecx
		retn	8

; ############################################################################

_lopen:
		mov	edx, [esp+4]
		mov	eax, [esp+8]
		mov	ah, 3Dh
		int	21h
		sbb	ecx, ecx
		jc	oNoFix

		HANDLE_D2W eax

oNoFix:
		mov	LastError, ecx
		and	LastError, eax
		or	eax, ecx
		retn	8

; ############################################################################

_lclose:
		push	ebx
		mov	ebx, [esp+8]
		HANDLE_W2D ebx
		mov	eax, 3E00h
		int	21h
		sbb	ecx, ecx
		and	eax, ecx
		mov	LastError, eax
		or	eax, ecx
		pop	ebx
		retn	4

; ############################################################################

_llseek:
		push	ebx
		mov	ebx, [esp +  8]
		HANDLE_W2D ebx
		mov	edx, [esp + 12]
		mov	eax, [esp + 16]
		shld	ecx, edx, 16
		mov	ah, 42h
		int	21h
		sbb	ecx, ecx
;
; 2do: Set LastError
;
		shl	eax, 16
		shrd	eax, edx, 16
		or	eax, ecx
		pop	ebx
		retn	12

; ############################################################################

	END
