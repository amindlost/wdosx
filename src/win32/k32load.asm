; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/WIN32/k32load.asm 1.14 2003/06/24 01:23:43 MikeT Exp MikeT $
;
; ----------------------------------------------------------------------------
;
; $Log: k32load.asm $
; Revision 1.14  2003/06/24 01:23:43  MikeT
; Untested: Also support import by ordinal.
;
; Revision 1.13  2003/04/24 20:38:31  MikeT
; Unresolved import do not automatically force a program abort at load time.
;
; Revision 1.12  2001/11/23 00:14:24  MikeT
; Apply sanity check before using module export section. Add a call to InitTls
; before the entry point call of each DLL (or WDL for that matter).
;
; Revision 1.11  1999/12/12 22:00:39  MikeT
; Two changes suggested by Oleg Prokhorov:
; 1. Implement stub for GetModuleFileNameW
; 2. Have LoadLibraryExA call GetModuleHandle first, as Windows does
;
; Revision 1.10  1999/11/11 20:32:55  MikeT
; Can cope with linkers leaving the ORIGINAL FIRST THUNK clear now.
; The import routine has been changed to copy FIRST THUNK into OFT if the
; latter was found blank.
;
; Revision 1.9  1999/08/10 19:21:08  MikeT
; Corrected header which got screwed up somehow during previous check in.
;
; Revision 1.8  1999/07/06 22:59:04  MikeT
; Modify LoadLibraryExA() to also look for files with a DLL extension if no
; WDL found. This has been done to reduce the number of complaints I receive.
;
; Revision 1.7  1999/04/07 00:24:13  MikeT
; Implemented workaround for an issue with ALINK. ALINK doesn't null
; terminate the IMAGE_THUNK_DATA array in FirstThunk. We now use
; OriginalFirstThunk as Windows does.
;
; Revision 1.6  1999/03/10 01:17:57  MikeT
; Fix the broken implementation of GetModuleFileName(). Particularly,
; this would fix problems with DLLs created with Delphi 3 or higher.
;
; Revision 1.5  1999/02/07 21:11:08  MikeT
; Updated copyright.
;
; Revision 1.4  1998/08/23 14:24:17  MikeT
; Fix the previous fix
;
; Revision 1.3  1998/08/23 14:18:15  MikeT
; Fix # sections
;
; Revision 1.2  1998/08/23 04:10:23  MikeT
; Fix BCB image dir
;
; Revision 1.1  1998/08/03 01:43:19  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## LoadLibrary and other dll loading stuff                                ##
; ############################################################################

.386p

include w32struc.inc

.model flat

;
; A maximum of 32 slots exists for keeping track of modules.
;
MAX_WDLS	EQU	32

.code

		PUBLICDLL		GetModuleHandleA
		PUBLICDLL		GetModuleFileNameA
		PUBLICDLL		GetModuleFileNameW
		PUBLICDLL		GetProcAddress
		PUBLICDLL		LoadLibraryA
		PUBLICDLL		LoadLibraryExA
		PUBLICDLL		FreeLibrary

		EXTRN		MainModuleHandle: DWORD
		EXTRN		MainModuleFileName: DWORD
		EXTRN		GenericError: NEAR
		EXTRN		VirtualAlloc: NEAR
		EXTRN		VirtualFree: NEAR
		EXTRN		lstrcmpi: NEAR
		EXTRN		lstrlen: NEAR
		EXTRN		lstrcpy: NEAR
		EXTRN		wfseHandler: NEAR
		EXTRN		isLoadTime: BYTE
		EXTRN		GetCommandLineA: NEAR
		EXTRN		InitTls: NEAR

		PUBLIC		peImport
		PUBLIC		WdlDirectory
		PUBLIC		getModuleFromAddress

.data

WdlSlots	dd	-2

.data?

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
; Free module slot
;
		bts	WdlSlots, edx
		push	edx
		mov	eax, [eax+OFFSET WdlDirectory.WdlInfo.Handle]
		push	eax
		mov	ecx, [eax+60]
		mov	ecx, [eax+ecx+28h]
		add	ecx, eax
		push	0
		push	DLL_PROCESS_DETACH
		push	eax
		call	ecx
		test	eax, eax
		pop	eax
		pop	edx
		jz	@@flClearToNuke

		btr	WdlSlots, edx
		sub	eax, eax
		retn	4

@@flClearToNuke:
;
; Free memory
;
		push	80h
		push	0
		push	DWORD PTR [eax+OFFSET WdlDirectory.WdlInfo.Handle]
		call	VirtualFree

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
		push	esi
		push	ebx
		push	DWORD PTR [esp + 12]
		call	GetModuleHandleA
		test	eax, eax
		jnz	@@llExaDone

		mov	esi, -1			; indicate first run (WDL)

@@llExaOneRun:
		mov	eax, WdlSlots
		bsf	eax, eax
		jnz	short @@slotFound

		inc	eax
		jmp	@@llExaError

@@slotFound:
		push	eax
		imul	ecx, eax, WDL_INFO_SIZE
		add	ecx, OFFSET WdlDirectory.WdlInfo.FileName
		mov	eax, [esp+16]
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
		test	esi, esi
		jnz	SHORT @@fixForWdl

		mov	DWORD PTR [ecx], 'LLD'
		jmp	short @@fNameComplete

@@fixForWdl:
		mov	DWORD PTR [ecx], 'LDW'
		jmp	short @@fNameComplete

@@fixDLL:
		mov	eax, [ecx-4]
		or	eax, 202020h
		cmp	eax, 'lld'
		jnz	short @@fNameComplete

		test	esi, esi
		jz	SHORT @@fNameComplete

		mov	word ptr [ecx-4], 'DW'

@@fNameComplete:
		pop	edx
		mov	eax, 3D00h
		call	wfseHandler
		sbb	ebx, ebx
		not	ebx
		and	eax, ebx
		pop	ebx
		jnz	short @@llExaFileOpen
;
; Try current directory
;
		mov	BYTE PTR [edx + 12], 0		; sanity
		call	GetCommandLineA
		sub	esp, 128
		push	edx
		lea	edx, [esp + 4]

@@llexaEndPathLoop:
		mov 	cl, [eax]
		inc	eax
		mov	[edx], cl
		inc	edx
		cmp	cl, 21h
		jnc	short @@llexaEndPathLoop

@@llexaFindPathLoop:
		dec	edx
		cmp	BYTE PTR [edx -1], '\'
		jnz	short @@llexaFindPathLoop

		pop	ecx
		push	ecx

@@llexaCopyFileName:
		mov	al, [ecx]
		inc	ecx
		mov	[edx], al
		inc	edx
		test	al, al
		jnz	short @@llexaCopyFileName

		lea	edx, [esp + 4]
		mov	ax, 3D00h
		int	21h
		pop	edx
		sbb	ecx, ecx
		add	esp, 128
		not	ecx
		and	eax, ecx
		jz	short @@llExaError

@@llExaFileOpen:
		push	ebx
		mov	ebx, eax
		sub	eax, eax
		call	loadWdlFromFile
		test	eax, eax
		pop	ecx
		jz	short @@llExaError

		push	eax
		mov	ah, 3Eh
		call	wfseHandler
		pop	eax

		btr	WdlSlots, ecx
;
; EDX -> WdlInfo, store hModule
;
		mov	[edx.WdlInfo.Handle], eax
;
; Set reference count
;
		mov	[edx.WdlInfo.Count], 1

		test	BYTE PTR [esp+20], LOAD_LIBRARY_AS_DATAFILE
		jne	@@llExaError
;
; Relocate the image
;
		call	peRelocate
;
; Process imports and recursively load more modules, if needed
;
		call	peImport
;
; Call the entry point of the DLL.
;
		push	ecx
		push	eax

		mov	ecx, [eax+60]
		mov	ecx, [eax+ecx+28h]
		add	ecx, eax
		push	0
		push	DLL_PROCESS_ATTACH
		push	eax
		push	eax
		call	InitTls
		call	ecx
		test	eax, eax
		pop	eax
		pop	ecx
		jnz	@@llExaError

		bts	WdlSlots, ecx

		push	80h
		push	0
		push	eax
		call	VirtualFree

		sub	eax, eax

@@llExaError:
;
; Lean mean hack in here - if the file could not be opened as WDL, try to
; find a DLL with the same name.
;
		inc	esi
		jnz	@@llExaDone

		test	eax, eax		; did we get a handle?
		jz	@@llExaOneRun		; Try again

@@llExaDone:
		pop	ebx
		pop	esi
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
		test	eax, eax
		jnz	short @@gmhIsDLL

		mov	eax, MainModuleHandle
		retn	4

@@gmhIsDLL:
;
; Speedup load time linking.
;
		cmp	isLoadTime, 0
		jz	@@gmhTheRealThing

		cmp	eax, gmhLastServed
		mov	gmhLastServed, eax
		jne	@@gmhTheRealThing

		mov	eax, gmhLastAnswer
		retn	4

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
		cmp	eax, 1
		sbb	eax, 0
		jc	@@gmhExit

		mov	eax, [eax+edx+12]
		add	eax, edx
		push	eax
		call	lstrcmpi
		test	eax, eax
		pop	eax
		jnz	short @@gmhIterate

		imul	eax, WDL_INFO_SIZE
		mov	eax, [eax+OFFSET WdlDirectory.WdlInfo.Handle]
		mov	gmhLastAnswer, eax
		retn	4

@@gmhIterate:
		dec	eax
		jns	short @@gmhLoop

@@gmhExit:
		mov	gmhLastServed, eax
		inc	eax
		retn	4

GetModuleHandleA ENDP

;+----------------------------------------------------------------------------
; Win32 - GetModuleFileNameA
;
GetModuleFileNameA PROC NEAR

		mov	eax, [esp+4]
		test	eax, eax
		jz	short @@gmfIsMain

		cmp	eax, MainModuleHandle
		jnz	short @@gmfIsDLL

@@gmfIsMain:
		push	MainModuleFileName
		call	lstrlen
		cmp	eax, [esp+12]
		ja	short @@gmfFail

		push	eax
		push	MainModuleFileName
		push	DWORD PTR [esp+16]
		call	lstrcpy
		pop	eax
		retn	12

@@gmfIsDLL:
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

		imul	eax, WDL_INFO_SIZE
		add	eax, OFFSET WdlDirectory.WdlInfo.FileName
		push	eax
		push	eax
		call	lstrlen
		cmp	eax, [esp+16]
		mov	edx, eax
		pop	eax
		ja	short @@gmfFail

		push	edx
;
; [ESP + 0] = size
; [ESP + 4] = return address
; [ESP + 8] = hModule
;
		push	eax
		push	DWORD PTR [esp+16]
		call	lstrcpy
		pop	eax
		retn	12

@@gmfIterate:
		dec	eax
		jns	short @@gmfLoop

@@gmfFail:
GetModuleFileNameW LABEL NEAR
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
		test	edx, edx
		jz	@@gpaExit

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
		cmp	esi, 10000h			;ordinal?
		jnc	@@gpaCmpStr

		mov	eax, esi
		sub	eax, [edx + 16]
		jmp	@@gpaGetAddrress

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
@@gpaError:
		sub	eax, eax
		jmp	short @@gpaExit
;
; Finally, we found the function name we were looking for, (numNames - ECX) is
; the ordinal number of the function address we are looking for.
;
@@gpaOrdinalFound:
		mov	eax, [edx+24]
		sub	eax, ecx

@@gpaGetAddrress:
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
; Fix for TLINK32 and the zero sized fixup sections it may create
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
		mov	edx, esp
		mov	eax, [esp+28]
		sub	esp, 260
		mov	edi, eax
		mov	ecx, esp
		push	260
		push	ecx
		push	eax
		call	GetModuleFileNameA
		push	esp
		push	OFFSET abortString
		add	edi, [ebp+12]
		push	edi
		push	OFFSET importStrErr1
		call	GenericError

.data

importStrErr1	db	0dh, 0ah
		db	'FATAL: Unable to load module %a!', 0dh, 0ah
		db	'       Either there is insufficient memory to load this module or the module', 0dh, 0ah
		db	'       could not be found at all.', 0dh, 0ah
		db	'%a%a .',0dh, 0ah, 0

.code
importModuleFound:
		mov	edi, eax
;
; Rva of import_lookup_table
;
; Use Original First Thunk instead of First Thunk array because of a bug
; in ALINK (It would not zero terminate the First Thunk - list)
;
;		mov	ebx, [ebp+16]
		mov	ebx, [ebp]
		test	ebx, ebx
		jnz	importGotFT
;
; Fix for Delphi 5 linker leaving the OFT blank
;
		mov	ebx, [ebp+16]
		mov	[ebp], ebx

importGotFT:
		add	ebx, [esp+28]

importNextLabel:
		mov	eax, [esp+28]
		mov	esi, [ebx]
		test	esi, esi
		jns	importNoOrdinal		; No import by ordinal!

		btr	esi, 31
		jmp	importOrdinal
;;
;;		ERROR - CANNOT IMPORT BY ORDINAL
;;		[EBP+12] -> Module name of supposed exporter
;;		ESI (LOW) Function ordinal number
;;		[ESP+28] = hModule of importer
;;
;		mov	edx, esp
;		mov	eax, [esp+28]
;		sub	esp, 260
;		mov	ecx, esp
;		mov	edi, eax
;		push	260
;		push	ecx
;		push	eax
;		call	GetModuleFileNameA
;		push	esp
;		push	OFFSET abortString
;		push	esi
;		add	edi, [ebp+12]
;		push	edi
;		push	OFFSET importStrErr2
;		call	GenericError
;
;.data
;
;importStrErr2	db	0dh, 0ah
;		db	'FATAL: Import by ordinal not supported!', 0dh, 0ah
;		db	'Unable to resolve %a Ordinal 0x%4 .', 0dh, 0ah
;		db	'%a%a .',0dh, 0ah, 0
;
;.code

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
importOrdinal:
		push	esi
		push	edi
		call	GetProcAddress
		test	eax, eax
		jnz	short importResolved
;
; 04/24/2003: For the sake of not having to implement another ten million
;             dummy functions, we do not abort here anymore. Rather we return
;             the address of an error handler. Less accurate but allows more
;             programs to run with the emulation that would not otherwise.
;
		mov	eax, OFFSET UnresolvedHandler
;;
;;		ERROR - CANNOT RESOLVE DYNALINK
;;		[EBP+12] -> Module name of supposed exporter
;;		ESI -> Function name that could not be resolved
;;		[ESP+28] = hModule of importer
;;
;		mov	edx, esp
;		mov	eax, [esp+28]
;		sub	esp, 260
;		mov	ecx, esp
;		mov	edi, eax
;		push	260
;		push	ecx
;		push	eax
;		call	GetModuleFileNameA
;		push	esp
;		push	OFFSET abortString
;		add	edi, [ebp+12]
;		push	edi
;		push	esi
;		push	OFFSET importStrErr3
;		call	GenericError
;
.data

abortString	db	'Abort loading module ',0

importStrErr3	db	0dh, 0ah
		db	'FATAL: Unresolved Win32 emulator function call at 0x%4 - Giving up...', 0dh, 0ah
;		db	'FATAL: Could not find %a in module %a!', 0dh, 0ah
;		db	'%a%a .',0dh, 0ah, 0
;
.code
importResolved:
		add	ebx, [ebp + 16]
		sub	ebx, [ebp]
		mov	[ebx], eax
		add	ebx, [ebp]
		sub	ebx, [ebp + 16]
		add	ebx, 4
		jmp	importNextLabel

importDone:
		popad
		ret

peImport	ENDP

UnresolvedHandler LABEL NEAR
		sub	DWORD PTR [esp], 5
		push	OFFSET importStrErr3
		call	GenericError

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
		call	wfseHandler
		jc	loadFileError
;
; Allocate some temp storage to determine the image size
;
		mov	ecx, 64
		sub	esp, 68h
		mov	edx, esp
		mov	ah, 3Fh
		call	wfseHandler
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
		push	PAGE_EXECUTE_READWRITE
		push	MEM_RESERVE + MEM_COMMIT
		push	ecx		; Size
		push	0		; Any location accepted
		call	VirtualAlloc
		test	eax, eax
		jz	loadFileError

		mov	esi, eax	; esi = hModule from now on
;
; lSeek back to the start of the image
;
		mov	edx, [esp+28]
		shld	ecx, edx, 16
		mov	eax, 4200h
		call	wfseHandler
		jc	loadFileError
;
; Load first portion of image (that'd be the MZ)
;
		mov	edx, esi
		mov	ecx, edi
		mov	ah, 3Fh
		call	wfseHandler
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
		call	wfseHandler
		jc	loadFileError

		cmp	eax, ecx
		jne	loadFileError
;
; Get the not-so-optional header size and load the coff heder
;
		movzx	ecx, word ptr [edx+20]
		add	edx, 24
		mov	ah, 3Fh
		call	wfseHandler
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

;-----------------------------------------------------------------------------
; For debugging purposes, we may need the module name and RVA of the crash
; address in eax
;
; Returns: hModule in EAX, EDX is the module name
;
getModuleFromAddress PROC NEAR

		push	0
		push	eax
		push	-1

		mov	eax, MAX_WDLS - 1	; current WDL slot

@@gmfaLoop:
		bt	WdlSlots, eax
		jc	short @@gmfaIterate

		push	eax
		imul	eax, WDL_INFO_SIZE
		mov	ecx, [esp+8]
		mov	edx, [eax+OFFSET WdlDirectory.WdlInfo.Handle]
		sub	ecx, edx
		cmp	ecx, [esp+4]
		pop	eax
		jnc	@@gmfaIterate

		mov	[esp], ecx
		mov	[esp+8], edx
		
@@gmfaIterate:
		dec	eax
		jns	short @@gmfaLoop

		pop	ecx
		pop	eax
		sub	eax, MainModuleHandle
		cmp	eax, ecx
		pop	eax
		jnc	@@gmfaNoMain

		mov	eax, MainModuleHandle

@@gmfaNoMain:
		mov	edx, [eax+60]
		mov	edx, [eax+edx+78h]
		mov	edx, [edx+eax+12]
		add	edx, eax

		ret

getModuleFromAddress ENDP

		END
