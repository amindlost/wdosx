.386
.model flat,C

PUBLIC		_bios_printer

.code

_bios_printer	proc near

	mov	ah,[esp+4]
	mov	edx,[esp+8]
	mov	al,[esp+12]
	int	17h
	movzx	eax,ah
	ret

_bios_printer	endp

end

