{
 ############################################################################# 
 ## Object oriented DPMI interface for Delphi 2/3 and WDosX 0.94 or better  ##
 ##                                                                         ##
 ## Copyright (c)1998, Michael Tippach                                      ##
 ## Released under the terms of the WDosX 0.95 license agreement            ##
 #############################################################################
}

unit OOdpmi;

interface
uses sysutils;

type

{$ifndef Registers}

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
{$endif}

   EDpmiError = class (Exception);

   TDescriptorType = (Code, Data);

   TDpmiDescriptor = Class (TObject)

      private
         DSelector: longint;
         function GetBase:longint;
         procedure SetBase(base: longint);
         function GetLimit:longint;
         procedure SetLimit(limit: longint);
         procedure SetType(Dtype: TDescriptorType);
         function GetType:TDescriptorType;

      public
         Constructor Create(DBase: longint; DLimit: longint; DAcc: TDescriptorType);
         Constructor CreateAliasOf(sel: longint);
         Destructor Destroy;
         property Base:longint read GetBase write SetBase;
         property Limit:longint read GetLimit write SetLimit;
         property TypeField:TDescriptorType read GetType write SetType;
         property Selector:longint read DSelector;

   end;


   TDosMemoryBlock = class (TObject)

      private
         DSelector: longint;
         DSize: longint;
         DAddress: longint;
         procedure Resize(sz: longint);

      public
         Constructor Create (MSize: longint);
         Destructor Destroy;
         property BlockSize: longint read DSize write Resize;
         property LinearAddress: longint read DAddress;
         property Selector: longint read DSelector;

   end;


   TAddressMapping = class (TObject)

      private
         DAddress: longint;
         DSize: longint;

      public
         Constructor Create(MBase: longint; MSize: longint);
         Destructor Destroy;
         property LinearAddress: longint read DAddress;

   end;

procedure SimulateInterrupt(IntNum: byte; var regs: registers);

implementation

procedure SimulateInterrupt(IntNum: byte; var regs: registers);
var error: boolean;
begin
   error:= false;
   regs.ss:= 0;
   regs.sp:= 0;
   regs.flags:= 0;
   asm
      push ebx
      push edi
      mov  bl, IntNum
      mov  ax, 300h
      sub  ecx, ecx
      mov  edi, regs
      int  31h
      pop  edi
      pop  ebx
      setc BYTE PTR error
   end;
   if error then raise EDpmiError.Create('Error during DPMI function $300');
end;


function Lar(sel: longint):longint;register;assembler;
asm
   lar eax, eax
end;

function Lsl(sel: longint):longint;register;assembler;
asm
   lsl eax, eax
end;

Constructor TDpmiDescriptor.Create(DBase: longint; DLimit: longint; DAcc: TDescriptorType);
var error: boolean;
begin
   error:=false;
   asm
      mov  ecx, 1
      sub  eax, eax
      int  31h
      jnc  @@00
      mov  error, true
@@00:
      mov  ecx, self
      mov  [ecx][TDpmiDescriptor.DSelector], eax
   end;
   if error then raise EDpmiError.Create('Could not allocate descriptor');
   Base:=DBase;
   Limit:=DLimit;
   TypeField:=Dacc;
end;

Constructor TDpmiDescriptor.CreateAliasOf(sel: longint);
var error: boolean;
begin
   error:=false;
   asm
      push  ebx
      mov  ebx, sel
      mov  ecx, 1
      mov  eax, 0Ah
      int  31h
      jnc  @@00
      mov  error, true
@@00:
      mov  ecx, self
      mov  [ecx][TDpmiDescriptor.DSelector], eax
      pop  ebx
   end;
   if error then raise EDpmiError.Create('Could not create descriptor');
end;

Destructor TDpmiDescriptor.Destroy;
var error: boolean;
begin
   error:= false;
   asm
      mov  ecx, self
      push ebx
      mov  ebx, [ecx][TDpmiDescriptor.DSelector]
      mov  eax, 1
      int  31h
      pop  ebx
      jnc  @@00
      mov  error, true
@@00:
   end;
   if error then raise EDpmiError.Create('Could not free descriptor');
end;

function TDpmiDescriptor.GetBase:longint;
var error: boolean;
begin
   error:= false;
   asm
      mov  edx, self
      push ebx
      mov  ebx, [edx][TDpmiDescriptor.DSelector]
      mov  eax, 6
      int  31h
      jnc  @@00
      mov  error, true
@@00:
      shl  ecx, 16
      mov  cx, dx
      mov  result, ecx
      pop  ebx
   end;
   if error then raise EDpmiError.Create('Could not read descriptor base');
end;

procedure TDpmiDescriptor.SetBase(base: longint);
var error: boolean;
begin
   error:= false;
   asm
      mov  edx, self
      push ebx
      mov  ebx, [edx][TDpmiDescriptor.DSelector]
      mov  edx, base
      shld ecx, edx, 16
      mov  eax, 7
      int  31h
      jnc  @@00
      mov  error, true
@@00:
      pop  ebx
   end;
   if error then raise EDpmiError.Create('Could not set descriptor base');
end;

function TDpmiDescriptor.GetLimit:longint;
begin
   GetLimit:=Lsl(DSelector);
end;

procedure TDpmiDescriptor.SetLimit(limit: longint);
var error: boolean;
begin
   error:= false;
   asm
      mov  edx, self
      push ebx
      mov  ebx, [edx][TDpmiDescriptor.DSelector]
      mov  edx, limit
      shld ecx, edx, 16
      mov  eax, 8
      int  31h
      jnc  @@00
      mov  error, true
@@00:
      pop  ebx
   end;
   if error then raise EDpmiError.Create('Could not set descriptor limit');
end;

procedure TDpmiDescriptor.SetType(Dtype: TDescriptorType);
var tacc: word;
    error: boolean;
begin
   error := false;
   tacc := (Lar(DSelector) shr 8);
   if DType = Code then tacc:=tacc or 8 else tacc:= tacc and $fff7;
   asm
      mov  edx, self
      mov  cx, tacc
      push ebx
      mov  ebx, [edx][TDpmiDescriptor.DSelector]
      mov  eax, 9
      int  31h
      jnc  @@00
      mov  error, true
@@00:
      pop  ebx
   end;
   if error then raise EDpmiError.Create('Could not set descriptor type');
end;

function TDpmiDescriptor.GetType:TDescriptorType;
begin
   if (Lar(DSelector) and $800) > 0 then GetType:=Code else GetType:=Data;
end;

Constructor TDosMemoryBlock.Create(MSize: longint);
var error: boolean;
begin
   error:=false;
   asm
      push ebx
      push edx
      mov  ebx, MSize
      add  ebx, 15
      and  ebx, $FFFF0
      mov  ecx, self
      mov  [ecx][TDosMemoryBlock.DSize], ebx
      shr  ebx, 4
      mov  eax, 100h
      int  31h
      jnc  @@00
      mov  error, true
@@00:
      shl  eax, 4
      mov  [ecx][TDosMemoryBlock.DSelector], edx
      mov  [ecx][TDosMemoryBlock.DAddress], eax
      pop  edx
      pop  ebx
   end;
   if error then raise EDpmiError.Create('Could not allocate DOS Memory');
end;

Destructor TDosMemoryBlock.Destroy;
var error: boolean;
begin
   error:=false;
   asm
      push edx
      mov  edx, self
      mov  edx, [edx][TDosMemoryBlock.DSelector]
      mov  eax, 101h
      int  31h
      jnc  @@00
      mov  error, true
@@00:
      pop  edx
   end;
   if error then raise EDpmiError.Create('Could not free DOS Memory');
end;

procedure TDosMemoryBlock.Resize(sz: longint);
var error: boolean;
begin
   error:=false;
   asm
      push ebx
      mov  ebx, sz
      add  ebx, 15
      shr  ebx, 4
      mov  eax, 102h
      int  31h
      jnc  @@00
      mov  error, true
      jmp  @@01
@@00:
      shl  ebx, 4
      mov  ecx, self
      mov  [ecx][TDosMemoryBlock.DSize], ebx
@@01:
      pop  ebx
   end;
   if error then raise EDpmiError.Create('Could not resize DOS Memory');
end;

Constructor TAddressMapping.Create(MBase: longint; MSize: longint);
var error: boolean;
begin
   error:= false;
   asm
      push ebx
      push esi
      push edi
      mov  ecx, Mbase
      shld ebx, ecx, 16
      mov  edi, MSize
      shld esi, edi, 16
      mov  eax, 800h
      int  31h
      jnc  @@00
      mov  error, true
@@00:
      shl  ecx, 16
      shld ebx, ecx, 16
      mov  ecx, self
      mov  [ecx][TAddressMapping.DAddress], ebx
      mov  [ecx][TAddressMapping.DSize], edi
      pop  edi
      pop  esi
      pop  ebx
   end;
   if error then raise EDpmiError.Create('Could not create address mapping');
end;

Destructor TAddressMapping.Destroy;
var error: boolean;
begin
   asm
      push ebx
      mov  ecx, self
      mov  ecx, [ecx][TAddressMapping.DAddress]
      shld ebx, ecx, 16
      mov  eax, 801h
      int  31h
      jnc  @@00

      mov  error, true
@@00:
      pop  ebx
   end;
{
   For 801 is a DPMI 1.0 function, it may be unsupported by some environments.
   However, up to a certain limit, your application may work in these too.
   Anyway, we would need to insert this line in order to be consistent all
   over the unit:

   if error then raise EDpmiError.Create('Could not free address mapping');
}
end;

end.
