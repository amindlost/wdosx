.386
.model flat,C

PUBLIC		_bios_equiplist
PUBLIC		_bios_memsize
PUBLIC		_bios_timeofday

.code

_bios_equiplist	proc near

	sub	eax,eax
	int	11h
	ret

_bios_equiplist	endp

_bios_memsize	proc near

	sub	eax,eax
	int	12h
	ret

_bios_memsize	endp

_bios_timeofday	proc near

	mov	edx,[esp+8]
	mov	edx,[edx]
	shld	ecx,edx,16
	sub	eax,eax
	mov	ah,[esp+4]
	int	1ah
	cmp	byte ptr [esp+4],0
	jnz	@@00
	shl	edx,16
	shld	ecx,edx,16
	mov	edx,[esp+8]
	mov	[edx],ecx
@@00:
	ret

_bios_timeofday	endp

end
