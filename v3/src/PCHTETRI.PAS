Unit PchTetris;
{$I PCHSYM.PAS}
{$O+,F+}
Interface
  Uses Objects, Drivers, Views, Dialogs;

  Type
    TFigure= Array[1..4, 1..5] Of Word;
    TField= Array[1..20, 1..20] Of Word;

    PFieldView= ^TFieldView;
    TFieldView= Object(TView)
      Field: TField;
      Procedure ShowField(Var Data: TField);
      Procedure Draw; virtual;
    End;

    PInfoView= ^TInfoView;
    TInfoView= Object(TView)
      Score: Word;
      Sl, Fl: Byte;
      Constructor Init(Bounds: TRect);
      Procedure ShowInfo(AScore: Word; FullLines, Level: Byte);
      Procedure Draw; virtual;
    End;

    PTetris= ^TTetris;
    TTetris= Object(TDialog)
      GameFieldView: PFieldView;
      GameInfoView: PInfoView;
      GameOverView: PStaticText;
      DosTime: ^LongInt;
      OldTime: LongInt;
      Field: TField;
      Figure: TFigure;
      Col: ShortInt;
      Line, Level, Rot, LineDropped, MaxFigures,
      FullLines, Num: Byte;
      PieceValue: ShortInt;
      GameOver, Paused: Boolean;
      Score: Word;
      Constructor Init;
      Procedure HandleEvent(Var Event: TEvent); virtual;
      Procedure GetFigure;
      Procedure MoveFigure(Key: Word);
      Function Check(ShowF: Boolean): Boolean;
      Procedure NewGame;
      Procedure Pause;
      Procedure SetState(AState: Word; Enable: Boolean); virtual;
      Constructor Load(Var S: TStream);
      Procedure Store(Var S: TStream);
    End;

  Const
    RFieldView: TStreamRec= (
      ObjType: 3005;
      VmtLink: Ofs(TypeOf(TFieldView)^);
      Load: @TFieldView.Load;
      Store: @TFieldView.Store
    );
    RInfoView: TStreamRec= (
      ObjType: 3006;
      VmtLink: Ofs(TypeOf(TInfoView)^);
      Load: @TInfoView.Load;
      Store: @TInfoView.Store
    );
    RTetris: TStreamRec= (
      ObjType: 3007;
      VmtLink: Ofs(TypeOf(TTetris)^);
      Load: @TTetris.Load;
      Store: @TTetris.Store
    );

Implementation
  Uses Crt, App, MsgBox, PchCmds, PchMsg, PchGlb;

  Procedure TFieldView.ShowField(Var Data: TField);
  Begin
    Field:=Data; Draw;
  End;

  Procedure TFieldView.Draw;
  Var R: TRect;
  Begin
    GetExtent(R);
    WriteBuf(R.A.X, R.A.Y, R.B.X, R.B.Y, Field);
  End;

  Constructor TInfoView.Init(Bounds: TRect);
  Begin
    TView.Init(Bounds);
    ShowInfo(0, 0, 0);
  End;

  Procedure TInfoView.ShowInfo(AScore: Word; FullLines, Level: Byte);
  Begin
    Score:=AScore;
    Fl:=FullLines;
    Sl:=Level;
    Draw;
  End;

  Procedure TInfoView.Draw;
  Var
    R: TRect;
    Dummy: String;
  Begin
    TView.Draw;
    GetExtent(R);
    Str(Score:5, Dummy);
    WriteStr(R.A.X, R.A.Y, Dummy, 2);
    Str(Fl:5, Dummy);
    WriteStr(R.A.X, R.A.Y+2, Dummy, 2);
    Str(Sl:5, Dummy);
    WriteStr(R.A.X, R.A.Y+4, Dummy, 2);
  End;

  Constructor TTetris.Init;
  Var R: TRect;
  Begin
    R.Assign(0, 0, 50, 22);
    TDialog.Init(R, 'Tetris');
    R.Assign(27, 15, 44, 17);
    Insert(New(PButton, Init(R, GetMsg(sNewGame), cmNewGame, bfDefault)));
    R.Assign(27, 17, 44, 19);
    Insert(New(PButton, Init(R, GetMsg(sPause), cmPause, bfNormal)));
    R.Assign(27, 19, 44, 21);
    Insert(New(PButton, Init(R, GetMsg(sEnd), cmNoMoreGame, bfNormal)));
    R.Assign(2, 1, 22, 21);
    GameFieldView:=New(PFieldView, Init(R));
    GameFieldView^.Options:=GameFieldView^.Options Or ofFramed;
    Insert(GameFieldView);
    R.Assign(24, 3, 37, 9);
    Insert(New(PStaticText, Init(R, GetMsg(sInfoView))));
    R.Assign(38, 3, 49, 13);
    GameInfoView:=New(PInfoView, Init(R));
    Insert(GameInfoView);
    R.Assign(28, 12, 41, 13);
    GameOverView:=New(PStaticText, Init(R, GetMsg(sGameOver)));
    SelectNext(False);
    Options:=Options Or ofCentered;
    HelpCtx:=hcTetris;
    DosTime:=Ptr($40, $6C);
    FillChar(Field, SizeOf(Field), 0);
    GameOver:=True;
    Paused:=False;
    Randomize;
  End;

  Procedure TTetris.NewGame;
  Var
    D: PDialog;
    Data: Record
      StartLevelFlag, ExtSetFlag: Word;
    End;
  Begin
    If (GameOver) Or
      (MessageBox(GetMsg(sNewGameAsk), nil, mfConfirmation+mfYesNoCancel)=cmYes) Then
    Begin
      D:=PDialog(GetRez('TetrisDialog'));
      If D<>nil Then
      Begin
        Data.StartLevelFlag:=0;
        Data.ExtSetFlag:=0;
        D^.SetData(Data);
        If DeskTop^.ExecView(D)=cmOk Then
        Begin
          D^.GetData(Data);
          Delete(GameOverView);
          Score:=0;
          FullLines:=0;
          Level:=Data.StartLevelFlag;
          MaxFigures:=7;
          Inc(MaxFigures, Byte(Data.ExtSetFlag=1)*3);
          GameOver:=False;
          FillChar(Field, SizeOf(Field), 0);
          GameInfoView^.ShowInfo(Score, FullLines, Level);
          GetFigure;
        End;
        Dispose(D, Done);
      End;
    End;
  End;

  Procedure TTetris.HandleEvent(Var Event: TEvent);
  Begin
    If (Event.What=evBroadcast) And (Event.Command=cmSearchTetris) Then
    Begin
      ClearEvent(Event);
      Exit;
    End;
    TDialog.HandleEvent(Event);
    If (Not GameOver) And (Event.What=evCommand) Then
    Begin
      If (DosTime^-(28-Level*3)>OldTime) And (Not Paused) Then
      Begin
        Inc(OldTime, 28-Level*3);
        MoveFigure(cmDown);
      End;
      Case Event.Command Of
        cmLeft, cmRight, cmRotate, cmDrop:
          Begin
            If Paused Then Pause;
            MoveFigure(Event.Command);
            ClearEvent(Event);
          End;
        cmDown: ClearEvent(Event);
      End;
      If GameOver Then
      Begin
        Insert(GameOverView);
        Sound(1000);
        Delay(100);
        NoSound;
      End;
    End;
    If Event.What=evCommand Then
    Begin
      Case Event.Command Of
        cmNewGame: NewGame;
        cmPause: Pause;
        cmNoMoreGame: Close;
        Else Exit;
      End;
      ClearEvent(Event);
    End;
  End;

  Procedure TTetris.GetFigure;
  Const
    Figures: Array[1..10, 1..5] Of Word=
      (($0066, $0066, $0066, $0066, 2),
       ($0036, $0462, $0036, $0462, 6),
       ($0063, $0132, $0063, $0132, 6),
       ($000F, $4444, $000F, $4444, 2),
       ($0074, $0223, $0170, $0311, 4),
       ($0072, $0232, $0270, $0262, 5),
       ($0071, $0322, $0470, $0226, 4),
       ($0057, $0313, $0750, $0646, 10),
       ($0272, $0272, $0272, $0272, 10),
       ($0117, $0711, $0744, $0447, 10));
    Value: Array[0..15] Of Word=
      ($0001, $0002, $0004, $0008, $0010, $0020,
       $0040, $0080, $0100, $0200, $0400, $0800,
       $1000, $2000, $4000, $8000);
  Var
    I, J, K: Integer;
  Begin
    Num:=Random(MaxFigures)+1;
    FillChar(Figure, SizeOf(Figure), 0);
    For I:=1 To 4 Do
    Begin
      J:=1;
      For K:=0 To 15 Do
        If (Figures[Num, I] And Value[K])=Value[K] Then
        Begin
          Figure[I, J]:=K Mod 4+(K Shr 2) Shl 8;
          Inc(J);
        End;
      If J=5 Then Figure[I, J]:=Figure[I, J-1];
    End;
    Col:=7;
    Line:=0;
    Rot:=1;
    LineDropped:=20;
    PieceValue:=5*Figures[Num, 5]*((Level+2) Div 2);
    MoveFigure(cmDown); OldTime:=DosTime^;
  End;

  Procedure TTetris.MoveFigure(Key: Word);
  Var
    DummyCol: ShortInt;
    DummyRot, DummyLine, I: Byte;
    OneCube: LongInt;
    LineFilled: Boolean;
    LinesFilled: Byte;
    Bonus: Word;
  Begin
    If Key=cmDrop Then LineDropped:=Line;
    Repeat
      DummyCol:=Col;
      DummyLine:=Line;
      DummyRot:=Rot;
      Case Key Of
        cmLeft: Dec(Col, 2);
        cmRight: Inc(Col, 2);
        cmDown, cmDrop: Inc(Line);
        cmRotate: Inc(Rot, 1-Byte(Rot=4) Shl 2);
      End;
      If (Key<>cmDrop) Then Dec(PieceValue, 5);
      If Not Check(Key<>cmDrop) Then
      Begin
        Col:=DummyCol;
        Line:=DummyLine;
        Rot:=DummyRot;
        If (Key=cmDown) Or (Key=cmDrop) Then
        Begin
          If Line>0 Then
          Begin
            If PieceValue>0 Then Inc(Score, PieceValue);
            {Inc(Score, Level+Num+Byte(Num>7) Shl 6+(20-LineDropped) Shr 2);}
            OneCube:=219+Word((Num+Byte(Num>7))) Shl 8+219 Shl 16+LongInt((Num+Byte(Num>7))) Shl 24;
            For DummyCol:=1 To 5 Do
              Move(OneCube, Field[Line+Hi(Figure[Rot, DummyCol]), Col+Lo(Figure[Rot, DummyCol]) Shl 1],
                SizeOf(OneCube));
            LinesFilled:=0;
            For DummyLine:=1 To 20 Do
            Begin
              LineFilled:=True;
              For DummyCol:=1 To 20 Do
                If Lo(Field[DummyLine, DummyCol])<>219 Then LineFilled:=False;
              If LineFilled Then
              Begin
                Inc(LinesFilled);
                Move(Field[1, 1], Field[2, 1], 40*(DummyLine-1));
                FillChar(Field[1, 1], 40, 0);
                GameFieldView^.ShowField(Field);
                Sound(300);
                Delay(20);
                NoSound;
              End;
            End;
            If LinesFilled>0 Then
            Begin
              Bonus:=100;
              For I:=1 To LinesFilled-1 Do Inc(Bonus, Bonus);
              Inc(Score, Bonus);
              Inc(FullLines, LinesFilled);
              If FullLines Mod 12=0 Then Inc(Level, Byte(Level<9));
            End;
            GetFigure;
          End Else GameOver:=True;
          GameInfoView^.ShowInfo(Score, FullLines, Level);
        End;
      End;
    Until (Key<>cmDrop) Or (Line=1) Or GameOver;
  End;

  Function TTetris.Check(ShowF: Boolean): Boolean;
  Var
    I: Integer;
    Buf: TField;
    X: ShortInt;
    Y: Byte;
    MoveOk: Boolean;
  Begin
    MoveOk:=True;
    Move(Field, Buf, SizeOf(Field));
    For I:=1 To 5 Do
    Begin
      X:=Col+Lo(Figure[Rot, I]) Shl 1;
      Y:=Line+Hi(Figure[Rot, I]);
      If (X>0) And (X<20) And (Y<21) And (Lo(Field[Y, X])<>219) Then
        MoveChar(Buf[Y, X], #219, Num+Byte(Num>7), 2)
      Else
        MoveOk:=False;
    End;
    If MoveOk And Showf Then GameFieldView^.ShowField(Buf);
    Check:=MoveOk;
  End;

  Procedure TTetris.Pause;
  Begin
    If GameOver Then Exit;
    Paused:=Not Paused;
    OldTime:=DosTime^;
  End;

  Procedure TTetris.SetState(AState: Word; Enable: Boolean);
  Begin
    TDialog.SetState(AState, Enable);
    If AState=sfActive Then
      If (Not Enable) And (Not Paused) Then Pause;
  End;

  Constructor TTetris.Load(Var S: TStream);
  Var R: TRect;
  Begin
    TDialog.Load(S);
    GetSubViewPtr(S, GameFieldView);
    GetSubViewPtr(S, GameInfoView);
    S.Read(Field, SizeOf(Field));
    S.Read(Figure, SizeOf(Figure));
    S.Read(Col, 11*SizeOf(Byte));
    S.Read(Score, SizeOf(Score));
    R.Assign(24, 12, 49, 13);
    GameOverView:=New(PStaticText, Init(R, GetMsg(sGameOver)));
    DosTime:=Ptr($40, $6C);
    OldTime:=DosTime^;
    Randomize;
    GameFieldView^.ShowField(Field);
    GameInfoView^.ShowInfo(Score, FullLines, Level);
  End;

  Procedure TTetris.Store(Var S: TStream);
  Begin
    TDialog.Store(S);
    PutSubViewPtr(S, GameFieldView);
    PutSubViewPtr(S, GameInfoView);
    S.Write(Field, SizeOf(Field));
    S.Write(Figure, SizeOf(Figure));
    S.Write(Col, 11*SizeOf(Byte));
    S.Write(Score, SizeOf(Score));
  End;

End.