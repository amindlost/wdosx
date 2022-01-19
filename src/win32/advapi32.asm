; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/win32/ADVAPI32.ASM 1.2 1999/02/07 21:09:35 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: ADVAPI32.ASM $
; Revision 1.2  1999/02/07 21:09:35  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 01:37:46  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## Stubbed out registry functions                                         ##
; ############################################################################

.386
.model flat
.code

		PUBLICDLL		RegOpenKeyA
		PUBLICDLL		RegOpenKeyExA
		PUBLICDLL		RegCloseKey
		PUBLICDLL		RegQueryValueExA

dllMain	PROC NEAR

		mov	eax, 1
		retn	12

dllMain	ENDP


RegOpenKeyA LABEL NEAR

		sub	eax, eax
		retn	12

RegOpenKeyExA LABEL NEAR

		sub	eax, eax
		retn	20

RegCloseKey LABEL NEAR

		sub	eax, eax
		retn	4

RegQueryValueExA LABEL NEAR

		or	eax, -1
		retn	24

	END dllMain
