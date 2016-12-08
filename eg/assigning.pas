program assigning(output);

const
  fnsize = 8;
type
  filename = packed array [1..fnsize] of char;
var
  f, p: Text;
  ch: char;
  fn: filename;
  i: integer;
begin
  i := 1;

  Assign(p, '?'); {'?' will open a special paramerer file }
  Reset(p); {check for paramerers}
  Readln(p); {first line is the program name}
  if not EOF(p) then
  begin
    while not EOLn(p) do
    begin
      Read(p, ch);
      fn[i] := ch;
      i := i + 1;
    end;
  end;
  Close(p);
  while i <= fnsize do
  begin
    fn[i] := ' ';
    i := i + 1;
  end;

  writeln('filename is: ''',fn,'''');
  Assign(f, fn);

end.
