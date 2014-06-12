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

with System;

with Skp.Kernel;
with Skp.Interrupts;

with SK.VMX;
with SK.Constants;
with SK.CPU;
with SK.Apic;
with SK.Dump;

package body SK.Scheduler
with
   Refined_State => (State                 => (Current_Major),
                     Tau0_Kernel_Interface => (New_Major))
is

   --  IRQ constants.
   Timer_Vector : constant := 48;
   IPI_Vector   : constant := 254;

   New_Major : Skp.Scheduling.Major_Frame_Range
   with
      Atomic,
      Async_Writers,
      Address => System'To_Address (Skp.Kernel.Tau0_Iface_Address);

   --  Current major.
   Current_Major : Skp.Scheduling.Major_Frame_Range
     := Skp.Scheduling.Major_Frame_Range'First;

   -------------------------------------------------------------------------

   --  Inject pending event into subject identified by ID.
   procedure Inject_Event (Subject_Id : Skp.Subject_Id_Type)
   with
      Global  => (Input  => Subjects.State,
                  In_Out => (Events.State, X86_64.State)),
      Depends =>
        ((Events.State, X86_64.State) =>
            (Events.State, Subjects.State, Subject_Id, X86_64.State))
   is
      RFLAGS        : SK.Word64;
      Intr_State    : SK.Word64;
      Event         : SK.Byte;
      Event_Present : Boolean;
      Event_Pending : Boolean;
   begin
      RFLAGS := Subjects.Get_RFLAGS (Id => Subject_Id);

      --  Check guest interruptibility state (see Intel SDM Vol. 3C, chapter
      --  24.4.2).

      VMX.VMCS_Read (Field => Constants.GUEST_INTERRUPTIBILITY,
                     Value => Intr_State);

      if Intr_State = 0
        and then SK.Bit_Test
          (Value => RFLAGS,
           Pos   => Constants.RFLAGS_IF_FLAG)
      then
         Events.Consume_Event (Subject => Subject_Id,
                               Found   => Event_Present,
                               Event   => Event);

         if Event_Present then
            VMX.VMCS_Write
              (Field => Constants.VM_ENTRY_INTERRUPT_INFO,
               Value => Constants.VM_INTERRUPT_INFO_VALID + SK.Word64 (Event));
         end if;
      end if;

      Events.Has_Pending_Events (Subject       => Subject_Id,
                                 Event_Pending => Event_Pending);

      if Event_Pending then
         VMX.VMCS_Set_Interrupt_Window (Value => True);
      end if;
   end Inject_Event;

   -------------------------------------------------------------------------

   --  Perform subject handover from the old to the new subject.
   procedure Subject_Handover
     (Old_Id   : Skp.Subject_Id_Type;
      New_Id   : Skp.Subject_Id_Type;
      New_VMCS : SK.Word64)
   with
      Global  => (In_Out => (CPU_Global.State, X86_64.State)),
      Depends => (CPU_Global.State =>+ (New_Id, Old_Id),
                  X86_64.State     =>+ New_VMCS),
      Pre     =>  Old_Id /= New_Id
   is
      Remaining_Ticks : SK.Word64;
   begin
      CPU_Global.Swap_Subject
        (Old_Id => Old_Id,
         New_Id => New_Id);

      VMX.VMCS_Read (Field => Constants.GUEST_VMX_PREEMPT_TIMER,
                     Value => Remaining_Ticks);
      VMX.Load (VMCS_Address => New_VMCS);
      VMX.VMCS_Write (Field => Constants.GUEST_VMX_PREEMPT_TIMER,
                      Value => Remaining_Ticks);
   end Subject_Handover;

   -------------------------------------------------------------------------

   --  Update scheduling information. If the end of the current major frame is
   --  reached, the minor frame index is reset and the major frame is switched
   --  to the one set by Tau0. Otherwise the minor frame index is incremented
   --  by 1.
   procedure Update_Scheduling_Info
   with
      Global  =>
        (Input  => New_Major,
         In_Out => (CPU_Global.State, Current_Major, Events.State,
                    MP.Barrier, X86_64.State)),
      Depends =>
        ((CPU_Global.State, Current_Major, Events.State, X86_64.State) =>+
            (CPU_Global.State, Current_Major, New_Major),
         MP.Barrier =>+ (CPU_Global.State, Current_Major))
   is
      Minor_Frame : CPU_Global.Active_Minor_Frame_Type;
      Plan_Frame  : Skp.Scheduling.Minor_Frame_Type;
   begin
      Minor_Frame := CPU_Global.Get_Current_Minor_Frame;

      if Minor_Frame.Minor_Id < CPU_Global.Get_Major_Length
        (Major_Id => Current_Major)
      then

         --  Switch to next minor frame in current major frame.

         Minor_Frame.Minor_Id := Minor_Frame.Minor_Id + 1;
      else

         --  Switch to first minor frame in next major frame.

         Minor_Frame.Minor_Id := Skp.Scheduling.Minor_Frame_Range'First;

         MP.Wait_For_All;
         if CPU_Global.Is_BSP then
            Current_Major := New_Major;
         end if;
         MP.Wait_For_All;
      end if;

      Plan_Frame := CPU_Global.Get_Minor_Frame
        (Major_Id => Current_Major,
         Minor_Id => Minor_Frame.Minor_Id);

      if Plan_Frame.Subject_Id /= Minor_Frame.Subject_Id then

         --  New minor frame contains different subject -> Load VMCS.

         VMX.Load (VMCS_Address => Skp.Subjects.Get_VMCS_Address
                   (Subject_Id => Plan_Frame.Subject_Id));
      end if;

      Minor_Frame.Subject_Id := Plan_Frame.Subject_Id;
      CPU_Global.Set_Current_Minor (Frame => Minor_Frame);

      if Skp.Subjects.Get_Profile
        (Subject_Id => Minor_Frame.Subject_Id) = Skp.Subjects.Vm
      then
         Events.Insert_Event (Subject => Minor_Frame.Subject_Id,
                              Event   => Timer_Vector);
      end if;

      --  Update preemption timer ticks in subject VMCS.

      VMX.VMCS_Write (Field => Constants.GUEST_VMX_PREEMPT_TIMER,
                      Value => SK.Word64 (Plan_Frame.Ticks));
   end Update_Scheduling_Info;

   -------------------------------------------------------------------------

   procedure Init
   with
      Refined_Global  =>
        (Input  => (Current_Major, Interrupts.State),
         In_Out => (CPU_Global.State, Subjects.State, X86_64.State)),
      Refined_Depends =>
        (CPU_Global.State =>+ Current_Major,
         Subjects.State   =>+ null,
         X86_64.State     =>+ (CPU_Global.State, Current_Major,
                               Interrupts.State))
   is
      Plan_Frame        : Skp.Scheduling.Minor_Frame_Type;
      Initial_VMCS_Addr : SK.Word64 := 0;
      Controls          : Skp.Subjects.VMX_Controls_Type;
      VMCS_Addr         : SK.Word64;
   begin
      CPU_Global.Set_Scheduling_Plan
        (Data => Skp.Scheduling.Scheduling_Plans (CPU_Global.CPU_ID));

      --  Set initial active minor frame.

      Plan_Frame := CPU_Global.Get_Minor_Frame
        (Major_Id => Current_Major,
         Minor_Id => Skp.Scheduling.Minor_Frame_Range'First);
      CPU_Global.Set_Current_Minor
        (Frame => CPU_Global.Active_Minor_Frame_Type'
           (Minor_Id   => Skp.Scheduling.Minor_Frame_Range'First,
            Subject_Id => Plan_Frame.Subject_Id));

      --  Setup VMCS and state of subjects running on this logical CPU.

      for I in Skp.Subject_Id_Type loop
         if Skp.Subjects.Get_CPU_Id (Subject_Id => I) = CPU_Global.CPU_ID then

            --  Initialize subject state.

            Subjects.Clear_State (Id => I);

            --  VMCS

            VMCS_Addr := Skp.Subjects.Get_VMCS_Address (Subject_Id => I);
            Controls  := Skp.Subjects.Get_VMX_Controls (Subject_Id => I);

            VMX.Clear (VMCS_Address => VMCS_Addr);
            VMX.Load  (VMCS_Address => VMCS_Addr);
            VMX.VMCS_Setup_Control_Fields
              (IO_Bitmap_Address  => Skp.Subjects.Get_IO_Bitmap_Address
                 (Subject_Id => I),
               MSR_Bitmap_Address => Skp.Subjects.Get_MSR_Bitmap_Address
                 (Subject_Id => I),
               MSR_Store_Address  => Skp.Subjects.Get_MSR_Store_Address
                 (Subject_Id => I),
               MSR_Count          => Skp.Subjects.Get_MSR_Count
                 (Subject_Id => I),
               Ctls_Exec_Pin      => Controls.Exec_Pin,
               Ctls_Exec_Proc     => Controls.Exec_Proc,
               Ctls_Exec_Proc2    => Controls.Exec_Proc2,
               Ctls_Exit          => Controls.Exit_Ctrls,
               Ctls_Entry         => Controls.Entry_Ctrls,
               CR0_Mask           => Skp.Subjects.Get_CR0_Mask
                 (Subject_Id => I),
               CR4_Mask           => Skp.Subjects.Get_CR4_Mask
                 (Subject_Id => I),
               Exception_Bitmap   => Skp.Subjects.Get_Exception_Bitmap
                 (Subject_Id => I));
            VMX.VMCS_Setup_Host_Fields;
            VMX.VMCS_Setup_Guest_Fields
              (PML4_Address => Skp.Subjects.Get_PML4_Address (Subject_Id => I),
               EPT_Pointer  => Skp.Subjects.Get_EPT_Pointer (Subject_Id => I),
               CR0_Value    => Skp.Subjects.Get_CR0 (Subject_Id => I),
               CR4_Value    => Skp.Subjects.Get_CR4 (Subject_Id => I),
               CS_Access    => Skp.Subjects.Get_CS_Access (Subject_Id => I));

            if Plan_Frame.Subject_Id = I then
               Initial_VMCS_Addr := VMCS_Addr;
            end if;

            --  State

            Subjects.Set_RIP
              (Id    => I,
               Value => Skp.Subjects.Get_Entry_Point (Subject_Id => I));
            Subjects.Set_RSP
              (Id    => I,
               Value => Skp.Subjects.Get_Stack_Address (Subject_Id => I));
            Subjects.Set_CR0
              (Id    => I,
               Value => Skp.Subjects.Get_CR0 (Subject_Id => I));
         end if;
      end loop;

      --  Load first subject and set preemption timer ticks.

      VMX.Load (VMCS_Address => Initial_VMCS_Addr);
      VMX.VMCS_Write (Field => Constants.GUEST_VMX_PREEMPT_TIMER,
                      Value => SK.Word64 (Plan_Frame.Ticks));
   end Init;

   -------------------------------------------------------------------------

   --  Handle hypercall with given event number.
   procedure Handle_Hypercall
     (Current_Subject : Skp.Subject_Id_Type;
      Event_Nr        : SK.Word64)
   with
      Global  =>
        (In_Out => (CPU_Global.State, Events.State, Subjects.State,
                    X86_64.State)),
      Depends =>
        ((CPU_Global.State,
          Events.State, X86_64.State) =>+ (Current_Subject, Event_Nr),
         Subjects.State               =>+ Current_Subject)
   is
      Event       : Skp.Subjects.Event_Entry_Type;
      Dst_CPU     : Skp.CPU_Range;
      Valid_Event : Boolean;
      RIP         : SK.Word64;
   begin
      Valid_Event := Event_Nr <= SK.Word64 (Skp.Subjects.Event_Range'Last);

      if Valid_Event then
         Event := Skp.Subjects.Get_Event
           (Subject_Id => Current_Subject,
            Event_Nr   => Skp.Subjects.Event_Range (Event_Nr));

         if Event.Dst_Subject /= Skp.Invalid_Subject then
            if Event.Dst_Vector /= Skp.Invalid_Vector then
               Events.Insert_Event (Subject => Event.Dst_Subject,
                                    Event   => SK.Byte (Event.Dst_Vector));

               if Event.Send_IPI then
                  Dst_CPU := Skp.Subjects.Get_CPU_Id
                    (Subject_Id => Event.Dst_Subject);
                  Apic.Send_IPI (Vector  => IPI_Vector,
                                 Apic_Id => SK.Byte (Dst_CPU));
               end if;
            end if;

            if Event.Handover then

               Subject_Handover
                 (Old_Id   => Current_Subject,
                  New_Id   => Event.Dst_Subject,
                  New_VMCS => Skp.Subjects.Get_VMCS_Address
                    (Subject_Id => Event.Dst_Subject));
            end if;
         end if;
      end if;

      pragma Debug
        (not Valid_Event or Event = Skp.Subjects.Null_Event,
         Dump.Print_Spurious_Event
           (Current_Subject => Current_Subject,
            Event_Nr        => Event_Nr));

      RIP := Subjects.Get_RIP (Id => Current_Subject);
      RIP := RIP + Subjects.Get_Instruction_Length (Id => Current_Subject);
      Subjects.Set_RIP (Id    => Current_Subject,
                        Value => RIP);
   end Handle_Hypercall;

   -------------------------------------------------------------------------

   --  Handle external interrupt request with given vector.
   procedure Handle_Irq (Vector : SK.Byte)
   with
      Global  => (In_Out => (Events.State, X86_64.State)),
      Depends => (Events.State =>+ Vector, X86_64.State =>+ null)
   is
      Vect_Nr : Skp.Interrupts.Remapped_Vector_Type;
      Route   : Skp.Interrupts.Vector_Route_Type;
   begin
      if Vector >= Skp.Interrupts.Remap_Offset then
         Vect_Nr := Skp.Interrupts.Remapped_Vector_Type (Vector);
         Route   := Skp.Interrupts.Vector_Routing (Vect_Nr);
         if Route.Subject in Skp.Subject_Id_Type then
            Events.Insert_Event
              (Subject => Route.Subject,
               Event   => SK.Byte (Route.Vector));
         end if;

         pragma Debug
           (Route.Subject not in Skp.Subject_Id_Type
            and then Vector /= IPI_Vector,
            Dump.Print_Message_8
              (Msg  => "Spurious IRQ vector",
               Item => Vector));
      end if;

      pragma Debug (Vector < Skp.Interrupts.Remap_Offset,
                    Dump.Print_Message_8 (Msg  => "IRQ with invalid vector",
                                          Item => Vector));
      Apic.EOI;
   end Handle_Irq;

   -------------------------------------------------------------------------

   --  Handle trap with given number using trap table of current subject.
   procedure Handle_Trap
     (Current_Subject : Skp.Subject_Id_Type;
      Trap_Nr         : SK.Word64)
   with
      Global  =>
        (In_Out => (CPU_Global.State, Events.State, X86_64.State)),
      Depends =>
        ((CPU_Global.State, Events.State, X86_64.State) =>+
            (Current_Subject, Trap_Nr))
   is
      Trap_Entry : Skp.Subjects.Trap_Entry_Type;

      ----------------------------------------------------------------------

      procedure Panic_No_Trap_Handler
      with
          Global  => (In_Out => (X86_64.State)),
          Depends => (X86_64.State =>+ null),
          Post    => False --  Workaround for No_Return limitations
      is
      begin
         pragma Debug (Dump.Print_Message_16
                       (Msg  => ">>> No handler for trap",
                        Item => Word16 (Trap_Nr)));
         pragma Debug (Dump.Print_Subject (Subject_Id => Current_Subject));

         pragma Assume (False); --  Workaround for limited No_Return handling
         CPU.Panic;
      end Panic_No_Trap_Handler;

      ----------------------------------------------------------------------

      procedure Panic_Unknown_Trap
      with
         Global  => (In_Out => (X86_64.State)),
         Depends => (X86_64.State =>+ null),
         Post    => False --  Workaround for No_Return limitations
      is
      begin
         pragma Debug (Dump.Print_Message_64 (Msg  => ">>> Unknown trap",
                                              Item => Trap_Nr));
         pragma Debug (Dump.Print_Subject (Subject_Id => Current_Subject));

         pragma Assume (False); --  Workaround for limited No_Return handling
         CPU.Panic;
      end Panic_Unknown_Trap;

   begin
      if not (Trap_Nr <= SK.Word64 (Skp.Subjects.Trap_Range'Last)) then
         Panic_Unknown_Trap;
      end if;

      Trap_Entry := Skp.Subjects.Get_Trap
        (Subject_Id => Current_Subject,
         Trap_Nr    => Skp.Subjects.Trap_Range (Trap_Nr));

      if Trap_Entry.Dst_Subject = Skp.Invalid_Subject then
         Panic_No_Trap_Handler;
      end if;

      if Trap_Entry.Dst_Vector < Skp.Invalid_Vector then
         Events.Insert_Event
           (Subject => Trap_Entry.Dst_Subject,
            Event   => SK.Byte (Trap_Entry.Dst_Vector));
      end if;

      --  Handover to trap handler subject.

      Subject_Handover
        (Old_Id   => Current_Subject,
         New_Id   => Trap_Entry.Dst_Subject,
         New_VMCS => Skp.Subjects.Get_VMCS_Address
           (Subject_Id => Trap_Entry.Dst_Subject));

   end Handle_Trap;

   -------------------------------------------------------------------------

   procedure Handle_Vmx_Exit (Subject_Registers : in out SK.CPU_Registers_Type)
   with
      Refined_Global  =>
        (Input  => New_Major,
         In_Out => (CPU_Global.State, Current_Major, Events.State,
                    MP.Barrier, Subjects.State, X86_64.State)),
      Refined_Depends =>
        (CPU_Global.State    =>+ (Current_Major, New_Major, Subject_Registers,
                                  X86_64.State),
         Current_Major       =>+ (CPU_Global.State, New_Major, X86_64.State),
         (Events.State,
          Subject_Registers) =>+ (CPU_Global.State, Current_Major, New_Major,
                                  Subjects.State, Subject_Registers,
                                  X86_64.State),
         MP.Barrier          =>+ (CPU_Global.State, Current_Major,
                                  X86_64.State),
         Subjects.State      =>+ (CPU_Global.State, Current_Major,
                                  Subject_Registers, X86_64.State),
         X86_64.State        =>+ (CPU_Global.State, Current_Major,
                                  Events.State, New_Major, Subjects.State,
                                  Subject_Registers))
   is
      Exit_Status     : SK.Word64;
      Current_Subject : Skp.Subject_Id_Type;
      Current_Minor   : CPU_Global.Active_Minor_Frame_Type;

      ----------------------------------------------------------------------

      procedure Panic_Exit_Failure
      with
         Global  => (In_Out => (X86_64.State)),
         Depends => (X86_64.State =>+ null),
         Post    => False -- Workaround for No_Return limitations
      is
      begin
         pragma Debug (Dump.Print_VMX_Entry_Error
                       (Current_Subject => Current_Subject,
                        Exit_Reason     => Exit_Status));

         pragma Assume (False); -- Workaround for No_Return limitations
         CPU.Panic;
      end Panic_Exit_Failure;
   begin
      pragma $Prove_Warnings (Off, "statement has no effect",
         Reason => "False positive");
      Current_Minor := CPU_Global.Get_Current_Minor_Frame;
      pragma $Prove_Warnings (On, "statement has no effect");

      Current_Subject := CPU_Global.Get_Minor_Frame
        (Major_Id => Current_Major,
         Minor_Id => Current_Minor.Minor_Id).Subject_Id;

      VMX.VMCS_Read (Field => Constants.VMX_EXIT_REASON,
                     Value => Exit_Status);

      if SK.Bit_Test (Value => Exit_Status,
                      Pos   => Constants.VM_EXIT_ENTRY_FAILURE)
      then
         Panic_Exit_Failure;
      end if;

      Subjects.Save_State (Id   => Current_Subject,
                           GPRs => Subject_Registers);

      if Exit_Status = Constants.EXIT_REASON_EXTERNAL_INT then
         Handle_Irq (Vector => SK.Byte'Mod (Subjects.Get_Interrupt_Info
                     (Id => Current_Subject)));
      elsif Exit_Status = Constants.EXIT_REASON_VMCALL then
         Handle_Hypercall (Current_Subject => Current_Subject,
                           Event_Nr        => Subject_Registers.RAX);
      elsif Exit_Status = Constants.EXIT_REASON_TIMER_EXPIRY then

         --  Minor frame ticks consumed, update scheduling information.

         Update_Scheduling_Info;
      elsif Exit_Status = Constants.EXIT_REASON_INTERRUPT_WINDOW then

         --  Resume subject to inject pending event.

         VMX.VMCS_Set_Interrupt_Window (Value => False);
      else
         Handle_Trap (Current_Subject => Current_Subject,
                      Trap_Nr         => Exit_Status);
      end if;

      Inject_Event
        (Subject_Id => CPU_Global.Get_Current_Minor_Frame.Subject_Id);

      Subjects.Restore_State
        (Id   => CPU_Global.Get_Current_Minor_Frame.Subject_Id,
         GPRs => Subject_Registers);
   end Handle_Vmx_Exit;

end SK.Scheduler;
