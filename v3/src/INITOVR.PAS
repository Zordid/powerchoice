{$A-,B-,D-,E+,F-,G-,I-,L+,N-,O-,R-,S-,V+,X-}
Unit InitOvr;
Interface
Implementation
  Uses Overlay, Dos, Drivers, PchGlb;

  Const
    OvrSize= 30*1024;

Begin
  If Lo(DosVersion) >= 3 Then EXEName := ParamStr(0)
  Else
  Begin
    EXEName := FSearch('PCHOICE.EXE', GetEnv('PATH'));
    If EXEName = '' Then PrintStr('PCHOICE.EXE could not be found.'#13#10);
  End;
{$IFDEF STANDALONE}
  OvrInit('PCHOICE.OVR');
{$ELSE}
  OvrInit(EXEName);
{$ENDIF}
  OvrSetBuf(OvrSize);
  OvrSetRetry((OvrSize Div 2)*5);
  If OvrResult <> ovrOk Then
  Begin
    PrintStr('Overlay Error !');
    Halt(1);
  End;
End.