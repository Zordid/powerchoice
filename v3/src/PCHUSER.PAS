Program PchUser;
Uses Dos;
Type
  PLowLevel= ^TLowLevel;
  TLowLevel= Record
    IRET: Byte;
    ID: String[6];
    Password,
    Clock: Byte;
    ScrSaver,
    WaitForKey,
    Booted,
    EnableEdit,
    EnableDos: Boolean;
  End;
Var
  LowLevel: PLowLevel;

Begin
  GetIntVec($60, Pointer(LowLevel));
  If LowLevel^.ID<>'PCH300' Then
  Begin
    Writeln('PCHUSER: Low level driver not installed or not found.');
    Halt;
  End;
  Halt(LowLevel^.Password);
End.