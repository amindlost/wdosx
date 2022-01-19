; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/deb/MEMWIN.INC 1.2 1999/02/07 20:12:17 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: MEMWIN.INC $
; Revision 1.2  1999/02/07 20:12:17  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:14:06  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
MemX		equ	0
MemY		equ	15
MemDx		equ	64
MemDy		equ	25-MemY
MemFieldsX	equ	MemX
MemFieldsY	equ	MemY

;Layout: AAAAAAAA  00 00 00 00 00 00 00 00  ABCDEFGH

MemUpdateField	proc	near
; void MemUpdateField(int x, int y)

		mov	eax,[esp+8]
		mov	ecx,[esp+4]
		add	eax,MemFieldsY
		mul	ScreenX
		lea	edx,[ecx+eax+16*3+MemFieldsX]
		lea	ecx,[ecx*2+ecx+MemFieldsX]
		add	ecx,eax
		mov	eax,[esp+8]
		shl	eax,4
		; edx -> ASCII ecx -> NUM
		push	ecx
		add	eax,[esp+8]
		push	edx
		add	eax,MemOriginLin
		push	eax
		call	ReadByte
		add	esp,4
		pop	edx
		pop	ecx
		cmp	eax,256
		jc	@@mufGotByte
		mov	word ptr [ecx+offset ScreenChars],'??'
		ret

@@mufGotByte:
		mov	[edx+offset ScreenChars],al
		mov	ah,al
		shr	al,4
		and	ah,0fh
		cmp	al,10
		jc	@@muf1adj
		add	al,7
@@muf1adj:

		cmp	ah,10
		jc	@@muf2adj
		add	ah,7
@@muf2adj:
		add	eax,3030h
		mov	[ecx+offset ScreenChars],ax
		ret
MemUpdateField	endp

MemUpdateView	proc	near

		; calculate linear address from offset and selector

		mov	MemOriginLin,0
		cmp	MemCurrentSNum,MemSelNone
		jz	@@muvlinset
		push	ebx
		mov	ebx,MemCurrentSel
		mov	ebx,[ebx]
		mov	eax,6
		int	31h
		pop	ebx
		jnc	@@muvsetlin
		mov	MemCurrentSNum,MemSelNone
		jmp	@@muvlinset
@@muvsetlin:
		shrd	eax,edx,16
		shrd	eax,ecx,16
		mov	MemOriginLin,eax
@@muvlinset:
		mov	eax,MemCurrentOfs
		add	MemOriginLin,eax
		mov	eax,30h
		cmp	ActiveWindow,AwMemWindow
		jz	@@muvcolor
		mov	eax,7

		; reset cursor

		mov	MemCurrentX,0
		mov	MemCurrentY,0

@@muvcolor:
		push	eax
		push	MemDy
		push	MemDx
		push	MemY
		push	MemX
		call	FillColor
		mov	byte ptr [esp+16],0
		call	FillChar
		push	0
		push	0
@@muvLoop:
		call	MemUpdateField
		mov	eax,[esp]
		inc	eax
		and	eax,0fh
		mov	[esp],eax
		jnz	@@muvLoop
		inc	dword ptr [esp+4]
		cmp	dword ptr [esp+4],MemDy
		jc	@@muvLoop
		add	esp,8
		cmp	ActiveWindow,AwMemWindow
		jnz	@@muvColor2
		mov	eax,MemCurrentY
		add	eax,MemFieldsY
		mul	ScreenX
		add	eax,MemCurrentX
		add	eax,MemCurrentX
		add	eax,MemCurrentX
		mov	word ptr [eax+offset ScreenColors],1f1fh
@@muvColor2:
		push	67h
		push	1
		push	MemDx
		push	MemY-1
		push	MemX
		call	FillColor
		mov	eax,MemCurrentSNum
		dec	eax
		js	@@muvIsNone
		shl	eax,2
		lea	eax,[eax*2+eax]
		add	[esp],eax
		mov	byte ptr [esp+16],6fh
		mov	dword ptr [esp+8],11
		call	FillColor
@@muvIsNone:
		mov	byte ptr [esp+16],0h
		call	FillChar
		add	esp,20

		; here comes an actual mess, fix this ASAP
		mov	eax,MemCurrentY
		shl	eax,4
		add	eax,MemCurrentX
		add	eax,MemOriginLin
		push	eax
		push	ebx
		mov	edx,MemY-1
		imul	edx,ScreenX

		mov	dword ptr [edx+offset ScreenChars],':SC'
		push	edx
		mov	ebx,Dcs
		mov	eax,6
		int	31h
		sbb	ebx,ebx
		shrd	eax,edx,16
		shrd	eax,ecx,16
		pop	edx
		inc	ebx
		jnz	@@muvCs
		mov	dword ptr [edx+offset ScreenChars+3],'????'
		mov	dword ptr [edx+offset ScreenChars+7],'????'
		jmp	@@muvCs1
@@muvCs:
		sub	eax,[esp+4]
		neg	eax
		push	edx
		call	Hex8ToStr
		pop	edx
		mov	eax,dword ptr [offset DummyBuffer]
		mov	[edx+offset ScreenChars+3],eax
		mov	eax,dword ptr [offset DummyBuffer+4]
		mov	[edx+offset ScreenChars+7],eax
@@muvCs1:

		mov	dword ptr [edx+offset ScreenChars+12],':SD'
		push	edx
		mov	ebx,Dds
		mov	eax,6
		int	31h
		sbb	ebx,ebx
		shrd	eax,edx,16
		shrd	eax,ecx,16
		pop	edx
		inc	ebx
		jnz	@@muvDs
		mov	dword ptr [edx+offset ScreenChars+3+12],'????'
		mov	dword ptr [edx+offset ScreenChars+7+12],'????'
		jmp	@@muvDs1
@@muvDs:
		sub	eax,[esp+4]
		neg	eax
		push	edx
		call	Hex8ToStr
		pop	edx
		mov	eax,dword ptr [offset DummyBuffer]
		mov	[edx+offset ScreenChars+3+12],eax
		mov	eax,dword ptr [offset DummyBuffer+4]
		mov	[edx+offset ScreenChars+7+12],eax
@@muvDs1:

		mov	dword ptr [edx+offset ScreenChars+24],':SE'
		push	edx
		mov	ebx,Des
		mov	eax,6
		int	31h
		sbb	ebx,ebx
		shrd	eax,edx,16
		shrd	eax,ecx,16
		pop	edx
		inc	ebx
		jnz	@@muvEs
		mov	dword ptr [edx+offset ScreenChars+3+24],'????'
		mov	dword ptr [edx+offset ScreenChars+7+24],'????'
		jmp	@@muvEs1
@@muvEs:
		sub	eax,[esp+4]
		neg	eax
		push	edx
		call	Hex8ToStr
		pop	edx
		mov	eax,dword ptr [offset DummyBuffer]
		mov	[edx+offset ScreenChars+3+24],eax
		mov	eax,dword ptr [offset DummyBuffer+4]
		mov	[edx+offset ScreenChars+7+24],eax
@@muvEs1:

		mov	dword ptr [edx+offset ScreenChars+36],':SF'
		push	edx
		mov	ebx,Dfs
		mov	eax,6
		int	31h
		sbb	ebx,ebx
		shrd	eax,edx,16
		shrd	eax,ecx,16
		pop	edx
		inc	ebx
		jnz	@@muvFs
		mov	dword ptr [edx+offset ScreenChars+3+36],'????'
		mov	dword ptr [edx+offset ScreenChars+7+36],'????'
		jmp	@@muvFs1
@@muvFs:
		sub	eax,[esp+4]
		neg	eax
		push	edx
		call	Hex8ToStr
		pop	edx
		mov	eax,dword ptr [offset DummyBuffer]
		mov	[edx+offset ScreenChars+3+36],eax
		mov	eax,dword ptr [offset DummyBuffer+4]
		mov	[edx+offset ScreenChars+7+36],eax
@@muvFs1:
		mov	dword ptr [edx+offset ScreenChars+48],':SG'
		push	edx
		mov	ebx,Dgs
		mov	eax,6
		int	31h
		sbb	ebx,ebx
		shrd	eax,edx,16
		shrd	eax,ecx,16
		pop	edx
		inc	ebx
		jnz	@@muvGs
		mov	dword ptr [edx+offset ScreenChars+3+48],'????'
		mov	dword ptr [edx+offset ScreenChars+7+48],'????'
		jmp	@@muvGs1
@@muvGs:
		sub	eax,[esp+4]
		neg	eax
		push	edx
		call	Hex8ToStr
		pop	edx
		mov	eax,dword ptr [offset DummyBuffer]
		mov	[edx+offset ScreenChars+3+48],eax
		mov	eax,dword ptr [offset DummyBuffer+4]
		mov	[edx+offset ScreenChars+7+48],eax
@@muvGs1:

		pop	ebx
		pop	eax

		dec	dword ptr [esp+4]
		inc	dword ptr [esp+12]
		call	SetRectangle
		add	esp,20
		ret
MemUpdateView	endp

MemOnPgUp	proc	near
		sub	MemCurrentOfs,16*(MemDy-1)
		call	MemUpdateView
		ret
MemOnPgUp	endp

MemOnPgDown	proc	near
		add	MemCurrentOfs,16*(MemDy-1)
		call	MemUpdateView
		ret
MemOnPgDown	endp

MemOnKeyUp	proc	near
		mov	eax,MemCurrentY
		dec	eax
		js	@@mkuscroll
		mov	MemCurrentY,eax
		call	MemUpdateView
		ret
@@mkuscroll:
		sub	MemCurrentOfs,16
		call	MemUpdateView
		ret
MemOnKeyUp	endp

MemOnKeyDown	proc	near
		mov	eax,MemCurrentY
		inc	eax
		cmp	eax,MemDy
		jnc	@@mkdscroll
		mov	MemCurrentY,eax
		call	MemUpdateView
		ret
@@mkdscroll:
		add	MemCurrentOfs,16
		call	MemUpdateView
		ret
MemOnKeyDown	endp

MemOnKeyLeft	proc	near
		mov	eax,MemCurrentX
		dec	eax
		and	eax,15
		cmp	MemCurrentX,eax
		mov	MemCurrentX,eax
		sbb	eax,eax
		sbb	MemCurrentY,0
		sbb	eax,eax
		sub	MemCurrentY,eax
		and	eax,16
		sub	MemCurrentOfs,eax
		call	MemUpdateView
		ret
MemOnKeyLeft	endp

MemOnKeyRight	proc	near
		mov	eax,MemCurrentX
		inc	eax
		and	eax,15
		cmp	eax,MemCurrentX
		mov	MemCurrentX,eax
		sbb	eax,eax
		sub	MemCurrentY,eax
		cmp	MemCurrentY,MemDy
		sbb	eax,eax
		xor	eax,-1
		add	MemCurrentY,eax
		and	eax,16
		add	MemCurrentOfs,eax
		call	MemUpdateView
		ret
MemOnKeyRight	endp

MemOnKeyAlt	proc

		cmp	dword ptr [esp+4],Key_Alt_C
		jnz	@@moka01
		mov	MemCurrentSel,offset Dcs
		mov	MemCurrentSNum,MemSelCs
		jmp	@@moka00
@@moka01:

		cmp	dword ptr [esp+4],Key_Alt_D
		jnz	@@moka02
		mov	MemCurrentSel,offset Dds
		mov	MemCurrentSNum,MemSelDs
		jmp	@@moka00
@@moka02:
		cmp	dword ptr [esp+4],Key_Alt_E
		jnz	@@moka03
		mov	MemCurrentSel,offset Des
		mov	MemCurrentSNum,MemSelEs
		jmp	@@moka00
@@moka03:
		cmp	dword ptr [esp+4],Key_Alt_F
		jnz	@@moka04
		mov	MemCurrentSel,offset Dfs
		mov	MemCurrentSNum,MemSelFs
		jmp	@@moka00
@@moka04:
		cmp	dword ptr [esp+4],Key_Alt_G
		jnz	@@moka05
		mov	MemCurrentSel,offset Dgs
		mov	MemCurrentSNum,MemSelGs
		jmp	@@moka00
@@moka05:
		cmp	dword ptr [esp+4],Key_Alt_0
		jnz	@@mokaDone
		mov	MemCurrentSNum,MemSelNone
@@moka00:
		mov	MemCurrentOfs,0
		mov	MemCurrentX,0
		mov	MemCurrentY,0
		call	MemUpdateView
@@mokaDone:
		ret
MemOnKeyAlt	endp

MemOnGoto	proc
		push	offset MsgGoto
		push	12
		call	InputBox8
		pop	edx
		pop	edx
		jc	@@mog00
		mov	MemCurrentOfs,eax
		mov	MemCurrentY,0
		mov	MemCurrentX,0
		call	MemUpdateView
@@mog00:
		ret
MemOnGoto	endp
