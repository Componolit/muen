
pragma Warnings (Off, "unit ""Debuglog.Client"" is not referenced");
with Componolit.Runtime.Debug;
with Debuglog.Client;
with SK.CPU;
with Musinfo;
with Musinfo.Instance;

procedure Sdump with
   SPARK_Mode
is
   use type Musinfo.Memregion_Type;
   Name_Obj : constant Musinfo.Name_Type := Musinfo.Instance.Subject_Name;
   Debug_Name : constant Musinfo.Name_Type :=
      (Length    => 8,
       Padding   => 0,
       Data      => ('d', 'e', 'b', 'u', 'g', 'l', 'o', 'g',
                     others => Character'First),
       Null_Term => Character'First);
   Memregion : constant Musinfo.Memregion_Type :=
      Musinfo.Instance.Memory_By_Name (Debug_Name);
begin
   Componolit.Runtime.Debug.Log_Debug ("Sdump");
   Componolit.Runtime.Debug.Log_Debug
      ("Name: " & String (Name_Obj.Data (1 .. Integer (Name_Obj.Length))));
   if Memregion = Musinfo.Null_Memregion then
      Componolit.Runtime.Debug.Log_Debug
         ("Memregion "
          & String (Debug_Name.Data (1 .. Integer (Debug_Name.Length)))
          & " not found");
   else
      Componolit.Runtime.Debug.Log_Debug
         ("Memregion "
          & String (Debug_Name.Data (1 .. Integer (Debug_Name.Length)))
          & " found");
   end if;
   SK.CPU.Stop;
end Sdump;
