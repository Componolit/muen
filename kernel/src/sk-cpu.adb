with System.Machine_Code;

with SK.Console;

package body SK.CPU
is

   RFLAGS_CF_FLAG : constant := 0;

   -------------------------------------------------------------------------

   procedure CPUID
     (EAX : in out SK.Word32;
      EBX :    out SK.Word32;
      ECX : in out SK.Word32;
      EDX :    out SK.Word32)
   is
      --# hide CPUID;
   begin
      System.Machine_Code.Asm
        (Template => "cpuid",
         Inputs   => (SK.Word32'Asm_Input ("a", EAX),
                      SK.Word32'Asm_Input ("c", ECX)),
         Outputs  => (SK.Word32'Asm_Output ("=a", EAX),
                      SK.Word32'Asm_Output ("=b", EBX),
                      SK.Word32'Asm_Output ("=c", ECX),
                      SK.Word32'Asm_Output ("=d", EDX)),
         Volatile => True);
   end CPUID;

   -------------------------------------------------------------------------

   function Get_CR0 return SK.Word64
   is
      --# hide Get_CR0;

      Result : SK.Word64;
   begin
      System.Machine_Code.Asm
        (Template => "movq %%cr0, %0",
         Outputs  => (SK.Word64'Asm_Output ("=r", Result)),
         Volatile => True);
      return Result;
   end Get_CR0;

   -------------------------------------------------------------------------

   function Get_CR4 return SK.Word64
   is
      --# hide Get_CR4;

      Result : SK.Word64;
   begin
      System.Machine_Code.Asm
        (Template => "movq %%cr4, %0",
         Outputs  => (SK.Word64'Asm_Output ("=r", Result)),
         Volatile => True);
      return Result;
   end Get_CR4;

   -------------------------------------------------------------------------

   procedure Get_MSR
     (Register :     SK.Word32;
      Low      : out SK.Word32;
      High     : out SK.Word32)
   is
      --# hide Get_MSR;
   begin
      System.Machine_Code.Asm
        (Template => "rdmsr",
         Inputs   => (SK.Word32'Asm_Input ("c", Register)),
         Outputs  => (SK.Word32'Asm_Output ("=d", High),
                      SK.Word32'Asm_Output ("=a", Low)),
         Volatile => True);
   end Get_MSR;

   -------------------------------------------------------------------------

   function Get_MSR64 (Register : SK.Word32) return SK.Word64
   is
      Low_Dword, High_Dword : SK.Word32;
   begin
      Get_MSR (Register => Register,
               Low      => Low_Dword,
               High     => High_Dword);
      return 2**31 * SK.Word64 (High_Dword) + SK.Word64 (Low_Dword);
   end Get_MSR64;

   -------------------------------------------------------------------------

   function Get_RFLAGS return SK.Word64
   is
      --# hide Get_RFLAGS;

      Result : SK.Word64;
   begin
      System.Machine_Code.Asm
        (Template => "pushf; pop %0",
         Outputs  => (SK.Word64'Asm_Output ("=m", Result)),
         Volatile => True,
         Clobber  => "memory");
      return Result;
   end Get_RFLAGS;

   -------------------------------------------------------------------------

   procedure Hlt
   is
      --# hide Hlt;
   begin
      System.Machine_Code.Asm
        (Template => "hlt",
         Volatile => True);
   end Hlt;

   -------------------------------------------------------------------------

   procedure Panic
   is
      --# hide Panic;
   begin
      System.Machine_Code.Asm
        (Template => "ud2",
         Volatile => True);
   end Panic;

   -------------------------------------------------------------------------

   procedure Set_CR4 (Value : SK.Word64)
   is
      --# hide Set_CR4;
   begin
      System.Machine_Code.Asm
        (Template => "movq %0, %%cr4",
         Inputs   => (SK.Word64'Asm_Input ("r", Value)),
         Volatile => True);
   end Set_CR4;

   -------------------------------------------------------------------------

   procedure VMXON
     (Region  :     SK.Word64;
      Success : out Boolean)
   is
      --# hide VMXON;
   begin
      Set_CR4 (Value => SK.Bit_Set
               (Value => Get_CR4,
                Pos   => CR4_VMXE_FLAG));

      System.Machine_Code.Asm
        (Template => "vmxon (%0)",
         Inputs   => (Word64'Asm_Input ("r", Region)),
         Volatile => True);

      Success := SK.Bit_Test
        (Value => Get_RFLAGS,
         Pos   => RFLAGS_CF_FLAG);
   end VMXON;

end SK.CPU;
