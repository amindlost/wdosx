; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/legacy/MEMSTAT.INC 1.1 1999/02/07 18:13:57 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: MEMSTAT.INC $
; Revision 1.1  1999/02/07 18:13:57  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
;
; Old floating segment PE code which I'm too lazy to maintain any longer or to
; even comment on. It should stay as is and eventually die.
;

;-----------------------------------------------------------------------------

GlobalMemoryStatus:
		push	ebp
		mov	ebp,esp
		push	edi
		sub	esp,30h
		mov	edi,esp
		mov	eax,500h
		int	31h

		; get percentage

		mov	eax,ApiInitialFree
		sub	eax,[esp]
		mov	ecx,100
		mul	ecx
		mov	ecx,ApiInitialFree
		div	ecx
		mov	edx,[ebp+8]
		mov	dwMemoryLoad[edx],eax

		; total physical memory

		mov	eax,[esp+18h]
		shl	eax,12
		cmp	eax,0fffff000h
		jnz	@@Memstat00
		mov	eax,ApiInitialFree
@@MemStat00:
		mov	dwTotalPhys[edx],eax

		; available physical memory

		mov	eax,[esp+14h]
		shl	eax,12
		cmp	eax,0fffff000h
		jnz	@@Memstat01
		mov	eax,[esp]
@@MemStat01:
		mov	dwAvailPhys[edx],eax

		; available page file
		; this is not quite correct, but as usual, I don't care.

		mov	eax,[esp]
		mov	dwAvailPageFile[edx],eax

		; total page file

		mov	eax,[esp+20h]
		cmp	eax,-1
		jnz	@@MemStat03
		sub	eax,eax
		mov	dwAvailPageFile[edx],eax
@@MemStat03:
		mov	dwTotalPageFile[edx],eax

		; the linear space thing

		mov	eax,[esp+0ch]
		cmp	eax,-1
		jnz	@@MemStat04
		mov	eax,ApiInitialFree
@@MemStat04:
		mov	dwTotalVirtual[edx],eax

		; virtual available?

		mov	eax,[esp+1ch]
		cmp	eax,-1
		jnz	@@MemStat05
		mov	eax,[esp]
@@MemStat05:		
		mov	dwAvailVirtual[edx],eax
		add	esp,30h
		pop	edi
		mov	esp,ebp
		pop	ebp
		retn	4

;-----------------------------------------------------------------------------