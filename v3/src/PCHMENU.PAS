Unit PchMenu;
{$I PCHSYM.PAS}
Interface
  Uses Objects, Drivers, Views, Dialogs, StrObj, TextObj;

  Const
    miClock= 1;
    miScreensaver= 2;
    miWait= 4;
    miSavePath= 8;

    CGroupColor= #$70#$7F#$7A#$30#$3F#$3E#$50#$5F#$5E#$70;
    CGroupBlackWhite= #$70#$7F#$7F#$70#$7F#$07#$70#$7F#$07#$70;
    CGroupMonochrome= #$70#$70#$70#$07#$0F#$0F#$07#$0F#$0F#$70;
    CGroupDialog=#77#78#79#80#81#82#83#84#85#86;
    CMenuButton=#4#0#5#0#6#6#6#10;
    CMenuButtonEditing=#7#0#8#0#9#9#9#10;

  Type
    PGroupItem= ^TGroupItem;

    PMenuItem= ^TMenuItem;
    TMenuItem= Object(TObject)
      Owner: PGroupItem;
      HotKey: Byte;
      Name, Password, Hint: TStr;
      Restricted: Set Of Byte;
      Constructor Init;
      Constructor Load(Var S: TStream);
      Procedure Store(Var S: TStream);
      Function CheckPassword: Boolean;
      Procedure SetName(N: String);
      Function GetName: String;
      Function GetCName: String; virtual;
      Procedure Execute; virtual;
      Function Edit: Word; virtual;
      Destructor Done; virtual;
    End;

    PDosItem= ^TDosItem;
    TDosItem= Object(TMenuItem)
      DosPath: TStr;
      Commands: PTextBlock;
      Options,
      ReqMem, ReqExtMem: Word;
      Constructor Init;
      Constructor Load(Var S: TStream);
      Procedure Store(Var S: TStream);
      Procedure Execute; virtual;
      Function Edit: Word; virtual;
      Destructor Done; virtual;
    End;

    TGroupItem= Object(TMenuItem)
      Cols: Byte;
      MenuItems: PCollection;
      Constructor Init;
      Constructor Load(Var S: TStream);
      Procedure Store(Var S: TStream);
      Function CheckPassword: Boolean;
      Function GetCName: String; virtual;
      Procedure Execute; virtual;
      Function Edit: Word; virtual;
      Destructor Done; virtual;
      Procedure InsertItem;
      Function GetGroupPath: String;
    End;

  Type
    PMenuButton= ^TMenuButton;
    TMenuButton= Object(TButton)
      MenuItem: PMenuItem;
      Constructor Init(AnOrigin: TPoint; AMenuItem: PMenuItem);
      Procedure SetState(AState: Word; Enable: Boolean); virtual;
      Procedure PutEvent(Var Event: TEvent); virtual;
      Procedure HandleEvent(Var Event: TEvent); virtual;
      Function GetPalette: PPalette; virtual;
    End;

    PGroupWindow= ^TGroupWindow;
    TGroupWindow= Object(TDialog)
      Group: PGroupItem;
      Colums: Byte;
      ItemsCount: Integer;
      Constructor Init(P: PGroupItem; Mov: ShortInt);
      Constructor Load(Var S: TStream);
      Procedure Store(Var S: TStream);
      Procedure SizeLimits(Var Min, Max: TPoint); virtual;
      Procedure HandleEvent(Var Event: TEvent); virtual;
      Function GetHelpCtx: Word; virtual;
      Function GetPalette: PPalette; virtual;
      Procedure SetTitle;
      Function PerCol: Byte;
      Procedure MakeInterior;
    End;

  Const
    RMenuItem: TStreamRec= (
      ObjType: 200;
      VmtLink: Ofs(TypeOf(TMenuItem)^);
      Load: @TMenuItem.Load;
      Store: @TMenuItem.Store);
    RDosItem: TStreamRec= (
      ObjType: 201;
      VmtLink: Ofs(TypeOf(TDosItem)^);
      Load: @TDosItem.Load;
      Store: @TDosItem.Store);
    RGroupItem: TStreamRec= (
      ObjType: 202;
      VmtLink: Ofs(TypeOf(TGroupItem)^);
      Load: @TGroupItem.Load;
      Store: @TGroupItem.Store);
    RMenuButton: TStreamRec= (
      ObjType: 3009;
      VmtLink: Ofs(TypeOf(TMenuButton)^);
      Load: @TMenuButton.Load;
      Store: @TMenuButton.Store);
    RGroupWindow: TStreamRec= (
      ObjType: 3004;
      VmtLink: Ofs(TypeOf(TGroupWindow)^);
      Load: @TGroupWindow.Load;
      Store: @TGroupWindow.Store);

  Const
    EditChanged: Boolean= False;
  Var
    MainMenu: PGroupItem;

  Function LoadMenu(Var P: PGroupItem; FName: String): Boolean;
  Procedure StoreMenu(Var P: PGroupItem; FName: String);
  Procedure EditMainGroup;

Implementation
  Uses
    StrUtl,
    MsgBox, App, HintStat,
    PchGlb, PchOpt, PchMsg, PchCmds, PchHelp, PchPW, PchRun, PchDos, PchMacro;

  Function EditMenuItem(M: PMenuItem): Word;
  Var
    Cmd: Word;
    Win: PGroupWindow;
    Group: PGroupItem;

    Function SameHotKey(Item: PMenuItem): Boolean; far;
    Begin
      SameHotKey:=(Item<>M) And (Item^.HotKey<>0) And (M^.HotKey<>0) And
        (UpCase(Item^.Name.P^[Item^.HotKey])=UpCase(M^.Name.P^[M^.HotKey]));
    End;

  Begin
    Cmd:=M^.Edit;
    Case Cmd Of
      cmOk:
        Begin
          If M^.Owner^.MenuItems^.FirstThat(@SameHotKey)<>nil Then
          Begin
            M^.HotKey:=0;
            MessageBox(GetMsg(sDuplicateHotKey), nil, mfInformation+mfOkButton);
          End;
          Message(DeskTop, evBroadcast, cmRedrawMenu, M);
          EditChanged:=True;
        End;
      cmDeleteItem:
        If MessageBox(GetMsg(sDeletePrompt), @M^.Name.P, mfConfirmation+mfYesNoCancel)=cmYes Then
        Begin
          EditChanged:=True;
          Group:=M^.Owner;
          With Group^.MenuItems^ Do
            AtFree(IndexOf(M));
          Message(Desktop, evBroadcast, cmRedrawMenu, Group);
        End;
      cmSwitchGroup:
        Begin
          Win:=Message(DeskTop, evBroadcast, cmSearchMenuPage, M);
          If Win=Nil Then
            DeskTop^.Insert(New(PGroupWindow, Init(PGroupItem(M), 1)))
          Else
            Win^.Select;
        End;
    End;
    EditMenuItem:=Cmd;
  End;

  Constructor TMenuItem.Init;
  Begin
    TObject.Init;
    Name.Init('');
    Password.Init('');
    Hint.Init('');
  End;

  Constructor TMenuItem.Load(Var S: TStream);
  Var P: PString;
  Begin
    Name.Load(S);
    Password.Load(S);
    Hint.Load(S);
    S.Read(HotKey, 1);
    S.Read(Restricted, SizeOf(Restricted));
  End;

  Procedure TMenuItem.Store(Var S: TStream);
  Begin
    Name.Store(S);
    Password.Store(S);
    Hint.Store(S);
    S.Write(HotKey, 1);
    S.Write(Restricted, SizeOf(Restricted));
  End;

  Function TMenuItem.CheckPassword: Boolean;
  Begin
    CheckPassword:=PchPW.CheckPassword(GetMsg(sEnterPassword), Name.P, Password.GetStr);
  End;

  Procedure TMenuItem.SetName(N: String);
  Begin
    HotKey:=ChrPosL(N, '~', 1);
    While ChrPosL(N, '~', 1)<>0 Do Delete(N, ChrPosL(N, '~', 1), 1);
    Name.SetStr(N);
  End;

  Function TMenuItem.GetName: String;
  Var N: String;
  Begin
    N:=Name.GetStr;
    If HotKey<>0 Then Insert('~', N, HotKey);
    GetName:=N;
  End;

  Function TMenuItem.GetCName: String;
  Var N: String;
  Begin
    N:=GetName;
    If HotKey<>0 Then Insert('~', N, HotKey+2);
    GetCName:=N;
  End;

  Procedure TMenuItem.Execute;
  Begin
    Abstract;
  End;

  Function TMenuItem.Edit: Word;
  Begin
    Abstract;
  End;

  Destructor TMenuItem.Done;
  Begin
    Name.Done;
    Password.Done;
    Hint.Done;
  End;

  Constructor TDosItem.Init;
  Begin
    TMenuItem.Init;
    DosPath.Init('');
    New(Commands, Init(nil));
    Options:=miClock+miScreenSaver;
  End;

  Constructor TDosItem.Load(Var S: TStream);
  Begin
    TMenuItem.Load(S);
    S.Read(Options, 3*SizeOf(Word));
    DosPath.Load(S);
    Commands:=PTextBlock(S.Get);
  End;

  Procedure TDosItem.Store(Var S: TStream);
  Begin
    TMenuItem.Store(S);
    S.Write(Options, 3*SizeOf(Word));
    DosPath.Store(S);
    S.Put(Commands);
  End;

  Procedure TDosItem.Execute;
  Var
    Quick: Boolean;
    MemArray: Array[1..2] Of LongInt;
    DosCmds, PchCmds: PTextBlock;

    Function SplitCmds: Boolean;
    Var
      L: Integer;
      S, U: String;
      Part: Byte;
    Begin
      SplitCmds:=False;
      New(DosCmds, Init(nil));
      New(PchCmds, Init(nil));
      L:=0;
      Part:=0;
      While L<Commands^.Count Do
      Begin
        StrMove(S, Commands^.GetLine(L)^);
        StrMove(U, S);
        StrUpr(U);
        If StrEqu(U, '[PCH]') Then
        Begin
          If Part>0 Then
          Begin
            Str(L, S);
            MessageBox('Befehl [PCH] falsch plaziert in Zeile '+S+' !', nil, mfError+mfOkButton);
            Exit;
          End Else
            Part:=1;
        End Else
        If StrEqu(U, '[DOS]') Then
        Begin
          If Part=2 Then
          Begin
            Str(L, S);
            MessageBox('Befehl [DOS] falsch plaziert in Zeile '+S+' !', nil, mfError+mfOkButton);
            Exit;
          End Else
            Part:=2;
        End Else
        If S<>'' Then
        Begin
          If Part=0 Then Part:=2;
          Case Part Of
            1: PchCmds^.Insert(New(PStr, Init(S)));
            2: DosCmds^.Insert(New(PStr, Init(S)));
          End;
        End;
        Inc(L);
      End;
      SplitCmds:=True;
    End;

  Begin
    If CheckPassword Then
    Begin
      If SplitCmds Then
      Begin
        If DosCmds^.Empty And PchCmds^.Empty Then
        Begin
          MessageBox(GetMsg(sNoCommands), @Name, mfInformation+mfOkButton);
        End Else
        Begin
          ClockGlb:=(Options And miClock)<>0;
          ScrSaverGlb:=(Options And miScreenSaver)<>0;
          WaitforKeyGlb:=(Options And miWait)<>0;
          Quick:=False;
          If ReqMem<>0 Then
          Begin
            Quick:=QuickMem>=ReqMem;
            If NormalMem<ReqMem Then
            Begin
              MemArray[1]:=ReqMem;
              MemArray[2]:=NormalMem;
              MessageBox(GetMsg(sNotEnoughMem), @MemArray, mfInformation+mfOkButton);
              Exit;
            End;
          End;
          If (PchCmds^.Empty) Or (PchExec(PchCmds, DosCmds)) Then
          Begin
            ClearPrompt;
            RememberOldPath(Options And miSavePath<>0);
            DosExec(DosPath.GetStr, DosCmds, Quick);
            If ExecResult=PathNotFound Then
              MessageBox(GetMsg(sDirNotFoundError), @DosPath.P, mfError+mfOkButton);
          End;
        End;
      End;
      Dispose(DosCmds, Done);
      Dispose(PchCmds, Done);
    End;
  End;

  Function TDosItem.Edit: Word;
  Type
    DlgRec= Record
      N: String[22]; 
      P: String[10]; 
      H, Path: String[80];
      Cmds: PTextBlock;
      O: Word;
      RMem, RExtMem: LongInt;
    End;
  Var
    Dlg: PDialog;
    Data: DlgRec;
    Cmd: Word;
  Begin
    Cmd:=cmCancel;
    If CheckPassword Then
    Begin
      Dlg:=PDialog(GetRez('CmdEditDialog'));
      If Dlg<>Nil Then
      Begin
        With Data Do
        Begin
          StrMove(N, GetName);
          StrMove(P, Password.GetStr);
          StrMove(H, Hint.GetStr);
          Cmds:=New(PTextBlock, Init(Commands));
          StrMove(Path, DosPath.GetStr);
          O:=Options;
          RMem:=ReqMem;
          RExtMem:=ReqExtMem;
        End;
        Dlg^.SetData(Data);
        Cmd:=DeskTop^.ExecView(Dlg);
        If Cmd=cmOk Then With Data Do
        Begin
          Dlg^.GetData(Data);
          SetName(N);
          Password.SetStr(P);
          Dispose(Commands, Done);
          Commands:=New(PTextBlock, Init(Cmds));
          DosPath.SetStr(Path);
          Hint.SetStr(H);
          Restricted:=[];
          Options:=O;
          ReqMem:=RMem;
          ReqExtMem:=RExtMem;
        End;
        Dispose(Data.Cmds, Done);
        Dispose(Dlg, Done);
      End;
    End;
    Edit:=Cmd;
  End;

  Destructor TDosItem.Done;
  Begin
    DosPath.Done;
    Dispose(Commands, Done);
    TMenuItem.Done;
  End;

  Constructor TGroupItem.Init;
  Begin
    TMenuItem.Init;
    MenuItems:=New(PCollection, Init(1, 5));
    Cols:=1;
  End;

  Constructor TGroupItem.Load(Var S: TStream);
  Var
    C: Integer;
    P: PObject;

    Procedure SetOwner(M: PMenuItem); far;
    Begin
      M^.Owner:=@Self;
    End;

  Begin
    TMenuItem.Load(S);
    S.Read(Cols, SizeOf(Cols));
    MenuItems:=PCollection(S.Get);
    MenuItems^.ForEach(@SetOwner);
  End;

  Procedure TGroupItem.Store(Var S: TStream);
  Begin
    TMenuItem.Store(S);
    S.Write(Cols, SizeOf(Cols));
    S.Put(MenuItems);
  End;

  Function TGroupItem.CheckPassword: Boolean;
  Begin
    { Is it already visible ? }
    CheckPassword:=(Message(DeskTop, evBroadcast, cmSearchMenuPage, @Self)<>Nil)
      Or TMenuItem.CheckPassword;
  End;

  Function TGroupItem.GetCName: String;
  Begin
    GetCName:=TMenuItem.GetCName+'...';
  End;

  Procedure TGroupItem.Execute;
  Var OldPage: PGroupWindow;
  Begin
    If CheckPassword Then
    Begin
      OldPage:=Message(DeskTop, evBroadcast, cmSearchMenuPage, @Self);
      If OldPage=Nil Then
        DeskTop^.Insert(New(PGroupWindow, Init(@Self, 1)))
      Else
        OldPage^.Select;
    End;
  End;

  Function TGroupItem.Edit: Word;
  Type
    DlgRec= Record
      N: String[22]; {KeyInputline}
      C: LongInt;  {NumInputline}
      P: String[10]; {Inputline}
      R: String[80]; {Inputline}
    End;
  Var
    OldPage: PGroupWindow;
    Dlg: PDialog;
    Data: DlgRec;
    Cmd: Word;
  Begin
    Cmd:=cmCancel;
    If CheckPassword Then
    Begin
      Dlg:=PDialog(GetRez('GroupEditDialog'));
      If Dlg<>Nil Then
      Begin
        With Data Do
        Begin
          StrMove(N, GetName);
          StrMove(P, Password.GetStr);
          C:=Cols;
          R:='';
        End;
        Dlg^.SetData(Data);
        Cmd:=DeskTop^.ExecView(Dlg);
        If Cmd=cmOk Then With Data Do
        Begin
          Dlg^.GetData(Data);
          SetName(N);
          Password.SetStr(P);
          Cols:=C;
          Restricted:=[];
        End;
        Dispose(Dlg, Done);
      End;
    End;
    Edit:=Cmd;
  End;

  Destructor TGroupItem.Done;
  Begin
    Message(Message(DeskTop, evBroadcast, cmSearchMenuPage, @Self), evCommand, cmClose, nil);
    Dispose(MenuItems, Done);
    TMenuItem.Done;
  End;

  Procedure TGroupItem.InsertItem;
  Var
    NewItem: PMenuItem;
    Dlg: PDialog;
    Cmd: Word;
  Begin
    Dlg:=PDialog(GetRez('NewItemDialog'));
    If Desktop^.ExecView(Dlg)<>cmCancel Then
    Begin
      Dlg^.GetData(Cmd);
      If Cmd=1 Then
        NewItem:=New(PGroupItem, Init)
      Else
        NewItem:=New(PDosItem, Init);
      NewItem^.Owner:=@Self;
      DeskTop^.DisableCommands([cmDeleteItem, cmSwitchGroup]);
      Case EditMenuItem(NewItem) Of
        cmOk:
          Begin
            EditChanged:=True;
            MenuItems^.Insert(NewItem);
            Message(DeskTop, evBroadcast, cmRedrawMenu, @Self);
          End;
        cmCancel:
          Dispose(NewItem, Done);
      End;
      DeskTop^.EnableCommands([cmDeleteItem, cmSwitchGroup]);
    End;
    If Dlg<>nil Then Dispose(Dlg, Done);
  End;

  Function TGroupItem.GetGroupPath: String;
  Var S: String;
  Begin
    If Owner<>Nil Then
    Begin
      S:=Owner^.GetGroupPath;
      S:=S+Chr(Owner^.MenuItems^.IndexOf(@Self));
    End Else
      S:='';
    GetGroupPath:=S;
  End;

{== TMenuButton ============================================================}

  Constructor TMenuButton.Init(AnOrigin: TPoint; AMenuItem: PMenuItem);
  Var R: TRect;
  Begin
    R.Assign(1, 2, 24, 4);
    R.Move(24*AnOrigin.X, 2*AnOrigin.Y);
    TButton.Init(R, AMenuItem^.GetCName, cmMenuItem, bfNormal);
    MenuItem:=AMenuItem;
  End;

  Procedure TMenuButton.PutEvent(Var Event: TEvent);
  Begin
    If (Event.What=evCommand) And (Event.Command=cmMenuItem) Then
      Event.InfoPtr:=Pointer(MenuItem);
    TButton.PutEvent(Event);
  End;

  Procedure TMenuButton.SetState(AState: Word; Enable: Boolean);
  Begin
    TButton.SetState(AState, Enable);
    If (AState=sfFocused) And Enable Then UpdateHint:=True;
  End;

  Procedure TMenuButton.HandleEvent(Var Event: TEvent);
  Var
    Shell: PDosShell;
    P: Integer;
    ShortCut: Char;
  Begin
    If Event.What=evKeyDown Then
    Begin
      If UpCase(Event.CharCode) In ['A'..'Z'] Then
      Begin
        Shell:=PDosShell(Message(DeskTop, evBroadcast, cmSearchDosShell, nil));
        If Shell<>nil Then
        Begin
          Shell^.Select;
          PutEvent(Event);
          ClearEvent(Event);
        End Else
          Event.CharCode:=Char(Byte(UpCase(Event.CharCode))-64);
      End;
      P:=Pos('~', Title^);
      If (P>0) And (P<Length(Title^)) Then
        ShortCut:=UpCase(Title^[P+1])
      Else
        ShortCut:=#0;
      If (Event.CharCode<#27) And (Byte(ShortCut)=Byte(Event.CharCode)+64) Then
      Begin
        Event.What:=evCommand;
        Event.Command:=Command;
        PutEvent(Event);
        ClearEvent(Event);
      End;
      If GetAltChar(Event.KeyCode)=ShortCut Then Exit;
    End;
    If (Event.What=evBroadcast) And (Event.Command=cmRedrawMenu) And
      (Event.InfoPtr=Pointer(MenuItem)) And (Not StrEqu(MenuItem^.GetCName, Title^)) Then
    Begin
      DisposeStr(Title);
      Title:=NewStr(MenuItem^.GetCName);
      Draw;
    End;
    TButton.HandleEvent(Event);
  End;

  Function TMenuButton.GetPalette: PPalette;
  Const
    P: String[Length(CMenuButton)]= CMenuButton;
    PEdit: String[Length(CMenuButtonEditing)]= CMenuButtonEditing;
  Begin
    If Editing Then
      GetPalette:=@PEdit
    Else
      GetPalette:=@P;
  End;

{== TGroupWindow ===========================================================}

  Function TGroupWindow.PerCol: Byte;
  Var C: Integer;
  Begin
    C:=Group^.MenuItems^.Count;
    While (C Mod Colums)<>0 Do Inc(C);
    PerCol:=C Div Colums;
  End;

  Procedure TGroupWindow.SetTitle;
  Var S: String;
  Begin
    DisposeStr(Title);
    If Editing Then StrMove(S, 'Edit: ') Else S:='';
    StrCat(S, Group^.Name.GetPtr^, 255);
    Title:=NewStr(S);
  End;

  Constructor TGroupWindow.Init(P: PGroupItem; Mov: ShortInt);
  Var R: TRect;
  Begin
    With DeskTop^.Last^.Next^.Origin Do R.Assign(X, Y, X+1, Y+1);
    R.Move(Mov, Mov);
    TDialog.Init(R, '');
    Group:=P;
    If Group^.Owner=Nil Then Flags:=Flags And (Not wfClose);
    MakeInterior;
    SetTitle;
  End;

  Function TGroupWindow.GetHelpCtx: Word;
  Var H: Word;
  Begin
    H:=TWindow.GetHelpCtx;
    If H=hcNoContext Then
    Begin
      If Editing Then
        GetHelpCtx:=hcEditMode
      Else
        GetHelpCtx:=hcMenuPage;
    End Else
      GetHelpCtx:=H;
  End;

  Function TGroupWindow.GetPalette: PPalette;
  Const P: String[Length(CGroupDialog)]= CGroupDialog;
  Begin
    GetPalette:=@P;
  End;

  Procedure TGroupWindow.MakeInterior;
  Var
    O: TPoint;
    R: TRect;
    PC: Byte;
    P: PView;
    ActItem: PMenuItem;

    Procedure DeleteView(Item: PView); far;
    Begin
      If (TypeOf(Item^)=TypeOf(TMenuButton)) Or
         (TypeOf(Item^)=TypeOf(TStaticText)) Then
      Begin
        Delete(Item);
        Dispose(Item, Done);
      End;
    End;

    Procedure InsertButton(Item: PMenuItem); far;
    Begin
      Insert(New(PMenuButton, Init(O, Item)));
      Inc(O.Y);
      If O.Y=PC Then
      Begin
        O.Y:=0;
        Inc(O.X);
      End;
    End;

  Begin
    Hide;
    If ItemsCount<>0 Then
      ActItem:=PMenuButton(Current)^.MenuItem
    Else
      ActItem:=nil;
    Colums:=Group^.Cols;
    ItemsCount:=Group^.MenuItems^.Count;
    If Group^.MenuItems^.Count=0 Then
      R.Assign(0, 0, 34, 5)
    Else
      R.Assign(0, 0, 3+Colums*24, 4+PerCol*2);
    R.Move(Origin.X, Origin.Y);
    ChangeBounds(R);
    ForEach(@DeleteView);
    PC:=PerCol;
    O.X:=0;
    O.Y:=0;
    If ItemsCount=0 Then
    Begin
      R.Assign(4, 2, 32, 3);
      P:=New(PStaticText, Init(R, GetMsg(sNoMenuItems)));
      P^.Options:=P^.Options Or ofCenterX;
      Insert(P);
    End Else
      Group^.MenuItems^.ForEach(@InsertButton);
    P:=Last^.Next;
    If (ActItem<>nil) And (ItemsCount<>0) Then
    Begin
      While (P<>Last) And (PMenuButton(P)^.MenuItem<>ActItem) Do P:=P^.Next;
      P^.Select;
      If PMenuButton(P)^.MenuItem<>ActItem Then SelectNext(False);
    End Else
      SelectNext(False);
    Show;
  End;

  Procedure TGroupWindow.SizeLimits(Var Min, Max: TPoint);
  Begin
    TDialog.SizeLimits(Min, Max);
    Dec(Min.Y);
  End;

  Procedure TGroupWindow.HandleEvent(Var Event: TEvent);
  Label HandleKey;
  Var
    PrevPage: Boolean;
    OldOrigin: TPoint;
    P: PView;
    R: TRect;

    Function GetNext(P: PView; Forward: Boolean): PView;
    Var R: PView;
    Begin
      R:=P^.Next;
      If Forward Then While R^.Next<>P Do R:=R^.Next;
      GetNext:=R;
    End;

  Begin
    PrevPage:=False;
    If (Event.What=evMouseDown) And (Event.Buttons=mbRightButton) Then
    Begin
      PrevPage:=True;
      ClearEvent(Event);
    End;
    If (Event.What=evKeydown) Then
    Begin
      Case Event.KeyCode Of
        kbTab: PrevPage:=True;
        kbUp: SelectNext(True);
        kbDown: SelectNext(False);
        kbRight, kbLeft:
          Begin
            OldOrigin:=Current^.Origin;
            P:=Current;
            Repeat
              P:=GetNext(P, Event.KeyCode=kbRight);
            Until (P^.Origin.Y=OldOrigin.Y) And
              (((Event.KeyCode=kbRight) And (P^.Origin.X>=OldOrigin.X)) Or
               ((Event.KeyCode=kbLeft) And (P^.Origin.X<=OldOrigin.X)));
            P^.Select;
          End;
        Else Goto HandleKey;
      End;
      ClearEvent(Event);
    End;
    If PrevPage And (Group^.Owner<>nil) Then
    Begin
      Select;
      P:=PView(Message(DeskTop, evBroadcast, cmSearchMenuPage, Group^.Owner));
      If P<>Nil Then P^.Select Else
      Begin
        P:=New(PGroupWindow, Init(Group^.Owner, -1));
        DeskTop^.Insert(P);
      End;
      If SysOptions.AutoClose Then Close;
    End;
    HandleKey:
    TDialog.HandleEvent(Event);
    If Event.What=evCommand Then
    Begin
      Case Event.Command Of
        cmNewMenuItem: Group^.InsertItem;
        cmMenuItem:
          If Editing Then
            EditMenuItem(PMenuItem(Event.InfoPtr))
          Else
            PMenuItem(Event.InfoPtr)^.Execute;
        Else Exit;
      End;
      ClearEvent(Event);
    End;
    If (Event.What=evBroadcast) And (Event.InfoPtr=Pointer(Group)) Then
    Case Event.Command Of
      cmSearchMenuPage: ClearEvent(Event);
      cmRedrawMenu:
        Begin
          If Not StrEqu(Group^.Name.P^, Title^) Then
          Begin
            SetTitle;
            Frame^.Draw;
          End;
          If (Group^.Cols<>Colums) Or (Group^.MenuItems^.Count<>ItemsCount) Then
            MakeInterior;
        End;
    End;
    If (Event.What=evBroadcast) And (Event.Command=cmModeChanged) Then
    Begin
      SetTitle;
      Redraw;
    End;
  End;

  Constructor TGroupWindow.Load(Var S: TStream);
  Var
    Path, Name: PString;
    P: PGroupItem;
    I: Integer;
  Begin
    Path:=S.ReadStr;
    Name:=S.ReadStr;
    { Find Group }
    P:=MainMenu;
    If Path<>Nil Then
      For I:=1 To Length(Path^) Do If P<>Nil Then
        P:=P^.MenuItems^.At(Ord(Path^[I]));
    If (P<>Nil) And StrEqu(Name^, P^.Name.P^) Then
    Begin
      Init(P, 0);
      S.Read(Origin, SizeOf(Origin));
      S.Read(I, SizeOf(I));
      For I:=I DownTo 1 Do SelectNext(False);
    End;
    DisposeStr(Path);
  End;

  Procedure TGroupWindow.Store(Var S: TStream);
  Var
    P: PString;
    I: Integer;
  Begin
    P:=NewStr(Group^.GetGroupPath);
    S.WriteStr(P);
    S.WriteStr(Group^.Name.P);
    S.Write(Origin, SizeOf(Origin));
    I:=Group^.MenuItems^.IndexOf(PMenuButton(Current)^.MenuItem);
    S.Write(I, SizeOf(I));
    DisposeStr(P);
  End;

  Function LoadMenu;
  Var S: TBufStream;
  Begin
    S.Init(FName, stOpen, 1024);
    If S.Status<>stOk Then
    Begin
      LoadMenu:=False;
      InfoPtr:=@FName;
      MessageBox(GetMsg(sMenuReadError), @InfoPtr, mfError+mfOkButton);
      P:=New(PGroupItem, Init);
      P^.SetName(GetMsg(sMainGroup));
      StoreMenu(P, FName);
    End Else
    Begin
      LoadMenu:=True;
      P:=PGroupItem(S.Get);
    End;
    S.Done;
    P^.Owner:=Nil;
    MainMenu:=P;
  End;

  Procedure StoreMenu;
  Var S: TBufStream;
  Begin
    S.Init(FName, stCreate, 1024);
    S.Put(P);
    S.Done;
    If S.Status<>stOk Then
    Begin
      InfoPtr:=@FName;
      MessageBox(GetMsg(sMenuWriteError), @InfoPtr, mfError+mfOkButton);
    End;
  End;

  Procedure EditMainGroup;
  Var
    Dlg: PDialog;
    Cmd: Word;
    Redraw: Boolean;
    Data: Record
      N: String[20];
      C: LongInt;
    End;
  Begin
    Dlg:=PDialog(GetRez('MainGroupEditDialog'));
    If Dlg<>Nil Then
    Begin
      Data.N:=MainMenu^.GetName;
      Data.C:=MainMenu^.Cols;
      Dlg^.SetData(Data);
      Cmd:=DeskTop^.ExecView(Dlg);
      If Cmd=cmOk Then With MainMenu^ Do
      Begin
        Dlg^.GetData(Data);
        EditChanged:=True;
        SetName(Data.N);
        Cols:=Data.C;
        Message(DeskTop, evBroadcast, cmRedrawMenu, MainMenu);
      End;
      Dispose(Dlg, Done);
    End;
  End;

End.