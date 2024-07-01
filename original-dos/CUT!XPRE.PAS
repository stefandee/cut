program textures2;
{$M 64000,0,200000}

uses dos,crt,graphics;

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
{  a:=a*p; b:=b*p; c:=c*p;}
  ca:=cost[a]; sa:=sint[a];
{  cb:=cost[b]; sb:=sint[b];
  cc:=cost[c]; sc:=sint[c];
}
  if a<>0 then
    begin
      t1:=v[2];
      v[2]:=t1*ca+v[3]*sa;
      v[3]:=v[3]*ca-t1*sa;
      t1:=u[2];
      u[2]:=t1*ca+u[3]*sa;
      u[3]:=u[3]*ca-t1*sa;
{      u:=v2[2];
      v2[2]:=u*ca+v2[3]*sa;
      v2[3]:=v2[3]*ca-u*sa;
      u:=v3[2];
      v3[2]:=u*ca+v3[3]*sa;
      v3[3]:=v3[3]*ca-u*sa;}
    end;
    {if b<>0 then
    begin
      u:=obj[i,3];v:=obj[i,1];
      obj[i,1]:=v*cb-u*sb;
      obj[i,3]:=u*cb+v*sb;
    end;
    if c<>0 then
    begin
      u:=obj[i,1];
      obj[i,1]:=u*cc+obj[i,2]*sc;
      obj[i,2]:=obj[i,2]*cc-u*sc;
    end;}
  end;
end;

procedure lvmload(fname:string);
var f : file;
begin
assign(f,fname);
reset(f,1);
seek(f,768);
with spr[1] do
     begin
     xl:=320;yl:=200;
     getmem(pspr,64000);
     blockread(f,pspr^,64000);
     end;
end;


begin

vga256;
initvscreen;
loadpal('default.pal');
loadspr('backgnd2.spr',1);
setpal;

cls(0,vaddr);
cls(0,vga);

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
  mix := 5050;   {use 5050 for fast gaming }
  pro := 0; {Leave at 0}
  loop :=0; {0 means mod will play anD stop}
  dev:=7;
  modvolume (255,255,255,255);    { Full volume }
  md:='war.mod';
  loop:=4;
  modsetup ( stat, dev, mix, pro, loop, md );


repeat
putspr(1,0,0,normalput,vaddr);
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
        end;
   x:=x+u[1];
   y:=y+u[2];
   z:=z+u[3];
   end;
flip;
until z=-40;
donespr(1);
getimage(1,0,0,319,199);
cls(0,vga);
cls(0,vaddr);
putspr(1,0,0,normalput,vaddr);
assign(fl,'mainfrm.spr');reset(fl,1);
with spr[1] do
     begin
     blockwrite(fl,xl,2);
     blockwrite(fl,yl,2);
     blockwrite(fl,pspr^,64000);
     end;
close(fl);
flip;
readln;
donevga256;
end.



