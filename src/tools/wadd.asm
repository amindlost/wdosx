; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/TOOLS/wadd.asm 1.4 2003/04/16 00:50:49 MikeT Exp MikeT $
;
; ----------------------------------------------------------------------------
;
; $Log: wadd.asm $
; Revision 1.4  2003/04/16 00:50:49  MikeT
; Wadd now replaces modules with the same name instead of rejecting them.
;
; Revision 1.3  1999/06/20 16:26:33  MikeT
; Corrected the check for the WdxInfo version to use ESI and not EDI as a
; pointer, which makes it work. Added a check for at least version 5 of the
; structure because earlier versions do not support the new compression method.
;
; Revision 1.2  1999/02/07 18:38:54  MikeT
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

EXTRN	_WdosxAddfile: NEAR

BUFFER_SIZE EQU 10000h		; Size of temp buffer

printUsage:
		mov	eax, OFFSET usageStr
		jmp	errExit

fileError:
		mov	eax, OFFSET fileErrStr
		jmp	errExit

notWfseError:
		mov	eax, OFFSET notWfseStr
		jmp	errExit

notWpackError:
		mov	eax, OFFSET notWpackStr
		jmp	errExit

addFailError:
		mov	eax, OFFSET addFailStr
		jmp	errExit

fatal:
		mov	eax, OFFSET fatalStr
;fileExistError:
;		mov	eax, OFFSET fileExistStr

errExit:
		call	printEAXStr
		mov	ax, 4CFFh
		int	21h

start:
		push	ds
		pop	es
		cmp	esi, 4
		ja	printUsage

		cmp	esi, 3
		jc	printUsage

		mov	eax, [edi + 8]
		mov	newfile, eax
		je	l001

		mov	eax, [edi + 12]

l001:
		mov	newname, eax
		mov	edx, [edi + 4]
		mov	hostfile, edx
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
		mov	ecx, 11
		mov	edi, OFFSET sigStr
		mov	esi, OFFSET thatsMe
		repe	cmpsb
		jne	notWfseError

		cmp	BYTE PTR [esi], 4
		jc	notWfseError

		cmp	BYTE PTR [esi], 5
		jc	notWpackError

		mov	eax, WdosxInfo.WfseStart
		test	eax, eax
		jne	readHeaderLoop

		sub	ecx, ecx
		sub	edx, edx
		mov	ax, 4202h
		int	21h
		jc	fileError
		
		mov	WdosxInfo.WfseStart, eax
		mov	WORD PTR [OFFSET WdosxInfo.WfseStart + 2], dx
		sub	ecx, ecx
		sub	edx, edx
		mov	ax, 4200h
		int	21h
		jc	fileError

		mov	edx, OFFSET mainHeader
		mov	ecx, 52
		mov	ah, 40h
		int	21h
		jc	fileError

		cmp	eax, ecx
		jne	fileError

		jmp	doTheAdd

readHeaderLoop:
		call	readWfseHeader
		jc	doTheAdd

		mov	eax, OFFSET TheName
		call	cmpEAXStr
		jnc	doReplace

		mov	eax, headerOffset
		add	eax, TheInfo.WfseSize
		jmp	readHeaderLoop

doReplace:
;
; Simply delete the part to be replaced
;
		mov	edx, headerOffset
		add	edx, TheInfo.WfseSize
		shld	ecx, edx, 16
		mov	ax, 4200h
		int	21h
		jc	fatal

		mov	ecx, BUFFER_SIZE
		mov	edx, OFFSET TheBuffer
		mov	ah, 3Fh
		int	21h
		jc	fatal

		push	eax
		mov	edx, headerOffset
		shld	ecx, edx, 16
		mov	ax, 4200h
		int	21h
		pop	ecx
		jc	fatal
		
		mov	edx, OFFSET TheBuffer
		mov	ah, 40h
		int	21h
		jc	fatal

		add	headerOffset, eax
		test	ecx, ecx
		jnz	doReplace

doTheAdd:
		mov	ah, 3Eh
		int	21h
		push	10h
		push	0
		push	newname
		push	newfile
		push	hostfile
		call	_WdosxAddfile
		add	esp, 20
		call	printCrlf
		test	eax, eax
		je	addFailError

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
cmpEAXStr PROC NEAR
		pushad
		mov	esi, eax
		mov	edi, newname

cmploop:
		mov	al, [esi]
		inc	esi
		call	upcaseAl
		mov	ah, al
		mov	al, [edi]
		inc	edi
		call	upcaseAl
		cmp	al, ah
		stc
		jne	doneCmp

		or	al, ah
		jnz	cmploop		

doneCmp:
		popad
		ret
cmpEAXStr ENDP

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

upcaseAl PROC BEAR
		cmp	al, 'a'
		jc	upcEnd

		cmp	al, 'z'
		ja	upcEnd

		add	al, 'A' - 'a'

upcEnd:
		ret
upcaseAl ENDP

printCrlf PROC NEAR
		push	eax
		mov	eax, OFFSET crlf
		call	printEAXStr
		pop	eax
		ret
printCrlf ENDP

.data

sigStr		db	'TIPPACH$WdX'
usageStr	db	'Usage: wadd <hostfile> <newfile> (optional <WFSEname>)', 0Dh, 0Ah
		db	'       where: hostfile = WDOSX extended main application', 0Dh, 0Ah
		db	'              newfile  = Filename of module to add', 0Dh, 0Ah
		db	'              WFSEname = Name under which <newfile> will be visible'
crlf		db	0Dh, 0Ah, 0
fileErrStr	db	'Error accessing hostfile.', 0Dh, 0Ah, 0
notWfseStr	db	'Error: Hostfile does not support WFSE.', 0Dh, 0Ah, 0
notWpackStr	db	'Error: Hostfile does not support new compression. Please re-stub!', 0Dh, 0Ah, 0
addfailStr	db	'Error: Failed to add WFSE module.', 0Dh, 0Ah, 0
;fileExistStr	db	'Error: A module with that name is already linked to the hostfile', 0Dh, 0Ah, 0
fatalStr	db	'Error: Fatal file I/O condition occured, giving up.', 0Dh, 0Ah, 0

.data?
hostfile	dd	?
newfile		dd	?
newname		dd	?
headerOffset	dd	?
mainHeader	db	25 dup (?)
thatsMe		db	7 dup (?)
WdosxInfo	WdxInfo <>
TheInfo		WfseInfo <>
TheName		db	256 dup (?)
TheBuffer	db	BUFFER_SIZE dup (?)

	END start

