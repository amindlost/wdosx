.386
.model flat,C

PUBLIC		inport
PUBLIC		inportb
PUBLIC		inpw
PUBLIC		inp

; This one runs circles around Borland's implementation
; If speed really is a concern, alter the declarations in <dos.h> to fastcall.
; This code must be changed too, then.

.code

inport	proc near

inpw:
	mov	edx,[esp+4]
	sub	eax,eax
	in	ax,dx
	ret

inport	endp

inportb	proc near

inp:
	mov	edx,[esp+4]
	sub	eax,eax
	in	al,dx
	ret

inportb	endp

end
