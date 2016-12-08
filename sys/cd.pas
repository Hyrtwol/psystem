program cd(output);

var
  f, p: Text;
  ch: char;
begin
  Assign(p, '?'); {'?' will open a special paramerer file }
  Reset(p); {check for paramerers}
  Readln(p); {first line is the program name}
  if not EOF(p) then
  begin
    Assign(f, '!'); {'!' will open a special command file }
    Rewrite(f);
    Write(f, 'cd ');
    while not EOLn(p) do
    begin
      Read(p, ch);
      Write(f, ch);
    end;
    Close(f); {the command will be executed on close}
  end;
  Close(p);

  Assign(f, '.'); {'.' will open a special directory file }
  Reset(f); {read current directory}
  Read(f, ch); {skip mode}
  Read(f, ch); {skip space}
  repeat
    Read(f, ch);
    Write(ch);
  until (ch = ' ') or eoln(f);
  WriteLn;
  Close(f);
end.
