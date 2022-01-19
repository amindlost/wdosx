{
##############################################################################
## Main graphics interface for              Delphi2/3 and WDosX 0.95.       ##
##                                                                          ##
## This one mainly provides static instances of vbe related classes.        ##
##                                                                          ##
##############################################################################
}
unit graphics;

interface
uses vbe;

const
   Screen: TVbeInterface = NIL;

implementation

initialization
   Screen:= TVbeInterface.Create;

finalization
   Screen.Destroy;

end.
