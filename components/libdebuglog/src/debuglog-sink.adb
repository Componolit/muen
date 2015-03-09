--
--  Copyright (C) 2014  secunet Security Networks AG
--  All rights reserved.
--
--  Redistribution and use in source and binary forms, with or without
--  modification, are permitted provided that the following conditions are met:
--
--    * Redistributions of source code must retain the above copyright notice,
--      this list of conditions and the following disclaimer.
--
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--
--  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
--  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
--  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
--  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
--  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
--  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
--  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
--  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
--  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
--  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
--  POSSIBILITY OF SUCH DAMAGE.
--

with System.Machine_Code;

with Interfaces;

with Debuglog.Config;
with Debuglog.Types;
with Debuglog.Stream.Writer_Instance;

--  Disable check subprogram bodies in alphabetical order
pragma Style_Checks ("-o");

package body Debuglog.Sink
with
   SPARK_Mode => Off
is

   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;

   Message_Channel : Stream.Channel_Type
     with
       Address => System'To_Address (Config.Channel_Base_Addr),
       Async_Readers;

   Message_Buffer : Types.Data_Type     := Types.Null_Data;
   Message_Index  : Types.Message_Index := Types.Message_Index'First;

   -------------------------------------------------------------------------

   --  TODO: Remove as soon as SK.CPU.RDTSC is available in a library.
   function RDTSC return Interfaces.Unsigned_64;
   function RDTSC return Interfaces.Unsigned_64
   with
      SPARK_Mode => Off
   is
      Lo : Interfaces.Unsigned_32;
      Hi : Interfaces.Unsigned_32;
   begin
      System.Machine_Code.Asm
        (Template => "rdtsc",
         Outputs  =>
           (Interfaces.Unsigned_32'Asm_Output ("=a", Lo),
            Interfaces.Unsigned_32'Asm_Output ("=d", Hi)),
         Volatile => True);
      return Interfaces.Unsigned_64 (Lo) +
        Interfaces.Unsigned_64 (Hi) * 2 ** 32;
   end RDTSC;

   -------------------------------------------------------------------------

   procedure Flush
   is
   begin
      Message_Buffer.Timestamp := RDTSC;

      Stream.Writer_Instance.Write (Channel => Message_Channel,
                                    Element => Message_Buffer);

      Message_Index  := Types.Message_Index'First;
      Message_Buffer := Types.Null_Data;
   end Flush;

   -------------------------------------------------------------------------

   procedure Write_Character (Item : Character)
   is
   begin
      if Item /= ASCII.NUL and then Item /= ASCII.CR then
         Message_Buffer.Message (Message_Index) := Item;

         if Message_Index = Types.Message_Index'Last or else Item = ASCII.LF
         then
            Flush;
         else
            Message_Index := Message_Index + 1;
         end if;
      end if;
   end Write_Character;
begin
   Stream.Writer_Instance.Initialize (Channel => Message_Channel,
                                      Epoch   => 1);
end Debuglog.Sink;
