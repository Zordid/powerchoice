{$I PCHSYM.PAS}
{$F+,O+,D+}
Unit PchCal;
Interface
  Uses Objects, Drivers, DateUtl, Views, Editor;

  Type
    PCalViewer= ^TCalViewer;
    TCalViewer= Object(TScroller)
      ActDate: TDate;
      Constructor Init(Var Bounds: TRect; AVScrollBar: PScrollBar);
      Procedure Draw; virtual;
      Procedure HandleEvent(Var Event: TEvent); virtual;
      Constructor Load(Var S: TStream);
      Procedure Store(Var S: TStream);
    End;

    PCalender= ^TCalender;
    TCalender= Object(TWindow)
      FName: PString;
      Rez: PResourceFile;
      Viewer: PCalViewer;
      Editor: PEdit;
      Constructor Init(ATitle: String; Name: FNameStr; WinNo: Integer);
      Procedure HandleEvent(Var Event: TEvent); virtual;
      Procedure SizeLimits(Var Min, Max: TPoint); virtual;
      Destructor Done; virtual;
      Constructor Load(Var S: TStream);
      Procedure Store(Var S: TStream);
    End;

  Const
    cmCalBase: Word= 10000;
    hcCalender: Word= hcNoContext;

    RCalViewer: TStreamRec= (
      ObjType: 3002;
      VmtLink: Ofs(TypeOf(TCalViewer)^);
      Load: @TCalViewer.Load;
      Store: @TCalViewer.Store
    );
    RCalender: TStreamRec= (
      ObjType: 3003;
      VmtLink: Ofs(TypeOf(TCalender)^);
      Load: @TCalender.Load;
      Store: @TCalender.Store
    );

Implementation
  Uses PchCmds, DosTools, StrObj, StrgUtl, Dialogs, Menus, App, MsgBox;

  Const
    cmDateSelected= 0;
    cmGotoDate= 1;
    cmGotoToday= 2;
    cmSearchEntry= 3;

  Constructor TCalViewer.Init(Var Bounds: TRect; AVScrollBar: PScrollBar);
  Begin
    TScroller.Init(Bounds, nil, AVScrollBar);
    SetLimit(0, 611);
    VScrollBar^.SetParams((Today.GetYear-1990)*12+Today.GetMonth-1, 0, 611, 12, 1);
    ScrollDraw;
    GrowMode:=0;
    VScrollBar^.GrowMode:=0;
    Options:=Options XOr OfFramed;
    ActDate.InitToday;
  End;

  Procedure TCalViewer.Draw;
  Var
    Color, InvColor: Byte;
    Month, Year: Word;
    Y, I: Integer;
    Para: Array[0..1] Of LongInt;
    S: String;
    B: TDrawBuffer;
    P: PCollection;

    Procedure GenerateMonth;
    Var
      T: TDate;
      Offset: Integer;
      L, S: String;
      Para: Array[0..1] Of LongInt;
    Begin
      P:=New(PCollection, Init(6, 0));
      T.InitSet(1, Month, Year);
      Offset:=T.GetWeekDay * 4;
      Repeat
        ChrFill(L, ' ', Offset+1);
        Repeat
          Str(T.GetDay:2, S);
          If T.Equals(ActDate) Then
          Begin
            ChrCat(L, '~');
            StrCat(L, S, 255);
            ChrCat(L, '~');
          End Else
            StrCat(L, S, 255);
          StrCat(L, '  ', 255);
          T.IncDay;
        Until ((T.GetWeekDay=0) Or (T.GetDay=1));
        P^.Insert(New(PStr, Init(L)));
        Offset:=0;
      Until T.GetDay=1;
    End;

  Begin
    Color := GetColor ($02);
    InvColor := GetColor($01);
    Month:=(Delta.Y Mod 12)+1;
    Year:=(Delta.Y Div 12)+1990;
    GenerateMonth;
    I:=0;
    MoveChar(B, '═', Color, Size.X);
    WriteLine(0, 0, Size.X, 1, B);
    PString(Para[0]):=@CDMonthNames[Month];
    Para[1]:=Year;
    FormatStr(S, ' %s %d ', Para);
    WriteStr(14-Length(S) Div 2, 0, S, $02);
    WriteStr(0, 1, ' Mo  Di  Mi  Do  Fr  Sa  So ', $02);
    Y:=2;
    While (Y<=Size.Y-1) And (I<P^.Count) Do
    Begin
      MoveChar(B, ' ', Color, Size.X);
      MoveCStr(B, PStr(P^.At(I))^.GetStr, InvColor Shl 8+Color);
      WriteLine(0, Y, Size.X, 1, B);
      Inc(I);
      Inc(Y);
    End;
    Dispose(P, Done);
    MoveChar(B, ' ', Color, Size.X);
    While Y<=Size.Y-1 Do
    Begin
      WriteLine(0, Y, Size.X, 1, B);
      Inc(Y);
    End;
  End;

  Procedure TCalViewer.HandleEvent(Var Event: TEvent);
  Var
    P: TPoint;
    NewDate: TDate;
    DateChanged: Boolean;

    Procedure CalcNewDate(P: TPoint);
    Var
      T: TDate;
      Week, DayOfWeek, Day: Integer;
    Begin
      Week:=Pred(P.Y);
      DayOfWeek:=(P.X Div 4)+1;
      T.InitSet(1, ActDate.GetMonth, ActDate.GetYear);
      Day:=(Pred(Week)*7)+DayOfWeek-T.GetWeekDay;
      If (Day>0) And (Day<=T.GetMonthLength) Then
      Begin
        DateChanged:=True;
        NewDate.Day:=Day;
      End;
    End;

    Procedure CheckForRedraw;
    Var Month, Year: Word;
    Begin
      Month:=(Delta.Y Mod 12)+1;
      Year:=(Delta.Y Div 12)+1990;
      If (ActDate.Month<>Month) Or (ActDate.Year<>Year) Then
      Begin
        ScrollTo(0, (ActDate.GetYear-1990)*12+ActDate.GetMonth-1);
        ScrollDraw;
      End Else
        Draw;
    End;

  Begin
    NewDate.InitTDate(ActDate);
    If (Event.What=evBroadcast) And (Event.Command=cmScrollBarChanged) Then
    Begin
      NewDate.Month:=(VScrollBar^.Value Mod 12)+1;
      NewDate.Year:=(VScrollBar^.Value Div 12)+1990;
      If NewDate.GetDay>NewDate.GetMonthLength Then
        NewDate.Day:=NewDate.GetMonthLength;
      Message(Owner, evBroadcast, cmCalBase+cmDateSelected, @NewDate);
      ActDate.InitTDate(NewDate);
    End;
    TScroller.HandleEvent(Event);
    DateChanged:=False;
    If (Event.What = evMouseDown) Then
    Begin
      P := Event.Where;
      MakeLocal(P, P);
      CalcNewDate(P);
      ClearEvent (Event);
    End;
    If (Event.What=evKeyDown) Then
    Begin
      If Event.KeyCode<>kbEnter Then
      Begin
        Case Event.KeyCode Of
          kbLeft: NewDate.DecDay;
          kbRight: NewDate.IncDay;
          kbUp: NewDate.DecWeek;
          kbDown: NewDate.IncWeek;
          Else Exit;
        End;
        DateChanged:=True;
      End Else
        PCalender(Owner)^.Editor^.Select;
      ClearEvent(Event);
    End;
    If DateChanged Then
    Begin
      Message(Owner, evBroadcast, cmCalBase+cmDateSelected, @NewDate);
      ActDate.InitTDate(NewDate);
      CheckForRedraw;
    End;
  End;

  Constructor TCalViewer.Load(Var S: TStream);
  Begin
    TScroller.Load(S);
    ActDate.Load(S);
  End;

  Procedure TCalViewer.Store(Var S: TStream);
  Begin
    TScroller.Store(S);
    ActDate.Store(S);
  End;

  Constructor TCalender.Init;
  Var
    Strm: PBufStream;
    R: TRect;
    P: PCollection;
    S: String;
    VScrollBar, HScrollBar: PScrollBar;
  Begin
    R.Assign(0, 0, 60, 14);
    TWindow.Init(R, ATitle, WinNo);

    FName:=NewStr(Name);
    Strm:=New(PBufStream, Init(Name, stOpen, 1024));
    If Strm^.Status<>0 Then Strm^.Init(Name, stCreate, 1024);
    Rez:=New(PResourceFile, Init(Strm));

    S:='Heute: ';
    StrCat(S, Today.GetStrDate, 255);
    GetExtent(R);
    R.Assign(R.A.X+3, R.B.Y-3, R.A.X+29, R.B.Y-2);
    Insert(New(PStaticText, Init(R, S)));
    R.Move(0, 1);
    Insert(New(PStaticText, Init(R, 'Datei: '+FileName(Name))));

    GetExtent(R);
    R.Assign(R.A.X+3, R.A.Y+10, R.A.X+29, R.A.Y+11);
    New(VScrollBar, Init(R));
    Insert(VScrollBar);

    GetExtent(R);
    R.Assign(R.A.X+2, R.A.Y+2, R.A.X+30, R.A.Y+10);
    Viewer:=New(PCalViewer, Init(R, VScrollBar));
    Viewer^.Options:=Viewer^.Options Or ofFramed;
    Insert(Viewer);

    GetExtent(R);
    R.Assign(R.B.X-2, R.A.Y+2, R.B.X-1, R.B.Y-2);
    New(VScrollBar, Init(R));
    Insert(VScrollBar);
    GetExtent(R);
    R.Assign(R.A.X+32, R.B.Y-2, R.B.X-2, R.B.Y-1);
    New(HScrollbar, Init(R));
    Insert(HScrollBar);

    GetExtent(R);
    R.Assign(R.A.X+32, R.A.Y+2, R.B.X-2, R.B.Y-2);
    Editor:=New(PEdit, Init(R, HScrollBar, VScrollBar, nil, 20000, 1));
    Editor^.Options:=(Editor^.Options Or ofFramed) And (Not ofPostProcess);
    Insert(Editor);
    P:=PCollection(Rez^.Get(Viewer^.ActDate.GetStrDate));
    Editor^.SetData(P);
  End;

  Procedure TCalender.SizeLimits(Var Min, Max: TPoint);
  Const
    MinSize: TPoint= (X:50; Y:14);
  Begin
    TWindow.SizeLimits(Min, Max);
    Min:=MinSize;
  End;

  Procedure TCalender.HandleEvent(Var Event: TEvent);
  Var
    P: PCollection;
    MPos: TPoint;
    R: TRect;
    Box: PMenuBox;
  Begin
    If ((Event.What=evMouseDown) And (Event.Buttons=mbRightButton)) Or
       ((Event.What=evKeyDown) And (Event.KeyCode=kbAltF10)) Then
    Begin
      If Event.What<>evMouseDown Then
      Begin
        MPos.X:=Origin.X+1;
        MPos.Y:=Origin.Y+1;
      End Else
      Begin
        MPos:=Event.Where;
        Repeat
          GetMouseEvent(Event);
        Until Event.What=evMouseUp;
      End;
      If MPos.X>58 Then MPos.X:=58;
      If MPos.Y>14 Then MPos.Y:=14;
      R.Assign(MPos.X, MPos.Y, MPos.X+35, MPos.Y+13);
      Box:=New(PMenuBox, Init(R, NewMenu(
        NewItem('~G~ehe zu...', '', kbNoKey, cmCalBase+cmGotoDate, hcCalender,
        NewItem('Gehe nach ~H~eute', '', kbNoKey, cmCalBase+cmGotoToday, hcCalender,
        NewLine(
        NewItem('Suche ~E~intrag...', '', kbNoKey, cmCalBase+cmSearchEntry, hcCalender,
        NewLine(
        NewItem('~S~chließen', 'Alt-F3', kbAltF3, cmClose, hcCalender,
        nil))))))),
      nil));
      Event.What:=evCommand;
      Event.Command:=DeskTop^.ExecView(Box);
      Dispose(Box, Done);
    End;
    TWindow.HandleEvent(Event);
    If Event.What=evBroadcast Then
    Begin
      If Event.Command=cmCalBase+cmDateSelected Then
      Begin
        Editor^.GetData(P);
        If (P^.Count<>1) Or (PStr(P^.At(0))^.GetStr<>'') Then
          Rez^.Put(P, Viewer^.ActDate.GetStrDate)
        Else
          Rez^.Delete(Viewer^.ActDate.GetStrDate);
        P:=PCollection(Rez^.Get(PDate(Event.InfoPtr)^.GetStrDate));
        Editor^.SetData(P);
        Editor^.Draw;
        ClearEvent(Event);
      End;
      If Event.Command=cmSearchCal Then
        ClearEvent(Event);
    End;
  End;

  Destructor TCalender.Done;
  Var P: PCollection;
  Begin
    Editor^.GetData(P);
    If (P^.Count<>1) Or (PStr(P^.At(0))^.GetStr<>'') Then
      Rez^.Put(P, Viewer^.ActDate.GetStrDate)
    Else
      Rez^.Delete(Viewer^.ActDate.GetStrDate);
    Dispose(Rez, Done);
    DisposeStr(FName);
    TWindow.Done;
  End;

  Constructor TCalender.Load(Var S: TStream);
  Var Strm: PBufStream;
  Begin
    TWindow.Load(S);
    GetSubViewPtr(S, Viewer);
    GetSubViewPtr(S, Editor);
    FName:=S.ReadStr;
    Strm:=New(PBufStream, Init(FName^, stOpen, 1024));
    If Strm^.Status<>0 Then
    Begin
      If MessageBox('Die Kalenderdatei %s existiert nicht mehr!'#13+
        'Soll sie neu angelegt werden ?', @FName, mfConfirmation+mfYesNoCancel)=cmYes Then
        Strm^.Init(FName^, stCreate, 1024)
      Else
        Fail;
    End;
    Rez:=New(PResourceFile, Init(Strm));
  End;

  Procedure TCalender.Store(Var S: TStream);
  Begin
    TWindow.Store(S);
    PutSubViewPtr(S, Viewer);
    PutSubViewPtr(S, Editor);
    S.WriteStr(FName);
  End;

End.