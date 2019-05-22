with SK.CPU;

with Debuglog.Client;

procedure Hello_World
is
begin
   Debuglog.Client.Put_Line ("Hello_World");
   SK.CPU.Stop;
end Hello_World;
