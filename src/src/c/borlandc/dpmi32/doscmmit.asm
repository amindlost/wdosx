.386
.model flat,C

PUBLIC		_dos_commit

.code

_dos_commit	proc near

	mov	ah,0dh
	int	21h
	sub	eax,eax
	ret

_dos_commit	endp

end
