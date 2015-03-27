--  This package has been generated automatically by GNATtest.
--  You are allowed to add your code to the bodies of test routines.
--  Such changes will be kept during further regeneration of this file.
--  All code placed outside of test routine bodies will be lost. The
--  code intended to set up and tear down the test environment should be
--  placed into Acpi.Utils.Test_Data.

with AUnit.Assertions; use AUnit.Assertions;

package body Acpi.Utils.Test_Data.Tests is


--  begin read only
   procedure Test_Indent (Gnattest_T : in out Test);
   procedure Test_Indent_399a7a (Gnattest_T : in out Test) renames Test_Indent;
--  id:2.2/399a7ad24f629c80/Indent/1/0/
   procedure Test_Indent (Gnattest_T : in out Test) is
   --  acpi-utils.ads:28:4:Indent
--  end read only

      pragma Unreferenced (Gnattest_T);

   begin
      Assert (Condition => True,
              Message   => "Already tested in Libmutools");
--  begin read only
   end Test_Indent;
--  end read only


--  begin read only
   procedure Test_Add_Dev_IRQ_Resource (Gnattest_T : in out Test);
   procedure Test_Add_Dev_IRQ_Resource_386422 (Gnattest_T : in out Test) renames Test_Add_Dev_IRQ_Resource;
--  id:2.2/386422a502039cf0/Add_Dev_IRQ_Resource/1/0/
   procedure Test_Add_Dev_IRQ_Resource (Gnattest_T : in out Test) is
   --  acpi-utils.ads:35:4:Add_Dev_IRQ_Resource
--  end read only

      pragma Unreferenced (Gnattest_T);

   begin

      AUnit.Assertions.Assert
        (Gnattest_Generated.Default_Assert_Value,
         "Test not implemented.");

--  begin read only
   end Test_Add_Dev_IRQ_Resource;
--  end read only

end Acpi.Utils.Test_Data.Tests;
