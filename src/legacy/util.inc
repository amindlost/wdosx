; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/legacy/UTIL.INC 1.1 1999/02/07 18:15:02 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: UTIL.INC $
; Revision 1.1  1999/02/07 18:15:02  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
;
; Old floating segment PE code which I'm too lazy to maintain any longer or to
; even comment on. It should stay as is and eventually die.
;

; ############################################################################
; ## Number display etc.                                                    ##
; ############################################################################

OutHex4		proc	near
		mov	ecx,[esp+4]
		mov	eax,30000200h
		ror	ecx,12
@@oh401:
		mov	dl,cl
		and	dl,0fh
		cmp	dl,0ah
		jc	short @@oh400
		add	dl,7
@@oh400:
		add	dl,30h
		int	21h
		rol	ecx,4
		sub	eax,10000000h
		jnc	short @@oh401
		
		retn	4
OutHex4		endp

OutHex8		proc	near
		push	dword ptr [esp+4]
		call	OutHex4
		mov	ax,word ptr [esp+6]
		push	eax
		call	OutHex4
		retn	4
OutHex8		endp

OutSel		proc	near
		push	ebx
		mov	ebx,[esp+8]
		push	ebx
		call	OutHex4
		mov	eax,6
		int	31h
		jnc	short @@os001
		push	offset ExcStrUnavail
		call	Output0String
		retn	4
@@os001:
		push	edx
		push	ecx
		push	offset ExcStrBase
		call	Output0String
		call	OutHex4
		call	OutHex4		
		push	offset ExcStrLimit
		call	Output0String
		lsl	eax,ebx
		push	eax
		call	OutHex8
		push	offset ExcStrAcc
		call	Output0String
		lar	ax,bx
		push	eax
		call	OutHex4
		pop	ebx
		retn	4
OutSel		endp

ExcStrContext	db	'WDOSX Win32 subsystem: Abort from unhandled exception at %4:%8',0dh,0ah
		db	'Context record dump:',0dh,0ah,0dh,0ah
		db	'EAX = %8  EBX = %8  ECX = %8  EDX = %8',0dh,0ah
		db	'ESI = %8  EDI = %8  EBP = %8  ESP = %8',0dh,0ah
		db	'CS = %s',0dh,0ah
		db	'DS = %s',0dh,0ah
		db	'ES = %s',0dh,0ah
		db	'FS = %s',0dh,0ah
		db	'GS = %s',0dh,0ah
		db	'SS = %s',0dh,0ah
ExcStrUnavail	db	'  N/A'
ExcStrBase	db	'  Base = ',0
ExcStrLimit	db	'  Limit = ',0
ExcStrAcc	db	'  Type/Acc = ',0
