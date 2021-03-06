--  This package is intended to set up and tear down  the test environment.
--  Once created by GNATtest, this package will never be overwritten
--  automatically. Contents of this package can be modified in any way
--  except for sections surrounded by a 'read only' marker.

with Ada.Exceptions;
with Ada.Directories;
with Ada.Strings.Unbounded;

with AUnit.Test_Fixtures;

with Bin_Split.Run;

with Mutools.Bfd;

with Test_Utils;

package Bin_Split.Files.Test_Data is

--  begin read only
   type Test is new AUnit.Test_Fixtures.Test_Fixture
--  end read only
   with null record;

   procedure Set_Up (Gnattest_T : in out Test);
   procedure Tear_Down (Gnattest_T : in out Test);

end Bin_Split.Files.Test_Data;
