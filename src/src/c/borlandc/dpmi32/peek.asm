.386
.model flat,C

PUBLIC		peek
PUBLIC		peekb

.code

peek	proc near

	push	ds
	mov	ds,[esp+4]
	mov	edx,[esp+8]
	mov	eax,[edx]
	pop	ds
	ret

peek	endp

peekb	proc near

	push	ds
	mov	ds,[esp+4]
	mov	edx,[esp+8]
	sub	eax,eax
	mov	al,[edx]
	pop	ds
	ret

peekb	endp

end
