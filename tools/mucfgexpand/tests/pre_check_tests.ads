--
--  Copyright (C) 2014  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2014  Adrian-Ken Rueegsegger <ken@codelabs.ch>
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

with Ahven.Framework;

package Pre_Check_Tests
is

   type Testcase is new Ahven.Framework.Test_Case with null record;

   --  Initialize testcase.
   procedure Initialize (T : in out Testcase);

   --  Check tau0 presence in scheduling plan.
   procedure Tau0_Presence_In_Scheduling;

   --  Check subject monitor references.
   procedure Subject_Monitor_References;

   --  Check subject channel references.
   procedure Subject_Channel_References;

   --  Check channel reader/writer counts.
   procedure Channel_Reader_Writer;

   --  Check event IDs of channel writers with HasEvent set.
   procedure Channel_Writer_Has_Event_ID;

   --  Check vector numbers of channel readers with HasEvent set.
   procedure Channel_Reader_Has_Event_Vector;

   --  Check presence of logical CPU count attribute.
   procedure Platform_CPU_Count_Presence;

end Pre_Check_Tests;