; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/deb/INBOX.INC 1.2 1999/02/07 20:10:11 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: INBOX.INC $
; Revision 1.2  1999/02/07 20:10:11  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:14:05  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
InputBox8	proc	near

IbColor		equ	7fh	; test

; int _cdecl InputBox(int dx,char *str)
; returns 0 if ESC has been pressed, 1 if RETURN pressed

		; get coordinates to draw (dy = numStrings + 2)
		; x = (ScreenX - dx) / 2
		; y = (ScreenY - dy) / 2

		mov	eax,[esp+4]	; dx
		mov	edx,4
		push	IbColor
		push	4
		push	eax
		neg	edx
		neg	eax
		add	edx,ScreenY
		add	eax,ScreenX
		shr	edx,1
		shr	eax,1
		push	edx
		push	eax
		call	FillColor
		mov	dword ptr [esp+16],0
		call	FillChar

		; leave the stuff on stack

		mov	eax,[esp]	; x
		mov	edx,[esp+4]	; y
		inc	eax		; x of string
		inc	edx		; y of string
		push	dword ptr [esp+28]
		push	edx		; y
		push	eax		; x

;junk
;mov cs:[0],al

		call	FillString
		add	esp,12		; remove locals
		call	SwapRectangle	; on screen
		mov	edx,[esp+4]	; y
		add	edx,2		; y for input
		mov	eax,[esp+8]	; dx
		sub	eax,8		; length
		shr	eax,1		; center
		add	eax,[esp]	; x for input
		push	edx
		push	eax
		call	InputDword
		pop	edx
		pop	edx
		jc	@@ib8error
		mov	[esp+16],eax
		call	SetRectangle
		add	esp,16
		pop	eax
		clc
		ret
@@ib8error:
		call	SetRectangle
		add	esp,20		; remove locals
		stc
		ret
InputBox8	endp
