{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O-,R-,S+,V+,X-}
Program CheckPos;
Const
  BS= 16*1024;
  BufSize: LongInt= BS;
Var
  F: File;
  Buf: Array[0..BS] Of Byte;
  N, S, S2: String;
  Found: Boolean;
  R: Integer;
  C, I, O: LongInt;
Begin
  If ParamCount<>2 Then
  Begin
    Writeln('Usage: CHECKPOS File[.EXE] Search');
    Halt(1);
  End;
  N:=ParamStr(1);
  S:=ParamStr(2);
  If Pos('.', N)=0 Then N:=N+'.EXE';
  Assign(F, N);
  Reset(F, 1);
  If IOResult<>0 Then
  Begin
    Writeln('File ', N, ' not found.');
    Halt(1);
  End;
  Found:=False;
  S2[0]:=S[0];
  C:=0;
  Repeat
    BlockRead(F, Buf, BufSize, R);
    I:=0;
    Repeat
      Move(Buf[I], S2[1], Length(S));
      Found:=S=S2;
      Inc(I);
    Until Found Or (I>R);
    Inc(C);
  Until Found Or (R<BufSize);
  If Not Found Then
  Begin
    Writeln('String "', S, '" not found in ', N, '.');
    Close(F);
    Halt(1);
  End;
  O:=(C-1)*BufSize+(I-1);
  Writeln('String "', S, '" found at offset ', O);
  Seek(F, O);
  BlockRead(F, S2[1], Length(S));
  If S<>S2 Then
  Begin
    Writeln('Error !');
    Halt(1);
  End;
  Inc(O, Length(S));
  Seek(F, FileSize(F));
  BlockWrite(F, O, SizeOf(O));
  Close(F);
End.