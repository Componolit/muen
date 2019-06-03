
pragma Warnings (Off, "unit ""Debuglog.Client"" is not referenced");
with Componolit.Runtime.Debug;
with Debuglog.Client;
with SK.CPU;
with Musinfo;
with Musinfo.Instance;

procedure Sdump
is
   pragma Warnings (Off, "constant ""Name_Obj"" is not referenced");
   Name_Obj : constant Musinfo.Name_Type := Musinfo.Instance.Subject_Name;
begin
   Componolit.Runtime.Debug.Log_Debug ("Sdump");
   --  Componolit.Runtime.Debug.Log_Debug
   --     ("Name: " & String (Name_Obj.Data (1 .. Integer (Name_Obj.Length))));
   SK.CPU.Stop;
   pragma Warnings (On, "constant ""Name_Obj"" is not referenced");
end Sdump;
