{$I PCHSYM.PAS}
Unit PchReg;
Interface
Const
  Chiffre= $3E;
  Rolling= 2;

  Type
    TReg= Record
      UserName, UserCompany: String[29];
      SerialNo: LongInt;
      Date: Word;
    End;

  Const
    Reg: TReg=
      (UserName:'USERREG'; UserCompany: ''; SerialNo: 0; Date: 0);
    Version: Word= $030A;

Implementation

Procedure Decode(Var S: String; L: Byte);
Var I, C, B: Byte;
Begin
  I:=0;
  C:=Chiffre;
  Repeat
    B:=Byte(S[I]);
    Asm
      mov al, B
      rol al, Rolling
      xor al, C
      mov B, al
    End;
    Byte(S[I]):=B;
    Inc(I);
    Inc(C);
  Until I=L;
End;

Begin
  If Reg.SerialNo<>0 Then
    Decode(Reg.UserName, SizeOf(Reg))
  Else
    Reg.UserName:='';
End.
