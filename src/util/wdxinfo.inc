; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/UTIL/WDXINFO.INC 1.2 1999/02/07 18:27:07 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: WDXINFO.INC $
; Revision 1.2  1999/02/07 18:27:07  MikeT
; Updated copyright + some cosmetics.
;
; Revision 1.1  1998/08/03 02:53:11  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
;
; Theory of operation
; ----------------------------------------------------------------------------
;
; Due to the need to provide a zero based memory model for all fully
; relocatable executable formats, we need a means for parametrizing the
; execution of WdosX.
;
; The solution is to define a structure WdxInfo and locate it at offset 0
; of the executable image of wdosx.dx (the DOS extender kernel)
;
; Not all of the information in this structure is actually processed by the
; kernel but rather meant to be taken care of by an executable loader.
;
; The structure will be initialized with default values to allow for 100%
; backward compatibility with earlier versions of WdosX and a pretty good
; level of backward compatibility even with the BASE0- feature turned ON.
;
; Since the Watcom- variant of WdosX runs zero- based since day one, the BASE0
; ON/OFF setting will be ignored by the executable loader.
;
; If the revision is incremented, the meaning of all earlier defined fields in
; the structure MUST NOT CHANGE to allow for future backward compatibility.
;
; Algorithm for accessing the WdxInfo structure:
;
; 1: Open executable file
; 2: Read executable header
; 3: Read header size from header
; 4: Set file pointer to after the header
; 5: Read in at least 4 bytes (you might want to read in all of the structure
;    at once)
; 6: If these four bytes match the string '$WdX', then WdxInfo is present
; ----------------------------------------------------------------------------

WDXINFO_FLAGS_BASE0	EQU	0000000000000001b
STUB_CLASS_WDX		EQU	1
STUB_CLASS_LE		EQU	2

WdxInfo		STRUC
		Signature	label	dword
		SigB		db	'$WdX'		; Magic
							; ---------------------

		Revision	dw	4		; Revision level of
							; this structure
							; ---------------------

		WdxFlags	db	0		; used by kernel/loader
							; ---------------------
IFDEF __WATCOM__
		StubClass	db	STUB_CLASS_LE
ELSE
		StubClass	db	STUB_CLASS_WDX
ENDIF
		XMemReserve	dd	0		; used by kernel
							; ---------------------
							; Minimum amount of
							; extended memory to
							; preserve for spawning
							; child apps
							; DEFAULT = NONE

		XMemAlloc	dd	-1		; used by app loader
							; ---------------------
							; 21/FFFF will never
							; try to allocate more
							; memory than this.
							; DEFAULT = ALL

		WfseStart	dd	0		; used by kernel
							; ---------------------
							; File offset first
							; WFSE block

		StrucEnd	LABEL DWORD
WdxInfo		ENDS

WDXINFO_REV1_SIZE	EQU	OFFSET WdxInfo.StrucEnd - \
				OFFSET WdxInfo.Signature

WfseInfo	STRUC
		WfseSignature	LABEL	DWORD
				dd	?
;				db	'WFSE'		; Signature
		WfseSize	dd	?		; Overall size of the
							; extension block
		WfseVirtualSize	dd	?		; Virtual file size
		WfseFlags	dd	?		; Additional info
			WFSE_COMP_LZ77		EQU	0000000000010000b
			WFSE_ISMAIN		EQU	0000000100000000b
				;
				; Lowest nibble if main program:
				;
				LOADER_CLASS_PE		EQU	1
				LOADER_CLASS_RDOFF	EQU	2
				LOADER_CLASS_DOS32	EQU	3
				LOADER_CLASS_COFF	EQU	4

		WfseFileName	LABEL	BYTE		; up to 255 chars
WfseInfo	ENDS

WfseFCB		STRUC
		WfseFileStart	dd	?		; raw data file offset
							; 0 = not in use
		WfseFilePos	dd	?		; current virtual file
							; pointer
		WfseFileSize	dd	?		; logical file size
		WfseFlags	dd	?		; reserved
WfseFCB		ENDS

WfseCompHeader	STRUC
		HeaderSize	dw	?
		LastBlockSize	dw	?
		CodeSize	dw	?
WfseCompHeader	ENDS


SIZE_OF_FCB	EQU	16

