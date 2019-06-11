with SK.CPU;

with Debuglog.Client;
with Musinfo;
with Musinfo.Instance;
with Musinfo.Utils;

procedure Hello_World
is
   use type Musinfo.Memregion_Type;
   Debug_Name : constant Musinfo.Name_Type :=
      (Length    => 8,
       Padding   => 0,
       Data      => ('d', 'e', 'b', 'u', 'g', 'l', 'o', 'g',
                     others => Character'First),
       Null_Term => Character'First);
   Memregion : constant Musinfo.Memregion_Type :=
      Musinfo.Instance.Memory_By_Name (Debug_Name);
   Resit : Musinfo.Utils.Resource_Iterator_Type :=
      Musinfo.Instance.Create_Resource_Iterator;
   Resource : Musinfo.Resource_Type;
begin
   Debuglog.Client.Put_Line ("Hello_World");
   Debuglog.Client.Put_Line ("Checking debuglog:");
   if Memregion /= Musinfo.Null_Memregion then
      Debuglog.Client.Put_Line ("Found.");
   else
      Debuglog.Client.Put_Line ("Not found.");
   end if;
   Debuglog.Client.Put_Line ("Searching memory resources:");
   while Musinfo.Instance.Has_Element (Resit) loop
      Resource := Musinfo.Instance.Element (Resit);
      case Resource.Kind is
         when Musinfo.Res_Memory =>
            Debuglog.Client.Put_Line (String (Resource.Name.Data));
         when others =>
            null;
      end case;
      Musinfo.Instance.Next (Resit);
   end loop;
   Debuglog.Client.Put_Line ("Checks finished.");
   SK.CPU.Stop;
end Hello_World;
