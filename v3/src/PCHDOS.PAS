Unit PchDos;
{$I PCHSYM.PAS}
{$O+,F+}
Interface
  Uses Objects, Drivers, Views;

  Type
    PDosInterior= ^TDosInterior;
    TDosInterior= Object(TScroller)
      Path: String[80];
      CursorX, CursorY: Byte;
      InputLine: String[80];
      InputPos, MaxLen, ActHist: Byte;
      Constructor Init(Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar);
      Constructor Load(Var S: TStream);
      Procedure Store(Var S: TStream);
      Procedure Draw; virtual;
      Procedure HandleEvent(Var Event: TEvent); virtual;
      Procedure DrawPrompt;
      Procedure InsertChar(C: Char);
      Procedure ExecInput;
    End;

    PDosIndicator= ^TDosIndicator;
    TDosIndicator= Object(TView)
      Constructor Init(Var Bounds: TRect);
      Procedure Draw; virtual;
      Function GetPalette: PPalette; virtual;
      Procedure HandleEvent(Var Event: TEvent); virtual;
      Procedure SetState(AState: Word; Enable: Boolean); virtual;
    End;

    PDosShell= ^TDosShell;
    TDosShell= Object(TWindow)
      Interior: PDosInterior;
      Indicator: PDosIndicator;
      Constructor Init;
      Constructor Load(Var S: TStream);
      Procedure Store(Var S: TStream);
      Procedure HandleEvent(Var Event: TEvent); virtual;
      Procedure SizeLimits(Var Min, Max: TPoint); virtual;
      Function GetPalette: PPalette; virtual;
    End;

  Const
    CDosShellColor= #7#15#10#49#49;
    CDosShellBlackWhite= #7#15#7#112#112;
    CDosShellMonochrome= #7#15#7#112#112;
    CDosWindow= #72#73#74#75#76#13#14#15;

  Const
    RDosIndicator: TStreamRec= (
      ObjType: 300;
      VmtLink: Ofs(TypeOf(TDosIndicator)^);
      Load: @TDosIndicator.Load;
      Store: @TDosIndicator.Store);
    RDosInterior: TStreamRec= (
      ObjType: 3000;
      VmtLink: Ofs(TypeOf(TDosInterior)^);
      Load: @TDosInterior.Load;
      Store: @TDosInterior.Store);
    RDosShell: TStreamRec= (
      ObjType: 3001;
      VmtLink: Ofs(TypeOf(TDosShell)^);
      Load: @TDosShell.Load;
      Store: @TDosShell.Store);

  Procedure ClearPrompt;

Implementation
  Uses
    Overlay, Crt, Dos, StrUtl, StrObj, TextObj, HistList, Memory, App, MsgBox,
    PchCmds, PchHelp, PchGlb, PchPW, PchOpt, PchRun, PchTools;

  Const
    CmdListId= 250;
    CDosIndicator= #2#3;

  Constructor TDosIndicator.Init;
  Begin
    TView.Init(Bounds);
    GrowMode:=gfGrowLoY + gfGrowHiY;
  End;

  Procedure TDosIndicator.Draw;
  Var
    Color: Byte;
    Frame: Char;
    B: TDrawBuffer;
    S: String[25];
  Begin
    If State And sfDragging = 0 Then
    Begin
      Color:=GetColor(1);
      Frame:=#205;
    End Else
    Begin
      Color:=GetColor(2);
      Frame:=#196;
    End;
    MoveChar(B, Frame, Color, Size.X);
    If DosOptions.Quick=1 Then
      FormatStr(S, ' %d KB (QR) ', QuickMem)
    Else
      FormatStr(S, ' %d KB ', NormalMem);
    MoveStr(B[2], S, Color);
    WriteBuf(0, 0, Size.X, 1, B);
  End;

  Function TDosIndicator.GetPalette;
  Const
    P: String[Length(CDosIndicator)]= CDosIndicator;
  Begin
    GetPalette:=@P;
  End;

  Procedure TDosIndicator.HandleEvent(Var Event: TEvent);
  Begin
    If Event.What=evMouseDown Then
    Begin
      Boolean(DosOptions.Quick):=Not Boolean(DosOptions.Quick);
      Draw;
    End;
  End;

  Procedure TDosIndicator.SetState;
  Begin
    TView.SetState(AState, Enable);
    If AState=sfDragging Then DrawView;
    If (AState=sfActive) Then
    Begin
      If Enable Then Show Else Hide;
    End;
  End;

  Constructor TDosInterior.Init;
  Begin
    TScroller.Init(Bounds, AHScrollBar, AVScrollBar);
    GrowMode := gfGrowHiX + gfGrowHiY;
    DragMode := dmLimitLoX + dmLimitLoY;
    HelpCtx := hcDosShell;
    SetLimit(80, 25);
    Path:='';
    InputLine:='';
    InputPos:=1;
    ShowCursor;
    CursorY:=Hi(OldPos);
    DrawPrompt;
    ActHist:=0;
  End;

  Constructor TDosInterior.Load(Var S: TStream);
  Var
    L: PString;
    I, M: Word;
    Str: String[80];
  Begin
    TScroller.Load(S);
    L:=S.ReadStr;
    S.Read(InputPos, SizeOf(InputPos));
    If L<>Nil Then
    Begin
      StrMove(InputLine, L^);
      DisposeStr(L);
    End Else
      InputLine:='';
    S.Read(M, SizeOf(M));
    For I:=0 To M Do
    Begin
      S.Read(Str[0], 1);
      S.Read(Str[1], Byte(Str[0]));
      HistoryAdd(CmdListId, Str);
    End;
    Path:='';
    ActHist:=0;
  End;

  Procedure TDosInterior.Store(Var S: TStream);
  Var
    I, M: Word;
    Str: String[80];
  Begin
    TScroller.Store(S);
    S.WriteStr(@InputLine);
    S.Write(InputPos, SizeOf(InputPos));
    M:=HistoryCount(CmdListId);
    If M>10 Then M:=10;
    S.Write(M, SizeOf(M));
    For I:=M DownTo 0 Do
    Begin
      Str:=HistoryStr(CmdListId, I);
      S.Write(Str[0], 1);
      S.Write(Str[1], Length(Str));
    End;
  End;

  Procedure TDosInterior.Draw;
  Var Y: Word;
  Begin
    For Y:=0 To Size.Y-1 Do
      If Delta.Y+Y<=24 Then
        WriteLine(0, Y, Size.X, 1, OldScreen[Delta.Y+Y, Delta.X]);
  End;

  Procedure TDosInterior.HandleEvent(Var Event: TEvent);

    Procedure MoveCursor(NewPos: ShortInt);
    Begin
      If (NewPos<=Length(InputLine)+1) And (NewPos>0) Then
      Begin
        InputPos:=NewPos;
        Inc(CursorX, NewPos-InputPos);
        SetCursor(CursorX-Delta.X, CursorY-Delta.Y);
        DrawPrompt;
      End;
    End;

    Procedure PutHistory(N: Byte);
    Begin
      If (N<=HistoryCount(CmdListId)) Then
      Begin
        If N=0 Then
          InputLine:=''
        Else
          InputLine:=HistoryStr(CmdListId, N-1);
        InputPos:=Length(InputLine)+1;
        ActHist:=N;
      End Else
      Begin
        Sound(1000);
        Delay(50);
        NoSound;
      End;
      DrawPrompt;
    End;

    Procedure SearchHistory;
    Var
      Found: Boolean;
      Input, Hist: String[80];
    Begin
      If InputPos=1 Then Exit;
      Input:=InputLine;
      StrCut(Input, InputPos-1);
      Found:=False;
      While (ActHist+1<=HistoryCount(CmdListId)) And (Not Found) Do
      Begin
        Inc(ActHist);
        Hist:=HistoryStr(CmdListId, ActHist-1);
        StrCut(Hist, InputPos-1);
        Found:=StrEqu(Input, Hist);
      End;
      If Found Then
      Begin
        InputLine:=HistoryStr(CmdListId, ActHist-1);
        DrawPrompt;
      End Else
      Begin
        Sound(1000);
        Delay(50);
        NoSound;
      End;
    End;

    Procedure InsCmd(S: String);
    Begin
      StrIns(InputLine, S, InputPos, 255);
      If Length(InputLine)>MaxLen Then InputLine[0]:=Char(MaxLen);
      Inc(InputPos, Length(S));
      DrawPrompt;
    End;

  Begin
    TScroller.HandleEvent(Event);
    With Event Do
    Begin
      If What=evKeyDown Then
      Begin
        Case KeyCode Of
          kbRight: MoveCursor(InputPos+1);
          kbLeft: MoveCursor(InputPos-1);
          kbHome: MoveCursor(1);
          kbEnd: MoveCursor(Length(InputLine)+1);
          kbDown: PutHistory(ActHist-1);
          kbUp: PutHistory(ActHist+1);
          kbEsc: PutHistory(0);
          kbEnter, kbCtrlEnter:
            If InputLine<>'' Then
            Begin
              HistoryAdd(CmdListId, InputLine);
              If Keycode=kbEnter Then
                ExecInput
              Else
                PutHistory(0);
              ActHist:=0;
            End;
          kbDel:
            If InputPos<=Length(InputLine) Then
            Begin
              ActHist:=0;
              StrUtl.Delete(InputLine, InputPos, 1);
              DrawPrompt;
            End;
          kbBack:
            If InputPos>1 Then
            Begin
              ActHist:=0;
              StrUtl.Delete(InputLine, InputPos-1, 1);
              Dec(InputPos);
              DrawPrompt;
            End;
          kbTab:
            Begin
              Boolean(DosOptions.Quick):=Not Boolean(DosOptions.Quick);
              Owner^.Redraw;
            End;
          Else
          Begin
            ActHist:=0;
            Case CharCode Of
              ^C: InsCmd('COPY ');
              ^D: InsCmd('DEL ');
              ^T: InsCmd('TYPE ');
              ^X: InsCmd('XCOPY ');
              #32..#255: InsCmd(CharCode);
            End;
          End;
        End;
        ClearEvent(Event);
      End Else
      If What=evCommand Then
      Begin
        Case Command Of
          cmPrevCmd: PutHistory(1);
          cmPrevCmdSearch: SearchHistory;
          Else Exit;
        End;
        ClearEvent(Event);
      End Else
      If (What=evBroadcast) And (Command=cmRedrawPrompt) Then
      Begin
        Path:='';
        DrawPrompt;
      End;
    End;
  End;

  Procedure TDosInterior.InsertChar(C: Char);
  Begin
    MoveChar(OldScreen[CursorY, CursorX], C, 0, 1);
    Inc(CursorX);
    SetCursor(CursorX-Delta.X, CursorY-Delta.Y);
    DrawView;
  End;

  Function Max(X,Y: Integer): Integer; assembler;
  Asm
     MOV   AX,X
     CMP   AX,Y
     JGE   @@1
     MOV   AX,Y
  @@1:
  End;

  Procedure TDosInterior.DrawPrompt;
  Var
    P: PString;
    Prompt: String;
  Begin
    If Path='' Then GetDir(0, Path);
    MoveChar(OldScreen[Hi(OldPos), 0], ' ', 0, 80);
    P:=@Path;
    FormatStr(Prompt, DosOptions.Prompt, P);
    MoveStr(OldScreen[Hi(OldPos), 0], Prompt+InputLine, 0);
    CursorX:=Length(Prompt)+InputPos-1;
    CursorY:=Hi(OldPos);
    If (CursorY >= Delta.Y+Size.Y) Or (CursorY <= Delta.Y) Then
    Begin
      VScrollBar^.SetValue(Max(CursorY-Size.Y+1, 0));
      ScrollDraw;
    End;
    SetCursor(CursorX-Delta.X, CursorY-Delta.Y);
    MaxLen:=80-Length(Prompt);
    Draw;
  End;

  Procedure TDosInterior.ExecInput;
  Var
    S: TBufStream;
    P: PTextBlock;
    Cd: Boolean;
    UInputLine: String;
  Begin
    ChrDelL(InputLine, ' ');
    StrMove(UInputLine, InputLine);
    StrUprG(UInputLine);
    Cd:=(Length(UInputLine)=2) And (UInputLine[2]=':');
    If (Pos('CD', UInputLine)=1) And
      ((UInputLine[3] In [' ', '.', '\']) Or (Length(UInputLine)=2)) Then
    Begin
      Delete(UInputLine, 1, 2);
      ChrDelL(UInputLine, ' ');
      Cd:=True;
    End;
    If Cd Then
    Begin
      If UInputLine<>'' Then
      Begin
        {$I-}
        ChDir(UInputLine);
{$IFDEF CHECKING}
        {$I+}
{$ENDIF}
        If (IOResult<>0) Then
        Begin
          If (DosOptions.AutoCD<>0) And
            ((Length(UInputLine)<>2) Or (UInputLine[2]<>':')) Then
            ChangeDirectory(UInputLine, DosOptions.AutoCD=2)
          Else
          Begin
            Sound(3000);
            Delay(50);
            NoSound;
          End;
        End;
      End Else
        Message(Application, evCommand, cmChangeDir, nil);
      InputLine:='';
      InputPos:=1;
      Message(DeskTop, evBroadcast, cmRedrawPrompt, nil);
    End Else
    Begin
      OldPos:=(CursorY Shl 8)+CursorX;
      Path:='';
      ClockGlb:=(DosOptions.Opt And 1)<>0;
      ScrSaverGlb:=(DosOptions.Opt And 2)<>0;
      WaitForKeyGlb:=(DosOptions.Opt And 8)<>0;
      ToPrintGlb:=NewStr(#10#13);
      RememberOldPath(False);
      New(P, Init(nil));
      P^.SetLine(-1, InputLine);
      InputLine:='';
      InputPos:=1;
      ActHist:=0;
      DosExec('', P, DosOptions.Quick=1);
      Dispose(P, Done);
    End;
  End;

  Constructor TDosShell.Init;
  Var
    VScrollBar, HScrollBar: PScrollBar;
    Bounds: TRect;
  Begin
    Application^.GetBounds(Bounds);
    Bounds.Assign(1, Bounds.B.Y-14, 79, Bounds.B.Y-2);
    If (ScreenMode And smFont8x8)<>0 Then
    Begin
      Dec(Bounds.A.Y, 15);
      Dec(Bounds.B.Y, 1);
    End;
    TWindow.Init(Bounds, 'Dos Shell', wnNoNumber);
    VScrollBar:=StandardScrollBar(sbVertical+sbHandleKeyboard);
    Bounds.Assign(18, Size.Y - 1, Size.X - 2, Size.Y);
    HScrollBar := New(PScrollBar, Init(Bounds));
    HScrollBar^.Hide;
    Insert(HScrollBar);
    Bounds.Assign(1, Size.Y - 1, 16, Size.Y);
    Indicator:= New(PDosIndicator, Init(Bounds));
    Indicator^.Hide;
    Insert(Indicator);
    GetExtent(Bounds);
    Bounds.Grow(-1, -1);
    Interior:=New(PDosInterior, Init(Bounds, HScrollBar, VScrollBar));
    Insert(Interior);
  End;

  Constructor TDosShell.Load(Var S: TStream);
  Begin
    If (LowLevel^.Password<>0) And (UserList[UserNo].Access And 1=0) Then Fail;
    TWindow.Load(S);
    GetSubViewPtr(S, Interior);
    GetSubViewPtr(S, Indicator);
    Interior^.DrawPrompt;
  End;

  Procedure TDosShell.Store(Var S: TStream);
  Begin
    TWindow.Store(S);
    PutSubViewPtr(S, Interior);
    PutSubViewPtr(S, Indicator);
  End;

  Procedure TDosShell.HandleEvent(Var Event: TEvent);
  Begin
    TWindow.HandleEvent(Event);
    With Event Do
    If What=evBroadcast Then
    Case Command Of
      cmSearchDosShell: ClearEvent(Event);
      cmRedrawMem: Indicator^.DrawView;
    End;
  End;

  Procedure TDosShell.SizeLimits(Var Min, Max: TPoint);
  Begin
    TWindow.SizeLimits(Min, Max);
    Min.X:=23;
    Dec(Min.Y);
    Max.Y:=27;
  End;

  Function TDosShell.GetPalette: PPalette;
  Const
    P: String[Length(CDosWindow)]= CDosWindow;
  Begin
    GetPalette:=@P;
  End;

  Procedure ClearPrompt;
  Begin
    MoveChar(OldScreen[Hi(OldPos), 0], ' ', 0, 80);
    WordRec(OldPos).Lo:=0;
  End;

End.