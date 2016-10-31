--
--  Copyright (C) 2016  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2016  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

with Interfaces;

package body Musinfo.Instance
with
   Refined_State => (State => Object)
is

   use type Interfaces.Unsigned_64;

   -------------------------------------------------------------------------

   --  TODO: Make expression function in private spec.
   --        (did not compile with SPARK GPL 2016)
   function Belongs_To
     (Iter : Musinfo.Utils.Memory_Iterator_Type)
      return Boolean
   with
      Refined_Post => Belongs_To'Result = Utils.Belongs_To
         (Container => Object,
          Iter      => Iter)
   is
   begin
      return Utils.Belongs_To (Container => Object,
                               Iter      => Iter);
   end Belongs_To;

   -------------------------------------------------------------------------

   function Is_Valid return Boolean
   with
      Refined_Post => Is_Valid'Result = Utils.Is_Valid (Sinfo => Object)
   is
   begin
      return Utils.Is_Valid (Sinfo => Object);
   end Is_Valid;

   -------------------------------------------------------------------------

   function Memory_By_Hash
     (Hash    : Hash_Type;
      Content : Content_Type)
      return Memregion_Type
   with
      Refined_Global => (Input => Object)
   is
   begin
      return Utils.Memory_By_Hash (Sinfo   => Object,
                                   Hash    => Hash,
                                   Content => Content);
   end Memory_By_Hash;

   -------------------------------------------------------------------------

   function Memory_By_Name (Name : String) return Memregion_Type
   with
      Refined_Global => (Input => Object)
   is
   begin
      return Utils.Memory_By_Name (Sinfo => Object,
                                   Name  => Name);
   end Memory_By_Name;

   -------------------------------------------------------------------------

   procedure Next (Iter : in out Musinfo.Utils.Memory_Iterator_Type)
   is
   begin
      Utils.Next (Container => Object,
                  Iter      => Iter);
   end Next;

   -------------------------------------------------------------------------

   function TSC_Khz return TSC_Tick_Rate_Khz_Type
   with
      Refined_Global => (Input => Object)
   is
   begin
      return Utils.TSC_Khz (Sinfo => Object);
   end TSC_Khz;

   -------------------------------------------------------------------------

   function TSC_Schedule_End return Interfaces.Unsigned_64
   with
      Refined_Global => (Input => Object)
   is
   begin
      return Utils.TSC_Schedule_End (Sinfo => Object);
   end TSC_Schedule_End;

   -------------------------------------------------------------------------

   function TSC_Schedule_Start return Interfaces.Unsigned_64
   with
      Refined_Global => (Input => Object)
   is
   begin
      return Utils.TSC_Schedule_Start (Sinfo => Object);
   end TSC_Schedule_Start;

   -------------------------------------------------------------------------

   function Subject_Name return Name_Type
   with
      Refined_Global => (Input => Object)
   is
   begin
      return Utils.Subject_Name (Sinfo => Object);
   end Subject_Name;

end Musinfo.Instance;
