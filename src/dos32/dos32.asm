; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/dos32/dos32.asm 1.2 1999/02/06 17:03:45 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: dos32.asm $
; Revision 1.2  1999/02/06 17:03:45  MikeT
; Updated copyright and some cosmetics.
;
; Revision 1.1  1998/08/03 02:43:00  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
;#############################################################################
;## dos32.asm - load a DOS32 executable and execute it                      ##
;#############################################################################
;
; Author's note:
;-----------------------------------------------------------------------------
;
; We're now at a stage where it is possible to load virtually any kind of
; executable, so why not get our hands on DOS32? The INT 33h/EExx API actually
; is a piece of %&$". Anyway, except for the DLL functions, we provide some
; support for this API in here. Don't expect too much effort to be put into
; this as the DOS32 executable format and the implied use of negative offsets
; will make your application fail in a NT DOS box at least and it will NEVER
; be possible to run these kinds of executables in true flat anyway.
;
; There appears to be a way to incorporate linear relocation into the file by
; adding relocation data after the end of the "offcial" fixup table. This has
; been seen in TMT Pascal executables and I'm not quite sure whether this is
; an "official" solution or not. As this code is experimental, it is aware of
; this expanded header and will load the aplication in true flat though if
; there is an additional field after these 28h header bytes. But if this field
; contains something else than the size of the relocation info we'll just
; crash... Same will happen if the executable is compressed anyway.
;
; Update: Now we do also support the "official" linear relocation format used
; by DOS32 3.5. Admittedly Adam implemented a quite clever solution here where 
; I still don't know why he's swapping upper and lower nibbles of the deltas.
;
; Summary: This loader handles these three different types of executables:
;
;  1: executables generated with DOS32 prior to version 3.5
;  2: executables generated with DOS32 3.5 - will there ever be a non- beta?
;  3: executables generated with the TMT Pascal compiler
;
; Except for #1 your program will run in true flat model, meaning the linear
; base addresses of CS, DS, ES and SS will be zero.
;
; This loader will NOT:
;
;       - emulate some DOS32 functions such as the DLL loading stuff
;       - work around the heap size limitation of TMT Pascal Lite
;         (Needless to say that I could have done that though...However, any
;          lame email asking me for this sort of thing may be forwarded to
;          TMT.)
;
; Then again, we will not respect the 4Mb heap limit of DOS32 3.5 unregistered.
; For I don't see any reason why I should write extra code just to impose an
; artificial memory limit on the executable when it's not using the original
; DOS32 extender anyway. Sue me!
;
; Nuff said, let's go on with the code:
;
MAX_ALLOC	EQU	64
MAX_CALLBACKS	EQU	16

RmCall		STRUC
		_edi	LABEL	DWORD
		_di	dw	?
			dw	?
		_esi	LABEL	DWORD
		_si	dw	?
			dw	?
		_ebp	LABEL	DWORD
		_bp	dw	?
			dw	?
		_esp	LABEL	DWORD
		_spl	dw	?
			dw	?
		_ebx	LABEL	DWORD
		_bx	LABEL	WORD
		_bl	db	?
		_bh	db	?
			dw	?
		_edx	LABEL	DWORD
		_dx	LABEL	WORD
		_dl	db	?
		_dh	db	?
			dw	?
		_ecx	LABEL	DWORD
		_cx	LABEL	WORD
		_cl	db	?
		_ch	db	?
			dw	?
		_eax	LABEL	DWORD
		_ax	LABEL	WORD
		_al	db	?
		_ah	db	?
			dw	?
		_flags	dw	?
		_es	dw	?
		_ds	dw	?
		_fs	dw	?
		_gs	dw	?
		_return	LABEL	DWORD
		_ip	dw	?
		_cs	dw	?
		_stack	LABEL	DWORD
		_sp	dw	?
		_ss	dw	?	
RmCall		ENDS

AdamHeader	STRUC
		Signature		dd	?	; 'madA'
		LinkerVersion		dw	?
		MinVersion		dw	?
		ExeSize			dd	?
		ImageStart		dd	?	; relative to 'Adam'
		ImageSize		dd	?
		InitialMemory		dd	?
		InitialEIP		dd	?
		InitialESP		dd	?
		NumFixups		dd	?
		AdamFlags		dd	?
		RelocSize		dd	?	; optional ???
AdamHeader	ENDS

;
; I really hate to do this but some people might consider their contributions
; to a former freeware product a waste of time after 3.5 beta came out, so
; it's probably fair enough. Having a look at 3 different "Hello World"
; programs tells us that most likely:
;
Adam35Header	STRUC
		Signature_35		dd	?
		LinkerVersion_35	dw	?
		MinVersion_35		dw	?
		ImageSize_35		dd	?	; -header but +reloc
		ExeSize_35		dd	?
		ImageStart_35		dd	?
		InitialEIP_35		dd	?
		InitialMemory_35	dd	?
		InitialESP_35		dd	?
		RelocStart_35		dd	?
		LogoColor_35		db	?
		LogoDelay_35		db	?
		Flags_35		db	?	; bit 2 = Unreg.
							; bit 1 = Logo
							; bit 0 = Compress
					db	?
		UsuallyZero_35		dd	?	; no idea as of yet
Adam35Header	ENDS
		

ADAM_HEADER_SIZE	EQU	2Ch

;=============================================================================
; Code goes here...
;=============================================================================

.386p
code segment use32
assume cs:code, ds:code

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
; Allocate some memory to move the stack out of the .BSS area
;
		mov	edx, (OFFSET EndOfBss-OFFSET start+0FFFh+1024) AND 0FFFFF000h
		mov	ax, -1
		int	21h
		push	OFFSET strMemory
		jc	stringErrorExit

		mov	esp, edx
;
; Save PSP selector and set ES = DS
;
		mov	APIpspSelector, es
		push	ds
		pop	es
;
; Fixup zero base descriptor according to CPL
;
		mov	eax, ds
		lar	eax, eax
		and	eax, 0FF00h
		or	DWORD PTR [OFFSET dataDescriptor+4], eax
		mov	APIInitialDs, ds
;
; Allocate new descriptors
;
		push	OFFSET strDescriptor
		sub	eax, eax
		mov	cx, 4
		int	31h
		jc	stringErrorExit

		mov	ebx, eax
		mov	APIZeroBaseSelector, ax
;
; Set allocated descriptor to base 0, limit 4G
;
		mov	eax, ds
		lar	eax, eax
		or	DWORD PTR [OFFSET dataDescriptor+4], eax
		mov	ax, 0Ch
		mov	edi, OFFSET dataDescriptor
		int	31h
		jc	stringErrorExit

		add	bx, 8
		mov	APIZeroCodeSelector, bx
		or	BYTE PTR [OFFSET dataDescriptor+5], 8
		mov	ax, 0Ch
		mov	edi, OFFSET dataDescriptor
		int	31h
		jc	stringErrorExit

		xor	BYTE PTR [OFFSET dataDescriptor+5], 8
		add	bx, 8
		mov	APIDataSelector, ebx
		int	31h
		jc	stringErrorExit

		or	BYTE PTR [OFFSET dataDescriptor+5], 8
		add	bx, 8
		mov	APICodeSelector, ebx
		int	31h
		jc	stringErrorExit
;
; Allocate 8 kByte transfer buffer
;
		mov	bx, 200h
		mov	ax, 100h
		int	31h
		jc	stringErrorExit

		shl	eax, 4
		mov	APIFake8KBufferSeg, ax
;
; Get executable file name
;
		mov	DWORD PTR [esp], OFFSET strFile
		mov	ds, APIpspSelector

		ASSUME ds:NOTHING

		mov	es, ds: [2Ch]
		mov	ds, ds: [2Ch]
		sub	edi, edi
		or	ecx, -1
		sub	eax, eax
		cld

@@nextEnv:
		repne	scasb
		scasb
		jne	short @@nextEnv

		lea	edx, [edi+2]
		mov	eax, 0FFFDh
		int	21h
		jc	notOpenWfse

		cmp	eax, 57465345h		; 'WFSE'
		jne	notOpenWfse

		push	ds
		push	ss
		pop	ds
		push	edx
		mov	edx, OFFSET wfseName
		mov	eax, 3D00FFFDh
		int	21h
		pop	edx
		pop	ds
		jnc	openWfse

notOpenWfse:
		mov	ax, 3D00h
		int	21h

openWfse:
		push	ss
		pop	ds

		ASSUME ds:CODE

		mov	APIPathRelative, edx
		jc	stringErrorExit

		mov	ebx, eax		; EBX = file handle
		mov	eax, es
		call	getSelectorBase
		mov	APIEnvRelative, eax
		add	APIPathRelative, eax
		mov	eax, APIPspSelector
		call	getSelectorBase
		mov	APIPspRelative, eax
;
; Set ES back to our segment.
;
		push	ds
		pop	es
;
; Skip both, the WDosX kernel and this executable loader in executable image.
;
		sub	edx, edx
		test	bh, 80h
		jnz	skipSkip

		call	skipMZexe
		call	skipMZexe

skipSkip:
;
; Warning: For WFSE this is NOT correct!
;
		mov	APITotalPgmSize, edx
;
; Now, supposedly the file pointer is at the start of the user executable.
; Read in the DOS32 header.
;
		mov	ecx, ADAM_HEADER_SIZE
		mov	edx, OFFSET ExeHeader	; buffer start
		mov	ah, 3Fh			; (W)DOS read from file
		call	wfseHandler
;
; Check for various error conditions
;
		jc	stringErrorExit

		cmp	eax, ecx
		jne	stringErrorExit

		mov	DWORD PTR [esp], OFFSET strFormat
		cmp	DWORD PTR [edx], 'madA'
		jne	stringErrorExit
;
; Check whether we have a new format header and do some data swapping if so
;
		mov	ax, [edx].AdamHeader.LinkerVersion
		mul	ah
		cmp	ax, 3*50h
		setc	isOldVersion
		jc	headerFixDone		

		mov	eax, ExeHeader.Adam35Header.ImageSize_35
		mov	ecx, ExeHeader.Adam35Header.ExeSize_35
		mov	edx, ExeHeader.Adam35Header.ImageStart_35
		mov	esi, ExeHeader.Adam35Header.InitialEIP_35
		mov	edi, ExeHeader.Adam35Header.InitialESP_35
		mov	ebp, ExeHeader.Adam35Header.InitialMemory_35
		mov	ExeHeader.AdamHeader.ImageSize, eax
		mov	ExeHeader.AdamHeader.ExeSize, ecx
		mov	ExeHeader.AdamHeader.ImageStart, edx
		mov	ExeHeader.AdamHeader.InitialEIP, esi
		mov	ExeHeader.AdamHeader.InitialESP, edi
		mov	ExeHeader.AdamHeader.InitialMemory, ebp

headerFixDone:
		mov	eax, ExeHeader.AdamHeader.ExeSize
		add	APITotalPgmSize, eax
;
; Seek to the beginning of the image
;
		mov	eax, ExeHeader.AdamHeader.ImageStart
		sub	eax, ADAM_HEADER_SIZE
		jz	dontSeek

		mov	edx, eax
		shld	ecx, edx, 16
		mov	ax, 4201h
		call	wfseHandler
		jc	stringErrorExit
		
dontSeek:
		push	ebx
;
; Allocate the memory needed
;
		sub	ecx, ecx
		mov	eax, ExeHeader.AdamHeader.InitialMemory
		cmp	isOldVersion, 0
		je	noLinearReloc

		mov	ecx, ExeHeader.AdamHeader.NumFixups
		cmp	ExeHeader.AdamHeader.ImageStart, 28h
		jna	noLinearReloc

		add	eax, ExeHeader.AdamHeader.RelocSize

noLinearReloc:
		lea	eax, [ecx * 4 + eax + 0FFFh]
		and	ax, 0F000h
		mov	APITopOfMemory, eax
		mov	ecx, eax
		shld	ebx, eax, 16
		mov	ax, 0501h
		int	31h
		push	OFFSET strMemory
		jc	stringErrorExit
	
		shl	ebx, 16
		mov	edx, ebx
		mov	dx, cx
		mov	APISegmentBase, edx
		sub	APIPspRelative, edx
		sub	APIEnvRelative, edx
		sub	APIPathRelative, edx
		push	OFFSET strDescriptor
		shld	ecx, edx, 16
		mov	ebx, APIDataSelector
		mov	ax, 7
		int	31h
		jc	stringErrorExit

		add	bx, 8
		int	31h
		jc	stringErrorExit

		pop	ebx
		pop	ebx
		pop	ebx
		mov	eax, ds
		call	getSelectorBase
		sub	edx, eax
		mov	edi, ExeHeader.AdamHeader.ImageSize
		mov	ecx, edi
		cmp	isOldVersion, 0
		je	LinearRelocLoad

		mov	ecx, ExeHeader.AdamHeader.NumFixups
		lea	ecx, [ecx * 4 + edi]
		cmp	ExeHeader.AdamHeader.ImageStart, 28h
		jna	LinearRelocLoad

		add	ecx, ExeHeader.AdamHeader.RelocSize

LinearRelocLoad:
		mov	ah, 3Fh
		call	wfseHandler
		jc	stringErrorExit

		cmp	eax, ecx
		jne	stringErrorExit

		mov	ah, 3Eh
		call	wfseHandler
;
; If new format exe, fixup processing is entirely different.
;
		cmp	isOldVersion, 0
		je	fixupDone
;
; Do some "fixups"
;
		mov	ebx, APIDataSelector
		mov	ecx, ExeHeader.AdamHeader.NumFixups
		jecxz	fixupDone
		
fixupLoop:
		mov	eax, [edx+edi]
		add	edi, 4
		mov	[edx+eax], bx
		loop	fixupLoop

fixupDone:
		mov	ax, 0EEFFh
		int	31h
		mov	cl, ch
		mov	ch, 1
		shl	ch, cl
		mov	APIsystemType, ch
		mov	ax, 204h
		mov	bl, 21h
		int	31h
		mov	OldInt21Ofs, edx
		mov	OldInt21Sel, ecx
		mov	bl, 31h
		int	31h
		mov	OldInt31Ofs, edx
		mov	OldInt31Sel, ecx
		inc	eax
		mov	ecx, cs
		mov	edx, OFFSET NewInt31
		int	31h
		mov	bl, 21h
		mov	edx, OFFSET NewInt21
		int	31h
		cmp	isOldVersion, 0
		je	forceZeroBase
;
; Check whether there is linear relocation info.
;
		cmp	ExeHeader.AdamHeader.ImageStart, 28h
		jna	LinearRelocDone

		mov	ecx, ExeHeader.AdamHeader.RelocSize
		test	ecx, ecx
		jz	LinearRelocDone
		
forceZeroBase:
		mov	edx, APISegmentBase
		mov	eax, ds
		call	GetSelectorBase
		add	ExeHeader.AdamHeader.InitialEIP, edx
		add	ExeHeader.AdamHeader.InitialESP, edx
		add	APIpspRelative, edx
		add	APIenvRelative, edx
		add	APIpathRelative, edx
		add	APITopOfMemory, edx
		mov	ebp, edx
		sub	edx, eax
		mov	esi, ExeHeader.AdamHeader.NumFixups
		lea	esi, [esi*4+edx]
		add	esi, ExeHeader.AdamHeader.ImageSize
		mov	eax, APISegmentBase
		mov	APIsegmentBase, 0
		cmp	isOldVersion, 0
		jne	LinearFixupLoop
;
; The new fixup format is slightly more complicated allthough it saves quite
; some disk space/memory.
;
; EDX -> image
; EBP = delta
;
		mov	bx, APIZeroBaseSelector
		mov	esi, ExeHeader.Adam35Header.RelocStart_35
		sub	edi, edi

V35FixupLoop:
		cmp	esi, ExeHeader.AdamHeader.ImageSize
		jnc	LinearFixupDone

		sub	ecx, ecx

V35GetNextByte:
		movzx	eax, BYTE PTR [edx+esi]
		inc	esi
		ror	al, 4
		test	ExeHeader.Adam35Header.Flags_35, 4
		jnz	adjustRotate

		rol	al, 3

adjustRotate:
		test	al, al
		jns	deltaDone

		and	al, 7fh
		or	ecx, eax
		shl	ecx, 7
		jmp	V35GetNextByte

deltaDone:
		add	ecx, eax
		add	edi, ecx
		cmp	esi, ExeHeader.AdamHeader.ImageSize
		jnc	mustBeLinear

		cmp	BYTE PTR [esi+edx], 0
		jnz	mustBeLinear

		mov	[edx+edi], bx
		inc	esi
		jmp	V35FixupLoop

mustBeLinear:
		add	[edx+edi], ebp
		jmp	V35FixupLoop

LinearFixupLoop:
		mov	ebx, [esi+ecx-4]
		add	[ebx+edx-4], eax
		sub	ecx, 4
		jne	LinearFixupLoop

		mov	TMTFlag, 1

LinearFixupDone:
		movzx	eax, APIZeroBaseSelector
		mov	APIDataSelector, eax
		movzx	eax, APIZeroCodeSelector
		mov	APICodeSelector, eax

LinearRelocDone:
;
; Set entry conditions and jump to user program (+wake up Wudebug, if present)
;
		push	APICodeSelector
		push	ExeHeader.AdamHeader.InitialEIP
		mov	ebp, esp
		mov	ss, APIDataSelector
		mov	esp, ExeHeader.AdamHeader.InitialESP		
		mov	es, APIDataSelector
		mov	ecx, APITopOfMemory
		mov	edi, esp
		sub	ecx, edi
		shr	ecx, 2
		sub	eax, eax
		rep	stosd
		push	es
		pop	ds
		sub	ebx, ebx
		sub	edx, edx
		sub	esi, esi
		sub	edi, edi
		jmp	PWORD PTR cs:[ebp]

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

		shl	eax, 16
		shld	edx, eax, 16
		add	esp, 12			; Clean up the stack
		ret

skipMZexe	ENDP

;-----------------------------------------------------------------------------
; DOS32 API support
;

	ASSUME ds: NOTHING

APIcommonExitError:
		or	BYTE PTR [esp+8], 1
		iretd

APIcommonExitOk:
		and	BYTE PTR [esp+8], 0FEh
		iretd

Int33EE00:
		mov	ax, 0300h
		cmp	isOldVersion, 0
		jne	is300

		mov	al, 50h

is300:
		mov	bx, APIzeroBaseSelector
		mov	dl, APIsystemType	; 1 raw, 2 x, 3 v, 4 d
		jmp	APIcommonExitOk

Int33EE02:
		mov	ebx, APIsegmentBase
		mov	edx, APITotalPgmSize
		mov	esi, APIpspRelative
		mov	edi, APIenvRelative
		mov	ecx, APIpathRelative
		mov	ax, APIfake8kBufferSeg
		jmp	APIcommonExitOk

Int33EE20:
Int33EE21:
		cmp	APIcbStart, MAX_CALLBACKS
		jnc	APIcommonExitError

		push	ds
		push	es
		push	esi
		push	edi
		push	eax
		mov	ds, APIInitialDS

	ASSUME ds: code

		push	ds
		pop	es
		movzx	edi, APIcbStart
		and	al, 3
		lea	eax, [eax+eax+4]
		mov	[edi].APIcbTypes, al
		mov	[edi*4].APIcbTargets, esi
		mov	esi, [edi*4].APIcbHandlerTable
		imul	edi, 50
		add	edi, OFFSET APIcbStructures
		push	ds
		push	cs
		pop	ds
		mov	ax, 0303h
		int	31h
		pop	ds
		jc	cbNoInc

		inc	APIcbStart

cbNoInc:

	ASSUME ds: NOTHING

		pop	eax
		pop	edi
		pop	esi
		pop	es
		pop	ds
		jc	APIcommonExitError

		jmp	APIcommonExitOk

Int33EE40:
		cmp	APIallocsStart, 0
		je	APIcommonExitError

		push	ds
		mov	ds, APIInitialDS
		push	eax
		push	edx
		push	esi
		push	edi

	ASSUME ds: code

		dec	APIallocsStart
		movzx	eax, BYTE PTR APIallocsStart
		mov	edx, [eax*4].APIallocationHandles
		bt	APIallocationType, eax
		jc	wasDpmiAlloc

		mov	ax, 0101h
		jmp	undoAllocCommon

wasDpmiAlloc:
		mov	edi, edx
		shld	esi, edx, 16
		mov	ax, 0502h

undoAllocCommon:
		int	31h

	ASSUME ds: NOTHING

		pop	edi
		pop	esi
		pop	edx
		pop	eax
		pop	ds
		jmp	APIcommonExitOk

Int33EE41:
Int33EE42:
		cmp	APIallocsStart, MAX_ALLOC
		jnc	APIcommonExitError

		push	ds
		mov	ds, APIInitialDS
		pushad

	ASSUME ds: code

		movzx	ecx, BYTE PTR APIallocsStart
		bts	APIallocationType, ecx
		sub	al, 42h
		je	isDpmiAlloc

		btr	APIallocationType, ecx
		mov	bx, 800h
		mov	ax, 100h
		int	31h
		jc	noIncExit

		mov	[ecx*4].APIAllocationHandles, edx
		movzx	edx, ax
		shl	edx, 4
		cmp	dx, 0C000h
		jna	alignOk

		sub	dx, dx
		add	edx, 10000h

alignOk:
		mov	[esp].RmCall._ebx, edx
		sub	edx, APISegmentBase
		mov	[esp].RmCall._edx, edx
		sub	ebp, ebp
		jmp	allocIncAndExit

isDpmiAlloc:
		sub	esp, 30h
		mov	edi, esp
		push	es
		push	ss
		pop	es
		mov	ax, 500h
		int	31h
		pop	es
		mov	eax, [esp]
		add	esp, 30h
		and	ax, 0F000h
		push	ecx
		add	edx, 0FFFh
		and	edx, 0FFFFF000h
		jz	no4GAlloc

		cmp	edx, eax
		jna	allocStartOk
		
no4GAlloc:
		mov	edx, eax

allocStartOk:
		push	edx

allocTryIt:
		mov	cx, dx
		shld	ebx, edx, 16
		mov	ax, 0501h
		int	31h
		jnc	gotSomeMem

		sub	edx, 1000h
		jnz	allocTryIt
		
gotSomeMem:
		mov	eax, edx
		pop	ebp
		pop	edx

		mov	[esp].RmCall._eax, eax
		test	eax, eax
		jz	noIncExit

		mov	WORD PTR [edx*4].APIallocationHandles, di
		mov	WORD PTR [edx*4+2].APIallocationHandles, si
		shl	ebx, 16
		mov	bx, cx
		sub	ebx, APIsegmentBase
		mov	[esp].RmCall._edx, ebx
		clc

allocIncAndExit:
		inc	APIallocsStart

noIncExit:
		cmp	eax, ebp

	ASSUME ds: NOTHING

		popad
		pop	ds
		jc	APIcommonExitError

		jmp	APIcommonExitOk

APICallback:
		mov	eax, [esp]
		push	esi
		push	edi
		push	ds
		push	es
		push	fs
		push	gs
		mov	ds, cs: APIDataSelector
		push	cs
		push	OFFSET cbReturn
		push	cs: APICodeSelector
		push	cs: [eax*4].APIcbTargets
		mov	eax, es: _eax[edi]
		mov	ebx, es: _ebx[edi]
		mov	ecx, es: _ecx[edi]
		mov	edx, es: _edx[edi]
		mov	esi, es: _esi[edi]
		mov	ebp, es: _ebp[edi]
		mov	edi, es: _edi[edi]
		push	ds
		pop	es
		retf

cbReturn:
		pop	gs
		pop	fs
		pop	es
		pop	ds
		xchg	edi, [esp]
		mov	es: _eax[edi], eax
		mov	es: _ebx[edi], ebx
		mov	es: _ecx[edi], ecx
		mov	es: _edx[edi], edx
		pop	es: _edi[edi]
		mov	es: _esi[edi], esi
		mov	es: _ebp[edi], ebp
		pop	esi
		mov	eax, ds:[esi]
		mov	es: _return[edi], eax
		pop	eax
		movzx	eax, cs:[eax].APIcbTypes
		add	es: _sp[edi], ax
		iretd

newInt21:
;
; If serving a TMT Pascal thingy, we have to work around the extended FindNext
; of the WDosX kernel.
;
		cmp	TMTFlag, 0
		je	check4Fdone

		cmp	ah, 4Fh
		jne	check4Fdone

		push	eax
		mov	eax, [esp+8]
		cmp	ax, WORD PTR cs: [APICodeSelector]
		pop	eax
		jne	chainInt21

		and	BYTE PTR [esp + 8], 0FEh
		push	edi
		push	ecx
		push	ebx
		push	es
		push	ss
		pop	es
		sub	esp, 52
		mov	edi, esp
		mov	[esp].RmCall._ah, 4Fh
		mov	DWORD PTR [esp].RmCall._sp, 0
		sub	ecx, ecx
		mov	bl, 21h
		mov	ax, 300h
		int	31h
		mov	ax, [esp].RmCall._ax
		bt	[esp].RmCall._flags, 0
		lea	esp, [esp + 52]
		pop	es
		pop	ebx
		pop	ecx
		pop	edi
		adc	BYTE PTR [esp + 8], 0
		iretd

check4Fdone:
		cmp	ax, 4B00h
		jne	Int21TestFor42

Int214B00:
		and	BYTE PTR [esp + 8], 0FEh
		push	es
		pop	edi
		mov	es, APIinitialDS
		mov	es: APIExeParam0, esi
		mov	es: APIExeParam1, ds
		mov	es: APIExeParam2, edi
		mov	es: APIExeParam3, ds
		mov	edi, OFFSET APIExeParam0
		pushfd
		call	PWORD PTR cs:[OFFSET oldInt21Ofs]
		pop	edi
		pop	es
		adc	BYTE PTR [esp + 8], 0
		iretd

Int21TestFor42:
		cmp	ah, 42h
		jne	chainInt21

		push	eax
		mov	eax, [esp+8]
		cmp	ax, WORD PTR cs: [APICodeSelector]
		pop	eax
		jne	chainInt21

		or	BYTE PTR [esp + 8], 1
		push	ecx
		push	edx
		shld	ecx, edx, 16
		int	21h
		jc	noEAXAdjust

		shl	eax, 16
		shrd	eax, edx, 16
		and	BYTE PTR [esp + 16], 0FEh

noEAXAdjust:
		pop	edx
		pop	ecx
		iretd

chainInt21:	db	0EAh
oldInt21Ofs	dd	?
oldInt21Sel	dd	?

TMTFlag		db	0

NewInt31:
		cmp	ah, 0EEh
		jne	chainInt31

		cmp	al, 0
		je	Int33EE00

		cmp	al, 2
		je	Int33EE02

		cmp	al, 20h
		je	Int33EE20

		cmp	al, 21h
		je	Int33EE21

		cmp	al, 40h
		je	Int33EE40

		cmp	al, 41h
		je	Int33EE41

		cmp	al, 42h
		je	Int33EE42

chainInt31:	db	0EAh
oldInt31Ofs	dd	?
oldInt31Sel	dd	?


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


;=============================================================================
; Initialized data
;=============================================================================

		ALIGN	4

dataDescriptor		dq	0CF92000000FFFFh

APIAllocsStart		dd	0

APIcbStart		db	0

		ALIGN	4

;-----------------------------------------------------------------------------
; Create callback handler table
;
APIcbHandlerTable	LABEL	DWORD

i = 0
REPT MAX_CALLBACKS

	cHandLabel  CATSTR <APIcbHandler>, %i

		dd	OFFSET	cHandLabel

	i = i + 1

ENDM

;-----------------------------------------------------------------------------
; Create callback handlers
;

i = 0
REPT MAX_CALLBACKS

	cHandlLabel CATSTR <APIcbHandler>, %i

cHandlLabel	LABEL	NEAR

		push	i
		jmp	APICallBack

	i = i + 1

ENDM

strDescriptor		db	'Could not set DPMI descriptors.',0Dh,0Ah,'$'
strFile			db	'Error reading executable.',0Dh,0Ah,'$'
strFormat		db	'Executable format error.',0Dh,0Ah,'$'
strMemory		db	'Not enough memory.',0Dh, 0Ah,'$'
wfseName		db	'wdosxmain',0

;=============================================================================
; Uninitialized data
;=============================================================================

		ALIGN	4

;-----------------------------------------------------------------------------
; Create callback target table
;
APIcbTargets	dd	MAX_CALLBACKS dup (?)

;-----------------------------------------------------------------------------
; Create callback types table
;
APIcbTypes	db	MAX_CALLBACKS dup (?)

;-----------------------------------------------------------------------------
; Create callback structures - what a waste of memory, actually...
;
APIcbStructures		LABEL	NEAR

i = 0
REPT MAX_CALLBACKS

		RmCall	<>

	i = i + 1

ENDM

;-----------------------------------------------------------------------------
; Allocation tracking
;
APIAllocationHandles	dd	MAX_ALLOC dup (?)

APIAllocationType	dd	?		; low dword
			dd	?		; high dword

;-----------------------------------------------------------------------------
; Misc. uninitialized data
;
APIInitialDS		dd	?
APIDataSelector		dd	?
APICodeSelector		dd	?
APIPspSelector		dd	?
APIsegmentBase		dd	?
APITotalPgmSize		dd	?
APIpspRelative		dd	?
APIenvRelative		dd	?
APIpathRelative		dd	?
APITopOfMemory		dd	?

ExeHeader		AdamHeader <>

APIExeParam0		dd	?
APIExeParam1		dw	?
APIExeParam2		dd	?
APIExeParam3		dw	?

APIfake8kBufferSeg	dw	?
APIzeroBaseSelector	dw	?
APIzeroCodeSelector	dw	?

APIsystemType		db	?	; 1 raw, 2 x, 3 v, 4 d
isOldVersion		db	?

	ALIGN 4
EndOfBss LABEL NEAR
;
;=============================================================================
;
code	ENDS
	END	start
