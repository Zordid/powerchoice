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
    AsciiTab, HelpFile, Fields, HintStat, Calc, DosTools,
    DateUtl, StrObj, TextObj, Editor,
    PchGlb, PchDos, PchMenu, PchPW, PchTetris,
    Messages;

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
    RegisterType(RNumInputLine);
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
    If LowLevel^.ID<>'PCH310' Then
    Begin
      PrintStr(errLL_not_loaded);
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
    PrintStr(msgPress_any_key);
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
    RezFile.Init(New(PBufStream, Init(PchPath+RezFileName, stOpen, 1024)));
    If (RezFile.Stream^.Status<>0) Or (RezFile.Count=0) Then
    Begin
      PrintStr(errNo_resources);
      Halt(1);
    End;
  End;

  Procedure InitVars;
  Begin
    QuickMem:=0;
    ReCalcMem;
    NormalMem:=(PtrRec(HeapEnd).Seg-PrefixSeg) Shr 6;
  End;

End.