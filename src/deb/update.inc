; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/deb/UPDATE.INC 1.2 1999/02/07 20:07:18 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: UPDATE.INC $
; Revision 1.2  1999/02/07 20:07:18  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:14:06  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
Update4		proc
; void Update4(NumField *This)
; does NOT diplay anything!

		; display field name

		mov	edx,[esp+4]	; get "this"

		push	FieldName[edx]
		push	LocY[edx]
		push	LocX[edx]
		call	FillString
		add	esp,12

		; convert content

		mov	edx,[esp+4]	; get "this"

		mov	eax,DepValue[edx]
		mov	eax,[eax]
		push	eax
		call	Hex4ToStr
		mov	byte ptr [offset DummyBuffer+4],' '
		pop	eax
		lar	eax,eax
		jnz	@@u4notASel
		mov	dword ptr [offset DummyBuffer+5],'ATAD'
		mov	dword ptr [offset DummyBuffer+9],'61'
		test	eax,800h
		jz	@@u4seldata
		mov	dword ptr [offset DummyBuffer+5],'EDOC'
@@u4seldata:
		test	eax,400000h
		jz	@@u4selDone
		mov	dword ptr [offset DummyBuffer+9],'23'
		jmp	@@u4selDone
@@u4notASel:
		mov	dword ptr [offset DummyBuffer+5],'!!!'
@@u4selDone:
		; DummyBuffer filled

		mov	edx,[esp+4]	; get "this"
		push	offset DummyBuffer
		push	LocY[edx]
		mov	eax,LocX[edx]		
		add	eax,3		; add length of string ( dirty!)
		push	eax
		call	FillString
		add	esp,12
		
		; now update color

		mov	edx,[esp+4]	; get "this"
		push	Color[edx]
		mov	eax,Value[edx]
		mov	ecx,DepValue[edx]
		mov	ecx,[ecx]
		and	eax,0ffffh
		and	ecx,0ffffh
		cmp	eax,ecx
		jz	@@u4color
		or	byte ptr [esp],0fh	; highlight on modification
@@u4color:
		push	1
		push	4
		push	LocY[edx]
		mov	eax,LocX[edx]
		add	eax,3
		push	eax
		call	FillColor
		add	esp,20
		ret
Update4		endp

Update8		proc
; void Update8(NumField *This)
; does NOT diplay anything!

		; display field name

		mov	edx,[esp+4]	; get "this"

		push	FieldName[edx]
		push	LocY[edx]
		push	LocX[edx]
		call	FillString
		add	esp,12

		; convert content

		mov	edx,[esp+4]	; get "this"

		mov	eax,DepValue[edx]
		mov	eax,[eax]
		call	Hex8ToStr

		; DummyBuffer filled

		mov	edx,[esp+4]	; get "this"
		push	offset DummyBuffer
		push	LocY[edx]
		mov	eax,LocX[edx]		
		add	eax,4		; add length of string ( dirty!)
		push	eax
		call	FillString
		add	esp,12
		
		; now update color

		mov	edx,[esp+4]	; get "this"
		push	Color[edx]
		mov	eax,DepValue[edx]
		mov	eax,[eax]
		cmp	eax,Value[edx]
		jz	@@u8color
		or	byte ptr [esp],0fh	; highlight on modification
@@u8color:
		push	1
		push	8
		push	LocY[edx]
		mov	eax,LocX[edx]
		add	eax,4
		push	eax
		call	FillColor
		add	esp,20
		ret
Update8		endp

Str2Hex		proc	near
; not C callable, converts String in [edx] to hex value in eax
; cf set if the string does not represent a valid 32 bit hex number
; make damn sure the string is 0 terminated!

		push	ebx
		mov	ebx,8
		sub	ecx,ecx
		sub	eax,eax
@@s2hLoop:
		mov	al,[edx]
		test	al,al
		jz	@@s2herror
		sub	al,'0'
		jc	@@s2hError
		cmp	al,0ah
		jc	@@s2h00
		and	al,NOT 20h
		sub	al,7
@@s2h00:
		cmp	al,16
		cmc
		jc	@@s2hError
		shl	ecx,4
		add	ecx,eax
		inc	edx
		dec	ebx
		jnz	@@s2hLoop
		cmp	byte ptr [edx],1
		cmc
@@s2hError:
		mov	eax,ecx
		pop	ebx
		ret
Str2Hex		endp

Input2		proc	near
;void Input2(void) used for MemWindow

		push	2
		mov	eax,MemCurrentY
		add	eax,MemY
		mul	ScreenX
		add	eax,MemCurrentX
		add	eax,MemCurrentX
		add	eax,MemCurrentX
		lea	eax,[eax+eax+0b8000h]
		push	eax
		call	InputField
		pop	edx
		pop	ecx
		test	eax,eax
		jz	@@i201
		mov	byte ptr [offset DummyBuffer+ecx],0
		lea	edx,[ecx*2+edx]
@@i2loop1:
		sub	edx,2
		mov	al,gs:[edx]
		mov	[ecx-1+offset DummyBuffer],al
		loop	@@i2loop1
		mov	edx,offset DummyBuffer
		call	Str2Hex
		jc	@@i200
		mov	edx,MemCurrentY
		shl	edx,4
		add	edx,MemCurrentX
		add	edx,MemOriginLin
		call	WriteByte
		jmp	@@i201
@@i200:
		push	offset MsgInvVal
		push	3
		push	18
		call	MsgBox
		add	esp,12
@@i201:
		call	MemUpdateView
		call	DaUpdateView
		call	StackUpdateView
		ret
Input2		endp

Input4		proc	near
;void _cdecl Input4(NumField *This)

		mov	edx,[esp+4]
		push	4
		mov	eax,ScreenX
		imul	eax,LocY[edx]
		add	eax,LocX[edx]
		lea	eax,[eax+eax+0b8006h]
		push	eax
		call	InputField
		pop	edx
		pop	ecx
		test	eax,eax
		jz	@@i401
		mov	byte ptr [offset DummyBuffer+ecx],0
		lea	edx,[ecx*2+edx]
@@i4loop1:
		sub	edx,2
		mov	al,gs:[edx]
		mov	[ecx-1+offset DummyBuffer],al
		loop	@@i4loop1
		mov	edx,offset DummyBuffer
		call	Str2Hex
		jc	@@i400
		cmp	eax,10000h
		jnc	@@i400
		test	eax,eax		; allow 0 selector
		jz	@@i4nochk
		push	eax
		push	ebx
		mov	ebx,eax
		mov	eax,6
		int	31h
		pop	ebx
		pop	eax
@@i4nochk:
		jc	@@i400
		mov	edx,[esp+4]
		mov	Value[edx],eax
		mov	edx,DepValue[edx]
		mov	[edx],eax
		jmp	@@i401
@@i400:
		push	offset MsgInvSel
		push	3
		push	20
		call	MsgBox
		add	esp,12
@@i401:
		mov	edx,[esp+4]
		push	edx
		call	UpdateProc[edx]
		add	esp,4
		ret
Input4		endp

Input8		proc	near

		mov	edx,[esp+4]
		push	8
		mov	eax,ScreenX
		imul	eax,LocY[edx]
		add	eax,LocX[edx]
		lea	eax,[eax+eax+0b8008h]
		push	eax
		call	InputField
		pop	edx
		pop	ecx
		test	eax,eax
		jz	@@i801
		mov	byte ptr [offset DummyBuffer+ecx],0
		lea	edx,[ecx*2+edx]
@@i8loop1:
		sub	edx,2
		mov	al,gs:[edx]
		mov	[ecx-1+offset DummyBuffer],al
		loop	@@i8loop1
		mov	edx,offset DummyBuffer
		call	Str2Hex
		jc	@@i800
		mov	edx,[esp+4]
		mov	Value[edx],eax
		mov	edx,DepValue[edx]
		mov	[edx],eax
		jmp	@@i801
@@i800:
		push	offset MsgInvVal
		push	3
		push	18
		call	MsgBox
		add	esp,12
@@i801:
		mov	edx,[esp+4]
		push	edx
		call	UpdateProc[edx]
		add	esp,4
		ret
Input8		endp

InputDword	proc	near
; in: [esp+4]: x [esp+8]: Y
; out: cf set on error or eax=value

		mov	eax,[esp+8]
		mul	ScreenX
		add	eax,[esp+4]
		lea	eax,[eax+eax+0b8000h]
		push	8
		push	eax
		call	InputField
		pop	edx
		pop	ecx
		test	eax,eax
		jz	@@id01
		mov	byte ptr [offset DummyBuffer+ecx],0
		lea	edx,[ecx*2+edx]
@@idloop1:
		sub	edx,2
		mov	al,gs:[edx]
		mov	[ecx-1+offset DummyBuffer],al
		loop	@@idloop1
		mov	edx,offset DummyBuffer
		call	Str2Hex
		jnc	@@id00

		; check for symbol match ( not optimal )

		mov	eax,dword ptr [offset DummyBuffer]
		and	eax,0dfdfdfh
		cmp	eax,'XAE'
		jnz	@@id001
		mov	eax,Deax
		ret
@@id001:
		cmp	eax,'XBE'
		jnz	@@id002
		mov	eax,Debx
		ret
@@id002:
		cmp	eax,'XCE'
		jnz	@@id003
		mov	eax,Decx
		ret
@@id003:
		cmp	eax,'XDE'
		jnz	@@id004
		mov	eax,Dedx
		ret
@@id004:
		cmp	eax,'ISE'
		jnz	@@id005
		mov	eax,Desi
		ret
@@id005:
		cmp	eax,'IDE'
		jnz	@@id006
		mov	eax,Dedi
		ret
@@id006:
		cmp	eax,'PBE'
		jnz	@@id007
		mov	eax,Debp
		ret
@@id007:
		cmp	eax,'PSE'
		jnz	@@id008
		mov	eax,Desp
		ret
@@id008:
		push	offset MsgInvVal
		push	3
		push	18
		call	MsgBox
		add	esp,12

		; view has been destroyed

		call	DaUpdateView

		; actually not needed _right now_ but who knows later on?

		call	UpdateAll		

@@id01:
		stc
@@id00:
		ret
InputDword	endp
