; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/rdoff/rdoff.asm 1.5 1999/06/27 21:39:13 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: rdoff.asm $
; Revision 1.5  1999/06/27 21:39:13  MikeT
; Added RDOFF2 support in form of a hack, not a real implementation. This
; module can handle both formats now: RDOFF1 as well as RDOFF2.
;
; Revision 1.4  1999/02/13 14:24:45  MikeT
; Removed the INT 21 FFFF blocking code. The kernel itself will now
; return an error if this function is being called inappropriately. It is
; not the responsibility of run time code to educate the programmer.
; Updated copyright.
;
; Revision 1.3  1998/09/30 01:47:13  MikeT
; Last fix was not all that'd be necessary: If any section is smaller
; in size than the header we would have corrupted the header whilst
; moving it up in memory (procedure moveHeader)
;
; Revision 1.2  1998/09/29 02:28:20  MikeT
; Fixed a very stupid bug where we would copy four times the size
; of the header... Manifested itself in Exception 0E when loading
; rather large RDOFF files.
;
; Revision 1.1  1998/08/03 02:33:51  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## rdoff.asm - load an RDOFF, relocate and execute it.                    ##
; ############################################################################

MIN_STACK	EQU	10000h			; default stack size is 64k

MAX_RECORD_TYPE	EQU	5			; highest record type supported

rdoffHeader	STRUC

	signature	db	6 dup (?)	; must be 'RDOFF1'
	headerSize	dd	?

rdoffHeader	ENDS

rdoffReloc	STRUC

	typ		db	?		; must be 1
	itemSeg		db	?
	itemOfs		dd	?
	itemSize	db	?
	targetSeg	dw	?

rdoffReloc	ENDS


rdoffBSS	STRUC

	typ		db	?		; must be 5
	bssSize		dd	?

rdoffBSS	ENDS

;
; TASM is so braindamaged that it thinks LAR was a privileged instruction,
; therefore the "p".
;
.386p
CODE	SEGMENT USE32
	ASSUME cs:CODE, ds:CODE

;-----------------------------------------------------------------------------
; Reusing loader code space for later parameter storage. Admittedly a hack.
;
pspSelector		dd	?	; ...guess!
topOfMemory		dd	?	; TOM
;myDs			dd	?	; floating segment DS
flatSelector		dd	?	; main program's CS
envCnt			dd	?	; number of environment strings
headerStart		dd	?	; start of floating header 
headerEnd		dd	?	; end of floating header
;
; these must remain in this order!
;
sectionTable	LABEL DWORD
codeStart		dd	?	; start of code section
dataStart		dd	?	; start of data section
bssStart		dd	?	; start of bss section

envStart		dd	?	; -> start of env[]
entryPoint		dd	?	; user program entry point
commandLine		db	80h dup (?)	; command tail copy
argv			dd	?	; start of argv[]

	ORG 0

;-----------------------------------------------------------------------------
; Loader entry point
;
start:
;
; Enable virtual interrupts
;
		mov	ax, 0901h
		int	31h
;
; Save PSP selector and set ES = DS
;
		mov	pspSelector, es
		push	ds
		pop	es
;
; Fixup zero base descriptors according to CPL
;
		mov	eax, cs
		lar	eax, eax
		and	eax, 0FF00h
		or	DWORD PTR [OFFSET codeDescriptor+4], eax

		mov	eax, ds
		lar	eax, eax
		and	eax, 0FF00h
		or	DWORD PTR [OFFSET dataDescriptor+4], eax
;
; Save TOM
;
		mov	topOfMemory, esp
;
; Save DS
;
;		mov	myDs, ds
;
; Allocate two new descriptors
;
		push	OFFSET strDescriptor

		sub	eax, eax
		mov	cx, 2
		int	31h
		jc	stringErrorExit

		mov	ebx, eax
		mov	flatSelector, eax
;
; Set allocated descriptors to base 0, limit 4G
;
		mov	ax, 0Ch
		mov	edi, OFFSET codeDescriptor
		int	31h
		jc	stringErrorExit

		add	ebx, 8
		mov	edi, OFFSET dataDescriptor
		int	31h
		jc	stringErrorExit
;
; Get executable file name, count number of environment strings
;
		mov	DWORD PTR [esp], OFFSET strFile
		mov	ds, pspSelector

		ASSUME ds:NOTHING

		mov	es, ds:[2Ch]
		mov	ds, ds:[2Ch]
		sub	edi, edi
		or	ecx, -1
		sub	eax, eax
		sub	ebx, ebx
		cld

@@nextEnv:
		inc	ebx
		repne	scasb
		scasb
		jne	short @@nextEnv

		lea	edx, [edi+2]

		push	ebx
		mov	eax, 0FFFDh
		int	21h
		pop	ebx
		jc	notOpenWfse

		cmp	eax, 57465345h		; 'WFSE'
		jne	notOpenWfse

		push	edx
		push	ds
		push	ss
		pop	ds
		mov	edx, OFFSET wfseName
		mov	eax, 3D00FFFDh
		int	21h
		pop	ds
		pop	edx
		jnc	fromOpenWfse

notOpenWfse:
		mov	ax, 3D00h
		int	21h

fromOpenWfse:
		push	ss
		pop	ds

		ASSUME ds:CODE

		jc	stringErrorExit
;
; Store the information we already gathered during environment scan
;
		mov	envCnt, ebx
		mov	ebx, eax		; EBX = file handle
		pop	eax			; Stack cleanup
		mov	eax, es
		call	getSelectorBase
		add	eax, edx
		mov	argv, eax
;
; Set ES back to our segment.
;
		push	ds
		pop	es
;
; Skip both, the WDosX kernel and this executable loader in executable image.
;
		test	bh, 80h
		jnz	skipSkip

		call	skipMZexe
		call	skipMZexe

skipSkip:
;
; Now, supposedly the file pointer is at the start of the user executable.
; Read in the RDOFF signature and the size of the header.
;
		mov	ecx, 10
		sub	esp, 12
		mov	edx, esp		; buffer start
		push	OFFSET strFile		; prepare to crash
		mov	ah, 3Fh			; (W)DOS read from file
		call	WfseHandler
;
; Check for various error conditions
;
		jc	stringErrorExit

		cmp	eax, ecx
		jne	stringErrorExit

		mov	DWORD PTR [esp], OFFSET strFormat
		cmp	DWORD PTR [esp+4], 'FODR'
		jne	stringErrorExit

		cmp	WORD PTR [esp+8], '2F'
		jne	notRdf2
;
; Have to read in four more bytes (the header size) and set the version flag
;
		add	edx, 6
		mov	ecx, 4
		mov	ah, 3Fh			; (W)DOS read from file
		call	WfseHandler
		jc	stringErrorExit

		cmp	eax, ecx
		jne	stringErrorExit

		mov	rdfVersion, 2
		jmp	gotOurRDOFF

notRdf2:
		cmp	WORD PTR [esp+8], '1F'
		jne	stringErrorExit
;
; ...So it's and RDOFF, get the header. The header will be stored in the
; Stack area as it can be discarded when the loader is finished. Whenever we
; move the stack, we have to move the header.
;
; The stack we allocate will have a size of MAX (MIN_STACK, sizeof(header)+4K)
; This is because the RDOFF header does not tell us anything about the stack
; size required. A vanilla approach (though obviously flawed) is to assume that
; a bigger program will have a bigger header and therefore might get a bigger
; stack allocated to it.
;
gotOurRDOFF:
		mov	edx, [esp+10]
		mov	headerEnd, edx
		add	edx, 1000h
		cmp	edx, MIN_STACK
		jnc	short @@stackSizeDone

		mov	edx, MIN_STACK

@@stackSizeDone:
;
; Add the number of env[] pointers we need as these will be stored on the
; stack too.
;
		mov	eax, envCnt
		lea	edx, [edx+eax*4]
		call	memAlloc
		mov	esp, topOfMemory
		mov	headerStart, edx
		add	headerEnd, edx
;
; Now read in the header
;
		mov	ecx, headerEnd
		sub	ecx, headerStart
		add	ecx, 4			; get code section size too
		cmp	rdfVersion, 1
		je	excessReadOk1

		add	ecx, 6			; read 6 more bytes if rdf2

excessReadOk1:
		mov	ah, 3Fh
		call	WfseHandler
;
; Check for errors as usual
;
		push	OFFSET strFile
		jc	stringErrorExit

		cmp	eax, ecx
		jne	stringErrorExit
;
; Header loaded, allocate code section memory, move header and load code
; section.
;
		mov	edx, headerEnd
		cmp	rdfVersion, 1
		je	sizeCorrect1

		add	edx, 6

sizeCorrect1:
		mov	edx, [edx]		; size of code section
		mov	edi, headerStart
		mov	codeStart, edi
		add	edi, edx		; location of data section size
		add	edx, 4			; allow for data section size
		cmp	rdfVersion, 1
		je	excessReadOk2

		add	edx, 6			; read 6 more bytes if rdf2

excessReadOk2:
		mov	ecx, edx		; bytes to read from file
		call	memAlloc

		mov	eax, topOfMemory
		mov	esp, eax
		sub	eax, edx
		call	moveHeader

		mov	edx, codeStart
		add	eax, edx
		mov	dataStart, eax

		mov	ah, 3Fh
		call	WfseHandler
;
; Again, check for errors
;
		push	OFFSET strFile
		jc	stringErrorExit

		cmp	eax, ecx
		jne	stringErrorExit
;
; Code section loaded, now load data section
;
		mov	edx, [edi]		; size of data section
		cmp	rdfVersion, 1
		je	sizeCorrect2

		mov	edx, [edi + 6]		; size of data section

sizeCorrect2:
		mov	ecx, edx		; bytes to read from file
		call	memAlloc

		mov	eax, topOfMemory
		mov	esp, eax
		sub	eax, edx
		call	moveHeader

		mov	edx, dataStart
		add	eax, edx
		mov	bssStart, eax

		mov	ah, 3Fh
		call	WfseHandler
;
; Check for errors one more time.
;
		push	OFFSET strFile
		jc	stringErrorExit

		cmp	eax, ecx
		jne	stringErrorExit

		pop	eax			; clear stack
;
; Now that we have loaded all of the file we can close it.
;
		mov	ah, 3Eh
		call	WfseHandler
;
; Finally, process the header. This is done in two runs. The first run
; collects all of the bss size entries and we may have to allocate some more
; memory for .bss. After done so, INT 21/FFFF becomes unusable as we cannot
; have moved the base address of our segment anymore.
; 
; Only the first run will check for unsupported/invalid entries.
; The second run will process all remaining header records.
;
		mov	esi, headerStart
		sub	edx, edx		; default BSS size = 0

@@pass1Loop:
		cmp	esi, headerEnd
		jnc	short @@pass1Done

		movzx	eax, BYTE PTR [esi]
		and	al, NOT 64
		cmp	al, MAX_RECORD_TYPE
		ja	recordInvalid

		cmp	rdfVersion, 2
		sbb	esi, -1
		call	recordJmpTable[eax*4]
		jmp	short @@pass1Loop

@@pass1Done:
;
; EDX now contains the accumulated bss - space
;
		mov	eax, bssStart
		mov	envStart, eax

		test	edx, edx
		jz	short @@bssDone

		call	memAlloc
		mov	eax, topOfMemory
		mov	esp, eax
		sub	eax, edx
		call	moveHeader
		add	envStart, eax

@@bssDone:
;
; Get the final location of our segment and store it in EBP
;
		mov	eax, cs
		call	getSelectorBase
		mov	ebp, eax
;
; Set the default entry point to the start of the code section.
;
		add	eax, codeStart
		mov	entryPoint, eax
;
; Do the second pass.
;
		inc	thisRun
		mov	esi, headerStart

@@pass2Loop:
		cmp	esi, headerEnd
		jnc	short @@pass2Done

		movzx	eax, BYTE PTR [esi]
		and	al, NOT 64
		cmp	rdfVersion, 2
		sbb	esi, -1
		call	recordJmpTable[eax*4]
		jmp	short @@pass2Loop

@@pass2Done:
;
; Set a new INT 21 - handler to avoid FFFF calling.
;
;		mov	bl, 21h
;		mov	ax, 204h
;		int	31h
;		mov	old21Ofs, edx
;		mov	old21Sel, ecx
;		mov	ecx, cs
;		mov	edx, OFFSET newInt21
;		inc	eax
;		int	31h		
;
; Create command line and env[] array
;
		mov	ds, pspSelector
		mov	esi, 80h
		mov	edi, OFFSET commandLine
		mov	ecx, 20h		
		rep	movsd
		push	ss
		pop	ds
		mov	edi, OFFSET argv+4	; point to argv[1]
		mov	cl, BYTE PTR [OFFSET commandLine]
		mov	esi, OFFSET commandLine+1
		push	1			; argc
		jecxz	@@cmdDone

		sub	ah, ah			; indicate last = ctl char

@@cmdLineLoop:
		lodsb
		cmp	al, 21h
		jc	short @@ctlChar

		cmp	ah, 21h
		jnc	short @@cmdNext

		lea	ebx, [esi+ebp-1]
		mov	[edi], ebx
		add	edi, 4
		inc	DWORD PTR [esp]
		jmp	short @@cmdNext

@@ctlChar:
		mov	BYTE PTR [esi-1], 0

@@cmdNext:
		mov	ah, al
		loop	short @@cmdLineLoop

@@cmdDone:
		mov	BYTE PTR [esi], 0
		mov	DWORD PTR [edi], 0

		mov	es, pspSelector
		mov	es, es:[2Ch]
		mov	eax, es
		call	getSelectorBase
		mov	edx, eax
		sub	edi, edi
		sub	eax, eax
		mov	esi, envStart
		or	ecx, -1
		mov	ebx, edx

@@envLoop2:
		mov	[esi], ebx
		cmp	BYTE PTR es:[edi], 0
		je	short @@envArrayDone

		repne	scasb

		add	esi, 4
		lea	ebx, [edi+edx] 
		jmp	short @@envLoop2

@@envArrayDone:
		mov	DWORD PTR [esi], 0
;
; Set up the user program environment and jump to the entry point in a way
; that would invoke the debugger, if present.
;
		mov	es, pspSelector
		sub	eax, eax
		mov	fs, eax
		mov	gs, eax

		lea	edx, [esp-124]
		mov	eax, entryPoint
		mov	[edx], eax

		mov	ebx, ebp
		add	ebp, envStart
		pop	esi
		lea	edi, [ebx+OFFSET argv]
		mov	eax, flatSelector
		mov	[edx+4], eax
		add	eax, 8
		mov	ds, eax
		mov	ss, eax
		add	esp, ebx
		jmp	PWORD PTR cs:[edx]

;-----------------------------------------------------------------------------
; StringErrorExit - Display string in [ESP] and exit
; (relocatable)
;
stringErrorExit LABEL NEAR

		pop	edx
		mov	ah, 9
		int	21h
		mov	ax, 4CFFh
		int	21h

;-----------------------------------------------------------------------------
; Relocation record
;
;
recordReloc	PROC NEAR

		cmp	thisRun, 0
		je	short @@relocExit

		cmp	[esi].rdoffReloc.targetSeg, 2
		ja	recordInvalid

		movzx	ecx, [esi].rdoffReloc.itemSeg

		movzx	eax, BYTE PTR [esi].rdoffReloc.targetSeg
		mov	eax, sectionTable[eax*4]

		mov	edi, ecx
		and	edi, NOT 64
		mov	edi, sectionTable[edi*4]
		mov	ebx, eax
		sub	ebx, edi
		add	edi, [esi].rdoffReloc.itemOfs

		test	cl, 64
		jne	short @@deltaDone

		lea	ebx, [eax+ebp]

@@deltaDone:
;
; There is not much we can do regarding fixup overflows. For now, just
; ignore the item size.
;
		add	[edi], ebx

@@relocExit:
		add	esi, 9
		ret

recordReloc	ENDP

;-----------------------------------------------------------------------------
; BSS record
;
recordBss	PROC NEAR

		lodsb
		lodsd
		add	edx, eax
		ret

recordBss	ENDP

;-----------------------------------------------------------------------------
; Export record
;
recordExport	PROC NEAR

		lodsw		; skip type and section identifier
		lodsd		; skip symbol address
;
; Look for the "_WdosxStart" label that would override the default entry
; point at .code:00000000.
;
		push	eax
		mov	edi, esi

@@exportLoop:
		lodsb
		cmp	al, 'a'
		jc	short @@noUpcase

		cmp	al, 'z'
		ja	@@exportLoop
	
		and	al, 0DFh
		mov	[esi-1], al

@@noUpcase:
		test	al, al
		jnz	short @@exportLoop

		pop	eax
		sub	edi, esi
		cmp	DWORD PTR [esi+edi], 'ODW_'
		jne	short @@noEntry

		cmp	DWORD PTR [esi+edi+4], 'TSXS'
		jne	short @@noEntry

		cmp	DWORD PTR [esi+edi+8], 'TRA'
		jne	short @@noEntry
;
; Adjust program entry point
;
		movzx	edi, BYTE PTR [esi+edi-5]
		mov	edi, sectionTable[edi*4]
		add	eax, edi
		add	eax, ebp
		mov	entryPoint, eax

@@noEntry:
		ret

recordExport	ENDP

;-----------------------------------------------------------------------------
; Invalid record - Abort loading
; (not relocatable)
;
recordInvalid	LABEL	NEAR

		push	OFFSET strInvalidRecord
		jmp	stringErrorExit

;-----------------------------------------------------------------------------
; Import record - Abort loading
; (not relocatable)
;
recordImport	PROC NEAR

		mov	DWORD PTR [esp], OFFSET strImportRecord
		jmp	stringErrorExit

recordImport	ENDP

;-----------------------------------------------------------------------------
; Library record - Abort loading
; (not relocatable)
;
recordLibrary	PROC NEAR

		mov	DWORD PTR [esp], OFFSET strLibraryRecord
		jmp	stringErrorExit

recordLibrary	ENDP

;-----------------------------------------------------------------------------
; getSelectorBase
;
; In:  EAX = Selector
; Out: EAX = linear base address
; (relocatable)
;      No error checking done here!
;
getSelectorBase	PROC NEAR

		push	ebx
		push	ecx
		push	edx
		mov	ebx, eax
		mov	ax, 6
		int	31h
		shrd	eax, edx, 16
		shrd	eax, ecx, 16
		pop	edx
		pop	ecx
		pop	ebx
		ret

getSelectorBase ENDP

;-----------------------------------------------------------------------------
; skipMZexe - set file pointer to after an MZ - .exe image
; (not relocatable)
;
; In:  EBX = file handle, file pointer assumed to be at 'MZ' signature
; Out: File pointer set accordingly
;
; Modified: Certain general purpose registers are clobbered, namely
;           EAX, ECX, EDX
;
; If we encounter an error, this procedure will never return. Then again, as
; we execute this code, it is highly unlikely that we get an error from this
; one.
;
skipMZexe	PROC NEAR

		mov	ecx, 8
		sub	esp, ecx	; Allocate temp storage
		mov	ah, 3Fh		; (W)DOS - read from file
		mov	edx, esp	; EDX = start of buffer
		push	OFFSET strFile	; Prepare to bomb out
		int	21h
;
; Check for certain error conditions
;
		jc	stringErrorExit

		cmp	eax, ecx
		jne	stringErrorExit
		
		cmp	WORD PTR [esp+4], 'ZM'
		jne	stringErrorExit
;
; Calculate size of MZ executable
;
		movzx	edx, WORD PTR [esp+6]	; Size MOD 512
		movzx	ecx, WORD PTR [esp+8]	; Size DIV 512
		shl	ecx, 9
		dec	edx
		and	edx, 511
		lea	edx, [edx+ecx-512+1-8]	; 8 bytes already read
;
; Call DOS lseek()
;
		shld	ecx, edx, 16
		mov	ax, 4201h
		int	21h
		jc	stringErrorExit

		add	esp, 12			; Clean up the stack
		ret

skipMZexe	ENDP

;-----------------------------------------------------------------------------
; memAlloc - allocate memory (page granular) at top of meory
; (not relocatable)
;
; In:  EDX = number of bytes to allocate, topOfMemory set
; Out: EDX = old topOfMemory value (page aligned), topOfMemory set
;
;    May bomb out with an error message if memory could not be allocated.
;
; Modified: EAX, EDX
;
memAlloc	PROC NEAR

		add	edx, 0FFFh
		and	dx, 0F000h
		add	edx, topOfMemory
		add	edx, 0FFFh
		and	dx, 0F000h
		mov	ax, -1
		int	21h
		push	OFFSET strMemory
		jc	stringErrorExit

		pop	eax
		xchg	edx, topOfMemory
		add	edx, 0FFFh
		and	dx, 0F000h
		ret

memAlloc	ENDP

;-----------------------------------------------------------------------------
; MoveHeader - move the header up in memory
; (not relocatable)
;
; In: HeaderStart and HeaderEnd set accordingly
;     EAX = address delta of new header - old header location, DF clear
; Out: HeaderStart and HeaderEnd adjusted accordingly, header moved.
;
;
moveHeader	PROC NEAR

		pushad
		mov	esi, headerStart
		add	headerStart, eax
		add	headerEnd, eax

		lea	edi, [esi + eax]
		mov	ecx, headerEnd
		sub	ecx, headerStart
		lea	esi, [esi + ecx - 1]
		lea	edi, [edi + ecx - 1]
		std
		rep	movsb
		cld
		popad
		ret

moveHeader	ENDP

;-----------------------------------------------------------------------------
; Initialized data following
;
	ALIGN 4

codeDescriptor		dq	0CF9A000000FFFFh
dataDescriptor		dq	0CF92000000FFFFh

recordJmpTable		dd	OFFSET recordInvalid
			dd	OFFSET recordReloc
			dd	OFFSET recordImport
			dd	OFFSET recordExport
			dd	OFFSET recordLibrary
			dd	OFFSET recordBSS

thisRun			db	0

strInvalidRecord	db	'Invalid record type.',0Dh,0Ah,'$'
strImportRecord		db	'Import records not supported.',0Dh,0Ah,'$'
strLibraryRecord	db	'Library records not supported.',0Dh,0Ah,'$'
strDescriptor		db	'Could not set DPMI descriptors.',0Dh,0Ah,'$'
strFile			db	'Error reading executable.',0Dh,0Ah,'$'
strFormat		db	'Not a valid RDOFF.',0Dh,0Ah,'$'
strMemory		db	'Not enough memory.',0Dh, 0Ah,'$'
;strNoFFFF		db	'INT 21/FFFF is unavailable in this environment.'
;			db	0Dh,0Ah
;			db	'Use DPMI function 0501 to allocate memory!'
;			db	0Dh,0Ah,'$'

;-----------------------------------------------------------------------------
; A new INT 21h - handler to avoid calling function FFFF, which otherwise
; would give unexpected results at best.
;
;newInt21:
;		cmp	ax, -1
;		jne	short oldInt21
;
;		mov	ds, cs:[myDs]
;		mov	ah, 0Fh
;		int	10h
;		and	al, 7Fh
;		cmp	al, 3
;		je	short @@modeOk
;
;		mov	ax, 3
;		int	10h
;
;@@modeOk:
;		push	OFFSET strNoFFFF
;		jmp	stringErrorExit
;
;oldInt21:		
;		db	0EAh	; JMP FAR opcode
;old21Ofs	dd	?
;old21Sel	dd	?


;-----------------------------------------------------------------------------
; wfseHandler: Wrapper around DOS file accesses. If WFSE present, try WFES
;              first, then DOS.
; (not relocatable)
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

wfseName	db	'wdosxmain',0
rdfVersion	db	1
CODE	ENDS
END	start
