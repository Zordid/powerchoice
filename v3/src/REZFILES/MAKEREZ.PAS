Program MakeRez;
Uses Objects, Drivers, Views, Dialogs, Menus, Fields, ColorSel, Editors, App,
    PchCmds, PchMsg, PchHelp, PchPW, HintStat, Editor, StrObj, PchTetris, PchOpt;

Var
  Strm: PBufStream;
  Rez: TResourceFile;

Procedure StrmError(Var S: TStream); far;
Begin
  Writeln('Stream error: ', S.Status);
  Halt(1);
End;

Procedure RegisterTypes;
Begin
  RegisterObjects;
  RegisterMenus;
  RegisterDialogs;
  RegisterViews;
  RegisterHintStat;
  RegisterFields;
  RegisterColorSel;
  RegisterEditor;
  RegisterType(RStr);
  RegisterType(RStringList);
  RegisterType(RClickTester);
  RegisterType(RSysDialog);
End;

Procedure CopyToRez(F: String);
Var
  CStrm: PBufStream;
  CRez: TResourceFile;
  C: Integer;
  Obj: PObject;
Begin
  Writeln('Copying ', F, '...');
  CStrm:=New(PBufStream, Init(F, stOpen, 1024));
  If CStrm^.Status<>0 Then Exit;
  CRez.Init(CStrm);
  For C:=0 To CRez.Count-1 Do
  Begin
    Obj:=CRez.Get(CRez.KeyAt(C));
    If (Obj<>nil) And (TypeOf(Obj^)<>TypeOf(TStringList)) Then
    Begin
      Writeln('  - ', CRez.KeyAt(C));
      Rez.Put(Obj, CRez.KeyAt(C));
      Dispose(Obj, Done);
    End Else
      Writeln('Could not read object');
  End;
  CRez.Done;
End;

Begin
  RegisterTypes;
  StreamError:=@StrmError;
  Writeln('Updating PCHOICE.REZ file...');
  Strm := New(PBufStream, Init('PCHOICE.REZ', stOpen, 1024));
  Rez.Init(Strm);
  CopyToRez('PCHOICE1.REZ');
  CopyToRez('PCHDLGS.REZ');
  Rez.Done;
End.