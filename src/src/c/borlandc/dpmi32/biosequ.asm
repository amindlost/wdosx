.386
.model flat,C

PUBLIC		biosequip
PUBLIC		biosmemory
PUBLIC		biostime

.code

biosequip	proc near
	sub	eax,eax
	int	11h
	ret
biosequip	endp


biosmemory	proc near

	sub	eax,eax
	int	12h
	ret

biosmemory	endp

biostime	proc near

	mov	ah,[esp+4]
	mov	edx,[esp+8]
	shld	ecx,edx,16
	int	1Ah
	shrd	eax,edx,16
	shrd	eax,ecx,16
	ret

biostime	endp

end

