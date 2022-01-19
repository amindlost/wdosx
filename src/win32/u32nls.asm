; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/win32/U32NLS.ASM 1.2 1999/05/14 00:42:33 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: U32NLS.ASM $
; Revision 1.2  1999/05/14 00:42:33  MikeT
; Moved GenricCP into uninitialized storage where it should have ended up in
; the first place.
;
; Revision 1.1  1999/03/06 23:21:45  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
;
; Limited UNICODE support
;
.386
.model flat

INSTALL_CODEPAGE MACRO ThisCP
   clabel CATSTR <CodePage>, <ThisCP>
   EXTRN clabel: WORD
   dd	ThisCP, OFFSET clabel
ENDM

.data

	ALIGN 4
;-----------------------------------------------------------------------------
; This is the location where you add / remove support for particular codepages
;
cpDirectory LABEL DWORD
	INSTALL_CODEPAGE 847	; Thai
	INSTALL_CODEPAGE 866	; Cyrillic II
	INSTALL_CODEPAGE 857	; Turkish
	INSTALL_CODEPAGE 852	; Central Europe
	INSTALL_CODEPAGE 775	; Baltic
	INSTALL_CODEPAGE 720	; Arabic
	INSTALL_CODEPAGE 932	; Japanese Shift-JIS
	INSTALL_CODEPAGE 1258	; Vietnamese
	INSTALL_CODEPAGE 437	; US
	INSTALL_CODEPAGE 737	; Greek
	INSTALL_CODEPAGE 850	; Western Europe
	INSTALL_CODEPAGE 855	; Cyrillic
	INSTALL_CODEPAGE 862	; Hebrew
	dd 	-1		; end marker
;
;----------------------------------------------------------------------------


.code

	EXTRN		GetOEMCP: NEAR

;+---------------------------------------------------------------------------
; nlsCharToOEMA - character conversion
;
;	In:  AL =  lower byte of double byte character
;
;       Out: EAX = OEM single byte character
;
	PUBLIC	nlsCharToOEMA
nlsCharToOEMA PROC NEAR
	movzx	eax, al
	push	edx
	push	ecx
	mov	edx, pCodePage
	mov	ecx, 256

@@C2OA:
	cmp	al, [edx]
	je	@@C2OAfound

	add	edx, 2
	loop	@@C2OA

	jmp	@@C2OAexit

@@C2OAfound:
	mov	eax, edx
	sub	eax, pCodePage
	shr	eax, 1

@@C2OAexit:
	pop	ecx
	pop	edx
	ret
nlsCharToOEMA ENDP

;+---------------------------------------------------------------------------
; nlsCharToOEMW - character conversion
;
;	In:  AX =  double byte character
;
;       Out: EAX = OEM single byte character
;
	PUBLIC	nlsCharToOEMW
nlsCharToOEMW PROC NEAR
	movzx	eax, ax
	push	edx
	push	ecx
	mov	edx, pCodePage
	mov	ecx, 256

@@C2OW:
	cmp	ax, [edx]
	je	@@C2OWfound

	add	edx, 2
	loop	@@C2OW

	jmp	@@C2OWexit

@@C2OWfound:
	mov	eax, edx
	sub	eax, pCodePage
	shr	eax, 1

@@C2OWexit:
	sub	ah, ah
	pop	ecx
	pop	edx
	ret
nlsCharToOEMW ENDP

;+---------------------------------------------------------------------------
; nlsOEMToChar - character conversion
;
;	In:  AL =  OEM character
;
;       Out: EAX = double byte character
;
	PUBLIC	nlsOEMToChar
nlsOEMToChar PROC NEAR
	push	edx
	mov	edx, pCOdePage
	and	eax, 0FFh
	mov	ax, [edx + eax * 2]
	pop	edx
	ret
nlsOEMToChar ENDP


;+---------------------------------------------------------------------------
; initU32NLS - initialize codepages and stuff
;
	PUBLIC	initU32NLS
initU32NLS PROC NEAR
	pushad
	mov	edx, OFFSET genericCP
	sub	eax, eax

@@initGCP:
	mov	[edx], ax
	inc	edx
	inc	edx
	inc	al
	jnz	@@initGCP
;
; At this point the CountryInfo structure is filled with the most appropriate
; values. For the given codepage, try to figure out whether we support it.
;
	call	GetOEMCP
	sub	edx, edx

@@findCP:
	cmp	cpDirectory[edx], -1
	je	@@cpErr

	cmp	eax, cpDirectory[edx]
	je	@@cpFound

	add	edx, 8
	jmp	@@findCP

@@cpFound:
	mov	eax, cpDirectory[edx + 4]
	mov	pCodePage, eax

@@cpErr:
;
; Later we want to build a reverse lookup structure here. However, for testing
; purposes the slow reverse conversion should be o.k.
;
	popad
	ret
initU32NLS ENDP

.data
		ALIGN	4
pCodePage	dd	OFFSET genericCP

.data?
		ALIGN 2
genericCP	LABEL WORD
		dw	256 dup (?)
END
