program dir(output);

const
  columnwidth1 = 40;
  columnwidth2 = 9;
var
  f: Text;
  ch, mode: char;
  w, size: integer;
begin
  Assign(f, '.');
  Reset(f);
  while not EOF(f) do
  begin
    Read(f, mode);
    Read(f, ch);
    w := 0;
    if mode = 'd' then
    begin
      Write('[');
      w := w + 1;
    end;
    repeat
      Read(f, ch);
      Write(ch);
      w := w + 1;
    until (ch = ' ') or eoln(f);
    if mode = 'd' then
    begin
      Write(']');
      w := w + 1;
    end;
    while w < columnwidth1 do
    begin
      Write(' ');
      w := w + 1;
    end;

    if mode = 'f' then
    begin
      Read(f, size);
      Write(size: columnwidth2);
    end;
    ReadLn(f);
    WriteLn;
  end;
  Close(f);
end.
