; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/kernel/leheader.inc 1.2 1999/02/07 17:36:16 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: leheader.inc $
; Revision 1.2  1999/02/07 17:36:16  MikeT
; Updated copyright + some cosmetics. No code changes.
;
; Revision 1.1  1998/10/01 19:13:51  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
; LE executable loader
; Structure declarations
;
LEHeader	struc

LESignature	dd	?	; must be 0x454C since order is little endian
LEFormatLevel	dd	?	; not really needed
LECpuType	dw	?
LETargetSystem	dw	?	; should be 01 (OS/2)
LEModuleVersion	dd	?	; who cares...
LEModuleType	dd	?	; Must be flat
LENumberPages	dd	?
LEEntrySection	dd	?
LEEntryOffset	dd	?
LEStackSection	dd	?
LEInitialESP	dd	?
LEPageSize	dd	?
LEBytesLastPage	dd	?
LEFixupSize	dd	?
LEFixupChecks	dd	?
LELoaderSize	dd	?
LELoaderChecks	dd	?
LEObjectTable	dd	?
LEObjectEntries	dd	?
LEObjectPMTable	dd	?
LEIterateData	dd	?
LEResourceTable	dd	?
LEResources	dd	?
LEResNamesTable	dd	?
LEEntryTable	dd	?
LEModuleDirTab	dd	?
LEModuleDirs	dd	?
LEFixupPageTab	dd	?
LEFixupRecords	dd	?
LEWeDontNeed	dd	3 dup (?)	; getting bored
LEPPchecksumTab	dd	?
LEDataPages	dd	?
LEPreloadPages	dd	?
LEWeDontNeed2	dd	3 dup (?)
LEAutoData	dd	?
LEDebugStart	dd	?
LEDebugSize	dd	?
LEPrelInstPages	dd	?
LEDemdInstPages	dd	?
LEExtraHeap	dd	?
LEReserved	dd	3 dup (?)

ends

ObjectTable	struc

OTVirtualSize	dd	?
OTRelocBase	dd	?
OTObjectFlags	dd	?
OTPageMapIndex	dd	?
OTPageMapSize	dd	?
OTReserved	dd	?

ends

ObjectPMTable	struc

OPMTUnknown	db	?
OPMTFixupTabIdx	dw	?	; big endian!
OPMTType	db	?	; 0 = no reloc 3 = reloc

ends

;Fixup type equates

ModSingle	equ	1000h
ModMultiple	equ	3000h

;only valid types listed here

ByteOffset	equ	0
WordOffset	equ	5
DwordOffset	equ	7
RelativeJMP	equ	8

OrdinalIsByte	equ	80h
OrdinalIs16	equ	40h
AddADword	equ	20h
SizeOverride	equ	10h
AddToDest	equ	4


;Single internal fixup

_FixupRecord	struc

FRType		dw	?	;only 6 and 7 supported
FROffset	dw	?
FRObject	db	?
FRItem		dw	?

ends



