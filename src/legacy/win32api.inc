; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/legacy/WIN32API.INC 1.2 1999/06/20 16:30:44 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: WIN32API.INC $
; Revision 1.2  1999/06/20 16:30:44  MikeT
; Fix build error when using newer TASM than 3.1.
;
; Revision 1.1  1999/02/07 18:15:53  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
;
; Old floating segment PE code which I'm too lazy to maintain any longer or to
; even comment on. It should stay as is and eventually die.
;


;-------------- Welcome to our Win32API --------------------------------------

;our kernel32.dll export table
;Export functions in alphabethic order+case sensitive, IOW 'A' < 'a'!
;BUT ALSO: 'B' < 'a' BUT NOT: 'B' < 'A'

k32dll		label	near

; In fact, also imports from other DLLs are listed here
; first  item = offset of emulation procedure
; second item = offset of a zero terminated string carrying the import name


	        dd	offset	AllocConsole
	        dd	offset	AllocConsole_s

		dd	offset	Beep
		dd	offset	Beep_s

		dd	offset	12345678h	; phantom function
		dd	offset	Borland32_s

		dd	offset	CloseHandle
		dd	offset	CloseHandle_s

		dd	offset	CompareStringA
		dd	offset	CompareStringA_s

	        dd	offset	CreateConsoleScreenBuffer
	        dd	offset	CreateConsoleScreenBuffer_s

		dd	offset	CreateDirectoryA
		dd	offset	CreateDirectoryA_s

		dd	offset	CreateFileA
		dd	offset	CreateFileA_s

		dd	offset	DeleteCriticalSection
		dd	offset	DeleteCriticalSection_s

		dd	offset	DeleteFileA
		dd	offset	DeleteFileA_s

		dd	offset	DosDateTimeToFileTime
		dd	offset	DosDateTimeToFileTime_s

		dd	offset	EnterCriticalSection
		dd	offset	EnterCriticalSection_s

		dd	offset	EnumCalendarInfoA
		dd	offset	EnumCalendarInfoA_s

		dd	offset	EnumThreadWindows
		dd	offset	EnumThreadWindows_s

		dd 	offset 	ExitProcess
		dd 	offset 	ExitProcess_s

		dd	offset	FileTimeToDosDateTime
		dd	offset	FileTimeToDosDateTime_s

		dd	offset	FileTimeToLocalFileTime
		dd	offset	FileTimeToLocalFileTime_s

		dd	offset	FileTimeToSystemTime
		dd	offset	FileTimeToSystemTime_s

	        dd	offset	FillConsoleOutputAttribute
	        dd	offset	FillConsoleOutputAttribute_s

	        dd	offset	FillConsoleOutputCharacterA
	        dd	offset	FillConsoleOutputCharacterA_s

		dd	offset	FindClose
		dd	offset	FindClose_s

		dd	offset	FindFirstFileA
		dd	offset	FindFirstFileA_s

		dd	offset	FindNextFileA
		dd	offset	FindNextFileA_s

		dd	offset	FlushConsoleInputBuffer
		dd	offset	FlushConsoleInputBuffer_s

		dd	offset	FormatMessageA
		dd	offset	FormatMessageA_s

		dd	offset	FreeConsole
		dd	offset	FreeConsole_s

		dd	offset	FreeLibrary
		dd	offset	FreeLibrary_s

		dd	offset	GetACP
		dd	offset	GetACP_s

		dd	offset	GetCommandLineA
		dd	offset	GetCommandLineA_s

		dd	offset	GetConsoleCP
		dd	offset	GetConsoleCP_s

		dd	offset	GetConsoleCursorInfo
		dd	offset	GetConsoleCursorInfo_s

		dd	offset	GetConsoleMode
		dd	offset	GetConsoleMode_s

		dd	offset	GetConsoleOutputCP
		dd	offset	GetConsoleOutputCP_s

		dd	offset	GetConsoleScreenBufferInfo
		dd	offset	GetConsoleScreenBufferInfo_s

		dd	offset	GetCPInfo
		dd	offset	GetCPInfo_s

		dd	offset	GetCurrentDirectoryA
		dd	offset	GetCurrentDirectoryA_s

		dd	offset	GetCurrentThreadId
		dd	offset	GetCurrentThreadId_s

		dd	offset	GetDateFormatA
		dd	offset	GetDateFormatA_s

		dd	offset	GetDriveTypeA
		dd	offset	GetDriveTypeA_s

		dd	offset	GetEnvironmentStrings
		dd	offset	GetEnvironmentStrings_s

		dd	offset	GetEnvironmentVariableA
		dd	offset	GetEnvironmentVariableA_s

		dd	offset	GetFileAttributesA
		dd	offset	GetFileAttributesA_s

		dd	offset	GetFileInformationByHandle
		dd	offset	GetFileInformationByHandle_s

		dd	offset	GetFileSize
		dd	offset	GetFileSize_s

		dd	offset	GetFileTime
		dd	offset	GetFileTime_s

		dd	offset	GetFileType
		dd	offset	GetFileType_s

		dd	offset	GetFullPathNameA
		dd	offset	GetFullPathNameA_s

		dd	offset	GetKeyboardType
		dd	offset	GetKeyboardType_s

		dd	offset	GetLargestConsoleWindowSize
		dd	offset	GetLargestConsoleWindowSize_s

		dd	offset	GetLastError
		dd	offset	GetLastError_s

		dd	offset	GetLocaleInfoA
		dd	offset	GetLocaleInfoA_s

		dd	offset	GetLocalTime
		dd	offset	GetLocalTime_s

		dd	offset	GetLogicalDrives
		dd	offset	GetLogicalDrives_s

		dd	offset	GetModuleHandleA
		dd	offset	GetModuleHandleA_s

		dd	offset	GetModuleFileNameA
		dd	offset	GetModuleFileNameA_s

		dd	offset	GetNumberOfConsoleInputEvents
		dd	offset	GetNumberOfConsoleInputEvents_s

		dd	offset	GetOEMCP
		dd	offset	GetOEMCP_s

		dd	offset	GetPrivateProfileStringA
		dd	offset	GetPrivateProfileStringA_s

		dd	offset	GetProcAddress
		dd	offset	GetProcAddress_s

		dd	offset	GetStartupInfoA
		dd	offset	GetStartupInfoA_s

		dd	offset	GetStdHandle
		dd	offset	GetStdHandle_s

		dd	offset	GetStringTypeW
		dd	offset	GetStringTypeW_s

		dd	offset	GetSystemDefaultLCID
		dd	offset	GetSystemDefaultLCID_s

		dd	offset	GetSystemMetrics
		dd	offset	GetSystemMetrics_s

		dd	offset	GetSystemTime
		dd	offset	GetSystemTime_s

		dd	offset	GetThreadLocale
		dd	offset	GetThreadLocale_s

		dd	offset	GetTimeZoneInformation
		dd	offset	GetTimeZoneInformation_s

		dd	offset	GetVersion
		dd	offset	GetVersion_s

		dd	offset	GetVersionExA
		dd	offset	GetVersionExA_s

		dd	offset	GetVersionExW
		dd	offset	GetVersionExW_s

		dd	offset	GetVolumeInformationA
		dd	offset	GetVolumeInformationA_s

		dd	offset	GlobalMemoryStatus
		dd	offset	GlobalMemoryStatus_s

		dd	offset	InitializeCriticalSection
		dd	offset	InitializeCriticalSection_s

		dd	offset	LeaveCriticalSection
		dd	offset	LeaveCriticalSection_s

		dd	offset	LoadStringA
		dd	offset	LoadStringA_s

		dd	offset	LoadLibraryA
		dd	offset	LoadLibraryA_s

		dd	offset	LoadLibraryExA
		dd	offset	LoadLibraryExA_s

		dd	offset	LocalAlloc
		dd	offset	LocalAlloc_s

		dd	offset	LocalFileTimeToFileTime
		dd	offset	LocalFileTimeToFileTime_s

		dd	offset	LocalFree
		dd	offset	LocalFree_s

		dd	offset	lstrcat
		dd	offset	lstrcat_s

		dd	offset	lstrcatA
		dd	offset	lstrcatA_s

		dd	offset	lstrcmp
		dd	offset	lstrcmp_s

		dd	offset	lstrcmpA
		dd	offset	lstrcmpA_s

		dd	offset	lstrcmpi
		dd	offset	lstrcmpi_s

		dd	offset	lstrcmpiA
		dd	offset	lstrcmpiA_s

		dd	offset	lstrcpy
		dd	offset	lstrcpy_s

		dd	offset	lstrcpyA
		dd	offset	lstrcpyA_s

		dd	offset	lstrcpyn
		dd	offset	lstrcpyn_s

		dd	offset	lstrcpynA
		dd	offset	lstrcpynA_s

		dd	offset	lstrlen
		dd	offset	lstrlen_s

		dd	offset	lstrlenA
		dd	offset	lstrlenA_s

		dd	offset	MessageBoxA
		dd	offset	MessageBoxA_s

		dd	offset	MoveFileA
		dd	offset	MoveFileA_s

		dd	offset	MultiByteToWideChar
		dd	offset	MultiByteToWideChar_s

		dd	offset	PeekConsoleInputA
		dd	offset	PeekConsoleInputA_s

		dd	offset	RaiseException
		dd	offset	RaiseException_s

		dd	offset	ReadConsoleA
		dd	offset	ReadConsoleA_s

		dd	offset	ReadConsoleInputA
		dd	offset	ReadConsoleInputA_s

		dd	offset	ReadFile
		dd	offset	ReadFile_s

		dd	offset	RegCloseKey
		dd	offset	RegCloseKey_s

		dd	offset	RegOpenKeyA
		dd	offset	RegOpenKeyA_s

		dd	offset	RegOpenKeyExA
		dd	offset	RegOpenKeyExA_s

		dd	offset	RegQueryValueExA
		dd	offset	RegQueryValueExA_s

		dd	offset	RemoveDirectoryA
		dd	offset	RemoveDirectoryA_s

		dd	offset	RtlUnwind
		dd	offset	RtlUnwind_s

		dd	offset	SetConsoleCtrlHandler
		dd	offset	SetConsoleCtrlHandler_s

		dd	offset	SetConsoleCursorPosition
		dd	offset	SetConsoleCursorPosition_s

		dd	offset	SetConsoleMode
		dd	offset	SetConsoleMode_s

		dd	offset	SetConsoleScreenBufferSize
		dd	offset	SetConsoleScreenBufferSize_s

		dd	offset	SetConsoleTextAttribute
		dd	offset	SetConsoleTextAttribute_s

		dd	offset	SetConsoleWindowInfo
		dd	offset	SetConsoleWindowInfo_s

		dd	offset	SetCurrentDirectoryA
		dd	offset	SetCurrentDirectoryA_s

		dd	offset	SetEndOfFile
		dd	offset	SetEndOfFile_s

		dd	offset	SetFileAttributesA
		dd	offset	SetFileAttributesA_s

		dd	offset	SetFilePointer
		dd	offset	SetFilePointer_s

		dd	offset	SetFileTime
		dd	offset	SetFileTime_s

		dd	offset	SetHandleCount
		dd	offset	SetHandleCount_s

		dd	offset	SysAllocStringLen
		dd	offset	SysAllocStringLen_s

		dd	offset	SysFreeString
		dd	offset	SysFreeString_s

		dd	offset	SysStringLen
		dd	offset	SysStringLen_s

		dd	offset	SystemTimeToFileTime
		dd	offset	SystemTimeToFileTime_s

		dd	offset	TlsAlloc
		dd	offset	TlsAlloc_s

		dd	offset	TlsFree
		dd	offset	TlsFree_s

		dd	offset	TlsGetValue
		dd	offset	TlsGetValue_s

		dd	offset	TlsSetValue
		dd	offset	TlsSetValue_s

		dd	offset	UnhandledExceptionFilter
		dd	offset	UnhandledExceptionFilter_s

		dd	offset	VariantClear
		dd	offset	VariantClear_s

		dd	offset	VariantChangeType
		dd	offset	VariantChangeType_s

		dd	offset	VariantChangeTypeEx
		dd	offset	VariantChangeTypeEx_s

		dd	offset	VariantCopy
		dd	offset	VariantCopy_s

		dd	offset	VariantCopyInd
		dd	offset	VariantCopyInd_s

		dd	offset	VariantInit
		dd	offset	VariantInit_s

		dd	offset	VirtualAlloc
		dd	offset	VirtualAlloc_s

		dd	offset	VirtualFree
		dd	offset	VirtualFree_s

		dd	offset	VirtualQuery
		dd	offset	VirtualQuery_s

		dd	offset	WideCharToMultiByte
		dd	offset	WideCharToMultiByte_s

		dd	offset	WriteFile
		dd	offset	WriteFile_s

		dd	offset	WritePrivateProfileStringA
		dd	offset	WritePrivateProfileStringA_s


		dd	offset	_hread
		dd	offset	_hread_s

		dd	offset	_hwrite
		dd	offset	_hwrite_s

		dd	offset	_lclose
		dd	offset	_lclose_s

		dd	offset	_lcreat
		dd	offset	_lcreat_s

		dd	offset	_llseek
		dd	offset	_llseek_s

		dd	offset	_lopen
		dd	offset	_lopen_s

		dd	offset	_lread
		dd	offset	_lread_s

		dd	offset	_lwrite
		dd	offset	_lwrite_s

		dd	0		;end of table

k32dllstring	db	'kernel32.dll',0

expstrings	label	near

DeleteCriticalSection_s		db	'DeleteCriticalSection',0
LeaveCriticalSection_s		db	'LeaveCriticalSection',0
EnterCriticalSection_s		db	'EnterCriticalSection',0
VirtualFree_s			db	'VirtualFree',0
LocalFree_s			db	'LocalFree',0
LocalAlloc_s			db	'LocalAlloc',0
TlsSetValue_s			db	'TlsSetValue',0
TlsGetValue_s			db	'TlsGetValue',0
GetModuleHandleA_s		db	'GetModuleHandleA',0
GetLastError_s			db	'GetLastError',0
GetCommandLineA_s		db	'GetCommandLineA',0
WriteFile_s			db	'WriteFile',0
SetFilePointer_s		db	'SetFilePointer',0
SetEndOfFile_s			db	'SetEndOfFile',0
RtlUnwind_s			db	'RtlUnwind',0
ReadFile_s			db	'ReadFile',0
RaiseException_s		db	'RaiseException',0
GetStdHandle_s			db	'GetStdHandle',0
GetFileSize_s			db	'GetFileSize',0
GetFileType_s			db	'GetFileType',0
ExitProcess_s			db	'ExitProcess',0
CreateFileA_s			db	'CreateFileA',0
CloseHandle_s			db	'CloseHandle',0
MessageBoxA_s			db	'MessageBoxA',0
GetCurrentThreadId_s		db	'GetCurrentThreadId',0
FileTimeToDosDateTime_s		db	'FileTimeToDosDateTime',0
GetStartupInfoA_s		db	'GetStartupInfoA',0
FindClose_s			db	'FindClose',0
FindFirstFileA_s		db	'FindFirstFileA',0
FreeLibrary_s			db	'FreeLibrary',0
GetCurrentDirectoryA_s		db	'GetCurrentDirectoryA',0
InitializeCriticalSection_s	db	'InitializeCriticalSection',0
VirtualAlloc_s			db	'VirtualAlloc',0
DeleteFileA_s			db	'DeleteFileA',0
GetDriveTypeA_s			db	'GetDriveTypeA',0
GetEnvironmentStrings_s		db	'GetEnvironmentStrings',0
GetEnvironmentVariableA_s	db	'GetEnvironmentVariableA',0
GetFileAttributesA_s		db	'GetFileAttributesA',0
SetFileAttributesA_s		db	'SetFileAttributesA',0
GetFileInformationByHandle_s	db	'GetFileInformationByHandle',0
GetFullPathNameA_s		db	'GetFullPathNameA',0
GetLocalTime_s			db	'GetLocalTime',0
GetLogicalDrives_s		db	'GetLogicalDrives',0
GetModuleFileNameA_s		db	'GetModuleFileNameA',0
GetProcAddress_s		db	'GetProcAddress',0
MoveFileA_s			db	'MoveFileA',0
SetCurrentDirectoryA_s		db	'SetCurrentDirectoryA',0
CreateDirectoryA_s		db	'CreateDirectoryA',0
RemoveDirectoryA_s		db	'RemoveDirectoryA',0
GetSystemTime_s			db	'GetSystemTime',0
GetVersion_s			db	'GetVersion',0
GetVersionExA_s			db	'GetVersionExA',0
GetVersionExW_s			db	'GetVersionExW',0
GlobalMemoryStatus_s		db	'GlobalMemoryStatus',0
SetConsoleCtrlHandler_s		db	'SetConsoleCtrlHandler',0
SetHandleCount_s		db	'SetHandleCount',0
UnhandledExceptionFilter_s	db	'UnhandledExceptionFilter',0
EnumThreadWindows_s		db	'EnumThreadWindows',0
GetTimeZoneInformation_s	db	'GetTimeZoneInformation',0
MultiByteToWideChar_s		db	'MultiByteToWideChar',0
WideCharToMultiByte_s		db	'WideCharToMultiByte',0
Borland32_s			db	'Borland32',0
LocalFileTimeToFileTime_s	db	'LocalFileTimeToFileTime',0
FileTimeToLocalFileTime_s	db	'FileTimeToLocalFileTime',0
FileTimeToSystemTime_s		db	'FileTimeToSystemTime',0
SystemTimeToFileTime_s		db	'SystemTimeToFileTime',0
DosDateTimeToFileTime_s		db	'DosDateTimeToFileTime',0
SetFileTime_s			db	'SetFileTime',0
GetFileTime_s			db	'GetFileTime',0
FindNextFileA_s			db	'FindNextFileA',0
GetPrivateProfileStringA_s	db	'GetPrivateProfileStringA',0
WritePrivateProfileStringA_s	db	'WritePrivateProfileStringA',0
VariantClear_s			db	'VariantClear',0
VariantCopy_s			db	'VariantCopy',0
VariantCopyInd_s		db	'VariantCopyInd',0
VariantInit_s			db	'VariantInit',0
VariantChangeType_s		db	'VariantChangeType',0
VariantChangeTypeEx_s		db	'VariantChangeTypeEx',0
GetLocaleInfoA_s		db	'GetLocaleInfoA',0
GetSystemDefaultLCID_s		db	'GetSystemDefaultLCID',0
SysStringLen_s			db	'SysStringLen',0
SysAllocStringLen_s		db	'SysAllocStringLen',0
LoadStringA_s			db	'LoadStringA',0
VirtualQuery_s			db	'VirtualQuery',0
AllocConsole_s			db	'AllocConsole',0
Beep_s				db	'Beep',0
CreateConsoleScreenBuffer_s	db	'CreateConsoleScreenBuffer',0
FillConsoleOutputAttribute_s	db	'FillConsoleOutputAttribute',0
FillConsoleOutputCharacterA_s	db	'FillConsoleOutputCharacterA',0
FlushConsoleInputBuffer_s	db	'FlushConsoleInputBuffer',0
FreeConsole_s			db	'FreeConsole',0
GetACP_s			db	'GetACP',0
GetConsoleCP_s			db	'GetConsoleCP',0
GetConsoleCursorInfo_s		db	'GetConsoleCursorInfo',0
GetConsoleMode_s		db	'GetConsoleMode',0
GetConsoleOutputCP_s		db	'GetConsoleOutputCP',0
GetOEMCP_s			db	'GetOEMCP',0
ReadConsoleA_s			db	'ReadConsoleA',0
SysFreeString_s			db	'SysFreeString',0
GetThreadLocale_s		db	'GetThreadLocale',0
GetCPInfo_s			db	'GetCPInfo',0
GetSystemMetrics_s		db	'GetSystemMetrics',0
LoadLibraryA_s			db	'LoadLibraryA',0
LoadLibraryExA_s		db	'LoadLibraryExA',0
GetKeyboardType_s		db	'GetKeyboardType',0
RegCloseKey_s			db	'RegCloseKey',0
RegOpenKeyA_s			db	'RegOpenKeyA',0
RegOpenKeyExA_s			db	'RegOpenKeyExA',0
RegQueryValueExA_s		db	'RegQueryValueExA',0
GetVolumeInformationA_s		db	'GetVolumeInformationA',0
GetNumberOfConsoleInputEvents_s	db	'GetNumberOfConsoleInputEvents',0
PeekConsoleInputA_s		db	'PeekConsoleInputA',0
ReadConsoleInputA_s		db	'ReadConsoleInputA',0
SetConsoleMode_s		db	'SetConsoleMode',0
GetConsoleScreenBufferInfo_s	db	'GetConsoleScreenBufferInfo',0
GetLargestConsoleWindowSize_s	db	'GetLargestConsoleWindowSize',0
SetConsoleScreenBufferSize_s	db	'SetConsoleScreenBufferSize',0
SetConsoleTextAttribute_s	db	'SetConsoleTextAttribute',0
SetConsoleWindowInfo_s		db	'SetConsoleWindowInfo',0
SetConsoleCursorPosition_s	db	'SetConsoleCursorPosition',0
GetDateFormatA_s		db	'GetDateFormatA',0
TlsAlloc_s			db	'TlsAlloc',0
TlsFree_s			db	'TlsFree',0
GetStringTypeW_s		db	'GetStringTypeW',0
FormatMessageA_s		db	'FormatMessageA',0
EnumCalendarInfoA_s		db	'EnumCalendarInfoA',0
CompareStringA_s		db	'CompareStringA',0

lstrlen_s			db	'lstrlen',0
lstrlenA_s			db	'lstrlenA',0
lstrcpy_s			db	'lstrcpy',0
lstrcpyA_s			db	'lstrcpyA',0
lstrcpyn_s			db	'lstrcpyn',0
lstrcpynA_s			db	'lstrcpynA',0
lstrcat_s			db	'lstrcat',0
lstrcatA_s			db	'lstrcatA',0
lstrcmp_s			db	'lstrcmp',0
lstrcmpA_s			db	'lstrcmpA',0
lstrcmpi_s			db	'lstrcmpi',0
lstrcmpiA_s			db	'lstrcmpiA',0
_lread_s			db	'_lread',0
_lwrite_s			db	'_lwrite',0
_lcreat_s			db	'_lcreat',0
_lopen_s			db	'_lopen',0
_lclose_s			db	'_lclose',0
_llseek_s			db	'_llseek',0
_hread_s			db	'_hread',0
_hwrite_s			db	'_hwrite',0


fmsgmsg				db	'Default error notification',0

;-------------- Get ready for my implementation of win32 --

; new API functions now are living in includes

include	fattrib.inc	; get/set file attribute
include memstat.inc	; GlobalMemoryStatus
include seh.inc		; structured exception handling routines
include widechr.inc	; MultiByteToWideChar / WideCharToMultiByte
include time.inc	; SystemTimeToFileTime and all that crap
include variant.inc	; oleout32.dll phantom functions
include	resrc.inc	; retrieving some resources
include lfuns.asi	; these Win16 leftovers
include advapi32.asi	; Registry phantoms

;-----------------------------------------------------------------------------

; These fail successfully:

LoadLibraryExA:
IFDEF DEBUG
		push	offset	LoadLibraryExA_s
		call	output0string
		mov	eax,4cffh
		int	21h
ELSE
		sub	eax,eax
		retn	12
ENDIF
GetStringTypeW:
push	offset GetStringTypeW_s
call	output0string
mov	ah,4ch
int	21h

FreeLibrary:
IFDEF DEBUG
push	offset FreeLibrary_s
call	output0string
mov	ah,4ch
int	21h
ENDIF

LoadLibraryA:
IFDEF DEBUG
		push	offset	LoadLibraryA_s
		call	output0string
		mov	eax,4cffh
		int	21h
ELSE
		sub	eax,eax
		retn	4
ENDIF

;-----------------------------------------------------------------------------

; ignore shit like that
GetDateFormatA:
			sub	eax, eax
			retn	24

GetSystemMetrics:
			sub	eax,eax
			retn	4

GetPrivateProfileStringA:
			push	dword ptr [esp+12]
			push	dword ptr [esp+20]
			call	lstrcpyA
			push	eax
			call	lstrlenA
			retn	24

WritePrivateProfileStringA:
			mov	eax,1
			retn	16

;
; This is ONLY for Delphi 3.01+ compatibility!
;
FormatMessageA:
			mov	edx, offset fmsgmsg
			mov	eax, [esp+20]
fmsgaloop:
			mov	cl, [edx]
			inc	edx
			mov	[eax], cl
			inc	eax
			test	cl, cl
			jne	fmsgaloop

			sub	eax, [esp+20]
			dec	eax
			retn	28
;
; only a partial implementation, too
;
CompareStringA:
			push	esi
			push	edi

			cmp	dword ptr [esp+24], -1
			jne	short cstra1
			push	dword ptr [esp+20]
			call	lstrlen
			mov	dword ptr [esp+24], eax
cstra1:

			cmp	dword ptr [esp+32], -1
			jne	short cstra2
			push	dword ptr [esp+28]
			call	lstrlen
			mov	dword ptr [esp+32], eax
cstra2:

			mov	eax, 2
			mov	esi, [esp+20]
			mov	edi, [esp+28]
			mov	ecx, [esp+24]
			cmp	ecx, [esp+32]
			jnc	short csta01

			mov	ecx, [esp+32]

csta01:
			cld
			repe	cmpsb
			jne	csta02

			mov	ecx, [esp+24]
			cmp	ecx, [esp+32]
			je	csta03

csta02:
			sbb	eax, eax
			and	eax, 3
			xor	al, 2
			
csta03:
			pop	esi
			pop	edi
			retn	24


EnumCalendarInfoA:	
			mov	LastError, 5555h
			sub	eax, eax
			retn	16

;-----------------------------------------------------------------------------
; who cares?

GetKeyboardType:
			mov	eax,4
			cmp	byte ptr [esp+4],2
			jz	short gkbt00
			mov	eax,12
gkbt00:
			retn	4

;-----------------------------------------------------------------------------

; this should go into time.inc

LocalFileTimeToFileTime:
FileTimeToLocalFileTime:
		mov	edx,[esp+4]
		mov	ecx,[esp+8]
		mov	eax,[edx]
		mov	edx,[edx+4]
		mov	[ecx],eax
		mov	[ecx+4],eax
		mov	eax,1
		retn	8

GetTimeZoneInformation:
		push	offset DummyTime
		call	GetLocalTime
		mov	edx,[esp+4]
		mov	Bias[edx],0
		mov	StandardName[edx],0
		mov	dword ptr StandardDate[edx],offset DummyTime
		mov	StandardBias[edx],0
		mov	DaylightName[edx],0
		mov	dword ptr DaylightDate[edx],offset DummyTime
		mov	DaylightBias[edx],0
		retn	4

;-----------------------------------------------------------------------------

EnumThreadWindows:
		mov	eax,1
		retn	12

;-----------------------------------------------------------------------------
; ignore...

SetConsoleCtrlHandler:
		mov	eax,1
		retn	8

;-----------------------------------------------------------------------------

SetHandleCount:

; 2do: call the DOS function!

		mov	eax,20
		retn	4

;-----------------------------------------------------------------------------

GetVersion:
	; return Win 3.1 with Win 32s or something like that... I don't care.
		mov	eax,80000103h
		retn

;-----------------------------------------------------------------------------

VER_PLATFORM_WIN32s		equ	0
VER_PLATFORM_WIN32_WINDOWS	equ	1
VER_PLATFORM_WIN32_NT 		equ	2

GetVersionExW:
GetVersionExA:
		mov	edx,[esp+4]
		mov	dword ptr [edx+4],3
		mov	dword ptr [edx+8],5
		mov	dword ptr [edx+12],1000
		mov	dword ptr [edx+16],0
		mov	dword ptr [edx+20],0
		mov	eax,1
		retn	4

;-----------------------------------------------------------------------------
; This is actually called by the BC 5 runtime!

GetProcAddress:
		push	esi
		push	edi
		mov	esi,[esp+16]
		mov	ecx,offset k32dll
		cld
gpa_loop:
		cmp	dword ptr [ecx],0
		jz	gpa_error
		mov	edi,[ecx+4]
		call	compare_string
		jz	gpa_found
		add	ecx,8
		jmp	gpa_loop
gpa_error:
		mov	LastError,1234	; what the heck...
gpa_found:
		pop	edi
		pop	esi
		mov	eax,[ecx]
		retn	8

;-----------------------------------------------------------------------------
DeleteCriticalSection:
;same as below
IFDEF DEBUG
push offset deletecriticalsection_s
call output0string
retn 4
ENDIF

InitializeCriticalSection:
IFDEF DEBUG
push offset initializecriticalsection_s
call output0string
ENDIF
		retn	4

; both of the above end up in this one

;--------------- 2do? --------------------------------------------------------

LeaveCriticalSection:
		retn	4
;push	offset LeaveCriticalSection_s
;call	output0string
;mov	ah,4ch
;int	21h


EnterCriticalSection:
		retn	4
;push	offset EnterCriticalSection_s
;call	output0string
;mov	ah,4ch
;int	21h


;--------------- return just a funny number on this one ----------------------

GetCurrentThreadId:
	mov eax,12345678h
	retn

;-----------------------------------------------------------------------------

GetModuleFileNameA:

	mov	ecx,ApiFnameLen
	sub	eax,eax
	cmp	ecx,[esp+12]
	jnc	short gmf_error
	mov	eax,ecx
	inc	eax
	push	esi
	push	edi
	cld
	mov	edi,[esp+16]
	mov	esi,offset CmdTail
	rep	movsb
	mov	byte ptr [edi],0
	pop	edi
	pop	esi

gmf_error:
	retn	12

;-----------------------------------------------------------------------------

GetEnvironmentStrings:
	mov	eax,EnvArray
	mov	eax,[eax]
	retn

;-----------------------------------------------------------------------------


GetEnvironmentVariableA:
	push	edi
	push	esi
	cld
	mov	edi,[esp+12]
	mov	esi,edi
	sub	eax,eax
	mov	ecx,-1
	repne	scasb
	lea	ecx,[edi-1]
	sub	ecx,esi
	mov	edx,EnvArray
	sub	eax,eax
@@gevnew:
	push	esi
	push	ecx
	mov	edi,[edx]
	add	edx,4
	test	edi,edi
	jnz	short @@gevcont
	pop	ecx
	pop	esi
	jmp	short @@gevnotfound
@@gevcont:
	repe	cmpsb
	pop	ecx
	pop	esi
	jnz	short @@gevnew
	cmp	byte ptr [edi],'='
	jnz	short @@gevnew
	inc	edi
	or	ecx,-1
	sub	eax,eax
	repne	scasb
	lea	esi,[edi+ecx+1]
	sub	eax,ecx
	dec	eax
	test	dword ptr [esp+20],-1
	jz	short @@gevdone
	cmp	eax,[esp+20]
	ja	@@gevnotfound
	mov	ecx,eax
	dec	eax
	mov	edi,[esp+16]
	rep	movsb
	jmp	short @@gevdone
@@gevnotfound:
	sub	eax,eax
@@gevdone:
	pop	esi
	pop	edi
	retn	12


;-----------------------------------------------------------------------------

GetFullPathNameA:
		cmp	dword ptr [esp+8],80
		jnc	@@gfpn00
		mov	eax,80
		retn	16
@@gfpn00:
		push	dword ptr [esp+12]
		push	dword ptr [esp+12]
		call	GetCurrentDirectoryA
		test	eax,eax
		jnz	@@gfpn01
		retn	16
@@gfpn01:
		mov	edx,[esp+12]
		add	edx,eax
		cmp	byte ptr [edx-1],'\'
		jz	short @@gfpn03
		mov	byte ptr [edx],'\'
		inc	edx
@@gfpn03:
		mov	ecx,[esp+16]
		mov	[ecx],edx
		mov	ecx,[esp+4]
@@gfpn02:
		mov	al,[ecx]
		inc	ecx
		mov	[edx],al
		inc	edx
		test	al,al
		jnz	@@gfpn02
		lea	eax,[edx-1]
		sub	eax,[esp+12]
		retn	16

;-----------------------------------------------------------------------------

GetCurrentDirectoryA:
IFDEF DEBUG
push	offset GetCurrentDirectoryA_s
call	output0string
ENDIF
	mov	lasterror,0
	push	esi
	mov	esi,[esp+12]	;we do not check buffer size...
	mov	ah,19h
	int	21h
	add	al,'A'
	mov	[esi],al
	inc	esi
	mov	word ptr [esi],'\:'
	inc	esi
	inc	esi
	sub	edx,edx
	mov	ah,47h
	int	21h
	pop	esi
	jc	short mkdir_error
	mov	eax,[esp+8]
@@gcd01:
	cmp	byte ptr [eax],0
	jz	short @@gcd00
	inc	eax
	jmp	short @@gcd01
@@gcd00:
	sub	eax,[esp+8]
	retn	8

;-----------------------------------------------------------------------------

CreateDirectoryA:
IFDEF DEBUG
push	offset CreateDirectoryA_s
call	output0string
ENDIF

	mov	ah,39h
	mov	lasterror,0
	mov	edx,[esp+4]
	int	21h

from_cwd:
	jc	short mkdir_error
	mov	eax,1
	retn	8

mkdir_error:
	mov	word ptr ds:[offset lasterror],ax
	sub	eax,eax
	retn	8

;-----------------------------------------------------------------------------

RemoveDirectoryA:
IFDEF DEBUG
push	offset RemoveDirectoryA_s
call output0string
ENDIF
	mov	ah,3ah
	jmp	short from_rmdir


SetCurrentDirectoryA:
IFDEF DEBUG
push	offset SetCurrentDirectoryA_s
call	output0string
ENDIF
	mov	eax,[esp+4]
	cmp	byte ptr [eax+1],':'
	jnz	short from_setdrive
	mov	dl,[eax]
	or	dl,20h
	sub	dl,'a'
	mov	ah,0eh
	int	21h
	add	dword ptr [esp+4],2

from_setdrive:
	mov	ah,3bh

from_rmdir:
	mov	lasterror,0
	mov	edx,[esp+4]
	int	21h
	jc	short chdir_error
	mov	eax,1
	retn	4

chdir_error:
	mov	word ptr ds:[offset lasterror],ax
	sub	eax,eax
	retn	4

;-----------------------------------------------------------------------------

GetVolumeInformationA:

; Note that this returns FAT, even for a Network drive! No Volume name etc.
; returned either
		
		mov	edx,[esp+8]
		test	edx,edx
		jz	short gvi01
		mov	byte ptr [edx],0
gvi01:
		mov	edx,[esp+16]
		test	edx,edx
		jz	short gvi02
		mov	dword ptr [edx],0
gvi02:
		mov	edx,[esp+20]
		test	edx,edx
		jz	short gvi03
		mov	dword ptr [edx],12
gvi03:
		mov	edx,[esp+24]
		test	edx,edx
		jz	short gvi04
		mov	dword ptr [edx],0
gvi04:
		mov	edx,[esp+28]
		test	edx,edx
		jz	short gvi05
		mov	dword ptr [edx],'TAF'
gvi05:
		mov	eax,1
		retn	32

;-----------------------------------------------------------------------------
; 2do 2do 2do

GetDriveTypeA:
push	offset GetDriveTypeA_s
call	output0string
mov	ah,4ch
int	21h

;-----------------------------------------------------------------------------

GetLogicalDrives:
		push	ebx
		mov	ebx,32
		sub	ecx,ecx
Gldr00:
		mov	eax,4409h
		int	21h
		cmc
		adc	ecx,ecx
		dec	ebx
		jnz	short Gldr00		
		
		mov	eax,ecx
		pop	ebx
		retn

;-----------------------------------------------------------------------------
; These map to the same function
;-----------------------------------------------------------------------------

GetLocalTime:
IFDEF DEBUG
push	offset GetLocalTime_s
call	output0string
jmp	DEBUG_GST
ENDIF

GetSystemTime:
IFDEF DEBUG
push	offset GetSystemTime_s
call	output0string
DEBUG_GST:
ENDIF
	push	ebx
	mov	ebx,[esp+8]
	mov	ah,2ah
	int	21h
	mov	[ebx.wYear],cx
	sub	ecx,ecx
	mov	cl,dh
	mov	[ebx.wMonth],cx
	mov	cl,al
	mov	[ebx.wDayOfWeek],cx
	mov	cl,dl
	mov	[ebx.wDay],cx
	mov	ah,2ch
	int	21h
	sub	eax,eax
	mov	al,ch
	mov	[ebx.wHour],ax
	mov	al,cl
	mov	[ebx.wMinute],ax
	mov	al,dh
	mov	[ebx.wSecond],ax
	mov	al,dl
	lea	eax,[eax*4+eax]
	add	eax,eax
	mov	[ebx.wMilliseconds],ax
	pop	ebx
	retn	4

;-----------------------------------------------------------------------------

FindFirstFileA:
		mov	edx,offset NewDTA + (80h * 31)
		mov	ecx,31
		mov	eax,ffHandles
@@fff01:
		add	eax,eax
		jnc	@@fff00
		sub	edx,80h
		loop	@@fff01
		mov	LastError,113
		mov	eax,-1
		retn	8
@@fff00:
		mov	ah,1ah
		int	21h
		push	ecx
		push	edx
		mov	ecx,-1
		mov	edx,[esp+12]
		mov	eax,4e00h
		int	21h
		pop	edx
		pop	ecx
		jc	@@fff02
		bts	ffHandles,ecx
		push	ecx
		mov	ecx,[esp+12]
		sub	eax,eax
		mov	al,[edx+15h]
		mov	[ecx],eax
		lea	eax,[ecx+4]
		push	ecx
		push	edx
		push	eax
		movzx	eax,word ptr [edx+16h]
		push	eax
		movzx	eax,word ptr [edx+18h]
		push	eax
		call	DosDateTimeToFileTime
		pop	edx
		pop	ecx
		mov	eax,[ecx+4]
		mov	[ecx+12],eax
		mov	[ecx+20],eax
		mov	eax,[ecx+8]
		mov	[ecx+16],eax
		mov	[ecx+24],eax
		mov	dword ptr [ecx+28],0
		mov	eax,[edx+1ah]
		mov	[ecx+32],eax
		sub	eax,eax
		push	ebx
		mov	ebx,13
@@fff03:	mov	al,[edx+1eh]
		inc	edx
		mov	[ecx+40],ax
		mov	[ecx+300],ax
		add	ecx,2
		dec	ebx
		jnz	short @@fff03
		pop	ebx
		pop	eax
		retn	8
@@fff02:
		mov	LastError,eax
		mov	eax,-1
		retn	8

FindNextFileA:
		mov	edx,[esp+4]
		mov	eax,6
		cmp	edx,32
		jnc	short @@fnf00
		shl	edx,7
		add	edx,offset NewDTA
		mov	ah,1ah
		int	21h
		mov	ah,4fh
		int	21h
		jc	@@fnf00
		mov	ecx,[esp+8]
		sub	eax,eax
		mov	al,[edx+15h]
		mov	[ecx],eax
		lea	eax,[ecx+4]
		push	ecx
		push	edx
		push	eax
		movzx	eax,word ptr [edx+16h]
		push	eax
		movzx	eax,word ptr [edx+18h]
		push	eax
		call	DosDateTimeToFileTime
		pop	edx
		pop	ecx
		mov	eax,[ecx+4]
		mov	[ecx+12],eax
		mov	[ecx+20],eax
		mov	eax,[ecx+8]
		mov	[ecx+16],eax
		mov	[ecx+24],eax
		mov	dword ptr [ecx+28],0
		mov	eax,[edx+1ah]
		mov	[ecx+32],eax
		sub	eax,eax
		push	ebx
		mov	ebx,13
@@fnf01:	mov	al,[edx+1eh]
		inc	edx
		mov	[ecx+40],ax
		mov	[ecx+300],ax
		add	ecx,2
		dec	ebx
		jnz	short @@fnf01
		pop	ebx
		mov	al,1
		retn	8
@@fnf00:
		mov	LastError,eax
		sub	eax,eax
		retn	8

;-----------------------------------------------------------------------------

FindClose:
		mov	eax,[esp+4]
		cmp	eax,32
		jc	short @@fcl00
@@fcl01:
		mov	LastError,6
		sub	eax,eax
		retn	4
@@fcl00:
		btr	ffHandles,eax
		jnc	short @@fcl01
		mov	eax,1
		retn	4

;-----------------------------------------------------------------------------

GetFileInformationByHandle:
push	offset GetFileInformationByHandle_s
call	output0string
mov	ah,4ch
int	21h

;-----------------------------------------------------------------------------

GetStartupInfoA:
	mov	edx,[esp+4]
	sub	eax,eax
	sub	ecx,ecx
	inc	ecx
	mov	dword ptr [edx],17*4
	mov	dword ptr [edx+ecx*4],eax
	inc	ecx
	mov	dword ptr [edx+ecx*4],eax
	inc	ecx
	mov	dword ptr [edx+ecx*4],eax
	inc	ecx
	mov	dword ptr [edx+ecx*4],eax
	inc	ecx
	mov	dword ptr [edx+ecx*4],eax
	inc	ecx
	mov	dword ptr [edx+ecx*4],eax
	inc	ecx
	mov	dword ptr [edx+ecx*4],eax
	inc	ecx
	mov	dword ptr [edx+ecx*4],80
	inc	ecx
	mov	dword ptr [edx+ecx*4],25
	inc	ecx
	mov	dword ptr [edx+ecx*4],7
	inc	ecx
	mov	dword ptr [edx+ecx*4],eax
	inc	ecx
	mov	dword ptr [edx+ecx*4],eax
	inc	ecx
	mov	dword ptr [edx+ecx*4],eax
	inc	ecx
	mov	dword ptr [edx+ecx*4],eax
	inc	ecx
	inc	eax
	mov	dword ptr [edx+ecx*4],eax
	inc	ecx
	inc	eax
	mov	dword ptr [edx+ecx*4],eax
	retn	4

;-----------------------------------------------------------------------------

; merely a dummy, since D3 calls this

VirtualQuery:

	mov	ax,[esp+6]
	mov	edx,offset va_space
	mov	ecx,blockcount
vq00:
	test	dword ptr [edx+ecx*4-4],-1
	jz	short vq03
	cmp	ax,[edx+ecx*4-2]
	jnc	short vq01
vq03:
	dec	ecx
	jnz	short vq00
vq04:
	mov	edx,[esp+8]
	mov	dword ptr [edx+12],0
	mov	dword ptr [edx+16],10000h	; mem_free
	mov	eax,24*4
	retn	12
vq01:
	sub	ax,[edx+ecx*4-2]
	cmp	ax,[edx+ecx*4]
	ja	short vq04
	mov	ecx,[edx+ecx*4-4]
	mov	edx,[esp+8]
	mov	eax,ecx
	and	eax,0ffff0000h
	mov	[edx],eax
	mov	[edx+4],eax
	mov	dword ptr [edx+8],40h		; page_execute_readwrite
	shl	ecx,16
	mov	[edx+12],ecx
	mov	dword ptr [edx+16],1000h	; mem_commit
	add	eax,ecx
	cmp	eax,segment_size
	jna	short vq02
	mov	dword ptr [edx+16],2000h	; mem_reserve
vq02:
	mov	dword ptr [edx+20],20000h	; mem_private
	mov	dword ptr [edx+24],40h
	mov	eax,24*4
	retn	12

;-----------------------------------------------------------------------------

VirtualAlloc:
;if not AT:
;  if free handle
;    use first fit,
;    if (commit) check + set segment limit -> exit on error
;  else error
;else
;  if in table (part of a block)
;    if size fits
;      if (commit) check + set segment limit -> exit on error
;    else error
;  else
;    if free handle 
;      if (commit) check + set segment limit -> exit on error
;    else error
;end
IFDEF DEBUG
mov	edx,free_handles
neg edx
add	edx,blockcount+30h
mov	ah,2
int	21h
mov	dl,' '
mov	ah,2
int	21h
push	offset VirtualAlloc_s
call	output0string
ENDIF

;1. Check whether AT or VOID
		cmp	dword ptr [esp+4],0
		mov	edx,offset va_space
		jnz	va_not_void
;2. Now we know that we chose the address, check if handle free
		cmp	free_handles,0
		jz	va_error

;3. Find a meory block that fits
;3.1 Find first used handle
		mov	ecx,free_handles
		cmp	ecx,blockcount
		jnz	short va_more_than_one

;we are the first block, so things get simple

		mov	eax,initial_top

va_putintolastblock:
		mov	edx,[esp+8]
		add	edx,0ffffh
		sub	dx,dx
		add	edx,eax
		cmp	edx,segment_size
		jna	short va_puttable	; 0.94 instead of jnc
		mov	ecx,edx
		test	byte ptr [esp+13],10h	;commit?
		jnz	short va_commit
		lea	edx,[eax+1000h]		;commit at least 1 page

va_commit:
;try to increase segment size
		mov	ax,-1
		int	21h
		jc	va_error

		mov	segment_size,edx
		sub	ax,ax
		mov	edx,ecx

va_puttable:
		sub	edx,eax
		shr	edx,16
		or	edx,eax
		mov	DWORD PTR ds:[offset va_space + 4*blockcount-4],edx
		dec	free_handles
		retn	16

va_more_than_one:
		push	ebx
;hier?
;edx -> va_space
;ecx = free_handles
		mov	ebx,[esp+12]		;size
		add	ebx,0ffffh
		sub	bx,bx

		lea	edx,[ecx*4+edx]		;first used
;edx -> first used
		mov	ecx,[edx]
;untersuch
		sub	cx,cx
		cmp	ecx,initial_top
		jz	short va_notatstart

;try insert block at start

		mov	eax,ebx
		add	eax,initial_top
		cmp	eax,ecx
		jnc	short va_check_next_hole
;insert block at start, is committed anyway
		shr	ebx,16
		mov	eax,initial_top
		add	ebx,eax
		mov	[edx-4],ebx
		pop	ebx
		dec	free_handles
		retn	16

va_notatstart:
;edx -> lowest used block
		cmp	edx,offset va_space + 4*blockcount-4
		jnz	short va_notlastblock
;o.k. lets cheat
		mov	dword ptr ds:[offset va_space],-1
		call	mem_bsort		;this will free last entry
		pop	ebx
		mov	eax,dword ptr ds:[offset va_space + blockcount*4 - 8]
		mov	edx,eax
		sub	ax,ax
		shl	edx,16
		add	eax,edx
		jmp	va_putintolastblock

va_insertblock:
		sub	eax,ebx		;this is the start
		shr	ebx,16		;size
		add	ebx,eax
		mov	dword ptr ds:[offset va_space],ebx
		pop	ebx
		call	mem_bsort
		dec	free_handles
		retn	16

va_notlastblock:
;not first, not last...,
;well, check base+size [edx] + desired size against base [edx+4]
		mov	eax,[edx-2]
		sub	ax,ax
;this one caused a crash, of course...
;		add	eax,[ebx]
		add	eax,[edx]	;looks much better... Aaarrghh

		sub	ax,ax
		add	eax,ebx
		cmp	eax,[edx+4]
		jc	short va_insertblock

va_check_next_hole:

		add	edx,4
		jmp	short va_notatstart
va_error:
		sub	eax,eax
		retn	16
va_not_void:
;IRL we had a lot of checking to do here
;check if block potentially in table

		mov	eax,[esp+4]
		sub	ax,ax
		cmp	eax,initial_top		;is below lowest possible?
		jc	short va_error

;EAX=desired end address, compare with highest possible block

		mov	ecx,ds:[offset va_space+blockcount*4-4]
		sub	cx,cx
		add	ecx,ds:[offset va_space+blockcount*4-6]
		sub	cx,cx
		cmp	ecx,eax
;ecx = highest allocated address
		jna	va_notintable

;here we know that desired block is in table range though it can overlap block
;boundaries, dunno, does the runtime check that?

		mov	ecx,[esp+8]
		add	ecx,[esp+4]
		add	ecx,0ffffh
		sub	cx,cx

		; ecx = desired end address

va_checkifinblock:
		cmp	edx,offset va_space+(4*blockcount)-4	;last block
		jz	va_last_check
		cmp	dword ptr [edx],0	;doesn't matter
		jz	short va_add4toedx
		cmp	eax,[edx]
		jc	short va_was_last

va_add4toedx:
		add	edx,4
		jmp	short va_checkifinblock

va_was_last:
;it's this one
		cmp	edx,offset va_space+(4*blockcount)-4	;last block
		jz	va_last_check
		add	edx,4
;edx-4 is our block, check for overlap
		cmp	ecx,[edx]
		jnc	va_error		;blocks cannot overlap
		mov	[esp+4],eax
		push	ecx
;check if start is in free space so we'd have to create a new block
		mov	ecx,[edx-6]		;get size
		sub	cx,cx
		add	ecx,[edx-4]		;add start
		sub	cx,cx
		cmp	ecx,eax		;ecx=actual end
		jnc	va_checkincrease
		pop	ecx
;create a new block with start eax size ecx-eax
		sub	ecx,eax
		shr	ecx,16
		add	ecx,eax
		cmp	free_handles,0
		jz	va_error
		mov	dword ptr ds:[offset va_space],ecx
		call	mem_bsort
		dec	free_handles
		retn	16

;do we have to increase block size?
va_checkincrease:
		pop	eax			;eax= desired block size
						;ecx=actual block size
		cmp	ecx,eax
		jnc	va_noswap
		mov	ecx,eax
		shr	ecx,16
		mov	[edx-4],cx

va_noswap:
		mov	eax,[esp+4]
		retn	16

va_last_check:
;it's in the last block. all we have to do is the <commit> -check.
;if commit, check against ecx else check against eax+1000h
		mov	edx,ecx
		test	byte ptr [esp+13],10h	;commit?
		jnz	short va_lastcommit
		lea	edx,[eax+1000h]

va_lastcommit:
; 0.94 fixed a flaw
		cmp	edx,segment_size
		jna	short va_inmemrange
		mov	ax,-1
		int	21h
		jc	va_error
		sub	ax,ax
va_inmemrange:
		sub	ecx,eax
		shr	ecx,16
		cmp	cx,word ptr ds:[offset va_space+4*blockcount-4]
		jna	short va_done
		cmp	word ptr ds:[offset va_space+4*blockcount-4],cx
va_done:
		retn	16

va_notintable:
;cheat again

		cmp	free_handles,0
		jz	va_error
		mov	dword ptr ds:[offset va_space],-1
		call	mem_bsort		;this will free last entry
		jmp	va_putintolastblock

VirtualFree:
IFDEF DEBUG
mov	edx,free_handles
neg	edx
add	edx,blockcount+30h
mov	ah,2
int	21h
mov	dl,' '
mov	ah,2
int	21h
push	offset virtualfree_s
call	output0string
ENDIF

;strategy: ignore mem_decommit so things get simple
		test	byte ptr [esp+13],80h
		jnz	short vf_do_something

		sub	eax,eax				;we cannot decommit
		inc	eax
		retn	12				;so we don't

vf_do_something:
		mov	ax,word ptr [esp+6]
		mov	edx,offset va_space
vf_findloop:
		cmp	ax,[edx+2]
		jz	short vf_found
		add	edx,4
		cmp	edx,offset va_space+4*blockcount
		jnz	short vf_findloop
		sub	eax,eax
		retn	12

vf_found:
		sub	eax,eax
		mov	[edx],eax
		call	mem_bsort
		inc	free_handles
		inc	eax
		retn	12

LocalFree:
IFDEF DEBUG
push	offset localfree_s
call	output0string
ENDIF
		mov	eax,[esp+4]
		sub	eax,8
		mov	edx,offset start_of_heap

lf_next_mcb:
		cmp	eax,[edx]			;next one?
		jz	short lf_found
		mov	edx,[edx]
		test	edx,edx				;not an mcb anymore?
		jnz	lf_next_mcb

;what do we have to return?

		mov	eax,-1
		retn	4

lf_found:
;check if we can concatenate with previous one
		cmp	edx,offset start_of_heap	;is there?
		jz	short lf_check_behind
		test	dword ptr [edx.mcb_desc],mcb_free
		jz	short lf_check_behind
;can concatenate
		mov	ecx,[eax]
		mov	[edx],ecx
;check if behind next block also free
		test	ecx,ecx				;something behind?
		jz	short lf_done

lf_testnext:
		test	dword ptr [ecx.mcb_desc],mcb_free
		jz	short lf_done
;can concatenate
		mov	eax,[ecx]
		mov	[edx],eax
		jmp	short lf_done

lf_check_behind:
		or	dword ptr [eax.mcb_desc],mcb_free
		mov	edx,eax
		mov	ecx,[eax]
		test	ecx,ecx
		jnz	lf_testnext

lf_done:
		sub	eax,eax
		retn	4

LocalAlloc:
IFDEF DEBUG
push	offset localalloc_s
call	output0string
ENDIF

;find a memory block of desired size
;2do: best fit rather than first fit
	mov	edx,[esp+8]	;get size
	add	edx,8+3		;add mcb size & roundoff
;2do: other allocation granularity
	and	dl,0fch

	mov	ecx,ds:[offset start_of_heap]

la_exam_mcb:
	cmp	[ecx.mcb_next],0	;last one?
	jz	short la_try_end

;check if free
	test	[ecx.mcb_desc],mcb_free
	jnz	short la_check_size
;get next
la_get_next:
	mov	ecx,[ecx.mcb_next]
	jmp	short la_exam_mcb

la_check_size:
	mov	eax,[ecx.mcb_next]
	sub	eax,ecx
;actual size in eax
	cmp	eax,edx
	jc	short la_get_next
;it fits.
	lea	edx,[ecx+8]
	and	[ecx.mcb_desc],not mcb_free	;mark used
	jmp	short la_success

la_try_end:
	lea	eax,[ecx+edx+8]
	cmp	eax,end_of_heap
	jnc	short la_error
;initialize new mcb
	sub	eax,8
	mov	[ecx.mcb_next],eax
	mov	[eax.mcb_next],0		;mark as last in chain
	and	[ecx.mcb_desc],not mcb_free	;mark used
	lea	edx,[ecx+8]
la_success:
;handle in edx
;check for zeroinit
	test	byte ptr [esp+4],40h
	jz	short la_exit
	push	edi
	cld
	mov	edi,eax
	mov	ecx,[esp+8]
	add	ecx,3
	shr	ecx,2
	sub	eax,eax
	rep	stosd
	pop	edi

la_exit:
	mov	eax,edx
	retn	8

la_error:
	sub	eax,eax
	retn	8

;-----------------------------------------------------------------------------
; We don't support multiple threads, though, but...

tlsbits		dq	0

TlsAlloc:
	bsf	eax, dword ptr ds:[offset tlsbits]
	jnz	short TlsAllocSuccess
	bsf	eax, dword ptr ds:[offset tlsbits + 4]
	lea	eax, [eax + 32]
	jnz	short TlsAllocSuccess
	or	eax, -1
	retn

TlsAllocSuccess:
	bts	dword ptr ds:[offset tlsbits], eax
	retn

; -----------------------------------------------------
;
;
TlsFree:
	mov	ecx, [esp + 4]
	cmp	ecx, 64
	sbb	eax, eax
	jnc	TlsFreeError

	btr	dword ptr ds:[offset tlsbits], ecx

TlsFreeError:
	and	eax, 1
	retn	4

; -----------------------------------------------------
;
;
TlsSetValue:
	mov	ecx, [esp + 4]
	cmp	ecx, 64
	jnc	TlsSetError
	mov	eax, [esp + 8]
	mov	TlsSpace[ecx * 4], eax

TlsSetError:
	sbb	eax, eax
	and	eax, 1
	retn	8

; -----------------------------------------------------
;
;
TlsGetValue:
	mov	ecx, [esp + 4]
	or	LastError, -1			; 2do!
	sub	eax, eax
	cmp	ecx, 64
	jnc	TlsGetError

	mov	LastError, eax
	mov	eax, TlsSpace[ecx * 4]

TlsGetError:
	retn	4

;-----------------------------------------------------------------------------

GetModuleHandleA:
	mov	eax,[esp+4]
	test	eax,eax
	jnz	short gmh_other
	mov	eax,rva2offset
;	mov	eax,ImageBase
;	sub	eax,SizeOfMzExe
	retn	4
gmh_other:
; called by the BC runtime with "kernel32.dll"

	push	esi
	push	edi

	; test for kernel32.dll

	cld
	mov	edi,eax
	mov	esi,offset k32dllstring
	call	compare_string
	pop	edi
	pop	esi

	jnz	gmh_error
	mov	eax,'K32'
	retn	4

gmh_error:
	push	offset GetModuleHandleA_s
	call	output0string
	push	dword ptr [esp+4]
	call	output0string
	mov	eax,4cffh
	int	21h

GetLastError:
	mov	eax,lasterror
	retn

;-----------------------------------------------------------------------------

GetCommandLineA:
	mov	eax,offset CmdTail
	retn

;-----------------------------------------------------------------------------

MoveFileA:
IFDEF DEBUG
push	offset MoveFileA_s
call output0string
push	dword ptr [esp+8]
call output0string
push	dword ptr [esp+12]
call output0string
ENDIF
		push	edi
		mov	lasterror,0
		mov	edx,[esp+8]
		mov	edi,[esp+12]
		sub	ecx,ecx
		mov	ah,56h
		int	21h
		jnc	short mva_noerror
		mov	word ptr ds:[offset lasterror],ax
		sub	eax,eax
		jmp	short mva_exit
mva_noerror:
		mov	eax,1
mva_exit:
		pop	edi
		retn	8

;-----------------------------------------------------------------------------

DeleteFileA:
IFDEF DEBUG
push	offset DeleteFileA_s
call	output0string
ENDIF
	mov	lasterror,0
	mov	edx,[esp+4]
	mov	ah,41h
	int	21h
	jnc	short df_noerror
	mov	word ptr ds:[offset lasterror],ax
df_noerror:
	sbb	eax,eax
	inc	eax
	retn	4

;-----------------------------------------------------------------------------

WriteFile:
IFDEF DEBUG
push	offset WriteFile_s
call	output0string
ENDIF
		push	ebx
		mov	ebx,[esp+8]
		mov	edx,[esp+12]
		mov	ecx,[esp+16]
		test	ecx,ecx
		mov	eax,ecx
		jz	short @@wf_donothing
		mov	ah,40h
		int	21h
		jnc	short wf_noerror
@@wf_donothing:
		mov	word ptr ds:[offset lasterror],ax

wf_noerror:
		mov	ecx,[esp+20]
		mov	[ecx],eax
		pop	ebx
		sbb	eax,eax
		inc	eax
		retn	20


SetFilePointer:
		push	ebx
		mov	ebx,[esp+8]
		mov	edx,[esp+12]
		mov	eax,[esp+20]
		shld	ecx,edx,16
		mov	ah,42h
		int	21h
		jnc	short sf_noerror
		mov	word ptr ds:[offset lasterror],ax
sf_noerror:

		sbb	eax,eax
		pop	ebx
		retn	16

SetEndOfFile:
IFDEF DEBUG
push	offset SetEndOfFile_s
call	output0string
ENDIF
		push	ebx
		mov	ebx,[esp+8]
		sub	ecx,ecx
		mov	ah,40h
		int	21h
		jnc	seof_noerror
		mov	word ptr ds:[offset lasterror],ax
seof_noerror:
		sbb	eax,eax
		inc	eax
		pop	ebx
		retn	4

; ############################################################################

; This should do the trick for RtlUnwind:

RtlUnwind:
IFDEF DEBUG
push	offset RtlUnwind_s
call	output0string
ENDIF

		; check if all exceptions to unwind

		cmp	dword ptr [esp+4],1

		; set to end of chain if so

		sbb	dword ptr [esp+4],0

		; trash return address

		pop	edx

		; check if we need to call handlers yet

		mov	edx,[esp+8]	; edx = ExceptionRecord
		test	edx,edx
		jnz	short @@UnwindChain
@@UnwindDone:
		pop	dword ptr fs:[0]
		retn	8

@@UnwindChain:
; junk

;		or	ExceptionFlags[edx],UNWIND_IN_PROGRESS

		; 2do: check this again ^^

		; check if done

		mov	ecx,fs:[0]	; ecx = DispatchRecord
@@UnwindNext:
		cmp	ecx,[esp]
		jz	short @@UnwindDone
		push	ecx
		push	edx

		push	ecx
		push	0		; may not work
		push	ecx
		push	edx		
		call	pEHandler[ecx]

		; 2do: calling conventions ?
		; !!!
		add	esp,16

		pop	edx
		pop	ecx
		mov	ecx,pPrevious[ecx]
		jmp	short @@UnwindNext


; ############################################################################
		
ReadFile:
IFDEF DEBUG
push	offset ReadFile_s
call	output0string
ENDIF
		mov	lasterror,0
		push	ebx
		mov	ebx,[esp+8]
		mov	edx,[esp+12]
		mov	ecx,[esp+16]

		test	ebx,ebx
		js	rf_iscon
		jnz	rf_testin
rf_iscon:
		test	ConsoleMode,ENABLE_LINE_INPUT
		jnz	rf_testin
		sub	ebx,ebx
rf_waitcon:
		dec	ecx
		js	rf_condone
		mov	ah,7
		int	21h
		mov	[edx],al
		inc	edx
		inc	ebx
		mov	ah,0bh
		int	21h
		cmp	al,-1	
		jz	rf_waitcon
rf_condone:
		mov	eax,[esp+20]
		mov	[eax],ebx
		pop	ebx
		mov	eax,1
		retn	20

rf_testin:

		mov	ah,3fh
		int	21h
		jnc	short rf_noerror
		mov	word ptr ds:[offset lasterror],ax
rf_noerror:
		mov	edx,[esp+20]
		mov	[edx],eax
		sbb	eax,eax
		inc	eax
		pop	ebx
		retn	20

;-----------------------------------------------------------------------------

GetStdHandle:
IFDEF DEBUG
push	offset GetStdHandle_s
call	output0string
ENDIF
	mov	eax,[esp+4]
	neg	eax
	sub	eax,10
	jc	short gsh_iscarry
	cmp	eax,3
	cmc
	jc	short gsh_iscarry
	retn	4
gsh_iscarry:
	sbb	eax,eax
	retn	4

;-----------------------------------------------------------------------------

GetFileSize:
IFDEF DEBUG
push	offset GetFileSize_s
call	output0string
ENDIF
	push	ebp
	push	ebx
	mov	ebp,esp
	push	ebx		;really need this?
	mov	ebx,[ebp+12]
	sub	edx,edx
	sub	ecx,ecx
	mov	eax,4201h
	int	21h
	jc	short	carry_error
	push	edx
	push	eax
	sub	edx,edx
	sub	ecx,ecx
	mov	eax,4202h
	int	21h
	jc	short	carry_error
	shl	edx,16
	or	eax,edx
	pop	edx
	pop	ecx
	push	eax
	mov	eax,4200h
	int	21h
	jc	short	carry_error
	pop	eax
	jmp	short	gfs_exit
carry_error:
	mov	word ptr ds:[offset lasterror],ax
	sbb	eax,eax

gfs_exit:
	mov	esp,ebp
	pop	ebx
	pop	ebp
	retn	8

;-----------------------------------------------------------------------------

GetFileType:
	push	ebx
	mov	ebx,[esp+8]
	mov	eax,4400h
	int	21h
	pop	ebx
	jc	gft_error
	and	edx,080h
	shr	edx,7
	mov	eax,1
	add	eax,edx
	retn	4
gft_error:
	mov	word ptr ds:[offset lasterror],ax
	sub	eax,eax
	retn	4

;-----------------------------------------------------------------------------

ExitProcess:
	mov	eax,[esp+4]
	mov	ah,4ch
	int	21h

;-----------------------------------------------------------------------------

CreateFileA:
gen_read	equ	80h
gen_write	equ	40h
	mov	LastError,0
	mov	eax,3d00h
	mov	edx,[esp+4]
	sub	ecx,ecx
	cmp	byte ptr [esp+20],CREATE_ALWAYS
	jnz	short dont_force
openalways:
	mov	eax,3c00h
	int	21h
	jc	short crf_error
	retn	28
dont_force:
	int	21h
	jc	short file_doesnt_exist
	push	ebx
	mov	ebx,eax
	mov	ah,3eh
	int	21h
	pop	ebx
	mov	eax,80	; ERROR_FILE_EXISTS
	cmp	byte ptr [esp+20],CREATE_NEW
	jz	short crf_error
	cmp	byte ptr [esp+20],TRUNCATE_EXISTING
	jz	short openalways
	mov	eax,3d00h
	test	byte ptr [esp+11],gen_write
	jz	short crf_test1
	mov	al,1
crf_test1:
	test	byte ptr [esp+11],gen_read
	jz	short crf_doit
	test	al,al
	jz	short crf_doit
	mov	al,2
crf_doit:
	mov	edx,[esp+4]
	int	21h
	jc	short crf_error
	retn	28
file_doesnt_exist:
	cmp	byte ptr [esp+20],OPEN_EXISTING
	jz	short crf_error
	cmp	byte ptr [esp+20],TRUNCATE_EXISTING
	jnz	short openalways
crf_error:
	mov	word ptr ds:[offset lasterror],ax
	mov	eax,-1
	retn	28

CloseHandle:
IFDEF DEBUG
push	offset closehandle_s
call	output0string
ENDIF
	mov	lasterror,0
	push	ebx
	mov	ebx,[esp+8]
	mov	ah,3eh
	int	21h

	jnc	short ch_noerror
	mov	word ptr ds:[offset lasterror],ax
ch_noerror:
	pop	ebx
	sbb	eax,eax
	inc	eax
	retn	4

;-----------------------------------------------------------------------------

MessageBoxA:
;this one is only called if something went wrong, so we don't care
		push	dword ptr [esp+8]
		call	output0string
		mov	ax,4cffh
		int	21h

;*****************************************************************************
;            -------------- end of win32 api ------------------
;*****************************************************************************

mem_bsort	proc	near
;bubble sorting memory blocks, not fast but...
		pushad
		mov	ecx,offset va_space
		mov	ebp,ecx
		add	ecx,blockcount*4-4

va_bs_start:
		mov	edx,ebp
		sub	ebp,ebp

va_bs_next:
		mov	eax,[edx]
		cmp	eax,[edx+4]
		jna	short va_bs_inorder
		xchg	eax,[edx+4]
		mov	[edx],eax
		test	ebp,ebp
		jnz	short va_bs_inorder
		mov	ebp,edx

va_bs_inorder:
		add	edx,4
		cmp	edx,ecx
		jnz	short va_bs_next
		test	ebp,ebp
		jnz	short va_bs_start
		popad
		ret
mem_bsort	endp

