Unit PchOvr1;
{$I PCHSYM.PAS}
{$O+,F+}
Interface

  Procedure ContactLowLevel;
  Procedure WaitForEvent;
  Procedure RegisterTypes;
  Procedure InitResource;
  Procedure InitVars;

Implementation
  Uses
    Crt, Dos, Objects, Drivers, Views, Menus, Dialogs,
    AsciiTab, HelpFile, Fields, ColorSel, HintStat, Calc,
    DateUtl, StrObj, TextObj, Editor,
    PchGlb, PchDos, PchMenu, PchPW, PchTetris;

  Procedure Ok(N: Byte);
  Begin
    PrintStr('Ok'+Char(N+Ord('0'))+#10#13);
  End;

  Procedure RegisterTypes;
  Begin
    RegisterObjects;
    RegisterViews;
    RegisterType(RStringList);
    RegisterType(RStr);
    RegisterType(RDate);
    RegisterType(RTextBlock);
    { DIALOGS }
    RegisterType(RButton);
    RegisterType(RCheckBoxes);
    RegisterType(RCluster);
    RegisterType(RDialog);
    RegisterType(RInputLine);
    RegisterType(RLabel);
    RegisterType(RListBox);
    RegisterType(RParamText);
    RegisterType(RRadioButtons);
    RegisterType(RStaticText);
    { MENUS }
    RegisterType(RMenuBar);
    RegisterType(RMenuBox);
    { HINTSTAT }
    RegisterType(RHintStatusLine);
    { FIELDS }
    RegisterType(RKeyInputLine);
    RegisterType(RIntInputLine);
    RegisterType(RRealInputLine);
    { HELPFILE }
    RegisterType(RHelpTopic);
    RegisterType(RHelpIndex);
    { ASCII }
    RegisterType(RTable);
    RegisterType(RReport);
    RegisterType(RASCIIChart);
    { CALC }
    RegisterType(RCalcDisplay);
    RegisterType(RCalculator);
    { EDITOR }
    RegisterType(RMemoEdit);
    { PCHDOS }
    RegisterType(RDosIndicator);
    RegisterType(RDosInterior);
    RegisterType(RDosShell);
    { PCHMENU }
    RegisterType(RMenuItem);
    RegisterType(RDosItem);
    RegisterType(RGroupItem);
    RegisterType(RGroupWindow);
    { PCHTETRIS }
    RegisterType(RFieldView);
    RegisterType(RInfoView);
    RegisterType(RTetris);
  End;

  Procedure ContactLowLevel;
  Begin
    GetIntVec($60, Pointer(LowLevel));
    If LowLevel^.ID<>'PCH300' Then
    Begin
      PrintStr('Low level driver not installed or not found.'#13#10);
      PrintStr('Program halted.'#13#10);
      Halt(1);
    End;
  End;

  Procedure WaitForEvent;
  Var Mouse, MouseThere: Boolean;
  Begin
    Mouse:=False;
    MouseThere:=False;
    Asm
      Mov AX, 0
      Int $33
      Cmp AX, -1
      Jne @NoMouse
      Mov MouseThere, True
     @NoMouse:
    End;
    PrintStr(#10#13'Beliebige (Maus-)Taste zur Wiederaufnahme von Power-Choice drücken !');
    Repeat
      If MouseThere Then
      Asm
        Mov AX, 3
        Int $33
        Cmp BX, 0
        Je @NoButton
        Mov Mouse, True
       @NoButton:
      End;
    Until KeyPressed Or Mouse;
    If KeyPressed Then ReadKey;
  End;

  Procedure InitResource;
  Begin
    RezFile.Init(New(PBufStream, Init(EXEName, stOpen, 1024)));
    If RezFile.Stream^.Status<>0 Then
    Begin
      PrintStr(EXEName+' is not containing ressources.'#13#10);
      PrintStr('Program halted.'#13#10);
      Halt(1);
    End;
  End;

  Procedure InitVars;
  Begin
    QuickMem:=0;
    ReCalcMem;
    NormalMem:=(PtrRec(HeapEnd).Seg-PrefixSeg) Shr 6;
    UserFileName:=NewStr(PchPath+'USER'+Chr(64+LowLevel^.Password));
  End;

End.