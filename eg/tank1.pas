{$t+}
program tank1(output);

{type
  vec = record
    x, y, z: integer;
  end;}

var
  i, j, k: integer;
  {x, y: real;
  v: vec;}
begin

  k := 1;
  writeln('start');
  poke(1, k);

  i := 0;
  j := 0;
  repeat
    peek(2, i);
    j := j + 1;
    if j > 100 then
    begin
      writeln('i=',i);
      j := 0;
    end;
  until i >= 3;

  k := 2;
  writeln('move');
  poke(1, k);

  repeat
    peek(2, i);
    j := j + 1;
    if j > 100 then
    begin
      writeln('i=',i);
      j := 0;
    end;
  until i >= 9;

  k := 1;
  writeln('idle');
  poke(1, k);

  repeat
    peek(2, i);
    j := j + 1;
    if j > 100 then
    begin
      writeln('i=',i);
      j := 0;
    end;
  until i >= 12;

  k := 0;
  writeln('stop');
  poke(1, k);

end.
