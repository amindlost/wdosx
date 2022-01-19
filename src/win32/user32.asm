; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/WIN32/user32.asm 1.16 2003/06/24 01:32:28 MikeT Exp MikeT $
;
; ----------------------------------------------------------------------------
;
; $Log: user32.asm $
; Revision 1.16  2003/06/24 01:32:28  MikeT
; Fix wsprintf as suggested by Dieter Prifling.
;
; Revision 1.15  2000/03/19 16:29:38  MikeT
; Remove GetResource and replaced reference to it by Kernel32.FindResourceA
;
; Revision 1.14  2000/03/18 19:27:37  MikeT
; Implemented CharUpperA and CharLowerA
;
; Revision 1.13  2000/03/18 18:37:58  MikeT
; Implemented stub for DestroyWindow
;
; Revision 1.12  2000/02/20 07:02:32  MikeT
; Partial implementation of wsprintfA. Seems to make BC 5.5 work.
;
; Revision 1.11  2000/01/30 17:50:00  MikeT
; Implemented CharLowerBuffA.
;
; Revision 1.10  1999/12/12 22:53:33  MikeT
; Implemented CharUpperBuffA (Thks Oleg Prokhorov)
;
; Revision 1.9  1999/11/11 20:37:04  MikeT
; Implemented CharNextA as this is supposed to make it work with Delphi 5.
;
; Revision 1.8  1999/03/07 00:30:29  MikeT
; Fixed CharToOemW to write just one byte per character.
;
; Revision 1.7  1999/03/07 00:08:01  MikeT
; Completed CharToOemBuff and OemToCharBuff A/W implementation so far.
; In any case, we only use the default code page for all translations.
;
; Revision 1.6  1999/03/06 23:19:43  MikeT
; Updated CharToOEMA/W and OEMToCHarA/W to actually use code pages. Also,
; LoadStringA does a character translation now. Yet to do this for other
; functions.
;
; Revision 1.5  1999/02/14 19:01:00  MikeT
; Added MessageBoxExA.
;
; Revision 1.4  1999/02/07 21:13:24  MikeT
; Updated copyright.
;
; Revision 1.3  1998/11/01 18:41:12  MikeT
; Implemented CharToOemBuff etc. dummy.
;
; Revision 1.2  1998/10/21 20:16:18  MikeT
; Implemented OemToCharA and CharToOem - stubs
;
; Revision 1.1  1998/08/03 01:48:32  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## Main module of User32 -> DPMI wrapper                                  ##
; ############################################################################

.386p
.model flat

include w32struc.inc

.code

		PUBLICDLL		IsCharAlphaNumericA
		PUBLICDLL		OemToCharA
		PUBLICDLL		OemToCharW
		PUBLICDLL		OemToCharBuffA
		PUBLICDLL		CharToOemBuffA
		PUBLICDLL		OemToCharBuffW
		PUBLICDLL		CharToOemBuffW
		PUBLICDLL		CharToOemA
		PUBLICDLL		CharToOemW
		PUBLICDLL		CharUpperA
		PUBLICDLL		CharLowerA
		PUBLICDLL		EnumThreadWindows
		PUBLICDLL		MessageBoxA
		PUBLICDLL		MessageBoxExA
		PUBLICDLL		GetKeyboardType
		PUBLICDLL		GetSystemMetrics
		PUBLICDLL		LoadStringA
		PUBLICDLL               CharNextA
		PUBLICDLL		CharUpperBuffA
		PUBLICDLL		CharLowerBuffA
		PUBLICDLL		DestroyWindow
		PUBLICDLL		wsprintfA


		EXTRN	initU32NLS: NEAR
		EXTRN	nlsCharToOEMA: NEAR
		EXTRN	nlsCharToOEMW: NEAR
		EXTRN	nlsOEMToChar: NEAR
		EXTRN	FindResourceA: NEAR

;+----------------------------------------------------------------------------
; DLL entry point.
;
dllMain PROC NEAR
;
; This would have been the real Win32 arguments:
;
;arg		dwHandle:   DWORD
;arg		dwReason:   DWORD
;arg		dwReserved: DWORD

		call	initU32NLS
		mov	eax, 1
		retn	12

dllMain ENDP

;++--------------------------------------------------------------------------
; Win32 - DestroyWindow
;
DestroyWindow PROC NEAR
		mov	eax, 1
		retn	4
DestroyWindow ENDP


;++--------------------------------------------------------------------------
; Win32 - CharNextA
;
CharNextA PROC NEAR
		mov	eax, [esp + 4]
		cmp	BYTE PTR [eax], 1       ; CF set if 0
		sbb	eax, -1			; Increment if [eax] != 0
		retn	4
CharNextA ENDP


EnumThreadWindows LABEL NEAR

		mov	eax, 1
		retn	12

IsCharAlphaNumericA PROC NEAR
		movzx	eax, BYTE PTR [esp + 4]
		cmp	al, '0'
		jc	ica_no

		cmp	al, '9'
		jna	ica_yes

		cmp	al, 'A'
		jc	ica_no

		cmp	al, 'Z'
		jna	ica_yes

		cmp	al, 'a'
		jc	ica_no

		cmp	al, 'z'
		jna	ica_yes

ica_no:
		sub	eax, eax
		retn	4

ica_yes:
		mov	eax, 1
		retn	4
IsCharAlphaNumericA ENDP

;++--------------------------------------------------------------------------
; Win32 - CharToOemBuffA
;
CharToOemBuffA PROC NEAR
		pushad
		mov	esi, [esp + 32 + 4]
		mov	edi, [esp + 32 + 8]
		mov	ecx, [esp + 32 + 12]
		jecxz	@@c2obAexit

@@c2obA:
		mov	al, [esi]
		inc	esi
		call	nlsCharToOEMA
		mov	[edi], al
		inc	edi
		loop	@@c2obA

@@c2obAexit:
		popad
		mov	eax, 1
		retn	12
CharToOemBuffA ENDP

;++--------------------------------------------------------------------------
; Win32 - CharToOemBuffW
;
CharToOemBuffW PROC NEAR
		pushad
		mov	esi, [esp + 32 + 4]
		mov	edi, [esp + 32 + 8]
		mov	ecx, [esp + 32 + 12]
		jecxz	@@c2obWexit

@@c2obW:
		mov	ax, [esi]
		inc	esi
		inc	esi
		call	nlsCharToOEMW
		mov	[edi], al
		inc	edi
		loop	@@c2obW

@@c2obWexit:
		popad
		mov	eax, 1
		retn	12
CharToOemBuffW ENDP

;++--------------------------------------------------------------------------
; Win32 - OemToCharBuffA
;
OemToCharBuffA PROC NEAR
		pushad
		mov	esi, [esp + 32 + 4]
		mov	edi, [esp + 32 + 8]
		mov	ecx, [esp + 32 + 12]
		jecxz	@@o2cbAexit

@@o2cbA:
		mov	al, [esi]
		inc	esi
		call	nlsOEMToCHar
		mov	[edi], al
		inc	edi
		loop	@@o2cbA

@@o2cbAexit:
		popad
		mov	eax, 1
		retn	12
OemToCharBuffA ENDP

;++--------------------------------------------------------------------------
; Win32 - OemToCharBuffW
;
OemToCharBuffW PROC NEAR
		pushad
		mov	esi, [esp + 32 + 4]
		mov	edi, [esp + 32 + 8]
		mov	ecx, [esp + 32 + 12]
		jecxz	@@o2cbWexit

@@o2cbW:
		mov	al, [esi]
		inc	esi
		call	nlsOEMToChar
		mov	[edi], ax
		inc	edi
		inc	edi
		loop	@@o2cbW

@@o2cbWexit:
		popad
		mov	eax, 1
		retn	12
OemToCharBuffW ENDP

;++--------------------------------------------------------------------------
; Win32 - OemToCharA
;
OemToCharA PROC NEAR
		mov	edx, [esp + 4]
		mov	ecx, [esp + 8]


o2caLoop:
		mov	al, [edx]
		inc	edx
		call	nlsOEMToChar
		mov	[ecx], al
		inc	ecx
		test	al, al
		jne	o2caLoop

		mov	eax, 1
		retn	8
OemToCharA ENDP


;++--------------------------------------------------------------------------
; Win32 - OemToCharW
;
OemToCharW PROC NEAR
		mov	edx, [esp + 4]
		mov	ecx, [esp + 8]

o2cwLoop:
		mov	al, [edx]
		inc	edx
		call	nlsOEMToChar
		mov	[ecx], ax
		inc	ecx
		inc	ecx
		test	al, al
		jne	o2cwLoop

		mov	eax, 1
		retn	8
OemToCharW ENDP


;++--------------------------------------------------------------------------
; Win32 - CharToOEMA
;
CharToOemA PROC NEAR
		mov	edx, [esp + 4]
		mov	ecx, [esp + 8]


c2oaLoop:
		mov	al, [edx]
		inc	edx
		call	nlsCharToOEMA
		mov	[ecx], al
		inc	ecx
		test	al, al
		jne	c2oaLoop

		mov	eax, 1
		retn	8
CharToOemA ENDP


;++--------------------------------------------------------------------------
; Win32 - CharToOemW
;
CharToOemW PROC NEAR
		mov	edx, [esp + 4]
		mov	ecx, [esp + 8]

c2owLoop:
		mov	ax, [edx]
		inc	edx
		inc	edx
		call	nlsCharToOEMW
		mov	[ecx], al
		inc	ecx
		test	al, al
		jne	c2owLoop

		mov	eax, 1
		retn	8
CharToOemW ENDP

;++--------------------------------------------------------------------------
; Win32 - CharUpperA
;
CharUpperA PROC NEAR

		pop	ecx
		pop	edx
		mov	eax, edx
		test	edx, 0FFFF0000h
		jnz	cuDoString

		cmp	dl, 'a'
		jc	cuDone

		cmp	dl, 'z'
		ja	cuDone

		add	al, 'A' - 'a'

cuDone:
		jmp	ecx

cuDoString:
		cmp	BYTE PTR [edx], 0
		je	cuDone

		cmp	BYTE PTR [edx], 'a'
		jc	cuNext
		
		cmp	BYTE PTR [edx], 'z'
		ja	cuNext

		add	BYTE PTR [edx], 'A' - 'a'

cuNext:
		inc	edx
		jmp	cuDoString

CharUpperA ENDP

;++--------------------------------------------------------------------------
; Win32 - CharLowerA
;
CharLowerA PROC NEAR

		pop	ecx
		pop	edx
		mov	eax, edx
		test	edx, 0FFFF0000h
		jnz	clDoString

		cmp	dl, 'A'
		jc	clDone

		cmp	dl, 'Z'
		ja	clDone

		add	al, 'a' - 'A'

clDone:
		jmp	ecx

clDoString:
		cmp	BYTE PTR [edx], 0
		je	clDone

		cmp	BYTE PTR [edx], 'A'
		jc	clNext
		
		cmp	BYTE PTR [edx], 'Z'
		ja	clNext

		add	BYTE PTR [edx], 'a' - 'A'

clNext:
		inc	edx
		jmp	clDoString

CharLowerA ENDP

;+----------------------------------------------------------------------------
; Win32 - CharUpperBuffA
;
CharUpperBuffA PROC NEAR
		pushad
		xor	edx, edx
		mov	ecx, [esp+8+32]
		or	ecx, ecx
		jz	@@cub2

		mov	esi, [esp+4+32]
		mov	edi, esi

@@cub0:
		mov	al, [esi]
		inc	esi
		cmp	al, 0
		jz	@@cub2

		cmp	al, 'a'
		jb	@@cub1

		cmp	al, 'z'
		ja	@@cub1

		sub	al, 'a'-'A'

@@cub1:
		mov	[edi], al
		inc	edi
		inc	edx
		dec	ecx
		jnz	@@cub0

@@cub2:
		mov	[esp+28], edx
		popad
		retn	8
CharUpperBuffA ENDP

;+----------------------------------------------------------------------------
; Win32 - CharLowerBuffA
;
CharLowerBuffA PROC NEAR
		pushad
		xor	edx, edx
		mov	ecx, [esp+8+32]
		or	ecx, ecx
		jz	@@clb2

		mov	esi, [esp+4+32]
		mov	edi, esi

@@clb0:
		mov	al, [esi]
		inc	esi
		cmp	al, 0
		jz	@@clb2

		cmp	al, 'A'
		jb	@@clb1

		cmp	al, 'Z'
		ja	@@clb1

		sub	al, 'A'-'a'

@@clb1:
		mov	[edi], al
		inc	edi
		inc	edx
		dec	ecx
		jnz	@@clb0

@@clb2:
		mov	[esp+28], edx
		popad
		retn	8
CharLowerBuffA ENDP

;+----------------------------------------------------------------------------
; Win32 - MessageBoxExA - ingore the Ex stuff
;
MessageBoxExA PROC NEAR
		pop	eax		; return address
		pop	edx		; hWnd
		mov	[esp + 12], eax
		call	MessageBoxA	
		retn
MessageBoxExA ENDP



;+----------------------------------------------------------------------------
; Win32 - MessageBoxA
;
MessageBoxA PROC NEAR

		mov	ah, 0Fh
		int	10h
		and	al, 7Fh
		cmp	al, 3
		jz	@@mbaModeOk

		mov	ax, 3
		int	10h

@@mbaModeOk:
		push	DWORD PTR [esp+12]
		call	doDosString
		mov	dl, 0Dh
		mov	ah, 2
		int	21h
		mov	dl, 0Ah
		mov	ah, 2
		int	21h
		push	DWORD PTR [esp+8]
		call	doDosString
                mov     dl, 0Dh
                mov     ah, 2
                int     21h
                mov     dl, 0Ah
                mov     ah, 2
                int     21h
		mov	eax, 1			; IDOK
		retn	16

MessageBoxA ENDP


GetKeyboardType LABEL NEAR

		mov	eax, 4
		cmp	byte ptr [esp+4], 2
		jz	short gkbt00
		mov	eax, 12

gkbt00:
		retn	4

GetSystemMetrics LABEL NEAR

		sub	eax, eax
		retn	4


;----------------------------------------------------------------------------
; Win32 - wsprintfA (partial implementation)
;
wsprintfA PROC NEAR
	pushad
	cld
	mov	esi, [esp + 8 +  32]		; source
	mov	edi, [esp + 4 +  32]		; destination
	lea	ebx, [esp + 12 + 32]		; argument list

wsp01:
	mov	ebp, OFFSET wsTable_nomofifier
	sub	eax, eax
	lodsb
	cmp	al, '%'
	je	wsp02

	test	al, al
	jne	wsp03

	stosb
	lea	eax, [edi - 1]
	sub	eax, [esp + 4 + 32]
	mov	[esp + 28], eax
	popad
	retn

wsp02:
	lodsb
	cmp	al, '%'
	jne	wsp04

wsp03:
	stosb
	jmp	wsp01

wsp07:
	lodsb

wsp04:
	cmp	al, '0'
	jb	wsp06
	cmp	al, '9'
	jbe	wsp07
wsp06:
	mov	edx, OFFSET wsTable_codes

wsp05:
	cmp	BYTE PTR [edx], 0
	je	wsp03

	cmp	al, [edx]
	lea	edx, [edx + 1]
	jne	wsp05

	sub	edx, OFFSET wsTable_codes
	jmp	DWORD PTR [ebp + edx * 4 - 4]


; -------------------------------

outChar:
	mov	al, [ebx]
	test	al, al
	jz	wsNextArg

	stosb
	jmp	wsNextArg

; -------------------------------

outWChar:
	mov	ax, [ebx]
	test	ax, ax
	jz	wsNextArg

	call	nlsCharToOEMW
	stosb
	jmp	wsNextArg

; -------------------------------

outString:
	push	esi
	mov	esi, [ebx]

wsOsNext:
	lodsb
	test	al, al
	jz	wsOsDone

	stosb
	jmp	wsOsNext

wsOsDone:
	pop	esi
	jmp	wsNextArg

; -------------------------------

outWString:
	push	esi
	mov	esi, [ebx]

wsOswNext:
	lodsw
	test	ax, ax
	jz	wsOswDone

	call	nlsCharToOEMW
	stosb
	jmp	wsOswNext

wsOswDone:
	pop	esi
	jmp	wsNextArg

; -------------------------------

outInteger:
	mov	eax, [ebx]
	test	eax, eax
	jns	outUsEAX

	neg	eax
	mov	BYTE PTR [edi], '-'
	inc	edi
	jmp	outUsEAX

; -------------------------------

outUnsigned:
	mov	eax, [ebx]

outUsEAX:
	push	ebx
	mov	ebx, 10
	call	NextDigit
	pop	ebx
	jmp	wsNextArg

; -------------------------------

outHexLower:
	mov	ebp, OFFSET htable_l	
	jmp	outHex

; -------------------------------

outHexUpper:
	mov	ebp, OFFSET htable_h

outHex:
	mov	edx, [ebx]
	mov	ecx, 8

outHexLoop:
	sub	eax, eax
	shld	eax, edx, 4
	shl	edx, 4
	mov	al, [ebp + eax]
	stosb
	loop	outHexLoop

	jmp	wsNextArg

; -------------------------------

setLTable:
	mov	ebp, OFFSET wsTable_l
	jmp	wsp07

setHTable:
	mov	ebp, OFFSET wsTable_h
	jmp	wsp07	

ignoreChar:
	jmp	wsp07	

wsNextArg:
	add	ebx, 4
	jmp	wsp01


wsTable_codes LABEL BYTE
	db	'cCsSdiuxXlh-#.'
	db	0

	align DWORD

wsTable_nomofifier LABEL DWORD
	dd	OFFSET outChar
	dd	OFFSET outWChar
	dd	OFFSET outString
	dd	OFFSET outWString
	dd	OFFSET outInteger
	dd	OFFSET outInteger
	dd	OFFSET outUnsigned
	dd	OFFSET outHexLower
	dd	OFFSET outHexUpper
	dd	OFFSET setLTable
	dd	OFFSET setHTable
	dd	OFFSET ignoreChar
	dd	OFFSET ignoreChar
	dd	OFFSET ignoreChar

wsTable_l LABEL DWORD
	dd	OFFSET outWChar
	dd	OFFSET outWChar
	dd	OFFSET outWString
	dd	OFFSET outWString
	dd	OFFSET outInteger
	dd	OFFSET outInteger
	dd	OFFSET outUnsigned
	dd	OFFSET outHexLower
	dd	OFFSET outHexUpper
	dd	OFFSET setLTable
	dd	OFFSET setHTable
	dd	OFFSET ignoreChar
	dd	OFFSET ignoreChar
	dd	OFFSET ignoreChar

wsTable_h LABEL DWORD
	dd	OFFSET outChar
	dd	OFFSET outChar
	dd	OFFSET outString
	dd	OFFSET outString
	dd	OFFSET outInteger
	dd	OFFSET outInteger
	dd	OFFSET outUnsigned
	dd	OFFSET outHexLower
	dd	OFFSET outHexUpper
	dd	OFFSET setLTable
	dd	OFFSET setHTable
	dd	OFFSET ignoreChar
	dd	OFFSET ignoreChar
	dd	OFFSET ignoreChar

htable_l LABEL BYTE
	db	'0123456789abcdef'

htable_h LABEL BYTE
	db	'0123456789ABCDEF'

wsprintfA ENDP

;----------------------------------------------------------------------------
; Helper for wsprintfA
;
NextDigit PROC NEAR

	xor	edx, edx
	div	ebx
	test	eax, eax
	push	edx
	jz	@@all

	call	NextDigit

@@all:
	pop	eax
	add	al, 30h
	stosb
	retn

NextDigit ENDP


; ############################################################################
; ## Functions dealing with resources                                       ##
; ############################################################################

LoadStringA PROC NEAR
;
; The next is guesswork:
;
		mov	eax, [esp+8]
		add	eax, 16
		push	6
		push	eax
		shr	dword ptr [esp], 4
		and	eax, 0Fh
		mov	[esp+16], eax
		push	DWORD PTR [esp+12]
		call	FindResourceA
		test	eax, eax
		jz	@@lsaError
;
; EAX -> resource data entry
; [esp+8] number of strings to skip
;
		sub	ecx, ecx
		mov	edx, [eax]
		add	edx, [esp+4]

@@lsaStrLoop:
		dec	DWORD PTR [esp+8]
		mov	cx, [edx]
		js	short @@lsaIsStr

		lea	edx, [edx+ecx*2+2]
		jmp	short @@lsaStrLoop

@@lsaIsStr:
;
; EDX -> wide char string
; ECX = size in wide chars
;
		cmp	ecx, [esp+16]
		jc	short @@lsaSizeOk

		mov	ecx, [esp+16]
		test	ecx, ecx
		jz	short @@lsaError
		dec	ecx

@@lsaSizeOk:
		jecxz	@@lsaError
		mov	[esp+16], ecx
		push	ecx		
		mov	ecx, [esp+16]

@@lsaLoop:
		add	edx, 2
		mov	ax, [edx]
		call	nlsCharToOEMW
		mov	[ecx], al
		inc	ecx
		dec	dword ptr [esp+20]
		jnz	@@lsaLoop

		mov	BYTE PTR [ecx], 0
		pop	eax
		retn	16
@@lsaError:
		sub	eax, eax
		retn	16

LoadStringA ENDP

; ############################################################################
; ## Helper functions                                                       ##
; ############################################################################


doDosString PROC NEAR

		mov	ecx, [esp+4]
		jecxz	ddstrDone
		mov	dh, 0

ddstrLoop:
		mov	dl, [ecx]
		test	dl, dl
		jnz	ddstrDoOut

ddstrDone:
		retn	4

ddstrDoOut:
		cmp	dl, 0Ah
		jne	ddstrFixDone

		cmp	dh, 0Dh
		je	ddstrFixDone

		mov	dl, 0Dh
		dec	ecx

ddstrFixDone:
		mov	dh, dl
		mov	ah, 2
		int	21h
		inc	ecx
		jmp	ddstrLoop

doDosString ENDP

END	dllMain
