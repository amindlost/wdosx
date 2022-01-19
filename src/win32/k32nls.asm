; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/win32/K32NLS.ASM 1.4 2000/04/11 17:45:47 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: K32NLS.ASM $
; Revision 1.4  2000/04/11 17:45:47  MikeT
; Implemented stub for IsDBCSLeadByteEx (BCC55 support).
;
; Revision 1.3  1999/03/06 23:20:40  MikeT
; Character conversion moved to u32nls.asm of user32.wdl fame.
;
; Revision 1.2  1999/03/06 20:12:47  MikeT
; Implemented basic character conversion functions.
;
; Revision 1.1  1999/03/06 18:00:53  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
;
; Limited UNICODE support
;
.386
.model flat

rmcall	STRUC
_edi    LABEL   DWORD
_di     dw      ?
        dw      ?
_esi    LABEL   DWORD
_si     dw      ?
        dw      ?
_ebp    LABEL   DWORD
_bp     dw      ?
        dw      ?
_esp    LABEL   DWORD
_spl    dw      ?
        dw      ?
_ebx    LABEL   DWORD
_bx     LABEL   WORD
_bl     db      ?
_bh     db      ?
        dw      ?
_edx    LABEL   DWORD
_dx     LABEL   WORD
_dl     db      ?
_dh     db      ?
        dw      ?
_ecx    LABEL   DWORD
_cx     LABEL   WORD
_cl     db      ?
_ch     db      ?
        dw      ?
_eax    LABEL   DWORD
_ax     LABEL   WORD
_al     db      ?
_ah     db      ?
        dw      ?
_oldesp LABEL   DWORD
_flags  dw      ?
_es     dw      ?
_oldss  LABEL   WORD
_ds     dw      ?
_fs     dw      ?
_gs     dw      ?
_ip     dw      ?
_cs     dw      ?
_sp     dw      ?
_ss     dw      ?
rmcall  ENDS


.code


;+----------------------------------------------------------------------------
; ???
;
		PUBLICDLL               GetConsoleOutputCP
		PUBLICDLL               GetACP
		PUBLICDLL               GetConsoleCP
		PUBLICDLL               GetOEMCP
		PUBLICDLL		IsDBCSLeadByteEx

GetConsoleOutputCP LABEL NEAR
GetACP LABEL NEAR
GetConsoleCP LABEL NEAR
GetOEMCP LABEL NEAR
	movzx	eax, CodePage
	retn

;+----------------------------------------------------------------------------
; Win32 - IsDBCSLeadByteEx (stub)
;
IsDBCSLeadByteEx PROC NEAR
		sub	eax, eax
		retn	8
IsDBCSLeadByteEx ENDP


;+---------------------------------------------------------------------------
; initNLS - initialize UNICODE support
;
	PUBLIC initNLS
initNLS PROC NEAR
	pushad
	sub	esp, 64
	mov	edi, esp
;
; Get a real mode transfer buffer
;
	mov	bx, 4
	mov	eax, 100h
	int	31h
	jc	initNLSexit

	lea	esi, [eax + eax]
;
; Fill in the rmcall structure
;
	mov	[edi].rmcall._ax, 6501h
	mov	[edi].rmcall._bx, -1
	mov	[edi].rmcall._dx, -1
	mov	[edi].rmcall._di, 0
	mov	[edi].rmcall._es, ax
	mov	[edi].rmcall._ss, 0
	mov	[edi].rmcall._sp, 0
	mov	[edi].rmcall._cx, 41
;
; Call DOS
;
	sub	ecx, ecx
	mov	bx, 21h
	mov	ax, 300h
	int	31h
	test	[edi].rmcall._flags, 1
	jnz	initNLSfree
;
; Copy country info into extended memory
;
	lea	esi, [esi * 8 + 3]
	cld
	mov	edi, OFFSET CountryInfo
	mov	ecx, 38
	rep	movsb

initNLSfree:
	mov	ax, 101h
	int	31h

initNLSexit:
	add	esp, 64
	popad
	ret
initNLS ENDP

.data
		ALIGN	4

CountryInfo LABEL BYTE
CountryCode	dw	1		; default = US
CodePage	dw	437		; default = US
DateFormat	dw	0 		; 0 = USA    mm dd yy
                             		; 1 = Europe dd mm yy
	                             	; 2 = Japan  yy mm dd
CurrencySymbol	db	'$', 0, 0, 0, 0	; 5 BYTES ASCIZ
ThousandsSeparator db	',', 0		; 2 BYTES ASCIZ
DecimalSeparator db	'.', 0		; 2 BYTES ASCIZ
DateSeparator 	db	'/', 0		; 2 BYTES ASCIZ
TimeSeparator 	db	':', 0		; 2 BYTES ASCIZ
CurrencyFormat	db	0
;
; bit 2 = set if currency symbol replaces decimal point
; bit 1 = number of spaces between value and currency symbol
; bit 0 = 0 if currency symbol precedes value
;         1 if currency symbol follows value
;
DigitsAfterDec	db	2		; Number of digits after decimal in
					; currency
TimeFormat	db	0		; bit 0 = 0 if 12-hour clock
					; 1 if 24-hour clock
CaseMapProc	dd	?		; @case map routine (unused)
ListSeparator	db	',', 0		; 2 BYTES ASCIZ
		db	10 dup (?)	; reserved

END
