
with Gneiss.Component;
with Gneiss.Types;

package Component with
   SPARK_Mode
is

   procedure Construct (Capability : Gneiss.Types.Capability);
   procedure Destruct;

   package Main is new Gneiss.Component (Construct, Destruct);

end Component;
