{$I PCHSYM.PAS}
Unit InitOvr;
Interface
Implementation
  Uses Overlay, Dos, Drivers, PchGlb, Messages;

  Const
    OvrSize= 30*1024;

Begin
  OvrInit(PchPath+OvrFileName);
  OvrSetBuf(OvrSize);
  OvrSetRetry((OvrSize Div 2)*5);
  If OvrResult <> ovrOk Then
  Begin
    PrintStr(errOverlay);
    Halt(1);
  End;
End.