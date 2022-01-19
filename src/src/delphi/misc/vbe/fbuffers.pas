{
 ############################################################################# 
 ## Offscreen drawing surface.                                              ##
 ##                                                                         ##
 ## Copyright (c)1998, Michael Tippach                                      ##
 ## Released under the terms of the WDosX 0.95 license agreement            ##
 #############################################################################

 The idea with this one is that we add a set of very neat methodes to allow
 drawing of primitives as well as rendering of polygons as well as...

}

unit fbuffers;

interface
uses sysutils;

Type

   EDDError = class(Exception);

   TDDSurface = class(TObject)

   private
      MemBlock: pointer;
      SizeX, SizeY: longint;
      BPPix: longint;

   public
      Constructor Create(X, Y, bpp: longint);
      Destructor Destroy;
      property Buffer: pointer read MemBlock;
      property XSize: longint read SizeX;
      property YSize: longint read SizeY;
      property BitsPerPixel: longint read BPPix;
   end;

implementation

Constructor TDDSurface.Create(X, Y, bpp: longint);
begin
   SizeX:= X;
   SizeY:= Y;
   BPPix:= bpp;
   GetMem(MemBlock, X * Y * ((bpp + 7) SHR 3));
   if MemBlock = NIL then
      raise EDDError.Create('Not enough memory for off screen buffer.');
end;

Destructor TDDSurface.Destroy;
begin
   if MemBlock <> NIL then FreeMem(MemBlock);
end;

end.
