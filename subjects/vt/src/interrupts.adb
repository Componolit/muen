with System.Machine_Code;
with System.Storage_Elements;

with SK.Descriptors;
with SK.IO;
with SK.Console;
with SK.Console_VGA;

with VGA_Output;

package body Interrupts
is

   subtype Width_Type  is Natural range 1 .. 80;
   subtype Height_Type is Natural range 1 .. 25;

   package VGA is new SK.Console_VGA
     (Width_Type   => Width_Type,
      Height_Type  => Height_Type,
      Base_Address => System'To_Address (16#000b_9000#));

   package Text_IO is new SK.Console
     (Initialize      => VGA.Init,
      Output_New_Line => VGA.New_Line,
      Output_Char     => VGA.Put_Char);

   --  Assembly ISR.
   ISR_Handler : SK.Word64;
   pragma Import (C, ISR_Handler, "isr_handler_ptr");

   IDT : SK.Descriptors.IDT_Type;

   --  Interrupt table pointer, loaded into IDTR
   IDT_Pointer : SK.Descriptors.Pseudo_Descriptor_Type;

   type GDT_Type is array (1 .. 3) of SK.Word64;

   GDT : GDT_Type;
   for GDT'Alignment use 8;

   --  Global descriptor table pointer, loaded into GDTR
   GDT_Pointer : SK.Descriptors.Pseudo_Descriptor_Type;

   --  PS/2 constants.

   Data_Port       : constant := 16#60#;
   Status_Register : constant := 16#64#;

   OUTPUT_BUFFER_STATUS : constant := 0;

   -------------------------------------------------------------------------

   procedure Handle_Interrupt
   is
      use type SK.Byte;

      Status, Data : SK.Byte;
   begin
      loop
         SK.IO.Inb (Port  => Status_Register,
                    Value => Status);
         exit when not SK.Bit_Test
           (Value => SK.Word64 (Status),
            Pos   => OUTPUT_BUFFER_STATUS);

         SK.IO.Inb (Port  => Data_Port,
                    Value => Data);

         if Data <= 86 then
            case Data is
               when 1  =>
                  Text_IO.Init;
               when 59 =>
                  VGA_Output.Set (Slot => 1);
                  Text_IO.Put_Line ("Switching to VT 1");
               when 60 =>
                  VGA_Output.Set (Slot => 2);
                  Text_IO.Put_Line ("Switching to VT 2");
               when 61 =>
                  VGA_Output.Set (Slot => 3);
                  Text_IO.Put_Line ("Switching to VT 3");
               when 62 =>
                  VGA_Output.Set (Slot => 4);
                  Text_IO.Put_Line ("Switching to VT 4");
               when others =>
                  null;
            end case;
         end if;
      end loop;
   end Handle_Interrupt;

   -------------------------------------------------------------------------

   procedure Initialize
   is
      use type SK.Word16;
      use type SK.Word64;
   begin
      GDT := GDT_Type'(1 => 0,
                       2 => 16#20980000000000#,
                       3 => 16#20930000000000#);
      GDT_Pointer := SK.Descriptors.Pseudo_Descriptor_Type'
        (Limit => 16 * SK.Word16 (GDT'Last) - 1,
         Base  => SK.Word64
           (System.Storage_Elements.To_Integer (Value => GDT'Address)));
      System.Machine_Code.Asm
        (Template => "lgdt (%0)",
         Inputs   => (System.Address'Asm_Input ("r", GDT_Pointer'Address)),
         Volatile => True);

      IDT := SK.Descriptors.IDT_Type'
        (others => SK.Descriptors.Gate_Type'
           (Offset_15_00     => 0,
            Segment_Selector => 0,
            Flags            => 0,
            Offset_31_16     => 0,
            Offset_63_32     => 0,
            Reserved         => 0));

      for I in SK.Descriptors.Vector_Type range IDT'Range loop
         IDT (I) := SK.Descriptors.Gate_Type'
           (Offset_15_00     => SK.Word16
              (ISR_Handler and 16#0000_0000_0000_ffff#),
            Segment_Selector => 16#0008#,
            Flags            => 16#8e00#,
            Offset_31_16     => SK.Word16
              ((ISR_Handler and 16#0000_0000_ffff_0000#) / 2 ** 16),
            Offset_63_32     => SK.Word32
              ((ISR_Handler and 16#ffff_ffff_0000_0000#) / 2 ** 32),
            Reserved         => 0);
      end loop;

      IDT_Pointer := SK.Descriptors.Pseudo_Descriptor_Type'
        (Limit => 16 * SK.Word16 (IDT'Last) - 1,
         Base  => SK.Word64
           (System.Storage_Elements.To_Integer (Value => IDT'Address)));
      System.Machine_Code.Asm
        (Template => "lidt (%0)",
         Inputs   => (System.Address'Asm_Input ("r", IDT_Pointer'Address)),
         Volatile => True);

      Text_IO.Init;
      Text_IO.Put_Line ("VT subject running");
   end Initialize;

end Interrupts;
