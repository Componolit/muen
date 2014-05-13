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

with X86_64;

package SK.Apic
is

   --  Place local APIC in x2APIC mode and set bit 8 of the APIC spurious
   --  vector register (SVR).
   procedure Enable
   with
      Global  => (In_Out => X86_64.State),
      Depends => (X86_64.State =>+ null);

   --  Startup AP processors by sending INIT-SIPI-SIPI IPI sequence, see Intel
   --  SDM 3A chapter 8.4.4.
   procedure Start_AP_Processors
   with
      Global  => (In_Out => X86_64.State),
      Depends => (X86_64.State =>+ null);

   --  Return local APIC ID.
   function Get_ID return SK.Byte
   with
      Global  => (Input => X86_64.State);

   --  Signal interrupt servicing completion.
   procedure EOI
   with
      Global  => (In_Out => X86_64.State),
      Depends => (X86_64.State =>+ null);

   --  Send Interprocessor Interrupt (IPI) with given vector to the CPU core
   --  identified by APIC id.
   procedure Send_IPI
     (Vector  : SK.Byte;
      Apic_Id : SK.Byte)
   with
      Global  => (In_Out => X86_64.State),
      Depends => (X86_64.State =>+ (Apic_Id, Vector));

end SK.Apic;
