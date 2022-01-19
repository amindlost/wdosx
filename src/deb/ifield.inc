; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/deb/IFIELD.INC 1.2 1999/02/07 20:09:39 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: IFIELD.INC $
; Revision 1.2  1999/02/07 20:09:39  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:14:05  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; an input field

InputField	proc	near
; int _cdecl InputField (char* screen,int size)
; returns 0 if leaved with ESC, 1 if leaved with RETURN

		push	ebp
		mov	ebp,esp
		sub	esp,8
		mov	eax,[ebp+12]
		add	eax,eax
		add	eax,[ebp+8]
		mov	[esp+4],eax	; store end address
@@IfClear:
		mov	ecx,[ebp+12]	; size
		mov	edx,[ebp+8]	; start
		mov	[esp],edx	; cursor
		mov	eax,0700h	; color + zero character
@@IfClLoop:
		mov	gs:[edx],ax
		add	edx,2
		loop	@@IfClLoop
@@IfLoop:
		; set cursor
		mov	edx,[esp]
		mov	byte ptr gs:[edx+1],6fh

		; get input

		sub	eax,eax
		int	16h
		cmp	al,20h
		jc	@@IfIsCtl	; Is control code?
		cmp	byte ptr gs:[edx],0
		jz	@@IfWrite

		; move forward, not very efficient, but who cares?

		mov	edx,[esp+4]	; this one must be left blank
@@IfC1Loop:
		sub	edx,2
		cmp	edx,[esp]
		jz	@@IfWrite1
		mov	cl,gs:[edx-2]
		mov	gs:[edx],cl
		jmp	@@IfC1Loop
@@IfWrite1:
		mov	gs:[edx],al	; store ASCII
		jmp	@@IfLoop

@@IfWrite:
		mov	gs:[edx],al	; store ASCII

		add	edx,2

		cmp	edx,[esp+4]	; end of line?
		jnc	@@IfLoop	; don't fix cursor if so

		mov	edx,[esp]
		mov	byte ptr gs:[edx+1],7

		add	dword ptr [esp],2
		jmp	@@IfLoop

@@IfIsCtl:
		; edx = cursor
		; eax = key code

		cmp	eax,Key_Left
		jnz	@@If01

		cmp	edx,[ebp+8]
		jna	@@IfLoop

		mov	edx,[esp]
		mov	byte ptr gs:[edx+1],7

		sub	dword ptr [esp],2
		jmp	@@IfLoop

@@If01:
		cmp	eax,Key_Right
		jnz	@@If02

		mov	eax,[esp+4]
		sub	eax,2
		cmp	edx,eax
		jnc	@@IfLoop

		cmp	byte ptr gs:[edx],0
		jz	@@IfLoop

		mov	edx,[esp]
		mov	byte ptr gs:[edx+1],7

		add	dword ptr [esp],2
		jmp	@@IfLoop

@@If02:
		cmp	eax,Key_Delete
		jnz	@@If03

		cmp	byte ptr gs:[edx],0
@@Ifdel1:
		mov	byte ptr gs:[edx],0
		jz	@@IfLoop

		mov	ecx,[esp+4]
		sub	ecx,2
@@IfC2Loop:
		cmp	edx,ecx
		jz	@@Ifdel1
		mov	al,gs:[edx+2]
		mov	gs:[edx],al
		add	edx,2
		jmp	@@IfC2Loop

@@If03:
		cmp	eax,Key_Bspace
		jnz	@@If04

		cmp	edx,[ebp+8]
		jna	@@IfLoop
@@IfBs00:
		mov	al,gs:[edx]
		mov	gs:[edx-2],al
		add	edx,2
		cmp	edx,[esp+4]
		jnz	@@IfBs00

		mov	byte ptr gs:[edx-2],0

		mov	edx,[esp]
		mov	byte ptr gs:[edx+1],7

		sub	dword ptr [esp],2
		jmp	@@IfLoop

@@If04:
		cmp	eax,Key_Home
		jnz	@@If05

		mov	edx,[esp]
		mov	byte ptr gs:[edx+1],7

		mov	eax,[ebp+8]
		mov	[esp],eax
		jmp	@@IfLoop

@@If05:
		cmp	eax,Key_End
		jnz	@@If06

		mov	edx,[esp]
		mov	byte ptr gs:[edx+1],7

@@IfEnd00:
		mov	[esp],edx
		cmp	byte ptr gs:[edx],0
		jz	@@IfLoop
		add	edx,2
		cmp	edx,[esp+4]
		jc	@@IfEnd00
		sub	edx,2
		mov	[esp],edx
		jmp	@@IfLoop

@@If06:

		cmp	ah,1
		jz	@@IfExit0
		cmp	al,13
		mov	eax,1
		jz	@@IfExit
		jmp	@@IfLoop
@@IfExit0:	
		sub	eax,eax	
@@IfExit:
		mov	esp,ebp
		pop	ebp
		ret
InputField	endp
