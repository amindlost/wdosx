.386
.model flat,C

PUBLIC		_bios_serialcom

.code

_bios_serialcom	proc near

	mov	ah,[esp+4]
	mov	edx,[esp+8]
	mov	al,[esp+12]
	int	14h
	movzx	eax,ax
	ret

_bios_serialcom endp

end
