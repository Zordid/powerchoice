{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O-,R-,S+,V+,X+}
Program Install;
Uses
  Dos, Crt, DosTools, StrObj, StrgUtl,
  Objects, Drivers, Views, Dialogs, Menus, App, MsgBox;

Const
  cmInstall= 100;
  cmDeInstall= 101;
  cmConfigure= 102;

Type
  TInstApp= Object(TApplication)
    Menu: PDialog;
    Constructor Init;
    Procedure InitMenu;
    Procedure InitStatusLine; virtual;
    Procedure HandleEvent(Var Event: TEvent); virtual;
    Procedure Install;
  End;

Const
  MBox: PDialog= nil;

Procedure HideMsgBox;
Begin
  DeskTop^.Delete(MBox);
  Dispose(MBox);
  MBox:=nil;
End;

Procedure ShowMsgBox(T, S: String);
Var R: TRect;
Begin
  If MBox<>nil Then HideMsgBox;
  R.Assign(20, 8, 60, 15);
  New(MBox, Init(R, T));
  MBox^.Flags:=MBox^.Flags-wfClose;
  R.Assign(3, 2, 36, 4);
  MBox^.Insert(New(PStaticText, Init(R, S)));
  DeskTop^.Insert(MBox);
End;

Procedure TInstApp.InitMenu;
Var
  R: TRect;
  Dlg: PDialog;
  Control: PView;
Begin
  R.Assign(2,2,77,19);
  New(Dlg, Init(R, 'Power-Choice 3.00 Installation'));
  R.Assign(13,2,63,3);
  Dlg^.Insert(New(PStaticText, Init(R, 'Willkommen zum Power-Choice Installationsprogramm!')));
  R.Assign(3,4,72,5);
  Dlg^.Insert(New(PStaticText, Init(R, 'Mit diesem Programm können  sie das Menüsystem  auf ihrer  Festplatte')));
  R.Assign(3,5,72,6);
  Dlg^.Insert(New(PStaticText, Init(R, 'problemlos installieren, eine bestehende Konfiguration ändern oder es')));
  R.Assign(3,6,39,7);
  Dlg^.Insert(New(PStaticText, Init(R, 'wieder von der Festplatte entfernen.')));
  R.Assign(3,7,72,8);
  Dlg^.Insert(New(PStaticText, Init(R, 'Dazu müssen sie nur einen der unteren "Knöpfe" mit der Maus anklicken')));
  R.Assign(3,8,65,9);
  Dlg^.Insert(New(PStaticText, Init(R, 'oder mit der Tabulatortaste anwählen und mit Enter bestätigen.')));
  R.Assign(8,10,37,12);
  Dlg^.Insert(New(PButton, Init(R, 'Programm neu ~i~nstallieren', cmInstall, bfNormal)));
  R.Assign(8,13,37,15);
  Dlg^.Insert(New(PButton, Init(R, '~K~onfiguration ändern', cmConfigure, bfNormal)));
  R.Assign(40,10,68,12);
  Dlg^.Insert(New(PButton, Init(R, 'Programm ~d~einstallieren', cmDeInstall, bfNormal)));
  R.Assign(40,13,68,15);
  Dlg^.Insert(New(PButton, Init(R, '~E~nde der Installation', cmQuit, bfNormal)));
  Dlg^.SelectNext(False);
  Menu:=Dlg;
  DeskTop^.Insert(Menu);
End;

Constructor TInstApp.Init;
Type
  LL= Record
    IRET: Byte;
    Code: String[6];
  End;
Var
  Int: Pointer;
Begin
  TApplication.Init;
  GetIntVec($60, Int);
  {LL(Int^).Code='PCH300';}
  If False Then
    DisableCommands([cmInstall])
  Else
    DisableCommands([cmDeInstall, cmConfigure]);
  InitMenu;
End;

Procedure TInstApp.InitStatusLine;
Var R: TRect;
Begin
  GetExtent(R);
  R.A.Y:=R.B.Y-1;
  StatusLine:=New(PStatusLine, Init(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~Alt-X~ Abbruch', kbAltX, cmQuit,
      nil),
    nil)
  ));
End;

Procedure TInstApp.HandleEvent(Var Event: TEvent);
Begin
  TApplication.HandleEvent(Event);
  If (Event.What=evCommand) Then
  Begin
    If Event.Command In [cmInstall..cmConfigure] Then
      Desktop^.Delete(Menu);
    Case Event.Command Of
      cmInstall: Install;
      Else Exit;
    End;
    If Event.Command In [cmInstall..cmConfigure] Then
      Desktop^.Insert(Menu);
    ClearEvent(Event);
  End;
End;

Procedure TInstApp.Install;
Const
  Title= 'Power-Choice Version 3.00';
Var
  S, FromPath, ToPath: String;
  FileList: TFileList;
  Event: TEvent;
  I: Integer;
  Error: Boolean;
  F: PCollection;

  Procedure CopyFile(Source, Dest: String);
  Const
    BufSize= 16*1024;
  Var
    Buffer: Pointer;
    F, T: File;
    NumRead, NumWritten: Word;
    FSize, Total: LongInt;
  Begin
    Error:=False;
    GetMem(Buffer, BufSize);
    Assign(F, Source);
    Reset(F, 1);
    Assign(T, Dest);
    Rewrite(T, 1);
    FSize:=FileSize(F);
    Total:=0;
    Repeat
      BlockRead(F, Buffer^, BufSize, NumRead);
      BlockWrite(T, Buffer^, NumRead, NumWritten);
      Inc(Total, NumWritten);
    Until (NumRead=0) Or (NumRead<>NumWritten);
    Close(F);
    Close(T);
    FreeMem(Buffer, BufSize);
    Error:=(IOResult<>0) Or (Total<>FSize);
  End;

  Procedure ReadFile(N: String; Var C: PCollection);
  Var
    F: Text;
    S: String;
  Begin
    Assign(F, N);
    Reset(F);
    New(C, Init(5, 5));
    While Not EoF(F) Do
    Begin
      Readln(F, S);
      C^.Insert(New(PStr, Init(S)));
    End;
    Close(F);
    Error:=IOResult<>0;
  End;

  Procedure WriteFile(N: String; Var C: PCollection);
  Var
    F: Text;
    I: Integer;
  Begin
    Assign(F, N);
    Rewrite(F);
    For I:=0 To C^.Count-1 Do
      Writeln(F, PStr(C^.At(I))^.GetStr);
    Close(F);
    Error:=IOResult<>0;
  End;

  Procedure ChangeAutoexec(Var C: PCollection);
  Begin

  End;

  Procedure ChangeConfig(Var C: PCollection);
  Var
    S: String;
    I: Integer;
  Begin
    I:=0;
    While I<C^.Count Do
    Begin
      S:=PStr(C^.At(0))^.GetStr;
      StrUpr(S);
      If Pos('PCHPW.SYS', S)<>0 Then
      Begin
        C^.AtFree(I);
        Dec(I);
      End;
      Inc(I);
    End;
    C^.AtInsert(0, New(PStr, Init('DEVICE='+ToPath+'PCHPW.SYS')));
  End;

Begin
  ChDir('A:\');
  S:=FSearch('PCHOICE.EXE', 'A:\;B:\');
  If S='' Then
  Begin
    S:='a:';
    If InputBox('Originaldiskette nicht gefunden',
      'In welchem Laufwerk befindet sie sich ?', S, 2)=cmCancel Then
      Exit;
    S:=FSearch('PCHOICE.EXE', S);
    If S='' Then
    Begin
      MessageBox('Originaldiskette nicht gefunden.', nil, mfInformation+mfOkButton);
      Exit;
    End;
  End;
  S:=FExpand(S);
  FromPath:=UpCase(S[1])+':\';
  S:='c:\pchoice';
  Repeat
    If InputBox(Title, 'In welchem Verzeichnis installieren ?', S, 255)=cmCancel Then
      Exit;
    If S[2]<>':' Then MessageBox('Bitte Laufwerk auch angeben !', nil, mfInformation+mfOkButton)
      Else
       If UpCase(S[1])<='B' Then MessageBox('Laufwerk muß eine Festplatte sein !', nil, mfInformation+mfOkButton);
  Until (UpCase(S[1])>='C') And (S[2]=':');
  ChDir(S);
  If IOResult<>0 Then
  Begin
    MkDir(S);
    ChDir(S);
  End;
  If IOResult<>0 Then
  Begin
    MessageBox('Verzeichnis '+S+' kann nicht angelegt werden.', nil, mfError+mfOkButton);
    Exit;
  End;
  If (DiskFree(Ord(UpCase(S[1]))-64) Div 1024)<250 Then
  Begin
    MessageBox('Nicht genügend freier Platz auf Laufwerk '+UpCase(S[1])+': !'#13+
      'Mindestens 250 KB benötigt.', nil, mfError+mfOkButton);
    ChDir(S[1]+':\');
    RmDir(S);
    InOutRes:=0;
    Exit;
  End;
  If S[Length(S)]<>'\' Then S:=S+'\';
  StrUpr(S);
  ToPath:=S;
  ShowMsgBox(Title, 'Kopiere Dateien ...');
  FileList.Init(FromPath+'*.*', AnyFile, False);
  I:=0;
  Repeat
    S:=PString(FileList.At(I))^;
    ShowMsgBox(Title, 'Kopiere '+FileName(S)+' ...');
    CopyFile(S, ToPath+FileName(S));
    Inc(I);
  Until (I=FileList.Count) Or Error;
  HideMsgBox;
  If Error Then
  Begin
    MessageBox('Dateien konnten nicht kopiert werden!', nil, mfError+mfOkButton);
    Exit;
  End;
  ShowMsgBox(Title, 'Passe AUTOEXEC.BAT an ...');
  ReadFile('C:\AUTOEXEC.BAT', F);
  WriteFile('C:\AUTOEXEC.OLD', F);
  ChangeAutoexec(F);
  WriteFile('C:\AUTOEXEC.BAT', F);
  Dispose(F, Done);
  ShowMsgBox(Title, 'Passe CONFIG.SYS an ...');
  ReadFile('C:\CONFIG.SYS', F);
  WriteFile('C:\CONFIG.OLD', F);
  ChangeConfig(F);
  WriteFile('C:\CONFIG.SYS', F);
  Dispose(F, Done);
  MessageBox('Power-Choice 3.00 wurde erfolgreich auf Ihrem Computer installiert.',
    nil, mfInformation+mfOkButton);
  Event.What:=evCommand;
  Event.Command:=cmQuit;
  PutEvent(Event);
  ChDir('E:');
End;

Var
  InstApp: TInstApp;

Begin
  InstApp.Init;
  InstApp.Run;
  InstApp.Done;
End.