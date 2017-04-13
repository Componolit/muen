--
--  Copyright (C) 2017  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2017  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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
with SK.Dump;

package body SK.MCE
is

   -------------------------------------------------------------------------

   function Is_Valid return Boolean
   is
      Unused_EAX, Unused_EBX, Unused_ECX, EDX : Word32;
   begin
      Unused_EAX := 1;
      Unused_ECX := 0;

      pragma Warnings
        (GNATprove, Off, "unused assignment to ""Unused_E*X""",
         Reason => "Only parts of the CPUID result is needed");
      CPU.CPUID
        (EAX => Unused_EAX,
         EBX => Unused_EBX,
         ECX => Unused_ECX,
         EDX => EDX);
      pragma Warnings (GNATprove, On, "unused assignment to ""Unused_E*X""");

      return Bit_Test
        (Value => Word64 (EDX),
         Pos   => Constants.CPUID_FEATURE_MCE)
        and then
          Bit_Test
            (Value => Word64 (EDX),
             Pos   => Constants.CPUID_FEATURE_MCA);
   end Is_Valid;

   -------------------------------------------------------------------------

   procedure Enable
   is
      Bank_Count : Byte;
      CR4, Value : Word64;
   begin
      Value := CPU.Get_MSR64 (Register => Constants.IA32_MCG_CAP);
      pragma Debug (Dump.Print_Message_32
                    (Msg  => "MCE: IA32_MCG_CAP",
                     Item => Word32'Mod (Value)));
      Bank_Count := Byte (Value and 16#ff#);

      if Bit_Test
        (Value => Value,
         Pos   => Constants.MCG_CTL_P_FLAG)
      then
         pragma Debug
           (Dump.Print_Message
              (Msg => "MCE: IA32_MCG_CTL present, "
               & "enabling all MCA features"));
         CPU.Write_MSR64
           (Register => Constants.IA32_MCG_CTL,
            Value    => Word64'Last);
      end if;

      for I in Integer range 0 .. Integer (Bank_Count) - 1 loop
         CPU.Write_MSR64
           (Register => Word32 (Constants.IA32_MC0_CTL + I * 4),
            Value    => Word64'Last);
      end loop;

      for I in Integer range 0 .. Integer (Bank_Count) - 1 loop
         CPU.Write_MSR64
           (Register => Word32 (Constants.IA32_MC0_STATUS + I * 4),
            Value    => 0);
      end loop;

      CR4 := CPU.Get_CR4;
      CR4 := Bit_Set (Value => CR4,
                      Pos   => Constants.CR4_MCE_FLAG);
      CPU.Set_CR4 (Value => CR4);
   end Enable;

end SK.MCE;
