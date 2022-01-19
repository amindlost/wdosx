.386
.model flat,C

EXTRN		_genericInterrupt:NEAR
EXTRN		_doserrno:DWORD
EXTRN		errno:DWORD
EXTRN		segread:NEAR

PUBLIC		int386
PUBLIC		int386x

; Note that the Borland routine had a bug that made it impossible to
; pass another DS: selector. Second one is that esi is not preserved upon
; return from the interrupt. The replacement code does not suffer from this.

.code

int386	proc near

	sub	esp,12
	push	esp
	call	segread
	push	dword ptr [esp+32]
	push	dword ptr [esp+32]
	push	dword ptr [esp+32]
	call	int386x
	add	esp,16
	ret

int386	endp

int386x	proc near

	push	ebp
	push	ebx
	push	esi
	push	edi

	push	ds
	push	es
	push	fs
	push	gs

	mov	ebp,[esp+12+32]
	mov	es,word ptr [ebp]
	mov	ds,word ptr [ebp+6]
	mov	fs,word ptr [ebp+8]
	mov	gs,word ptr [ebp+10]
	mov	ebp,[esp+8+32]
	mov	eax,[ebp]
	mov	ebx,[ebp+4]
	mov	ecx,[ebp+8]
	mov	edx,[ebp+12]
	mov	esi,[ebp+16]
	mov	edi,[ebp+20]

	clc
	push	dword ptr [esp+4+32]

	call	_genericInterrupt

	mov	ebp,[esp+12+32+4]
	mov	[ebp],eax
	mov	[ebp+4],ebx
	mov	[ebp+8],ecx
	mov	[ebp+12],edx
	mov	[ebp+16],esi
	mov	[ebp+20],edi

	pushfd
	pop	edx
	mov	[ebp+28],edx
	and	edx,1
	mov	[ebp+28],edx

	add	esp,4

	mov	ebp,[esp+16+32]

	mov	word ptr [ebp],es
	mov	word ptr [ebp+6],ds
	mov	word ptr [ebp+8],fs
	mov	word ptr [ebp+10],gs

	pop	gs
	pop	fs
	pop	es
	pop	ds

	; this is stupid, but your program may rely on this behaviour:

	test	eax,eax
	jnz	short SkipErr

	mov	_doserrno,eax
	mov	errno,eax

SkipErr:
	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret

int386x	endp

end
