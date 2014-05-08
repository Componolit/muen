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

with DOM.Core.Nodes;
with DOM.Core.Elements;

with McKae.XML.XPath.XIA;

with Mulog;
with Muxml.Utils;
with Mutools.Immutable_Processors;
with Mucfgcheck.Memory;
with Mucfgcheck.Device;

pragma Elaborate_All (Mutools.Immutable_Processors);

package body Expand.Pre_Checks
is

   package Check_Procs is new
     Mutools.Immutable_Processors (Param_Type => Muxml.XML_Data_Type);

   --  Check the existence of channel endpoint (reader or writer) event
   --  attributes given by name. The XPath query specifies which global
   --  channels should be checked.
   procedure Check_Channel_Events_Attr
     (XML_Data  : Muxml.XML_Data_Type;
      XPath     : String;
      Endpoint  : String;
      Attr_Name : String);

   -------------------------------------------------------------------------

   procedure Channel_Reader_Has_Event_Vector (XML_Data : Muxml.XML_Data_Type)
   is
   begin
      Check_Channel_Events_Attr
        (XML_Data  => XML_Data,
         XPath     => "/system/channels/channel[@hasEvent!='switch']",
         Endpoint  => "reader",
         Attr_Name => "vector");
   end Channel_Reader_Has_Event_Vector;

   -------------------------------------------------------------------------

   procedure Channel_Reader_Writer (XML_Data : Muxml.XML_Data_Type)
   is
      Channels : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => XML_Data.Doc,
           XPath => "/system/channels/channel");
   begin
      Mulog.Log (Msg => "Checking" & DOM.Core.Nodes.Length
                 (List => Channels)'Img & " channel(s) for reader/writer "
                 & "count");
      for I in 0 .. DOM.Core.Nodes.Length (List => Channels) - 1 loop
         declare
            Channel : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Channels,
                 Index => I);
            Channel_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Channel,
                 Name => "name");
            Reader_Count : constant Natural
              := DOM.Core.Nodes.Length
                (List => McKae.XML.XPath.XIA.XPath_Query
                   (N     => XML_Data.Doc,
                    XPath => "/system/subjects/subject/channels/reader[@ref='"
                    & Channel_Name & "']"));
            Writer_Count : constant Natural
              := DOM.Core.Nodes.Length
                (List => McKae.XML.XPath.XIA.XPath_Query
                   (N     => XML_Data.Doc,
                    XPath => "/system/subjects/subject/channels/writer[@ref='"
                    & Channel_Name & "']"));
         begin
            if Reader_Count /= 1 then
               raise Mucfgcheck.Validation_Error with "Invalid number of "
                 & "readers for channel '" & Channel_Name & "':"
                 & Reader_Count'Img;
            end if;

            if Writer_Count /= 1 then
               raise Mucfgcheck.Validation_Error with "Invalid number of "
                 & "writers for channel '" & Channel_Name & "':"
                 & Writer_Count'Img;
            end if;
         end;
      end loop;
   end Channel_Reader_Writer;

   -------------------------------------------------------------------------

   procedure Channel_Writer_Has_Event_ID (XML_Data : Muxml.XML_Data_Type)
   is
   begin
      Check_Channel_Events_Attr
        (XML_Data  => XML_Data,
         XPath     => "/system/channels/channel[@hasEvent]",
         Endpoint  => "writer",
         Attr_Name => "event");
   end Channel_Writer_Has_Event_ID;

   -------------------------------------------------------------------------

   procedure Check_Channel_Events_Attr
     (XML_Data  : Muxml.XML_Data_Type;
      XPath     : String;
      Endpoint  : String;
      Attr_Name : String)
   is
      Channels : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => XML_Data.Doc,
           XPath => XPath);
   begin
      Mulog.Log (Msg => "Checking '" & Attr_Name & "' attribute of"
                 & DOM.Core.Nodes.Length (List => Channels)'Img & " channel "
                 & Endpoint & "(s) with associated event");

      for I in 0 .. DOM.Core.Nodes.Length (List => Channels) - 1 loop
         declare
            Channel_Node : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Channels,
                 Index => I);
            Channel_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Channel_Node,
                 Name => "name");
            Node : constant DOM.Core.Node
              := Muxml.Utils.Get_Element
                (Doc   => XML_Data.Doc,
                 XPath => "/system/subjects/subject/channels/" & Endpoint
                 & "[@ref='" & Channel_Name & "']");
         begin
            if DOM.Core.Elements.Get_Attribute
              (Elem => Node,
               Name => Attr_Name) = ""
            then
               raise Mucfgcheck.Validation_Error with "Missing '" & Attr_Name
                 & "' attribute for " & Endpoint & " of channel '"
                 & Channel_Name & "'";
            end if;
         end;
      end loop;
   end Check_Channel_Events_Attr;

   -------------------------------------------------------------------------

   function Get_Count return Natural renames Check_Procs.Get_Count;

   -------------------------------------------------------------------------

   procedure Platform_CPU_Count_Presence (XML_Data : Muxml.XML_Data_Type)
   is
      Attr_Path : constant String := "/system/platform/processor/@logicalCpus";
      Attr      : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => XML_Data.Doc,
           XPath => Attr_Path);
   begin
      Mulog.Log (Msg => "Checking presence of '" & Attr_Path & "' attribute");

      if DOM.Core.Nodes.Length (List => Attr) /= 1 then
         raise Mucfgcheck.Validation_Error with "Required "
           & "'/system/platform/processor/@logicalCpus' attribute not found, "
           & "add it or use mucfgmerge tool";
      end if;
   end Platform_CPU_Count_Presence;

   -------------------------------------------------------------------------

   procedure Register_All
   is
   begin
      Check_Procs.Register
        (Process => Mucfgcheck.Memory.Physical_Memory_References'Access);
      Check_Procs.Register
        (Process => Mucfgcheck.Device.Device_Memory_References'Access);

      Check_Procs.Register (Process => Tau0_Presence_In_Scheduling'Access);
      Check_Procs.Register (Process => Subject_Monitor_References'Access);
      Check_Procs.Register (Process => Subject_Channel_References'Access);
      Check_Procs.Register (Process => Channel_Reader_Writer'Access);
      Check_Procs.Register (Process => Channel_Writer_Has_Event_ID'Access);
      Check_Procs.Register (Process => Channel_Reader_Has_Event_Vector'Access);
      Check_Procs.Register (Process => Platform_CPU_Count_Presence'Access);
   end Register_All;

   -------------------------------------------------------------------------

   procedure Run (Data : Muxml.XML_Data_Type) renames Check_Procs.Run;

   -------------------------------------------------------------------------

   procedure Subject_Channel_References (XML_Data : Muxml.XML_Data_Type)
   is
      --  Returns the error message for a given reference node.
      function Error_Msg (Node : DOM.Core.Node) return String;

      --  Match name of reference and channel.
      function Match_Channel_Name (Left, Right : DOM.Core.Node) return Boolean;

      ----------------------------------------------------------------------

      function Error_Msg (Node : DOM.Core.Node) return String
      is
         Ref_Channel_Name : constant String := DOM.Core.Elements.Get_Attribute
           (Elem => Node,
            Name => "ref");
         Subj_Name : constant String := DOM.Core.Elements.Get_Attribute
           (Elem => Muxml.Utils.Ancestor_Node
              (Node  => Node,
               Level => 2),
            Name => "name");
      begin
         return "Channel '" & Ref_Channel_Name & "' referenced by subject '"
           & Subj_Name & "' does not exist";
      end Error_Msg;

      ----------------------------------------------------------------------

      function Match_Channel_Name (Left, Right : DOM.Core.Node) return Boolean
      is
         Ref_Name : constant String := DOM.Core.Elements.Get_Attribute
           (Elem => Left,
            Name => "ref");
         Channel_Name : constant String := DOM.Core.Elements.Get_Attribute
           (Elem => Right,
            Name => "name");
      begin
         return Ref_Name = Channel_Name;
      end Match_Channel_Name;
   begin
      Mucfgcheck.For_Each_Match
        (XML_Data     => XML_Data,
         Source_XPath => "/system/subjects/subject/channels/*",
         Ref_XPath    => "/system/channels/channel",
         Log_Message  => "subject channel reference(s)",
         Error        => Error_Msg'Access,
         Match        => Match_Channel_Name'Access);
   end Subject_Channel_References;

   -------------------------------------------------------------------------

   procedure Subject_Monitor_References (XML_Data : Muxml.XML_Data_Type)
   is
      --  Returns the error message for a given reference node.
      function Error_Msg (Node : DOM.Core.Node) return String;

      ----------------------------------------------------------------------

      function Error_Msg (Node : DOM.Core.Node) return String
      is
         Ref_Subj_Name : constant String := DOM.Core.Elements.Get_Attribute
           (Elem => Node,
            Name => "subject");
         Subj_Name     : constant String := DOM.Core.Elements.Get_Attribute
           (Elem => Muxml.Utils.Ancestor_Node
              (Node  => Node,
               Level => 2),
            Name => "name");
      begin
         return "Subject '" & Ref_Subj_Name & "' referenced by subject monitor"
           & " '" & Subj_Name & "' does not exist";
      end Error_Msg;
   begin
      Mucfgcheck.For_Each_Match
        (XML_Data     => XML_Data,
         Source_XPath => "/system/subjects/subject/monitor/state",
         Ref_XPath    => "/system/subjects/subject",
         Log_Message  => "subject monitor reference(s)",
         Error        => Error_Msg'Access,
         Match        => Mucfgcheck.Match_Subject_Name'Access);
   end Subject_Monitor_References;

   -------------------------------------------------------------------------

   procedure Tau0_Presence_In_Scheduling (XML_Data : Muxml.XML_Data_Type)
   is
      Tau0_Node : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => XML_Data.Doc,
           XPath => "/system/scheduling/majorFrame/cpu/minorFrame"
           & "[@subject='tau0']");
   begin
      Mulog.Log
        (Msg => "Checking presence of tau0 subject in scheduling plan");
      if DOM.Core.Nodes.Length (List => Tau0_Node) = 0 then
         raise Mucfgcheck.Validation_Error with "Subject tau0 not present in "
           & "scheduling plan";
      end if;
   end Tau0_Presence_In_Scheduling;

end Expand.Pre_Checks;