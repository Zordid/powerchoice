Unit PchOpt;
{$I PCHSYM.PAS}
{$O+,F+}
Interface
  Uses
    Objects, Drivers, Views, Dialogs;

  Const
    CClickTester = #7#8;

  Type
    PClickTester= ^TClickTester;
    TClickTester= Object(TStaticText)
      Clicked: Boolean;
      Constructor Load(Var S: TStream);
      Function GetPalette: PPalette; virtual;
      Procedure HandleEvent(var Event: TEvent); virtual;
      Procedure Draw; virtual;
    End;

    PSysDialog= ^TSysDialog;
    TSysDialog= Object(TDialog)
      MouseScrollBar: PScrollbar;
      OldDelay: Word;
      Procedure HandleEvent(Var Event: TEvent); virtual;
      Constructor Load(Var S: TStream);
      Procedure Store(Var S: TStream);
    End;

  Const
    RClickTester: TStreamRec= (
      ObjType: 3009;
      VmtLink: Ofs(TypeOf(TClickTester)^);
      Load: @TClickTester.Load;
      Store: @TClickTester.Store
    );
    RSysDialog: TStreamRec= (
      ObjType: 3010;
      VmtLink: Ofs(TypeOf(TSysDialog)^);
      Load: @TSysDialog.Load;
      Store: @TSysDialog.Store
    );

  Procedure SetSysOptions;
  Procedure SetDosOptions;
  Procedure ChangeColors;

Implementation
  Uses
    StrUtl, Menus, App, ColorSel, PchCmds, PchGlb;

  { TClickTester }
  Constructor TClickTester.Load(Var S: TStream);
  Begin
    TStaticText.Load(S);
    Clicked := False;
  End;

  Function TClickTester.GetPalette: PPalette;
  Const
    P: String[Length(CClickTester)] = CClickTester;
  Begin
    GetPalette := @P;
  End;

  Procedure TClickTester.HandleEvent(var Event: TEvent);
  Begin
    TStaticText.HandleEvent(Event);
    if (Event.What = evMouseDown) then
    Begin
      if Event.Double then
      Begin
        Clicked := not Clicked;
        DrawView;
      End;
      ClearEvent(Event);
    End;
  End;

  Procedure TClickTester.Draw;
  Var
    B: TDrawBuffer;
    C: Byte;
  Begin
    if Clicked then C := GetColor(2)
    else C := GetColor(1);
    MoveChar(B, ' ', C, Size.X);
    MoveStr(B, Text^, C);
    WriteLine(0, 0, Size.X, 1, B);
  End;

  Procedure TSysDialog.HandleEvent(Var Event: TEvent);
  Begin
    Case Event.What Of
      evCommand:
        if Event.Command = cmCancel then DoubleDelay := OldDelay;
      evBroadcast:
        if Event.Command = cmScrollBarChanged then
        Begin
          DoubleDelay := MouseScrollBar^.Value;
          ClearEvent(Event);
        End;
    End;
    TDialog.HandleEvent(Event);
  End;

  Constructor TSysDialog.Load(Var S: TStream);
  Begin
    TDialog.Load(S);
    GetSubViewPtr(S, MouseScrollBar);
    MouseScrollBar^.SetValue(DoubleDelay);
  End;

  Procedure TSysDialog.Store(Var S: TStream);
  Begin
    TDialog.Store(S);
    PutSubViewPtr(S, MouseScrollBar);
  End;

  Procedure SetSysOptions;
  Const
    Registered: Boolean= False;
  Var
    Dlg: PSysDialog;
    Data: Word;
  Begin
    If Not Registered Then
    Begin
      RegisterType(RClickTester);
      RegisterType(RSysDialog);
      Registered:=True;
    End;
    Dlg:=PSysDialog(GetRez('SysOptionsDialog'));
    If Dlg<>nil Then
    Begin
      Dlg^.OldDelay:=DoubleDelay;
      Dlg^.MouseScrollBar^.SetValue(DoubleDelay);
      Data:=Word((ScreenMode And smFont8x8)=smFont8x8);
      Dlg^.SetData(Data);
      If DeskTop^.ExecView(Dlg)<>cmCancel Then
      Begin
        Dlg^.GetData(Data);
        If Data=1 Then Data:=smFont8x8;
        Inc(Data, ScreenMode And (Not smFont8x8));
        If Data<>ScreenMode Then Application^.SetScreenMode(Data);
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
      Data:=DosOptions;
      Dlg^.SetData(Data);
      If DeskTop^.ExecView(Dlg)<>cmCancel Then
        Dlg^.GetData(DosOptions);
      Dispose(Dlg, Done);
    End;
    Message(DeskTop, evBroadcast, cmRedrawPrompt, nil);
    Message(DeskTop, evBroadcast, cmRedrawMem, nil);
  End;

  Procedure ChangeColors;
  Const
    Registered: Boolean= False;
  Var
    Dlg: PColorDialog;
    Palette: PPalette;
  Begin
    If Not Registered Then
    Begin
      RegisterType(RColorSelector);
      RegisterType(RMonoSelector);
      RegisterType(RColorDisplay);
      RegisterType(RColorGroupList);
      RegisterType(RColorItemList);
      RegisterType(RColorDialog);
      Registered:=True;
    End;
    Dlg:=PColorDialog(GetRez('ColorDialog'));
    If Dlg<>nil Then
    Begin
      Palette:=Application^.GetPalette;
      Dlg^.SetData(Palette^);
      If DeskTop^.ExecView(Dlg)=cmOK Then
      Begin
        Dlg^.GetData(Palette^);
        CustomColors:=True;
      End;
      Dispose(Dlg, Done);
    End;
    DoneVideo;
    InitVideo;
    Application^.Redraw;
  End;

End.