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

with Skp;

package SK.Dump
is

   --  Print CPU registers.
   procedure Print_Registers
     (GPR : CPU_Registers_Type;
      RIP : Word64; CS  : Word64; RFL : Word64; RSP : Word64; SS  : Word64;
      CR0 : Word64; CR2 : Word64; CR3 : Word64; CR4 : Word64);
   pragma Inline_Always (Print_Registers);

   --  Print IRQ Routing.
   procedure Print_IRQ_Routing
     (IRQ     : SK.Byte;
      Vector  : SK.Byte;
      CPU_ID  : SK.Byte;
      APIC_ID : SK.Byte);

   --  Print ISR execution environment state.
   procedure Print_ISR_State (Context : Isr_Context_Type);
   pragma Inline_Always (Print_ISR_State);

   --  Print a single value prepended by a message.
   procedure Print_Message_8  (Msg : String; Item : SK.Byte);
   procedure Print_Message_16 (Msg : String; Item : SK.Word16);
   procedure Print_Message_32 (Msg : String; Item : SK.Word32);
   procedure Print_Message_64 (Msg : String; Item : SK.Word64);

   --  Print invalid event from userspace.
   procedure Print_Spurious_Event
     (Current_Subject : Skp.Subject_Id_Type;
      Event_Nr        : SK.Word64);

   --  Print subject exit information including the whole subject state.
   procedure Print_Subject (Subject_Id : Skp.Subject_Id_Type);
   pragma Inline_Always (Print_Subject);

   --  Print exit reason and exit qualification of VMX entry errors.
   procedure Print_VMX_Entry_Error
     (Current_Subject : Skp.Subject_Id_Type;
      Exit_Reason     : SK.Word64);

   --  Print VMX error after vmlaunch/vmresume failed.
   procedure Print_VMX_Error;
   pragma Inline_Always (Print_VMX_Error);

end SK.Dump;
