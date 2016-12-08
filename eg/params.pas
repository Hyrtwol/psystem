program params(output);
var
  p: text;
  ch: char;
  paramcount: integer;
begin
  Assign(p, '?'); {'?' will open a special paramerer file }
  Reset(p);
  while not EOF(p) do
  begin
    Read(p, ch);
    Write(ch);
  end;
  Close(p)
end.
