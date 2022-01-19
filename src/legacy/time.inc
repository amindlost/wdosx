; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/legacy/TIME.INC 1.1 1999/02/07 18:14:48 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: TIME.INC $
; Revision 1.1  1999/02/07 18:14:48  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
;
; Old floating segment PE code which I'm too lazy to maintain any longer or to
; even comment on. It should stay as is and eventually die.
;

; #### We do not use the Windows FILETIME format who cares about 1601 A.D.? ##

FileTimeToSystemTime:
		mov	ecx,[esp+4]
		mov	edx,[esp+8]
		sub	eax,eax
		mov	al,[ecx+6]
		mov	wMonth[edx],ax
		mov	al,[ecx+5]
		mov	wDay[edx],ax
		mov	al,[ecx+4]
		mov	wDayOfWeek[edx],ax
		mov	al,[ecx+3]
		mov	wHour[edx],ax
		mov	al,[ecx+2]
		mov	wMinute[edx],ax
		mov	al,[ecx+1]
		mov	wSecond[edx],ax
		mov	al,[ecx]
		shl	eax,4
		mov	wMilliseconds[edx],ax
		sub	eax,eax
		mov	al,[ecx+7]
		add	eax,1980
		mov	wYear[edx],ax
		mov	eax,1
		retn	8

; ############################################################################

SystemTimeToFileTime:
		mov	ecx,[esp+4]
		movzx	eax,wHour[ecx]
		mov	edx,eax
		shl	edx,8
		movzx	eax,wMinute[ecx]
		mov	dl,al
		shl	edx,8
		movzx	eax,wSecond[ecx]
		mov	dl,al
		shl	edx,8
		movzx	eax,wMilliseconds[ecx]
		shr	eax,4
		mov	dl,al
		mov	eax,[esp+8]
		mov	[eax],edx
		movzx	eax,wYear[ecx]
		sub	eax,1980
		mov	dl,al
		shl	edx,8
		movzx	eax,wMonth[ecx]
		mov	dl,al
		shl	edx,8
		movzx	eax,wDay[ecx]
		mov	dl,al
		shl	edx,8
		movzx	eax,wDayOfWeek[ecx]
		mov	dl,al
		mov	eax,[esp+8]	
		mov	[eax+4],edx
		mov	eax,1
		retn	8

; ############################################################################

FileTimeToDosDateTime:
		mov	ecx,[esp+4]
		mov	edx,[esp+8]
		mov	al,[ecx+7]
		mov	[edx+1],al
		mov	ax,[ecx+5]
		shl	ah,5
		or	al,ah
		mov	[edx],al
		mov	edx,[esp+12]
		mov	ah,[ecx+3]
		mov	al,[ecx+2]
		shl	al,2
		shl	eax,3
		mov	[edx+1],ah
		mov	ax,[ecx+1]
		shr	al,1
		shl	ah,5
		or	al,ah
		mov	[edx],al
		mov	eax,1
		retn	12

; ############################################################################

DosDateTimeToFileTime:
		mov	edx,[esp+12]
		mov	byte ptr [edx],0
		mov	eax,[esp+8]
		add	eax,eax
		and	al,3fh
		mov	[edx+1],al
		mov	eax,[esp+8]
		shr	eax,5
		and	al,3fh
		mov	[edx+2],al
		mov	eax,[esp+8]
		shr	eax,11
		and	al,1fh
		mov	[edx+3],al
		mov	eax,[esp+4]
		and	al,1fh
		mov	[edx+5],al
		mov	eax,[esp+4]
		shr	eax,5
		and	al,0fh
		mov	[edx+6],al
		mov	eax,[esp+4]
		shr	eax,9
		and	al,7fh
		mov	[edx+7],al
		mov	eax,1
		retn	12

; ############################################################################

GetFileTime:
		push	ebx
		mov	ebx,[esp+8]
		mov	eax,5700h
		int	21h
		jc	short @@gft00
		movzx	ecx,cx
		movzx	edx,dx
		sub	esp,8
		push	esp
		push	ecx
		push	edx
		call	DosDateTimeToFileTime
		pop	eax
		pop	edx
		mov	ecx,[esp+12]
		test	ecx,ecx
		jz	short @@gft01
		mov	[ecx],eax
		mov	[ecx+4],edx
@@gft01:	mov	ecx,[esp+16]
		test	ecx,ecx
		jz	short @@gft02
		mov	[ecx],eax
		mov	[ecx+4],edx
@@gft02:	mov	ecx,[esp+20]
		test	ecx,ecx
		jz	short @@gft03
		mov	[ecx],eax
		mov	[ecx+4],edx
@@gft03:
		mov	eax,1
		jmp	short @@gft04
@@gft00:
		mov	LastError,eax
		sub	eax,eax
@@gft04:
		pop	ebx
		retn	16

; ############################################################################

SetFileTime:
		push	ebx
		mov	ebx,[esp+8]
		mov	ecx,[esp+20]
		test	ecx,ecx
		jnz	short @@sft00
@@sft01:
		pop	ebx
		mov	eax,1
		retn	16
@@sft00:
		sub	esp,8
		push	esp
		lea	eax,[esp+8]
		push	eax
		push	ecx
		call	FileTimeToDosDateTime
		pop	ecx
		pop	edx
		mov	eax,5701h
		int	21h
		jnc	short @@sft01
		mov	LastError,eax
		sub	eax,eax
		pop	ebx
		retn	16

; ############################################################################
