{$A+,B-,D+,E-,F-,I-,L+,N-,O-,R+,S+,V-}
{$M 16384,65334,655360}
Program COMPRESS;
Uses Dos,Crt;
Type INFOTYPE = Record
                  ID   : String[4];
                  NAME : String[12];
                  LEN  : LongInt;
                End;
     BYTES = Array[1..22] Of Byte;
     BUFFERTYPE = Array[1..65334] Of Byte;
Var SOURCE,DEST : File Of Byte;
    INFO  : INFOTYPE;
    COUNT : LongInt;
    ACT   : Byte;
    DATA  : Byte;
    SR    : SearchRec;
    A     : Byte;
    Regs  : Registers;
    BUFFER   : ^BUFFERTYPE;
    Files    : Byte;
    DestFile : String;
    SourceFile : Array[1..20] Of String;

Begin
  Writeln('Softwhere Associates pre-installation program.');
  Writeln;
  Write('Enter destination: ');
  Readln(DestFile);
  If DestFile='' Then Halt;
  Files:=0;
  Repeat
    Inc(Files);
    Write('Enter source #',Files,': ');
    Readln(SourceFile[Files]);
  Until SourceFile[Files]='';
  Dec(Files);
  If Files=0 Then Halt;
  Writeln;
  New(BUFFER);
  Assign(DEST,DestFile);
  Rewrite(DEST);
  If IOResult<>0 Then
  Begin
    Writeln('Can''t create file ',DestFile);
    Halt(1);
  End;
  Writeln('Opening file ',DestFile);
  Writeln;
  INFO.ID:='NexT';
  Write(DEST,Files);
  For ACT:=1 To Files Do
  Begin
    SR.Name:=SourceFile[ACT];
    FindFirst(SourceFile[ACT],AnyFile,SR);
    If DosError<>0 Then
    Begin
      Writeln('Can''t find file ',SourceFile[ACT]);
      Close(DEST);
      Erase(DEST);
      Halt(1);
    End;
    INFO.LEN:=SR.Size;
    INFO.NAME:=SR.Name;
    Writeln('Reading/Writing file ',ACT);
    Writeln('Name: ',INFO.NAME);
    Writeln('Size: ',INFO.LEN:5,' bytes');
    Writeln;
    Assign(SOURCE,SourceFile[ACT]);
    Reset(SOURCE);
    For A:=1 To 22 Do Write(DEST,BYTES(INFO)[A]);
    COUNT:=0;
    Regs.BX:=FileRec(SOURCE).Handle;
    Regs.CX:=INFO.LEN;
    Regs.DS:=Seg(BUFFER^);
    Regs.DX:=Ofs(BUFFER^);
    Regs.AH:=63;
    MsDos(Regs);
    If Regs.AX<>INFO.LEN Then
    Begin
      Writeln('Error while reading ...');
      Halt(1);
    End;
    Regs.BX:=FileRec(DEST).Handle;
    Regs.CX:=INFO.LEN;
    Regs.DS:=Seg(BUFFER^);
    Regs.DX:=Ofs(BUFFER^);
    Regs.AH:=64;
    MsDos(Regs);
    If Regs.AX<>INFO.LEN Then
    Begin
      Writeln('Error while writing ...');
      Halt(1);
    End;
    Close(SOURCE);
    If IOResult<>0 Then Halt(1);
  End;
  Close(DEST);
  Writeln('Closing file ',DestFile);
  Writeln;
  Writeln('OK.');
End.