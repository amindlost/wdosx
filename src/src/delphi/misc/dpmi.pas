{ Yet another example for a DPMI unit. Not quite complete. }
{ Untested yet. Feel free to use as you see fit! - Wuschel }

unit	dpmi;

interface

const	

	dpmiError = -1;
	dpmiSuccess = 0;

	CPU286 = 2;
	CPU386 = 3;
	CPU486 = 4;
	CPU586 = 5;
	CPU686 = 6;

	dpmi32Bit = 1;
	dpmiDOSRm = 2;
	dpmiVMem = 4;

type

	dpmiRealCallRegs = packed record
          case integer of
	    0: (edi,esi,ebp,espres,ebx,edx,ecx,eax:integer;
                flags,es,ds,fs,gs,ip,cs,sp,ss:word);
            1: (di,diu,si,siu,bp,bpu,spres,spu,bx,bxu,dx,dxu,cx,cxu,ax,axu:word);
	    2: (dil,dih,di2,di3,sil,sih,si2,si3,bpl,bph,bp2,bp3,spl,sph,sp2,sp3,bl,bh,bx2,bx3,dl,dh,dx2,dx3,cl,ch,cx2,cx3,al,ah,ax2,ax3:byte);
        end;

        dpmiSelector = integer;
	dpmiStatus = integer;

	dpmiPMvector = record
          offset:procedure;
	  selector:integer;
	end;

	dpmiInfo = packed record
	  vminor,vmajor:byte;
          flags:word;
          CPUType:byte;
          PIC2Map,PIC1Map:byte;
	end;

{ For selector passing as integers }

	dpmiDescriptor = integer;

var

        dpmiDataSelector,dpmiCodeSelector:word;

	dpmiXam: dpmiInfo;

procedure dpmiGetVersion(var vinfo:dpmiInfo);register;assembler;
function dpmiGetIRQ(inum:integer;var vec:dpmiPMVector):dpmiStatus;register;assembler;
function dpmiSetIRQ(inum:integer;vec:dpmiPMVector):dpmiStatus;register;assembler;
function dpmiAllocDescriptor(var sel:dpmiDescriptor):dpmiStatus;register;assembler;
function dpmiFreeDescriptor(sel: dpmiDescriptor):dpmiStatus;register;assembler;
function dpmiSetSegmentBase(sel: dpmiDescriptor; base: integer):dpmiStatus;register;assembler;
function dpmiGetSegmentBase(sel: dpmiDescriptor; var base: integer):dpmiStatus;register;assembler;
function dpmiSetSegmentLimit(sel: dpmiDescriptor; lim: integer):dpmiStatus;register;assembler;
function dpmiSetAccessRights(sel: dpmiDescriptor; acc: integer):dpmiStatus;register;assembler;
function dpmiCreateCodeAlias(sel: dpmiDescriptor; var asel: integer):dpmiStatus;register;assembler;
function dpmiAllocDOSMem(numpara: integer; var segm: integer; var sel: dpmiDescriptor):dpmiStatus;register;assembler;
function dpmiFreeDOSMem(sel: integer):dpmiStatus;register;assembler;
function dpmiRealModeInt(intnr: integer; var cregs:dpmiRealCallRegs):dpmiStatus;register;assembler;
function dpmiLockMemory(lstart: integer; lsize: integer):dpmiStatus;register;assembler;
function dpmiUnlockMemory(lstart: integer; lsize: integer):dpmiStatus;register;assembler;

implementation

procedure dpmiGetVersion(var vinfo:dpmiInfo);register;assembler;
asm
  push ebx
  push esi
  mov esi,eax
  mov eax,400h
  int 31h
  mov [esi],ax
  mov [esi+2],bx
  mov [esi+4],cl
  mov [esi+5],dx
  pop esi
  pop ebx
end;

function dpmiGetIRQ(inum:integer;var vec:dpmiPMVector):dpmiStatus;register;assembler;
asm
  push ebx
  mov ebx,eax
  cmp ebx,8
  ja @@1
  add bl,byte ptr [offset dpmiXam].PIC1Map
  jmp @@2
@@1:
  cmp ebx,16
  cmc
  jc @@3
  add bl,byte ptr [offset dpmiXam].PIC2Map
@@2:
  push edx
  mov eax,0204h
  int 31h  
  pop eax
  mov [eax],edx
  mov [eax+4],ecx
@@3:
  sbb eax,eax
  pop ebx
end;

function dpmiSetIRQ(inum:integer;vec:dpmiPMVector):dpmiStatus;register;assembler;
asm
  push ebx
  mov ebx,eax
  cmp ebx,8
  ja @@1
  add bl,byte ptr [offset dpmiXam].PIC1Map
  jmp @@2
@@1:
  cmp ebx,16
  cmc
  jc @@3
  add bl,byte ptr [offset dpmiXam].PIC2Map
@@2:
  mov ecx,[edx+4]
  mov edx,[edx]
  mov eax,0205h
  int 31h
@@3:
  sbb eax,eax
  pop ebx
end;

function dpmiAllocDescriptor(var sel:dpmiDescriptor):dpmiStatus;register;assembler;
asm
  mov	ecx,1
  mov	edx,eax
  sub	eax,eax
  int	31h
  mov	[edx],eax
  sbb	eax,eax   
end;

function dpmiFreeDescriptor(sel: dpmiDescriptor):dpmiStatus;register;assembler;
asm
  push	ebx
  mov	ebx,eax
  mov	eax,1
  int	31h
  sbb	eax,eax
  pop	ebx
end;

function dpmiSetSegmentBase(sel: dpmiDescriptor; base: integer):dpmiStatus;register;assembler;
asm
  push	ebx
  mov	ebx,eax
  shld	ecx,edx,16
  mov	eax,7
  int	31h
  sbb	eax,eax
  pop	ebx
end;

function dpmiGetSegmentBase(sel: dpmiDescriptor; var base: integer):dpmiStatus;register;assembler;
asm
  push	ebx
  mov	ebx,eax
  push	edx
  mov	eax,6
  int	31h
  sbb	eax,eax
  shl	edx,16
  shld	ecx,edx,16
  pop	ebx
  mov	[ebx],ecx
  pop	ebx
end;

function dpmiSetSegmentLimit(sel: dpmiDescriptor; lim: integer):dpmiStatus;register;assembler;
asm
  push	ebx
  mov	ebx,eax
  shld	ecx,edx,16
  mov	eax,8
  int	31h
  sbb	eax,eax
  pop	ebx
end;

function dpmiSetAccessRights(sel: dpmiDescriptor; acc: integer):dpmiStatus;register;assembler;
asm
  push	ebx
  mov	ebx,eax
  mov	eax,9
  mov	ecx,edx
  int	31h
  sbb	eax,eax
  pop	ebx
end;

function dpmiCreateCodeAlias(sel: dpmiDescriptor; var asel: integer):dpmiStatus;register;assembler;
asm
  push	ebx
  mov	ebx,eax
  mov	eax,10
  int	31h
  mov	[edx],eax
  sbb	eax,eax
  pop	ebx
end;

function dpmiAllocDOSMem(numpara: integer; var segm: integer; var sel: dpmiDescriptor):dpmiStatus;register;assembler;
asm
  push	ebx
  mov	ebx,eax
  mov	eax,100h
  push	edx
  int	31h
  pop	ebx
  mov	[ebx],eax
  mov	[ecx],edx
  sbb	eax,eax
  pop	ebx
end;

function dpmiFreeDOSMem(sel: integer):dpmiStatus;register;assembler;
asm
  mov	edx,eax
  mov	eax,101h
  int	31h
  sbb	eax,eax
end;

function dpmiRealModeInt(intnr: integer; var cregs:dpmiRealCallRegs):dpmiStatus;register;assembler;
asm
  push	ebx
  push	edi
  mov	ebx,eax
  mov	edi,edx
  mov	eax,300h
  int	31h
  sbb	eax,eax
  pop	edi
  pop	ebx
end;

function dpmiLockMemory(lstart: integer; lsize: integer):dpmiStatus;register;assembler;
asm
  push	ebx
  push	esi
  push  edi
  mov	ecx,eax
  shld	ebx,eax,16
  mov	edi,edx
  shld	esi,edx,16
  mov	eax,600h
  int	31h
  sbb	eax,eax
  pop	edi
  pop	esi
  pop	ebx
end;

function dpmiUnlockMemory(lstart: integer; lsize: integer):dpmiStatus;register;assembler;
asm
  push	ebx
  push	esi
  push  edi
  mov	ecx,eax
  shld	ebx,eax,16
  mov	edi,edx
  shld	esi,edx,16
  mov	eax,601h
  int	31h
  sbb	eax,eax
  pop	edi
  pop	esi
  pop	ebx
end;

begin
  dpmiGetVersion(dpmiXam);
  asm
    mov dpmiDataSelector,ds
    mov dpmiCodeSelector,cs
  end;
end.
