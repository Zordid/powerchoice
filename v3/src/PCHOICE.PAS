{$I PCHSYM.PAS}
{$M 16384,8192,655360}
Program Power_Choice;
Uses
  InitOvr,
  { TP units: }
  Overlay, StrUtl, StrObj, DateUtl, DosTools,
  { Turbo Vision units: }
  Objects, Drivers, Views, Menus, Dialogs, App, MsgBox, StdDlg, Editor,
  HelpFile, Fields, AsciiTab, HistList, HintStat, Calc, Gadgets,
  { Power-Choice units: }
  PchGlb, PchCmds, PchHelp, PchOpt, PchMsg, PchPW, PchRun, PchOvr1,
  PchDos, PchMenu, PchFunc, PchTools, PchTetris, PchReg,
  Messages;

{$O Menus}
{$O StdDlg}
{$O MsgBox}
{$O HistList}
{$O Fields}
{$O HelpFile}
{$O AsciiTab}
{$O Calc}
{$O DosTools}
{$O Editor}
{$O PchDos}
{$O PchPW}
{$O PchOpt}
{$O PchRun}
{$O PchFunc}
{$O PchOvr1}
{$O PchTools}
{$O PchTetris}

Type
  PPchoiceApp= ^TPchoiceApp;
  TPchoiceApp= Object(TApplication)
    {$IFDEF DEBUG}
    Heap: PHeapView;
    {$ELSE}
    Clock: PClockView;
    {$ENDIF}
    MainMenu: PGroupItem;
    Constructor Init;
    Procedure InitMenuBar; virtual;
    Procedure InitStatusLine; virtual;
    Procedure GetEvent(Var Event: TEvent); virtual;
    Procedure HandleEvent(Var Event: TEvent); virtual;
    Function GetPalette: PPalette; virtual;
    Procedure OutOfMemory; virtual;
    Procedure Idle; virtual;
    Destructor Done; virtual;
  End;

Constructor TPchoiceApp.Init;
Var
  R: TRect;
  H: Word;
  S: String;
Begin
  ContactLowLevel;
  With LowLevel^ Do
  Begin
    If Booted Then PrintStr(msgTitle);
    If WaitForKey Then WaitForEvent;
    Clock:=0;
    ScrSaver:=True;
  End;
  CopyVideo2Buf;          { Save video memory }
  RegisterTypes;          { Register object types }
  InitResource;           { Init resource file }
  InitVars;               { Init variables }
  TApplication.Init;      { Init the application }
  R.Assign(71, 0, 80, 1);
  {$IFDEF DEBUG}
  Heap:=New(PHeapView, Init(R));
  Insert(Heap);
  {$ELSE}
  Clock:=New(PClockView, Init(R));
  Insert(Clock);
  {$ENDIF}
  DisableCommands(EditCommands);
  With LowLevel^ Do
  Begin
    { Load menu+desktop }
    If LoadMenu(MainMenu, PchPath+MenuFileName) Then
    Begin
      If Booted Then
      Begin
        If FileExists(PchPath+DeskFileName) Then LoadDeskTop Else ClearDeskTop;
        SavePathGlb:=True;
      End Else LoadDeskTop;
    End Else ClearDeskTop;
    If SavePathGlb And (OldPathGlb<>Nil) Then
    Begin
      If Not (Booted And (OldPathGlb^[1]<='B')) Then
      Begin
        ChDir(OldPathGlb^);
        If (IOResult<>0) And (Not Booted) Then
          MessageBox(GetMsg(sDirNotFound), @OldPathGlb, mfError+mfOkButton);
        Message(DeskTop, evBroadcast, cmRedrawPrompt, nil);
      End;
    End;
    If Booted Then
    Begin
      SetScreenSaverPassword;
      About;
    End;
    Booted:=False;
  End;
End;

Procedure TPchoiceApp.InitMenuBar;
Begin
  MenuBar:=PMenuBar(GetRez('MenuBar'))
End;

Procedure TPchoiceApp.InitStatusLine;
Begin
  GetHintStr := GetMenuHint;
  StatusLine := PHintStatusLine(GetRez('StatusLine'));
End;

Procedure TPchoiceApp.GetEvent(Var Event: TEvent);
Begin
  TApplication.GetEvent(Event);
  If (Event.What=evCommand) And (Event.Command=cmHelp) Then
  Begin
    If Not ShowHelp(PchPath+HelpFileName, GetHelpCtx) Then
      MessageBox(GetMsg(sHelpFileNotFound), nil, mfError+mfOkButton);
    ClearEvent(Event);
  End;
End;

Procedure TPchoiceApp.HandleEvent(Var Event: TEvent);
Begin
  TApplication.HandleEvent(Event);
  With Event Do
  Begin
    If What=evCommand Then
    Begin
      Case Command Of
        cmAbout: About;
        cmClearDeskTop: ClearDeskTop;
        cmDos: Dos;
        cmEditmode: Editmode;
        cmDosOptions: SetDosOptions;
        cmSysOptions: SetSysOptions;
        cmEditMainGroup: EditMainGroup;
        cmAscii: Ascii;
        cmCalc: Calculator;
        cmChangeDir: ChangeDir;
        cmDosShell: DosShell;
        cmChangePassword: ChangeUserPassword;
        cmCleanDisk: CleanDisk;
        cmTetris: Tetris;
        Else Exit;
      End;
      ClearEvent(Event);
    End;
  End;
End;

Function TPchoiceApp.GetPalette: PPalette;
Const       {  1-63      64-71         72-76           77-86          87-88   }
  CNewColor = CColor + CHelpColor + CDosShellColor + CGroupColor;
  CNewBlackWhite = CBlackWhite + CHelpBlackWhite + CDosShellBlackWhite + CGroupBlackWhite;
  CNewMonochrome = CMonochrome + CHelpMonochrome + CDosShellMonochrome + CGroupMonochrome;
  P: Array[apColor..apMonochrome] Of String[Length(CNewColor)] =
    (CNewColor, CNewBlackWhite, CNewMonochrome);
Begin
  GetPalette := @P[AppPalette];
End;

Procedure TPchoiceApp.OutOfMemory;
Begin
  MessageBox(GetMsg(sOutOfMemory), nil, mfError+mfOkButton);
End;

Procedure TPchoiceApp.Idle;
Var E: TEvent;
Begin
  TApplication.Idle;
  {$IFDEF DEBUG}
  Heap^.Update;
  {$ELSE}
  Clock^.Update;
  {$ENDIF}
  If ReCalcMem Then Message(DeskTop, evBroadcast, cmRedrawMem, nil);
  If TypeOf(DeskTop^.Current^)=TypeOf(TTetris) Then
  Begin
    E.What:=evCommand;
    E.Command:=cmDown;
    PutEvent(E);
  End;
  If UpdateHint Then
  Begin
    UpdateHint:=False;
    StatusLine^.Draw;
  End;
End;

Destructor TPchoiceApp.Done;
Begin
  StoreDeskTop;
  TApplication.Done;
  RezFile.Done;
  With LowLevel^ Do
  Begin
    If ClockGlb Then Clock:=$FF;
    ScrSaver:=ScrSaverGlb;
    WaitforKey:=WaitforKeyGlb;
  End;
  CopyBuf2Video;
  If ToPrintGlb<>Nil Then 
  Begin
    PrintStr(ToPrintGlb^);
    DisposeStr(ToPrintGlb);
  End;
End;

Var Pch: TPchoiceApp;

Begin
  Pch.Init;
  Pch.Run;
  Pch.Done;
End.