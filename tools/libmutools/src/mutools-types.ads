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

package Mutools.Types
is

   --  Subject event groups.
   type Event_Group_Type is (Vmx_Exit, Vmcall);

   --  Types of physical memory.
   type Memory_Kind is
     (System, System_Vmxon, System_Vmcs, System_Iobm, System_Msrbm, System_Pt,
      Kernel, Kernel_Binary, Kernel_Interface,
      Subject, Subject_Binary, Subject_Zeropage, Subject_Initrd,
      Subject_Channel, Subject_State, Subject_Bios, Subject_Acpi_Rsdp,
      Subject_Acpi_Xsdt, Subject_Acpi_Fadt, Subject_Acpi_Dsdt);

   subtype System_Memory  is Memory_Kind range System  .. System_Pt;
   subtype Kernel_Memory  is Memory_Kind range Kernel  .. Kernel_Interface;
   subtype Subject_Memory is Memory_Kind range Subject .. Subject_Acpi_Dsdt;

end Mutools.Types;