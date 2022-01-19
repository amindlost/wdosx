.386
.model flat,C

PUBLIC		ctrlbrk

; Note that while under plain DOS, WDOSX INT23's will be swallowed by wdosx
; either. So, this function has been implemented as a dummy. The handler you
; provide will never be called. I think this is something we can live with.

.code

OurHandler:

		and	byte ptr [esp+8],0feh
		iretd


ctrlbrk		proc near

		mov	edx,offset OurHandler
		mov	ecx,cs
		mov	eax,0205h
		push	ebx
		mov	bl,23h
		int	31h
		pop	ebx
		sbb	eax,eax
		inc	eax
		ret

ctrlbrk		endp

end
