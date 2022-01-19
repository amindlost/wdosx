.386
.model flat,C

PUBLIC		bioskey

.code

bioskey	proc near

	sub	eax,eax
	mov	ah,[esp+4]
	int	16h
	jz	short @@02
	test	byte ptr [esp+4],1
	jnz	short @@00
	ret
@@00:
	cmp	eax,1
@@01:
	sbb	edx,edx
	or	eax,edx
	ret
@@02:
	test	byte ptr [esp+4],1
	jnz	short @@01
	ret

bioskey	endp

end
