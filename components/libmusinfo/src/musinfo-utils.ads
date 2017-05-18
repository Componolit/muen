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

package Musinfo.Utils
is

   --  Convert given string to name.
   function To_Name (Str : String) return Name_Type
   with
      Pre => Str'Length <= Name_Index_Type'Last
                and Str'First + Str'Length < Positive'Last;

   --  Concatenate given names.
   function Concat (L, R : Name_Type) return Name_Type
   with
      Pre => L.Length + R.Length <= Name_Size_Type'Last;

   --  Return True if Left and Right name data is identical.
   function Name_Data_Equal (Left, Right : Name_Data_Type) return Boolean
   with
      Post => Name_Data_Equal'Result =
                 (for all I in Left'Range => Left (I) = Right (I));

   --  Compare given name types for equality (the default implementation leads
   --  to implicit loops in the expanded generated code).
   function Names_Equal (Left, Right : Name_Type) return Boolean
   with
      Post => Names_Equal'Result = (Left.Length = Right.Length
                                    and Left.Padding = Right.Padding
                                    and Name_Data_Equal
                                       (Left  => Left.Data,
                                        Right => Right.Data));

   --  Compare Count characters of names N1 and N2. Return True if characters
   --  1 .. Count are equal.
   function Names_Match
     (N1, N2 : Name_Type;
      Count  : Name_Size_Type)
      return Boolean;

   --  Returns True if the sinfo data is valid.
   function Is_Valid (Sinfo : Subject_Info_Type) return Boolean;

   --  Return subject name stored in given subject info data.
   function Subject_Name (Sinfo : Subject_Info_Type) return Name_Type
   with
      Pre => Is_Valid (Sinfo => Sinfo);

   --  Return TSC tick rate in kHz.
   function TSC_Khz (Sinfo : Subject_Info_Type) return TSC_Tick_Rate_Khz_Type
   with
      Pre => Is_Valid (Sinfo => Sinfo);

   --  Return memory region with specified name. If no such memory region
   --  exists, Null_Memregion is returned.
   function Memory_By_Name
     (Sinfo : Subject_Info_Type;
      Name  : Name_Type)
      return Memregion_Type
   with
      Pre => Is_Valid (Sinfo);

   --  Return memory region with specified hash and content type. If no such
   --  memory region exists, Null_Memregion is returned. If multiple regions
   --  with the same hash/content exist, the first occurrence is returned.
   function Memory_By_Hash
     (Sinfo   : Subject_Info_Type;
      Hash    : Hash_Type;
      Content : Content_Type)
      return Memregion_Type
   with
      Pre => Is_Valid (Sinfo => Sinfo);

   --  Memory resource iterator.
   type Memory_Iterator_Type is private;

   --  Returns True if the given iterator belongs to the specified subject info
   --  data.
   function Belongs_To
     (Container : Subject_Info_Type;
      Iter      : Memory_Iterator_Type)
      return Boolean
   with
      Ghost;

   --  Create memory region iterator for given container. If the sinfo data
   --  contains memory resources, the iterator points to the first region
   --  available. Otherwise it points to No_Resource.
   function Create_Memory_Iterator
     (Container : Subject_Info_Type)
      return Memory_Iterator_Type
   with
      Pre  => Is_Valid (Sinfo => Container),
      Post => Belongs_To (Container => Container,
                          Iter      => Create_Memory_Iterator'Result);

   --  Memory region with associated name.
   type Named_Memregion_Type is record
      Name : Name_Type;
      Data : Memregion_Type;
   end record;

   Null_Named_Memregion : constant Named_Memregion_Type;

   --  Returns True if the iterator points to a valid resource in the
   --  container.
   function Has_Element
     (Container : Subject_Info_Type;
      Iter      : Memory_Iterator_Type)
      return Boolean
   with
      Pre => Is_Valid (Sinfo => Container)
             and Belongs_To (Container => Container,
                             Iter      => Iter);

   --  Return element at current iterator position. If the iterator points to
   --  no valid element, Null_Named_Memregion is returned.
   function Element
     (Container : Subject_Info_Type;
      Iter      : Memory_Iterator_Type)
      return Named_Memregion_Type
   with
      Pre => Is_Valid (Sinfo => Container)
             and Belongs_To (Container => Container,
                             Iter      => Iter);

   --  Advance memory iterator to next position (if available).
   procedure Next
     (Container :        Subject_Info_Type;
      Iter      : in out Memory_Iterator_Type)
   with
      Depends => (Iter =>+ Container),
      Pre     => Is_Valid (Sinfo => Container)
                 and Belongs_To (Container => Container,
                                 Iter      => Iter),
      Post    => Belongs_To (Container => Container,
                             Iter      => Iter);

private

   function Subject_Name (Sinfo : Subject_Info_Type) return Name_Type
   is (Sinfo.Name);

   function TSC_Khz (Sinfo : Subject_Info_Type) return TSC_Tick_Rate_Khz_Type
   is (Sinfo.TSC_Khz);

   type Memory_Iterator_Type is record
      Resource_Idx : Resource_Count_Type := No_Resource;
      Owner        : Name_Type           := Null_Name;
   end record;

   function Belongs_To
     (Container : Subject_Info_Type;
      Iter      : Memory_Iterator_Type)
      return Boolean
   is (Names_Equal (Left  => Iter.Owner,
                    Right => Container.Name));

   function Has_Element
     (Container : Subject_Info_Type;
      Iter      : Memory_Iterator_Type)
      return Boolean
   is (Iter.Resource_Idx /= No_Resource);

   Null_Named_Memregion : constant Named_Memregion_Type
     := (Name => Null_Name,
         Data => Null_Memregion);

end Musinfo.Utils;
