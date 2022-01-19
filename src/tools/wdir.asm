; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/tools/wdir.asm 1.2 1999/02/07 18:38:31 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: wdir.asm $
; Revision 1.2  1999/02/07 18:38:31  MikeT
; Updated copyright + some cosmetics.
;
; Revision 1.1  1998/08/03 03:03:11  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
.386
.model flat
.code
include wdxinfo.inc

printUsage:
		mov	eax, OFFSET usageStr
		jmp	errExit

fileError:
		mov	eax, OFFSET fileErrStr
		jmp	errExit

notWfseError:
		mov	eax, OFFSET notWfseStr
		jmp	errExit

noFilesError:
		mov	eax, OFFSET noFilesStr

errExit:
		call	printEAXStr
		mov	ax, 4CFFh
		int	21h

start:
		push	ds
		pop	es
		cmp	esi, 2
		jne	printUsage

		mov	edx, [edi + 4]
		mov	ax, 3D00h
		int	21h
		jc	fileError

		mov	ebx, eax
		mov	edx, OFFSET mainHeader
		mov	ecx, 52
		mov	ah, 3Fh
		int	21h
		jc	fileError

		cmp	eax, ecx
		jne	notWfseError

		cld
		mov	ecx, 11
		mov	edi, OFFSET sigStr
		mov	esi, OFFSET thatsMe
		repe	cmpsb
		jne	notWfseError
;
; Version check here
;
		cmp	BYTE PTR [edi], 4
		jc	notWfseError

		mov	eax, WdosxInfo.WfseStart
		test	eax, eax
		je	noFilesError

readHeaderLoop:
		call	readWfseHeader
		jc	TheEnd

		mov	eax, OFFSET TheName
		call	printEAXStr
		call	printCrlf
		mov	eax, TheInfo.WfseSize
		add	eax, headerOffset
		jmp	readHeaderLoop

TheEnd:
		mov	ax, 4C00h
		int	21h

;----------------------------------------------------------------------------
; EAX = offset, EBX = handle
;		
readWfseHeader PROC NEAR
		pushad
		mov	edx, eax
		shld	ecx, eax, 16
		mov	ax, 4200h
		int	21h
		jc	rwexit

		mov	headerOffset, eax
		mov	WORD PTR [OFFSET headerOffset + 2], dx
		mov	ecx, 16 + 256
		mov	edx, OFFSET TheInfo
		mov	ah, 3Fh
		int	21h
		jc	rwexit

		cmp	eax, 18
		jc	rwexit

		cmp	DWORD PTR [edx], 'ESFW'
		sete	al
		cmp	al, 1

rwexit:
		popad
		ret
readWfseHeader ENDP

;----------------------------------------------------------------------------
; EAX -> String
;
printEAXStr PROC NEAR
		pushad
		mov	edi, eax

pasIn:
		mov	dl, [edi]
		inc	edi
		test	dl, dl
		je	pasOut

		mov	ah, 2
		int	21h
		jmp	pasIn

pasOut:
		popad
		ret
printEAXStr ENDP

printCrlf PROC NEAR
		push	eax
		mov	eax, OFFSET crlf
		call	printEAXStr
		pop	eax
		ret
printCrlf ENDP

.data

sigStr		db	'TIPPACH$WdX'
usageStr	db	'Usage: wdir <hostfile>'
crlf		db	0Dh, 0Ah, 0
fileErrStr	db	'Error reading hostfile.', 0Dh, 0Ah, 0
notWfseStr	db	'Error: Hostfile does not support WFSE.', 0Dh, 0Ah, 0
noFilesStr	db	'No WFSE attachments detected.', 0Dh, 0Ah, 0

.data?

headerOffset	dd	?
mainHeader	db	25 dup (?)
thatsMe		db	7 dup (?)
WdosxInfo	WdxInfo <>
TheInfo		WfseInfo <>
TheName		db	256 dup (?)

	END start
