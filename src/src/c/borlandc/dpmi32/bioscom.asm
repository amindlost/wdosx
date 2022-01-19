.386
.model flat,C

PUBLIC		bioscom

.code

bioscom	proc near

	sub	eax,eax
	mov	ah,[esp+4]
	mov	al,[esp+8]
	mov	edx,[esp+12]
	int	14h
	ret

bioscom	endp

end
