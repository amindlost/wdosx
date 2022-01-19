; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 2000, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/TOOLS/wdmem.asm 1.1 2000/05/28 12:33:20 MikeT Exp MikeT $
;
; ----------------------------------------------------------------------------
;
; $Log: wdmem.asm $
; Revision 1.1  2000/05/28 12:33:20  MikeT
; Initial revision.
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

writeError:
		mov	eax, OFFSET fileWrStr
		jmp	errExit

notWfseError:
		mov	eax, OFFSET notWfseStr
		jmp	errExit

errInsane:
		mov	eax, OFFSET insaneStr

errExit:
		call	printEAXStr
		mov	ax, 4CFFh
		int	21h

start:
		push	ds
		pop	es
		cmp	esi, 2
		jc	printUsage

		mov	edx, [edi + 4]
		mov	ax, 3D02h
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
		push	esi
		push	edi
		mov	ecx, 11
		mov	edi, OFFSET sigStr
		mov	esi, OFFSET thatsMe
		repe	cmpsb
		pop	edi
		pop	esi
		jne	notWfseError
;
; Version check here
;
		cmp	BYTE PTR [edi], 5
		jc	notWfseError

		cmp	esi, 3
		jc	displayOnly

		sub	ecx, ecx
		mov	edx, OFFSET WdosxInfo.XMemAlloc - OFFSET mainHeader
		mov	eax, 4200h
		int	21h
;
; Get new setting
;
		mov	edi, [edi + 8]
		sub	eax, eax

sLoop:
		movzx	edx, BYTE PTR [edi]
		cmp	dl, '0'
		jc	done

		cmp	dl, '9'
		ja	cHex

		sub	dl, '0'
		jmp	lNext

cHex:
		cmp	dl, 'A'
		jc	done

		cmp	dl, 'F'
		ja	clHex

		sub	dl, 'A' - 10
		jmp	lNext

clHex:
		cmp	dl, 'a'
		jc	done

		cmp	dl, 'f'
		ja	done

		sub	dl, 'a' - 10

lNext:
		shl	eax, 4
		add	eax, edx
		inc	edi
		jmp	sLoop

done:
		cmp	eax, 10000h
		jc	errInsane

		test	eax, eax
		jns	noWtr

		mov	eax, 80000000h

noWtr:
		lea	eax, [eax + 0FFFh]
		shr	eax, 12
		mov	edx, eax
		add	edx, 3FFh
		shr	edx, 10
		add	eax, edx

		mov	edx, OFFSET WdosxInfo.XMemAlloc
		mov	[edx], eax
		mov	ecx, 4
		mov	ah, 40h
		int	21h
		jnc	TheEnd

		jmp	writeError

displayOnly:
		mov	eax, OFFSET setStr
		call	printEAXStr

		mov	ebp, WdosxInfo.XMemAlloc
;
; Subtract pacge table memory and convert from pages to bytes
;
		cmp	ebp, 80020h
		mov	eax, -1
		jae	noTrans

		mov	eax, 1024 * 4096
		mul	ebp
		mov	ebp, 1025
		div	ebp

noTrans:
		and	eax, 0FFFFF000h
		mov	ebp, eax
		mov	ecx, 8

dLoop:
		sub	edx, edx
		shld	edx, ebp, 4
		shl	ebp, 4
		mov	dl, [edx + OFFSET xtab]
		mov	ah, 2
		int	21h
		loop	dLoop

		mov	eax, OFFSET crlf
		call	printEAXStr

TheEnd:
		mov	ah, 3Eh
		int	21h

		mov	ax, 4C00h
		int	21h

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

.data

sigStr		db	'TIPPACH$WdX'
usageStr	db	'Usage: wdmem <wdosxfile>', 0Dh, 0Ah
		db	'       (Displays current maxalloc setting)', 0Dh, 0Ah
		db	'       wdmem <wdosxfile>, <maxmem>', 0Dh, 0Ah
		db	'       (Sets maxalloc parameter to <maxmem> (hexadecimal)'
crlf		db	0Dh, 0Ah, 0
fileErrStr	db	'Error reading file.', 0Dh, 0Ah, 0
fileWrStr	db	'Error writing to file.', 0Dh, 0Ah, 0
notWfseStr	db	'Error: No rev. 5 compatible WDOSX header detected in input file.', 0Dh, 0Ah, 0
setStr		db	'Current maxalloc setting (hex) = ', 0
insaneStr	db	'Error: Setting maxalloc below 64k is insane!', 0Dh, 0Ah, 0

xtab		db	'0123456789ABCDEF'

.data?

mainHeader	db	25 dup (?)
thatsMe		db	7 dup (?)
WdosxInfo	WdxInfo <>

	END start
