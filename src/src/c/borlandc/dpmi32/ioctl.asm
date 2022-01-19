.386
.model flat,C

	EXTRN		__IOerror:NEAR

	include dpmi32.inc
	EXTRN		__WDOSXRmRegs:RmCallStruc

	PUBLIC		ioctl

.code

ioctl	proc near

	mov	eax,[esp+8]
	mov	ah,44h
	cmp	al,2
	jc	Simple
	cmp	al,6
	jnc	Simple

	mov	__WDOSXRmRegs._eax,eax

	; allocate a small DOS memory block

	mov	eax,100h
	push	ebx
	mov	ebx,[esp+20]
	add	ebx,15
	shr	ebx,4
	int	31h
	pop	ebx
	jc	Error

	mov	__WDOSXRmRegs._ds,ax
	mov	__WDOSXRmRegs._dx,0

	test	__WDOSXRmRegs._al,1
	jz	@@nowrite

	push	gs
	mov	gs,edx
	mov	eax,[esp+16]
	mov	ecx,[esp+20]
@@00:
	mov	dl,[eax+ecx-1]
	mov	gs:[ecx-1],dl
	loop	short @@00
	mov	edx,gs
	pop	gs

@@nowrite:
	mov	eax,[esp+4]
	mov	__WDOSXRmRegs._ebx,eax
	mov	eax,[esp+16]
	mov	__WDOSXRmRegs._ecx,eax
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

	test	__WDOSXRmRegs._al,1
	jnz	@@notread

	push	gs
	mov	gs,edx
	mov	eax,[esp+16]
	mov	ecx,[esp+20]
@@01:
	mov	dl,gs:[ecx-1]
	mov	[eax+ecx-1],dl
	loop	short @@01

	mov	edx,gs
	pop	gs

@@notread:
	mov	eax,0101h
	int	31h
	mov	eax,__WDOSXRmRegs._eax
	ret
Error1:
	mov	eax,0101h
	int	31h
Error:
	mov	eax,-1
	ret

Simple:
	push	ebx
	mov	ebx,[esp+8]
	cmp	al,1
	jnz	short @@02
	mov	edx,[esp+20]
@@02:
	push	eax
	int	21h
	pop	ecx
	pop	ebx

	; 2do: set error information

	jc	Error
	cmp	cl,6
	jc	@@03
	movsx	eax,al
	ret
@@03:
	movzx	eax,dx
	ret

ioctl	endp

end
