; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/deb/HELP.INC 1.2 1999/02/07 20:09:12 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: HELP.INC $
; Revision 1.2  1999/02/07 20:09:12  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:14:04  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
OnKeyF1		proc	near
		mov	ecx,2000
		mov	eax,70007000h
                mov	edx,0b8000h
@@f1cls:
		mov	gs:[edx],eax
		add	edx,4
		loop	@@f1cls
		push	24
		push	0b8000h
		mov	ecx,offset helpscreen
@@f1print1:
		mov	edx,[esp]
@@f1print2:
		mov	al,[ecx]
		mov	gs:[edx],al
		inc	edx
		inc	edx
		inc	ecx
		test	al,al
		jnz	@@f1print2
		mov	eax,ScreenX
		add	eax,eax
		add	[esp],eax
		dec	dword ptr [esp+4]
		jnz	@@f1print1
		add	esp,8
		sub	eax,eax
		int	16h
		call	DaUpdateView
		call	UpdateAll
		ret
OnKeyF1		endp
