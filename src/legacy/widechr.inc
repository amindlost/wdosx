; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/legacy/WIDECHR.INC 1.1 1999/02/07 18:15:42 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: WIDECHR.INC $
; Revision 1.1  1999/02/07 18:15:42  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
;
; Old floating segment PE code which I'm too lazy to maintain any longer or to
; even comment on. It should stay as is and eventually die.
;

; ########### No conversion done in these routines ###########################
; 2do maybe the other way around

MultiByteToWideChar:
		mov 	eax,[esp+16]
		cmp	eax,-1
		jne	@@Mbwc02
		mov	eax,[esp+12]
@@Mbwc00:
		cmp	byte ptr [eax],0
		jz	short @@Mbwc01
		inc	eax
		jmp	short @@Mbwc00
@@Mbwc01:
		sub	eax,[esp+12]
@@Mbwc02:
		test	eax,eax
		jz	short @@Mbwc04
		mov	ecx,dword ptr [esp+24]
		test	ecx,ecx
		jz	short @@Mbwc04
		cmp	ecx,eax
		jnc	@@Mbwc03
		mov	eax,ecx
@@Mbwc03:
		mov	[esp+16],eax
		push	eax
		mov	eax,[esp+12]
		mov	edx,[esp+20]
		sub	ch,ch
@@Mbwc05:
		mov	cl,[eax]
		inc	eax
		mov	word ptr [edx],cx
		add	edx,2
		dec	dword ptr [esp+16]
		jnz	@@Mbwc05
		pop	eax
		cmp	eax,[esp+24]
		jnc	@@Mbwc04
		mov	word ptr [edx],0
		inc	eax
@@Mbwc04:
		retn	24


; ############################################################################

WideCharTomultiByte:

		mov 	eax,[esp+16]
		cmp	eax,-1
		jne	@@Wcmb02
		mov	eax,[esp+12]
@@Wcmb00:
		cmp	word ptr [eax],0
		jz	short @@Wcmb01
		add	eax,2
		jmp	short @@Wcmb00
@@Wcmb01:
		shr	eax,2
		sub	eax,[esp+12]
@@Wcmb02:
		test	eax,eax
		jz	short @@Wcmb04
		mov	ecx,dword ptr [esp+24]
		test	ecx,ecx
		jz	short @@Wcmb04
		cmp	ecx,eax
		jnc	@@Wcmb03
		mov	eax,ecx
@@Wcmb03:
		mov	[esp+16],eax
		push	eax
		mov	eax,[esp+12]
		mov	edx,[esp+20]
		sub	ch,ch
@@Wcmb05:
		mov	cl,[eax]
		add	eax,2
		mov	[edx],cl
		inc	edx
		dec	dword ptr [esp+16]
		jnz	@@Wcmb05
		pop	eax
		cmp	eax,[esp+24]
		jnc	@@Wcmb04
		mov	byte ptr [edx],0
		inc	eax
@@Wcmb04:
		retn	32
