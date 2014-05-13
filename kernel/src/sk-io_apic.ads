--
--  Copyright (C) 2013  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2013  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

package SK.IO_Apic
with
   Abstract_State =>
     (State with External => (Async_Writers, Async_Readers, Effective_Writes)),
   Initializes    => State
is

   --  Interrupt trigger mode.
   type Trigger_Kind is (Edge, Level);

   --  Route IRQ as interrupt with specified vector to APIC given by
   --  destination id.
   procedure Route_IRQ
     (IRQ            : SK.Byte;
      Vector         : SK.Byte;
      Trigger_Mode   : Trigger_Kind;
      Destination_Id : SK.Byte)
   with
      Global  => (Output => State),  --  XXX Logically output state *is* In_Out
      Depends => (State => (Destination_Id, IRQ, Trigger_Mode, Vector));

   --  Mask/disable interrupt delivery for specified IRQ.
   procedure Mask_Interrupt (IRQ : SK.Byte)
   with
      Global  => (In_Out => State),
      Depends => (State =>+ IRQ);

   --  Unmask/enable interrupt delivery for specified IRQ.
   procedure Unmask_Interrupt (IRQ : SK.Byte)
   with
      Global  => (In_Out => State),
      Depends => (State =>+ IRQ);

end SK.IO_Apic;
