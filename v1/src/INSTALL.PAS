{$A+,B-,D+,E-,F-,I-,L+,N-,O-,R+,S+,V-}
Unit Install;
Interface
  Uses Dos,Crt,Graph;
  Const Installed = 1;
        None      = 0;
        TextDisp  = -2;
        CGA       = 1;
        MCGA      = 2;
        EGA       = 3;
        EGA64     = 4;
        EGAMono   = 5;
        IBM8514   = 6;
        HercMono  = 7;
        ATT400    = 8;
        VGA       = 9;
        PC3270    = 10;

  Type MemoryType = Record
                      Total : Word;
                      Free  : Word;
                    End;

  Var Autoexec,Config : PathStr;
      Drives          : Byte;
      Videoboard      : Integer;
      Mouse,
      Serial,Parallel,
      Gameport        : Byte;
      Memory,ExtMemory,
      ExpMemory       : MemoryType;
      EMMVersion      : String[4];
      Result          : Word;

  Procedure DetectHardware;
  Procedure DetectMemory;
  Function  CheckDos(MustVersion:Word):Boolean;
  Procedure UnArc(FileName:PathStr;Drive:Char);
  Procedure Find_Autoexec;

Implementation
  Var Regs : Registers;

Procedure ReadBytes(Var F:File;Var B;C:Word);
Begin
  With Regs Do
  Begin
    BX:=FileRec(F).Handle;
    CX:=C;
    DS:=Seg(B);
    DX:=Ofs(B);
    AH:=63;
  End;
  MsDos(Regs);
End;

Procedure WriteBytes(Var F:File;Var B;C:Word);
Begin
  With Regs Do
  Begin
    BX:=FileRec(F).Handle;
    CX:=C;
    DS:=Seg(B);
    DX:=Ofs(B);
    AH:=64;
  End;
  MsDos(Regs);
End;

Procedure UnArc(FileName:PathStr;Drive:Char);
Label Done;
Type InfoType = Record
                  ID   : String[4];
                  Name : String[12];
                  Len  : LongInt;
                End;

Var Source,Dest : File;
    Info        : InfoType;
    Files,Act   : Byte;
    Buffer      : Pointer;
    BSize       : Word;
    CH          : Char;

Begin
  Result:=0;
  BSize:=64*1024-1;  { 64 KBytes }
  If MaxAvail<BSize Then
  Begin
    Result:=3;
    Goto Done;
  End;
  GetMem(Buffer,BSize);
  Assign(Source,FileName);
  Reset(Source);
  If IOResult<>0 Then
  Begin
    Result:=1;
    Exit;
  End;
  ReadBytes(Source,Files,1);
  If Regs.AX<>1 Then
  Begin
    Result:=1;
    Goto Done;
  End;
  Act:=0;
  While (Not EoF(Source)) And (Act<Files) Do
  Begin
    ClrEol;
    Write(' Reading ',FileName,' . . .'#13);
    Inc(Act);
    ReadBytes(Source,Info,22);
    If (Regs.AX<>22) Or (Info.ID<>'NexT') Then
    Begin
      Result:=1;
      Goto Done;
    End;
    ReadBytes(Source,Buffer^,Info.Len);
    If (Regs.AX<>Info.Len) Then
    Begin
      Result:=2;
      Goto Done;
    End;
    ClrEol;
    Write(' Writing ',Drive,':',Info.Name,' . . .'#13);
    Assign(Dest,Drive+':'+Info.Name);
    Rewrite(Dest);
    If IOResult<>0 Then
    Begin
      Result:=2;
      Goto Done;
    End;
    WriteBytes(Dest,Buffer^,Info.Len);
    Close(Dest);
    If (Regs.AX<>Info.Len) Or (IOResult<>0) Then
    Begin
      Result:=2;
      Goto Done;
    End;
  End;
  If Act<>Files Then Result:=1;
  Done:
  Close(Source);
  Close(Dest);
  FreeMem(Buffer,Bsize);
  BSize:=IOResult;
  ClrEol;
  Case Result Of 1 : Write(' Error reading source file.'#13);
                 2 : Write(' Error writing destination file.'#13);
                 3 : Write(' Error - not enough memory.'#13);
  End;
End;

Function CheckDos(MustVersion:Word):Boolean;
Var Version : Word;
Begin
  Version:=DosVersion;
  CheckDos:=( (Lo(Version)>Hi(MustVersion)) Or
             ((Lo(Version)=Hi(MustVersion)) And (Hi(Version)>=Lo(MustVersion))));
End;

Procedure DetectHardware;
Var A : Integer;
Begin
  { Get video board type }
  DetectGraph(Videoboard,A);
  { Check for mouse }
  Regs.AX:=0;
  Intr($33,Regs);
  If Regs.BX<>0 Then Mouse:=Installed Else Mouse:=None;
  { Read more hardware settings }
  Intr($11,Regs);
  Parallel  :=Regs.AX Shr 14;
  Serial    :=(Regs.AX Shl 4) Shr 13;
  Gameport  :=(Regs.AX Shl 3) Shr 15;
  Drives    :=((Regs.AX Shl 8) Shr 14)+1;
  { Find AUTOEXEC.BAT and CONFIG.SYS files }
  Autoexec:='';
  Config:=''
End;


Procedure Find_Autoexec;
Begin
  Autoexec:=FExpand(FSearch('AUTOEXEC.BAT','C:\;D:\;E:\;F:\'));
  Config:=FExpand(FSearch('CONFIG.SYS','C:\;D:\;E:\;F:\'));
End;

Procedure DetectMemory;
Var EMM_Device    : String[8];
    Int_67_Device : String[8];
    P             : Word;
    W,F           : Char;
Begin
  { Conventional memory }
  Memory.Total:=MemW[$0040:$0013];
  Memory.Free:=Round(MemAvail/1024);
  { Extended memory }
  ExtMemory.Free:=0;
  If Mem[$F000:$FFFE]=$FC Then
  Begin
    Regs.AH:=$88;
    Intr($15,Regs);
    ExtMemory.Total:=Regs.AX;
  End Else ExtMemory.Total:=0;
  { Expanded memory }
  ExpMemory.Total:=0;
  ExpMemory.Free:=0;
  EMMVersion:='';
  Int_67_Device:='';
  EMM_Device:='EMMXXXX0';
  With Regs Do
  Begin
    AH:=$35;
    AL:=$67;
    MsDos(Regs);
    For P:=0 To 7 Do Int_67_Device:=Int_67_Device+Chr(Mem[ES:$0A+P]);
  End;
  If Int_67_Device=EMM_Device Then With Regs Do
  Begin
    AH:=$46;
    Intr($67,Regs);
    If AH=0 Then
    Begin
      W:=Char(AL Shr 4  +48);
      F:=Char(AL And $F +48);
      AH:=$42;
      Intr($67,Regs);
      If AH=0 Then
      Begin
        ExpMemory.Total:=DX;
        ExpMemory.Free:=BX;
        EMMVersion:=W+'.'+F+'0';
      End;
    End;
  End;
End;

End.