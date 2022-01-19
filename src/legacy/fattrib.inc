; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/legacy/FATTRIB.INC 1.1 1999/02/07 18:13:35 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: FATTRIB.INC $
; Revision 1.1  1999/02/07 18:13:35  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
;
; Old floating segment PE code which I'm too lazy to maintain any longer or to
; even comment on. It should stay as is and eventually die.
;

; DOS file attributes

DOS_FA_NORMAL			equ	0
DOS_FA_READONLY			equ	1
DOS_FA_HIDDEN			equ	2
DOS_FA_SYSTEM			equ	4
DOS_FA_VOLUME			equ	8
DOS_FA_DIRECTORY		equ	10h
DOS_FA_ARCHIVE			equ	20h
DOS_FA_SHAREABLE		equ	80h

; Win 32 file attributes that matter

FILE_ATTRIBUTE_READONLY		equ	1
FILE_ATTRIBUTE_HIDDEN		equ	2
FILE_ATTRIBUTE_SYSTEM		equ	4
FILE_ATTRIBUTE_DIRECTORY	equ	10
FILE_ATTRIBUTE_ARCHIVE		equ	20
FILE_ATTRIBUTE_NORMAL		equ	80

;-----------------------------------------------------------------------------
; These map fine to the extended Wdosx DOS API
;-----------------------------------------------------------------------------

GetFileAttributesA:
			mov	edx,[esp+4]
			mov	eax,4300h
			int	21h
			jc	@@FattrError00

			; do the translation

			mov	eax,FILE_ATTRIBUTE_NORMAL

			and	ecx,037h
			jz	short @@FattrDone00
			mov	eax,ecx
@@FattrDone00:
			retn	4

@@FattrError00:
			and	eax,0ffh
			mov	LastError,eax
			or	eax,-1
			retn	4

;-----------------------------------------------------------------------------

SetFileAttributesA:
			mov	ecx,[esp+8]
			and	ecx,37h
			mov	edx,[esp+4]
			mov	eax,4301h
			int	21h
			jc	@@FattrError01
			mov	eax,1
			retn	8

@@FattrError01:
			and	eax,0ffh
			mov	LastError,eax
			sub	eax,eax
			retn	8

;-----------------------------------------------------------------------------

