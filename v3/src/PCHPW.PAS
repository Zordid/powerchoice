Unit PchPW;
{$I PCHSYM.PAS}
{$O+,F+,I-}
Interface
  Uses Objects, StrObj, Drivers, Views, Dialogs;

  Const
    MaxUsers= 10;
    Chiffre= $7f3a;
    PK= 59;
    SK= 179;
    R= 3649;
    { 89, 41 }

  Type
    TUserData= Record
      Name, Password: String[20];
      PWNo, Access: Byte;
    End;

  Const
    UserStr= 'userlst';
    UserID: String[Length(UserStr)]= UserStr;
    UserCount: Byte= 0;
    UserList: Array[1..MaxUsers] Of TUserData=
      ((Name: ''; Password: ''; PWNo: 0; Access: 0),  (Name: ''; Password: ''; PWNo: 0; Access: 0),
       (Name: ''; Password: ''; PWNo: 0; Access: 0),  (Name: ''; Password: ''; PWNo: 0; Access: 0),
       (Name: ''; Password: ''; PWNo: 0; Access: 0),  (Name: ''; Password: ''; PWNo: 0; Access: 0),
       (Name: ''; Password: ''; PWNo: 0; Access: 0),  (Name: ''; Password: ''; PWNo: 0; Access: 0),
       (Name: ''; Password: ''; PWNo: 0; Access: 0),  (Name: ''; Password: ''; PWNo: 0; Access: 0));
    CodedMasterPassword: Array[0..30] Of Integer=
       (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

  Var
    UserNo: Byte;

  Procedure InitUserSystem;
  Function MasterPassword: String;
  Function CheckPassword(Txt: String; Info: Pointer; Password: String): Boolean;
  Procedure SetUserPassword(User: Byte; P: String);
  Procedure GetUserPassword(User: Byte; Var P: String);
  Procedure ChangeUserPassword;
  Procedure EditUserList;

Implementation
  Uses
    StrUtl, DosTools, MsgBox, Fields, App, PchOpt, PchGlb, PchMsg, PchCmds,
    PchFunc;

  Type
    TPasswords= Array[0..MaxUsers] Of String[20];
    PPWInputLine= ^TPWInputLine;
    TPWInputLine= Object(TKeyInputLine)
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

  Procedure ReadPasswords(Var P: TPasswords);
  Var
    F: File;
    PWTable, I: Word;
  Begin
    Assign(F, PchPath+'PCHPW.SYS');
    Reset(F, 1);
    Seek(F, 18);
    BlockRead(F, PWTable, 2);
    Seek(F, PWTable);
    For I:=0 To MaxUsers Do
    Begin
      BlockRead(F, P[I, 0], 1);
      BlockRead(F, P[I, 1], Byte(P[I, 0]));
    End;
    Close(F);
  End;

  Procedure WritePasswords(Var P: TPasswords);
  Var
    F: File;
    PWTable, I: Word;
  Begin
    Assign(F, PchPath+'PCHPW.SYS');
    Reset(F, 1);
    Seek(F, 18);
    BlockRead(F, PWTable, 2);
    Seek(F, PWTable);
    For I:=0 To MaxUsers Do
      BlockWrite(F, P[I, 0], Length(P[I])+1);
    Close(F);
  End;

  Procedure XorRol(Var A: Word); assembler;
  Asm
    Les Bx, A
    Mov Ax, Es:[Bx]
    Xor Ax, Chiffre
    Mov Cl, 2
    Rol Ax, Cl
    Mov Es:[Bx], Ax
  End;

  Procedure DeXorRol(Var A: Word); assembler;
  Asm
    Les Bx, A
    Mov Ax, Es:[Bx]
    Mov Cl, 2
    Ror Ax, Cl
    Xor Ax, Chiffre
    Mov Es:[Bx], Ax
  End;

  Function RSACrypt(Value, Key: Integer; R: LongInt): LongInt;
  Var
    D1, C, M: LongInt;
  Begin
    C:=Value;
    D1:=Key;
    M:=1;
    While D1>0 Do
    Begin
      If (D1 And 1)=1 Then
        M:=(M*C) Mod R;
      C:=SQR(C) Mod R;
      D1:=D1 Div 2;
    End;
    RSACrypt:=M;
  End;

  Procedure InitUserSystem;
  Type
    WordArray= Array[1..SizeOf(UserList) Div 2] Of Word;
  Var
    I: Integer;
    Dlg: PDialog;
  Begin
    For I:=1 To SizeOf(UserList) Div 2 Do
      DeXorRol(WordArray(UserList)[I]);
    If LowLevel^.Password=0 Then Exit;
    For I:=1 To UserCount Do
      If UserList[I].PWNo=LowLevel^.Password Then
      Begin
        UserNo:=I;
        If UserList[I].Access And 4=4 Then
        Begin
          Dlg:=PDialog(GetRez('LockedDialog'));
          DeskTop^.Insert(Dlg);
          Repeat Until False;
        End;
        If UserList[I].Access And 1<>1 Then
          Application^.DisableCommands([cmDos, cmDosShell]);
        Exit;
      End;
    Error(3);
  End;

  Function MasterPassword: String;
  Var
    M: String[30];
    I: Integer;
  Begin
    M[0]:=Char(CodedMasterPassword[0]);
    For I:=1 To Length(M) Do
      M[I]:=Char(RSACrypt(CodedMasterPassword[I], SK, R));
    MasterPassword:=M;
  End;

  Procedure SetUserPassword(User: Byte; P: String);
  Var
    Passwords: TPasswords;
    I: Byte;
  Begin
    ReadPasswords(Passwords);
    Passwords[User, 0]:=P[0];
    For I:=1 To Length(P) Do
      Passwords[User, I]:=Char(Byte(P[I]) Xor Hi(Chiffre));
    WritePasswords(Passwords);
    {
    If User=0 Then
    Begin
      S.Done;
      CodedMasterPassword[0]:=Integer(P[0]);
      For I:=1 To Length(P) Do
        CodedMasterPassword[I]:=RSACrypt(Integer(P[I]), PK, R);
      If MasterPassword<>P Then
        MessageBox('RSA stimmt nicht !', nil, mfInformation+mfOkButton);
      S.Init(EXEName, stOpen, 1024);
      S.Seek(S.GetSize-SizeOf(LongInt));
      S.Read(O, SizeOf(O));
      S.Seek(O+1+SizeOf(UserList));
      S.Write(CodedMasterPassword, SizeOf(CodedMasterPassword));
    End;
    }
  End;

  Procedure GetUserPassword(User: Byte; Var P: String);
  Var
    Passwords: TPasswords;
    I: Byte;
  Begin
    ReadPasswords(Passwords);
    P:=Passwords[User];
    For I:=1 To Length(P) Do
      P[I]:=Char(Byte(P[I]) Xor Hi(Chiffre));
  End;

  Procedure ChangeUserPassword;
  Var P, PTest: String;
  Begin
    GetUserPassword(LowLevel^.Password, P);
    If CheckPassword(GetMsg(sEnterOldPassword), nil, P) Then
    Begin
      If (EnterPassword(GetMsg(sEnterNewPassword1), P)=cmOk) And
         (EnterPassword(GetMsg(sEnterNewPassword2), PTest)=cmOk) Then
      Begin
        If P=PTest Then
        Begin
          SetUserPassword(LowLevel^.Password, P);
          MessageBox(GetMsg(sPasswordChanged), nil, mfInformation+mfOkButton);
        End Else
          MessageBox(GetMsg(sWrongPassword), nil, mfWarning+mfOKButton);
      End;
    End;
  End;

  Procedure EditUserList;
  Begin
  End;

End.