;----------------------------------------------------------------------------
; Configuration parameters
;
NUM_INTERRUPT_STACKS = 4
INTERRUPT_STACK_SIZE = 1000h

;----------------------------------------------------------------------------
; TASM red tape
;
.386
.model flat
.code

	PUBLICDLL	SetIRQHandler
	PUBLICDLL	GetIRQHandler

SIZE_OF_ENTRY	EQU	((OFFSET __entryEnd - OFFSET __entryStart) SHR 4)
SIZE_OF_WRAPPER	EQU	((OFFSET __wrapperEnd - OFFSET __wrapperStart) SHR 4)

;+---------------------------------------------------------------------------
; DLL Entry point
;
DllMain PROC NEAR
	pushad
	mov	DataSelector, ds
	mov	TIBSelector, fs
	mov	ebx, 8
	mov	edi, OFFSET __wrapperStart
	mov	esi, OFFSET __entryStart

@@getSetLoop:
	mov	eax, 0204h
	int	31h
	mov	[edi + SIZE_OF_WRAPPER - 8], edx
	mov	[edi + SIZE_OF_WRAPPER - 4], ecx
	mov	edx, esi
	mov	ecx, cs
	mov	eax, 0205h
	int	31h
	add	esi, SIZE_OF_ENTRY
	add	edi, SIZE_OF_WRAPPER	
	inc	ebx
	cmp	ebx, 78h
	je	@@getSetDone

	cmp	ebx, 16
	jne	@@getSetLoop

	mov	ebx, 70h
	jmp	@@getSetLoop

@@getSetDone:
	popad
	mov	eax, 1
	retn	12
DllMain ENDP

;----------------------------------------------------------------------------
; The actual interrupt glue code
;
EnterInterrupt PROC NEAR
	xchg	ecx, [esp]
	push	eax
	push	edx
	push	gs
	push	fs
	push	es
	push	ds
	mov	ds, DWORD PTR cs:[OFFSET DataSelector]
	mov	fs, TIBSelector
	mov	edx, ss
	mov	eax, esp
	push	ds
	push	ds
	pop	es
	pop	ss
	mov	esp, DWORD PTR [OFFSET IntStackTop]
	sub	DWORD PTR [OFFSET IntStackTop], INTERRUPT_STACK_SIZE
	push	edx
	push	eax
	call	ecx
	cli
	lss	esp, [esp]
	add	DWORD PTR [OFFSET IntStackTop], INTERRUPT_STACK_SIZE
	pop	ds
	pop	es
	pop	fs
	pop	gs
	pop	edx
	pop	eax
	pop	ecx
	iretd
EnterInterrupt ENDP

;----------------------------------------------------------------------------
; Standard Interrupt entry points
;
__entryStart LABEL NEAR
i = 0
REPT 16
IrqEntry CATSTR <Irq>,%i,<Entry>
IrqEntry LABEL NEAR
	call	EnterInterrupt
	jmp	DWORD PTR [OFFSET HandlerArray + i * 4]
	i = i + 1
ENDM
__entryEnd LABEL NEAR

;----------------------------------------------------------------------------
; NEAR callable irq handler entries with IRET stackframe
;
__wrapperStart LABEL NEAR
i = 0
REPT 16
	xchg	eax, [esp]
	push	eax
	push	eax
	pushfd
	pop	eax
	xchg	[esp + 8], eax
	mov	[esp + 4], cs
	db	0EAh
	dd	?
	dd	?
	i = i + 1
ENDM
__wrapperEnd LABEL NEAR

;+----------------------------------------------------------------------------
; GetIrqHandler
;
GetIrqHandler PROC NEAR
	mov	eax, [esp + 4]
	mov	eax, [eax * 4 + OFFSET HandlerArray]
	retn	4
GetIrqHandler ENDP

;+----------------------------------------------------------------------------
; SetIrqHandler
;
SetIrqHandler PROC NEAR
	mov	edx, [esp + 4]
	mov	eax, [esp + 8]
	mov	[edx * 4 + OFFSET HandlerArray], eax
	retn	8
SetIrqHandler ENDP

.data

HandlerArray LABEL DWORD
i = 0
REPT 16
	dd	OFFSET __wrapperStart + i * SIZE_OF_WRAPPER
	i = i + 1
ENDM

IntStackTop	dd	OFFSET TheTopOfStack

.data?
DataSelector	dd	?
TIBSelector	dd	?
		db	NUM_INTERRUPT_STACKS * INTERRUPT_STACK_SIZE DUP (?)
TheTopOfStack	LABEL	DWORD

END	DllMain
