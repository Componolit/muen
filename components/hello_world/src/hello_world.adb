
pragma Warnings (Off, "unit ""Debuglog.Client"" is not referenced");
with Debuglog.Client;
with SK.CPU;
with Runtime_Lib.Debug;

procedure Hello_World
is
   function Hw return String
   is
   begin
      return "Hello_World: Hello World!";
   end Hw;
begin
   Runtime_Lib.Debug.Log_Debug (Hw);
   Runtime_Lib.Debug.Log_Debug ("Info");
   Runtime_Lib.Debug.Log_Warning ("Warning");
   Runtime_Lib.Debug.Log_Error ("Error");
   SK.CPU.Stop;
end Hello_World;
