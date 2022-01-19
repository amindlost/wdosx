; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/deb/SEGDEF.INC 1.2 1999/02/07 20:17:09 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: SEGDEF.INC $
; Revision 1.2  1999/02/07 20:17:09  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:14:06  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
	.386P
 	.387
DGROUP	group	_DATA,_BSS
	ASSUME	cs:_TEXT,ds:DGROUP,ss:DGROUP

_TEXT SEGMENT PARA PUBLIC USE32  'CODE'
_TEXT ENDS

_DATA SEGMENT PARA PUBLIC USE32  'DATA'
_DATA ENDS

_BSS SEGMENT PARA PUBLIC USE32  'BSS'
_BSS ENDS

