
with Componolit.Interfaces.Component;
with Componolit.Interfaces.Types;

package Component with
   SPARK_Mode
is

   procedure Construct (Capability : Componolit.Interfaces.Types.Capability);
   procedure Destruct;

   package Main is new Componolit.Interfaces.Component (Construct, Destruct);

end Component;
