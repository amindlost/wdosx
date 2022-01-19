.386
.model flat,C

include	dpmi32.inc

EXTRN		__WDOSXRmRegs:RmCallStruc

PUBLIC		country

.code

country	proc near

	; allocate a small DOS memory block

	mov	eax,100h
	push	ebx
	mov	ebx,3
	int	31h
	pop	ebx
	jc	short Error

	mov	__WDOSXRmRegs._ds,ax
	mov	__WDOSXRmRegs._dx,0

	mov	ah,38h
	mov	al,[esp+4]
	mov	__WDOSXRmRegs._eax,eax
	push	ebx
	push	edi
	lea	edi,__WDOSXRmRegs
	mov	bl,21h
	sub	ecx,ecx
	mov	eax,300h
	int	31h
	pop	edi
	pop	ebx
	jc	short Error1
	test	byte ptr [__WDOSXRmRegs._flags],1
	jnz	short Error1	
	push	gs
	mov	gs,edx
	mov	eax,[esp+12]
	mov	ecx,8
@@00:
	mov	edx,gs:[ecx*4-4]
	mov	[eax+ecx*4-4],edx
	loop	short @@00

	mov	edx,gs
	mov	eax,0101h
	int	31h
	pop	gs
	mov	eax,[esp+8]
	ret
Error1:
	mov	eax,0101h
	int	31h
Error:
	sub	eax,eax
	ret

country	endp

end
