.386
.model flat,C

EXTRN		__IOerror:NEAR

PUBLIC		bdosptr

.code

bdosptr	proc near

	sub	eax,eax
	mov	ah,[esp+4]
	mov	edx,[esp+8]
	mov	al,[esp+12]
	clc
	int	21h
	jc	short BdosErr
	ret

BdosErr:
	push	eax
	call	__IOerror
	pop	eax
	ret

bdosptr	endp

end
