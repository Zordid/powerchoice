Unit PchRun;
{$I PCHSYM.PAS}
{$I-,F+,O+}
Interface
  Uses Objects, TextObj;

  Const
    PathNotFound   = 1;
    BatchFileError = 2;

  Var
    ExecResult: Integer;
    Cancel: Boolean;

  Procedure ResetBatchFile;
  Function OpenBatchFile(Var S: TBufStream): Boolean;
  Procedure CloseBatchFile(Var S: TBufStream);
  Procedure WriteBatchFile(Var S: TBufStream; K: String);
  Procedure DosExec(Path: String; CmdLines: PTextBlock; Quick: Boolean);

Implementation
  Uses
    Dos, Drivers, Memory, Views, App,
    StrObj, StrUtl, MsgBox, PchGlb, PchCmds, PchMsg, PchOvr1;

  Function OpenBatchFile(Var S: TBufStream): Boolean;
  Var K: String;
  Begin
    S.Init(BatchFileName, stCreate, 512);
    K:='ECHO OFF'#13#10':$AGAIN'#13#10+ParamStr(0)+#13#10;
    S.Write(K[1], Length(K));
    OpenBatchFile:=S.Status=0;
    If S.Status<>0 Then S.Done;
  End;

  Procedure WriteBatchFile(Var S: TBufStream; K: String);
  Begin
    If K<>'' Then
    Begin
      StrCat(K, #13#10, 255);
      S.Write(K[1], Length(K));
    End;
  End;

  Procedure CloseBatchFile(Var S: TBufStream);
  Var K: String[20];
  Begin
    K:='GOTO $AGAIN'#13#10;
    S.Write(K[1], Length(K));
    S.Done;
  End;

  Procedure DosExec(Path: String; CmdLines: PTextBlock; Quick: Boolean);
  Var
    S: TBufStream;
    I: Integer;
  Begin
    ExecResult:=0;
    If (CmdLines<>nil) And (Not CmdLines^.Empty) Then
    Begin
      If Path<>'' Then
      Begin
        ChDir(Path);
        If IOResult<>0 Then
        Begin
          ExecResult:=PathNotFound;
          Exit;
        End;
      End;
      If Quick And (QuickMem>60) Then
      Begin
        DoneSysError;
        DoneEvents;
        DoneVideo;
        DoneMemory;
        CopyBuf2Video;
        If ToPrintGlb<>nil Then
        Begin
          PrintStr(ToPrintGlb^);
          DisposeStr(ToPrintGlb);
          ToPrintGlb:=nil;
        End;
        With LowLevel^ Do
        Begin
          If ClockGlb Then Clock:=$FF;
          ScrSaver:=ScrSaverGlb;
        End;
        SetMemTop(HeapPtr);
        SwapVectors;
        For I:=0 To CmdLines^.Count-1 Do If CmdLines^.GetLine(I)^<>'' Then
          Exec(GetEnv('COMSPEC'), '/C'+CmdLines^.GetLine(I)^);
        SwapVectors;
        SetMemTop(HeapEnd);
        If WaitForKeyGlb Then WaitForEvent;
        With LowLevel^ Do
        Begin
          Clock:=0;
          ScrSaver:=True;
        End;
        CopyVideo2Buf;
        InitMemory;
        InitVideo;
        InitEvents;
        InitSysError;
        Application^.Redraw;
        If DosError<>0 Then ExecResult:=-DosError;
        If SavePathGlb Then
        Begin
          ChDir(OldPathGlb^);
          InOutRes:=0;
        End;
        Message(DeskTop, evBroadcast, cmRedrawPrompt, nil);
      End Else
      Begin
        If OpenBatchFile(S) Then
        Begin
          For I:=0 To CmdLines^.Count-1 Do If CmdLines^.GetLine(I)^<>'' Then
	    WriteBatchFile(S, 'call '+CmdLines^.GetLine(I)^);
          CloseBatchFile(S);
          QuitToDos;
        End Else
          ExecResult:=BatchFileError;
      End;
    End;
    Case ExecResult Of
      0: ;
      -2, -3:
        MessageBox(GetMsg(sMSDOSNotFound), nil, mfError+mfOkButton);
      -8:
        Application^.OutOfMemory;
      BatchFileError:
        MessageBox(GetMsg(sBatchFileError), @BatchFileName, mfError+mfOkButton);
      Else MessageBox(GetMsg(sMSDOSError), nil, mfError+mfOkButton);
    End;
  End;

  Procedure ResetBatchFile;
  Var S: TBufStream;
  Begin
    OpenBatchFile(S);
    S.Done;
  End;

End.