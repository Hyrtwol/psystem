program circles(output);
const
  maxx = 39;
  maxy = 24;
  aspectratio = 1.5;
  scale = 0.52;
var
  x, y: integer;
  ox, oy, rx, ry, dist: real;
begin
  ox := -(maxx / 2.0);
  oy := -(maxy / 2.0);
  for y := 0 to maxy do
  begin
    for x := 0 to maxx do
    begin
      rx := ox + x;
      ry := (oy + y) * aspectratio;
      dist := sqrt((rx*rx) + (ry*ry));
      if sin(dist*scale) < 0.0 then
        write('O')
      else
        write(' ');
    end;
    {writeln}
  end;
end.
