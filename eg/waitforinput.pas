{$t+}
program waitforinput(input, output);
var
  c: char;
begin
  {eof blocks until a full line is given}
  while not eof(input) do
  begin
    write(output, '*');
    read(input, c);    
    write(output, c);
    if c = '!' then halt;
  end;
end.
