{$I PCHSYM.PAS}
{$M 16384,8192,655360}
Program Power_Choice;
Uses
  InitOvr, 
  { TP units: }
  Overlay, StrUtl, StrObj, DateUtl, DosTools,
  { Turbo Vision units: }
  Objects, Drivers, Views, Menus, Dialogs, App, MsgBox, StdDlg, Editor,
  HelpFile, Fields, AsciiTab, HistList, HintStat, ColorSel, Calc,
  { Power-Choice units: }
  PchGlb, PchCmds, PchHelp, PchOpt, PchMsg, PchPW, PchRun, PchOvr1,
  PchDos, PchMenu, PchFunc, PchTools, PchTetris;

{$O Menus}
{$O StdDlg}
{$O MsgBox}
{$O HistList}
{$O ColorSel}
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
    {Clock: PClockView;}
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

Var
  Pchoice: TPchoiceApp;

Constructor TPchoiceApp.Init;
Var
  H: Word;
  S: String;
Begin
  { Detect Low-Level driver }
  With LowLevel^ Do
  Begin
    If Booted Then
      PrintStr(#10#13' Power-Choice Version 3.01  (c) Copyright 1990-93 by Olaf Gottschalk'#10#13);
    If WaitForKey Then WaitForEvent;
    Clock:=0;
    ScrSaver:=True;
  End;
  CopyVideo2Buf;          { Save video memory }
  RegisterTypes;          { Register object types }
  InitResource;           { Init resource file }
  InitVars;               { Init variables }
  TApplication.Init;      { Init the application }
  {Clock:=Nil;}             { Set Clock to Nil }
  DisableCommands(EditCommands);
  With LowLevel^ Do
  Begin
    InitUserSystem;
    { Load menu+desktop }
    If LoadMenu(MainMenu, PchPath+MenuFileName) Then
    Begin
      If Booted Then
      Begin
        If FileExists(UserFileName^+'.DSK') Then LoadDeskTop Else ClearDeskTop;
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
      DeskTop^.ExecView(PDialog(GetRez('AboutDialog')));
    Booted:=False;
  End;
End;

Procedure TPchoiceApp.InitMenuBar;
Begin
  If LowLevel^.Password=0 Then
    MenuBar := PMenuBar(GetRez('MainMenuBar'))
  Else
    MenuBar := PMenuBar(GetRez('UserMenuBar'));
End;

Procedure TPchoiceApp.InitStatusLine;
Begin
  GetHintStr := GetMenuHint;
  StatusLine := PHintStatusLine(GetRez('StatusLine'));
End;

Procedure TPchoiceApp.GetEvent(Var Event: TEvent);
Var Mouse: Word;
Begin
  TApplication.GetEvent(Event);
  If (Event.What=evCommand) And (Event.Command=cmHelp) Then
  Begin
    {
    If Not ShowHelp(PchPath+HelpFileName) Then
      MessageBox(GetMsg(sHelpFileNotFound), nil, mfError+mfOkButton);
    ClearEvent(Event);
    }
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
        cmColors: ChangeColors;
        cmUserList: EditUserList;
        cmEditMainGroup: EditMainGroup;
        cmAscii: Ascii;
        cmCalc: Calculator;
        cmChangeDir: ChangeDir;
        cmDosShell: DosShell;
        cmChangePassword: ChangeUserPassword;
        cmCleanDisk: CleanDisk;
        cmTetris: Tetris;
        cmReset:
          Begin
            StoreDeskTop;
            RezFile.Done;
            ResetComputer;
          End;
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
Var
  R: TRect;
  E: TEvent;
Begin
  TApplication.Idle;
  {
  If Clock=Nil Then
  Begin
    R.Assign(71, 0, 80, 1);
    Clock:=New(PClockView, Init(R));
    Insert(Clock);
  End;
  Clock^.Update;
  }
  If ReCalcMem Then
    Message(DeskTop, evBroadcast, cmRedrawMem, nil);
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

Begin
  ContactLowLevel;
  Pchoice.Init;
  Pchoice.Run;
  Pchoice.Done;
End.