{ ############################################################################
  ## WDOSX DOS Extender           Copyright (c) 1996, 1998, Michael Tippach ##
  ##                                                                        ##
  ## Realeased under the terms of the WDOSX license agreement.              ##
  ############################################################################

  $Header: E:/RCS/WDOSX/0.95/SRC/DELPHI/dos.pas 1.11 2000/03/03 20:39:29 MikeT Exp MikeT $

  ----------------------------------------------------------------------------

  $Log: dos.pas $
  Revision 1.11  2000/03/03 20:39:29  MikeT
  Hooking IRQ 8..15 did not work due to an error in the calculation of
  interrupt numbers.

  Revision 1.10  1999/12/12 22:06:56  MikeT
  Fixed stack allocation in IRQ wrapper routine. Previously, one interrupt
  stack never got used.

  Revision 1.9  1999/03/06 11:45:20  MikeT
  Fixed the handling of the command line arguments passed to the exec()
  function. INT 21 function 4Bh expects a copy of the real PSP command
  tail image and not an ASCIIZ string. This fixes various issues where
  command line arguments would be passed incompletely or additional
  garbage would have been appended to the end of the command line.

  Revision 1.8  1998/10/10 14:54:32  MikeT
  Fixed Exec() destroying random memory. Wasn't a problem in any official
  release though.

  Revision 1.7  1998/10/10 14:51:26  MikeT
  Added some cleanup routines. Does not fix anything but does not hurt either.

  Revision 1.6  1998/10/10 12:25:55  MikeT
  Fix ToPchar failing on empty strings.

  Revision 1.5  1998/10/07 19:41:56  MikeT
  GetEnv() now returns an empty string if the variable could not be found.
  EnvStr() now starts at index 1. Both changes were made to improve BP
  compatibility.

  Revision 1.4  1998/09/13 16:25:53  MikeT
  Corrected the ToPchar helper function. That one would not have worked.

  Revision 1.3  1998/09/13 16:13:55  MikeT
  Change the Name field in SearchRec to contain a Pascal string

  Revision 1.2  1998/08/27 01:38:30  MikeT
  Changed Pchar parameters back to string in order to increase
  compatibility with Turbo Pascal

  Revision 1.1  1998/08/04 00:42:22  MikeT
  Initial check in


  ----------------------------------------------------------------------------

  32 bit DOS unit for use with WDOSX 0.95 or better. Most of the stuff
  hasn't been tested yet. Note that I somehow managed GetIntVec and SetIntVec
  to deal with near pointers almost transparently. Delphi 2 does not support
  the "interrupt" attribute for a procedure, so we have to generate entry-
  and exitcode in a different way.

  [97/04/28] Fixed the SearchRec structure declaration
  [97/05/05] Locking the memory for the interrupt handlers makes no sense
             since the addresses may change during program execution
  [97/05/21] Pops up an error message if used without WDOSX ( it happens
             far to often that we forget about STUBIT whilst in Windows
             doesn't it? )
  [97/05/29] Added Exec() and DosExitCode support. SwapVectors is merely
             a dummy, though...
             Intr() now validates selectors passed to it so there seems to
             be no need to intitialize unused selector fields in a Registers
             structure -> better backward compatibility
  [97/06/12] Added support for mem[], memw[], memd[] as well as port[] and
             portw[]. This should help you porting legacy code.
             I have to thank Niklas Martinsson once again for his suggestions
             as well as the people in comp.lang.pascal.delphi.misc for giving
             me a clue on how to implement port[] and portw[]

  [97/06/28] Fixed GetDate and GetTime.

  [97/07/04] Since WDOSX now has the GetEnvironmentStrings() fixed to return
             Env[0]^ instead of @Env[], We have to fix GetEnv(), EnvStr() and
             EnvCount too.

  [97/07/17] Changed mem[]/memw[]/meml[] to Zero base since else there's
             little use for it. Now, writing to gfx video memory using
             "mem[$A0000]:=foo;" works fine (alltough it's anything but fast)

  [97/07/19] Minor changes in the interrupt glue code

  [98/03/10] Changed memX[] reflecting the new memory model for faster speed.
             Added PortL as this might be useful when dealing with PCI.

  ---------------------------------------------------------------------------}

unit Dos;

interface

{$H-}

const

	FCarry		= $0001;
	FParity		= $0004;
	FAuxiliary	= $0010;
	FZero		= $0040;
	FSign		= $0080;
	FOverflow	= $0800;

	fmClosed	= $D7B0;
	fmInput		= $D7B1;
	fmOutput	= $D7B2;
	fmInOut		= $D7B3;

	ReadOnly	= $01;
	Hidden		= $02;
	SysFile		= $04;
	VolumeID	= $08;
	Directory	= $10;
	Archive		= $20;
	AnyFile		= $3F;

type

	ComStr		= String[127];
	PathStr		= String[79];
	DirStr		= String[67];
        NameStr		= String[8];
        ExtStr		= String[4];

	Registers	= packed record
		case integer of
		    0: (edi,esi,ebp,espres,ebx,edx,ecx,eax:longint;
	                flags,es,ds,fs,gs,ip,cs,sp,ss:word);
	            1: (di,diu,si,siu,bp,bpu,spres,spu,bx,bxu,dx,dxu,cx,cxu,
			ax,axu:word);
		    2: (dil,dih,di2,di3,sil,sih,si2,si3,bpl,bph,bp2,bp3,spl,
			sph,sp2,sp3,bl,bh,bx2,bx3,dl,dh,dx2,dx3,cl,ch,cx2,cx3,
			al,ah,ax2,ax3:byte);
		end;

	FileRec		= record
		Handle: integer;
		Mode: integer;
		RecSize: cardinal;
		Private: array[1..28] of byte;
		UserData: array[1..32] of byte;
		Name: array [0..259] of char;
	end;

	TextBuf		= array[0..127] of Char;

	TextRec		= record
		Handle: integer;
		Mode: integer;
		BufSize: cardinal;
		BufPos: cardinal;
		BufEnd: cardinal;
		BufPtr: PChar;
		OpenFunc: Pointer;
		InOutFunc: Pointer;
		FlushFunc: Pointer;
		CloseFunc: Pointer;
		UserData: array [1..32] of byte;
		Name: array [0..259] of Char;
		Buffer: TextBuf;
	end;

        SearchRec	= packed record
                Fill: array[1..21] of byte;
                Attr: byte;
                Time: Longint;
                Size: Longint;
                Name: String[12];
	end;

	DateTime	= packed record
		Year,Month,Day,Hour,Min,Sec: word;
	end;

{
  TMemB sent into nirvana as we have a true flat model now.

	TMemB = class
		private
			function ReadMemB(index: longint):byte;
			procedure WriteMemB(index: longint; value:byte);
		public
			property mem[index: longint]:byte read ReadMemB write WriteMemB;default;
	end;
}

	TMemW = class
		private
			function ReadMemW(index: longint):word;
			procedure WriteMemW(index: longint; value:word);
		public
			property memw[index: longint]:word read ReadMemW write WriteMemW;default;
	end;

	TMemL = class
		private
			function ReadMemL(index: longint): longint;
			procedure WriteMemL(index: longint; value: longint);
		public
			property memL[index: longint]:longint read ReadMemL write WriteMemL; default;
	end;

	TPortB = class
		private
			function ReadPortB(index:word):byte;
			procedure WritePortB(index:word; value:byte);
		public
			property port[index:word]:byte read ReadPortB write WritePortB;default;
	end;

	TPortW = class
		private
			function ReadPortW(index:word):word;
			procedure WritePortW(index:word; value:word);
		public
			property portw[index:word]:word read ReadPortW write WritePortW;default;
	end;

	TPortL = class
		private
			function ReadPortL(index:word):longint;
			procedure WritePortL(index:word; value:longint);
		public
			property portl[index:word]:longint read ReadPortL write WritePortL;default;
	end;

var
	port:TPortB;
	portw:TPortW;
	portl:TPortL;
{        mem:TMemB;}
        memw:TMemW;
        meml:TMemL;
	DosError: integer;

        mem: array[0..$7ffffffe] of byte absolute 0;
{        memw: array[0..$3ffffffe] of word absolute 0; }
{        meml: array[0..$1ffffffe] of longint absolute 0; }


procedure CallInterrupt(OldInt:pointer);register;assembler;
{ I thought this one may come in handy here an there... }

function Ds:longint;register;assembler;
function Es:longint;register;assembler;
function Fs:longint;register;assembler;
function Gs:longint;register;assembler;
function Ss:longint;register;assembler;
function Cs:longint;register;assembler;

function DosVersion: word;register;assembler;
procedure Intr(IntNo: byte; var Regs: Registers);register;assembler;
procedure MsDos(var Regs: Registers);register;assembler;
procedure GetDate(var Year,Month,Day,DayOfWeek: word);
procedure SetDate(Year,Month,Day: word);register;assembler;
procedure GetTime(var Hour,Minute,Second,Sec100: word);
procedure SetTime(Hour,Minute,Second,Sec100: word);
procedure GetCBreak(var Break: Boolean);register;assembler;
procedure SetCBreak(Break: Boolean);register;assembler;
procedure GetVerify(var Verify: Boolean);register;assembler;
procedure SetVerify(Verify: Boolean);register;assembler;
function DiskFree(Drive: byte): Longint;register;assembler;
function DiskSize(Drive: byte): Longint;register;assembler;
procedure GetFAttr(var F:file; var Attr: word);
procedure SetFAttr(var F:file; Attr: word);
procedure GetFTime(var F:file; var Time: Longint);
procedure SetFTime(var F:file; Time: Longint);
procedure FindFirst(Path: PathStr; Attr: word; var F: SearchRec);
procedure FindNext(var F: SearchRec);
procedure UnpackTime(P: Longint; var T: DateTime);register;
procedure PackTime(var T: DateTime; var P: Longint);register;
procedure GetIntVec(IntNo: byte; var Vector: Pointer);
procedure SetIntVec(IntNo: byte; Vector: Pointer);

{
procedure Keep(ExitCode: word);
}

procedure SwapVectors;
function DosExitCode: word;register;assembler;
procedure Exec(Path: PathStr; ComLine: ComStr);
function FSearch(Path: PathStr; DirList: String): PathStr;
function FExpand(Path: PathStr): PathStr;register;assembler;
procedure FSplit(Path: PathStr; var Dir: DirStr;var Name: NameStr; var Ext: ExtStr);
function EnvCount: integer;
function EnvStr(Index: integer): String;
function GetEnv(EnvVar: String): String;

implementation

type	IrdEntry = packed record
		IOpcode		: byte;
		IOffset		: longint;
		ISelector	: word;
		IPadding	: byte;
	end;

	DTA	 = packed record
		Payload		: SearchRec;
		Padding		: array [0..(127-SizeOf(SearchRec))] of byte;
	end;

        ExecParBlk = packed record
                EnvOffset       : longInt;
                EnvSelector     : word;
                CmdOffset       : longInt;
                CmdSelector     : word;
        end;

var	IntRedir: array [0..255] of IrdEntry;
	TempDTA : DTA;
	IntStack: array [0..$ffff] of byte;
	IntStackTop: Longint;
	DataSelector: Longint;
	ECount:integer;
	IrqHandler: array [0..15] of pointer;
	ProcLookup: array [0..15] of pointer;
	Pic1Base,Pic2Base: byte;
	IntsInitialized: boolean;

{ Don't be shocked, we don't actually deal with Windows, it's just the stub
  functions of our DOS extender. YOU should not call Win32 API functions
  directly since YOU don't know how I implemented them in particular. Anyway,
  I _do_ know, so I'm allowed to do this ;-> }

function GetEnvStr:pointer;stdcall;external 'kernel32.dll' name 'GetEnvironmentStrings';
function GetEnvVar(EName:Pchar; EBuffer:Pchar ;Esize: longint):longint;stdcall;
external 'kernel32.dll' name 'GetEnvironmentVariableA';

function GetPathStr:integer;stdcall;external 'kernel32.dll' name 'GetFullPathName';

{ These are for user notification in case one forgot about the DOS extender: }

function MessageBoxA(hWin: integer; title,Msg: Pchar; Style: integer):integer;stdcall;external 'user32.dll' name 'MessageBoxA';
function GetModuleHandleA(lpFn: Pchar):integer;stdcall;external 'kernel32.dll' name 'GetModuleHandleA';
function GetProcAddress(hMod: integer; Pname: Pchar):integer;stdcall;external 'kernel32.dll' name 'GetProcAddress';
procedure ExitProcess(Exitcode: integer);stdcall;external 'kernel32.dll' name 'ExitProcess';

procedure ToPchar(s: ShortString);register;assembler;
asm
   movzx ecx, BYTE PTR [eax]
   jecxz @@01

@@00:
   mov   dl, [eax + 1]
   mov   [eax], dl
   inc   eax
   loop  @@00

   mov   [eax], cl
@@01:
end;

procedure ToString(p: Pchar);register;assembler;
asm
   mov	ecx, eax

@@00:
   cmp  BYTE PTR [ecx], 0
   je   @@01

   inc  ecx
   jmp  @@00

@@01:
   sub  ecx, eax
   jz   @@03

   push ecx

@@02:
   mov  dl, [eax + ecx - 1]
   mov  [eax + ecx], dl
   loop @@02

   pop  ecx
   mov  [eax], cl

@@03:
end;


{

function TMemB.ReadMemB(index: longint):byte;register;assembler;
asm
	push	ds
	mov	ds,ZeroDataSelector
	mov	al,[edx]
	pop	ds
end;

}

function TMemW.ReadMemW(index: longint):word;register;assembler;
asm
{	push	ds }
{	mov	ds,ZeroDataSelector }
	mov	ax,[edx]
{	pop	ds }
end;

function TMemL.ReadMemL(index: longint):longint;register;assembler;
asm
{	push	ds }
{	mov	ds,ZeroDataSelector }
	mov	eax,[edx]
{	pop	ds }
end;

{
procedure TMemB.WriteMemB(index: longint; value: byte);register;assembler;
asm
	push	ds
	mov	ds,ZeroDataSelector
	mov	[edx],cl
	pop	ds
end;
}

procedure TMemW.WriteMemW(index: longint; value: word);register;assembler;
asm
{	push	ds }
{	mov	ds,ZeroDataSelector }
	mov	[edx],cx
{	pop	ds }
end;

procedure TMemL.WriteMemL(index: longint; value: longint);register;assembler;
asm
{	push	ds }
{	mov	ds,ZeroDataSelector }
	mov	[edx],ecx
{	pop	ds }
end;

function TPortB.ReadPortB(index:word):byte;register;assembler
asm
	in	al,dx
end;

procedure TPortB.WritePortB(index:word; value:byte);register;assembler;
asm
	mov	eax,ecx
	out	dx,al
end;

function TPortW.ReadPortW(index:word):word;register;assembler;
asm
	in	ax,dx
end;

procedure TPortW.WritePortW(index:word; value:word);register;assembler;
asm
	mov	eax,ecx
	out	dx,ax
end;

function TPortL.ReadPortL(index:word):longint;register;assembler;
asm
	in	eax,dx
end;

procedure TPortL.WritePortL(index:word; value:longint);register;assembler;
asm
	mov	eax,ecx
	out	dx,eax
end;

function PtrInRange(Ptr1,Lower,Upper:pointer):boolean;register;assembler;
asm
	sub	eax,edx
	sub	ecx,edx
	cmp	eax,ecx
	mov	eax,0
	ja	@@done
	inc	eax
@@done:
end;


procedure EnterInterrupt;register;assembler;
asm
	xchg	ecx,[esp]
	push	eax
	push	edx
	push	gs
	push	fs
	push	es
	push	ds
	mov	ds,dword ptr cs:[offset DataSelector]
	mov	edx,ss
	mov	eax,esp
	push	ds
	pop	ss
	mov	esp,dword ptr [offset IntStackTop]
	sub	dword ptr [offset IntStackTop],4000h
	push	edx
	mov	edx,ds
	mov	fs,edx
	mov	es,edx
	push	eax
	call	ecx
	db	0fh,0b2h,24h,24h
	{ lss esp,[esp], this compiler is just brain dead }
	add	dword ptr [offset IntStackTop],4000h
	pop	ds
	pop	es
	pop	fs
	pop	gs
	pop	edx
	pop	eax
	pop	ecx
	iretd
end;

procedure HandleIrq0;register;assembler;
asm
	call	EnterInterrupt
	call	dword ptr [offset IrqHandler]
end;

procedure HandleIrq1;register;assembler;
asm
	call	EnterInterrupt
	call	dword ptr [offset IrqHandler+4]
end;

procedure HandleIrq2;register;assembler;
asm
	call	EnterInterrupt
	call	dword ptr [offset IrqHandler+4*2]
end;

procedure HandleIrq3;register;assembler;
asm
	call	EnterInterrupt
	call	dword ptr [offset IrqHandler+4*3]
end;

procedure HandleIrq4;register;assembler;
asm
	call	EnterInterrupt
	call	dword ptr [offset IrqHandler+4*4]
end;

procedure HandleIrq5;register;assembler;
asm
	call	EnterInterrupt
	call	dword ptr [offset IrqHandler+4*5]
end;

procedure HandleIrq6;register;assembler;
asm
	call	EnterInterrupt
	call	dword ptr [offset IrqHandler+4*6]
end;

procedure HandleIrq7;register;assembler;
asm
	call	EnterInterrupt
	call	dword ptr [offset IrqHandler+4*7]
end;

procedure HandleIrq8;register;assembler;
asm
	call	EnterInterrupt
	call	dword ptr [offset IrqHandler+4*8]
end;

procedure HandleIrq9;register;assembler;
asm
	call	EnterInterrupt
	call	dword ptr [offset IrqHandler+4*9]
end;

procedure HandleIrq10;register;assembler;
asm
	call	EnterInterrupt
	call	dword ptr [offset IrqHandler+4*10]
end;

procedure HandleIrq11;register;assembler;
asm
	call	EnterInterrupt
	call	dword ptr [offset IrqHandler+4*11]
end;

procedure HandleIrq12;register;assembler;
asm
	call	EnterInterrupt
	call	dword ptr [offset IrqHandler+4*12]
end;

procedure HandleIrq13;register;assembler;
asm
	call	EnterInterrupt
	call	dword ptr [offset IrqHandler+4*13]
end;

procedure HandleIrq14;register;assembler;
asm
	call	EnterInterrupt
	call	dword ptr [offset IrqHandler+4*14]
end;

procedure HandleIrq15;register;assembler;
asm
	call	EnterInterrupt
	call	dword ptr [offset IrqHandler+4*15]
end;

function IsIrq(IntNr: integer):boolean;
begin
	IsIrq:=(((IntNr<16) and (IntNr>7)) or ((IntNr<$78) and (IntNr>$6f)));
end;

function IntToIrq(IntNr: integer):integer;register;
begin
	if IntNr > 16 then IntToIrq:=IntNr-$68 else IntToIrq:=IntNr-8;
end;

function TrueIntNr(IntNr: integer):integer;register;
begin
	if IsIrq(IntNr) then begin
		if (IntToIrq(IntNr) < 8) then
			TrueIntNr:= IntToIrq(IntNr) + Pic1Base
			else
			TrueIntNr:= IntToIrq(IntNr) + Pic2Base - 8;
	end else TrueIntNr:= IntNr;
end;


{ Unless someone is using Get/SetIntVec, we don't want the overhead caused by
  the interrupt logic }

procedure InitInterrupts; assembler;
asm
	cmp	IntsInitialized, TRUE
	je	@@intsdone

	mov	eax, offset IntStack
	add	eax, 10000h
	mov	IntStackTop,eax

	mov	dword ptr [offset ProcLookup],offset HandleIrq0
	mov	dword ptr [offset ProcLookup+4*1],offset HandleIrq1
	mov	dword ptr [offset ProcLookup+4*2],offset HandleIrq2
	mov	dword ptr [offset ProcLookup+4*3],offset HandleIrq3
	mov	dword ptr [offset ProcLookup+4*4],offset HandleIrq4
	mov	dword ptr [offset ProcLookup+4*5],offset HandleIrq5
	mov	dword ptr [offset ProcLookup+4*6],offset HandleIrq6
	mov	dword ptr [offset ProcLookup+4*7],offset HandleIrq7
	mov	dword ptr [offset ProcLookup+4*8],offset HandleIrq8
	mov	dword ptr [offset ProcLookup+4*9],offset HandleIrq9
	mov	dword ptr [offset ProcLookup+4*10],offset HandleIrq10
	mov	dword ptr [offset ProcLookup+4*11],offset HandleIrq11
	mov	dword ptr [offset ProcLookup+4*12],offset HandleIrq12
	mov	dword ptr [offset ProcLookup+4*13],offset HandleIrq13
	mov	dword ptr [offset ProcLookup+4*14],offset HandleIrq14
	mov	dword ptr [offset ProcLookup+4*15],offset HandleIrq15
	
	{ hook all interrupts to ensure GetIntVec returns a near pointer }

	push	ebx
	push	esi

	mov	esi,offset IntRedir
	sub	ebx,ebx
@@loop:
	mov	byte ptr [esi],0eah
	mov	eax,204h
	int	31h
	jc	@@ignore
	mov	[esi+1],edx
	mov	[esi+5],cx
	mov	eax,205h
	mov	ecx,cs
	mov	edx,esi
	int	31h
@@ignore:
	add	esi,8
	inc	ebx
	test	bh,bh
	je	@@loop

	mov	eax,400h
	int	31h
	mov	Pic1Base,dh
	mov	Pic2Base,dl

	pop	esi
	pop	ebx
	mov	DataSelector,ds

	mov	IntsInitialized, TRUE

@@intsdone:
end;

{ ##################### public stuff ################### }

function Ds:longint;register;assembler;
asm
   mov eax,ds;
end;

function Es:longint;register;assembler;
asm
   mov eax,es
end;

function Fs:longint;register;assembler;
asm
   mov eax,fs
end;

function Gs:longint;register;assembler;
asm
   mov eax,gs
end;

function Ss:longint;register;assembler;
asm
   mov eax,ss
end;

function Cs:longint;register;assembler;
asm
   mov eax,cs
end;

procedure CallInterrupt(OldInt:pointer);register;assembler;
asm
	pushfd
	push	cs
	call	eax
end;

function DosVersion: word;register;assembler;
asm
	push	ebx
	mov	ah,30h
	int	21h
	pop	ebx
end;

procedure Intr(IntNo: byte; var Regs: Registers);register;assembler;
asm
	mov	byte ptr ds:[offset @@IntPatch],al
	pushad
	push	ds
	push	es
	push	fs
	push	gs
	push	edx
	mov	eax,[edx+28]
	mov	ebx,[edx+16]
	mov	ecx,[edx+24]
	mov	esi,[edx+4]
	mov	edi,[edx]
	mov	ebp,[edx+8]
{ 
  Normally, the user knows that we are running in protected mode and will take
  care of loading proper selector values into Regs, normally...
}
	verr	dword ptr [edx+38]
	jnz	@@00
	mov	fs,word ptr [edx+38]
@@00:
	verr	dword ptr [edx+40]
	jnz	@@01
	mov	gs,dword ptr [edx+40]
@@01:
	verr	dword ptr [edx+34]
	jnz	@@02
	mov	es,word ptr [edx+34]
@@02:
	verr	dword ptr [edx+36]
	jnz	@@03
	mov	ds,dword ptr [edx+36]
@@03:
	mov	edx,ss:[edx+20]

        { no known CPU has a prefetch queue of more than 32 bytes in size }

	db	0cdh
@@IntPatch:
	db	0
	xchg	edx,[esp]
	mov	word ptr ss:[edx+36],ds
	push	ss
	pop	ds
	pop	dword ptr [edx+20]
	mov	[edx+28],eax
	mov	[edx+16],ebx
	mov	[edx+24],ecx
	mov	[edx+4],esi
	mov	[edx],edi
	mov	[edx+12],ebp
	mov	word ptr [edx+34],es
	mov	word ptr [edx+38],fs
	mov	word ptr [edx+40],gs
	pushfd
	pop	eax
	mov	[edx+32],ax
	pop	gs
	pop	fs
	pop	es
	pop	ds
	popad
end;

procedure MsDos(var Regs: Registers);register;assembler;
asm
	push	edi
	push	ebx
	mov	edi,eax
	mov	bl,21h
	sub	ecx,ecx
	mov	eax,300h
	int	31h
	pop	ebx
	pop	edi
end;

procedure GetDate(var Year,Month,Day,DayOfWeek: word);
begin
	asm

	mov	ah,2ah
	int	21h
	push	eax
	mov	eax,Year
	mov	[eax],cx
	mov	eax,Month
	ror	edx,8
	sub	dh,dh
	mov	[eax],dx
	rol	edx,8
	sub	dh,dh
	mov	eax,Day
	mov	[eax],dx
	pop	edx
	sub	dh,dh
	mov	eax,DayOfWeek
	mov	[eax],dx

	end;
end;

procedure SetDate(Year,Month,Day: word);register;assembler;
asm
	shl	edx,8
	mov	dl,cl
	lea	ecx,[eax-1980]
	mov	ah,2bh
	int	21h
	movzx	eax,al
	mov	DosError,eax
end;


procedure GetTime(var Hour,Minute,Second,Sec100: word);
begin
	asm

	mov	ah,2ch
	int	21h
	mov	eax,Hour
	ror	ecx,8
	sub	ch,ch
	mov	[eax],cx
	mov	eax,Minute
	rol	ecx,8
	sub	ch,ch
	mov	[eax],cx
	mov	eax,Second
	ror	edx,8
	sub	dh,dh
	mov	[eax],dx
	mov	eax,Sec100
	rol	edx,8
	sub	dh,dh
	mov	[eax],dx

	end;
end;


procedure SetTime(Hour,Minute,Second,Sec100: word);
begin
	asm

	mov	ch,byte ptr [Hour]
	mov	cl,byte ptr [Minute]
	mov	dh,byte ptr [Second]
	mov	dl,byte ptr [Sec100]
	mov	ah,2dh
	int	21h
	movzx	eax,al
	mov	DosError,eax

	end;
end;

procedure GetCBreak(var Break: Boolean);register;assembler;
asm
	push	eax
	mov	eax,3300h
	int	21h
	pop	edx
	mov	[edx],dl
end;

procedure SetCBreak(Break: Boolean);register;assembler;
asm
	mov	edx,eax
	mov	eax,3301h
	int	21h
end;

procedure GetVerify(var Verify: Boolean);register;assembler;
asm
	push	eax
	mov	ah,54h
	int	21h
	pop	edx
	movzx	eax,al
	mov	[edx],eax
end;

procedure SetVerify(Verify: Boolean);register;assembler;
asm
	sub	edx,edx
	mov	ah,2eh
	int	21h
end;

function DiskFree(Drive: byte): Longint;register;assembler;
asm
	push	ebx
	mov	dl,al
	sub	ebx,ebx
	sub	ecx,ecx
	mov	ah,36h
	int	21h
	movzx	eax,ax
	cmp	eax,0ffffh
	jnz	@@ok
	mov	DosError,eax
@@ok:
	mul	ecx
	mul	ebx
	pop	ebx
end;


function DiskSize(Drive: byte): Longint;register;assembler;
asm
	push	ebx
	push	ds
	sub	edx,edx
	mov	dl,al
	sub	ecx,ecx
	mov	ah,1ch
	int	21h
	pop	ds
	movzx	eax,al
	cmp	al,0ffh
	jnz	@@ok
	mov	DosError,eax
@@ok:
	mul	edx
	mul	ecx
	pop	ebx
end;

procedure GetFAttr(var F:file; var Attr: word);register;assembler;
asm
	push	edx
	lea	edx,[eax+72]
	mov	eax,4300h
	int	21h
	pop	edx
	movzx	eax,al
	jc	@@err
	sub	eax,eax
	mov	[edx],cx
@@err:
	mov	DosError,eax
end;

procedure SetFAttr(var F:file; Attr: word);register;assembler;
asm
	mov	ecx,edx
	lea	edx,[eax+72]
	mov	eax,4301h
	int	21h
	movzx	eax,al
	jc	@@err
	sub	eax,eax
@@err:
	mov	DosError,eax
end;

procedure GetFTime(var F:file; var Time: Longint);register;assembler;
asm
	push	ebx
	push	eax
	mov	ebx,[eax]
	cmp	dword ptr [eax+4],fmClosed
	push	edx
	ja	@@open
	lea	edx,[eax+72]
	mov	eax,3d00h
	int	21h
	jc	@@open1
	mov	ebx,eax
@@open:
	mov	eax,5701h
	int	21h
	movzx	eax,al
	jnc	@@ok
	mov	DosError,eax
@@ok:
	pop	eax
	shl	edx,16
	mov	dx,cx
	mov	[eax],edx
	pop	eax
	cmp	dword ptr [eax+4],fmClosed
	ja	@@open1
	mov	ah,3eh
	int	21h
@@open1:
	pop	ebx
end;

procedure SetFTime(var F:file; Time: Longint);register;assembler;
asm
	push	ebx
	mov	ecx,eax
	mov	ebx,[eax]
	cmp	dword ptr [eax+4],fmClosed
	ja	@@open
	push	edx
	lea	edx,[eax+72]
	mov	eax,3d01h
	int	21h
	pop	edx
	jc	@@open1
	mov	ebx,eax
@@open:
	push	ecx
	mov	ecx,edx
	shr	edx,16
	mov	eax,5701h
	int	21h
	movzx	eax,al
	jnc	@@ok
	mov	DosError,eax
@@ok:
	pop	ecx
	cmp	dword ptr [ecx+4],fmClosed
	ja	@@open1
	mov	ah,3eh
	int	21h
@@open1:
	pop	ebx
end;

procedure FindFirst(Path: PathStr; Attr: word; var F: SearchRec);
begin
  ToPchar(Path);
	asm
	mov	DosError,0
	push	ebx
	push	es
	push	ds
	mov	ah,2fh
	int	21h
	push	ebx
	lea	edx,TempDTA
	mov	ah,1ah
	int	21h
	mov	ah,4eh
	lea	edx,Path
	mov	ecx,dword ptr [Attr]
	int	21h
	movzx	eax,al
	mov	DosError,eax
	pop	edx
	push	es
	pop	ds
	mov	ah,1ah
	int	21h
	pop	ds
	pop	es
	pop	ebx	

	end;
   ToString(@Path[0]);
   ToString(@(TempDTA.Payload.Name[0]));
   F := TempDTA.Payload;
end;

procedure FindNext(var F: SearchRec);
begin
	TempDTA.Payload := F;
        ToPchar(TempDTA.Payload.Name);
	asm

	mov	DosError,0
	push	ebx
	push	es
	push	ds
	mov	ah,2fh
	int	21h
	push	ebx
	lea	edx,TempDTA
	mov	ah,1ah
	int	21h
	mov	ah,4fh
	int	21h
	movzx	eax,al
	mov	DosError,eax
	pop	edx
	push	es
	pop	ds
	mov	ah,1ah
	int	21h
	pop	ds
	pop	es
	pop	ebx	

	end;
        ToString(@(TempDTA.Payload.Name[0]));
	F := TempDTA.Payload;
end;


procedure UnpackTime(P: Longint; var T: DateTime);register;
begin
	T.Year	:= (P shr 25) + 1980;
	T.Month	:= (P shr 21) and 15;
	T.Day	:= (P shr 16) and 31;
	T.Hour	:= (P shr 11) and 31;
	T.Min	:= (P shr 5) and 63;
	T.Sec	:= (P + P) and 63;
end;

procedure PackTime(var T: DateTime; var P: Longint);register;
begin
	P :=	((T.Year-1980) shl 25) +
		((T.Month and 15) shl 21) +
		((T.Day and 31) shl 16) +
		((T.Hour and 31) shl 11) +
		((T.Min and 63) shl 5) +
		((T.Sec and 63) shr 2);
end;

procedure GetIntVec(IntNo: byte; var Vector: Pointer);
var
	IntNr	  : integer;
	IntVector : pointer;
begin
	InitInterrupts;
	IntNr:=TrueIntNr(IntNo);
	asm
	push	ebx
	mov	ebx,IntNr
	mov	eax,204h
	int	31h
	mov	IntVector,edx
	pop	ebx
	end;
	if ((PtrInRange(IntVector,@IntRedir[0],@IntRedir[255]))
		 or (not(IsIrq(IntNo)))) then Vector:=IntVector
	else Vector:=IrqHandler[IntToIrq(IntNo)];
end;

procedure SetIntVec(IntNo: byte; Vector: Pointer);
var
	IntNr	  : integer;
	IntVector : pointer;
begin
	InitInterrupts;
	IntNr:=TrueIntNr(IntNo);
	IntVector:=Vector;
	if (IsIrq(IntNo) and 
		(not(PtrInRange(IntVector,@IntRedir[0],@IntRedir[255]))))
		then begin
		IrqHandler[IntToIrq(IntNo)]:=IntVector;
		IntVector:=ProcLookup[IntToIrq(IntNo)];
	end;
	asm
	push	ebx
	mov	ebx,IntNr
	mov	edx,IntVector
	mov	ecx,cs
	mov	eax,0205h
	int	31h
	pop	ebx
	end;
end;

{
procedure Keep(ExitCode: word);
}

procedure SwapVectors;
begin
  { not really }
end;

function DosExitCode: word;register;assembler;
asm
   mov ah,4dh
   int 21h
end;

function FSearch(Path: PathStr; DirList: String): PathStr;
var	i,j,k,l:integer;
	PS:PathStr;
	SR:SearchRec;
	found:boolean;
begin
   ToPchar(Path);
   ToPchar(DirList);

	found:=false;
	i:=0;
	while (DirList[i] <> chr(0)) and (not found) do begin
		j:=0;
		while (DirList[j] <> chr(0)) and (DirList[j] <> ';') do inc(j);
		if j > i then begin 
			for k:= 0 to (j-i)-1 do PS[k]:=DirList[k+i];
			l:=0;
			k:=0;
			if PS[(j-i)-1]<>'\' then begin
				PS[j-i]:='\';
				inc(l);
			end;
			while Path[k] <> chr(0) do begin
				PS[l+j-i] := Path[k];
				inc(l);
				inc(k);
			end;
			PS[l+j-i]:= #0;
			FindFirst (PS,$ffff,SR);
			found:=(DosError = 0);
		end;
		if DirList[j] <> chr(0) then i:=j+1 else i:=j;
	end;
	if found then begin
		k:=0;
		while PS[k] <> chr(0) do begin
			FSearch[k]:=PS[k];
			inc(k);
		end;
		FSearch[k]:=#0;
	end else FSearch[0]:=#0;
   ToString(@Path[0]);
   ToString(@Dirlist[0]);
   ToString(@Result[0]);
end;

function FExpand(Path: PathStr): PathStr;register;assembler;
asm
        push    edx
	push	esp
	push	edx
	push	260
	push	eax
	call	ToPchar
	call	GetPathStr
	pop	eax
        call    ToString
end;

procedure FSplit(Path: PathStr;var Dir: DirStr;var Name: NameStr; var Ext: ExtStr);
var	i,j:integer;
begin
	ToPchar(Path);
	i:= 0;
	while Path[i] <> chr(0) do inc(i);
	j:= i;
	while ((j > 0) and (Path[j] <> '.')) do dec(j);
	if j > 0 then begin
        	Ext[0]:=Path[j+1];
        	Ext[1]:=Path[j+2];
        	Ext[2]:=Path[j+3];
        	Ext[3]:=#0;
	end else Ext[0]:=#0;
	j:= i;
	while ((j > 0) and (Path[j] <> '\')) do dec(j);
	if j > 0 then begin
		for i:= 0 to 7 do Name[i]:=Path[j+i+1];
		for i:= 0 to j-1 do Dir[i]:=Path[i];
		Dir[j]:=#0;
	end else begin
		for i:= 0 to 7 do Name[i]:=Path[i];
		Dir[0]:=#0;
	end;
	Name[8]:=#0;
	ToString(@Path[0]);
	ToString(@Dir[0]);
	ToString(@Name[0]);
	ToString(@Ext[0]);
end;

procedure Exec(Path: PathStr; ComLine: ComStr);register;assembler;
var ParBlk: ExecParBlk;
    CmdTail: array[0..127] of char;
asm
   push ebx
   push eax		{ save program name }
   push edx		{ save command tail }
   call ToPchar
   pop  eax             { restore command tail }
   lea edx,CmdTail
   movzx ecx,BYTE PTR [eax]
   inc ecx
@@01:
   mov bl,[eax]
   inc eax
   mov [edx],bl
   inc edx
   loop @@01
   mov WORD PTR [edx], 0Dh
   lea ebx,ParBlk
   lea edx,CmdTail
   mov [ExecParBlk.CmdSelector][ebx],ds
   mov [ExecParBlk.CmdOffset][ebx],edx
   pop edx
   push edx
   mov ah,62h
   int 21h
   push ds
   mov ds,ebx
   mov eax,[2ch]   
   pop ds
   lea ebx,ParBlk
   mov [ExecParBlk.EnvSelector][ebx],ax
   mov [ExecParBlk.EnvOffset][ebx],0
   mov eax,4b00h
   int 21h
   jc  @@00
   sub eax,eax
@@00:
   mov DOSError,eax
   pop  eax
   call ToString
   pop ebx
end;

function EnvCount: integer;
begin
   EnvCount:=Ecount;
end;

function EnvStr(Index: integer): String;
var p:Pchar;
    i,j:longint;
    k:byte;
begin
   Index:=Index - 1;
   if ((Index < EnvCount) and (Index > -1)) then begin
     p:=GetEnvStr;
     i:=0;
     if Index > 0 then for j:=0 to Index-1 do begin
       while p[i] <> #0 do i:= i + 1;
       i:=i+1;
     end;
     k:= 0;
     repeat
        EnvStr[k + 1]:= p[i];
        i:= i + 1; k:= k + 1;
     until p[i] = #0;
     EnvStr[0]:=chr(k);
   end;
end;

function GetEnv(EnvVar: String): String;
begin
  ToPchar(EnvVar);
  if ((GetEnvVar(@EnvVar[0],@Result[0], 255 )) > 0) then ToString(@Result[0])
  else Result:='';
  ToString(@EnvVar[0]);
end;


{ ########################################################################## }

initialization

begin

{ Determine EnvCount once }

	asm
	call GetEnvStr
	or  edx,-1
@@EnvLoop:
	cmp  byte ptr [eax],1
	inc  eax
	jnc  @@EnvLoop
	inc  edx
	cmp  byte ptr [eax],0
	jnz  @@EnvLoop
	mov  Ecount,edx
	end;

{ A very small example of cross- platform code :-) }

	if GetProcAddress(GetModuleHandleA('kernel32.dll'),'Borland32') = 0 then begin
           MessageBoxA(0,'Cannot run without WDOSX DOS extender!','Oooops...',0);
           ExitProcess($ff);
        end;

{ We never come here without WDOSX }
        asm
	push	ebx
	push	esi

	mov	esi,offset IntRedir
	sub	ebx, ebx

@@loop:
	mov	WORD PTR [esi+5], 0
	add	esi, 8
	inc	ebx
	test	bh,bh
	je	@@loop

	pop	esi
	pop	ebx
        end;
end;

finalization

asm
	push	ebx
	push	esi
	mov	esi,offset IntRedir
	sub	ebx, ebx
	sub	ecx, ecx

@@loop:
	mov	cx, [esi + 5]
	mov	edx, [esi + 1]
	jecxz	@@ignore

	mov	ax, 0205h
	int	31h

@@ignore:
	add	esi, 8
	inc	ebx
	test	bh, bh
	je	@@loop

	pop	esi
	pop	ebx
        
end;

end.
