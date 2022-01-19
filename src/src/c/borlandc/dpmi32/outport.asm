.386
.model flat,C

PUBLIC		outport
PUBLIC		outportb
PUBLIC		outpw
PUBLIC		outp

.code

outport		proc near

outpw:
	mov	edx,[esp+4]
	mov	eax,[esp+8]
	out	dx,ax
	ret

outport		endp

outportb	proc near

outp:
	mov	edx,[esp+4]
	mov	eax,[esp+8]
	out	dx,al
	ret

outportb	endp

end
