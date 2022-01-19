; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/deb/SLIB.ASM 1.2 1999/02/07 20:17:34 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: SLIB.ASM $
; Revision 1.2  1999/02/07 20:17:34  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:14:05  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
DEBUG = 0
; replacements for the stdlib functions needed

	.386p
	model flat,C
_TEXT	segment dword public use32 'CODE'
_TEXT	ends
_DATA	segment dword public use32 'DATA'
_DATA	ends
_BSS	segment dword public use32 'BSS'
_BSS	ends
DGROUP	group	_BSS,_DATA
_TEXT	segment dword public use32 'CODE'

public strncpy
public sprintf

;------ strncpy -------------------------------

strncpy	proc uses edi esi ecx
arg dest:dword,src:dword,size_t:dword
	mov	esi,src
	mov	edi,dest
	mov	ecx,size_t
	cld
	rep	movsb
	sub	eax,eax
	mov	edi,dest
	mov	ecx,size_t
	repne	scasb
	rep	stosb
	mov	eax,dest
	ret
strncpy endp

;------ sprintf - not really the complete thing -------

sprintf	proc uses edi esi ebx edx ecx
arg buffer:dword,format:dword
local bytes_written:dword
	lea	ebx,[format+4]
	mov	esi,format
	mov	edi,buffer
IF DEBUG
	push	esi
@@dd01:
	mov	dl,[esi]
	inc	esi
	test	dl,dl
	jz	@@dd00
	mov	ah,2
	int	21h
	jmp	@@dd01
@@dd00:
	mov	dl,0dh
	mov	ah,2
	int	21h
	mov	dl,0ah
	mov	ah,2
	int	21h
	pop	esi
ENDIF

	cld
@@next:
	lodsb
	cmp	al,'%'
	jnz	@@noarg
	lodsb
	cmp	al,'%'
	jnz	@@nopr
	stosb
	jmp	@@next
@@nopr:
	cmp	al,'c'
	jnz	@@nochr
	mov	al,[ebx]
	add	ebx,4
	stosb
	jmp	@@next
@@nochr:
	cmp	al,'s'
	jnz	@@nostr
	push	esi
	mov	esi,[ebx]
	add	ebx,4
@@nextchar:
	lodsb
	test	al,al
	jz	@@strdone
	stosb
	jmp	@@nextchar
@@strdone:
	pop	esi
	jmp	@@next

@@nostr:
	cmp	al,'l'
	jz	@@dolong
	cmp	al,'d'
;this code shows that we do not really want the entire sprintf
	jnz	@@done
	mov	eax,[ebx]
	add	ebx,4
	test	eax,eax
	jns	@@noneg
	neg	eax
	mov	byte ptr [edi],'-'
	inc	edi
@@noneg:
	push	ebx
	mov	ebx,10
	call	nextdig
	pop	ebx
	jmp	@@next	

nextdig label	near

	xor	edx,edx
	div	ebx
	test	eax,eax
	push	edx
	jz	@@all
	call	nextdig
@@all:
	pop	eax
	add	al,30h
	stosb
	retn

@@dolong:
	lodsb
	cmp	al,'x'
	jnz	@@done
	mov	edx,[ebx]
	add	ebx,4
	mov	ecx,8
	push	ebx
	sub	ebx,ebx
@@nexthex:
	rol	edx,4
	mov	eax,edx
	and	al,0fh
	add	al,30h
	cmp	al,3ah
	sbb	ah,ah
	xor	ah,0ffh
	and	ah,7
	add	al,ah
;nuke leading zeros
	cmp	al,31h
	sbb	bh,bh
	xor	bh,0ffh
	or	bl,bh
	jz	@@nhdloop
	stosb
@@nhdloop:
	loop	@@nexthex
	test	edx,edx
	pop	ebx
	jnz	@@next
	mov	al,30h
	stosb
	jmp	@@next
@@noarg:
	test	al,al
	jz	@@done
	stosb
	jmp	@@next

@@done:
	mov	eax,edi
	sub	eax,buffer
	ret
sprintf	endp

;------------------------------------------------------

_TEXT	ends
	end
