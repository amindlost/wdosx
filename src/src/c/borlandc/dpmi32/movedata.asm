.386
.model flat,C

PUBLIC		movedata

.code

movedata	proc near

	push	ds
	push	es
	push	esi
	push	edi
	cld
	mov	ecx,[esp+20+16]
	mov	esi,[esp+8+16]
	mov	edi,[esp+16+16]
	mov	es,dword ptr [esp+12+16]
	mov	ds,dword ptr [esp+4+16]
	shr	ecx,2
	rep	movsd
	xor	ecx,3
	and	ecx,[esp+20+16]
	rep	movsb
	pop	edi
	pop	esi
	pop	es
	pop	ds
	ret

movedata	endp

end
