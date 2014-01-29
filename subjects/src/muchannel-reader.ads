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

generic

   --  Protocol identifier.
   Protocol : Muchannel.Header_Field_Type;

package Muchannel.Reader
is

   type Result_Type is
     (Inactive,
      Incompatible_Interface,
      Epoch_Changed,
      No_Data,
      Overrun_Detected,
      Success);

   type Reader_Type is private;

   --  Synchronize reader with given channel.
   procedure Synchronize
     (Channel :     Channel_Type;
      Reader  : out Reader_Type;
      Result  : out Result_Type);

   --  Read next element from given channel.
   procedure Read
     (Channel :        Channel_Type;
      Reader  : in out Reader_Type;
      Element :    out Element_Type;
      Result  :    out Result_Type);

   --  Drain all current channel elements.
   procedure Drain
     (Channel :        Channel_Type;
      Reader  : in out Reader_Type);

private

   type Reader_Type is record
      Epoch    : Header_Field_Type;
      Protocol : Header_Field_Type;
      Size     : Header_Field_Type;
      Elements : Header_Field_Type;
      RC       : Header_Field_Type;
   end record;

end Muchannel.Reader;
