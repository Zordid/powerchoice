{$I PCHSYM.PAS}
Unit PchGlb;
Interface
  Uses Objects, PchCmds;

  Type
    TSysOptions= Record
      DisplayLines: Word;
      AutoClose: Word;
    End;
    TDosOptions= Record
      DosShellOpt: Word;
      Prompt: String[10];
      DosOpt: Word;
    End;
    TScreen= Array[0..24, 0..79] Of Word;
    PLowLevel= ^TLowLevel;
    TLowLevel= Record
      IRET: Byte;
      ID: String[6];
      Clock: Byte;
      ScrSaver,
      WaitForKey,
      Booted: Boolean;
      Password: String[15];
    End;

  Const
    SysOptions: TSysOptions=
      (DisplayLines: 0; AutoClose: 1);
    DosOptions: TDosOptions=
      (DosShellOpt: 2; Prompt: '%s>'; DosOpt: 3);

    { Optionen }
    OptionsArea: String[11]= 'OPTIONSAREA';
    PchPath: String[40]= 'C:\PCHOICE\';
    UserPath: String[40]= 'C:\PCHOICE\';
    BatchFileName: String[40]= 'C:\PCHOICE\PCH.BAT';
    PWFileName: String[40]= 'C:\PCHOICE\PCHPW.SYS';
    { weitere Konstanten }
    HelpFileName= 'PCHHELP.HLP';
    MenuFileName= 'PCHOICE.MNU';
    ExeFileName = 'PCHOICE.EXE';
    RezFileName = 'PCHOICE.EXE';
    {$IFNDEF IDE}
    OvrFileName = 'PCHOICE.EXE';
    DeskFileName= 'PCHOICE.DSK';
    {$ELSE}
    OvrFileName = 'PCHOICE.OVR';
    DeskFileName= 'PCHIDE.DSK';
    {$ENDIF}
    Editing: Boolean= False;
    UpdateHint: Boolean= False;
    EditCommands: Set Of Byte= [cmNewMenuItem, cmEditMainGroup];
    OldPathGlb: PString= Nil;
    ToPrintGlb: PString= Nil;

  Var
    RezFile: TResourceFile;
    LowLevel: PLowLevel;
    OldScreen: TScreen;
    OldPos: Word;
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
    Overlay, Drivers, Memory, StrUtl, Views, App, MsgBox,
    PchHelp, PchMenu;

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
        StrMove(Hint, GlbHint^.Get(Ctx));
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