{$A+,B-,D+,E-,F-,I-,L+,N-,O-,R+,S+,V-}
Unit PCH_DEF;
Interface
  Uses Crt,Dos,DeskTop;

{$I MESSAGE.DEF }
{$I COLORS.DEF }

  Const Batch     : String = 'ECHO OFF'#13#10':$AGAIN'#13#10;
        BatchName : String = ':\PCH.BAT';
        MenuName  : String = 'PCHOICE.MNU';
        UndoName  : String = 'PCHOICE.UDO';
        ShowSerial: Boolean = False;

  Type  ConfigRec= Record
                     JMP       : String[4];
                     ID        : String[6];
                     Msave     : Byte;
                     Video     : Byte;
                     Path      : String[30];
                     Item      : Byte;
                     Group     : Byte;
                     PW        : Byte;
                     Status    : Byte;
                     Clock     : Byte;
                     Wait      : Boolean;
                   End;
        MenuFile = Text;
        PWStr    = String[10];
        NameStr  = String[40];
        MessStr  = String[80];
        ItemPtr  = ^Item;
        Item     = Object
                     No        : Byte;
                     Name      : NameStr;
                     Message   : MessStr;
                     Password  : PWStr;
                     Typ       : Byte;
                     GroupNo   : Byte;
                     Next,Prev : ItemPtr;
                     Path      : PathStr;
                     Commands  : String;
                     Wait      : Boolean;
                     Clock     : Boolean;
                     Constructor Init(N:Byte);
                     Procedure   Show;
                     Function    Edit:Boolean;
                     Procedure   Run;
                     Function    ReadF(Var F:MenuFile):Word;
                     Function    WriteF(Var F:MenuFile):Word;
                     Destructor  Done;
                   End;
        GroupPtr = ^Group;
        Group    = Object
                     No        : Byte;
                     Name      : NameStr;
                     Current   : ItemPtr;
                     Next      : GroupPtr;
                     Items     : Byte;
                     Parent    : Byte;
                     Procedure   FirstItem;
                     Procedure   LastItem;
                     Constructor Init(N:Byte);
                     Procedure   Rearrange;
                     Procedure   ChangeItem;
                     Procedure   InsertItem;
                     Procedure   DeleteItem;
                     Function    Choose:Word;
                     Procedure   Show;
                     Function    ReadF(Var F:MenuFile):Word;
                     Function    WriteF(Var F:MenuFile):Word;
                     Destructor  Done;
                   End;
        MenuObj  = Object
                     LogOnPW   : PWStr;
                     DOSPW     : PWStr;
                     EditPW    : PWStr;
                     ModulePW  : PWStr;
                     Current   : GroupPtr;
                     Constructor Init;
                     Procedure   Edit;
                     Procedure   SwitchGroup(N:Byte);
                     Procedure   ChangePasswords;
                     Procedure   Run;
                     Procedure   Undo;
                     Procedure   SaveFile;
                     Function    ReadF:Word;
                     Procedure   WriteF;
                     Destructor  Done;
                     Procedure   Create;
                   End;

  Var   Copyright: String;
        Serial   : String;
        Version  : String;
        Config   : ^ConfigRec;
        Menu     : MenuObj;

  Procedure Check_Low_Level;
  Procedure Prepare_Screen;
  Procedure Read_Menu;
  Procedure SetGroupItem;
  Procedure PutInfo(N:Byte);
  Procedure PutMsg(N:Byte);

Implementation
  Const GroupX : Byte = 15;

  Var GroupWin   : MessageWindow;
      Memory     : LongInt;
      F          : EntryScreen;
      ExitSave   : Pointer;
      UsedGroups : Set Of Byte;
      NotSaved   : Boolean;

  Function UpperCase(S:String):String;
  Var T : String;
      I : Byte;
  Begin
    T:=S;
    For I:=1 To Length(T) Do T[I]:=UpCase(T[I]);
    UpperCase:=T;
  End;

  Procedure PutInfo(N:Byte);
  Var I : Byte;
  Begin
    AbsWrite(2,25,InfoStr[N]);
    For I:=Length(InfoStr[N])+2 To 52 Do AbsWrite(I,25,' ');
  End;

  Procedure PutMsg(N:Byte);
  Var W  : MessageWindow;
      CH : Char;
      I  : Byte;
  Begin
    New(W,Init(15,8,65,11,WinClr[MsgClr],''));
    W^.Show;
    Center(MessageStr[N]);
    Writeln;
    Center(Press_any_key);
    PutInfo(2);
    For I:=1 To 4 Do
    Begin
      Sound(1000+(I Mod 2)*500);
      Delay(40);
    End;
    NoSound;
    CH:=Readkey;
    Dispose(W,Done);
  End;

  Procedure Resetbatch;
  Var F : Text;
  Begin
    Assign(F,BatchName);
    Rewrite(F);
    Writeln(F,Batch);
    Writeln(F,'VER');
    Close(F);
  End;

  Function PWAsk(PW:PWStr;Msg:String):Boolean;
  Var S  : PWStr;
      X  : Byte;
      W  : MessageWindow;
      CH : Char;
  Begin
    If PW='' Then
    Begin
      PWAsk:=True;
      Exit;
    End;
    New(W,Init(22,8,58,13,WinClr[PWClr],'- - Password o─╖ - -'));
    W^.Show;
    Center(Msg);
    GotoXY(13,3);
    Write('[..........]');
    X:=1;
    S:='';
    Cursor.Full;
    Repeat
      GotoXY(13+X,3);
      CH:=Readkey;
      Case CH Of #13 :;
                 #27 :;
                 #0  :;
                 #8  : If X>1 Then
                       Begin
                         Dec(X);
                         Delete(S,X,1);
                         GotoXY(13+X,3);
                         Write('.');
                       End Else Keybeep;
                 Else If X<=10 Then
                 Begin
                   Write('X');
                   S:=S+CH;
                   Inc(X);
                 End Else Keybeep;

      End;
    Until CH In [#13,#27];
    Cursor.Off;
    Dispose(W,Done);
    If (CH=#13) And (S<>PW) Then
    Begin
      New(W,Init(22,8,58,13,WinClr[ADClr],''));
      W^.Show;
      GotoXY(1,2);
      Center(Access_denied);
      Sound(2000);
      Delay(250);
      NoSound;
      GotoXY(1,4);
      Center(Press_any_key);
      CH:=ReadKey;
      Dispose(W,Done);
    End;
    PWAsk:=(CH=#13) And (S=PW);
  End;

  Function Decide(S:String;C,L:Byte):Byte;
  Var M : MenuWindow;
      I : Byte;
  Begin
    If L<21 Then L:=21;
    New(M,Init(5,10,5+L,11+C,WinClr[MsgClr],Do_you_want_to));
    M^.Show;
    Write(S);
    PutInfo(3);
    Decide:=M^.Choose;
    Dispose(M,Done);
  End;

  Function Sure:Boolean;
  Var CH : Char;
      W  : MessageWindow;
  Begin
    New(W,Init(47,19,75,21,WinClr[EditClr],SureHL));
    W^.Show;
    Write(' ',SureMsg);
    PutInfo(7);
    Repeat
      CH:=UpCase(ReadKey);
    Until CH In [_Yes,_No];
    Sure:=(CH=_Yes);
    Dispose(W,Done);
  End;

  Function Error(N:Word):Byte;
  Var W  : MessageWindow;
      CH : Char;
  Begin
    If N=0 Then
    Begin
      Error:=0;
      Exit;
    End;
    If N<6 Then
    Begin
      Error:=N;
      Exit;
    End;
    New(W,Init(7,5,40,9,WinClr[ErrorClr],'Error'));
    W^.Show;
    Writeln('I/O-Error #',N);
    Case N Of 152 : Writeln('Disk drive not ready');
              150 : Writeln('Disk is write protected');
              156 : Writeln('Disk seek error');
              158 : Writeln('Sector not found');
              160 : Writeln('Device write fault');
              161 : Writeln('Device read fault');
              162 : Writeln('Hardware failure');
    End;
    Write(Retry_Abort);
    Repeat
      CH:=UpCase(Chr(Lo(ReadKbd)));
    Until CH In ['A','R'];
    If CH='R' Then Error:=1 Else Error:=2;
    Dispose(W,Done);
  End;

  Procedure ChDrive(D:Char);
  Var Regs : Registers;
  Begin
    Regs.AH:=14;
    Regs.DL:=Ord(D)-65;
    MsDos(Regs);
  End;

  Constructor Item.Init(N:Byte);
  Begin
    No:=N;
    Typ:=1;
    GroupNo:=0;
    Name:='';
    Message:='';
    Password:='';
    Path:='';
    Commands:='';
    Wait:=False;
    Clock:=False;
    Next:=Nil;
    Prev:=Nil;
  End;

  Destructor Item.Done;
  Var C : ItemPtr;
      G : GroupPtr;
  Begin
    Next^.Prev:=Prev;
    Prev^.Next:=Next;
    C:=Next;
    While C<>Nil Do
    Begin
      Dec(C^.No);
      C:=C^.Next;
    End;
    If Typ=2 Then
    Begin
      G:=Menu.Current;
      While G^.No<>GroupNo Do G:=G^.Next;
      Dispose(G,Done);
    End;
  End;

  Procedure Item.Show;
  Begin
    Write(' ',Chr(No+65),'» ',Name);
  End;

  Function Item.Edit:Boolean;
  Var W:MessageWindow;
      CH:Char;
      N,M,P1,P2,C : String;
      CLK,WT      : String[1];
      Temp        : String;
      G           : GroupPtr;
  Begin
    If Not PWAsk(Password,ItemPWMsg) Then Exit;
    N:=Name;
    M:=Message;
    P1:=Password;
    If Typ=1 Then
    Begin
      P2:=Path;
      C:=Commands;
      If Clock Then CLK:='Y' Else CLK:='N';
      If Wait  Then WT:='Y' Else WT:='N';
      New(W,Init(10,10,65,20,WinClr[EditClr],'Edit Command Item'));
      W^.Show;
      GotoXY(2,2);
      Write(         'Item No. : ',Chr(No+65));
      F.Init('D');
      F.AddEntry(2,3,'Name     :',N,40,40);
      F.AddEntry(2,4,'Message  :',M,80,40);
      F.AddEntry(2,5,'Password :',P1,10,10);
      F.AddEntry(2,6,'Path     :',P2,79,40);
      F.AddEntry(2,7,'Commands :',C,254,40);
      F.AddEntry(2,8,'Clock ?  :',CLK,1,1);
      F.AddEntry(30,8,'Wait ?  :',WT,1,1);
      PutInfo(6);
      CH:=F.Use;
    End Else
    Begin
      New(W,Init(10,10,65,17,WinClr[EditClr],'Edit Group Item'));
      W^.Show;
      GotoXY(2,2);
      Write(         'Item No. : ',Chr(No+65));
      F.Init('D');
      F.AddEntry(2,3,'Name     :',N,40,40);
      F.AddEntry(2,4,'Message  :',M,80,40);
      F.AddEntry(2,5,'Password :',P1,10,10);
      PutInfo(6);
      CH:=F.Use;
    End;
    If (CH='D') And Sure Then
    Begin
      If Typ=1 Then
      Begin
        GetDir(0,Temp);
        ChDir(P2);
        If IOResult<>0 Then PutMsg(5) Else GetDir(0,P2);
        ChDir(Temp);
        If C='' Then PutMsg(2);
        Path:=P2;
        Commands:=C;
        Wait:=(WT='Y');
        Clock:=(CLK='Y');
      End Else
      Begin If GroupNo<>0 Then
        Begin
          G:=Menu.Current;
          While G^.No<>GroupNo Do G:=G^.Next;
          G^.Name:=N;
        End;
      End;
      Name:=N;
      Message:=M;
      Password:=P1;
      Edit:=True;
    End Else Edit:=False;
    F.Done;
    Dispose(W,Done);
  End;

  Procedure Item.Run;
  Var F   : File;
      B   : Text;
      S,C : String;
      IO  : Word;
      T   : Byte;

    Procedure CheckCall(Var S:String);
    Var T : Byte;
    Begin
      If DosVersion<>$2003 Then Exit;
      T:=Pos('CALL',UpperCase(S));
      If T<>0 Then
      Begin
        Delete(S,T,4);
        Insert('COMMAND /C ',S,T);
      End;
    End;

  Begin
    If Not PWAsk(Password,ItemPWMsg) Then Exit;
    If Typ=2 Then
    Begin
      Menu.SwitchGroup(GroupNo);
      Exit;
    End;
    If Commands='' Then
    Begin
      PutMsg(2);
      Exit;
    End;
    ChDir(Path);
    If IOResult<>0 Then
    Begin
      PutMsg(5);
      Exit;
    End;
    ChDrive(Path[1]);
    Assign(B,BatchName);
    Repeat
      Rewrite(B);
      IO:=Error(IOResult);
      If IO=2 Then Exit;
    Until IO=0;
    Writeln(B,Batch);
    S:=Commands;
    While Pos('│',S)<>0 Do
    Begin
      C:=Copy(S,1,Pos('│',S)-1);
      Delete(S,1,Pos('│',S));
      CheckCall(C);
      Writeln(B,C);
    End;
    CheckCall(S);
    Writeln(B,S);
    Writeln(B,'GOTO $AGAIN');
    Close(B);
    If IOResult<>0 Then
    Begin
      PutMsg(10);
      Exit;
    End;
    Config^.Status:=1;
    Config^.Wait:=Wait;
    If Clock Then Config^.Clock:=255 Else Config^.Clock:=0;
    Config^.Item:=No;
    Config^.Group:=Menu.Current^.No;
    Window(1,1,80,25);
    NormVideo;
    ClrScr;
    Halt;
  End;

  Function Item.ReadF(Var F:MenuFile):Word;
  Var C : Char;
  Begin
    Readln(F,Name);
    Readln(F,Message);
    Readln(F,Password);
    Readln(F,Typ);
    If Typ=1 Then
    Begin
      Readln(F,Path);
      Readln(F,Commands);
      Read(F,C);
      If C='X' Then Clock:=True Else Clock:=False;
      Read(F,C);
      If C='X' Then Wait:=True Else Wait:=False;
    End Else Readln(F,GroupNo);
    ReadF:=IOResult;
  End;

  Function Item.WriteF(Var F:MenuFile):Word;
  Begin
    Writeln(F,Name);
    Writeln(F,Message);
    Writeln(F,Password);
    Writeln(F,Typ);
    If Typ=1 Then
    Begin
      Writeln(F,Path);
      Writeln(F,Commands);
      If Clock Then Write(F,'X') Else Write(F,' ');
      If Wait Then Write(F,'X') Else Write(F,' ');
    End Else Writeln(F,GroupNo);
    WriteF:=IOResult;
  End;

  Procedure Group.FirstItem;
  Begin
    If Current=Nil Then Exit;
    While Current^.Prev<>Nil Do Current:=Current^.Prev;
  End;

  Procedure Group.LastItem;
  Begin
    If Current=Nil Then Exit;
    While Current^.Next<>Nil Do Current:=Current^.Next;
  End;

  Constructor Group.Init(N:Byte);
  Begin
    No:=N;
    UsedGroups:=UsedGroups+[N];
    Parent:=0;
    Name:='';
    Current:=Nil;
    Items:=0;
    Next:=@Self;
  End;

  Procedure Group.Rearrange;
  Var CH  : Word;
      Y   : Byte;
      I,C : ItemPtr;
  Begin
    If Items<2 Then
    Begin
      PutMsg(8+Items);
      Exit;
    End;
    PutInfo(11);
    CH:=Choose;
    PutInfo(12);
    I:=Current;
    If I^.Prev<>Nil Then Current:=I^.Prev
                    Else Current:=I^.Next;
    I^.Prev^.Next:=I^.Next;
    I^.Next^.Prev:=I^.Prev;
    FirstItem;
    Y:=I^.No+1;
    Repeat
      Show;
      GotoXY(3,Y+1);
      InsLine;
      Write('-> ',I^.Name);
      InvLine(Y+1);
      CH:=ReadKbd;
      Case Ch Of 256+72 : Dec(Y);
                 256+80 : Inc(Y);
                 13     : Begin
                            C:=I^.Next;
                            While C<>Nil Do
                            Begin
                              Dec(C^.No);
                              C:=C^.Next;
                            End;
                            If Y=Items Then
                            Begin
                              LastItem;
                              Current^.Next:=I;
                              I^.No:=Items-1;
                              I^.Next:=Nil;
                              I^.Prev:=Current;
                            End Else
                            Begin
                              While Current^.No<>Y-1 Do Current:=Current^.Next;
                              I^.Next:=Current;
                              I^.Prev:=Current^.Prev;
                              Current^.Prev^.Next:=I;
                              Current^.Prev:=I;
                              While Current<>Nil Do
                              Begin
                                Inc(Current^.No);
                                Current:=Current^.Next;
                              End;
                              I^.No:=Y-1;
                            End;
                            Current:=I;
                            Menu.WriteF;
                          End;
                 27     : Begin
                            I^.Prev^.Next:=I;
                            I^.Next^.Prev:=I;
                          End;
                 Else Keybeep;
      End;
      If Y<1 Then Y:=Items;
      If Y>Items Then Y:=1;
    Until (CH=13) Or (CH=27);
  End;

  Procedure Group.ChangeItem;
  Begin
    If Items=0 Then PutMsg(3)
    Else Begin
      PutInfo(4);
      If Choose<>27 Then If Current^.Edit Then Menu.WriteF;
    End;
  End;

  Procedure Group.InsertItem;
  Var C   : ItemPtr;
      G   : GroupPtr;
      Y,X : Byte;
      CH  : Word;
  Begin
    If Items=15 Then PutMsg(4) Else
    Begin
      Y:=1;
      If Items>0 Then
      Begin
        PutInfo(8);
        Inc(Items);
        Repeat
          Show;
          GotoXY(1,Y+1);
          InsLine;
          Write(New_Items_Pos);
          InvLine(Y+1);
          CH:=ReadKbd;
          Case CH Of 256+72 : Dec(Y);
                     256+80 : Inc(Y);
                     27,13  : ;
                     Else Keybeep;
          End;
          If Y<1 Then Y:=Items;
          If Y>Items Then Y:=1;
        Until (CH=13) Or (CH=27);
        Dec(Items);
        If CH=27 Then Exit;
      End;
      New(C,Init(Y-1));
      C^.Typ:=Decide(Group_or_Command,2,20);
      Case C^.Typ Of 0 : Dispose(C,Done);
                     1 : If C^.Edit Then
                         Begin
                         Inc(Items);
                         If Items<>1 Then
                         Begin
                           If Y=Items Then
                           Begin
                             LastItem;
                             Current^.Next:=C;
                             C^.Prev:=Current;
                           End Else
                           Begin
                             FirstItem;
                             While Current^.No<>Y-1 Do Current:=Current^.Next;
                             C^.Next:=Current;
                             C^.Prev:=Current^.Prev;
                             Current^.Prev^.Next:=C;
                             Current^.Prev:=C;
                             While Current<>Nil Do
                             Begin
                               Inc(Current^.No);
                               Current:=Current^.Next;
                             End;
                           End;
                         End;
                         Current:=C;
                         Menu.WriteF;
                       End Else Dispose(C,Done);
                   2 : If C^.Edit Then
                       Begin
                         Inc(Items);
                         If Items<>1 Then
                         Begin
                           If Y=Items Then
                           Begin
                             LastItem;
                             Current^.Next:=C;
                             C^.Prev:=Current;
                           End Else
                           Begin
                             FirstItem;
                             While Current^.No<>Y-1 Do Current:=Current^.Next;
                             C^.Next:=Current;
                             C^.Prev:=Current^.Prev;
                             Current^.Prev^.Next:=C;
                             Current^.Prev:=C;
                             While Current<>Nil Do
                             Begin
                               Inc(Current^.No);
                               Current:=Current^.Next;
                             End;
                           End;
                         End;
                         Current:=C;
                         X:=0;
                         While X In UsedGroups Do Inc(X);
                         New(G,Init(X));
                         G^.Parent:=No;
                         G^.Name:=C^.Name;
                         G^.Next:=Next;
                         C^.GroupNo:=X;
                         Next:=G;
                         Menu.WriteF;
                       End Else Dispose(C,Done);
      End;
    End;
  End;

  Procedure Group.DeleteItem;
  Var CH : Char;
      W  : MessageWindow;
      IO : Word;
      C  : ItemPtr;
      G  : GroupPtr;
  Begin
    If Items=0 Then PutMsg(3)
    Else Begin
      PutInfo(5);
      If Choose<>27 Then
      Begin
        If Current^.Typ=2 Then
        Begin
          G:=Menu.Current;
          While G^.No<>Current^.GroupNo Do G:=G^.Next;
          If G^.Items<>0 Then
          Begin
            PutMsg(7);
            Exit;
          End;
        End;
        If Not PWAsk(Current^.Password,ItemPWMsg) Then Exit;
        New(W,Init(10,10,59,12,WinClr[EditClr],SureHL));
        W^.Show;
        Write(' ',SureDeleteMsg);
        Repeat
          CH:=UpCase(ReadKey);
        Until CH In [_Yes,_No];
        Dispose(W,Done);
        If CH=_No Then Exit;
        Dec(Items);
        C:=Current;
        If Current^.Next<>Nil Then Current:=Current^.Next
                              Else Current:=Current^.Prev;
        Dispose(C,Done);
        Menu.WriteF;
      End;
    End;
  End;

  Procedure Group.Show;
  Var C : ItemPtr;
      Y : Byte;
  Begin
    GroupWin^.HL:=Name;
    GroupWin^.ReSize(GroupX,4,GroupX+50,Max(7+Items,8));
    If Items=0 Then
    Begin
      GotoXY(3,2);
      Writeln(Group_is_empty);
    End Else
    Begin
      C:=Current;
      While C^.Prev<>Nil Do C:=C^.Prev;
      Y:=1;
      Repeat
        GotoXY(2,Y+1);
        C^.Show;
        C:=C^.Next;
        Inc(Y);
      Until C=Nil;
    End;
  End;

  Function Group.Choose:Word;
  Var I  : Byte;
      CH : Word;
  Begin
    GroupWin^.Show;
    Repeat
      If Items>0 Then
      Begin
        InvLine(Current^.No+2);
        AbsWrite(1,23,Current^.Message+
                 MakeStr(' ',80-Length(Current^.Message)));
        CH:=ReadKbd;
        InvLine(Current^.No+2);
      End Else CH:=ReadKbd;
      If (CH<256) And (CH In [97..122]) Then Dec(CH,32);
      Case CH Of 256+72 : If Current^.Prev<>Nil Then
                            Current:=Current^.Prev
                          Else
                            LastItem;
                 256+80,32 : If Current^.Next<>Nil Then
                            Current:=Current^.Next
                          Else
                            FirstItem;
                 9,13,27: ;
                 Else If (Not ((CH>64) And (CH<65+Items))) And (CH<256)
                   Then Keybeep;
      End;
      If (CH>64) And (CH<65+Items) Then
      Begin
        FirstItem;
        While Current^.No<>CH-65 Do Current:=Current^.Next;
        CH:=13;
      End;
    Until (CH=9) Or (CH=13) Or (CH=27) Or ((CH>256+58) And (CH<256+69));
    AbsWrite(1,23,MakeStr(' ',80));
    If (CH=13) And (Items=0) Then CH:=0;
    Choose:=CH;
  End;

  Function Group.ReadF(Var F:MenuFile):Word;
  Var IO : Word;
      C  : Byte;
      P  : ItemPtr;
  Begin
    Readln(F,Name);
    Readln(F,Items);
    Readln(F,Parent);
    Current:=Nil;
    IO:=IOResult;
    If (IO=0) And (Items>0) Then
    Begin
      For C:=0 To Items-1 Do If IO=0 Then
      Begin
        New(P,Init(C));
        IO:=P^.ReadF(F);
        If Current=Nil Then Current:=P
        Else
        Begin
          P^.Prev:=Current;
          Current^.Next:=P;
          Current:=P;
        End;
        If IO<>0 Then Items:=C+1;
      End;
      FirstItem;
    End;
    ReadF:=IO;
  End;

  Function Group.WriteF(Var F:MenuFile):Word;
  Var P  : ItemPtr;
      IO : Word;
  Begin
    Writeln(F,Name);
    Writeln(F,Items);
    Writeln(F,Parent);
    IO:=IOResult;
    If (IO=0) And (Items>0) Then
    Begin
      P:=Current;
      While P^.Prev<>Nil Do P:=P^.Prev;
      While (P<>Nil) And (IO=0) Do
      Begin
        IO:=P^.WriteF(F);
        P:=P^.Next;
      End;
    End;
    WriteF:=IO;
  End;

  Destructor Group.Done;
  Var C : ItemPtr;
      G : GroupPtr;
  Begin
    FirstItem;
    While Current<>Nil Do
    Begin
      C:=Current^.Next;
      Dispose(Current,Done);
      Current:=C;
    End;
    G:=@Self;
    While G^.Next<>@Self Do G:=G^.Next;
    G^.Next:=Next;
    UsedGroups:=UsedGroups-[No];
  End;

  Procedure Info;
  Var W  : MessageWindow;
      CH : Char;
  Begin
    New(W,Init(14,5,66,20,WinClr[MsgClr],'Program Info'));
    W^.Show;
    PutInfo(2);
    Writeln;
    Center('Power-Choice Version 1.0e');
    Writeln;
    Center('(C) 1990 Softwhere Associates');
    Writeln;
    Writeln;
    HighVideo;
    Write('    Programming+Design : ');
    LowVideo;
    Writeln('Olaf Gottschalk');
    HighVideo;
    Write('    Documentation      : ');
    LowVideo;
    Writeln('Robert W. Codner');
    Writeln('                         and Olaf Gottschalk');
    HLine(1,51,WhereY,'─');
    Center('Special Thanks to my parents who gave me a chance');
    Writeln;
    Center('to experience more than I ever expected !');
    Writeln;
    HighVideo;
    Writeln('                         Olaf Gottschalk, May ''90');
    HLine(1,51,WhereY,'─');
    LowVideo;
    Writeln;
    If ShowSerial Then Center(' Registered Serial Number is '+Serial);
    CH:=ReadKey;
    Dispose(W,Done);
  End;

  Procedure MenuObj.ChangePasswords;
  Var L,E,D,M : PWStr;
      W       : MessageWindow;
      IO      : Word;
      CH      : Char;
  Begin
    L:=LogOnPW;
    E:=EditPW;
    D:=DOSPW;
    M:=ModulePW;
    New(W,Init(25,15,56,23,WinClr[EditClr],'Change Passwords'));
    W^.Show;
    F.Init('D');
    F.AddEntry(2,2,'Log On Password :',L,10,10);
    F.AddEntry(2,4,'Edit Password   :',E,10,10);
    F.AddEntry(2,6,'DOS Password    :',D,10,10);
    PutInfo(6);
    CH:=F.Use;
    If CH='D' Then
    Begin
      If Sure Then
      Begin
        LogOnPW:=L;
        EditPW:=E;
        DOSPW:=D;
        ModulePW:=M;
        Menu.WriteF;
      End;
    End;
    F.Done;
    Dispose(W,Done);
  End;

  Constructor MenuObj.Init;
  Begin
    LogOnPW:='';
    DOSPW:='';
    EditPW:='';
    Current:=Nil;
    UsedGroups:=[];
  End;

  Procedure MenuObj.SwitchGroup(N:Byte);
  Begin
    If Not (N In UsedGroups) Then Exit;
    While Current^.No<>N Do Current:=Current^.Next;
    Current^.Show;
  End;

  Procedure MenuObj.Edit;
  Var EditMenu : MenuWindow;
      I        : Byte;
      Itm      : ItemPtr;
      Grp      : Group;
      CH       : Char;
      W        : MessageWindow;
      S        : String[3];
  Begin
    If MaxAvail<20*1024 Then
    Begin
      PutMsg(6);
      Exit;
    End;
    If Not PWAsk(EditPW,EditPWMsg) Then Exit;
    New(EditMenu,Init(4,4,23,19,WinClr[EditClr],'Edit Mode'));
    EditMenu^.Show;
    For I:=1 To 13 Do Write(' ',EditChoice[I],' ');
    Write(' ',EditChoice[14]);
    EditMenu^.NoChoice([1,5,9,12,14]);
    GroupX:=29;
    Repeat
      Current^.Show;
      PutInfo(3);
      I:=EditMenu^.Choose;
      GroupWin^.Show;
      Case I Of 0,13 : If NotSaved Then
                       Begin
                       End;
                2    : Current^.ChangeItem;
                3    : Current^.InsertItem;
                4    : Current^.DeleteItem;
                6    : ChangePasswords;
                7    : Current^.Rearrange;
                8    : WriteF;
                10   : Begin
                         New(W,Init(14,10,56,15,WinClr[EditClr],'Are you sure ??'));
                         W^.Show;
                         LowVideo;
                         Writeln(' The next step will undo only  the  LAST');
                         Writeln(' change you made ! Do you REALLY want to');
                         Writeln(' proceed ? Then, type YES !');
                         Write(' Proceed ? ');HighVideo;Write('No');
                         Cursor.Full;
                         Repeat Until Keypressed;
                         GotoXY(WhereX-2,4);
                         Readln(S);
                         Cursor.Off;
                         Dispose(W,Done);
                         For I:=1 To 3 Do S[I]:=UpCase(S[I]);
                         I:=9;
                         If S='YES' Then Undo;
                       End;
                11   : Begin
                         New(W,Init(14,10,56,15,WinClr[EditClr],'Are you sure ??'));
                         W^.Show;
                         LowVideo;
                         Writeln(' The next step will totally  erase  your');
                         Writeln(' complete menu structure ! Do you REALLY');
                         Writeln(' want to proceed ? Then, type YES !');
                         Write(' Proceed ? ');HighVideo;Write('No');
                         Cursor.Full;
                         Repeat Until Keypressed;
                         GotoXY(WhereX-2,4);
                         Write('  ');
                         GotoXY(WhereX-2,4);
                         Readln(S);
                         Cursor.Off;
                         Dispose(W,Done);
                         For I:=1 To 3 Do S[I]:=UpCase(S[I]);
                         I:=10;
                         If S='YES' Then Create;
                       End;
      End;
    Until I In [0,13];
    Dispose(EditMenu,Done);
    GroupX:=15;
    GroupWin^.Move(15,4);
  End;

  Function MenuObj.ReadF:Word;
  Var F  : MenuFile;
      IO : Word;
      C  : Byte;
      P  : GroupPtr;
  Begin
    Done;
    PutInfo(1);
    Assign(F,MenuName);
    Repeat
      Reset(F);
      IO:=Error(IOResult);
      ReadF:=IO;
      If IO=2 Then Exit;
    Until IO=0;
    Readln(F,LogOnPW);
    Readln(F,DOSPW);
    Readln(F,EditPW);
    Readln(F,ModulePW);
    IO:=IOResult;
    If IO=0 Then
    Begin
      Readln(F,C);
      New(Current,Init(0));
      IO:=Current^.ReadF(F);
      While (IO=0) And (Not EoF(F)) Do
      Begin
        Readln(F,C);
        New(P,Init(C));
        IO:=P^.ReadF(F);
        P^.Next:=Current^.Next;
        Current^.Next:=P;
      End;
      If IO=0 Then Close(F);
    End;
    If IO<>0 Then Current:=Nil;
    ReadF:=IO;
  End;

  Procedure MenuObj.Undo;
  Var F1,F2 : File;
      IO    : Word;
  Begin
    Assign(F1,UndoName);
    Assign(F2,MenuName);
    Reset(F1);
    IO:=IOResult;
    If IO=0 Then
    Begin
      Close(F1);
      Erase(F2);
      Rename(F1,MenuName);
      IO:=IOResult;
    End;
    If IO<>0 Then
    Begin
      WriteF;
      PutMsg(13);
    End Else IO:=ReadF;
  End;

  Procedure MenuObj.SaveFile;
  Var F  : File;
      IO : Word;
  Begin
    Assign(F,UndoName);
    Erase(F);
    IO:=IOResult;
    Assign(F,MenuName);
    Rename(F,UndoName);
    IO:=IOResult;
    If IO<>0 Then
    Begin
      Undo;
      PutMsg(14);
    End;
  End;

  Procedure MenuObj.WriteF;
  Var F  : MenuFile;
      IO : Word;
      P  : GroupPtr;
  Begin
    PutInfo(10);
    SaveFile;
    Assign(F,MenuName);
    Repeat
      Rewrite(F);
      IO:=Error(IOResult);
    Until IO<>1;
    If IO=0 Then
    Begin
      Writeln(F,LogOnPW);
      Writeln(F,DOSPW);
      Writeln(F,EditPW);
      Writeln(F,ModulePW);
      IO:=IOResult;
      If IO=0 Then
      Begin
        P:=Current;
        While P^.No<>0 Do P:=P^.Next;
        Repeat
          Writeln(F,P^.No);
          IO:=P^.WriteF(F);
          P:=P^.Next;
        Until (P^.No=0) Or (IO<>0);
        If IO=0 Then Close(F);
      End;
    End;
    Case IO Of 101 : PutMsg(12);
               0   : ;
               Else PutMsg(11);
    End;
    If IO<>0 Then NotSaved:=True;
  End;

  Procedure MenuObj.Run;
  Var CH : Word;
      W  : MessageWindow;
  Begin
    Current^.Show;
    Repeat
      If Current^.Items=0 Then PutInfo(13) Else PutInfo(9);
      If Current^.No<>0 Then AbsWrite(44,7+Max(Current^.Items,1),' TAB-Parent Group ');
      CH:=Current^.Choose;
      Case CH Of 9      : If Current^.No=0 Then Keybeep
                            Else SwitchGroup(Current^.Parent);
                 13     : Current^.Current^.Run;
                 27     : If PWAsk(DOSPW,DOSPWMsg) Then With Config^ Do
                          Begin
                            Resetbatch;
                            Status:=2;
                            Clock:=255;
                            Group:=Current^.No;
                            Item:=Current^.Current^.No;
                            Window(1,1,80,25);
                            NormVideo;
                            ClrScr;
                            New(W,Init(1,1,45,3,WinClr[WaitClr],''));
                            W^.Show;
                            Write(' ',Type_PCH_to_return);
                            Window(1,1,80,25);
                            GotoXY(1,4);
                            ChDir('\');
                            Halt;
                          End;
                 256+60 : Edit;
                 256+59 : Info;
      End;
    Until False;
  End;

  Procedure MenuObj.Create;
  Begin
    Done;
    New(Current,Init(0));
    Current^.Name:='Main Group';
    Menu.WriteF;
  End;

  Destructor MenuObj.Done;
  Var C : GroupPtr;
  Begin
    If Current=Nil Then Exit;
    While Current^.No<>0 Do Current:=Current^.Next;
    Dispose(Current,Done);
    LogOnPW:='';
    DOSPW:='';
    EditPW:='';
    ModulePW:='';
  End;

  Procedure Prepare_Screen;
  Begin
    Window(1,1,80,25);
    Cursor.Off;
    SetColor(WinClr[BGClr,1]);
    ClrScr;
    HLine(1,80,2,'─');
    HLine(1,80,24,'─');
    GotoXY(58,24);
    Write('┤ ',Round(Memory/1024):3,' KB ',Memory_free,' ├');
    SetColor(WinClr[BGClr,3]);
    GotoXY(1,1);
    ClrEol;
    Center('* * *  P O W E R - C H O I C E  '+Version+'  * * *');
    GotoXY(1,25);
    ClrEol;
    GotoXY(53,25);
    Write('│',Copyright);
    Time.On(68,1);
    Date.On(3,1);
    New(GroupWin,Init(15,4,65,20,WinClr[GroupClr],''));
  End;

  Procedure Check_Low_Level;
  Var W  : MessageWindow;
      CH : Char;
  Begin
    GetIntVec($60,Pointer(Config));
    With Config^ Do
    Begin
      If ID<>'PCH100' Then
      Begin
        Window(1,1,80,25);
        NormVideo;
        ClrScr;
        Writeln('Power-Choice ',Version);
        Writeln('Fatal error: #1 Low level application not found !');
        Writeln;
        Halt(1);;
      End;
      If Video=Color Then WinClr:=_Color Else
      Begin
        WinClr:=_Mono;
        InvByte:=$77;
      End;
      Batch:=Batch+Path+'PCHOICE';
      BatchName:=Path[1]+BatchName;
      MenuName:=Path+MenuName;
      UndoName:=Path+UndoName;
      If Status=1 Then
      Begin
        If Wait Then
        Begin
          New(W,Init(40,23,79,25,WinClr[WaitClr],''));
          W^.Show;
          Write(' ',Press_ESC_to_return);
          Repeat
            CH:=ReadKey;
          Until CH=#27;
          Dispose(W,Done);
          Wait:=False;
        End;
      End;
      Clock:=0;
    End;
  End;

  Procedure Read_Menu;
  Var B : Word;
  Begin
    Repeat
      B:=Menu.ReadF;
      If B<>0 Then
      Begin
        Config^.Status:=0;
        PutMsg(1);
        B:=Decide(Choice1,3,21);
        Case B Of 1   : B:=Menu.ReadF;
                  2   : Begin
                          Menu.Create;
                          Menu.Edit;
                        End;
                  0,3 : Begin
                          Window(1,1,80,25);
                          NormVideo;
                          ClrScr;
                          Halt;
                        End;
        End;
      End;
    Until B=0;
  End;

  Procedure SetGroupItem;
  Var C : Byte;
  Begin
    If Config^.Status=0 Then
    Begin
      C:=0;
      Repeat
        Inc(C);
        If C=4 Then Inline($B8/$40/$00/$8E/$D8/$B8/$7F/$7F/
                           $A3/$72/$00/$EA/$00/$00/$FF/$FF);
      Until PWAsk(Menu.LogOnPW,LogOnPWMsg);
      Exit;
    End;
    With Menu,Config^ Do
    Begin
      If Group In UsedGroups Then
        While Current^.No<>Group Do Current:=Current^.Next;
      With Current^ Do
      Begin
        FirstItem;
        If Item<Items Then
          While Current^.No<>Item Do Current:=Current^.Next;
      End;
      Status:=0;
    End;
  End;

  {$F+}
  Procedure NewExit;
  Begin
    {$F-}
    Cursor.On;
    ExitProc:=ExitSave;
    {$F+}
  End;
  {$F-}

Begin
  If ParamStr(1)='/SN' Then ShowSerial:=True;
  Menu.Init;
  ExitSave:=ExitProc;
  ExitProc:=@NewExit;
  Memory:=MemAvail+79*1024;
  NotSaved:=False;
End.
