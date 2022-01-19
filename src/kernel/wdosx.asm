; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 2002, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/KERNEL/wdosx.asm 1.41 2003/04/16 02:46:07 MikeT Exp MikeT $
;
; ----------------------------------------------------------------------------
;
; $Log: wdosx.asm $
; Revision 1.41  2003/04/16 02:46:07  MikeT
; Fix bug when reading WFSE files bigger than 4MB.
;
; Revision 1.40  2002/02/05 20:07:13  MikeT
; Dymdns URL now pointing to some valid place on the Internet.
;
; Revision 1.39  2002/01/31 21:09:38  MikeT
; Updated copuright and 0.97 version number.
;
; Revision 1.38  2001/02/22 22:15:26  MikeT
; Wdosx-Depack upgraded. The whole kernel is now compressed as one block.
;
; Revision 1.37  2001/02/21 21:29:10  MikeT
; Updated year in copyright one more time, added one more email address.
;
; Revision 1.36  2001/02/21 21:24:56  MikeT
; Callbacks under NT now fixed for good (I hope). Actually, this is a rather
; a workaround for an NTVDM bug.
;
; Revision 1.35  2001/02/04 15:50:00  MikeT
; Fix spawn problem under Windows where the application crashes when the child
; returns. Technical: Save and restore PM- interrupt vectors around the spawn
; call in int 21h function 4B.
;
; Revision 1.34  2000/07/12 16:33:54  MikeT
; Implemented a temporary fix to make the mouse callback work under NT. NTVDM
; has a bug in that only the SI and DI portions of ESI and EDI are valid when
; a DPMI callback procedure is entered. The final solution would fix this in
; the callback redirector instead of the mouse hook.
;
; Revision 1.33  2000/06/30 16:08:33  MikeT
; Sign extend esi and edi on the mouse callback (thks Jim Hutchinson).
;
; Revision 1.32  2000/04/11 17:53:01  MikeT
; Updated copyright in (c) string.
;
; Revision 1.31  2000/04/11 17:50:22  MikeT
; Add a thing that is supposed to fix a problem with callbacks in NTVDM (would
; ignore high word of target EIP). Not tested yet.
;
; Revision 1.30  2000/02/29 23:51:24  MikeT
; Clear the high word of ESP on entry into PM in RAW (non- V86) mode. The VCPI
; mode switch routine has been clearing the high word of ESP ever since. This
; is supposed to fix a problem where the system would crash on a real mode
; callback if the real mode code (for whatever reason) makes use of ESP 31:16
;
; Revision 1.29  2000/02/27 12:53:08  MikeT
; If an application decides to go resident, what we generally do not support,
; HIMEM.SYS would disable the A20 on every EXEC call, making installed
; callback handlers and IRQ autopassup go ballistic. Implemented sort of a
; means to frequently check and conditionally re-enable A20, which makes it
; work somewhat better but there are still problems.
;
; Revision 1.28  2000/01/30 18:39:15  MikeT
; File open mode set back to compatibility mode. Implemented a means to
; temporarily close the EXE normally held open by WFSE. Use the WFSE Alternate
; function call with an empty string to close the EXE. Re- open with the EXE
; file name as input argument to WFSE Alternate.
;
; Revision 1.27  1999/12/12 18:46:27  MikeT
; Implemented INT 1Ch autopassup. File open mode for program file is deny write
; now (as opposed to compatibility mode before). We'll do some testing and see
; whether this has any negative side effects or not.
;
; Revision 1.26  1999/11/17 21:27:57  MikeT
; Implement workaround for a DJGPP "thing": When CTRL+C or CTRL+BRK is pressed,
; the DJGPP run time alters the DS (and SS) segment limit of the main program.
; This caused a stack fault (and consequently a triple fault) when kernel code
; attempted to dwitch back to the application's stack in order to IRETD from a
; hardware interrupt or the like.
;
; We now check the validity of the application's stack first and if it turns
; out to have been tampered with, we generate kind of a "software-stackfault".
;
; Revision 1.25  1999/11/11 22:15:51  MikeT
; Fixed a bug where DPMI functions 204 and 205 would not work correctly with
; int numbers 10 thru 1Fh. The index into the table of shadowed handlers was
; off by 128 bytes.
;
; Revision 1.24  1999/06/20 16:10:20  MikeT
; Numerous changes:
;
;
;
; 1. Implemented Joergen Ibsen's WDOSX - DEPACK decompressor as the default
;    one. Old LZ77 compressed WFSE attachments are still supported, so there
;    should be no problem when re-stubbing existing executables with this
;    version. Also, Wudebug should work with compressed executables of either
;    kind.
;
; 2. Implemented a means to restrict the internal DPMI host from grabbing all
;    the memory in the system. This allowes spawning child programs which need
;    some extended memory themselfs. The maximum amount of pages that the DPMI
;    host will allocate is defined in WdosxInfo.XMemAlloc and the mechanism
;    should work with all types of memory allocation (INT 15, XMS, VCPI).
;
; 3. Save all general purpose registers when calling a real mode IRQ handler.
;    This is because some buggy DOS drivers and SCSI BIOSes trash the high
;    portion of registers in their IRQ handlers.
;
; 4. I think that was it...
;
; Revision 1.23  1999/05/27 22:56:33  MikeT
; Fixed INT 21/4B00h to always copy the trailing 0Dh, 00h, even if the
; command tail is otherwise empty.
;
; Revision 1.22  1999/02/17 22:11:45  MikeT
; Some changes to not only make it assemble with TASM 5.0 but to also
; produce identical binary results compared with these obtained with
; TASM 3.1.
;
; Revision 1.21  1999/02/16 23:25:41  MikeT
; Fix for the fix for the fix... Well, what happened was, that if we've got
; only XMS 2 and the E801 check was being done, we would not have taken into
; consideration that an XMS 2 manager does not intercept E801. Therfore, the
; memory below 16MB ended up beeing allocated twice, with all kinds of
; interesting crashes as a result. Also, the XMS3 check has been corrected
; so as to not rely on BL being nonzero for the Caldera DOS workaround.
; We only consider the XMS manager being Caldera's buggy one if the return
; code is exactly 80h (unsupported function). The reason for this change was
; that according to the XMS 3 spec. any XMS 3 manager has to return 0A0h in
; BL if all extended memory has been allocated.
;
; Revision 1.20  1999/02/13 14:07:47  MikeT
; Let INT 21 function FFFF check the caller's CS. If it doesn't match the
; initial application code segment, return an error. This allowes us to
; remove INT 21 FFFF blocking code from the true flat model executable
; loaders.
;
; Revision 1.19  1999/02/13 13:50:41  MikeT
; Updated year in EEFF copyright string.
;
; Revision 1.18  1999/02/08 23:26:49  MikeT
; If XMS version is < 3, call INT 15 E801 anyway to allow above 64M
; also on newer computers running older DOSes.
; This needs some more testing, though.
;
; Revision 1.17  1999/02/07 17:35:29  MikeT
; Updated copyright + some cosmetics. No code changes.
;
; Revision 1.16  1999/02/06 16:23:57  MikeT
; Make wdxinfo.inc local.
;
; Revision 1.15  1999/02/06 15:13:18  MikeT
; Pulled in code includes.
;
; Revision 1.14  1999/01/10 16:31:57  MikeT
; Increase the amount of DPMI memory handles from 128 to 512. That
; should let get us rid of complaints WRT available handles for good.
;
; Revision 1.13  1999/01/06 00:31:05  MikeT
; Implemented workaround for the Caldera DOS HIMEM.SYS screwup.
;
; Revision 1.12  1998/12/08 02:11:44  MikeT
; If there is a DPMI host in real mode, it usually had claimed all
; available memory anyway. Therefore, we have to negotiate.
; Fixes "Insufficient extended memory" error with 32rtm resident.
;
; Revision 1.11  1998/11/18 23:04:29  MikeT
; Some code cleanup, no change in the binary result.
;
; Revision 1.10  1998/11/18 21:10:59  MikeT
; Function EEFF now correctly returns 0 in CH if in raw (BIOS) mode.
;
; Revision 1.9  1998/10/28 00:10:51  MikeT
; Implemented INT 2F function 1686 as the braindamaged bgivga.dll of
; Borland fame is actually calling it. Why calling this function from
; within 32 bit PM is pointless should be obvious and is otherwise left
; as an exercise to the reader.
;
; Revision 1.8  1998/10/25 14:40:40  MikeT
; Fixed XMS memory size calculation bug. Workaround for a common BIOS bug
; where int 15/E801 would not reflect an extended memory hole correctly.
;
; Revision 1.7  1998/10/10 15:02:59  MikeT
; Permanently enable the 2GB check as this is the maximum memory size we can
; handle anyway.
;
; Revision 1.6  1998/10/07 20:04:17  MikeT
; Partially rewrote DPMI function 501/502/503h. This fixes a bug with
; DPMI memory allocation/deallocation.
;
; Revision 1.5  1998/09/25 00:31:31  MikeT
; Reset DTA after child program has finished. This fixes the problem
; where FindFirst/ FindNext would not work anymore after int21h 4Bh had
; been called.
;
; Revision 1.4  1998/09/12 23:13:19  MikeT
; Some corrections WRT the free XMS memory calculation when using XMS 3.0
;
; Revision 1.3  1998/09/12 18:13:31  MikeT
; First implementation of above 64MB support. Using XMS 3.0 and
; INT 15h E801h now to gather big memory information. Subject to
; further testing on as much as possible platforms before it can
; be released.
;
; Revision 1.2  1998/09/12 17:10:55  MikeT
; Change CPUID level 1 call to not expect level 0 return < 256 in EAX
; The reason for this is that I've already learned that nowadays
; BIT 31 is used to obtain extended capabilities and we don't want to
; break the extender just because of a stupid thing like this do we?
;
; Revision 1.1  1998/08/03 01:59:29  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; ############################################################################
; ## File: wdosx.asm - DOS extender kernel code                             ##
; ############################################################################

; Uncommenting this line unconditionally produces the Watcom - variant
;__WATCOM__ = 1

include	wdxinfo.inc

MajorVersion = 0
MinorVersion = 97
;
; Maximum DPMI memory blocks
; 8 bytes per block, maximum is (8k- 1) - sizeof WDOSX / 8
; The reason for chosing 512 is that this is in the range of what most DPMI
; hosts support and it makes no sense whatsoever to allow for considerably more
; handles in here.
;
MAX_MEM_HANDLES		EQU	512
;
; Maximum Wfse - FCBs (each uses 16 bytes additional memory)
;
MAX_WFSE_FCBS		EQU	20
;
; Pre - VCS Revision history:
; ---------------------------
;
; [96/06/10]	Wuschel:
;
; complete rewrite started. Goals are size optimization, some exception
; handling, DPMI- support, "cleaner" code, more stuff...
;
; [96/07/02]	Wuschel:
;
; added INT32-API
;
; [96/07/22]	Wuschel:
;
; added INT21H API, supported so far: 09H/3CH/3DH/3FH/40H
; will add more as I need it.
;
; [96/08/02]	Wuschel:
;
; moved INT32/0000 to INT21/FFFF, INT32API died	(r.i.p.:)
;
; V 0.9 released!!!
;
; [96/08/14]	Wuschel:
;
; BUG, BUG! : 21/FFFF did not set carry on error (not enough mem) - fixed
; Some jumps "hand- shorted", saved 40 bytes!
; Not enough memory for flatmode overlay error message is now
; "error loading flatmode overlay" rather than "dpmi error"
;
; [96/09/14]	Wuschel:
;
; Yet another Bug fixed: 21/40 now returns bytes written correctly
;
; [96/09/17]	Wuschel:
;
; More functions added to INT 21 API. (39, 3A, 3B, 41, 43, 5B)
; Fixed 2 Bugs in translation services - Aaaarrgggghhh!!!
; WDOSX now supports callbacks :)
;
; [96/10/06]	Wuschel:
;
; Major bugfix. Crashes because of stack reentrancy while hardware
; interrupts occur the same time a mode switch for a software interrupt
; processing is in progress. Still no idea why this could happen when
; ints are disabled...
;
; [96/12/05]	Wuschel:
;
; Some minor changes in DPMI.INC 
; - 31/0500 not filling the entire buffer - fixed
; - Get/Set/Reset VI did reset the carry flag - fixed
;
; Uninitialized variables are zeroed out right at startup
;
; [97/01/21]    Wuschel:
;
; Added support for INT 31/0202 and 0203 - get/set exception handler
; They do work to some extent but the stack has to be intact...
;
; [97/01/31]	Wuschel:
;
; Call to INT 21/62 now returns a selector rather than a segment
;
; [97/02/15]	Wuschel:
;
; Certain issues fixed with 21/FFFF memory leaks
;
; [97/03/15]	Wuschel:
;
; Fixed 31/500h to return the exact amount of free memory
;
; [97/03/18]	Wuschel:
;
; Fixed int 21/56 swapping ebx and edi
;
; [97/04/02]
;
; Added support for more extended DOS functions
; Includes sucked in so we have only one source file for WDOSX.DX
;
; [97/04/16]	Wuschel:
;
; Added support for exceptions 10h - 1fh
;
; [97/04/27]	Wuschel:
;
; What made me think 31/90x shouldn't reset the carry flag?
;
; [97/05/28]	Wuschel:
;
; Added Extended 21/4b00h
;
; [97/09/03]	Wuschel:
;
; Fixed find first/next copying more than 2ch bytes up/down
;
; [97/10/14]	Wuschel:
;
; Fixed find next returning CF set on success/ CF clear on error
;
; [97/11/05]	Wuschel:
;
; Completely rewrote int 31/0800 and 0801 due to public demand. It's now
; possible to map insane amounts of address space such as 256 or even 512
; megabytes at the cost of 4k DOS memory / 4Mb address space - have a nice
; mapping time!
;
; [97/11/06]	Wuschel:
;
; When looking back at all the change descriptions to this file I must admit
; that I recorded only every other change (on average) up here. Finally, who
; cares, considering that this sourcecode isn't to be released ever...
;
; [97/11/06]	Wuschel:
;
; And while we're at it: just a minor thingy fixed with int 31 / 070x. Not that
; anyone cares, though... 
;
; [97/11/10]	Wuschel:
;
; Long delay during cleanup under VCPI. Reason was that the address space
; above 2g was included into the cleanup check.
;
; [98/01/17]	Wuschel:
;
; Added support for WdoxInfo structure, changed the way we access unitialized
; data (no runtime implication either)
;
; [98/02/17]	Wuschel:
;
; Made the maximum number of DPMI memory handles one can have allocated at a
; time a parameter controlled by a single EQUate (MAX_MEM_HANDLES). Up to 256
; are possible, 128 should be sufficient.
;
; [98/02/22]	Wuschel:
;
; First implementation of WFSE.
;
; [98/02/27]	Wuschel:
;
; Implemented workaround for an NT bug: free the allocated callback on exit.
;
; [98/03/01]	Wuschel:
;
; Updated copyright.
;
; [98/03/08]	Wuschel:
;
; Fix 32/0006 succeeding on a zero selector.
;
; [98/03/17]	Wuschel:
;
; When running under RAW/XMS, include HMA into page tables. This solves some
; problems with DJGPP.
;
; [98/03/20]	Wuschel:
; Start implementing the decompressor.
;
; [98/04/05]	Wuschel:
; Decompressor (first shot) implemented. Supports:
; 		- load time decopression of the kernel itself
;		- run time decompression of WFSE images
; Fixed bug where wfseSeek would return an error when there actually was none.
;
; [98/04/14]	Wuschel:
; Clear high wor of EAX before chaining into the old handler for int21h/40h
; ecx = 0 (truncate file)
;
; [98/07/10]	Wuschel:
; Moved copyright string into non-compresable area.
;
;------------------------------------------------------------------------------
;... so here we go:
;
; GDT selectors (Used in RAW/XMS/VCPI mode only)
;
dosx_sel_code16	EQU	0800h
dosx_sel_data16	EQU	0808h
dosx_sel_tss	EQU	0810h
dosx_sel_data0	EQU	0818h	; use32  4g
dosx_sel_bigdos	EQU	0820h	; use16	big
dosx_selector1	EQU	0830h


dosx_selector_vcpi1	EQU	dosx_selector1
dosx_selector_vcpi2	EQU	dosx_selector1 + 8
dosx_selector_vcpi3	EQU	dosx_selector1 + 16

dosx_sel_psp		EQU	dosx_selector1 + 24
dosx_sel_env		EQU	dosx_selector1 + 32
dosx_sel_start		EQU	282*8	; first one for user program
dosx_sel_end		EQU	512*8	; last one + 1

dosx_gdtsize	EQU	512 * 8
dosx_idtsize	EQU	256 * 8
dosx_tsssize	EQU	104

.386p

stacksize		EQU	2048
dosx_intstacksize	EQU	1024
;
; PUSHAD- stackframe and DPMI realmode call structure:
;
s	struc
_edi	LABEL	DWORD
_di	dw	?
	dw	?
_esi	LABEL	DWORD
_si	dw	?
	dw	?
_ebp	LABEL	DWORD
_bp	dw	?
	dw	?
_esp	LABEL	DWORD
_spl	dw	?
	dw	?
_ebx	LABEL	DWORD
_bx	LABEL	WORD
_bl	db	?
_bh	db	?
	dw	?
_edx	LABEL	DWORD
_dx	LABEL	WORD
_dl	db	?
_dh	db	?
	dw	?
_ecx	LABEL	DWORD
_cx	LABEL	WORD
_cl	db	?
_ch	db	?
	dw	?
_eax	LABEL	DWORD
_ax	LABEL	WORD
_al	db	?
_ah	db	?
	dw	?
_oldesp	LABEL	DWORD
;
; appendix for realmode call structure
;
_flags	dw	?
_es	dw	?
_oldss	LABEL	WORD
_ds	dw	?
_fs	dw	?
_gs	dw	?
_ip	dw	?
_cs	dw	?
_sp	dw	?
_ss	dw	?	
s	ends

dosx_int31strucsize	EQU	(OFFSET _ss - OFFSET _edi) + 2

;------------------------------------------------------------------------------
; start of mixed rm and 16 bit pm- code + datasegment
;------------------------------------------------------------------------------

code16	segment	para public use16 'code'
ASSUME cs:code16, ds:code16

dosx_maxintstack	EQU	OFFSET dosx_stack
dosx_dosmemory		EQU	OFFSET ((dosx_top_of_memory-OFFSET dosx_startsegment)+15)/16

;-----------------------------------------------------------------------------
; This label indicates the start of the segment and MUST BE at offset 0!
;
dosx_startsegment	LABEL	NEAR

;- 0.95 - Insert WdosX info structure (MUST be the first thing) --------------

WdosxInfo		WdxInfo	<>

;-----------------------------------------------------------------------------
; Anything that cannot be compressed such as the decompressor itself goes
; between here and the "start:" label. The decopressed size is calculated at
; assembly time.
;
dosx_thats_me		db	'WDOSX ', MajorVersion+30h, '.'
                        db      (MinorVersion/10)+30h
                        db      MinorVersion-((MinorVersion/10)*10)+30h
                        db      ' DOS extender Copyright (c) 1996-2002 Michael Tippach', 0dh, 0ah
                        db      '<mtippach@gmx.net> http://wdosx.homeip.net/', 0dh, 0ah, 0

;**************************************************************************
;* WDOSX-Depack v1.07     Copyright (c) 1999-2001 by Joergen Ibsen / Jibz *
;*                                                    All Rights Reserved *
;*                                                                        *
;* For data and executable compression software:    http://apack.cjb.net/ *
;*                                                  jibz@hotmail.com      *
;**************************************************************************
;
; In: DS:SI -> source data
;     ES:DI -> dest. buffer
;     BX -> number of bytes to decompress
;
; Out: DS:SI -> next byte in input stream
;
; Destroys flags including DF and all general purpose registers except BP
;
WdosxDepack PROC NEAR
        push    bp
        cld
        mov     dl, 80h
        add     bx, di

literal:
        movsb

        mov     dh, 80h          ; lastwasmatch = 0

nexttagbit:
        cmp     di, bx           ; test for EOD
        jnc     DecompDone       ;

        call    getbit
        jnc     literal

        mov     ax, 1
        mov     cx, ax           ; get length
more_cx:                         ;
        call    getbit           ;
        adc     cx, cx           ;
        call    getbit           ;
        jc      more_cx          ;

more_axh:                        ; get high part of position
        call    getbit           ;
        adc     ax, ax           ;
        call    getbit           ;
        jc      more_axh         ;

        add     dh, dh           ; check lastwasmatch (and clear dh)
        sbb     ax, 2            ; same position as last match?
        jc      lastpos          ;

        or      ax, 0400h        ; get 6 low bits of position
more_axl:                        ;
        call    getbit           ;
        adc     ax, ax           ;
        jnc     more_axl         ;

        inc     ax

        cmp     ax, 1921
        sbb     cx, -1

        mov     bp, ax
lastpos:
        mov     ax, bp

        push    si               ; copy match
        mov     si, di           ;
        sub     si, ax           ;
        rep     movsb            ;
        pop     si               ;

        jmp     short nexttagbit

getbit:
        add     dl, dl           ; get a bit from tagbyte
        jnz     bitsleft         ;
        mov     dl, [si]         ;
        inc     si               ;
        adc     dl, dl           ;
bitsleft:
        ret
DecompDone:
        pop     bp
        ret
WdosxDepack ENDP

;-----------------------------------------------------------------------------

wdosx_decompress:
;
; Move the compressed data up in memory. Actually, we move more than that as
; we don't know the size of the compressed data.
;
		push	cs
		pop	ds
		push	ds
		pop	es
		mov	si, OFFSET dosx_endsegment - 1 
		mov	di, OFFSET dosx_endsegment + 4095 + 4096
		std
		mov	cx, OFFSET dosx_endsegment - OFFSET start
		rep	movsb
		xchg	di, si
		inc	si
		inc	di
		mov	bx, (OFFSET dosx_endsegment - OFFSET start)
		call	WdosxDepack
		retn


;-----------------------------------------------------------------------------
; Alternate program entry point
;
; The compressor will move the entry point in the executable header 3 bytes
; down so we would start right here if the executable was compressed.
;
		call	wdosx_decompress

; --------------------------> Program entry point <---------------------------
; Some 1 - 2k after this point must not contain run time code as this area
; is reused for temporary data storage during run time.
;
start:
;		push	cs
;		pop	ds
		mov	ah, 62h
		int	21h
		mov	es, bx		; the decompressor might have
					; killed es
		mov	ax, bx
		mov	bx, cs		; get code16
;
; Patch modeswitches, there must be no fixups left in the EXE header.
;
		mov	ds: dosx_patch1, bx
		mov	ds: dosx_patch2, bx
		mov	ds: dosx_patch3, bx

		sub	bx, ax		; get psp size
;
; Set memory block
;
		add	bx, dosx_dosmemory
		mov	ah, 4Ah
		int	21h
		jnc	SHORT dosx_no_memerror

		lea	dx, dosx_msg_nomem
		jmp	dosx_exit_raw

dosx_no_memerror:
		mov	sp, OFFSET dosx_top_of_memory
;
;- 0.94 ------- set dta ------------------------------------------------------
;
		mov	ah, 1Ah
		mov	dx, OFFSET dosx_dta
		int	21h
;
;- 0.93 ------- zero out uninitialized variables -----------------------------
;
		push	es
		push	cs
		pop	es
		cld
		sub	ax, ax
		mov	cx, OFFSET dosx_stackbegin
		mov	di, OFFSET variables
		sub	cx, di
		shr	cx, 1
		rep	stosw
		pop	es
		mov	dosx_pspseg, es
		mov	es, es:[2Ch]
		mov	dosx_envseg, es

;-------------- detect if at least 386 CPU ------------------------------------
; We throw out the 8086 detection. It did not work at all since the 8086 does
; not support the "push immediate" in the first place. The final reason why I
; throw this out is that the decompressor itself won't run on an 8086 so we'll
; never get here anyway. Bottom line: If there is this moron running a program
; like this on an 8068 they probably deserve it when we fsck up big time.
;
;		pushf				; save flags
;		mov	bx, 0f000h		; bx = cpu - info
;		push	0			; check for 8086/88
;		popf				; bits 12- 15 cannot be cleared
;		pushf
;		pop	ax
;		and	ah, bh
;		cmp	ah, bh
;               ... blah, blah, blah....
;
; Quick check for NOT 286 instead.
;
		pushf
		push	0F000h
		popf			; bits 12- 15 always clear on 286
		pushf
		pop	ax
		popf
		and	ah, 0F0h
		jnz	SHORT dosx_is386

		lea	dx, dosx_msg_wrongcpu	; the "BUY A COMPUTER!"- one
		jmp	dosx_exit_raw
;
; O.K. to use 386 ops from now on
;
dosx_is386:
		mov	cl, 3			; set to 386
		mov	dosx_mode, 0		; init mode
		pushfd				; save flags
		mov	esi, 200000h		; check for CPUID
		call	dosx_toggle
		jnz	SHORT dosx_has_cpuid

dosx_no_cpuid:
		shr	esi, 7
		call	dosx_toggle
		jz	SHORT dosx_cpu_done	; no AC-support->is 386

		inc	cl			; else is 486
		jmp	SHORT dosx_cpu_done

dosx_has_cpuid:
		sub	eax, eax
		db	0Fh, 0A2h	; CPUID

IFDEF PARANOID
		test	eax, eax
		jz	SHORT dosx_no_cpuid
ENDIF
		mov	eax, 1
		db	0Fh, 0A2h	; CPUID
		and	ah, 0Fh		; only family of interest
		mov	cl, ah		; override cpu type

dosx_cpu_done:
		popfd
		mov	dosx_cpu_type, cl

;-------------- CPU detection complete, now check some DOS stuff -------------
;
; Scan for program name + path
;
		sub	di, di
		sub	ax, ax
		mov	cx, 0FFFFh
		cld
dosx_nextenv:	
		repne	scasb
		jcxz	dosx_envbad

		scasb
		jne	SHORT dosx_nextenv

		inc	ax
		scasw
		mov	al, ah
		jne	SHORT dosx_nextenv
;
; es:di is pointing to program file now
;
		push	ds
		push	es
		pop	ds
		mov	dx, di
		mov	ax, 3d00h
		int	21h
		pop	ds
		jnc	SHORT dosx_gethandle

dosx_openerr:	
		lea	dx, dosx_msg_openerr
		jmp	dosx_exitmsg

dosx_envbad:	
;
; dunno, will this ever happen?
;
		lea	dx, dosx_msg_envbad
		jmp	dosx_exitmsg

dosx_gethandle:
;
; overwrite startup code
;
		mov	bx, ax
		mov	dosx_fhandle, ax
		mov	dx, OFFSET start
		mov	cx, 10			; read .EXE size
		mov	ah, 3Fh
		int	21h
		cmp	ax, cx
		jnz	SHORT dosx_openerr
;
; get physical file size
;
		mov	ax, 4202h
		sub	cx, cx
		sub	dx, dx
		int	21h
		jc	SHORT dosx_openerr

		shrd	edi, eax, 16
		shrd	edi, edx, 16
;
; Calculate start of overlay
;
		movzx	eax, WORD PTR ds:[2+OFFSET start]
		movzx	edx, WORD PTR ds:[4+OFFSET start]
		neg	ax
		and	ax, 1FFh
		shl	edx, 9
		sub	edx, eax
;
; Calculate overlay size
;
		sub	edi, edx
		jz	SHORT dosx_openerr	; no overlay

		shld	ecx, edx, 16
		mov	ax, 4200h
		int	21h
		jc	SHORT dosx_openerr
;
; the DOS file pointer is now set to start of OVL data
;

;
; This check has been removed in order to make it work with 32rtm loaded
;
;		smsw	ax
;		test	al, 1
;		jz	SHORT dosx_makedpmi
;
;-------------- Check if DPMI- host installed ---------------------------------
;
                mov	dosx_PMSys_EEFF, 3 ; 0.94
		mov	ax, 1687h
		int	2Fh
		test	ax, ax
		jz	dosx_havedpmi

dosx_makedpmi:
                mov	dosx_PMSys_EEFF, 0 ; 0.94
;
;-------------- create a very simple DPMI-host --------------------------------
;
protmode_used	EQU	80h
vcpi_used	EQU	2
xms_used	EQU	1
is_tsr		EQU	4
a20_used	EQU	8
ints_hooked	EQU	40h
pic1_used	EQU	20h
pages_allocated	EQU	10h

;
; Store default gdt+ idt
;
		sidt	dosx_rm_idt
		sgdt	dosx_rm_gdt
;
;-------------- XAM the machine -----------------------------------------------
;
		smsw	ax		; get low cr0
		test	al, 1		; PE?
		jz	SHORT dosx_is_rm


dosx_check_vcpi:
                mov	dosx_PMSys_EEFF, 2 ; 0.94
		mov	ax, 3567h	; check if handler installed
		int	21h
		mov	ax, es
		or	ax, bx
		jnz	SHORT dosx_have_int67

dosx_noidea:
		lea	dx, dosx_msg_nomode
		jmp	dosx_exitmsg

dosx_have_int67:
		mov	ax, 0DE00h
		int	67h
		or	ah, ah
		jnz	SHORT dosx_noidea
;
;-------------- We have a VCPI server installed -------------------------------
;
		or	dosx_mode, vcpi_used+protmode_used

dosx_is_rm:
;
;-------------- Check for XMS- driver -----------------------------------------
;
; Check if already been here
;
		test	dosx_mode, xms_used
		jnz	dosx_mode_bios

		mov	ax, 4300h
		int	2Fh
		cmp	al, 80h
		jnz	dosx_mode_bios
;
;-------------- XMS installed -------------------------------------------------
;
; Get driver entry point
;
		mov	ax, 4310h
		int	2Fh
		mov	WORD PTR [OFFSET dosx_himem], bx
		mov	WORD PTR [OFFSET dosx_himem + 2], es
		or	dosx_mode, xms_used
;
; Better to grab the mem right now so we wouldn't have to store a huge amount
; of XMS- handles. Get largest mem area out there...
;
		mov	eax, 800h
		call	dosx_xms3
		call	DWORD PTR [dosx_himem]
		test	eax, eax
		jz	SHORT dosx_mode_bios
;
; Check against the XMemAlloc parameter so as to not allocate more memory than
; necessary.
;
		mov	edx, WdosxInfo.XMemAlloc
		shl	edx, 2		; to kb
		cmp	edx, eax
		jnc	SHORT sizeNotTooBig

		mov	eax, edx

sizeNotTooBig:
		mov	edx, eax
		push	eax		; need it for adjust to page boundary
;
; Allocate the mem (hopefully not allocated by an interrupt handler inbetween)
; disable interrupts if you use this to control nuclear facilities :)
;
		mov	ah, 9
		call	dosx_xms3
		call	DWORD PTR [dosx_himem]
		mov	dosx_xmshandle, dx
;
; For we speek of linear addresses here, this is not entirely correct.
; Actually we are dealing with PHYSICAL adresses in this place!
; Anyway, Wuschel ist too lazy to change this for you, flames welcome! :)
; lock mem + get linear address
;
		mov	ah, 0Ch
		call	DWORD PTR [dosx_himem]

		shrd	eax, edx, 16
		mov	ax, bx			; eax=linear start of block
		pop	edx			; Get size of block
		shl	edx, 10			; Kb to bytes
		add	edx, eax		; EDX = end of block
		add	eax, 0FFFh		; Adjust start of block to
		and	ax, 0F000h		; page boundary.
		sub	edx, eax		; EDX = adjusted size
		shr	edx, 12			; To pages
		mov	dosx_xmssize, edx	; store size in pages
		mov	dosx_linear_start, eax	; store linear start of xms
		smsw	ax
                and     al, 1
                inc	ax
                mov	dosx_PMSys_EEFF, al	; 0.94
		cmp	al, 1
		jnz	dosx_check_vcpi

dosx_mode_bios:
;
; Preload cx with the maximum ext mem size. This will be adjusted by E801 or
; maybe not. The reason why we're doing this is that extended memory functions
; are badly broken in many BIOSes as soon as an extended memory hole is
; enabled. The AMI BIOS on the machine I'm writing this on, for instance, will
; still return 3C00h in ax and cx even though there is a memory hole at 15MB.
;
		mov	cx, -1
;
; If XMS used and XMS version is < 3, then memory above 64MB should be
; untouched so we call E801 anyway. We do, however need to adjust the
; allocation base to 65MB instead of 16MB.
;
		test	dosx_mode, (xms_used OR vcpi_used)
		jz	safeToDoE801

		test	dosx_mode, xms_used
		jz	useLegacyInt15

		mov	ah, 8
		call	dosx_xms3
		cmp	ah, 8
		jnz	useLegacyInt15
;
; Now we know that we're on XMS 2 or less. Yet we have to adjust the alloc
; base.
;
		mov	dosx_E801start, 4100000h	; start at 65MB

safeToDoE801:
;
; Check E801h first and use legacy function as a fall trough
;
		mov	ax, 0E801h
		int	15h
		jc	SHORT useLegacyInt15

		mov	ax, cx			; memory below 16k
		mov	esi, dosx_E801start
		sub	esi, 1000000h
		shr	esi, 12			; to pages
		movzx	edx, dx
		shl	edx, 4			; to pages
		sub	edx, esi
		jna	useLegacyInt15

		mov	dosx_E801size, edx
;
; Perform sanity check in case the BIOS fucked up on a memory hole. Most of
; the time, the return value of function 88h will be correct, though.
;
;		jmp	SHORT fromInt15

useLegacyInt15:
		mov	ah, 88h
		int	15h
		cmp	ax, cx
		jna	fromInt15

		mov	ax, cx

fromInt15:
;
; We don't need no stinkin' error checking...
;
		shr	ax, 2			; get pages
		mov	dosx_extsize, ax	; save size in pages
;
; No further adjust since the physical start using INT15 top down is 1MB or N/A
; though int15 should give AX=0 at least if HMA is in use. Hook int15 anyway, 
; it doesn't hurt!
;
; Hook all hardware int + int 15, 1C, 21, 23, 24
;
		cli
;
; Save all interruptvectors
;
		push	cs
		pop	es
		cld
		mov	cx, 256
		sub	si, si
		mov	ds, si
		mov	di, OFFSET dosx_intvectors
		rep	movs DWORD PTR es:[di], ds:[si]
;
; A copy of the old irq- vectors goes into the chain handler table.
;
		mov	si, 8 * 4
		mov	cl, 8
		mov	di, OFFSET dosx_oldirqs
		rep	movs DWORD PTR es:[di], ds:[si]
		mov	si, 70h * 4
		mov	cl, 8
		rep	movs DWORD PTR es:[di], ds:[si]
;
; Now hook into irqs.
;
		mov	ax, cs
		mov	es, cx
		mov	cl, 8
		mov	di, 8 * 4
		shl	eax, 16
		mov	ax, OFFSET dosx_start_irqs

dosx_setirqloop1:
		stos	DWORD PTR es:[di]
		add	ax, 4
		loop	dosx_setirqloop1

		mov	cl, 8
		mov	di, 70h * 4

dosx_setirqloop2:
		stos	DWORD PTR es:[di]
		add	ax, 4
		loop	dosx_setirqloop2

		mov	di, 15h * 4
		mov	ax, OFFSET dosx_new15
		stos	DWORD PTR es:[di]
		mov	di, 1Ch * 4
		mov	ax, OFFSET dosx_new1C
		stos	DWORD PTR es:[di]
		mov	di, 21h * 4
		mov	ax, OFFSET dosx_new21
		stos	DWORD PTR es:[di]
		mov	di, 23h * 4
		mov	ax, OFFSET dosx_new23
		stos	DWORD PTR es:[di]
		mov	ax, OFFSET dosx_new24
		stos	DWORD PTR es:[di]

dosx_old15vec	EQU	DWORD PTR [OFFSET dosx_intvectors + 4 * 15h]
dosx_old1Cvec	EQU	DWORD PTR [OFFSET dosx_intvectors + 4 * 1Ch]
dosx_old21vec	EQU	DWORD PTR [OFFSET dosx_intvectors + 4 * 21h]
dosx_old23vec	EQU	DWORD PTR [OFFSET dosx_intvectors + 4 * 23h]
dosx_old24vec	EQU	DWORD PTR [OFFSET dosx_intvectors + 4 * 24h]

		push	cs
		pop	ds
		or	dosx_mode, ints_hooked
;
;-----------------------------  enable A20 -----------------------------------
;
		cli
		call	dosx_testa20
		jnz	SHORT dosx_a20_enabled
;
; Hmm... this one is for qemm (refuses A20 enable when HMA is not in use by
; trapping port accesses)
;
		test	dosx_mode, xms_used
		jz	SHORT dosx_qemma20

		mov	ah, 5
		call	DWORD PTR [dosx_himem]

dosx_qemma20:
		or	dosx_mode, a20_used
		call	dosx_testa20
		jnz	SHORT dosx_a20_enabled

		in	al, 92h
		or	al, 2
		out	92h, al
;
; Newer chipsets have a rather long delay opening the A20 through the port 92h
; The danger here is that we end up dealing with the keyboard controller even
; though the port 92 would have worked. Considering that it's unlikely to have
; fatal consequences, we leave it this way.
;
		call	dosx_testa20
		jnz	SHORT dosx_a20_enabled

		call	dosx_wait8042
		mov	al, 0D1h
		out	64h, al
		call	dosx_wait8042
		mov	al, 0FFh
		out	60h, al
		call	dosx_wait8042
		mov	al, 0FFh
		out	64h, al
		call	dosx_wait8042
		call	dosx_testa20
		jnz	SHORT dosx_a20_enabled
;
; No idea now...
;
		lea	dx, dosx_msg_a20
		jmp	dosx_exitmsg

dosx_a20_enabled:
		sti
;
; Allocate page directory + 1st page. Get memory block.
;
		mov	bx, 3 * 256
		mov	ah, 48h
		int	21h	
		jnc	SHORT dosx_gottablemem

		lea	dx, dosx_msg_nomem
		jmp	dosx_exitmsg

dosx_gottablemem:
;
; Get the mem page aligned.
;
		mov	bx, ax
		mov	es, ax
		mov	dosx_tableblock, ax
		neg	bl
		mov	bh, 2
		mov	ah, 4Ah
		int	21h
;
; Unaligned mem is wasted.
;
		mov	ax, es
		add	ax, 0FFh
		sub	al, al
		mov	es, ax
		movzx	eax, ax
;
; Store adress in page directory[0]
;
		sub	di, di
		mov	ebx, eax
		inc	ah
		shl	eax, 4
		mov	al, 7
		stosd
		shl	ebx, 4
		mov	dosx_cr3_base, ebx
;
; Zero out pagedirectory + first page
;
		sub	eax, eax
		mov	cx, 2046 - 1024
		rep	stosw
		mov	al, 7
;
; Preset the remaining entries for use by int 31h function 800h.
;
dosx_set31800loop:
		stos	DWORD PTR es:[di]
		add	eax, 1000h
		inc	cl
		jnz	SHORT dosx_set31800loop

		sub	ax, ax
		mov	cx, 512 + 2048
		rep	stosw
;
; Prepare to fill
;
		mov	di, 4096
		test	dosx_mode, vcpi_used
		jnz	SHORT dosx_de01

		mov	dosx_raw2rm, OFFSET dosx_prot2rm
		mov	dosx_raw2pm, OFFSET dosx_rm2prot
;
; Realmode fill goes from 0 to 1 Meg.
; 0.95: we inlude the HMA as some sick software really scans the HMA from
; within protected mode.
;
		sub	eax, eax
		mov	al, 7
		mov	cx, 256 + 16

dosx_fillfirsttableloop:
		stos	DWORD PTR es:[di]
		add	eax, 1000h
		loop	dosx_fillfirsttableloop
		jmp	SHORT dosx_pagesdone

dosx_de01:
		mov	dosx_raw2rm, OFFSET dosx_prot2v86
		mov	dosx_raw2pm, OFFSET dosx_v862prot
		mov	si, OFFSET dosx_gdt + dosx_selector_vcpi1
		mov	ax, 0DE01h
		int	67h
		mov	dosx_vcpiOFFSET, ebx
		mov	dosx_vcpisel, dosx_selector_vcpi1

dosx_pagesdone:
;
;-------------- IDT setup -----------------------------------------------------
;
; INTEL vs. IBM :(
; First 16 interrupts are exceptions (IOW don't call the printscreen handler
; as INT 05 from pm)
;
		push	cs
		pop	es
		mov	di, OFFSET dosx_idt
		mov	edx, 8E00h		; type = interrupt gate
		mov	eax, 80000h
		mov	ebx, eax
		mov	cl, 16
		mov	ax, OFFSET dosx_hnd_exception
		call	dosx_storeidt
;
; (V 0.93) set #1 and #3 to trap gate
;
		mov	BYTE PTR ds:[OFFSET dosx_idt + 8+5], 8Fh
		mov	BYTE PTR ds:[OFFSET dosx_idt + 3*8+5], 8Fh
;
; WDOSX 0.94 supports exceptions 10h - 1Fh
;
		mov	cl, 16
		mov	ax, OFFSET dosx_hnd_10to1F
		call	dosx_storeidt
;
; Now 224 interrupts (patch INT 31H later)
;
		mov	cl, 224
		mov	ax, OFFSET dosx_hnd_interrupt
		call	dosx_storeidt
;
; Now patch int31
;
		mov	WORD PTR ds:[OFFSET dosx_idt + 8 * 31h], OFFSET dosx_int31
;
; WDOSX 0.94: Initialize Interrupt table for interrupts 10..1F
;
		mov	ax, OFFSET dosx_hnd_interrupt
		mov	dx, 88h				; first cs: selector
		mov	si, OFFSET dosx_int10to1F
		mov	cx, 16

dosx_highExc:
		mov	[si], ax
		mov	[si + 4], dx
		add	si, 8
		add	dx, 8
		loop	SHORT dosx_highExc
;
; Prepare for IDT fixup.
;
		mov	bx, 8
		mov	cx, 70h
		test	dosx_mode, vcpi_used
		jz	SHORT dosx_nopicfixup

		mov	ax, 0DE0Ah
		int	67h

dosx_nopicfixup:
		mov	dosx_pic1map, bl
		mov	dosx_pic2map, cl
		push	cx
		shl	bx, 3
		lea	si, [bx+OFFSET dosx_idt]
		mov	di, OFFSET dosx_pic1backup
		push	si
		mov	cl, 8
;
; Get old "non-irqs"
;
dosx_picloop1:
		lods	DWORD PTR ds:[si]
		add	si, 4
		stosw
		stos	DWORD PTR es:[di]
		mov	WORD PTR [di-4], 0
		mov	WORD PTR [di], 0
		add	di, 2
		loop	dosx_picloop1
		mov	edx, 8E00h			; type = interrupt gate
		mov	eax, 80000h * 8 + OFFSET dosx_hnd_checkpic1
		mov	ebx, 80000h
		pop	di
		mov	cl, 8
		call	dosx_storeidt
		pop	bx
		shl	bx, 3
		lea	si, [bx+OFFSET dosx_idt]
		mov	di, OFFSET dosx_pic2backup
		push	si
		mov	cl, 8

dosx_picloop2:
		lods	DWORD PTR ds:[si]
		add	si, 4
		stosw
		stos	DWORD PTR es:[di]
		mov	WORD PTR [di-4], 0
		mov	WORD PTR [di], 0
		add	di, 2
		loop	dosx_picloop2
				
		mov	eax, 80000h * 16 + OFFSET dosx_hnd_checkpic2
		mov	ebx, 80000h
		pop	di
		mov	cl, 8
		call	dosx_storeidt
;
; Now initialize default irq handlers.
;
		mov	cl, 16
		mov	eax, OFFSET dosx_hnd_irq + 80000h * 8
		mov	di, OFFSET dosx_pmirqtab

dosx_picloop3:
		stosw
		stos	DWORD PTR es:[di]
		mov	WORD PTR [di-4], 0
		mov	WORD PTR [di], 0
		add	di, 2
		add	eax, ebx
		loop	dosx_picloop3
;
; Set up VCPI switch structure (even w/o VCPI it doesn't hurt)
;
		mov	eax, OFFSET dosx_v862prot1
		mov	dosx_pm_selector, dosx_sel_code16
		mov	dosx_pm_offset, eax
		mov	dosx_gdtr_linear, OFFSET dosx_gdtr
		mov	dosx_idtr_linear, OFFSET dosx_idtr
		mov	dosx_v86struc, OFFSET dosx_cr3_base
		mov	dosx_tr_dummy, dosx_sel_tss
		mov	dosx_ldt_dummy, 0
;
;-------------- IDT setup now complete, build GDT ----------------------------
;
; selectors 1 up to 257 are base code16 use16, limit 64k BYTE granularity....
;
		mov	di, OFFSET dosx_gdt + 8
		sub	dx, dx
		sub	eax, eax
		mov	ax, cs
		sub	ebx, ebx
		shld	edx, eax, 20
		shl	eax, 20
		mov	dh, 9Eh
		dec	ax		; limit = 0ffffh
		mov	cx, 257
		call	dosx_storeidt	; abuse of idtloopproc
;
; Adjust the last one to be a data descriptor instead.
;
		mov	BYTE PTR [di - 3], 92h
;
; TSS - descriptor:
;
		add	eax, LARGE (OFFSET dosx_dummytss - OFFSET dosx_startsegment) * 10000h - 0fffffh + dosx_tsssize -1
		adc	dx, 8900h - 9E00h
		stosd
		mov	[di], edx
;
; Huge 4g use32 data base 0. 2DO: check whether this one's still used.
;
		mov	DWORD PTR [di + 4], 0FFFFh
		mov	DWORD PTR [di + 8], 0CF9200h
;
; Another huge one use16
;
		mov	DWORD PTR [di + 12], 0FFFFh
		mov	DWORD PTR [di + 16], 8F9200h
;
; Next one is unused so far
;
; Skip vcpi descriptors, create psp- descritor.
;
		movzx	eax, dosx_pspseg
		mov	es, ax
		shl	eax, 4
		add	eax, 92000000h
		mov	WORD PTR [di + 52], 0FFh
		mov	DWORD PTR [di + 54], eax
;
; 0.93 make it accessible by DPMI calls. 2DO: this seems unnecessary now...
;
		mov	WORD PTR [di + 58], 10h
;
; Create environment- descritor
;
		movzx	eax, WORD PTR es:[2Ch]
		mov	WORD PTR es:[2Ch], dosx_sel_env
		shl	eax, 4
		add	eax, 92000000h
		mov	WORD PTR [di + 60], 0FFFFh
		mov	DWORD PTR [di + 62], eax
;
; 0.93 as above. Again, this is most likely obsolete...
;
		mov	WORD PTR [di + 66], 10h
;
;------------------------------------------------------------------------------
;
; Now set some pointers.
;
		mov	WORD PTR [OFFSET dosx_gdtr], dosx_gdtsize - 1
		mov	WORD PTR [OFFSET dosx_idtr], dosx_idtsize - 1
		sub	eax, eax
		mov	ax, cs
		shl	eax, 4
;
; Fixup linear adresses
;
		add	dosx_gdtr_linear, eax
		add	dosx_idtr_linear, eax
		add	dosx_v86struc, eax
;
; Store values to load into gdtr, idtr
;
		add	eax, LARGE OFFSET dosx_gdt
		mov	DWORD PTR [OFFSET dosx_gdtr + 2], eax
		add	eax, LARGE (OFFSET dosx_idt - OFFSET dosx_gdt)
		mov	DWORD PTR [OFFSET dosx_idtr + 2], eax
		call	WORD PTR [dosx_raw2pm]
;
; Now we are either crashed or in 16:16 PM.
; Build huge linear block until no more pages avail.
; Make sure we can access all the memory.
;
		sti
		mov	ax, dosx_sel_data0
		mov	es, ax
;
; esi ^ pagedirectory
;
		mov	esi, dosx_cr3_base
		add	si, 4			; index second entry
;
; now the sequence is:	- get page for pagetable
;			- update pagedir
;		  	- zero out pagetable
;			- 1024 times get page, store in pagetable
;			- loop
;		abort anytime if no more pages available
;
dosx_next_page_table:
		call	dosx_getpage
		jc	SHORT dosx_malloc_done

		mov	es:[esi], edx
;
; Use last page table entry in first page table as scratchpad to access
; the page table itself.
;
		call	dosx_set_edi
;
; edi ^first entry in pagetable
;
		add	esi, 4
		mov	ecx, 1024

dosx_next_page_entry:
		call	dosx_getpage
		jc	SHORT dosx_zero_out

		inc	DWORD PTR ds:[OFFSET dosx_memavail]
;
; When running that thing on an 8GB machine (I did), we don't want to crash...
;
		cmp	DWORD PTR ds:[OFFSET dosx_memavail], 80000h
		jnc	SHORT dosx_malloc_done

		mov	es:[edi], edx
		add	edi, 4
		loop	SHORT dosx_next_page_entry

		jmp	SHORT dosx_next_page_table

dosx_zero_out:	
		sub	eax, eax
		rep	stos DWORD PTR es:[edi]

dosx_malloc_done:
;
; Clear the TLB
;
		mov	eax, cr3
		mov	cr3, eax
		push	ds
		pop	es
;
; Initialize MCB area to not used
;
		mov	cx, MAX_MEM_HANDLES * 4
		mov	di, OFFSET dosx_mcb
		sub	ax, ax
		rep	stosw
;
; Set ES according to dpmi spec, leave fs, gs initialized
;
		mov	ax, dosx_sel_psp
		mov	es, ax
;
; Now that we can sucessfully pretend to be a DPMI host, jump to the point
; where we don't care anymore about how we did the mode switch.
;
		cli
		jmp	SHORT dosx_welcomepm
;
; Here we go if there was a DPMI- host already hanging around
;
dosx_havedpmi:
		test	bl, 1			; is host 32 bit?
;		jnz	SHORT dosx_host_is32
		jz	dosx_makedpmi		; If not, pray that we have
						; other means to get into PM
;		lea	dx, dosx_msg_dpmi16
;		jmp	SHORT dosx_exitmsg

;dosx_host_is32:
;
; Store entry point
;
		mov	WORD PTR [OFFSET dosx_dpmi], di
		mov	WORD PTR [OFFSET dosx_dpmi+2], es
;
; Do we need memory?
;
		test	si, si
		jz	SHORT dosx_modeswitch
;
; Grab some if yes.
;
		mov	bx, si
		mov	ah, 48h
		int	21h
		jnc	SHORT dosx_modeswitch

		lea	dx, dosx_msg_nomem
		jmp	SHORT dosx_exitmsg

dosx_modeswitch:
		mov	es, ax
		mov	ax, 1
		call	DWORD PTR [dosx_dpmi]
		jnc	SHORT dosx_welcomepm

		lea	dx, dosx_msg_dpmierr
		jmp	SHORT dosx_exitmsg
;
; Everything from the START label up to this point could be used as rm- stack!
; (startup code that we don't need anymore)
;
		ALIGN WORD

dosx_dpmierror:	
;
; Called if dpmi-host returns carry during startup. At this point we cannot
; make the assumption that our extended API has been initialized.
;
		lea	dx, dosx_msg_dpmi

dosx_pm_error:
		mov	ds, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		push	ds
		pop	es
		mov	edi, OFFSET dosx_int31struc
		mov	_ah[di], 9
		mov	ax, dosx_patch1
		mov	_ds[di], ax
		mov	_dx[di], dx
		sub	cx, cx
		mov	bl, 21h
		mov	ax, 300h
		int	31h
		mov	ax, 4CFFh
		int	21h

dosx_exitmsg:	
		push	dx
		call	dosx_killdpmi
		pop	dx

dosx_exit_raw:
		push	cs
		pop	ds
		mov	ah, 9
		int	21h
		mov	ax, 4CFFh
		int	21h
;
; Now in pm, if there was no DPMI- host installed, the makedpmi- "function"
; will jmp right here.
;
dosx_welcomepm:

;- 0.94 ------- initialize DTA to PSP to stay compatible with 0.93 ------------

		mov	DWORD PTR ds:[OFFSET dosx_dta_offset], 80h
		mov	WORD PTR ds:[OFFSET dosx_dta_selector], es
;
; Initialize int31 callback structure
;
		mov	ax, ds
		mov	ss, ax
		mov	sp, OFFSET dosx_top_of_memory
		mov	ax, dosx_patch1
		mov	WORD PTR dosx_int31struc._ss, ax
		mov	WORD PTR dosx_int31struc._sp, \
                                                ((OFFSET dosx_dpmierror \
                                                - OFFSET dosx_startsegment \
                                                - 4) / 4) * 4
		mov	WORD PTR dosx_int31struc._flags, 0
;
; Enable VI
;
		mov	ax, 0901h
		int	31h
		mov	dosx_flat_sel_data16, ds
                mov	dosx_pspsel, es
;
; Set default exception handlers
;
		mov	cx, cs
		mov	edx, OFFSET Exc0To15
		sub	bx, bx

E0to15Loop:
		mov	ax, 0203h
		int	31h
		inc	bx
		add	dx, 6
		cmp	bl, 16
		jne	SHORT EndOfExLoop

		mov	dx, OFFSET Exc16To32

EndOfExLoop:
		cmp	bl, 32
		jne	E0to15Loop
;
; Get int 21 handler NOW, otherwise DPMI call 100 etc would crash
;
		mov	bl, 21h
		mov	ax, 204h
		int	31h
		jc	dosx_dpmierror

		mov	dosx_old21_sel, cx
		mov	dosx_old21_ofs, edx
;
; Save old int 31h vector
;
		mov	bl, 31h
		mov	ax, 204h
		int	31h
		jc	dosx_dpmierror
		mov	dosx_old31_sel, cx
		mov	dosx_old31_ofs, edx
;
; Hook int 31 for identification call
;
                mov     cx, cs
                mov     edx, OFFSET dosx_hook31
                inc     ax
                int     31h
		jc	dosx_dpmierror
;
; Save old int 33h vector
;
		mov	bl, 33h
		dec	ax
		int	31h
		jc	dosx_dpmierror

		mov	dosx_old33sel, cx
		mov	dosx_old33ofs, edx
;
; Hook int 33 for extended mouse API
;
		mov	cx, cs
		mov	edx, OFFSET dosx_new_int33
		inc	ax
		int	31h
		jc	dosx_dpmierror
;
; Allocate callback for ext. mouse function
;
		push	es
		push	ds
		pop	es
		push	ds
		push	cs
		pop	ds
		mov	esi, OFFSET dosx_int33callback
		mov	edi, OFFSET dosx_int33struc
		mov	ax, 303h
		int	31h
		jc	dosx_dpmierror

		pop	ds
		mov	dosx_mouse_rmcallback_ofs, dx
		mov	dosx_mouse_rmcallback_seg, cx
		pop	es

		; allocate transfer buffer

		mov	bx, 400h		; 16k to allocate
		mov	ax, 100h
		int	31h
		jc	dosx_dpmierror
;
; Returns: AX base, DX selector
; Store base in int31 struc
;
		mov	dosx_flat_sel_dos, dx
		mov	dosx_flat_seg_dos, ax
		mov	dosx_int31struc._ds, ax
		mov	dosx_int31struc._es, ax
;
; Allocate code and data descriptor for flat segment
;
		sub	ax, ax
		mov	cx, 2
		int	31h
		jc	dosx_dpmierror
;
; Store selector in bp for later use
;
		mov	bp, ax
		mov	dosx_flat_sel_data, ax
;
; Get increment
;
		mov	ax, 3
		int	31h
		add	ax, bp
;
; Set code selector for far jmp
;
		mov	dosx_jmpinto_sel, ax
		mov	dosx_flat_sel_code, ax
		mov	bx, ax
		mov	ax, 8
		mov	cx, -1
		mov	dx, cx
		int	31h
		jc	dosx_dpmierror

		mov	bx, bp
		int	31h		
		jc	dosx_dpmierror
;
; Get cpl to use in "set access rights"
;
		lar	cx, bx
		mov	cl, ch
		and	cl, 060h
		or	cl, 092h
		mov	ch, 0c0h
		mov	ax, 9
		int	31h
		jc	dosx_dpmierror

		mov	bx, dosx_jmpinto_sel
		or	cl, 9ah
		int	31h
		jc	dosx_dpmierror
;
; Move dos- related api to int21h
;
		mov	bl, 21h
		mov	ax, 205h
		mov	cx, cs
		mov	edx, OFFSET dosx_int21api
		int	31h
		jc	dosx_dpmierror

IFDEF __WATCOM__
		sub	bx, bx
		mov	cx, (OFFSET dosx_lestruc_end-OFFSET dosx_lestruc_start+1024+15) and 0fff0h
		push	bp
;
; bx:cx will be popped as esp at the very end of this
;
		push	bx
		push	cx
		mov	ax, 501h
		int	31h
		lea	dx, dosx_msg_noextmem
		jc	dosx_pm_error

		mov	WORD PTR ds:[OFFSET dosx_flat_handle], di
		mov	WORD PTR ds:[OFFSET dosx_flat_handle+2], si
;
; Set descriptor base for new cs, ds
;
		mov	ax, 7
		mov	dx, cx
		mov	cx, bx
		mov	bx, dosx_jmpinto_sel
		int	31h
		jc	dosx_dpmierror

		mov	bx, bp
		int	31h
		jc	dosx_dpmierror
;
; Copy executable image
;
		mov	es, bx
		sub	di, di
		mov	cx, (OFFSET dosx_lestruc_end-OFFSET dosx_lestruc_start+1)/2
		cld
		mov	si, OFFSET dosx_lestruc_start
		rep	movsw
;
; Set entry parameters
;
		mov	bx, dosx_fhandle
		mov	ax, 0900h
		int	31h
		lss	esp, [esp]
		mov	es, dosx_pspsel
		mov	ds, bp
;
; jmp to LE loader
;
			db	0EAh
dosx_jmpinto_offset	dw	0
dosx_jmpinto_sel	dw	?

ELSE		; !__WATCOM__
;
; Get current file pointer
;
		mov	bx, dosx_fhandle
		sub	cx, cx
		sub	dx, dx
		mov	ax, 4201h
		int	21h
		push	ax
		push	dx
;
; Read first 22 BYTE
;
		mov	edx, OFFSET start
		mov	ah, 3Fh
		mov	ecx, 22
		mov	bx, dosx_fhandle
		int	21h
		lea	dx, dosx_msg_openerr
		jc	dosx_pm_error

		cmp	ax, 22
		jc	SHORT dosx_is_binary
;
; Check for .exe - header
;
		cmp	WORD PTR ds:[OFFSET start], 'ZM'
		jnz	SHORT dosx_is_binary

;-------------- MZ EXE ------------------------
; check for no relocation
; removed 0.94 to support David Lindauers compiler
;
;		cmp	WORD PTR ds:[6], 0
;		jnz	dosx_pm_error

		; calc needed memory

		movzx	eax, WORD PTR ds:[20+OFFSET start]
		mov	dosx_jmpinto_offset, eax
		movzx	eax, WORD PTR ds:[4+OFFSET start]
		movzx	edx, WORD PTR ds:[8+OFFSET start]
		shl	eax, 9
		movzx	esi, WORD PTR ds:[2+OFFSET start]
		neg	si
		and	si, 511
		sub	eax, esi
		shl	dx, 4
		sub	eax, edx
		push	eax
		sub	cx, cx
		sub	dx, 22
		mov	ax, 4201h
		jmp     SHORT dosx_getfmem
;
; FLAT FORM BINARY ONLY:
;
dosx_is_binary:
;
; Set fp to eof
;
		sub	cx, cx
		sub	dx, dx
		mov	ax, 4202h
		int	21h
;
; Calc needed memory
;
		mov	si, dx
		pop	cx
		pop	dx
		sub	ax, dx
		sbb	si, cx
;
; Required amount of memory in si:ax
;
		push	si
		push	ax
;
; Set filepointer back to where it's been before
;
		mov	ax, 4200h

dosx_getfmem:
		int	21h
		pop	cx
		pop	bx
;
; Zero- test
;
		mov	ax, bx
		or	ax, cx
		lea	dx, dosx_msg_openerr
		jz	dosx_pm_error
;
; Get # of bytes to read
;
		mov	di, bx
		shl	edi, 16
		mov	di, cx
;
; Align on DWORD and add stack
;
		add	cx, 1027
		adc	bx, 0
		and	cl, 0FCh
;
; Save initial esp
;
		push	bx
		push	cx
;
; Allocate memory block for application
;
		push	edi
		mov	ax, 501h
		int	31h
		lea	dx, dosx_msg_noextmem
		jc	dosx_pm_error

		mov	WORD PTR ds:[OFFSET dosx_flat_handle], di
		mov	WORD PTR ds:[OFFSET dosx_flat_handle+2], si
;
; Set descriptor base for new cs, ds
;
		mov	ax, 7
		mov	dx, cx
		mov	cx, bx
		mov	bx, dosx_jmpinto_sel
		int	31h
		jc	dosx_dpmierror

		mov	bx, bp
		int	31h
		jc	dosx_dpmierror

		pop	edi
;
; Read file into memory
;
		sub	edx, edx
		mov	bx, dosx_fhandle
		push	ds
		mov	ds, bp
		mov	ecx, edi
		mov	ah, 3Fh
		int	21h
		pop	ds
		lea	dx, dosx_msg_openerr
		jc	dosx_pm_error

		cmp	eax, edi
		jnz	dosx_pm_error
;
; Close file if WFSE not present.
;
		test	cs: WdosxInfo.WdxInfo.WfseStart, -1
		jnz	SHORT wfse_skip_close

		mov	ah, 3eh
		int	21h
;
; This may fail, but it's not a fatal condition so what?
;
wfse_skip_close:
;
; starting convention:
; es		= psp- selector
; cs, ds, ss	= flat segment
; esp		= user file size + stack size (1k), DWORD aligned
; eip		= 0
; interrupts disabled!
; all other registers - undefined
;
; Switch stacks
;
		mov	ax, 0900h
		int	31h
		pop	esp
		mov	ss, bp
		mov	ds, bp
;
; jmp to user program
;
			dw	0EA66h
dosx_jmpinto_offset	dd	0
dosx_jmpinto_sel	dw	?

ENDIF		; __WATCOM__/ELSE

; ############################################################################
;
; Partially rewritten INT21 API
;
; ############################################################################

dosx_32dsdx	db	09h, 39h, 3Ah, 3Bh, 3Ch, 3Dh, 41h, 43h, 4Eh, 5Ah, 5Bh
		db	3Fh, 40h, 56h, 47h, 51h, 62h, 1Ah, 2Fh, 4Fh, 25h, 35h
		db	1Bh, 1Ch, 1Fh, 32h, 34h, 48h, 49h, 4Ah, 44h, 4Bh, 4Ch
		db	0FFh

		align WORD

dosx_whatapi	dw	OFFSET dosx_dosopencreate
		dw	OFFSET dosx_dosopencreate
		dw	OFFSET dosx_dosopencreate
		dw	OFFSET dosx_dosopencreate
		dw	OFFSET dosx_dosopencreate
		dw	OFFSET dosx_dosopencreate
		dw	OFFSET dosx_dosopencreate
		dw	OFFSET dosx_dosopencreate
		dw	OFFSET dosx_dosopencreate
		dw	OFFSET dosx_dosopencreate
		dw	OFFSET dosx_dosopencreate
		dw	OFFSET dosx_dosread
		dw	OFFSET dosx_doswrite
		dw	OFFSET dosx_rename
		dw	OFFSET dosx_getdir
		dw	OFFSET dosx_getpsp
		dw	OFFSET dosx_getpsp
		dw	OFFSET dosx_setdta
		dw	OFFSET dosx_getdta
		dw	OFFSET dosx_findnext
		dw	OFFSET dosx_setintvec
		dw	OFFSET dosx_getintvec
		dw	OFFSET dosx_conv_dsbx
		dw	OFFSET dosx_conv_dsbx
		dw	OFFSET dosx_conv_dsbx
		dw	OFFSET dosx_conv_dsbx
		dw	OFFSET dosx_conv_esbx
		dw	OFFSET dosx_2148
		dw	OFFSET dosx_2149
		dw	OFFSET dosx_214A
		dw	OFFSET dosx_2144
		dw	OFFSET dosx_214b
		dw	OFFSET dosx_upon_exit
;
; ############################################################################
;
dosx_int21api:
		; decide whether our proprietary API has been called

		cmp	ah, 0ffh
		jnz	dosx_is_DOS_fn
;
; 0.95 intercept WFSE calls
;
		cmp	al, 0FDh		; WFSE?
		jne	dosx_notwfse

		shr	eax, 16
		push	si
		sub	si, si

WfseCheckApi:
		cmp	ah, BYTE PTR cs: [si+OFFSET WfseFunctionTable]
		jz	SHORT WfseApiGet

		inc	si
		cmp	BYTE PTR cs: [si+OFFSET WfseFunctionTable], 0FFh
		jnz	SHORT WfseCheckApi

		jmp	dosx_int21_chain

WfseApiGet:
		add	si, si
		mov	si, WORD PTR cs: [si+OFFSET WfseFunctions]
		xchg	si, [esp]
		retn

;-----------------------------------------------------------------------------
; Invalidate wfse context
;
WfseInvalidate PROC NEAR
                push    ds
                mov     ds, cs: dosx_flat_sel_data16
                mov     WORD PTR ds: wfse_current_handle, 0
                pop     ds
                retn
WfseInvalidate ENDP

WfseAlternate:
;
; Check for an empty string and just close the EXE in that case
;
		cmp	BYTE PTR ds:[edx], 0
		jne	WfseAltRealfile
;
; Mark all WFSE related info as invalid
;
                push    ds
		push	bx
                mov     ds, cs: dosx_flat_sel_data16
		sub	bx, bx
                mov     WORD PTR ds: wfse_current_handle, bx
		xchg	bx, ds: dosx_fhandle
		mov	ah, 3Eh
		int	21h
		pop	bx
                pop     ds
		jmp	WfseCommonOk

WfseAltRealfile:
;
; DS:EDX -> File name
;
		mov	ax, 3D00h
		int	21h
		jc	WfseCommonError

		push	ds
		push	bx
		push	ecx
		push	edx
		mov	ds, cs:[dosx_flat_sel_dos]
                call    WfseInvalidate
		mov	bx, ax
		mov	ah, 3Fh
		sub	edx, edx
		mov	ecx, 10
		int	21h
		jc	WfseAltFail

		cmp	ax, cx
		jne	WfseAltFail

		mov	dx, WORD PTR ds:[8]
		shl	dx, 4
		sub	cx, cx
		mov	ax, 4200h
		int	21h
		jc	WfseAltFail

		mov	ecx, WDXINFO_REV1_SIZE
		mov	ah, 3Fh
		sub	edx, edx
		int	21h
		jc	WfseAltFail

		cmp	ax, cx
		jne	WfseAltFail

		cmp	DWORD PTR ds:[0], 'XdW$'
		jne	WfseAltFail

		mov	eax, DWORD PTR ds:[OFFSET WdxInfo.WfseStart]
		mov	ds, cs:[dosx_flat_sel_data16]
		xchg	bx, ds:dosx_fhandle
		test	ds: WdosxInfo.WdxInfo.WfseStart, -1
		mov	ds: WdosxInfo.WdxInfo.WfseStart, eax
		jz	WfseAltNoclose

		test	bx, bx
		jz	WfseAltNoclose

		mov	ah, 3Eh
		int	21h
		
WfseAltNoclose:
		clc
		jmp	WfseAltOk

WfseAltFail:
		mov	ah, 3Eh
		int	21h
		stc
WfseAltOk:
		pop	edx
		pop	ecx
		pop	bx
		pop	ds
		jc	WfseCommonError
		jmp	WfseCommonOk

WfseInstall:
		mov	eax, 57465345h
		mov	ebx, 1

WfseCommonOk:
		and	BYTE PTR [esp+8], 0FEh
		iretd

WfseOpen:
;
; - 0.95 quick WFSE install check -------------------------------------------
;
		cmp	cs: WdosxInfo.WdxInfo.WfseStart, 0
		jz	WfseCommonError
;
; Handle closed?
;
		cmp	cs: dosx_fhandle, 0
		jz	WfseCommonError

		cmp	al, 0
		jne	WfseCommonError
;
; Find a free FCB
;
		sub	eax, eax

WfseGetHandle:
		test	DWORD PTR cs:[eax*8].WfseFcbs.WfseFCB.WfseFileStart, -1
		je	SHORT WfseGotHandle

		inc	ax
		inc	ax
		cmp	ax, MAX_WFSE_FCBS*2
		jc	SHORT WfseGetHandle
		jmp	WfseCommonError

WfseGotHandle:
		push	es
		push	edx
		push	ecx
		push	eax
		mov	es, cs:dosx_flat_sel_dos
                call    WfseInvalidate
		call	HWfseFindFirst
		jnc	SHORT WfseNameCmpFirst

WfseOpenPopError:
		pop	eax
		pop	ecx
		pop	edx
		pop	es
		jmp	WfseCommonError

WfseDoFindNext:
		call	HWfseFindNext
		jc	SHORT WfseOpenPopError
				
WfseNameCmpFirst:
		sub	ecx, ecx
WfseNameCmpNext:
		mov	al, ds:[edx+ecx]
		mov	ah, es:[ecx+ OFFSET WfseInfo.WfseFileName]
		inc	ecx

		call	HWfseToLower
		xchg	al, ah
		call	HWfseToLower

		cmp	al, ah
		jne	WfseDoFindNext

		or	al, ah
		jne	SHORT WfseNameCmpNext

		pop	edx

		call	HWfseGetFilePointer	; This probably wouldn't fail
;
; eax = File pointer
; edx = table index * 2
; ecx = size of WFSE string
;
		push	ds
		mov	ds, cs:[dosx_flat_sel_data16]
		lea	eax, [eax+ecx+OFFSET WfseInfo.WfseFileName]
		mov	ds:[edx*8].WfseFcbs.WfseFCB.WfseFileStart, eax
		and	ds:[edx*8].WfseFcbs.WfseFCB.WfseFilePos, 0
;
; As the only form currently allowed is uncompressed, the logical size of the
; file is the size of raw data
;
		mov	eax, DWORD PTR es:[OFFSET WfseInfo.WfseVirtualSize]
		mov	ds:[edx*8].WfseFcbs.WfseFCB.WfseFileSize, eax
		mov	eax, DWORD PTR es:[OFFSET WfseInfo.WfseFlags]
		mov	[edx*8].WfseFcbs.WfseFCB.WfseFlags, eax
		lea	eax, [edx*8+8000h]

		pop	ds
		pop	ecx
		pop	edx
		pop	es
		jmp	WfseCommonOk

WfseCommonError:
		or	BYTE PTR [esp+8], 1
		iretd

WfseClose:
		call	HWfseVerifyHandle
		jc	WfseCommonError

		push	ds
		mov	ds, cs:[dosx_flat_sel_data16]
		and	ds:[bx-8000h].WfseFcbs.WfseFCB.WfseFileStart, 0
		pop	ds
		jmp	WfseCommonOk

WfseRead:
		call	HWfseVerifyHandle
		jc	WfseCommonError
;
; Check whether the file is compressed
		test	cs: [bx-8000h].WfseFcbs.WfseFCB.WfseFlags, WFSE_COMP_ANY
		jz	WfseIsUncompressed

		call	WfseReadDecomp
		jc	WfseCommonError
		jmp	WfseCommonOk

WfseIsUncompressed:
		push	ecx
		push	es
		mov	es, cs:[dosx_flat_sel_data16]
		mov	eax, es:[bx-8000h].WfseFcbs.WfseFCB.WfseFileStart
		add	eax, es:[bx-8000h].WfseFcbs.WfseFCB.WfseFilePos
		call	HWfseSetFilePointer
		jc	WfseReadError

		mov	eax, es:[bx-8000h].WfseFcbs.WfseFCB.WfseFileSize
		sub	eax, es:[bx-8000h].WfseFcbs.WfseFCB.WfseFilePos
		jz	WfseReadError

		cmp	eax, ecx
		jnc	WfseDoRead

		mov	ecx, eax

WfseDoRead:
		push	bx
		mov	bx, cs:dosx_fhandle
		mov	ah, 3Fh
		int	21h
		pop	bx
		jc	WfseReadError

		add	es:[bx-8000h].WfseFcbs.WfseFCB.WfseFilePos, eax

WfseReadError:
		pop	es
		pop	ecx
		jc	WfseCommonError
		jmp	WfseCommonOk

WfseSeek:
		cmp	al, 3
		jnc	WfseCommonError

		call	HWfseVerifyHandle
		jc	WfseCommonError

		push	ds
		push	ecx
		mov	ds, cs:[dosx_flat_sel_data16]

		shl	ecx, 16
		mov	cx, dx
		cmp	al, 0
		jz	WfseSeekDoIt

		cmp	al, 1
		jnz	WfseSeekEnd

		add	ecx, ds:[bx-8000h].WfseFcbs.WfseFCB.WfseFilePos
		jmp	WfseSeekDoIt

WfseSeekEnd:
		add	ecx, ds:[bx-8000h].WfseFcbs.WfseFCB.WfseFileSize

WfseSeekDoIt:
		cmp	ecx, ds:[bx-8000h].WfseFcbs.WfseFCB.WfseFileSize
		ja	WfseSeekExit

		mov	ds:[bx-8000h].WfseFcbs.WfseFCB.WfseFilePos, ecx
		mov	ax, cx
		shr	ecx, 16
		mov	dx, cx
		sub	cx, cx		; set flags to na

WfseSeekExit:
		pop	ecx
		pop	ds
		ja	WfseCommonError
		jmp	WfseCommonOk

;-----------------------------------------------------------------------------
; INCLUDE THE CACHEING DECOMPRESSION READER
;
;#############################################################################
; The structure of a WFSE compressed file is a follows:
;
; OFFSET
;   0       WFSE header with compression flag set ("H")
; H + 0     Offset to block directory from H + 0
; H + 2     Size of last compressed block
; H + 4     size of decompressor (max 2048 bytes) if 0: use build-in; 
; H + 6..   decompressor (if any)
;
; The block directory is an array of file offsets relative to H + 0
; if the difference between two block offsets is 4k then the block is not
; compressed. Block offsets are relative to the start of the raw compressed
; data (makes compressing easier)
;#############################################################################

;-----------------------------------------------------------------------------
; WfseReadDecomp - read from a compressed file
;
; Entry:
;        ECX = bytes to read
;        BX  = file handle (already verified)
;        DS: EDX -> dest
;
; Exit:
;        we will exit, of course
;
WfseReadDecomp PROC NEAR
;
; ecx -= read (min (ecx, ((not (file pointer)) and (FFF)) + 1)) (file pointer+++)
; while ecx >= 4096 ecx -= read(4096) (file pointer+++)
; if ecx != 0 then read ecx file pointer
;
		push	ds
		push	es
		push	ecx
		push	ds
		pop	es
		mov	ds, cs: dosx_flat_sel_data16
		mov	eax, [bx-8000h].WfseFcbs.WfseFcb.WfseFileSize
		sub	eax, [bx-8000h].WfseFcbs.WfseFcb.WfseFilePos
		cmp	eax, ecx
		jnc	wfseEcxSanitized

		mov	ecx, eax

WfseEcxSanitized:
		mov	eax, ecx
		test	ecx, ecx
		jz	WfseEarlyOut

		push	esi
		push	edi
		push	ecx
		mov	edi, edx
		mov	esi, [bx-8000h].WfseFcbs.WfseFCB.WfseFilePos
		or	eax, -1
		xor	eax, esi
		and	esi, 0FFFh
		and	eax, 0FFFh
		add	esi, 3000h
		inc	eax
		cmp	eax, ecx
		jna	wfseFirstBlockSizeOk

wfseLastBlockOk:
		mov	eax, ecx

wfseFirstBlockSizeOk:
		call	ReadVirtualBlock
		jc	wfseReadDecompDone

		call	CopyDecompData
		add	[bx-8000h].WfseFcbs.WfseFCB.WfseFilePos, eax
		sub	ecx, eax
		jz	wfseReadDecompDone

		mov	eax, 4096
		cmp	ecx, eax
		jc	wfseLastBlockOk
		jmp	wfseFirstBlockSizeOk

wfseReadDecompDone:
		mov	eax, edi
		sub	eax, edx
		pop	ecx
		cmp	eax, ecx
		pop	edi
		pop	esi

WfseEarlyOut:
		pop	ecx
		pop	es
		pop	ds
		retn
WfseReadDecomp ENDP

;-----------------------------------------------------------------------------
; Quick helper, EAX = # bytes to copy from transfer buffer
;
CopyDecompData PROC NEAR
		push	ds
		mov	ds, dosx_flat_sel_dos
		push	ecx
		mov	ecx, eax
		cld
		shr	cx, 2
		rep	movs DWORD PTR es: [edi], ds: [esi]
		mov	cx, ax
		and	cx, 3
		rep	movs BYTE PTR es: [edi], ds: [esi]
		mov	esi, 3000h
		pop	ecx
		pop	ds
		ret
CopyDecompData ENDP

;-----------------------------------------------------------------------------
; ReadVirtualBlock - Reads and decompresses a virtual block at bx = handle
;                    using the current virtual file pointer. This procedure
;                    just makes sure the addressed virtual block is in the
;                    transfer buffer.
; 
; Entry:
;        WFSE handle
;
; Exit:  Decompressed block available at Buffer[3000h], certain globals
;        updated (but NOT the virtual file pointer!)
;        CF set on error, ax = DOS error code
;
ReadVirtualBlock PROC NEAR
		pushad
		push	ds
		push	es
		mov	ds, cs: dosx_flat_sel_data16
		mov	es, dosx_flat_sel_dos
;
; if not current file
;
		cmp	bx, wfse_current_handle
		je	wfseCurrentHandleOk

		mov	eax, [bx-8000h].WfseFcbs.WfseFCB.WfseFileStart
		call	HWfseSetFilePointer
		mov	cx, 4096
		sub	si, si
		call	ReadBlockSICX
		jc	readVirtualExit

		cmp	ax, 12
		jc	readVirtualExit
;
;	if custom decompressor store decompressor, this is todo
;       Currently, we support JIBZ' WPACK and the old LZ77 one for backwards
;	compatibility.
;
		mov	wfse_current_decomp, OFFSET LZ77Decompress
		test	cs: [bx-8000h].WfseFcbs.WfseFCB.WfseFlags, WFSE_COMP_LZ77
		jnz	SHORT wfseGotDecomp

		mov	wfse_current_decomp, OFFSET WdosxDepack

wfseGotDecomp:
		mov	wfse_current_handle, bx
		movzx	eax, es: [WfseCompHeader.LastBlockSize]
		mov	wfse_current_last, eax
		mov	wfse_current_block, -1
		movzx	eax, es: [WfseCompHeader.HeaderSize]
		add	eax, [bx-8000h].WfseFcbs.WfseFCB.WfseFileStart
		mov	wfse_current_dir_offset, eax
		mov	edx, [bx-8000h].WfseFcbs.WfseFCB.WfseFileSize
		add	edx, 0FFFh
		shr	edx, 12
		lea	eax, [edx * 4 +eax]
		mov	wfse_current_raw_offset, eax

wfseCurrentHandleOk:

		mov	eax, [bx-8000h].WfseFcbs.WfseFCB.WfseFilePos
		shr	eax, 12
		mov	edx, wfse_current_block
		shr	edx, 12
		cmp	eax, edx
		je	wfseKeepContext
;
; if not current directory block (determined from file offset upper 10 bits)
; - get directory block we need (upper 10 bits of file offset to read from)
;
		shr	eax, 10
		shr	edx, 10
		cmp	ax, dx
		je	wfseCurrentDirOk
;
; wfse_dir_offset = filepointer shr 22 (EAX)
; size = (((virtual size + FFF) shr 12) - wfse_dir_offset shl 10) shl 2
;
		mov	ecx, [bx-8000h].WfseFcbs.WfseFCB.WfseFileSize
		shl	eax, 10
		add	ecx, 0FFFh
		shr	ecx, 12
		sub	ecx, eax
		shl	ecx, 2
		cmp	ecx, 4100
		jc	wfseDirSizeOk

		mov	cx, 4100

wfseDirSizeOk:
		shl	eax, 2
		add	eax, wfse_current_dir_offset
		call	HWfseSetFilePointer
		sub	si, si
		call	ReadBlockSICX
		jc	readVirtualExit

		cmp	ax, cx
		mov	ax, 01Ch		; ???
		jc	readVirtualExit

		cmp	cx, 4100
		jnc	wfseCurrentDirOk

		mov	si, cx
		mov	eax, es: [si - 4]
		add	eax, wfse_current_last
		mov	es: [si], eax

wfseCurrentDirOk:
		mov	eax, [bx-8000h].WfseFcbs.WfseFCB.WfseFilePos
		shr	eax, 12
		mov	edx, [bx-8000h].WfseFcbs.WfseFCB.WfseFileSize
		shr	edx, 12
		cmp	eax, edx
		je	wfseIsLastBlock
;
; if block != last block { 
;    csize = dir[block + 1] - dir[block]
;    size = 4096
; }
;
		and	eax, 03FFh
		mov	ecx, es: [eax * 4 + 4]
		sub	ecx, es: [eax * 4]
		mov	dx, 4096
		jmp	wfseSizeCalcOk
;
;  else {
;    csize = last_block_size
;    size = Virtual size and FFF
; }
;
wfseIsLastBlock:
		mov	cx, WORD PTR wfse_current_last
		and	eax, 03FFh
		mov	dx, WORD PTR [bx-8000h].WfseFcbs.WfseFCB.WfseFileSize
		and	dx, 0FFFh

wfseSizeCalcOk:
		mov	eax, es: [eax * 4]
		add	eax, wfse_current_raw_offset
		call	HWfseSetFilePointer
		mov	si, 8192
		call	ReadBlockSICX
		jc	readVirtualExit

		cmp	ax, cx
		mov	ax, 01Ch		; ???
		jc	readVirtualExit

;		movzx	eax, cx
		mov	eax, [bx-8000h].WfseFcbs.WfseFCB.WfseFilePos
;		add	eax, wfse_current_block
		mov	wfse_current_block, eax
;
; if csize != size then decomp(size) else move(size)
;
		mov	di, 3000h
		push	es
		pop	ds
		xchg	cx, dx
		cmp	cx, dx
;		cmp	dx, 1000h
		je	wfseJustMove

		mov	bx, cx
		call	[cs: wfse_current_decomp]
		clc
		jmp	wfseKeepContext

wfseJustMove:
		cld
		rep	movsb
		clc
		jmp	wfseKeepContext

readVirtualExit:

		call	WfseInvalidate

wfseKeepContext:
		pop	es
		pop	ds
		popad
		retn
ReadVirtualBlock ENDP

;-----------------------------------------------------------------------------
; ReadBlockSICX
;
; Entry:
;        SI = target offset in transfer buffer
;        CX = number of bytes to read
;
; Exit:
;        CF clear on success, AX = bytes read
;        CF set on error, AX = DOS error code
;
ReadBlockSICX PROC NEAR
		push	es
		push	edi
		push	bx
		mov	es, cs:dosx_flat_sel_data16
		mov	edi, OFFSET dosx_int31struc
		mov	ax, cs: dosx_fhandle
		mov	es: dosx_int31struc._bx, ax
		mov	es: dosx_int31struc._dx, si
		mov	es: dosx_int31struc._cx, cx
		mov	es: dosx_int31struc._ah, 3Fh
		sub	cx, cx
		mov	bl, 21h
		mov	ax, 300h
		call	dosx_call31
		mov	ax, es: dosx_int31struc._flags
		shr	ax, 1
		mov	ax, es: dosx_int31struc._ax
		mov	cx, es: dosx_int31struc._cx
		pop	bx
		pop	edi
		pop	es
		retn
ReadBlockSICX ENDP

; ############################################################################
; ## Realmode and 16 bit PM LZ77 decompressor                               ##
; ############################################################################
;
; In: DS:SI -> source data
;     ES:DI -> dest. buffer
;     BX -> number of bytes to decompress
;
; Out: DS:SI -> next byte in input stream
;
; Destroys flags including DF and all general purpose registers except BP
;
; This is a very silly implementation, obviously.
;
Lz77Decompress PROC NEAR
		cld
		add	bx, di

NewTag:
		mov	dh, 8
		mov	dl, [si]
		inc	si

TestTag:
		add	dl, dl
		jc	processMatch

		movsb

TestEnd:
		cmp	di, bx
		jnc	LZDecompDone

		dec	dh
		jnz	TestTag

		jmp	NewTag

processMatch:
		lodsw
		push	si
		mov	cx, ax
		mov	si, di
		and	cx, 15
		shr	ax, 4
		sub	si, ax
		add	cx, 3
		rep	movsb
		pop	si
		jmp	TestEnd

LZDecompDone:
		ret
Lz77Decompress ENDP

;-----------------------------------------------------------------------------
WfseFunctionTable	db	0, 03Dh, 03Eh, 03Fh, 042h, 0FEh, 0FFh

WfseFunctions		dw	OFFSET WfseInstall
			dw	OFFSET WfseOpen
			dw	OFFSET WfseClose
			dw	OFFSET WfseRead
			dw	OFFSET WfseSeek
			dw	OFFSET WfseAlternate

;----------------------- WFSE helper functions -------------------------------

HWfseVerifyHandle PROC NEAR

		cmp	bh, 80h
		jc	@@VerifyDone


		cmp	bx, 8000h+MAX_WFSE_FCBS*SIZE_OF_FCB
		cmc
		jc	@@VerifyDone

		test	bl, SIZE_OF_FCB-1
		jnz	@@VerifyError

		test	cs:[bx-8000h].WfseFcbs.WfseFCB.WfseFileStart, -1
		jnz	@@VerifyDone

@@VerifyError:
		stc

@@VerifyDone:
		ret

HWfseVerifyHandle ENDP

HWfseTolower PROC NEAR

		cmp	al, 'A'
		jc	SHORT WfseUpcase0

		cmp	al, 'Z'
		ja	SHORT WfseUpcase0

		or	al, 20h

WfseUpcase0:
		ret
HWfseTolower ENDP

;-----------------------------------------------------------------------------
; HWfseFindFirst
;
; Out:  CF clear on success, transfer buffer filled with WFSE header
;                            master file pointer at the beginning of WFSE
;                            header.
;       CF set on error
;
HWfseFindFirst PROC NEAR

		pushad
		mov	bx, cs:dosx_fhandle
		mov	eax, cs:WdosxInfo.WdxInfo.WfseStart

FindNextEntry:
		call	HWfseSetFilePointer
		jc	SHORT @@error

		push	eax
		push	ds
		mov	ds, cs:dosx_flat_sel_dos
		sub	edx, edx
		mov	ecx, 16+256		; size of header
		mov	ah, 3Fh
		int	21h
		jc	SHORT @@noError

		cmp	eax, 16+2
		jc	SHORT @@noError

		cmp	DWORD PTR ds:[0], 45534657h
		je	SHORT @@noError

		stc

@@noError:
		pop	ds
		pop	eax
		jc	SHORT @@error

		call	HWfseSetFilePointer
		jc	SHORT @@error

@@error:
		popad
		ret

HWfseFindFirst ENDP

;-----------------------------------------------------------------------------
; HWfseSetFilePointer
;
; In:   EAX = file pointer
;
; Out:  CF clear = O.K.
;       CF set   = error
;
HWfseSetFilePointer PROC NEAR

		pushad
		mov	bx, cs: dosx_fhandle
		shld	ecx, eax, 16
		mov	dx, ax
		mov	ax, 4200h
		int	21h
		popad
		ret

HWfseSetFilePointer ENDP

;-----------------------------------------------------------------------------
; HWfseGetFilePointer
;
; Out:  CF clear = O.K. EAX = file pointer
;       CF set   = error
;
HWfseGetFilePointer PROC NEAR

		push	cx
		push	dx
		push	bx
		mov	bx, cs:dosx_fhandle
		sub	cx, cx
		sub	dx, dx
		mov	ax, 4201h
		int	21h
		pushf
		shl	eax, 16
		mov	ax, dx
		ror	eax, 16
		popf
		pop	bx
		pop	dx
		pop	cx
		ret

HWfseGetFilePointer ENDP

;-----------------------------------------------------------------------------
; HWfseFindNext
;
; In:                        file pointer at the beginning of a WFSE header
;                            transfer buffer filled with header data from
;                            previous call to FindFirst/Next
;
; Out:  CF clear on success, transfer buffer filled with WFSE header
;                            master file pointer at the beginning of WFSE
;                            header.
;       CF set on error
;
HWfseFindNext PROC NEAR
		pushad
		mov	bx, cs:dosx_fhandle
		call	HWfseGetFilePointer
		push	ds
		mov	ds, cs:dosx_flat_sel_dos
		add	eax, ds:[WfseInfo.WfseSize]
		pop	ds
		jmp	FindNextEntry
HWfseFindNext ENDP
;
; ############# End of WFSE API ##############################################
;
dosx_notwfse:
		cmp	al, 0ffh
		jnz	dosx_int21_chain_01
;
; If caller's CS does not match dosx_flat_sel_code, return an error.
;
		push	eax
		mov	ax, [esp + 8]
		cmp	ax, WORD PTR cs:[OFFSET dosx_flat_sel_code]
		pop	eax
		je	SHORT callerOkFor21FFFF

		or	BYTE PTR [esp + 8], 1
		iretd


callerOkFor21FFFF:
		mov	ds, cs:[dosx_flat_sel_data16]
		pop	DWORD PTR ds:[OFFSET dosx_32api_return_offset]
		pop	DWORD PTR ds:[OFFSET dosx_32api_return_selector]
		pop	DWORD PTR ds:[OFFSET dosx_api_return_flags]
		or	BYTE PTR ds:[OFFSET dosx_api_return_flags], 1
		mov	dosx_api_return_esp, esp
		mov	ss, ds:[dosx_flat_sel_data16]
		mov	esp, OFFSET dosx_top_of_memory
		push	es
		push	fs
		push	gs
		pushad
		mov	ecx, edx

dosx_21FF_common:
		shld	ebx, ecx, 16
		mov	ax, 0503h
		mov	di, WORD PTR ds:[OFFSET dosx_flat_handle]
		mov	si, WORD PTR ds:[OFFSET dosx_flat_handle+2]
		call	dosx_call31
		jc	SHORT dosx_32api_fail

		mov	WORD PTR ds:[OFFSET dosx_flat_handle], di
		mov	WORD PTR ds:[OFFSET dosx_flat_handle+2], si
		mov	dx, cx
		mov	cx, bx
		mov	bx, dosx_flat_sel_code
		mov	ax, 7
		call	dosx_call31
		jc	dosx_dpmierror

		mov	bx, dosx_flat_sel_data
		call	dosx_call31
		jc	dosx_dpmierror

		and	BYTE PTR ds:[OFFSET dosx_api_return_flags], 0feh

dosx_32api_fail:
		popad
		pop	gs
		pop	fs
		pop	es
		push	DWORD PTR ds:[OFFSET dosx_api_return_flags]
		popfd
		mov	ss, dosx_flat_sel_data
		mov	esp, dosx_api_return_esp
		mov	ds, dosx_flat_sel_data

				dw	0EA66h
dosx_32api_return_offset	dd	?
dosx_32api_return_selector	dd	?

dosx_call31	LABEL	NEAR
		pushfd
		db	66h
		push	cs
		db	66h
		push	OFFSET dosx_from_old31
		dw	0
                jmp     SHORT dosx_chain31

dosx_chain31:
		dw	0EA66h
dosx_old31_ofs	dd	?
dosx_old31_sel	dw	?

dosx_from_old31:
		ret


fix_callbacks_for_nt PROC NEAR
;
; workaround for an NT bug: the high word of ESI is invalid...
;
		mov	ax, ds
		lsl	eax, eax
		cmp	eax, esi
		ja	ntBugDone

		movzx	esi, si
		movzx	edi, di

ntBugDone:

		ret
fix_callbacks_for_nt ENDP


dosx_hook31:
;
; Workaround for an NTVDM bug, which zeroes out the high 16 bits of target
; EIP
;
		cmp	ax, 0303h
		jne	check304
;
; Scan the handler table for a free entry
;
		push	bx
		push	bp
		mov	bp, ds
		mov	ds, cs:[dosx_flat_sel_data16]
		sub	bx, bx

dpmi_cb_cont_scan:
		cmp	DWORD PTR [bx + OFFSET dpmi_cb_addx], 0
		je	dpmi_cb_found_free

		add	bx, 4
		cmp	bx, 4 * 16
		jc	dpmi_cb_cont_scan

dpmi_cb_fail:
		mov	ds, bp
		pop	bp
		pop	bx
                or	BYTE PTR [esp + 8], 1
		iretd

dpmi_cb_found_free:
		push	bx
		imul	bx, 3
		mov	BYTE PTR ds: [bx + OFFSET dpmi_cb_dest], 0E8h
		mov	WORD PTR ds: [bx + OFFSET dpmi_cb_dest + 3], 0EA66h
		mov	DWORD PTR ds: [bx + OFFSET dpmi_cb_dest + 5], esi
		mov	WORD PTR ds: [bx + OFFSET dpmi_cb_dest + 9], bp
;
; Calculate displacement for near call
;
		mov	si, OFFSET fix_callbacks_for_nt - OFFSET dpmi_cb_dest - 3
		sub	si, bx
		mov	WORD PTR ds: [bx + OFFSET dpmi_cb_dest + 1], si
		lea	si, [bx + OFFSET dpmi_cb_dest]
		push	cs
		pop	ds
		movzx	esi, si
		call	dosx_call31	
		mov	ds, cs:[dosx_flat_sel_data16]
		mov	esi, DWORD PTR [bx + OFFSET dpmi_cb_dest + 5]
		pop	bx
		jc	dpmi_cb_fail

		mov	WORD PTR [bx + OFFSET dpmi_cb_addx], dx
		mov	WORD PTR [bx + OFFSET dpmi_cb_addx + 2], cx

dpmi_cb_ok:
		mov	ds, bp
		pop	bp
		pop	bx
                and	BYTE PTR [esp + 8], 0FEh
		iretd

check304:
		cmp	ax, 0304h
		jne	checkIdent

		push	bx
		push	bp
		mov	bp, ds
		mov	ds, cs:[dosx_flat_sel_data16]
		sub	bx, bx

dpmi_cb_cont_search:
		cmp	WORD PTR [bx + OFFSET dpmi_cb_addx], dx
		jne	dpmi_cb_found_next

		cmp	WORD PTR [bx + OFFSET dpmi_cb_addx + 2], cx
		jne	dpmi_cb_found_next

		call	dosx_call31	
		jc	dpmi_cb_fail

		mov	DWORD PTR [bx + OFFSET dpmi_cb_addx], 0
		jmp	dpmi_cb_ok
			

dpmi_cb_found_next:
		add	bx, 4
		cmp	bx, 4 * 16
		jc	dpmi_cb_cont_search

		jmp	dpmi_cb_fail
;
; End of NTVDM callback workaround
;
checkIdent:
		cmp	ax, 0eeffh
                jnz     dosx_chain31

                mov	eax, 'WDSX'
                mov     dx, MajorVersion*256+MinorVersion
                mov     ch, 0
org $-1
dosx_PMSys_EEFF db      ?
                mov     cl, BYTE PTR cs:[OFFSET dosx_cpu_type]
                and     BYTE PTR [esp+8], 0feh
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
                mov     ebx, OFFSET dosx_thats_me
                iretd


; ############################################################################
; ## Extended DOS API functions                                             ##
; ############################################################################


dosx_is_DOS_fn:
		cld
		and	BYTE PTR [esp+8], 0feh
		push	si
		sub	si, si

dosx_int21_checkapi:
		cmp	ah, BYTE PTR cs:[si+OFFSET dosx_32dsdx]
		jz	SHORT dosx_int21apiget

		inc	si
		cmp	BYTE PTR cs:[si+OFFSET dosx_32dsdx], 0ffh
		jnz	SHORT dosx_int21_checkapi

dosx_int21_chain:
		pop	si

dosx_int21_chain_01:
		dw	0EA66h
dosx_old21_ofs	dd	0
dosx_old21_sel	dw	0

dosx_int21apiget:
		add	si, si
		mov	si, WORD PTR cs:[si + OFFSET dosx_whatapi]
		xchg	si, [esp]
		retn

dosx_upon_exit:
		push	ax
		mov	dx, cs:dosx_mouse_rmcallback_ofs
		mov	cx, cs:dosx_mouse_rmcallback_seg
		mov	ax, 0304h
		int	31h
		pop	ax
		jmp	SHORT dosx_int21_chain_01


; ############################################################################
; ## INT 21/4b00h Execute child program                                     ##
; ############################################################################

dosx_214b:

		test	al, al
		jz	SHORT dosx_214b_ok

		or	BYTE PTR [esp+8], 1
		iretd

dosx_214b_ok:
		and	BYTE PTR [esp+8], 0FEh
		pushad
		push	es
		push	fs
		push	ds
		mov	fs, WORD PTR cs:[OFFSET dosx_flat_sel_dos]   ; transfer buffer
                call    WfseInvalidate
		mov	di, 24              ; reserve space for parameter block
;
; Copy filename
;
dosx_4b00_00:
		mov	al, [edx]
		inc	edx
		mov	fs:[di], al
		inc	di
		test	al, al
		jnz	SHORT dosx_4b00_00
;
; Setup first part of parameter block
;
		mov	fs:[2], di
		mov	DWORD PTR fs:[6], 0
		mov	DWORD PTR fs:[0Ah], 0
;
; Copy command tail
;
		lds	edx, FWORD PTR es:[ebx+6]
;
; Always copy at least one byte w/o zero checking
;
		movzx	cx, BYTE PTR [edx]
		inc	edx
		mov	fs:[di], cl
		inc	di
		add	cl, 2		; maximum size is real size + 0Dh, 00h

dosx_4b00_01:
		mov	al, [edx]
		inc	edx
		mov	fs:[di], al
		inc	di
		test	al, al
		jz	SHORT dosx_4b00_01_01

		loop	SHORT dosx_4b00_01

dosx_4b00_01_01:
;
; Check whether caller's environment should be copied or not
;
		les	edi, FWORD PTR es:[ebx]

dosx_4b00_02:
		sub	ax, ax
		cld
		or	ecx, -1

dosx_4b00_04:
		repne	scas BYTE PTR es:[edi]
		dec	ecx
		scas	BYTE PTR es:[edi]
		jne	SHORT dosx_4b00_04

		lea	esi, [edi + ecx + 1]
		not	ecx
		lea	ebx, [ecx + 15]
		shr	ebx, 4
                and	bx, 0FFFh
		mov	ds, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		mov	ax, 100h
		int	31h
		mov	dosx_int31struc._ax, 1Fh	; general failure
		jc	dosx_4b00_error

		push	es
		pop	ds
		mov	es, dx
		mov	fs:[0], ax
		sub	edi, edi
		rep	movs BYTE PTR es:[edi], ds:[esi]

dosx_4b00_05:
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		mov	edi, OFFSET dosx_int31struc
		mov	ax, es:_ds[di]
		mov	fs:[4], ax
		mov	es:_bx[di], 0
		mov	es:_dx[di], 24
		mov	es:_ax[di], 4B00h

		push	dx
		mov	ax, 204h
		mov	bl, 33h
		int	31h
		push	cx
		push	edx
		mov	cx, es:dosx_old33sel
		mov	edx, es:dosx_old33ofs
		inc	ax
		int	31h

		dec	ax
		mov	bl, 21h
		int	31h
		push	cx
		push	edx
		mov	cx, es:dosx_old21_sel
		mov	edx, es:dosx_old21_ofs
		inc	ax
		int	31h

		dec	ax
		mov	bl, 31h
		int	31h
		push	cx
		push	edx
		mov	cx, es:dosx_old31_sel
		mov	edx, es:dosx_old31_ofs
		inc	ax
		int	31h
		mov	bx, 21h
		mov	ax, 300h
		sub	cx, cx
		int	31h

		mov	ax, 205h
		pop	edx
		pop	cx
		mov	bl, 31h
		int	31h

		pop	edx
		pop	cx
		mov	bl, 21h
		int	31h

		pop	edx
		pop	cx
		mov	bl, 33h
		int	31h

		pop	dx
		mov	ax, 101h
		int	31h
		test	es:_flags[di], 1
		jz	SHORT dosx_4b00_07

dosx_4b00_error:
		stc

dosx_4b00_07:
		pop	ds
		pop	fs
		pop	es
		popad
		jnc	SHORT dosx_4b00_noerr

		or	BYTE PTR [esp+8], 1
                mov	ax, WORD PTR cs:[OFFSET dosx_int31struc._ax]

dosx_4b00_noerr:
;
; Either way, reset the DTA to where it belongs
;
		pushad
		push	es
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		mov	edi, OFFSET dosx_int31struc
		push	es:dosx_int31struc._ds
		mov	ax, cs:dosx_patch1
		mov	es:dosx_int31struc._ds, ax
		mov	es:dosx_int31struc._dx, OFFSET dosx_dta
		mov	es:dosx_int31struc._ah, 1Ah
		sub	cx, cx
		mov	ax, 300h
		mov	bl, 21h
		int	31h
		pop	es:dosx_int31struc._ds
		pop	es
		popad
		iretd

; ############################################################################
; ## INT 21/44 IOCTL dispatcher                                             ##
; ############################################################################

dosx_2144:
		cmp	al, 2
		jz	SHORT dosx_21442

		cmp	al, 4
		jz	SHORT dosx_21442

		cmp	al, 3
		jz	dosx_doswrite

		cmp	al, 5
		jz	dosx_doswrite

		jmp	dosx_int21_chain_01

dosx_21442:
;
; copy max (ecx, 16k) down to buffer
;
		push	es
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_dos]
                call    WfseInvalidate
		push	esi
		push	edi
		push	ecx
;
; Only use cx and make the default 256 bytes
;
		movzx	ecx, cx
;		cmp	ecx, 4000h
;
		cmp	cx, 100h
		jc	SHORT dosx_21442_1
;
;		mov	ecx, 4000h
		mov	cx, 100h

dosx_21442_1:
		mov	esi, edx
		sub	edi, edi
		rep	movs BYTE PTR es:[edi], ds:[esi]
		pop	ecx
		pop	edi
		pop	esi
		pop	es
		jmp	dosx_dosread

; ############################################################################
; ## INT 21/48 Allocate DOS memory block                                    ##
; ############################################################################

dosx_2148:
		push	dx
		mov	eax, 100h
		int	31h
		jc	SHORT dosx_2148_01

		movzx	eax, dx

dosx_2148_01:
		pop	dx
		movzx	ebx, bx
		jnc	SHORT dosx_2148_02

		or	BYTE PTR [esp+8], 1

dosx_2148_02:
		iretd

; ############################################################################
; ## INT 21/49 Free DOS memory block                                        ##
; ############################################################################

dosx_2149:
		push	cx
		mov	cx, ax
		push	dx
		mov	dx, es
		mov	ax, 101h
		int	31h
		pop	dx
		jc	SHORT dosx_2149_01

		mov	ax, cx
		push	0
		pop	es

dosx_2149_01:
		pop	cx
		jnc	SHORT dosx_2149_02

		or	BYTE PTR [esp+8], 1

dosx_2149_02:
		iretd

; ############################################################################
; ## INT 21/4a Resize DOS memory block                                      ##
; ############################################################################

dosx_214A:
		push	cx
		mov	cx, ax
		push	dx
		mov	dx, es
		mov	ax, 102h
		int	31h
		pop	dx
		movzx	ebx, bx
		jc	SHORT dosx_214A_01

		mov	ax, cx

dosx_214A_01:
		pop	cx
		jnc	SHORT dosx_214A_02

		or	BYTE PTR [esp + 8], 1

dosx_214A_02:
		iretd

; ############################################################################
; ## INT 21/34 Get address of Indos flag                                    ##
; ############################################################################

dosx_conv_esbx:
		push	ds
		push	edi
		push	bx
		push	cx
		mov	edi, OFFSET dosx_int31struc
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		push	es
		pop	ds
		mov	_ax[di], ax
		push	_es[di]
		mov	bl, 21h
		sub	cx, cx
		mov	ax, 300h
		int	31h
		mov	bx, _es[di]
		mov	ax, 2
		int	31h
		pop	_es[di]
		movzx	ebx, _bx[di]
		mov	es, ax
		mov	ax, _ax[di]
		pop	cx
		pop	bx
		pop	edi
		pop	ds
		iretd

; ############################################################################
; ## Common function for returning a pointer in ds:ebx                      ##
; ############################################################################

dosx_conv_dsbx:
		push	es
		push	edi
		mov	edi, OFFSET dosx_int31struc
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		push	es
		pop	ds
		mov	_bx[di], bx
		mov	_cx[di], cx
		mov	_dx[di], dx
		mov	_ax[di], ax
		inc	ah
		and	ah, 0FEh
		cmp	ah, 01Ch
		jne	SHORT dosx_cv_01

		sub	edx, edx
		sub	ecx, ecx

dosx_cv_01:
		push	_ds[di]
		mov	bl, 21h
		sub	cx, cx
		mov	ax, 300h
		int	31h
		mov	bx, _ds[di]
		mov	ax, 2
		int	31h
		pop	_ds[di]
		movzx	ebx, _bx[di]
		mov	cx, _cx[di]
		mov	dx, _dx[di]
		mov	ds, ax
		mov	ax, es:_ax[di]
		pop	edi
		pop	es
		iretd
		
; ############################################################################
; ## INT 21/25 SET interrupt vector                                         ##
; ############################################################################

dosx_setintvec:
		push	bx
		push	cx
		mov	cx, ds
		push	ax
		mov	bl, al
		mov	ax, 205h
		int	31h
		pop	ax
		pop	cx
		pop	bx
		iretd

; ############################################################################
; ## INT 21/35 GET interrupt vector                                         ##
; ############################################################################

dosx_getintvec:
		mov	bl, al
		push	edx
		push	cx
		push	ax
		mov	ax, 204h
		int	31h
		mov	es, cx
		mov	ebx, edx
		pop	ax
		pop	cx
		pop	edx
		iretd

; ############################################################################
; ## INT 21/1A SET DTA                                                      ##
; ############################################################################

dosx_setdta:
		push	es
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		mov	DWORD PTR es:[OFFSET dosx_dta_offset], edx
		mov	WORD PTR es:[OFFSET dosx_dta_selector], ds
		pop	es
		iretd

; ############################################################################
; ## INT 21/2F GET DTA                                                      ##
; ############################################################################

dosx_getdta:
		les	ebx, PWORD PTR cs:[OFFSET dosx_dta_offset]
		iretd

; ############################################################################
; ## INT 21/4F FIND NEXT                                                    ##
; ############################################################################

dosx_findnext:
		push	ds
		push	es
		push	esi
		push	edi
		push	ecx
		push	bx
;
; User dta -> dta buffer
;
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		lds	esi, PWORD PTR cs:[OFFSET dosx_dta_offset]
		mov	edi, OFFSET dosx_dta
		mov	ecx, 11
		rep	movs DWORD PTR es:[edi], ds:[esi]
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		mov	edi, OFFSET dosx_int31struc
		mov	es:_ax[di], ax
		sub	cx, cx
		mov	ax, 300h
		mov	bl, 21h
		int	31h
		mov	ax, es:_ax[di]
		test	BYTE PTR es:_flags[di], 1
;
; crashes in a Windows DOS box...
;		pushfd
;		call	PWORD PTR cs:[OFFSET dosx_old21_ofs]
;
; dta buffer -> user dta
;
		mov	ds, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		les	edi, PWORD PTR cs:[OFFSET dosx_dta_offset]
		mov	esi, OFFSET dosx_dta
		mov	ecx, 11
		rep	movs DWORD PTR es:[edi], ds:[esi]
		pop	bx
		pop	ecx
		pop	edi
		pop	esi
		pop	es
		pop	ds
		jz	SHORT dosx_fn_ok

		or	BYTE PTR [esp+8], 1

dosx_fn_ok:
		iretd
;
; ############################################################################
;
dosx_rename:
		push	es
		push	gs
		mov	gs, WORD PTR cs:[OFFSET dosx_flat_sel_dos]	; target
                call    WfseInvalidate
		push	ebx
		push	edi
		sub	ebx, ebx

dosx_ren1:
		mov	ah, es:[edi+ebx]
		mov	gs:[bx], ah
		inc	bx
		test	ah, ah
		jnz	SHORT dosx_ren1

		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		mov	edi, OFFSET dosx_int31struc
		mov	es:_dx[di], bx
		push	esi
		sub	esi, esi

dosx_ren2:
		mov	ah, ds:[edx+esi]
		mov	gs:[bx+si], ah
		inc	si
		test	ah, ah
		jnz	SHORT dosx_ren2

		pop	esi
		mov	ah, 56h
		mov	es:_ax[di], ax
		mov	es:_cx[di], cx
		mov	ax, es:_ds[di]
		mov	es:_es[di], ax
		mov	es:_di[di], 0
		mov	bl, 21h
		sub	cx, cx
		mov	ax, 0300h
		int	31h
		mov	cx, es:_cx[di]
		mov	ax, es:_ax[di]
		test	BYTE PTR es:_flags[di], 1
		pop	edi
		pop	ebx
		pop	gs
		pop	es
		jz	SHORT dosx_ren3

		or	BYTE PTR [esp+8], 1

dosx_ren3:
		iretd

; ############################################################################

dosx_getdir:
		push	es
		push	edi
		push	esi
		push	cx
		push	bx
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		mov	edi, OFFSET dosx_int31struc
		mov	es:_dx[di], dx
		mov	es:_ax[di], ax
		mov	es:_si[di], 0
		sub	cx, cx
		mov	bl, 21h
		mov	ax, 300h
		int	31h
		sub	bx, bx
		push	es
		mov	es, WORD PTR cs:[dosx_flat_sel_dos]
                call    WfseInvalidate

dosx_getdirloop:
		mov	al, es:[bx]
		mov	ds:[esi], al
		inc	esi
		inc	bx
		cmp	bx, 64
		jnz	SHORT dosx_getdirloop

		pop	es
		mov	ax, es:_ax[di]
		test	BYTE PTR es:_flags[di], 1
		pop	bx
		pop	cx
		pop	esi
		pop	edi
		pop	es
		jz	SHORT dosx_getdir1

		or	BYTE PTR [esp+8], 1

dosx_getdir1:
		iretd

; ############################################################################

dosx_getpsp:
		mov	bx, WORD PTR cs:[OFFSET dosx_pspsel]
		iretd

; ############################################################################

dosx_dosopencreate:
		push	ds
		push	es
		push	esi
		push	edi
		sub	edi, edi
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_dos]	; target
                call    WfseInvalidate
		mov	esi, edx					; source

dosx_copyfilename:
		cmp	ah, 9
		jnz	SHORT dosx_api_0term

		cmp	BYTE PTR ds:[esi], '$'		; end of string?
		jmp	SHORT dosx_api_cond

dosx_api_0term:
		cmp	BYTE PTR ds:[esi], 0		; end of name?

dosx_api_cond:
		movs	BYTE PTR es:[edi], ds:[esi]	; copy BYTE
		jnz	SHORT dosx_copyfilename

		cmp	ah, 5ah
		jnz	SHORT dosx_bcopy_done

		mov	al, 12

dosx_fillz_0:
		mov	WORD PTR es:[di], 0
		inc	di
		dec	al
		jnz	SHORT dosx_fillz_0

dosx_bcopy_done:
		push	ds
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		mov	ds, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		mov	edi, LARGE OFFSET dosx_int31struc
		mov	_cx[di], cx
		mov	_ax[di], ax
		mov	_bx[di], ax
		mov	_dx[di], 0
		push	bx
		mov	bl, 21h
		sub	cx, cx
		mov	ax, 0300h
		int	31h
		pop	bx
		mov	cx, _cx[di]
		mov	ax, _ax[di]
		pop	es
		cmp	_bh[di], 5ah
		jnz	SHORT dosx_nomaket

		push	ds
		mov	ds, WORD PTR ds:[OFFSET dosx_flat_sel_dos]
                call    WfseInvalidate
		mov	edi, edx
		sub	esi, esi

dosx_copy_tf:
		cmp	BYTE PTR [si], 0
		movs	BYTE PTR es:[edi], ds:[esi]
		jnz	SHORT dosx_copy_tf

		pop	ds

dosx_nomaket:
;
; If function 4e, copy dta
;
		cmp	_bh[di], 4Eh
		jnz	SHORT dosx_not_4e

		push	edi
		les	edi, PWORD PTR ds:[OFFSET dosx_dta_offset]
		push	ecx
		mov	ecx, 11
		mov	esi, OFFSET dosx_dta
		rep	movs DWORD PTR es:[edi], ds:[esi]
		pop	ecx
		pop	edi

dosx_not_4e:
		test	BYTE PTR _flags[di], 1
		pop	edi
		pop	esi
		pop	es
		pop	ds
		jz	SHORT dosx_oc_ok

		or	BYTE PTR [esp+8], 1

dosx_oc_ok:
		iretd
;
; ############################################################################
;
dosx_dosread:
;
; Could havwe been called from 2144
;
		push	ds
		push	es
		push	esi
		push	edi
		push	ecx
		push	edx
		push	ds
		mov	ds, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		mov	esi, edx
		sub	edx, edx
		mov	edi, OFFSET dosx_int31struc
		mov	_bx[di], bx
		mov	_di[di], ax

dosx_api32_readloop:
		mov	ax, _di[di]
		mov	_ax[di], ax
		mov	_cx[di], 4000h		; default:read 16k
		mov	_dx[di], 0
		sub	ecx, 4000h
		jnc	SHORT dosx_api32_rlblock

		add	_cx[di], cx
		jz	SHORT dosx_api32_rdarnspecialcase

dosx_api32_rlblock:
		mov	es, WORD PTR ds:[OFFSET dosx_flat_sel_data16]
		mov	ax, 300h
		mov	bl, 21h
		push	cx
		sub	cx, cx
		int	31h
		pop	cx
		test	BYTE PTR _flags[di], 1
		pop	es
		jnz	SHORT dosx_32api_readerror

		push	ds
		push	ecx
		movzx	ecx, WORD PTR _ax[di]
		add	edx, ecx
		mov	ds, [dosx_flat_sel_dos]
                call    WfseInvalidate
		mov	edi, esi
		sub	esi, esi
		shr	cx, 1
		pushf
		shr	cx, 1
		pushf
		rep	movs DWORD PTR es:[edi], ds:[esi]
		popf
		jnc	SHORT dosx_rnomovsw

		movs	WORD PTR es:[edi], ds:[esi]

dosx_rnomovsw:
		popf
		jnc	SHORT dosx_rnomovsb

		movs	BYTE PTR es:[edi], ds:[esi]

dosx_rnomovsb:
		mov	esi, edi
		pop	ecx
		pop	ds
;
; Now check some conditions: 
;
		mov	edi, OFFSET dosx_int31struc
		cmp	_cx[di], 4000h
		jnz	SHORT dosx_api32_rdone

		cmp	_ax[di], 4000h
		jnz	SHORT dosx_api32_rdone

		push	es
		jmp	SHORT dosx_api32_readloop

dosx_api32_rdarnspecialcase:
		pop	es

dosx_api32_rdone:
		mov	eax, edx
		clc

dosx_api32_rcommon:
		pop	edx
		pop	ecx
		mov	bx, _bx[di]
		pop	edi
		pop	esi
		pop	es
		pop	ds
		jnc	SHORT dosx_rd_ok

		or	BYTE PTR [esp+8], 1

dosx_rd_ok:
		iretd

dosx_32api_readerror:
		mov	ax, _ax[di]
		stc
		jmp	SHORT dosx_api32_rcommon
;
; ############################################################################
;
dosx_doswrite:
;
; Test for ecx = 0 ( truncate file )
;
		movzx	eax, ax
		test	ecx, ecx
		jz	dosx_int21_chain_01
;
; If zero, no buffer operation involved, just chain into old int 21h
;
		push	ds
		push	es
		push	esi
		push	edi
		push	ebp
		sub	ebp, ebp
		push	ecx
		push	fs
		push	ds
		pop	fs
		mov	ds, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		mov	esi, edx
		mov	edi, OFFSET dosx_int31struc
		mov	_bx[di], bx
		mov	es, WORD PTR ds: [OFFSET dosx_flat_sel_data16]
		mov	_di[di], ax

dosx_api32_writeloop:
		mov	ax, _di[di]
		mov	_ax[di], ax
		mov	_cx[di], 4000h
		mov	_dx[di], 0
		sub	ecx, 4000h
		jnc	SHORT dosx_api32_wlblock

		add	_cx[di], cx
		jz	SHORT dosx_api32_wdarnspecialcase

dosx_api32_wlblock:
		push	ds
		push	es
		push	ecx
		push	edi
		movzx	ecx, WORD PTR _cx[di]
		mov	es, WORD PTR ds:[OFFSET dosx_flat_sel_dos]
                call    WfseInvalidate
		push	fs
		pop	ds
		sub	edi, edi
		push	cx
		shr	cx, 2
		rep	movs DWORD PTR es: [edi], ds: [esi]
		pop	cx
		and	cx, 3
		rep 	movs BYTE PTR es: [edi], ds: [esi]
		pop	edi
		pop	ecx
		pop	es
		pop	ds
		mov	ax, 300h
		mov	bl, 21h
		mov	es, WORD PTR ds: [OFFSET dosx_flat_sel_data16]
		push	cx
		sub	cx, cx
		int	31h
		pop	cx
		test	BYTE PTR _flags[di], 1
		jnz	SHORT dosx_32api_writeerror

		movzx	eax, _ax[di]
		add	ebp, eax
		cmp	ax, _cx[di]
		jnz	SHORT dosx_api32_wdarnspecialcase

		cmp	_ch[di], 40h
		jz	SHORT dosx_api32_writeloop

dosx_api32_wdarnspecialcase:
		mov	eax, ebp
		clc

dosx_wr_common:
		pop	fs
		pop	ecx
		pop	ebp
		mov	bx, _bx[di]
		pop	edi
		pop	esi
		pop	es
		pop	ds
		jnc	SHORT dosx_wr_ok

		or	BYTE PTR [esp], 1

dosx_wr_ok:
		iretd

dosx_32api_writeerror:
		mov	ax, _ax[di]
		stc
		jmp	SHORT dosx_wr_common

; ############################################################################
; ## Extended mouse functions                                               ##
; ############################################################################

dosx_new_int33:
		cmp	ax, 9
		jnz	dosx_int33_01

		push	edi
		push	ax
		push	bx
		push	cx
		push	ds
		push	es
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		mov	edi, OFFSET dosx_int31struc
		mov	es:_cx[di], cx
		mov	es:_bx[di], bx
		mov	bx, OFFSET dosx_mouse_bitmap
		mov	es:_dx[di], bx
		push	es:_es[di]
                mov	es:_es[di], es
		mov	es:_ax[di], ax
		mov	ds, [esp]
		mov	cx, 32

dosx_int33_00:
		mov	ax, [edx]
		add	edx, 2
		mov	es:[bx], ax
		add	bx, 2
		loop	SHORT dosx_int33_00

		sub	edx, 64
		mov	ax, 300h
		mov	bl, 33h
		int	31h
		pop	es:_es[di]
		pop	es
		pop	ds
		pop	cx
		pop	bx
		pop	ax
		pop	edi
		iretd

dosx_int33_01:
		cmp	ax, 0ch
		jnz	dosx_int33_02

		push	edi
		push	ax
		push	cx
		push	es
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		mov	edi, OFFSET dosx_int31struc
		mov	es:_cx[di], cx
		mov	es:_ax[di], ax
		mov	ax, WORD PTR es:[OFFSET dosx_mouse_rmcallback_seg]
		mov	cx, [esp]
		push	es:_es[di]
		mov	es:_es[di], ax
		mov	ax, WORD PTR es:[OFFSET dosx_mouse_rmcallback_ofs]
		mov	es:_dx[di], ax
		mov	DWORD PTR es:[OFFSET dosx_mouse_proc], edx
		mov	WORD PTR es:[OFFSET dosx_mouse_proc + 4], cx
		test	cx, cx
		jnz	dosx_int33_03

		mov	es:_es[di], cx
		mov	es:_dx[di], cx

dosx_int33_03:
		mov	bl, 33h
		sub	cx, cx
		mov	ax, 0300h
		int	31h
		pop	es:_es[di]
		pop	es
		pop	cx
		pop	ax
		pop	edi
		iretd

dosx_int33_02:
		cmp	ax, 16h
		jnz	dosx_int33_04

		push	edi
		push	esi
		push	ecx
		push	ax
		push	ds
		push	es
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		mov	edi, OFFSET dosx_int31struc
		mov	es:_bx[di], bx
		mov	es:_ax[di], ax
		mov	ax, es:_ds[di]
		mov	es:_es[di], ax
		mov	es:_dx[di], 0
		sub	cx, cx
		mov	bl, 33h
		mov	ax, 300h
		int	31h
		movzx	ecx, es:_bx[di]
		mov	edi, edx
		sub	esi, esi
		mov	ds, WORD PTR cs:[OFFSET dosx_flat_sel_dos]
                call    WfseInvalidate
		cld
		pop	es
		rep	movs BYTE PTR es:[edi], ds:[esi]
		pop	ds
		pop	ax
		pop	ecx
		pop	esi
		pop	edi
		iretd

dosx_int33_04:		
		cmp	ax, 17h
		jnz	dosx_int33_05

		push	edi
		push	esi
		push	ecx
		push	ax
		push	bx
		push	ds
		push	es
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_dos]
                call    WfseInvalidate
		pop	ds
		mov	esi, edx
		sub	edi, edi
		cld
		movzx	ecx, bx
		rep	movs BYTE PTR es:[edi], ds:[esi]
		push	ds
		mov	es, WORD PTR cs:[OFFSET dosx_flat_sel_data16]
		mov	edi, OFFSET dosx_int31struc
		mov	es:_ax[di], ax
		mov	es:_bx[di], bx
		mov	es:_dx[di], 0
		mov	ax, es:_ds[di]
		mov	es:_es[di], ax
		sub	cx, cx
		mov	bl, 33h
		mov	ax, 300h
		int	31h
		pop	es
		pop	ds
		pop	bx
		pop	ax
		pop	ecx
		pop	esi
		pop	edi
		iretd

dosx_int33_05:		
		dw	0EA66h
dosx_old33ofs	dd	?
dosx_old33sel	dw	?

; ############################################################################
; ##               The mouse callback glue code                             ##
; ############################################################################

dosx_int33callback:
		mov	ax, ds:[esi]
		mov	es:_ip[edi], ax
		mov	ax, ds:[esi+2]
		mov	es:_cs[edi], ax
		add	es:_sp[edi], 4
		push	esi
		push	edi
		movzx	eax, es:_ax[edi]
		movzx	ebx, es:_bx[edi]
		movzx	ecx, es:_cx[edi]
		movzx	edx, es:_dx[edi]
		movsx	esi, es:_si[edi]
		movsx	edi, es:_di[edi]
		db	66h
		call	DWORD PTR cs:[OFFSET dosx_mouse_proc]
		pop	edi
		pop	esi
		iretd
;
; ############################################################################
;
dosx_set_edi	PROC
;
; Set EDI to scratch page and clear TLB
; in: edx - physical adress
;
		mov	dl, 7
		mov	edi, dosx_cr3_base
		add	edi, 4096 * 2 - 4
		mov	es:[edi], edx
		mov	edi, 400000h-4096	; constant adress
		mov	eax, cr3
		mov	cr3, eax
		ret
dosx_set_edi	ENDP

dosx_getpage	PROC NEAR
;
; returns physical address of page in edx, cf clear, u/s + present set
; if cf set: memorino finito
; check if int15 malloc avail
;
		mov	edx, WdosxInfo.XMemAlloc
		dec	edx 
		cmp	edx, dosx_pagecount
		jnc	SHORT canMalloc

		ret

canMalloc:
		cmp	dosx_E801size, 0
		jz	SHORT dosx_alloc88

		dec	dosx_E801size
;		mov	edx, dosx_E801start
		mov	edx, dosx_E801size
		shl	edx, 12
		add	edx, dosx_E801start
;		add	dosx_E801start, 1000h
		jmp	SHORT dosx_alloc_fromvcpi

dosx_alloc88:
;
; As of WDOSX 0.95 we support INT 15h E801 for memory above 64MB
;
		cmp	dosx_extsize, 0
		jz	SHORT dosx_alloc_xms

;
; physical address = pagecount * 4096 + 100000h
;
; MikeT 99/06/20 We have to change this so that memory gets allocated top-down
;
		dec	dosx_extsize
;		mov	edx, dosx_pagecount
		movzx	edx, dosx_extsize
		shl	edx, 12
		add	edx, 100000h
;
; note that cf is clear here, isn't it?
;
		jmp	SHORT dosx_alloc_fromvcpi

dosx_alloc_xms:
		cmp	dosx_xmssize, 0
		jz	SHORT dosx_alloc_vcpi

		dec	dosx_xmssize
;
; physical = dosx_linear_start
;
		mov	edx, dosx_linear_start
		add	dosx_linear_start, 4096	;does not carry

dosx_alloc_fromvcpi:
		mov	dl, 7
		inc	DWORD PTR ds:[OFFSET dosx_pagecount]
		ret

dosx_alloc_vcpi:
		test	dosx_mode, vcpi_used
		jz	SHORT dosx_alloc_fail

		or	dosx_mode, pages_allocated
		mov	ax, 0DE04h
		push	ds
		push	dosx_sel_data0
		pop	ds
		call	PWORD PTR cs:[OFFSET dosx_vcpi_entry]
		pop	ds
;
; mark page as allocated from vcpi
;
		or	dh, 2
		test	al, al
		jz	SHORT dosx_alloc_fromvcpi
		
dosx_alloc_fail:
		stc
		ret
dosx_getpage	ENDP


dosx_killdpmi	PROC
		cli
		push	cs
		pop	ds
		mov	dosx_pmhands, 0
		mov	es, dosx_pspseg
		mov	ax, dosx_envseg
		mov	es:[2ch], ax
		cld
		test	dosx_mode, pages_allocated
		jz	SHORT dosx_exit_novcpi
;
; release pages.
; since pagetables are stored above 1MB we need pm here
;
		call	WORD PTR ds:[OFFSET dosx_raw2pm]
		mov	ax, dosx_sel_data0
		mov	es, ax
		mov	esi, dosx_cr3_base
		mov	cx, 512

dosx_nov_v_entr:
		add	si, 4			; start check here
		mov	edx, es:[esi]
		test	dl, 1	;valid entry ?
		loope	SHORT dosx_nov_v_entr
		jcxz	dosx_dealloc_done
;
; Found a valid entry
;
		call	dosx_set_edi
		push	cx
		mov	cx, 1024	

dosx_check4vcpipage:
		mov	edx, es:[edi]
		add	edi, 4	
		test	dh, 2			; vcpi-page?
		jz	SHORT dosx_novcpipage

		and	dx, 0F000h
		mov	ax, 0DE05h
		push	ds
		push	dosx_sel_data0
		pop	ds
		call	PWORD PTR cs:[OFFSET dosx_vcpi_entry]
		pop	ds

dosx_novcpipage:
		loop	SHORT dosx_check4vcpipage
		pop	cx
;
; test page table entry for beeing vcpi-mem
;
		mov	edx, es:[esi]
		test	dh, 2
		jz	SHORT dosx_nov_v_entr

		and	dx, 0F000h
		mov	ax, 0DE05h
		push	ds
		push	dosx_sel_data0
		pop	ds
		call	PWORD PTR cs:[OFFSET dosx_vcpi_entry]
		pop	ds
		jmp	SHORT dosx_nov_v_entr				

dosx_dealloc_done:
		call	WORD PTR cs:[OFFSET dosx_raw2rm]

dosx_exit_novcpi:
		sti
;
; Release XMS- handle
;
		mov	dx, dosx_xmshandle
		test	dx, dx
		jz	SHORT dosx_exit_noxms

		mov	ah, 0Dh
		call	DWORD PTR [dosx_himem]
		mov	ah, 0Ah
		call	DWORD PTR [dosx_himem]

dosx_exit_noxms:
		test	dosx_mode, a20_used
		jz	SHORT dosx_exit_noa20
;
; Locally disable A20
;
		test	dosx_mode, xms_used
		jz	SHORT dosx_exit_alta20

		mov	ah, 6
		call	DWORD PTR [dosx_himem]

dosx_exit_alta20:
		cli
		call	dosx_testa20
		jz	SHORT dosx_exit_noa20
;		
; Restore a20 state
;
		in	al, 92h
		and	al, 0fdh
		out	92h, al
		call	dosx_testa20
		jz	SHORT dosx_exit_noa20

		call	dosx_wait8042
		mov	al, 0d1h
		out	64h, al
		call	dosx_wait8042
		mov	al, 0fdh
		out	60h, al
		call	dosx_wait8042
		mov	al, 0ffh
		out	64h, al
		call	dosx_wait8042

dosx_exit_noa20:
		sti
		test	dosx_mode, ints_hooked
		jz	SHORT dosx_exit_noints
;
; Unhook all hooked ints
;
		cli
		push	ds
		pop	es
		cld
		mov	cx, 512
		sub	di, di
		mov	es, di
		mov	si, OFFSET dosx_intvectors
		rep	movs WORD PTR es:[di], ds:[si]

dosx_exit_noints:
		ret
dosx_killdpmi	ENDP

dosx_testa20	PROC
		sub	ax, ax
		mov	fs, ax
		dec	ax
		mov	gs, ax
		mov	ax, WORD PTR fs:[0]
		push	ax
		cmp	ax, gs:[16]
		jnz	SHORT dosx_testa20_done

		dec	WORD PTR fs:[0]
		mov	ax, WORD PTR fs:[0]
		cmp	ax, gs:[16]

dosx_testa20_done:
		pop	WORD PTR fs:[0]
		ret
dosx_testa20	ENDP

dosx_xms3	PROC
		pushad
		mov	ah, 0
		call	DWORD PTR [dosx_himem]
		cmp	ah, 3
		jc	skipxms3
;
; The following is a workaround for a Caldera DOS bug, where HIMEM.SYS would
; report XMS 3.0 where it actually only supports XMS 2
;
		mov	ah, 88h
		sub	bx, bx
		call	DWORD PTR [dosx_himem]
		cmp	bl, 80h			; set CF if BL > 0
		setne	bl
		cmp	bl, 1

skipxms3:
		popad
		jc	xms3end

		or	ah, 80h

xms3end:	
		ret
dosx_xms3	ENDP

dosx_toggle	PROC
		pushfd			; try to toggle bit
		pop	eax
		mov	ebx, eax
		xor	eax, esi
		push	eax
		popfd
		pushfd
		pop	eax
		xor	eax, ebx		
		and	eax, esi
		ret
dosx_toggle	ENDP

dosx_storeidt	PROC

dosx_storeidtloop:
		stos	DWORD PTR es:[di]
		mov	ds:[di], edx
		add	eax, ebx
		add	di, 4
		loop	SHORT dosx_storeidtloop

		ret
dosx_storeidt	ENDP

dosx_xms_a20_enable PROC NEAR
		test	cs:dosx_mode, is_tsr
		jz	SHORT dxae_exit

		push	eax
		push	fs
		push	gs
		call	dosx_testa20
		jnz	SHORT dxae_enabled
;
; Do something really evil: temporarily replace int 21h vector with an
; old one. Same for INT 15h. These are the ones himem.sys is likely to use
;
		sub	ax, ax
		mov	fs, ax
		push	DWORD PTR fs:[21h * 4]
		push	DWORD PTR fs:[15h * 4]
		mov	eax, cs:dosx_old21vec
		mov	fs:[21h * 4], eax
		mov	eax, cs:dosx_old15vec
		mov	fs:[15h * 4], eax
;
; Also, mask the PICS, so that no H/W interrupt can occur, should these become
; enabled throughout the XMS fn. call
;
; Locally enable A20 for current application
;
		in	al, 21h
		push	ax
		mov	ax, 5FFh
		out	21h, al
		call	DWORD PTR cs: [dosx_himem]
		pop	ax
		out	21h, al
		pop	DWORD PTR fs:[15h * 4]
		pop	DWORD PTR fs:[21h * 4]

dxae_enabled:
		pop	gs
		pop	fs
		pop	eax

dxae_exit:
		ret
dosx_xms_a20_enable ENDP

dosx_wait8042	PROC

dosx_w8042:
		in	al, 64h
		test	al, 2
		jnz	SHORT dosx_w8042

		ret
dosx_wait8042	ENDP

dosx_new15	PROC
		push	ds
		push	cs
		pop	ds
		cmp	ax, 0E801h
		jne	SHORT dosx_noE801call

		mov	cx, dosx_extsize	; return what's left
		shl	cx, 2			; to kB
		push	eax
		mov	eax, dosx_E801size
;
; If we're under XMS 2, we can give away all the memory. It is the reponsiblity
; of the child program to not use the portion that has been allocated by XMS 2  
;
		shl	eax, 12			; to bytes
		add	eax, dosx_E801start
		shr	eax, 16			; to 64k units
		dec	ah			; sub 16MB
		mov	bx, ax
		mov	dx, ax
		pop	eax
		jmp	SHORT noInt15Mem		

dosx_noE801call:
		cmp	ah, 88h
		jnz	SHORT dosx_chain15

noInt15Mem:
		mov	ax, dosx_extsize	; return what's left
		shl	ax, 2			; to kB
		pop	ds
		iret

dosx_chain15:
		pop	ds
		jmp	cs:dosx_old15vec
dosx_new15	ENDP

dosx_new21	PROC
		cmp	ah, 31h			; resident?
		je	SHORT dosx_checkPSP

		cmp	ah, 4Ch			; terminate?
		jnz	SHORT dosx_chain21

dosx_checkPSP:
;
; Get process id
;
		push	ax
		push	bx
		mov	ah, 62h
		int	21h
		cmp	bx, cs:dosx_pspseg
		pop	bx
		pop	ax
		jnz	SHORT dosx_chain21	; if not our program

		cmp	ah, 4Ch
		je	SHORT dosx_term4C
;
; If XMS driver installed, set the is_tsr bit to allow the call back and IRQ
; passup handlers to re- enable the A20 line.
;
		test	cs:dosx_mode, xms_used
		jz	SHORT dosx_chain21

		or	cs:dosx_mode, is_tsr
;
; Release all interrupt stacks (we do not return to PM)
;
		cli
		mov	cs:dosx_lastintstack, OFFSET dosx_intstacks

dosx_term4C:
;
; Set up main stack
;
		mov	bx, cs
		mov	ss, bx
		mov	sp, OFFSET dosx_top_of_memory

		cmp	ah, 4Ch
		jne	SHORT dosx_chain21
;
; kill DPMI
;
		push	ax
		call	dosx_killdpmi
		pop	ax

dosx_kill_done:
;
; Now terminate
;
		int	21h	; old vector may be invalid now

dosx_chain21:	
		jmp	cs:dosx_old21vec
dosx_new21	ENDP

dosx_new23	PROC
		iret		; return with clear carry=break off
				; 2do: if it really stays just an iret, point
				; it to another arbitrary iret! (1 BYTE saved)
dosx_new23	ENDP

dosx_new24	PROC
		mov	al, 3
		test	ah, 8		; fail allowed?
		jz	SHORT dosx_int24makesproblems

		iret

dosx_int24makesproblems:
		call	dosx_killdpmi	; auto- terminate
		mov	al, 2
		iret
dosx_new24	ENDP
;
; ############## Protmode irq handling ########################################
;
dosx_nointstacks:
;
; here we arrive if there was a problem allocating an interrupt stack in pm
;
		mov	ax, dosx_sel_data16
		mov	ss, ax
		mov	ds, ax
		mov	sp, OFFSET dosx_top_of_memory
		call	WORD PTR ds:[dosx_raw2rm]
		jmp	dosx_rmnostacks

dosx_hnd_checkpic2:
		push	ax
		mov	ax, cs		; get int
		shr	ax, 3		; get irq
		sub	al, 8
		bts	ax, ax
		mov	al, 0bh		; else check if it actually is one
		out	0a0h, al
		in	al, 0a0h		; get in service mask
		jmp	SHORT dosx_hnd_haveisr

dosx_hnd_checkpic1	PROC
		push	ax
		mov	ax, cs		; get int
		shr	ax, 3		; get irq
		bts	ax, ax
		mov	al, 0bh		; else check if it actually is one
		out	20h, al
		in	al, 20h		; get in service mask
;
; Nuke spurious irq 7
;
		or 	al, 80h

dosx_hnd_haveisr:
		test	al, ah
		pop	ax
;
; on ZF decide where to call the handler from
; get room for far ret, do not change flags:
;
		lea	esp, [esp-8]
		push	ebx
		push	esi
		mov	bx, OFFSET dosx_pmirqtab
		jnz	SHORT dosx_hnd_isirq

		mov	bx, OFFSET dosx_pic1backup

dosx_hnd_isirq:
		mov	si, cs
		add	esp, 16
		push	DWORD PTR cs:[si+bx-60]
		push	DWORD PTR cs:[si+bx-64]
		sub	esp, 8
		pop	esi
		pop	ebx
		db	066h
		retf
dosx_hnd_checkpic1		ENDP


dosx_hnd_irq	PROC
;
; There are instances of real mode drivers and BIOSes that clobber the high
; word of general purpose registers. One known case is the Adaptec 2940UW
; SCSI BIOS ver. 1.23, which destroys the high word of EAX in its IRQ handler.
; Therefore, we play safe when calling code that has been written by dodgy
; 16 bit C programmers.
;
		pushad
		push	ds
		push	es
		push	fs
		push	gs
		push	dosx_sel_data16
		pop	ds
;
; o.k. to access 16 bit data now
;
		mov	ds:dosx_isr_ss, ss
		mov	ds:dosx_isr_esp, esp
;
; switch stack to interrupt stack
;
		push	ds
		pop	ss
                add	dosx_lastintstack, dosx_intstacksize
		cmp	dosx_lastintstack, dosx_maxintstack
		jnc	dosx_nointstacks

		movzx	esp, dosx_lastintstack
		push	ds:dosx_isr_ss
		push	ds:dosx_isr_esp
;
; Get irq
;
		mov	ax, cs
		shr	ax, 1
		movzx	eax, ax
		mov	eax, ds:[eax+OFFSET dosx_oldirqs-32]
;
; irq in eax, set farcall
;
		mov	ds:dosx_irqfarcall, eax
;
; switch to realmode
;
		call	WORD PTR ds:[dosx_raw2rm]
;
; do the farcall
;
		pushf
		db	9Ah
dosx_irqfarcall	dd	?
;
; back to pm again
;
		call	WORD PTR ds:[dosx_raw2pm]
		pop	ds:dosx_isr_esp
;
; Check stack for validity, otherwise we'd end up with a triple fault.
;
		pop	ax
		push	ax
		lsl	eax, eax
		cmp	eax, ds:dosx_isr_esp
		ja	irqStackValid
;
; Something has messed with the stack in our IRQ handler. Whoever did that
; would probably want to fix this in their stack fault handler (DJGPP)
;
		pop	ax
		push	eax
		push	ds:dosx_isr_esp
		pushfd
		db	66h
		push	cs
		db	66h
		push	OFFSET irqFaultLoc
		mov	eax, 12			; stack fault
		mov	ds:dosx_exc_ds, ds
		jmp	dosx_simulate_exc
;
; IRQ stack will be released by exception handling code
;
irqStackValid:
;
; restore stack
;
		pop	ss
		mov	esp, ds:dosx_isr_esp
		sub	dosx_lastintstack, dosx_intstacksize
;
; restore selectors
;
irqFaultLoc:
		pop	gs
		pop	fs
		pop	es
		pop	ds
		popad
		iretd
dosx_hnd_irq	ENDP


dosx_hnd_interrupt	PROC

		cli
;
; Quick check for INT 2F/1686
;
		cmp	ax, 1686h
		jne	dosx_no1686

		push	ax
		mov	ax, cs
		cmp	ax, 30h * 8
		pop	ax
		jne	dosx_no1686

		sub	ax, ax
		iretd

dosx_no1686:
		push	ds
		push	es
		push	fs
		push	gs
		push	dosx_sel_data16
		pop	ds
;
; o.k. to access 16 bit data now
;
		mov	dosx_isr_ss, ss
		mov	dosx_isr_esp, esp
		pushf
		add	ds:dosx_lastintstack, dosx_intstacksize
		cmp	ds:dosx_lastintstack, dosx_maxintstack
		jnc	dosx_nointstacks

		popf
		push	ds
		pop	ss
		movzx	esp, ds:dosx_lastintstack
;
; stack o.k.
;
		push	ds:dosx_isr_ss
		push	ds:dosx_isr_esp
		push	eax
		pushf
;
; get interrupt
;
		mov	ax, cs
		shr	ax, 3
		dec	ax
		mov	ds:dosx_isr_int, al
;
; switch to realmode
;
		call	WORD PTR ds:[OFFSET dosx_raw2rm]
		popf
		pop	eax
		db	0CDh
dosx_isr_int	db	?
		cli			; BIOS calls will re-enable ints
		push	eax
		pushf
		call	WORD PTR ds:[OFFSET dosx_raw2pm]
 		popf
		pop	eax
		pop	ds:dosx_isr_esp
;
; restore stack
;
		pop	ss
		mov	esp, ds:dosx_isr_esp
;
; release int stack
;
		pushf
		sub	ds:dosx_lastintstack, dosx_intstacksize
		popf
;
; restore selectors
;
		pop	gs
		pop	fs
		pop	es
		pop	ds
;
; restore stack
; give some flags back to user program
;
		push	ax
		pushf
		pop	ax
		and	ax, 0DFFh
		and	WORD PTR [esp + 10], 0F200h
		or	WORD PTR [esp + 10], ax
		pop	ax
		iretd
dosx_hnd_interrupt	ENDP

dosx_hnd_10to1F		PROC
		push	eax
		push	ebx
		push	ecx
		mov	bx, ds
		mov	ax, cs
		shl	ax, 5
		dec	ah
		mov	al, 0CDh
		mov	ds, [esp + 16]
		mov	ecx, [esp + 12]
;
; check whether the code at cs:eip-2 is INT nn
; this is not quite correct since the next instruction
; may have caused the exception... oh well!
;
		cmp	WORD PTR ds:[ecx - 2], ax
		mov	ds, bx
		pop	ecx
		movzx	eax, ah
		jz	SHORT dosx_is_int10to1f

		pop	ebx
		pop	eax
		jmp	SHORT dosx_hnd_exception

dosx_is_int10to1f:
;
; it is an interrupt, so call the handler
;
		mov	ebx, DWORD PTR cs:[eax*8+OFFSET dosx_int10to1F-80h]
		mov	eax, DWORD PTR cs:[eax*8+OFFSET dosx_int10to1F-7ch]
		xchg	ebx, [esp]
		xchg	eax, [esp+4]
		db	66h
		retf
dosx_hnd_10to1F		ENDP

dosx_hnd_exception:
;
; check for user installed handler, otherwise throw out registers
; use startup code to overwrite
;
dosx_exc_errcode	EQU	DWORD PTR ds:[OFFSET start + 0]
dosx_exc_offset		EQU	DWORD PTR ds:[OFFSET start + 4]
dosx_exc_selector	EQU	DWORD PTR ds:[OFFSET start + 8]
dosx_exc_eflags		EQU	DWORD PTR ds:[OFFSET start + 12]

dosx_exc_eax		EQU	DWORD PTR ds:[OFFSET start + 16]
dosx_exc_esp		EQU	DWORD PTR ds:[OFFSET start + 20]
dosx_rep_errcode	EQU	DWORD PTR ds:[OFFSET start + 24]
dosx_rep_offset		EQU	DWORD PTR ds:[OFFSET start + 28]
dosx_rep_selector	EQU	WORD PTR ds:[OFFSET start + 32]
dosx_rep_eflags		EQU	DWORD PTR ds:[OFFSET start + 36]
dosx_rep_eax		EQU	DWORD PTR ds:[OFFSET start + 40]
dosx_rep_esp		EQU	DWORD PTR ds:[OFFSET start + 44]
;dosx_exc_cr0		EQU	DWORD PTR ds:[OFFSET start + 48]
;dosx_exc_cr2		EQU	DWORD PTR ds:[OFFSET start + 52]
;dosx_exc_cr3		EQU	DWORD PTR ds:[OFFSET start + 56]
;dosx_exc_es		EQU	WORD PTR ds:[OFFSET start + 60]
;dosx_exc_fs		EQU	WORD PTR ds:[OFFSET start + 62]
;dosx_exc_gs		EQU	WORD PTR ds:[OFFSET start + 64]
dosx_exc_ds		EQU	WORD PTR ds:[OFFSET start + 66]
dosx_exc_ss		EQU	WORD PTR ds:[OFFSET start + 68]
dosx_rep_ds		EQU	WORD PTR ds:[OFFSET start + 70]
dosx_rep_ss		EQU	WORD PTR ds:[OFFSET start + 76]
;dosx_exc_ldt		EQU	WORD PTR ds:[OFFSET start + 82]
;dosx_exc_tr		EQU	WORD PTR ds:[OFFSET start + 84]
dosx_exc_number		EQU	BYTE PTR ds:[OFFSET start + 86]
;
; Stackframe now:
;            (errorcode)
;            (E)IP
;            CS
;            (E)flags
;
		push	ds
		push	dosx_sel_data16
		pop	ds
		pop	dosx_exc_ds
		mov	dosx_exc_eax, eax	; save eax
		mov	ax, cs			; get exc nr.
		shr	ax, 3
		dec	ax
		mov	dosx_exc_number, al	; save exception number
		test	al, 8
		jz	SHORT dosx_exc_noerrcode

		pop	dosx_exc_errcode

dosx_exc_noerrcode:
;
; check for exceptions 10h - 1fh
;
		cmp	al, 17
		jnz	SHORT dosx_exc_really_noerrcode

		pop	dosx_exc_errcode
;
; (V 0.93) check whether exception handler set V.094 do it for higher ones too
; (V 0.95) There will be an exception handler set REGARDLESS, so remove this
; check.
;
dosx_exc_really_noerrcode:
		cwde
		pop	dosx_exc_offset
		pop	dosx_exc_selector
		pop	dosx_exc_eflags
		mov	dosx_exc_ss, ss
		mov	dosx_exc_esp, esp
		push	ds
		pop	ss
;
; (V 0.93) call the user exception handler
; try to get an interrupt stack
;
                add	ds:dosx_lastintstack, dosx_intstacksize
		cmp	ds:dosx_lastintstack, dosx_maxintstack
		jnc	dosx_nointstacks	; now completely fucked up

		movzx	esp, dosx_lastintstack
;
; build stack frame
;
		push	0
		push	dosx_exc_ss
		push	dosx_exc_esp
		push	dosx_exc_eflags
		push	dosx_exc_selector
		push	dosx_exc_offset
;
; Entry point from simulated stack fault
;
dosx_simulate_exc:
		push	dosx_exc_errcode
		push	0
		push	cs
		dw	6866h	;push DWORD
		dd	OFFSET dosx_from_exc
		push	DWORD PTR ds:[eax * 8 + OFFSET dosx_ehandlers + 4]
		push	DWORD PTR ds:[eax * 8 + OFFSET dosx_ehandlers]
		mov	eax, dosx_exc_eax
		mov	ds, dosx_exc_ds
		db	66h
		retf

dosx_from_exc:
		push	ds
		push	dosx_sel_data16
		pop	ds
		pop	dosx_exc_ds
		add	esp, 4
		pop	dosx_exc_offset
		pop	dosx_exc_selector
		pop	dosx_exc_eflags
		lss	esp, [esp]
                sub	ds:dosx_lastintstack, dosx_intstacksize
		push	dosx_exc_eflags
		push	dosx_exc_selector
		push	dosx_exc_offset
		mov	ds, dosx_exc_ds
		iretd

;-----------------------------------------------------------------------------
; Common exception handler code. The difficulty is to deal with both, 16 and
; 32 bit stacks.
;
CommonException:
;
; Stack:          EAX
;                 R EIP
;                 R CS
;                 ERROR CODE
;                 F EIP
;                 F CS
;                 F EFLAGS
;                 F ESP
;                 F SS
;
		push	ebx
		mov	bx, ds			; "push ds" might push just
		push	ebx			; 2 bytes...
		mov	ds, cs:[dosx_flat_sel_data16]
		mov	dosx_rep_ds, bx
;
; Grab information from stack
;
		mov	ebx, [esp+20]
		mov	dosx_rep_errcode, ebx
		mov	ebx, [esp+24]
		mov	dosx_rep_offset, ebx
		mov	bx, [esp+28]
		mov	dosx_rep_selector, bx
		mov	ebx, [esp+32]
		mov	dosx_rep_eflags, ebx
		mov	ebx, [esp+36]
		mov	dosx_rep_esp, ebx
		mov	bx, [esp+40]
		mov	dosx_rep_ss, bx
		mov	dosx_exc_number, al
		mov	ebx, OFFSET fatalException
		mov	[esp+24], ebx
		mov	bx, cs
		mov	[esp+28], bx
		mov	bx, 200h
		mov	[esp+36], ebx			; high word already 0!
		mov	bx, ds
		mov	[esp+40], bx
		pop	ebx
		mov	ds, bx
		pop	ebx
		pop	eax
		db	66h
		retf
; 
; As 32 iterations wouldn't allow for short jumps anymore, we split the
; exception vector tables.
;
Exc0to15 LABEL NEAR
i = 0
REPT	16
	elabel	CATSTR <Exception>, %i
elabel:
		push	eax
		mov	al, i
		jmp	SHORT JmpToCommon
	i = i + 1
ENDM

JmpToCommon:
		jmp	CommonException

Exc16to32 LABEL NEAR
i = 16
REPT	16
		push	eax
		mov	al, i
		jmp	SHORT JmpToCommon
	i = i + 1
ENDM

fatalException:
		push	ss				; sanitize DS
		pop	ds
;
; Push a lot of things onto the stack and print them out. When done, terminate.
; At this point we know that we have a 16 bit stack, so things are safe.
; 
		push	gs
		push	fs
		push	es
		push	dosx_rep_ds
		push	dosx_rep_ss
		push	dosx_rep_errcode
		push	dosx_rep_eflags
		push	dosx_rep_esp
		push	ebp
		push	edi
		push	esi
		push	edx
		push	ecx
		push	ebx
		push	eax
		push	dosx_rep_offset
		push	dosx_rep_selector
		movzx	ax, dosx_exc_number
		push	ax
;
; Now that we have all the relevant information on the stack, do the output.
;
		mov	ah, 0Fh
		int	10h
		and	al, 7Fh
		cmp	al, 3
		jz	dosx_exc_noset

		mov	ax, 3
		int	10h

dosx_exc_noset:

		cld
		mov	si, OFFSET dosx_exc_string

dosx_exc_loop:
		lodsb
		test	al, al
		jz	dosx_exc_done

		cmp	al, '%'
		jnz	dosx_exc_out

		lodsb
		pop	di
		cmp	al, '8'
		jnz	dosx_exc_out4

		xchg	bp, di
		pop	di
		call	dosx_hexout_di
		xchg	bp, di

dosx_exc_out4:
		call	dosx_hexout_di
		jmp	dosx_exc_loop

dosx_exc_out:
		mov	ah, 2
		mov	dl, al
		int	21h
		jmp	dosx_exc_loop

dosx_exc_done:
		mov	ah, 4ch
		int	21h

dosx_hexout_di	PROC
		mov	cx, 4

dosx_o16_loop:
		rol	di, 4
		mov	dx, di
		and	dl, 0Fh
		cmp	dl, 10
		jc	dosx_o16_num

		add	dl, 7

dosx_o16_num:
		add	dl, 30h
		mov	ah, 2
		int	21h
		loop	dosx_o16_loop

		ret
dosx_hexout_di	ENDP

dosx_new1C:
		test	BYTE PTR cs:[OFFSET dosx_pmhands + 3], 10h
		jnz	passup1c

chain1c:
		jmp	cs:dosx_old1Cvec

passup1c:
		bts	WORD PTR cs:[OFFSET dosx_pmhands + 2], 15
		jc	SHORT chain1c

		push	OFFSET dosx_start_irqs + 3 + (1Ch * 4)
		jmp	SHORT dosx_gen_rmirq
;
; ############## Generic realmode irq handler #################################
;
; realmode irq entry points

dosx_start_irqs	LABEL	WORD
		rept 16
		call	dosx_gen_rmirq
		nop
		endm
dosx_end_irqs	LABEL	WORD

dosx_gen_rmirq:
assume	ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

		cli
		sub	sp, 2
		push	bp
		mov	bp, sp
		push	eax
		movzx	eax, WORD PTR [bp+4]
		sub	ax, OFFSET dosx_start_irqs+3
		shr	ax, 2
;
; irq number in eax
; check if pm- handler set
;
		bt	cs:dosx_pmhands, eax
		jc	SHORT dosx_int2pm

dosx_chain_irq:
		add	sp, 10
		push	DWORD PTR cs:[eax * 4 + OFFSET dosx_oldirqs]
		mov	eax, ss:[bp-4]
		mov	bp, ss:[bp]
		retf

dosx_int2pm:
		call	dosx_xms_a20_enable
;
; This one sucks: reflecting a real mode interrupt into pm, not knowing
; what the pm-handler does...
;
; get selector/OFFSET of pm- handler
;
		push	DWORD PTR cs:[eax*8 + OFFSET dosx_pmirqtab]
		push	WORD PTR cs:[eax*8 + OFFSET dosx_pmirqtab+4]
		pop	cs:dosx_irq_sel
		pop	DWORD PTR cs:[OFFSET dosx_irq_offset]
;
; restore original stack
;
		pop	eax
		pop	bp
		add	sp, 4
;
; save caller stack
;
		mov	cs:dosx_switch_ss, ss
		mov	cs:dosx_switch_esp, esp
		add	cs:dosx_lastintstack, dosx_intstacksize
		cmp	cs:dosx_lastintstack, dosx_maxintstack
		jc	SHORT dosx_gotintstack
;
; we have a problem right now
;
dosx_rmnostacks:
		mov	al, 20h
		out	0a0h, al
		out	20h, al
		mov	ax, cs
		mov	ss, ax
		mov	sp, OFFSET dosx_top_of_memory
		call	dosx_killdpmi
		lea	dx, dosx_msg_nointstacks
		jmp	dosx_exitmsg

dosx_gotintstack:
		mov	ss, cs:dosx_patch1	; get ss
		movzx	esp, cs:dosx_lastintstack
;
; o.k. to access stack
;
		push	cs:dosx_switch_ss
		push	ds
		push	es
		push	fs
		push	gs
		push	cs:dosx_switch_esp
		push	eax
;
; switch to pm
;
		call	WORD PTR cs:[OFFSET dosx_raw2pm]
;
; now in pm, call protected mode handler
; no reentrancy as of here
; reentrancy only matters if the handler enables interrupts or does an int call
;
		pushfd
		dw	9A66h			; call far use32
dosx_irq_offset	dd	?
dosx_irq_sel	dw	?
;
; hope it will finally IRETD _here_ (god knows)
;
		call	WORD PTR cs:[OFFSET dosx_raw2rm]
;
; back again in rm
;
		pop	eax
		cli
		btr	WORD PTR ds:[OFFSET dosx_pmhands + 2], 15
		pop	ds:dosx_switch_esp
		pop	gs
		pop	fs
		pop	es
		pop	ds
		pop	ss
;
; stack switched now!
;
		mov	esp, cs:dosx_switch_esp
		sub	cs:dosx_lastintstack, dosx_intstacksize
		iret
;
; ############# Realmode callback support ####################################
;
		align 4

dosx_callback_entry	LABEL NEAR
rept 16
	call callback_proc
	db	0	; free indicator
endm

callback_proc	PROC	NEAR
		pushf
		cli
		pop	WORD PTR cs:[OFFSET dosx_callback_fltemp]
		call	dosx_xms_a20_enable
;
; save caller's ss:sp, callback id
;
		pop	WORD PTR cs:[OFFSET dosx_callback_idtemp]
		mov	WORD PTR cs:[OFFSET dosx_callback_sstemp], ss
		mov	WORD PTR cs:[OFFSET dosx_callback_sptemp], sp
;
; now get an interrupt stack
;
		push	cs
		pop	ss
		add	cs:dosx_lastintstack, dosx_intstacksize
		cmp	cs:dosx_lastintstack, dosx_maxintstack
		jnc	dosx_rmnostacks

		mov	sp, cs:dosx_lastintstack
;
; ajust return ip
;
		sub	WORD PTR cs:[OFFSET dosx_callback_idtemp], 3
		push	ax		; (mis)align stack
		push	WORD PTR cs:[OFFSET dosx_callback_sstemp]
		push	WORD PTR cs:[OFFSET dosx_callback_sptemp]
		push	cs
		push	WORD PTR cs:[OFFSET dosx_callback_idtemp]
		push	gs
		push	fs
		push	ds
		push	es
		push	WORD PTR cs:[OFFSET dosx_callback_fltemp]
		pushad
;
; switch to pm
;
		call	WORD PTR cs:[dosx_raw2pm]
;
; prepare dest
;
		mov	bx, ds:dosx_callback_idtemp
		sub	bx, OFFSET dosx_callback_entry
		add	bx, bx
		les	edi, PWORD PTR ds:[bx+OFFSET dosx_callback_strucs]
;
; prepare source
;
		mov	esi, esp
;
; copy stuff
;
		push	edi
		cld
		mov	ecx, 12
		rep	movs DWORD PTR es:[edi], ds:[esi]
		movs	WORD PTR es:[edi], ds:[esi]
		pop	edi
;
; adjust stack, if stackspace is a concern
;		add	esp, 52

		pushfd				; iret frame
;
; prepare stack reference OFFSET
;
		movzx	edx, ds:[dosx_callback_sstemp]
		shl	edx, 4
		movzx	esi, ds:[dosx_callback_sptemp]
		add	esi, edx
		mov	ax, dosx_sel_data0
		mov	ds, ax
		call	PWORD PTR cs:[bx+OFFSET dosx_callback_procs]
;
; here we return if nothing crashed
; swap some selectors
;
		push	es
		pop	ds
		push	ss
		pop	es
		mov	esi, edi
;
; if we ajusted the stack above we had to sub esp, 52 here
;
		mov	edi, esp
		mov	ecx, 12
;
; in 999.999 out of 1.000.000 cases we could just move 52 bytes, but what...?
;
		rep	movs DWORD PTR es:[edi], ds:[esi]
		movs	WORD PTR es:[edi], ds:[esi]
;
; switch back to RM
;
		call	WORD PTR cs:[dosx_raw2rm]
;
; pop stuff
;
		popad
		pop	WORD PTR ds:[OFFSET dosx_callback_fltemp]
		pop	es
		pop	ds
		pop	fs
		pop	gs
		pop	WORD PTR cs:[OFFSET dosx_callback_iptemp]
		pop	WORD PTR cs:[OFFSET dosx_callback_cstemp]
		pop	WORD PTR cs:[OFFSET dosx_callback_sptemp]
		pop	ss
		mov	sp, WORD PTR cs:[OFFSET dosx_callback_sptemp]
;
; release interrupt stack
;
		sub	cs:dosx_lastintstack, dosx_intstacksize
;
; build iret stack frame
;
		push	WORD PTR cs:[OFFSET dosx_callback_fltemp]
		push	WORD PTR cs:[OFFSET dosx_callback_cstemp]
		push	WORD PTR cs:[OFFSET dosx_callback_iptemp]
		iret
callback_proc	ENDP
;
; ############## very, very raw mode switch proc's ###########################
; trashes eax, high WORD of esp return:ax=16 bit data selector or realmode cs
; req'd: ss = code16 or dosx_sel_data16!, sp set to valid stack
;
dosx_rm2prot	PROC	NEAR
;
; clear NT+ INT-flag
;
		push	0
		popf
		lgdt	cs:dosx_gdtr
		lidt	cs:dosx_idtr
;
; set cr3
;
		mov	eax, cs:dosx_cr3_base
		mov	cr3, eax
;
; enter pm
;
		mov	eax, cr0
		or	eax, 80000001h
		mov	cr0, eax
		db	0EAh
		dw	OFFSET	dosx_rm2prot1
		dw	dosx_sel_code16

dosx_rm2prot1:
		mov	ax, dosx_sel_data16
		mov	ss, ax
		movzx	esp, sp
		mov	ds, ax
		mov	es, ax
		mov	fs, ax
		mov	gs, ax
		ret
dosx_rm2prot	ENDP

dosx_prot2rm	PROC
		push	0
		popf
		mov	ax, dosx_sel_data16
		mov	ds, ax
		mov	es, ax
		mov	ss, ax
		mov	fs, ax
		mov	gs, ax
		mov	eax, cr0
		and	eax, 7FFFFFFEh
		mov	cr0, eax
		sub	eax, eax
		mov	cr3, eax
		db	0EAh
		dw	OFFSET dosx_prot2rm1
dosx_patch1	dw	?

dosx_prot2rm1:
		lgdt	cs:dosx_rm_gdt
		lidt	cs:dosx_rm_idt

dosx_retfrompm:
		mov	ax, cs
		mov	ss, ax
		mov	ds, ax
		mov	es, ax
		mov	fs, ax
		mov	gs, ax
		movzx	esp, sp
		ret
dosx_prot2rm	ENDP

dosx_v862prot	PROC	NEAR
		push	0
		popf
		push	esi
		push	bp
		mov	bp, sp
		mov	esi, cs:dosx_v86struc
		mov	ax, 0DE0Ch
		int	67h

dosx_v862prot1:
		mov	ax, dosx_sel_data16
		mov	ds, ax
		mov	es, ax
		mov	ss, ax
		movzx	esp, bp
		mov	fs, ax
		mov	gs, ax
		pop	bp
		pop	esi
		ret
dosx_v862prot	ENDP

dosx_prot2v86	PROC
		push	0
		popf
		movzx	eax, sp
		sub	sp, 16	; skip ds, es, fs, gs
		dw	6866h	; push DWORD
dosx_patch2	dw 	?
		dw	0
		push	eax
		pushfd
		dw	6866h	; push DWORD
dosx_patch3	dw 	?
		dw	0
		dw	6866h	; push DWORD
		dd	OFFSET dosx_retfrompm
		mov	ax, dosx_sel_data0
		mov	ds, ax
		mov	ax, 0de0ch
		sub	sp, 8
		dw	0EA66h
dosx_vcpi_entry	LABEL	PWORD
dosx_vcpiOFFSET	dd	?
dosx_vcpisel	dw	?
		dw	0
dosx_prot2v86	ENDP

; ############################################################################
; ##                      The DPMI 0.9 emulation                            ##
; ############################################################################

dosx_int31:
;
; speedup for virtual interrupts
;
		cmp	ah, 9
		jnz	SHORT dpmi_no_vint
;
; clear carry flag
;
		and	BYTE PTR [esp+8], 0FEh
		cmp	al, 2
		jz	SHORT dpmi_get

		cmp	al, 1
		jz	SHORT dpmi_set

		btr	WORD PTR [esp+8], 9
		setc	al
		iretd

dpmi_set:	
		bts	WORD PTR [esp+8], 9
		setc	al
		iretd

dpmi_get:
		bt	WORD PTR [esp+8], 9
		setc	al
		iretd

assume ds:code16
dpmi_no_vint:
		cld
		push	es
		push	fs
		push	ds
		pop	fs		; orig. ds needed for callback
		push	ds
		push	gs
		push	dosx_sel_data16
		pop	ds
;
; o.k. to access 16 bit data now
;
		mov	dosx_isr_ss, ss
		mov	dosx_isr_esp, esp
		add	ds:dosx_lastintstack, dosx_intstacksize
		cmp	ds:dosx_lastintstack, dosx_maxintstack
		jnc	dosx_nointstacks

		push	ds
		pop	ss
		movzx	esp, ds:dosx_lastintstack
;
; stack o.k., store user program stack on temp stack
;
		push	ds:dosx_isr_ss
		push	ds:dosx_isr_esp
		pushad
		mov	bp, sp
;
; get function to jump to
;
		mov	si, OFFSET dpmi_groups
		sub	bx, bx
		xchg	bl, ah
		cmp	bx, [si]
		jnc	dpmi_exitcarry

		add	bx, bx
		mov	si, [bx + si + 2]
		mov	bx, ax
		cmp	bx, [si]
		jnc	dpmi_exitcarry

		add	bx, bx
		jmp	WORD PTR [bx + si + 2]

		align 2

dpmi_groups	LABEL	WORD
		dw	09h		; highest group supported+1
		dw	OFFSET dpmi_00
		dw	OFFSET dpmi_01
		dw	OFFSET dpmi_02
		dw	OFFSET dpmi_03
		dw	OFFSET dpmi_04
		dw	OFFSET dpmi_05
		dw	OFFSET dpmi_06
		dw	OFFSET dpmi_07
		dw	OFFSET dpmi_08

dpmi_00		LABEL	WORD
		dw	0Dh		; highest function supported +1
		dw	OFFSET int310000
		dw	OFFSET int310001
		dw	OFFSET int310002
		dw	OFFSET int310003
		dw	OFFSET dpmi_exitcarry
		dw	OFFSET dpmi_exitcarry
		dw	OFFSET int310006
		dw	OFFSET int310007
		dw	OFFSET int310008
		dw	OFFSET int310009
		dw	OFFSET int31000a
		dw	OFFSET int31000b
		dw	OFFSET int31000c

dpmi_01		LABEL	WORD
		dw	03h		; highest function supported +1
		dw	OFFSET int310100
		dw	OFFSET int310101
		dw	OFFSET int310102

dpmi_02		LABEL	WORD
		dw	06h		; highest function supported +1
		dw	OFFSET int310200
		dw	OFFSET int310201
		dw	OFFSET int310202
		dw	OFFSET int310203
		dw	OFFSET int310204
		dw	OFFSET int310205

dpmi_03		LABEL	WORD
		dw	05h
		dw	OFFSET int310300
		dw	OFFSET int310301
		dw	OFFSET int310302
		dw	OFFSET int310303
		dw	OFFSET int310304

dpmi_04		LABEL	WORD
		dw	01h
		dw	OFFSET int310400

dpmi_05		LABEL	WORD
		dw	04h
		dw	OFFSET int310500
		dw	OFFSET int310501
		dw	OFFSET int310502
		dw	OFFSET int310503

dpmi_06		LABEL	WORD
		dw	05h
		dw	OFFSET dpmi_exitok
		dw	OFFSET dpmi_exitok
		dw	OFFSET dpmi_exitok
		dw	OFFSET dpmi_exitok
		dw	OFFSET int310604

dpmi_07		LABEL	WORD
		dw	04h
		dw	OFFSET dpmi_exitcarry
		dw	OFFSET dpmi_exitcarry
		dw	OFFSET dpmi_exitok
		dw	OFFSET dpmi_exitok

dpmi_08		LABEL	WORD
		dw	02h
		dw	OFFSET int310800
		dw	OFFSET int310801

;******************************************************************************
;- HELPER PROCS
;******************************************************************************

dpmi_index_gdt	PROC
		test	bl, 7
		jnz	dpmi_exitcarry

		cmp	bx, 0848h	; 0.93
		jc	dpmi_exitcarry

		cmp	bx, 512*8
		jnc	dpmi_exitcarry

		mov	si, OFFSET dosx_gdt
		ret
dpmi_index_gdt	ENDP

dpmi_check_gdt	PROC
;
; bx = selector to start with
; cx = number of descriptors to check
; returns: bx = base selector or never returns
; never, never call with cx=0!
;
		mov	dx, cx
		sub	si, si

dpmi_find_one:
		test	BYTE PTR [si+bx+OFFSET dosx_gdt + 6], 10h
		jnz	SHORT dpmi_try_next
;
; well, at least this one is free
;
		dec	cx
		jz	SHORT dpmi_gdt_fine
;
; check subsequent descriptors
;
		add	si, 8
		lea	ax, [bx+si]
		cmp	ax, 512*8
		jc	SHORT dpmi_find_one
;
; executing the next instructions will also result in error and save some space
;
dpmi_try_next:
		lea	bx, [bx + si + 8]
		cmp	bx, 512 * 8
		jnc	dpmi_exitcarry

		mov	cx, dx			; restore count
		jmp	SHORT dpmi_find_one

dpmi_gdt_fine:
;
; mark descriptors as used, initialize do data r/w everything
; else = 0 /Wuschel 10/96: make sure the base actually is zero
;
		mov	DWORD PTR [si+bx+OFFSET dosx_gdt], 0
		mov	DWORD PTR [si+bx+OFFSET dosx_gdt+4], 109200h
		sub	si, 8
		jnc	SHORT dpmi_gdt_fine

		mov	cx, dx
		ret
dpmi_check_gdt	ENDP

dpmi_xam_int	PROC
		mov	ax, dosx_sel_bigdos
		mov	fs, ax
		sub	si, si
		call	dpmi_xam_pmint
		jnc	SHORT dpmi_dosvec

		mov	si, OFFSET dosx_oldirqs
		push	ds
		pop	fs

dpmi_dosvec:
		shl	bx, 2
		ret
dpmi_xam_int	ENDP

dpmi_xam_pmint	PROC
;
; check if the caller wants an irq- vector cf set if in 8..15, 70h..77h
;
		mov	bl, _bl[bp]
		sub	bh, bh
		cmp	bl, 8
		jc	SHORT dpmi_get_vec

		cmp	bl, 78h
		jnc	SHORT dpmi_get_vec

		cmp	bl, 10h
		jc	SHORT dpmi_get_irq

		cmp	bl, 70h
		jc	SHORT dpmi_get_vec

dpmi_get_irq:
		and	bl, 1fh
		sub	bl, 8
		stc
		ret

dpmi_get_vec:
		clc
		ret
dpmi_xam_pmint	ENDP

dpmi_xam_picmap	PROC
;
; check if the handler rEQUested is in pic shadow
;
		mov	ax, WORD PTR ds:[OFFSET dosx_pic1map]	
		cmp	bl, al
		jc	SHORT dpmi_notinpic1

		add	al, 8
		cmp	bl, al
		jnc	SHORT dpmi_notinpic1
;
; is in pic1-shadow, index goes from 0..7
;
		and	bl, 7
		stc
		ret

dpmi_notinpic1:
		cmp	bl, ah
		jc	SHORT dpmi_notinpic2

		add	ah, 8
		cmp	bl, ah
		jnc	SHORT dpmi_notinpic2
;
; is in pic2-shadow, index goes from 8..15
;
		or	bl, 8
		and	bl, 0fh
		stc
		ret

dpmi_notinpic2:
		shl	bx, 3	; clears carry!
		ret
dpmi_xam_picmap	ENDP

;******************************************************************************
;- INT 31h
;******************************************************************************

;------------------------------------------------------------------------------
;AX = 0000h		ALLOCATE LDT DESCRIPTORS
; CX = # of descriptors to alloc.
; RET CF clear -> ok. AX = base selector /all have BASE 0 LIMIT 0 /data
; add the increment froom AX = 3 to get subsEQUent
;------------------------------------------------------------------------------

int310000:
;
; parse gdt for the requested block of descriptors (AVL= 0)
; start at gdt.282
;
		mov	bx, 282*8
		mov	cx, _cx[bp]
		call	dpmi_check_gdt
		mov	_ax[bp], bx
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0001h		FREE LDT DESCRIPTOR
; BX = selector
; RET CF clear (1.0 sets all segregs containing bx to 0)
;------------------------------------------------------------------------------

int310001:
;
; mask bx to gdt/rpl0, refuse any call for selector < gdt.282 or > gdt.511
;
		mov	bx, _bx[bp]
		call	dpmi_index_gdt
;
; zero out the descriptor's AVL
;
		mov	BYTE PTR [bx+si+6], 0
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0002h		SEGMENT 2 DESCRIPTOR
; BX = real mode segment
; RET CF clear AX = selector 64k /data???
; returned descriptor can never be modified or freed
; multiple calls return the same selector
;------------------------------------------------------------------------------

int310002:
;
; parse gdt for 64k 286 data descriptor that would fit, if not found, make one
; if gdt full, carry
;
		mov	eax, _ebx[bp-2]
		mov	edx, 109200h/16
		shld	edx, eax, 4
		shl	eax, 4
		mov	ax, 0ffffh
		mov	edi, edx	;be aware of acessed bit
		or	di, 100h
		mov	bx, 8
		mov	cx, 511

dpmi_findgdtloop1:
		cmp	eax, [bx+OFFSET dosx_gdt]
	jnz	SHORT dpmi_this_descriptor_is_not_the_one_we_are_looking_for

		cmp	edx, [bx+OFFSET dosx_gdt+4]
		jz	SHORT dpmi_finally_we_found_a_suitable_descriptor

		cmp	edi, [bx+OFFSET dosx_gdt+4]
		jz	SHORT dpmi_finally_we_found_a_suitable_descriptor

dpmi_this_descriptor_is_not_the_one_we_are_looking_for:
		add	bx, 8
		loop	SHORT dpmi_findgdtloop1

		push	eax
		push	edx
		mov	bx, 282*8
		mov	cx, 1
		call	dpmi_check_gdt
		pop	DWORD PTR [bx+OFFSET dosx_gdt+4]
		pop	DWORD PTR [bx+OFFSET dosx_gdt]

dpmi_finally_we_found_a_suitable_descriptor:
		mov	_ax[bp], bx
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0003h		GET NEXT SELECTOR INC
; RET CF clear AX = INC
;------------------------------------------------------------------------------

int310003:
;
; return(8)
;
		mov	_al[bp], 8
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0004/0005		LOCK/UNLOCK SELECTOR (RESERVED)
; WE DO NOT SUPPORT THIS, SETTING CF
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;AX = 0006h		GET SEGMENT BASE ADDRESS
; BX = SELECTOR
; RET CF clear CX:DX = linear base address
;------------------------------------------------------------------------------

int310006:
;
; only accept selectors 282..511, return the base from gdt if selector valid
; V 0.93 : Accept PSP, environment... as well
;
		mov	bx, _bx[bp]
		test	bx, 0FFF8h
		jz	dpmi_exitcarry

		test	bl, 7
		jnz	dpmi_exitcarry

		cmp	bx, 512*8
		jnc	dpmi_exitcarry

		mov	si, OFFSET dosx_gdt
		cmp	bx, 850h
		jc	SHORT @@skiptest

		test	BYTE PTR [bx+si+6], 10h
		jz	dpmi_exitcarry

@@skiptest:
		mov	eax, [bx+si+1]
		mov	al, [bx+si+7]
		ror	eax, 24
		mov	_cx[bp], ax
		ror	eax, 16
		mov	_dx[bp], ax
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0007h		SET SEGMENT BASE ADDRESS
; BX = SELECTOR
; CX:DX = linear base
; RET CF clear
; (1.0 reloads segregs)
;------------------------------------------------------------------------------
int310007:

; only accept selectors 282..511, set base in gdt if selector valid

		mov	bx, _bx[bp]
		call	dpmi_index_gdt
		test	BYTE PTR [bx+si+6], 10h
		jz	dpmi_exitcarry

		mov	ax, _dx[bp]
		ror	eax, 16
		mov	ax, _cx[bp]
		rol	eax, 24
		mov	[bx+si+7], al
		mov	al, [bx+si+1]
		mov	[bx+si+1], eax
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0008h		SET SEGMENT LIMIT
; BX = SELECTOR
; CX:DX = limit (-1 as in descriptor)
; RET CF clear
; limits > 1MB page aligned
; (1.0 reloads segregs)
;------------------------------------------------------------------------------

int310008:
;
; only accept selectors 282..511, shr limit 12 if limit > 100000h-1, 
; set B- bit then, set limit in gdt if selector valid
;
		mov	bx, _bx[bp]
		call	dpmi_index_gdt
		test	BYTE PTR [bx+si+6], 10h
		jz	dpmi_exitcarry

		mov	ax, _cx[bp]
		and	BYTE PTR [bx+si+6], 70h	; reset granularity+limit high
		test	ax, ax
		jz	SHORT int310007001

		or	BYTE PTR [bx+si+6], 40h	; set B

int310007001:	
		ror	eax, 16
		mov	ax, _dx[bp]
		test	eax, 0fff00000h		; greater 1MB?
		jz	SHORT dpmi_is_below_1meg

IFDEF NUCLEAR_FACILITY
	mov	cx, ax
	and	cx, 0fffh
	inc	cx
	jnz	dpmi_exitcarry
ENDIF

		shr	eax, 12				; to pages
		or	BYTE PTR [bx + si + 6], 080h	; set granularity

dpmi_is_below_1meg:
		mov	[bx + si], ax
		shr	eax, 16
		or	BYTE PTR [bx + si + 6], al
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0009h		SET ACC
; BX = SELECTOR
; CL = ACC/TYP - BYTE
; CH = EXT/TYP (32 bit stuff)
; RET CF clear
; if present bit clear, CL.0-3 may have any val.
; (1.0 reloads segregs)
;------------------------------------------------------------------------------

int310009:
;
; only accept selectors 282..511, set ACC if selector valid
;
		mov	bx, _bx[bp]
		call	dpmi_index_gdt
		test	BYTE PTR [bx + si + 6], 10h
		jz	dpmi_exitcarry

		mov	ax, _cx[bp]
;
; force dpl0+this one that must be zero:
;
		and	ax, 0C09Eh
;
; do not let the user program screw up our descr. management
;
		and	WORD PTR [bx+si+5], 01F00h
		or	WORD PTR [bx+si+5], ax
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 000Ah		CREATE ALIAS
; BX = SELECTOR (CODESEG!)
; RET CF clear AX = datasel
;------------------------------------------------------------------------------

int31000A:

; only accept selectors 282..511, check if descriptor = code
; store acc modified descriptor, error if gdt full

		mov	bx, _bx[bp]
		call	dpmi_index_gdt
		test	BYTE PTR [bx + si + 6], 10h
		jz	dpmi_exitcarry

		mov	al, BYTE PTR [bx + si + 5]
;
; V 0.94 Don't do this since there seems to be software (DJGPP?) relying on
; this call to NOT fail for a data type selector even though the DPMI spec
; says it should fail. It doesn't fail in Win 95 either...
;
		test	al, 10h			; S=1?
		jz	dpmi_exitcarry

		push	DWORD PTR [bx + si]
		push	DWORD PTR [bx + si + 4]
		mov	cx, 1
		mov	bx, 8*282
		call	dpmi_check_gdt
		pop	eax
		and	ah, 0F0h		; modify type to data r/w
		or	ah, 2
		pop	DWORD PTR [bx + OFFSET dosx_gdt]
		mov	[bx + OFFSET dosx_gdt+4], eax
;
; V 0.94: it's always a good idea to give the selector back to the caller
;
		mov	_ax[bp], bx
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 000Bh		GET DESCRIPTOR
; BX = LDT selector
; ES:(E)DI ^8 BYTE buffer (type of es descriptor!)
; RET CF clear, buffer filled
; (1.0 reloads segregs)
;------------------------------------------------------------------------------

int31000B:
;
; if gdt.282 < selector < gdt.511 return gdt.selector in ES:EDI
;
		mov	bx, _bx[bp]
		call	dpmi_index_gdt
		test	BYTE PTR [bx+si+6], 10h
		jz	dpmi_exitcarry

		add	si, bx
		movzx	esi, si
		mov	edi, _edi[bp]
		movs	DWORD PTR es:[edi], ds:[esi]
		movs	DWORD PTR es:[edi], ds:[esi]
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 000Ch		SET DESCRIPTOR
; BX = LDT selector
; ES:(E)DI ^8 BYTE buffer (type of es descriptor!)
; RET CF clear, descriptor set
; (1.0 reloads segregs)
;------------------------------------------------------------------------------
int31000C:
;
; if selector > gdt.282 < gdt.511 get gdt.selector from ES:EDI
;
		mov	bx, _bx[bp]
		call	dpmi_index_gdt
		test	BYTE PTR [bx + si + 6], 10h
		jz	dpmi_exitcarry

		mov	edi, _edi[bp]
		mov	eax, DWORD PTR es:[edi]
		mov	DWORD PTR [bx + si], eax
		mov	eax, DWORD PTR es:[edi + 4]
		or	eax, 100000h			; set in use bit
		mov	DWORD PTR [bx + si + 4], eax
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 000Dh		ALLOC SPECIFIC DESCRIPTOR
; BX = LDT selector
; RET CF clear
; (0004 - 007C)
; free with 0001
;------------------------------------------------------------------------------

; - not supported, return (carry), we have no LDT!

;------------------------------------------------------------------------------
;AX = 0100h		DOS - ALLOC
;  BX = # paras
;  RET cf clear : AX = realmode seg /DX = first selector if called from 16bit
;      cf set   : BX = # paras free /AX = DOS ERROR CODE (21/59)
;  never modify!
;------------------------------------------------------------------------------

int310100:
;
; issue int21- call, on success: create selectors
; check gdt for free descriptors to allocate + allocate
; calc how many selectors we would need
;
		mov	_ax[bp], 1Fh
;
; ...who is this damn "General Failure" and why is he reading MY harddisk?
;
		movzx	ecx, _bx[bp]
		add	ecx, 0fffh
		shr	ecx, 12
		jz	dpmi_exitcarry		; don't allocate 0 BYTE!

		mov	bx, 282*8
		call	dpmi_check_gdt
;
; - 0.94 call the old handler to avoid infinite recursion --
;
		push	bx
		pushfd
		mov	ah, 48h
		mov	bx, _bx[bp]
		call	PWORD PTR cs:[OFFSET dosx_old21_ofs]
		jnc	SHORT dpmi_dosmem_ok

		mov	_ax[bp], ax
		mov	_bx[bp], bx
;
; deallocate gdt descriptors
;
		pop	bx

dpmi_stupid_deallocation_loop_resulting_from_bad_program_design:
		mov	BYTE PTR [bx+ OFFSET dosx_gdt+6], 0
		add	bx, 8
loop	SHORT dpmi_stupid_deallocation_loop_resulting_from_bad_program_design

		jmp	dpmi_exitcarry

dpmi_dosmem_ok:
		mov	_ax[bp], ax			; store base

dpmi_from_310102:
		pop	bx
		mov	_dx[bp], bx			; store first selector
;
; cx=descriptor count
; Set base
;
		mov	edx, 500000h+9200h/16		; B- bit doesn't hurt
		shld	dx, ax, 4
		shl	eax, 20
;
; get number of paras
;
		mov	si, _bx[bp]
		mov	ax, -1
		push	cx

dpmi_setgdtloop2:
		sub	si, 1000h
		jnc	SHORT dpmi_sgdtl_limit64k	; limit < 64k?
		lea	ax, [si+1000h]			; adjust limit
		shl	ax, 4
		dec	ax

dpmi_sgdtl_limit64k:
		mov	[bx + OFFSET dosx_gdt], eax
		mov	[bx + OFFSET dosx_gdt + 4], edx
		add	bx, 8				; next selector
		inc	dl				; base=base+64k
		loop	SHORT dpmi_setgdtloop2

		pop	cx
		dec	cx
;
; Adjust limit of first descriptor to the overall limit
;
		mov	bx, _dx[bp]			; get first selector
		mov	[bx + OFFSET dosx_gdt], ax	; store limit low
		or	[bx + OFFSET dosx_gdt+6], cl	; store limit high
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0101h		FREE DOS MEM
;  DX = SELECTOR
;  RET cf clear
;      cf set   : AX = DOS ERROR CODE (21/59)
;  descriptors freed (1.0 zeros segregs)
;------------------------------------------------------------------------------

int310101:
;
; get segment(bx), switch to realmode, load segment into es, call int21/49
; back to pm, on success: free selectors calculated according to the limit
; field of bx
;
		push	_ax[bp]
		mov	_ax[bp], 1fh		; default error
		mov	bx, _dx[bp]
		call	dpmi_index_gdt
		test	BYTE PTR [bx + si + 6], 10h
		jz	dpmi_exitcarry

		pop	_ax[bp]
;
; get base
;
		mov	ecx, [bx + si + 2]
		shr	ecx, 4
;
; switch to realmode
;
		call	WORD PTR [dosx_raw2rm]
		mov	es, cx
		mov	ah, 49h
		int	21h
		pushf
		push	ax
;
; back to pm
;
		call	WORD PTR [dosx_raw2pm]
		pop	ax
		popf
		jnc	SHORT dpmi_freeselec

		mov	_al[bp], al
		jmp	dpmi_exitcarry

dpmi_freeselec:
		mov	cl, [bx+si+6]
		and	cx, 0fh
		inc	cx
;
; cx = #descriptors to be freed
;
dpmi_freedescriptorloop:
		mov	BYTE PTR [bx+si+6], 0
		add	si, 8
		loop	SHORT dpmi_freedescriptorloop

		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0102h		MODIFY DOS MEM
;  DX = SELECTOR, BX = NEW SIZE
;  RET cf clear
;      cf set   : AX = DOS ERROR CODE (21/59) BX = MAXSIZE
;  descriptors maybe freed (1.0 zeros segregs)
;  increase will fail while next descriptor in use
;------------------------------------------------------------------------------
int310102:
;
; if increase check for descriptors
; get segment(dx), switch to realmode, load segment into es, call int21/4ah
; back to pm, on success: create/free selectors and so...
;
		push	_ax[bp]
		mov	_ax[bp], 1Fh
		mov	bx, _dx[bp]
		call	dpmi_index_gdt
		mov	dx, WORD PTR [bx + si + 6]
		test	dl, 10h
		jz	dpmi_exitcarry
;
; check for increase/decrease
;
		and	dx, 0Fh
;
; dx = #of descriptor allocated-1
;
		inc	dx
		mov	cx, _bx[bp]
		add	cx, 0FFFh
		shr	cx, 12			; resize to zero = free
		jz	int310101
;
; cx = #of descriptor needed
;
		push	bx
		push	dx
		push	cx
		sub	cx, dx
		jng	SHORT dpmi_no_new_descriptors
;
; check gdt for cx free descriptors at dx*8
;
		shl	dx, 3
		add	bx, dx

dpmi_checkgdtloop2:
		test	BYTE PTR [bx+si+6], 10h	; already in use?
		jnz	dpmi_exitcarry		; so fail

		add	bx, 8
		loop	SHORT dpmi_checkgdtloop2

dpmi_no_new_descriptors:
;
; note the order we pop dx, cx!
;
		pop	dx
		pop	cx
		pop	bx
		pop	_ax[bp]
		push	bx
;
; get segment
;
		mov	edi, [bx + si + 2]
		shr	edi, 4
;
; switch to realmode
;
		call	WORD PTR [dosx_raw2rm]
		mov	es, di
		mov	ah, 4Ah
		int	21h
		pushf
		push	ax
;
; back to pm
;
		call	WORD PTR [dosx_raw2pm]
		pop	ax
		popf
		jnc	SHORT dpmi_modify_dosmem

		mov	_al[bp], al
		mov	_bx[bp], bx
		jmp	dpmi_exitcarry

dpmi_modify_dosmem:
		cmp	cx, dx
		mov	ax, di
		jng	dpmi_from_310102
;
; free just all descriptors
;
		pop	bx
		push	bx

dpmi_setgdtloop3:
		mov	BYTE PTR [bx + si + 6], 0
		add	bx, 8
		loop	SHORT dpmi_setgdtloop3
;
; just have the base in ax and reuse 310100
;
		jmp	dpmi_from_310102

;------------------------------------------------------------------------------
;AX = 0200h		GET RM IRVEC
;  BL = INTNR
;  RET CF clear  CX:DX seg/ofs
;------------------------------------------------------------------------------
int310200:
;
; if bl not in (8...0fh, 70h..77h) get vector from memory, else get vector
; from oldirq- array
;
		call	dpmi_xam_int
		mov	ax, fs:[bx + si]
		mov	_dx[bp], ax
		mov	ax, fs:[bx + si + 2]
		mov	_cx[bp], ax
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0201h		SET RM IRVEC
;  BL = INTNR
;  CX:DX seg/ofs
;  RET CF clear
;  don't forget to lock all IRQ mem via 0600!
;------------------------------------------------------------------------------
int310201:
;
; if bl not in (8...0fh, 70h..77h) set vector in memory, else set vector
; in oldirq- array
;
		call	dpmi_xam_int
		mov	ax, _dx[bp]
		mov	fs:[bx + si], ax
		mov	ax, _cx[bp]
		mov	fs:[bx + si + 2], ax
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0202h		GET EXCEPTION HANDLER
;  BL = EXC (0..1F)
;  RET CF clear CX:(E)DX SEL/OFS
;------------------------------------------------------------------------------

INT310202:
		movzx	eax, _bl[bp]
		cmp	al, 32
		jnc     dpmi_exitcarry

		mov	edx, [eax * 8 + OFFSET dosx_ehandlers]
		mov	_edx[bp], edx
		mov	dx, [eax * 8 + OFFSET dosx_ehandlers+4]
		mov	_cx[bp], dx
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0203h		SET EXCEPTION HANDLER
;  BL = EXC (0..1F)
;  CX/(E)DX sel/ofs
;  RET CF clear
;  refer to intlist for stackframe /handler does far ret
;------------------------------------------------------------------------------

INT310203:
		movzx	eax, _bl[bp]
		cmp	al, 32
		jnc     dpmi_exitcarry

		mov	edx, _edx[bp]
		mov	[eax * 8 + OFFSET dosx_ehandlers], edx
		mov	dx, _cx[bp]
		mov	[eax * 8 + OFFSET dosx_ehandlers + 4], dx
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0204h		GET INTERRUPT HANDLER
;  BL = INT
;  RET CF clear CX:(E)DX SEL/OFS
;------------------------------------------------------------------------------
INT310204:
		call	dpmi_xam_pmint		; check if irq wanted
		jc	SHORT dpmi_pmget_isirq

		call	dpmi_xam_picmap		; check if in pic shadow
		jc	SHORT dpmi_pmget_shadow
;
; not an irq, not in pic shadow, so address the idt
; 0.94 check whether shadow for exceptions 10-1F
; if so, bx is in the range 80h...0f8h
;
		test	bh, bh
		jnz	SHORT dpmi_pmget_noes

		test	bl, bl
		mov	si, OFFSET dosx_int10to1F - 80h
		js	SHORT dpmi_getpm_ex

dpmi_pmget_noes:
		mov	ax, WORD PTR [bx+OFFSET dosx_idt+2]	; selector
		mov	_cx[bp], ax
		mov	ax, WORD PTR [bx+OFFSET dosx_idt]
		mov	_dx[bp], ax				; OFFSET low
		mov	ax, WORD PTR [bx+OFFSET dosx_idt+6]
		mov	_dx[bp+2], ax				; OFFSET high
		jmp	dpmi_exitok

dpmi_pmget_isirq:
		mov	si, OFFSET dosx_pmirqtab
		jmp	SHORT dpmi_getpm_tab

dpmi_pmget_shadow:
		mov	si, OFFSET dosx_pic1backup

dpmi_getpm_tab:
		shl	bx, 3

dpmi_getpm_ex:
		mov	eax, [bx+si]
		mov	_edx[bp], eax
		mov	ax, [bx+si+4]
		mov	_cx[bp], ax
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0205h		SET INTERRUPT HANDLER
;  BL = INT
;  CX/(E)DX sel/ofs
;  RET CF clear
;  refer to intlist for stackframe /handler does far ret
;------------------------------------------------------------------------------

INT310205:
		call	dpmi_xam_pmint		; check if irq wanted
		jc	SHORT dpmi_pmset_isirq

		call	dpmi_xam_picmap		; check if in pic shadow
		jc	SHORT dpmi_pmset_shadow
;
; not an irq, not in pic shadow, so address the idt
; 0.94 check whether shadow for exceptions 10-1F
; if so, bx is in the range 80h...0f8h
;
		test	bh, bh
		jnz	SHORT dpmi_pmset_noes

		test	bl, bl
		mov	si, OFFSET dosx_int10to1F - 80h
		js	SHORT dpmi_setpm_ex

dpmi_pmset_noes:
		mov	ax, _cx[bp]
		mov	WORD PTR [bx + OFFSET dosx_idt + 2], ax	; selector
		mov	ax, _dx[bp]				; OFFSET low
		mov	WORD PTR [bx + OFFSET dosx_idt], ax
		mov	ax, _dx[bp + 2]			; OFFSET high
		mov	WORD PTR [bx + OFFSET dosx_idt + 6], ax
		jmp	dpmi_exitok

dpmi_pmset_isirq:
		movzx	ebx, bl
		btr	dosx_pmhands, ebx	; reset handler installed bit
		cmp	_cx[bp], 0800h		; check for old handler
		jc	SHORT dpmi_set_oldhandler

		bts	dosx_pmhands, ebx	; set handler installed bit

dpmi_set_oldhandler:
		mov	si, OFFSET dosx_pmirqtab
		jmp	SHORT dpmi_setpm_tab

dpmi_pmset_shadow:
		mov	si, OFFSET dosx_pic1backup

dpmi_setpm_tab:
		shl	bx, 3

dpmi_setpm_ex:
		mov	eax, _edx[bp]
		mov	[bx + si], eax
		mov	cx, _cx[bp]
		mov	[bx + si + 4], cx
		shr	bx, 3
		cmp	bl, 1Ch
		jne	dpmi_exitok

		movzx	ebx, bl
		btr	dosx_pmhands, ebx	; reset handler installed bit
		cmp	cx, 8 + (1Ch * 8)
		je	dpmi_exitok

		bts	dosx_pmhands, ebx	; set handler installed bit
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;  TRANSLATION SERVICES
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;AX = 0300h		SIMULATE RM INTERRUPT
;------------------------------------------------------------------------------
INT310300:

		; check if we are _really_ reentrant

		mov	bl, _bl[bp]
		mov	ax, 200h
		int	31h
		jmp	SHORT dpmi_300

;------------------------------------------------------------------------------
;AX = 0301h		CALL REALMODE PROC / RETF
;------------------------------------------------------------------------------

INT310301:

;------------------------------------------------------------------------------
;AX = 0302h		CALL REALMODE PROC / IRET
;------------------------------------------------------------------------------

INT310302:
		mov	esi, _edi[bp]
		mov	cx, es:[esi._cs]
		mov	dx, es:[esi._ip]

dpmi_300:
		mov	dpmi_rmcall_o, dx
		mov	dpmi_rmcall_s, cx
;
; set up realmode stack
;
		push	ds			; xchg ds, es
		push	es
		pop	ds
		pop	es
		push	ds			; save callers es
		movzx	edi, sp			; default = DPMISTACK
		sub	di, 6			; make sure we're free
;
; at this point we had to check for user stack.
; we avoid alot of trouble by using an internal stack no matter of ss:sp
; in caller struc
;
		mov	dx, ds			; caller struc selector
		std
;
; copy a couple of wordss from caller stack
;
		movzx	ecx, _cx[bp]
		mov	esi, _oldesp[bp]
;
; skip iretd frame+4 selectors pushed, address to - down
;
		lea	esi, [esi+ecx*2 +12 +8]
		mov	ds, _oldss[bp]
		rep	movs WORD PTR es:[edi], ds:[esi]
		mov	esi, _edi[bp]		; get call struc address
		mov	ds, dx
;
; if not ax=0301 store flags
;
		cmp	_al[bp], 1
		jz	SHORT dpmi_isfarcall

		mov	ax, ds:[esi._flags]
;
; mask some off
;
		and	ah, 0Ch
		stosw					; on stack

dpmi_isfarcall:
;
; prepare popad, pop segreg
;
		add	esi, 26h				; fs in caller struc
		movs	DWORD PTR es:[edi], ds:[esi]	; gs, fs
		movs	DWORD PTR es:[edi], ds:[esi]	; ds, es
		sub	esi, 2				; ignore flags so far
		mov	cl, 8
;
; move general registers
;
		rep	movs DWORD PTR es:[edi], ds:[esi]
;
; adjust stack
;
		add	di, 4
		mov	sp, di
		push	ax		; fire off flags
;
; switch to realmode
; look at the trouble we've gone through to get it looking _that_ nice, 
; ooooh, doesn't this look nice? (would look even better if it really works :)
; so, here we go:
;
;------------------------------------------------------------------------------
; REALMODE FARCALL:
;------------------------------------------------------------------------------

		call	WORD PTR cs:[OFFSET dosx_raw2rm]

		popf
		popad
		pop	es
		pop	ds
		pop	fs
		pop	gs

		db	09ah
dpmi_rmcall_o	dw	?
dpmi_rmcall_s	dw	?

		push	gs
		push	fs
		push	ds
		push	es
		pushad
		pushf

		call	WORD PTR cs:[OFFSET dosx_raw2pm]

;"...DAMN, I'M LOOKING GOOD!" (D.NUKEM)

;------------------------------------------------------------------------------
; REALMODE FARCALL DONE
;------------------------------------------------------------------------------
;
; now it's time to cleanup
;
		cld			; copying upwards
		movzx	esi, sp
		mov	edx, esi
;
; Q: "where's the caller's es ?"
; A: "hmm, long story...!"
;
; on stack there were:	old ss		 2
;			old esp		 4
;			pushad		32
;			push es		 2
; ------------------------------------------
; sum (bytes)				40
;
		mov	bp, dosx_lastintstack
		sub	bp, 38
		mov	sp, bp
		sub	sp, 2
		pop	es
		add	si, 2		; ignore flags
;
; copy general registers
;
		mov	ecx, 8
		mov	edi, _edi[bp]
		rep	movs DWORD PTR es:[edi], ds:[esi]
;
; restore flags
;
		mov	ax, ds:[edx]
		and	ah, 0Ch
		and	WORD PTR es:[edi], 0F000h
		or	WORD PTR es:[edi], ax
		add	edi, 2
;
; copy segment registers
;
		movs DWORD PTR es:[edi], ds:[esi]
		movs DWORD PTR es:[edi], ds:[esi]
;
; copy stack parameters
;
		mov	cx, _cx[bp]
		mov	edi, _oldesp[bp]
		add	edi, 20
		mov	dx, es
		mov	es, _oldss[bp]
		rep	movs WORD PTR es:[edi], ds:[esi]
		mov	es, dx
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0303h		ALLOCATE REALMODE CALLBACK
;------------------------------------------------------------------------------

INT310303:
		; find free callback address

		mov	si, OFFSET dosx_callback_entry+3
		mov	cx, 16

dpmi_findcallback:
		cmp	BYTE PTR [si], 0
		jz	SHORT dpmi_callbackfound

		add	si, 4
		loop	SHORT dpmi_findcallback
		jmp	dpmi_exitcarry

dpmi_callbackfound:
		mov	BYTE PTR [si], 1
		sub	si, 3
		mov	_dx[bp], si
		sub	si, OFFSET dosx_callback_entry
		mov	ax, dosx_patch1
		mov	_cx[bp], ax
		add	si, si
		mov	eax, _esi[bp]
		mov	ebx, _edi[bp]
		mov	DWORD PTR [si+OFFSET dosx_callback_procs], eax
		mov	DWORD PTR [si+OFFSET dosx_callback_strucs], ebx
		mov	WORD PTR [si+4+OFFSET dosx_callback_procs], fs
		mov	WORD PTR [si+4+OFFSET dosx_callback_strucs], es
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0304h		FREE REALMODE CALLBACK
;------------------------------------------------------------------------------

INT310304:
;
; 2do: error checking in case the user has a terroristic mentality
;
		mov	si, _dx[bp]
		mov	BYTE PTR [si + 3], 0
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0400h		GET VERSION
;
;  RET CF clear
;  AX = MAJOR/MINOR VERSION
;  BX = FLAGS
;  CL = CPU
;  DH = MASTER PIC
;  DL = SLAVE PIC
;------------------------------------------------------------------------------

INT310400:
;
; stupid moves
;
		mov	_ax[bp], 9
		mov	_bx[bp], 1
		test	dosx_mode, vcpi_used
		jnz	SHORT dpmi_reflect_v86

		mov	_bl[bp], 3

dpmi_reflect_v86:
		mov	al, dosx_cpu_type
		mov	_cl[bp], al
		mov	ah, dosx_pic1map
		mov	al, dosx_pic2map
		mov	_dx[bp], ax
		jmp	dpmi_exitok

; ############################################################################
;
; memory management:
; a block handle is an index in mcb- array
; the mcb-table'first entry is linear start, the second entry contains
; the end address (linear) +1 of that block
; so we can handle resizing / releasing of blocks to some extend
; translation structure handle - OFFSET in mcb
;
;
; Oviously not the high- tech way to sort a small table, but small size and
; it took me 4 minutes to type in :)
;
dpmi_bsort	PROC

dpmi_bsort_start:
		sub	dx, dx
		mov	cx, MAX_MEM_HANDLES
		mov	di, dosx_free_mcbs
		sub	cx, di
		jz	@@bsortDone
;
; We include one more block into the sort if di ! = 0 
;
		shl	di, 3
		lea	di, [di + OFFSET dosx_mcb - 8]
		jnz	dpmi_bsort_loop
		
		add	di, 8
		dec	cx

dpmi_bsort_loop:
		mov	eax, [di]
		cmp	eax, [di + 8]
		jna	SHORT dpmi_bsort_noxchg

		xchg	eax, [di + 8]
		mov	[di], eax
		mov	eax, [di + 4]
		xchg	[di + 12], eax
		mov	[di + 4], eax
		inc	dx

dpmi_bsort_noxchg:
		add	di, 8
		loop	SHORT dpmi_bsort_loop

		test	dx, dx
		jnz	SHORT dpmi_bsort_start

@@bsortDone:
		ret
dpmi_bsort	ENDP

dpmi_getblock	PROC
;
; ebx = blocksize (bytes)
; returns: linear base of block in edx or carry
; 0.93 force DWORD aligment
;
		add	ebx, 3
		and	bl, 0FCh
		mov	di, OFFSET dosx_mcb
		mov	edx, 400000h	;suggested start address
		mov	cx, MAX_MEM_HANDLES

dpmi_findblockloop:
		mov	eax, [di]
		test	eax, eax		;skip unused entries
		jz	SHORT dpmi_ignore_mcb

dpmi_check_edx:
;
; check if there there is room below that block
;
		sub	eax, ebx
		jc	SHORT dpmi_adjust_edx

		cmp	eax, edx
		jnc	SHORT dpmi_checkmemmax

dpmi_adjust_edx:
;
; if not, base address >= address of this block
;
		mov	edx, [di + 4]

dpmi_ignore_mcb:
		add	di, 8
		loop	dpmi_findblockloop

dpmi_checkmemmax:
		mov	eax, dosx_memavail
		shl	eax, 12
		add	eax, 400000h	; add start of user mem
		sub	eax, ebx		; sub desired size
		jc	SHORT dpmi_gp_end

		cmp	eax, edx		; must be >=min possible start address

dpmi_gp_end:
		ret
dpmi_getblock	ENDP

dpmi_findblock PROC NEAR
;
; In:  EAX = block start
; Out: EDI = block # or CF set on error
;
		mov	edi, MAX_MEM_HANDLES

@@fbLoop:
		sub	di, 1
		jc	@@fbError

		cmp	DWORD PTR [edi * 8 + OFFSET dosx_mcb], eax
		jc	@@fbError

		jne	@@fbLoop

@@fbError:
		ret
dpmi_findblock ENDP

; ############################################################################

;------------------------------------------------------------------------------
;AX = 0500h		GET FREE MEMORY (ADVISORY)
;------------------------------------------------------------------------------

INT310500:
;
; "zero-1" out the buffer
;
		mov	eax, -1
		mov	ecx, 12
		mov	edi, _edi[bp]
		rep	stos DWORD PTR es:[edi]
		mov	edi, _edi[bp]
;
; sum up used memory ( all new in 0.93 )
;
		sub	edx, edx
		mov	bx, OFFSET dosx_mcb

dosx093_fix31500_0:
		mov	eax, [bx]
		test	eax, eax
		jz	SHORT dosx093_fix31500_1

		sub	eax, [bx + 4]
		add	edx, eax

dosx093_fix31500_1:
		add	bx, 8
		cmp	bx, OFFSET dosx_mcb + ((MAX_MEM_HANDLES - 1) * 8)
		jna	SHORT dosx093_fix31500_0

		mov	eax, dosx_memavail
		mov	es:[edi + 18h], eax
		shl	eax, 12
		add	edx, eax
		mov	es:[edi], edx
		shr	edx, 12
		mov	es:[edi + 4], edx
		mov	es:[edi + 8], edx
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0501h		ALLOC MEMORY BLOCK
;  BX:CX = LINEAR SIZE
;RETURNS
;  BX:CX = LINEAR START
;  SI:DI = MEMORY BLOCK HANDLE  
;------------------------------------------------------------------------------

INT310501:
		cmp	dosx_free_mcbs, 0
		je	dpmi_exitcarry

		mov	ebx, DWORD PTR _bx[bp - 2] ; get high WORD of linear size
		mov	bx, _cx[bp]		   ; get low WORD
		call	dpmi_getblock
		jc	dpmi_exitcarry

		dec	dosx_free_mcbs
		movzx	ecx, dosx_free_mcbs
;
; store mcb
;
dpmi_from_310503:
		mov	[ecx * 8 + OFFSET dosx_mcb], edx
		add	ebx, edx
		mov	[ecx * 8 + OFFSET dosx_mcb + 4], ebx
		mov	_cx[bp], dx
		mov	_di[bp], dx
		ror	edx, 16
		mov	_bx[bp], dx
		mov	_si[bp], dx
		call	dpmi_bsort
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0502h		FREE MEMORY BLOCK
;  SI:DI = MEMORY BLOCK HANDLE  
;RETURNS
; CF cler/set
;------------------------------------------------------------------------------

INT310502:
		mov	eax, _esi[bp-2]
		mov	ax, _di[bp]
		call	dpmi_findblock
		jc	dpmi_exitcarry
;
; edi = mcb #
;
		mov	DWORD PTR [edi * 8 + OFFSET dosx_mcb], 0
		call	dpmi_bsort
		inc	dosx_free_mcbs
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0503h		RESIZE MEMORY BLOCK
;  BX:CX = LINEAR SIZE
;  SI:DI = MEMORY BLOCK HANDLE  
;RETURNS
;  BX:CX = LINEAR START
;  SI:DI = MEMORY BLOCK HANDLE  
;------------------------------------------------------------------------------

INT310503:
		mov	eax, _esi[bp-2]
		mov	ax, _di[bp]
		call	dpmi_findblock
		jc	dpmi_exitcarry

		mov	ebx, DWORD PTR _bx[bp-2] ; get high WORD of linear size
		mov	bx, _cx[bp]	         ; get low WORD
;
; 0.93 force alignment to DWORD
;
		add	ebx, 03
		and	bl, 0FCh
		mov	eax, [edi * 8 + OFFSET dosx_mcb]
		mov	edx, eax
;
; ebx = new size rEQUested
; eax = old start address of block
; edi = #mcb (0..MAX_MEM_HANDLES-1)
;
		add	eax, ebx
;
; eax = desired new end address
;
		sub	eax, [edi * 8 + OFFSET dosx_mcb + 4]
		jbe	dpmi_shrink
;
; eax = size difference
; now try to resize the block + EAX bytes
;
		mov	edx, 400000h
;
; 1. special case: first block?
;
		test	di, di
		jz	SHORT dpmi_firstblock

		cmp	DWORD PTR [edi * 8 + OFFSET dosx_mcb - 8], 0
		jz	SHORT dpmi_firstblock
;
; nope, get end address from previous block
;
		mov	edx, [edi * 8 + OFFSET dosx_mcb - 4]
		
dpmi_firstblock:
;
; edx = start of block to resize
; eax = size difference
;
		mov	ecx, dosx_memavail
		shl	ecx, 12
		add	ecx, 400000h
;
; ecx = maximum possible end address
; 2. special case: last block?
;
		cmp	di, MAX_MEM_HANDLES - 1
		jz	SHORT dpmi_lastblock

		mov	ecx, [edi * 8 + OFFSET dosx_mcb + 8]

dpmi_lastblock:
;
; the hole is now the range from edx up to ecx
; temporary fix (0.93)
;
		push	ebx
		mov	ebx, [edi*8 + OFFSET dosx_mcb + 4]
		add	ebx, eax
		cmp	ebx, ecx
		pop	ebx
		ja	SHORT dpmi_moveblock
;
; now we know that the block fits into the hole
; check if start adresses are the same
;
		cmp	edx, [edi * 8 + OFFSET dosx_mcb]
		jz	SHORT dpmi_shrink	;just update end
;
; else do a memcopy
;
dpmi_from_below:
;
; get old start
;
		sub	esi, esi
		xchg	esi, [edi*8 + OFFSET dosx_mcb]
;
; get old size
;
		mov	ecx, [edi*8 + OFFSET dosx_mcb+4]
		sub	ecx, esi
;
; get target
;
		push	edi
		mov	edi, edx
		push	ds
		push	dosx_sel_data0
		pop	ds
		push	ds
		pop	es
		rep	movs BYTE PTR es:[edi], ds:[esi]
		pop	ds
		pop	ecx
;
; Pass info back
;
		jmp	dpmi_from_310503

dpmi_moveblock:
;
; here we go if the block did not fit into its old "hole"
;
		push	edi
		call	dpmi_getblock
;
; new block address in edx
;
		pop	edi
		jc	dpmi_exitcarry

		jmp	SHORT dpmi_from_below

dpmi_shrink:
;
; trivial case edx=linear start
;
		add	[edi*8+OFFSET dosx_mcb+4], eax
		mov	_cx[bp], dx
		shr	edx, 16
		mov	_bx[bp], dx
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0604h		GET PAGE SIZE
;RETURNS
;  BX:CX = SIZE IN bytes
;------------------------------------------------------------------------------

INT310604:
		mov	_cx[bp], 4096
		mov	_bx[bp], 0
		jmp	dpmi_exitok

;------------------------------------------------------------------------------
;AX = 0800h		MAP PHYSICAL REGION
;  BX:CX = PHYSICAL OFFST
;  SI:DI = SIZE
;RETURNS
;  BX:CX = LINEAR ADRESS
;------------------------------------------------------------------------------

INT310800:
;
; major change in 0.94 final: reserve the entire linear memory space between
; 2Gb and 3Gb as potential candidate for physical adress mappings
; during initialization, this part of the page directory is set up as if the
; entire first megaBYTE was filled up with page tables. Furthermore, the
; HIGH 16 bits of the corresponding entry in the first page table contain
; the segment we obtained from DOS while allocating space for the page tables.
;
		movzx	ebx, _cx[bp]			; get lower 16 bits
		and	bh, 0Fh				; mask off don't care
		mov	ax, _si[bp]
		shl	eax, 16
		mov	ax, _di[bp]			; EAX = size
		lea	ebx, [eax + ebx + 0FFFh]
		shr	ebx, 12				; EBX = number of pages
		jnz	SHORT dpmi_310800_0

		inc	bx

dpmi_310800_0:
;
; EBX now contains the needed DOS memory in DWORDS. Since we can only store
; 256 different segment adresses, we must make sure that we allocate at least
; 4k page table memory.
;
		push	ebx
		shr	ebx, 2				; DWORD to paragraphs
		test	bh, bh
		jnz	SHORT dpmi_310800_1

		mov	bx, 100h			; allocate 4k

dpmi_310800_1:
		mov	ah, 48h
		pushfd
		call	PWORD PTR cs:[OFFSET dosx_old21_ofs]
		pop	ebx
		jc	dpmi_exitcarry
;
; the linear address to return is 2GB + AH * 4Mb + AL * 16k + lower 12 bits
; of physical base (or AX shl 14 + 2GB + lower 12 bits for that matter)
;
		push	dosx_sel_data0
		pop	es
		movzx	esi, ah
		mov	edi, dosx_cr3_base
;
; now that we've got our index, store real mode segment
;
		mov	es:[edi + esi * 4 + 4096 + 2048 + 2], ax
;
; fill the page table(s) accordingly
;
		movzx	eax, ax
		mov	cx, _bx[bp]
		shl	ecx, 16
		mov	cx, _cx[bp]
		and	cx, 0f000h
		shl	ebx, 12
		lea	ecx, [ebx + ecx + 1fh - 1000h]
		shr	ebx, 12
		shl	eax, 4

dpmi_310800_2:
		mov	es:[eax + ebx * 4 - 4], ecx
		sub	ecx, 1000h
		dec	ebx
		jnz	SHORT dpmi_310800_2

		shl	eax, 10
		and	_cx[bp], 0fffh			; isolate odd bits
		or	_cx[bp], ax			; bits 15 and 14
		shr	eax, 16
		or	ah, 80h				; start at 2Gb
		mov	_bx[bp], ax
		jmp	dpmi_exitok


;------------------------------------------------------------------------------
;AX = 0801h		UNMAP PHYSICAL REGION
;  BX:CX = LINEAR ADDRESS
;RETURNS
;  CF ON ERROR, AX = 8025h
;------------------------------------------------------------------------------

INT310801:
		movzx	eax, _bx[bp]
		and	ah, 03fh
		shr	eax, 6
		push	dosx_sel_data0
		pop	es
		mov	edi, dosx_cr3_base
		mov	si, es:[edi + eax * 4 + 4096 + 2048 + 2]
		test	si, si
		jz	SHORT dpmi31801f

		mov	WORD PTR es:[edi + eax * 4 + 4096 + 2048 + 2], 0
		call	WORD PTR [dosx_raw2rm]
		mov	es, si
		mov	ah, 49h
		int	21h
		pushf
		call	WORD PTR [dosx_raw2pm]
		popf
		jnc	dpmi_exitok

dpmi31801f:
		mov	_ax[bp], 8025h
;		jmp	dpmi_exitcarry
; DON'T FORGET TO PUT THAT IN AGAIN IF SOMETHING COMES INBETWEEN!
; ############################################################################

dpmi_exitcarry:
		mov	sp, bp
		popad
;
; release int stack
;
		sub	ds:dosx_lastintstack, dosx_intstacksize
		pop	ds:dosx_isr_esp
;
; restore stack
;
		pop	ss
		mov	esp, ds:dosx_isr_esp
;
; restore selectors
;
		pop	gs
		pop	ds
		pop	fs
		pop	es
		or	BYTE PTR [esp+8], 1
		iretd

dpmi_exitok:
		mov     sp, bp
		popad
		pop     ds:dosx_isr_esp
;
; DJGPP: Check stack for validity, otherwise we'd end up with a triple fault.
;
		push	eax
		mov	ax, [esp + 4]
		lsl	eax, eax
		cmp	eax, ds:dosx_isr_esp
		ja	int31StackValid
;
; Something has messed with the stack somewhere. Whoever did that
; would probably want to fix this in their stack fault handler (DJGPP)
;
		pop	ds:dosx_exc_eax
		pop	ax
		push	eax
		push	ds:dosx_isr_esp
		pushfd
		db	66h
		push	cs
		db	66h
		push	OFFSET int31FaultLoc
		mov	eax, 12		 ; stack fault
		mov	ds:dosx_exc_ds, ds
		jmp	dosx_simulate_exc

int31StackValid:
;
; restore stack
;
		pop	eax
		pop	ss
		mov	esp, ds:dosx_isr_esp
;
; release int stack
;
		sub	ds:dosx_lastintstack, dosx_intstacksize
;
; restore selectors
;
int31FaultLoc:
		pop	gs
		pop	ds
		pop	fs
		pop	es
		and	BYTE PTR [esp + 8], 0FEh
		iretd


; ############################################################################
; ##                       Initialized global data                          ##
; ############################################################################

align			DWORD
dosx_lastintstack	dw	OFFSET dosx_intstacks
dosx_free_mcbs		dw	MAX_MEM_HANDLES
dosx_pmhands		dd	0
dosx_pagecount		dd	0	; total pages allocated > 1MB
dosx_memavail		dd	0	; pages available at init
dosx_E801size		dd	0	; above 16MB in pages
dosx_E801start		dd	1000000h
; dosx_api_flag		db	0	; 1 = DOS/4G - mode

dosx_exc_string	db	0dh, 0ah, 'Hi, I', 39, 'm exception %4 at %4:%8 !'
		db	0dh, 0ah, 'EAX=%8 EBX=%8 ECX=%8 EDX=%8'
		db	0dh, 0ah, 'ESI=%8 EDI=%8 EBP=%8 ESP=%8'
		db	0dh, 0ah, 'EFLAGS=%8 ERRORCODE=%8 (may be rubbish)'
		db	0dh, 0ah, 'SS=%4 DS=%4 ES=%4 FS=%4 GS=%4'
		db	0dh, 0ah, 0

	trm EQU 0Dh, 0Ah, '$'

dosx_msg_nomode		db	'V86 but no DPMI/VCPI!', trm
dosx_msg_noextmem	db	'Insufficient extended memory!', trm
dosx_msg_wrongcpu	db	'Need 386+ CPU!', trm
dosx_msg_envbad		db	'Bad program environment!', trm
;dosx_msg_dpmi16		db	'DPMI error: host not 32 bit!', trm
dosx_msg_nomem		db	'Insufficient DOS- memory!', trm
dosx_msg_openerr	db	'Error loading 32 bit overlay!', trm
dosx_msg_dpmierr	db	'DPMI mode switch error!', trm
dosx_msg_nointstacks	db	'Out of interrupt stacks!', trm
dosx_msg_a20		db	'A20 error!', trm
dosx_msg_dpmi		db	'INT 31 error!', trm
IFDEF __WATCOM__

;#############################################################################

dosx_lestruc_start	LABEL	BYTE
include loadle.inc
dosx_lestruc_end	LABEL	BYTE

;#############################################################################

ENDIF

align	DWORD
dosx_endsegment		LABEL	NEAR

;---------------------- uninitialized data ------------------------------------

variables		LABEL	NEAR
;
; Wfse cacheing status
;
wfse_current_handle	dw	?
wfse_current_decomp	dw	?
wfse_current_block	dd	?
wfse_current_last	dd	?
wfse_current_dir_offset	dd	?
wfse_current_raw_offset	dd	?

dosx_linear_start	dd	?
dosx_intvectors		dd	256 dup (?)
dosx_idt		dq	256 dup (?)
dosx_gdt		dq	512 dup (?)
dosx_pic1backup		dq	8   dup (?)
dosx_pic2backup		dq	8   dup (?)
dosx_himem		dd	?
dosx_v86struc		dd	?
;VCPI modeswitch struc
dosx_cr3_base		dd	?
dosx_gdtr_linear	dd	?
dosx_idtr_linear	dd	?

dosx_ldt_dummy		dw	?
dosx_tr_dummy		dw	?

dosx_pm_offset		dd	?

dosx_pm_selector	dw	?
			dw	?	; I'm here for alignment
;end modeswitch struc
dosx_switch_ss		dw	?
			dw	?

dosx_esp_new		dd	?
dosx_switch_esp		dd	?
dosx_r2p_int		dd	?
dosx_dpmi		dd	?

dosx_gdtr		LABEL	PWORD
dosx_gdt_limit		dw	?
dosx_gdt_base		dd	?

dosx_idtr		LABEL	PWORD
dosx_idt_limit		dw	?
dosx_idt_base		dd	?

dosx_isr_esp		dd	?
dosx_rm_idt		dp	?
dosx_rm_gdt		dp	?

dosx_envseg		dw	?
dosx_raw2rm		dw	?

dosx_raw2pm		dw	?
dosx_isr_ss		dw	?

dosx_xmshandle		dw	?
			dw	?		; padding
dosx_xmssize		dd	?

dosx_extsize		dw	?
dosx_fhandle		dw	?

dosx_pspseg		dw	?
dosx_tableblock		dw	?

dosx_cpu_type		db	?
dosx_mode		db	?
dosx_pic1map		db	?
dosx_pic2map		db	?

dosx_oldirqs		LABEL	DWORD
			dd	16 dup (?)	;16 IRQ

;
; Note: These must remain in that order!
;
dosx_pmirqtab		LABEL	QWORD
			dq	16 dup (?)	;16 IRQ
dosx_int10to1F		dq	16 dup (?)	;INT Redirector from IDT (0.94)
;
; Resulting "IRQ" assignment for INT 1Ch passup = IRQ 1Ch
;
; End of "these must remain in that order"
;
dosx_ehandlers		dq	32 dup (?)	;16 Exception handlers (V0.93)
						;32 Exception handlers (V0.94)
dosx_dummytss		db	104 dup (?)
dosx_int31struc		db	dosx_int31strucsize dup (?)
dosx_int33struc		db	dosx_int31strucsize dup (?)
dosx_mouse_proc		dq	?
dosx_mouse_rmcallback_seg	dw	?
dosx_mouse_rmcallback_ofs	dw	?

dosx_callback_procs	dq	16 dup (?)
dosx_callback_strucs	dq	16 dup (?)
dpmi_cb_addx		dd	16 dup (?)
dpmi_cb_dest		dq	16 + 8 dup (?)

dosx_callback_sstemp	dw	?
dosx_callback_sptemp	dw	?
dosx_callback_cstemp	dw	?
dosx_callback_iptemp	dw	?
dosx_callback_fltemp	dw	?
dosx_callback_idtemp	dw	?

dosx_mouse_bitmap	dw	32 dup (?)

dosx_mcb		dd	MAX_MEM_HANDLES*2 dup (?)

;flat segment maintainance
dosx_api_return_flags	dd	?
dosx_api_return_esp	dd	?
dosx_flat_handle	dd	?

dosx_dta_offset		dd	?
dosx_dta_selector	dw	?
			dw	?	; filler

dosx_flat_sel_data	dw	?
dosx_flat_sel_code	dw	?
dosx_flat_sel_data16	dw	?
dosx_pspsel		dw	?
dosx_flat_sel_dos	dw	?
dosx_flat_seg_dos	dw	?

dosx_dta		db	80h dup (?)
; dpmi_xref		db	MAX_MEM_HANDLES dup (?)
WfseFcbs		db	MAX_WFSE_FCBS*SIZE_OF_FCB dup (?)
dosx_intstacks		LABEL	NEAR
			dw	16 * dosx_intstacksize/2 dup (?)
dosx_stack		LABEL	NEAR
dosx_stackbegin		db	stacksize dup (?)
align	DWORD
dosx_top_of_memory	LABEL	NEAR
code16		ends
end		start
