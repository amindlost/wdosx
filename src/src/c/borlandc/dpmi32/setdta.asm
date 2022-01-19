.386
.model flat,C

PUBLIC		setdta

; Not supported in 0.93 yet, don't use until 0.94 is out!
; Use the default DTA at psp:[80h] instead.

.code

setdta	proc near

	mov	ah,1Ah
	mov	edx,[esp+4]
	int	21h
	ret

setdta	endp

end
