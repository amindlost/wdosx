
.386
.model flat,C

PUBLIC		getfat

include	dpmi32.inc

EXTRN		__WDOSXRmRegs:RmCallStruc

.code

getfat	proc near

	push	ebx
	push	edi
	mov	eax,[esp+12]
	mov	__WDOSXRmRegs._ah,1ch
	mov	__WDOSXRmRegs._edx,eax
	sub	ecx,ecx
	lea	edi,__WDOSXRmRegs
	mov	bl,21h
	mov	eax,300h
	int	31h
	mov	ebx,ds
	mov	eax,6
	int	31h
	shl	ecx,16
	mov	cx,dx
	pop	edi
	pop	ebx	
	movzx	eax,__WDOSXRmRegs._ds
	shl	eax,4
	movzx	edx,__WDOSXRmRegs._bx
	sub	edx,ecx
	mov	ah,[edx+eax]
	mov	edx,[esp+8]
	mov	al,__WDOSXRmRegs._al
	and	eax,0ffffh
	mov	[edx],eax
	movzx	eax,__WDOSXRmRegs._dx
	mov	[edx+4],edx
	movzx	eax,__WDOSXRmRegs._cx
	mov	[edx+8],eax
	ret

getfat	endp


getfatd	proc near

	push	dword ptr [esp+4]
	push	0
	call	getfat
	add	esp,8
	ret

getfatd	endp

end

