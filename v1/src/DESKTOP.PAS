{$A+,B-,D+,E-,F-,I+,L+,N-,O-,R-,S-,V-}
Unit DeskTop;
Interface
  Uses Crt,Dos;
  Const InvByte : Byte = 63;
  Type Str20     = String[20];
       Str40     = String[40];
       Str80     = String[80];
       StrPtr    = ^String;
       SaveType  = Array[1..4000] Of Byte;
       SavePtr   = ^SaveType;
       ColorSet  = Array[1..2] Of Byte;
       DTColor   = Array[1..3] Of ColorSet;

       MessageWin= Object
                     XMAX,XMIN,
                     YMAX,YMIN : Byte;
                     ID        : Byte;
                     COLOR     : Array[1..3] Of Byte;
                     HL        : Str80;
                     SAVE      : SavePtr;
                     SIZE      : Word;
                     ATTRIBUTES: Record
                                   STYLED : Boolean;
                                   CSIZE  : Word;
                                   X,Y    : Byte;
                                   X1,Y1,
                                   X2,Y2  : Integer;
                                   ATTR   : Byte;
                                 End;
                     CLEARPROC : Procedure;
                     Procedure   AttrSave;
                     Procedure   AttrSet;
                     Constructor Init(X1,Y1,X2,Y2:Byte;C:DTColor;H:Str80);
                     Procedure   Clear; virtual;
                     Procedure   Show;
                     Procedure   Hide;
                     Procedure   Move(X,Y:Byte);
                     Procedure   ReSize(X1,Y1,X2,Y2:Byte);
                     Destructor  Done;
                   End;
       MessageWindow = ^MessageWin;

       Choice     = ^ChoiceRec;
       ChoiceRec  = Record
                      T : Str40;
                      P,N : Choice;
                    End;

       ChoiceWin  = Object(MessageWin)
                      CHOICES : Choice;
                      COUNT   : Word;
                      MAXLEN  : Byte;
                      MAXDISP : Byte;
                      Constructor Init(X1,Y1,X2,Y2:Byte;C:DTColor;H:Str80);
                      Procedure   AddChoice(T:Str40);
                      Procedure   ClearChoices;
                      Procedure   Clear; virtual;
                      Function    Choose:Byte;
                      Destructor  Done;
                    End;
       ChoiceWindow = ^ChoiceWin;

       DirWin     = Object(ChoiceWin)
                      PATH : PathStr;
                      ATTR : Byte;
                      NAME : String[12];
                      INFO : Boolean;
                      Constructor Init(X,Y:Byte;C:DTColor;S:Boolean);
                      Function    Choose:String;
                    End;
       DirWindow  = ^DirWin;

       SetofByte  = Set Of Byte;
       MenuWin    = Object(MessageWin)
                      CURRENT : Byte;
                      BLOCK   : SetofByte;
                      Constructor Init(X1,Y1,X2,Y2:Byte;C:DTColor;H:Str80);
                      Procedure   NoChoice(B:SetofByte);
                      Function    Choose:Byte;
                    End;
       MenuWindow = ^MenuWin;

       CursorType = Object
                      NormSize : Word;
                      Procedure On;
                      Procedure Off;
                      Procedure Full;
                      Procedure SetSize(C:Word);
                      Function  GetSize:Word;
                    End;

       Location   = Record
                      Character : Char;
                      Attribute : Byte;
                    End;
       ScreenType = Array[1..25,1..80] Of Location;

       MouseMap   = Array[1..25,1..80] Of Byte;
       MouseType  = Object
                      MAP : ^MouseMap;
                      ON  : Boolean;
                      X,Y : Integer;
                      Left,Middle,Right : Boolean;
                      STATUS : Boolean;
                      Procedure Init;
                      Function  Test:Byte;
                      Procedure Read;
                      Procedure SetXY(X1,Y1:Integer);
                      Procedure Window(X1,Y1,X2,Y2:Integer);
                      Procedure Show;
                      Procedure Hide;
                    End;

       EntryPtr   = ^EntryType;
       EntryType  = Record
                      X,Y   : Byte;
                      LMAX  : Byte;
                      DMAX  : Byte;
                      MESSAGE : Str40;
                      INPUT : StrPtr;
                      ITYPE : Byte;
                      N,P   : EntryPtr;
                    End;
       EntryScreen= Object
                      ENTRY  : EntryPtr;
                      EXITCH : Char;
                      Constructor Init(C:Char);
                      Procedure   AddEntry(X_,Y_:Byte;M:Str40;Var I:String;L,D:Byte);
                      Procedure   Clear;
                      Function    Use:Char;
                      Destructor  Done;
                    End;

       TimeObj   = Object
                     X,Y  : Byte;
                     Disp : Boolean;
                     Procedure On(XPOS,YPOS:Byte);
                     Procedure Off;
                     Procedure Show;
                   End;
       DateObj   = Object
                     X,Y  : Byte;
                     Disp : Boolean;
                     LD   : Word;
                     Procedure On(XPOS,YPOS:Byte);
                     Procedure Off;
                     Procedure Show;
                   End;



Var    Screen     : ^ScreenType;
       ScreenSeg  : Word;
       ScreenMode : Byte;
       Mouse      : MouseType;
       Cursor     : CursorType;
       Time       : TimeObj;
       Date       : DateObj;

  Function  MakeStr(C:Char;N:Byte):String;
  Function  KeyPressed:Boolean;
  Function  ReadKbd:Word;
  Function  ReadKey:Char;
  Function  EditString(X,Y:Byte;Var I:String;L,D:Byte):Char;
  Procedure Keybeep;
  Procedure Center(T:String);
  Procedure SetColor(C:ColorSet);
  Procedure SaveScreen;
  Procedure Box(X1,Y1,X2,Y2:Byte);
  Procedure VLine(X,Y1,Y2:Byte;C:Char);
  Procedure HLine(X1,X2,Y:Byte;C:Char);
  Procedure Button(X,Y:Byte;T:String);
  Procedure WriteXY(X,Y:Byte;S:String);
  Procedure AbsWrite(X,Y:Byte;S:String);
  Procedure InvLine(Y:Byte);
  Procedure InvChars(X1,X2,Y:Byte);
  Function  Max(A,B:Integer):Integer;
  Inline(
    $58/       { POP AX    }
    $5A/       { POP DX    }
    $39/$D0/   { CMP AX,DX }
    $7F/$02/   { JG  +2    }
    $89/$D0);  { MOV AX,DX }

  Function  Min(A,B:Integer):Integer;
  Inline(
    $58/       { POP AX    }
    $5A/       { POP DX    }
    $39/$D0/   { CMP AX,DX }
    $7C/$02/   { JL  +2    }
    $89/$D0);  { MOV AX,DX }

Implementation
  Var WindowList  : Array[0..255] Of MessageWindow;
      OpenWindows : Byte;
      Regs        : Registers;
      ScreenSave  : ^ScreenType;
      ScreenX,
      ScreenY     : Byte;
      ExitSave    : Pointer;

  Procedure DateObj.On(XPOS,YPOS:Byte);
  Begin
    Disp:=True;
    X:=XPOS;
    Y:=YPOS;
    LD:=0;
  End;

  Procedure DateObj.Off;
  Var I:Byte;
  Begin
    Disp:=False;
    LD:=0;
    AbsWrite(X,Y,'        ');
  End;

  Procedure DateObj.Show;
  Var Year,Month,Day,Dow : Word;
      D                  : String[8];
      I                  : Byte;
  Begin
    If Disp Then
    Begin
      GetDate(Year,Month,Day,Dow);
      If Day=LD Then Exit;
      Dec(Year,(Year Div 100)*100);
      Str(Year:2,D);
      Insert('  /  /',D,1);
      Str(Day:2,D);
      Insert('  /',D,1);
      Str(Month:2,D);
      D[0]:=#8;
      For I:=1 To 8 Do If D[I]=' ' Then D[I]:='0';
      AbsWrite(X,Y,D);
    End;
  End;


  Procedure TimeObj.On(XPOS,YPOS:Byte);
  Begin
    Disp:=True;
    X:=XPOS;
    Y:=YPOS;
  End;

  Procedure TimeObj.Off;
  Var I:Byte;
  Begin
    Disp:=False;
    AbsWrite(X,Y,'           ');
  End;

  Procedure TimeObj.Show;
  Var H,M,S,I:Word;
      T : String[11];
  Begin
    If Disp Then
    Begin
      GetTime(H,M,S,I);
      Str(S:2,T);
      Insert('  :  :',T,1);
      Str(M:2,T);
      Insert('  :',T,1);
      If H>12 Then
      Begin
        H:=H-12;
        Str(H:2,T);
        T[0]:=#8;
        T:=T+' pm';
      End Else
      Begin
        If H<>0 Then
        Begin
          Str(H:2,T);
          T[0]:=#8;
          If H<12 Then T:=T+' am' Else T:=T+' pm';
        End Else
        Begin
          H:=12;
          Str(H:2,T);
          T[0]:=#8;
          T:=T+' am';
        End;
      End;
      For S:=2 To 8 Do If T[S]=' ' Then T[S]:='0';
      AbsWrite(X,Y,T);
    End;
  End;

  Procedure Center(T:String);
  Begin
    GotoXY(Round((Lo(WindMax)-Lo(WindMin)+1)/2-Length(T)/2)+1,WhereY);
    Write(T);
  End;

  Procedure SetColor(C:ColorSet);
  Begin
    TextColor(C[1]);
    TextBackGround(C[2]);
  End;

  Function Bit(B,N:Byte):Boolean;
  Begin
    Bit:=((B shl (15-N)) shr 15)=1;
  End;

  Procedure AbsWrite(X,Y:Byte;S:String);
  Var I : Byte;
  Begin
    For I:=1 To Length(S) Do Screen^[Y,X+I-1].Character:=S[I];
  End;

  Procedure WriteXY(X,Y:Byte;S:String);
  Var I : Byte;
  Begin
    For I:=1 To Length(S) Do
    With WindowList[OpenWindows]^,Screen^[YMIN+Y-1,XMIN+X+I-2] Do
    Begin
      Character:=S[I];
      Attribute:=TextAttr;
    End;
  End;

  Function MakeStr(C:Char;N:Byte):String;
  Var S : String;
      I : Byte;
  Begin
    S:='';
    For I:=1 To N Do S:=S+C;
    MakeStr:=S;
  End;

  Procedure InvChars(X1,X2,Y:Byte);
  Var I:Byte;
  Begin
    Inc(X1,Lo(WindMin));
    Inc(X2,Lo(WindMin));
    Inc(Y,Hi(WindMin));
    For I:=X1 To X2 Do Screen^[Y,I].Attribute:=Screen^[Y,I].Attribute Xor InvByte;
  End;

  Procedure InvLine(Y:Byte);
  Var X1,X2,I : Byte;
  Begin
    If Y=0 Then Exit;
    Inc(Y,Hi(WindMin));
    X1:=Lo(WindMin)+1;
    X2:=Lo(WindMax)+1;
    For I:=X1 To X2 Do Screen^[Y,I].Attribute:=Screen^[Y,I].Attribute Xor InvByte;
  End;

  Procedure VLine(X,Y1,Y2:Byte;C:Char);
  Var I : Byte;
  Begin
    For I:=Y1 To Y2 Do
    Begin
      GotoXY(X,I);
      Write(C);
    End;
  End;

  Procedure HLine(X1,X2,Y:Byte;C:Char);
  Var I : Byte;
  Begin
    GotoXY(X1,Y);
    For I:=X1 To X2 Do Write(C);
  End;

  Procedure Box(X1,Y1,X2,Y2:Byte);
  Var I : Byte;
  Begin
    GotoXY(X1,Y1);
    Write('┌');
    For I:=X1+1 To X2-1 Do Write('─');
    Write('┐');
    For I:=Y1+1 To Y2-1 Do
    Begin
      GotoXY(X1,I);
      Write('│');
      GotoXY(X2,I);
      Write('│');
    End;
    GotoXY(X1,Y2);
    Write('└');
    For I:=X1+1 To X2-1 Do Write('─');
    Write('┘');
  End;

  Procedure Button(X,Y:Byte;T:String);
  Var I : Byte;
  Begin
    GotoXY(X,Y);
    Write('╔');
    For I:=1 To 8 Do Write('═');
    Write('╕');
    GotoXY(X,Y+1);
    Write('║',T:8,'│');
    GotoXY(X,Y+2);
    Write('╙');
    For I:=1 To 8 Do Write('─');
    Write('┘');
  End;

{ *** SwapScreen procedure ************************************************ }

  Procedure SwapScreen(X1,Y1,X2,Y2:Byte;SV:SavePtr);
  Var Y : Byte;
      C : Word;
      L : Word;
      S : String[160];
  Begin
    C:=1;
    L:=(X2-X1+1)*2;
    For Y:=Y1 To Y2 Do
    Begin
      Move(SV^[C],S,L);
      Move(Screen^[Y,X1],SV^[C],L);
      Move(S,Screen^[Y,X1],L);
      Inc(C,L);
    End;
  End;

  Procedure CopyScreen(X1,Y1,X2,Y2:Byte;SV:SavePtr);
  Var Y : Byte;
      C : Word;
      L : Word;
  Begin
    C:=1;
    L:=(X2-X1+1)*2;
    For Y:=Y1 To Y2 Do
    Begin
      Move(Screen^[Y,X1],SV^[C],L);
      Inc(C,L);
    End;
  End;

{ *** Exit procedure ****************************************************** }

  {$F+}
  Procedure NewExit;
  Var I:Byte;
  Begin
    {$F-}
    If (ErrorAddr=Nil) And (ExitCode=0) Then
    Begin
      Move(ScreenSave^,Screen^,4000);
      Window(1,1,80,25);
      GotoXY(ScreenX,ScreenY);
    End;
    Cursor.On;
    NormVideo;
    {$F+}
    ExitProc:=ExitSave;
  End;
  {$F-}

  Procedure SaveScreen;
  Begin
    ScreenX:=WhereX;
    ScreenY:=WhereY;
    New(ScreenSave);
    Move(Screen^,ScreenSave^,4000);
    Window(1,1,80,25);
    ExitSave:=ExitProc;
    ExitProc:=@NewExit;
  End;

{ *** CursorType Methods ************************************************** }

  Procedure CursorType.On;
  Begin
    Regs.CX:=NormSize;
    Regs.AH:=1;
    Intr($10,Regs);
  End;

  Procedure CursorType.Off;
  Begin
    Regs.CX:=$2E00;
    Regs.AH:=1;
    Intr($10,Regs);
  End;

  Procedure CursorType.Full;
  Begin
    Regs.CH:=1;
    Regs.CL:=Lo(NormSize)-1;
    Regs.AH:=1;
    Intr($10,Regs);
  End;

  Procedure CursorType.SetSize(C:Word);
  Begin
    Regs.AH:=1;
    Regs.CX:=C;
    Intr($10,Regs);
  End;

  Function CursorType.GetSize:Word;
  Begin
    Regs.AH:=3;
    Regs.BH:=0;
    Intr($10,Regs);
    GetSize:=Regs.CX;
  End;


  {$F+}
  Procedure NilClear;
  Begin
  End;
  {$F-}

{ *** MessageWindow Methods *********************************************** }

  Procedure MessageWin.AttrSave;
  Begin
    IF Not ATTRIBUTES.STYLED Then Clear Else
    With ATTRIBUTES Do
    Begin
      CSIZE:=Cursor.GetSize;
      X:=WhereX;
      Y:=WhereY;
      X1:=Lo(WindMin)+1-XMIN;
      X2:=Lo(WindMax)+1-XMAX;
      Y1:=Hi(WindMin)+1-YMIN;
      Y2:=Hi(WindMax)+1-YMAX;
      ATTR:=TextAttr;
    End;
  End;

  Procedure MessageWin.AttrSet;
  Begin
    With ATTRIBUTES Do
    Begin
      If Not STYLED Then AttrSave Else
      Begin
        Cursor.SetSize(CSIZE);
        Window(X1+XMIN,Y1+YMIN,X2+XMAX,Y2+YMAX);
        GotoXY(X,Y);
        TextAttr:=ATTR;
      End;
    End;
  End;

  Procedure MessageWin.Clear;
  Var I : Byte;
  Begin
    ATTRIBUTES.STYLED:=True;
    TextAttr:=COLOR[1];
    Window(XMIN,YMIN,XMAX,YMAX);
    ClrScr;
    TextAttr:=COLOR[2];
    For I:=2 To XMAX-XMIN Do
    Begin
      If HL='' Then WriteXY(I,1,'═');
      WriteXY(I,YMAX-YMIN+1,'═');
    End;
    For I:=2 To YMAX-YMIN Do
    Begin
      WriteXY(1,I,'║');
      WriteXY(XMAX-XMIN+1,I,'║');
    End;
    WriteXY(1,1,'╔');
    WriteXY(1,YMAX-YMIN+1,'╚');
    WriteXY(XMAX-XMIN+1,1,'╗');
    WriteXY(XMAX-XMIN+1,YMAX-YMIN+1,'╝');
    Window(XMIN,YMIN,XMAX-1,YMAX);
    If HL<>'' Then
    Begin
      TextAttr:=COLOR[3];
      GotoXY(2,1);
      ClrEol;
      Write(' ',HL);
    End;
    Window(XMIN+1,YMIN+1,XMAX-1,YMAX-1);
    TextAttr:=COLOR[1];
    CLEARPROC;
    AttrSave;
  End;

  Constructor MessageWin.Init(X1,Y1,X2,Y2:Byte;C:DTColor;H:Str80);
  Var I : Word;
  Begin
    ID:=0;
    XMIN:=X1;
    XMAX:=X2;
    YMIN:=Y1;
    YMAX:=Y2;
    SIZE:=((XMAX-XMIN+1)*(YMAX-YMIN+1)*2);
    GetMem(SAVE,SIZE);
    If SAVE=Nil Then Fail;
    For I:=1 To 3 Do
      COLOR[I]:=C[I,2]*16+C[I,1];
    HL:=H;
    ATTRIBUTES.STYLED:=False;
    CLEARPROC:=NilClear;
  End;

  Procedure MessageWin.Show;
  Var I : Byte;
  Begin
    If ID>0 Then
    Begin
      If ID=OpenWindows Then Exit;
      WindowList[OpenWindows]^.AttrSave;
      For I:=OpenWindows DownTo ID Do With WindowList[I]^ Do
        SwapScreen(XMIN,YMIN,XMAX,YMAX,SAVE);
      For I:=ID To OpenWindows-1 Do
      Begin
        WindowList[I]:=WindowList[I+1];
        With WindowList[I]^ Do
        Begin
          SwapScreen(XMIN,YMIN,XMAX,YMAX,SAVE);
          Dec(ID);
        End;
      End;
    End Else
    Begin
      If OpenWindows>0 Then WindowList[OpenWindows]^.AttrSave;
      Inc(OpenWindows);
    End;
    WindowList[OpenWindows]:=@Self;
    ID:=OpenWindows;
    If ATTRIBUTES.STYLED Then SwapScreen(XMIN,YMIN,XMAX,YMAX,SAVE)
                         Else CopyScreen(XMIN,YMIN,XMAX,YMAX,SAVE);
    AttrSet;
  End;

  Procedure MessageWin.Hide;
  Var I : Byte;
  Begin
    If ID=0 Then Exit;
    If OpenWindows<>ID Then
    Begin
      WindowList[OpenWindows]^.AttrSave;
      For I:=OpenWindows DownTo ID Do With WindowList[I]^ Do
        SwapScreen(XMIN,YMIN,XMAX,YMAX,SAVE);
      For I:=ID To OpenWindows-1 Do
      Begin
        WindowList[I]:=WindowList[I+1];
        With WindowList[I]^ Do
        Begin
          SwapScreen(XMIN,YMIN,XMAX,YMAX,SAVE);
          Dec(ID);
        End;
      End;
    End Else
    Begin
      AttrSave;
      SwapScreen(XMIN,YMIN,XMAX,YMAX,SAVE);
    End;
    Dec(OpenWindows);
    ID:=0;
    If OpenWindows>0 Then WindowList[OpenWindows]^.AttrSet;
  End;

  Procedure MessageWin.ReSize(X1,Y1,X2,Y2:Byte);
  Var S:Word;
  Begin
    Hide;
    XMIN:=X1;
    XMAX:=X2;
    YMIN:=Y1;
    YMAX:=Y2;
    S:=((XMAX-XMIN+1)*(YMAX-YMIN+1)*2);
    If S>SIZE Then
    Begin
      Freemem(SAVE,SIZE);
      SIZE:=S;
      Getmem(SAVE,SIZE);
    End;
    ATTRIBUTES.STYLED:=False;
    Show;
  End;

  Procedure MessageWin.Move(X,Y:Byte);
  Var XL,YL : Byte;
  Begin
    XL:=XMAX-XMIN;
    YL:=YMAX-YMIN;
    If (X+XL>80) Or (Y+YL>25) Then Exit;
    Hide;
    XMIN:=X;
    YMIN:=Y;
    XMAX:=X+XL;
    YMAX:=Y+YL;
    Show;
  End;

  Destructor MessageWin.Done;
  Begin
    Hide;
    FreeMem(SAVE,SIZE);
  End;

{ *** ChoiceWindow Methods ************************************************ }

  Constructor ChoiceWin.Init(X1,Y1,X2,Y2:Byte;C:DTColor;H:Str80);
  Begin
    MessageWin.Init(X1,Y1,X2,Y2,C,H);
    CHOICES:=Nil;
    COUNT:=0;
    MAXLEN:=XMAX-XMIN-6;
    MAXDISP:=YMAX-YMIN-6;
    If MAXLEN-11>40 Then Inc(MAXDISP,3);
    MAXLEN:=Min(MAXLEN,40);
  End;

  Procedure ChoiceWin.AddChoice(T:Str40);
  Var C : Choice;
  Begin
    If CHOICES=Nil Then
    Begin
      New(C);
      C^.P:=Nil;
      C^.N:=Nil;
    End Else
    Begin
      While CHOICES^.N<>Nil Do CHOICES:=CHOICES^.N;
      New(C);
      C^.P:=CHOICES;
      C^.N:=Nil;
      CHOICES^.N:=C;
    End;
    C^.T:=Copy(T,1,MAXLEN);
    CHOICES:=C;
    Inc(COUNT);
  End;

  Procedure ChoiceWin.Clear;
  Var I : Byte;
  Begin
    MessageWin.Clear;
    Cursor.Off;
    HighVideo;
    Box(1,1,MAXLEN+5,MAXDISP+2);
    VLine(MAXLEN+3,2,MAXDISP+1,'│');
    GotoXY(MAXLEN+3,1);
    Write('┬');
    GotoXY(MAXLEN+3,MAXDISP+2);
    Write('┴');
    GotoXY(MAXLEN+4,2);
    Write('');
    GotoXY(MAXLEN+4,MAXDISP+1);
    Write('');
    LowVideo;
    VLine(MAXLEN+4,3,MAXDISP,'▒');
    HighVideo;
    If XMAX-XMIN-11>MAXLEN Then
    Begin
      Button(MAXLEN+7,2,'  Done  ');
      Button(MAXLEN+7,5,' Cancel ');
    End Else
    Begin
      Button(2,MAXDISP+3,'  Done  ');
      Button(14,MAXDISP+3,' Cancel ');
    End;
  End;

  Function ChoiceWin.Choose:Byte;
  Var I       : Byte;
      CURRENT : Byte;
      TOP     : Byte;
      CH      : Char;
      C       : Choice;
      CB      : Byte;
      BAR,BARL  : Byte;
      BARX,BARY : Byte;
      BARR      : Real;

    Procedure HighLight(X,Y:Byte);
    Begin
      If Bit(Screen^[Y,X].Attribute,3) Then Exit;
      Inc(Screen^[Y,X].Attribute,8);
    End;

    Procedure LowLight(X,Y:Byte);
    Begin
      If Not Bit(Screen^[Y,X].Attribute,3) Then Exit;
      Dec(Screen^[Y,X].Attribute,8);
    End;

  Begin
    Show;
    Window(XMIN+2,YMIN+2,XMIN+2+MAXLEN,YMIN+1+MAXDISP);
    TextAttr:=COLOR[1];
    ClrScr;
    If COUNT<>0 Then
    Begin
      BARX:=XMIN+MAXLEN+4;
      BARY:=YMIN+2;
      BARL:=MAXDISP-3;
      If COUNT<MAXDISP Then BARL:=0;
      BARR:=BARL/COUNT;
      While CHOICES^.P<>Nil Do CHOICES:=CHOICES^.P;
      C:=CHOICES;
      For I:=1 To MAXDISP Do
      Begin
        GotoXY(1,I);
        Write(C^.T);
        If C^.N<>Nil Then C:=C^.N
                     Else I:=MAXDISP;
      End;
      TOP:=1;
      CURRENT:=1;
      Repeat
        BAR:=Round(CURRENT*BARR)+1;
        InvLine(CURRENT-TOP+1);
        HighLight(BARX,BARY+BAR);
        CH:=ReadKey;
        LowLight(BARX,BARY+BAR);
        InvLine(CURRENT-TOP+1);
        If CH=#0 Then
        Begin
          CH:=Crt.ReadKey;
          Case CH Of #72 : If CHOICES^.P<>Nil Then Begin
                                                     Dec(CURRENT);
                                                     CHOICES:=CHOICES^.P;
                                                   End Else Keybeep;
                     #80 : If CHOICES^.N<>Nil Then Begin
                                                     Inc(CURRENT);
                                                     CHOICES:=CHOICES^.N;
                                                   End Else Keybeep;
          End;
          If CURRENT>TOP+MAXDISP-1 Then
          Begin
            GotoXY(1,1);DelLine;
            Inc(TOP);
            GotoXY(1,MAXDISP);
            Write(CHOICES^.T);
          End;
          If CURRENT<TOP Then
          Begin
            GotoXY(1,1);InsLine;
            Dec(TOP);
            GotoXY(1,1);
            Write(CHOICES^.T);
          End;
        End Else If Not (CH In [#13,#27,#9]) Then Keybeep;
      Until CH In [#27,#13];
      Choose:=CURRENT;
      If CH=#27 Then Choose:=0;
    End Else
    Begin
      Write('No choices');
      Repeat
        CH:=ReadKey;
        If Not (CH In [#13,#27]) Then Keybeep;
      Until CH In [#13,#27];
      Choose:=0;
    End;
  End;

  Procedure ChoiceWin.ClearChoices;
  Begin
    If CHOICES=Nil Then Exit;
    While CHOICES^.P<>Nil Do CHOICES:=CHOICES^.P;
    While CHOICES^.N<>Nil Do
    Begin
      CHOICES:=CHOICES^.N;
      Dispose(CHOICES^.P);
    End;
    Dispose(CHOICES);
    CHOICES:=Nil;
    COUNT:=0;
  End;

  Destructor ChoiceWin.Done;
  Begin
    ClearChoices;
    MessageWin.Done;
  End;

{ *** MenuWindow Methods ************************************************** }

  Constructor MenuWin.Init(X1,Y1,X2,Y2:Byte;C:DTColor;H:Str80);
  Begin
    MessageWin.Init(X1,Y1,X2,Y2,C,H);
    CURRENT:=0;
    BLOCK:=[0];
  End;

  Procedure MenuWin.NoChoice(B:SetofByte);
  Begin
    BLOCK:=B;
    BLOCK:=BLOCK+[0];
  End;

  Function MenuWin.Choose:Byte;
  Var CH  : Char;
      MAX : Byte;
  Begin
    Show;
    MAX:=YMAX-YMIN-1;
    InvLine(CURRENT);
    While CURRENT In BLOCK Do Inc(CURRENT);
    Repeat
      InvLine(CURRENT);
      CH:=ReadKey;
      InvLine(CURRENT);
      If CH=#0 Then
      Begin
        CH:=ReadKey;
        Case CH Of #72 : Repeat
                           Dec(CURRENT);
                           If CURRENT<1 Then CURRENT:=MAX;
                         Until Not (CURRENT In BLOCK);
                   #80 : Repeat
                           Inc(CURRENT);
                           If CURRENT>MAX Then CURRENT:=1;
                         Until Not (CURRENT In BLOCK);
        End;
      End;
    Until CH In [#27,#13];
    Choose:=CURRENT;
    If CH=#27 Then Choose:=0;
    InvLine(CURRENT);
  End;

{ *** DirWindow Methods *************************************************** }

  Constructor DirWin.Init(X,Y:Byte;C:DTColor;S:Boolean);
  Var A : Byte;
  Begin
    INFO:=S;
    If Not INFO Then
    Begin
      ChoiceWin.Init(X,Y,X+30,Y+10,C,'Directory');
      MAXLEN:=12;
      Inc(MAXDISP,3);
    End Else ChoiceWin.Init(X,Y,X+58,Y+10,C,'Directory of');
    PATH:='\';
    NAME:='*.*';
    ATTR:=AnyFile;
  End;

  Function DirWin.Choose:String;
  Const FILETEMPLATE : Str40 = '            │   /  /   │           bytes';
        DIRTEMPLATE  : Str40 = '            │   /  /   │  (Directory)';
  Var F        : SearchRec;
      I,J      : Byte;
      ADDPATH  : String[13];
      TEMPLATE : Str40;
      DT       : DateTime;
      S        : String[12];

    Procedure PUT_TIME;
    Begin
      UnpackTime(F.TIME,DT);
      Str(DT.Month:2,S);
      TEMPLATE[15]:=S[1];
      TEMPLATE[16]:=S[2];
      Str(DT.Day:2,S);
      TEMPLATE[18]:=S[1];
      TEMPLATE[19]:=S[2];
      Str(DT.Year:4,S);
      TEMPLATE[21]:=S[3];
      TEMPLATE[22]:=S[4];
    End;

  Begin
    ADDPATH:='';
    Repeat
      PATH:=PATH+ADDPATH;
      ClearChoices;
      PATH:=FExpand(PATH);
      FindFirst(PATH+'*.*',Directory,F);
      While DosError=0 Do
      Begin
        If (F.ATTR And Directory=Directory) And
           (F.NAME<>'.') Then
        Begin
          TEMPLATE:=DIRTEMPLATE;
          TEMPLATE:=F.NAME+'\';
          If INFO Then
          Begin
            TEMPLATE[0]:=#37;
            PUT_TIME;
          End;
          AddChoice(TEMPLATE);
        End;
        FindNext(F);
      End;
      FindFirst(PATH+NAME,ATTR,F);
      While DosError=0 Do
      Begin
        If (F.ATTR And Directory<>Directory) And
           (F.ATTR And VolumeID<>VolumeID) Then
        Begin
          TEMPLATE:=FILETEMPLATE;
          TEMPLATE:=F.NAME;
          If INFO Then
          Begin
            TEMPLATE[0]:=#40;
            PUT_TIME;
            Str(F.Size:7,S);
            J:=7;
            While (J>0) And (S[J-1]<>' ') Do Dec(J);
            J:=Trunc(((8-J)/3)-0.1);
            For I:=1 To J Do Insert(',',S,8-(I*3));
            For I:=2-J DownTo 0 Do Insert(' ',S,1);
            For I:=1 To 10 Do TEMPLATE[I+24]:=S[I];
          End;
          AddChoice(TEMPLATE);
        End;
        FindNext(F);
      End;
      Show;
      If INFO Then
      Begin
        TextAttr:=COLOR[3];
        WriteXY(16,1,PATH+NAME);
        I:=ChoiceWin.Choose;
        TextAttr:=COLOR[3];
        WriteXY(16,1,MakeStr(' ',Length(PATH+NAME)));
      End Else I:=ChoiceWin.Choose;
      ADDPATH:=Copy(CHOICES^.T,1,Pos('\',CHOICES^.T));
    Until (ADDPATH='') Or (I=0);
    Choose:=PATH+CHOICES^.T;
    If I=0 Then Choose:='';
  End;

{ *** Mouse Object ******************************************************** }

Procedure MI(N:Integer);
InLine($58/$CD/$33);

Procedure MouseType.Init;
Var I,J : Byte;
Begin
  If ON Then Exit;
  ON:=True;
  New(MAP);
  If MAP=Nil Then Exit;
  For I:=1 To 25 Do
    For J:=1 To 80 Do MAP^[I,J]:=0;
  STATUS:=True;
End;

Function MouseType.Test:Byte;
Begin
  MI(0);
  Test:=Regs.BX;
End;

Procedure MouseType.Read;
Begin
  If Not ON Then Exit;
  MI(3);
  X:=Regs.CX;
  Y:=Regs.DX;
  If (Regs.BX And 4)=4 Then Middle:=True Else Middle:=False;
  If (Regs.BX And 1)=1 Then Left:=True Else Left:=False;
  If (Regs.BX And 2)=2 Then Right:=True Else Right:=False;
End;

Procedure MouseType.SetXY(X1,Y1:Integer);
Begin
  If Not ON Then Exit;
  Regs.CX:=X1;
  Regs.DX:=Y1;
  MI(4);
End;

Procedure MouseType.Window(X1,Y1,X2,Y2:Integer);
Begin
  If Not ON Then Exit;
  Regs.CX:=X1;
  Regs.DX:=X2;
  MI(7);
  Regs.CX:=Y1;
  Regs.DX:=Y2;
  MI(8);
End;

Procedure MouseType.Show;
Begin
  STATUS:=True;
End;

Procedure MouseType.Hide;
Begin
  STATUS:=False;
End;

Function KeyPressed:Boolean;
Begin
  KeyPressed:=Crt.KeyPressed;
  Time.Show;
  Date.Show;
End;

Function ReadKey:Char;
Begin
  Repeat Until Keypressed;
  ReadKey:=Crt.ReadKey;
End;

Function ReadKbd:Word;
Var W:Word;
Begin
  W:=Ord(Readkey);
  If W=0 Then W:=256+Ord(ReadKey);
  ReadKbd:=W;
End;

Procedure Keybeep;
Begin
  Sound(1000);
  Delay(50);
  NoSound;
End;

{ *** Entry code ********************************************************** }

Function EditString(X,Y:Byte;Var I:String;L,D:Byte):Char;
Var POS   : Byte;
    LEFT,RIGHT : Byte;
    C1,C2 : Char;
Begin
  GotoXY(X,Y);
  If L>1 Then
  Begin
    Write(Copy(I,1,D));
    Write(MakeStr('·',D-Min(Length(I),D)));
    POS:=1;
    LEFT:=1;
    C2:=#1;
    Repeat
      RIGHT:=LEFT+D-1;
      GotoXY(X,Y);
      Write(Copy(I+'·',LEFT,D));
      GotoXY(X-1,Y);
      If LEFT>1 Then Write(#27) Else Write(#32);
      GotoXY(X+D,Y);
      If LEFT+D<Min(Length(I)+1,L) Then Write(#26) Else Write(#32);
      GotoXY(X+POS-LEFT,Y);
      Cursor.Full;
      C1:=ReadKey;
      Cursor.Off;
      If C1=#0 Then
      Begin
        C2:=ReadKey;
        Case C2 Of #75 : Dec(POS);
                   #77 : Inc(POS);
                   #71 : Begin
                           POS:=1;
                           LEFT:=1;
                         End;
                   #79 : Begin
                           POS:=Length(I)+1;
                           If POS>RIGHT Then LEFT:=POS-D;
                         End;
                   #83 : If POS<Length(I)+1 Then Delete(I,POS,1) Else Keybeep;
                   Else
                   Begin
                     C1:=C2;
                     C2:=#0;
                   End;
        End;
        If POS>Length(I)+1 Then POS:=Length(I)+1;
        If POS>L Then POS:=L;
        If POS<1 Then POS:=1;
        If POS>RIGHT Then Inc(LEFT);
        If POS<LEFT Then Dec(LEFT);
      End Else
      Begin
        Case C1 Of #8 : If POS>1 Then
                        Begin
                          Dec(POS);
                          Delete(I,POS,1);
                          If LEFT>1 Then Dec(LEFT);
                        End Else Keybeep;
                   #13 :;
                   #27 :;
                   Else If Length(I)<L Then
                   Begin
                     Insert(C1,I,POS);
                     If POS<L Then Inc(POS);
                     If POS>RIGHT Then Inc(LEFT);
                   End Else Keybeep;
        End;
      End;
    Until (C1 In [#13,#27]) Or (C2=#0);
    EditString:=C1;
  End Else
  Begin
    Write('[',I,']');
    Cursor.Full;
    C2:=#1;
    Repeat
      GotoXY(X+1,Y);
      C1:=UpCase(ReadKey);
      If C1=#0 Then
      Begin
        C2:=ReadKey;
        C1:=C2;
        C2:=#0;
      End Else
      Begin
        If (C1 In ['Y','N']) Then
        Begin
          I:=C1;
          Write(C1);
        End Else If Not (C1 In [#13,#27]) Then Keybeep;
      End;
    Until (C1 In [#13,#27]) Or (C2=#0);
    Cursor.Off;
    EditString:=C1;
  End;
End;

Constructor EntryScreen.Init(C:Char);
Begin
  ENTRY:=Nil;
  EXITCH:=C;
End;

Procedure EntryScreen.AddEntry(X_,Y_:Byte;M:Str40;Var I:String;L,D:Byte);
Var E : EntryPtr;
Begin
  E:=ENTRY;
  New(ENTRY);
  With ENTRY^ Do
  Begin
    X:=X_;
    Y:=Y_;
    MESSAGE:=M;
    INPUT:=@I;
    LMAX:=L;
    DMAX:=D;
    N:=Nil;
    P:=E;
  End;
  If E<>Nil Then E^.N:=ENTRY;
End;

Function EntryScreen.Use:Char;
Var CH : Char;
    E  : EntryPtr;
Begin
  If ENTRY=Nil Then Exit;
  While ENTRY^.P<>Nil Do ENTRY:=ENTRY^.P;
  E:=ENTRY;
  Repeat
    With E^ Do
    Begin
      GotoXY(X,Y);
      Write(MESSAGE,' ');
      If LMAX>1 Then
      Begin
        Write(Copy(INPUT^,1,DMAX),MakeStr('·',DMAX-Min(Length(INPUT^),DMAX)));
        If Length(INPUT^)>DMAX Then Write(#26);
      End Else Write('[',INPUT^,']');
    End;
    E:=E^.N;
  Until E=Nil;
  Repeat
    With ENTRY^ Do CH:=EditString(X+Length(MESSAGE)+1,Y,INPUT^,LMAX,DMAX);
    Case CH Of #13,#80 : If ENTRY^.N<>Nil Then ENTRY:=ENTRY^.N;
               #72     : If ENTRY^.P<>Nil Then ENTRY:=ENTRY^.P;
               #27     :;
               Else If CH<>EXITCH Then Keybeep;
    End;
  Until CH In [EXITCH,#27];
  Use:=CH;
End;

Procedure EntryScreen.Clear;
Begin
  If ENTRY=Nil Then Exit;
  While ENTRY^.P<>Nil Do ENTRY:=ENTRY^.P;
  While ENTRY^.N<>Nil Do
  Begin
    ENTRY:=ENTRY^.N;
    Dispose(ENTRY^.P);
  End;
  Dispose(ENTRY);
  ENTRY:=Nil;
End;

Destructor EntryScreen.Done;
Begin
  Clear;
End;

{ *** Initialization code ************************************************* }

Begin
  ScreenMode:=Mem[$0040:$0049];
  If ScreenMode=7 Then ScreenSeg:=$B000 Else ScreenSeg:=$B800;
  Screen:=Ptr(ScreenSeg,$0000);
  OpenWindows:=0;
  Cursor.NormSize:=Cursor.GetSize;
  Mouse.ON:=False;
  Mouse.STATUS:=False;
  Time.Disp:=False;
  Date.Disp:=False;
End.
