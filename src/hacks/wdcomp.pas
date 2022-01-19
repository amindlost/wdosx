{ ############################################################################
  ## WDOSX DOS Extender           Copyright (c) 1996, 2001, Michael Tippach ##
  ##                                                                        ##
  ## Realeased under the terms of the WDOSX license agreement.              ##
  ############################################################################

  $Header: E:/RCS/WDOSX/0.95/SRC/HACKS/wdcomp.pas 1.3 2001/02/22 22:21:34 MikeT Exp MikeT $

  ----------------------------------------------------------------------------

  $Log: wdcomp.pas $
  Revision 1.3  2001/02/22 22:21:34  MikeT
  The kernel is now compressed as one block.

  Revision 1.2  2001/02/22 21:40:50  MikeT
  New revision to support wdosxpack 1.07.

  Revision 1.1  2001/02/22 21:35:01  MikeT
  Initial revision.


  ---------------------------------------------------------------------------}
{
function Lz77Compress(InBuf, OutBuf: PChar; InSize: longint):longint; stdcall; 
external 'lz77.dll' name 'Lz77Compress';
}
function WdosxPack(InBuf, OutBuf: PChar; workmem: pointer; InSize: longint):longint; stdcall; 
external 'wpack.dll' name 'WdosxPack';

type MZHeader = packed record
	Signature, LastParaBytes, NumParas: word;
	filler: array [0..9] of byte;
	StartSP: word;
	filler1: word;
        StartIP: word;
end;


var huf1: array[0..$10000] of char;
    huf2: array[0..$10000] of char;
    wm: array[0..$20000] of char;
    f:file of byte;
    a, b, p, x, y: longint;
    mz: MZHeader absolute huf1;

begin
   assign(f, paramstr(1));
   reset(f);
   b:=filesize(f);
   blockread(f, huf1, b);
   close(f);

{ add silly checks here }
   mz.StartSP:=b + 5096 + 4096;
   p:= 32 + mz.StartIP;
   y:=p;
   a:= 0;
   b:= b-p;
   x:= b;
   a:= (WdosxPack(@huf1[p], @huf2[a], @wm, b));
{ do nothing if compression would expand the file }
   if a < x then begin
      mz.LastParaBytes:= (y + a) AND 511;
      mz.NumParas:= ((y + a) + 511) SHR 9;
      mz.StartIP:= mz.StartIP - 3;
      rewrite(f);
      blockwrite(f, huf1, y);
      blockwrite(f, huf2, a);
      close(f);
   end;
end.
