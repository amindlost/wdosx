; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/legacy/W32STRUC.INC 1.1 1999/02/07 18:15:28 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: W32STRUC.INC $
; Revision 1.1  1999/02/07 18:15:28  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
;
; Old floating segment PE code which I'm too lazy to maintain any longer or to
; even comment on. It should stay as is and eventually die.
;

memorystatus	struc
dwLength	dd	?	; sizeof(memorystatus) 
dwMemoryLoad	dd	?	; percent of memory in use 
dwTotalPhys	dd	?	; bytes of physical memory 
dwAvailPhys	dd	?	; free physical memory bytes 
dwTotalPageFile	dd	?	; bytes of paging file 
dwAvailPageFile	dd	?	; free bytes of paging file 
dwTotalVirtual	dd	?	; user bytes of address space 
dwAvailVirtual	dd	?	; free user bytes 
memorystatus	ends

systime struc
wYear		dw	?
wMonth		dw	?
wDayOfWeek	dw	?
wDay 		dw	?
wHour 		dw	?
wMinute 	dw	?
wSecond 	dw	?
wMilliseconds	dw	?
systime	ends

time_zone_information	struc 
Bias		dd	?
StandardName	db	32 dup (?)
StandardDate	systime	<?,?,?,?,?,?,?,?>
StandardBias	dd	?
DaylightName	db	32 dup (?) 
DaylightDate	systime <?,?,?,?,?,?,?,?>
DaylightBias	dd	?
time_zone_information	ends

startupinfo	struc
cb		dd	?
lpReserved	dd	? 
lpDesktop	dd	?
lpTitle		dd	?
dwX		dd	?
dwY		dd	?
dwXSize		dd	?
dwYSize		dd	?
dwXCountChars	dd	?
dwYCountChars	dd	?
dwFillAttribute	dd	?
dwFlags		dd	?
wShowWindow	dw	?
cbReserved2	dw	?
lpReserved2	dd	?
hStdInput	dd	?
hStdOutput	dd	?
hStdError	dd	?
startupinfo	ends

blockcount	equ	16

mcb		struc
mcb_next	dd	?	;pointer to next mcb, 0 if last in chain
mcb_desc	dd	?	;descriptor flags
mcb		ends

memblock	struc
mem_block	label	dword
mem_size	dw	?
mem_start	dw	?
memblock	ends

;descriptor flags
mcb_free	equ	1

CREATE_ALWAYS	    equ   2
OPEN_EXISTING	    equ   3
OPEN_ALWAYS  	    equ   4
TRUNCATE_EXISTING   equ   5
CREATE_NEW	    equ	  1
