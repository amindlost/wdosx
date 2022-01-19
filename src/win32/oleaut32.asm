; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/win32/OLEAUT32.ASM 1.4 1999/12/12 22:03:59 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: OLEAUT32.ASM $
; Revision 1.4  1999/12/12 22:03:59  MikeT
; Implemented stub for SysReAllocStringLen
;
; Revision 1.3  1999/02/07 21:12:44  MikeT
; Updated copyright.
;
; Revision 1.2  1998/09/12 23:10:43  MikeT
; Fully implement VariantClear in order to support Delphi 4
;
; Revision 1.1  1998/08/03 01:47:11  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ###########################################################################
; ## Functions dealing with variants and stuff ( oleaut32.dll )            ##
; ###########################################################################


.386
.model flat
.code

		PUBLICDLL		VariantClear
		PUBLICDLL		VariantCopy
		PUBLICDLL		VariantCopyInd
		PUBLICDLL		VariantInit
		PUBLICDLL		VariantChangeType
		PUBLICDLL		VariantChangeTypeEx
		PUBLICDLL		SysFreeString
		PUBLICDLL		SysStringLen
		PUBLICDLL		SysAllocStringLen
		PUBLICDLL		SysReAllocStringLen

dllMain PROC NEAR

		mov	eax, 1
		retn	12

dllMain ENDP

VariantClear LABEL NEAR
		mov	edx, [esp + 4]
		sub	eax, eax
		mov	[edx], eax
		mov	[edx + 4], eax
		retn	4
;
; They aren't truely supported yet, but at least there won't be errors at
; load time anymore. Again every one gets its own breakpoint so we can look
; them up in the TDUMP.
;
VariantCopy LABEL NEAR

		int	3

VariantCopyInd LABEL NEAR

		int	3

VariantInit LABEL NEAR

		int	3

VariantChangeType LABEL NEAR

		int	3

VariantChangeTypeEx LABEL NEAR

		int	3

SysFreeString LABEL NEAR

		int	3

SysStringLen LABEL NEAR

		int	3

SysAllocStringLen LABEL NEAR

		int	3

SysReAllocStringLen LABEL NEAR

		int	3

	END dllMain
