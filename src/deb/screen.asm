; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/deb/SCREEN.ASM 1.2 1999/02/07 20:16:40 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: SCREEN.ASM $
; Revision 1.2  1999/02/07 20:16:40  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:14:04  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
_IsDebugVideo	proc	near
		mov	eax,ActiveScreen
		ret
_IsDebugVideo	endp

_SetUserScreen	proc	near

		; restore user screen
		cmp	ActiveScreen,0
		jz	@@susdone

		mov	ecx,40*50
		sub	edx,edx
@@usrs00:
		mov	eax,[edx*4+offset SaveScreen]
		mov	gs:[edx*4+0b8000h],eax
		inc	edx
		loop	@@usrs00

		push	edi
		push	ebx
		mov	edi,offset DpmiReg
		mov	_ss,0
		mov	_sp,0
		mov	_bx,0
		mov	_dl,2
		mov	eax,SaveMethod
		test	al,al
		jnz	@@usrs01
		mov	al,2
@@usrs01:
		mov	_eax,eax
		mov	eax,RmCallSeg
		mov	_es,ax
		mov	_cx,7
		mov	bl,10h
		mov	eax,300h
		int	31h
		pop	ebx
		pop	edi
		mov	ActiveScreen,0
@@susdone:
		ret

_SetUserScreen	endp

_SetDebScreen	proc	near

		; save user screen

		cmp	ActiveScreen,1
		jz	@@sdsdone

		sub	ecx,ecx
		push	edi
		push	ebx
		mov	edi,offset DpmiReg
		mov	_ss,0
		mov	_sp,0
		mov	_bx,0
		mov	_dl,1
		mov	eax,SaveMethod
		test	al,al
		jnz	@@debs01
		mov	al,1
@@debs01:
		mov	_eax,eax
		mov	eax,RmCallSeg
		mov	_es,ax
		mov	_cx,7
		mov	bl,10h
		mov	eax,300h
		int	31h
		mov	eax,83h
		int	10h
		mov	edx,-1
		sub	ebx,ebx
		mov	eax,200h
		int	10h
		mov	ecx,40*50
		sub	edx,edx
		pop	ebx
		pop	edi

@@debs00:
		mov	eax,gs:[edx*4+0b8000h]
		mov	[edx*4+offset SaveScreen],eax
		inc	edx
		loop	@@debs00

		mov	ActiveScreen,1
@@sdsdone:
		ret

_SetDebScreen	endp
