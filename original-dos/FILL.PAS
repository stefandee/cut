procedure fill(x,y : integer);
var oldcul : byte;
    nr     : integer;
procedure rfill(x,y : integer);
begin
modspr(x,y,flood);
inc(nr);
if nr>3000 then exit;
if getspr(x-1,y)=oldcul then rfill(x-1,y);
if getspr(x+1,y)=oldcul then rfill(x+1,y);
if getspr(x,y-1)=oldcul then rfill(x,y-1);
if getspr(x,y+1)=oldcul then rfill(x,y+1);
end;
begin
oldcul:=getspr(x,y);
nr:=0;
if not(oldcul in [margin,flood]) then rfill(x,y);
area_filled:=area_filled+nr;
end;
