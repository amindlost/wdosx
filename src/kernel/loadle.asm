; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 2005, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/KERNEL/loadle.asm 1.9 2004/01/05 17:43:12 MikeT Exp MikeT $
;
; ----------------------------------------------------------------------------
;
; $Log: loadle.asm $
; Revision 1.9  2004/01/05 17:43:12  MikeT
; Add workaround foir Open Watcom.
;
; Revision 1.8  1999/07/10 14:23:21  MikeT
; Corrected version 1.6 this time everything looks o.k.
;
; Revision 1.7  1999/06/20 19:15:52  MikeT
; Backed out last revision. DOOM.EXE page faults and we need to sort out that
; one first... :-(
;
; Revision 1.6  1999/06/20 19:08:42  MikeT
; This revision has been supplied by Oleg Prokhorov:
;
;
; Revision 1.6 OlegPro
; Fixed a lot...
; added support for fixup 3 , 16-bit segments (thanks to Zurenava extender 
; source code), proper handling of zero paged objects, proper loading of 
; pages (we are able to check how much bytes we've loaded), loading of 
; small LE's (which consist of one page), the same fixuping code for both 
; 16-bit and 32-bit targets.
;
; Revision 1.5  1999/02/17 22:14:20  MikeT
; Some adjustments WRT TASM 5.0 stupidity. Notably TASM 5 would ignore
; the fact that in 32 bit mode if we want to store a segment register in
; a word variable, we would need to add an opsize override. Stoopid thang!
; Should equally well assemble with TASM 3.1 and 5.0 now and produce
; identical binary results.
;
; Revision 1.4  1999/02/07 17:38:38  MikeT
; Updated copyright + some cosmetics. No code changes.
;
; Revision 1.3  1998/11/29 16:17:48  MikeT
; Fix object load adresses if zero init objects present. Applied a quick
; and dirty temporary fix to the relocation code to skip the first object
; if the page count for that one was zero. This allows WDOSX to work with
; UPX packed LE executables.
;
; Revision 1.2  1998/10/07 20:02:37  MikeT
; ESP now exactly matches the LE header.
;
; Revision 1.1  1998/08/03 01:59:28  MikeT
; Initial check in
;
;
; ----------------------------------------------------------------------------
; LE executable loader
; this variant is inteded to be converted into a binary
; Entered with the file handle in bx and the file pointer of the excutable
; pointing to the start of the LE image
;
include leheader.inc

.386p
code		segment use32
assume		cs:code,ds:code
segbegin	label	near
org 0
entry_point:
		jmp	start_it_up
align 4

		; globals
org 0

pspsel		dd	?
handle		dd	?
;image2filepos	dd	?
StartOfPayload	dd	?
RelocationBase	dd	?
WatcomCode	dd	?
WatcomData	dd	?

femsg		db	'Error reading executable',0dh,0ah,'$'
fomsg		db	'Wrong executable format',0dh,0ah,'$'
memsg		db	'Not enough extended memory',0dh,0ah,'$'


file_error:	mov	edx,offset femsg
		jmp	short errormsg
format_error:	mov	edx,offset fomsg
		jmp	short errormsg
mem_error:	mov	edx,offset memsg

errormsg:	mov	ah,9
		int	21h
		mov	ax,4cffh
		int	21h

new21		proc	near

		cmp	ah,0ffh
		jnz	short chain21

		cmp	al, 0FDh
		jz	short chain21

		mov	al,ah
		push	0
		pop	gs
		iretd

chain21:
		db	0eah
old21ofs	dd	?
old21seg	dd	?
new21		endp

start_it_up:

;-------------- enable virtual interrupts -------------

		mov	ax,0901h
		int	31h

;-------------- save handle ---------------------------

		push	ebx
		mov	eax, 0FFFDh
		int	21h
		pop	ebx
		jc	notOpenWfse

		cmp	eax, 57465345h		; 'WFSE'
		jne	notOpenWfse

		mov	edx, OFFSET wfseName
		mov	eax, 3D00FFFDh
		int	21h
		jc	notOpenWfse

		mov	ebx, eax

notOpenWfse:
		mov	handle, ebx

;-------------- expand segment a bit ------------------

		mov	ax,-1
		mov	edx,20000h	;128k should be available on any system 
		int	21h
		jc	mem_error
		mov	esp,edx

;-------------- save PSP selector ---------------------

		mov	pspsel,es

;-------------- find LE signature ---------------------

		mov	ecx,16
		mov	edx,offset freemem
		mov	ah,3fh
		call	WfseHandler
		jc	file_error

		cmp	eax, ecx
		jne	file_error		; ecx = 16

findLE:
		cmp	word ptr [edx],'EL'
		jz	short sigfound

		cmp	byte ptr [edx],0
		jnz	format_error

		inc	edx
		loop	findLE
		jmp	format_error
sigfound:
		sub	edx,offset freemem+16
		shld	ecx,edx,16
		mov	ax,4201h
		call	WfseHandler
		jc	file_error

;		mov	word ptr [offset image2filepos],ax
;		mov	word ptr [offset image2filepos+2],dx

;file pointer now at "LE"

;		sub	ebp,ebp

;-------------- Set anchor to start of program mem ---

;		add	ebp, offset freemem+01ffh
		mov	ebp, offset freemem+01ffh
		and	ebp, 0fffffe00h		;align on 512

;-------------- read header --------------------------

		mov	ecx,0b0h
		mov	ah,3Fh
		mov	edx,ebp
		call	WfseHandler
		jc	file_error

		cmp	eax, ecx
		jne	file_error

;		cmp	dword ptr [ebp],'EL'
;		jnz	file_error

;
; Fix Open Watcom issue where the LoaderSize would not encompass the fixup
; section
;
		mov	eax,LEFixupSize[ebp]
		cmp	eax,LELoaderSize[ebp]		;size of loader data
		jc	owfixdone

		add	LELoaderSize[ebp],eax		;size of loader data
		

owfixdone:
;------------- calculate overall mem from LE header ---

;We need pages*pagesize + loadersize + 1024 (temp stack) + offset
;freemem + offset object table as our new segment size the header size is the
;offset of the object table for that matter...
;2do: find a way to reduce the amount of memory needed
		mov	edi,LENumberPages[ebp]
		imul	edi,LEPageSize[ebp]		;the paranoid version
		mov	edx,LEObjectTable[ebp]		;size of LE header
		add	edx,LELoaderSize[ebp]		;size of loader data
		lea	ecx,[edx-0b0h]			; bytes to read
		add	edx,511
		and	edx,0fffffe00h			;align 512
;edx = size of all headers
		mov	StartOfPayload,edx
		add	StartOfPayload,ebp
		mov	RelocationBase,edx
		add	RelocationBase,ebp
		lea	edx,[edx+edi+1024]
		add	edx,ebp
;try to grab the memory (segment may get smaller too, so nothing can be on the
;stack!
		mov	eax,-1
		int	21h
		jc	mem_error
		mov	esp,edx

;------------- load resident header data --------------

		lea	edx,[ebp+0b0h]
		mov	ah,3fh
		call	WfseHandler
		jc	file_error

		cmp	eax, ecx
		jne	file_error

;-------------- get number of pages finally needed -----
		mov	esi,[ebp+40h]
		mov	eax,[ebp+44h]
		sub	edx,edx
                lea     edi, [edx+1]
DetMemLoop:
		mov	ecx,[ebp+esi]

; check if indexing of pages is correct according to object table info.
; If it's correct we can destroy it to store selector value there.
;
                cmp     edi, [ebp+esi][OTPageMapIndex]
                jne     format_error
                add     edi, [ebp+esi][OTPageMapSize]
                mov     [ebp+esi][OTPageMapIndex], 0

		add	esi,24
		add	ecx,4095
		and	ecx,NOT 4095
		add	edx,ecx
		dec	eax
		jnz	DetMemLoop
		add	edx,StartOfPayload
		add	edx,1024
		cmp	edx,esp
		jna	MemSuff
		mov	eax,-1
		int	21h
		jc	mem_error
		mov	esp,edx
MemSuff:

		push	ebx

		mov	bl,21h
		mov	eax,204h
		int	31h
		jc	mem_error
		mov	old21ofs,edx
		mov	old21seg,ecx
		mov	ecx,cs
		mov	edx,offset new21
		mov	eax,205h
		int	31h
		jc	mem_error

; get the segment base address

		mov	eax,6
		mov	ebx,cs
		int	31h

		jc	mem_error
		add	word ptr [offset RelocationBase],dx
		adc	word ptr [offset RelocationBase+2],cx

                ; lock the int 21h handler memory

		mov	ebx,ecx
		mov	ecx,edx
		mov	edi,offset start_it_up
		sub	esi,esi
                mov	eax,600h
                int	31h

                ; error? who cares!

		; get new code segment selector

                mov     dx, 4092h
                xor     ebx, ebx
                mov     ecx, 0FFFFF000h
                call    CreateSelector
		mov	WatcomData,ebx

                mov     dx, 409Ah
                xor     ebx, ebx
                mov     ecx, 0FFFFF000h
                call    CreateSelector
		mov	WatcomCode,ebx

		pop	ebx

;zero out the memory

		push	ds
		pop	es
		mov	edi,StartOfPayload
		lea	ecx,[esp-1024]
		sub	ecx,edi
		shr	ecx,2
		sub	eax,eax
		rep	stosd


; find start of program data
		mov	ecx,LEPageSize[ebp]
                cmp     LENumberPages[ebp], 1
                ja      MoreThanOnePage
                mov     ecx, ebp[LEBytesLastPage]
MoreThanOnePage:
		mov	edx,StartOfPayload

		mov	ah,3fh
		call	WfseHandler
		jc	file_error

		cmp	eax, ecx
		jne	file_error

		mov	edi,edx
		sub	eax,eax
		repe	scasb
		jz	file_error
		not	ecx
		mov	edx,ecx
		shr	ecx,16
		mov	eax,4201h
		call	WfseHandler
		jc	file_error

;really need paranoid size checking?
;file pointer now at program data in file

;------------- start processing Objects --------------

		mov	edi,LEObjectEntries[ebp]
		mov	esi,LEObjectTable[ebp]
		mov	edx,RelocationBase
                mov     ecx, LENumberPages[ebp]
		mov	eax,OTPageMapIndex[ebp+esi]
		shl	eax,2
		add	eax,LEObjectPMTable[ebp]
LoadObject:
		mov	ebx,OTPageMapSize[ebp+esi]

; Use reserved field to store actual object load address

		mov	OTReserved[ebp+esi], edx

		push	edx			; store load address
		test	ebx,ebx
		jz	ebxwaszero

ReadPage:
                push    ecx
                cmp     ecx, 1
                ja      NotLastPage
                mov     ecx, ebp[LEBytesLastPage]
                jmp     CheckPage
NotLastPage:
		mov	ecx, LEPageSize[ebp]
CheckPage:
;check against Object Page Table (load or relocation only)
		
		cmp	byte ptr [eax+ebp+3], 0
		jnz	AfterRead

		push	eax
		push	ebx
		push	ds
		mov	ebx,handle
		mov	ds,WatcomData
		mov	ah,3fh
		call	WfseHandler
		pop	ds

		cmp	eax, ecx
		jne	file_error

		pop	ebx
		pop	eax
		jc	file_error

AfterRead:
		add	edx,ecx
		add	eax,4
                pop     ecx
                dec     ecx
		dec	ebx
		jnz	ReadPage

ebxwaszero:
		pop	edx
		mov	ebx, [ebp + esi]	; get vsize of current section
		add	ebx, 000000FFFh		; align to pages
		and	ebx, 0FFFFF000h
		add	edx, ebx		; Set to start of next object
		add	esi,24
		dec	edi
		jnz	LoadObject

; this I added yet, it's always a good idea to close a file if we don't need
; it anymore:

; If WFSE is present, we don't close the file

                mov     ebx,handle
		test	bh, 80h		
		jz	short skipClose

                mov	ah,3eh
                call	WfseHandler

skipClose:

;-------------- raw data loaded, now do fixups ----

; considering that there are LOTS of fixups, this could take some time
; A decent level of speed optimization doesn't hurt... -> 2DO

		mov	fs,WatcomCode
		mov	gs,WatcomData

		mov	esi,LEObjectTable[ebp]
		mov	edi,LEFixupPageTab[ebp]
		mov	edx,RelocationBase
		mov	ecx,LEFixupRecords[ebp]
		add	ecx,ebp
;
; EAX = ???
; EBX = ???
; ECX -> Fixup records
; [ESI + EBP] -> object table
; [EDI + EBP] -> Fixup page table
;
;Quick and dirty fix for UPX
;
                mov     eax, esi
FixupObject:
  		cmp     OTPageMapSize[ebp+eax], 0
  		je      ZeroPagesObject

		mov	edx, OTReserved[ebp + eax]

FixupPage:
                push    eax
		mov	ebx,[edi+ebp]
		cmp	ebx,[edi+ebp+4]
		jnc	FixupDone

FixupRecord:


; Wlink produces 12h, instead 2h as a fixup type if referenced object is
; 16-bit. Is it possible for other fixup types ?

                and     byte ptr FRType[ebx+ecx], NOT 10h

; sort of an inner loop [ebx+ecx] = start of fixup record

                push    edi
                movzx   edi,FRObject[ecx+ebx]

                cmp     byte ptr FRType[ebx+ecx+1],10h
                jnz     check16bit

                mov     eax,dword ptr FRItem[ecx+ebx]
                jmp     targetselected
check16bit:

                cmp     byte ptr FRType[ebx+ecx+1],0
		jnz	format_error
		movzx	eax,FRItem[ecx+ebx]
targetselected:
                lea     edi,[edi*2+edi-3]
		lea	edi,[edi*8+esi]

		cmp	byte ptr FRType[ebx+ecx],3
		jnz	FuNoFarCall16

                call    CreateSelForObject
                shl     eax, 16
                mov     ax, word ptr [ebx+ecx+5]
		movsx	edi,FROffset[ecx+ebx]		;can be negative!
		push	edx
		sub	edx,RelocationBase
		add	edx,StartOfPayload

                mov	dword ptr [edi+edx], eax

		pop	edx
                jmp     OnlyOfs

FuNoFarCall16:
		cmp	byte ptr FRType[ebx+ecx],2
		jnz	FuNoSel16
                call    CreateSelForObject
		movsx	edi,FROffset[ecx+ebx]		;can be negative!
		push	edx
		sub	edx,RelocationBase
		add	edx,StartOfPayload

		mov	word ptr [edi+edx], ax

                movzx   edi, byte ptr FRType[ebx+ecx+1]
                shr     edi, 3
                add     ebx, edi
                pop     edx
		pop	edi
		add	ebx,5
		cmp	ebx,[edi+ebp+4]
		jc	FixupRecord
		jmp	FixupDone

FuNoSel16:
		cmp	byte ptr FRType[ebx+ecx], 5
                je      DontAddOff32
		add	eax,OTReserved[edi+ebp]
DontAddOff32:
		push	edi
		movsx	edi,FROffset[ecx+ebx]	;can be negative!
		push	edx
		cmp	byte ptr FRType[ebx+ecx],8
		jnz	NoRel16
		sub	eax,edx
		sub	eax,edi
		sub	eax,4
NoRel16:
		sub	edx,RelocationBase
		add	edx,StartOfPayload
		mov	[edi+edx],ax
		cmp	byte ptr FRType[ebx+ecx],5
		jz	Fu16_16
		mov	[edi+edx],eax
Fu16_16:
		pop	edx
		pop	edi
		cmp	byte ptr FRType[ebx+ecx],7
		jz	OnlyOfs
		cmp	byte ptr FRType[ebx+ecx],5
		jz	OnlyOfs
		cmp	byte ptr FRType[ebx+ecx],8
		jz	OnlyOfs
		cmp	byte ptr FRType[ebx+ecx],6
		jnz	format_error

		push	edi
                call    CreateSelForObject
		movsx	edi,FROffset[ecx+ebx]	;can be negative!
		push	edx
		sub	edx,RelocationBase
		add	edx,StartOfPayload

		mov	word ptr [edi+edx+4], ax

		pop	edx
		pop	edi

OnlyOfs:
                movzx   edi, byte ptr FRType[ebx+ecx+1]
                shr     edi, 3
                add     ebx, edi
                pop     edi
		add	ebx,7
		cmp	ebx,[edi+ebp+4]
		jc	FixupRecord

FixupDone:
                pop     eax
		add	edi,4
		add	edx,LEPageSize[ebp]
		dec     OTPageMapSize[ebp+eax]
		jnz	FixupPage

ZeroPagesObject:

  		add	eax, 24
		dec	LEObjectEntries[ebp]
		jnz	FixupObject

		mov	esi,LEEntrySection[ebp]
		lea	esi,[esi*2+esi-3]
		lea	esi,[esi*8+ebp]
		add	esi,LEObjectTable[ebp]
		mov	ebx,OTReserved[esi]
		mov	edx,ebx
		add	ebx,LEEntryOffset[ebp]

		mov	esi,LEStackSection[ebp]
		lea	esi,[esi*2+esi-3]
		lea	esi,[esi*8+ebp]
		add	esi,LEObjectTable[ebp]
		mov	eax,OTReserved[esi]
		add	eax,LEInitialESP[ebp]
		push	WatcomCode
		push	ebx
		mov	JumpPoint,esp
;                push    cs
;                push    offset Fetcher
;                retf
		jmp	short Fetcher
Fetcher:
		mov	es,pspsel
		mov	ss,WatcomData
		mov	esp,eax
;		push	edx			; ???
;		push	ebx			; ???
		sub	eax,eax
		sub	ebx,ebx
		sub	ecx,ecx
		sub	edx,edx
		sub	esi,esi
		sub	edi,edi
		sub	ebp,ebp
		mov	fs,WatcomData
		mov	ds,WatcomData
		mov	gs,eax

; this originally has been done to generate an exception if the debugger
; modified the segment limit of the current cs: descriptor, it doesn't
; work for the binary image with the current version of the debugger since
; the debugger currently won't recognize the executable format. No problem
; since there's always the WATCOM debugger yet, isn't it?

		jmp	pword ptr cs:[11111111h]
		org	$-4
JumpPoint	dd	?


;ebx-base, ecx-size, dx-attrs
;return selector in ebx
;ax destroyed
CreateSelector PROC NEAR
               push edi
               sub esp, 8        ;alloc space for descriptor
Cache EQU ss:[esp]
               cmp ecx, 100000h  ;may use byte limit ?
               jb  @@SizeNotinPages
               or  dh, 80h
               add ecx, 0FFFh
               shr ecx, 12
@@SizeNotinPages:
               mov ax, cs
               and eax, 3
               shl eax, 5         ;setup privelegy level
               or  dl, al
               or  dl, 1
               mov dword ptr Cache, ecx
               shr ecx, 16
               or  dh, cl
               mov dword ptr Cache[2], ebx
               shr ebx, 24
               mov Cache[7], bl
               mov word ptr Cache[5], dx
               mov cx, 1
               xor eax, eax
               int 31h
               jc  mem_error
               movzx ebx, ax
               mov ax, 0Ch
               mov edi, esp
               push es
               push ds
               pop  es
               int 31h
               pop  es
               jc  mem_error

               add esp, 8
               pop edi
               retn
               ENDP

;eax - ObjIndex

@@AttrTranslateTable: DB 0   ;0    all flags zero               ?
                     DB 0   ;1    conformed but not executable ?
                     DB 90h ;10   readable data
                     DB 0   ;11   conformed but not executable ?
                     DB 0   ;100  writable but not readable    ?
                     DB 0   ;101  conformed but not executable ?
                     DB 92h ;110  readable & writable data
                     DB 0   ;111  conformed but not executable ?
                     DB 98h ;1000 executable only
                     DB 9Ch ;1001 conformed executable
                     DB 9Ah ;1010 readable & executable
                     DB 9Eh ;1011 conformed readable & executable
                     DB 0   ;1100 executable but writable ?
                     DB 0   ;1101 executable but writable ?
                     DB 0   ;1110 executable but writable ?
                     DB 0   ;1111 executable but writable ?
CreateSelForObject PROC NEAR
               mov  eax, [edi+ebp][OTPageMapIndex]
               or   eax, eax
               jnz  @@Ret2
               pushad
               mov  ecx, [edi+ebp][OTObjectFlags]
               mov  edx, ecx
               shl  ch, 2
               rcl  cl, 1
               and  ecx, 1111b
               mov  dl, Byte Ptr @@AttrTranslateTable[ecx]
               or   dl, dl
               jz   format_error
               shl  dh, 1
               and  dh, 40h
               jz   @@Sel16bit
               cmp  dx, 409Ah
               je   @@WCode
               cmp  dx, 4092h
               je   @@WData
               xor  ebx, ebx
               mov  ecx, 0FFFFF000h
               jmp  @@Sel32bit
@@Sel16bit:
               mov  ebx, [edi+ebp][OTReserved]
               mov  ecx, [edi+ebp][OTVirtualSize]
@@Sel32bit:
               call CreateSelector
@@MakeSel:
               mov  [edi+ebp][OTPageMapIndex], ebx
@@Ret:        
               popad
               mov  eax, [edi+ebp][OTPageMapIndex]
@@Ret2:
               ret
@@WCode:
               mov ebx, fs
               jmp @@MakeSel
@@WData:
               mov ebx, gs
               jmp @@MakeSel
ENDP

;-----------------------------------------------------------------------------
; wfseHandler: Wrapper around DOS file accesses. If WFSE present, try WFES
;              first, then DOS.
; (not relocatable)
wfseHandler	PROC NEAR

		test	bh, 80h
		jz	@@noWfse

		push	eax
		shl	eax, 16
		mov	ax, 0FFFDh
		int	21h
		jnc	@@wfseOk

		pop	eax
		jmp	wfseErr

@@noWfse:
		int	21h
		ret
		
@@wfseOk:
		add	esp, 4

wfseErr:
		ret

wfseHandler	ENDP

wfseName	db	'wdosxmain',0

		align 4
freemem		label	near
code		ends
end		entry_point
