; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/WIN32/k32file.asm 1.20 2003/04/24 20:39:34 MikeT Exp MikeT $
;
; ----------------------------------------------------------------------------
;
; $Log: k32file.asm $
; Revision 1.20  2003/04/24 20:39:34  MikeT
; Add DuplicateHandle, LockFile, UnlockFile.
;
; Revision 1.19  2001/02/04 17:43:31  MikeT
; Fix CopyFileA to not destroy EBP and EBX.
;
; Revision 1.18  2000/06/09 14:22:43  MikeT
; Corrected file truncation routine in CreateFileA to use the proper handle.
;
; Revision 1.17  2000/06/08 18:35:09  MikeT
; Changed logic for CreateFileA such that unnecessary file re- opens do not
; occur. This is meant to speed up networked file access.
;
; Revision 1.16  2000/04/11 17:48:16  MikeT
; Implemented Semi- Implementation of GetShortPathNameA.
;
; Revision 1.15  2000/03/19 16:01:11  MikeT
; Fixed GetFullPathName to return to acknowledge the drive portion of the file
; name part if a drive letter has been specified.
;
; Revision 1.14  2000/03/19 13:02:04  MikeT
; Check for lpFilePart == 0 in GetFullPathNameA. Not checking resulted in
; potential of memory corruption.
;
; Revision 1.13  2000/03/18 19:39:40  MikeT
; Implemented stub for SetFileApisToOEM
;
; Revision 1.12  2000/03/18 19:08:08  MikeT
; Implemented CopyFileA
;
; Revision 1.11  2000/02/10 19:27:28  MikeT
; Replaced stub implementation of GetDriveTypeA with more sensible code and
; added GetLogicalDriveStringsA (supplied by Tony Low).
;
; Revision 1.10  1999/05/05 19:40:03  MikeT
; Implemented suggested change to SetCurrentDirectory() according to
; feedback from the field (Thanks Tim Adam of Open Software Associates Ltd.)
; SetCurrentDirectory("A:") is valid under Win32 as is SetCurrentDirectory("").
;
; Revision 1.9  1999/03/21 15:47:20  MikeT
; Use file handle translation between DOS and WIN.
;
; This has become necessary because of a bug in the Borland C++ 4.5 RTL
; (not present in BC 5 though). The RTL would do something like:
;
; ulong handleTable[]
; handle = CreateFile(Some disk file)
; GetFileType(handleTable[handle])
;
; When it should have have just done GetFileType(handle)
;
; handleTable isn't initialized for others than stdin, stdout and stderr, hence
; the argument to GetFileType would be just 0. Windows returns
; FILE_TYPE_UNKNOWN but under DOS, 0 is a valid handle...
;
; Revision 1.8  1999/02/07 21:06:24  MikeT
; Updated copyright.
;
; Revision 1.7  1998/11/01 18:37:46  MikeT
; Add partial support for GetFileInformationByHandle
;
; Revision 1.6  1998/10/21 20:09:42  MikeT
; Add AreFileApisANSI - stub function
;
; Revision 1.5  1998/09/24 19:58:52  MikeT
; CLoseHandle will now accept the handle of a child program.
;
; Revision 1.4  1998/09/16 23:43:59  MikeT
; Added PROC W2A and pseudo-unicode versions of some functions.
;
; Revision 1.3  1998/09/15 23:56:25  MikeT
; Implemented GetDiskFreeSpaceA to satisfy one more D4 requirement.
;
; Revision 1.2  1998/08/09 16:17:24  MikeT
; Fix Findfirst/next
;
; Revision 1.1  1998/08/03 01:39:45  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## File handling routines of Win32 API emulation                          ##
; ############################################################################

.386p
.model flat

include w32struc.inc

.code

		PUBLICDLL		AreFileApisANSI
		PUBLICDLL		SetHandleCount
		PUBLICDLL		GetFullPathNameA
		PUBLICDLL		GetTempFileNameA
		PUBLICDLL		GetCurrentDirectoryA
		PUBLICDLL		CreateDirectoryA
		PUBLICDLL		CreateDirectoryW
		PUBLICDLL		RemoveDirectoryA
		PUBLICDLL		RemoveDirectoryW
		PUBLICDLL		SetCurrentDirectoryA
		PUBLICDLL		SetCurrentDirectoryW
		PUBLICDLL		GetVolumeInformationA
		PUBLICDLL		GetDiskFreeSpaceA
		PUBLICDLL		GetDriveTypeA
		PUBLICDLL		GetLogicalDrives
		PUBLICDLL		GetLogicalDriveStringsA
		PUBLICDLL		FindFirstFileA
		PUBLICDLL		FindNextFileA
		PUBLICDLL		FindClose
		PUBLICDLL		FlushFileBuffers
		PUBLICDLL		GetFileInformationByHandle
		PUBLICDLL		MoveFileA
		PUBLICDLL		DeleteFileA
		PUBLICDLL		DeleteFileW
		PUBLICDLL		WriteFile
		PUBLICDLL		SetFilePointer
		PUBLICDLL		SetEndOfFile
		PUBLICDLL		ReadFile
		PUBLICDLL		GetShortPathNameA
		PUBLICDLL		GetStdHandle
		PUBLICDLL		SetStdHandle
		PUBLICDLL		GetFileSize
		PUBLICDLL		GetFileType
		PUBLICDLL		CreateFileA
		PUBLICDLL		CopyFileA
		PUBLICDLL		CreateFileW
		PUBLICDLL		CloseHandle
		PUBLICDLL		GetFileAttributesA
		PUBLICDLL		GetFileAttributesW
		PUBLICDLL		SetFileAttributesA
		PUBLICDLL		SetFileAttributesW
		PUBLICDLL		SetFileApisToOEM
		PUBLICDLL		GetFileTime
		PUBLICDLL		SetFileTime
		PUBLICDLL		DuplicateHandle
		PUBLICDLL		LockFile
		PUBLICDLL		UnlockFile

		EXTRN		DosDateTimeToFileTime: NEAR
		EXTRN		FileTimeToDosDateTime: NEAR

;
; Hook procedures to allow direct console i/o, called with:
;
;       EBX = file handle
;       EDX = -> data to read/write
;       ECX = number of bytes to read/write
;
; Return:
;       CF clear: EAX bytes actually read/written
;       CF set:   nothing done, default procedure should handle
;                 read/write operation
;
; When the request is processed by the console module, these routines may
; destroy EAX, EBX, ECX and EDX, otherwise only EAX may be destroyed.
;
		EXTRN		consoleReadFileHook: NEAR
		EXTRN		consoleWriteFileHook: NEAR

.data
		EXTRN		LastError: DWORD

align 4

ffhandles	dd	0

.data?

NewDTA		db	80h * 32 dup (?)

.code

;+----------------------------------------------------------------------------
; Win32 - Lock/Unlock File
;
; Ignore error condition if share not installed
;

UnlockFile LABEL NEAR
		mov	al, 1
		jmp	lockCommon

LockFile LABEL NEAR
		mov	al, 0
lockCommon:
		pushad
		mov	ebx, [esp + 4 + 32]
		HANDLE_W2D ebx
		or	edx, -1
		test	DWORD PTR [esp + 12 + 32], edx
		jnz	lockCommon1

		mov	edx, [esp + 8 + 32]

lockCommon1:
		or	edi, -1
		test	DWORD PTR [esp + 20 + 32], edi
		jnz	lockCommon2

		mov	edi, [esp + 16 + 32]

lockCommon2:
		shld	esi, edi, 16
		shld	ecx, edx, 16
		mov	ah, 5Ch
		int	21h

		popad
		mov	eax, 1				; always o.k.
		retn	20


;+----------------------------------------------------------------------------
; Win32 - DuplicateHandle
;
; Always assume source- and destination process are the same
;
DuplicateHandle PROC NEAR
		push	ebx
		mov	ebx, [esp + 12]
		HANDLE_W2D ebx
		sub	eax, eax
		mov	ah, 45h
		int	21h
		sbb	edx, edx
		mov	ecx, eax
		test	BYTE PTR [esp + 32], 1 ; DUPLICATE_CLOSE_SOURCE?
		jz	dhndSkipClose

		mov	ah, 3Eh
		int	21h

dhndSkipClose:
		mov	eax, edx
		inc	eax
		jz	dhndExit
		
		mov	edx, [esp + 20]
		mov	[edx], ecx

dhndExit:
		pop	ebx
		retn	28
DuplicateHandle ENDP

;+----------------------------------------------------------------------------
; Win32 - AreFileApisANSI
;
AreFileApisANSI PROC NEAR
		mov	eax, 1
		retn
AreFileApisANSI ENDP

;+----------------------------------------------------------------------------
; Win32 - SetFileApisToOEM
;
SetFileApisToOEM PROC NEAR
		retn
SetFileApisToOEM ENDP

;+---------------------------------------------------------------------------
; Win32 - GetShortPathNameA
;
; We assume that the input path string is in 8.3 format already.
;
GetShortPathNameA PROC NEAR
		mov	eax, [esp + 4]

gspnLoop1:
		cmp	BYTE PTR [eax], 1
		inc	eax
		jnc	gspnLoop1

		sub	eax, [esp + 4]
		cmp	eax, [esp + 12]
		ja	gspnExit

		mov	eax, [esp + 4]
		mov	ecx, [esp + 8]

gspnLoop2:
		mov	dl, [eax]
		inc	eax
		mov	[ecx], dl
		inc	ecx
		test	dl, dl
		jnz	gspnLoop2

		dec	eax

gspnExit:
		retn	12
GetShortPathNameA ENDP


;+----------------------------------------------------------------------------
; Win32 - CopyFileA
;
CopyFileA PROC NEAR

		pushad
		sub	ebx, ebx
		sub	ebp, ebp
		mov	edx, [esp + 4 + 32]
		mov	eax, 3D00h
		int	21h
		jc	cpfaTerm

		mov	ebx, eax
		mov	edx, [esp + 8 + 32]
		cmp	BYTE PTR [esp + 12 + 32], 0
		je	cpfaCheck

		mov	eax, 3D00h
		int	21h
		jc	cpfaCheck

		mov	ebp, eax
		jmp	cpfaTerm
		
cpfaCheck:
		mov	eax, 3C00h
		int	21h
		jc	cpfaTerm

		mov	ebp, eax

copyUntilDone:
		mov	edx, OFFSET CPBuffer
		mov	ecx, 4096
		mov	ah, 3Fh
		int	21h
		jc	cpfaTerm

		mov	ecx, eax
		jecxz	cpfaFinish

		xchg	ebp, ebx
		mov	ah, 40h
		int	21h
		xchg	ebp, ebx
		jc	cpfaTerm

		cmp	eax, ecx
		jne	cpfaTerm

		cmp	eax, 4096
		jnc	copyUntilDone

cpfaFinish:
		mov	BYTE PTR [esp + 28], 1
		mov	ax, 5700h
		int	21h
		xchg	ebx, ebp
		mov	ax, 5701h
		int	21h
		xchg	ebx, ebp
		sub	eax, eax

cpfaTerm:
		test	eax, eax
		jz	cpfaClose
		
		mov	LastError, eax		; fixme!

cpfaClose:
		test	ebx, ebx
		jz	cpfaDone

		mov	ah, 03Eh
		int	21h
		mov	ebx, ebp
		sub	ebp, ebp
		jmp	cpfaClose

cpfaDone:
		popad
		retn	12

CopyFileA ENDP


;+----------------------------------------------------------------------------
; Win32 - GetTempFileNameA
;
GetTempFileNameA PROC NEAR
		pushad
;
; Copy the path
;
		mov	edx, [esp + 32 + 4]
		mov	ebx, [esp + 32 + 16]
		sub	eax, eax

gtf_loop1:
		mov	al, [edx]
		inc	edx
		mov	[ebx], al
		inc	ebx
		test	al, al
		jnz	gtf_loop1
;
; If there is no trailing backslash, insert one
;
		dec	ebx
		dec	ebx
		cmp	BYTE PTR [ebx], '\'
		setne	al
		add	ebx, eax
		mov	BYTE PTR [ebx], '\'
		inc	ebx
;
; Copy the 3 bytes prefix
;
		mov	edx, [esp + 32 + 8]

		mov	ecx, 3

gtf_loop2:
		mov	al, [edx]
		test	al, al
		je	gtf_alphaok

		mov	[ebx], al
		inc	ebx
		loop	gtf_loop2

gtf_alphaok:
;
; EBX now points at the beginning of the numerical part
;
		mov	DWORD PTR [ebx + 4], 'pmt.'
		mov	BYTE PTR [ebx + 8], 0
		mov	esi, [esp + 12]
		test	esi, esi
		jnz	gtf_gotnum

gtf_getnum:
		inc	esi

gtf_gotnum:
		movzx	esi, si
		mov	[esp + 28], esi

		mov	edi, esi
		sub	edx, edx
		mov	ecx, 4

gtf_loop3:
		ror	edi, 4
		shld	edx, edi, 4
		shl	edx, 4
		cmp	dl, 10
		jc	gtf_noadj

		add	dl, 7

gtf_noadj:				
		loop	gtf_loop3

		add	edx, 30303030h
		mov	[ebx], edx
		cmp	DWORD PTR [esp + 12], 0
		jne	gtf_done

		mov	edx, [esp + 16 + 4]
		mov	ax, 3D00h
		int	21h
		jnc	gtf_close

		cmp	ax, 2
		je	gtf_done

		jmp	gtf_getnum

gtf_close:
		push	ebx
		mov	ebx, eax
		mov	ah, 3Eh
		int	21h
		pop	ebx
		jmp	gtf_getnum

gtf_done:
		popad
		retn	16
GetTempFileNameA ENDP


;+----------------------------------------------------------------------------
; Win32 - GetDiskFreeSpaceA
;
GetDiskFreeSpaceA PROC NEAR
		sub	eax, eax	; assume error
		pushad
		mov	edx, [esp + 4 + 32]
		test	edx, edx
		je	@@gfdsCallDOS

		mov	dl, [edx]
		and	dl, NOT 20h
		sub	dl, 'A' - 1

@@gfdsCallDOS:
		mov	ah, 36h
		int	21h
		cmp	ax, 0FFFFh
		je	@@gfdsExit

		movzx	eax, ax
		movzx	ebx, bx
		movzx	ecx, cx
		movzx	edx, dx

		mov	esi, [esp + 8  + 32]
		mov	edi, [esp + 12 + 32]
		mov	ebp, [esp + 16 + 32]
		mov	[esi], eax
		mov	esi, [esp + 20 + 32]
		mov	[edi], ebx
		mov	[ebp], ecx
		mov	[esi], edx

		inc	BYTE PTR [esp + 28]

@@gfdsExit:
		popad
		retn	20
GetDiskFreeSpaceA ENDP

;+----------------------------------------------------------------------------
; Win32 - FlushFileBuffers
;	Flushes buffers for ALL files as there is no direct equivalent in DOS
;
FlushFileBuffers PROC NEAR
		mov	ah, 0Dh
		int	21h
		mov	eax, 1
		retn	4
FlushFileBuffers ENDP

;+----------------------------------------------------------------------------
; Win32- SetHandleCount
;
SetHandleCount	PROC NEAR

		push	ebx
		movzx	ebx, word ptr [esp+8]
		mov	eax, 20
		cmp	ebx, eax
		jna	short @@shcDone

		push	ebx
		mov	ah, 67h
		int	21h
		mov	eax, 20
		pop	ebx
		jc	short @@shcDone

		mov	eax, ebx

@@shcDone:
		pop	ebx
		retn	4

SetHandleCount	ENDP

;+----------------------------------------------------------------------------
; Win32 - GetFullPathNameA
;
GetFullPathNameA PROC NEAR

		cmp	dword ptr [esp+8], 80
		jnc	short @@gfpn00

		mov	eax, 80
		retn	16

@@gfpn00:
;
; Determine if drive specified
;
		mov	eax, [esp + 4]
		cmp	BYTE PTR [eax + 1], ':'
		jne	@@gfpn06

		mov	edx, [esp + 12]
		mov	cx, [eax]
		add	eax, 2
		mov	[esp + 4], eax
		mov	[edx], cx
		mov	BYTE PTR [edx + 2], '\'
		push	esi
		lea	esi, [edx + 3]
		mov	ah, 47h
		mov	dl, [edx]
		and	dl, NOT ('a' - 'A')
		sub	dl, 'A' - 1
		int	21h
		mov	eax, 0
		pop	esi
		jc	@@gfpnFail
		
		mov	edx, [esp + 12]

@@gfpnScan:
		cmp	BYTE PTR [eax + edx], 0
		je	@@gfpn01

		inc	eax
		jmp	@@gfpnScan

@@gfpn06:
		push	dword ptr [esp+12]
		push	dword ptr [esp+12]
		call	GetCurrentDirectoryA
		test	eax, eax
		jnz	short @@gfpn01

@@gfpnFail:
		retn	16

@@gfpn01:
		mov	edx, [esp+12]
		add	edx, eax
		cmp	byte ptr [edx-1], '\'
		jz	short @@gfpn03

		mov	byte ptr [edx], '\'
		inc	edx

@@gfpn03:
		mov	ecx, [esp+16]
		jecxz	@@gfpn05

		mov	[ecx], edx

@@gfpn05:
		mov	ecx, [esp+4]

@@gfpn02:
		mov	al, [ecx]
		inc	ecx
		mov	[edx], al
		inc	edx
		test	al, al
		jnz	short @@gfpn02

		lea	eax, [edx-1]
		sub	eax, [esp+12]
		retn	16

GetFullPathNameA ENDP

;+----------------------------------------------------------------------------
; Win32 - GetCurrentDirectoryA
;
GetCurrentDirectoryA LABEL NEAR

		push	esi
		mov	esi, [esp+12]
		mov	ah, 19h
		int	21h
		add	al, 'A'
		mov	[esi], al
		inc	esi
		mov	word ptr [esi], '\:'
		inc	esi
		inc	esi
		sub	edx, edx
		mov	ah, 47h
		int	21h
		pop	esi
		jc	short mkdirError

		mov	eax, [esp+8]
@@gcd01:
		cmp	byte ptr [eax], 0
		jz	short @@gcd00

		inc	eax
		jmp	short @@gcd01

@@gcd00:
		sub	eax, [esp+8]
		retn	8

;+----------------------------------------------------------------------------
; Win32 - CreateDirectoryA
;
CreateDirectoryW LABEL NEAR
		call	W2A
CreateDirectoryA LABEL NEAR

		mov	ah, 39h
		mov	edx, [esp+4]
		int	21h

fromCwd:
		jc	short mkdirError

		mov	eax, 1
		retn	8

mkdirError:
		movzx	eax, al
		mov	LastError, eax
		sub	eax, eax
		retn	8

;+----------------------------------------------------------------------------
; Win32 - RemoveDirectoryA
;
RemoveDirectoryW LABEL NEAR
		call	W2A
RemoveDirectoryA LABEL NEAR

		mov	ah, 3Ah
		jmp	short fromRmdir

;+----------------------------------------------------------------------------
; Win32 - SetCurrentDirectoryA
;
SetCurrentDirectoryW LABEL NEAR
		call	W2A
SetCurrentDirectoryA LABEL NEAR

		mov	eax, [esp+4]
		cmp	BYTE PTR [eax+1], ':'
		jnz	short fromSetdrive

		mov	dl, [eax]
		or	dl, 20h
		sub	dl, 'a'
		mov	ah, 0Eh
		int	21h
		add	DWORD PTR [esp+4], 2

fromSetdrive:
		mov	ah,3Bh

fromRmdir:
		mov	LastError, 0
		mov	edx, [esp+4]
;
; Allow empty argument since SetCurrentDirectory("C:") is valid
;
		cmp	BYTE PTR [edx], 0
		je	SHORT chdirSuccess

		int	21h
		jc	SHORT chdirError

chdirSuccess:
		mov	eax, 1
		retn	4

chdirError:
		movzx	eax, al
		mov	LastError, eax
		sub	eax, eax
		retn	4

;+----------------------------------------------------------------------------
; Win32 - GetVolumeInformationA
;
; Note that this one returns FAT, even for a Network drive!
; No Volume name etc. returned either.
;
GetVolumeInformationA PROC NEAR
		
		mov	edx, [esp+8]
		test	edx, edx
		jz	short @@gvi01

		mov	byte ptr [edx], 0

@@gvi01:
		mov	edx, [esp+16]
		test	edx, edx
		jz	short @@gvi02

		mov	dword ptr [edx], 0

@@gvi02:
		mov	edx, [esp+20]
		test	edx, edx
		jz	short @@gvi03

		mov	dword ptr [edx], 12

@@gvi03:
		mov	edx, [esp+24]
		test	edx, edx
		jz	short @@gvi04

		and	dword ptr [edx], 0

@@gvi04:
		mov	edx, [esp+28]
		test	edx, edx
		jz	short @@gvi05

		mov	dword ptr [edx], 'TAF'

@@gvi05:
		mov	eax, 1
		retn	32

GetVolumeInformationA ENDP

;+----------------------------------------------------------------------------
; Win32 - GetDriveType
;

DRIVE_UNKNOWN	  EQU	0
DRIVE_NO_ROOT_DIR EQU	1
DRIVE_REMOVABLE   EQU	2
DRIVE_FIXED	  EQU	3
DRIVE_REMOTE	  EQU	4
DRIVE_CDROM	  EQU	5
DRIVE_RAMDISK	  EQU	6

GetDriveTypeA PROC NEAR

		push	ebx
		mov	ebx, [esp + 4 + 4]
		movzx	ecx, byte ptr [ebx]
		or	cl, 20h
		sub	cl, 61h
		mov	ax, 150Bh
		int	2Fh
		cmp	bx, 0ADADh
		jnz	@@gdta_if_removable

		or	ax, ax
		jz	@@gdta_if_removable

		mov	eax, DRIVE_CDROM
		jmp	@@gdta_exit

@@gdta_if_removable:
		mov	ecx, [esp + 4 + 4]
		movzx	ebx, byte ptr [ecx]
		or	bl, 20h
		sub	bl, 60h
		mov	eax, 4408h	; if removable
		int	21h
		jc	@@gdta_if_remote

		or	ax, ax
		jz	@@gdta_is_removable

		mov	eax, DRIVE_FIXED
		jmp	@@gdta_exit

@@gdta_is_removable:
		mov	eax, DRIVE_REMOVABLE
		jmp	@@gdta_exit

@@gdta_if_remote:
		mov	eax, 4409h	; if remote
		int	21h
		jc	@@gdta_is_unknown

		test	dx, 1000h
		jz	@@gdta_if_ramdisk

		mov	eax, DRIVE_REMOTE
		jmp	@@gdta_exit

@@gdta_if_ramdisk:
		test	dx, 0800h
		jz	@@gdta_is_unknown

		mov	eax, DRIVE_RAMDISK
		jmp	@@gdta_exit

@@gdta_is_unknown:
		sub	eax, eax	; DRIVE_UNKNOWN

@@gdta_exit:
		pop	ebx
		retn	4

GetDriveTypeA ENDP


;+----------------------------------------------------------------------------
; Win32 - GetLogicalDrives
;
GetLogicalDrives PROC NEAR

		push	ebx
		mov	ebx, 32
		sub	ecx, ecx

@@gld01:
		mov	eax, 4409h
		int	21h
		cmc
		adc	ecx, ecx
		dec	ebx
		jnz	short @@gld01
		
		mov	eax, ecx
		pop	ebx
		retn

GetLogicalDrives ENDP

;+----------------------------------------------------------------------------
; Win32 - GetLogicalDriveStringsA
;
GetLogicalDriveStringsA PROC NEAR

		push	ebx
		push	edi
		xor	ecx, ecx
		mov	edi, [esp + 8 + 8]
		cmp	edi, ecx
		jz	@@gldsa00
		mov	ebx, 1

@@gldsa01:
		mov	eax, 4409h
		int	21h
		jc	@@gldsa02

		mov	eax, 5C3A61h - 1 ; 'a:\',0
		add	ecx, 4
		add	eax, ebx
		cmp	ecx, [esp + 4 + 8]
		ja	@@gldsa02

		mov	[edi], eax
		add	edi, 4

@@gldsa02:
		inc	ebx
		cmp	ebx, 26
		jbe	@@gldsa01

		mov	BYTE PTR [edi], 0

@@gldsa00:
		mov	eax, ecx
		pop	edi
		pop	ebx
		retn	8

GetLogicalDriveStringsA ENDP

;+----------------------------------------------------------------------------
; Win32 - FindFirstFileA
;
FindFirstFileA PROC NEAR

		mov	edx, offset NewDTA + (80h * 31)
		mov	ecx, 31
		mov	eax, ffHandles

@@fff01:
		add	eax, eax
		jnc	short @@fff00

		sub	edx, 80h
		loop	short @@fff01

		mov	LastError, 113
		or	eax, -1
		retn	8

@@fff00:
		mov	ah, 1Ah
		int	21h
		push	ecx
		push	edx
		mov	ecx, -1
		mov	edx, [esp+12]
		mov	eax, 4E00h
		int	21h
		pop	edx
		pop	ecx
		jc	short @@fff02

		bts	ffHandles, ecx
		push	ecx
		mov	ecx, [esp+12]
		sub	eax, eax
		mov	al, [edx+15h]
		mov	[ecx], eax
		lea	eax, [ecx+4]
		push	ecx
		push	edx
		push	eax
		movzx	eax, word ptr [edx+16h]
		push	eax
		movzx	eax, word ptr [edx+18h]
		push	eax
		call	DosDateTimeToFileTime
		pop	edx
		pop	ecx
		mov	eax, [ecx+4]
		mov	[ecx+12], eax
		mov	[ecx+20], eax
		mov	eax, [ecx+8]
		mov	[ecx+16], eax
		mov	[ecx+24], eax
		and	dword ptr [ecx+28], 0
		mov	eax, [edx+1Ah]
		mov	[ecx+32], eax
		sub	eax, eax

@@fff03:	
		mov	al, [edx+1Eh]
		inc	edx
		mov	[ecx + 44], al
		mov	[ecx + 304], al
		inc	ecx
		test	al, al
		jnz	short @@fff03

		pop	eax
		retn	8

@@fff02:
		mov	LastError, eax
		or	eax, -1
		retn	8

FindFirstFileA ENDP

;+----------------------------------------------------------------------------
; Win32 - FindNextFileA
;
FindNextFileA PROC NEAR

		mov	edx, [esp+4]
		mov	eax, 6
		cmp	edx, 32
		jnc	short @@fnf00

		shl	edx, 7
		add	edx, offset NewDTA
		mov	ah, 1Ah
		int	21h
		mov	ah, 4Fh
		int	21h
		jc	short @@fnf00

		mov	ecx, [esp+8]
		sub	eax, eax
		mov	al, [edx+15h]
		mov	[ecx], eax
		lea	eax, [ecx+4]
		push	ecx
		push	edx
		push	eax
		movzx	eax, word ptr [edx+16h]
		push	eax
		movzx	eax, word ptr [edx+18h]
		push	eax
		call	DosDateTimeToFileTime
		pop	edx
		pop	ecx
		mov	eax, [ecx+4]
		mov	[ecx+12], eax
		mov	[ecx+20], eax
		mov	eax, [ecx+8]
		mov	[ecx+16], eax
		mov	[ecx+24], eax
		and	dword ptr [ecx+28], 0
		mov	eax, [edx+1Ah]
		mov	[ecx+32], eax
		sub	eax, eax

@@fnf01:	
		mov	al, [edx+1Eh]
		inc	edx
		mov	[ecx + 44], al
		mov	[ecx + 304], al
		inc	ecx
		test	al, al
		jnz	short @@fnf01

		mov	al, 1
		retn	8

@@fnf00:
		mov	LastError, eax
		sub	eax, eax
		retn	8

FindNextFileA ENDP

;+----------------------------------------------------------------------------
; Win32 - FindClose:

FindClose PROC NEAR

		mov	eax, [esp + 4]
		cmp	eax, 32
		jc	short @@fcl00

@@fcl01:
		mov	LastError, 6
		sub	eax, eax
		retn	4

@@fcl00:
		btr	ffHandles, eax
		jnc	short @@fcl01

		mov	eax, 1
		retn	4

FindClose ENDP

;+----------------------------------------------------------------------------
; Win32 - GetFileInformationByHandle
;
; Only the filesize being reported though
;
GetFileInformationByHandle PROC NEAR
		mov	ecx, 13
		mov	edx, [esp + 8]
;
; Clear the structure
;
@@gfibhLoop:
		mov	DWORD PTR [edx + ecx * 4 - 4], 0
		loop	@@gfibhLoop

		mov	BYTE PTR [edx].bhfi.nNumberOfLinks, 1
		push	ebx
		mov	ebx, [esp + 4 + 4]
		HANDLE_W2D ebx
		mov	ax, 4201h
		sub	edx, edx
		sub	ecx, ecx
		int	21h
		jc	@@gfibhErr

		push	eax
		push	edx

		sub	edx, edx
		mov	ax, 4202h
		int	21h
		mov	ecx, [esp + 12 + 8]
		mov	WORD PTR [ecx].bhfi.nFileSizeLow, ax		
		mov	WORD PTR [ecx + 2].bhfi.nFileSizeLow, dx
		pop	ecx
		pop	edx
		mov	ax, 4200h
		int	21h

@@gfibhErr:
		pop	ebx
		mov	eax, 0
		setnc	al
		retn	8
GetFileInformationByHandle ENDP
		

;+----------------------------------------------------------------------------
; Win32 - MoveFileA
;
; Differences to Win32 API: moving files across drives not permitted.
;
MoveFileA PROC NEAR

		push	edi
		mov	edx, [esp+8]
		mov	edi, [esp+12]
		sub	ecx, ecx
		mov	ah, 56h
		int	21h
		jnc	short @@mva01

		movzx	eax, al
		mov	LastError, eax
		sub	eax, eax
		jmp	short @@mva02

@@mva01:
		mov	eax, 1

@@mva02:
		pop	edi
		retn	8

MoveFileA ENDP

;+----------------------------------------------------------------------------
; Win32 - DeleteFileA
;
DeleteFileW LABEL NEAR
		call	W2A
DeleteFileA PROC NEAR

		mov	edx, [esp + 4]
		mov	ah, 41h
		int	21h
		jnc	short @@df01

		movzx	eax, al
		mov	LastError, eax

@@df01:
		sbb	eax, eax
		inc	eax
		retn	4

DeleteFileA ENDP

;+----------------------------------------------------------------------------
; Win32 - WriteFile
;
; Too many differences to list.
;
WriteFile PROC NEAR

		push	ebx
		mov	ebx, [esp + 8]
		mov	edx, [esp + 12]
		mov	ecx, [esp + 16]
		HANDLE_W2D ebx
		call	consoleWriteFileHook
		jnc	short @@wf02

		test	ecx, ecx
		mov	eax, ecx
		jz	short @@wf01

		mov	ah, 40h
		int	21h
		jnc	short @@wf02

@@wf01:
		movzx	eax, al
		mov	LastError, eax

@@wf02:
		mov	ecx, [esp + 20]
		mov	[ecx], eax
		pop	ebx
		sbb	eax, eax
		inc	eax
		retn	20

WriteFile ENDP

;+----------------------------------------------------------------------------
; Win32 - SetFilePointer
;
SetFilePointer PROC NEAR

		push	ebx
		mov	ebx, [esp + 8]
		HANDLE_W2D ebx
		mov	edx, [esp + 12]
		mov	ecx, [esp + 16]
		test	ecx, ecx
		jz	@@sf00

		and	DWORD PTR [ecx], 0

@@sf00:
		mov	eax, [esp + 20]
		shld	ecx, edx, 16
		mov	ah, 42h
		int	21h
		mov	LastError, 0
		movzx	eax, ax
		jnc	short @@sf01

		mov	LastError, eax
		sbb	eax, eax
		jmp	@@sf02

@@sf01:
		shl	edx, 16
		or	eax, edx		

@@sf02:
		pop	ebx
		retn	16

SetFilePointer ENDP

;+----------------------------------------------------------------------------
; Win32 - SetEndOfFile
;
SetEndOfFile PROC NEAR

		push	ebx
		mov	ebx, [esp + 8]
		HANDLE_W2D ebx
		sub	ecx, ecx
		mov	ah, 40h
		int	21h
		jnc	short @@seof01

		movzx	eax, al
		mov	LastError, eax

@@seof01:
		sbb	eax, eax
		inc	eax
		pop	ebx
		retn	4

SetEndOfFile ENDP

;+----------------------------------------------------------------------------
; Win32 - ReadFile
;
ReadFile PROC NEAR

		push	ebx
		mov	ebx, [esp + 8]
		HANDLE_W2D ebx
		mov	edx, [esp + 12]
		mov	ecx, [esp + 16]
		call	consoleReadFileHook
		jnc	short @@rf01
		
		mov	ah, 3Fh
		int	21h
		jnc	short @@rf01

		movzx	eax, al
		mov	LastError, eax

@@rf01:
		mov	edx, [esp + 20]
		mov	[edx], eax
		sbb	eax, eax
		inc	eax
		pop	ebx
		retn	20

ReadFile ENDP

;+----------------------------------------------------------------------------
; Win32 - GetStdHandle
;
; As we currently do not support SetStdHandle, we can handle things relaxed.
;
GetStdHandle PROC NEAR

	 	mov	eax, [esp+4]
		neg	eax
		sub	eax, 10
		jc	short @@gsh01

		cmp	eax, 3
		jnc	short @@gsh01
	
		HANDLE_D2W eax
		retn	4

@@gsh01:
		or	eax, -1
		retn	4

GetStdHandle ENDP

;+----------------------------------------------------------------------------
; Win32 - SetStdHandle
;
SetStdHandle LABEL NEAR
		int	3

;+----------------------------------------------------------------------------
; Win32 - GetFileSize
;
GetFileSize PROC NEAR

		push	ebp
		push	ebx
		mov	ebp, esp
		push	ebx
		mov	ebx, [ebp + 12]
		HANDLE_W2D ebx
		sub	edx, edx
		sub	ecx, ecx
		mov	eax, 4201h
		int	21h
		jc	short @@gfs01

		push	edx
		push	eax
		sub	edx, edx
		sub	ecx, ecx
		mov	eax, 4202h
		int	21h
		jc	short @@gfs01

		shl	edx, 16
		or	eax, edx
		pop	edx
		pop	ecx
		push	eax
		mov	eax, 4200h
		int	21h
		jc	short @@gfs01

		pop	eax
		jmp	short @@gfs02

@@gfs01:
		movzx	eax, al
		mov	LastError, eax
		sbb	eax, eax

@@gfs02:
		mov	esp, ebp
		pop	ebx
		pop	ebp
		retn	8

GetFileSize ENDP

;+----------------------------------------------------------------------------
; Win32 - GetFileType
;
GetFileType PROC NEAR

		push	ebx
		mov	ebx, [esp + 8]
		HANDLE_W2D ebx
		mov	eax, 4400h
		int	21h
		pop	ebx
		jc	@@gft01
;
; DX bit 7 set means character device, if a disk file, bit 15 set means remote
;
; FILE_TYPE_UNKNOWN   = 0000
; FILE_TYPE_DISK      = 0001
; FILE_TYPE_CHAR      = 0002
; FILE_TYPE_PIPE      = 0003
; FILE_TYPE_REMOTE    = 8000
;
		shr	dl, 7			; isolate char / disk bit
		je	isDiskFile

		sub	dh, dh
		je	finalizeFileType

isDiskFile:
		and	dh, 80h			; remote ?
		setnz	dl			; 1 if remote, 0 otherwise
		neg	dl			; - 1 if remote, 0 otherwise

finalizeFileType:
		inc	dl
		movzx	eax, dx
		retn	4

@@gft01:
		movzx	eax, al
		mov	LastError, eax
		sub	eax, eax
		retn	4

GetFileType ENDP

;+----------------------------------------------------------------------------
; Win32 - CreateFileA
;
; Main difference is that we cannot create anything but a file.
;
CreateFileW LABEL NEAR
		call	W2A
CreateFileA PROC NEAR

		GEN_READ	EQU	80h
		GEN_WRITE	EQU	40h
;
; Check whether stdio handle requested
;
		mov	edx, [esp + 4]
		call	CheckConHandle
		jnc	@@cfa09

		mov	eax, DWORD PTR [esp  + 8]
		mov	ecx, [esp + 20]
		shr	eax, 30
		mov	al, cfaFlags[eax]
		dec	ecx
		cmp	ecx, 5
		jnc	@@cfaError		; invalid argument

		call	cfaTable[ecx * 4]
		jc	@@cfaError

@@cfa09:
		HANDLE_D2W eax
		retn	28

@@cfaError:
		movzx	eax, al
		mov	LastError, eax		; incorrect!
		or	eax, -1
		retn	28

CreateFileA ENDP

;
; Helper stuff for CreateFileA
;
cfaCreateNew LABEL NEAR
		mov	eax, 3D00h
		int	21h
		jc	cfaCreateAlways

@@closeErr:
		push	ebx
		mov	ebx, eax
		mov	ah, 3Eh
		int	21h
		pop	ebx
		stc
		retn

cfaCreateAlways LABEL NEAR
		sub	ecx, ecx
		mov	ah, 3Ch
		int	21h
		retn

cfaOpenExisting LABEL NEAR
		mov	ah, 3Dh
		int	21h
		retn

cfaOpenAlways LABEL NEAR
		mov	ah, 3Dh
		int	21h
		jc	cfaCreateAlways

		retn

cfaTruncateExisting LABEL NEAR
		mov	ah, 3Dh
		int	21h
		jc	@@teErr

		push	ebx
		mov	ebx, eax
		mov	ah, 40h
		sub	ecx, ecx
		int	21h
		pop	ebx
		jc	@@closeErr

@@teErr:
		retn


;+----------------------------------------------------------------------------
; Win32 - CloseHandle
;
CloseHandle PROC NEAR
		cmp	DWORD PTR [esp+4], 12345678h
		je	@@ch02

		push	ebx
		mov	ebx, [esp+8]
		HANDLE_W2D ebx
		mov	ah, 3Eh
		int	21h
		jnc	short @@ch01

		movzx	eax, al
		mov	LastError, eax

@@ch01:
		pop	ebx

@@ch02:
		sbb	eax, eax
		inc	eax
		retn	4

CloseHandle ENDP

;+----------------------------------------------------------------------------
; Win32 - GetFileAttributesA
;
GetFileAttributesW LABEL NEAR
		call	W2A
GetFileAttributesA PROC NEAR

		mov	edx, [esp+4]
		mov	eax, 4300h
		int	21h
		jc	short @@gfa02

		mov	eax, FILE_ATTRIBUTE_NORMAL
		and	ecx, 037h
		jz	short @@gfa01

		mov	eax, ecx

@@gfa01:
		retn	4

@@gfa02:
		movzx	eax, al
		mov	LastError, eax
		or	eax, -1
		retn	4

GetFileAttributesA ENDP

;+----------------------------------------------------------------------------
; Win32 - SetFileAttributesA
;
SetFileAttributesW LABEL NEAR
		call	W2A
SetFileAttributesA PROC NEAR

		mov	ecx, [esp+8]
		and	ecx, 37h
		mov	edx, [esp+4]
		mov	eax, 4301h
		int	21h
		jc	short @@sfa01

		mov	eax, 1
		retn	8

@@sfa01:
		movzx	eax, al
		mov	LastError, eax
		sub	eax, eax
		retn	8

SetFileAttributesA ENDP

;+----------------------------------------------------------------------------
; Win32 - GetFileTime
;
GetFileTime PROC NEAR

		push	ebx
		mov	ebx, [esp+8]
		HANDLE_W2D ebx
		mov	eax, 5700h
		int	21h
		jc	short @@gftim00

		movzx	ecx, cx
		movzx	edx, dx
		sub	esp, 8
		push	esp
		push	ecx
		push	edx
		call	DosDateTimeToFileTime
		pop	eax
		pop	edx
		mov	ecx, [esp+12]
		test	ecx, ecx
		jz	short @@gftim01

		mov	[ecx], eax
		mov	[ecx+4], edx

@@gftim01:
		mov	ecx, [esp+16]
		test	ecx, ecx
		jz	short @@gftim02

		mov	[ecx], eax
		mov	[ecx+4], edx

@@gftim02:
		mov	ecx, [esp+20]
		test	ecx, ecx
		jz	short @@gftim03

		mov	[ecx], eax
		mov	[ecx+4], edx

@@gftim03:
		mov	eax, 1
		jmp	short @@gftim04

@@gftim00:
		mov	LastError, eax
		sub	eax, eax

@@gftim04:
		pop	ebx
		retn	16

GetFileTime ENDP

;+----------------------------------------------------------------------------
; Win32 - SetFileTime
;
SetFileTime PROC NEAR

		push	ebx
		mov	ebx, [esp+8]
		HANDLE_W2D ebx
		mov	ecx, [esp+20]
		test	ecx, ecx
		jnz	short @@sft00

@@sft01:
		pop	ebx
		mov	eax, 1
		retn	16

@@sft00:
		sub	esp, 8
		push	esp
		lea	eax, [esp+8]
		push	eax
		push	ecx
		call	FileTimeToDosDateTime
		pop	ecx
		pop	edx
		mov	eax, 5701h
		int	21h
		jnc	short @@sft01

		mov	LastError, eax
		sub	eax, eax
		pop	ebx
		retn	16

SetFileTime ENDP

;----------------------------------------------------------------------------
; CheckConHandle
;
; In:   EDX -> file name
;
; Exit: CF clear if match, EAX = handle
;
CheckConHandle PROC NEAR
		sub	eax, eax
		pushad
		cld
		mov	esi, edx
		mov	edi, OFFSET inputStr
		mov	ecx, 7
		repe	cmpsb
		je	@@cchDone

		mov	DWORD PTR [esp + 28], hStdout
		mov	esi, edx
		mov	edi, OFFSET outputStr
		mov	ecx, 8
		repe	cmpsb
		je	@@cchDone

		stc

@@cchDone:
		popad
		retn
CheckConHandle ENDP

W2A PROC NEAR
		mov	edx, OFFSET UCFnBuffer
		mov	ecx, [esp + 8]
		mov	[esp + 8], edx

@@w2aLoop:
		mov	al, [ecx]
		add	ecx, 2
		mov	[edx], al
		inc	edx
		test	al, al
		jnz	@@w2aLoop

		retn
W2A ENDP

.data

ALIGN 4

cfaTable	LABEL	DWORD
		dd	OFFSET	cfaCreateNew
		dd	OFFSET	cfaCreateAlways
		dd	OFFSET	cfaOpenExisting
		dd	OFFSET	cfaOpenAlways
		dd	OFFSET	cfaTruncateExisting

cfaFlags	db	0, 1, 0, 2

inputStr	db	'CONIN$',0
outputStr	db	'CONOUT$',0

.data?

UCFnBuffer	db	260 dup (?)
CPBuffer	db	4096 dup (?)

	END
