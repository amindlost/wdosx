; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/DEB/nfields.inc 1.2 1999/02/07 20:06:01 MikeT Exp MikeT $
;
; ----------------------------------------------------------------------------
;
; $Log: nfields.inc $
; Revision 1.2  1999/02/07 20:06:01  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:20:20  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; static numeric fields

FieldEax	NumField	<RegisterX,0,0,offset StrEax,0,offset Deax,offset Update8,offset Input8>
FieldEbx	NumField	<RegisterX,1,0,offset StrEbx,0,offset Debx,offset Update8,offset Input8>
FieldEcx	NumField	<RegisterX,2,0,offset StrEcx,0,offset Decx,offset Update8,offset Input8>
FieldEdx	NumField	<RegisterX,3,0,offset StrEdx,0,offset Dedx,offset Update8,offset Input8>
FieldEsi	NumField	<RegisterX,4,0,offset StrEsi,0,offset Desi,offset Update8,offset Input8>
FieldEdi	NumField	<RegisterX,5,0,offset StrEdi,0,offset Dedi,offset Update8,offset Input8>
FieldEbp	NumField	<RegisterX,6,0,offset StrEbp,0,offset Debp,offset Update8,offset Input8>
FieldEsp	NumField	<RegisterX,7,0,offset StrEsp,0,offset Desp,offset Update8,offset Input8>

FieldCs		NumField	<RegisterX+2,8,0,offset StrCs,0,offset Dcs,offset Update4,offset Input4>
FieldDs		NumField	<RegisterX+2,9,0,offset StrDs,0,offset Dds,offset Update4,offset Input4>
FieldEs		NumField	<RegisterX+2,10,0,offset StrEs,0,offset Des,offset Update4,offset Input4>
FieldFs		NumField	<RegisterX+2,11,0,offset StrFs,0,offset Dfs,offset Update4,offset Input4>
FieldGs		NumField	<RegisterX+2,12,0,offset StrGs,0,offset Dgs,offset Update4,offset Input4>
FieldSs		NumField	<RegisterX+2,13,0,offset StrSs,0,offset Dss,offset Update4,offset Input4>

; display list for register window

DlRegisters	dd	offset FieldEax
		dd	offset FieldEbx
		dd	offset FieldEcx
		dd	offset FieldEdx
		dd	offset FieldEsi
		dd	offset FieldEdi
		dd	offset FieldEbp
		dd	offset FieldEsp

		dd	offset FieldCs
		dd	offset FieldDs
		dd	offset FieldEs
		dd	offset FieldFs
		dd	offset FieldGs
		dd	offset FieldSs

		dd	0

; display list for flags window

DlFlags		label	near
		dw	FlagMaskCF,'=C'
		dw	FlagMaskPF,'=P'
		dw	FlagMaskAF,'=A'
		dw	FlagMaskZF,'=Z'
		dw	FlagMaskSF,'=S'
		dw	FlagMaskDF,'=D'
		dw	FlagMaskOF,'=O'
		dd	0

