{$A-,B-,D-,E-,F-,I-,L-,N-,O-,R-,S-,V-}
{$M 1024,0,0}
{$L HANDLER}
Program NODOS;
Uses Dos;
Var OldInt : Pointer;
    PrgName : PathStr;
    CmdLine : ComStr;
    S : SearchRec;
    I : Byte;

Procedure NewInt;External;

Begin
  If ParamCount=0 Then Halt(1);
  CmdLine:='';
  For I:=2 To ParamCount Do CmdLine:=CmdLine+' '+ParamStr(I);
  PrgName:=ParamStr(1);
  If Pos('.',PrgName)=0 Then
  Begin
    FindFirst(PrgName+'.EXE',AnyFile,S);
    If DosError<>0 Then
    Begin
      FindFirst(PrgName+'.COM',AnyFile,S);
      If DosError=0 Then PrgName:=PrgName+'.COM';
    End Else PrgName:=PrgName+'.EXE';
  End;
  GetIntVec($21,OldInt);
  Move(OldInt,Ptr(Seg(NewInt),Ofs(NewInt)+2)^,SizeOf(OldInt));
  SetIntVec($21,@NewInt);
  Exec(PrgName,CmdLine);
  SetIntVec($21,OldInt);
  Halt(DosExitCode);
End.