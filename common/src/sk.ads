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

with Interfaces;

package SK
is

   subtype Byte   is Interfaces.Unsigned_8;
   subtype Word16 is Interfaces.Unsigned_16;
   subtype Word32 is Interfaces.Unsigned_32;
   subtype Word64 is Interfaces.Unsigned_64;

   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;

   CPU_Regs_Size : constant := 16 * 8;

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
   end record
   with
      Size => CPU_Regs_Size * 8;

   Null_CPU_Regs : constant CPU_Registers_Type;

   --  Size of one page (4k).
   Page_Size : constant := 4096;

   --  Size of XSAVE area in bytes, see Intel SDM Vol. 1 (December 2015
   --  edition), section 13.5.
   XSAVE_Area_Size : constant := (512 + 64) + 512;

   type XSAVE_Area_Range is range 0 .. XSAVE_Area_Size - 1;

   type XSAVE_Area_Type is array (XSAVE_Area_Range) of Byte;
   for XSAVE_Area_Type'Alignment use 64;

   Seg_Type_Size : constant := 8 + 8 + 4 + 4;

   type Segment_Type is record
      Selector      : Word64;
      Base          : Word64;
      Limit         : Word32;
      Access_Rights : Word32;
   end record
   with
      Size => Seg_Type_Size * 8;

   Null_Segment : constant Segment_Type;

   Subj_State_Size : constant :=
     (CPU_Regs_Size + 10 * Seg_Type_Size + 3 * 4 + 14 * 8);

   type Subject_State_Type is record
      Regs               : CPU_Registers_Type;
      Exit_Reason        : Word32;
      Intr_State         : Word32;
      SYSENTER_CS        : Word32;
      Exit_Qualification : Word64;
      Guest_Phys_Addr    : Word64;
      Instruction_Len    : Word64;
      RIP                : Word64;
      RSP                : Word64;
      CR0                : Word64;
      SHADOW_CR0         : Word64;
      CR3                : Word64;
      CR4                : Word64;
      SHADOW_CR4         : Word64;
      RFLAGS             : Word64;
      IA32_EFER          : Word64;
      SYSENTER_ESP       : Word64;
      SYSENTER_EIP       : Word64;
      CS                 : Segment_Type;
      SS                 : Segment_Type;
      DS                 : Segment_Type;
      ES                 : Segment_Type;
      FS                 : Segment_Type;
      GS                 : Segment_Type;
      TR                 : Segment_Type;
      LDTR               : Segment_Type;
      GDTR               : Segment_Type;
      IDTR               : Segment_Type;
   end record
   with
      Pack,
      Size => Subj_State_Size * 8;

   Null_Subject_State : constant Subject_State_Type;

   Isr_Ctx_Size : constant := CPU_Regs_Size + 7 * 8;

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
   end record
   with
      Size => Isr_Ctx_Size * 8;

   Null_Isr_Context : constant Isr_Context_Type;

   Ex_Ctx_Size : constant := Isr_Ctx_Size + 3 * 8;

   type Exception_Context_Type is record
      ISR_Ctx       : Isr_Context_Type;
      CR0, CR3, CR4 : Word64;
   end record
   with
      Size => Ex_Ctx_Size * 8;

   Null_Exception_Context : constant Exception_Context_Type;

   --  Pseudo Descriptor type, see Intel SDM Vol. 3A, chapter 3.5.1.
   type Pseudo_Descriptor_Type is record
      Limit : SK.Word16;
      Base  : SK.Word64;
   end record
   with
      Size => 80;

private

   for Segment_Type use record
      Selector      at  0 range 0 .. 63;
      Base          at  8 range 0 .. 63;
      Limit         at 16 range 0 .. 31;
      Access_Rights at 20 range 0 .. 31;
   end record;

   for Pseudo_Descriptor_Type use record
      Limit at 0 range 0 .. 15;
      Base  at 2 range 0 .. 63;
   end record;

   for CPU_Registers_Type use record
      CR2 at   0 range 0 .. 63;
      RAX at   8 range 0 .. 63;
      RBX at  16 range 0 .. 63;
      RCX at  24 range 0 .. 63;
      RDX at  32 range 0 .. 63;
      RDI at  40 range 0 .. 63;
      RSI at  48 range 0 .. 63;
      RBP at  56 range 0 .. 63;
      R08 at  64 range 0 .. 63;
      R09 at  72 range 0 .. 63;
      R10 at  80 range 0 .. 63;
      R11 at  88 range 0 .. 63;
      R12 at  96 range 0 .. 63;
      R13 at 104 range 0 .. 63;
      R14 at 112 range 0 .. 63;
      R15 at 120 range 0 .. 63;
   end record;

   Null_CPU_Regs : constant CPU_Registers_Type
     := CPU_Registers_Type'(others => 0);

   Null_Segment : constant Segment_Type
     := Segment_Type'(Selector      => 0,
                      Base          => 0,
                      Limit         => 0,
                      Access_Rights => 0);

   Null_Subject_State : constant Subject_State_Type
     := Subject_State_Type'
       (Regs           => Null_CPU_Regs,
        Exit_Reason    => 0,
        Intr_State     => 0,
        SYSENTER_CS    => 0,
        CS             => Null_Segment,
        SS             => Null_Segment,
        DS             => Null_Segment,
        ES             => Null_Segment,
        FS             => Null_Segment,
        GS             => Null_Segment,
        TR             => Null_Segment,
        LDTR           => Null_Segment,
        GDTR           => Null_Segment,
        IDTR           => Null_Segment,
        others         => 0);

   for Isr_Context_Type use record
      Regs       at 0                  range 0 .. 8 * CPU_Regs_Size - 1;
      Vector     at CPU_Regs_Size      range 0 .. 63;
      Error_Code at CPU_Regs_Size + 8  range 0 .. 63;
      RIP        at CPU_Regs_Size + 16 range 0 .. 63;
      CS         at CPU_Regs_Size + 24 range 0 .. 63;
      RFLAGS     at CPU_Regs_Size + 32 range 0 .. 63;
      RSP        at CPU_Regs_Size + 40 range 0 .. 63;
      SS         at CPU_Regs_Size + 48 range 0 .. 63;
   end record;

   Null_Isr_Context : constant Isr_Context_Type
     := (Regs   => Null_CPU_Regs,
         others => 0);

   for Exception_Context_Type use record
      ISR_Ctx at 0                 range 0 .. 8 * Isr_Ctx_Size - 1;
      CR0     at Isr_Ctx_Size      range 0 .. 63;
      CR3     at Isr_Ctx_Size + 8  range 0 .. 63;
      CR4     at Isr_Ctx_Size + 16 range 0 .. 63;
   end record;

   Null_Exception_Context : constant Exception_Context_Type
     := (ISR_Ctx => Null_Isr_Context,
         others  => 0);

end SK;
