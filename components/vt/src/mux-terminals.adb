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

with SK.CPU;
with SK.IO;

with VT_Channels;

with Log;
with Mux.Screens;
with Mux.Channels;

package body Mux.Terminals
is

   Active_Slot : Slot_Range := Slot_Range'First;
   pragma Atomic (Active_Slot);

   VGA_CRT_Register       : constant := 16#3d4#;
   VGA_CRT_Idx_Start_High : constant := 16#0c#;
   VGA_CRT_Idx_Start_Low  : constant := 16#0d#;

   type Slot_Mapping is array (Input.Keysym_Type) of Slot_Range;

   --  Key to session slot mapping
   Slot_Map : constant Slot_Mapping :=
     (Input.KEY_F1 => 1,
      Input.KEY_F2 => 2,
      Input.KEY_F3 => 3,
      Input.KEY_F4 => 4,
      Input.KEY_F5 => 5,
      Input.KEY_F6 => 6,
      others       => Slot_Range'Last);

   type Flags_Type is array (Input_Channel_Range) of Boolean;

   --  Pending data flags per channel.
   Pending_Data : Flags_Type := (others => False);

   --  Read data from input channels if new data is present.
   procedure Update_In_Channels;

   --  Set VGA start address, see:
   --  www.phatcode.net/res/224/files/html/ch23/23-04.html
   procedure Set_VGA_Start (Address : SK.Word16);

   --  Returns True if one of the channels has data to consume.
   function Has_Pending_Data return Boolean;

   -------------------------------------------------------------------------

   function Get_Active_Slot return Slot_Range
   is
   begin
      return Active_Slot;
   end Get_Active_Slot;

   -------------------------------------------------------------------------

   function Has_Pending_Data return Boolean
   is
   begin
      for I in Pending_Data'Range loop
         if Pending_Data (I) then
            return True;
         end if;
      end loop;

      return False;
   end Has_Pending_Data;

   -------------------------------------------------------------------------

   procedure Initialize
   is
   begin
      Mux.Screens.Init;
      Mux.Screens.Set_Active (Screen => Active_Slot);
      Mux.Channels.Init;
   end Initialize;

   -------------------------------------------------------------------------

   procedure Process_Key (Event : Input.Key_Event_Type)
   is
      use Input;
   begin
      case Event.Key is
         when KEY_F1 | KEY_F2 | KEY_F3 | KEY_F4 | KEY_F5 | KEY_F6 =>
            if Event.Pressed and then
              Active_Slot /= Slot_Map (Event.Key)
            then
               Set (Slot => Slot_Map (Event.Key));
               Log.Text_IO.Put_String (Item => "Switching to VT ");
               Log.Text_IO.Put_Byte (Item => SK.Byte (Slot_Map (Event.Key)));
               Log.Text_IO.New_Line;
            end if;
         when others =>
            if Active_Slot > 2 then
               return;
            end if;

            Mux.Channels.Write
              (Channel => Output_Channel_Range (Active_Slot),
               Event   => Event);
      end case;
   end Process_Key;

   -------------------------------------------------------------------------

   procedure Run
   is
      use type SK.Byte;
   begin
      loop
         SK.CPU.Cli;
         if not Has_Pending_Data then
            SK.CPU.Sti;
            SK.CPU.Hlt;
         else
            SK.CPU.Sti;
         end if;
         Update_In_Channels;
      end loop;
   end Run;

   -------------------------------------------------------------------------

   procedure Set (Slot : Slot_Range)
   is
      use type SK.Word16;
   begin
      Active_Slot := Slot;
      Mux.Screens.Set_Active (Screen => Slot);
      Set_VGA_Start (Address => SK.Word16 (Slot - 1) * 16#800#);
   end Set;

   -------------------------------------------------------------------------

   procedure Set_Pending_Flag (Channel_Nr : Input_Channel_Range)
   is
   begin
      Pending_Data (Channel_Nr) := True;
   end Set_Pending_Flag;

   -------------------------------------------------------------------------

   procedure Set_VGA_Start (Address : SK.Word16)
   is
      use type SK.Word16;
   begin
      SK.IO.Outw
        (Port  => VGA_CRT_Register,
         Value => VGA_CRT_Idx_Start_High + (Address and 16#ff00#));
      SK.IO.Outw
        (Port  => VGA_CRT_Register,
         Value => VGA_CRT_Idx_Start_Low + ((Address * 2 ** 8) and 16#ff00#));
   end Set_VGA_Start;

   -------------------------------------------------------------------------

   procedure Update_In_Channels
   is
      use Mux;
      use VT_Channels;

      use type VT_Channels.VT_Channel_Rdr.Result_Type;

      Data : Character;
      Res  : VT_Channel_Rdr.Result_Type;
      C    : Input_Channel_Range := Input_Channel_Range'Last;
   begin
      while Has_Pending_Data loop
         if Pending_Data (C) then
            for I in Positive range 1 .. 80 loop
               Channels.Read (Channel => C,
                              Char    => Data,
                              Result  => Res);

               case Res is
                  when VT_Channel_Rdr.Incompatible_Interface =>
                     Log.Text_IO.Put_String (Item => "Channel ");
                     Log.Text_IO.Put_Byte   (Item => SK.Byte (C));
                     Log.Text_IO.Put_Line
                       (Item => ": Incompatible interface detected");
                  when VT_Channel_Rdr.Epoch_Changed =>
                     Log.Text_IO.Put_String (Item => "Channel ");
                     Log.Text_IO.Put_Byte   (Item => SK.Byte (C));
                     Log.Text_IO.Put_Line   (Item => ": Epoch changed");
                  when VT_Channel_Rdr.No_Data =>
                     SK.CPU.Cli;
                     Pending_Data (C) := Channels.Has_Pending_Data
                       (Channel => C);
                     SK.CPU.Sti;
                  when VT_Channel_Rdr.Overrun_Detected =>
                     Log.Text_IO.Put_String (Item => "Channel ");
                     Log.Text_IO.Put_Byte   (Item => SK.Byte (C));
                     Log.Text_IO.Put_Line   (Item => ": Overrun detected");
                  when VT_Channel_Rdr.Inactive =>
                     Log.Text_IO.Put_String (Item => "Channel ");
                     Log.Text_IO.Put_Byte   (Item => SK.Byte (C));
                     Log.Text_IO.Put_Line   (Item => ": Inactive");
                  when VT_Channel_Rdr.Success =>
                     Screens.Update
                       (Screen => Slot_Range (C),
                        Char   => Data);
               end case;

               exit when Res /= VT_Channel_Rdr.Success;
            end loop;
         end if;

         if C = Input_Channel_Range'First then
            C := Input_Channel_Range'Last;
         else
            C := C - 1;
         end if;
      end loop;
   end Update_In_Channels;

end Mux.Terminals;
