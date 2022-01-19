.386
.model flat,C

PUBLIC		coreleft

.code

coreleft	proc near

	push	edi
	sub	esp,32
	mov	edi,esp
	mov	eax,500h
	int	31h
	pop	eax
	add	esp,28
	pop	edi
	ret

coreleft	endp

end
