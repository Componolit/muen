--
--  Copyright (C) 2014  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2014  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

with Ada.Strings.Unbounded;

with Interfaces;

with DOM.Core.Nodes;
with DOM.Core.Elements;

with McKae.XML.XPath.XIA;

with Mulog;
with Mutools.Utils;
with Mutools.Processors;

with Pack.Command_Line;

pragma Elaborate_All (Mutools.Processors);

package body Pack.Content_Providers
is

   use Ada.Strings.Unbounded;

   package Content_Procs is new Mutools.Processors (Param_Type => Param_Type);

   -------------------------------------------------------------------------

   function Get_Count return Natural renames Content_Procs.Get_Count;

   -------------------------------------------------------------------------

   procedure Process_Files (Data : in out Param_Type)
   is
      In_Dir     : constant String := Command_Line.Get_Input_Dir;
      File_Nodes : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
        (N     => Data.XML_Doc,
         XPath => "/system/memory/memory/file");
      File_Count : constant Natural
        := DOM.Core.Nodes.Length (List => File_Nodes);
   begin
      Mulog.Log (Msg => "Found" & File_Count'Img & " file(s) to process");

      if File_Count = 0 then
         return;
      end if;

      for I in 0 .. File_Count - 1 loop
         declare
            File   : constant DOM.Core.Node := DOM.Core.Nodes.Item
              (List  => File_Nodes,
               Index => I);
            Memory : constant DOM.Core.Node := DOM.Core.Nodes.Parent_Node
              (N => File);

            Filename   : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => File,
                 Name => "filename");
            Format     : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => File,
                 Name => "format");
            Offset_Str : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => File,
                 Name => "offset");
            Address    : constant Interfaces.Unsigned_64
              := Interfaces.Unsigned_64'Value
                (DOM.Core.Elements.Get_Attribute
                   (Elem => Memory,
                    Name => "physicalAddress"));
            Size       : constant Interfaces.Unsigned_64
              := Interfaces.Unsigned_64'Value
                (DOM.Core.Elements.Get_Attribute
                   (Elem => Memory,
                    Name => "size"));
            Mem_Name   : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Memory,
                 Name => "name");
            Offset     : Interfaces.Unsigned_64 := 0;
         begin
            if Offset_Str /= "none" then
               Offset := Interfaces.Unsigned_64'Value (Offset_Str);
            end if;

            Image.Add_File (Image   => Data.Image,
                            Path    => In_Dir & "/" & Filename,
                            Address => Address,
                            Size    => Size,
                            Offset  => Offset);

            Manifest.Add_Entry (Manifest => Data.Manifest,
                                Mem_Name => Mem_Name,
                                Format   => Format,
                                Content  => In_Dir & "/" & Filename,
                                Address  => Address,
                                Size     => Size,
                                Offset   => Offset);
         end;
      end loop;
   end Process_Files;

   -------------------------------------------------------------------------

   procedure Process_Fills (Data : in out Param_Type)
   is
      Nodes : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
        (N     => Data.XML_Doc,
         XPath => "/system/memory/memory/fill");
      Count : constant Natural := DOM.Core.Nodes.Length (List => Nodes);
   begin
      Mulog.Log (Msg => "Found" & Count'Img & " fill(s) to process");

      if Count = 0 then
         return;
      end if;

      for I in 0 .. Count - 1 loop
         declare
            Fill   : constant DOM.Core.Node := DOM.Core.Nodes.Item
              (List  => Nodes,
               Index => I);
            Memory : constant DOM.Core.Node := DOM.Core.Nodes.Parent_Node
              (N => Fill);

            Pattern  : constant Ada.Streams.Stream_Element
              := Ada.Streams.Stream_Element'Value
                (DOM.Core.Elements.Get_Attribute
                   (Elem => Fill,
                    Name => "pattern"));
            Address  : constant Ada.Streams.Stream_Element_Offset
              := Ada.Streams.Stream_Element_Offset'Value
                (DOM.Core.Elements.Get_Attribute
                   (Elem => Memory,
                    Name => "physicalAddress"));
            Size     : constant Ada.Streams.Stream_Element_Offset
              := Ada.Streams.Stream_Element_Offset'Value
                (DOM.Core.Elements.Get_Attribute
                   (Elem => Memory,
                    Name => "size"));
            Mem_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Memory,
                 Name => "name");
         begin
            Image.Add_Buffer (Image   => Data.Image,
                              Buffer  => (1 .. Size => Pattern),
                              Address => Address);

            Manifest.Add_Entry
              (Manifest => Data.Manifest,
               Mem_Name => Mem_Name,
               Format   => "fill_pattern",
               Content  => Mutools.Utils.To_Hex
                 (Number => Interfaces.Unsigned_64 (Pattern)),
               Address  => Interfaces.Unsigned_64 (Address),
               Size     => Interfaces.Unsigned_64 (Size),
               Offset   => 0);
         end;
      end loop;
   end Process_Fills;

   -------------------------------------------------------------------------

   procedure Register_All
   is
   begin
      Content_Procs.Register (Process => Process_Files'Access);
      Content_Procs.Register (Process => Process_Fills'Access);
   end Register_All;

   -------------------------------------------------------------------------

   procedure Run (Data : in out Param_Type) renames Content_Procs.Run;

end Pack.Content_Providers;