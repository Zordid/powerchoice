Unit PchMacro;
{$I PCHSYM.PAS}
{$O+,F+}
Interface
  Uses Objects;

  Function PchExec(PchCmds, DosCmds: PCollection): Boolean;

Implementation

  Function PchExec(PchCmds, DosCmds: PCollection): Boolean;
  Begin
    PchExec:=True;
  End;

End.