--
--  Copyright (C) 2016  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2016  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

with Skp.Subjects;

package SK.Subjects_MSR_Store
with
   Abstract_State => (State with External => (Async_Writers, Async_Readers)),
   Initializes    => State
is

   --  Clear MSR values in storage area of subject with given ID.
   procedure Clear_MSRs (ID : Skp.Subject_Id_Type)
   with
      Global  => (In_Out => State),
      Depends => (State =>+ ID),
      Pre     => Skp.Subjects.Get_MSR_Count (Subject_Id => ID) > 0;

end SK.Subjects_MSR_Store;
