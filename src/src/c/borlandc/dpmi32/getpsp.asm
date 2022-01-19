.386
.model flat,C

PUBLIC		getpsp

.code

getpsp	proc near

	push	ebx
	mov	ah,62h
	int	21h
	movzx	eax,bx
	pop	ebx
	ret

getpsp	endp

end

