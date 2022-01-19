
; ############################################################################
; ## Filename     :   dpmi32.asm                                            ##
; ## Description  :   DPMI function wrappers for Borland C / WDOSX          ##
; ## Author       :   Michael Tippach                                       ##
; ## Creation Date:   1997/03/17                                            ##
; ## Last Modified:   1997/03/17                                            ##
; ############################################################################

.386p
.model flat		; not adding "C" avoids automatic underscores

include	dpmi32.inc	; include macros and structure declarations

public	_dpmiAllocDescriptor
public	_dpmiFreeDescriptor
public	_dpmiSegToDescriptor
public	_dpmiGetSelectorBase
public	_dpmiSetSelectorBase
public	_dpmiGetSelectorLimit
public	_dpmiSetSelectorLimit
public	_dpmiGetAccessRights
public	_dpmiSetAccessRights
public	_dpmiCreateAlias
public	_dpmiAllocateDOSMemory
public	_dpmiFreeDOSMemory
public	_dpmiResizeDOSMemory
public	_dpmiGetRMVector
public	_dpmiSetRMVector
public	_dpmiGetPMVector
public	_dpmiSetPMVector
public	_dpmiSimulateInterrupt
public	_dpmiAllocateCallback
public	_dpmiFreeCallback
public	_dpmiGetIntFromIRQ
public	_dpmiLockLinearRegion
public	_dpmiUnlockLinearRegion
public	_dpmiMapPhysicalRegion
public	_CsSelector
public	_SsSelector
public	_DsSelector
public	_EsSelector
public	_FsSelector
public	_GsSelector


.code

; ############################################################################
; ## unsigned long CsSelector (void);                                       ##
; ############################################################################

_CsSelector		proc	near
			mov	eax,cs
			ret
_CsSelector		endp


; ############################################################################
; ## unsigned long SsSelector (void);                                       ##
; ############################################################################

_SsSelector		proc	near
			mov	eax,ss
			ret
_SsSelector		endp


; ############################################################################
; ## unsigned long DsSelector (void);                                       ##
; ############################################################################

_DsSelector		proc	near
			mov	eax,ds
			ret
_DsSelector		endp


; ############################################################################
; ## unsigned long EsSelector (void);                                       ##
; ############################################################################

_EsSelector		proc	near
			mov	eax,es
			ret
_EsSelector		endp


; ############################################################################
; ## unsigned long FsSelector (void);                                       ##
; ############################################################################

_FsSelector		proc	near
			mov	eax,fs
			ret
_FsSelector		endp


; ############################################################################
; ## unsigned long GsSelector (void);                                       ##
; ############################################################################

_GsSelector		proc	near
			mov	eax,gs
			ret
_GsSelector		endp


; ############################################################################
; ## int _cdecl dpmiAllocDescriptor ( unsigned long *Selector );            ##
; ############################################################################

_dpmiAllocDescriptor	proc C
arg	SelPtr:dword

			DPMIAllocDescriptors 1 eax
			mov	edx,SelPtr
			mov	[edx],eax
			sbb	eax,eax
			inc	eax
			ret

_dpmiAllocDescriptor	endp


; ############################################################################
; ## int _cdecl dpmiFreeDescriptor ( unsigned long Selector );              ##
; ############################################################################

_dpmiFreeDescriptor	proc C
arg	Selector:dword

			DPMIFreeDescriptor Selector
			sbb	eax,eax
			inc	eax
			ret

_dpmiFreeDescriptor	endp


; ############################################################################
; ## int _cdecl dpmiSegToDescriptor ( unsigned long Segment,                ##
; ##                                  unsigned long *Selector );            ##
; ############################################################################

_dpmiSegToDescriptor	proc C
arg	DSegment:dword
arg	SelPtr:dword

			mov	edx,SelPtr
			DPMISegToDescriptor DSegment [edx]
			sbb	eax,eax
			inc	eax
			ret

_dpmiSegToDescriptor	endp


; ############################################################################
; ## int _cdecl dpmiGetSelectorBase ( unsigned long Selector,               ##
; ##                                  unsigned long *BaseAddr );            ##
; ############################################################################

_dpmiGetSelectorBase	proc C
arg	Selector:dword
arg	BasePtr:dword

			DPMIGetSegmentBase Selector edx
			mov	eax,BasePtr
			mov	[eax],edx
			sbb	eax,eax
			inc	eax
			ret

_dpmiGetSelectorBase	endp


; ############################################################################
; ## int _cdecl dpmiSetSelectorBase ( unsigned long Selector,               ##
; ##                                  unsigned long BaseAddr );             ##
; ############################################################################

_dpmiSetSelectorBase	proc C
arg	Selector:dword
arg	SBaseAddr:dword

			mov	eax,SBaseAddr
			DPMISetSegmentBase Selector eax
			sbb	eax,eax
			inc	eax
			ret

_dpmiSetSelectorBase	endp


; ############################################################################
; ## int _cdecl dpmiGetSelectorLimit ( unsigned long Selector,              ##
; ##                                   unsigned long *Limit );              ##
; ############################################################################

_dpmiGetSelectorLimit	proc C
arg	Selector:dword
arg	LimitPtr:dword

			DPMIGetSegmentLimit Selector edx
			mov	eax,LimitPtr
			mov	[eax],edx
			sub	eax,eax
			inc	eax
			ret

_dpmiGetSelectorLimit	endp


; ############################################################################
; ## int _cdecl dpmiSetSelectorLimit ( unsigned long Selector,              ##
; ##                                  unsigned long Limit );                ##
; ############################################################################

_dpmiSetSelectorLimit	proc C
arg	Selector:dword
arg	Limit:dword

			mov	eax,Limit
			DPMISetSegmentLimit Selector eax
			sbb	eax,eax
			inc	eax
			ret

_dpmiSetSelectorLimit	endp


; ############################################################################
; ## int _cdecl dpmiGetAccessRights ( unsigned long Selector,               ##
; ##                                  unsigned long *Rights );              ##
; ############################################################################

_dpmiGetAccessRights	proc C
arg	Selector:dword
arg	AccPtr:dword

			DPMIGetAccessRights Selector edx
			mov	eax,AccPtr
			mov	[eax],edx
			sub	eax,eax
			inc	eax
			ret

_dpmiGetAccessRights	endp


; ############################################################################
; ## int _cdecl dpmiSetAccessRights ( unsigned long Selector,               ##
; ##                                  unsigned long Rights );               ##
; ############################################################################

_dpmiSetAccessRights	proc C
arg	Selector:dword
arg	Rights:dword

			mov	eax,Rights
			DPMISetAccessRights Selector eax
			sbb	eax,eax
			inc	eax
			ret

_dpmiSetAccessRights	endp


; ############################################################################
; ## int _cdecl dpmiCreateAlias ( unsigned long Selector,                   ##
; ##                              unsigned long *AliasSel );                ##
; ############################################################################

_dpmiCreateAlias	proc C
arg	Selector:dword
arg	AliasPtr:dword

			DPMICreateAlias Selector eax
			mov	edx,AliasPtr
			mov	[edx],eax
			sbb	eax,eax
			inc	eax

			ret
_dpmiCreateAlias	endp

; ############################################################################
; ## int _cdecl dpmiAllocateDOSMemory ( unsigned long SizeInBytes,          ##
; ##                                    unsigned long *Segment,             ##
; ##                                    unsigned long *Selector );          ##
; ############################################################################

_dpmiAllocateDOSMemory	proc C
arg	MemSize:dword
arg	SegPtr:dword
arg	SelPtr:dword

			DPMIAllocDosMem	MemSize eax edx
			mov	ecx,SegPtr
			mov	[ecx],eax
			mov	ecx,SelPtr
			mov	[ecx],edx
			sbb	eax,eax
			inc	eax
			ret

_dpmiAllocateDOSMemory	endp

; ############################################################################
; ## int _cdecl dpmiFreeDOSMemory ( unsigned long Selector );               ##
; ############################################################################

_dpmiFreeDOSMemory	proc C
arg	Selector:dword

			DPMIFreeDosMem Selector
			sbb	eax,eax
			inc	eax
			ret

_dpmiFreeDOSMemory	endp


; ############################################################################
; ## int _cdecl dpmiResizeDOSMemory ( unsigned long Selector,               ##
; ##                                  unsigned long NewSize );              ##
; ############################################################################

_dpmiResizeDOSMemory	proc C
arg	Selector:dword
arg	NewSize:dword

			DPMIResizeDosMem Selector NewSize
			sbb	eax,eax
			inc	eax
			ret

_dpmiResizeDOSMemory	endp


; ############################################################################
; ## int _cdecl dpmiGetRMVector ( int IntNum, RMFarPtr *IntVec );           ##
; ############################################################################

_dpmiGetRMVector	proc C uses esi
arg	Intrr:dword
arg	RMFarPtr:dword

			mov	esi,RMFarPtr
			DPMIGetRMVector Intrr esi
			sbb	eax,eax
			inc	eax
			ret

_dpmiGetRMVector	endp


; ############################################################################
; ## int _cdecl dpmiSetRMVector ( int IntNum, RMFarPtr *IntVec );           ##
; ############################################################################

_dpmiSetRMVector	proc C uses esi
arg	Intrr:dword
arg	RMFarPtr:dword

			mov	esi,RMFarPtr
			DPMISetRMVector Intrr esi
			sbb	eax,eax
			inc	eax
			ret

_dpmiSetRMVector	endp


; ############################################################################
; ## int _cdecl dpmiGetPMVector ( int IntNum, PMFarPtr *IntVec );           ##
; ############################################################################

_dpmiGetPMVector	proc C uses esi
arg	Intrr:dword
arg	PMFarPtr:dword

			mov	esi,PMFarPtr
			DPMIGetPMVector Intrr esi
			sbb	eax,eax
			inc	eax
			ret

_dpmiGetPMVector	endp


; ############################################################################
; ## int _cdecl dpmiSetPMVector ( int IntNum, PMFarPtr *IntVec );           ##
; ############################################################################

_dpmiSetPMVector	proc C uses esi
arg	Intrr:dword
arg	PMFarPtr:dword

			mov	esi,PMFarPtr
			DPMISetPMVector Intrr esi
			sbb	eax,eax
			inc	eax
			ret

_dpmiSetPMVector	endp


; ############################################################################
; ## int _cdecl dpmiSimulateInterrupt ( int IntNum, RMCallStruc *RmRegs );  ##
; ############################################################################

_dpmiSimulateInterrupt	proc C uses edi
arg	Intrr:dword
arg	RMRegsPtr:dword

			mov	edi,RMRegsPtr
			DPMISimulateRMInterrupt	Intrr edi
			sbb	eax,eax
			inc	eax
			ret

_dpmiSimulateInterrupt	endp

; ############################################################################
; ## int _cdecl dpmiAllocateCallback  ( RMFarPtr *CallbackAddr,             ##
; ##                                    void *CallbackFunc,                 ##
; ##                                    RMCallStruc *CallbackStruc);        ##
; ############################################################################

_dpmiAllocateCallback	proc C  uses ebx esi edi
arg	CallAddr:dword
arg	CallProc:dword
arg	CallStruc:dword

			mov	esi,CallProc
			mov	edi,CallStruc
			mov	ebx,CallAddr
			DPMIAllocateCallback ebx esi edi
			sbb	eax,eax
			inc	eax
			ret

_dpmiAllocateCallback	endp


; ############################################################################
; ## int _cdecl dpmiFreeCallback  ( RMFarPtr *CallbackAddr );               ##
; ############################################################################

_dpmiFreeCallback	proc C
arg	CallAddr:dword

			mov	eax,CallAddr
			DPMIFreeCallback eax
			sbb	eax,eax
			inc	eax
			ret

_dpmiFreeCallback	endp


; ############################################################################
; ## unsigned short _cdecl dpmiGetIntFromIRQ  ( unsigned short IRQNum );    ##
; ############################################################################

_dpmiGetIntFromIRQ	proc C
arg	UseIRQ:dword
			DPMIGetIntFromIRQ UseIRQ eax
			ret
_dpmiGetIntFromIRQ	endp

; ############################################################################
; ## int _cdecl dpmiLockLinearRegion ( unsigned long LockStart,             ##
; ##                                   unsigned long LockSize  );           ##
; ############################################################################

_dpmiLockLinearRegion	proc C
arg	LockStart:dword
arg	LockSize:dword

			DPMILockLinearRegion LockStart LockSize
			sbb	eax,eax
			inc	eax
			ret

_dpmiLockLinearRegion	endp


; ############################################################################
; ## int _cdecl dpmiUnlockLinearRegion ( unsigned long UnlockStart,         ##
; ##                                     unsigned long UnlockSize  );       ##
; ############################################################################

_dpmiUnlockLinearRegion	proc C
arg	UnlockStart:dword
arg	UnlockSize:dword

			DPMIUnLockLinearRegion UnlockStart UnlockSize
			sbb	eax,eax
			inc	eax
			ret

_dpmiUnlockLinearRegion	endp


; ############################################################################
; ## int _cdecl dpmiMapPhysicalRegion ( unsigned long MapStart,             ##
; ##                                    unsigned long MapSize,              ##
; ##                                    unsigned long *MapLinear );         ##
; ############################################################################

_dpmiMapPhysicalRegion	proc C
arg	MapStart:dword
arg	MapSize:dword
arg	MapLinear:dword

			DPMIMapPhysicalRegion MapStart MapSize ecx
			mov	edx,MapLinear
			mov	[edx],ecx
			sbb	eax,eax
			inc	eax
			ret

_dpmiMapPhysicalRegion	endp


end
