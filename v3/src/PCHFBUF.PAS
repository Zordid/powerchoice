Unit PchFBuf;
{$I PCHSYM.PAS}
{$I-,O+,F+}
Interface
  Uses Objects;

  Type
    PFileBuffer= ^TFileBuffer;
    TFileBuffer= Object(TCollection)
      UsedMem: LongInt;
      Procedure ReadFile(FName: String);
      Function FileInBuffer(Var FName: String): Boolean;
      Procedure ClearBuffer;
      Function Used: LongInt;
      Function Free: LongInt;
    End;

Implementation
  Uses Dos, DosTools, Memory, GlbMem;

  Type
    PFile= ^TFile;
    TFile= Object(TObject)
      FName: PString;
      Attrib: Byte;
      Size, Time: LongInt;
      Buffer: PMemDesc;
      Constructor Init(Var AFile: String);
      Destructor Done; virtual;
    End;

  Constructor TFile.Init(Var AFile: String);
  Const
    MaxBuf= 65535;
  Var
    F: File;
    S: LongInt;
    N, C: PMemDesc;
    P: Pointer;
  Begin
    TObject.Init;
    Assign(F, AFile);
    Reset(F, 1);
    If IOResult<>0 Then Fail;
    P:=MemAlloc(MaxBuf);
    If P=nil Then Fail;
    Size:=FileSize(F);
    S:=Size;
    C:=nil;
    While S>0 Do
    Begin
      If S>MaxBuf Then
      Begin
        N:=GetMemory(MaxBuf, mtAny);
        BlockRead(F, P^, MaxBuf);
        N^.PutData(P^, MaxBuf);
        Dec(S, MaxBuf);
      End Else
      Begin
        N:=GetMemory(S, mtAny);
        BlockRead(F, P^, S);
        N^.PutData(P^, S);
        S:=0;
      End;
      If N<>nil Then
      Begin
        If C=nil Then Buffer:=N Else C^.Next:=N;
        C:=N;
      End Else
      Begin
        Done;
        Fail;
      End;
    End;
    FName:=NewStr(AFile);
  End;

  Destructor TFile.Done;
  Begin
    If Buffer<>nil Then Dispose(Buffer, Done);
    DisposeStr(FName);
    TObject.Done;
  End;

  Procedure TFileBuffer.ReadFile(FName: String);
  Var F: PFile;
  Begin
    F:=New(PFile, Init(FName));
    If F<>nil Then
    Begin
      Insert(F);
      Inc(UsedMem, F^.Size);
    End;
  End;

  Function TFileBuffer.FileInBuffer(Var FName: String): Boolean;
  Begin

  End;

  Procedure TFileBuffer.ClearBuffer;
  Begin
    FreeAll;
  End;

  Function TFileBuffer.Used: LongInt;
  Begin
    Used:=UsedMem;
  End;

  Function TFileBuffer.Free: LongInt;
  Begin
    Free:=FreeMemory(mtRAM);
  End;

End.