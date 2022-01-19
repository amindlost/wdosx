; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/tools/dualmode.inc 1.1 1999/02/07 18:40:19 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: dualmode.inc $
; Revision 1.1  1999/02/07 18:40:19  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## Macro definition for static/dynamic library generation.                ##
; ############################################################################
.386
;
; Tasm 3.1 does not accept STDCALL as an argument to the model directive.
;
IFDEF __DLL__
.model flat
ELSE
.model flat, C
ENDIF

DUAL_EXPORT MACRO some_label
IFDEF __DLL__
	PUBLICDLL some_label
ELSE
	PUBLIC some_label
ENDIF
ENDM

DUAL_MAIN MACRO
IFDEF __DLL__
dllMain PROC NEAR
ENDIF
ENDM

DUAL_ENDMAIN MACRO
IFDEF __DLL__
dllMain ENDP
ENDIF
ENDM

DUAL_STDMAIN MACRO
IFDEF __DLL__
dllMain PROC NEAR
	mov	eax, 1
	retn	12
dllMain ENDP
ENDIF
ENDM

DUAL_RETURN MACRO num_args
IFDEF __DLL__
	retn	num_args
ELSE
	retn
ENDIF
ENDM

DUAL_END MACRO
IFDEF __DLL__
	END dllMain
ENDIF
	END
ENDM
