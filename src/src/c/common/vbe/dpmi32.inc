
; ############################################################################
; ## Filename     :   dpmi32.inc                                            ##
; ## Description  :   Defines structures and constants related to DPMI API  ##
; ## Author       :   Michael Tippach                                       ##
; ## Creation Date:   1997/03/11                                            ##
; ## Last Modified:   1997/03/17                                            ##
; ############################################################################

; ############################################################################
; ## A real mode pointer                                                    ##
; ############################################################################

IFDEF DPMI32_INC
ELSE
DPMI32_INC = 1

IFDEF RealModePtr
ELSE

RealModePtr		struc

			RmOffset	dw ?
			RmSegment	dw ?

RealModePtr		ends

ENDIF


; ############################################################################
; ## A 32 bit far pointer                                                   ##
; ############################################################################

IFDEF ProtModePtr
ELSE

ProtModePtr		struc

			PmOffset	dd ?
			PmSelector	dd ?

ProtModePtr		ends

ENDIF

; ############################################################################
; ## Real mode callback structure for DPMI translation services             ##
; ############################################################################

IFDEF RmCallStruc
ELSE

RmCallStruc	struc

		_edi	label	dword
		_di	dw	?
			dw	?
		_esi	label	dword
		_si	dw	?
			dw	?
		_ebp	label	dword
		_bp	dw	?
			dw	?
		_esp	label	dword
		_spl	dw	?
			dw	?
		_ebx	label	dword
		_bx	label	word
		_bl	db	?
		_bh	db	?
			dw	?
		_edx	label	dword
		_dx	label	word
		_dl	db	?
		_dh	db	?
			dw	?
		_ecx	label	dword
		_cx	label	word
		_cl	db	?
		_ch	db	?
			dw	?
		_eax	label	dword
		_ax	label	word
		_al	db	?
		_ah	db	?
			dw	?
		_flags	dw	?
		_es	dw	?
		_ds	dw	?
		_fs	dw	?
		_gs	dw	?
		_ip	dw	?
		_cs	dw	?
		_sp	dw	?
		_ss	dw	?	

RmCallStruc	ends

ENDIF

; ############################################################################
; ## Two useful macros for packing / unpacking 16:16 bit values (slow!)     ##
; ############################################################################


DPMIPack	macro Target32,SourceHigh,SourceLow

		___S1 CATSTR <e>,<SourceHigh>
		___S2 CATSTR <e>,<SourceLow>
		IFIDN ___S1,<Target32>
			shrd	Target32,___S2,16
			ror	Target32,16
                ELSE	
			IFIDN ___S2,<Target32>
				shl	Target32,16
				shrd	Target32,___S1,16
	        	ELSE
				shrd	Target32,___S2,16
				shrd	Target32,___S1,16
			ENDIF
		ENDIF
endm


DPMIUnpack	macro Source32,TargetHigh,TargetLow

		___S1 CATSTR <e>,<TargetHigh>
		___S2 CATSTR <e>,<TargetLow>
		IFIDN ___S1,<Source32>
			mov	___S2,Source32
			shr	Source32,16
                ELSE	
			IFIDN ___S2,<Source32>
				shld	___S1,Source32,16
	        	ELSE
				mov	___S2,Source32
				shld	___S1,Source32,16
			ENDIF
		ENDIF
endm

; ############################################################################
; ## DPMI functions ( destroy: eax, edx, ecx, flags )                       ##
; ############################################################################

DPMIAllocDescriptors	macro NumDescriptors,OutSelector

			mov	ecx,NumDescriptors
			sub	eax,eax
			int	31h
			IFIDN <OutSelector>,<eax>
			ELSE
				mov	OutSelector,eax
			ENDIF
endm

DPMIFreeDescriptor	macro FreeSel

			IFIDN <FreeSel>,<ebx>
			ELSE
				push	ebx
				mov	ebx,FreeSel
			ENDIF
			mov	eax,1
			int	31h
			IFIDN <FreeSel>,<ebx>
			ELSE
				pop	ebx
			ENDIF
endm

DPMISegToDescriptor	macro RealSegment,OutSelector

			IFIDN <RealSegment>,<ebx>
			ELSE
				push	ebx
				mov	ebx,RealSegment
			ENDIF
			mov	eax,2
			int	31h
			IFIDN <RealSegment>,<ebx>
			ELSE
				pop	ebx
			ENDIF
			IFIDN <OutSelector>,<eax>
			ELSE
				mov	OutSelector,eax
			ENDIF
endm

DPMIGetSelectorInc	macro OutInc

			mov	eax,3
			int	31h
			IFIDN <OutInc>,<eax>
			ELSE
				mov	OutInc,eax
			ENDIF
endm

DPMIGetSegmentBase	macro InSelector,OutBase

			IFIDN <InSelector>,<ebx>
			ELSE
				push	ebx
				mov	ebx,InSelector
			ENDIF
			mov	eax,6
			int	31h
			IFIDN <InSelector>,<ebx>
			ELSE
				pop	ebx
			ENDIF
			pushfd
			DPMIPack OutBase cx dx
			popfd
endm

DPMISetSegmentBase	macro InSelector,InBase

			DPMIUnpack InBase cx dx
			IFIDN <InSelector>,<ebx>
			ELSE
				push	ebx
				mov	ebx,InSelector
			ENDIF
			mov	eax,7
			int	31h
			IFIDN <InSelector>,<ebx>
			ELSE
				pop	ebx
			ENDIF
endm

DPMIGetSegmentLimit	macro InSelector,OutLimit

			lsl	OutLimit,InSelector
endm

DPMISetSegmentLimit	macro InSelector,InLimit

			DPMIUnpack InLimit cx dx
			IFIDN <InSelector>,<ebx>
			ELSE
				push	ebx
				mov	ebx,InSelector
			ENDIF
			mov	eax,8
			int	31h
			IFIDN <InSelector>,<ebx>
			ELSE
				pop	ebx
			ENDIF
endm

DPMIGetAccessRights	macro InSelector,OutRights

			lar	OutRights,InSelector
endm

DPMISetAccessRights	macro InSelector,InRights

			IFIDN	<InRights>,<ecx>
			ELSE
				mov	ecx,InRights
			ENDIF
			shr	ecx,8
			IFIDN <InSelector>,<ebx>
			ELSE
				push	ebx
				mov	ebx,InSelector
			ENDIF
			mov	eax,9
			int	31h
			IFIDN <InSelector>,<ebx>
			ELSE
				pop	ebx
			ENDIF
endm

DPMICreateAlias		macro	InSelector,OutSelector

			IFIDN <InSelector>,<ebx>
			ELSE
				push	ebx
				mov	ebx,InSelector
			ENDIF
			mov	eax,0ah
			int	31h
			IFIDN <InSelector>,<ebx>
			ELSE
				pop	ebx
			ENDIF
			IFIDN <OutSelector>,<eax>
			ELSE
				mov	OutSelector,eax
			ENDIF
endm

; ###### 2 do: Get / Set Descriptor #######

DPMIAllocDosMem		macro	SizeInBytes,OutSegment,OutSelector

			IFIDN <SizeInBytes>,<ebx>
			ELSE
				push	ebx
				mov	ebx,SizeInBytes
			ENDIF
			add	ebx,15
			shr	ebx,4
			mov	eax,100h
			int	31h
			IFIDN <SizeInBytes>,<ebx>
			ELSE
				pop	ebx
			ENDIF
			IFIDN <OutSegment>,<eax>
			ELSE
				push	eax
			ENDIF
			IFIDN <OutSelector>,<edx>
			ELSE
				mov	OutSelector,edx
			ENDIF
			IFIDN <OutSegment>,<eax>
			ELSE
				pop	OutSegment
			ENDIF
endm

DPMIFreeDosMem		macro InSelector

			IFIDN <InSelector>,<edx>
			ELSE
				mov	edx,Inselector
			ENDIF
			mov	eax,101h
			int	31h
endm

DPMIResizeDosMem	macro InSelector,SizeInBytes

			IFIDN <InSelector>,<ebx>
			ELSE
				push	ebx
				push	InSelector
			ENDIF
			IFIDN <SizeInBytes>,<edx>
			ELSE
				mov	edx,SizeInBytes
			ENDIF
			IFIDN <InSelector>,<ebx>
			ELSE
				pop	ebx
			ENDIF
			add	ebx,15
			shr	ebx,4
			mov	eax,102h
			int	31h
			IFIDN <InSelector>,<ebx>
			ELSE
				pop	ebx
			ENDIF
endm

DPMIGetRMVector		macro IntNum,OutPtr

			IFIDN <IntNum>,<ebx>
			ELSE
				push	ebx
				mov	ebx,IntNum
			ENDIF
			mov	eax,200h
			int	31h
			IFIDN <IntNum>,<ebx>
			ELSE
				pop	ebx
			ENDIF
			mov	[OutPtr.RmOffset],dx
			mov	[OutPtr.RmSegment],cx
endm

DPMISetRMVector		macro IntNum,InPtr

			IFIDN <IntNum>,<ebx>
			ELSE
				push	ebx
				mov	ebx,IntNum
			ENDIF
			mov	dx,[InPtr.RmOffset]
			mov	cx,[InPtr.RmSegment]
			mov	eax,201h
			int	31h
			IFIDN <IntNum>,<ebx>
			ELSE
				pop	ebx
			ENDIF
endm

DPMIGetExcHandler	macro	IntNum,OutPtr

			IFIDN <IntNum>,<ebx>
			ELSE
				push	ebx
				mov	ebx,IntNum
			ENDIF
			mov	eax,202h
			int	31h
			IFIDN <IntNum>,<ebx>
			ELSE
				pop	ebx
			ENDIF
			mov	[OutPtr.PmOffset],edx
			mov	[OutPtr.PmSelector],ecx
endm

DPMISetExcHandler	macro	IntNum,InPtr

			IFIDN <IntNum>,<ebx>
			ELSE
				push	ebx
				mov	ebx,IntNum
			ENDIF
			mov	edx,[InPtr.PmOffset]
			mov	ecx,[InPtr.PmSelector]
			mov	eax,203h
			int	31h
			IFIDN <IntNum>,<ebx>
			ELSE
				pop	ebx
			ENDIF
endm

DPMIGetPMVector		macro	IntNum,OutPtr

			IFIDN <IntNum>,<ebx>
			ELSE
				push	ebx
				mov	ebx,IntNum
			ENDIF
			mov	eax,204h
			int	31h
			IFIDN <IntNum>,<ebx>
			ELSE
				pop	ebx
			ENDIF
			mov	[OutPtr.PmOffset],edx
			mov	[OutPtr.PmSelector],ecx
endm

DPMISetPMVector		macro	IntNum,InPtr

			IFIDN <IntNum>,<ebx>
			ELSE
				push	ebx
				mov	ebx,IntNum
			ENDIF
			mov	edx,[InPtr.PmOffset]
			mov	ecx,[InPtr.PmSelector]
			mov	eax,205h
			int	31h
			IFIDN <IntNum>,<ebx>
			ELSE
				pop	ebx
			ENDIF
endm

DPMISimulateRMInterrupt	macro	IntNum,InPtr

			IFIDN	<InPtr>,<edi>
			ELSE
				push	edi
			ENDIF
			IFIDN <IntNum>,<ebx>
			ELSE
				push	ebx
			ENDIF
			IFIDN	<InPtr>,<edi>
			ELSE
				push	offset InPtr
			ENDIF
			IFIDN <IntNum>,<ebx>
			ELSE
				mov	ebx,Intnum
			ENDIF
			IFIDN	<InPtr>,<edi>
			ELSE
				pop	edi
			ENDIF
			sub	ecx,ecx
			mov	eax,300h
			push	es
			push	ds
			pop	es
			int	31h
			pop	es
			IFIDN <IntNum>,<ebx>
			ELSE
				pop	ebx
			ENDIF
			IFIDN	<InPtr>,<edi>
			ELSE
				pop	edi
			ENDIF
endm

; ### 2 do: far call (301,302) ###

DPMIAllocateCallback	macro OutPtr,InProc,InPtr

			IFIDN	<InPtr>,<edi>
			ELSE
				push	edi
			ENDIF
			IFIDN	<InProc>,<esi>
			ELSE
				push	esi
			ENDIF
			IFIDN	<InPtr>,<edi>
			ELSE
				push	offset InPtr
			ENDIF
			IFIDN	<InProc>,<esi>
			ELSE
				lea	esi,InProc
			ENDIF
			IFIDN	<InPtr>,<edi>
			ELSE
				pop	edi
			ENDIF
			mov	eax,303h
			push	es
			push	ds
			pop	es
			push	ds
			push	cs
			pop	ds
			int	31h
			pop	ds
			pop	es
			IFIDN	<InProc>,<esi>
			ELSE
				pop	esi
			ENDIF
			IFIDN	<InPtr>,<edi>
			ELSE
				pop	edi
			ENDIF
			mov	[OutPtr.RmOffset],dx
			mov	[Outptr.RmSegment],cx
endm

DPMIFreeCallback	macro InPtr

			mov	dx,[InPtr.RmOffset]
			mov	cx,[InPtr.RmSegment]
			mov	eax,304h
			int	31h
endm

; ### 31/500 has been split so it's more handy to use ###

DPMIGetVersion		macro OutVersion

			IFIDN <OutVersion>,<ebx>
			ELSE
				push	ebx
			ENDIF
			mov	eax,400h
			int	31h
			IFIDN <OutVersion>,<eax>
			ELSE
				mov	OutVersion,eax
			ENDIF
			IFIDN <OutVersion>,<ebx>
			ELSE
				pop	ebx
			ENDIF
endm

DPMIGetHostFlags	macro OutFlags

			IFIDN <OutFlags>,<ebx>
			ELSE
				push	ebx
			ENDIF
			mov	eax,400h
			int	31h
			IFIDN <OutFlags>,<ebx>
			ELSE
				mov	OutFlags,ebx
				pop	ebx
			ENDIF
endm

DPMIGetCPUType		macro OutType

			IFIDN <OutType>,<ebx>
			ELSE
				push	ebx
			ENDIF
			mov	eax,400h
			int	31h
			movzx	ecx,cl
			IFIDN <OutType>,<ecx>
			ELSE
				mov	OutType,ecx
			ENDIF
			IFIDN <OutType>,<ebx>
			ELSE
				pop	ebx
			ENDIF
endm

DPMIGetIntFromIRQ	macro InIrq,OutInt
local	@@UseEdx

			IFIDN <OutInt>,<ebx>
			ELSE
				push	ebx
			ENDIF
			push	InIrq
			mov	eax,400h
			int	31h
			pop	ebx
			cmp	bl,8
			jnc	short @@UseEdx
			mov	dl,dh
@@UseEdx:
			add	ebx,edx
			movzx	ebx,bl
			IFIDN <OutInt>,<ebx>
			ELSE
				mov	OutInt,ebx
				pop	ebx
			ENDIF
endm

; ### 2 do: Extended memory allocation (5xx) ###

DPMILockLinearRegion	macro InAddr,InSize

			push	ebx
			push	edi
			push	esi
			push	InAddr
			IFIDN <InSize>,<edi>
			ELSE
				mov	edi,InSize
			ENDIF
			DPMIUnpack edi si di
			pop	ecx
			DPMIUnpack ecx bx cx
			mov	eax,600h
			int	31h
			pop	esi
			pop	edi
			pop	ebx
endm


DPMIUnLockLinearRegion	macro InAddr,InSize

			push	ebx
			push	edi
			push	esi
			push	InAddr
			IFIDN <InSize>,<edi>
			ELSE
				mov	edi,InSize
			ENDIF
			DPMIUnpack edi si di
			pop	ecx
			DPMIUnpack ecx bx cx
			mov	eax,601h
			int	31h
			pop	esi
			pop	edi
			pop	ebx
endm

DPMIUnLockRMRegion	macro InAddr,InSize

			push	ebx
			push	edi
			push	esi
			push	InAddr
			IFIDN <InSize>,<edi>
			ELSE
				mov	edi,InSize
			ENDIF
			DPMIUnpack edi si di
			pop	ecx
			DPMIUnpack ecx bx cx
			mov	eax,602h
			int	31h
			pop	esi
			pop	edi
			pop	ebx
endm


DPMIReLockRMRegion	macro InAddr,InSize

			push	ebx
			push	edi
			push	esi
			push	InAddr
			IFIDN <InSize>,<edi>
			ELSE
				mov	edi,InSize
			ENDIF
			DPMIUnpack edi si di
			pop	ecx
			DPMIUnpack ecx bx cx
			mov	eax,603h
			int	31h
			pop	esi
			pop	edi
			pop	ebx
endm

DPMIGetPageSize		macro OutSize
			IFIDN <OutSize>,<ebx>
			ELSE
				push	ebx
			ENDIF
			mov	eax,604h
			int	31h
			IFIDN <OutSize>,<ebx>
			DPMIPack ebx bx cx
			ELSE
				DPMIPack eax bx cx
				IFIDN <OutSize>,<eax>
				ELSE
					mov	OutSize,eax
				ENDIF
				pop	ebx
			ENDIF
endm

DPMIMarkPageable	macro InAddr,InSize

			push	ebx
			push	edi
			push	esi
			push	InAddr
			IFIDN <InSize>,<edi>
			ELSE
				mov	edi,InSize
			ENDIF
			DPMIUnpack edi si di
			pop	ecx
			DPMIUnpack ecx bx cx
			mov	eax,702h
			int	31h
			pop	esi
			pop	edi
			pop	ebx
endm

DPMIDiscardPages	macro InAddr,InSize

			push	ebx
			push	edi
			push	esi
			push	InAddr
			IFIDN <InSize>,<edi>
			ELSE
				mov	edi,InSize
			ENDIF
			DPMIUnpack edi si di
			pop	ecx
			DPMIUnpack ecx bx cx
			mov	eax,703h
			int	31h
			pop	esi
			pop	edi
			pop	ebx
endm


DPMIMapPhysicalRegion	macro InAddr,InSize,OutAddr

			push	ebx
			push	edi
			push	esi
			push	InAddr
			IFIDN <InSize>,<edi>
			ELSE
				mov	edi,InSize
			ENDIF
			DPMIUnpack edi si di
			pop	ecx
			DPMIUnpack ecx bx cx
			mov	eax,800h
			int	31h
			pushfd
			DPMIPack ecx bx cx
			popfd
			pop	esi
			pop	edi
			pop	ebx
			IFIDN <OutAddr>,<ecx>
			ELSE
				mov	OutAddr,ecx
			ENDIF
endm

DPMIEnableVI		macro OutState
			mov	eax,0901h
			int	31h
			IFIDN <OutState>,<>
			ELSE
				IFIDN <OutState>,<eax>
				ELSE
					mov	OutState,eax
				ENDIF
			ENDIF
endm

DPMIDisableVI		macro OutState
			mov	eax,0900h
			int	31h
			IFIDN <OutState>,<>
			ELSE
				IFIDN <OutState>,<eax>
				ELSE
					mov	OutState,eax
				ENDIF
			ENDIF
endm


DPMIGetVIState		macro OutState
			mov	eax,0902h
			int	31h
			IFIDN <OutState>,<>
			ELSE
				IFIDN <OutState>,<eax>
				ELSE
					mov	OutState,eax
				ENDIF
			ENDIF
endm

DPMISetVIState		macro InState
			IFIDN <InState>,<eax>
			ELSE
				mov	eax,InState
			ENDIF
			mov	ah,9
			int	31h
endm

ENDIF ; DPMI32_INC
