Program Register;
Uses Crt, Dos, Objects, PchReg;

Var
  F: File;

Function Search(S: String): LongInt;
Const
  BufSize= 20*1024;
  BS: LongInt= BufSize;
Var
  S2: String;
  O1, O2: LongInt;
  Found: Boolean;
  R: Word;
  Buffer: PByteArray;
Begin
  GetMem(Buffer, BufSize+10);
  S2[0]:=S[0];
  O1:=0;
  Repeat
    Seek(F, O1);
    BlockRead(F, Buffer^, BufSize, R);
    O2:=0;
    Repeat
      Move(Buffer^[O2], S2[1], Length(S));
      Found:=S=S2;
      If Not Found Then Inc(O2);
    Until Found Or (O2>R-Length(S));
    If Not Found Then Inc(O1, BufSize-Length(S));
  Until Found Or (R<BufSize);
  If Found Then
  Begin
    Search:=O1+O2-1;
    Seek(F, O1+O2);
    BlockRead(F, S2[1], Length(S));
    If S<>S2 Then RunError(99);
  End Else
    Search:=-1;
  FreeMem(Buffer, BufSize+10);
End;

Procedure Code(Var S: String; L: Byte);
Var I, C, B: Byte;
Begin
  I:=0;
  C:=Chiffre;
  Repeat
    B:=Byte(S[I]);
    Asm
      mov al, B
      xor al, C
      ror al, Rolling
      mov B, al
    End;
    Byte(S[I]):=B;
    Inc(I);
    Inc(C);
  Until I=L;
End;

Var
  O: LongInt;
  Y, M, D, DoW: Word;

Begin
  Writeln('Power-Choice 3.1 Registrierung...');
  Writeln;
  If ParamCount=0 Then
    Assign(F, 'A:\PCHOICE.EXE')
  Else
    Assign(F, ParamStr(1));
  Reset(F, 1);
  O:=Search('USERREG');
  If O<>-1 Then
  Begin
    Write('Benutzer  : '); Readln(Reg.UserName);
    Write('Firma     : '); Readln(Reg.UserCompany);
    Write('Serien-Nr.: '); Readln(Reg.SerialNo);
    GetDate(Y, M, D, DoW);
    Reg.Date:=(M Shl 8)+(Y-1990);
    Writeln;
    Writeln('Registriere...');
    Code(Reg.UserName, SizeOf(Reg));
    Seek(F, O);
    BlockWrite(F, Reg, SizeOf(Reg));
    Writeln('Ok.');
  End Else
    Writeln('Schon registriert.');
  Close(F);
End.
