; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/WIN32/ole32.asm 1.1 2001/09/19 19:55:14 MikeT Exp MikeT $
;
; ----------------------------------------------------------------------------
;
; $Log: ole32.asm $
; Revision 1.1  2001/09/19 19:55:14  MikeT
; Initial check in.
;
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## Stubbed out OLE32.DLL stuff                                                  ##
; ############################################################################

.386
.model flat
.code

		PUBLICDLL		IIDFromString

dllMain	PROC NEAR

		mov	eax, 1
		retn	12

dllMain	ENDP

IIDFromString PROC NEAR
		int	3
IIDFromString ENDP


	END dllMain
