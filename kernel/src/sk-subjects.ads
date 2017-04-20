--
--  Copyright (C) 2013, 2015, 2016  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2013, 2015, 2016  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

private with System;

private with Skp.Kernel;

with Skp;

with X86_64;

package SK.Subjects
with
   Abstract_State => State,
   Initializes    => State
is

   --  Returns True if the subject with given ID can accept interrupts.
   function Accepts_Interrupts (ID : Skp.Subject_Id_Type) return Boolean
   with
      Global => (Input => State);

   --  Move instruction pointer of subject with given ID to next instruction.
   procedure Increment_RIP (ID : Skp.Subject_Id_Type)
   with
      Global  => (In_Out => State),
      Depends => (State  =>+ ID);

   --  Returns True if required invariants hold for given subject state.
   function Valid_State (Id : Skp.Subject_Id_Type) return Boolean
   with
      Ghost;

   --  Restore VMCS guest state from the subject state identified by ID.
   --  The Regs field of the subject state is returned to the caller.
   procedure Restore_State
     (Id   :     Skp.Subject_Id_Type;
      Regs : out SK.CPU_Registers_Type)
   with
      Global  => (Input  => State,
                  In_Out => X86_64.State),
      Depends => (X86_64.State =>+ (Id, State),
                  Regs         =>  (Id, State)),
      Pre     => Valid_State (Id => Id);

   --  Ensure subject state invariants.
   procedure Filter_State (Id : Skp.Subject_Id_Type)
   with
      Global  => (In_Out => State),
      Depends => (State =>+ Id),
      Post    => Valid_State (Id => Id);

   --  Save registers and VMCS guest data to the state of the subject
   --  identified by ID.
   procedure Save_State
     (Id   : Skp.Subject_Id_Type;
      Regs : SK.CPU_Registers_Type)
   with
      Global  => (In_Out => (State, X86_64.State)),
      Depends => (State        =>+ (Id, Regs, X86_64.State),
                  X86_64.State =>+ null);

   --  Clear state of subject with given ID.
   procedure Clear_State (Id : Skp.Subject_Id_Type)
   with
      Global  => (In_Out => State),
      Depends => (State =>+ Id);

private

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
      Part_Of => State,
      Address => System'To_Address (Skp.Kernel.Subj_States_Address);
   pragma Annotate
     (GNATprove, Intentional,
      "not initialized",
      "Subject states are initialized by their owning CPU. Not yet modeled");

end SK.Subjects;
