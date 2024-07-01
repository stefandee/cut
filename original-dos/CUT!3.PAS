program cut;
{$M 65520,0,340000}
{mod is only for presentation }
uses graphics,crt,dos,sbdsp,images;

const {handle keys} nothing   = 0;
                    outofgame = 1;
                    rungame   = 2;

type Menuobj  = record
             sprnr : byte;
             x,y   : integer;
             code : byte;
             end;

var volcnt,menucnt : byte;
    menu : array[1..3] of menuobj;

const left   = 160-80;
      right  = 160+80;
      bottom = 100+50;
      top    = 100-50;
      chenar = 10;
      step   = 1;
      flood  = 190;
      v_flood= 195;
      air    = 250;
      margin = 160;
      bub_nr :byte= 2;
      bub_color  = 130;
      scorexb = 220;
      scoreyb = 182;
      scorexf= 319;
      scoreyf= 199;

const TIMERINTR = 8;
      PIT_FREQ = $1234DD;

var BIOSTimerHandler : procedure;
    clock_ticks, counter : longint;
    int9 : longint;

var
    dev,mix,stat,pro,loop : integer;
    md : string;

{$L MOD-obj.OBJ} 	        { Link in Object file }
{$F+} 				{ force calls to be 'far'}
procedure modvolume(v1,v2,v3,v4:integer); external ; {Can do while playing}
procedure moddevice(var device:integer); external ;
procedure modsetup(var status:integer;device,mixspeed,pro,loop:integer;var str:string); external ;
procedure modstop; external ;
procedure modinit; external;
{$F-}


var dotx,doty   : integer;
    key         : byte;
    i,j,k       : integer;
    s,o,adr     : word;
    xdist,ydist : word;
    toleft,toright,toup,todown,on_air : boolean;
    y1,y2,x1,x2 : integer;
    fx,fy,fxdir,fydir : integer;{the follower}
    rnd : word;
    mixmots : array[0..3] of byte;
    cntmots : byte;
    bubdir : array[1..15,1..2] of integer;
    bubcor : array[1..15,1..3] of integer;
    f : file;
    score : longint;
    area_filled,area_to_fill : word;
    maxtime : longint;
    time : real;
    exitcode : integer;{means 0 nothing-just continue
                              1 escape exit(quit,abort)
                              2 killed
                              3 time over
                              4 pass level
                       }
    first_time : boolean;
    lives : integer;
    bubinlevel : integer;
    level : integer;
    nr,nr2,nr1:longint;

{$F+}
procedure DoNothing;interrupt;
begin
port[$20]:=$20;
end;
{$F-}

procedure wait;
begin
repeat until readkey=#13;
end;

procedure modspr(x,y:integer;v:byte;sprnr:byte);
var s,o : word;
begin
s:=seg(spr[sprnr].pspr^);
o:=ofs(spr[sprnr].pspr^);
mem[s:o+xdist*(y-1)+x-1]:=v;
end;

function getspr(x,y:integer;sprnr:byte):byte;
var s,o: word;
begin
s:=seg(spr[sprnr].pspr^);
o:=ofs(spr[sprnr].pspr^);
getspr:=mem[s:o+xdist*(y-1)+x-1];
end;



procedure doair1;assembler;
asm
   push si
   push di
   push bp
   push ds
   push es
   mov ax,s
   mov es,ax
   mov di,o
   mov dx,area_filled
   mov cx,area_to_fill
   cld
@7:
   mov al,es:[di]
   cmp al,air
   jne @8
   mov al,margin
   jmp @100
@8:
   cmp al,v_flood
   jne @9
   mov al,0
   jmp @100
@9:
   cmp al,0
   jne @100
   mov al,flood
   inc dx
@100:
   mov es:[di],al
   inc di
   loop @7
   mov area_filled,dx
   pop es
   pop ds
   pop bp
   pop di
   pop si
end;



function fill(sx,sy,d : integer;sprnr : byte;color : byte):longint;

procedure scanleft(var x: integer;y : integer);
var v:integer;
begin
repeat
dec(x);
v:=getspr(x,y,sprnr);
inc(nr);
until (v<>0);
inc(x);
end;
procedure scanright(var x: integer;y:integer);
var v:integer;
begin
repeat
inc(x);
v:=getspr(x,y,sprnr);
inc(nr);
until (v<>0);
dec(x);
end;


function LaFill(seedx,seedy,d,prevxl,prevxr:integer):integer;
var x,y,xl,xr,v : integer;
begin
y:=seedy;xl:=seedx;xr:=seedx;
scanleft(xl,y);scanright(xr,y);
for i:=xl to xr do modspr(i,y,color,sprnr);
for x:=xl to xr do
    begin
    v:=getspr(x,y+d,sprnr);
    if (v=0) then x:=lafill(x,y+d,d,xl,xr);
    end;
for x:=xl to prevxl-1 do
    begin
    v:=getspr(x,y-d,sprnr);
    if (v=0) then x:=lafill(x,y-d,-d,xl,xr);
    end;
for x:=prevxr to xr-1 do
    begin
    v:=getspr(x,y-d,sprnr);
    if (v=0) then x:=lafill(x,y-d,-d,xl,xr);
    end;
lafill:=xl;
end;

begin{fill begin}
nr:=0;fill:=0;
if getspr(sx,sy,2)=0
   then begin
        lafill(sx,sy,d,sx,sx);
        fill:=nr;
        end;
end;

{$F+}
procedure Handler; Interrupt;
begin
{read keys}
nr:=0;
key:=port[$60];
asm cli end;
case key of
24 : if on_air then if toleft then begin
                                   dec(dotx);
                                   if getspr(dotx,doty,2)=air then exitcode:=2
                                   else begin
                                   toleft:=true;toright:=false;
                                   toup:=true;todown:=true;
                                   if getspr(dotx,doty,2)=margin then begin
                                                                    on_air:=false;
                                                                    nr1:=fill(dotx+1,doty+1,1,2,v_flood);
                                                                    if nr1>(area_to_fill-area_filled) div 2
                                                                       then begin
                                                                            {revert flooded pixels,set the others}
                                                                            nr:=0;
                                                                            for i:=1 to xdist do
                                                                                for j:=1 to ydist do
                                                                                case getspr(i,j,2) of
                                                                                0 : begin
                                                                                    modspr(i,j,flood,2);
                                                                                    inc(nr);
                                                                                    end;
                                                                                v_flood : modspr(i,j,0,2);
                                                                                end;
                                                                            area_filled:=area_filled+nr;
                                                                            end
                                                                       else begin
                                                                            for i:=1 to xdist do
                                                                                for j:=1 to ydist do
                                                                                if getspr(i,j,2)=v_flood
                                                                                   then modspr(i,j,flood,2);
                                                                            area_filled:=area_filled+nr1;
                                                                            end;
                                                                    doair;
                                                                    if area_filled>=85*(area_to_fill/100) then exitcode:=4;
                                                                    end
                                                               else modspr(dotx,doty,air,2);
                                   end;
                                   end
                              else begin end
               else if dotx>1 then if getspr(dotx-1,doty,2)=margin then begin
                                                                      dec(dotx,step);
                                                                      if dotx<1 then dotx:=1;
                                                                      end
                                                                 else begin
                                                                      if getspr(dotx-1,doty,2)<>flood then
                                                                      begin
                                                                      on_air:=true;
                                                                      toleft:=true;toright:=false;
                                                                      toup:=true;todown:=true;
                                                                      end;
                                                                      end;
25 : if on_air then if toright then begin
                                   inc(dotx);
                                   if getspr(dotx,doty,2)=air then exitcode:=2
                                   else begin
                                   toleft:=false;toright:=true;
                                   toup:=true;todown:=true;
                                   if getspr(dotx,doty,2)=margin then begin
                                                                    on_air:=false;
                                                                    nr1:=fill(dotx-1,doty+1,1,2,v_flood);
                                                                    if nr1>(area_to_fill-area_filled) div 2
                                                                       then begin
                                                                            {revert flooded pixels,set the others}
                                                                            nr:=0;
                                                                            for i:=1 to xdist do
                                                                                for j:=1 to ydist do
                                                                                case getspr(i,j,2) of
                                                                                0 : begin
                                                                                    modspr(i,j,flood,2);
                                                                                    inc(nr);
                                                                                    end;
                                                                                v_flood : modspr(i,j,0,2);
                                                                                end;
                                                                            area_filled:=area_filled+nr;
                                                                            end
                                                                       else begin
                                                                            for i:=1 to xdist do
                                                                                for j:=1 to ydist do
                                                                                if getspr(i,j,2)=v_flood
                                                                                   then modspr(i,j,flood,2);
                                                                            area_filled:=area_filled+nr1;
                                                                            end;
                                                                    doair;
                                                                    if area_filled>=85*(area_to_fill/100) then exitcode:=4;
                                                                    end
                                                               else modspr(dotx,doty,air,2);
                                   end;
                                   end
                              else begin end
               else if dotx<xdist then if getspr(dotx+1,doty,2)=margin then begin
                                                                      inc(dotx,step);
                                                                      if dotx>xdist then dotx:=xdist;
                                                                      end
                                                                 else begin
                                                                      if getspr(dotx+1,doty,2)<>flood then
                                                                      begin
                                                                      on_air:=true;
                                                                      toleft:=false;toright:=true;
                                                                      toup:=true;todown:=true;
                                                                      end;
                                                                      end;
16 : if on_air then if toup then begin
                                   dec(doty);
                                   if getspr(dotx,doty,2)=air then exitcode:=2
                                   else begin
                                   toleft:=true;toright:=true;
                                   toup:=true;todown:=false;
                                   if getspr(dotx,doty,2)=margin then begin
                                                                    on_air:=false;
                                                                    nr1:=fill(dotx+1,doty+1,1,2,v_flood);
                                                                    if nr1>(area_to_fill-area_filled) div 2
                                                                       then begin
                                                                            {revert flooded pixels,set the others}
                                                                            nr:=0;
                                                                            for i:=1 to xdist do
                                                                                for j:=1 to ydist do
                                                                                case getspr(i,j,2) of
                                                                                0 : begin
                                                                                    modspr(i,j,flood,2);
                                                                                    inc(nr);
                                                                                    end;
                                                                                v_flood : modspr(i,j,0,2);
                                                                                end;
                                                                            area_filled:=area_filled+nr;
                                                                            end
                                                                       else begin
                                                                            for i:=1 to xdist do
                                                                                for j:=1 to ydist do
                                                                                if getspr(i,j,2)=v_flood
                                                                                   then modspr(i,j,flood,2);
                                                                            area_filled:=area_filled+nr1;
                                                                            end;
                                                                    doair;
                                                                    if area_filled>=85*(area_to_fill/100) then exitcode:=4;
                                                                    end
                                                               else modspr(dotx,doty,air,2);
                                   end;
                                   end
                              else begin end
               else if doty>1 then if getspr(dotx,doty-1,2)=margin then begin
                                                                      dec(doty,step);
                                                                      if doty<1 then doty:=1;
                                                                      end
                                                                 else begin
                                                                      if getspr(dotx,doty-1,2)<>flood then
                                                                      begin
                                                                      on_air:=true;
                                                                      toleft:=true;toright:=true;
                                                                      toup:=true;todown:=false;
                                                                      end;
                                                                      end;
44 : if on_air then if todown then begin
                                   inc(doty);
                                   if getspr(dotx,doty,2)=air then exitcode:=2
                                   else begin
                                   toleft:=true;toright:=true;
                                   toup:=false;todown:=true;
                                   if getspr(dotx,doty,2)=margin then begin
                                                                    on_air:=false;
                                                                    nr1:=fill(dotx+1,doty-1,-1,2,v_flood);
                                                                    if nr1>(area_to_fill-area_filled) div 2
                                                                       then begin
                                                                            {revert flooded pixels,set the others}
                                                                            nr:=0;
                                                                            for i:=1 to xdist do
                                                                                for j:=1 to ydist do
                                                                                case getspr(i,j,2) of
                                                                                0 : begin
                                                                                    modspr(i,j,flood,2);
                                                                                    inc(nr);
                                                                                    end;
                                                                                v_flood : modspr(i,j,0,2);
                                                                                end;
                                                                            area_filled:=area_filled+nr;
                                                                            end
                                                                       else begin
                                                                            for i:=1 to xdist do
                                                                                for j:=1 to ydist do
                                                                                if getspr(i,j,2)=v_flood
                                                                                   then modspr(i,j,flood,2);
                                                                            area_filled:=area_filled+nr1;
                                                                            end;
                                                                    doair;
                                                                    if area_filled>=85*(area_to_fill/100) then exitcode:=4;
                                                                    end
                                                               else modspr(dotx,doty,air,2);
                                   end;
                                   end
                              else begin end
               else if doty<ydist then if getspr(dotx,doty+1,2)=margin then begin
                                                                      inc(doty,step);
                                                                      if doty>ydist then doty:=ydist;
                                                                      end
                                                                 else begin
                                                                      if getspr(dotx,doty+1,2)<>flood then
                                                                      begin
                                                                      on_air:=true;
                                                                      toleft:=true;toright:=true;
                                                                      toup:=false;todown:=true;
                                                                      end;
                                                                      end;
1 : exitcode:=1;

end;
{end read key}

fx:=fx+fxdir;fy:=fy+fydir;
cntmots:=0;
if (fx=dotx) and (fy=doty) then exitcode:=2;
if fx<xdist then if (getspr(fx+1,fy,2)=margin) and (fxdir<>-1) then begin
                                                             mixmots[cntmots]:=0;
                                                             inc(cntmots);
                                                             end;
if fx>1 then if (getspr(fx-1,fy,2)=margin) and (fxdir<>1) then begin
                                                             mixmots[cntmots]:=2;
                                                             inc(cntmots);
                                                             end;
if fy>1 then if (getspr(fx,fy-1,2)=margin) and (fydir<>1) then begin
                                                             mixmots[cntmots]:=3;
                                                             inc(cntmots);
                                                             end;
if fy<ydist then if (getspr(fx,fy+1,2)=margin) and (fydir<>-1) then begin
                                                             mixmots[cntmots]:=1;
                                                             inc(cntmots);
                                                             end;
rnd:=random(cntmots);
if cntmots>1 then playsound(7);
case mixmots[rnd] of
0 : begin fxdir:=1;fydir:=0;end;
2 : begin fxdir:=-1;fydir:=0;end;
1 : begin fxdir:=0;fydir:=1;end;
3 : begin fxdir:=0;fydir:=-1; end;
end;

for i:=1 to bub_nr do
    begin
    if (getspr(bubcor[i,1]+bubdir[i,1],bubcor[i,2]+bubdir[i,2],2)=margin) and
       (getspr(bubcor[i,1]+bubdir[i,1],bubcor[i,2],2)=margin) and
       (getspr(bubcor[i,1],bubcor[i,2]+bubdir[i,2],2)=margin)
       then begin
            bubdir[i,1]:=-bubdir[i,1];
            bubdir[i,2]:=-bubdir[i,2];
            playsound(2);
            end
       else if getspr(bubcor[i,1],bubcor[i,2]+bubdir[i,2],2)=margin
               then begin
                    bubdir[i,2]:=-bubdir[i,2];
                    playsound(2);
                    end
               else if getspr(bubcor[i,1]+bubdir[i,1],bubcor[i,2],2)=margin
                       then begin
                            bubdir[i,1]:=-bubdir[i,1];
                            playsound(2);
                            end
                       else if getspr(bubcor[i,1]+bubdir[i,1],bubcor[i,2]+bubdir[i,2],2)=margin
                            then begin
                            bubdir[i,1]:=-bubdir[i,1];
                            bubdir[i,2]:=-bubdir[i,2];
                            playsound(2);
                            end;
     if (getspr(bubcor[i,1],bubcor[i,2],2)=flood) and
        (bubcor[i,3]=1)
        then begin
             bubcor[i,3]:=0;
             score:=score+1000;
             end;
     if bubcor[i,3]=1
        then begin
             if (getspr(bubcor[i,1]+bubdir[i,1],bubcor[i,2]+bubdir[i,2],2)=air)
                then exitcode:=2;
             bubcor[i,1]:=bubcor[i,1]+bubdir[i,1];
             bubcor[i,2]:=bubcor[i,2]+bubdir[i,2];
             end;
     end;
asm sti end;

  { Adjust the count of clock ticks }
  clock_ticks := clock_ticks + counter;

  { Is it time for the BIOS handler to do it's thang? }
  if clock_ticks >= $10000 then
    begin

      { Yep! So adjust the count and call the BIOS handler }
      clock_ticks := clock_ticks - $10000;

      time:=time+0.25;
      if time>maxtime then time:=maxtime;

      asm pushf end;
      BIOSTimerHandler;
    end

  { If not then just acknowledge the interrupt }
  else
    Port[$20] := $20;
end;
{$F-}

procedure scoretable;
const scorexb = 220;
      scoreyb = 182;
      scorexf= 319;
      scoreyf= 198;
begin
bar(scorexb,scoreyb,scorexf,scoreyf,0,vaddr);
outtext(scorexb+1,scoreyb+1,'SCORE : ',smallfnt,vaddr);
outint(scorexb+1,scoreyb+8,score,smallfnt,vaddr);
end;

procedure percentage;
const pxb=1;
      pyb=182;
      pxf=101;
      pyf=198;
var manv : string;
begin
bar(pxb,pyb,pxf,pyf,0,vaddr);
outtext(pxb+1,pyb+1,'AREA CUT : ',smallfnt,vaddr);
str(round(100*(area_filled/area_to_fill)),manv);
outtext(pxb+1,pyb+8,manv+' %',smallfnt,vaddr);
end;

procedure timebar;
const txb = 1;
      tyb = 1;
      txf = 319;
      tyf = 19;
      txt = 'ELAPSED TIME';
begin
bar(txb,tyb,txf,tyf,0,vaddr);
outtext(160-(7*length(txt) div 2),tyb+1,txt,smallfnt,vaddr);
bar(txb+1,tyb+8,txb+round(time-1),tyb+15,round(105+time/4),vaddr);
end;

procedure liveshow;
const lxb=130;lyb=182;
      lxf=190;lyf=198;
      lvxb=1;lvyb=92;
      lvxf=61;lvyf=108;

var manv:string;
begin
bar(lxb,lyb,lxf,lyf,0,vaddr);
outtext(lxb+1,lyb+1,'LIVES : ',smallfnt,vaddr);
str(lives,manv);
outint(lxb+1,lyb+8,lives,smallfnt,vaddr);
bar(lvxb,lvyb,lvxf,lvyf,0,vaddr);
outtext(lvxb+1,lvyb+1,'LEVEL : ',smallfnt,vaddr);
str(level,manv);
outint(lvxb+1,lvyb+8,level,smallfnt,vaddr);

end;



procedure presentation;
type trivect=array[1..3] of real;
     poly = record
          v0,v1,v2,v3:trivect;
          lung,lat:byte;
          end;
     table=array[0..259] of real;
const
      orgx=160;
      orgy=100;
      z0=200;
      p=pi/180;

var i,j:integer;
    map:array[1..66,1..23] of byte;
    u,v:trivect;
    workpal      : array[0..767] of byte absolute $a000-48:0;
    pal          : array[0..255,1..3] of byte;
    plan : poly;
    delta,x1,y1,z1,x,y,z,fpr,modu,modv:real;
    tmp,tmp1:real;
    f:file of table;
    fl : file;
    sint,cost:table;
    center : trivect;
    xi,yi,k : integer;

procedure initmap;
var i,j:integer;
    f : file;
begin
assign(f,'title.spr');reset(f,1);seek(f,4);
for i:=1 to 23 do
    for j:=1 to 66 do
    begin
    blockread(f,map[j,i],1);
    end;
end;

procedure Rotate3D(a,b,c : integer);
var sa,sb,sc       : real;
    ca,cb,cc,t1,t2 : real;
    i              : integer;
begin
  with plan do
  begin
  if a<>0 then
    begin
      ca:=cost[a]; sa:=sint[a];
      t1:=v[2];
      v[2]:=t1*ca+v[3]*sa;
      v[3]:=v[3]*ca-t1*sa;
      t1:=u[2];
      u[2]:=t1*ca+u[3]*sa;
      u[3]:=u[3]*ca-t1*sa;
    end;
  end;
end;

label endpres;

begin

loadspr('backgnd2.spr',10);

cls(0,vaddr);cls(0,vga);

initmap;
assign(f,'sincos.tab');
reset(f);
read(f,sint);
read(f,cost);
close(f);

plan.lung:=66;
plan.lat:=23;

plan.v0[1]:=-plan.lung div 2;plan.v0[2]:=-plan.lat div 2;plan.v0[3]:=0;
plan.v1[1]:=plan.lung div 2;plan.v1[2]:=-plan.lat div 2;plan.v1[3]:=0;
plan.v2[1]:=plan.lung div 2;plan.v2[2]:=plan.lat div 2;plan.v2[3]:=0;
plan.v3[1]:=-plan.lung div 2;plan.v3[2]:=plan.lat div 2;plan.v3[3]:=0;

for i:=1 to 3 do
    begin
    v[i]:=plan.v3[i]-plan.v0[i];
    u[i]:=plan.v1[i]-plan.v0[i];
    end;
modv:=sqrt(sqr(v[1])+sqr(v[2])+sqr(v[3]));
modu:=sqrt(sqr(u[1])+sqr(u[2])+sqr(u[3]));
for i:=1 to 3 do
    begin
    v[i]:=v[i]/modv;
    u[i]:=u[i]/modu;
    end;
z:=500;k:=1;y:=plan.lat div 2;

  modinit;
  mix := 7000;   {use 5050 for fast gaming }
  pro := 0; {Leave at 0}
  loop :=4; {0 means mod will play anD stop}
  dev:=7;
  modvolume (255,255,255,255);    { Full volume }
  md:='planetx.mod';
  loop:=4;
  modsetup ( stat, dev, mix, pro, loop, md );


repeat
putspr(10,0,0,normalput,vaddr);
line(160,100-k,160,100+k,0,vaddr);line(160-k,100,160+k,100,0,vaddr);
    for yi:=1 to k do     {y}
        for xi:=1 to k-yi do  {x}
            begin
            {up right}
            putpixel(160+k-yi,100-k+xi,getpixel(160+xi,100-yi,vaddr),vaddr);
            putpixel(160+xi,100-yi,0,vaddr);
            {down right}
            putpixel(160+k-yi,100+k-xi,getpixel(160+xi,100+yi,vaddr),vaddr);
            putpixel(160+xi,100+yi,0,vaddr);
            {down left}
            putpixel(160-k+yi,100+k-xi,getpixel(160-xi,100+yi,vaddr),vaddr);
            putpixel(160-xi,100+yi,0,vaddr);
            {up left}
            putpixel(160-k+yi,100-k+xi,getpixel(160-xi,100-yi,vaddr),vaddr);
            putpixel(160-xi,100-yi,0,vaddr);
            if port[$60]=1 then goto endpres;
            end;
if k<80 then inc(k);
if k mod 3=0 then begin
                  y:=y-1.7;
{                  sound(400);delay(10);nosound;}
                  end;

rotate3d(10,5,5);
x:=-plan.lung div 2;
tmp1:=plan.lat*v[3];
z:=z-5;

for i:=1 to plan.lung do
    begin
    x1:=x;
    y1:=y;
    z1:=z;
    tmp:=z0+z1;
    fpr:=z0/tmp;
    delta:=fpr/(tmp+tmp1);
        for j:=1 to plan.lat do
        begin
        x1:=x1+v[1];
        y1:=y1+v[2];
        z1:=z1+v[3];
        fpr:=fpr-delta;
{        fpr:=z0/(z0+z1);}
        putpixel(orgx+round(x1*fpr),orgy+round(y1*fpr),map[i,j],vaddr);
        if port[$60]=1 then goto endpres;
        end;
   x:=x+u[1];
   y:=y+u[2];
   z:=z+u[3];
   end;
if port[$60]=1 then goto endpres;
flip;
until z=-40;
endpres:

donespr(10);

end;

procedure inittable(cite_bub:byte);
begin
xdist:=word(right-left);ydist:=word(bottom-top);
with spr[2] do
     begin
     xl:=xdist;
     yl:=ydist;
     getmem(spr[2].pspr,xl*yl);
     end;
with spr[11] do
     begin
     xl:=xdist;
     yl:=ydist;
     getmem(spr[11].pspr,xl*yl);
     end;
with spr[12] do
     begin
     xl:=xdist;
     yl:=ydist;
     getmem(spr[12].pspr,xl*yl);
     end;

s:=seg(spr[2].pspr^);o:=ofs(spr[2].pspr^);
for i:=1 to ydist do for j:=1 to xdist do modspr(j,i,0,2);
for i:=1 to xdist do begin
              modspr(i,1,margin,2);
              modspr(i,ydist,margin,2);
end;
for i:=1 to ydist do begin
              modspr(1,i,margin,2);
              modspr(xdist,i,margin,2);
end;

dotx:=1;doty:=ydist;
on_air:=false;toleft:=false;toright:=false;toup:=false;todown:=false;
fx:=40;fy:=1;fxdir:=1;fydir:=0;
area_to_fill:=xdist*ydist;area_filled:=0;
maxtime:=318;time:=0;exitcode:=0;
randomize;
bub_nr:=cite_bub;
for i:=1 to cite_bub do
    begin
    bubcor[i,1]:=3+random(xdist-10);
    bubcor[i,2]:=ydist div 2;
    case random(2) of
    1 : bubdir[i,1]:=-1;
    0 : bubdir[i,1]:=1;
    end;
    case random(2) of
    1 : bubdir[i,2]:=-1;
    0 : bubdir[i,2]:=1;
    end;
    bubcor[i,3]:=1;
    end;
{ Do some initialization }
  clock_ticks := 0;
  counter := $1234DD div 50;

{ Store the current BIOS handler and set up our own }
  GetIntVec(TIMERINTR, @BIOSTimerHandler);
  SetIntVec(TIMERINTR, addr(Handler));
{  GetIntVec(KEYINTR, @BIOSKeyHandler);
  SetIntVec(KEYINTR, addr(KeyHandler));
}

  { Set the PIT channel 0 frequency }
  Port[$43] := $34;
  Port[$40] := counter mod 256;
  Port[$40] := counter div 256;

end;

procedure WOSintro;
begin

loadsound('aonoise.raw',10);
corection:=2;
pcxread('c_wings0.pcx',0,12937);
playsound(10);
delay(6000);
FadeOut(3);
cls(0,vga);
freesound(10);
end;


label startgame,endgame,samelevel;


begin

int9:=meml[0:(9*4)];
memw[0:9*4+2]:=seg(donothing);
memw[0:9*4]:=ofs(donothing);


vga256;
initvscreen;
base:=0;volcnt:=8;
for i:=1 to 9 do
      if resetdsp(i) then begin
                          base:=2*256+i*16;
                          break;
                          end;
if base=0 then begin
                 donevscreen;
                 donevga256;
                 writeln('No SoundBlaster available .');
                 halt;
                 end;

setmixerreg(0,0);
setmixerreg($04,volume);
setmixerreg($22,volume);
speakeron;

{WOSintro;}

first_time:=true;
loadpal('default.pal');setpal;
assign(f,'dotty.fnt');reset(f,1);blockread(f,small,filesize(f));close(f);
loadspr('exit.spr',5);loadspr('start.spr',6);loadspr('volume.spr',7);
loadspr('cursor.spr',8);
loadsound('gameon.raw',1);
loadsound('boing.raw',2);
loadsound('gameover.raw',3);
loadsound('close.raw',4);
loadsound('loser.raw',5);
loadsound('excellnt.raw',6);
loadsound('shipskid.raw',7);

presentation;

with menu[1] do begin x:=115;y:=100;sprnr:=5;end;
with menu[2] do begin x:=145;y:=100;sprnr:=6;end;
with menu[3] do begin x:=175;y:=100;sprnr:=7;end;

repeat

loadspr('mainfrm.spr',10);
if not first_time then begin
                modinit;
                mix := 10050;   {use 5050 for fast gaming }
                pro := 0; {Leave at 0}
                loop :=4; {0 means mod will play anD stop}
                dev:=7;
                modvolume (255,255,255,255);    { Full volume }
                md:='planetx.mod';
                loop:=4;
                modsetup ( stat, dev, mix, pro, loop, md );
                end;
if first_time then first_time:=false;
menucnt:=1;

repeat
key:=port[$60];
case key of
75 : begin
     dec(menucnt);if menucnt<1 then menucnt:=3;
     end;
77 : begin
     inc(menucnt);if menucnt>3 then menucnt:=1;
     end;
end;

if key=28 then case menucnt of
              1 : begin
                  meml[0:(9*4)]:=int9;
                  goto endgame;
                  end;
              2 : goto startgame;
              end;

putspr(10,0,0,normalput,vaddr);

if menucnt=3 then begin
                  case key of
                  72 : if volcnt<11 then inc(volcnt);
                  80 : if volcnt>1 then dec(volcnt);
                  end;
                  volume:=voltable[volcnt];
                  setmixerreg($04,volume);
                  setmixerreg($22,volume);
                  end;
for i:=1 to 3 do with menu[i] do putspr(sprnr,x,y,copyput,vaddr);
with menu[menucnt] do rectangle(x-1,y-1,x+spr[sprnr].xl+1,y+spr[sprnr].yl+1,255,vaddr);
with menu[3] do putspr(8,x+10,y+spr[sprnr].yl-10-volcnt,copyput,vaddr);

flip;

until false;

startgame :
modstop;
playsound(1);
fadeout(3);
donespr(10);
cls(0,vaddr);cls(0,vga);
loadpal('default.pal');setpal;

lives:=3;bubinlevel:=2;score:=0;level:=0;
inittable(bubinlevel);

loadspr('dotty.spr',1);
loadspr('backgnd1.spr',3);

samelevel:
repeat
putspr(3,0,0,normalput,vaddr);
bar(left-10,top-10,right+10,bottom+10,0,vaddr);

putspr(2,left,top,normalput,vaddr);
for i:=1 to bub_nr do putpixel(bubcor[i,1]+left,bubcor[i,2]+top,bub_color,vaddr);
putspr(1,fx-spr[1].xl div 2+left,fy-spr[1].yl div 2+top,copyput,vaddr);
putspr(1,dotx-spr[1].xl div 2+left,doty-spr[1].yl div 2+top,copyput,vaddr);
scoretable;percentage;timebar;liveshow;
{waitretrace;}

flip;
until exitcode<>0;

{ Restore the normal clock frequency }

  Port[$43] := $34;
  Port[$40] := 0;
  Port[$40] := 0;

{ Restore the normal ticker handler }
  SetIntVec(TIMERINTR, @BIOSTimerHandler);
  donespr(2);donespr(11);donespr(12);

  case exitcode of
  1 : playsound(3);
  2 : begin
      playsound(5);
      dec(lives);
      if lives<1 then playsound(3)
                 else begin
                      Fadeout(3);
                      cls(0,vaddr);cls(0,vga);
                      delay(500);
                      loadpal('default.pal');setpal;
                      inittable(bubinlevel);
                      goto samelevel;
                      end;
      end;
  4 : begin
      playsound(6);
      inc(lives);
      if lives>20 then lives:=20;
      inc(level);
      inc(bubinlevel);
      if bubinlevel>8 then bubinlevel:=8;
      Fadeout(3);
      cls(0,vaddr);cls(0,vga);
      delay(1000);
      loadpal('default.pal');setpal;
      inittable(bubinlevel);
      goto samelevel;
      end;
  end;

  Fadeout(3);
  cls(0,vaddr);cls(0,vga);
  loadpal('default.pal');setpal;
  donespr(1);donespr(3);

until false;{game main cycle}

endgame :
modstop;
playsound(4);
fadeout(3);
delay(25);
speakeroff;
Donevscreen;
Donevga256;
end.