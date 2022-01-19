.386
.model flat,C

PUBLIC		getdta

; the current version of WDOSX (0.93) does not support an extended 21/2f yet
; Don't use this one with WDOSX 0.93. I'm sure 0.94 will have support
; added.
; The DTA is in the real mode region at psp:[80h].

.code

getdta	proc near

	push	ebx
	mov	ah,2Fh
	int	21h
	mov	eax,ebx
	pop	ebx
	ret

getdta	endp

end

