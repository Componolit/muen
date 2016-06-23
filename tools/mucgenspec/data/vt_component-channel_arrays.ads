package Vt_Component.Channel_Arrays
is

   Input_Arr_Address_Base  : constant := 16#0001_0000#;
   Input_Arr_Element_Size  : constant := 16#1000#;
   Input_Arr_Element_Count : constant := 2;
   Input_Arr_Vector_Base   : constant := 32;

   Output_Arr_Address_Base  : constant := 16#0002_0000#;
   Output_Arr_Element_Size  : constant := 16#2000#;
   Output_Arr_Element_Count : constant := 3;
   Output_Arr_Event_Base    : constant := 16;

end Vt_Component.Channel_Arrays;