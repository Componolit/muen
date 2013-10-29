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

with Skp.Kernel;

with SK.CPU;
with SK.CPU_Global;
with SK.Interrupts;
with SK.Descriptors;
with SK.KC;
with SK.GDT;
with SK.Constants;
with SK.Subjects;
with SK.Apic;
with SK.Events;

package body SK.VMX
--# own
--#    State is VMX_Exit_Address;
is

   --  Segment selectors

   SEL_KERN_CODE : constant := 16#08#;
   SEL_KERN_DATA : constant := 16#10#;
   SEL_TSS       : constant := 16#18#;

   --# accept Warning, 350, VMX_Exit_Address, "Imported from Linker";
   VMX_Exit_Address : SK.Word64;
   pragma Import (C, VMX_Exit_Address, "vmx_exit_handler_ptr");
   --# end accept;

   ---------------------------------------------------------------------------

   --  Return per-CPU memory offset.
   function Get_CPU_Offset return SK.Word64
   --# global
   --#    X86_64.State;
   is
   begin
      return SK.Word64 (Apic.Get_ID) * SK.Page_Size;
   end Get_CPU_Offset;

   -------------------------------------------------------------------------

   procedure VMCS_Write
     (Field : SK.Word16;
      Value : SK.Word64)
   is
      Success : Boolean;
   begin
      CPU.VMWRITE (Field   => SK.Word64 (Field),
                   Value   => Value,
                   Success => Success);
      if not Success then
         pragma Debug (KC.Put_String (Item => "Error setting VMCS field "));
         pragma Debug (KC.Put_Word16 (Item => Field));
         pragma Debug (KC.Put_String (Item => " to value "));
         pragma Debug (KC.Put_Word64 (Item => Value));
         pragma Debug (KC.New_Line);
         CPU.Panic;
      end if;
   end VMCS_Write;

   -------------------------------------------------------------------------

   procedure VMCS_Read
     (Field :     SK.Word16;
      Value : out SK.Word64)
   is
      Success : Boolean;
   begin
      CPU.VMREAD (Field   => SK.Word64 (Field),
                  Value   => Value,
                  Success => Success);
      if not Success then
         pragma Debug (KC.Put_String (Item => "Error reading VMCS field "));
         pragma Debug (KC.Put_Word16 (Item => Field));
         pragma Debug (KC.New_Line);
         CPU.Panic;
      end if;
   end VMCS_Read;

   -------------------------------------------------------------------------

   procedure VMX_Error
   is
      Error   : SK.Word64;
      Success : Boolean;
   begin
      pragma Debug (KC.Put_String (Item => "Error running subject "));
      pragma Debug (KC.Put_Byte
                    (Item => SK.Byte
                     (CPU_Global.Get_Current_Minor_Frame.Subject_Id)));
      pragma Debug (KC.New_Line);

      pragma Debug (CPU.VMREAD (Field   => Constants.VMX_INST_ERROR,
                                Value   => Error,
                                Success => Success));
      pragma Debug (Success, KC.Put_String (Item => "VM instruction error: "));
      pragma Debug (Success, KC.Put_Byte (Item => Byte (Error)));
      pragma Debug (Success, KC.New_Line);
      pragma Debug (not Success, KC.Put_Line
        (Item => "Unable to read VMX instruction error"));

      CPU.Panic;

      --# accept Warning, 400, Error,   "Only used for debug output";
      --# accept Warning, 400, Success, "Only used for debug output";
   end VMX_Error;

   -------------------------------------------------------------------------

   procedure VMCS_Set_Interrupt_Window (Value : Boolean)
   is
      Interrupt_Window_Exit_Flag : constant SK.Word64_Pos := 2;

      Cur_Flags : SK.Word64;
   begin
      VMCS_Read (Field => Constants.CPU_BASED_EXEC_CONTROL,
                 Value => Cur_Flags);
      if Value then
         Cur_Flags := SK.Bit_Set
           (Value => Cur_Flags,
            Pos   => Interrupt_Window_Exit_Flag);
      else
         Cur_Flags := SK.Bit_Clear
           (Value => Cur_Flags,
            Pos   => Interrupt_Window_Exit_Flag);
      end if;
      VMCS_Write (Field => Constants.CPU_BASED_EXEC_CONTROL,
                  Value => Cur_Flags);
   end VMCS_Set_Interrupt_Window;

   -------------------------------------------------------------------------

   procedure VMCS_Setup_Control_Fields
     (IO_Bitmap_Address  : SK.Word64;
      MSR_Bitmap_Address : SK.Word64;
      Ctls_Exec_Pin      : SK.Word32;
      Ctls_Exec_Proc     : SK.Word32;
      Ctls_Exec_Proc2    : SK.Word32;
      Ctls_Exit          : SK.Word32;
      Ctls_Entry         : SK.Word32;
      CR0_Mask           : SK.Word64;
      CR4_Mask           : SK.Word64;
      Exception_Bitmap   : SK.Word32)
   is
      Default0, Default1, Value : SK.Word32;
   begin

      --  Pin-based controls.

      CPU.Get_MSR (Register => Constants.IA32_VMX_TRUE_PINBASED_CTLS,
                   Low      => Default0,
                   High     => Default1);
      Value := Ctls_Exec_Pin;
      Value := Value and Default1;
      Value := Value or  Default0;
      VMCS_Write (Field => Constants.PIN_BASED_EXEC_CONTROL,
                  Value => SK.Word64 (Value));

      --  Primary processor-based controls.

      CPU.Get_MSR (Register => Constants.IA32_VMX_TRUE_PROCBASED_CTLS,
                   Low      => Default0,
                   High     => Default1);
      Value := Ctls_Exec_Proc;
      Value := Value and Default1;
      Value := Value or  Default0;
      VMCS_Write (Field => Constants.CPU_BASED_EXEC_CONTROL,
                  Value => SK.Word64 (Value));

      --  Secondary processor-based controls.

      CPU.Get_MSR (Register => Constants.IA32_VMX_PROCBASED_CTLS2,
                   Low      => Default0,
                   High     => Default1);
      Value := Ctls_Exec_Proc2;
      Value := Value and Default1;
      Value := Value or  Default0;
      VMCS_Write (Field => Constants.CPU_BASED_EXEC_CONTROL2,
                  Value => SK.Word64 (Value));

      --  Exception bitmap.

      VMCS_Write (Field => Constants.EXCEPTION_BITMAP,
                  Value => SK.Word64 (Exception_Bitmap));

      --  Write access to CR0/CR4.

      VMCS_Write (Field => Constants.CR0_MASK,
                  Value => CR0_Mask);
      VMCS_Write (Field => Constants.CR4_MASK,
                  Value => CR4_Mask);

      --  I/O bitmaps.

      VMCS_Write (Field => Constants.IO_BITMAP_A,
                  Value => IO_Bitmap_Address);
      VMCS_Write (Field => Constants.IO_BITMAP_B,
                  Value => IO_Bitmap_Address + SK.Page_Size);

      --  MSR bitmaps.

      VMCS_Write (Field => Constants.MSR_BITMAP,
                  Value => MSR_Bitmap_Address);

      --  VM-exit controls.

      CPU.Get_MSR (Register => Constants.IA32_VMX_TRUE_EXIT_CTLS,
                   Low      => Default0,
                   High     => Default1);
      Value := Ctls_Exit;
      Value := Value and Default1;
      Value := Value or  Default0;
      VMCS_Write (Field => Constants.VM_EXIT_CONTROLS,
                  Value => SK.Word64 (Value));

      --  VM-entry controls.

      CPU.Get_MSR (Register => Constants.IA32_VMX_TRUE_ENTRY_CTLS,
                   Low      => Default0,
                   High     => Default1);
      Value := Ctls_Entry;
      Value := Value and Default1;
      Value := Value or  Default0;
      VMCS_Write (Field => Constants.VM_ENTRY_CONTROLS,
                  Value => SK.Word64 (Value));
   end VMCS_Setup_Control_Fields;

   -------------------------------------------------------------------------

   procedure VMCS_Setup_Host_Fields
   --# global
   --#    in     Interrupts.State;
   --#    in     GDT.GDT_Pointer;
   --#    in     VMX_Exit_Address;
   --#    in out X86_64.State;
   --# derives
   --#    X86_64.State from
   --#       *,
   --#       Interrupts.State,
   --#       GDT.GDT_Pointer,
   --#       VMX_Exit_Address;
   is
      PD : Descriptors.Pseudo_Descriptor_Type;
   begin
      VMCS_Write (Field => Constants.HOST_SEL_CS,
                  Value => SEL_KERN_CODE);
      VMCS_Write (Field => Constants.HOST_SEL_DS,
                  Value => SEL_KERN_DATA);
      VMCS_Write (Field => Constants.HOST_SEL_ES,
                  Value => SEL_KERN_DATA);
      VMCS_Write (Field => Constants.HOST_SEL_SS,
                  Value => SEL_KERN_DATA);
      VMCS_Write (Field => Constants.HOST_SEL_TR,
                  Value => SEL_TSS);

      VMCS_Write (Field => Constants.HOST_CR0,
                  Value => CPU.Get_CR0);
      VMCS_Write (Field => Constants.HOST_CR3,
                  Value => CPU.Get_CR3);
      VMCS_Write (Field => Constants.HOST_CR4,
                  Value => CPU.Get_CR4);

      PD := Interrupts.Get_IDT_Pointer;
      VMCS_Write (Field => Constants.HOST_BASE_IDTR,
                  Value => PD.Base);
      PD := GDT.Get_GDT_Pointer;
      VMCS_Write (Field => Constants.HOST_BASE_GDTR,
                  Value => PD.Base);

      VMCS_Write (Field => Constants.HOST_RSP,
                  Value => Skp.Kernel.Stack_Address);
      VMCS_Write (Field => Constants.HOST_RIP,
                  Value => VMX_Exit_Address);
      VMCS_Write (Field => Constants.HOST_IA32_EFER,
                  Value => CPU.Get_MSR64 (Register => Constants.IA32_EFER));
   end VMCS_Setup_Host_Fields;

   -------------------------------------------------------------------------

   procedure VMCS_Setup_Guest_Fields
     (PML4_Address : SK.Word64;
      EPT_Pointer  : SK.Word64;
      CR0_Value    : SK.Word64;
      CR4_Value    : SK.Word64;
      CS_Access    : SK.Word32)
   is
   begin
      VMCS_Write (Field => Constants.VMCS_LINK_POINTER,
                  Value => SK.Word64'Last);

      VMCS_Write (Field => Constants.GUEST_SEL_CS,
                  Value => SEL_KERN_CODE);
      VMCS_Write (Field => Constants.GUEST_SEL_DS,
                  Value => SEL_KERN_DATA);
      VMCS_Write (Field => Constants.GUEST_SEL_ES,
                  Value => SEL_KERN_DATA);
      VMCS_Write (Field => Constants.GUEST_SEL_SS,
                  Value => SEL_KERN_DATA);
      VMCS_Write (Field => Constants.GUEST_SEL_TR,
                  Value => SEL_TSS);

      VMCS_Write (Field => Constants.GUEST_LIMIT_CS,
                  Value => SK.Word64 (SK.Word32'Last));
      VMCS_Write (Field => Constants.GUEST_LIMIT_DS,
                  Value => SK.Word64 (SK.Word32'Last));
      VMCS_Write (Field => Constants.GUEST_LIMIT_ES,
                  Value => SK.Word64 (SK.Word32'Last));
      VMCS_Write (Field => Constants.GUEST_LIMIT_SS,
                  Value => SK.Word64 (SK.Word32'Last));
      VMCS_Write (Field => Constants.GUEST_LIMIT_TR,
                  Value => SK.Word64 (SK.Byte'Last));

      VMCS_Write (Field => Constants.GUEST_ACCESS_RIGHTS_CS,
                  Value => SK.Word64 (CS_Access));
      VMCS_Write (Field => Constants.GUEST_ACCESS_RIGHTS_DS,
                  Value => 16#c093#);
      VMCS_Write (Field => Constants.GUEST_ACCESS_RIGHTS_ES,
                  Value => 16#c093#);
      VMCS_Write (Field => Constants.GUEST_ACCESS_RIGHTS_SS,
                  Value => 16#c093#);
      VMCS_Write (Field => Constants.GUEST_ACCESS_RIGHTS_TR,
                  Value => 16#8b#);

      --  Disable fs, gs and ldt segments; they can be enabled by guest code
      --  if needed.

      VMCS_Write (Field => Constants.GUEST_ACCESS_RIGHTS_FS,
                  Value => 16#10000#);
      VMCS_Write (Field => Constants.GUEST_ACCESS_RIGHTS_GS,
                  Value => 16#10000#);
      VMCS_Write (Field => Constants.GUEST_ACCESS_RIGHTS_LDTR,
                  Value => 16#10000#);

      VMCS_Write (Field => Constants.GUEST_CR0,
                  Value => CR0_Value);
      VMCS_Write (Field => Constants.GUEST_CR3,
                  Value => PML4_Address);
      VMCS_Write (Field => Constants.GUEST_CR4,
                  Value => CR4_Value);

      VMCS_Write (Field => Constants.EPT_POINTER,
                  Value => EPT_Pointer);

      VMCS_Write (Field => Constants.GUEST_RFLAGS,
                  Value => 2);
      VMCS_Write (Field => Constants.GUEST_IA32_EFER,
                  Value => 0);
   end VMCS_Setup_Guest_Fields;

   -------------------------------------------------------------------------

   procedure Clear (VMCS_Address : SK.Word64)
   is
      Success : Boolean;
   begin
      CPU.VMCLEAR (Region  => VMCS_Address,
                   Success => Success);
      if not Success then
         pragma Debug (KC.Put_String (Item => "Error clearing VMCS: "));
         pragma Debug (KC.Put_Word64 (Item => VMCS_Address));
         pragma Debug (KC.New_Line);
         CPU.Panic;
      end if;
   end Clear;

   -------------------------------------------------------------------------

   procedure Load (VMCS_Address : SK.Word64)
   is
      Success : Boolean;
   begin
      CPU.VMPTRLD (Region  => VMCS_Address,
                   Success => Success);
      if not Success then
         pragma Debug (KC.Put_String (Item => "Error loading VMCS pointer: "));
         pragma Debug (KC.Put_Word64 (Item => VMCS_Address));
         pragma Debug (KC.New_Line);
         CPU.Panic;
      end if;
   end Load;

   -------------------------------------------------------------------------

   procedure Inject_Event (Subject_Id : Skp.Subject_Id_Type)
   is
      State         : SK.Subject_State_Type;
      Intr_State    : SK.Word64;
      Event         : SK.Byte;
      Event_Present : Boolean;
   begin
      State := Subjects.Get_State (Id => Subject_Id);

      --  Check guest interruptibility state (see Intel SDM Vol. 3C, chapter
      --  24.4.2).

      VMCS_Read (Field => Constants.GUEST_INTERRUPTIBILITY,
                 Value => Intr_State);

      if Intr_State = 0
        and then SK.Bit_Test
          (Value => State.RFLAGS,
           Pos   => Constants.RFLAGS_IF_FLAG)
      then
         Events.Consume_Event (Subject => Subject_Id,
                               Found   => Event_Present,
                               Event   => Event);

         if Event_Present then
            VMCS_Write
              (Field => Constants.VM_ENTRY_INTERRUPT_INFO,
               Value => Constants.VM_INTERRUPT_INFO_VALID + SK.Word64 (Event));
         end if;
      end if;

      if Events.Has_Pending_Events (Subject => Subject_Id) then
         VMCS_Set_Interrupt_Window (Value => True);
      end if;
   end Inject_Event;

   -------------------------------------------------------------------------

   procedure Restore_Guest_Regs
     (Subject_Id :     Skp.Subject_Id_Type;
      Regs       : out SK.CPU_Registers_Type)
   is
      State : SK.Subject_State_Type;
   begin
      State := Subjects.Get_State (Id => Subject_Id);
      VMCS_Write (Field => Constants.GUEST_RIP,
                  Value => State.RIP);
      VMCS_Write (Field => Constants.GUEST_RSP,
                  Value => State.RSP);

      if CPU.Get_CR2 /= State.CR2 then
         CPU.Set_CR2 (Value => State.CR2);
      end if;

      Regs := State.Regs;
   end Restore_Guest_Regs;

   -------------------------------------------------------------------------

   procedure Enter_Root_Mode
   is
      Success : Boolean;
   begin
      CPU.Set_CR4 (Value => SK.Bit_Set
                   (Value => CPU.Get_CR4,
                    Pos   => Constants.CR4_VMXE_FLAG));

      CPU.VMXON (Region  => Skp.Vmxon_Address + Get_CPU_Offset,
                 Success => Success);
      if not Success then
         pragma Debug (KC.Put_Line (Item => "Error enabling VMX"));
         CPU.Panic;
      end if;
   end Enter_Root_Mode;

end SK.VMX;
