; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/deb/STACKWIN.INC 1.2 1999/02/07 20:06:30 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: STACKWIN.INC $
; Revision 1.2  1999/02/07 20:06:30  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:18:39  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
StackX		equ	64
StackY		equ	15
StackDx		equ	80-StackX
StackDy		equ	25-StackY

StackUpdateView	proc

		; calculate linear address from offset and selector

		mov	eax,30h
		cmp	ActiveWindow,AwStackWindow
		jz	@@suvcolor

		mov	eax,7

		; reset cursor

		mov	StackCurrentY,0
		mov	edx,Desp
		mov	StackCurrentOfs,edx

@@suvcolor:
		push	eax
		push	StackDy
		push	StackDx
		push	StackY
		push	StackX
		call	FillColor
		mov	byte ptr [esp+16],0
		call	FillChar

		push	ebx
		mov	ebx,Dss
		mov	eax,6
		int	31h
		pop	ebx

		; there ought to be no error...

		shrd	eax,edx,16
		shrd	eax,ecx,16

		push	eax		; base of SS:

		add	eax,StackCurrentOfs

		push	0		; counter
		push	eax		; address to read from
		mov	eax,StackY
		mul	ScreenX
		add	eax,StackX
		push	eax
@@suvLoop1:
		mov	edx,[esp]
		cmp	ActiveWindow,AwStackWindow
		jnz	@@suvcolor2
		mov	eax,[esp+8]
		cmp	eax,StackCurrentY
		jnz	@@suvcolor2
		mov	dword ptr [edx+offset ScreenColors+8],1f1f1f1fh
		mov	dword ptr [edx+offset ScreenColors+12],1f1f1f1fh
@@suvcolor2:
		mov	eax,[esp+4]
		sub	eax,[esp+12]
		cmp	eax,Desp
		jnz	@@suvNoEsp
		mov	dword ptr [edx+offset ScreenChars],'se  '
		mov	dword ptr [edx+offset ScreenChars+4],'>-p'
		jmp	@@suvNoEbp
@@suvNoEsp:
		cmp	eax,Debp
		jnz	@@suvNoEbp
		mov	dword ptr [edx+offset ScreenChars],'be  '
		mov	dword ptr [edx+offset ScreenChars+4],'>-p'
@@suvNoEbp:
		mov	eax,[esp+4]	; read address
		add	eax,3		; set to highest byte
		push	eax
		mov	ecx,8
@@suvLoop2:
		call	ReadByte
		cmp	eax,256
		jc	@@suvhb01
		mov	edx,[esp+4]
		mov	word ptr [edx+ecx+offset ScreenChars],'??'
		jmp	@@suvib01
@@suvhb01:
		mov	ah,al
		shr	al,4
		and	eax,0f0fh
		cmp	al,0ah
		sbb	dl,dl
		cmp	ah,0ah
		sbb	dh,dh
		not	edx
		and	edx,707h
		lea	eax,[eax+edx+3030h]
		mov	edx,[esp+4]
		mov	word ptr [edx+ecx+offset ScreenChars],ax
@@suvib01:
		dec	word ptr [esp]
		add	ecx,2
		cmp	ecx,16
		jc	@@suvLoop2
		add	esp,4
		add	dword ptr [esp+4],4
		pop	eax
		add	eax,ScreenX
		push	eax
		inc	dword ptr [esp+8]
		cmp	dword ptr [esp+8],StackDy
		jc	@@suvloop1

		push	6fh
		push	1
		push	StackDx
		push	(StackY-1)
		push	StackX
		call	FillColor
		mov	byte ptr [esp+16],0
		call	FillChar
		add	esp,36

		mov	eax,StackCurrentY
		shl	eax,2
		add	eax,StackCurrentOfs
		
		call	Hex8ToStr

		mov	eax,StackY-1
		mul	ScreenX
		add	eax,StackX

		mov	dword ptr [eax+offset ScreenChars+5],':SS'
		mov	edx,dword ptr [offset DummyBuffer]
		mov	dword ptr [eax+offset ScreenChars+8],edx
		mov	edx,dword ptr [offset DummyBuffer+4]
		mov	dword ptr [eax+offset ScreenChars+12],edx

		dec	dword ptr [esp+4]
		inc	dword ptr [esp+12]
		call	SetRectangle
		add	esp,20
		ret

StackUpdateView	endp

StackToOrigin	proc	near
		mov	StackCurrentY,0
		mov	eax,Desp
		mov	StackCurrentOfs,eax
		call	StackUpdateView
		ret
StackToOrigin	endp

StackOnKeyUp	proc	near
		sub	StackCurrentY,1
		sbb	eax,eax
		sub	StackcurrentY,eax
		shl	eax,2
		add	StackCurrentOfs,eax
		call	StackUpdateView
		ret
StackOnKeyUp	endp

StackOnKeyDown	proc	near
		inc	StackCurrentY
		cmp	StackCurrentY,StackDy
		cmc
		sbb	eax,eax
		add	StackcurrentY,eax
		shl	eax,2
		sub	StackCurrentOfs,eax
		call	StackUpdateView
		ret
StackOnKeyDown	endp

StackOnPgUp	proc	near
		sub	StackCurrentOfs,StackDy*4
		call	StackUpdateView
		ret
StackOnPgUp	endp

StackOnPgDown	proc	near
		add	StackCurrentOfs,StackDy*4
		call	StackUpdateView
		ret
StackOnPgDown	endp

StackOnEnter	proc	near
		mov	eax,StackCurrentY
		add	eax,StackY
		push	eax
		push	StackX+8
		call	InputDword
		pop	edx
		pop	edx
		jc	@@soe00
		push	eax
		push	ebx
		mov	ebx,Dss
		mov	eax,6
		int	31h
		pop	ebx

		shl	edx,16
		shrd	edx,ecx,16
		add	edx,StackCurrentOfs
		mov	eax,StackCurrentY
		lea	edx,[edx+eax*4]
		pop	eax
		push	eax
		call	WriteByte
		pop	eax
		jc	@@soe00
		inc	edx
		shr	eax,8
		push	eax
		call	WriteByte
		pop	eax
		jc	@@soe00
		inc	edx
		shr	eax,8
		push	eax
		call	WriteByte
		pop	eax
		jc	@@soe00
		inc	edx
		shr	eax,8
		call	WriteByte
@@soe00:
		call	StackUpdateView
		call	MemUpdateView
		call	DaUpdateView
		ret
StackOnEnter	endp

StackOnGoto	proc
		push	offset MsgGoto
		push	12
		call	InputBox8
		pop	edx
		pop	edx
		jc	@@sog00
		mov	StackCurrentOfs,eax
		mov	StackCurrentY,0
		call	StackUpdateView
@@sog00:
		ret
StackOnGoto	endp
