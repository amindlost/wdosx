; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/WIN32/k32vmem.asm 1.10 2004/02/24 02:07:59 MikeT Exp MikeT $
;
; ----------------------------------------------------------------------------
;
; $Log: k32vmem.asm $
; Revision 1.10  2004/02/24 02:07:59  MikeT
; Add Read/WriteProcessMemory().
;
; Revision 1.9  2000/04/11 17:46:19  MikeT
; Implemented stub for VirtualProtect (BCC55 support).
;
; Revision 1.8  1999/02/14 17:54:49  MikeT
; Added the following functions:
; IsBadReadPtr
; IsBadWritePtr
; IsBadHugeReadPtr
; IsBadHugeWritePtr
; IsBadCodePtr
;
; Corrected the return result of VirtualQuery.
;
; Revision 1.7  1999/02/07 21:12:07  MikeT
; Updated copyright.
;
; Revision 1.6  1998/09/20 17:40:49  MikeT
; Code cleanup. No functional change.
;
; Revision 1.5  1998/09/17 22:10:16  MikeT
; VirtualQuery now returns information on blocks allocated for
; the main application and kernel32.wdl.
;
; Revision 1.4  1998/08/27 01:08:39  MikeT
; Fix potential memory corruption in VirtualAlloc
;
; Revision 1.3  1998/08/12 23:16:43  MikeT
; Fix 16k base calculation
;
; Revision 1.2  1998/08/12 03:30:55  MikeT
; 16k align alloc. base
;
; Revision 1.1  1998/08/03 01:44:59  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## Win32 - Virtual memory functions emulation.                            ##
; ############################################################################

.386p
.model flat

include w32struc.inc

MAX_MEM_BLOCKS	EQU	128

;
; 2DO: Move this out of here
;
vmemMcb		STRUC
		bStart			dd ?	; base address of block
		bEnd			dd ?	; end address of block
		bHandL			dw ?	; DPMI handle low word
		bHandH			dw ?	; DPMI handle high word
		bFlags			dd ?	; flags (currently unused)
vmemMcb		ENDS

.code
		PUBLICDLL		VirtualAlloc
		PUBLICDLL		VirtualQuery
		PUBLICDLL		VirtualFree
		PUBLICDLL		VirtualProtect
		PUBLICDLL		IsBadCodePtr
		PUBLICDLL		IsBadReadPtr
		PUBLICDLL		IsBadHugeReadPtr
		PUBLICDLL		IsBadWritePtr
		PUBLICDLL		IsBadHugeWritePtr
		PUBLICDLL		WriteProcessMemory
		PUBLICDLL		ReadProcessMemory

		PUBLIC		vmemInit

.data
		EXTRN		LastError: DWORD
		EXTRN		WdlDirectory: WdlInfo
		EXTRN		MainModuleHandle: DWORD

.data?
		align	4

memBlocks	vmemMcb MAX_MEM_BLOCKS DUP (<>)

.code

		EXTRN		isLoadTime: BYTE

;+----------------------------------------------------------------------------
; W32 - VirtualAlloc
;
; The main difference between this one and the real thing is that everything
; but the block address and size is ignored. Neither is the block guaranteed
; to start at a 64k boundary.
;
VirtualAlloc	PROC NEAR

		mov	eax, [esp+4]
		test	eax, eax
		jz	@@vaNewBlock

		call	vmemFindBlock
		test	eax, eax
		jz	@@vaError
;
; Allocation in an existing block means address + size must be less or equal
; MCB.bEnd No further checks necessary.
;
		mov	ecx, [eax].vmemMcb.bEnd
		sub	ecx, [esp+4]		; cannot overflow
		sub	ecx, [esp+8]
		mov	eax, [eax].vmemMcb.bStart
		jnc	@@va01

@@vaError:
		mov	LastError, 0C0000017h
		sub	eax, eax

@@va01:
		retn	16

@@vaNewBlock:
		call	vmemFindEmpty
		test	eax, eax
		jz	@@vaError

		mov	LastError, 0C0000017h
		mov	ecx, [esp+8]
;
; The allocation base address granularity Delphi assumes is 16k. 
; "Assume" makes an Ass out of U and Me...
; Using DPMI, we can only guarantee 4k alignment, so we need to waste some
; memory :(
;
;
		add	ecx, 4FFFh
		cmp	isLoadTime, 0
		jz	@@vaWasteMem

		sub	ecx, 4000h		; don't waste mem at load time

@@vaWasteMem:
		and	cx, 0F000h
		push	ebx
		push	esi
		push	edi
		push	eax
		push	ecx
		shld	ebx, ecx, 16
		mov	ax, 0501h
		int	31h
		pop	edx
		jnc	@@vaOkiDoki
;
; If the request was for committed memory we really need to return an error
; now. Otherwise, find out how much memory there could be and allocate just
; that much. A subsequent MEM_COMMIT for this block will succeed or fail
; depending on where exactly the application wants to get committed memory.
; For machines with very little memory this behaviour is essential as your
; typical RTL would try to MEM_RESERVE 4Mb or so even when only 64k were
; malloc'd.
;
		test	DWORD PTR [esp+28], MEM_COMMIT
		jz	@@vaTryHarder

@@vaNoWay:
		pop	eax
		sub	eax, eax
		jmp	@@vaPopError

@@vaTryHarder:
		sub	esp, 30h
		mov	edi, esp
		mov	ax, 500h
		int	31h
		pop	edx
		add	esp, 2Ch
		add	edx, 3FFFh
		and	dx, 0C000h
		jz	@@vaNoWay

@@vaGetSomeMem:
		sub	edx, 4000h
		jz	@@vaNoWay

		mov	ecx, edx
		shld	ebx, edx, 16
		mov	ax, 0501h
		int	31h
		jc	@@vaGetSomeMem

@@vaOkiDoki:
		shl	ebx, 16
		mov	bx, cx
;
; Align start address on 16k, if not load time.
;
		cmp	isLoadTime, 0
		jnz	@@skipMemWaste

		mov	eax, ebx
		add	ebx, 3FFFh
		and	bx, 0C000h
		sub	eax, ebx
		add	edx, eax

@@skipMemWaste:
		mov	LastError, 0
		pop	eax
		push	ebx
		mov	[eax].vmemMcb.bStart, ebx
		add	ebx, edx
		mov	[eax].vmemMcb.bEnd, ebx
		mov	[eax].vmemMcb.bHandL, di
		mov	[eax].vmemMcb.bHandH, si
;
; Zero out the memory block (2do: check fo MEM_ZEROINIT to save some time)
;
		cld
		mov	edi, ebx
		sub	eax, eax
		sub	edi, edx
		mov	ecx, edx
		shr	ecx, 2
		rep	stosd
		pop	eax

@@vaPopError:
		pop	edi
		pop	esi
		pop	ebx
		retn	16

VirtualAlloc	ENDP

;+----------------------------------------------------------------------------
; W32 - VirtualQuery
;
; This one in no way comes even close to the original. Who cares - as long as
; it works?
;
VirtualQuery	PROC NEAR

		mov	eax, [esp+4]
		and	eax, 0FFFFF000h
		mov	edx, [esp+8]
		mov	[edx].vmemMBI.BaseAddress, eax
		call	vmemFindBlock
		test	eax, eax
		jne	@@vq01
;
; As the memory blocks for the main module and kernel32.wdl are not listed
; in the block table, we need to deal with these in a different way.
;
		mov	eax, MainModuleHandle
		call	VqModuleQuery
		jc	@@vq01

		mov	eax, WdlDirectory.Handle
		call	VqModuleQuery
		jc	@@vq01
; 
; Region is not part of any currently allocated block.
;
		and	[edx].vmemMBI.AllocationBase, 0	; don't give people
		and	[edx].vmemMBI.RegionSize, 0	; bad ideas!
		mov	[edx].vmemMBI.State, 10000h	; MEM_FREE
		jmp	short @@vq02

@@vq01:
		mov	ecx, [eax].vmemMcb.bStart
		mov	[edx].vmemMBI.AllocationBase, ecx
		mov	ecx, [eax].vmemMcb.bEnd
		sub	ecx, [edx].vmemMBI.BaseAddress
		mov	[edx].vmemMBI.RegionSize, ecx
		mov	[edx].vmemMBI.State, 1000h	; MEM_COMMIT
		mov	[edx].vmemMBI.AllocationProtect, 40h
		mov	[edx].vmemMBI.Protect, 40h	; EXEC_READWRITE
		mov	[edx].vmemMBI.PageType, 20000h	; MEM_PRIVATE

@@vq02:
		mov	eax, 28
		retn	12

VirtualQuery	ENDP


;+----------------------------------------------------------------------------
; W32 - VirtualFree
;
; There're some differences between this one and the real thing too. First, we
; ignore MEM_DECOMMIT, second, we don't check whether MEM_RELEASE means the
; whole block or just a part of it. We release the whole block in either case.
;
VirtualFree	PROC NEAR

		test	byte ptr [esp+13], 80h		; MEM_RELEASE?
		jz	@@vf01

		mov	eax, [esp+4]
		call	vmemFindBlock
		test	eax, eax
		jz	@@vf02

		push	esi
		push	edi
		mov	edx, eax
		mov	di, [eax].vmemMcb.bHandL
		mov	si, [eax].vmemMcb.bHandH
		mov	eax, 0502h
		int	31h
		mov	eax, 0
		pop	edi
		pop	esi
		jc	@@vf02

		mov	[edx], eax
		mov	[edx+4], eax
		mov	[edx+8], eax
		mov	[edx+12], eax

@@vf01:
		sub	eax, eax
		inc	eax

@@vf02:
		retn	12

VirtualFree	ENDP

;+---------------------------------------------------------------------------
; Win32 - VirtualProtect
;
VirtualProtect PROC NEAR
		mov	eax, 1
		retn	16
VirtualProtect ENDP


;++---------------------------------------------------------------------------
; Win32 - IsBad<Whatever>Pointer - support for sloppy programmers
;
IsBadCodePtr PROC NEAR
		push	1
		push	DWORD PTR [esp + 8]
		call	IsBadReadPtr
		retn	4
IsBadCodePtr ENDP

IsBadReadPtr LABEL NEAR
IsBadHugeReadPtr LABEL NEAR
IsBadWritePtr LABEL NEAR
IsBadHugeWritePtr LABEL NEAR
		sub	esp, 28
		mov	eax, esp
		push	28
		push	eax
		push	DWORD PTR [esp + 28 + 8 + 4]
		call	VirtualQuery
		sub	eax, eax
		mov	edx, [esp].vmemMBI.AllocationBase
		cmp	edx, 1
		adc	eax, 0
		jnz	isBadExit

		add	edx, [esp].vmemMBI.RegionSize
		sub	edx, [esp + 28 + 4]
		cmp	edx, [esp + 28 + 8]
		adc	eax, 0
		
isBadExit:
		add	esp, 28
		retn	8


WriteProcessMemory LABEL NEAR
		mov	edx, [esp +  8]		; src
		mov	ecx, [esp + 12]		; dest
		jmp	pmDoit		

ReadProcessMemory PROC NEAR
		mov	ecx, [esp +  8]		; src
		mov	edx, [esp + 12]		; dest

pmDoit LABEL NEAR
		push	OFFSET pmFail
		push	DWORD PTR fs:[0]
		mov	fs:[0], esp

rpmLoop:
		mov	al, [ecx]
		mov	[edx], al
		inc	ecx
		inc	edx
		mov	eax, [esp + 8 + 20]
		inc	DWORD PTR [eax]
		dec	DWORD PTR [esp + 8 + 16]
		jnz	rpmLoop

		mov	esp, fs: [0]
		pop	DWORD PTR fs: [0]
		pop	eax
		mov	eax, 1
		retn	20
ReadProcessMemory ENDP


pmFail		LABEL NEAR
		mov	eax, [esp + 4]
		mov	edx, [esp + 8]
		push	0
		push	eax
		push	OFFSET pmFailRet
		push	edx
		EXTRN	RtlUnwind:NEAR
		call	RtlUnwind
pmFailRet:	mov	esp, fs: [0]
		pop	DWORD PTR fs: [0]
		pop	eax
		xor	eax, eax
		retn	20


; ############################################################################
; ## Private routines of module kernel32.wdl                                ##
; ############################################################################

;-----------------------------------------------------------------------------
; VqModuleQuery - Check if linear address within module memory block
;
; Entry:      EAX = linear address of block
; Exit :      CF set if hModule match
;             EAX -> tempMCB structure
;             tempMCB filled
;
; Modifies:   EAX, ECX, minor flags destroyed
;
; Processing: Checks whether the linear address supplied matches a PE module
;             memroy block. If match, then return the size of that block.
;
;
VqModuleQuery PROC NEAR
;
; Returns CF set if module match
;
		mov	tempMCB.vmemMcb.bStart, eax
		mov	ecx, [eax + 60]
		mov	ecx, [ecx + eax + 50h]
		add	ecx, 0FFFh
		and	ecx, 0FFFFF000h
		add	ecx, eax
		mov	tempMCB.vmemMcb.bEnd, ecx
		mov	eax, [edx].vmemMBI.BaseAddress
		sub	eax, tempMCB.vmemMcb.bStart
		cmp	eax, tempMCB.vmemMcb.bEnd
		mov	eax, OFFSET tempMCB
		ret
VqModuleQuery ENDP

;-----------------------------------------------------------------------------
; vmemFindBlock - Find a memory block in the table
;
; Entry:      EAX = linear address of block
; Exit :      EAX = address of block descriptor
;             EAX = 0 - block descriptor not found
;
; Modifies:   EAX, minor flags destroyed
;
; Processing: Checks whether the linear address supplied is within an
;             allocated block
;
vmemFindBlock	PROC NEAR

		push	edx
		sub	edx, edx

@@fbStartFind:
		cmp	eax, [edx].memBlocks.bStart
		jc	@@fbNextBlock

		cmp	eax, [edx].memBlocks.bEnd
		jc	@@fbBlockFound

@@fbNextBlock:
		add	edx, 16
		cmp	edx, MAX_MEM_BLOCKS * 16
		jc	@@fbStartFind

		mov	edx, OFFSET memBlocks
		neg	edx

@@fbBlockFound:
		lea	eax, [edx + OFFSET memBlocks]
		pop	edx
		ret

vmemFindBlock	ENDP

;-----------------------------------------------------------------------------
; vmemFindEmpty - Find empty memory block descriptor
;
; Entry:
; Exit :      EAX = address of free block descriptor
;             EAX = 0 - You are a real memory hog and therefore do not deserve
;                   a new descriptor beeing given to you.
;
; Modifies:   EAX, minor flags destroyed
;
vmemFindEmpty	PROC NEAR

		mov	eax, OFFSET memBlocks

@@feStartFind:
		test	dword ptr [eax], -1
		jz	@@feBlockFound

		add	eax, 16
		cmp	eax, MAX_MEM_BLOCKS * 16 + OFFSET memBlocks
		jc	@@feStartFind

		sub	eax, eax

@@feBlockFound:
		ret

vmemFindEmpty	ENDP

;+----------------------------------------------------------------------------
; vmemInit - Initialize memory subsystem
;
; Entry:
; Exit:
; Modifies:    minor flags destroyed
;
vmemInit	PROC NEAR

		push	eax
		mov	eax, MAX_MEM_BLOCKS * 4

@@iStartLoop:
		and	dword ptr [eax * 4 - 4 + OFFSET memBlocks], 0
		dec	eax
		jne	@@iStartLoop
		
		pop	eax
		ret

vmemInit	ENDP

.data?

tempMCB		vmemMCB	<>

END
