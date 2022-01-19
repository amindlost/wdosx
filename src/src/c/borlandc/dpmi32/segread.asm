.386
.model flat,C

PUBLIC		segread

.code

segread	proc	near

	mov	eax,[esp+4]
	mov	word ptr [eax],es
	mov	word ptr [eax+2],cs
	mov	word ptr [eax+4],ss
	mov	word ptr [eax+6],ds
	mov	word ptr [eax+8],fs
	mov	word ptr [eax+10],gs
	ret

segread	endp

end
