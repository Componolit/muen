--
--  Copyright (C) 2015  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2015  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

with System;

with Skp.Kernel;

with SK.KC;
with SK.CPU;
with SK.Constants;

package body SK.FPU
with
   Refined_State => (State => Subject_FPU_States)
is

   pragma Warnings (GNAT, Off, "*padded by * bits");
   type Subject_FPU_State_Array is array
     (Skp.Subject_Id_Type) of SK.XSAVE_Area_Type
   with
      Independent_Components,
      Component_Size => Page_Size * 8,
      Alignment      => Page_Size;
   pragma Warnings (GNAT, On, "*padded by * bits");

   Null_FPU_State : constant XSAVE_Area_Type := (others => 0);

   Subject_FPU_States : Subject_FPU_State_Array
   with
      Address => System'To_Address (Skp.Kernel.Subj_FPU_State_Address);
   pragma Annotate
     (GNATprove, Intentional,
      "not initialized",
      "Subject FPU states are initialized by their owning CPU.");

   -------------------------------------------------------------------------

   procedure Clear_State (ID : Skp.Subject_Id_Type)
   with
      Refined_Global  => (In_Out => Subject_FPU_States),
      Refined_Depends => (Subject_FPU_States =>+ ID),
      Refined_Post    => Subject_FPU_States =
       Subject_FPU_States'Old'Update (ID => Null_FPU_State)
   is
   begin
      Subject_FPU_States (ID) := Null_FPU_State;
   end Clear_State;

   -------------------------------------------------------------------------

   procedure Enable
   is
      CR4, XCR0 : SK.Word64;
   begin
      CR4 := CPU.Get_CR4;
      CR4 := Bit_Set (Value => CR4,
                      Pos   => Constants.CR4_XSAVE_FLAG);
      CPU.Set_CR4 (Value => CR4);

      XCR0 := Bit_Set (Value => 0,
                       Pos   => Constants.XCR0_FPU_STATE_FLAG);
      XCR0 := Bit_Set (Value => XCR0,
                       Pos   => Constants.XCR0_SSE_STATE_FLAG);
      XCR0 := Bit_Set (Value => XCR0,
                       Pos   => Constants.XCR0_AVX_STATE_FLAG);

      CPU.XSETBV (Register => 0,
                  Value    => XCR0);
      CPU.Fninit;
   end Enable;

   -------------------------------------------------------------------------

   procedure Restore_State (ID : Skp.Subject_Id_Type)
   with
     Refined_Global  => (Input  => Subject_FPU_States,
                         In_Out => X86_64.State),
     Refined_Depends => (X86_64.State =>+ (ID, Subject_FPU_States))
   is
   begin
      CPU.XRSTOR (Source => Subject_FPU_States (ID));
   end Restore_State;

   -------------------------------------------------------------------------

   procedure Save_State (ID : Skp.Subject_Id_Type)
   with
      Refined_Global  => (Input  => X86_64.State,
                          In_Out => Subject_FPU_States),
      Refined_Depends => (Subject_FPU_States =>+ (ID, X86_64.State))
   is
   begin
      CPU.XSAVE (Target => Subject_FPU_States (ID));
   end Save_State;

   -------------------------------------------------------------------------

   --  Sets Features_Present to True if XSAVE has support for FPU, SSE and AVX
   --  state handling. Save_Area_Size is set to True if the FPU state save area
   --  is larger than the reported maximum XSAVE area size.
   procedure Query_XSAVE
     (Features_Present : out Boolean;
      Save_Area_Size   : out Boolean)
   with
      Global  => (Input => X86_64.State),
      Depends => ((Features_Present, Save_Area_Size) => X86_64.State)
   is
      EAX, Unused_EBX, ECX, EDX : SK.Word32;
   begin
      EAX := 16#d#;
      ECX := 0;

      pragma Warnings (GNATprove, Off, "unused assignment to ""Unused_EBX""",
                       Reason => "Only parts of the CPUID result is needed");
      CPU.CPUID
        (EAX => EAX,
         EBX => Unused_EBX,
         ECX => ECX,
         EDX => EDX);
      pragma Warnings (GNATprove, On, "unused assignment to ""Unused_EBX""");

      Features_Present := Bit_Test (Value => SK.Word64 (EAX),
                                    Pos   => Constants.XCR0_FPU_STATE_FLAG);
      Features_Present := Features_Present and
        Bit_Test (Value => SK.Word64 (EAX),
                  Pos   => Constants.XCR0_SSE_STATE_FLAG);
      Features_Present := Features_Present and
        Bit_Test (Value => SK.Word64 (EAX),
                  Pos   => Constants.XCR0_AVX_STATE_FLAG);
      Features_Present := Features_Present and EDX = 0;

      Save_Area_Size := ECX <= SK.XSAVE_Area_Size;
   end Query_XSAVE;

   -------------------------------------------------------------------------

   function Has_Valid_State return Boolean
   is
      XSAVE_Support : Boolean;
      FPU_Area_Size : Boolean;
   begin
      Query_XSAVE (Features_Present => XSAVE_Support,
                   Save_Area_Size   => FPU_Area_Size);

      pragma Debug (not XSAVE_Support,
                    KC.Put_Line (Item => "XSAVE features missing"));
      pragma Debug (not FPU_Area_Size,
                    KC.Put_Line (Item => "FPU state save area too small"));

      return XSAVE_Support and FPU_Area_Size;
   end Has_Valid_State;

end SK.FPU;
