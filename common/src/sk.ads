--
--  Copyright (C) 2013, 2015  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2013, 2015  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

package SK
is

   type Byte is mod 2**8;
   for Byte'Size use 8;

   type Word16 is mod 2**16;
   for Word16'Size use 16;

   type Word32 is mod 2**32;
   for Word32'Size use 32;

   type Word64 is mod 2**64;
   for Word64'Size use 64;

   type Word64_Pos is range 0 .. 63;

   --  CPU registers.
   type CPU_Registers_Type is record
      CR2 : Word64;
      RAX : Word64;
      RBX : Word64;
      RCX : Word64;
      RDX : Word64;
      RDI : Word64;
      RSI : Word64;
      RBP : Word64;
      R08 : Word64;
      R09 : Word64;
      R10 : Word64;
      R11 : Word64;
      R12 : Word64;
      R13 : Word64;
      R14 : Word64;
      R15 : Word64;
   end record;

   Null_CPU_Regs : constant CPU_Registers_Type;

   --  Size of one page (4k).
   Page_Size : constant := 4096;

   --  Size of XSAVE area (x87, SSE, AVX) in bytes, see Intel SDM Vol. 2B,
   --  table 4-20.
   XSAVE_Area_Size : constant := (512 + 64) + 256;

   type XSAVE_Area_Range is range 0 .. XSAVE_Area_Size - 1;

   type XSAVE_Area_Type is array (XSAVE_Area_Range) of Byte;
   for XSAVE_Area_Type'Alignment use 64;

   --  Subject state.
   type Subject_State_Type is record
      Regs               : CPU_Registers_Type;
      Exit_Reason        : Word64;
      Exit_Qualification : Word64;
      Guest_Phys_Addr    : Word64;
      Interrupt_Info     : Word64;
      Instruction_Len    : Word64;
      RIP                : Word64;
      CS                 : Word64;
      RSP                : Word64;
      SS                 : Word64;
      CR0                : Word64;
      SHADOW_CR0         : Word64;
      CR3                : Word64;
      CR4                : Word64;
      RFLAGS             : Word64;
      IA32_EFER          : Word64;
      XSAVE_Area         : XSAVE_Area_Type;
   end record;

   Null_Subject_State : constant Subject_State_Type;

   --  ISR execution environment state.
   type Isr_Context_Type is record
      Regs       : CPU_Registers_Type;
      Vector     : Word64;
      Error_Code : Word64;
      RIP        : Word64;
      CS         : Word64;
      RFLAGS     : Word64;
      RSP        : Word64;
      SS         : Word64;
   end record;

   --  Test if bit at given position is set.
   function Bit_Test
     (Value : Word64;
      Pos   : Word64_Pos)
      return Boolean
   with
      Global => null;

   --  Set bit at given position.
   function Bit_Set
     (Value : Word64;
      Pos   : Word64_Pos)
      return Word64
   with
      Global => null;

   --  Clear bit at given position.
   function Bit_Clear
     (Value : Word64;
      Pos   : Word64_Pos)
      return Word64
   with
      Global => null;

private

   Null_CPU_Regs : constant CPU_Registers_Type := CPU_Registers_Type'
     (CR2 => 0,
      RAX => 0,
      RBX => 0,
      RCX => 0,
      RDX => 0,
      RDI => 0,
      RSI => 0,
      RBP => 0,
      R08 => 0,
      R09 => 0,
      R10 => 0,
      R11 => 0,
      R12 => 0,
      R13 => 0,
      R14 => 0,
      R15 => 0);

   Null_Subject_State : constant Subject_State_Type
     := Subject_State_Type'
       (Regs               => Null_CPU_Regs,
        Exit_Reason        => 0,
        Exit_Qualification => 0,
        Guest_Phys_Addr    => 0,
        Interrupt_Info     => 0,
        Instruction_Len    => 0,
        RIP                => 0,
        CS                 => 0,
        RSP                => 0,
        SS                 => 0,
        CR0                => 0,
        SHADOW_CR0         => 0,
        CR3                => 0,
        CR4                => 0,
        RFLAGS             => 0,
        IA32_EFER          => 0,
        XSAVE_Area         => XSAVE_Area_Type'(others => 0));

end SK;
