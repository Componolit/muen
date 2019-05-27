with SK.CPU;

with Debuglog.Client;

procedure Hello_World
is
   function Hw return String
   is
   begin
      return "Hello_World: Hello World!";
   end Hw;
begin
   Debuglog.Client.Put_Line (Hw);
   SK.CPU.Stop;
end Hello_World;
