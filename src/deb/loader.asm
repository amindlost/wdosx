; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/DEB/loader.asm 1.4 2000/04/13 15:23:50 MikeT Exp MikeT $
;
; ----------------------------------------------------------------------------
;
; $Log: loader.asm $
; Revision 1.4  2000/04/13 15:23:50  MikeT
; Back out previous change.
;
; Revision 1.3  1999/12/12 18:50:30  MikeT
; Open debuggee in "deny write" as opposed to compatibility mode.
;
; Revision 1.2  1999/02/07 20:11:24  MikeT
; Updated copyright.
;
; Revision 1.1  1998/08/03 03:14:04  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
_TEXT ENDS
_DATA SEGMENT
align 4
;
; Include the LE loader binary
;
StartLoadle	LABEL BYTE
include	loadle.inc
EndLoadle	LABEL BYTE

SIZE_OF_LOADLE	EQU (OFFSET EndLoadle - OFFSET StartLoadle)
SIZE_OF_LEBLOCK	EQU ((SIZE_OF_LOADLE + 1024 + 3) AND 0FFFCh)

_DATA ENDS

_BSS SEGMENT

isLeExe		db	?

_BSS ENDS
_TEXT SEGMENT

; error codes

ENotWdosx	equ	80000000h
ELoadFile	equ	40000000h
ELoadDpmi	equ	20000000h

; include for David Lindauers PMODE c0

C0PMODE		struc
		c0_magic	dd	?	; should be 'WDBG'
		c0_version	dw	?	; some Version info
		c0_dgroup	dw	?
		c0_BSSEND	dw	?
		c0_stack	dd	?	; PROGRAM_STACK
		c0_pmodew	dd	?	;
		c0_start	dd	?	; true entry point
		c0_main		dd	?	; where to set a breakpoint
C0PMODE		ends

_LoadProgram	proc	near
; int LoadProgram(char * Filename)

		mov	_Deax,1
		mov	_Debx,0

		; try opening the file

		mov	edx,[esp+4]
		mov	eax,3d00h
		int	21h
		jnc	@@lp00
		mov	eax,ELoadFile
		ret
@@lp00:
		mov	_Debx,eax

		pushad

		; read wdosx exe header

		mov	_Deax,2
		mov	ebx,eax
		mov	edx,offset Buffer32
		mov	ecx,32
		mov	ah,3fh
		int	21h
		jnc	@@lp01
@@lpb0:
		mov	ebx,_Debx
		test	ebx,ebx
		jz	@@lpnocl
		mov	ah,3eh
		int	21h
@@lpnocl:
		popad
		mov	eax,ELoadFile
		add	eax,_Deax
		ret
@@lp01:
		cmp	eax,32
		jnz	@@lpb0

		; cmp signature

		mov	_Deax,2
		mov	_Dedx,1		; indicate WDOSX

		cld
		mov	esi,offset ThatsMe
		mov	edi,offset Buffer32+32-7
		mov	ecx,7
		repe	cmpsb
		je	@@lp03
; testing:
		sub	edx,edx			; seek to start
		mov	_Dedx,edx		; may be pmode .exe
		jmp	short @@lpFromPm

@@lp02:
		mov	ah,3eh
		int	21h
		popad
		mov	eax,ENotWdosx
		ret
@@lp03:
		cmp	word ptr [offset Buffer32],'ZM'
		jne	@@lp02		

		; get size of extender

		sub	edx,edx
		sub	ecx,ecx
		mov	eax,dword ptr [offset Buffer32+2]	; size mod 512
		shld	edx,eax,16				; size div 512
		neg	eax
		and	eax,511
		shl	edx,9
		sub	edx,eax

		; edx = size, jmp to next header
@@lpFromPm:

		shld	ecx,edx,16	; wdosx will never be > 64k, but anyway
		mov	edi,edx
		mov	esi,ecx
		mov	eax,4200h
		int	21h
		jc	@@lpb0

		; file pointer now at the beginning of the executable to load

		mov	_Deax,3

		; get selectors

		sub	eax,eax
		mov	ecx,2
		int	31h
		jnc	@@lp05
@@lpdpmi:
		mov	ebx,_Debx
		test	ebx,ebx
		jz	@@lpnocl1
		mov	ah,3eh
		int	21h
@@lpnocl1:
		popad
		mov	eax,ELoadDpmi
		add	eax,_Deax
		ret
@@lp05:

		mov	_Deax,4

		and	eax,0ffffh
		sub	edx,edx
		mov	ebp,eax
		mov	UserDataSel,eax

		; add selector to free list

		shld	edx,eax,29
		mov	_Dds,eax
		mov	_Dss,eax
		mov	_Dfs,0
		mov	_Dgs,0

		or	al,80h		; mark valid

		mov	[edx+offset AllocSelectors],al

		; get increment, just to satisfy the official protocol 

		mov	eax,3
		int	31h

		add	eax,ebp
		and	eax,0ffffh
		mov	UserCodeSel,eax
		mov	edx,eax
		mov	_Dcs,eax
		shr	edx,3
	
		; set limits to 4G

		mov	ebx,eax

		; add selector to free list

		or	al,80h
		mov	[edx+offset AllocSelectors],al

		mov	eax,8
		mov	ecx,-1
		mov	edx,ecx
		int	31h
		jc	@@lpdpmi
		mov	ebx,ebp
		int	31h	
		jc	@@lpdpmi

		; get cpl, set access rights

		mov	_Deax,5

		lar	cx,bx
		mov	cl,ch
		and	cl,060h
		or	cl,092h
		mov	ch,0c0h
		mov	eax,9
		int	31h
		jc	@@lpdpmi
		mov	ebx,UserCodeSel
		or	cl,9ah
		int	31h
		jc	@@lpdpmi

		mov	_Deax,6

		; current file pointer in si:di

		; read user exe header

		mov	edx,offset Buffer32
		mov	ebx,_Debx
		mov	ah,3fh
		mov	ecx,32
		int	21h
		jc	@@lpb0
		cmp	eax,32
		jnz	@@lpb0

		mov	_Deax,7
;
; LE - EXE detection
;
		cmp	DWORD PTR [edx], 'ESFW'
		sete	isLeExe
		jne	doMoreDet
;
; We can close the user file now
;
		mov	ah, 3Eh
		int	21h
		jmp	@@DefinitelyLE

doMoreDet:
		push	edx
		mov	ecx, 16

detLoop:
		cmp	WORD PTR [edx], 'EL'
		sete	isLeExe
		je	detDone

		cmp	BYTE PTR [edx], 0
		jne	detDone

		inc	edx
		loop	detLoop

detDone:
		pop	edx

		cmp	isLeExe, 0
		je	skipLeFpReset

		mov	ecx, -1
		mov	edx, -32
		mov	ax, 4201h
		int	21h
		jc	@@lpb0

@@DefinitelyLE:
		mov	_Deip, 0
		mov	edx, SIZE_OF_LOADLE
		jmp	@@MZandLE01

skipLeFpReset:
;
; check for .exe - header
;
		cmp	word ptr [edx],'ZM'
		jnz	@@lpbinary

		mov	_Deax,8

		; -------------- MZ EXE ------------------------

		; 2do check for loader signature

		; get size of user pgm

		sub	edx,edx
		sub	ecx,ecx
		mov	eax,dword ptr [offset Buffer32+2]	; size mod 512
		shld	edx,eax,16				; size div 512
		neg	eax
		and	eax,511
		shl	edx,9
		sub	edx,eax
		movzx	eax,word ptr [offset Buffer32+8]	; size of header
		shl	eax,4			; para -> byte
		sub	edx,eax

		; edx = bytes to load

		push	edx
		sub	eax,32			; bytes already loaded
		jz	@@lp08
		mov	edx,eax
		sub	ecx,ecx
		shld	ecx,edx,16		; exe header > 64k ??? :-)
		mov	eax,4201h
		int	21h
@@lp08:		
		pop	edx
		jc	@@lpb0


		movzx	eax,word ptr [offset Buffer32+20]	; entry point
;
; EDX = bytes to load, EAX = Entry point
;
		mov	_Deip,eax
		jmp	@@lpgetmem

;-------------- FLAT FORM BINARY ONLY ------------------	

@@lpbinary:
		; set fp to eof
		mov	_Deax,9


		sub	ecx,ecx
		sub	edx,edx
		mov	ax,4202h
		int	21h
		jc	@@lpb0
		shl	eax,16
		shld	edx,eax,16		

		; sub extender size

		sub	edx,edi


		mov	_Deax,10

		; reset file pointer

		push	edx
		mov	edx,edi
		mov	ecx,esi
		mov	eax,4200h
		int	21h
		pop	edx
		jc	@@lpb0

		mov	_Deip,0

@@lpgetmem:

		; don't allocate nothing

		mov	_Deax,11

		test	edx,edx
		jz	@@lpb0

		; get bytes to read

		mov	_Deax,12

@@MZandLE01:
		push	edx

		; align on dword and add stack

		add	edx,1027
		and	edx,0fffffffch

		mov	ecx,edx
		shld	ebx,edx,16

		; save initial esp

		mov	_Desp,edx

		; grab mem

		mov	eax,501h
		int	31h
		pop	ebp		; size of bytes to read
		jc	@@lpdpmi

		; save handle

		mov	word ptr ds:[offset UserMemHnd],di
		mov	word ptr ds:[offset UserMemHnd+2],si

		; register the segment as the first one

		mov	word ptr [UserSegs.MsLinearAd],cx
		mov	word ptr [UserSegs.MsLinearAd+2],bx
		mov	word ptr [UserSegs.MsHandle],di
		mov	word ptr [UserSegs.MsHandle+2],si
		mov	[UserSegs.MsSize],edx

		mov	NumSegments,1

		mov	_Deax,13

		; set descriptor base for new cs,ds

		mov	eax,7
		mov	edx,ecx
		mov	ecx,ebx
		mov	ebx,UserCodeSel
		int	31h
		jc	@@lpdpmi

		mov	_Deax,14

		mov	ebx,UserDataSel
		int	31h
		jc	@@lpdpmi


		mov	_Deax,15

		; check whether it could be a PMODE thingy

		cmp	_Dedx,0
		jnz	@@lpIsWdosx

		; if so, the signature must be somewhere

		movzx	eax,word ptr [offset Buffer32+16h]
		movzx	edx,word ptr [offset Buffer32+14h]
		movzx	esi,word ptr [offset Buffer32+8]
		shl	esi,4
		shl	eax,4
		add	edx,eax
		lea	edx,[edx+esi+2] 	; skip short jmp
		shld	ecx,edx,16
		mov	ebx,_Debx
		mov	eax,4200h
		int	21h
		jc	@@lpdpmi

		; read struc into buffer

		mov	ecx,32
		mov	edx,offset Buffer32
		mov	ah,3fh
		int	21h
		jc	@@lpdpmi

		; check for signature

		cmp	c0_magic[edx],'WDBG'
		jnz	@@lpdpmi

		; adjust file pointer and bytes to read

		movzx	edx,c0_dgroup[edx]
		shl	edx,4
		sub	ebp,edx
		add	edx,esi
		shld	ecx,edx,16
		mov	eax,4200h
		int	21h
		jc	@@lpdpmi

@@lpIsWdosx:
		mov	ecx,ebp
;
; If LE, copy the binary, otherwise read file
;
		cmp	isLeExe, 0
		jz	skipLECopy

		pushad
		cld
		mov	esi, OFFSET StartLoadle
		sub	edi,edi
		push	es
		mov	es,UserDataSel
		rep	movs BYTE PTR es:[edi], ds:[esi]
		pop	es
		popad
		jmp	@@doLoadLE

skipLeCopy:
		sub	edx,edx
		mov	ebx,_Debx
		push	ds
		mov	ds,UserDataSel
		mov	ah,3fh
		int	21h
		pop	ds
		jc	@@lpdpmi

		mov	_Deax,16

		cmp	eax,ebp
		jnz	@@lpb0

		; close file

		mov	ah,3eh
		int	21h


		cmp	_Dedx,0
		jnz	@@lpCheckLoader

		; adjust segment size

		mov	di,word ptr ds:[offset UserMemHnd]
		mov	si,word ptr ds:[offset UserMemHnd+2]
		movzx	edx,word ptr c0_BSSEND[offset Buffer32]
		shl	edx,4
		add	edx,c0_stack[offset Buffer32]
		add	edx,3+12
		and	dl,0fch
		mov	ecx,edx
		shld	ebx,edx,16
		mov	eax,0503h
		int	31h	
		jc	@@lpdpmi
		mov	word ptr ds:[offset UserMemHnd],di
		mov	word ptr ds:[offset UserMemHnd+2],si
		mov	word ptr [UserSegs.MsLinearAd],cx
		mov	word ptr [UserSegs.MsLinearAd+2],bx
		mov	word ptr [UserSegs.MsHandle],di
		mov	word ptr [UserSegs.MsHandle+2],si
		mov	[UserSegs.MsSize],ecx
		sub	edx,12
		mov	_Desp,edx
		mov	_Debx,edx

		; adjust base addresses

		mov	eax,7
		mov	edx,ecx
		mov	ecx,ebx
		mov	ebx,UserCodeSel
		int	31h
		jc	@@lpdpmi
		mov	ebx,UserDataSel
		int	31h
		jc	@@lpdpmi


		shl	edx,16
		shld	ecx,edx,16
		mov	_Decx,ecx
		mov	eax,dword ptr c0_start[offset Buffer32]
		mov	_Deip,eax
		mov	eax,dword ptr c0_pmodew[offset Buffer32]
		push	gs
		mov	gs,_Dds
		mov	word ptr gs:[eax],4ch
		mov	edx,_Desp
		add	edx,8
		mov	dword ptr gs:[edx],21cd4cb4h	; mov ah,4ch/int 21h
		mov	dword ptr gs:[edx-8],edx
		mov	eax,_Dcs
		mov	gs:[edx-4],eax
		pop	gs
		push	dword ptr c0_main[offset Buffer32]
		push	_Dcs
		call	_Here
		add	esp,8
		jmp	@@NoLoader

@@lpCheckLoader:

; check for a loader

		mov	esi,offset ThatsMe
		mov	edi,offset Buffer32+32-7
		mov	ecx,7
		repe	cmpsb
		jne	@@NoLoader

		; starting convention:
		; es = psp- selector
		; cs,ds,ss = flat segment
		; esp = user file size + stack size (1k), dword aligned
		; eip = 0
		; interrupts disabled!
		; all other registers - undefined

		; just run the loader ( don't do this at home, kids! )
@@doLoadLE:
		mov	edx,_Desp
		sub	edx,1024
		shld	ecx,edx,16
		mov	ebx,_Dcs
		mov	eax,8
		int	31h
		jc	@@lpdpmi

		; let it run until it GPFs

		mov	ebx,_Debx
		call	_Run
		cmp	al,13
;Junk
;		jnz	@@lpdpmi

		stc
		sbb	ecx,ecx
		sbb	edx,edx
		mov	ebx,_Dcs
		mov	eax,8
		int	31h
		jc	@@lpdpmi
		call	_SingleStep

@@NoLoader:
		popad
		sub	eax,eax
		ret

_LoadProgram	endp

