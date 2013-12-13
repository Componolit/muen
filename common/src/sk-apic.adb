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

with SK.CPU;
with SK.Constants;

package body SK.Apic
is

   ENABLE_APIC         : constant := 8;
   ENABLE_X2_MODE_FLAG : constant := 10;

   APIC_BSP_FLAG : constant := 8;

   MSR_X2APIC_ID  : constant := 16#802#;
   MSR_X2APIC_EOI : constant := 16#80b#;
   MSR_X2APIC_SVR : constant := 16#80f#;
   MSR_X2APIC_ICR : constant := 16#830#;

   Ipi_Init_Broadcast  : constant := 16#000c4500#;
   Ipi_Start_Broadcast : constant := 16#000c4600#;

   -------------------------------------------------------------------------

   --  Write given value to the ICR register of the local APIC.
   procedure Write_ICR (Value : SK.Word64)
   --# global
   --#    in out X86_64.State;
   --# derives
   --#    X86_64.State from *, Value;
   is
      Low_Dword, High_Dword : SK.Word32;
   begin
      Low_Dword  := SK.Word32'Mod (Value);
      High_Dword := SK.Word32'Mod (Value / 2 ** 32);

      CPU.Write_MSR (Register => MSR_X2APIC_ICR,
                     Low      => Low_Dword,
                     High     => High_Dword);
   end Write_ICR;

   -------------------------------------------------------------------------

   --  Busy-sleep for a given (scaled) period of time.
   procedure Sleep (Count : Positive)
   --# derives null from Count;
   is
   begin
      --# accept Flow, 10, "Passing time by busy looping";
      for I in Integer range 1 .. Count * (2 ** 8) loop
         null;
      end loop;
      --# end accept;
      --# accept Flow, 35, Count, "Count controls wait time";
   end Sleep;

   -------------------------------------------------------------------------

   procedure Enable
   is
      Base, Svr : SK.Word64;
   begin

      --  Enable x2APIC mode.

      Base := CPU.Get_MSR64 (Register => Constants.IA32_APIC_BASE);
      Base := SK.Bit_Set (Value => Base,
                          Pos   => ENABLE_X2_MODE_FLAG);
      CPU.Write_MSR64 (Register => Constants.IA32_APIC_BASE,
                       Value    => Base);

      --  Set bit 8 of the APIC spurious vector register (SVR).

      Svr := CPU.Get_MSR64 (Register => MSR_X2APIC_SVR);
      Svr := SK.Bit_Set (Value => Svr,
                         Pos   => ENABLE_APIC);
      CPU.Write_MSR64 (Register => MSR_X2APIC_SVR,
                       Value    => Svr);
   end Enable;

   -------------------------------------------------------------------------

   procedure EOI
   is
   begin
      CPU.Write_MSR64 (Register => MSR_X2APIC_EOI,
                       Value    => 0);
   end EOI;

   -------------------------------------------------------------------------

   function Get_ID return SK.Byte
   is
      ID, Unused : SK.Word32;
   begin

      --# accept Flow, 10, Unused, "Result unused";

      CPU.Get_MSR (Register => MSR_X2APIC_ID,
                   Low      => ID,
                   High     => Unused);

      --# accept Flow, 33, Unused, "Result unused";

      return SK.Byte'Mod (ID);
   end Get_ID;

   -------------------------------------------------------------------------

   function Is_BSP return Boolean
   is
      Base : SK.Word64;
   begin
      Base := CPU.Get_MSR64 (Register => Constants.IA32_APIC_BASE);
      return SK.Bit_Test (Value => Base,
                          Pos   => APIC_BSP_FLAG);
   end Is_BSP;

   -------------------------------------------------------------------------

   procedure Start_AP_Processors
   is
   begin
      Write_ICR (Value => Ipi_Init_Broadcast);
      Sleep (Count => 10);

      Write_ICR (Value => Ipi_Start_Broadcast);
      Sleep (Count => 200);

      Write_ICR (Value => Ipi_Start_Broadcast);
      Sleep (Count => 200);
   end Start_AP_Processors;

   -------------------------------------------------------------------------

   procedure Send_IPI
     (Vector  : SK.Byte;
      Apic_Id : SK.Byte)
   is
      ICR_Value : SK.Word64;
   begin
      ICR_Value := SK.Word64 (Apic_Id) * 2 ** 32;
      ICR_Value := ICR_Value + SK.Word64 (Vector);
      Write_ICR (Value => ICR_Value);
   end Send_IPI;

end SK.Apic;
