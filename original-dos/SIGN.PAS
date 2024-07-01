var fs,fd:file;
    b:byte;
    i:integer;
    s:shortint;
begin
assign(fs,'dorrknar.raw');reset(fs,1);
assign(fd,'close.raw');rewrite(fd,1);
for i:=1 to filesize(fs) do
    begin
    blockread(fs,b,1);
    b:=b+128;
    blockwrite(fd,b,1);
    end;
end.
