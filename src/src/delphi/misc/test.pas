{ test program, mainly testing the CRT unit, not that anyone cares...         }
{ compile: DCC32 TEST.PAS and say: STUBIT TEST.EXE                            }
{ Make sure the compiler can find the CRT unit!                               }

{ This is a 100% Turbo Pascal program, it compiles and runs the same way with }
{ Turbo Pascal 5.5!                                                           }
 
program testall;
uses crt;
var  c:char;
     b:byte;
     f:text;
     s:string;
     a:boolean;
begin
  textmode(CO80);
  textcolor(white);
  textbackground(blue);
  window(5,5,75,20);
  clrscr;
  window(7,6,73,19);
  textbackground(black);
  clrscr;
  gotoxy(20,7);
  highvideo;
  writeln('Welcome to Turbo Pascal 10 !!');
  gotoxy(1,14);
  for b:=0 to 5 do begin
    delay(50);
    sound((6-b)*220);
    writeln
  end;
  nosound;
  gotoxy(14,7);
  textcolor(lightgreen);
  writeln('Well, at least the loader did not crash :)');
  gotoxy(20,8);
  textcolor(lightred);
  writeln('Press any key to continue...');
  while keypressed do c:=readkey;
  repeat until keypressed;
  gotoxy(1,7);
  for b:=0 to 7 do begin
    delay(50);
    sound((b+1)*220);
    insline;
  end;
  nosound;
  gotoxy(19,14);
  textcolor(lightgreen);
  write('Now let',chr(39),'s have some more tests !');
  gotoxy(19,7);
  for b:=0 to 6 do begin
    delay(50);
    sound((6-b)*220);
    delline;
  end;
  nosound;
  delay(1000);
  gotoxy(18,8);
  textcolor(lightred);
  writeln('Press any key to set textmode BW40');

{usually this is colored also...}

  while keypressed do c:=readkey;
  repeat until keypressed;
  textmode(BW40);
  writeln('Welcome to mode BW40');
  lowvideo;
  writeln('Any key to test mode CO40...');
  while keypressed do c:=readkey;
  repeat until keypressed;
  textmode(CO40);
  highvideo;
  writeln('Welcome to mode CO40');
  lowvideo;
  writeln('Any key to test mode BW80...');
  while keypressed do c:=readkey;
  repeat until keypressed;
  textmode(BW80);
  highvideo;
  writeln('Welcome to mode BW80');
  lowvideo;
  writeln('Any key to test mode CO80...');
  while keypressed do c:=readkey;
  repeat until keypressed;
  textmode(CO80);
  highvideo;
  writeln('Welcome to mode CO80');
  lowvideo;
  writeln('Any key to test mode CO80 + Font8x8...');
  while keypressed do c:=readkey;
  repeat until keypressed;
  textmode(CO80+Font8x8);
  highvideo;
  writeln('Are you actually able to read this???');
  lowvideo;
  writeln('Any key to get out of here...');
  while keypressed do c:=readkey;
  repeat until keypressed;
  textmode(CO80);
  textcolor(white);
  textbackground(blue);
  window(5,5,75,20);
  clrscr;
  window(7,6,73,19);
  textbackground(black);
  clrscr;
  gotoxy(20,7);
  highvideo;
  writeln('Welcome to Turbo Pascal 10 !!!');
  gotoxy(1,14);
  for b:=0 to 5 do begin
    delay(50);
    sound((6-b)*220);
    writeln
  end;
  nosound;
  gotoxy(20,7);
  textcolor(lightgreen);
  writeln('Whowww, still not crashed ???');
  gotoxy(16,8);
  textcolor(white);
  writeln('Press any key to have some file IO...');
  while keypressed do c:=readkey;
  repeat until keypressed;
  gotoxy(1,7);
  for b:=0 to 7 do begin
    delay(50);
    sound((b+1)*220);
    insline;
  end;
  nosound;
  repeat
    while keypressed do c:=readkey;
    gotoxy(2,7);
    writeln('Enter a file we could write some garbage to ! [RETURN SKIPS] :');
    gotoxy(14,8);
    a:=true;
    delline;
    readln(s);
    if s <> '' then begin
      assign(f,s);
  {$I-}
      reset(f);
  {$I+}
      if (ioresult<>0) then {$I-} rewrite(f) {$I+} else begin
        gotoxy(14,8);
        clreol;
        writeln('File already exists !');
        delay (500);
        a:=false;
        close(f);
      end;
    end;
  until ( ((ioresult=0) or (s='')) and a);
  gotoxy(2,7);
  delline;
  if s<>'' then begin
    writeln(f,'Wuschel',chr(39),'s garbage file');
    for b:=0 to 200 do writeln (f,b,' SPAM SPAM SPAM SPAM SPAM SPAM...');
    close(f);
    clrscr;
    clreol;
    writeln('Garbage written to file "',s,'", any key to exit');
  end else writeln('No garbage written to no file. Any key to exit...');
  while keypressed do c:=readkey;
  repeat until keypressed;
  while keypressed do c:=readkey;
end.
