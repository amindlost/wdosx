; ############################################################################
; ## WDOSX DOS Extender 	  Copyright (c) 1996, 1999, Michael Tippach ##
; ##									    ##
; ## Released under the terms of the WDOSX license agreement.		    ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/win32/CONSOLE.ASM 1.24 2000/05/28 08:54:40 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: CONSOLE.ASM $
; Revision 1.24  2000/05/28 08:54:40  MikeT
; Avoid div0 exception on embedded systems that do not have a video card.
;
; Revision 1.23  2000/05/26 21:18:18  MikeT
; Fixed Borland C++ getch() to uppercase/lowercase issue. New translation table
; has been introduced.
;
; Revision 1.22  2000/02/10 19:17:36  MikeT
; Corrected header from previous check in.
;
; Revision 1.21  2000/02/10 19:05:02  MikeT
; GenerateKeyEvent does now force upper case for A-Z
;
; Revision 1.20  1999/06/20 18:55:40  MikeT
; Replaced the previous version by this bug fixed one supplied by Tony Low.
; Numerous issues fixed.
;
; Revision 1.19  1999/05/14 00:41:33  MikeT
; Added missing handle translation for GetNumberOfConsoleInputEvents() call
; in WaitForSingleObject(). This does not fix anything but just makes it more
; correct.
;
; Revision 1.18  1999/03/21 15:43:34  MikeT
; Translate file handles between DOS and WIN.
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
; Revision 1.17  1999/03/06 23:16:30  MikeT
; Removed GetOEMCP and friends. These are now part of k32nls.asm.
;
; Revision 1.16  1999/02/07 21:10:02  MikeT
; Updated copyright.
;
; Revision 1.15  1998/09/24 23:55:57  MikeT
; Fix: SetConsoleMode would destroy BX if mouse reinitialized.
;
; Revision 1.14  1998/09/20 17:33:59  MikeT
; Fix warning message when assembling with TASM32.EXE.
;
; Revision 1.13  1998/08/27 22:55:53  MikeT
; Clear mouse events when flushing console input buffer.
;
; Revision 1.12  1998/08/25 01:50:28  MikeT
; Some cleanup done. No functional change.
;
; Revision 1.11  1998/08/24 23:32:06  MikeT
; += Read/WriteConsoleA
;
; Revision 1.10  1998/08/24 23:18:17  MikeT
; +=Sleep, WaitForSingleObject
;
; Revision 1.9	1998/08/23 23:16:29  MikeT
; Fix control key recongnicion
;
; Revision 1.8	1998/08/23 19:29:28  MikeT
; Cleanup += ScrollConsoleSB
;
; Revision 1.7	1998/08/23 19:28:24  MikeT
; Fix rectangle sizes
;
; Revision 1.6	1998/08/15 20:56:07  MikeT
; +=Mouse support
;
; Revision 1.5	1998/08/12 23:55:28  MikeT
; Key input rewritten
;
; Revision 1.4	1998/08/09 18:38:44  MikeT
; fix cursor shape
;
; Revision 1.3	1998/08/09 17:16:34  MikeT
; Fix Fill*, more funs
;
; Revision 1.2	1998/08/08 15:38:55  MikeT
; +more funs (development)
;
; Revision 1.1	1998/08/03 01:39:00  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## Console support functions						    ##
; ############################################################################
.386p

include w32struc.inc

bdaVideoMode		EQU	BYTE PTR ds:[449h]
bdaVideoColums		EQU	WORD PTR ds:[44Ah]
bdaVideoBufferSize	EQU	WORD PTR ds:[44Ch]
bdaVideoCurrentOffset	EQU	WORD PTR ds:[44Eh]
bdaCursorPositions	EQU	WORD PTR ds:[450h]
bdaCursorType		EQU	WORD PTR ds:[460h]
bdaVideoCurrentPage	EQU	BYTE PTR ds:[462h]
bdaVideoRowsMinusOne	EQU	BYTE PTR ds:[484h]
bdaVideoCharHeight	EQU	WORD PTR ds:[485h]

.model flat
.code

		PUBLIC		initConsole
		PUBLIC		consoleWriteFileHook
		PUBLIC		consoleReadFileHook

consoleWriteFileHook	PROC NEAR
		stc
		ret
consoleWriteFileHook	ENDP

consoleReadFileHook	PROC NEAR
		stc
		ret
consoleReadFileHook	ENDP

		ALT	EQU	2
		CTRL	EQU	8
		SHIFT	EQU	16

GetCtrlKeyState PROC NEAR
		push	ecx
		mov	ah, 2
		int	16h
		shl	eax, 8
		bt	eax, 6 + 8	; caps
		adc	al, al
		bt	eax, 4 + 8	; scroll
		adc	al, al
		bt	eax, 5 + 8	; num
		adc	al, al
		bt	eax, 0 + 8	; shift
		adc	al, al
		bt	eax, 1 + 8	; shift again
		setc	cl
		or	al, cl
		bt	eax, 2 + 8	; ctrl
		adc	al, al
		add	al, al
		bt	eax, 3 + 8	; alt
		adc	al, al
		add	al, al
		pop	ecx
		retn
GetCtrlKeyState ENDP

GenerateKeyEvent	PROC NEAR
		mov	eax, [esp+4]
		mov	edx, [esp+8]
		push	ecx
		xor	ecx, ecx
;
; Initilaize all fields
;
		sub	eax, eax
		mov	[edx][KEY_EVENT_RECORD.dwControlKeyState], eax
		inc	eax
		mov	[edx][KEY_EVENT_RECORD.wEventType], eax
		mov	[edx][KEY_EVENT_RECORD.bKeyDown], eax
		mov	[edx][KEY_EVENT_RECORD.wRepeatCount], ax
		mov	al, [esp + 8]
		mov	[edx][KEY_EVENT_RECORD.Character], ax
		cmp	al, 128
		jnc	gkeAAdj

		mov	cl, [eax + eax + OFFSET VkATbl + 1]
		mov	al, [eax + eax + OFFSET VkATbl]

gkeAAdj:
		mov	[edx][KEY_EVENT_RECORD.wVirtualKeyCode],  ax
		mov	eax, [esp + 8]
		test	ecx, ecx
		jnz	@@setScanAndEnd

		test	al, al
		jnz	@@VkLookup

		mov	cl, ah
		cmp	cl, 8Ch
		ja	@@noTrans

		mov	cx, [ecx + ecx].VkXTbl
		test	cl, cl
		jnz	@@transDone

@@noTrans:
;
; Checking the current control key state is the last ressort...
;
		mov	ch, 1			; signal extended key
		push	eax			; save scancode
		call	GetCtrlKeyState
		mov	cl, al
		pop	eax			; restore scancode

@@setScanAndEnd:
		shr	ax, 8			; AX = scancode
		jmp	@@writeVKandFlags

@@transdone:
;
; cl = scan code, ch = flags
;
		movzx	eax, cl
		shr	ecx, 8
		jmp	@@writeVKandFlags

@@VkLookup:
		cmp	ax, 20h
		jnc	@@setScanAndEnd

		mov	cl, al
		mov	cl, [ecx].CntrlXTbl
		mov	ch, CTRL
		test	cl, cl
		jnz	@@transdone

		sub	eax, eax

@@writeVKandFlags:
		mov	[edx][KEY_EVENT_RECORD.wVirtualScanCode], ax
		movzx	ecx, cx
		mov	[edx][KEY_EVENT_RECORD.dwControlKeyState], ecx
		pop	ecx
		retn	8

GenerateKeyEvent ENDP


; Functions to be emulated:

;+	  AllocConsole
;+	  Beep
;+	  CreateConsoleScreenBuffer
;	 DoMessageBoxA
;+	  FillConsoleOutputAttribute
;+	  FillConsoleOutputCharacterA
;+	  FlushConsoleInputBuffer
;+	  FreeConsole
;+	  GetACP
;+	  GetConsoleCP
;+	  GetConsoleCursorInfo
;+	  GetConsoleMode
;+	  GetConsoleOutputCP
;++	   GetConsoleScreenBufferInfo
;	 GetConsoleTitleA
;++	   GetLargestConsoleWindowSize
;++	   GetNumberOfConsoleInputEvents
;+	  GetNumberOfConsoleMouseButtons
;+	 GetOEMCP
;++	   PeekConsoleInputA
;+	  ReadConsoleA
;++	   ReadConsoleInputA
;	 ReadConsoleOutputA
;	 ReadConsoleOutputAttribute
;	 ReadConsoleOutputCharacterA
;+	  ScrollConsoleScreenBufferA
;	 SetConsoleCP
;+	  SetConsoleCursorInfo
;++	   SetConsoleCursorPosition
;++	   SetConsoleMode
;	 SetConsoleOutputCP
;++	   SetConsoleScreenBufferSize
;++	   SetConsoleTextAttribute
;	 SetConsoleTitleA
;++	   SetConsoleWindowInfo
;	 ShowConsoleCursor
;+	  Sleep
;	 WaitForMultipleObjects
;+	  WaitForSingleObject
;+	  WriteConsoleA
;	 WriteConsoleInputA
;+	  WriteConsoleOutputA
;	 WriteConsoleOutputAttribute
;	 WriteConsoleOutputCharacterA

		PUBLICDLL		AllocConsole

AllocConsole LABEL NEAR

		sub	eax, eax
		retn


		PUBLICDLL		Beep

Beep PROC NEAR
;
; The NT thing since the Borland C RTL is using this for SOUND()
;
		movsx	ecx, word ptr [esp+4]
		cmp	ecx, 24
		jng	short BeepDont

		mov	eax, 1193180
		sub	edx, edx
		div	ecx
		mov	ecx, eax
		mov	al, 182
		out	43h, al
		mov	al, cl
		out	42h, al
		mov	al, ch
		out	42h, al
		in	al, 61h
		or	al, 3
		out	61h, al
		mov	edx, [esp+8]
		inc	edx
		jz	short BeepDone

		shld	ecx, edx, 16
		mov	ah, 86h
		int	15h

BeepDont:
		in	al, 61h
		and	al, 0FCh
		out	061h, al

BeepDone:
		mov	eax, 1
		retn	8

Beep ENDP

;+----------------------------------------------------------------------------
; Win32 - CreateConsoleScreenBuffer (returns error)
;
		PUBLICDLL		CreateConsoleScreenBuffer

CreateConsoleScreenBuffer PROC NEAR

		mov	eax, -1
		retn	20

CreateConsoleScreenBuffer ENDP

;DoMessageBoxA:
; 2do!
;		retn	12

;+----------------------------------------------------------------------------
; Win32 - FillConsoleOutputAttribute
;
		PUBLICDLL		FillConsoleOutputAttribute

FillConsoleOutputAttribute PROC NEAR
		mov	ax, 2
		int	33h
;
; Get the size of the current screen buffer in ecx
;
		movzx	ecx, ScreenBufferInfo.dwMaximumWindowSize.X
		imul	cx, ScreenBufferInfo.dwMaximumWindowSize.Y
;
; Get the offset into the buffer in edx
;
		movzx	edx, ScreenBufferInfo.dwMaximumWindowSize.X
		imul	dx, WORD PTR [esp + 18]
		add	dx, WORD PTR [esp + 16]
;
; Calculate maximum length
;
		sub	ecx, edx

		cmp	ecx, [esp + 12]
		jc	@@fcaasizeok

		mov	ecx, [esp + 12]

@@fcaasizeok:
		mov	eax, [esp + 20] ; get lpNumberOfcharsWritten
		mov	[eax], ecx	; Write NumberOfcharsWritten

		call	GetScreenPtr
		lea	edx, [edx * 2 + eax + 1]

		mov	eax, [esp + 8]	; get attribute

@@fcaaloop:
		mov	[edx], al
		add	edx, 2
		dec	ecx
		jnz	@@fcaaloop

		mov	ax, 1
		int	33h
		mov	eax, 1
		retn	20

FillConsoleOutputAttribute ENDP

;+----------------------------------------------------------------------------
; Win32 - FillConsoleOutputCharacterA
;
		PUBLICDLL		FillConsoleOutputCharacterA

FillConsoleOutputCharacterA PROC NEAR
		mov	ax, 2
		int	33h
;
; Get the size of the current screen buffer in ecx
;
		movzx	ecx, ScreenBufferInfo.dwMaximumWindowSize.X
		imul	cx, ScreenBufferInfo.dwMaximumWindowSize.Y
;
; Get the offset into the buffer in edx
;
		movzx	edx, ScreenBufferInfo.dwMaximumWindowSize.X
		imul	dx, WORD PTR [esp + 18]
		add	dx, WORD PTR [esp + 16]
;
; Calculate maximum length
;
		sub	ecx, edx

		cmp	ecx, [esp + 12]
		jc	@@fcacsizeok

		mov	ecx, [esp + 12]

@@fcacsizeok:
		mov	eax, [esp + 20] ; get lpNumberOfcharsWritten
		mov	[eax], ecx	; Write NumberOfcharsWritten
		jecxz	@@fcacjcxz

		call	GetScreenPtr
		lea	edx, [edx * 2 + eax]

		mov	eax, [esp + 8]	; get char

@@fcacloop:
		mov	[edx], al
		add	edx, 2
		dec	ecx
		jnz	@@fcacloop

@@fcacjcxz:
		mov	ax, 1
		int	33h
		mov	eax, 1
		retn	20

FillConsoleOutputCharacterA ENDP

;+----------------------------------------------------------------------------
; Win32 - FlushConsoleInputBuffer
;
		PUBLICDLL		FlushConsoleInputBuffer

FlushConsoleInputBuffer PROC NEAR

		mov	ah, 1
		int	16h
		jz	short fcip01

		sub	ah, ah
		int	16h
		jmp	short FlushConsoleInputBuffer

fcip01:
		mov	ActiveEvent, 0
		mov	eax, 1
		retn	4

FlushConsoleInputBuffer ENDP


;+----------------------------------------------------------------------------
; Win32 - FreeConsole (stub)
;
		PUBLICDLL		FreeConsole

FreeConsole PROC NEAR

		mov	eax, 1
		retn

FreeConsole ENDP


;+----------------------------------------------------------------------------
; Win32 - GetConsoleCursorInfo
;
			PUBLICDLL		GetConsoleCursorInfo

GetConsoleCursorInfo PROC NEAR

		call	UpdateStrucs
		mov	edx, [esp + 8]
		mov	eax, CursorInfo.bVisible
		mov	[edx].CONSOLE_CURSOR_INFO.bVisible, eax
		mov	eax, CursorInfo.dwCursorSize
		mov	[edx].CONSOLE_CURSOR_INFO.dwCursorSize, eax
		mov	eax, 1
		retn	8

GetConsoleCursorInfo ENDP

;----------------------------------------------------------------------------
; Win32 - GetConsoleMode
;
		PUBLICDLL	GetConsoleMode

GetConsoleMode PROC NEAR

		HANDLE_W2D <DWORD PTR [esp + 4]>
		mov	ecx, [esp+8]
		cmp	DWORD PTR [esp + 4], hStdout
		mov	eax, ConsoleOutputMode
		je	@@gcmdone

		mov	eax, ConsoleInputMode

@@gcmdone:
		mov	[ecx], eax
		mov	eax, 1
		retn	8

GetConsoleMode ENDP


;GetConsoleTitleA:

;+----------------------------------------------------------------------------
; Win32 - GetNumberOfConsoleInputEvents
;
			PUBLICDLL		GetNumberOfConsoleInputEvents

GetNumberOfConsoleInputEvents PROC NEAR

		mov	edx, [esp+8]
		sub	ecx, ecx
		mov	ah, 1
		int	16h
		setne	cl
		jnz	@@gnciDone

		call	UpdateMouse
		mov	cl, ActiveEvent

@@gnciDone:
		mov	[edx], ecx
		retn	8

GetNumberOfConsoleInputEvents ENDP

;+----------------------------------------------------------------------------
; Win32 - GetNumberOfConsoleMouseButtons (returns 2 regardless)
;
			PUBLICDLL		GetNumberOfConsoleMouseButtons

GetNumberOfConsoleMouseButtons PROC NEAR
		mov	eax, consoleMouseButtons
		add	eax, eax
		jz	@@cmbdone

		mov	edx, [esp + 4]
		mov	[edx], eax
		dec	eax

@@cmbdone:
		retn	4
GetNumberOfConsoleMouseButtons ENDP

;+----------------------------------------------------------------------------
; Win32 - PeekConsoleInputA
;
			PUBLICDLL		PeekConsoleInputA

PeekConsoleInputA PROC NEAR

		mov	edx, [esp+16]
		sub	ecx, ecx
		mov	ah, 1
		int	16h
		setne	cl
		mov	[edx], ecx
		jecxz	Pkinput01

		push	dword ptr [esp+8]
		push	eax
		call	GenerateKeyEvent
		jmp	Pkinput02

Pkinput01:
		cmp	ActiveEvent, 0
		jz	Pkinput02

		push	DWORD PTR [esp + 8]
		call	GenerateMouseEvent
		mov	DWORD PTR [edx], 1

Pkinput02:
		mov	eax, 1
		retn	16

PeekConsoleInputA ENDP

;+----------------------------------------------------------------------------
; Win32 - ReadConsoleInputA
;
			PUBLICDLL		ReadConsoleInputA

ReadConsoleInputA PROC NEAR
		mov	edx, [esp+16]

@@rciDoAgain:
		mov	ah, 1
		int	16h
		jz	@@rciDoMouse

		sub	ah, ah
		int	16h
		push	dword ptr [esp+8]
		push	eax
		call	GenerateKeyEvent
		jmp	@@rciDone

@@rciDoMouse:
		call	UpdateMouse
		cmp	ActiveEvent, 0
		jz	@@rciDoAgain

		push	dword ptr [esp+8]
		call	GenerateMouseEvent
		mov	ActiveEvent, 0

@@rciDone:
		mov	eax, 1
		mov	[edx], eax
		retn	16
ReadConsoleInputA ENDP

;ReadConsoleOutputA:

;ReadConsoleOutputAttribute:

;ReadConsoleOutputCharacterA:

;+---------------------------------------------------------------------------
; Win32 - ScrollConsoleScreenBufferA
;
		PUBLICDLL	ScrollConsoleScreenBufferA

ScrollConsoleScreenBufferA PROC NEAR
		pushad
		mov	ebp, esp
		mov	ax, 2
		int	33h
;
; Get the real source rectangle after clipping it to the screen buffer and
; to a possibly supplied clipping rectangle.
;
		push	DWORD PTR ScreenbufferInfo.dwMaximumWindowSize
		sub	DWORD PTR [esp], 10001h
		push	0			;
		mov	eax, esp
		push	esp			; -> src1 = -> result
		push	DWORD PTR [ebp+ 32+ 8]	; -> src2
		push	eax			; -> result
		call	clipRectangle
		add	esp, 12
		test	eax, eax
		jz	@@scsbExit

		cmp	DWORD PTR [ebp+ 32+12], 0
		je	@@scsbClipDone

		mov	eax, esp
		push	esp
		push	DWORD PTR [ebp+ 32+12]
		push	eax
		call	clipRectangle
		add	esp, 12
		test	eax, eax
		jz	@@scsbExit
;
; [esp]     : src start
; [esp + 4] : src end
;
@@scsbClipDone:
;
; Now do the same with the dest rectangle. First, calculate what the dest
; rectangle would be.
;
		push	eax
		push	eax
		mov	ebx, esp		; -> dest
		push	DWORD PTR ScreenbufferInfo.dwMaximumWindowSize
		sub	DWORD PTR [esp], 10001h
		push	0
		mov	ecx, esp
		mov	ax, [esp + 6]
		sub	ax, [esp + 2]
		add	ax, [ebp + 32 + 16 + 2]
		shl	eax, 16
		mov	ax, [esp + 4]
		sub	ax, [esp]
		add	ax, [ebp + 32 + 16]
		push	eax			; src1 end
		push	DWORD PTR [ebp+ 32+ 16] ; src1 start
		push	esp			; -> src1
		push	ecx			; -> src2
		push	ebx			; -> dest
		call	clipRectangle
		add	esp, 28
		test	eax, eax
		jz	@@scsbExit

		cmp	DWORD PTR [ebp+ 32+12], 0
		je	@@scsbDoCopy

		mov	eax, esp
		push	esp
		push	DWORD PTR [ebp+ 32+12]
		push	eax
		call	clipRectangle
		add	esp, 12
		test	eax, eax
		jz	@@scsbExit
;
; [esp]     : dest start
; [esp + 4] : dest end
; [esp + 8] : src start
; [esp +12] : src end
;
@@scsbDoCopy:
		call	GetScreenPtr
;
; Get screenbuffer pointers to src and dest. If the origin of dest has been
; clipped off, we need add that difference to src.
;
		movzx	esi, WORD PTR [esp + 10]
		imul	si, ScreenBufferInfo.dwMaximumWindowSize.X
		add	si, [esp + 8]
		movzx	edi, WORD PTR [esp + 2]
		imul	di, ScreenBufferInfo.dwMaximumWindowSize.X
		add	di, [esp]
		movsx	ecx, WORD PTR [ebp + 32 + 16 + 2]
		movzx	ebx, ScreenBufferInfo.dwMaximumWindowSize.X
		imul	ecx, ebx
		movsx	ebx, WORD PTR [ebp + 32 + 16]
		add	ecx, ebx
		sub	esi, ecx
		add	esi, edi
;
; Get screenbuffer pointers to end dest
;
		movzx	edx, WORD PTR [esp + 6]
		imul	dx, ScreenBufferInfo.dwMaximumWindowSize.X
		add	dx, [esp + 4]

		lea	esi, [esi * 2 + eax]
		lea	edi, [edi * 2 + eax]
		lea	edx, [edx * 2 + eax]
;
; Get loop counters
;
		mov	ch, [esp + 6]
		sub	ch, [esp + 2]
		mov	cl, [esp + 4]
		sub	cl, [esp]
		add	cx, 0101h
;
; ch = outer loop counter
; cl = inner loop counter
;
; Load filler word into bx
;
		mov	eax, [ebp + 32 + 20]
		mov	bl, [eax]
		mov	bh, [eax + 2]
;
; Calculate the gap size and store it on the stack
;
		movzx	eax, ScreenBufferInfo.dwMaximumWindowSize.X
		sub	al, cl
		add	eax, eax
		push	eax
;
; If the start of the source rectangle is before dest, we need to copy
; backwards.
;
		cmp	esi, edi
		jc	@@scsbBackwards

@@scsbOutF:
		push	ecx

@@scsbInF:
		mov	ax, [esi]
		cmp	esi, edx
		jna	@@noFillF

		mov	[esi], bx

@@noFillF:
		add	esi, 2
		mov	[edi], ax
		add	edi, 2
		dec	cl
		jnz	@@scsbInF

		pop	ecx
		add	esi, [esp]
		add	edi, [esp]
		dec	ch
		jnz	@@scsbOutF

		jmp	@@scsbExit

@@scsbBackwards:
;
; Adjust filler stop and start addresses
;
		lea	esi, [esi + edx - 2]
		xchg	edi, edx
		lea	edi, [edi + edx - 2]

@@scsbOutB:
		push	ecx

@@scsbInB:
		mov	ax, [esi]
		cmp	esi, edx
		jnc	@@noFillB

		mov	[esi], bx

@@noFillB:
		sub	esi, 2
		mov	[edi], ax
		sub	edi, 2
		dec	cl
		jnz	@@scsbInB

		pop	ecx
		sub	esi, [esp]
		sub	edi, [esp]
		dec	ch
		jnz	@@scsbOutB

@@scsbExit:
		mov	esp, ebp
		mov	ax, 1
		int	33h
		popad
		mov	eax, 1
		retn	20
ScrollConsoleScreenBufferA ENDP


;SetConsoleCP:

;+----------------------------------------------------------------------------
; Win32 - SetConsoleCursorInfo
;
		PUBLICDLL	SetConsoleCursorInfo

SetConsoleCursorInfo PROC NEAR
		mov	edx, [esp + 8]
		movzx	eax, bdaVideoCharHeight
		mul	DWORD PTR [edx]
		cdq
		mov	ecx, 100
		div	ecx
		cmp	edx, 50
		sbb	eax, -1
		cmp	eax, 1
		adc	eax, 0
		mov	cx, bdaVideoCharHeight
		mov	ch, cl
		dec	ecx
		sub	ch, al
		mov	edx, [esp + 8]
		cmp	DWORD PTR [edx + 4], 0		; visible?
		jne	@@shapeOk

		mov	cx, 100h

@@shapeOk:
;
; BIOS bug workaround
;
		push	ebx
		mov	ah, 0Fh
		int	10h
		pop	ebx
;
; Do it now
;
		mov	ah, 1
		int	10h
		call	UpdateStrucs
		mov	eax, 1
		retn	8
SetConsoleCursorInfo ENDP

;+----------------------------------------------------------------------------
; Win32 - SetConsoleCursorPosition
;
			PUBLICDLL		SetConsoleCursorPosition

SetConsoleCursorPosition PROC NEAR
		push	ebx
		mov	ah, 0Fh
		int	10h
		mov	edx, [esp+12]
		mov	eax, edx
		shr	eax, 8
		mov	dh, ah
		mov	ah, 2
		int	10h
		mov	eax, 1
		pop	ebx
		call	UpdateStrucs
		retn	8
SetConsoleCursorPosition ENDP

;+----------------------------------------------------------------------------
; Win32 - SetConsoleMode
;
		PUBLICDLL	SetConsoleMode

SetConsoleMode PROC NEAR
		HANDLE_W2D <DWORD PTR [esp + 4]>
		mov	eax, [esp+8]
		cmp	DWORD PTR [esp+4], hStdout
		jne	@@scmin

		mov	ConsoleOutputMode, eax
		jmp	@@scmdone

@@scmin:
		mov	edx, ConsoleInputMode
		mov	ConsoleInputMode, eax
		cmp	consoleMouseButtons, 0
		jz	@@scmdone

		and	edx, ENABLE_MOUSE_INPUT
		and	eax, ENABLE_MOUSE_INPUT
		cmp	eax, edx
		je	@@scmdone

		mov	ActiveEvent, 0
		mov	MoveFlag, 0

		test	eax, eax
		jz	@@scmHideMous

		push	ebx
		sub	ax, ax
		int	33h
		mov	ax, 3
		int	33h
		shr	cx, 3
		shr	dx, 3
		mov	MouseX, cx
		mov	MouseY, dx
		and	bx, 3
		mov	MouseButtons, bx
		mov	ax, 1
		int	33h
		pop	ebx
		jmp	@@scmdone

@@scmHideMous:
		push	ebx
		sub	ax, ax
		int	33h
		pop	ebx

@@scmdone:
		mov	eax, 1
		retn	8
SetConsoleMode ENDP


;SetConsoleOutputCP:

;+----------------------------------------------------------------------------
; Win32 - SetConsoleScreenBufferSize
;
			PUBLICDLL		SetConsoleScreenBufferSize

SetConsoleScreenBufferSize PROC NEAR

		cmp	dword ptr [esp+8], 1C0050h
		jnz	short scsbs000

		mov	eax, 83h
		int	10h
		push	ebx
		mov	eax, 1111h
		sub	ebx, ebx
		int	10h
		pop	ebx
		mov	eax, 1
		retn	8

scsbs000:
		cmp	dword ptr [esp+8], 320028h
		jnz	short scsbs001

		mov	eax, 81h
		int	10h
		push	ebx
		mov	eax, 1112h
		sub	ebx, ebx
		int	10h
		pop	ebx
		mov	eax, 1
		retn	8

scsbs001:
		cmp	dword ptr [esp+8], 1C0028h
		jnz	short scsbs002

		mov	eax, 81h
		int	10h
		push	ebx
		mov	eax, 1111h
		sub	ebx, ebx
		int	10h
		pop	ebx
		mov	eax, 1
		retn	8

scsbs002:
		cmp	dword ptr [esp+8], 190050h
		jnz	short scsbs00

		mov	eax, 83h
		int	10h
		mov	eax, 1
		retn	8

scsbs00:
		cmp	dword ptr [esp+8], 190028h
		jnz	short scsbs01

		mov	eax, 81h
		int	10h
		mov	eax, 1
		retn	8

scsbs01:
		cmp	dword ptr [esp+8], 2B0050h
		jnz	short scsbs02

scsbs03:
		mov	eax, 83h
		int	10h
		push	ebx
		mov	eax, 1112h
		sub	ebx, ebx
		int	10h
		pop	ebx
		mov	eax, 1
		retn	8

scsbs02:
		cmp	dword ptr [esp+8], 320050h
		jz	short scsbs03

		sub	eax, eax
		retn	8

SetConsoleScreenBufferSize ENDP

comment &

SetConsoleTextAttribute:
		mov	eax,[esp+8]
		mov	console_attr,eax
		retn	8
;SetConsoleTitleA:

&

;+----------------------------------------------------------------------------
; Win32 - SetConsoleWindowInfo
;
		PUBLICDLL	SetConsoleWindowInfo

SetConsoleWindowInfo PROC NEAR
		mov	edx, [esp + 12] 		; pSMALL_RECT
		cmp	dword ptr [esp + 8], 0		; FAsolute
		jz	short scwi00

		mov	eax, [edx]
		mov	DWORD PTR ScreenBufferInfo.srWindow ,eax
		mov	eax, [edx + 4]
		mov	DWORD PTR ScreenBufferInfo.srWindow[4] ,eax
		mov	eax, 1
		retn	12

scwi00:
		mov	eax, [edx]
		add	ax, ScreenBufferInfo.srWindow.left
		ror	eax, 16
		add	ax, ScreenBufferInfo.srWindow.top
		ror	eax, 16
		mov	DWORD PTR ScreenBufferInfo.srWindow ,eax
		mov	eax, [edx + 4]
		add	ax, ScreenBufferInfo.srWindow.right
		ror	eax, 16
		add	ax, ScreenBufferInfo.srWindow.bottom
		ror	eax, 16
		mov	DWORD PTR ScreenBufferInfo.srWindow[4] ,eax
		mov	eax, 1
		retn	12
SetConsoleWindowInfo ENDP

;ShowConsoleCursor:

;+----------------------------------------------------------------------------
; Win32 - Sleep (Not really a console function but what the...)
;
;
		PUBLICDLL	Sleep

Sleep PROC NEAR
		mov	edx, [esp + 4]
		shld	ecx, edx, 26
		shl	edx, 10
		jz	@@sRelTimeSlice

		mov	ah, 86h
		int	15h
		retn	4

@@sRelTimeSlice:
		mov	ax, 1680h
		int	2Fh
		retn	4
Sleep ENDP

;WaitForMultipleObjects:

;+----------------------------------------------------------------------------
; Win32 - WaitForSingleObject (only CONIN$ supported)
;
		PUBLICDLL	WaitForSingleObject

WaitForSingleObject PROC NEAR
		mov	eax, [esp + 8]
		sub	edx, edx
		add	eax, 17
		mov	ecx, 18
		div	ecx
		add	eax, ds:[46Ch]
		shl	eax, 14

		cmp	DWORD PTR [esp + 4], 12345678h
		je	@@wfsoDone

		HANDLE_W2D <DWORD PTR [esp + 4]>
@@wfsoLoop:
		cmp	DWORD PTR [esp + 4], 0
		jnz	@@wfsoChkTime

		push	eax
		push	edx
		push	esp
		push	0
		HANDLE_D2W <DWORD PTR [esp]>
		call	GetNumberOfCOnsoleInputEvents
		pop	edx
		pop	eax
		test	edx, edx
		jz	@@wfsoChkTime

@@wfsoDone:
		sub	eax, eax
		retn	8

@@wfsoChkTime:
		mov	ecx, ds:[46Ch]
		shl	ecx, 14
		cmp	ecx, eax
		js	@@wfsoLoop

		mov	eax, 102h			; STATUS_TIMEOUT
		retn	8
WaitForSingleObject ENDP

;+----------------------------------------------------------------------------
; Win32 - WriteConsoleA
;
		EXTRN		WriteFile: NEAR
		PUBLICDLL	WriteConsoleA
WriteConsoleA LABEL NEAR
		jmp	WriteFile

;+----------------------------------------------------------------------------
; Win32 - ReadConsoleA
;
		EXTRN		ReadFile: NEAR
		PUBLICDLL	ReadConsoleA
ReadConsoleA LABEL NEAR
		jmp	ReadFile


;WriteConsoleInputA:

;+----------------------------------------------------------------------------
; Win32 - WriteConsoleOutputA
;
		PUBLICDLL	WriteConsoleOutputA

WriteConsoleOutputA PROC NEAR
		HANDLE_W2D <DWORD PTR [esp + 4]>
		mov	ax, 2
		int	33h
		sub	eax, eax
		cmp	DWORD PTR [esp + 4], hStdout
		jne	@@wcaexit
;
; clip destination rectangle to screen buffer size
;
		push	DWORD PTR ScreenbufferInfo.dwMaximumWindowSize
		sub	DWORD PTR [esp], 10001h
		push	0
;
; data for src1 + address for src1
;
		push	esp
;
; address for src2 = dest
;
		push	DWORD PTR [esp + 20 + 12]
		push	DWORD PTR [esp + 20 + 16]
		call	clipRectangle
		add	esp, 20
;
; No intersection -> nothing to do
;
		xor	eax, 1
		jnz	@@wcaexit
;
; Now clip the source rectangle into dest
;
		mov	eax, [esp + 12] 	; size
		sub	eax, 10001h
		mov	ecx, [esp + 16] 	; start
		mov	edx, [esp + 20] 	; dest
		mov	edx, [edx]		; start dest
;
; Create a rectangle from that
;
		sub	ax, cx
		add	ax, dx
		rol	eax, 16
		rol	ecx, 16
		rol	edx, 16
		sub	ax, cx
		add	ax, dx
		rol	eax, 16
		rol	edx, 16
		push	eax			; end
		push	edx			; start
		push	esp			; address of src rect.
		push	DWORD PTR [esp + 20 + 12]
		push	DWORD PTR [esp + 20 + 16]
		call	clipRectangle
		add	esp, 20
;
; No intersection -> nothing to do (highly unlikely)
;
		xor	eax, 1
		jnz	@@wcaexit
;
; Eventually we have calculated our safe drawing region
;
		pushad
;
; Calculate row increments for src and dest
;
		mov	ecx, [esp + 32 + 20]		; *src
		movzx	ebx, WORD PTR [ecx + 4] 	; right
		sub	bx, WORD PTR [ecx]		; - left
		inc	ebx				; # chars X
;
; #Colums in EBX
;
		movzx	edx, WORD PTR [esp + 32 + 12]	; EDX = src row size
		sub	edx, ebx			; EDX = src row inc
		shl	edx, 2
;
; edx = source inc
;
		movzx	esi, WORD PTR ScreenBufferInfo.dwMaximumWindowSize
							; ESI = dest row size
		sub	esi, ebx			; ESI = dest row inc
		add	esi, esi
;
; Now desperately try to figure out the number of rows we have to draw.
;
		mov	ebp, [esp + 32 + 20]		; get dest. rect. *
		movzx	edi, WORD PTR [ebp  + 6]	; Thank you Bill for
		sub	di, [ebp + 2]			; that 16 bits rubbish!
		inc	edi
;
; EDI now contains the number of rows we'll print. Finally, we still need to
; know where TF to draw, in the first place.
;
		movzx	eax, WORD PTR [ebp + 2] ; dest. top
		imul	ax, WORD PTR ScreenBufferInfo.dwMaximumWindowSize
		add	ax, [ebp]			; dest x
		add	eax, eax			; char + attrib
		push	eax
		call	getScreenPtr
		pop	ebp
		add	ebp, eax
;
; EBP now points to where we want to spam our stuff into. Try to write some
; code to get the source offset.
;
		movzx	eax, WORD PTR [esp + 32 + 18]	; get source start Y
		mov	ecx, [esp + 32 + 12]		; get source sz *
		imul	ax, WORD PTR [ecx]		; get source buf addx
		shl	eax, 2				; Billy adjust
		add	eax, [esp + 32 + 8]		; eax -> src
;
; You must be very sick if you're really trying to understand that code. Go out
; and have some beer instead!
;
@@wcaOuterLoop:
		push	ebx

@@wcaInnerLoop:
		mov	cl, [eax]
		mov	ch, [eax + 2]
		add	eax, 4
		mov	[ebp], cx
		add	ebp, 2
		dec	ebx
		jnz	@@wcaInnerLoop

		pop	ebx
		lea	eax, [eax + edx]	    ; inc src
		lea	ebp, [ebp + esi]	    ; inc dest
		dec	edi
		jnz	@@wcaOuterLoop

		popad

@@wcaexit:
		push	eax
		mov	ax, 1
		int	33h
		pop	eax
		retn	20
WriteConsoleOutputA ENDP

;WriteConsoleOutputAttribute:

;WriteConsoleOutputCharacterA:

;+----------------------------------------------------------------------------
; Win32 - GetConsoleScreenBufferInfo
;
; We don't check for the handle and return true in any case.
;
		PUBLICDLL	GetConsoleScreenBufferInfo

GetConsoleScreenBufferInfo  PROC NEAR
		call	UpdateStrucs
		mov	edx, [esp + 8]
		sub	ecx, ecx

@@getBufInfoLoop:
		mov	al, [ecx + OFFSET ScreenBufferInfo]
		inc	ecx
		mov	[edx], al
		inc	edx
		cmp	ecx, size CONSOLE_SCREEN_BUFFER_INFO
		jc	@@getBufInfoLoop

		mov	eax, 1
		retn	8
GetConsoleScreenBufferInfo  ENDP

;+---------------------------------------------------------------------------
; Win32 - GetLargestConsoleWindowSize
;
		PUBLICDLL	GetLargestConsoleWindowSize

GetLargestConsoleWindowSize PROC NEAR
		mov	eax, 320050h		; return 80 x 50
		retn	4
GetLargestConsoleWindowSize ENDP


;-----------------------------------------------------------------------------
; UpdateStrucs
;
; Purpose: Update ScreenBufferInfo and CursorInfo with the actual BIOS values.
;
UpdateStrucs PROC NEAR
		pushad
;
; Update buffer size and maximum window size
;
		movzx	eax, bdaVideoRowsMinusOne
		inc	eax
		shl	eax, 16
		mov	ax, bdaVideoColums
		mov	DWORD PTR ScreenBufferInfo.dwSize, eax
		mov	DWORD PTR ScreenBufferInfo.dwMaximumWindowSize, eax
;
; Update cursor position
;
		movzx	eax, bdaVideoCurrentPage
		movzx	eax, bdaCursorPositions[eax + eax]
		shl	eax, 8
		shr	ax, 8
		mov	DWORD PTR ScreenBufferInfo.dwCursorPosition, eax
;
; Update cursor size and visibility
;
		mov	CursorInfo.bVisible, 0
		sub	eax, eax
		cmp	bdaVideoCharHeight, 0
		je	@@us01

		movzx	eax, bdaCursorType
		sub	al, ah
		setna	BYTE PTR CursorInfo.bVisible
		sub	ah, ah
		inc	ax
		mov	dx, 100
		mul	dx
		div	bdaVideoCharHeight

@@us01:
		mov	CursorInfo.dwCursorSize, eax
		popad
		ret
UpdateStrucs ENDP

;+---------------------------------------------------------------------------
; initConsole - set up structures etc.
;
; Purpose: To be called on program entry and evertime a new screen mode has
;	   been set.
;
initConsole PROC NEAR
		call	UpdateStrucs
		mov	ScreenBufferInfo.wAttributes, 7
		mov	DWORD PTR ScreenBufferInfo.srWindow, 0
		push	eax
		push	ebx
		mov	ax, ScreenBufferInfo.dwMaximumWindowSize.X
		dec	ax
		mov	ScreenBufferInfo.srWindow.Right, ax
		mov	ax, ScreenBufferInfo.dwMaximumWindowSize.Y
		dec	ax
		mov	ScreenBufferInfo.srWindow.Bottom, ax
		sub	eax, eax
		int	33h
		inc	ax
		sete	BYTE PTR consoleMouseButtons
		pop	ebx
		pop	eax
		ret
initConsole ENDP

;+----------------------------------------------------------------------------
; BOOL _cdecl clipRectangle(pSmall_Rect dest, src1, src2)
;
; Returns true if there is an intersection area
;
clipRectangle PROC NEAR
		sub	eax, eax		; assume no intersection
		pushad
		mov	esi, [esp + 32 + 8]	; fetch src1
		mov	edi, [esp + 32 + 12]	; fetch src2
		mov	ebp, [esp + 32 + 4]	; fetch dest
		mov	ax, [esi].SMALL_RECT.left
		mov	bx, [edi].SMALL_RECT.left
		cmp	ax, bx
		jge	@@setLeft

		mov	ax, bx

@@setLeft:
		mov	[ebp].SMALL_RECT.left, ax

		mov	ax, [esi].SMALL_RECT.top
		mov	bx, [edi].SMALL_RECT.top
		cmp	ax, bx
		jge	@@setTop

		mov	ax, bx

@@setTop:
		mov	[ebp].SMALL_RECT.top, ax

		mov	ax, [esi].SMALL_RECT.right
		mov	bx, [edi].SMALL_RECT.right
		cmp	ax, bx
		jng	@@setRight

		mov	ax, bx

@@setRight:
		mov	[ebp].SMALL_RECT.right, ax

		mov	ax, [esi].SMALL_RECT.bottom
		mov	bx, [edi].SMALL_RECT.bottom
		cmp	ax, bx
		jng	@@setBottom

		mov	ax, bx

@@setBottom:
		mov	[ebp].SMALL_RECT.bottom, ax
		cmp	ax, [ebp].SMALL_RECT.top
		jnge	@@clipDone

		mov	ax, [ebp].SMALL_RECT.right
		cmp	ax, [ebp].SMALL_RECT.left
		setge	BYTE PTR [esp + 28]

@@clipDone:
		popad
		retn
clipRectangle ENDP

;-----------------------------------------------------------------------------
; This is not really necessary, but...
;
GetScreenPtr PROC NEAR
		push	edx
		mov	dx, 3CCh
		in	al, dx
		test	al, 1
		mov	eax, 0B0000h
		jz	@@askBdaForOffset

		mov	ah, 80h

@@askBdaForOffset:
		add	ax, bdaVideoCurrentOffset
		pop	edx
		retn
GetScreenPtr ENDP

;----------------------------------------------------------------------------
; GenerateMouseEvent
;
GenerateMouseEvent PROC NEAR			; STDCALL
		mov	eax, [esp + 4]
		mov	[eax].KEY_EVENT_RECORD.wEventType, 2
		add	eax, 4
		mov	ecx, DWORD PTR [OFFSET MouseX]
		mov	DWORD PTR [eax].MOUSE_EVENT_RECORD.dwMousePosition, ecx
		movzx	ecx, CtrlKeys
		mov	[eax].MOUSE_EVENT_RECORD.dwKbControlkeyState, ecx
		mov	cl, MoveFlag
		mov	[eax].MOUSE_EVENT_RECORD.dwEventFlags, ecx
		mov	cx, MouseButtons
		mov	[eax].MOUSE_EVENT_RECORD.dwButtonState, ecx
		retn	4
GenerateMouseEvent ENDP

;----------------------------------------------------------------------------
; UpdateMouse
;
; Does nothing if mouse event alreaydy pending, mouse input not enabled or
; no mouse present.
;
UpdateMouse PROC NEAR
		cmp	ActiveEvent, 0
		jnz	@@umDone

		cmp	consoleMouseButtons, 0
		jz	@@umDone

		test	consoleInputMode, ENABLE_MOUSE_INPUT
		jz	@@umDone

		pushad
		mov	ax, 3
		int	33h
		and	bx, 3
		shr	cx, 3
		shr	dx, 3
		mov	MoveFlag, 1
		cmp	cx, MouseX
		jne	@@mouseMoved

		cmp	dx, MouseY
		jne	@@mouseMoved

		cmp	bx, MouseButtons
		je	@@noMouseEvent

		mov	MoveFlag, 0

@@mouseMoved:
		mov	MouseX, cx
		mov	MouseY, dx
		mov	MouseButtons, bx
		mov	ActiveEvent, 1
		call	GetCtrlKeyState
		mov	CtrlKeys, al

@@NoMouseEvent:
		popad

@@umDone:
		retn
UpdateMouse ENDP

.data
		align	DWORD

consoleInputMode	dd	ENABLE_LINE_INPUT + \
				ENABLE_ECHO_INPUT + \
				ENABLE_PROCESSED_INPUT
;				ENABLE_MOUSE_INPUT

consoleOutputMode	dd	ENABLE_PROCESSED_OUTPUT + \
				ENABLE_WRAP_AT_EOL_OUTPUT

consoleMouseButtons	dd	0

;
; Translation for 0 < al < 20h "0" means -> VK_NADA
;
CntrlXTbl LABEL BYTE
		db	0,  30, 48, 46, 32, 18, 33, 34
		db	35, 23, 36, 37, 38, 50, 49, 24
		db	25, 16, 19, 31, 20, 22, 47, 17
		db	45, 21, 44, 0,	0,  0,	0,  0
;
; Translation table for al = 0
;
VkXTbl LABEL WORD
		dw	2 dup (0)

		db	57, ALT 		; 2

		dw	0

		db	82, CTRL		; 4
		db	83, SHIFT		; 5
		db	83, CTRL		; 6
		db	84, SHIFT		; 7
		db	14, ALT 		; 8

		dw	(10h - 08h - 1) dup (0)

		db	16, ALT 		; 10h
		db	17, ALT 		; 11h
		db	18, ALT 		; 12h
		db	19, ALT 		; 13h
		db	20, ALT 		; 14h
		db	21, ALT 		; 15h
		db	22, ALT 		; 16h
		db	23, ALT 		; 17h
		db	24, ALT 		; 18h
		db	25, ALT 		; 19h

		dw	(1Eh - 19h - 1) dup (0)

		db	30, ALT 		; 1Eh
		db	31, ALT 		; 1Fh
		db	32, ALT 		; 20h
		db	33, ALT 		; 21h
		db	34, ALT 		; 22h
		db	35, ALT 		; 23h
		db	36, ALT 		; 24h
		db	37, ALT 		; 25h
		db	38, ALT 		; 26h

		dw	(2Ch - 26h - 1) dup (0)

		db	44, ALT 		; 2Ch
		db	45, ALT 		; 2Dh
		db	46, ALT 		; 2Eh
		db	47, ALT 		; 2Fh
		db	48, ALT 		; 30h
		db	49, ALT 		; 31h
		db	50, ALT 		; 32h

		dw	(54h - 32h - 1) dup (0)

		db	59, SHIFT		; 54h
		db	60, SHIFT		; 55h
		db	61, SHIFT		; 56h
		db	62, SHIFT		; 57h
		db	63, SHIFT		; 58h
		db	64, SHIFT		; 59h
		db	65, SHIFT		; 5Ah
		db	66, SHIFT		; 5Bh
		db	67, SHIFT		; 5Ch
		db	68, SHIFT		; 5Dh
		db	59, CTRL		; 5Eh
		db	60, CTRL		; 5Fh
		db	61, CTRL		; 60h
		db	62, CTRL		; 61h
		db	63, CTRL		; 62h
		db	64, CTRL		; 63h
		db	65, CTRL		; 64h
		db	66, CTRL		; 65h
		db	67, CTRL		; 66h
		db	68, CTRL		; 67h
		db	59, ALT 		; 68h
		db	60, ALT 		; 69h
		db	61, ALT 		; 6Ah
		db	62, ALT 		; 6Bh
		db	63, ALT 		; 6Ch
		db	64, ALT 		; 6Dh
		db	65, ALT 		; 6Eh
		db	66, ALT 		; 6Fh
		db	67, ALT 		; 70h
		db	68, ALT 		; 71h

		dw	0

		db	75, CTRL		; 73h
		db	77, CTRL		; 74h
		db	79, CTRL		; 75h
		db	81, CTRL		; 76h
		db	71, CTRL		; 77h
		db	 2, ALT 		; 78h
		db	 3, ALT 		; 79h
		db	 4, ALT 		; 7Ah
		db	 5, ALT 		; 7Bh
		db	 6, ALT 		; 7Ch
		db	 7, ALT 		; 7Dh
		db	 8, ALT 		; 7Eh
		db	 9, ALT 		; 7Fh
		db	10, ALT 		; 80h
		db	11, ALT 		; 81h
		db	12, ALT 		; 82h
		db	13, ALT 		; 83h
		db	73, CTRL		; 84h

		dw	2 DUP (0)

		db	87, SHIFT		; 87h
		db	88, SHIFT		; 88h
		db	87, CTRL		; 89h
		db	88, CTRL		; 8Ah
		db	87, ALT 		; 8Bh
		db	88, ALT 		; 8Ch

VkATbl LABEL WORD
		db	0, 0
		db	65, CTRL
		db	66, CTRL
		db	67, CTRL
		db	68, CTRL
		db	69, CTRL
		db	70, CTRL
		db	71, CTRL
		db	72, CTRL
		db	73, CTRL
		db	74, CTRL
		db	75, CTRL
		db	76, CTRL
		db	77, CTRL
		db	78, CTRL
		db	79, CTRL
		db	80, CTRL
		db	81, CTRL
		db	82, CTRL
		db	83, CTRL
		db	84, CTRL
		db	85, CTRL
		db	86, CTRL
		db	87, CTRL
		db	88, CTRL
		db	89, CTRL
		db	90, CTRL
		db	219, CTRL
		db	220, CTRL
		db	221, CTRL
		db	54, CTRL
		db	189, CTRL
		db	32, 0
		db	49, SHIFT
		db	222, SHIFT
		db	51, SHIFT
		db	52, SHIFT
		db	53, SHIFT
		db	55, SHIFT
		db	222, 0
		db	57, SHIFT
		db	48, SHIFT
		db	74, 0
		db	187, SHIFT
		db	188, 0
		db	189, 0
		db	190, 0
		db	191, 0
		db	96, 0
		db	65, 0
		db	66, 0
		db	67, 0
		db	68, 0
		db	69, 0
		db	70, 0
		db	71, 0
		db	72, 0
		db	73, 0
		db	186, SHIFT
		db	186, 0
		db	188, SHIFT
		db	187, 0
		db	190, SHIFT
		db	191, SHIFT
		db	50, SHIFT
		db	65, SHIFT
		db	66, SHIFT
		db	67, SHIFT
		db	68, SHIFT
		db	69, SHIFT
		db	70, SHIFT
		db	71, SHIFT
		db	72, SHIFT
		db	73, SHIFT
		db	74, SHIFT
		db	75, SHIFT
		db	76, SHIFT
		db	77, SHIFT
		db	78, SHIFT
		db	79, SHIFT
		db	80, SHIFT
		db	81, SHIFT
		db	82, SHIFT
		db	83, SHIFT
		db	84, SHIFT
		db	85, SHIFT
		db	86, SHIFT
		db	87, SHIFT
		db	88, SHIFT
		db	89, SHIFT
		db	90, SHIFT
		db	219, 0
		db	220, 0
		db	221, 0
		db	54, SHIFT
		db	189, SHIFT
		db	192, 0
		db	65, 0
		db	66, 0
		db	67, 0
		db	68, 0
		db	69, 0
		db	70, 0
		db	71, 0
		db	72, 0
		db	73, 0
		db	74, 0
		db	75, 0
		db	76, 0
		db	77, 0
		db	78, 0
		db	79, 0
		db	80, 0
		db	81, 0
		db	82, 0
		db	83, 0
		db	84, 0
		db	85, 0
		db	86, 0
		db	87, 0
		db	88, 0
		db	89, 0
		db	90, 0
		db	219, SHIFT
		db	220, SHIFT
		db	221, SHIFT
		db	192, SHIFT
		db	8, CTRL

.data?
		align	DWORD

ScreenBufferInfo	CONSOLE_SCREEN_BUFFER_INFO <>
CursorInfo		CONSOLE_CURSOR_INFO <>
;
; Next vaiables are used in conjunction with the generation of mouse events
;
MouseX		dw	?
MouseY		dw	?
MouseButtons	dw	?
ActiveEvent	db	?
MoveFlag	db	?
CtrlKeys	db	?
	END
