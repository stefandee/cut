uses dos,crt;

var int9save : pointer;
{$F+}
procedure tst;
begin
asm pushf
    iret
end;
end;
{$F-}

begin
clrscr;
{new(int9save);}
getintvec(9,int9save);
writeln('segment / offset with getintvec : ',seg(int9save^),':',ofs(int9save^));
writeln('segment / offset with mem       : ',memw[0:9*4+2],':',memw[0:9*4]);
writeln('segment / offset of procedure : ',seg(tst),':',ofs(tst));
setintvec(9,addr(tst));
delay(1000);
writeln('segment / offset with getintvec : ',seg(int9save^),':',ofs(int9save^));
writeln('segment / offset with mem       : ',memw[0:9*4+2],':',memw[0:9*4]);
setintvec(9,int9save);
writeln('segment / offset with getintvec : ',seg(int9save^),':',ofs(int9save^));
writeln('segment / offset with mem       : ',memw[0:9*4+2],':',memw[0:9*4]);
readln;
end.