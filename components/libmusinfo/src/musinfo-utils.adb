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

package body Musinfo.Utils
is

   -------------------------------------------------------------------------

   function Names_Match
     (N1 : Name_Type;
      N2 : String)
      return Boolean
   is
      Res : Boolean := True;
   begin
      if N1.Length /= N2'Length then
         Res := False;
      else
         Check_Characters :
         for I in 1 .. N2'Length loop
            if N1.Data (I) /= N2 (N2'First + (I - 1)) then
               Res := False;
               exit Check_Characters;
            end if;
         end loop Check_Characters;
      end if;

      return Res;
   end Names_Match;

   -------------------------------------------------------------------------

   function Memory_By_Hash
     (Sinfo : Subject_Info_Type;
      Hash  : Hash_Type)
      return Memregion_Type
   is
      M : Memregion_Type := Null_Memregion;
   begin
      Search :
      for I in 1 .. Sinfo.Memregion_Count loop
         if Sinfo.Memregions (I).Hash = Hash then
            M := Sinfo.Memregions (I);
            exit Search;
         end if;
      end loop Search;

      return M;
   end Memory_By_Hash;

   -------------------------------------------------------------------------

   function Memory_By_Name
     (Sinfo : Subject_Info_Type;
      Name  : String)
      return Memregion_Type
   is
      M : Memregion_Type := Null_Memregion;
   begin
      Search :
      for I in 1 .. Sinfo.Resource_Count loop
         if Names_Match
           (N1 => Sinfo.Resources (I).Name,
            N2 => Name)
         then
            declare
               Idx : constant Resource_Count_Type
                 := Sinfo.Resources (I).Memregion_Idx;
            begin
               if Idx > 0 and then Idx <= Sinfo.Memregion_Count then
                  M := Sinfo.Memregions (Idx);
                  exit Search;
               end if;
            end;
         end if;
      end loop Search;

      return M;
   end Memory_By_Name;

end Musinfo.Utils;
