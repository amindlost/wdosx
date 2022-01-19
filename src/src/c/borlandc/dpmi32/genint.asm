.386
.model flat,C

PUBLIC		_genericInterrupt

.code


_genericInterrupt	proc near

		push	eax
		mov	eax,[esp+8]
		mov	byte ptr ss:[offset PokeHere],al
		pop	eax
		jmp	short ClearQueue

ClearQueue:
		int	0
org $-1
PokeHere	db	?
		ret

_genericInterrupt	endp

end
