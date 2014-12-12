--
--  Copyright (C) 2013, 2014  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2013, 2014  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

with SK;

with Types;
with Devices.i8042;
with Debug_Ops;

package body Exit_Handlers.IO_Instruction
is

   use Types;
   use Subject_Info;

   -------------------------------------------------------------------------

   --  Ignore acces to port: Do nothing on write, fake read.
   procedure Ignore_Access (Info : IO_Info_Type)
   with
      Global  => (In_Out => Subject_Info.State),
      Depends => (Subject_Info.State =>+ Info)
   is
      use type SK.Word64;

      RAX  : constant SK.Word64 := State.Regs.RAX;
      Mask : SK.Word64          := 0;
   begin
      pragma Debug (Debug, Debug_Ops.Put_String (Item => "Port 16#"));
      pragma Debug (Debug, Debug_Ops.Put_Word16 (Item => Info.Port_Number));
      pragma Debug (Debug, Debug_Ops.Put_String (Item => "# ignore "));

      case Info.Size is
         when One_Byte  => Mask := 16#ff#;
         when Two_Byte  => Mask := 16#ffff#;
         when Four_Byte => Mask := 16#ffff_ffff#;
         when others    => null;
      end case;

      if Info.Direction = Dir_In then
         State.Regs.RAX := RAX or Mask;
      end if;

      pragma Debug (Debug and then Info.Direction = Dir_In,
                    Debug_Ops.Put_Line (Item => "read"));
      pragma Debug (Debug and then Info.Direction = Dir_Out,
                    Debug_Ops.Put_Value32
                      (Message => "write",
                       Value   => SK.Word32'Mod (RAX and Mask)));
   end Ignore_Access;

   -------------------------------------------------------------------------

   procedure Process (Halt : out Boolean)
   is
      Exit_Q : constant SK.Word64    := State.Exit_Qualification;
      Info   : constant IO_Info_Type := To_IO_Info (Qualification => Exit_Q);
   begin
      Halt := False;

      if Info.String_Instr or Info.REP_Prefixed then
         pragma Debug
           (Debug_Ops.Put_Line
              (Item => "I/O instructions with string and REP not supported"));
         Halt := True;
      elsif Info.Size not in One_Byte | Two_Byte | Four_Byte then
         pragma Debug
           (Debug_Ops.Put_Value8
              (Message => "I/O instruction with invalid access size",
               Value   => SK.Byte (Info.Size)));
         Halt := True;
      else
         case Info.Port_Number is
            when 16#0020# |  --  PIC_MASTER_CMD   (hardcoded)
                 16#0021# |  --  PIC_MASTER_DATA  (hardcoded)
                 16#00a0# |  --  PIC_SLAVE_CMD    (hardcoded)
                 16#00a1# |  --  PIC_SLAVE_DATA   (hardcoded)
                 16#0040# |  --  i8253/4 PIT_CH0  (hardcoded)
                 16#0043# |  --  i8253/4 PIT_MODE (hardcoded)
                 16#0080# |  --  PORT80           (hardcoded)
                 16#02e9# |  --  COM 4            (configurable)
                 16#02f9# |  --  COM 2            (configurable)
                 16#02fa# |  --  82C710 C&T mouse port chip   (conf.)
                 16#0390# |  --  82C710 C&T mouse port chip   (conf.)
                 16#0391# |  --  82C710 C&T mouse port chip   (conf.)
                 16#03e9# |  --  COM 3            (configurable)
                 16#04d0# |  --  PIC_ELCR1        (hardcoded,ACPI)
                 16#04d1# |  --  PIC_ELCR2        (hardcoded,ACPI)
                 16#0cf8# |  --  PCI Addr         (hardcoded)
                 16#0cf9# |  --  PCI Addr         (hardcoded)
                 16#0cfa# |  --  PCI Addr         (hardcoded)
                 16#0cfb# |  --  PCI Addr         (hardcoded)
                 16#0cfc# |  --  PCI Data         (hardcoded)
                 16#0cfd# |  --  PCI Data         (hardcoded)
                 16#0cfe# |  --  PCI Data         (hardcoded)
                 16#0cff# => --  PCI Data         (hardcoded)
               Ignore_Access (Info => Info);
            when 16#60# | 16#64# =>
               Devices.i8042.Emulate
                 (Info => Info,
                  Halt => Halt);
            when Devices.UART8250.Com1_Port_Range =>
               Devices.UART8250.Emulate
                 (Info => Info,
                  Halt => Halt);
            when others =>
               pragma Debug (Debug_Ops.Put_Value16
                             (Message => "Unhandled access to I/O port",
                              Value   => Info.Port_Number));
               Halt := True;
         end case;
      end if;
   end Process;

end Exit_Handlers.IO_Instruction;
