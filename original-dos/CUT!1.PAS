program cut;
{$M 32768,0,200000}
uses graphics,crt;

const left   = 160-80;
      right  = 160+80;
      bottom = 100+50;
      top    = 100-50;
      chenar = 10;
      step   = 1;
      flood  = 190;
      margin = 160;


type mirrortype = array[1..right-left,1..bottom-top] of byte;


var dotx,doty   : integer;
    key         : byte;
    mirror      : ^mirrortype;
    i,j,k       : integer;
    s,o,adr     : word;
    xdist,ydist : word;
    toleft,toright,toup,todown,on_air : boolean;

procedure wait;
begin
repeat until readkey=#13;
end;

procedure modspr(x,y:integer;v:byte);
begin
mem[s:o+xdist*(y-1)+x-1]:=v;
end;

function getspr(x,y:integer):byte;
begin
getspr:=mem[s:o+xdist*(y-1)+x-1];
end;

begin

vga256;
initvscreen;
loadpal('default.pal');
setpal;
loadspr('dotty.spr',1);

xdist:=word(right-left);ydist:=word(bottom-top);
with spr[2] do
     begin
     xl:=xdist;
     yl:=ydist;
     getmem(spr[2].pspr,xl*yl);
     end;
s:=seg(spr[2].pspr^);o:=ofs(spr[2].pspr^);
for i:=1 to ydist do for j:=1 to xdist do modspr(j,i,0);
for i:=1 to xdist do begin modspr(i,1,margin);modspr(i,ydist,margin);
                     modspr(i,ydist div 2,margin);end;
for i:=1 to ydist do begin modspr(1,i,margin);modspr(xdist,i,margin);end;

dotx:=1;doty:=ydist;
on_air:=false;toleft:=false;toright:=false;toup:=false;todown:=false;

repeat
cls(0,vaddr);
key:=port[$60];
case key of
24 :
      if (dotx>1) then if getspr(dotx-1,doty)=margin
        then begin
             dec(dotx,step);
             if dotx<1 then dotx:=1;
             end;
25 : if (dotx<xdist) then if getspr(dotx+1,doty)=margin
        then begin
             inc(dotx,step);
             if dotx>xdist then dotx:=xdist;
             end;
16 : if (dotx=left) or (dotx=right)
        then begin
             dec(doty,step);
             if doty<top then doty:=top;
             end;
44 : if (dotx=left) or (dotx=right)
        then begin
             inc(doty,step);
             if doty>bottom then doty:=bottom;
             end;

end;
asm
   mov ax,$0c02
   int $21
end;
putspr(2,left,top,normalput,vaddr);
{for j:=0 to ydist-1 do for i:=1 to xdist do mem[Vaddr:(j+top)*320+i+left]:=mirror^[i,j+1];}
putspr(1,dotx-spr[1].xl div 2+left,doty-spr[1].yl div 2+top,copyput,vaddr);
{waitretrace;}
flip;
until key=1;
donevscreen;
donevga256;
end.