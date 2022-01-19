; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/win32/K32MISC.ASM 1.13 2000/04/11 17:47:04 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: K32MISC.ASM $
; Revision 1.13  2000/04/11 17:47:04  MikeT
; Implemented GetSystemTimeAsFileTime (BCC55 support).
;
; Revision 1.12  2000/03/18 19:37:08  MikeT
; Implemented CompareFileTime (sort of)
;
; Revision 1.11  2000/02/10 19:35:19  MikeT
; Implemented stub for CreateEventA.
;
; Revision 1.10  2000/02/05 17:35:50  MikeT
; WideCharToMultiByte and MultiByteToWideChar now stop when a 0 character is
; detetcted. This has been suggested by Oleg Prokhorov.
;
; Revision 1.9  2000/01/30 17:41:14  MikeT
; Implemented GetSystemDefaultLangID, which just returns LANG_NEUTRAL.
;
; Revision 1.8  1999/02/07 21:07:26  MikeT
; Updated copyright.
;
; Revision 1.7  1998/11/27 04:28:56  MikeT
; Fix GetTickCount returning incorrect values
;
; Revision 1.6  1998/11/01 22:24:47  MikeT
; Added GetSystemInfo)() courtesy Genadi V. Zawidowski
;
; Revision 1.5  1998/08/09 16:18:09  MikeT
; Fix FT2DOSDT
;
; Revision 1.4  1998/08/09 15:40:50  MikeT
; fix TickCount
;
; Revision 1.3  1998/08/09 14:49:31  MikeT
; fix LFT <-> FT
;
; Revision 1.2  1998/08/08 14:06:00  MikeT
; Added GetTickCount etc.
;
; Revision 1.1  1998/08/03 01:44:10  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## Miscellanous kernel32.dll function replacements                        ##
; ############################################################################

.386
.model flat

include	w32struc.inc

.code

		PUBLICDLL		DebugBreak
		PUBLICDLL		InterlockedIncrement
		PUBLICDLL		InterlockedDecrement
		PUBLICDLL		InterlockedExchange
		PUBLICDLL		TerminateProcess
		PUBLICDLL		FreeEnvironmentStringsA
		PUBLICDLL		FreeEnvironmentStringsW
		PUBLICDLL		GetCurrentTime
		PUBLICDLL		GetTickCount
		PUBLICDLL		QueryPerformanceCounter
		PUBLICDLL		QueryPerformanceFrequency
		PUBLICDLL		FileTimeToSystemTime
		PUBLICDLL		SystemTimeToFileTime
		PUBLICDLL		FileTimeToDosDateTime
		PUBLICDLL		DosDateTimeToFileTime
		PUBLICDLL		GetLocaleInfoA
		PUBLICDLL		GetSystemInfo
		PUBLICDLL		GetCPInfo
		PUBLICDLL		GetThreadLocale
		PUBLICDLL		GetSystemDefaultLCID
		PUBLICDLL		GetUserDefaultLCID
		PUBLICDLL		GetSystemDefaultLangID
		PUBLICDLL 		FileTimeToLocalFileTime
		PUBLICDLL 		CompareFileTime
		PUBLICDLL		LocalFileTimeToFileTime 
		PUBLICDLL		GetTimeZoneInformation
		PUBLICDLL		GetLocalTime
		PUBLICDLL		GetSystemTime
		PUBLICDLL		WideCharToMultiByte
		PUBLICDLL		MultiByteToWideChar
		PUBLICDLL		LCMapStringW
		PUBLICDLL		LCMapStringA
		PUBLICDLL		GetCurrentProcess
		PUBLICDLL		CreateEventA
		PUBLICDLL		GetSystemTimeAsFileTime


		EXTRN			ExitProcess: NEAR

;+---------------------------------------------------------------------------
; Now that's an easy one...
;
DebugBreak PROC NEAR
		int	3
		retn
DebugBreak ENDP

;+---------------------------------------------------------------------------
; In case of the event...
;
CreateEventA PROC NEAR
		sub     eax, eax
		retn    16
CreateEventA ENDP

;+---------------------------------------------------------------------------
; No threads - no trouble:
;
InterlockedIncrement PROC NEAR
		mov	eax, [esp + 4]
		inc	DWORD PTR [eax]
		mov	eax, [eax]
		retn	4
InterlockedIncrement ENDP

InterlockedDecrement PROC NEAR
		mov	eax, [esp + 4]
		dec	DWORD PTR [eax]
		mov	eax, [eax]
		retn	4
InterlockedDecrement ENDP

InterlockedExchange PROC NEAR
		mov	edx, [esp + 4]
		mov	eax, [esp + 8]
		xchg	eax, [edx]
		retn	8
InterlockedExchange ENDP

;
; 2do: at least in plain DOS and with a Pentium, we can make this work
;
QueryPerformanceCounter LABEL NEAR
QueryPerformanceFrequency LABEL NEAR

		sub	eax, eax
		retn	4
;
; Following implementations are incomplete but allow VC++ to work
;
WideCharToMultiByte LABEL NEAR
		push	ebx
		mov	ecx, [esp + 16 + 4]	; number of input chrs
		mov	edx, [esp + 12 + 4]	; input string
		mov	ebx, [esp + 20 + 4]	; output string
		sub	eax, eax
		test	ebx, ebx
		jz	@@wcmbDone

@@wcmbLoop:
		mov	al, [edx]
		inc	edx
		inc	edx
		mov	[ebx], al
		inc	ebx
		test	al ,al
		jz	@@wcmbDone

		loop	@@wcmbLoop

@@wcmbDone:
		sub	ebx, [esp + 20 + 4]
		mov	eax, ebx
		pop	ebx
		retn	32


MultiByteToWideChar LABEL NEAR
		push	ebx
		mov	ecx, [esp + 16 + 4]	; number of input chrs
		mov	edx, [esp + 12 + 4]	; input string
		mov	ebx, [esp + 20 + 4]	; output string
		test	ebx, ebx
		jz	@@mbwcDone

		sub	eax, eax

@@mbwcLoop:
		mov	al, [edx]
		inc	edx
		mov	[ebx], ax
		inc	ebx
		inc	ebx
		test	al, al
		jz	@@mbwcDone

		loop	@@mbwcLoop

@@mbwcDone:
		sub	ebx, [esp + 20 + 4]
		mov	eax, ebx
		pop	ebx
		retn	24

FreeEnvironmentStringsA LABEL NEAR
FreeEnvironmentStringsW LABEL NEAR
		mov	eax, 1
		retn	4

GetCurrentProcess LABEL NEAR
		mov	eax, 12345678h
		retn

TerminateProcess LABEL NEAR
		pop	eax
		pop	edx
		push	eax
		cmp	edx, 12345678h
		jz	ExitProcess		

		sub	eax, eax
		retn	4

;+----------------------------------------------------------------------------
; Win32 - GetSystemInfo
;
GetSystemInfo   PROC NEAR
		mov	edx, [esp+4]
		mov	DWORD PTR [edx+00h], 00000000h	; PROCESSOR_ARCHITECTURE_INTEL = 0
		mov	DWORD PTR [edx+04h], 00001000h	; dwPageSize
		mov	DWORD PTR [edx+08h], 00400000h	; lpMinimumApplicationAddress
		mov	DWORD PTR [edx+0ch], 7f000000h	; lpMaximumApplicationAddress
		mov	DWORD PTR [edx+10h], 00000001h	; dwActiveProcessorMask
		mov	DWORD PTR [edx+14h], 386	; dwProcessorType 386
		mov	DWORD PTR [edx+1ch], 00010000h	; dwAllocationGranularity 64K
		mov	word ptr [edx+20h], 3		; wProcessorLevel 3 = 386
		mov	word ptr [edx+22h], 0000h	; dwAllocationGranularity;
		retn	4
GetSystemInfo   ENDP

;+----------------------------------------------------------------------------
; Win32 - GetCurrentTime
; Win32 - GetTickCount
;
; This is the "I don't give a rat's ass" solution as most software needs the
; differences only. It is not even very accurate but what would you expect
; from a one-instruction- implementation?
;
GetCurrentTime LABEL NEAR
GetTickCount LABEL NEAR
;		imul	eax, DWORD PTR ds: [46Ch], 18
; 64k ticks is exactly one hour
;
; 3600 000	shr 16
; 1800 000	shr 15
;  900 000	shr 14
;  445 000	shr 13
;  222 500	shr 12
;  111 250	shr 11
;   55 625	shr 10
; ..55 624	shr 10
;   27 812      shr  9
;   13 906      shr  8
;    6 953	shr  7
; .. 6 952	shr  7
;    3 976      shr  6
;    1 888	shr  5
;
		mov	eax, 55625
		mul	DWORD PTR ds: [46Ch]
		shrd	eax, edx, 10
;		mov	eax, 3600000
;		mul	DWORD PTR ds: [46Ch]
;		shrd	eax, edx, 16
		retn

;+----------------------------------------------------------------------------
; Win32  - FileTimeToLocalFileTime and vice versa
;
; These do a mere copy
;
FileTimeToLocalFileTime LABEL NEAR
LocalFileTimeToFileTime PROC NEAR

		mov	edx, [esp+4]
		mov	ecx, [esp+8]
		mov	eax, [edx]
		mov	edx, [edx+4]
		mov	[ecx], eax
		mov	[ecx+4], edx
		mov	eax, 1
		retn	8

LocalFileTimeToFileTime ENDP

;+---------------------------------------------------------------------------
;
; Win32 - GetSystemTimeAsFileTime
;
; win32.hlp says this function was not available on a Windows95 platform.
; At least as far as OSR2, this is a lie.
;
GetSystemTimeAsFileTime PROC NEAR
		sub	esp, 16
		mov	eax, esp
		push	DWORD PTR [esp + 4 + 16]
		push	eax
		push	eax
		call	GetSystemTime
		call	SystemTimeToFileTime
		add	esp, 16
		retn	4
GetSystemTimeAsFileTime ENDP


;+----------------------------------------------------------------------------
; Win32  - CompareFileTime
;
;
CompareFileTime PROC NEAR

		mov	edx, [esp + 4]
		mov	ecx, [esp + 8]
		mov	eax, [edx + 4]
		sub	eax, [ecx + 4]
		je	cftLower

		sbb	eax, eax
		jc	cftDone

		jmp	cftDoInc

cftLower:
		mov	eax, [edx]
		sub	eax, [ecx]
		je	cftDone

		sbb	eax, eax

cftDoInc:
		lea	eax, [eax + eax + 1]

cftDone:
		retn	8

CompareFileTime ENDP

;+----------------------------------------------------------------------------
; Win32 - GetTimeZoneInformation
;
GetTimeZoneInformation PROC NEAR

		push	OFFSET DummyTime
		call	GetLocalTime
		mov	edx, [esp+4]
		mov	Bias[edx], 0
		mov	StandardName[edx], 0
		mov	DWORD PTR StandardDate[edx], OFFSET DummyTime
		mov	StandardBias[edx], 0
		mov	DaylightName[edx], 0
		mov	DWORD PTR DaylightDate[edx], OFFSET DummyTime
		mov	DaylightBias[edx], 0
		retn	4

GetTimeZoneInformation ENDP

;+----------------------------------------------------------------------------
; Win32 - GetLocalTime / GetSystemTime
;
GetLocalTime LABEL NEAR
GetSystemTime PROC NEAR

		push	ebx
		mov	ebx, [esp+8]
		mov	ah, 2Ah
		int	21h
		mov	[ebx.wYear], cx
		sub	ecx, ecx
		mov	cl, dh
		mov	[ebx.wMonth], cx
		mov	cl, al
		mov	[ebx.wDayOfWeek], cx
		mov	cl, dl
		mov	[ebx.wDay], cx
		mov	ah, 2Ch
		int	21h
		sub	eax, eax
		mov	al, ch
		mov	[ebx.wHour], ax
		mov	al, cl
		mov	[ebx.wMinute], ax
		mov	al, dh
		mov	[ebx.wSecond], ax
		mov	al, dl
		lea	eax, [eax * 4 + eax]
		add	eax, eax
		mov	[ebx.wMilliseconds], ax
		pop	ebx
		retn	4

GetSystemTime ENDP

;+----------------------------------------------------------------------------
; Win32 - FileTimeToSystemTime
;
; We do not use the Windows FILETIME format who cares about 1601 A.D. anyway?
;
FileTimeToSystemTime PROC NEAR

		mov	ecx, [esp+4]
		mov	edx, [esp+8]
		sub	eax, eax
		mov	al, [ecx+6]
		mov	wMonth[edx], ax
		mov	al, [ecx+5]
		mov	wDay[edx], ax
		mov	al, [ecx+4]
		mov	wDayOfWeek[edx], ax
		mov	al, [ecx+3]
		mov	wHour[edx], ax
		mov	al, [ecx+2]
		mov	wMinute[edx], ax
		mov	al, [ecx+1]
		mov	wSecond[edx], ax
		mov	al, [ecx]
		shl	eax, 4
		mov	wMilliseconds[edx], ax
		sub	eax, eax
		mov	al, [ecx+7]
		add	eax, 1980
		mov	wYear[edx], ax
		mov	eax, 1
		retn	8

FileTimeToSystemTime ENDP

;+----------------------------------------------------------------------------
; Win32 - SystemTimeToFileTime
;
; We do not use the Windows FILETIME format who cares about 1601 A.D. anyway?
;
SystemTimeToFileTime PROC NEAR

		mov	ecx, [esp+4]
		movzx	eax, wHour[ecx]
		mov	edx, eax
		shl	edx, 8
		movzx	eax, wMinute[ecx]
		mov	dl, al
		shl	edx, 8
		movzx	eax, wSecond[ecx]
		mov	dl, al
		shl	edx, 8
		movzx	eax, wMilliseconds[ecx]
		shr	eax, 4
		mov	dl, al
		mov	eax, [esp+8]
		mov	[eax], edx
		movzx	eax, wYear[ecx]
		sub	eax, 1980
		mov	dl, al
		shl	edx, 8
		movzx	eax, wMonth[ecx]
		mov	dl, al
		shl	edx, 8
		movzx	eax, wDay[ecx]
		mov	dl, al
		shl	edx, 8
		movzx	eax, wDayOfWeek[ecx]
		mov	dl, al
		mov	eax, [esp+8]	
		mov	[eax+4], edx
		mov	eax, 1
		retn	8

SystemTimeToFileTime ENDP

;+----------------------------------------------------------------------------
; Win32 - FileTimeToDosDateTime
;
FileTimeToDosDateTime PROC NEAR
		mov	ecx, [esp + 4]
		mov	edx, [esp + 8]
		mov	ah, [ecx + 7]		; year
		add	ah, ah			; shift to 9..15
		mov	al, [ecx + 5]		; day
		mov	[edx], ax		; write y + d
		movzx	eax, BYTE PTR [ecx + 6]	; get month
		shl	eax, 5			; shift to 5..8
		or	[edx], ax		; write
		mov	edx, [esp + 12]
		mov	ah, [ecx + 3]
		mov	al, [ecx + 2]
		shl	al, 2
		shl	eax, 3
		mov	[edx + 1], ah
		mov	ax, [ecx + 1]
		shr	al, 1
		shl	ah, 5
		or	al, ah
		mov	[edx], al
		mov	eax, 1
		retn	12

FileTimeToDosDateTime ENDP

;+----------------------------------------------------------------------------
; Win32 - DosDateTimeToFileTime
;
DosDateTimeToFileTime PROC NEAR

		mov	edx, [esp+12]
		mov	byte ptr [edx], 0
		mov	eax, [esp+8]
		add	eax, eax
		and	al, 3Fh
		mov	[edx+1], al
		mov	eax, [esp+8]
		shr	eax, 5
		and	al, 3Fh
		mov	[edx+2], al
		mov	eax, [esp+8]
		shr	eax, 11
		and	al, 1Fh
		mov	[edx+3], al
		mov	eax, [esp+4]
		and	al, 1Fh
		mov	[edx+5], al
		mov	eax, [esp+4]
		shr	eax, 5
		and	al, 0Fh
		mov	[edx+6], al
		mov	eax, [esp+4]
		shr	eax, 9
		and	al, 7Fh
		mov	[edx+7], al
		mov	eax, 1
		retn	12

DosDateTimeToFileTime ENDP

;+----------------------------------------------------------------------------
; Win32 - GetLocaleInfoA (Highly crippled)
;
GetLocaleInfoA	PROC	NEAR

		mov	edx, offset LocaleTable
		mov	ecx, [esp+8]
		and	ecx, 0ffffh

@@gliLoop:
		mov	eax, [edx+4]
		test	eax, eax
		jz	short @@gliFound

		cmp	eax, ecx
		jz	short @@gliFound

		add	edx, 8
		jmp	short @@gliLoop

@@gliFound:

; Don't check buffer size

		mov	edx, [edx]
		mov	eax, [esp+12]
		mov	ch, 255

		mov	cl, [esp+8]
		cmp	cl, 31h
		jc	short @@gliCopy

		cmp	cl, 38h
		jc	short @@gliCopy3

		cmp	cl, 44h
		jc	short @@gliCopy

		cmp	cl, 50h
		jnc	short @@gliCopy

@@gliCopy3:
		mov	ch, 3

@@gliCopy:
		mov	cl, [edx]
		mov	[eax], cl
		inc	edx
		inc	eax
		test	cl, cl
		jz	short @@gliCopyEnd

		dec	ch
		jnz	short @@gliCopy

		mov	[eax], ch
		inc	eax

@@gliCopyEnd:
		sub	eax, [esp+12]
		cmp	eax, 2
		sbb	eax, 0
		retn	16

GetLocaleInfoA	ENDP

;+----------------------------------------------------------------------------
; Win32 - GetCPInfo (stubbed)
;
GetCPInfo PROC NEAR

		mov	eax, [esp + 8]
		mov	DWORD PTR [eax], 1
		mov	DWORD PTR [eax + 4], 20h
		and	DWORD PTR [eax + 8], 0
		and	DWORD PTR [eax + 12], 0
		and	DWORD PTR [eax + 14], 0
		retn	8

GetCPInfo ENDP

;+----------------------------------------------------------------------------
; Two + 1 more stubbed out functions
;
GetThreadLocale	LABEL NEAR
GetSystemDefaultLCID LABEL NEAR
GetUserDefaultLCID LABEL NEAR
GetSystemDefaultLangID LABEL NEAR
		sub	eax, eax
		retn

;+----------------------------------------------------------------------------
; And a dummy that allowes us to stub nasmw.exe
;
LCMapStringW	LABEL NEAR
LCMapStringA	LABEL NEAR
		int	3

.data

		align	4

LocaleTable	LABEL	DWORD

dd offset LOCALE_ILANGUAGE, 	      00000001h   ; language id
dd offset LOCALE_SLANGUAGE,           00000002h   ; localized name of language
dd offset LOCALE_SENGLANGUAGE,        00001001h   ; English name of language
dd offset LOCALE_SABBREVLANGNAME,     00000003h   ; abbreviated language name
dd offset LOCALE_SNATIVELANGNAME,     00000004h   ; native name of language
dd offset LOCALE_ICOUNTRY,            00000005h   ; country code
dd offset LOCALE_SCOUNTRY,            00000006h   ; localized name of country
dd offset LOCALE_SENGCOUNTRY,         00001002h   ; English name of country
dd offset LOCALE_SABBREVCTRYNAME,     00000007h   ; abbreviated country name
dd offset LOCALE_SNATIVECTRYNAME,     00000008h   ; native name of country
dd offset LOCALE_IDEFAULTLANGUAGE,    00000009h   ; default language id
dd offset LOCALE_IDEFAULTCOUNTRY,     0000000Ah   ; default country code
dd offset LOCALE_IDEFAULTCODEPAGE,    0000000Bh   ; default oem code page
dd offset LOCALE_IDEFAULTANSICODEPAGE,00001004h   ; default ansi code page
dd offset LOCALE_SLIST,               0000000Ch   ; list item separator
dd offset LOCALE_IMEASURE,            0000000Dh   ; 0 = metric, 1 = US
dd offset LOCALE_SDECIMAL,            0000000Eh   ; decimal separator
dd offset LOCALE_STHOUSAND,           0000000Fh   ; thousand separator
dd offset LOCALE_SGROUPING,           00000010h   ; digit grouping
dd offset LOCALE_IDIGITS,             00000011h   ; number of fractional digits
dd offset LOCALE_ILZERO,              00000012h   ; leading zeros for decimal
dd offset LOCALE_INEGNUMBER,          00001010h   ; negative number mode
dd offset LOCALE_SNATIVEDIGITS,       00000013h   ; native ascii 0-9
dd offset LOCALE_SCURRENCY,           00000014h   ; local monetary symbol
dd offset LOCALE_SINTLSYMBOL,         00000015h   ; intl monetary symbol
dd offset LOCALE_SMONDECIMALSEP,      00000016h   ; monetary decimal separator
dd offset LOCALE_SMONTHOUSANDSEP,     00000017h   ; monetary thousand separator
dd offset LOCALE_SMONGROUPING,        00000018h   ; monetary grouping
dd offset LOCALE_ICURRDIGITS,         00000019h   ; # local monetary digits
dd offset LOCALE_IINTLCURRDIGITS,     0000001Ah   ; # intl monetary digits
dd offset LOCALE_ICURRENCY,           0000001Bh   ; positive currency mode
dd offset LOCALE_INEGCURR,            0000001Ch   ; negative currency mode
dd offset LOCALE_SDATE,               0000001Dh   ; date separator
dd offset LOCALE_STIME,               0000001Eh   ; time separator
dd offset LOCALE_SSHORTDATE,          0000001Fh   ; short date format string
dd offset LOCALE_SLONGDATE,           00000020h   ; long date format string
dd offset LOCALE_STIMEFORMAT,         00001003h   ; time format string
dd offset LOCALE_IDATE,               00000021h   ; short date format ordering
dd offset LOCALE_ILDATE,              00000022h   ; long date format ordering
dd offset LOCALE_ITIME,               00000023h   ; time format specifier
dd offset LOCALE_ITIMEMARKPOSN,       00001005h   ; time marker position
dd offset LOCALE_ICENTURY,            00000024h   ; century format specifier (short date)
dd offset LOCALE_ITLZERO,             00000025h   ; leading zeros in time field
dd offset LOCALE_IDAYLZERO,           00000026h   ; leading zeros in day field (short date)
dd offset LOCALE_IMONLZERO,           00000027h   ; leading zeros in month field (short date)
dd offset LOCALE_S1159,               00000028h   ; AM designator
dd offset LOCALE_S2359,               00000029h   ; PM designator
dd offset LOCALE_ICALENDARTYPE,       00001009h   ; type of calendar specifier
dd offset LOCALE_IOPTIONALCALENDAR,   0000100Bh   ; additional calendar types specifier
dd offset LOCALE_IFIRSTDAYOFWEEK,     0000100Ch   ; first day of week specifier
dd offset LOCALE_IFIRSTWEEKOFYEAR,    0000100Dh   ; first week of year specifier
dd offset LOCALE_SDAYNAME1,           0000002Ah   ; long name for Monday
dd offset LOCALE_SDAYNAME2,           0000002Bh   ; long name for Tuesday
dd offset LOCALE_SDAYNAME3,           0000002Ch   ; long name for Wednesday
dd offset LOCALE_SDAYNAME4,           0000002Dh   ; long name for Thursday
dd offset LOCALE_SDAYNAME5,           0000002Eh   ; long name for Friday
dd offset LOCALE_SDAYNAME6,           0000002Fh   ; long name for Saturday
dd offset LOCALE_SDAYNAME7,           00000030h   ; long name for Sunday
dd offset LOCALE_SABBREVDAYNAME1,     00000031h   ; abbreviated name for Monday
dd offset LOCALE_SABBREVDAYNAME2,     00000032h   ; abbreviated name for Tuesday
dd offset LOCALE_SABBREVDAYNAME3,     00000033h   ; abbreviated name for Wednesday
dd offset LOCALE_SABBREVDAYNAME4,     00000034h   ; abbreviated name for Thursday
dd offset LOCALE_SABBREVDAYNAME5,     00000035h   ; abbreviated name for Friday
dd offset LOCALE_SABBREVDAYNAME6,     00000036h   ; abbreviated name for Saturday
dd offset LOCALE_SABBREVDAYNAME7,     00000037h   ; abbreviated name for Sunday
dd offset LOCALE_SMONTHNAME1,         00000038h   ; long name for January
dd offset LOCALE_SMONTHNAME2,         00000039h   ; long name for February
dd offset LOCALE_SMONTHNAME3,         0000003Ah   ; long name for March
dd offset LOCALE_SMONTHNAME4,         0000003Bh   ; long name for April
dd offset LOCALE_SMONTHNAME5,         0000003Ch   ; long name for May
dd offset LOCALE_SMONTHNAME6,         0000003Dh   ; long name for June
dd offset LOCALE_SMONTHNAME7,         0000003Eh   ; long name for July
dd offset LOCALE_SMONTHNAME8,         0000003Fh   ; long name for August
dd offset LOCALE_SMONTHNAME9,         00000040h   ; long name for September
dd offset LOCALE_SMONTHNAME10,        00000041h   ; long name for October
dd offset LOCALE_SMONTHNAME11,        00000042h   ; long name for November
dd offset LOCALE_SMONTHNAME12,        00000043h   ; long name for December
dd offset LOCALE_SABBREVMONTHNAME1,   00000044h   ; abbreviated name for January
dd offset LOCALE_SABBREVMONTHNAME2,   00000045h   ; abbreviated name for February
dd offset LOCALE_SABBREVMONTHNAME3,   00000046h   ; abbreviated name for March
dd offset LOCALE_SABBREVMONTHNAME4,   00000047h   ; abbreviated name for April
dd offset LOCALE_SABBREVMONTHNAME5,   00000048h   ; abbreviated name for May
dd offset LOCALE_SABBREVMONTHNAME6,   00000049h   ; abbreviated name for June
dd offset LOCALE_SABBREVMONTHNAME7,   0000004Ah   ; abbreviated name for July
dd offset LOCALE_SABBREVMONTHNAME8,   0000004Bh   ; abbreviated name for August
dd offset LOCALE_SABBREVMONTHNAME9,   0000004Ch   ; abbreviated name for September
dd offset LOCALE_SABBREVMONTHNAME10,  0000004Dh   ; abbreviated name for October
dd offset LOCALE_SABBREVMONTHNAME11,  0000004Eh   ; abbreviated name for November
dd offset LOCALE_SABBREVMONTHNAME12,  0000004Fh   ; abbreviated name for December
dd offset LOCALE_SPOSITIVESIGN,       00000050h   ; positive sign
dd offset LOCALE_SNEGATIVESIGN,       00000051h   ; negative sign
dd offset LOCALE_IPOSSIGNPOSN,        00000052h   ; positive sign position
dd offset LOCALE_INEGSIGNPOSN,        00000053h   ; negative sign position
dd offset LOCALE_IPOSSYMPRECEDES,     00000054h   ; mon sym precedes pos amt
dd offset LOCALE_IPOSSEPBYSPACE,      00000055h   ; mon sym sep by space from pos amt
dd offset LOCALE_INEGSYMPRECEDES,     00000056h   ; mon sym precedes neg amt
dd offset LOCALE_INEGSEPBYSPACE,      00000057h   ; mon sym sep by space from neg amt
dd offset LOCALE_WDOSX,0

LOCALE_WDOSX			label	byte
LOCALE_SMONTHNAME13		label	byte
LOCALE_IFIRSTWEEKOFYEAR		label	byte
LOCALE_ICALENDARTYPE		label	byte
LOCALE_IOPTIONALCALENDAR	label	byte
LOCALE_ICENTURY			label	byte
LOCALE_IDATE			label	byte
LOCALE_ILDATE			label	byte
LOCALE_ITIME			label	byte
LOCALE_ITIMEMARKPOSN		label	byte
LOCALE_ICURRENCY		db	0

LOCALE_SNEGATIVESIGN		label	byte
LOCALE_INEGCURR			label	byte
LOCALE_ILZERO			label	byte
LOCALE_INEGNUMBER		label	byte
				db	'-'

LOCALE_SPOSITIVESIGN		db	'+'

LOCALE_IPOSSYMPRECEDES		label	byte
LOCALE_IPOSSEPBYSPACE		label	byte
LOCALE_INEGSYMPRECEDES		label	byte
LOCALE_INEGSEPBYSPACE		label	byte
LOCALE_IPOSSIGNPOSN		label	byte
LOCALE_INEGSIGNPOSN		label	byte
LOCALE_IDAYLZERO		label	byte
LOCALE_IMONLZERO		label	byte
LOCALE_ITLZERO			label	byte
LOCALE_IMEASURE			label	byte
LOCALE_IDEFAULTLANGUAGE		label	byte
LOCALE_IDEFAULTCOUNTRY		label	byte
LOCALE_ICOUNTRY			label	byte
LOCALE_ILANGUAGE		db	'0',0

LOCALE_SNATIVELANGNAME		label	byte
LOCALE_SABBREVLANGNAME		label	byte
LOCALE_SENGLANGUAGE		label	byte
LOCALE_SLANGUAGE		label	byte

LOCALE_SCOUNTRY			label	byte
LOCALE_SENGCOUNTRY		label	byte
LOCALE_SABBREVCTRYNAME		label	byte
LOCALE_SNATIVECTRYNAME		db	0

LOCALE_IDEFAULTCODEPAGE		label	byte
LOCALE_IDEFAULTANSICODEPAGE	db	'437',0

LOCALE_SDECIMAL			label	byte
LOCALE_SMONDECIMALSEP		label	byte
LOCALE_SLIST			db	',',0
LOCALE_SMONTHOUSANDSEP		label	byte
LOCALE_STHOUSAND		db	'.',0
LOCALE_SMONGROUPING		label	byte
LOCALE_SGROUPING		db	'3',0
LOCALE_IDIGITS			db	'2',0
LOCALE_ICURRDIGITS		label	near
LOCALE_IINTLCURRDIGITS		label	near
LOCALE_SNATIVEDIGITS		db	'0123456789',0
LOCALE_SINTLSYMBOL		label	byte
LOCALE_SCURRENCY		db	'$',0
LOCALE_SDATE			db	'/',0
LOCALE_STIME			db	':',0

LOCALE_SSHORTDATE		db	'yy/mm/dd',0
LOCALE_SLONGDATE		db	'yyyy/mm/dd',0
LOCALE_STIMEFORMAT		db	'hh:mm:ss',0

LOCALE_S1159			db	'AM',0
LOCALE_S2359			db	'PM',0

LOCALE_IFIRSTDAYOFWEEK		label	byte
LOCALE_SABBREVDAYNAME1		label	byte
LOCALE_SDAYNAME1		db	'Monday',0
LOCALE_SABBREVDAYNAME2		label	byte
LOCALE_SDAYNAME2		db	'Tuesday',0
LOCALE_SABBREVDAYNAME3		label	byte
LOCALE_SDAYNAME3		db	'Wednesday',0
LOCALE_SABBREVDAYNAME4		label	byte
LOCALE_SDAYNAME4		db	'Thursday',0
LOCALE_SABBREVDAYNAME5		label	byte
LOCALE_SDAYNAME5		db	'Friday',0
LOCALE_SABBREVDAYNAME6		label	byte
LOCALE_SDAYNAME6		db	'Saturday',0
LOCALE_SABBREVDAYNAME7		label	byte
LOCALE_SDAYNAME7		db	'Sunday',0

LOCALE_SABBREVMONTHNAME1	label	byte
LOCALE_SMONTHNAME1		db	'January',0
LOCALE_SABBREVMONTHNAME2	label	byte
LOCALE_SMONTHNAME2		db	'February',0
LOCALE_SABBREVMONTHNAME3	label	byte
LOCALE_SMONTHNAME3		db	'March',0
LOCALE_SABBREVMONTHNAME4	label	byte
LOCALE_SMONTHNAME4		db	'April',0
LOCALE_SABBREVMONTHNAME5	label	byte
LOCALE_SMONTHNAME5		db	'May',0
LOCALE_SABBREVMONTHNAME6	label	byte
LOCALE_SMONTHNAME6		db	'June',0
LOCALE_SABBREVMONTHNAME7	label	byte
LOCALE_SMONTHNAME7		db	'July',0
LOCALE_SABBREVMONTHNAME8	label	byte
LOCALE_SMONTHNAME8		db	'August',0
LOCALE_SABBREVMONTHNAME9	label	byte
LOCALE_SMONTHNAME9		db	'September',0
LOCALE_SABBREVMONTHNAME10	label	byte
LOCALE_SMONTHNAME10		db	'October',0
LOCALE_SABBREVMONTHNAME11	label	byte
LOCALE_SMONTHNAME11		db	'November',0
LOCALE_SABBREVMONTHNAME12	label	byte
LOCALE_SMONTHNAME12		db	'December',0

.data?

DummyTime		systime	<>

	END
