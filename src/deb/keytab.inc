; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/deb/KEYTAB.INC 1.2 1999/02/07 20:11:02 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: KEYTAB.INC $
; Revision 1.2  1999/02/07 20:11:02  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:14:05  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; keys understood by the desktop

include keys.inc

KtDesktop	label	near

		dd	Key_F1,offset OnKeyF1
		dd	Key_F7,offset DaExecute
		dd	Key_F8,offset DaExecute
		dd	Key_F9,offset DaExecute
		dd	Key_Alt_F5,offset DoToggleScreen
		dd	Key_Alt_X,offset AppExit
		dd	Key_Tab,offset DtOnTab
		dd	Key_Shift_Tab,offset DtOnShiftTab
		dd	Key_Ctl_F2,offset DebReload
		dd	0

; keys understood by the disassembly window

KtDisAsm	label	near

		dd	Key_F2,offset DaToggleBp
		dd	Key_F4,offset DaExecute
		dd	Key_CtL_O,offset DaGotoOrigin
		dd	Key_Ctl_N,offset DaNewEip
		dd	Key_Up,offset DaCursorUp
		dd	Key_Down,offset DaCursorDown
		dd	Key_PgUp,offset DaPageUp
		dd	Key_PgDown,offset DaPageDown
		dd	Key_Ctl_G,offset DaOnGoto
		dd	0

; keys understood by the register window

KtRegisters	label	near
		dd	Key_Up,offset RegCursorUp
		dd	Key_Down,offset RegCursorDown
		dd	Key_Left,offset RegCursorLeft
		dd	Key_Right,offset RegCursorRight
		dd	Key_Home,offset RegCursorHome
		dd	Key_End,offset RegCursorEnd
		dd	Key_Return,offset RegOnReturn
		dd	0


; keys understood by the flags window

KtFlags		label	near
		dd	Key_Up,offset FlagsOnKeyUp
		dd	Key_Down,offset FlagsOnKeyDown
		dd	Key_Home,offset FlagsOnKeyHome
		dd	Key_End,offset FlagsOnKeyEnd
		dd	Key_Return,offset FlagsOnEnter
		dd	0

; keys understood by the memory window

KtMem		label	near
		dd	Key_PgUp,offset MemOnPgUp
		dd	Key_PgDown,offset MemOnPgDown
		dd	Key_Up,offset MemOnKeyUp
		dd	Key_Down,offset MemOnKeyDown
		dd	Key_Left,offset MemOnKeyLeft
		dd	Key_Right,offset MemOnKeyRight
		dd	Key_Return,offset Input2
		dd	Key_Alt_C,offset MemOnKeyAlt
		dd	Key_Alt_D,offset MemOnKeyAlt
		dd	Key_Alt_E,offset MemOnKeyAlt
		dd	Key_Alt_F,offset MemOnKeyAlt
		dd	Key_Alt_G,offset MemOnKeyAlt
		dd	Key_Alt_0,offset MemOnKeyAlt
		dd	Key_Ctl_G,offset MemOnGoto
		dd	0

; keys understand by the stack frame window

KtStack		label	near

		dd	Key_PgUp,offset StackOnPgUp
		dd	Key_PgDown,offset StackOnPgDown
		dd	Key_Up,offset StackOnKeyUp
		dd	Key_Down,offset StackOnKeyDown
		dd	Key_Ctl_O,offset StackToOrigin
		dd	Key_Return,offset StackOnEnter
		dd	Key_Ctl_G,offset StackOnGoto
		dd	0
