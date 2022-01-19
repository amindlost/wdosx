unit keyboard;
{
  Keyboard handler example. Get the actual key state by hooking the keyboard
  interrupt. Useful for games etc. The 32 bit DOS unit is needed for compiling.
  Just standard TP stuff, except that now we can do this in Delphi 2 too!
  Note that it doesn't need a single line of assembly anymore...

  usage:
  ------------------------ 8< -----------------------

  uses keyboard;
  begin
     SetKeyboardHandler;
     repeat until IsKeyDown(Key_ESC);
     RemoveKeyboardHandler;
  end.

  ------------------------ 8< -----------------------

  Mainly to show what the DOS unit can do for you as far as IRQ handlers are
  concerned.

}

interface

const

  Key_ESC = 1;

  { Add more scancodes here, if you like }

procedure SetKeyboardHandler;
procedure RemoveKeyboardHandler;
function IsKeyDown(key: byte):boolean;

implementation
uses dos;

var 

    Keys: array [0..127] of byte;
    hooked:boolean;
    keybh:pointer;

procedure ISR;  { "Interrupt" keyword not supported in D 2 }
var key:byte;
begin
  key:=port[$60];
  if key <> $E0 then begin
    if key > 127 then Keys[key and 127]:=0 else Keys[key]:=1;
  end;
  port[$61]:=port[$61] or $80;
  port[$61]:=port[$61] and $7F;
  port[$20]:=$20;
end;

procedure ClearAllKeys;
var i:byte;
begin
  for i:=0 to 127 do Keys[i]:=0;
end;

procedure SetKeyboardHandler;
begin
  ClearAllKeys;
  if not hooked then begin
    hooked:=true;
    GetIntVec($9,keybh);
    SetIntVec($9,@ISR);
  end;
end;

procedure RemoveKeyboardHandler;
begin
  ClearAllKeys;
  if hooked then SetIntVec($9,keybh);
  hooked:=false;
end;

function IsKeyDown(key: byte):boolean;
begin
  IsKeyDown:=(Keys[key and 127] = 1);
end;


begin
  hooked:=false;
end.
