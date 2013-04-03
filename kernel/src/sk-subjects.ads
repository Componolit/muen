with Skp;

with SK.CPU;

--# inherit
--#    Skp.Subjects,
--#    SK.CPU;
package SK.Subjects
--# own
--#    Descriptors;
--# initializes
--#    Descriptors;
is

   --  Subject state.
   type State_Type is record
      Launched : Boolean;
      Regs     : CPU.Registers_Type;
   end record;

   --  Get state of subject with given ID.
   function Get_State (Id : Skp.Subject_Id_Type) return State_Type;
   --# global
   --#    Descriptors;

   --  Set state of subject identified by ID.
   procedure Set_State
     (Id    : Skp.Subject_Id_Type;
      State : State_Type);
   --# global
   --#    Descriptors;
   --# derives
   --#    Descriptors from *, Id, State;

end SK.Subjects;
