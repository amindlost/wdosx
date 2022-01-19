{
 ############################################################################# 
 ## VBE style palette definitions for 8 bpp modes.                          ##
 ##                                                                         ##
 ## Copyright (c)1998, Michael Tippach                                      ##
 ## Released under the terms of the WDosX 0.95 licence agreement            ##
 #############################################################################

 2DO: Add decent gamma support, the current gamma is crap which is why it
      isn't used at all.
}
unit palettes;

interface

Type

   TRGB8 = packed record
      Blue, Green, Red, Alignment: byte;
   end;

   TPalette = class(TObject)

   public
      Palette: array[byte] of TRGB8;
   end;


   TPalette2Dot6 = class(TPalette)

   public
      Constructor Create;
   end;

   TPalette332 = class(TPalette)

   public
      Constructor Create;
   end;


implementation

Const
   Gamma64: array[0..63] of byte = (
    0, 10, 14, 17, 19, 21, 23, 24, 26, 27, 28, 29, 31, 32, 33, 34,
   35, 36, 37, 37, 38, 39, 40, 41, 41, 42, 43, 44, 44, 45, 46, 46,
   47, 48, 48, 49, 49, 50, 51, 51, 52, 52, 53, 53, 54, 54, 55, 55,
   56, 56, 57, 57, 58, 58, 59, 59, 60, 60, 61, 61, 62, 62, 63, 63 );

   NoGamma64: array[0..63] of byte = (
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
   16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
   32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
   48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63 );

   Constructor TPalette2Dot6.Create;
   var r, g ,b: integer;
   begin
      for r:= 0 to 5 do for g:= 0 to 5 do for b:= 0 to 5 do begin
         Palette[((r * 6) + g) * 6 + b].Red:= NoGamma64[(r * 63) DIV 5];
         Palette[((r * 6) + g) * 6 + b].Green:= NoGamma64[(g * 63) DIV 5]; 
         Palette[((r * 6) + g) * 6 + b].Blue:=  NoGamma64[(b * 63) DIV 5];
      end;
      for g:= 216 to 255 do begin
         Palette[g].Red:= NoGamma64[((g - 216) * 63) DIV (255 - 216)];
         Palette[g].Green:= Palette[g].Red;
         Palette[g].Blue:= Palette[g].Red;
      end;
   end;

   Constructor TPalette332.Create;
   var i: integer;
   begin
      for i:= 0 to 255 do begin
         Palette[i].Red:= NoGamma64[((i SHR 5) * 63) DIV 7];
         Palette[i].Green:= NoGamma64[(((i SHR 2) AND 7) * 63) DIV 7];
         Palette[i].Blue:= NoGamma64[((i AND 3) * 63) DIV 3];
      end;
   end;

end.
