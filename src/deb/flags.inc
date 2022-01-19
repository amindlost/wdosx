; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/deb/FLAGS.INC 1.2 1999/02/07 20:08:42 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: FLAGS.INC $
; Revision 1.2  1999/02/07 20:08:42  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:14:03  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
FlagMaskCF	equ	1
FlagMaskPF	equ	4
FlagMaskAF	equ	10h
FlagMaskZF	equ	40h
FlagMaskSF	equ	80h
FlagMaskDF	equ	400h
FlagMaskOF	equ	800h

FlagsX		equ	77
FlagsY		equ	0

FlagsSaveState	proc	near
		mov	eax,Deflags
		mov	SaveEflags,eax
		ret
FlagsSaveState	endp

FlagsUpdateView	proc	near
		push	0	; current y
		mov	eax,30h
		cmp	ActiveWindow,AwFlagWindow
		jz	@@Flcolor
		mov	eax,7
		mov	FlagsCurrentY,0
@@Flcolor:
		push	eax	; color
		push	7
		push	3
		push	FlagsY
		push	FlagsX
		call	FillColor
		mov	edx,offset DlFlags
		mov	ecx,FlagsX
@@FlMloop:
		mov	eax,[esp+20]
		cmp	eax,FlagsCurrentY
		jnz	@@Flcolor1
		cmp	ActiveWindow,AwFlagWindow
		jnz	@@Flcolor1
		mov	word ptr [ecx+offset ScreenColors],1f1fh
		mov	byte ptr [ecx+offset ScreenColors+2],1fh
@@FlColor1:
		mov	eax,[edx]
		ror	eax,16
		mov	word ptr [ecx+offset ScreenChars],ax
		shr	eax,16
		and	eax,0ffffh
		test	eax,Deflags
		jz	@@FlWrite0
		mov	byte ptr [ecx+offset ScreenChars+2],'1'
		test	eax,SaveEflags
		jnz	@@FlWritten
		or	byte ptr [ecx+offset ScreenColors+2],0fh
		jmp	@@FlWritten
@@FlWrite0:
		mov	byte ptr [ecx+offset ScreenChars+2],'0'
		test	eax,SaveEflags
		jz	@@FlWritten
		or	byte ptr [ecx+offset ScreenColors+2],0fh
@@FlWritten:
		add	edx,4
		add	ecx,ScreenX
		inc	dword ptr [esp+20]
		cmp	dword ptr [edx],0
		jnz	@@FlMloop

		call	SetRectangle
		add	esp,24
		ret
FlagsUpdateView	endp

FlagsOnKeyUp	proc	near
		cmp	FlagsCurrentY,0
		jz	@@flkudone
		dec	FlagsCurrentY
		call	FlagsUpdateView		
@@flkudone:
		ret
FlagsOnKeyUp	endp

FlagsOnKeyDown	proc	near
		cmp	FlagsCurrentY,6
		adc	FlagsCurrentY,0
		call	FlagsUpdateView		
		ret
FlagsOnKeyDown	endp

FlagsOnEnter	proc	near
		mov	edx,FlagsCurrentY
		movzx	eax,word ptr DlFlags[edx*4]
		xor	Deflags,eax
		xor	SaveEflags,eax
		call	FlagsUpdateView		
		ret
FlagsOnEnter	endp

FlagsOnKeyHome	proc	near
		mov	FlagsCurrentY,0
		call	FlagsUpdateView		
		ret
FlagsOnKeyHome	endp

FlagsOnKeyEnd	proc	near
		mov	FlagsCurrentY,6
		call	FlagsUpdateView		
		ret
FlagsOnKeyEnd	endp
