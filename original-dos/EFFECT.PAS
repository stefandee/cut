program get_a_screen;

uses images,graphics;
var     f :file;
        b:byte absolute $a000:0;
        p :pointer;
        xl,yl:word;
        x,y : integer;

procedure lvmload(fname:string);
var f:file;
    b:byte absolute $a000:0;
begin
assign(f,fname);
reset(f,1);
blockread(f,workpal,768);
setpal;
with spr[1] do
     begin
     xl:=320;yl:=200;
     getmem(pspr,64000);
     blockread(f,pspr^,64000);
     end;
putspr(1,0,0,normalput,vaddr);
flip;
close(f);
end;

var i,j,k : integer;

begin

vga256;
initvscreen;
lvmload('frc5.lvm');
for k:=0 to 90 do
    begin
    line(160,100-k,160,100+k,0,vaddr);line(160-k,100,160+k,100,0,vaddr);
    for y:=1 to k do     {y}
        for x:=1 to k-y do  {x}
            begin
            {up right}
            putpixel(160+k-y,100-k+x,getpixel(160+x,100-y,vaddr),vaddr);
            putpixel(160+x,100-y,0,vaddr);
            {down right}
            putpixel(160+k-y,100+k-x,getpixel(160+x,100+y,vaddr),vaddr);
            putpixel(160+x,100+y,0,vaddr);
            {down left}
            putpixel(160-k+y,100+k-x,getpixel(160-x,100+y,vaddr),vaddr);
            putpixel(160-x,100+y,0,vaddr);
            {up left}
            putpixel(160-k+y,100-k+x,getpixel(160-x,100-y,vaddr),vaddr);
            putpixel(160-x,100-y,0,vaddr);
            end;
    waitretrace;
    flip;
    putspr(1,0,0,normalput,vaddr);
    end;


readln;
donevga256;
end.


