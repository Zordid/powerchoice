{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O-,R-,S+,V+,X-}
{$M 2048,0,0}
Program FirstBoot;
Uses Dos;
Var F: File;
    L: LongInt;
    DT1, DT2: DateTime;
Begin
  Assign(F, 'C:\PCHOICE\BOOT.LST');
  Reset(F);
  If IOResult<>0 Then
  Begin
    Rewrite(F);
    Close(F);
    Halt(0);
  End;
  GetFTime(F, L);
  UnPackTime(L, DT1);
  Rewrite(F);
  GetFTime(F, L);
  UnPackTime(L, DT2);
  Close(F);
  If (DT1.Day=DT2.Day) And (DT1.Month=DT2.Month) And (DT1.Year=DT2.Year) Then
    Halt(1);
End.