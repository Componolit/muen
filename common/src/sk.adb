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

package body SK
is

   -------------------------------------------------------------------------

   function Bit_Clear
     (Value : Word64;
      Pos   : Word64_Pos)
      return Word64
   is
      Mask : Word64;
   begin
      Mask := not (2 ** Natural (Pos));
      return Value and Mask;
   end Bit_Clear;

   -------------------------------------------------------------------------

   function Bit_Set
     (Value : Word64;
      Pos   : Word64_Pos)
      return Word64
   is
   begin
      return (Value or 2 ** Natural (Pos));
   end Bit_Set;

   -------------------------------------------------------------------------

   function Bit_Test
     (Value : Word64;
      Pos   : Word64_Pos)
      return Boolean
   is
      Mask : Word64;
   begin
      Mask := 2 ** Natural (Pos);
      return ((Value and Mask) /= 0);
   end Bit_Test;

end SK;
