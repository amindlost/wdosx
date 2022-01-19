{
##############################################################################
## Test program for the VBE stuff. Requires Delphi2/3 and WDosX 0.95.       ##
##                                                                          ##
## Copyr... err... this one is so stupid that I hereby grant anyone the     ##
## right to sell it to Microsoft.                                           ##
##############################################################################
}

uses graphics, palettes, fbuffers;
Type
   s = array[0..0] of byte;

var
   Xres, Yres: integer;
   Pal26: TPalette2Dot6;
   Pal332: TPalette332;
   Surface: TDDSurface;
   p: ^s;
   px, py: integer;
   r, g, b: integer;
begin

Xres:= 640;
Yres:= 480;

{ Create a drawing surface. }
   Surface:= TDDSurface.Create(Xres, Yres, 8);

   with Screen do begin

{ Set a video mode (fingers crossed as it might not be supported) }
      ScreenMode(Xres, Yres, 8);

{ Create a palette with 2.6 bits per primary color. }
      Pal26:= TPalette2Dot6.Create;
      Pal332:= TPalette332.Create;

{ Make this one the active palette. }
      Palette:= Pal26;

{ Create a test pattern. This is really stupid and slow. }
      p:= Surface.Buffer;
      for px:= 0 to Xres-1 do begin
         for py:= 0 to Yres-1 do begin
            r:= (px * 6) DIV Xres;
            g:= (py * 6) DIV Yres;
            b:= ((px * 36) DIV Xres) MOD 6;
            p^[px + py * Xres]:= r * 36 + g * 6 + b;
         end;
      end;

{ Blit our test pattern to screen. }
      Content:= Surface;


{ Create another stupid test pattern. }
      p:= Surface.Buffer;
      for px:= 0 to Xres-1 do begin
         for py:= 0 to Yres-1 do begin
            r:= (px * 8) DIV Xres;
            g:= (py * 8) DIV Yres;
            b:= ((px * 32) DIV Xres) MOD 4;
            p^[px + py * Xres]:= r * 32 + g * 4 + b;
         end;
      end;

{ Wait for user input. }
      readln;

{ Blit our test pattern to screen. }
      Content:= Surface;

{ Wait for user input. }
      readln;

{ Switch Palette to 3-3-2. }
      Palette:= Pal332;

{ Wait for user input. }
      readln;

   end; { with }

end.
