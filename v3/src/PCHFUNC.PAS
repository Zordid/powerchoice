Unit PchFunc;
{$I PCHSYM.PAS}
{$F+,O+}
Interface

  Procedure About;
  Procedure Ascii;
  Procedure Calculator;
  Procedure Editmode;
  Procedure Dos;
  Procedure DosShell;
  Function ChangeDir: Word;
  Procedure PutMainMenu;
  Procedure ClearDeskTop;
  Procedure LoadDeskTop;
  Procedure StoreDeskTop;
  Procedure ResetComputer;
  Procedure Tetris;

Implementation
  Uses
    Crt, StrUtl, DosTools,
    Objects, Drivers, Views, Dialogs, App, MsgBox, StdDlg, AsciiTab, Calc,
    PchGlb, PchCmds, PchMsg, PchOpt, PchMenu, PchRun, PchDos,
    PchPW, PchTetris, PchReg;

  Procedure About;
  Var
    Dlg: PDialog;
    R: TRect;
    S, T: String[20];
    I: Byte;
  Begin
    Dlg:=PDialog(GetRez('AboutDialog'));
    If Dlg<>Nil Then
    Begin
      R.Assign(14, 7, 43, 8);
      Dlg^.Insert(New(PStaticText, Init(R, Reg.UserName)));
      R.Assign(14, 8, 43, 9);
      Dlg^.Insert(New(PStaticText, Init(R, Reg.UserCompany)));
      If Reg.SerialNo<>0 Then
      Begin
        Str(Lo(Reg.Date)+90:2, S);
        Str(Hi(Reg.Date), T);
        S:='AD'+S+T+'I';
        Str(Reg.SerialNo:8, T);
        S:=S+T;
        For I:=1 To Length(S) Do If S[I]=' ' Then S[I]:='0';
      End Else
        S:='! RAUBKOPIE !';
      R.Assign(14, 9, 43, 10);
      Dlg^.Insert(New(PStaticText, Init(R, S)));
      {$IFDEF DEBUG}
      R.Assign(26, 1, 43, 2);
      Dlg^.Insert(New(PStaticText, Init(R, 'DEBUGGING VERSION')));
      {$ENDIF}
      DeskTop^.ExecView(Dlg);
      Dispose(Dlg, Done);
    End;
  End;

  Procedure Ascii;
  Var P: PASCIIChart;
  Begin
    P:=New(PASCIIChart, Init);
    DeskTop^.Insert(Application^.ValidView(P));
  End;

  Procedure Calculator;
  Var P: PCalculator;
  Begin
    P:=New(PCalculator, Init);
    DeskTop^.Insert(Application^.ValidView(P));
  End;

  Procedure Editmode;
  Var Cmd: Word;
  Begin
    With Application^ Do
    Begin
      If Not Editing Then
      Begin
        MessageBox(GetMsg(sEditmodeOn), nil, mfInformation+mfOkButton);
        EnableCommands(EditCommands);
        DisableCommands([cmClearDesktop]);
        StoreDeskTop;
      End Else
      Begin
        If EditChanged Then
        Begin
          Cmd:=MessageBox(GetMsg(sEditmodeOffAsk), nil, mfInformation+mfYesNoCancel);
          If Cmd=cmYes Then
            StoreMenu(MainMenu, PchPath+MenuFileName)
          Else If Cmd=cmNo Then
          Begin
            LoadMenu(MainMenu, PchPath+MenuFileName);
            LoadDeskTop;
          End Else
            Exit;
          EditChanged:=False;
        End Else
          MessageBox(GetMsg(sEditmodeOff), nil, mfInformation+mfOkButton);
        EnableCommands([cmClearDeskTop]);
        DisableCommands(EditCommands);
      End;
      Editing:=Not Editing;
      Message(DeskTop, evBroadcast, cmModeChanged, nil);
    End;
  End;

  Procedure Dos;
  Begin
    If Editing Then Editmode;
    If Not Editing Then
    Begin
      ResetBatchFile;
      ClearPrompt;
      ClockGlb:=(DosOptions.DosOpt And 1)=1;
      ScrSaverGlb:=(DosOptions.DosOpt And 2)=2;
      WaitforKeyGlb:=False;
      ToPrintGlb:=NewStr(GetMsg(sExitText));
      RememberOldPath(False);
      If DosOptions.DosOpt And 4=4 Then ChDir('C:\');
      QuitToDos;
    End;
  End;

  Procedure DosShell;
  Var P: PDosShell;
  Begin
    P:=Message(DeskTop, evBroadcast, cmSearchDosShell, Nil);
    If P=Nil Then
    Begin
      P:=New(PDosShell, Init);
      DeskTop^.Insert(Application^.ValidView(P));
    End Else
      P^.Select;
  End;

  Function ChangeDir: Word;
  Var
    D: PChDirDialog;
    C: Word;
  Begin
    D:=New(PChDirDialog, Init(cdNormal, 201));
    C:=DeskTop^.ExecView(D);
    Dispose(D, Done);
    If C<>cmCancel Then Message(DeskTop, evBroadcast, cmRedrawPrompt, nil);
    ChangeDir:=C;
  End;

  Procedure PutMainMenu;
  Var
    D: PGroupWindow;
  Begin
    New(D, Init(MainMenu, 1));
    D^.Options:=D^.Options Or ofCenterX;
    DeskTop^.Insert(D);
  End;

  Procedure AllClearDeskTop;
  Var R: TRect;
    Procedure CloseView(P: PView); far;
    Begin
      Message(P, evCommand, cmClose, nil);
    End;
  Begin
    DeskTop^.ForEach(@CloseView);
    DeskTop^.GetBounds(R);
    Dispose(DeskTop, Done);
    DeskTop:=New(PDeskTop, Init(R));
    Application^.Insert(DeskTop);
    DeskTop^.DrawView;
  End;

  Procedure ClearDeskTop;
  Begin
    AllClearDeskTop;
    PutMainMenu;
  End;

  Const
    DskID: LongInt= $1A45;

  Procedure LoadDesktop;
  Var
    ID: LongInt;
    P: PView;
    S: TBufStream;
    M: TPoint;
    Mode: Word;
  Begin
    AllClearDeskTop;
    S.Init(PchPath+DeskFileName, stOpen, 1024);
    If S.Status=stOk Then
    Begin
      S.Read(ID, SizeOf(ID));
      If ID=DskID Then
      Begin
        { Optionen laden }
        S.Read(DosOptions, SizeOf(DosOptions));
        S.Read(SysOptions, SizeOf(SysOptions));
        S.Read(Mode, SizeOf(Mode));
        If (Mode<>ScreenMode) Then
          Application^.SetScreenMode(Mode);
        { Maus }
        S.Read(DoubleDelay, SizeOf(DoubleDelay));
        S.Read(MouseReverse, SizeOf(MouseReverse));
        S.Read(MouseWhere, SizeOf(MouseWhere));
        S.Read(M, SizeOf(M));
        Asm
          mov ax, 4
          mov cx, M.X
          mov dx, M.Y
          int $33
        End;
        { SavePath }
        S.Read(SavePathGlb, SizeOf(SavePathGlb));
        OldPathGlb:=S.ReadStr;
        { Views laden }
        Repeat
          P := PView(S.Get);
          Desktop^.InsertBefore(Application^.ValidView(P), Desktop^.Last)
        Until P = Nil;
        If S.Status<>stOk Then
        Begin
          MessageBox(GetMsg(sDesktopReadError), nil, mfError+mfOkButton);
          ClearDeskTop;
        End;
        S.Done;
        Exit;
      End Else
        MessageBox(GetMsg(sWrongDesktopFile), nil, mfError+mfOkButton);
    End;
    PutMainMenu;
    S.Done;
  End;

  Procedure StoreDesktop;
  Var
    S: TBufStream;
    Palette: String;
    M: TPoint;
    Procedure WriteView(P: PView); far;
    Begin
      If P <> Desktop^.Last Then S.Put(P);
    End;
  Begin
    S.Init(PchPath+DeskFileName, stCreate, 1024);
    S.Write(DskID, SizeOf(DskID));
    { Optionen speichern }
    S.Write(DosOptions, SizeOf(DosOptions));
    S.Write(SysOptions, SizeOf(SysOptions));
    S.Write(ScreenMode, SizeOf(ScreenMode));
    { Maus }
    S.Write(DoubleDelay, SizeOf(DoubleDelay));
    S.Write(MouseReverse, SizeOf(MouseReverse));
    S.Write(MouseWhere, SizeOf(MouseWhere));
    Asm
      mov ax, 3
      int $33
      mov M.X, cx
      mov M.Y, dx
    End;
    S.Write(M, SizeOf(M));
    { Savepath }
    S.Write(SavePathGlb, SizeOf(SavePathGlb));
    S.WriteStr(OldPathGlb);
    { Views speichern }
    Desktop^.ForEach(@WriteView);
    S.Put(nil);
    S.Done;
    If S.Status<>stOk Then
    Begin
      MessageBox(GetMsg(sDesktopWriteError), nil, mfError+mfOkButton);
      FileDelete(DeskFileName);
    End;
  End;

  Procedure ResetComputer;
  Begin
    Asm
      mov ax, $0040
      mov ds, ax
      mov ax, $1234
      mov [$0072], ax
    End;
    Inline($EA/$00/$00/$FF/$FF);
  End;

  Procedure Tetris;
  Var TetrisDlg: PTetris;
  Begin
    TetrisDlg:=Message(DeskTop, evBroadcast, cmSearchTetris, nil);
    If TetrisDlg=nil Then
    Begin
      TetrisDlg:=New(PTetris, Init);
      DeskTop^.Insert(TetrisDlg);
    End Else
      TetrisDlg^.Select;
  End;

End.