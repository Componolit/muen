with SK.Console_VGA;

package SK.Legacy_VGA
is

   type Width_Type  is range 1 .. 80;
   type Height_Type is range 1 .. 25;

   package VGA is new Console_VGA
     (Width_Type    => Width_Type,
      Height_Type   => Height_Type,
      Base_Address  => 16#b_8000#,
      Cursor_Offset => 0);

end SK.Legacy_VGA;
