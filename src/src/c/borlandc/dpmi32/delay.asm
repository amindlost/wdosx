.386
.model flat,C

PUBLIC		delay

.code

delay	proc near

	mov	edx,[esp+4]
	shl	edx,10
	shld	ecx,edx,16
	mov	ah,86h
	int	15h
	ret

delay	endp

end

