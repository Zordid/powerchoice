Unit PchTools;
{$I PCHSYM.PAS}
{$O+,F+}
Interface

  Procedure CleanDisk;
  Procedure ChangeDirectory(SearchDir: String; AllDrives: Boolean);

Implementation
  Uses
    Objects, Drivers, Views, Dialogs, App, MsgBox,
    Crt, Dos, DosTools, StrUtl,
    PchCmds, PchMsg, PchGlb;

  Procedure CleanDisk;
  Const
    NotAllowedCount= 5;
    NotAllowed: Array[1..NotAllowedCount] Of String[5]=
      ('*.*', '*.EXE', '*.COM', '*.SYS', '*.BAT');
  Var
    Dlg, Dlg1, DlgAsk: PDialog;
    Options: Record
      Drives: String[10];
      FileSpecs: String[100];
      Options : Word;
    End;
    Strm: TBufStream;
    I: Byte;
    Cancel: Boolean;
    SearchStr, FoundStr, DelStr, S, F: String[80];
    Info: LongInt;

    Procedure ProcessDrive(Drive: Char; Var FileSpecs: String);
    Var
      FSpec: String[100];
      FList: TFileList;
      WrdCount, I: Word;
      OldSpace, NewSpace: LongInt;
      Stat: Record
        Drive: LongInt;
        Deleted, Found: LongInt;
        SpaceGained: LongInt;
      End;
      R: TRect;
      Txt: PStaticText;

      Function Allowed: Boolean;
      Var I: Byte;
      Begin
        Allowed:=False;
        For I:=1 To NotAllowedCount Do
          If StrEqu(FSpec, NotAllowed[I]) Then Exit;
        Allowed:=True;
      End;

      Procedure DeleteFile(P: PString); far;
      Begin
        If P<>nil Then FileDelete(P^);
      End;

    Begin
      If Dlg1=nil Then
      Begin
        R.Assign(15, 2, 65, 5);
        Dlg1:=New(PDialog, Init(R, GetMsg(sWorkingOn)+' '+Drive+':'));
        Dec(Dlg1^.Flags, wfClose);
        R.Assign(4, 1, 46, 2);
        Txt:=New(PStaticText, Init(R, ''));
        Dlg1^.Insert(Txt);
        DeskTop^.Insert(Dlg1);
      End Else
      Begin
        DisposeStr(Dlg1^.Title);
        Dlg1^.Title:=NewStr(GetMsg(sWorkingOn)+' '+Drive+':');
        Dlg1^.Frame^.Draw;
      End;
      OldSpace:=DiskFree(Ord(Drive)-Ord('A')+1);
      Stat.Found:=0;
      Stat.Deleted:=0;
      WrdCount:=1;
      WrdL(FSpec, FileSpecs, WrdCount);
      While FSpec<>'' Do
      Begin
        If Allowed Then
        Begin
          InfoPtr:=@FSpec;
          FormatStr(S, SearchStr, InfoPtr);
          DisposeStr(Txt^.Text);
          Txt^.Text:=NewStr(S);
          Txt^.Draw;
          FList.Init(Drive+':\'+FSpec, Archive, ReadOnly+Hidden+SysFile, True);
          Inc(Stat.Found, FList.Count);
          If FList.Count>0 Then
          Begin
            Info:=FList.Count;
            FormatStr(F, FoundStr, Info);
            DisposeStr(Txt^.Text);
            Txt^.Text:=NewStr(S+F);
            Txt^.Draw;
            If Options.Options And 1=1 Then
            Begin
              DlgAsk:=PDialog(GetRez('CleanAskDlg'));
              If DlgAsk<>nil Then
              Begin
                PListBox(DlgAsk^.Current)^.NewList(@FList);
                I:=DeskTop^.ExecView(DlgAsk);
                Dispose(DlgAsk, Done);
              End Else
                I:=cmCancel;
            End Else
              I:=cmYes;
            If I=cmYes Then
            Begin
              Info:=FList.Count;
              FormatStr(S, DelStr, Info);
              DisposeStr(Txt^.Text);
              Txt^.Text:=NewStr(S);
              Txt^.Draw;
              FList.ForEach(@DeleteFile);
              Inc(Stat.Deleted, FList.Count);
            End Else
            If I=cmCancel Then
            Begin
              Cancel:=True;
              FList.Done;
              Exit;
            End;
          End;
          FList.Done;
          Inc(WrdCount);
        End Else
        Begin
          InfoPtr:=@FSpec;
          MessageBox(GetMsg(sWrongSpec), @InfoPtr, mfInformation+mfOkButton);
          Delete(FileSpecs, WrdPos, Length(FSpec));
        End;
        WrdL(FSpec, FileSpecs, WrdCount);
      End;
      NewSpace:=DiskFree(Ord(Drive)-Ord('A')+1);
      If (Options.Options And 2=2) And (Stat.Found>0) Then
      Begin
        Stat.Drive:=Ord(Drive);
        Stat.SpaceGained:=(NewSpace-OldSpace) Div 1024;
        MessageBox(GetMsg(sStatistic), @Stat, mfInformation+mfOkButton);
      End;
    End;

  Begin
    Dlg:=PDialog(GetRez('CleanDlg'));
    If Dlg<>nil Then
    Begin
      SearchStr:=GetMsg(sSearchingFor);
      FoundStr:=GetMsg(sFound);
      DelStr:=GetMsg(sDeleting);
      Strm.Init(PchPath+'PCHOICE.INI', stOpen, 1024);
      Strm.Read(Options, SizeOf(Options));
      Strm.Done;
      If Strm.Status<>stOk Then
      With Options Do
      Begin
        Drives:='C:';
        FileSpecs:='*.BAK *.SIK *.TMP *.$$$';
        Options:=1+2;
      End;
      Dlg^.SetData(Options);
      If DeskTop^.ExecView(Dlg)=cmOk Then
      Begin
        Cancel:=False;
        Dlg^.GetData(Options);
        StrUpr(Options.Drives);
        StrUpr(Options.FileSpecs);
        Strm.Init(PchPath+'PCHOICE.INI', stCreate, 1024);
        Strm.Write(Options, SizeOf(Options));
        Strm.Done;
        StrMove(WrdDelim, ' ,;');
        Dlg1:=nil;
        For I:=1 To Length(Options.Drives) Do
          If Options.Drives[I] In ['C'..'Z'] Then
            If Not Cancel Then
              ProcessDrive(Options.Drives[I], Options.FileSpecs);
        If Dlg1<>nil Then
        Begin
          DeskTop^.Delete(Dlg1);
          Dispose(Dlg1, Done);
        End;
        StrMove(WrdDelim, StdDelim);
      End;
      Dispose(Dlg, Done);
    End;
  End;

  Type
    PDirRec= ^TDirRec;
    TDirRec= Record
      Name: String[12];
      Complete: PString;
    End;

    PTreeCollection= ^TTreeCollection;
    TTreeCollection= Object(TStringCollection)
      Procedure FreeItem(Item: Pointer); virtual;
      Procedure PutItem(Var S: TStream; Item: Pointer); virtual;
      Function GetItem(Var S: TStream): Pointer; virtual;
    End;

    Procedure TTreeCollection.FreeItem(Item: Pointer);
    Begin
      DisposeStr(PDirRec(Item)^.Complete);
      Dispose(PDirRec(Item));
    End;

    Procedure TTreeCollection.PutItem(Var S: TStream; Item: Pointer);
    Begin
      S.Write(PDirRec(Item)^.Name, 13);
      S.WriteStr(PDirRec(Item)^.Complete);
    End;

    Function TTreeCollection.GetItem(Var S: TStream): Pointer;
    Var D: PDirRec;
    Begin
      New(D);
      S.Read(D^.Name, 13);
      D^.Complete:=S.ReadStr;
      GetItem:=D;
    End;

  Type
    PSelectBox= ^TSelectBox;
    TSelectBox= Object(TListBox)
      Found: Integer;
      Function GetText(Item, MaxLen: Integer): String; virtual;
    End;

    Function TSelectBox.GetText(Item, MaxLen: Integer): String;
    Begin
      GetText:=Copy(PDirRec(List^.At(Found-Item))^.Complete^, 1, MaxLen);
    End;

  Const
    RTreeCollection: TStreamRec= (
      ObjType: 3008;
      VmtLink: Ofs(TypeOf(TTreeCollection)^);
      Load: @TTreeCollection.Load;
      Store: @TTreeCollection.Store
    );

  Procedure ChangeDirectory(SearchDir: String; AllDrives: Boolean);
  Const
    Registered: Boolean= False;
  Var
    Tree: PTreeCollection;
    Drive: Char;
    Found, C: Integer;
    Info: LongInt;
    Try: Word;

    Procedure Scan(Dir: String);
    Var
      SR: SearchRec;
      D: PDirRec;
    Begin
      FindFirst(Dir+'*.*', Directory, SR);
      While DosError=0 Do
      Begin
        If (SR.Name[1]<>'.') And (SR.Attr And Directory=Directory) Then
        Begin
          New(D);
          StrMove(D^.Name, SR.Name);
          D^.Complete:=NewStr(Dir+SR.Name);
          Tree^.Insert(D);
          Scan(Dir+SR.Name+'\');
        End;
        FindNext(SR);
      End;
    End;

    Procedure Select;
    Var
      Dlg: PDialog;
      Box: PSelectBox;
      ScrollBar: PScrollBar;
      R: TRect;
    Begin
      R.Assign(0, 0, 60, 15);
      New(Dlg, Init(R, GetMsg(sAutoCD)));
      Dlg^.Options:=Dlg^.Options Or ofCentered;
      R.Assign(57, 3, 58, 11);
      ScrollBar:=New(PScrollBar, Init(R));
      Dlg^.Insert(ScrollBar);
      R.Assign(2, 3, 57, 11);
      Box:=New(PSelectBox, Init(R, 1, Scrollbar));
      Box^.NewList(Tree);
      Box^.SetRange(C);
      Box^.Found:=Found+C-1;
      Dlg^.Insert(Box);
      R.Assign(2, 2, 50, 3);
      Dlg^.Insert(New(PLabel, Init(R, GetMsg(sMDirsFound), Box)));
      R.Assign(35, 12, 45, 14);
      Dlg^.Insert(New(PButton, Init(R, GetMsg(sOk), cmOk, bfDefault)));
      R.Assign(47, 12, 58, 14);
      Dlg^.Insert(New(PButton, Init(R, GetMsg(sCancel), cmCancel, bfNormal)));
      Dlg^.SelectNext(False);
      If DeskTop^.ExecView(Application^.ValidView(Dlg))<>cmCancel Then
        Found:=Box^.Found-Box^.Focused
      Else
        Found:=-1;
      Dispose(Dlg, Done);
    End;

    Function GetTree(Drive: Char): PTreeCollection;
    Var
      FileName: String;
      S: TBufStream;
    Begin
      StrMove(FileName, PchPath);
      StrCat(FileName, 'TREE', 255);
      ChrCat(FileName, Drive);
      StrCat(FileName, '.DAT', 255);
      S.Init(FileName, stOpen, 1024);
      GetTree:=PTreeCollection(S.Get);
      S.Done;
    End;

    Procedure PutTree(Drive: Char; Tree: PTreeCollection);
    Var
      FileName: String;
      S: TBufStream;
    Begin
      StrMove(FileName, PchPath);
      StrCat(FileName, 'TREE', 255);
      ChrCat(FileName, Drive);
      StrCat(FileName, '.DAT', 255);
      S.Init(FileName, stCreate, 1024);
      S.Put(Tree);
      S.Done;
      If S.Status<>stOk Then
        MessageBox(GetMsg(sTreeFileWError), nil,  mfError+mfOkButton);
    End;

  Begin
    ChrDelL(SearchDir, '.');
    If Not Registered Then
    Begin
      RegisterType(RTreeCollection);
      Registered:=True;
    End;
    Try:=1;
    Drive:=GetCurDrive;
    Tree:=GetTree(Drive);
    Repeat
      If Tree=nil Then
      Begin
        Info:=Ord(Drive);
        If (Try=1) And (MessageBox(GetMsg(sDontKnowTree), @Info, mfConfirmation+mfYesNoCancel)<>cmYes) Then Exit;
        New(Tree, Init(5, 5));
        Tree^.Duplicates:=True;
        Scan(Drive+':\');
        PutTree(Drive, Tree);
        Inc(Try);
      End;
      If Tree^.Search(@SearchDir, Found) Then
      Begin
        C:=0;
        While (Found+C<Tree^.Count) And (StrEqu(PDirRec(Tree^.At(Found+C))^.Name, SearchDir)) Do Inc(C);
        If C>1 Then Select;
        If Found<>-1 Then
        Begin
          {$I-}
          ChDir(PDirRec(Tree^.At(Found))^.Complete^);
  {$IFDEF CHECKING}
          {$I+}
  {$ENDIF}
          InOutRes:=0;
        End;
        Inc(Try);
      End Else
      Begin
        InfoPtr:=@SearchDir;
        If Try=1 Then
        Begin
          Dispose(Tree, Done);
          Tree:=nil;
          If MessageBox(GetMsg(sReadNewTree), @InfoPtr, mfConfirmation+mfYesNoCancel)<>cmYes Then
            Exit;
        End Else
          MessageBox(GetMsg(sDirNotFound), @InfoPtr, mfInformation+mfOkButton);
      End;
      Inc(Try);
    Until Try>2;
    Dispose(Tree, Done);
  End;

End.