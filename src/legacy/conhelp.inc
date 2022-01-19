; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/legacy/CONHELP.INC 1.1 1999/02/07 18:13:12 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: CONHELP.INC $
; Revision 1.1  1999/02/07 18:13:12  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
;
; Old floating segment PE code which I'm too lazy to maintain any longer or to
; even comment on. It should stay as is and eventually die.
;

;
; structure declarations
;
COORD				struc
				X			dw ?
				Y			dw ?
COORD				ends

SMALL_RECT			struc
				Left			dw ?
				Top			dw ?
				Right			dw ?
				Bottom			dw ?
SMALL_RECT			ends

CONSOLE_SCREEN_BUFFER_INFO	struc
				dwSize			COORD <>
				dwCursorPosition	COORD <>
				wAttributes		dw ?
				srWindow		SMALL_RECT <>
				dwMaximumWindowSize	COORD <>
CONSOLE_SCREEN_BUFFER_INFO	ends

;
; housekeeping data
;
align 4

ConsoleScreenBufferInfo		CONSOLE_SCREEN_BUFFER_INFO	<>
