; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/tools/general.inc 1.1 1999/02/07 18:39:54 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: general.inc $
; Revision 1.1  1999/02/07 18:39:54  MikeT
; Initial check in.
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
