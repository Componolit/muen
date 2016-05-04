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

   --  Size of XSAVE area in bytes, see Intel SDM Vol. 1 (December 2015
   --  edition), section 13.5.
   XSAVE_Area_Size : constant := (512 + 64) + 512;

   type XSAVE_Area_Range is range 0 .. XSAVE_Area_Size - 1;

   type XSAVE_Area_Type is array (XSAVE_Area_Range) of Byte;
   for XSAVE_Area_Type'Alignment use 64;

   type Segment_Type is record
      Selector      : SK.Word64;
      Base          : SK.Word64;
      Limit         : SK.Word32;
      Access_Rights : SK.Word32;
   end record;

   Null_Segment : constant Segment_Type;

   --  TODO: Fix guest state fields widths, introduce segment type etc.

   --  Subject state.
   type Subject_State_Type is record
      Regs               : CPU_Registers_Type;
      Exit_Reason        : Word64;
      Exit_Qualification : Word64;
      Guest_Phys_Addr    : Word64;
      Interrupt_Info     : Word64;
      Instruction_Len    : Word64;
      RIP                : Word64;
      RSP                : Word64;
      CR0                : Word64;
      SHADOW_CR0         : Word64;
      CR3                : Word64;
      CR4                : Word64;
      RFLAGS             : Word64;
      IA32_EFER          : Word64;
      CS                 : Word64;
      CS_Limit           : Word64;
      CS_Base            : Word64;
      CS_Access          : Word64;
      SS                 : Word64;
      SS_Limit           : Word64;
      SS_Base            : Word64;
      SS_Access          : Word64;
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

   for Segment_Type use record
      Selector      at  0 range 0 .. 63;
      Base          at  8 range 0 .. 63;
      Limit         at 16 range 0 .. 31;
      Access_Rights at 20 range 0 .. 31;
   end record;

   Null_CPU_Regs : constant CPU_Registers_Type
     := CPU_Registers_Type'(others => 0);

   Null_Segment : constant Segment_Type
     := Segment_Type'(Selector
                      => 0,
                      Base          => 0,
                      Limit         => 0,
                      Access_Rights => 0);

   Null_Subject_State : constant Subject_State_Type
     := Subject_State_Type'
       (Regs   => Null_CPU_Regs,
        others => 0);

end SK;
