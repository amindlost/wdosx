; ############################################################################
; ## WDOSX DOS Extender           Copyright (c) 1996, 1999, Michael Tippach ##
; ##                                                                        ##
; ## Released under the terms of the WDOSX license agreement.               ##
; ############################################################################
;
; $Header: E:/RCS/WDOSX/0.95/SRC/legacy/LOADPE.ASM 1.1 1999/02/07 18:13:00 MikeT Exp $
;
; ----------------------------------------------------------------------------
;
; $Log: LOADPE.ASM $
; Revision 1.1  1999/02/07 18:13:00  MikeT
; Initial check in.
;
;
; ----------------------------------------------------------------------------
;
; Old floating segment PE code which I'm too lazy to maintain any longer or to
; even comment on. It should stay as is and eventually die.
;


; This includes the Win32 API Emulation

;WIN32API = 1

.386p

IFDEF WIN32API
include w32struc.inc
include except.inc
ENDIF


code		segment use32
assume		cs:code,ds:code
segbegin	label	near

IFDEF WIN32API
		; thread information block MUST BE AT OFFSET 0 !!!

TIB		label	near
TIBErecord	dd	-1
StackBase	dd	?
org 02ch
TlsArray	dd	?
ENDIF



femsg		db	'Error reading executable',0dh,0ah,'$'
fomsg		db	'Wrong executable format',0dh,0ah,'$'
memsg		db	'Not enough extended memory',0dh,0ah,'$'

IFDEF WIN32API

dmmsg		db	'DPMI host returned an error',0dh,0ah,'$'
impmsg		db	'Import by ordinal not supported',0dh,0ah,'$'
todomsg		db	'This dynalink is not supported yet',0dh,0ah,'$'
ENDIF

file_error:	mov	edx,offset femsg
		jmp	short errormsg
format_error:	mov	edx,offset fomsg
		jmp	short errormsg
mem_error:	mov	edx,offset memsg

IFDEF WIN32API
		jmp	short errormsg
import_error:
		mov	edx,offset impmsg
		jmp	short errormsg
dpmi_error:
		mov	edx,offset dmmsg
		jmp	short errormsg
todo_error:
		push	esi
		call	output0string
		mov	edx,offset todomsg
ENDIF

errormsg:	mov	ah,9
		int	21h
		mov	ax,4cffh
		int	21h

IFDEF WIN32API
include imports.inc
include win32api.inc
include console.asi
ENDIF

align dword
FlatDataSel		dd	0
ZeroDataSelector	dd	0
OldExcHandlers	label	dword


start_it_up:

;-------------- enable virtual interrupts -------------

		mov	ax,0901h
		int	31h

IFDEF WIN32API
;-------------- Allocate the 0 - 4g descriptor --------

		sub	eax,eax
		mov	ecx,1
		int	31h
		jc	dpmi_error
		mov	ebx,eax
		mov	eax,8
		stc
		sbb	ecx,ecx
		sbb	edx,edx
		int	31h
		jc	dpmi_error
		lar	cx,bx
		mov	cl,ch
		and	cl,60h
		or	cl,92h
		mov	ch,0cfh
		mov	eax,9
		int	31h
		jc	dpmi_error
		sub	ecx,ecx
		sub	edx,edx
		mov	ax,7
		int	31h
		jc	dpmi_error
		mov	ZeroDataSelector,ebx

ENDIF

;-------------- expand segment a bit -----------------

		mov	ax,-1
		mov	edx,20000h	;128k, should be enough

		int	21h
		jc	mem_error
		mov	esp,edx
		
;-------------- save PSP selector ---------------------

		mov	pspsel,es

;-------------- get environment selector --------------

		mov	es,es:[2ch]

;-------------- scan for filename ---------------------

		sub	ebp,ebp
		cld
		mov	ecx,0fff4h
		sub	edi,edi
		sub	eax,eax
		mov	ebp,4

next_env:
		add	ebp,4
		repne	scasb
		scasb
		jne	short next_env

;ebp bytes needed for *environm[]

		lea	edx,[edi+2]
		push	edx
		push	ebp

;-------------- copy environment ----------------------

;find end of filename
		mov	edi,edx
		repne	scasb
;		lea	ecx,[edi+1]
;bugfix
		mov	ecx,edi
;
		mov	edi,offset freemem
		sub	esi,esi

		mov	ebp,ds

		push	es
		mov	es,ebp
		pop	ds
IFDEF DEBUG
		mov	eax,esi
		call	ccc
		mov	eax,edi
		call	ccc
		mov	eax,ecx
		call	ccc
		mov	ax,es
		call	ccc
		mov	ax,ds
		call	ccc
		pushfd
		pop	eax
		call	ccc
ENDIF
		cld
		rep	movs byte ptr es:[edi],ds:[esi]

;-------------- open exe ------------------------------

		mov	ax,3d00h
		int	21h
		mov	ds,ebp
		pop	ebp
		pop	edx
		jc	file_error
		add	edx,offset freemem
		mov	argv[0],edx
		mov	handle,eax
IFDEF DEBUG
		pushad
		mov	edx,offset succ1
		mov	ah,9
		int	21h
		popad
ENDIF

;-------------- copy command line args ----------------

		push	edi
		mov	ds,pspsel
		movzx	ecx,byte ptr ds:[80h]
		mov	esi,81h
		push	ecx
		rep	movs byte ptr es:[edi],ds:[esi]
		push	ss
		pop	ds
		mov	[edi],cl
		pop	ecx

;-------------- determine start of loader space -------

		lea	edi,[edi+4]
		and	edi,0fffffffch
		mov	EnvArray,edi
		add	ebp,edi
		mov	ImageBase,ebp
		pop	edi

;-------------- Get yet another copy of the CmdTail ---

IFDEF WIN32API
		push	edi
		mov	esi,edi	

		; get a pointer to filename ( argv[0] already set )

		sub	eax,eax
		mov	edx,argv[0]
		mov	edi,offset CmdTail

CmdTail2Fname:
		mov	ah,[edx]
		inc	edx
		mov	[edi],ah
		inc	edi
		inc	al
		test	ah,ah
		jnz	short CmdTail2Fname
		cmp	byte ptr [esi],20h
		jc	CmdTail2Done
		mov	byte ptr [edi-1],20h
		jnz	CmdTail2Copy
		dec	edi
CmdTail2Copy:
		mov	ecx,80h
		rep	movsb
CmdTail2Done:
		mov	ApiFnameLen,eax
		pop	edi
ENDIF

;-------------- Fixup command tail --------------------

		sub	edx,edx
		mov	argc,1	;?
		mov	esi,offset Argv+4
		jecxz	FixCmdDone

FixCmdTail:
		cmp	byte ptr [edi],20h
		jna	short IsSeparator

		test	edx,edx
		jnz	short NoArgument
		or	edx,1
		inc	argc
		mov	[esi],edi
		add	esi,4
		jmp	short NoArgument
IsSeparator:
		mov	byte ptr [edi],0
		sub	edx,edx
NoArgument:
		inc	edi
		loop	short FixCmdTail
FixCmdDone:
		mov	dword ptr [esi],0

;-------------- build *evironment[] -------------------

		mov	edi,offset freemem
		mov	esi,EnvArray
		sub	eax,eax
		stc
		sbb	ecx,ecx
		mov	[esi],edi

nextenvptr:
		add	esi,4
		repne	scasb
		mov	[esi],edi
		scasb
		jne	nextenvptr
		mov	[esi],eax

;-------------- read wdosx header ---------------------

		mov	ebx,handle
		mov	ecx,6
		mov	ah,3fh
		mov	edx,ebp
		int	21h
		jc	file_error

;-------------- get offset to next header -------------

		sub	edx,edx
		mov	ecx,[ebp+2]

		shld	edx,ecx,16+9
		neg	ecx
		and	ecx,511
		and	edx,0ffffffe0h
		sub	edx,ecx
		sub	ecx,ecx
		push	edx
		mov	ax,4200h
		int	21h

;-------------- read peloader header ------------------

		mov	ecx,6
		mov	ah,3fh
		mov	edx,ebp
		int	21h
		jc	file_error

;-------------- get offset to user exe header ---------

		sub	edx,edx
		mov	ecx,[ebp+2]
		shld	edx,ecx,16+9
		neg	ecx
		and	ecx,511
		and	edx,0fffffe00h
		sub	edx,ecx
		sub	ecx,ecx
		pop	eax
		add	edx,eax

;we'll have to do something if wdosx+peloader gets > 64k

		mov	image2filepos,edx

		mov	ax,4200h
		int	21h

;-------------- read header --------------------------

		mov	ecx,64
		mov	ah,3fh
		mov	edx,ebp
		int	21h
		jc	file_error
		cmp	eax,64
		jnz	file_error

;-------------- check for MZ signature ---------------
		mov	eax,[ebp]
		cmp	ax,5A4Dh
		jnz	format_error

;-------------- get offset to PE header --------------

		mov	edx,dword ptr [ebp+60]
IFDEF WIN32API
		mov	SizeOfMzExe,edx
ENDIF
		sub	edx,64

;-------------- read headers struct ------------------

		sub	ecx,ecx
		shld	ecx,edx,16
		mov	ax,4201h
		int	21h

;sig = 4
;image_file_header = 20

		mov	ecx,24
		mov	ah,3fh
		mov	edx,ebp
		int	21h
		jc	file_error
		cmp	eax,ecx
		jnz	file_error
		cmp	dword ptr [ebp],'EP'
		jnz	format_error

;-------------- get optional header --------------------------

		add	edx,24
		movzx	ecx,word ptr [ebp+20]

		mov	ah,3fh
		int	21h
		jc	file_error
		cmp	eax,ecx
		jnz	file_error

;-------------- load section table ---------------------------

		mov	ecx,[edx+92]		;get directory size
		add	edx,eax			;set pointer where to store
						;ecx*=40...
		shl	ecx,3			;ecx*=8
		lea	ecx,[ecx*4+ecx]		;ecx*=5
		mov	ah,3fh
		int	21h
		jc	file_error
		cmp	eax,ecx
		jnz	file_error

;-------------- now basic structures in memory ---------------
;-------------- check, how much mem we finally need ----------
;assumtion is that there is at least one empty entry in image section header
		mov	edi,edx

;first section = end of table + first rva
		add	ecx,edi			;ecx->free mem
						;edi->start of ISH
		mov	rva2offset,ecx

;get imagesize
		mov	edx,dword ptr [50h+ebp]

;add start of first section - rva
		add	edx,ecx
;add stack size
		add	edx,dword ptr[76+24+ebp]

;align on 4k boundary (Page granular)
		add	edx,0fffh
		and	edx,0fffff000h

IFDEF WIN32API
		mov	start_of_heap,edx

		; add size of heap to commit and align on 64k

		add	edx,[ebp+84+24]
		add	edx,0ffffh
		and	edx,0ffff0000h
		mov	end_of_heap,edx
		mov	segment_size,edx
		mov	initial_top,edx
ENDIF
		mov	ax,-1
		int	21h
IFDEF WIN32API
		mov	edx,start_of_heap
ENDIF
		jc	mem_error
		mov	esp,edx

		sub	eax,eax

		; quick'n dirty: zero out all that mem

		push	ds
		pop	es

IFDEF WIN32API
		; zero out local heap
		push	edi
		mov	edx,ecx
		mov	edi,start_of_heap
		mov	ecx,end_of_heap
		sub	ecx,edi
		shr	ecx,2
		rep	stosd
		pop	edi
		mov	ecx,edx
ENDIF
		push	edi
		mov	edi,ecx		;start
		mov	edx,ecx
		neg	ecx
		add	ecx,esp		;ecx=esp-ecx
		shr	ecx,2
;eax=0!
		rep	stosd
		pop	edi

;now safe to load sections (a broken image will crash this!)

load_section:

		; check first letter of section name

		cmp	byte ptr [edi],0
		jz	short load_done

		; get virtual size

		mov	eax,[edi+8]
		or	eax,[edi+16]
		jz	short load_next			;nothing to load

		mov	edx,[edi+20]			;get filepos
		add	edx,image2filepos		;adjust
		shld	ecx,edx,16
		mov	ax,4200h
		int	21h
		mov	edx,[edi+12]			;get rva
		mov	ecx,[edi+16]			;get size
		add	edx,rva2offset			;adjust rva
		mov	ah,3fh
		int	21h
		jc	file_error
		cmp	eax,ecx
		jnz	file_error

load_next:
		add	edi,40
		jmp	short load_section
load_done:

;-------------- now all that stuff in memory ------------

		mov	ah,3eh
		int	21h

;-------------- close handle ----------------------------
;get fixups from array of interesting rvas

		mov	edi,dword ptr ds:[0a0h+ebp]	;rva
		mov	ecx,dword ptr ds:[0a4h+ebp]	;size
		mov	eax,rva2offset
		add	edi,eax
		sub	eax,dword ptr [34h+ebp]		;imagebase
;eax=delta


;get page rva
do_a_page:

		mov	edx,[edi]
		test	edx,edx
		jz	short reloc_done
		add	edx,rva2offset
;get blocksize
		mov	esi,8					;start
;read item

do_a_fixup:
		movzx	ebp,word ptr [edi+esi]
;get type
		ror	ebp,12
		mov	ebx,ebp
		shr	ebx,20

		cmp	bp,2
		jnz	short no_low
		add	[edx+ebx],ax
		jmp	short lookup_next

no_low:
		cmp	bp,1
		jnz	short no_high
		push	eax
		shl	eax,16
		add	[edx+ebx],ax
		pop	eax
		jmp	short lookup_next

no_high:
		cmp	bp,3
		jnz	short no_hilow
		add	[edx+ebx],eax
		jmp	short lookup_next
no_hilow:
;next one sux
		cmp	bp,4
		jnz	short lookup_next		;ignore others
		add	esi,2
		mov	ebp,[edx+ebx-2]			;get high word
		mov	bp,[edi+esi]			;get low word
		lea	ebp,[ebp+eax+8000h]		;do as M$ says
		shr	ebp,16				;only high word matters
		mov	[edx+ebx],bp			;what is this for???

lookup_next:
		add	esi,2
		cmp	esi,[edi+4]
		jnz	short do_a_fixup
		add	edi,esi
		jmp	short do_a_page

reloc_done:

IFDEF WIN32API
		call	process_imports
		; get approx. initial free memory size
		sub	esp,30h
		mov	edi,esp
		mov	eax,500h
		int	31h
		pop	ApiInitialFree	
		add	esp,2ch
		mov	eax,start_of_heap
		add	ApiInitialFree,eax
		mov	edx,offset NewDTA
		mov	ah,1ah
		int	21h
		call	InitSeh
		mov	eax,cs
		lar	eax,eax
		test	ah,60h
		jnz	short @@FpuCheck
		mov	eax,cr0
		and	al,NOT 6	; reset EM + MP
		mov	cr0,eax
@@FpuCheck:
	        fninit
	        push    5a5ah
	        fstsw  [esp]
		mov	eax,[esp]
	        test    al,al
	        jnz     short @@NoFpu

	        fstcw  [esp]
	        pop	eax
	        and     eax,103fh
	        cmp     eax,3fh
	        jnz	short @@NoFpu1

; This is a horrible kludge since Windows does not allow us to use exception 10
; It allowes setting the exception handler, though, but it doesn't trigger it.

		mov	eax,400h
		int	31h
		cmp	cl,4
		jc	short TheHardWay
		mov	eax,cs
		lar	eax,eax
		test	ah,60h
		jnz	short TheHardWay
		mov	eax,cr0
		or	eax,80000022h
		mov	cr0,eax
TheHardWay:
		mov	bl,dl
		add	bl,5

		mov	ecx,cs
		mov	edx,offset FPUHandlerPIC

		mov	eax,205h
		int	31h
		in	al,0a1h
		and	al,NOT 20h
		out	0a1h,al
		in	al,21h
		and	al,NOT 4
		out	21h,al
		jmp	short @@FpuDone
@@NoFpu: 
		pop	eax
@@NoFpu1: 

; remove the comments to raise an exception if there's no FPU present

;		mov	eax,cs
;		lar	eax,eax
;		test	ah,60h
;		jnz	short @@FpuDone
;		mov	eax,cr0
;		or	al,4
;		and	al,NOT 2
;		mov	cr0,eax
@@FpuDone:

ENDIF

;launch the proggy
		mov	eax,ImageBase
IFDEF WIN32API
		mov	ebx,[eax+0c0h]
		add	ebx,rva2offset
		add	ebx,0ch
		mov	TlsArray,ebx
ENDIF
		mov	eax,dword ptr [16+24+eax]
		add	eax,rva2offset
		mov	esi,argc
		mov	edi,offset argv
		mov	ebp,EnvArray
		push	ds
		pop	fs
		push	ds
		pop	gs

IFDEF WIN32API
		; I'm not sure if this is correct...

		mov	StackBase,esp
		lea	ebp,[esp-30h]
		push	ebp
		push	ebp
		push	ebp
		sub	esp,30h-12
ELSE
;get dpmi style es - selector (PSP)
		mov	es,pspsel
ENDIF
		jmp	eax


;entry conditions:
;		VI enabled
;		es=fs=gs=ds=ss alias cs
;		esi->Argc
;		edi->*Argv[Argc]
;		ebp->*Environment[]

IFDEF DEBUG
succ1		db	'environment copy done',0dh,0ah,'$'
ENDIF

align 4

IFDEF WIN32API
va_space	MemBlock blockcount dup (<0,0>)
free_handles	dd blockcount
ConsoleMode	dd	ENABLE_LINE_INPUT + ENABLE_ECHO_INPUT
ffhandles	dd	0
ENDIF

;globals
rva2offset	dd	?
image2filepos	dd	?
pspsel		dw	?
		dw	?	;align
handle		dd	?
ImageBase	dd	?
Argc		dd	?
EnvArray	dd	?
Argv		dd	40h dup (?)

IFDEF WIN32API
ApiFnameLen	dd	?
LastError	dd	?
SizeOfMzExe	dd	?
initial_top	dd	?
start_of_heap	dd	?
end_of_heap	dd	?
segment_size	dd	?
ApiInitialFree	dd	?
NewDTA		db	80h * 32 dup (?)

DummyTime	systime	<?,?,?,?,?,?,?,?>

CmdTail		db	260 dup	(?)
Cntx		ContextRecord <>
Erec		ExceptionRecord <>
		dd	15 dup (?)
align 4
TlsSpace	dd	64 dup (?)
ENDIF

freemem		label	near
code		ends
end		start_it_up
