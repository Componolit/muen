
with Musinfo;
with Musinfo.Instance;
with Musinfo.Utils;
with Componolit.Interfaces.Log;
with Componolit.Interfaces.Log.Client;

package body Component with
   SPARK_Mode
is

   package CIL renames Componolit.Interfaces.Log;
   package CILC renames Componolit.Interfaces.Log.Client;

   Log : CIL.Client_Session := CILC.Create;

   procedure Construct (Cap : Componolit.Interfaces.Types.Capability)
   is
      use type Musinfo.Memregion_Type;
      Name_Obj : constant Musinfo.Name_Type := Musinfo.Instance.Subject_Name;
      Debug_Name : constant Musinfo.Name_Type :=
         (Length    => 8,
          Padding   => 0,
          Data      => ('d', 'e', 'b', 'u', 'g', 'l', 'o', 'g', others => Character'First),
          Null_Term => Character'First);
      Memregion : constant Musinfo.Memregion_Type := Musinfo.Instance.Memory_By_Name (Debug_Name);
      Resit : Musinfo.Utils.Resource_Iterator_Type := Musinfo.Instance.Create_Resource_Iterator;
      Resource : Musinfo.Resource_Type;
   begin
      CILC.Initialize (Log, Cap, "debuglog1");
      if CILC.Initialized (Log) then
         CILC.Info (Log, "Sdump");
         CILC.Info (Log, "Name: " & String (Name_Obj.Data (1 .. Integer (Name_Obj.Length))));
         if Memregion = Musinfo.Null_Memregion then
            CILC.Info (Log, "Memregion "
                            & String (Debug_Name.Data (1 .. Integer (Debug_Name.Length)))
                            & " not found");
         else
            CILC.Info (Log, "Memregion "
                            & String (Debug_Name.Data (1 .. Integer (Debug_Name.Length)))
                            & " found at "
                            & CIL.Image (CIL.Unsigned (Memregion.Address)));
         end if;
         while Musinfo.Instance.Has_Element (Resit) loop
            Resource := Musinfo.Instance.Element (Resit);
            case Resource.Kind is
               when Musinfo.Res_None =>
                  CILC.Info (Log, "Found no resource");
               when Musinfo.Res_Memory =>
                  CILC.Info (Log, "Found memory resource: "
                                  & String (Resource.Name.Data (1 .. Integer (Resource.Name.Length)))
                                  & " at "
                                  & CIL.Image (CIL.Unsigned (Resource.Mem_Data.Address))
                                  & " with size "
                                  & CIL.Image (CIL.Unsigned (Resource.Mem_Data.Size)));
               when Musinfo.Res_Event =>
                  CILC.Info (Log, "Found event resource: "
                                  & String (Resource.Name.Data (1 .. Integer (Resource.Name.Length))));
               when Musinfo.Res_Vector =>
                  CILC.Info (Log, "Found vector resource: "
                                  & String (Resource.Name.Data (1 .. Integer (Resource.Name.Length))));
               when Musinfo.Res_Device =>
                  CILC.Info (Log, "Found device resource: "
                                  & String (Resource.Name.Data (1 .. Integer (Resource.Name.Length))));
            end case;
            Musinfo.Instance.Next (Resit);
         end loop;
         CILC.Info (Log, "Finished sdump");
      end if;
   end Construct;

   procedure Destruct
   is
   begin
      null;
   end Destruct;

end Component;
