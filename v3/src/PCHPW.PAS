Unit PchPW;
{$I PCHSYM.PAS}
{$O+,F+,I-}
Interface
  Uses Objects, StrObj, Drivers, Views, Dialogs;

  Const
    Chiffre= $7f;

  Function CheckPassword(Txt: String; Info: Pointer; Password: String): Boolean;
  Procedure SetPassword(P: String);
  Procedure GetPassword(Var P: String);
  Procedure ChangeUserPassword;

Implementation
  Uses
    StrUtl, DosTools, MsgBox, Fields, App, PchOpt, PchGlb, PchMsg, PchCmds,
    PchFunc;

  Type
    PPWInputLine= ^TPWInputLine;
    TPWInputLine= Object(TInputLine)
      Procedure Draw; virtual;
    End;

  Procedure TPWInputLine.Draw;
  Var
    L: Byte;
    S: String;
  Begin
    If Data=Nil Then L:=0 Else L:=Length(Data^);
    S[0]:=Char(Size.X);
    FillChar(S[1], Size.X, 32);
    FillChar(S[2], L-FirstPos, 254);
    WriteStr(0, 0, S, $02);
    SetCursor(CurPos-FirstPos+1, 0);
  End;

  Function EnterPassword(Txt: String; Var Password: String): Word;
  Var
    R: TRect;
    Dlg: PDialog;
    Control: PView;
    Cmd, I: Word;
  Begin
    I:=(Length(Txt) Div 2)+3;
    If I<15 Then I:=15;
    R.Assign(40-I, 6, 40+I, 14);
    Dlg:=New(PDialog, Init(R, GetMsg(sPassword)));
    With Dlg^ Do
    Begin
      R.Assign(4, 3, I*2-4, 4);
      Control:=New(PPWInputLine, Init(R, 15));
      Insert(Control);
      R.Assign(2, 2, Length(Txt)+3, 3);
      Insert(New(PLabel, Init(R, Txt, Control)));
      R.Assign(I-13, 5, I-2, 7);
      Insert(New(PButton, Init(R, GetMsg(sOK), cmOK, bfDefault)));
      R.Assign(I+2, 5, I+13, 7);
      Insert(New(PButton, Init(R, GetMsg(sCancel), cmCancel, bfNormal)));
      Dlg^.SelectNext(False);
    End;
    Cmd:=DeskTop^.ExecView(Application^.ValidView(Dlg));
    If Cmd<>cmCancel Then Dlg^.GetData(Password);
    Dispose(Dlg, Done);
    EnterPassword:=Cmd;
  End;

  Function CheckPassword(Txt: String; Info: Pointer; Password: String): Boolean;
  Var L, S: String;
  Begin
    If Password<>'' Then
    Begin
      FormatStr(L, Txt, Info);
      S:='';
      If (EnterPassword(L, S)=cmOk) And (S<>Password) Then
        MessageBox(GetMsg(sAccessDenied), nil, mfInformation+mfOkButton);
      CheckPassword:=S=Password;
    End Else
      CheckPassword:=True;
  End;

  Procedure ReadPassword(Var P: String);
  Var
    F: File;
    PWTable: Word;
    I: Byte;
  Begin
    Assign(F, PchPath+'PCHPW.SYS');
    Reset(F, 1);
    Seek(F, 18);
    BlockRead(F, PWTable, 2);
    Seek(F, PWTable);
    BlockRead(F, P[0], 1);
    BlockRead(F, P[1], Length(P));
    Close(F);
    For I:=1 To Length(P) Do P[I]:=Char(Byte(P[I]) Xor Chiffre);
  End;

  Procedure WritePassword(P: String);
  Var
    F: File;
    PWTable: Word;
    I: Byte;
  Begin
    Assign(F, PchPath+'PCHPW.SYS');
    Reset(F, 1);
    Seek(F, 18);
    BlockRead(F, PWTable, 2);
    Seek(F, PWTable);
    For I:=1 To Length(P) Do P[I]:=Char(Byte(P[I]) Xor Chiffre);
    BlockWrite(F, P[0], Length(P)+1);
    Close(F);
  End;

  Procedure SetPassword(P: String);
  Begin
    WritePassword(P);
  End;

  Procedure GetPassword(Var P: String);
  Begin
    ReadPassword(P);
  End;

  Procedure ChangeUserPassword;
  Var P, PTest: String;
  Begin
    GetPassword(P);
    If CheckPassword(GetMsg(sEnterOldPassword), nil, P) Then
    Begin
      If (EnterPassword(GetMsg(sEnterNewPassword1), P)=cmOk) And
         (EnterPassword(GetMsg(sEnterNewPassword2), PTest)=cmOk) Then
      Begin
        If P=PTest Then
        Begin
          SetPassword(P);
          MessageBox(GetMsg(sPasswordChanged), nil, mfInformation+mfOkButton);
        End Else
          MessageBox(GetMsg(sWrongPassword), nil, mfWarning+mfOKButton);
      End;
    End;
  End;

End.