; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/UTIL/import.asm 1.6 2003/06/24 01:41:12 MikeT Exp MikeT $
;
; ----------------------------------------------------------------------------
;
; $Log: import.asm $
; Revision 1.6  2003/06/24 01:41:12  MikeT
; Import by ordinal no longer unsupported, just suspicious.
;
; Revision 1.5  1999/11/11 20:36:14  MikeT
; Some linkers leave OriginalFirstThunk blank. If so, we use FirstThunk instead..
;
; Revision 1.4  1999/04/10 15:54:54  MikeT
; Use OriginalFirstThunk instead of FirstThunk when walking down the import
; records array. This is fixes an issue with ALINK 1.5 which does not zero
; terminate the FirstThunk array. Should be fixed in ALINK 1.6, though.
;
; Revision 1.3  1999/02/07 18:21:22  MikeT
; Updated copyright + some cosmetics.
;
; Revision 1.2  1998/08/23 14:15:50  MikeT
; Fix # sections
;
; Revision 1.1  1998/08/03 02:53:11  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## LoadLibrary and other dll loading stuff                                ##
; ############################################################################

.386p

include w32struc.inc

.model flat, C

;
; A maximum of 32 slots exists for keeping track of modules.
;
MAX_WDLS	EQU	32

.code

;		EXTRN		lstrcmpi: NEAR
;		EXTRN		lstrlen: NEAR
;		EXTRN		lstrcpy: NEAR

		EXTRN		malloc: NEAR
		EXTRN		free: NEAR
		EXTRN		printf: NEAR

		EXTRN		WdosxAddfile:NEAR

;		PUBLIC		peImport
;		PUBLIC		WdlDirectory
;		PUBLIC		getModuleFromAddress

		PUBLIC		WdosxAddWdls

WdosxAddWdls PROC NEAR
		pushad
		mov	edx, [esp + 16 + 32]	; argv[0]
		mov	ecx, OFFSET FullPath

@@pCpyStart:
		mov	al, [edx]
		inc	edx
		mov	[ecx], al
		inc	ecx
		test	al, al
		jnz	@@pCpyStart

@@pFindLoop:
		dec	ecx
		cmp	BYTE PTR [ecx - 1], '\'
		jne	@@pFindLoop

		mov	FnameAppend, ecx

.data?

FullPath	db	128 dup (?)
FnameAppend	dd	?
TrueName	dd	?

.code
		mov	DWORD PTR [esp + 28], 0
		mov	edx, [esp + 4 + 32]	; hostfile
		mov	TheHostfile, edx
		mov	edx, [esp + 8 + 32]
		mov	ax, 3D00h
		int	21h
		jc	adderr

		mov	ebx, eax
		mov	eax, [esp + 12 + 32]
		call	LoadWdlFromFile
		push	eax
		mov	ah, 3eh
		int	21h
		pop	eax
		test	eax, eax
		jz	adderr
;
; eax = hmodule
;
		call	peRelocate
		call	peImport
		mov	DWORD PTR [esp + 28], 1

adderr:
		popad
		ret
WdosxAddWdls ENDP


.data

WdlSlots	dd	-1
LastFail	dd	0

.data?

TheHostfile	dd	?


		align 4

WdlDirectory	WdlInfo MAX_WDLS dup (<>)

.code

;+----------------------------------------------------------------------------
; Win32 - FreeLibrary
;
FreeLibrary PROC NEAR

		mov	eax, MAX_WDLS - 1	; current WDL slot

@@flLoop:
		bt	WdlSlots, eax
		jc	short @@flIterate

		push	eax
		imul	eax, WDL_INFO_SIZE
		mov	eax, [eax+OFFSET WdlDirectory.WdlInfo.Handle]
		cmp	eax, [esp+8]
		pop	eax
		jne	short @@flIterate

		mov	edx, eax
		imul	eax, WDL_INFO_SIZE
		dec	DWORD PTR [eax+OFFSET WdlDirectory.WdlInfo.Count]
		jz	short @@flDone
;
; Free module slot (don't, as the info is just what we're looking for)
;
;		bts	WdlSlots, edx
		mov	eax, [eax+OFFSET WdlDirectory.WdlInfo.Handle]
;
; Free memory
;
		push	DWORD PTR [eax+OFFSET WdlDirectory.WdlInfo.Handle]
		call	free
		add	esp, 4

@@flDone:
		mov	eax, 1
		retn	4

@@flIterate:
		dec	eax
		jns	short @@flLoop

		inc	eax
		retn	4

FreeLibrary ENDP

;+----------------------------------------------------------------------------
; Win32 - LoadLibraryExA
;
LoadLibraryExA PROC NEAR

		push	ebx
		mov	eax, WdlSlots
		bsf	eax, eax
		jnz	short @@slotFound

		inc	eax
		jmp	@@llExaError

@@slotFound:
		push	eax
		imul	ecx, eax, WDL_INFO_SIZE
		add	ecx, OFFSET WdlDirectory.WdlInfo.FileName
		mov	eax, [esp+12]
		push	ecx
		sub	dh, dh

@@findDot:
		mov	dl, [eax]
		inc	eax
		mov	[ecx], dl
		inc	ecx
		cmp	dl, '.'
		jne	short @@notDot

		inc	dh

@@notDot:
		test	dl, dl
		jnz	short @@findDot

		test	dh, dh
		jnz	short @@fixDLL

		mov	BYTE PTR [ecx-1], '.'
		mov	DWORD PTR [ecx], 'ldw'
		jmp	short @@fNameComplete

@@fixDLL:
		mov	eax, [ecx-4]
		or	eax, 202020h
		cmp	eax, 'lld'
		jnz	short @@fNameComplete

		mov	word ptr [ecx-4], 'dw'

@@fNameComplete:
		pop	edx
		mov	TrueName, edx
		mov	eax, 3D00h
		int	21h
		sbb	ebx, ebx
		not	ebx
		and	eax, ebx
		pop	ebx
		jnz	short @@llExaOpen
;
; Try current directory
;
		mov	ecx, FnameAppend

@@llexaCopyFileName:
		mov	al, [edx]
		inc	edx
		mov	[ecx], al
		inc	ecx
		test	al, al
		jnz	short @@llexaCopyFileName

		mov	edx, OFFSET FullPath
		mov	ax, 3D00h
		int	21h
		sbb	ecx, ecx
		not	ecx
		and	eax, ecx
		jz	@@llExaError

@@llExaOpen:
		push	eax
		push	edx
		push	OFFSET loadstr
		call	printf
		pop	edx
		pop	edx

		push	10h
		push	0
		push	TrueName
		push	edx
		push	TheHostfile
		call	WdosxAddfile
		add	esp, 20
		test	eax, eax
		pop	eax
		jz	short @@llExaError

		push	eax
		push	edx
		push	OFFSET crlfstr
		call	printf
		pop	edx
		pop	edx
		test	eax, eax
		pop	eax
		jz	short @@llExaError


.data

loadstr		db	'Adding WDL module %s',0
crlfstr		db	 0ah ,0


.code
		push	ebx
		mov	ebx, eax
		sub	eax, eax
		call	loadWdlFromFile
		test	eax, eax
		pop	ecx
		jz	short @@llExaError

		push	eax
		mov	ah, 3Eh
		int	21h
		pop	eax

		btr	WdlSlots, ecx
;
; EDX -> WdlInfo, store hModule
;
		mov	edx, TrueName
		mov	[edx.WdlInfo.Handle], eax
;
; Set reference count
;
		mov	[edx.WdlInfo.Count], 1

		test	BYTE PTR [esp+16], LOAD_LIBRARY_AS_DATAFILE
		jne	@@llExaError
;
; Relocate the image
;
		call	peRelocate
;
; Process imports and recursively load more modules, if needed
;
		call	peImport

@@llExaError:
		pop	ebx
		retn	12

LoadLibraryExA ENDP

;+----------------------------------------------------------------------------
; Win32 - LoadLibraryA
;
LoadLibraryA PROC NEAR

		push	0
		push	0
		push	DWORD PTR [ESP+12]
		call	LoadLibraryExA
		retn	4

LoadLibraryA ENDP

.data
		gmhLastServed	dd	-1

.data?
		gmhLastAnswer	dd	?

.code
;+----------------------------------------------------------------------------
; Win32 - GetModuleHandleA
;
GetModuleHandleA PROC NEAR

		mov	eax, [esp+4]

@@gmhTheRealThing:
		mov	eax, MAX_WDLS - 1	; current WDL slot

@@gmhLoop:
		bt	WdlSlots, eax
		jc	short @@gmhIterate

		push	eax
		push	dword ptr [esp+8]
		imul	eax, WDL_INFO_SIZE
		mov	eax, [eax+OFFSET WdlDirectory.WdlInfo.Handle]
		mov	edx, eax
		mov	eax, [eax+60]
		mov	eax, [eax+edx+78h]
		mov	eax, [eax+edx+12]
		add	eax, edx
		push	eax
		call	lstrcmpi
		test	eax, eax
		pop	eax
		jnz	short @@gmhIterate

		imul	eax, WDL_INFO_SIZE
		mov	eax, [eax+OFFSET WdlDirectory.WdlInfo.Handle]
		retn	4

@@gmhIterate:
		dec	eax
		jns	short @@gmhLoop

		inc	eax
		retn	4

GetModuleHandleA ENDP

;+----------------------------------------------------------------------------
; Win32 - GetModuleFileNameA
;
GetModuleFileNameA PROC NEAR

		mov	eax, MAX_WDLS - 1	; current WDL slot

@@gmfLoop:
		bt	WdlSlots, eax
		jc	short @@gmfIterate

		push	eax
		imul	eax, WDL_INFO_SIZE
		mov	eax, [eax+OFFSET WdlDirectory.WdlInfo.Handle]
		cmp	eax, [esp+8]
		pop	eax
		jnz	short @@gmfIterate

		push	eax
		imul	eax, WDL_INFO_SIZE
		push	DWORD PTR [eax+OFFSET WdlDirectory.WdlInfo.FileName]
		call	lstrlen
		cmp	eax, [esp+16]
		mov	edx, eax
		pop	eax
		ja	short @@gmfFail

		push	edx
		push	DWORD PTR [eax*4+OFFSET WdlDirectory.WdlInfo.FileName]
		push	DWORD PTR [esp+12]
		call	lstrcpy
		pop	eax
		retn	12

@@gmfIterate:
		dec	eax
		jns	short @@gmfLoop

@@gmfFail:
		sub	eax, eax
		retn	12

GetModuleFileNameA ENDP

;+----------------------------------------------------------------------------
; Win32 - GetProcAddress
;
GetProcAddress PROC NEAR

		push	ebx
		push	esi
		push	edi
;
; Get hModule
;
		mov	edx, [esp+16]
;
; Quick sanity check
;
		sub	eax, eax
		cmp	word ptr [edx], 'ZM'
		jnz	@@gpaExit

		mov	edx, [edx+60]
		add	edx, [esp+16]

		cmp	dword ptr [edx], 'EP'
		jnz	@@gpaExit
;
; Now it's quite reasonable to assume that the supplied handle is a valid one
;
		mov	edx, [edx+78h]
		add	edx, [esp+16]
;
; EDX now points to the start of .edata
;
; [edx+12] -> module name	 RVA
; [edx+16] =  ordinal base
; [edx+20] =  number of addresses
; [edx+24] =  number of names
; [edx+28] -> array of n address RVA
; [edx+32] -> array of n names*  RVA
;
		mov	ecx, [edx+24]
		jecxz	@@gpaExit
;
; Walk through all the strings until either match or end of array
;
		mov	edi, [edx+32]
		add	edi, [esp+16]

@@gpaLoop:
;		mov	ebx, [edi-4]
		mov	ebx, [edi]
		add	edi, 4
		add	ebx, [esp+16]
		mov	esi, [esp+20]

@@gpaCmpStr:
		mov	al, [ebx]
		mov	ah, [esi]
		or	ah, al
		jz	short @@gpaOrdinalFound

		cmp	al, [esi]
		jne	short @@gpaCheckNext

		inc	esi
		inc	ebx
		jmp	short @@gpaCmpStr

@@gpaCheckNext:
		loop	short @@gpaLoop
;
; We had no luck in this case, return error
;
		sub	eax, eax
		jmp	short @@gpaExit

@@gpaOrdinalFound:
;
; Finally, we found the function name we were looking for, (numNames - ECX) is
; the ordinal number of the function address we are looking for.
;
		mov	eax, [edx+24]
		sub	eax, ecx
		mov	ecx, [edx+24h]
		add	ecx, [esp+16]
		movzx	eax, WORD PTR [eax*2+ecx]
		mov	eax, [edx+eax*4+28h]
		add	eax, [esp+16]

@@gpaExit:
		pop	edi
		pop	esi
		pop	ebx
		retn	8

GetProcAddress ENDP

; ############################################################################
; ## Helper functions                                                       ##
; ############################################################################

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
		jz	short @@relocDone

;		mov	ecx, [ebp+0A4h]
; Some sick incarnation of TLINK32 would create a fixup section of size 0
;
		cmp	DWORD PTR [ebp+0A4h], 0
		jz	short @@relocDone

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
		movzx	ebp, word ptr [edi+esi]
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
; peImport - Resolve module import references in a PE image.
;
; Entry:	EAX = hModule
; Exit:
;
; This procedure might bomb out at any time with an error if an import could
; not be resolved as this is a fatal error condition.
;
; For obvious reasons, this procedure will be called recursively.
;
peImport	PROC NEAR

		pushad
;
; get rva of .idata
;
		mov	ebp, [eax+60]
		mov	ebp, dword ptr [ebp+eax+80h]
;
; Convert RVA to offset
;
		test	ebp, ebp
		jz	importDone

		add	ebp, eax

importNextDescriptor:
;
; Check if last in chain
;
		test	dword ptr [ebp+12], -1	; No module name?
		jz	importDone		; O.k. ready then

		add	eax, [ebp+12]
		push	eax
		call	GetModuleHandleA
		test	eax, eax
		jnz	short importModuleFound

		mov	eax, [esp+28]
		add	eax, [ebp+12]
		push	eax
		call	LoadLibraryA
		test	eax, eax
		jnz	short importModuleFound
;
;		ERROR - MODULE NOT FOUND
;		[EBP+12] -> module name
;		[ESP+28] = hModule of importer
;
		mov	eax, [esp+28]
		add	eax, [ebp+12]
		cmp	eax, LastFail
		mov	LastFail, eax
		jz	importResolved
		
		push	eax
		push	OFFSET importStrErr1
		call	printf
		add	esp, 4 * 2
		sub	eax, eax
		mov	ebx, [ebp+16]
		add	ebx, [esp+28]
		jmp	importResolved

.data

importStrErr1	db	'Warning: WDL module %s not linked.', 0ah, 0

.code
importModuleFound:
		mov	edi, eax
;
; Rva of import_lookup_table
;
		mov	ebx, [ebp]		; ALINK bug: use Original 1st
		test	ebx, ebx		; Then again, Delphi 5: no OFT
		jnz	oftNotZero

		mov	ebx, [ebp+16]

oftNotZero:
		add	ebx, [esp+28]

importNextLabel:
		mov	eax, [esp+28]
		mov	esi, [ebx]
		test	esi, esi
		jns	importNoOrdinal		; No import by ordinal!
;
;		ERROR - CANNOT IMPORT BY ORDINAL
;		[EBP+12] -> Module name of supposed exporter
;		ESI (LOW) Function ordinal number
;		[ESP+28] = hModule of importer
;
		mov	edx, esp
		mov	eax, [esp+28]
		add	eax, [ebp+12]
		push	eax
		push	OFFSET importStrErr2
		call	printf
		add	esp, 4 * 2
		jmp	importResolved

.data

importStrErr2	db	'Warning: WDL module %s - import by ordinal.', 0ah, 0

.code

importNoOrdinal:
		jnz	short importString
;
; All references into given module resolved, get next module.
;
		add	ebp, 20
		jmp	importNextDescriptor

importString:
		lea	esi, [esi+eax+2]	; Ignore hint
;
; ESI -> Import label to resolve. 
; EDI = hModule of exporter
; EBX -> Target address to fix
;
		push	esi
		push	edi
		call	GetProcAddress
		test	eax, eax
		jnz	short importResolved
;
;		ERROR - CANNOT RESOLVE DYNALINK
;		[EBP+12] -> Module name of supposed exporter
;		ESI -> Function name that could not be resolved
;		[ESP+28] = hModule of importer
;
		mov	eax, [esp+28]
		add	eax, [ebp+12]
		push	eax
		push	esi
		push	OFFSET importStrErr3
		call	printf
		add	esp, 12

.data

importStrErr3	db	'Warning: Missing import %s from module %s.',0ah, 0

.code
importResolved:
;		mov	[ebx], eax
		add	ebx, 4
		jmp	importNextLabel

importDone:
		popad
		ret

peImport	ENDP

;-----------------------------------------------------------------------------
; loadWdlFromFile - load an umcompressed PE image from a file.
;
; Entry:	EBX = File handle
;		EAX = file offset of module within image
;
; Exit:		EAX = hModule
;		EAX = 0 -> ERROR
;
; Modifies:	Minor flags destroyed
;
; The file pointer will be moved during the load operation. The caller must
; open and close the file and preserve the file pointer, if necessary. Another
; side effect of this function is that it allocates memory via VirtualAlloc().
;
; This function will NOT do any relocation, imports etc, it just maps the raw
; image into the caller's address space.
;
loadWdlFromFile	PROC NEAR

		pushad
		mov	ebp, esp
;
; Set file pointer accordingly
;
		shld	ecx, eax, 16
		mov	edx, eax
		mov	eax, 4200h
		int	21h
		jc	loadFileError
;
; Allocate some temp storage to determine the image size
;
		mov	ecx, 64
		sub	esp, 68h
		mov	edx, esp
		mov	ah, 3Fh
		int	21h
		jc	loadFileError

		cmp	eax, ecx
		jne	loadFileError
;
; Check for MZ .EXE signature
;
		cmp	word ptr [esp], 'ZM'
		jnz	loadFileError
;
; Get offset to PE header and load first bytes there
;
		mov	edx, [esp+60]
		mov	edi, edx		; Save MZ EXE size
		sub	edx, 64
		jz	short loadFileAtPE

		shld	ecx, edx, 16
		mov	eax, 4201h
		int	21h
		jc	loadFileError

loadFileAtPE:
		mov	ecx, 68h
		mov	edx, esp
		mov	ah, 3Fh
		int	21h
		jc	loadFileError

		cmp	eax, ecx
		jne	loadFileError
;
; Verify whether the image pretends to be a PE or not
;
		cmp	dword ptr [esp], 'EP'
		jnz	loadFileError
;
; Get the size of memory needed to load all of the image
;
		mov	ecx, [esp+50h]
		add	ecx, 0FFFh
		and	ecx, 0FFFFF000h
;
; Release temporary storage
;
		add	esp, 68h
;
; Try to allocate a memory block
;
		push	ecx		; Size
		call	malloc
		add	esp, 4
		test	eax, eax
		jz	loadFileError

		mov	esi, eax	; esi = hModule from now on
;
; lSeek back to the start of the image
;
		mov	edx, [esp+28]
		shld	ecx, edx, 16
		mov	eax, 4200h
		int	21h
		jc	loadFileError
;
; Load first portion of image (that'd be the MZ)
;
		mov	edx, esi
		mov	ecx, edi
		mov	ah, 3Fh
		int	21h
		jc	loadFileError

		cmp	eax, ecx
		jne	loadFileError
;
; We keep in mind that [esi] = 'MZ' and [edi] = 'PE'
; Load the first header bytes now
;
		lea	edx, [esi+edi]
		mov	ecx, 24
		mov	ah, 3Fh
		int	21h
		jc	loadFileError

		cmp	eax, ecx
		jne	loadFileError
;
; Get the not-so-optional header size and load the coff heder
;
		movzx	ecx, word ptr [edx+20]
		add	edx, 24
		mov	ah, 3Fh
		int	21h
		jc	loadFileError

		cmp	eax, ecx
		jne	loadFileError
;
; Load section table
;
		mov	ecx, [esi + 60]
		movzx	ecx, BYTE PTR [esi + ecx + 6]
		add	edx, eax		; set pointer where to store
		imul	ecx, 28h
		mov	ah,3Fh
		int	21h
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
		add	ecx, edx
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
		test	edx, edx			; M$ linker sets this 0
		jz	short loadNextSection		; for .bss

		add	edx, [esp+28+4]			; Adjust file offset
		shld	ecx, edx, 16
		mov	eax, 4200h
		int	21h
		jc	loadFileError

		mov	edx, [edi+12]			; Get RVA
		mov	ecx, [edi+16]			; Get size
		add	edx, esi			; RVA -> offset
		mov	ah, 3Fh
		int	21h
		jc	loadFileError

		cmp	eax, ecx
		jne	loadFileError

loadNextSection:
		add	edi, 40
		jmp	short loadImageSection

loadFileError:
		sub	esi, esi

loadFileDone:
		mov	esp, ebp
;
; Store hModule in pushad stack_frame.eax
;
		mov	[esp+28], esi
		popad
		ret

loadWdlFromFile	ENDP

lstrlen:
		mov	edx, [esp+4]
		sub	eax, eax

lstrlen00:
		cmp	byte ptr [edx+eax], 0
		jz	short lstrlen01

		inc	eax
		jmp	short lstrlen00

lstrlen01:
		retn	4

; ############################################################################

lstrcpy:
lstrcpyA:
		mov	edx, [esp+4]
		mov	ecx, [esp+8]

lstrcpy00:
		mov	al, [ecx]
		inc	ecx
		mov	[edx], al
		inc	edx
		test	al, al
		jnz	short lstrcpy00

		mov	eax, [esp+4]
		retn	8

; ############################################################################

lstrcmpi:
lstrcmpiA:
		mov	edx, [esp+4]
		mov	ecx, [esp+8]
		sub	eax, eax

lstrcmpi00:
		mov	al, [edx]
		cmp	al, 'A'

		jc	short lstrcmpi001
		cmp	al, 'Z'

		ja	short lstrcmpi001
		or	al, 20h

lstrcmpi001:
		mov	ah, [ecx]
		cmp	ah, 'A'
		jc	short lstrcmpi002

		cmp	ah, 'Z'
		ja	short lstrcmpi002

		or	ah, 20h

lstrcmpi002:
		sub	al, ah
		sbb	ah, ah
		cmp	byte ptr [edx], 0
		jz	short lstrcmpi01

		cmp	byte ptr [ecx], 0
		jz	short lstrcmpi01

		inc	edx
		inc	ecx
		test	eax, eax
		jz	short lstrcmpi00

lstrcmpi01:
		movsx	eax, ax
		retn	8

		END
