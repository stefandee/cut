procedure fill;
var x,y:integer;
    colorize:boolean;
    i:integer;
    oldcul:byte;
   
    ip:integer;
    filled:integer;


label endfill;

begin
nr:=0;
for y:=ymin+1 to ymax-1 do
    begin
    x:=xmin;
    colorize:=false;
    while getspr(x,y)<>air do inc(x);
    inc(x);
    repeat
    ip:=0;
    while (x<=xmax) and (getspr(x,y)<>air) do
    begin
    if (colorize) and (getspr(x,y)<>flood) and (getspr(x,y)<>margin)
       and (getspr(x,y)<>air)
       then begin
            inc(ip);
            oldcul:=lafill(x,y,1,x,x+1);
            goto endfill;
            end;
    inc(x);                    
    end;
    while (x<=xmax) and ((getspr(x,y)=air) or (getspr(x,y)=flood) or (getspr(x,y)=margin)) do inc(x);
    colorize:=not colorize;
    if (ip=0) and (getspr(xmin+1,y)<>flood) and (getspr(xmin+1,y)<>margin)
              and (getspr(xmin+1,y)<>air)
       then begin
            oldcul:=lafill(xmin+1,y,1,xmin+1,xmin+1);
            goto endfill;
            end;
    until x>=xmax;
    end;

endfill:
area_filled:=area_filled+nr;
if area_filled>=85*(area_to_fill/100) then exitcode:=4;
doair;
end;
