{ ############################################################################
  ## WDOSX DOS Extender           Copyright (c) 1996, 1998, Michael Tippach ##
  ##                                                                        ##
  ## Realeased under the terms of the WDOSX license agreement.              ##
  ############################################################################

  $Header: G:/ASMPRJ/RCS/RCS/WDOSX/0.95/SRC/DELPHI/crt.pas 1.1 1998/08/04 00:46:05 MikeT Exp MikeT $

  ----------------------------------------------------------------------------

  $Log: crt.pas $
  Revision 1.1  1998/08/04 00:46:05  MikeT
  Initial check in


  ----------------------------------------------------------------------------
  ############################################################################
  ##              32 bit CRT unit for use with DPMI                         ##
  ############################################################################
                                                                             
  Note that all routines here are written to get the job done, not to gain     
  maximum CRT performance. As soon as I have more time I'll probably add       
  direct video support. Most of the boolean publics (checkBreak...) are        
  ignored. As of now, there are lots of urgent 2-do's and priority scope       
  is different among people...                                                 
  compile with DCC32 Delphi 2 command line compiler "DCC32 CRT.PAS"            
                                                                             
  Thanks to Niklas Martinsson for pointing out a small error in the readkey   
  function. He also provided a fix for this.                                  
                                                                             
  Comments and suggestions to: Michael Tippach <wuschel@geocities.com>         
                                                                             
                                             ... enjoy!                      
                                                                             
  Some adaptions have been made WRT the true flat model of WDOSX 0.95.         
  ---------------------------------------------------------------------------}

unit	crt;
interface
const
   Black        = 0;
   Blue         = 1;
   Green        = 2;
   Cyan         = 3;
   Red          = 4;
   Magenta      = 5;
   Brown        = 6;
   LightGray    = 7;
   DarkGray     = 8;
   LightBlue    = 9;
   LightGreen   = 10;
   LightCyan    = 11;
   LightRed     = 12;
   LightMagenta = 13;
   Yellow       = 14;
   White        = 15;
   Blink        = 128;

   BW40    = 0;{40x25 B/W on CGA}
   CO40    = 1;{40x25 Color on CGA}
   BW80    = 2;{80x25 B/W on CGA}
   CO80    = 3;{80x25 Color on CGA}
   Mono    = 7;{80x25 B/W on MDA or HGC}
   Font8x8 = 256;{43-/50-line mode EGA/VGA}

   C40  = CO40;
   C80  = CO80;


var	checkbreak,checksnow,checkeof,directvideo:boolean;
	lastmode,windmin,windmax:word;
	textattr:byte;
{	huge_selector:	word;	4G data selector with base 0 }

procedure AssignCrt(var f:text);
procedure ClrEol;
procedure ClrScr;
procedure Delay(MS:word);
procedure DelLine;
procedure Gotoxy(X,Y:byte);
procedure HighVideo;
procedure InsLine;
function  Keypressed:boolean;
procedure LowVideo;
procedure NormVideo;
procedure NoSound;
function  ReadKey:char;
procedure Sound(Hz:word);
procedure TextBackground(Color:byte);
procedure TextColor(Color:byte);
procedure TextMode(Mode:integer);
function  WhereX:byte;
function  WhereY:byte;
procedure Window(X1,Y1,X2,Y2:byte);

implementation
{ uses zerosel; }

var	
        isega:		boolean;
        current_page:	byte;
        normattr:	byte;
	rktemp:		char;

{******************** private functions and procedures ***********************}

function max_x:byte;
var	x:byte;
begin
  asm
{    push ds }
{    mov ds,huge_selector }
    mov al,ds:[44ah]
{    pop ds }
    dec al
    mov x,al
  end;
  max_x:=x;
end;

function max_y:byte;
var	y:byte;
begin
  asm
{    push ds }
{    mov ds,huge_selector }
    mov al,ds:[484h]
{    pop ds }
    mov y,al
  end;
  max_y:=y;
end;

procedure put_one(c:byte);
begin
  asm
    push ebx
    mov bl,textattr
    mov bh,current_page
    mov ah,9
    mov al,c
    mov cx,1
    int 10h
{update cursor position}
    mov ah,3
    int 10h
{start with X}
    inc dl
    cmp dl,byte ptr [offset windmax]
    jna @@1
    inc dh
    mov dl,byte ptr [offset windmin]

@@1:
{now check Y}
    cmp dh,byte ptr [offset windmax+1]
    jna @@2
{have to scroll the window}
    dec dh
    push edx
    mov cx,windmin
    mov dx,windmax
    mov bh,textattr
    mov ax,0601h
    push ds
    push ebp
    int 10h
    pop ebp
    pop ds
    pop edx

@@2:
{set new cursor pos.}
    mov bh,current_page
    mov ah,2
    int 10h
    pop ebx
  end;
end;

procedure nuke_one;
begin
  if whereX > 1 then begin
    asm
      push ebx
      mov bh,current_page
      mov ah,3
      int 10h
      dec dl
      mov ah,2
      int 10h
      mov ax,920h
      mov bl,textattr
      mov cx,1
      int 10h
      pop ebx
    end;
  end;
end;

procedure put_cr;
begin
  asm
    push ebx
    mov bh,current_page
    mov ah,3
    int 10h
    mov dl,byte ptr [offset windmin]
    mov ah,2
    int 10h
    pop ebx
  end;
end;

procedure put_lf;
begin
  asm
    push ebx
    mov bh,current_page
    mov ah,3
    int 10h
    inc dh
    cmp dh,byte ptr [offset windmax+1]
    jna @@1
{have to scroll the window}
    dec dh
    push edx
    mov cx,windmin
    mov dx,windmax
    mov bh,textattr
    mov ax,0601h
    push ds
    push ebp
    int 10h
    pop ebp
    pop ds
    pop edx

@@1:
{set new cursor pos.}
    mov bh,current_page
    mov ah,2
    int 10h
    pop ebx
  end;
end;

{********************* public functions and procedures ***********************}

procedure AssignCrt(var f:text);
begin
  assign(f,'CON'); {Is this the answer? Who actually uses it, BTW?}
end;

procedure ClrEol;
var i,x,y:byte;
begin
  x:=whereX;
  y:=whereY;
  for i:= (x+lo(windmin)) to (lo(windmax)+1) do put_one($20);
  gotoxy(x,y);
end;

procedure ClrScr;
begin
  asm
    push ebx
    mov ax,600h
    mov bh,textattr
    mov cx,windmin
    mov dx,windmax
    push ds	{there're some bugs...          }
    push ebp	{see Ralf Brown's Interrupt list}
    int 10h
    pop ebp
    pop ds
    mov bh,current_page
    mov dx,windmin
    mov ah,2
    int 10h
    pop ebx
  end;
end;

procedure Delay(MS:word);
begin
  asm
    sub ecx,ecx
    movzx edx,MS
    shl edx,10
    shld ecx,edx,16
    mov ah,86h
    int 15h {for some strange reason this does not work under NT, however in}
            {TP5.5 it behaves the same way under NT so we are compatible :) }
  end;
end;

procedure DelLine;
begin
  asm
    push ebx
    mov bh,current_page
    mov ah,3
    int 10h
    mov ax,601h
    mov bh,textattr
    mov cx,windmin
    mov ch,dh
    mov dx,windmax
    push ds	{there're some bugs...          }
    push ebp	{see Ralf Brown's Interrupt list}
    int 10h
    pop ebp
    pop ds
    pop ebx
  end;
end;

procedure Gotoxy(X,Y:byte);
begin
{check if in current window, ignore if not}
  asm
    push ebx
    mov ax,windmin
    mov dl,X
    mov dh,Y
    dec dl
    dec dh
    add dl,al
    add dh,ah
    mov ax,windmax
    cmp dl,al
    ja @@1
    cmp dh,ah
    ja @@1
    mov bh,current_page
    mov ah,2
    int 10h
@@1:
    pop ebx
  end;
end;

procedure HighVideo;
begin
  textattr:=(textattr or 8);
end;

procedure InsLine;
begin
  asm
    push ebx
    mov bh,current_page
    mov ah,3
    int 10h
    mov ax,701h
    mov bh,textattr
    mov cx,windmin
    mov ch,dh
    mov dx,windmax
    push ds	{there're some bugs...          }
    push ebp	{see Ralf Brown's Interrupt list}
    int 10h
    pop ebp
    pop ds
    pop ebx
  end;
end;

function  Keypressed:boolean;
var k:boolean;
begin
  asm
    mov ah,1
    mov k,false
    int 16h
    jz @@1
    mov k,true
@@1:
  end;
  Keypressed:=k;
end;

procedure LowVideo;
begin
  textattr:=(textattr and $F7);
end;

procedure NormVideo;
begin
  textattr:=normattr;
end;

procedure NoSound;
begin
  asm
    in al,61h
    and al,0fch
    out 61h,al
  end;
end;

function  ReadKey:char;
var 	k:char;
begin
  if rktemp<>#0 then begin
    ReadKey:=rktemp;
    rktemp:=#0;
  end else begin
    asm
      sub ah,ah
      int 16h
      mov k,al
      cmp al,1
      sbb al,al
      and al,ah
      mov rktemp,al
    end;
    ReadKey:=k;
  end;
end;

procedure Sound(Hz:word);
begin
  if Hz > 18 then begin
    asm
      movzx ecx,Hz
      mov eax,1193180
      sub edx,edx
      div ecx
      mov ecx,eax
{set timer #3}
      mov al,182
      out 43h,al
      mov al,cl
      out 42h,al
      mov al,ch
      out 42h,al
{enable speaker}
      in al,61h
      or al,3
      out 61h,al
    end;
  end;
end;

procedure TextBackground(Color:byte);
begin
  asm
    mov al,textattr
    mov ah,color
    and al,08fh
    and ah,7
    shl ah,4
    or al,ah
    mov textattr,al
  end;
end;

procedure TextColor(Color:byte);
begin
  asm
    mov al,textattr
    mov ah,color
    and al,070h
    and ah,08fh
    or al,ah
    mov textattr,al
  end;
end;

procedure TextMode(Mode:integer);
begin
  asm
    push ebx
    mov eax,mode {integer now is 32 bit}
    test ah,ah
    jz @@1
    cmp isega,true
    jnz @@4

@@1:
    cmp al,4
    jc @@2
    cmp al,7
    jnz @@4

@@2:
    mov ecx,eax
    sub ah,ah
    int 10h
    mov ah,0fh
    int 10h
    cmp cl,al
    jnz @@4
    mov current_page,bh
    mov eax,mode
    mov lastmode,ax
    test ah,ah
    jz @@3
    mov ax,1112h
    sub bl,bl
    int 10h

@@3:
{update screen window size}
    mov windmin,0
{    push ds }
{    mov ds,huge_selector }
    mov al,ds:[44ah]
    mov ah,ds:[484h]
{    pop ds }
    mov windmax,ax
{update textattr}
    mov bh,current_page
    mov ah,8
    int 10h
    mov textattr,ah
{    mov normattr,ah}

@@4:
    pop ebx
  end;
end;


function  WhereX:byte;
var	X:byte;
begin
  asm
    push ebx
    mov bh,current_page
    mov ah,3
    int 10h
    sub dl,byte ptr [offset windmin]
    inc dl  
    mov X,dl
    pop ebx
  end;
  WhereX:=X;
end;

function  WhereY:byte;
var	Y:byte;
begin
  asm
    push ebx
    mov bh,current_page
    mov ah,3
    int 10h
    sub dh,byte ptr [offset windmin + 1]
    inc dh  
    mov Y,dh
    pop ebx
  end;
  WhereY:=Y;
end;

procedure Window(X1,Y1,X2,Y2:byte);
begin
  if (((X1-1) < X2) and ((Y1-1) < Y2) and (X2<=(max_x+1)) and (Y2<=(max_y+1))) then begin
    windmin:=256*(Y1-1) + X1 - 1;
    windmax:=256*(Y2-1) + X2 - 1;
  end;
end;

{*************************** init for unit CRT *******************************}

begin
  rktemp:=#0;
{  huge_selector:=ZeroDataSelector; }
asm
    push ebx
{get videomode info, check for supported videomode}
    mov ah,0fh
    int 10h
    cmp al,4
    jc @@1
    cmp al,Mono
    jz @@1
    mov ax,3
    int 10h
    mov ah,0fh
    int 10h
    cmp al,CO80
    jz @@1
    mov ax,7
    int 10h
    mov ah,0fh
    int 10h
    cmp al,Mono
    jz @@1
{abort if no suitable videomode, this one is for the paranoid}
@@00:
    mov	eax,4cffh
    int	21h
@@1:
    mov current_page,bh
    push eax
    mov ah,12h
    mov bx,0ff10h
    int 10h
    inc bh
    mov isega,true
    jnz @@2
{no ega}
    mov isega,false

@@2:
{    push ds }
{    mov ds,huge_selector }
    mov bl,ds:[484h]
{    pop ds }
    cmp bl,18h
    seta bh
    pop eax
    cmp isega,true
    jz @@3
    sub bh,bh

@@3:
    xchg ah,bh
    mov lastmode,ax

    mov checksnow,true
    cmp al,1
    jz @@4
    cmp al,3
    jz @@4
    mov checksnow,false

@@4:
    xchg bl,bh
    mov windmax,bx
    mov windmin,0

{read attribute at cursor position}
    mov bh,current_page
    mov ah,8
    int 10h
    mov textattr,ah
    mov normattr,ah
{set defaults}
    mov directvideo,true
    mov checkbreak,true
    mov checkeof,false

{hook into int 21 to trap console reads/writes                            }
{I'd like to apologize to everyone for that mess, especially if you're not}
{an all- day ASM coder. It works, anyway.                                 }

{get old interrupt vector}
    mov ax,0204h
    mov bl,21h
    int 31h
    jc @@00
    mov dword ptr ds:[offset @@21+1],edx
    mov word ptr ds:[offset @@21+5],cx

{set new one}

    mov cx,cs
    mov edx,offset @@hook
    inc eax
    int 31h
    jc @@00

    jmp @@5

@@hook:
    cmp ah,3fh
    jz @@tread
    cmp ah,40h
    jz @@twrite

@@21:
    db  0eah {jmp far}
    dd	0
    dw  0

@@tread:

    test bx,bx 
    jnz @@21
    sub	eax,eax
    pushad


@@r00:
    sub ah,ah
    int 16h

    cmp al,20h
    jnc @@r04

{is control char}
    cmp al,8
    jnz @@r01

    call nuke_one
    cmp dword ptr [esp+28],0
    jz @@r00    
    dec dword ptr [esp+28]    
    jmp @@r00

@@r01:
    cmp al,13
    jz @@r03
    cmp al,27
    jnz @@r00


@@r02:
    cmp dword ptr [esp+28],0
    jz @@r00
    call nuke_one
    dec dword ptr [esp+28]
    jmp @@r02

@@r04:
    mov ebx,[esp+28]
    inc ebx
    inc ebx
    cmp ebx,[esp+24]
    jnc @@r00
    dec ebx
    dec ebx
    inc dword ptr [esp+28]
    add ebx,[esp+20]
    mov [ebx],al
    call put_one
    jmp @@r00

@@r03:
{all done}
    mov ebx,[esp+28]
    add dword ptr [esp+28],2
    add ebx,[esp+20]
    mov word ptr [ebx],0a0dh
    call put_cr
    call put_lf
    popad
    and byte ptr [esp+8],0feh
    iretd

@@twrite:
    cmp bx,1
    jnz @@21

    push ebx
    test ecx,ecx
    jz @@w01
    push edx
    push ecx

@@w00:
    mov al,[edx]
    inc edx
    push edx
    push ecx
    call @@onscreen
    pop ecx
    pop edx
    loop @@w00

    pop ecx
    pop edx

@@w01:
    mov eax,ecx
    pop ebx
    and byte ptr [esp+8],0feh
    iretd

@@onscreen:
    cmp al,7
    jnz @@o1
    mov ah,0eh
    int 10h
    retn

@@o1:
    cmp al,8
    jnz @@o2
    call nuke_one
    retn

@@o2:
    cmp al,10
    jnz @@o3
    call put_lf
    retn

@@o3:
    cmp al,13
    jnz @@o4
    call put_cr
    retn

@@o4:

    call put_one
    retn

@@5:
    pop ebx
  end;
end.
