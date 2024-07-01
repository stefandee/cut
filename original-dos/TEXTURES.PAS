program textures2;

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
    sint,cost:table;
    center : trivect;



procedure initmap;
var i,j:integer;
    f : file;
begin
assign(f,'title.spr');reset(f,1);seek(f,4);
for i:=1 to 23 do
    for j:=1 to 66 do
    begin
    blockread(f,map[j,i],1);
    putpixel(j,i,map[j,i],vaddr);
    end;
putspr(1,100,50,normalput,vaddr);
flip;
readln;
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
  cb:=cost[b]; sb:=sint[b];
  cc:=cost[c]; sc:=sint[c];
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

begin

vga256;
initvscreen;
loadpal('default.pal');
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
z:=500;

repeat

rotate3d(10,5,5);
cls(0,vaddr);
x:=-plan.lung div 2;y:=0;tmp1:=plan.lat*v[3];
z:=z-5;

for i:=1 to plan.lung do
    begin
    x1:=x;
    y1:=y;
    z1:=z;
    {tmp:=z0+z1;
    fpr:=z0/tmp;
    delta:=fpr/(tmp+tmp1);}
    for j:=1 to plan.lat do
        begin
        x1:=x1+v[1];
        y1:=y1+v[2];
        z1:=z1+v[3];
        fpr:=z0/(z0+z1);;
        putpixel(orgx+round(x1*fpr),orgy-30+round(y1*fpr),map[i,j],vaddr);
        end;
   x:=x+u[1];
   y:=y+u[2];
   z:=z+u[3];
   end;
flip;
until z=-40;
readln;
donevga256;
end.



