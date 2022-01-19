; ############################################################################
; ## WDOSX DOS Extender 	  Copyright (c) 1996, 1999, Michael Tippach ##
; ##									    ##
; ## Released under the terms of the WDOSX license agreement.		    ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/win32/W32STRUC.INC 1.8 1999/06/20 18:52:40 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: W32STRUC.INC $
; Revision 1.8  1999/06/20 18:52:40  MikeT
; Appended the missing "h" to the definitions of MEM_PRIVATE, MEM_MAPPED and
; MEM_TOP_DOWN. Thanks to Tony Low for pointing that out.
;
; Revision 1.7	1999/03/21 15:42:16  MikeT
; Introduced two macros, HANDLE_W2D and HANDLE_D2W which translate file
; handles between both worlds.
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
; Revision 1.6	1999/02/07 21:08:53  MikeT
; Updated copyright.
;
; Revision 1.5	1998/11/01 18:38:11  MikeT
; Add bhfi structure declaration
;
; Revision 1.4	1998/08/15 20:57:06  MikeT
; +=Mouse event
;
; Revision 1.3	1998/08/08 15:36:17  MikeT
; Fix dwCursorSize
;
; Revision 1.2	1998/08/08 14:50:29  MikeT
; +CONSOLE_CURSOR_INFO
;
; Revision 1.1	1998/08/03 01:49:31  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## A collection of these Win32 structures and more			    ##
; ############################################################################

memorystatus	STRUC
		dwLength	dd ?	; sizeof(memorystatus)
		dwMemoryLoad	dd ?	; percent of memory in use
		dwTotalPhys	dd ?	; bytes of physical memory
		dwAvailPhys	dd ?	; free physical memory bytes
		dwTotalPageFile dd ?	; bytes of paging file
		dwAvailPageFile dd ?	; free bytes of paging file
		dwTotalVirtual	dd ?	; user bytes of address space
		dwAvailVirtual	dd ?	; free user bytes
memorystatus	ENDS

systime 	STRUC
		wYear		dw ?
		wMonth		dw ?
		wDayOfWeek	dw ?
		wDay		dw ?
		wHour		dw ?
		wMinute 	dw ?
		wSecond 	dw ?
		wMilliseconds	dw ?
systime 	ENDS

bhfi STRUC
		dwFileAttributes	dd ?
		ftCreationTime		dd 2 DUP (?)
		ftLastAccessTime	dd 2 DUP (?)
		ftLastWriteTime 	dd 2 DUP (?)
		dwVolumeSerialNumber	dd ?
		nFileSizeHigh		dd ?
		nFileSizeLow		dd ?
		nNumberOfLinks		dd ?
		nFileIndexHigh		dd ?
		nFileIndexLow		dd ?
bhfi ENDS

SIZEOF_BHFI EQU 13 * 4

time_zone_information	STRUC
		Bias		dd ?
		StandardName	db 32 dup (?)
		StandardDate	systime <>
		StandardBias	dd ?
		DaylightName	db 32 dup (?)
		DaylightDate	systime <>
		DaylightBias	dd ?
time_zone_information	ENDS

startupinfo	STRUC
		cb		dd ?
		lpReserved	dd ?
		lpDesktop	dd ?
		lpTitle 	dd ?
		dwX		dd ?
		dwY		dd ?
		dwXSize 	dd ?
		dwYSize 	dd ?
		dwXCountChars	dd ?
		dwYCountChars	dd ?
		dwFillAttribute dd ?
		dwFlags 	dd ?
		wShowWindow	dw ?
		cbReserved2	dw ?
		lpReserved2	dd ?
		hStdInput	dd ?
		hStdOutput	dd ?
		hStdError	dd ?
startupinfo	ENDS

vmemMBI 	STRUC

		BaseAddress		dd ?	; base address of region
		AllocationBase		dd ?	; allocation base address
		AllocationProtect	dd ?	; initial access protection
		RegionSize		dd ?	; size, in bytes, of region
		State			dd ?	; committed, reserved, free
		Protect 		dd ?	; current access protection
		PageType		dd ?	; type of pages

vmemMBI 	ENDS

mcb		STRUC
		mcb_next	dd ?	; pointer to next mcb,
					; 0 if last in chain
		mcb_desc	dd ?	;descriptor flags
mcb		ENDS

; descriptor flags

		mcb_free	EQU	1

CREATE_NEW			EQU	1
CREATE_ALWAYS			EQU	2
OPEN_EXISTING			EQU	3
OPEN_ALWAYS			EQU	4
TRUNCATE_EXISTING		EQU	5

; DOS file attributes

DOS_FA_NORMAL			EQU	0
DOS_FA_READONLY 		EQU	1
DOS_FA_HIDDEN			EQU	2
DOS_FA_SYSTEM			EQU	4
DOS_FA_VOLUME			EQU	8
DOS_FA_DIRECTORY		EQU	10h
DOS_FA_ARCHIVE			EQU	20h
DOS_FA_SHAREABLE		EQU	80h

; Win 32 file attributes that matter

FILE_ATTRIBUTE_READONLY 	EQU	1
FILE_ATTRIBUTE_HIDDEN		EQU	2
FILE_ATTRIBUTE_SYSTEM		EQU	4
FILE_ATTRIBUTE_DIRECTORY	EQU	10h
FILE_ATTRIBUTE_ARCHIVE		EQU	20h
FILE_ATTRIBUTE_NORMAL		EQU	80h

; ############################################################################
; ## Structured exception handling in win32 - mostly guesswork		    ##
; ############################################################################

; ############ Exception handler declaration #################################

; int EHandler(ExceptionRecord *pERec, ExceptionFrame *pEFrame,
;	       ContextRecord *pCntx, DispatchRecord *pDisp)
; RETURNS: 1 if exception has been handled, 0 if not

; FS:[0] ( TIB ) = pointer to topmost DispatchRecord, -1 if none


; ####### RETURN VALUE OF THE EXCEPTION HANDLER ##############################

XCPT_CONTINUE_EXECUTION 	EQU	0
XCPT_CONTINUE_SEARCH		EQU	1


; ####### EXCEPTION TYPES ####################################################

STATUS_BREAKPOINT		EQU	080000003h
STATUS_SINGLE_STEP		EQU	080000004h
STATUS_ACCESS_VIOLATION 	EQU	0C0000005h
STATUS_NO_MEMORY		EQU	0C0000017h
STATUS_ILLEGAL_INSTRUCTION	EQU	0C000001Dh
STATUS_NONCONTINUABLE_EXCEPTION EQU	0C0000025h
STATUS_ARRAY_BOUNDS_EXCEEDED	EQU	0C000008Ch
STATUS_INTEGER_DIVIDE_BY_ZERO	EQU	0C0000094h
STATUS_INTEGER_OVERFLOW 	EQU	0C0000095h
STATUS_PRIVILEGED_INSTRUCTION	EQU	0C0000096h
STATUS_STACK_OVERFLOW		EQU	0C00000FDh
STATUS_CONTROL_C_EXIT		EQU	0C000013Ah
STATUS_FLOAT_DENORMAL_OPERAND	EQU	0C000008Dh
STATUS_FLOAT_DIVIDE_BY_ZERO	EQU	0C000008Eh
STATUS_FLOAT_INEXACT_RESULT	EQU	0C000008Fh
STATUS_FLOAT_INVALID_OPERATION	EQU	0C0000090h
STATUS_FLOAT_OVERFLOW		EQU	0C0000091h
STATUS_FLOAT_STACK_CHECK	EQU	0C0000092h
STATUS_FLOAT_UNDERFLOW		EQU	0C0000093h
STATUS_INTEGER_DIVIDE_BY_ZERO	EQU	0C0000094h


; ####### context flags ######################################################

CONTEXT_X86			EQU	10000h
CONTEXT_CONTROL 		EQU	1
CONTEXT_INTEGER 		EQU	2
CONTEXT_SEGMENTS		EQU	4
CONTEXT_FPU			EQU	8
CONTEXT_DREGS			EQU	10h

; ####### X86 context record #################################################
; we don't return FPU and DR0-7 information

OUR_CNT EQU	CONTEXT_X86+CONTEXT_CONTROL+CONTEXT_INTEGER+CONTEXT_SEGMENTS

ContextRecord	STRUC
		ContextFlags	dd ?
		DRSpace 	dd 8 dup (?)	; not filled
		FPUSpace	dd 28 dup (?)	; not filled
		CntSegGs	dd ?
		CntSegFs	dd ?
		CntSegEs	dd ?
		CntSegDs	dd ?
		CntEdi		dd ?
		CntEsi		dd ?
		CntEbx		dd ?
		CntEdx		dd ?
		CntEcx		dd ?
		CntEax		dd ?
		CntEbp		dd ?
		CntEip		dd ?
		CntSegCs	dd ?
		CntEFlags	dd ?
		CntEsp		dd ?
		CntSegSs	dd ?
ContextRecord	ENDS



; ####### Exception flags ####################################################

CONTINUABLE			EQU	0
NOT_CONTINUABLE 		EQU	1
UNWINDING			EQU	2
UNWINDING_FOR_EXIT		EQU	4
UNWIND_IN_PROGRESS		EQU	6

; ####### End of chain marker ################################################

END_OF_CHAIN			EQU	-1

; ####### Data structures ####################################################

;
; Thread Information Block. Accessed through the FS: register. This appears
; to be heavily undocumented. Some more reverse engineering would be necessary
; to make this complete. (MSDN subscription, anyone?)
;
TIB		STRUC
		pFirstEx	dd ?	; Pointer to first Dispatch
					; Record or -1 if none.
		pStackBase	dd ?	; Pointer to a structure that
					; contains things like TOS
				dd 4 dup (?)
		pTEB		dd ?	; Pointer to Thread
					; Environment Block, a
					; structure that contains
					; <something>
					; (ThreadID at 24h amongst
					; others)
				dd 4 dup (?)
		pTlsArray	dd ?	; Pointer to 64 DWORD array
					; for Thread Local Storage,
					; same as accessed by
					; TlsGet(Set)Value
TIB		ENDS

DispatchRecord	STRUC
		pPrevious	dd ?	; DispatchRecord *pPrevious
		pEhandler	dd ?	; EHandler *pEhandler
DispatchRecord	ENDS

ExceptionRecord STRUC
		ExceptionCode	dd ?	; Number of Exception
		ExceptionFlags	dd ?
		pOuterException dd ?	; ExceptionRecord *pOuterException
		ExceptionAddress dd ?
		NumParams	dd ?	; Number of parameters following
		ExceptionInfo	label near
ExceptionRecord ENDS

; ##### this seems to be an overlay structure to DispatchRecord ##############

ExceptionFrame	STRUC
		pNextFrame	dd ?	; ExceptionFrame *pNextFrame
		pExceptionDesc	dd ?	; pointer to exception desc
		hEBP		dd ?
ExceptionFrame	ENDS


; RTLUnwind called with:

; pExceptionFrame,	( actually the same as dispatch record )
; ReturnAddress,	( where to go afterwards )
; pExceptionRecord,	( current ExceptionRecord )

; if pExceptionRecord is 0, then no handlers will be called, otherwise
; all handlers will be called until pExceptionFrame reached
; if pExceptionFrame is 0, all handlers will be unwound

;
; This structure keeps all necessary information for a PE image loaded.
;
WdlInfo 	STRUC
		FileName	db 262 dup (?)
		Flags		dw ?
		Handle		dd ?
		Count		dd ?
WdlInfo 	ENDS

WDL_INFO_SIZE			EQU	262 + 2 + 4 + 4

LOAD_LIBRARY_AS_DATAFILE	EQU	2
DLL_PROCESS_ATTACH		EQU	1
DLL_PROCESS_DETACH		EQU	0
DLL_THREAD_ATTACH		EQU	2
DLL_THREAD_DETACH		EQU	3

COORD		STRUC
		X			dw ?
		Y			dw ?
COORD		ENDS

SMALL_RECT	STRUC
		Left			dw ?
		Top			dw ?
		Right			dw ?
		Bottom			dw ?
SMALL_RECT	ENDS

CONSOLE_SCREEN_BUFFER_INFO STRUC
		dwSize			COORD <>
		dwCursorPosition	COORD <>
		wAttributes		dw ?
		srWindow		SMALL_RECT <>
		dwMaximumWindowSize	COORD <>
CONSOLE_SCREEN_BUFFER_INFO ENDS

CONSOLE_CURSOR_INFO STRUC
		dwCursorSize		dd	?
		bVisible		dd	?
CONSOLE_CURSOR_INFO ENDS

hStdout 			EQU	1

ENABLE_PROCESSED_INPUT		EQU	1
ENABLE_LINE_INPUT		EQU	2
ENABLE_ECHO_INPUT		EQU	4
ENABLE_WINDOW_INPUT		EQU	8
ENABLE_MOUSE_INPUT		EQU	10h

ENABLE_PROCESSED_OUTPUT 	EQU	1
ENABLE_WRAP_AT_EOL_OUTPUT	EQU	2



KEY_EVENT_RECORD	STRUC
			wEventType		dd ?
			bKeyDown		dd ?
			wRepeatCount		dw ?
			wVirtualKeyCode 	dw ?
			wVirtualScanCode	dw ?
			Character		dw ?
			dwControlKeyState	dd ?
KEY_EVENT_RECORD	ENDS

MOUSE_EVENT_RECORD	STRUC
			dwMousePosition 	COORD <>
			dwButtonState		dd ?
			dwKbControlKeyState	dd ?
			dwEventFlags		dd ?
MOUSE_EVENT_RECORD	ENDS

MOUSE_MOVED			EQU	1
DOUBLE_CLICK			EQU	2

RIGHT_ALT_PRESSED		EQU	1
LEFT_ALT_PRESSED		EQU	2
RIGHT_CTRL_PRESSED		EQU	4
LEFT_CTRL_PRESSED		EQU	8
SHIFT_PRESSED			EQU	10h
NUMLOCK_ON			EQU	20h
SCROLLLOCK_ON			EQU	40h
CAPSLOCK_ON			EQU	80h
ENHANCED_KEY			EQU	100h

PAGE_NOACCESS			EQU	1
PAGE_READONLY			EQU	2
PAGE_READWRITE			EQU	4
PAGE_WRITECOPY			EQU	8
PAGE_EXECUTE			EQU	16
PAGE_EXECUTE_READ		EQU	32
PAGE_EXECUTE_READWRITE		EQU	64
PAGE_EXECUTE_WRITECOPY		EQU	128
PAGE_GUARD			EQU	256
PAGE_NOCACHE			EQU	512

MEM_COMMIT			EQU	1000h
MEM_RESERVE			EQU	2000h
MEM_DECOMMIT			EQU	4000h
MEM_RELEASE			EQU	8000h
MEM_FREE			EQU	10000h
MEM_PRIVATE			EQU	20000h
MEM_MAPPED			EQU	40000h
MEM_TOP_DOWN			EQU	100000h

GMEM_INVALID_HANDLE		EQU	08000h

HANDLE_D2W MACRO op1
	inc	op1
ENDM

HANDLE_W2D MACRO op1
	dec	op1
ENDM
