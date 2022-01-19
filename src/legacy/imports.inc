; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/legacy/IMPORTS.INC 1.1 1999/02/07 18:13:46 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: IMPORTS.INC $
; Revision 1.1  1999/02/07 18:13:46  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
;
; Old floating segment PE code which I'm too lazy to maintain any longer or to
; even comment on. It should stay as is and eventually die.
;


; routines needed processing Win32 API imports

output0string	proc	near
		; print a 0 terminated string to stdout, add a CRLF
		push	edx
		push	ecx
		push	eax
		mov	ecx,[esp+16]
		sub	edx,edx
@@ocstr00:
		mov	ah,2
		mov	dl,[ecx]
		test	dl,dl
		jz	@@ocstr01
		cmp	dl,0ah
		jnz	@@ocstr02
		cmp	dh,0dh
		jz	@@ocstr02
		mov	dl,0dh
		int	21h
		mov	dl,0ah
		mov	ah,2
@@ocstr02:
		inc	ecx
		int	21h
		mov	dh, dl
		jmp	@@ocstr00
@@ocstr01:
		mov	dl,0dh
		mov	ah,2
		int	21h
		mov	dl,0ah
		mov	ah,2
		int	21h
		pop	eax
		pop	ecx
		pop	edx
		retn 4
output0string	endp

;-----------------------------------------------------------------------------

compare_string	proc	near
		push	edi
		push	esi
		sub	eax,eax

cs_getnext:
		mov	al,[esi]
		inc	edi
		inc	esi
		test	al,al
		jz	short cs_done
		cmp	al,[edi-1]
		jz	short cs_getnext

cs_done:
		pop	esi
		pop	edi
		ret
compare_string	endp

;-----------------------------------------------------------------------------

parse_import	proc

; ->	edx = offset table, esi=^function name
; returns: eax=0 if error or proc address 
; 2do: speedup by making use of the fact that strings are sorted

		sub	eax,eax
		push	edi
		push	edx

import_next:
		mov	edi,[edx+4]
		call	compare_string
		test	eax,eax
		jz	short import_end
		add	edx,8
		cmp	dword ptr [edx],0
		jnz	short import_next

import_end:
		mov	eax,[edx]
		pop	edx
		pop	edi
		ret
parse_import	endp

;-----------------------------------------------------------------------------

process_imports	proc	near

		; get rva of .idata

		mov	ebp,imagebase
		mov	ebp,dword ptr [80h+ebp]

		; convert to offset

		add	ebp,rva2offset
		mov	edx,offset k32dll

do_import_descriptor:

		; check if last in chain

		cmp	dword ptr [ebp+12],0	;no dll name?
		jz	short ready2launch	;last entry
		mov	ebx,[ebp+16]		;rva import_lookup_table
		add	ebx,rva2offset

get_next_import:
		mov	esi,[ebx]
		test	esi,esi
		js	import_error		;import by number!
		jnz	short is_string
		add	ebp,20
		jmp	short do_import_descriptor

is_string:
		add	esi,rva2offset
		add	esi,2			;ignore hint
		call	parse_import
		test	eax,eax
		jz	todo_error
		mov	[ebx],eax
		add	ebx,4
		jmp	short get_next_import

ready2launch:
		ret
process_imports	endp
