Unit PchFm;
{$I PCHSYM.PAS}
{$O+,F+}
Interface
  Uses Objects, Drivers, Views, Dialogs, ItmDlg, DosTools, GlbMem, PchFBuf;

  Const
    { Akitv - Inaktiv - Fokussiert - Gewählt - Fokussiert+Gewählt }
    CFileViewer= #26#33#27#28#34;
    CKoboldDialog= #87#88;
    CKoboldColor= #$38#$2E;
    CKoboldMonochrome= #$0#$7F;
    CKoboldBlackWhite= #$0#$7F;

    idBufferAvail= 101;
    idBufferUsed= 102;

    fmActive= 0;
    fmInactive= 1;
    fmSelected= 2;

  Type
    PFileViewer= ^TFileViewer;
    TFileViewer= Object(TListBox)
      Start: Word;
      TotalSize: LongInt;
      Constructor Init(Var Bounds: TRect; AScrollbar: PScrollbar);
      Function GetText(Item, MaxLen: Integer): String; virtual;
      Procedure SelectItem(Item: Integer); virtual;
      Procedure Draw; virtual;
      Function GetPalette: PPalette; virtual;
      Procedure HandleEvent(Var Event: TEvent); virtual;
    End;

    TDirDesc= Object(TObject)
      Source: Boolean;
      Path: String;
      FileSpec: String[12];
      FileList: PFileInfoList;
      Marked: Word;
      Viewer: PFileViewer;
      PathDisplay: PStaticText;
      Constructor Init(ADialog: PItemDialog; IsSource: Boolean; APath: String);
      Procedure ChDir(APath: String);
      Function Count: Word;
      Function HandleEvent(Var Event: TEvent): Boolean;
      Function GetSelectedFiles: PCollection;
      Destructor Done; virtual;
    End;

    PKobold= ^TKobold;
    TKobold= Object(TItemDialog)
      FBuffer: PFileBuffer;
      Source, Dest: TDirDesc;
      Constructor Init(SourceDir, DestDir: String);
      Procedure UpdateBuffer;
      Procedure HandleEvent(Var Event: TEvent); virtual;
      Function GetPalette: PPalette; virtual;
      Destructor Done; virtual;
    End;

  Procedure Kobold;

Implementation
  Uses
    Dos, App, MsgBox, StrUtl,
    PchCmds;

{== TFileViewer ==}

  Constructor TFileViewer.Init(Var Bounds: TRect; AScrollbar: PScrollBar);
  Begin
    TListBox.Init(Bounds, 1, AScrollbar);
    Start:=$FFFF;
  End;

  Function TFileViewer.GetText(Item, MaxLen: Integer): String;
  Var
    S: String;
    P: PSearchRec;
  Begin
    If Item<List^.Count Then
    Begin
      P:=PSearchRec(List^.At(Item));
      If (P^.Attr And Directory)<>0 Then
      Begin
        P^.Extra:=fmActive;
        If P^.Name^='..' Then
          FormatStr(S, ' %-12s  <UP-DIR>', P^)
        Else
          FormatStr(S, ' %-12s <SUB-DIR>', P^);
      End Else
        FormatStr(S, ' %-12s %2#%9d', P^);
      S[1]:=Char(P^.Extra);
      StrCut(S, MaxLen+1);
    End Else S:=Char(fmInactive);
    GetText:=S;
  End;

  Procedure TFileViewer.Draw;
  Const
    ColorTable: Array[0..6] Of Byte= (1, 4, 3, 5, 2, 0, 3);
  Var
    Color: Byte;
    Y, I: Integer;
    B: TDrawBuffer;
    S: String;
    Info: ^Byte;
    Mode: Byte;
  Begin
    Info:=@S[1];
    For Y:=0 To Size.Y-1 Do
    Begin
      I:=TopItem+Y;
      S:=GetText(I, Size.X-2);
      Mode:=Byte(Info^=fmInactive)*$4+Byte(IsSelected(I))*$2+Byte(Info^=fmSelected)*$1;
      Delete(S, 1, 1);
      Color:=GetColor(ColorTable[Mode]);
      MoveChar(B, ' ', Color, Size.X);
      MoveStr(B[1], S, Color);
      WriteLine(0, Y, Size.X, 1, B);
    End;
  End;

  Function TFileViewer.GetPalette: PPalette;
  Const P: String[Length(CFileViewer)]= CFileViewer;
  Begin
    GetPalette:=@P;
  End;

  Procedure TFileViewer.SelectItem(Item: Integer);
  Var P: PSearchRec;
  Begin
    P:=PSearchRec(List^.At(Item));
    If P^.Extra<>fmInactive Then TListBox.SelectItem(Item);
  End;

  Procedure TFileViewer.HandleEvent(Var Event: TEvent);
  Var
    ShiftState: Byte absolute $40:$17;
    S: Boolean;
  Begin
    S:=(Event.What=evKeyDown) And ((Event.KeyCode=kbDown) Or (Event.KeyCode=kbUp)) And
       (ShiftState And (kbRightShift+kbLeftShift)<>0);
    If S And (Start=$ffff) Then
    Begin
      Start:=Focused;
      SelectItem(Focused);
    End;
    TListBox.HandleEvent(Event);
    If S Then
    Begin
      SelectItem(Focused);
    End Else
      Start:=$ffff;
  End;

  {
  Function TFileViewer.SelectFile(I: Integer; Mode: Byte): Boolean;
  Var
    Old: Word;
    P: PSearchRec;
  Begin
    SelectFile:=False;
    If I>=FileList^.Count Then Exit;
    P:=PSearchRec(FileList^.At(I));
    If P^.Attr And Directory<>0 Then Exit;
    SelectFile:=True;
    Old:=P^.Attr;
    Case Mode Of
      0: P^.Attr:=Old Xor $100;
      1: P^.Attr:=Old Or $100;
      2: P^.Attr:=Old And (Not $100);
    End;
    If Old<>P^.Attr Then
    Begin
      If P^.Attr And $100<>0 Then
      Begin
        Inc(Marked);
        Inc(TotalSize, P^.Size);
      End Else
      Begin
        Dec(Marked);
        Dec(TotalSize, P^.Size);
      End;
    End;
  End;

  Procedure TFileViewer.ReadDirectory(APath: String);
  Begin
    If PathName<>nil Then
    Begin
      ChDir(PathName^);
      DisposeStr(PathName);
    End;
    APath:=FExpand(APath);
    PathName:=NewStr(APath);
    If APath[Length(APath)]<>'\' Then ChrCat(APath, '\');
    StrCat(APath, FileSpec, 255);
    If FileList<>nil Then
      FileList^.ReadDirectory(APath, AnyFile, VolumeID, False)
    Else
      FileList:=New(PFileInfoList, Init(APath, AnyFile, VolumeID, False));
    SetRange(FileList^.Count);
    FocusItem(0);
    DisposeStr(PathViewer^.Text);
    PathViewer^.Text:=NewStr(APath);
    PathViewer^.Draw;
    Marked:=0;
    TotalSize:=0;
  End;
  }

{== TDirDesc ==}

  Constructor TDirDesc.Init(ADialog: PItemDialog; IsSource: Boolean; APath: String);
  Var
    R: TRect;
    XOfs: Byte;
    LabelTxt: String;
    ScBar: PScrollbar;
    Control, Labl: PView;
  Begin
    TObject.Init;
    If IsSource Then
    Begin
      XOfs:=0;
      LabelTxt:='~Q~uellverzeichnis';
    End Else
    Begin
      XOfs:=42;
      LabelTxt:='~Z~ielverzeichnis';
    End;
    R.Assign(26+XOfs,3,27+XOfs,18);
    ScBar := New(PScrollbar, Init(R));
    ADialog^.Insert(ScBar);
    R.Assign(3+XOfs,2,26+XOfs,3);
    PathDisplay:=New(PStaticText, Init(R, ''));
    ADialog^.Insert(PathDisplay);
    R.Assign(2+XOfs,3,26+XOfs,18);
    Viewer := New(PFileViewer, Init(R, ScBar));
    ADialog^.Insert(Viewer);
      R.Assign(2+XOfs,1,19+XOfs,2);
      Labl := New(PLabel, Init(R, LabelTxt, Viewer));
      ADialog^.Insert(Labl);
    StrMove(FileSpec, '*.*');
    ChDir(APath);
  End;

  Procedure TDirDesc.ChDir(APath: String);
    Procedure DeActivate(P: PSearchRec); far;
    Begin
      If P^.Attr And Directory=0 Then P^.Extra:=fmInActive;
    End;
  Begin
    If APath<>'' Then ChDir(APath);
    StrMove(APath, FExpand(APath));
    StrMove(Path, APath);
    If APath[Length(APath)]<>'\' Then ChrCat(APath, '\');
    StrCat(APath, FileSpec, 255);
    FileList:=New(PFileInfoList, Init(APath, AnyFile, VolumeID, False));
    Viewer^.NewList(FileList);
    DisposeStr(PathDisplay^.Text);
    PathDisplay^.Text:=NewStr(APath);
    PathDisplay^.Draw;
    Marked:=0;
    If Not Source Then
    Begin
      FileList^.ForEach(@DeActivate);
      Viewer^.Draw;
    End;
  End;

  Function TDirDesc.Count: Word;
  Begin
    Count:=FileList^.Count;
  End;

  Function TDirDesc.HandleEvent(Var Event: TEvent): Boolean;
  Var P: PSearchRec;
  Begin
    If (Event.What=evBroadcast) And (Event.Command=cmListItemSelected) And
      (Event.InfoPtr=Pointer(Viewer)) Then
    Begin
      HandleEvent:=True;
      P:=PSearchRec(FileList^.At(Viewer^.Focused));
      If P^.Attr And Directory=0 Then
      Begin
        If P^.Extra=fmActive Then P^.Extra:=fmSelected Else P^.Extra:=fmActive;
        Viewer^.Draw;
        If P^.Extra=fmSelected Then Inc(Marked) Else Dec(Marked);
      End Else
        ChDir(P^.Name^);
    End Else
      HandleEvent:=False;
  End;

  Function TDirDesc.GetSelectedFiles: PCollection;
  Var L: PCollection;
    Procedure InsertToL(P: PSearchRec); far;
    Begin
      If P^.Extra=fmSelected Then L^.Insert(P);
    End;
  Begin
    New(L, Init(1, Marked-1));
    If Marked=0 Then
      L^.Insert(FileList^.At(Viewer^.Focused))
    Else
      FileList^.ForEach(@InsertToL);
    GetSelectedFiles:=L;
  End;

  Destructor TDirDesc.Done;
  Begin
    Viewer^.NewList(nil);
  End;

{== TKobold ==}

  Constructor TKobold.Init;
  Var
    R: TRect;
    Control: PView;
  Begin
    R.Assign(4,1,75,21);
    TItemDialog.Init(R, 'Datei-Operationen');
    FBuffer:=New(PFileBuffer, Init(10, 10));
    { Quelle }
    Source.Init(@Self, True, SourceDir);
    { Ziel }
    Dest.Init(@Self, False, DestDir);
    { Buttons }
    R.Assign(28,2,43,4);
    Insert(New(PButton, Init(R, '~E~inlesen', cmRead, bfNormal)));
    R.Assign(28,4,43,6);
    Insert(New(PButton, Init(R, '~S~chreiben', cmWrite, bfNormal)));
    R.Assign(28,6,43,8);
    Insert(New(PButton, Init(R, '~K~opieren', cmCopy, bfNormal)));
    R.Assign(28,8,43,10);
    Insert(New(PButton, Init(R, '~V~erschieben', cmMove, bfNormal)));
    R.Assign(28,10,43,12);
    Insert(New(PButton, Init(R, '~L~öschen', cmDelete, bfNormal)));
    R.Assign(28,12,43,14);
    Insert(New(PButton, Init(R, '~U~mbenennen', cmRename, bfNormal)));
    { Puffer }
    R.Assign(28,16,34,17);
    Insert(New(PStaticText, Init(R, 'Puffer')));
    R.Assign(28,17,33,18);
    Insert(New(PStaticText, Init(R, 'Frei:')));
    R.Assign(28,18,35,19);
    Insert(New(PStaticText, Init(R, 'Belegt:')));
    R.Assign(33,17,43,18);
    InsertItem(idBufferAvail, New(PStaticText, Init(R, 'xxxxxxxxxx')));
    R.Assign(35,18,43,19);
    InsertItem(idBufferUsed, New(PStaticText, Init(R, 'xxxxxxxx')));
    SelectNext(False);
    { Initialisieren der Listen }
    UpdateBuffer;
  End;

  Function TKobold.GetPalette: PPalette;
  Const P: String[Length(CDialog)+Length(CKoboldDialog)]= CDialog+CKoboldDialog;
  Begin
    GetPalette:=@P;
  End;

  Procedure TKobold.UpdateBuffer;
  Var
    S: String;
    P: PStaticText;
  Begin
    Str(FBuffer^.Free:10, S);
    P:=PStaticText(GetItemPtr(idBufferAvail));
    P^.Text^:=S;
    P^.Draw;
    Str(FBuffer^.Used:8, S);
    P:=PStaticText(GetItemPtr(idBufferUsed));
    P^.Text^:=S;
    P^.Draw;
  End;

  Procedure TKobold.HandleEvent(Var Event: TEvent);

    Procedure DeleteFiles;
    Var
      ThePath: String;
      Cmd: Word;
      Confirm: Boolean;
      L: PCollection;
      P: PSearchRec;
    Begin
      StrMove(ThePath, Source.Path);
      If ThePath[Length(ThePath)]<>'\' Then ChrCat(ThePath, '\');
      L:=Source.GetSelectedFiles;
      If L^.Count>1 Then
        Cmd:=MessageBox('Einzeln Löschen bestätigen lassen ?', nil, mfConfirmation+mfYesNoCancel)
      Else
        Cmd:=cmYes;
      Confirm:=Cmd=cmYes;
      While (Cmd<>cmCancel) And (L^.Count>0) Do
      Begin
        P:=PSearchRec(L^.At(0));
        L^.Delete(P);
        If P^.Attr And Directory=0 Then
        Begin
          If Confirm Then
            Cmd:=MessageBox('Datei %s löschen ?', @P^.Name, mfConfirmation+mfYesNoCancel);
          If (Not Confirm) Or (Cmd=cmYes) Then
          Begin
            FileDelete(ThePath+P^.Name^);
            If DosToolsRes=0 Then
            Begin
              If Source.Marked>0 Then
              Begin
                Dec(Source.Marked);
              End;
              Source.FileList^.Free(P);
              Source.Viewer^.SetRange(Source.FileList^.Count);
              Source.Viewer^.Draw;
            End Else
              MessageBox('Datei %s konnte nicht gelöscht werden.', @P^.Name, mfError+mfOkButton);
          End;
        End;
      End;
      L^.DeleteAll;
      Dispose(L, Done);
    End;

    Procedure RenameFiles;
    Begin

    End;

    Procedure ReadFiles;
    Begin

    End;

  Begin
    TItemDialog.HandleEvent(Event);
    If Source.HandleEvent(Event) Then ClearEvent(Event);
    If Event.What=evCommand Then
    Begin
      Case Event.Command Of
        cmDelete: DeleteFiles;
        cmRename: RenameFiles;
        cmRead: ReadFiles;
        Else Exit;
      End;
      ClearEvent(Event);
    End;
  End;

  Destructor TKobold.Done;
  Begin
    Dispose(FBuffer, Done);
    TItemDialog.Done;
  End;

  Procedure Kobold;
  Var
    Dlg: PKobold;
    OldDir: String;
  Begin
    GetDir(0, OldDir);
    Dlg:=New(PKobold, Init('C:\', 'C:\TP\PRGTOOLS'));
    DeskTop^.ExecView(Dlg);
    Dispose(Dlg, Done);
    ChDir(OldDir);
  End;

End.