Unit PchOpt;
{$I PCHSYM.PAS}
{$O+,F+}
Interface
  Uses
    Objects, Drivers, Views, Dialogs;

  Procedure SetSysOptions;
  Procedure SetDosOptions;

Implementation
  Uses
    App, PchCmds, PchHelp, PchGlb;

  Procedure SetSysOptions;
  Var
    Dlg: PDialog;
    Data: TSysOptions;
    W: Word;
  Begin
    Dlg:=PDialog(GetRez('SysOptionsDialog'));
    If Dlg<>nil Then
    Begin
      Dlg^.HelpCtx:=hcSysOptionsDialog;
      Data:=SysOptions;
      Data.DisplayLines:=Word((ScreenMode And smFont8x8)=smFont8x8);
      Dlg^.SetData(Data);
      If DeskTop^.ExecView(Dlg)<>cmCancel Then
      Begin
        Dlg^.GetData(Data);
        SysOptions:=Data;
        W:=Data.DisplayLines;
        If W=1 Then W:=smFont8x8;
        Inc(W, ScreenMode And (Not smFont8x8));
        If W<>ScreenMode Then Application^.SetScreenMode(W);
      End;
      Dispose(Dlg);
    End;
  End;

  Procedure SetDosOptions;
  Var
    Dlg: PDialog;
    Data: TDosOptions;
  Begin
    Dlg:=PDialog(GetRez('DosOptionsDialog'));
    If Dlg<>Nil Then
    Begin
      Dlg^.HelpCtx:=hcDosOptionsDialog;
      Data:=DosOptions;
      Dlg^.SetData(Data);
      If DeskTop^.ExecView(Dlg)<>cmCancel Then Dlg^.GetData(DosOptions);
      Dispose(Dlg, Done);
    End;
    Message(DeskTop, evBroadcast, cmRedrawPrompt, nil);
    Message(DeskTop, evBroadcast, cmRedrawMem, nil);
  End;

End.