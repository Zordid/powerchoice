{$I PCHSYM.PAS}
Unit InitOvr;
Interface
Implementation
  Uses Overlay, Dos, Drivers, PchGlb, Messages, DosTools;

  Const
    OvrSize= 30*1024;

  Procedure InitDirectories;
  Var S: String;
  Begin
    S:=GetEnv('PCHGLOBAL');
    If S<>'' Then
    Begin
      If S[Length(S)]<>'\' Then S:=S+'\';
      PchPath:=S;
    End;
    S:=GetEnv('PCHUSER');
    If S<>'' Then
    Begin
      If S[Length(S)]<>'\' Then S:=S+'\';
      UserPath:=S;
      BatchFileName:=S+'PCH.BAT';
      PWFileName:=S+'PCHPW.SYS';
    End;
    If Not FileExists(PWFileName) Then
      PWFileName:=FSearch('PCHPW.SYS', GetEnv('PATH'));
    If PWFileName='' Then
    Begin
      PrintStr(errPWFile_not_found);
      Halt(1);
    End;
  End;

Begin
  InitDirectories;
  OvrInit(PchPath+OvrFileName);
  OvrSetBuf(OvrSize);
  OvrSetRetry((OvrSize Div 2)*5);
  If OvrResult <> ovrOk Then
  Begin
    PrintStr(errOverlay);
    Halt(1);
  End;
End.