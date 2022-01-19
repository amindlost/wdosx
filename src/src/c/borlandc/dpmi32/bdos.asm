.386
.model flat,C

PUBLIC		bdos

.code

bdos	proc near

	sub	eax,eax
	mov	ah,[esp+4]
	mov	edx,[esp+8]
	mov	al,[esp+12]
	int	21h
	ret

bdos	endp

end

