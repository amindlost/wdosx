; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/deb/KEYBOARD.ASM 1.2 1999/02/07 20:05:33 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: KEYBOARD.ASM $
; Revision 1.2  1999/02/07 20:05:33  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:16:40  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
SetUserKeyb	proc	near
		push	ebx
		mov	ebx,Pic1Map
		inc	ebx
		cmp	bl,9
		jz	@@suk00
		mov	eax,204h
		int	31h
		mov	[ebx*8+offset DebugInts],edx
		mov	[ebx*8+offset DebugInts+4],ecx
		mov	edx,[ebx*8+offset UserInts]
		mov	ecx,[ebx*8+offset UserInts+4]
		mov	eax,205h
		int	31h
@@suk00:

		mov	bl,9
		mov	eax,204h
		int	31h
		mov	[ebx*8+offset DebugInts],edx
		mov	[ebx*8+offset DebugInts+4],ecx
		mov	edx,[ebx*8+offset UserInts]
		mov	ecx,[ebx*8+offset UserInts+4]
		mov	eax,205h
		int	31h

		pop	ebx
		ret
SetUserKeyb	endp


SetDebKeyb	proc	near
		push	ebx
		mov	ebx,Pic1Map
		inc	ebx
		cmp	ebx,9
		jz	@@sdk00
		mov	eax,204h
		int	31h
		mov	[ebx*8+offset UserInts],edx
		mov	[ebx*8+offset UserInts+4],ecx
		mov	edx,[ebx*8+offset DebugInts]
		mov	ecx,[ebx*8+offset DebugInts+4]
		mov	eax,205h
		int	31h
@@sdk00:

		mov	bl,9

		mov	eax,204h
		int	31h
		mov	[ebx*8+offset UserInts],edx
		mov	[ebx*8+offset UserInts+4],ecx
		mov	edx,[ebx*8+offset DebugInts]
		mov	ecx,[ebx*8+offset DebugInts+4]
		mov	eax,205h
		int	31h

		pop	ebx
		ret

SetDebKeyb	endp