; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/legacy/EXCEPT.INC 1.1 1999/02/07 18:13:24 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: EXCEPT.INC $
; Revision 1.1  1999/02/07 18:13:24  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
;
; Old floating segment PE code which I'm too lazy to maintain any longer or to
; even comment on. It should stay as is and eventually die.
;

; ############################################################################
; ## Structured exception handling in win32 - mostly guesswork              ##
; ############################################################################

; ############ Exception handler declaration #################################

; int EHandler(ExceptionRecord *pERec, ExceptionFrame *pEFrame,
;              ContextRecord *pCntx, DispatchRecord *pDisp)
; RETURNS: 1 if exception has been handled, 0 if not

; FS:[0] ( TIB ) = pointer to topmost DispatchRecord, -1 if none


; ####### RETURN VALUE OF THE EXCEPTION HANDLER ##############################

XCPT_CONTINUE_EXECUTION		EQU	0
XCPT_CONTINUE_SEARCH		EQU	1


; ####### EXCEPTION TYPES ####################################################

STATUS_BREAKPOINT		equ	080000003h
STATUS_SINGLE_STEP		equ	080000004h
STATUS_ACCESS_VIOLATION		equ	0C0000005h
STATUS_NO_MEMORY		equ	0C0000017h
STATUS_ILLEGAL_INSTRUCTION      equ	0C000001Dh
STATUS_NONCONTINUABLE_EXCEPTION	equ	0C0000025h
STATUS_ARRAY_BOUNDS_EXCEEDED	equ	0C000008Ch
STATUS_INTEGER_DIVIDE_BY_ZERO	equ	0C0000094h
STATUS_INTEGER_OVERFLOW		equ	0C0000095h
STATUS_PRIVILEGED_INSTRUCTION	equ	0C0000096h
STATUS_STACK_OVERFLOW		equ	0C00000FDh
STATUS_CONTROL_C_EXIT		equ	0C000013Ah
STATUS_FLOAT_DENORMAL_OPERAND   equ   	0C000008Dh
STATUS_FLOAT_DIVIDE_BY_ZERO     equ	0C000008Eh
STATUS_FLOAT_INEXACT_RESULT	equ	0C000008Fh
STATUS_FLOAT_INVALID_OPERATION	equ	0C0000090h
STATUS_FLOAT_OVERFLOW		equ	0C0000091h
STATUS_FLOAT_STACK_CHECK	equ	0C0000092h
STATUS_FLOAT_UNDERFLOW		equ	0C0000093h
STATUS_INTEGER_DIVIDE_BY_ZERO	equ	0C0000094h


; ####### context flags ######################################################

CONTEXT_X86			equ	10000h
CONTEXT_CONTROL			equ	1
CONTEXT_INTEGER			equ	2
CONTEXT_SEGMENTS		equ	4
CONTEXT_FPU			equ	8
CONTEXT_DREGS			equ	10h

; ####### X86 context record #################################################
; we don't return FPU and DR0-7 information

OUR_CNT	equ	CONTEXT_X86+CONTEXT_CONTROL+CONTEXT_INTEGER+CONTEXT_SEGMENTS

ContextRecord		struc
			ContextFlags	dd ?
			DRSpace		dd 8 dup (?)	; not filled
			FPUSpace	dd 28 dup (?)	; not filled
			CntSegGs	dd ?
			CntSegFs	dd ?
			CntSegEs	dd ?
			CntSegDs	dd ?
			CntEdi		dd ?
			CntEsi		dd ?
			CntEbx		dd ?
			CntEdx		dd ?
			CntEcx		dd ?
			CntEax		dd ?
			CntEbp		dd ?
			CntEip		dd ?
			CntSegCs	dd ?
			CntEFlags	dd ?
			CntEsp		dd ?
			CntSegSs	dd ?
ContextRecord		ends



; ####### Exception flags ####################################################

CONTINUABLE			EQU	0
NOT_CONTINUABLE			EQU	1
UNWINDING			EQU	2
UNWINDING_FOR_EXIT		EQU	4
UNWIND_IN_PROGRESS		EQU	6

; ####### End of chain marker ################################################

END_OF_CHAIN			EQU	-1

; ####### Data structures ####################################################

DispatchRecord		struc
			pPrevious	dd ?	; DispatchRecord *pPrevious
			pEhandler	dd ?	; EHandler *pEhandler
DispatchRecord		ends

ExceptionRecord		struc
			ExceptionCode	dd ?	; Number of Exception
			ExceptionFlags	dd ?
			pOuterException	dd ?	; ExceptionRecord *pOuterException
			ExceptionAddress dd ?
			NumParams	dd ?	; Number of parameters following
			ExceptionInfo	label near
ExceptionRecord		ends

; ##### this seems to be an overlay structure to DispatchRecord ##############

ExceptionFrame		struc
			pNextFrame	dd ?	; ExceptionFrame *pNextFrame
			pExceptionDesc	dd ?	; pointer to exception desc
			hEBP		dd ?
ExceptionFrame		ends


; RTLUnwind called with:

; pExceptionFrame,	( actually the same as dispatch record )
; ReturnAddress,	( where to go afterwards )
; pExceptionRecord,	( current ExceptionRecord )

; if pExceptionRecord is 0, then no handlers will be called, otherwise
; all handlers will be called until pExceptionFrame reached
; if pExceptionFrame is 0, all handlers will be unwound
