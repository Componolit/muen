
with Debuglog.Client;

package body Component with
   SPARK_Mode
is

   procedure Construct (Capability : Componolit.Interfaces.Types.Capability)
   is
      pragma Unreferenced (Capability);
   begin
      Debuglog.Client.Put_Line ("Construct");
   end Construct;

   procedure Destruct
   is
   begin
      null;
   end Destruct;

end Component;
