.386
.model flat,C

PUBLIC		getverify
PUBLIC		setverify

.code

getverify proc near

	mov	eax,5400h
	int	21h
	movzx	eax,al
	ret

getverify endp

setverify proc near

	mov	al,[esp+4]
	mov	ah,2eh
	int	21h
	ret

setverify endp

end
