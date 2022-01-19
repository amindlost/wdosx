; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/TOOLS/adc.asm 1.3 2001/02/22 21:47:20 MikeT Exp MikeT $
;
; ----------------------------------------------------------------------------
;
; $Log: adc.asm $
; Revision 1.3  2001/02/22 21:47:20  MikeT
; New version to support wpack 1.07.
;
; Revision 1.2  1999/06/20 15:49:37  MikeT
; We now use Joergen Ibsen's compressor instead of the old LZ77 one.
;
; Revision 1.1  1999/02/07 18:41:26  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## Basic WFSE extension tool support.                                     ##
; ############################################################################


include dualmode.inc
include	general.inc
include wdxinfo.inc

.code

EXTRN	WdosxPack: NEAR

DUAL_STDMAIN
DUAL_EXPORT WdosxAddfile

;+----------------------------------------------------------------------------
; unsigned long
; (__stdcall) WdosxAddfile(char *HostFile, char *Infile, char *WfseName, \
;                           unsigned long InOffset, unsigned long flags)
;
WdosxAddfile PROC NEAR
	pushad
;
; Initialize status variables
;
	sub	eax, eax
	mov	InputFileHandle, eax
	mov	OutputFileHandle, eax
	mov	[esp].pushadFrame.eaxReg, eax		; assume error
;
; Try to open the input file.
;
	mov	edx, [esp + 8 + FRAME_SIZE]
	mov	ah, 03Dh
	int	21h
	jc	addfileExit

	mov	InputFileHandle, eax
	mov	ebx, eax
;
; Get file size and seek to the beginning of valid input data
;
	sub	ecx, ecx
	sub	edx, edx
	mov	ax, 4202h
	int	21h
	jc	addfileExit
	
	mov	WORD PTR TheHeader.WfseVirtualSize, ax
	mov	WORD PTR TheHeader.WfseVirtualSize[2], dx
	mov	dx, [esp + 16 + FRAME_SIZE]
	mov	cx, [esp + 18 + FRAME_SIZE]
	mov	ax, 4200h
	int	21h
	jc	addfileExit
;
; Adjust input file size
;
	sub	WORD PTR [OFFSET TheHeader.WfseVirtualSize], ax
	sbb	WORD PTR [OFFSET TheHeader.WfseVirtualSize + 2], dx
;
; Try to open the output file.
;
	mov	edx, [esp + 4 + FRAME_SIZE]
	mov	ax, 03D02h
	int	21h
	jc	addfileExit

	mov	OutputFileHandle, eax
	mov	ebx, eax
;
; Get file size and seek to the end of the file
;
	sub	ecx, ecx
	sub	edx, edx
	mov	ax, 4202h
	int	21h
	jc	addfileExit
	
	mov	WORD PTR [OFFSET OutputFileSize], ax
	mov	WORD PTR [OFFSET OutputFileSize + 2], dx
;
; Put the new filename into the WFSE header and calculate its size.
;
	push	DWORD PTR [esp + 12 + FRAME_SIZE]
	push	OFFSET TheFileName
	call	strcpy
	call	strlen
	add	esp, 8
;
; EAX = size
;
	add	eax, 16 + 6
	mov	OffsetTableStart, eax
	add	eax, OutputFileSize		; Convert into File offset
;
; Size of the offset Table = (((Filesize + 0xFFF) div 4k) * 4)
;
	mov	edx, TheHeader.WfseVirtualSize
	add	edx, 0FFFh
	shr	edx, 12
	mov	OffsetTableSize, edx		; in DWORDs
;
; Expand the output file accordingly.
;
	lea	edx, [eax + edx * 4]
	shld	ecx, edx, 16
	mov	ax, 4200h
	int	21h
	jc	addfileExit
;
; The compression algorithm goes like this:
;
; OutTableOffset = TableOffset
; CurrentIteration = 0
; OutOffset = 0
;
;
; Loop:
;    OffsetTable[CurrentIteration AND 0x3FF] = OutOffset
;    CurrentIteration += 1
;    if CurrentIteration AND 0x3FF == 0 then
;       SaveOutPtr()
;       WriteTable(CurrentIteration + TableOffset, 4096)
;       RestoreOutPtr()
;    if CurrentIteration == OffsetTableSize GOTO LastBlock
;    ReadInputBuffer(4096)
;    TempSize = CompressBuffer(4096)
;    WritBuffer = OutBuffer
;    if TempSize > 4095 then 
;       WriteBuffer = InBuffer
;       TempSize = 4096
;    WriteOutFile(WriteBuffer, TempSize)
;    OutOffset += TempSize
; GOTO Loop
;
; LastBlock:
;    if CurrentIteration AND 0x3FF <> 0 then
;       SaveOutPtr()
;       WriteTable(CurrentIteration AND NOT (0x3FF) + TableOffset, \
;                  CurrentIteration AND 0x3FF)
;       RestoreOutPtr()
;    LastSize = ((VirtualSize - 1) AND 4095) + 1
;    ReadInputBuffer(LastSize)
;    TempSize = CompressBuffer(LastSize)
;    WritBuffer = OutBuffer
;    if TempSize >= LastSize then 
;       WriteBuffer = InBuffer
;       TempSize = LastSize
;    WriteOutFile(WriteBuffer, TempSize)
;    OutOffset += TempSize
; END
;
	mov	eax, OffsetTableStart
	add	eax, OutputFileSize		; Convert into File offset
	mov	OutTableOffset, eax
	mov	CurrentIteration, 0
	mov	OutOffset, 0

CompressLoop:
	mov	edx, CurrentIteration
	and	edx, 03FFh
	mov	eax, OutOffset
	mov	HeadBuffer[edx * 4], eax
	inc	CurrentIteration
	cmp	edx, 03FFh
	jne	headBufferOk

	call	WriteTable
	jc	addfileExit

headBufferOk:
	mov	edx, CurrentIteration
	cmp	edx, OffsetTableSize
	je	lastBlock

	mov	ebx, InputFileHandle
	mov	ah, 03Fh
	mov	ecx, 4096
	mov	edx, OFFSET LoadBuffer
	int	21h
	jc	addfileExit

	cmp	eax, ecx
	jne	addfileExit

	push	eax
	push	OFFSET tempBuffer
	push	OFFSET StoreBuffer
	push	edx
	call	WdosxPack
	add	esp, 16
	test	BYTE PTR [esp + 20 + FRAME_SIZE], 10h
	je	dontShowDot

	push	eax
	push	edx
	mov	ah, 2
	mov	dl, '.'
	int	21h
	pop	edx
	pop	eax

dontShowDot:
	mov	edx, OFFSET StoreBuffer
	cmp	eax, 4096
	jc	blockSizeOk

	mov	edx, OFFSET LoadBuffer
	mov	eax, 4096

blockSizeOk:
	mov	ecx, eax
	mov	ah, 40h
	mov	ebx, OutputFileHandle
	int	21h
	jc	addfileExit

	cmp	eax, ecx
	jne	addfileExit

	add	OutOffset, eax
	jmp	CompressLoop

lastBlock:
	test	CurrentIteration, 03FFh
	je	lastHeadOk

	call	WriteTable
	jc	addfileExit

lastHeadOk:
	mov	ecx, TheHeader.WfseVirtualSize
	dec	ecx
	and	ecx, 4095
	inc	ecx
	mov	edx, OFFSET LoadBuffer
	mov	ebx, InputFileHandle
	mov	ah, 03Fh
	int	21h
	jc	addfileExit

	cmp	eax, ecx
	jne	addfileExit
;
;    TempSize = CompressBuffer(LastSize)
;
	push	ecx
	push	eax
	push	OFFSET tempBuffer
	push	OFFSET StoreBuffer
	push	edx
	call	WdosxPack
	add	esp, 16
	pop	ecx
	mov	edx, OFFSET StoreBuffer
	cmp	eax, ecx
	jc	lastBlockSizeOk

	mov	edx, OFFSET LoadBuffer
	mov	eax, ecx

lastBlockSizeOk:
	mov	ecx, eax
	mov	ah, 40h
	mov	ebx, OutputFileHandle
	int	21h
	jc	addfileExit

	cmp	eax, ecx
	jne	addfileExit

	add	OutOffset, eax
;
; Now fill out all of the headers remaining
;
	mov	edx, OffsetTableStart
	mov	WORD PTR [edx + OFFSET TheHeader - 6], 6
	mov	[edx + OFFSET TheHeader - 4], eax
	mov	DWORD PTR [OFFSET TheHeader], 'ESFW'
;
; Calculate the physical size
;
	mov	eax, OffsetTableSize
	shl	eax, 2
	add	eax, OffsetTableStart
	add	eax, OutOffset
	mov	TheHeader.WfseSize, eax
	mov	eax, [esp + 20 + FRAME_SIZE]
;	or	al, 10h
	and	al, 0Fh
	or	al, 20h		; WFSE_COMP_WPACK
	mov	TheHeader.WfseFlags, eax
;
; Write the headers to the output file
;
	mov	edx, OutputFileSize
	mov	ebx, OutputFileHandle
	shld	ecx, edx, 16
	mov	ax, 4200h
	int	21h
	jc	addfileExit
	
	mov	ecx, OffsetTableStart
	mov	edx, OFFSET TheHeader
	mov	ah, 40h
	int	21h
	jc	addfileExit

	cmp	eax, ecx
	jne	addfileExit
;
; Signal success to the caller.
;
	mov	[esp].pushadFrame.eaxReg, 1

addfileExit:
	mov	ebx, InputFileHandle
	test	ebx, ebx
	jz	checkOutputHandle	

	mov	ah, 03Eh
	int	21h

checkOutputHandle:
	mov	ebx, OutputFileHandle
	test	ebx, ebx
	jz	outputHandleDone	

	mov	ah, 03Eh
	int	21h

outputHandleDone:
	popad
	DUAL_RETURN 20
WdosxAddfile ENDP

;-----------------------------------------------------------------------------
; WriteTable (Writes the current offset table to the output file)
;
; Exit: CF set on error
;
WriteTable PROC NEAR
	pushad
	mov	ebx, OutputFileHandle
	sub	ecx, ecx
	sub	edx, edx
	mov	ax, 4201h
	int	21h
	jc	WtExit

	mov	esi, edx
	mov	edi, eax
	mov	edx, OutTableOffset
	shld	ecx, edx, 16
	mov	ax, 4200h
	int	21h
	jc	WtExit

	mov	ecx, CurrentIteration
	dec	ecx
	and	ecx, 03FFh
	lea	ecx, [ecx * 4 + 4]
	add	OutTableOffset, ecx
	mov	edx, OFFSET HeadBuffer
	mov	ah, 40h
	int	21h
	jc	WtExit

	mov	ax, 4200h
	mov	ecx, esi
	mov	edx, edi
	int	21h

WtExit:
	popad
	ret
WriteTable ENDP

;-----------------------------------------------------------------------------
; unsigned long strcpy(char* dest, char* src)
;
;
strcpy PROC NEAR
	mov	ecx, [esp + 8]
	mov	edx, [esp + 4]

TheLoop1:
	mov	al, [ecx]
	inc	ecx
	mov	[edx], al
	inc	edx
	cmp	al, 1
	jnc	TheLoop1

	mov	eax, [esp + 4]
	ret
strcpy ENDP

;-----------------------------------------------------------------------------
; unsigned long strlen(char* s)
;
; Returns the size of a 0 terminated string including the trailing zero.
;
strlen PROC NEAR
	mov	eax, [esp + 4]

TheLoop2:
	cmp	BYTE PTR [eax], 1
	inc	eax
	jnc	TheLoop2

	sub	eax, [esp + 4]
	ret
strlen ENDP

;Lz77Compress PROC NEAR
;
;		push	ebx
;		push	esi
;		push	edi
;		push	ebp
;;
;; Initialize match lookup
;;
;		mov	eax, -3
;		mov	edi, OFFSET MatchLookup
;		cld
;		mov	ecx, 10000h
;		rep	stosd		
;
;		mov	esi, [esp + 20]
;		mov	ecx, [esp + 28]
;		dec	ecx
;		jz	EndTableInit
;
;StartTableInit:
;		movzx	eax, WORD PTR [esi]
;		cmp	MatchLookup[eax * 4], -3
;		jne	HaveAMatch
;
;		mov	MatchLookup[eax * 4], esi
;
;HaveAMatch:
;		inc	esi
;		dec	ecx
;		jnz	StartTableInit
;
;EndTableInit:
;		mov	esi, [esp + 20]
;		mov	edi, [esp + 24]
;		push	0
;		push	0
;;
;; ESI = INPUT_BUFFER
;; EDI = OUTPUT_BUFFER
;;
;		mov	ebx, esi
;		add	ebx, [esp + 36]
;		mov	[esp], edi
;		inc	edi
;
;findBestMatch:
;		push	edi
;		sub	ebp, ebp
;
;		inc	esi
;		cmp	esi, ebx
;		dec	esi
;		jnc	ThisMatchDone
;
;;		mov	edi, ebx
;;		sub	edi, [esp + 40]
;
;		movzx	eax, WORD PTR [esi]
;		mov	eax, MatchLookUp[eax*4]
;		mov	edi, eax
;		add	eax, 2
;		cmp	eax, esi
;		jnc	ThisMatchDone
;
;newRun:
;;
;; get the maximum possible match size
;;
;		mov	eax, esi
;		mov	ecx, ebx
;		sub	ecx, eax
;		cmp	ecx, MAX_MATCH_SIZE
;		jna	UpperLimitOk
;
;		mov	ecx, MAX_MATCH_SIZE
;
;UpperLimitOk:
;		sub	eax, edi
;		cmp	eax, ecx
;		jae	LowerLimitOk		
;
;		xchg	eax, ecx
;
;LowerLimitOk:
;		cmp	ecx, MIN_MATCH_SIZE
;		jc	thisMatchDone
;;
;; now find the match size
;;
;		push	ecx
;		push	esi
;		push	edi
;		repe	cmpsb
;		pop	edi
;		pop	esi
;		pop	eax
;		je	fullHouse
;
;		dec	eax
;
;fullHouse:
;		sub	eax, ecx
;;
;; match size in EAX, check for new high score
;;
;		cmp	eax, ebp
;		jna	HighScoreOk
;
;		xchg	eax, ebp
;		mov	edx, edi
;
;HighScoreOk:
;		inc	edi
;		cmp	ebp, MAX_MATCH_SIZE
;		jc	newRun
;
;thisMatchDone:
;		pop	edi
;;
;; edx = match index
;; ebp = match size
;; esi = current index
;; edi = output index
;;
;; if EBP < 3 output literal else output match tag ((EDX-ESI), EBP - MIN_MATCH)
;;
;		cmp	ebp, MIN_MATCH_SIZE
;		jnc	outMatch
;
;		movsb
;		mov	al, 0
;		jmp	outDone
;
;outMatch:
;
;; TEST
;;		sub	edx, [esp+28]
;
;		neg	edx			; comm 
;		add	edx, esi		; comm
;
;		add	esi, ebp
;		shl	edx, 4
;		lea	eax, [edx + ebp - MIN_MATCH_SIZE]
;		stosw
;		mov	al, 80h
;
;outDone:
;		mov	ah, [esp + 5]
;		add	eax, eax
;		mov	[esp + 5], ah
;
;CheckTag:
;		inc	BYTE PTR [esp + 4]
;		mov	al, [esp + 4]
;		and	al, 7
;		jnz	TagDone
;
;		mov	ecx, [esp]
;		mov	[esp], edi
;		inc	edi
;		mov	[ecx], ah
;		mov	BYTE PTR [esp + 5], 0
;
;TagDone:
;		cmp	esi, ebx
;		jc	findBestMatch
;
;		and	al, 7		; Tag to update?
;		jnz	outDone		; finish up, if necessary
;
;		pop	eax
;		pop	eax
;		lea	eax, [edi-1]
;		pop	ebp
;		pop	edi
;		pop	esi
;		pop	ebx
;		sub	eax, [esp + 8]
;		retn	12
;
;Lz77Compress ENDP

.data?

align 4
TheHeader	WfseInfo <>
TheFileName	db 	256 + 8 dup (?)		; Just reserve some space

;MatchLookup	dd	10000h dup (?)
LoadBuffer	db	4096 dup (?)
HeadBuffer	dd	1024 dup (?)
StoreBuffer	db	4096 + 1024 dup (?)
tempBuffer	db	10000h dup (?)

InputFileHandle		dd	?
OutputFileHandle	dd	?
OutputFileSize		dd	?
OffsetTableStart	dd	?
OffsetTableSize		dd	?
CurrentIteration	dd	?
OutOffset		dd	?
OutTableOffset		dd	?




IFDEF __DLL__
	END dllMain
ENDIF
	END
