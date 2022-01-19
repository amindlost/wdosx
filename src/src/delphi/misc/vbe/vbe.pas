{ 
  ############################################################################
  ## VBE interface unit for Delphi2/3 and WDosX 0.95                        ##
  ##                                                                        ##
  ## Copyright (c)1998, Michael Tippach                                     ##
  ## Released under the terms of the WDosX 0.95 license agreement.          ##
  ############################################################################

  Obviously this one is unfinished.
}
unit vbe;

interface
uses sysutils, oodpmi, palettes, fbuffers;

type

   EVbeError = class(Exception);

   TRgb24 = packed record
      Blue, Green, Red: byte;
   end;

   TRgb32 = packed record
      Blue, Green, Red, Alpha: byte;
   end;

   TRealModePtr = packed record
      Offset, Segment:    word;
   end;

   TScreenBuffer8B  = array [0..0] of byte;
   TScreenBuffer16B = array [0..0] of word;
   TScreenBuffer24B = array [0..0] of TRgb24;
   TScreenBuffer32B = array [0..0] of TRgb32;

   TModeList   = array [word] of word;
   PModeList   = ^TModeList;

   TLfbPointer = record
   case integer of
      0: (TLfb8bitPtr:     ^TScreenBuffer8B;);
      1: (TLfb16bitPtr:    ^TScreenBuffer16B;);
      2: (Tlfb24bitPtr:    ^TScreenBuffer24B;);
      3: (Tlfb32bitPtr:    ^TScreenBuffer32B;);
   end;

   TVbeInfo = packed record

      VbeSignature:       longint;
      VbeMinorVersion:    byte;
      VbeMajorVersion:    byte;

      case integer of
         0: (
            OemStringRmPtr:  TRealModePtr;
            Capabilities:    longint;
            ModeListRmPtr:   TRealModePtr;
            TotalMemory:     word;
            OemSoftwareRev:  word;
            OemVendorNameRmPtr,
            OemProductNameRmPtr,
            OemProductRevRmPtr: TRealModePtr;
            Reserved:        array [0..221] of byte;
            OemData:         array [0..255] of byte;
            );

         1: (
            OemStringPtr:    Pchar;
            Capabilities_:   longint;
            ModeListPtr:     PModeList;
            TotalMemory_:    word;
            OemSoftwareRev_: word;
            OemVendorNamePtr,
            OemProductNamePtr,
            OemProductRevPtr:   Pchar;
            Reserved_:        array [0..221] of byte;
            OemData_:         array [0..255] of byte;
            );
   end;

   TVbeModeInfo = packed record

      ModeAttributes:     word;
      WinAAttributes:     byte;
      WinBAttributes:     byte;
      WinGranularity:     word;
      WinSize:            word;
      WinASegment:        word;
      WinBSegment:        word;
      WinFuncPtr:         TRealModePtr;
      BytesPerScanLine:   word;
      SizeX:              word;
      SizeY:              word;
      CharSizeX:          byte;
      CharSizeY:          byte;
      NumberOfPlanes:     byte;
      BitsPerPixel:       byte;
      NumberOfBanks:      byte;
      MemoryModel:        byte;
      BankSize:           byte;
      NumberOfImagePages: byte;
      Reserved1:          byte;
      RedMaskSize:        byte;
      RedFieldPosition:   byte;
      GreenMaskSize:      byte;
      GreenFieldPosition: byte;
      BlueMaskSize:       byte;
      BlueFieldPosition:  byte;
      RsvdMaskSize:       byte;
      RsvdFieldPosition:  byte;
      DirectColorInfo:    byte;
      LfbPtr:             TLfbPointer;
      OffScreenMemOffset: pointer;
      OffScreenMemSize:   word;
      Reserved2:          Array [0..205] of Byte;

   end;

   TVbePmi = packed record
      SetWindowOffset:    word; { fn 5 }
      SetDispStartOffset: word; { fn 7 }
      SetPrimaryPalette:  word; { fn 9 }
      PortMemArrayOffset: word;
      PmCode:             array [word] of byte;
   end;

   PVbeInfo = ^TVbeInfo;
   PVbeModeInfo = ^TVbeModeInfo;
   PVbePmi = ^TVbePmi;

   TVbeInterface = class(TObject)

      private
         OldMode: word;
         CurrentMode: word;
         CurrentX: longint;
         CurrentY: longint;
         CurrentBPP: longint;
         CurrentPalette: TPalette;
         CurrentBank: integer;
         ScreenBuffer: pointer;
         WindowSize: longint;
         NumBlocks: longint;
         BlockSize: longint;
         BankIncrement: longint;
         VbeInfo: PVbeInfo;
         ModeInfo: PVbeModeInfo;
         PmiBankSwitcher: pointer;
         PmiSetDisplayStart: pointer;
         PmiSetPalette: pointer;
         DosMemoryBlock: TDosMemoryBlock;
         AddressMapping: TAddressMapping;
         procedure SetBank(bank: integer);
         function  GetVMode:word;
         procedure SetVMode(mode: word);
         procedure GetVbeInfo;
         function GetModeInfo(mode: word): PVbeModeInfo;
         function GetVendorString: string;
         function GetMajorVersion: integer;
         function GetMinorVersion: integer;
         procedure SetPalette(const pal: TPalette);
         procedure InitPmi;
         function FindMode(x, y, bpp: longint): word;
         procedure SetContent(src: TDDSurface);

      public
         WaitRetrace: boolean;
         Constructor Create;
         Destructor Destroy;
         procedure ScreenMode(X, Y, bpp: longint);
         property VesaMode: word read GetVMode write SetVMode;
         property VbeModeInfo [mode: word]: PVbeModeInfo read GetModeInfo;
         property VendorString: string read GetVendorString;
         property MajorVersion: integer read GetMajorVersion;
         property MinorVersion: integer read GetMinorVersion;
         property Palette: TPalette read CurrentPalette write SetPalette;
         property Content: TDDSurface write SetContent;

   end;

implementation

const 
      vbesigstr: array [0..3] of char = 'VESA';

var
      vbesig: longint absolute vbesigstr;

procedure WaitVRT; assembler;
asm
  mov  edx, 3DAh

@@1:
  in   al, dx
  test al, 8
  jnz  @@1

@@2:
  in   al, dx
  test al, 8
  jz   @@2
end;

function LinearPointer(SegOfs: TRealModePtr):pointer;
begin
   LinearPointer:= pointer((longint(SegOfs.Segment) SHL 4) + SegOfs.Offset);
end;

procedure TVbeInterface.SetContent(src: TDDSurface);
var 
    sPtr, dPtr: pointer;
    tSize: longint;
    bi, i: integer;
    sz: longint;
begin
   if (src.XSize = CurrentX) and (src.YSize = CurrentY)
      and (src.BitsPerPixel = CurrentBPP) then begin
      bi:= 0;
      sPtr:= src.Buffer;
      sz:= CurrentX * CurrentY * ((CurrentBPP + 7) SHR 3);
      if WaitRetrace then WaitVRT;
      for i:= 0 to numBlocks - 1 do begin
      dPtr:= ScreenBuffer;
         SetBank(bi);
         bi:= bi + BankIncrement;
         if sz > blockSize then tSize:= blockSize else tSize:= sz;
         sz:= sz - blockSize;
         asm
            cld
            mov  ecx, tSize
            push edi
            push esi
            mov  esi, sPtr
            mov  edi, dPtr
            shr  ecx, 2
            rep  movsd
            mov  sPtr, esi
            pop  esi
            pop  edi
         end;
      end;
   end else
     raise EVbeError.Create('Attempt to BLT with different buffer dimensions');
end;


function TVbeInterface.FindMode(X, Y, bpp: longint): word;
var i: integer;
    list: PModeList;
    haveLfb: boolean;
begin
   haveLfb:= false;
   result:= $FFFF;
   i:= 0;
   list:= VbeInfo^.ModeListPtr;
   with ModeInfo^ do begin
      while (list^[i] <> $FFFF) and (result = $FFFF) do begin
         GetModeInfo(list^[i] AND $FFF);
         if (SizeX = X) and (SizeY = Y) and (BitsPerPixel = bpp)
            and ((ModeAttributes AND 3) = 3) then begin
            result:= list^[i];
            if MajorVersion > 1 then begin
               haveLfb := (ModeAttributes AND $83) = $83;
               while (list^[i+1] <> $FFFF) and (not(haveLfb)) do begin
                  GetModeInfo(list^[i+1] AND $FFF);
                  if (SizeX = X) and (SizeY = Y) and (BitsPerPixel = bpp)
                     then begin
                     haveLfb := (ModeAttributes AND $83) = $83;
                     if haveLfb then result:= list^[i+1];
                  end;
                  i:= i + 1;
               end;
            end;
         end;
         i:= i + 1;
      end;
   end;
   if (result = 0) and (X = 320) and (Y = 200) and (bpp = 8) then result:= $13;
end;

procedure TVbeInterface.ScreenMode(X, Y, bpp: longint);
var m: word;
begin
   m:= FindMode(X, Y, bpp);
   if m = $FFFF then
      raise EVbeError.Create('Requested video mode not supported.')
   else VesaMode:= m;
end;

procedure TVbeInterface.SetPalette(const pal: TPalette);
begin
   CurrentPalette:= Palette;
   if (pal <> NIL) and ((CurrentBPP = 8) OR (CurrentMode = $13)) then begin
      if PmiSetPalette <> NIL then begin
         asm
            push  ebx
            push  edi
            mov   edi, pal
            mov   eax, self
            add   edi, OFFSET TPalette.Palette
            sub   ebx, ebx
            cmp   BYTE PTR [eax][TVbeInterface.WaitRetrace], 0
            jz    @@1

            mov   bl, 80h

         @@1:
            sub   edx, edx
            mov   ecx, 256
            call  [eax][TVbeInterface.PmiSetPalette]
            pop   edi
            pop   ebx
         end;
      end else begin
         if WaitRetrace then WaitVRT;
         asm
            mov   edx, 3C8h
            mov   ecx, pal
            sub   eax, eax
            add   ecx, OFFSET TPalette.Palette
            out   dx, al
            inc   edx

         @@Palloop:
            mov   al, [ecx + 2]
            out   dx, al
            mov   al, [ecx + 1]
            out   dx, al
            mov   al, [ecx]
            out   dx, al
            add   ecx, 4
            inc   ah
            jnz   @@Palloop
         end;
      end;
   end;
end;

procedure TVbeInterface.SetBank(bank: integer); register; assembler;
asm
   cmp   [eax][TVbeInterface.CurrentBank], edx
   je    @@done

   mov   [eax][TVbeInterface.CurrentBank], edx
   mov   ecx, [eax][TVbeInterface.PmiBankSwitcher]

{
   A well behaved implementation would not destroy esi and ebp as the VBE 2
   standard says that it must not.
}
   push  edi
   push  ebx
   mov   eax, 4F05h
   sub   ebx, ebx
   test  ecx, ecx
   je    @@UseInt

   push  OFFSET @@Return
   jmp   ecx

@@UseInt:
   int   10h

@@Return:
   pop   ebx
   pop   edi
@@done:
end;

procedure TVbeInterface.InitPmi;
var  Pmi:   PVbePmi;
     regs:  registers;
begin
   Pmi:= NIL;
   PmiBankSwitcher:= NIL;
   PmiSetDisplayStart:= NIL;
   PmiSetPalette:= NIL;
   if MajorVersion > 1 then begin
      regs.ax:= $4F0A;
      regs.bl:= 0;
      try
         SimulateInterrupt($10, regs);
         if regs.ax = $4F then begin
            Pmi:= pointer((longint(regs.es) SHL 4) + regs.di);
            PmiBankSwitcher:= @(Pmi^.PmCode[Pmi^.SetWindowOffset - 8]);
            PmiSetDisplayStart:= @(Pmi^.PmCode[Pmi^.SetDispStartOffset - 8]);
            PmiSetPalette:= @(Pmi^.PmCode[Pmi^.SetPrimaryPalette - 8]);
         end;
      except
      end;
   end;
end;

procedure TVbeInterface.GetVbeInfo;
var regs: registers;
begin
   regs.es:= DosMemoryBlock.LinearAddress SHR 4;
   regs.di:= 0;
   regs.ax:= $4F00;
   SimulateInterrupt($10, regs);
   if (regs.ax <> $4F) or (VbeInfo^.VbeSignature <> vbesig) then
       raise EVbeError.Create('VESA compatible video BIOS not found.');
   with VbeInfo^ do begin
       OemVendorNamePtr:= LinearPointer(OemVendorNameRmPtr);
       OemProductNamePtr:= LinearPointer(OemProductNameRmPtr);
       OemProductRevPtr:= LinearPointer(OemProductRevRmPtr);
       OemStringPtr:= LinearPointer(OemStringRmPtr);
       ModeListPtr:= LinearPointer(ModeListRmPtr);
   end;
end;

function TVbeInterface.GetModeInfo(mode: word): PVbeModeInfo;
var regs: registers;
begin
   regs.es:= DosMemoryBlock.LinearAddress SHR 4;
   regs.di:= 512;
   regs.cx:= mode AND $FFF;
   regs.ax:= $4F01;
   SimulateInterrupt($10, regs);
   if (regs.ax <> $4F) then
       raise EVbeError.Create('Error returned from GetModeInfo().');
   GetModeInfo:= ModeInfo;
end;

function TVbeInterface.GetVendorString: string;
begin
   if VbeInfo^.OemStringPtr <> NIL then result:= string(VbeInfo^.OemStringPtr)
   else result:= '';
end;

function TVbeInterface.GetMajorVersion: integer;
begin
   GetMajorVersion:= VbeInfo^.VbeMajorVersion;
end;

function TVbeInterface.GetMinorVersion: integer;
begin
   GetMinorVersion:= VbeInfo^.VbeMinorVersion;
end;

function  TVbeInterface.GetVMode: word; register; assembler;
asm
   push  eax
   push  ebx
   sub   ebx, ebx
   mov   ax, 04F03h
   int   10h
   cmp   ax, 4Fh
   jnz   @@ModeInBx

@@TryVga:
   mov   ah, 0Fh
   int   10h
   movzx ebx, al
   and   bl, 7Fh

@@ModeInBx:
   mov   eax, ebx
   and   ah, 7Fh
   pop   ebx
   pop   edx
   mov   [edx][TVbeInterface.CurrentMode], ax
end;

function SetModeVbe(mode: word):boolean; register; assembler;
asm
   push  ebx
   mov   ebx, eax
   sub   edx, edx
   mov   ax, 4F02h
   int   10h
   xchg  eax, edx
   cmp   dx, 4Fh
   sete  al
   pop   ebx
end;

procedure SetModeVga(mode: word); register; assembler;
asm
   sub  ah, ah
   int  10h
end;

procedure TVbeInterface.SetVMode(mode: word);
var error: boolean;
begin
   error:= true;
   if AddressMapping <> NIL then AddressMapping.Destroy;
   AddressMapping:= NIL;
   if mode AND $F7F < $14 then begin
      SetModeVga(mode);
      CurrentMode:= mode;
      CurrentBank:= 0;
      if (mode AND $1F) = $13 then begin
         CurrentX:= 320;
         CurrentY:= 200;
         CurrentBPP:= 8;
         ScreenBuffer:= pointer($A0000);
         WindowSize:= 64000;
         blockSize:= WindowSize;
         numBlocks:= 1;
         Palette:= CurrentPalette;
      end;
   end else begin
      GetModeInfo(mode AND $FFF);
      with ModeInfo^ do begin
         if (MajorVersion > 1) and ((ModeAttributes AND $83) = $83) then begin
            try 
               AddressMapping:= TAddressMapping.Create (
                                   longint(LfbPtr),
                                   longint(SizeX) * 
                                   longint(SizeY) *
                                   longint((BitsPerPixel + 7) DIV 8)
                                );
               error:= not (SetModeVbe(mode OR $4000));
               if not error then begin
                  CurrentMode:= mode OR $4000;
                  ScreenBuffer:= pointer(AddressMapping.LinearAddress);
                  WindowSize:= SizeX * SizeY * ((BitsPerPixel + 7) SHR 3);
                  blockSize:= WindowSize;
               end;
            except
               if AddressMapping <> NIL then AddressMapping.Destroy;
               AddressMapping:= NIL;
            end; { try }
         end; { if }
         if error and ((ModeAttributes AND $43) = 3) then begin
            error:= not (SetModeVbe(mode AND $FFF));
            if not error then begin
               CurrentMode:= mode AND $FFF;
               ScreenBuffer:= pointer(longint(WinASegment) SHL 4);
               WindowSize:= longint(WinSize) SHL 10;
               blockSize:= WindowSize - (WindowSize MOD (longint(WinGranularity) SHL 10));
               BankIncrement:= blockSize DIV (longint(WinGranularity) SHL 10);
               CurrentBank:= -1; { This fixes some older BIOSes that would }
               SetBank(0);       { start with a non zero offset.           }
            end;
         end; { if }
      end; { with }
      if error then raise EVbeError.Create('Could not set video mode.')
      else begin
         CurrentBank:= 0;
         CurrentX:= ModeInfo^.SizeX;
         CurrentY:= ModeInfo^.SizeY;
         CurrentBPP:= ModeInfo^.BitsPerPixel;
         Palette:= CurrentPalette;
         numBlocks:= CurrentX * CurrentY * ((CurrentBPP + 7) SHR 3) 
            DIV blockSize;
         if ((CurrentX * CurrentY * ((CurrentBPP + 7) SHR 3)) MOD blockSize)
            > 0 then numBlocks:= numBlocks + 1;
      end;
   end; { vbe }
end;

Constructor TVbeInterface.Create;
begin
   WaitRetrace:= TRUE;
   DosMemoryBlock:= TDosMemoryBlock.Create(768);
   VbeInfo:= pointer(DosMemoryBlock.LinearAddress);
   ModeInfo:= pointer(DosMemoryBlock.LinearAddress+512);
   FillChar(VbeInfo^, 768, #0);
   AddressMapping:= NIL;
   CurrentPalette:= NIL;
   GetVbeInfo;
   OldMode:= VesaMode;
   InitPmi;
end;

Destructor TVbeInterface.Destroy;
begin
   VesaMode:= OldMode;
   if DosMemoryBlock <> NIL then DosMemoryBlock.Destroy;
   if AddressMapping <> NIL then AddressMapping.Destroy;
end;

initialization

finalization

end.
