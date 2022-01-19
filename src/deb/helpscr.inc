; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/deb/HELPSCR.INC 1.2 1999/02/07 20:05:11 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: HELPSCR.INC $
; Revision 1.2  1999/02/07 20:05:11  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:21:29  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
helpscreen	label	near
db '              ********   THANKS FOR PRESSING F1 !   ********',0
db 0
db ' Global keys: F1 - This                       ALT F5 - Show user screen',0
db '              F7 - Trace                      TAB    - Next window',0
db '              F8 - Step                       SFT TAB- Previous window',0
db '              F9 - Run                        ALT X  - Exit',0
db 0
db ' Disassembly: UP/DOWN   - Move cursor         CTRL O - Goto EIP',0
db '              PGUP/DOWN - Page up/down        CTRL N - Set EIP to cursor',0
db '              F2        - Toggle Breakpoint   CTRL G - Goto XXXXXXXX',0
db '              F4        - Execute to cursor',0
db 0
db ' Registers+ : UP/DOWN   - Move cursor         RETURN - Enter value (registers)',0
db '   Flags      HOME/END  - First/Last item              Toggle flag (flags)',0
db 0
db ' Memory dump: ARROW KEYS- Navigate            ALT C  - Goto CS:0',0
db '              PGUP/DOWN - Page up/down        ALT D  - Goto DS:0',0
db '              RETURN    - Enter data byte     ALT E  - Goto ES:0',0
db '              CTRL G    - Goto XXXXXXXX       ALT F  - Goto FS:0',0
db '              ALT 0     - Goto lin. 00000000  ALT G  - Goto GS:0',0
db 0
db ' Stack view : UP/DOWN   - Move cursor         CTRL O - Goto SS:ESP',0
db '              PGUP/DOWN - Page up/down        CTRL G - Goto SS:XXXXXXXX',0
db '              RETURN    - Enter data dword',0
