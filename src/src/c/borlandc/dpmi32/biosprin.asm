.386
.model flat,C

PUBLIC		biosprint

.code

biosprint	proc near

	mov	ah,[esp+4]
	mov	al,[esp+8]
	mov	dx,[esp+12]
	int	17h
	movzx	eax,ah
	ret

biosprint	endp

end
