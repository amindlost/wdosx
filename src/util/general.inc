; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/UTIL/GENERAL.INC 1.2 1999/02/07 18:26:12 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: GENERAL.INC $
; Revision 1.2  1999/02/07 18:26:12  MikeT
; Updated copyright + some cosmetics.
;
; Revision 1.1  1998/08/03 02:53:11  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------

pushadFrame STRUC
	ediReg		dd	?
	esiReg		dd	?
	ebpReg		dd	?
	espReg		dd	?
	ebxReg		dd	?
	edxReg		dd	?
	ecxReg		dd	?
	eaxReg		dd	?
pushadFrame ENDS

FRAME_SIZE = 32
