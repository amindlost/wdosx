.386
.model flat,C

PUBLIC		getcbrk
PUBLIC		setcbrk

.code

getcbrk	proc near

	mov	eax,3300h
	int	21h
	sub	eax,eax
	mov	al,dl
	ret

getcbrk	endp

setcbrk	proc near

	mov	eax,3301h
	mov	dl,[esp+4]
	int	21h
	sub	eax,eax
	mov	al,dl
	ret

setcbrk	endp

end
