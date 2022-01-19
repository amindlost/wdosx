; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/legacy/RESRC.INC 1.1 1999/02/07 18:14:11 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: RESRC.INC $
; Revision 1.1  1999/02/07 18:14:11  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
;
; Old floating segment PE code which I'm too lazy to maintain any longer or to
; even comment on. It should stay as is and eventually die.
;


; ############################################################################
; ## functions dealing with resources                                       ##
; ############################################################################

; void _stdcall *GetResource(unsigned long TYID, unsigned long NID);
; since the API emulator does not have language support, we take the first
; entry found.

GetResource	proc	near

		; Get start of resource section

		mov	edx,ImageBase
		mov	edx,[edx+88h]
		add	edx,rva2offset
		push	edx
		cmp	edx,rva2offset
		jz	@@gresError

		; get named entries to skip

		mov	eax,[edx+12]
		mov	ecx,[edx+12]
		shr	ecx,16
		and	eax,0ffffh
		lea	edx,[edx+eax*8+16]
		
		; edx = first Type ID entry

		jecxz	short @@gresError
@@gresTypeLoop:
		mov	eax,[edx]
		cmp	eax,[esp+8]
		jz	short @@gresTypeOk
		add	edx,8
		loop	short @@gresTypeLoop
		jmp	short @@gresError
@@gresTypeOk:
		mov	eax,[edx+4]
		add	eax,[esp]
		jns	@@gresDone

		; eax bit 30..0 pointing to sub directory now

		mov	edx,[eax+12-80000000h]
		mov	ecx,[eax+12-80000000h]
		shr	ecx,16
		and	edx,0ffffh
		lea	edx,[eax+edx*8+16-80000000h]

		jecxz	short @@gresError
@@gresNameLoop:
		mov	eax,[edx]
		cmp	eax,[esp+12]
		jz	short @@gresNameOk
		add	edx,8
		loop	short @@gresNameLoop
		jmp	short @@gresError
@@gresNameOk:
		mov	eax,[edx+4]
		add	eax,[esp]
		jns	short @@gresDone

		; the entry may exist for different languages
		; we just take the first one, who cares...

		cmp	dword ptr [eax+12-80000000h],0
		mov	eax,[eax+20-80000000h]
		jnz	short @@gresDone
@@gresError:
		sub	eax,eax
		sub	eax,[esp]
@@gresDone:
		pop	edx
		add	eax,edx
		retn	8
GetResource	endp

; ############################################################################

LoadStringA:
		push	0
		call	GetModuleHandleA
		cmp	dword ptr [esp+4],eax
		jnz	@@lsaError

		; the next is guesswork:

		mov	eax,[esp+8]
		add	eax,16
		push	eax
		shr	dword ptr [esp],4
		and	eax,0fh
		mov	[esp+12],eax
		push	6
		call	GetResource
		test	eax,eax
		jz	@@lsaError

		; eax -> resource data entry
		; [esp+8] number of strings to skip

		sub	ecx,ecx
		mov	edx,[eax]
		add	edx,rva2offset
@@lsaStrLoop:
		dec	dword ptr [esp+8]
		mov	cx,[edx]
		js	short @@lsaIsStr
		lea	edx,[edx+ecx*2+2]
		jmp	short @@lsaStrLoop
@@lsaIsStr:

		; edx -> wide char string
		; ecx = size in wide chars

		cmp	ecx,[esp+16]
		jc	short @@lsaSizeOk
		mov	ecx,[esp+16]
		test	ecx,ecx
		jz	short @@lsaError
		dec	ecx
@@lsaSizeOk:
		jecxz	@@lsaError
		mov	[esp+16],ecx
		push	ecx		
		mov	ecx,[esp+16]
@@lsaLoop:
		add	edx,2
		mov	al,[edx]
		mov	[ecx],al
		inc	ecx
		dec	dword ptr [esp+20]
		jnz	@@lsaLoop
		mov	byte ptr [ecx],0
		pop	eax
		retn	16
@@lsaError:
		sub	eax,eax
		retn	16

; ############################################################################