
with Musinfo;
with Musinfo.Instance;
with Musinfo.Utils;
with Gneiss.Log;
with Gneiss.Log.Client;
with Gneiss.Block;
with Gneiss.Block.Client;
with Basalt.Strings;

package body Component with
   SPARK_Mode
is

   package CIL renames Gneiss.Log;
   package CIS renames Basalt.Strings;
   package CIB is new Gneiss.Block (Character, Positive, String, Integer, Integer);

   procedure Write (C : in out CIB.Client_Session;
                    I :        Integer;
                    D :    out String);

   procedure Read (C : in out CIB.Client_Session;
                   I :        Integer;
                   D :        String);

   procedure Print_Info;
   procedure Event;

   package CIBC is new CIB.Client (Event, Read, Write);
   package CILC is new Gneiss.Log.Client (Event);

   Log        : CIL.Client_Session;
   Block      : CIB.Client_Session;
   Capability : Gneiss.Capability;

   procedure Construct (Cap : Gneiss.Capability)
   is
   begin
      Capability := Cap;
      CILC.Initialize (Log, Cap, "debuglog1");
   end Construct;

   procedure Destruct
   is
   begin
      null;
   end Destruct;

   procedure Write (C : in out CIB.Client_Session;
                    I :        Integer;
                    D :    out String)
   is
   begin
      null;
   end Write;

   procedure Read (C : in out CIB.Client_Session;
                   I :        Integer;
                   D :        String)
   is
   begin
      null;
   end Read;

   procedure Event
   is
   begin
      case Gneiss.Log.Status (Log) is
         when Gneiss.Initialized =>
            Print_Info;
         when Gneiss.Pending =>
            CILC.Initialize (Log, Capability, "");
         when Gneiss.Uninitialized =>
            Main.Vacate (Capability, Main.Failure);
      end case;
   end Event;

   procedure Print_Info
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
      CILC.Info (Log, "Sdump");
      CILC.Info (Log, "Name: " & String (Name_Obj.Data (1 .. Integer (Name_Obj.Length))));
      CILC.Info (Log, "Tick rate: " & CIS.Image (Musinfo.Instance.TSC_Khz));
      CILC.Info (Log, "Schedule start: " & CIS.Image (Musinfo.Instance.TSC_Schedule_Start));
      CILC.Info (Log, "Schedule end: " & CIS.Image (Musinfo.Instance.TSC_Schedule_End));
      if Memregion = Musinfo.Null_Memregion then
         CILC.Info (Log, "Memregion "
                         & String (Debug_Name.Data (1 .. Integer (Debug_Name.Length)))
                         & " not found");
      else
         CILC.Info (Log, "Memregion "
                         & String (Debug_Name.Data (1 .. Integer (Debug_Name.Length)))
                         & " found at "
                         & CIS.Image (Memregion.Address));
      end if;
      while Musinfo.Instance.Has_Element (Resit) loop
         Resource := Musinfo.Instance.Element (Resit);
         case Resource.Kind is
            when Musinfo.Res_None =>
               CILC.Info (Log, "Found no resource");
            when Musinfo.Res_Memory =>
               CILC.Info (Log, "Found memory "
                               & (if Resource.Mem_Data.Flags.Channel then "channel" else "resource")
                               & ": "
                               & String (Resource.Name.Data (1 .. Integer (Resource.Name.Length)))
                               & (if Resource.Mem_Data.Flags.Writable then " (rw) " else " (ro) ")
                               & " at "
                               & CIS.Image (Resource.Mem_Data.Address)
                               & " with size "
                               & CIS.Image (Resource.Mem_Data.Size));
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
      CILC.Info (Log, "Running block test...");
      CILC.Info (Log, "Initializing...");
      CIBC.Initialize (Block, Capability, "blockdev1", 42);
      if CIB.Initialized (Block) then
         CILC.Info (Log, "Initialized.");
         CILC.Info (Log, "Block size: " & CIS.Image (Long_Integer (CIB.Block_Size (Block))));
         CILC.Info (Log, "Block count: " & CIS.Image (Long_Integer (CIB.Block_Count (Block))));
      else
         CILC.Warning (Log, "Initialization failed.");
      end if;
      CILC.Info (Log, "Finished sdump");
      Main.Vacate (Capability, Main.Success);
   end Print_Info;

end Component;
