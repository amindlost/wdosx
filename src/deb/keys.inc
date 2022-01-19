; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/deb/KEYS.INC 1.2 1999/02/07 20:10:39 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: KEYS.INC $
; Revision 1.2  1999/02/07 20:10:39  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:14:05  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; key codes as returned by BIOS

; function keys

Key_F1		equ	3b00h
Key_F2		equ	3c00h
Key_F3		equ	3d00h
Key_F4		equ	3e00h
Key_F5		equ	3f00h
Key_F6		equ	4000h
Key_F7		equ	4100h
Key_F8		equ	4200h
Key_F9		equ	4300h
Key_F10		equ	4400h


; function keys with ALT

Key_Alt_F1	equ	6800h
Key_Alt_F2	equ	6900h
Key_Alt_F3	equ	6a00h
Key_Alt_F4	equ	6b00h
Key_Alt_F5	equ	6c00h
Key_Alt_F6	equ	6d00h
Key_Alt_F7	equ	6e00h
Key_Alt_F8	equ	6f00h
Key_Alt_F9	equ	7000h
Key_Alt_F10	equ	7100h

; Cursor keys

Key_Up		equ	4800h
Key_Down	equ	5000h
Key_Left	equ	4b00h
Key_Right	equ	4d00h
Key_PgUp	equ	4900h
Key_PgDown	equ	5100h

Key_Delete	equ	5300h
Key_Bspace	equ	0e08h
Key_Home	equ	4700h
Key_End		equ	4f00h

; special keys ( unsorted )

Key_Alt_X	equ	2d00h
Key_Alt_C	equ	2e00h
Key_Alt_D	equ	2000h
Key_Alt_E	equ	1200h
Key_Alt_F	equ	2100h
Key_Alt_G	equ	2200h
Key_Alt_X	equ	2d00h
Key_Alt_0	equ	8100h

Key_Ctl_N	equ	310eh
Key_Ctl_O	equ	180fh
Key_Ctl_G	equ	2207h

Key_Ctl_F2	equ	5f00h

Key_Tab		equ	0f09h
Key_Shift_Tab	equ	0f00h
Key_Return	equ	1c0dh

