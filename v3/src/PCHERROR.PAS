Unit PchError;
Interface
  Uses Objects;

  Type
    PErrorRec= ^TErrorRec;
    TErrorRec= Record
      No: Byte;
      Msg: PString;
      ErrType: Integer;
    End;

    PErrorColl= ^TErrorColl;
    TErrorColl= Object(TSortedCollection)
      Procedure FreeItem(Item: Pointer); virtual;
      Procedure PutItem(Var S: TStream; Item: Pointer); virtual;
      Function GetItem(Var S: TStream): Pointer; virtual;
      Function KeyOf(Item: Pointer): Pointer; virtual;
      Function Compare(Key1, Key2: Pointer): Integer; virtual;
    End;

  Const
    RErrorColl: TStreamRec= (
      ObjType: 3002;
      VmtLink: Ofs(TypeOf(TErrorColl)^);
      Load: @TErrorColl.Load;
      Store: @TErrorColl.Store
    );

Implementation
  Uses StrUtl;

  Procedure TErrorColl.FreeItem(Item: Pointer);
  Begin
    DisposeStr(PErrorRec(Item)^.Msg);
    Dispose(PErrorRec(Item));
  End;

  Procedure TErrorColl.PutItem(Var S: TStream; Item: Pointer);
  Begin
    With PErrorRec(Item)^ Do
    Begin
      S.Write(No, SizeOf(No));
      S.WriteStr(Msg);
      S.Write(ErrorType, SizeOf(ErrorType));
    End;
  End;

  Function TErrorColl.GetItem(Var S: TStream): Pointer;
  Var P: PErrorRec;
  Begin
    New(P);
    With P^ Do
    Begin
      S.Read(No, SizeOf(No));
      Msg:=S.ReadStr;
      S.Read(ErrorType, SizeOf(ErrorType));
    End;
  End;

  Function TErrorColl.KeyOf(Item: Pointer): Pointer;
  Begin
    KeyOf:=@PErrorRec(Item)^.No;
  End;

  Function TErrorColl.Compare(Key1, Key2: Pointer): Integer;
  Begin
    If Byte(Key1^)<Byte(Key2^) Then Compare:=-1 Else
      If Byte(Key1^)=Byte(Key2^) then Compare:=0 Else
        Compare:=+1;
  End;

End.