.386
.model flat,C

PUBLIC		dosexterr

include	dpmi32.inc

EXTRN		__WDOSXRmRegs:RmCallStruc

.code

dosexterr	proc near

	push	ebx
	push	edi
	mov	__WDOSXRmRegs._ah,59h
	mov	__WDOSXRmRegs._bx,0
	sub	ecx,ecx
	lea	edi,__WDOSXRmRegs
	mov	bl,21h
	mov	eax,300h
	int	31h
	pop	edi
	pop	ebx	
	mov	edx,[esp+4]
	mov	eax,__WDOSXRmRegs._ebx
	mov	[edx+4],ah
	mov	[edx+5],al
	mov	eax,__WDOSXRmRegs._ebx
	mov	[edx+6],ah
	movzx	eax,__WDOSXRmRegs._ax
	mov	[edx],ax
	ret

dosexterr	endp

end
