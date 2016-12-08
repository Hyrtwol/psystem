program typefile(prr, output);
var
  {prr: text;}
  c: char;
begin
  writeln('typing file:');
  reset(prr);
  while not eof(prr) do
    begin
      read(prr, c);
      write(c);
    end;
  close(prr)
end.
