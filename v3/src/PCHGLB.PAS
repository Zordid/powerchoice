{$I PCHSYM.PAS}
Unit PchGlb;
Interface
  Uses Objects, PchCmds;

  Type
    TSysOptions= Record
      AutoClose: Boolean;
    End;
    TDosOptions= Record
      Opt: Word;
      Prompt: String[10];
      Quick: Word;
      AutoCD: Word;
    End;
    TScreen= Array[0..24, 0..79] Of Word;
    PLowLevel= ^TLowLevel;
    TLowLevel= Record
      IRET: Byte;
      ID: String[6];
      Password,
      Clock: Byte;
      ScrSaver,
      WaitForKey,
      Booted,
      EnableEdit,
      EnableDos: Boolean;
    End;

  Const
    CustomColors: Boolean= False;
    SysOptions: TSysOptions=
      (AutoClose: True);
    DosOptions: TDosOptions=
      (Opt: 3; Prompt: '%s>'; Quick: 0; AutoCD: 1);

    { Optionen }
    OptionsArea: String[7]= 'OPTIONS';
    AskMainPW: Boolean= True;
    PchPath: String[80]= 'C:\PCHOICE\';
    BatchFileName: String[15]= 'C:\PCH.BAT';
    MenuFileName: String[12]= 'PCHOICE.MNU';
    { weitere Konstanten }
    HelpFileName= 'PCHHELP.HLP';
    Editing: Boolean= False;
    UpdateHint: Boolean= False;
    EditCommands: Set Of Byte= [cmNewMenuItem, cmEditMainGroup, cmChangeOrder];
    OldPathGlb: PString= Nil;
    ToPrintGlb: PString= Nil;

  Var
    EXEName: String[80];
    RezFile: TResourceFile;
    LowLevel: PLowLevel;
    OldScreen: TScreen;
    OldPos: Word;
    UserFileName: PString;
    QuickMem,
    NormalMem: LongInt;
    SavePathGlb,
    ClockGlb,
    ScrSaverGlb,
    WaitforKeyGlb: Boolean;
    InfoPtr: Pointer;

  Function GetWinNumber: Byte;
  Function ReCalcMem: Boolean;
  Procedure RememberOldPath(On: Boolean);
  Procedure QuitToDos;
  Function GetRez(Key: String): PObject;
  Function GetMsg(No: Word): String;
  Procedure GetMenuHint(Ctx: Word; Var Hint: String);
  Procedure CopyVideo2Buf;
  Procedure CopyBuf2Video;

Implementation
  Uses
    Overlay, Drivers, Memory, StrUtl, Views, App, MsgBox, PchHelp, PchMenu;

  Const
    GlbMsg: PStringList= Nil;
    GlbHint: PStringList= Nil;

  Procedure QuitToDos;
  Var Event: TEvent;
  Begin
    Event.What:=evCommand;
    Event.Command:=cmQuit;
    Application^.PutEvent(Event);
  End;

  Function GetRez(Key: String): PObject;
  Var P: PObject;
      Data: Pointer;
  Begin
    If Not LowMemory Then
    Begin
      P:=RezFile.Get(Key);
      If P=Nil Then
      Begin
        Data:=@Key;
        MessageBox('Resource "%s" not found!', @Data, mfError+mfOkButton);
      End;
      P:=Application^.ValidView(PView(P));
    End Else
    Begin
      Application^.OutOfMemory;
      P:=Nil;
    End;
    GetRez:=P;
  End;

  Function GetMsg(No: Word): String;
  Var
    S: String;
    L: LongInt;
  Begin
    If GlbMsg=Nil Then
      GlbMsg:=PStringList(RezFile.Get('Messages'));
    GetMsg:='';
    If GlbMsg<>Nil Then
    Begin
      S:=GlbMsg^.Get(No);
      GetMsg:=S;
      If S='' Then
      Begin
        L:=No;
        MessageBox('String #%d not found!', @L, mfError+mfOkButton);
      End;
    End Else
      MessageBox('Stringlist resource not found!', nil, mfError+mfOkButton);
  End;

  Procedure GetMenuHint(Ctx: Word; Var Hint: String);
  Var Button: PView;
  Begin
    Hint:='';
    If Ctx<>hcMenuPage Then
    Begin
      If GlbHint=Nil Then
        GlbHint:=PStringList(RezFile.Get('Hints'));
      If GlbHint<>Nil Then
        StrMove(Hint, GlbHint^.Get(Ctx-hcMenuStart));
    End Else
    Begin
      Button:=PGroupWindow(DeskTop^.Current)^.Current;
      If (Button<>nil) And (TypeOf(Button^)=TypeOf(TMenuButton)) Then
        StrMove(Hint, PMenuButton(Button)^.MenuItem^.Hint.GetPtr^);
    End;
  End;

  Procedure RememberOldPath(On: Boolean);
  Var S: String;
  Begin
    SavePathGlb:=On;
    GetDir(0, S);
    DisposeStr(OldPathGlb);
    OldPathGlb:=NewStr(S);
  End;

  Function ReCalcMem: Boolean; assembler;
  Const
    OldHeap: Word= 0;
  Asm
    Mov AX, word ptr HeapPtr+2
    Cmp AX, word ptr OldHeap
    Jne @Calc
    Xor AX, AX
    Jmp @OK
   @Calc:
    Mov word ptr OldHeap, AX
    Mov BX, word ptr HeapEnd+2
    Sub BX, AX
    Mov CL, 6
    Shr BX, CL
    Mov word ptr QuickMem, BX
    Mov AX, True
   @OK:
  End;

  Function GetWinNumber: Byte;
  Var TestNum: Byte;

    Function CheckNumber(P: PView): Boolean; far;
    Begin
      CheckNumber:=(PWindow(P)^.Frame^.Owner=PGroup(P)) And (PWindow(P)^.Number=TestNum);
    End;

  Begin
    TestNum:=1;
    While (TestNum<=10) And (DeskTop^.FirstThat(@CheckNumber)<>nil) Do Inc(TestNum);
    If TestNum=11 Then
      GetWinNumber:=wnNoNumber
    Else
      GetWinNumber:=TestNum;
  End;

  Procedure CopyBuf2Video;
  Var Video: Pointer;
  Begin
    If Mem[$0040:$0049]=7 Then Video:=Ptr($B000, 0) Else Video:=Ptr($B800, 0);
    Move(OldScreen, Video^, 4000);
    Asm
      mov ah, 2
      mov bh, 0
      mov dx, OldPos
      int $10
    End;
  End;

  Procedure CopyVideo2Buf;
  Var Video: Pointer;
  Begin
    PrintStr(#10#13);
    If Mem[$0040:$0049]=7 Then Video:=Ptr($B000, 0) Else Video:=Ptr($B800, 0);
    Move(Video^, OldScreen, 4000);
    Asm
      mov ah, 3
      mov bh, 0
      int $10
      mov OldPos, dx
    End;
  End;

End.