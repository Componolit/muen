with System.Storage_Elements;

with SK.Constants;
with SK.Console;
with SK.Console_VGA;

package body SK.Subjects
is

   type Subject_Array is array (Index_Type) of State_Type;

   --  Descriptors used to manage subjects.
   Descriptors : Subject_Array;

   --# accept Warning, 350, Guest_Stack_Address, "Imported from Linker";
   Guest_Stack_Address : SK.Word64;
   pragma Import (C, Guest_Stack_Address, "guest_stack_pointer");
   --# end accept;

   --# accept Warning, 350, VMCS_Address, "Imported from Linker";
   VMCS_Address : SK.Word64;
   pragma Import (C, VMCS_Address, "vmcs_pointer");
   --# end accept;

   -------------------------------------------------------------------------

   function Get_State (Idx : Index_Type) return State_Type
   is
   begin
      return Descriptors (Idx);
   end Get_State;

   -------------------------------------------------------------------------

   procedure Set_State
     (Idx   : Index_Type;
      State : State_Type)
   is
   begin
      Descriptors (Idx) := State;
   end Set_State;

   -------------------------------------------------------------------------

   procedure Subject_Main_1
   is
      --# hide Subject_Main_1;

      package Text_IO is new SK.Console
        (Initialize      => Console_VGA.Init,
         Output_New_Line => Console_VGA.New_Line,
         Output_Char     => Console_VGA.Put_Char);

      Greeter : constant String := "Hello from guest world";
      Counter : SK.Word32       := 0;
      Idx     : Positive        := 1;
      Dlt     : Integer         := -1;
   begin
      Text_IO.Init;
      Text_IO.Put_Line (Item => Greeter);
      Text_IO.New_Line;

      for I in Greeter'Range loop
         Text_IO.Put_Char (Item => Character'Val (176));
      end loop;

      while True loop
         if Counter mod 2**19 = 0 then
            Console_VGA.Set_Position (X => Integer (Idx - Dlt),
                                      Y => 3);
            Text_IO.Put_Char (Item => Character'Val (176));
            if Idx = Greeter'Last then
               Dlt := -1;
            elsif Idx = Greeter'First then
               Dlt := 1;
            end if;
            Console_VGA.Set_Position (X => Integer (Idx),
                                      Y => 3);
            Text_IO.Put_Char (Item => Character'Val (178));
            Idx := Idx + Dlt;
         end if;
         Counter := Counter + 1;
      end loop;
   end Subject_Main_1;

begin

   --# hide SK.Subjects;

   declare
      Unused_High, VMCS_Region : SK.Word32;
      for VMCS_Region'Address use System'To_Address (VMCS_Address);
   begin
      CPU.Get_MSR
        (Register => Constants.IA32_VMX_BASIC,
         Low      => VMCS_Region,
         High     => Unused_High);

      Descriptors (Descriptors'First)
        := State_Type'
          (Regs          => CPU.Null_Regs,
           Stack_Address => Guest_Stack_Address,
           VMCS_Address  => VMCS_Address,
           Entry_Point   => SK.Word64
             (System.Storage_Elements.To_Integer
                (Value => Subject_Main_1'Address)));
   end;
end SK.Subjects;
