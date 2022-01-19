; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 2002, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/PE/loadpe.asm 1.9 2002/02/05 19:58:38 MikeT Exp MikeT $
;
; ----------------------------------------------------------------------------
;
; $Log: loadpe.asm $
; Revision 1.9  2002/02/05 19:58:38  MikeT
; Final adjustment to the XP workaround: Take care of difficult stack condition
;
; Revision 1.8  2002/01/31 20:31:06  MikeT
; Slight correction of the XP workaround.
;
; Revision 1.7  2002/01/31 19:40:12  MikeT
; Fix crash under XP.
;
; Revision 1.6  1999/02/13 14:19:25  MikeT
; Removed INT21 FFFF blocking code. The kernel itself will now return an
; error if this function is being used inappropriately. It is not the
; responsibility of run time code to educate the programmer.
;
; Revision 1.5  1999/02/13 12:34:46  MikeT
; Add support for PEs that do just RET to terminate.
;
; Revision 1.4  1999/02/06 17:12:26  MikeT
; Updated copyright + some cosmetics.
;
; Revision 1.3  1998/08/23 14:25:01  MikeT
; Fix # sections
;
; Revision 1.2  1998/08/03 02:41:25  MikeT
; Fix for zero sized .reloc
;
; Revision 1.1  1998/08/03 02:35:19  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## loadpe.asm - load a PE without Win32 API, relocate and execute it      ##
; ############################################################################

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
hKernel			dd	?	; hModule of kernel32.wdl
isDebugger		dd	?	; only low byte counts
pspSelector		dd	?	; ...guess!
flatSelector		dd	?	; main program's CS
envCnt			dd	?	; number of environment strings
entryPoint		dd	?	; Entry RVA
envStart		dd	?	; -> start of env[]
hModule			dd	?	; linear base of PE image
commandLine		db	80h dup (?)	; command tail copy
argv			dd	?	; start of argv[]
pOffset			dd	?	; offset of path name in environment

	ORG 0
;-----------------------------------------------------------------------------
; Signature. This indicates that the loader supports WFSE loading of the
; main executable. If this signature doesn't exist, any compressor should
; refuse to compress the main executable.
;
WfseSig			db	'$LDR'
;
; In future versions there might be some sort of an info structure following
; the signature. To allow for this to be compatible with the current version
; we store a "0" dword that normally would indicate the version number of the
; header.
;
			dd	0

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
; Fixup zero base descriptors according to CPL and detect debugger presence
;
		mov	eax, cs
		lsl	edx, eax
		cmp	edx, esp
		setc	BYTE PTR [OFFSET isDebugger]
		lar	eax, eax
		and	eax, 0FF00h
		or	DWORD PTR [OFFSET codeDescriptor+4], eax

		mov	eax, ds
		lar	eax, eax
		and	eax, 0FF00h
		or	DWORD PTR [OFFSET dataDescriptor+4], eax
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

		mov	gs, ebx			; MikeT - XP workaround
;
; check Wfse
;
		call	checkWfse
		cmp	haveWfse, 1
		jne	isLegacy
;
; If Wfse present, try to open the main file by WFSE
;
		mov	edx, OFFSET wfseName
		mov	eax, 3D00FFFDh
		int	21h
		setnc	haveWfse
;
; Get executable file name, count number of environment strings
;
isLegacy:
		mov	DWORD PTR [esp], OFFSET strFile
		push	eax
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

		pop	eax
		lea	edx, [edi+2]
		cmp	cs:haveWfse, 1
		jz	fileOpen

		mov	ax, 3D00h
		int	21h

fileOpen:
		push	ss
		pop	ds

		ASSUME ds:CODE

		jc	stringErrorExit
;
; Store the information we already gathered during environment scan
;
		mov	envCnt, ebx
		mov	pOffset, edx
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
; Do this only if not WFSE loading as with WFSE we start at the beginning of
; the image anyway.
;
		sub	edx, edx
		cmp	haveWfse, 1
		jz	FilePointerSet

		call	skipMZexe
		call	skipMZexe

FilePointerSet:
;
; Now, supposedly the file pointer is at the start of the user executable.
;
		mov	ebp, edx		; save file pointer
		mov	ecx, 64
		sub	esp, 68h		; alloc temp storage
		mov	edx, esp
		mov	ah, 3Fh
		call	wfseHandler
		jc	loadFileError

		cmp	eax, ecx
		jne	loadFileError
;
; Check for MZ .EXE signature
;
		cmp	word ptr [esp],'ZM'
		jnz	loadFileError
;
; Get offset to PE header and load first 54h bytes there
;
		mov	edx, [esp+60]
		lea	edi, [edx+24]		; First chunk to load into real
						; memory
		sub	edx, 64
		jz	short loadFileAtPE

		shld	ecx, edx, 16
		mov	eax, 4201h
		call	wfseHandler
		jc	loadFileError

loadFileAtPE:
		mov	ecx, 68h
		mov	edx, esp
		mov	ah, 3Fh
		call	wfseHandler
		jc	loadFileError

		cmp	eax, ecx
		jne	loadFileError
;
; Verify whether the image pretends to be a PE or not
;
		cmp	DWORD PTR [esp],'EP'
		jnz	loadFileError
;
; Get the size of memory needed to load all of the image
;
		mov	edx, [esp+50h]
		add	edx, 0FFFh
		and	edx, 0FFFFF000h
;
; Add stack size (StackCommit)
;
		mov	edi, [esp+64h]
		add	edi, 0FFFh
		and	di, 0F000h
		add	edx, edi
;
; Add Env[] size
;
		mov	ecx, envCnt
		lea	edi, [edi+ecx*4+0FFFh]
		and	di, 0F000h
		lea	esi, [esp+0FFFh]	; esi = hModule from now on
		and	si, 0F000h
;
; Try to allocate a memory block
;
		add	edx, edi
		add	edx, esi
		push	OFFSET strMemory
		mov	ax, -1
		int	21h
		jc	stringErrorExit
;
; Some poor programs require the memory to be zeroed out
;
		push	edi
		sub	eax, eax
		lea	ecx, [edx - 1000h]
		sub	ecx, esi
		lea	edi, [esi+1000h]
		shr	ecx, 2
		rep	stosd
		pop	edi

		mov	esp, edx
		sub	edx, edi
		mov	envStart, edx
;
; lSeek back to the start of the image
;
		mov	edx, ebp
		shld	ecx, edx, 16
		mov	eax, 4200h
		call	wfseHandler
		jc	loadFileError
;
; Load first portion of image
;
		mov	edx, esi
		mov	ecx, 64
		mov	ah, 3Fh
		call	wfseHandler
		jc	loadFileError

		cmp	eax, ecx
		jne	loadFileError

		add	edx, ecx
		sub	ecx, [esi+60]
		neg	ecx
		add	ecx, 24
		mov	ah, 3Fh
		call	wfseHandler
		jc	loadFileError

		cmp	eax, ecx
		jne	loadFileError
;
; Get the not-so-optional header size and load the thing
;
		lea	edx, [edx+ecx]
		movzx	ecx, word ptr [edx-4]
		mov	ah, 3Fh
		call	wfseHandler
		jc	loadFileError

		cmp	eax, ecx
		jne	loadFileError
;
; Load section table
;
		mov	ecx, [esi + 60]
		movzx	ecx, BYTE PTR [esi + ecx + 6]	; Get # of sections
		add	edx, eax		; set pointer where to store
		imul	ecx, 28h		; size of section headers
		mov	ah, 3Fh
		call	wfseHandler
		jc	loadFileError

		cmp	eax, ecx
		jne	loadFileError

		mov	edi, edx
;
; ESI = hModule (RVA = 0)
; EDI -> Image Section Header
;
; Now clear to load all these sections into memory
; 
;
		add	ecx, edx			; ecx = end
		push	ecx

loadImageSection:
		cmp	edi, [esp]
		jnc	loadFileDone
;
; Check first letter of section name, done if zero
;
		cmp	byte ptr [edi], 0
		jz	short loadFileDone
;
; Get virtual size
;
		mov	eax, [edi+8]
		or	eax, [edi+16]
		jz	short loadNextSection		; nothing to load?

		mov	edx, [edi+20]			; Get file offset
		test	edx, edx
		jz	short loadNextSection		; nothing to load?

		add	edx, ebp			; Adjust file offset
		shld	ecx, edx, 16
		mov	eax, 4200h
		call	wfseHandler
		jc	loadFileError

		mov	edx, [edi+12]			; Get RVA
		mov	ecx, [edi+16]			; Get size
		add	edx, esi			; RVA -> offset
		mov	ah, 3Fh
		call	wfseHandler
		jc	loadFileError

		cmp	eax, ecx
		jne	loadFileError

loadNextSection:
		add	edi, 40
		jmp	short loadImageSection

loadFileError:
		push	OFFSET strFile
		jmp	stringErrorExit

loadFileDone:
		pop	eax				; clean stack
;
; Now that we have loaded all of the file we can close it.
;
		mov	ah, 3Eh
		call	wfseHandler
;
; Prepare run in true flat
;
		mov	eax, cs
		call	getSelectorBase
		mov	ebp, eax
		add	eax, esi
		mov	hModule, eax
		mov	eax, [esi+60]
		mov	edi, [eax+esi+80h]
		mov	eax, [eax+esi+28h]
		add	eax, esi
		add	eax, ebp
		mov	entryPoint, eax
		mov	hKernel, 0
		test	edi, edi
		je	noWinAPI

		test	DWORD PTR [edi+esi+12], -1
		je	noWinAPI
;
; If the user program contains references to the Win32 API, we invoke
; kernel32.wdl
;
		call	loadKernel
		mov	hKernel, eax
; MikeT - XP workaround begin
;		sub	eax, ebp
;		mov	esi, [eax+60]
;		mov	esi, [eax+esi+28h]
		mov	esi, gs:[eax+60]
		mov	esi, gs:[eax+esi+28h]
		add	esi, eax
;		add	esi, ebp
; MikeT - XP workaround end
		mov	entryPoint, esi

noWinAPI:
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
		mov	gs, eax
		push	ds
		pop	fs				; FS => TIB

		lea	edx, [esp-1016]
		mov	eax, entryPoint
		mov	[edx], eax

		mov	ebx, ebp			; segment base in ebx
		add	ebp, envStart
		pop	esi
		lea	edi, [ebx+OFFSET argv]
		mov	eax, flatSelector
		mov	[edx+4], eax
		add	eax, 8
		mov	ds, eax
		mov	ss, eax
		add	esp, ebx
;
; Finally, process fixups.
;
		mov	eax, cs:hModule
		call	peRelocate
		cmp	DWORD PTR cs:hKernel, 0
		jz	loaderDoJump

		push	eax
		mov	eax, cs:hKernel
		call	peRelocate
		pop	eax

loaderDoJump:
;
; ...and jump to start of user program
;
; Registers are:
; EAX = hModule
; EBX = loader segment base address
; ECX, EDX = rubbish
; ESI, EDI, EBP = argc, argv[] and env[] as usual
;
;
; Prepare for possible termination of the PE with RET.
;
		lea	ecx, [ebx + OFFSET doTerminate]
		push	ecx
		jmp	PWORD PTR cs:[edx]
;
; In case the PE terminates with just a RET instead of calling ExitProcess()
; we'll end up right here, allthough with a different CS (zero based)
;
doTerminate:
		mov	ah, 4Ch
		int	21h

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
; Out: File pointer set accordingly, EDX = new file pointer
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
		shl	edx, 16
		mov	dx, ax
		ret

skipMZexe	ENDP


;-----------------------------------------------------------------------------
; Initialized data following
;
	ALIGN 4

codeDescriptor		dq	0CF9A000000FFFFh
dataDescriptor		dq	0CF92000000FFFFh

strDescriptor		db	'Could not set DPMI descriptors.',0Dh,0Ah,'$'
strFile			db	'Error reading executable.',0Dh,0Ah,'$'
strFormat		db	'Not a valid PE.',0Dh,0Ah,'$'
strMemory		db	'Not enough memory.',0Dh, 0Ah,'$'
;strNoFFFF		db	'Sorry, but INT 21/FFFF is unavailable in this environment.'
;			db	0Dh,0Ah
;			db	'Either use DPMI function 0501 to allocate memory or use STUBIT.EXE with the'
;			db	0Dh,0Ah
;			db	'-m_float backwards compatibility option!'
;			db	0Dh,0Ah,'$'
strK32			db	'kernel32.wdl',0
strNoK32		db	'Error loading module kernel32.wdl.',0Dh,0Ah,'$'

;-----------------------------------------------------------------------------
; peRelocate - Process all fixups in a PE image
;
; Entry:	EAX = hModule
; Exit:
; 
; The procedure itself does not have fixed memory references and therefore can
; be used to let a PE executable relocate itself.
;
; One might excuse the lack of comments, but as this procedure has proven very
; reliable, it's highly unlikely that it needs to be changed ever. Just works.
;
; As a side effect, the new relocation base is stored in the image, making
; multiple relocation passes possible.
;
peRelocate	PROC NEAR

		pushad
		mov	ebp, [eax+60]
		add	ebp, [esp+28]
		mov	edi, [ebp+0A0h]
		test	edi, edi
		je	short @@relocDone

		cmp	DWORD PTR [ebp+0A4h], 0
		je	@@relocDone
		
		add	edi, eax
		sub	eax, [ebp+034h]
		add	[ebp+034h], eax

@@relocNextPage:
		mov	edx, [edi]
		test	edx, edx
		jz	short @@relocDone

		add	edx, [esp+28]
		mov	esi, 8

@@relocNextFixup:
		movzx	ebp, WORD PTR [edi+esi]
		ror	ebp, 12
		mov	ebx, ebp
		shr	ebx, 20
		cmp	bp, 2
		jnz	short @@relocNotType2

		add	[edx+ebx], ax
		jmp	short @@relocGetNext

@@relocNotType2:
		cmp	bp, 1
		jnz	short @@relocNotType1
		push	eax
		shl	eax, 16
		add	[edx+ebx], ax
		pop	eax
		jmp	short @@relocGetNext

@@relocNotType1:
		cmp	bp, 3
		jnz	short @@relocNotType3
		add	[edx+ebx], eax
		jmp	short @@relocGetNext

@@relocNotType3:
		cmp	bp, 4
		jnz	short @@relocGetNext

		add	esi, 2
		mov	ebp, [edx+ebx-2]
		mov	bp, [edi+esi]
		lea	ebp, [ebp+eax+8000h]
		shr	ebp, 16
		mov	[edx+ebx], bp

@@relocGetNext:
		add	esi, 2
		cmp	esi, [edi+4]
		jnz	short @@relocNextFixup

		add	edi, esi
		jmp	short @@relocNextPage

@@relocDone:
		popad
		retn

peRelocate	ENDP

;-----------------------------------------------------------------------------
; wfseHandler: Wrapper around DOS file accesses. If WFSE present, try WFES
;              first, then DOS.
; (not relocatable)
wfseHandler	PROC NEAR
		cmp	cs:haveWfse, 0	; allow running with different DS
		je	@@noWfse

		push	eax
		shl	eax, 16
		mov	ax, 0FFFDh
		int	21h
		jnc	@@wfseOk

		pop	eax

@@noWfse:
		int	21h
		ret
		
@@wfseOk:
		add	esp, 4
		ret

wfseHandler	ENDP

haveWfse	db	0		; default to NO

;-----------------------------------------------------------------------------
; CheckWfse - Check whether we have WFSE and set the flag accordingly
;
checkWfse PROC NEAR
		push	eax
		push	ebx
		mov	eax, 0FFFDh
		int	21h
		jc	noWfse

                cmp	eax, 57465345h
		sete	haveWfse

noWfse:
		pop	ebx
		pop	eax
		ret
checkWfse ENDP

;-----------------------------------------------------------------------------
; loadKernel - Load and relocate Kernel32.wdl
;
; Return: EAX = hModule
;
loadKernel	PROC NEAR
		pushad
		mov	ebp, ds
		call	checkWfse
;
; Open this file.
;
		mov	edx, OFFSET strK32
		mov	ax, 3D00h
		call	wfseHandler
		jnc	loadK32Open
;
; Try current directory
;
		mov	eax, pOffset
		sub	esp, 128
		push	ds
		mov	ds, pspSelector
		mov	ds, ds:[2Ch]
		lea	edx, [esp + 4]

@@EndPathLoop:
		mov 	cl, [eax]
		inc	eax
		mov	ss:[edx], cl
		inc	edx
		cmp	cl, 1
		jnc	short @@EndPathLoop

		pop	ds

@@FindPathLoop:
		dec	edx
		cmp	BYTE PTR [edx -1], '\'
		jnz	short @@FindPathLoop

		mov	DWORD PTR [edx], 'nrek'
		mov	DWORD PTR [edx + 4], '23le'
		mov	DWORD PTR [edx + 8], 'ldw.'
		mov	BYTE PTR [edx + 12], 0
		mov	edx, esp
		mov	ax, 3D00h
		int	21h
		lea	esp, [esp + 128]
		jc	loadK32Error

loadK32Open:
		mov	ebx, eax
;
; Read in headers and perform the usual PE loading stuff
;
		mov	ecx, 64
		sub	esp, 68h		; alloc temp storage
		mov	edx, esp
		mov	ah, 3Fh
		call	wfseHandler
		jc	loadK32Error

		cmp	eax, ecx
		jne	loadK32Error
;
; Check for MZ .EXE signature
;
		cmp	word ptr [esp],'ZM'
		jnz	loadK32Error
;
; Get offset to PE header and load first 54h bytes there
;
		mov	edx, [esp+60]
		lea	edi, [edx+24]		; First chunk to load into real
						; memory
		sub	edx, 64
		jz	short loadK32AtPE

		shld	ecx, edx, 16
		mov	eax, 4201h
		call	wfseHandler
		jc	loadK32Error

loadK32AtPE:
		mov	ecx, 68h
		mov	edx, esp
		mov	ah, 3Fh
		call	wfseHandler
		jc	loadK32Error

		cmp	eax, ecx
		jne	loadK32Error
;
; Verify whether the image pretends to be a PE or not
;
		cmp	DWORD PTR [esp],'EP'
		jnz	loadK32Error
;
; Get the size of memory needed to load all of the image
;
		mov	ecx, [esp+50h]
		add	ecx, 0FFFh
		and	ecx, 0FFFFF000h
;
; Try to allocate a memory block
;
		shld	ebx, ecx, 16		; handle > high EBX
		push	OFFSET strMemory
		mov	ax, 0501h
		int	31h
		jc	stringErrorExit
;
; The block handle is never to be released, so we can just discard it
;
		add	esp, 6CH		; relase temp storage
		mov	esi, ebx
		shr	ebx, 16			; handle > low EBX
		shl	ecx, 16
		shld	esi, ecx, 16
;		mov	eax, cs			; MikeT - XP workaround
;		call	getSelectorBase		; MikeT - XP workaround
		mov	[esp+28], esi		; store linear hModule
;		sub	esi, eax		; MikeT - XP workaround
		push	gs			; MikeT - XP workaround
		pop	ds			; MikeT - XP workaround
;
; lSeek back to the start of the image
;
		sub	ecx, ecx
		sub	edx, edx
		mov	ax, 4200h
		call	wfseHandler		
		jc	loadK32Error
;
; Load first portion of image
;
		mov	edx, esi
		mov	ecx, 64
		mov	ah, 3Fh
		call	wfseHandler
		jc	loadK32Error

		cmp	eax, ecx
		jne	loadK32Error

		add	edx, ecx
		sub	ecx, [esi+60]
		neg	ecx
		add	ecx, 24
		mov	ah, 3Fh
		call	wfseHandler
		jc	loadK32Error

		cmp	eax, ecx
		jne	loadK32Error
;
; Get the not-so-optional header size and load the thing
;
		lea	edx, [edx+ecx-24]
		movzx	ecx, word ptr [edx+20]
		add	edx, 24
		mov	ah, 3Fh
		call	wfseHandler
		jc	loadK32Error

		cmp	eax, ecx
		jne	loadK32Error
;
; Load section table
;
		mov	ecx, [esi + 60]		
		movzx	ecx, BYTE PTR [ecx + esi + 6]	; Get # of sections
		add	edx, eax		; Set pointer where to store
		imul	ecx, 28h		; Get directory size
		mov	ah, 3Fh
		call	wfseHandler
		jc	loadK32Error

		cmp	eax, ecx
		jne	loadK32Error

		mov	edi, edx
;
; ESI = hModule (RVA = 0)
; EDI -> Image Section Header
;
; Now clear to load all these sections into memory
; 
;
		add	ecx, edx
		push	ecx

k32loadImageSection:
		cmp	edi, [esp]
		jnc	loadK32Done
;
; Check first letter of section name, done if zero
;
		cmp	byte ptr [edi], 0
		jz	short loadK32Done
;
; Get virtual size
;
		mov	eax, [edi+8]
		or	eax, [edi+16]
		jz	short k32loadNextSection	; nothing to load?

		mov	edx, [edi+20]			; Get file offset
		shld	ecx, edx, 16
		mov	ax, 4200h
		call	wfseHandler
		jc	loadK32Error

		mov	edx, [edi+12]			; Get RVA
		mov	ecx, [edi+16]			; Get size
		add	edx, esi			; RVA -> offset
		mov	ah, 3Fh
		call	wfseHandler
		jc	loadK32Error

		cmp	eax, ecx
		jne	loadK32Error

k32loadNextSection:
		add	edi, 40
		jmp	short k32loadImageSection

loadK32Error:
		mov	ds, ebp				; MikeT - XP workaround
		push	OFFSET strNoK32
		jmp	stringErrorExit

loadk32Done:
		pop	eax
		mov	ds, ebp				; MikeT - XP workaround
;
; Now that we have loaded all of the file we can close it.
;
		mov	ah, 3Eh
		call	wfseHandler

		popad
		ret

loadKernel	ENDP

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
; Name of the main executable if it's WFSE'ed. Note that this name cannot
; exist in 8.3 DOS.
;
wfseName	db	'wdosxmain',0

;oldInt21:		
;		db	0EAh	; JMP FAR opcode
;old21Ofs	dd	?
;old21Sel	dd	?
;myDs		dd	?	; floating segment DS

CODE	ENDS
END	start
