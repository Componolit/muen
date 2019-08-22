
with Componolit.Gneiss.Component;
with Componolit.Gneiss.Types;

package Component with
   SPARK_Mode
is

   procedure Construct (Capability : Componolit.Gneiss.Types.Capability);
   procedure Destruct;

   package Main is new Componolit.Gneiss.Component (Construct, Destruct);

end Component;
