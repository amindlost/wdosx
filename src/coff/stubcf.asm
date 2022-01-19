; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/coff/stubcf.asm 1.7 1999/08/21 09:58:52 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: stubcf.asm $
; Revision 1.7  1999/08/21 09:58:52  MikeT
; Include the terminating 0 of the file name into the size of argv[0].
;
; Revision 1.6  1999/08/17 20:59:52  MikeT
; Include the size of the programs path and file name in the environment size
; to be stored in StubInfo. It has been suggested by Robert Cronk that this
; fixes the lack of an argv[0] string.
;
; Revision 1.5  1999/02/20 15:32:52  MikeT
; Force the B bit being set for the "MINKEEP" data selector. Win3.x doesn't
; like it if we terminate on a 16 bit stack. This should eventually fix the
; Stack-Fault-On-Exit issue under Win3.x.
;
; Revision 1.4  1999/02/16 20:38:04  MikeT
; Selectors of the fake loader segment ("MINKEEP") are now aliases of
; the DOS memory block's selector as returned by the DPMI host. Also, we
; create a code selector for that block as well. This fixes the lack of
; an error code when the application returns to DOS (it would always
; return "01"). Also this might/might not fix stack faults upon exit in
; a Win 3.x DOS box. The DJGPP run-time frees the selectors of the
; supposed loader segment using DPMI function 0001. The selector we
; passed on to DJGPP though was the one obtained by 0100 (alloc DOS memory)
; which may confuse the Win3.x DPMI host. Subject to further testing, still.
;
; Revision 1.3  1999/02/06 16:41:25  MikeT
; Updated copyright and so on.
;
; Revision 1.2  1998/10/01 20:18:42  MikeT
; Changed the RETF at the end of the loading process into a FAR jump
; with an CS: override. This would invoke WUDEBUG, if running.
;
; Revision 1.1  1998/08/03 02:30:50  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## Coff loader for WDOSX/DJGPP. I did this just for fun when I realized   ##
; ## how easy it is.                                                        ##
; ############################################################################

CoffSection	STRUC
		SectionName	db	8 dup (?)	; 0 terminated string
		SectionPaddr	dd	?
		SectionVaddr	dd	?		; where to load
		SectionSize	dd	?		; how much to load
		SectionFoffset	dd	?		; file offset relative
							; to coff header
				dd	4 dup (?)	; rubbish
CoffSection	ENDS

CoffHeader	STRUC
		CoffMagic	dw	?		; must be 014Ch
				db	18 dup (?)	; rubbish
		AoutHeader	LABEL	NEAR
		AoutMagic	dw	?		; must be 010Bh
				db	14 dup (?)	; rubbish
		AoutEntry	dd	?		; initial EIP
				db	8 dup (?)	; rubbish
		TextSection	CoffSection <>
		DataSection	CoffSection <>
		BssSection	CoffSection <>
		CoffHeaderEnd	LABEL	NEAR
CoffHeader	ENDS

CoffHeaderSize	EQU	OFFSET CoffHeaderEnd- OFFSET CoffMagic

.386p
code	SEGMENT use32			; 32 bit Tiny model
ASSUME cs:code, ds:code
;
; the following is needed for DJGPP compatibility
; 2 do: fill this structure from the old stub, otherwise use defaults
; must remain at offset 0 !!!
;
StubInfo		LABEL	NEAR
StubInfoMagic		db	'go32stub, v 2.00'	; a fake
StubInfoSize		dd	OFFSET StubInfoEnd- OFFSET StubInfo
StubInfoMinstack	dd	40000h
StubInfoMemoryHandle	dd	0
StubInfoInitialSize	dd	0
StubInfoMinkeep		dw	4000h
StubInfoDsSelector	dw	0
StubInfoDsSegment	dw	0			; not filled
StubInfoPspSelector	dw	0			; PSP selector
StubInfoCsSelector	dw	0
StubInfoEnvSize		dw	0			
StubInfoBasename	db	8 dup (0)
StubInfoArgv0		db	16 dup (0)
StubInfoDpmiServer	db	16 dup (0)
StubInfoEnd		LABEL	NEAR
;
; DOS strings for possible error messages
;
StrErrDpmi		db	'DPMI host returned an error',0dh,0ah,'$'
StrErrFile		db	'Error reading executable',0dh,0ah,'$'
StrErrFormat		db	'Not a valid .coff executable',0dh,0ah,'$'
StrErrMem		db	'Not enough memory to load executable',0dh,0ah,'$'
;
; error routines
;
ErrorDpmi:
	lea	edx, StrErrDpmi
	jmp	short ErrorMsg

ErrorFile:
	lea	edx, StrErrFile
	jmp	short ErrorMsg

ErrorFormat:
	lea	edx, StrErrFormat
	jmp	short ErrorMsg

ErrorMem:
	lea	edx, StrErrMem

ErrorMsg:
	mov	ah, 9
	int	21h
	mov	eax, 4CFFh
	int	21h		
;
; Program entry point
;
start:
	mov	ax, 0901h
	int	31h
	mov	StubInfoPspSelector, es
;
; allocate transfer buffer used by the main program
;
	mov	bx, 0400h
	mov	ax, 0100h
	int	31h
	jc	ErrorDpmi

	mov	StubInfoDsSegment,ax
;
; Create one code and one data alias. The reason for the data alias is
; that the selector of the DOS memory block is being freed by DJGPP when the
; memory itself is not. This might confuse certain DPMI hosts.
;
	mov	ebx, edx
	mov	ax, 000Ah
	int	31h
	jc	ErrorDpmi

	mov	StubInfoDsSelector, ax
;
; For Win3.x blows up if the program terminates on a 16 bit stack, we force
; the B bit being set on this one.
;
	push	ebx
	mov	ebx, eax
	lar	ecx, eax
	shr	ecx, 8
	or	ch, 40h
	mov	ax, 0009h
	int	31h
	jc	ErrorDpmi

	pop	ebx
	mov	ax, 000Ah
	int	31h
	jc	ErrorDpmi

	mov	StubInfoCsSelector, ax
	mov	ebx, eax
	lar	ecx, eax
	shr	ecx, 8
	or	cl, 8
	mov	ax, 0009h
	int	31h
	jc	ErrorDpmi
;
; Scan environment for filename
;
	mov	es, es:[2Ch]
	sub	edi, edi
	sub	eax, eax
	mov	ecx, -1
	cld

EnvScan:
	repne	scasb				; Scan for end of env var
	scasb					; Last env var?
	jnz	short EnvScan			; Not yet, keep scanning

	add	edi, 2				; move to exe filename (argv[0])
	repne	scasb
	mov	StubInfoEnvSize, di		; store, DJGPP crt0/crt1 use this to
						; set the environment structure and
						; argv[0]
;
; Try to open the .exe
;
	sub	ebp, ebp			; preload file offset
	mov	edx, OFFSET wfseName
	mov	eax, 3D00FFFDh
	int	21h
	lea	edx,[edi+4]			; start of filename
	mov	ebx, eax
	jnc	openWfse

	push	ds
	push	es
	pop	ds
	mov	ax, 3D00h
	int	21h
	pop	ds
	jc	ErrorFile
;
; First header is wdosx header
;
	mov	ebx, eax
	mov	ah, 3Fh
	mov	ecx, 32
	lea	edx, Headers
	int	21h
	jc	ErrorFile
;
; If it wasn't there, we didn't even come here
; Get the size of wdosx.dx
;
	movzx	ecx, WORD PTR Headers[2]
	movzx	edx, WORD PTR Headers[4]
	neg	ecx
	shl	edx, 9
	and	ecx, 511
	sub	edx, ecx
	shld	ecx, edx,16
	mov	ebp, edx			; preserve this
	mov	eax, 4200h
	int	21h
	jc	ErrorFile
;
; Read loader header
;
	mov	ah, 3Fh
	mov	ecx, 32
	lea	edx, Headers
	int	21h
	jc	ErrorFile
;
; This one should also cause no error...
; Get loader size and seek right behind the loader
;
	movzx	ecx, WORD PTR Headers[2]
	movzx	edx, WORD PTR Headers[4]
	neg	ecx
	shl	edx, 9
	and	ecx, 511
	sub	edx, ecx
	add	edx, ebp			; add wdosx.dx size
	shld	ecx, edx, 16
	mov	ebp, edx			; preserve this
	mov	eax, 4200h
	int	21h
	jc	ErrorFile
;
; Now (hopefully) pointing to coff header, so load this
;
openWfse:
	lea	edx, Headers
	mov	ecx, CoffHeaderSize
	mov	ah, 3Fh
	call	WfseHandler
	jc	ErrorFile

	cmp	eax, ecx
	jnz	ErrorFormat
;
; COFF header sucked in, verify that it is a coff and executable
;
	cmp	Headers.CoffMagic, 014Ch
	jnz	ErrorFormat

	cmp	Headers.AoutMagic, 010Bh
	jnz	ErrorFormat
;
; Get overall memory to allocate
;
	push	ebx					; save file handle
	mov	ecx, Headers.BssSection.SectionVaddr
	add	ecx, Headers.BssSection.SectionSize
	add	ecx, 0FFFFh
	sub	cx, cx
	shld	ebx, ecx, 16
	mov	StubInfoInitialSize, ecx
	mov	eax, 0501h
	int	31h
	jc	ErrorMem
;
; Start address in bx:cx, handle in si:di
;
	mov	WORD PTR [OFFSET StubInfoMemoryHandle], di
	mov	WORD PTR [OFFSET StubInfoMemoryHandle+2], si
	push	ebx
	push	ecx
;
; Time to get some selectors
;
	sub	eax, eax
	mov	ecx, 2
	int	31h
	jc	ErrorDpmi
	mov	ebx, eax
;
; Set base + limit
;
	mov	ax, 0008h
	stc
	sbb	ecx, ecx
	sbb	edx, edx
	int	31h
	jc	ErrorDpmi		
	
	pop	edx
	pop	ecx
	mov	ax, 0007h
	int	31h
	mov	ax, 0003h
	int	31h
	add	ebx, eax
	mov	ax, 0007h
	int	31h
	jc	ErrorDpmi

	stc
	sbb	ecx, ecx
	sbb	edx, edx
	mov	ax, 0008h
	int	31h
	jc	ErrorDpmi
;
; Set access rights
;
	lar	cx, bx
	mov	cl, ch
	and	cl, 060h
	or	cl, 092h			; data
	mov	ch, 0c0h
	mov	ax, 9
	int	31h
	jc	ErrorDpmi

	mov	es, ebx
	mov	ax, 3
	int	31h
	sub	ebx, eax
	mov	ax, 9
	or	cl, 9Ah			; code
	int	31h
	jc	ErrorDpmi
;
; Zero out the memory
;
	sub	eax, eax
	sub	edi, edi	
	mov	ecx, StubInfoInitialSize
	shr	ecx, 2
	rep	stosd
;
; Load text section
;
	xchg	ebx, [esp]		; code selector on stack, handle back
	push	Headers.AoutEntry	; retf will launch the app

	mov	edx, Headers.TextSection.SectionFoffset
	add	edx, ebp
	mov	ecx, edx
	shr	ecx, 16
	mov	eax, 4200h
	call	WfseHandler
	jc	ErrorFile

	mov	ecx, Headers.TextSection.SectionSize
	mov	edx, Headers.TextSection.SectionVaddr
	mov	ah, 3Fh
	push	ds
	push	es
	pop	ds
	call	WfseHandler
	pop	ds
	jc	ErrorFile
;
; Load data section
;
	mov	edx, Headers.DataSection.SectionFoffset
	add	edx, ebp
	mov	ecx, edx
	shr	ecx, 16
	mov	eax, 4200h
	call	WfseHandler
	jc	ErrorFile

	mov	ecx, Headers.DataSection.SectionSize
	mov	edx, Headers.DataSection.SectionVaddr
	mov	ah, 3Fh
	push	ds
	push	es
	pop	ds
	call	WfseHandler
	pop	ds
	jc	ErrorFile

	mov	ah, 3Eh
	call	WfseHandler
	push	es
;
; Copy the Stub info to the low memory block
;
	cld
	mov	es, StubInfoDsSelector
	sub	esi, esi
	sub	edi, edi
	mov	ecx, StubInfoSize
	rep	movs BYTE PTR es:[edi], ds:[esi]
;
; FS: fake loader segment, DS: main app segment, ES: PSP
;
	push	es
	pop	fs
	mov	es, StubInfoPspSelector
	pop	ds
;
; Under Wudebug, the jump below will generate a GPF, thus signalling the end
; of the loading process.
;
	jmp	PWORD PTR cs:[esp]
;	retf

;-----------------------------------------------------------------------------
; wfseHandler: Wrapper around DOS file accesses. If WFSE present, try WFSE
;              first, then DOS.
;
wfseHandler	PROC NEAR
	cmp	bh, 80h
	jc	@@noWfse

	push	eax
	shl	eax, 16
	mov	ax, 0FFFDh
	int	21h
	jnc	@@wfseOk

	pop	eax
	jmp	wfseErr

@@noWfse:
	int	21h
	ret
		
@@wfseOk:
	add	esp, 4

wfseErr:
	ret
wfseHandler	ENDP

wfseName	db	'WdosxMain', 0

Headers	CoffHeader <>

code	ENDS

END	start

