.386
.model flat,C

PUBLIC		poke
PUBLIC		pokeb

.code

poke	proc near

	push	ds
	mov	edx,[esp+8]
	mov	eax,[esp+12]
	mov	ds,[esp+4]
	mov	[edx],eax
	pop	ds
	ret

poke	endp

pokeb	proc near

	push	ds
	mov	edx,[esp+8]
	mov	eax,[esp+12]
	mov	ds,[esp+4]
	mov	[edx],al
	pop	ds
	ret

pokeb	endp

end
