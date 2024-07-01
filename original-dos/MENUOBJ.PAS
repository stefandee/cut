type Menuobj  = object
             sprnr : byte;
             x,y   : integer;
             retcode : byte;
             portcode : byte;
             volcnt : byte;
             procedure Init(wx,wy : integer;nr,rc,pc : byte);virtual;
             function Handlekey:byte;virtual;
             procedure Draw;virtual;
             end;
     Volobj = object(menuobj)
              function Handlekey:byte;virtual;
              procedure Draw;virtual;
              end;

procedure Menuobj.Init;
begin
x:=wx;y:=wy;sprnr:=nr;retcode:=rc;portcode:=pc;
end;
function Menuobj.HandleKey:byte;
var key : byte;
begin
key:=port[$60];
if key=portcode then handlekey:=retcode;
end;
procedure Menuobj.Draw;
begin
putspr(sprnr,x,y,copyput,vaddr);
with spr[sprnr] do rectangle(x-1,y-1,x+xl+1,y+yl+1,255,vaddr);
end;

procedure VolObj.Draw;
begin
inherited Draw;
putspr(8,x+spr[sprnr].xl-7-volcnt,y+9,copyput,vaddr);
end;

function VolObj.Handlekey:byte;
var key : byte;
begin
key:=port[$60];
case key of
72 : if volcnt<11 then inc(volcnt);
80 : if volcnt>1 then dec(volcnt);
end;
volume:=voltable[volcnt];
end;

var menu : array[1..2] of menuobj;
    menucnt : byte;
    vo : volobj;
    mo : menuobj;