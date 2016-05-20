--
--  Copyright (C) 2013-2016  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2013-2016  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

with SK.VMX;
with SK.Constants;

package body SK.Subjects
with
   Refined_State => (State => Descriptors)
is

   pragma Warnings (GNAT, Off, "*padded by * bits");
   type Subject_State_Array is array
     (Skp.Subject_Id_Type) of SK.Subject_State_Type
   with
      Independent_Components,
      Component_Size => Page_Size * 8,
      Alignment      => Page_Size;
   pragma Warnings (GNAT, On, "*padded by * bits");

   --  Descriptors used to manage subject states.
   --  TODO: Model access rules
   --  TODO: Handle initialization
   Descriptors : Subject_State_Array
   with
      Address => System'To_Address (Skp.Kernel.Subj_States_Address);
   pragma Annotate
     (GNATprove, Intentional,
      "not initialized",
      "Subject states are initialized by their owning CPU. Not yet modeled");

   type Segment_ID_Type is (CS, SS, DS, ES, FS, GS, TR, LDTR);

   type VMCS_Seg_Fields_Type is record
      Selector_Field      : Word16;
      Base_Field          : Word16;
      Limit_Field         : Word16;
      Access_Rights_Field : Word16;
   end record;

   --  Mapping of segment ID to corresponding VMCS fields.
   Seg_to_VMCS_Map : constant array (Segment_ID_Type) of VMCS_Seg_Fields_Type
     := (CS   => (Selector_Field      => Constants.GUEST_SEL_CS,
                  Base_Field          => Constants.GUEST_CS_BASE,
                  Limit_Field         => Constants.GUEST_LIMIT_CS,
                  Access_Rights_Field => Constants.GUEST_ACCESS_RIGHTS_CS),
         SS   => (Selector_Field      => Constants.GUEST_SEL_SS,
                  Base_Field          => Constants.GUEST_SS_BASE,
                  Limit_Field         => Constants.GUEST_LIMIT_SS,
                  Access_Rights_Field => Constants.GUEST_ACCESS_RIGHTS_SS),
         DS   => (Selector_Field      => Constants.GUEST_SEL_DS,
                  Base_Field          => Constants.GUEST_DS_BASE,
                  Limit_Field         => Constants.GUEST_LIMIT_DS,
                  Access_Rights_Field => Constants.GUEST_ACCESS_RIGHTS_DS),
         ES   => (Selector_Field      => Constants.GUEST_SEL_ES,
                  Base_Field          => Constants.GUEST_ES_BASE,
                  Limit_Field         => Constants.GUEST_LIMIT_ES,
                  Access_Rights_Field => Constants.GUEST_ACCESS_RIGHTS_ES),
         FS   => (Selector_Field      => Constants.GUEST_SEL_FS,
                  Base_Field          => Constants.GUEST_FS_BASE,
                  Limit_Field         => Constants.GUEST_LIMIT_FS,
                  Access_Rights_Field => Constants.GUEST_ACCESS_RIGHTS_FS),
         GS   => (Selector_Field      => Constants.GUEST_SEL_GS,
                  Base_Field          => Constants.GUEST_GS_BASE,
                  Limit_Field         => Constants.GUEST_LIMIT_GS,
                  Access_Rights_Field => Constants.GUEST_ACCESS_RIGHTS_GS),
         TR   => (Selector_Field      => Constants.GUEST_SEL_TR,
                  Base_Field          => Constants.GUEST_TR_BASE,
                  Limit_Field         => Constants.GUEST_LIMIT_TR,
                  Access_Rights_Field => Constants.GUEST_ACCESS_RIGHTS_TR),
         LDTR => (Selector_Field      => Constants.GUEST_SEL_LDTR,
                  Base_Field          => Constants.GUEST_LDTR_BASE,
                  Limit_Field         => Constants.GUEST_LIMIT_LDTR,
                  Access_Rights_Field => Constants.GUEST_ACCESS_RIGHTS_LDTR));

   -------------------------------------------------------------------------

   --  Stores the VMCS guest selector and descriptor information of the segment
   --  specified by ID in the returned segment type.
   procedure Save_Segment
     (Segment_ID :     Segment_ID_Type;
      Segment    : out Segment_Type)
   with
      Global  => (In_Out => X86_64.State),
      Depends => ((Segment, X86_64.State) => (Segment_ID, X86_64.State))
   is
      Value : Word64;
   begin
      VMX.VMCS_Read (Field => Seg_to_VMCS_Map (Segment_ID).Base_Field,
                     Value => Segment.Base);
      VMX.VMCS_Read (Field => Seg_to_VMCS_Map (Segment_ID).Selector_Field,
                     Value => Segment.Selector);
      VMX.VMCS_Read (Field => Seg_to_VMCS_Map (Segment_ID).Limit_Field,
                     Value => Value);
      Segment.Limit := Word32'Mod (Value);
      VMX.VMCS_Read (Field => Seg_to_VMCS_Map (Segment_ID).Access_Rights_Field,
                     Value => Value);
      Segment.Access_Rights := Word32'Mod (Value);
   end Save_Segment;

   -------------------------------------------------------------------------

   --  Loads the VMCS guest selector and descriptor fields of the segment
   --  specified by ID with the values of the given segment type.
   procedure Restore_Segment
     (Segment_ID : Segment_ID_Type;
      Segment    : Segment_Type)
   with
      Global  => (In_Out => X86_64.State),
      Depends => (X86_64.State =>+ (Segment_ID, Segment))
   is
   begin
      VMX.VMCS_Write (Field => Seg_to_VMCS_Map (Segment_ID).Base_Field,
                      Value => Segment.Base);
      VMX.VMCS_Write (Field => Seg_to_VMCS_Map (Segment_ID).Selector_Field,
                      Value => Segment.Selector);
      VMX.VMCS_Write (Field => Seg_to_VMCS_Map (Segment_ID).Limit_Field,
                      Value => Word64 (Segment.Limit));
      VMX.VMCS_Write
        (Field => Seg_to_VMCS_Map (Segment_ID).Access_Rights_Field,
         Value => Word64 (Segment.Access_Rights));
   end Restore_Segment;

   -------------------------------------------------------------------------

   procedure Clear_State (Id : Skp.Subject_Id_Type)
   with
      Refined_Global  => (In_Out => Descriptors),
      Refined_Depends => (Descriptors =>+ Id),
      Refined_Post    => Descriptors (Id) = SK.Null_Subject_State
   is
   begin
      Descriptors (Id) := SK.Null_Subject_State;
   end Clear_State;

   -------------------------------------------------------------------------

   function Get_Instruction_Length (Id : Skp.Subject_Id_Type) return SK.Word64
   with
      Refined_Global => (Input => Descriptors),
      Refined_Post   =>
         Get_Instruction_Length'Result = Descriptors (Id).Instruction_Len
   is
   begin
      return Descriptors (Id).Instruction_Len;
   end Get_Instruction_Length;

   -------------------------------------------------------------------------

   function Get_Interrupt_Info (Id : Skp.Subject_Id_Type) return SK.Word64
   with
      Refined_Global => (Input => Descriptors),
      Refined_Post   =>
         Get_Interrupt_Info'Result = Descriptors (Id).Interrupt_Info
   is
   begin
      return Descriptors (Id).Interrupt_Info;
   end Get_Interrupt_Info;

   -------------------------------------------------------------------------

   function Get_RFLAGS (Id : Skp.Subject_Id_Type) return SK.Word64
   with
      Refined_Global => (Input => Descriptors),
      Refined_Post   => Get_RFLAGS'Result = Descriptors (Id).RFLAGS
   is
   begin
      return Descriptors (Id).RFLAGS;
   end Get_RFLAGS;

   -------------------------------------------------------------------------

   function Get_RIP (Id : Skp.Subject_Id_Type) return SK.Word64
   with
      Refined_Global => (Input => Descriptors),
      Refined_Post   => Get_RIP'Result = Descriptors (Id).RIP
   is
   begin
      return Descriptors (Id).RIP;
   end Get_RIP;

   -------------------------------------------------------------------------

   function Get_State (Id : Skp.Subject_Id_Type) return SK.Subject_State_Type
   with
      Refined_Global => (Input => Descriptors),
      Refined_Post   => Get_State'Result = Descriptors (Id)
   is
   begin
      return Descriptors (Id);
   end Get_State;

   -------------------------------------------------------------------------

   procedure Restore_State
     (Id   :     Skp.Subject_Id_Type;
      Regs : out SK.CPU_Registers_Type)
     with
      Refined_Global  => (Input  => Descriptors,
                          In_Out => X86_64.State),
      Refined_Depends => (Regs         =>  (Descriptors, Id),
                          X86_64.State =>+ (Descriptors, Id)),
      Refined_Post    => Descriptors (Id).Regs = Regs
   is
   begin
      VMX.VMCS_Write (Field => Constants.GUEST_RIP,
                      Value => Descriptors (Id).RIP);
      VMX.VMCS_Write (Field => Constants.GUEST_RSP,
                      Value => Descriptors (Id).RSP);

      VMX.VMCS_Write (Field => Constants.GUEST_CR0,
                      Value => Descriptors (Id).CR0);
      VMX.VMCS_Write (Field => Constants.CR0_READ_SHADOW,
                      Value => Descriptors (Id).SHADOW_CR0);

      VMX.VMCS_Write (Field => Constants.GUEST_CR3,
                      Value => Descriptors (Id).CR3);
      VMX.VMCS_Write (Field => Constants.GUEST_CR4,
                      Value => Descriptors (Id).CR4);
      VMX.VMCS_Write (Field => Constants.GUEST_RFLAGS,
                      Value => Descriptors (Id).RFLAGS);
      VMX.VMCS_Write (Field => Constants.GUEST_IA32_EFER,
                      Value => Descriptors (Id).IA32_EFER);

      Restore_Segment (Segment_ID => CS,
                       Segment    => Descriptors (Id).CS);
      Restore_Segment (Segment_ID => SS,
                       Segment    => Descriptors (Id).SS);

      Regs := Descriptors (Id).Regs;
   end Restore_State;

   -------------------------------------------------------------------------

   procedure Save_State
     (Id   : Skp.Subject_Id_Type;
      Regs : SK.CPU_Registers_Type)
   with
      Refined_Global  => (In_Out => (Descriptors, X86_64.State)),
      Refined_Depends => (Descriptors  =>+ (Id, Regs, X86_64.State),
                          X86_64.State =>+ null),
      Refined_Post    => Descriptors (Id).Regs = Regs
   is
   begin
      VMX.VMCS_Read (Field => Constants.VMX_EXIT_REASON,
                     Value => Descriptors (Id).Exit_Reason);
      VMX.VMCS_Read (Field => Constants.VMX_EXIT_QUALIFICATION,
                     Value => Descriptors (Id).Exit_Qualification);
      VMX.VMCS_Read (Field => Constants.VMX_EXIT_INTR_INFO,
                     Value => Descriptors (Id).Interrupt_Info);
      VMX.VMCS_Read (Field => Constants.VMX_EXIT_INSTRUCTION_LEN,
                     Value => Descriptors (Id).Instruction_Len);

      VMX.VMCS_Read (Field => Constants.GUEST_PHYSICAL_ADDRESS,
                     Value => Descriptors (Id).Guest_Phys_Addr);

      VMX.VMCS_Read (Field => Constants.GUEST_RIP,
                     Value => Descriptors (Id).RIP);
      VMX.VMCS_Read (Field => Constants.GUEST_RSP,
                     Value => Descriptors (Id).RSP);
      VMX.VMCS_Read (Field => Constants.GUEST_CR0,
                     Value => Descriptors (Id).CR0);
      VMX.VMCS_Read (Field => Constants.CR0_READ_SHADOW,
                     Value => Descriptors (Id).SHADOW_CR0);
      VMX.VMCS_Read (Field => Constants.GUEST_CR3,
                     Value => Descriptors (Id).CR3);
      VMX.VMCS_Read (Field => Constants.GUEST_CR4,
                     Value => Descriptors (Id).CR4);
      VMX.VMCS_Read (Field => Constants.GUEST_RFLAGS,
                     Value => Descriptors (Id).RFLAGS);
      VMX.VMCS_Read (Field => Constants.GUEST_IA32_EFER,
                     Value => Descriptors (Id).IA32_EFER);

      Save_Segment (Segment_ID => CS,
                    Segment    => Descriptors (Id).CS);
      Save_Segment (Segment_ID => SS,
                    Segment    => Descriptors (Id).SS);

      Descriptors (Id).Regs := Regs;
   end Save_State;

   -------------------------------------------------------------------------

   procedure Set_CR0
     (Id    : Skp.Subject_Id_Type;
      Value : SK.Word64)
   with
      Refined_Global  => (In_Out => Descriptors),
      Refined_Depends => (Descriptors =>+ (Id, Value)),
      Refined_Post    => Descriptors (Id).CR0 = Value
   is
   begin
      Descriptors (Id).CR0 := Value;
   end Set_CR0;

   -------------------------------------------------------------------------

   procedure Set_RIP
     (Id    : Skp.Subject_Id_Type;
      Value : SK.Word64)
   with
      Refined_Global  => (In_Out => Descriptors),
      Refined_Depends => (Descriptors =>+ (Id, Value)),
      Refined_Post    => Descriptors (Id).RIP = Value
   is
   begin
      Descriptors (Id).RIP := Value;
   end Set_RIP;

   -------------------------------------------------------------------------

   procedure Set_RSP
     (Id    : Skp.Subject_Id_Type;
      Value : SK.Word64)
   with
      Refined_Global  => (In_Out => Descriptors),
      Refined_Depends => (Descriptors =>+ (Id, Value)),
      Refined_Post    => Descriptors (Id).RSP = Value
   is
   begin
      Descriptors (Id).RSP := Value;
   end Set_RSP;

end SK.Subjects;
