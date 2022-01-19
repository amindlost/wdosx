.386
.model flat,C

PUBLIC		sound
PUBLIC		nosound

.code

sound	proc near

	movzx	ecx,word ptr [esp+4]
	cmp	ecx,18
	jna	@@00
	mov	eax,1193180
	sub	edx,edx
	div	ecx
	mov	ecx,eax
	mov	al,182
	out	43h,al
	mov	al,cl
	out	42h,al
	mov	al,ch
	out	42h,al
	in	al,61h
	or	al,3
	out	61h,al
@@00:
	ret

sound	endp

nosound	proc near

	in	al,61h
	and	al,0fch
	out	061h,al
	ret

nosound	endp

end

