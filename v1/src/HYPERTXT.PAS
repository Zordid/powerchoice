{$A+,B-,D+,E-,F-,I+,L+,N-,O-,R+,S+,V-}
Unit HyperTxt;
Interface
  Procedure Help_Editor(Filename:String);
  Procedure Do_Help(Filename:String;GoPage,HomePage:Word);

Implementation
  Uses Crt,Desktop;
  Const WColor      : DTColor = ((Black,LightGray),(Black,LightGray),(Black,LightGray));
        HelpColor   : Array[False..True] Of Byte = (LightGray*16+Black,LightGray*16+Blue);
        NormalColor : Byte = Black*16+LightGray;
        BoldColor   : Byte = Black*16+White;
        Header      : String[50] = 'HyperText System 1.0';
        MaxLinesPerPage = 15;
        MaxLineWidth    = 57;
        PgUp            = 'I';
        PgDn            = 'Q';
        UpArrow         = 'H';
        DnArrow         = 'P';
        LArrow          = 'K';
        RArrow          = 'M';
        Esc             = #27;
        HomeKey         = 'G';
        EndKey          = 'O';
        Return          = ^M;
        BkSpc           = #8;
        Nul             = #0;
        Tab             = #9;
        F2              = '<';
        DelKey          = 'S';

  Type  HelpRecord = Record
                       HelpLines : Array[1..MaxLinesPerPage] Of String[100];
                     End;

  Var   HelpRec  : HelpRecord;
        HelpFile : File Of HelpRecord;
        Alt,Ctrl,CommandKey : Boolean;

  Function Make_String(CH:Char;Size:Integer):String;
  Var S : String;
  Begin
    S[0]:=Chr(Size);
    FillChar(S[1],Size,CH);
    Make_String:=S;
  End;

  Procedure Draw_Box(TopX,TopY,BotX,BotY:Byte;Color,Width:Byte);
  Type  BoxPos = (TopL,TopR,BotL,BotR,Top,Bot,LSide,RSide);
  Var   Y : Byte;
  Const BoxChar : Array[1..2,TopL..RSide] Of Char
                = (('┌','┐','└','┘','─','─','│','│'),
                   ('╔','╗','╚','╝','═','═','║','║'));
  Begin
    TextAttr:=Color;
    If Not (Width In [1,2]) Then Width:=1;
    GotoXY(TopX,TopY);
    Write(BoxChar[Width,TopL]+Make_String(BoxChar[Width,Top],BoTX-TopX-1)+BoxChar[Width,TopR]);
    For Y:=TopY+1 To BotY-1 Do
    Begin
      GotoXY(TopX,Y);
      Write(BoxChar[Width,LSide],BoxChar[Width,RSide]:BotX-TopX);
    End;
    GotoXY(TopX,BotY);
    Write(BoxChar[Width,BotL]+Make_String(BoxChar[Width,Top],BotX-TopX-1)+BoxChar[Width,BotR]);
  End;

  Function Read_Keyboard:Char;
  Const CtrlMask = $04;
        AltMask  = $08;
  Var   KbdFlag : Byte Absolute $0040:$0017;
  Begin
    Read_Keyboard:=ReadKey;
    CommandKey:=((KbdFlag And AltMask)<>0) Or ((KbdFlag And CtrlMask)<>0);
    Alt:=(KbdFlag And AltMask)<>0;
    Ctrl:=(KbdFlag And CtrlMask)<>0;
    If KeyPressed Then
    Begin
      Read_Keyboard:=ReadKey;
      CommandKey:=True;
    End;
  End;

  Procedure Show_HelpLine(X,Y,StartBold,EndBold:Integer;Var Line:String);
  Var I,J : Integer;

    Procedure Write_Char(CH:Char);
    Begin
      If Ord(CH)>127 Then CH:=Chr(Ord(CH)-128);
      If Ord(CH)>27 Then Write(CH) Else Inc(I);
    End;

  Begin
    TextAttr:=HelpColor[False];
    GotoXY(X,Y);
    ClrEol;
    I:=1;
    While I<=Length(Line) Do
    Begin
      TextAttr:=HelpColor[Ord(Line[I])>128];
      If I In [StartBold..EndBold] Then TextAttr:=BoldColor;
      Write_Char(Line[I]);
      Inc(I);
    End;
  End;

  Procedure Show_Help_Page(Var HelpRec:HelpRecord);
  Var I : Integer;
  Begin
    TextAttr:=HelpColor[False];
    Clrscr;
    For I:=1 To MaxLinesPerPage Do Show_HelpLine(1,I,0,0,HelpRec.HelpLines[I]);
  End;

  Function Determine_Actual_Line_Pos(Var Line:String;Line_Pos:Integer):Integer;
  Var I,J : Integer;
  Begin
    I:=0;
    J:=1;
    While (J<=Length(Line)) And (I<>Line_Pos) Do
    Begin
      If Line[J]<>Nul Then Inc(I)
                      Else Inc(J,2);
      Inc(J);
    End;
    Determine_Actual_Line_Pos:=J;
  End;

  Function Link_Count(Var Line:String):Integer;
  Var I,Count : Integer;
  Begin
    Count:=0;
    For I:=1 To Length(Line) Do
      If Line[I]=Nul Then Inc(Count,2);
    Link_Count:=Count;
  End;

  Function Input_HelpPage(Var AHelpRec:HelpRecord):Char;
  Var CH      : Char;
      I,J,LinePos,
      RealLinePos,
      LineNum : Integer;
      PageNum : Byte;

    Procedure Delete_Linked_Char(Var Line:String;LinePos:Integer);
    Var I,J : Integer;
    Begin
      LinePos:=Pred(Determine_Actual_Line_Pos(Line,LinePos));
      If Ord(Line[LinePos])>127 Then
      Begin
        I:=LinePos;
        While ((Ord(Line[I-1])>127) And (I>1)) Do Dec(I);
        J:=LinePos;
        While ((Ord(Line[J+1])>127) And (I<Length(Line))) Do Inc(J);
        Delete(Line,LinePos,1+2*Ord(J=I));
      End;
    End;

  Begin
    Window(3,5,59,19);
    Show_Help_Page(AHelpRec);
    LinePos:=1;
    RealLinePos:=1;
    LineNum:=1;
    With AHelpRec Do
    Repeat
      Show_HelpLine(1,LineNum,0,0,HelpLines[LineNum]);
      GotoXY(LinePos,LineNum);
      Repeat
        CH:=Read_Keyboard;
      Until CH<>Nul;
      If CommandKey Then
        Case CH Of ^Y : If RealLinePos<=Length(HelpLines[LineNum]) Then
                        Begin
                          If (RealLinePos=1) Then HelpLines[LineNum]:='' Else
                          Begin
                            While HelpLines[LineNum,RealLinePos]<>Nul Do Delete(HelpLines[LineNum],RealLinePos,1);
                            If HelpLines[LineNum,LinePos]=Nul Then Delete(HelpLines[LineNum],LinePos+2,255);
                          End;
                        End;
                   F2 : Begin
                          J:=RealLinePos;
                          While (J>0) And (HelpLines[LineNum,J]<>' ') Do Dec(J);
                          Inc(J);
                          PageNum:=1;
                          If Ord(HelpLines[LineNum,J]) In [28..127] Then
                          Begin
                            Window(1,24,80,25);
                            TextAttr:=NormalColor;
                            Repeat
                              GotoXY(3,1);
                              Write('Link Page: ');
                              Readln(PageNum);
                              GotoXY(3,1);
                              ClrEol;
                            Until (PageNum>-1) And (PageNum<256);
                            Window(3,5,59,19);
                          End;
                          If PageNum<>0 Then
                          Begin
                            While (HelpLines[LineNum,J]<>' ') And (HelpLines[LineNum,J]<>Nul) Do
                            Begin
                              HelpLines[LineNum,J]:=Chr(Ord(HelpLines[LineNum,J])+128);
                              Inc(J);
                            End;
                            If Ord(HelpLines[LineNum,J-1]) In [28..127] Then Delete(HelpLines[LineNum],J,2)
                                                                        Else Insert(Nul+Chr(PageNum),HelpLines[LineNum],J);
                          End;
                        End;
               LArrow : If RealLinePos>1 Then
                        Begin
                          Dec(LinePos);
                          RealLinePos:=Pred(Determine_Actual_Line_Pos(HelpLines[LineNum],LinePos));
                        End;
               RArrow : If RealLinePos<=Length(HelpLines[LineNum]) Then
                        Begin
                          Inc(LinePos);
                          If RealLinePos<Length(HelpLines[LineNum]) Then
                            Inc(RealLinePos,1+Ord(HelpLines[LineNum,RealLinePos+1]=Nul)*2)
                          Else
                            Inc(RealLinePos);
                        End;
              DnArrow : If LineNum<MaxLinesPerPage Then
                        Begin
                          Inc(LineNum);
                          If LinePos<=Length(HelpLines[LineNum]) Then
                            RealLinePos:=Pred(Determine_Actual_Line_Pos(HelpLines[LineNum],LinePos))
                          Else
                          Begin
                            RealLinePos:=Succ(Length(HelpLines[LineNum]));
                            LinePos:=RealLinePos-Link_Count(HelpLines[LineNum]);
                          End;
                        End;
              UpArrow : If LineNum>1 Then
                        Begin
                          Dec(LineNum);
                          If LinePos<=Length(HelpLines[LineNum]) Then
                            RealLinePos:=Pred(Determine_Actual_Line_Pos(HelpLines[LineNum],LinePos))
                          Else
                          Begin
                            RealLinePos:=Succ(Length(HelpLines[LineNum]));
                            LinePos:=RealLinePos-Link_Count(HelpLines[LineNum]);
                          End;
                        End;
              HomeKey : Begin
                          LinePos:=1;
                          RealLinePos:=1;
                        End;
              EndKey  : Begin
                          RealLinePos:=Succ(Length(HelpLines[LineNum]));
                          LinePos:=RealLinePos-Link_Count(HelpLines[LineNum]);
                        End;
              DelKey  : If (RealLinePos<=Length(HelpLines[LineNum])) Then
                        Begin
                          If (HelpLines[LineNum,LinePos] In [' '..'}']) Then Delete(HelpLines[LineNum],RealLinePos,1)
                                                                        Else Delete_Linked_Char(HelpLines[LineNum],LinePos);
                          RealLinePos:=Pred(Determine_Actual_Line_Pos(HelpLines[LineNum],LinePos));
                        End;
        End
      Else
        Case CH Of Return : If LineNum<MaxLinesPerPage Then
                            Begin
                              Inc(LineNum);
                              LinePos:=1;
                              RealLinePos:=1;
                            End;
                   Tab    : Begin
                              If RealLinePos+10<=Length(HelpLines[LineNum])+1 Then Inc(RealLinePos,10)
                                                                              Else RealLinePos:=Length(HelpLines[LineNum])+1;
                              LinePos:=RealLinePos-Link_Count(HelpLines[LineNum]);
                            End;
                   BkSpc  : If RealLinePos>1 Then
                            Begin
                              If HelpLines[LineNum,RealLinePos-1] In [' '..'}'] Then
                              Begin
                                Delete(HelpLines[LineNum],RealLinePos-1,1);
                                Dec(RealLinePos);
                                Dec(LinePos);
                              End Else
                              Begin
                                Delete_Linked_Char(HelpLines[LineNum],LinePos-1);
                                Dec(LinePos);
                                RealLinePos:=Pred(Determine_Actual_Line_Pos(HelpLines[LineNum],LinePos));
                              End;
                            End;
                 ' '..'}' : If Length(HelpLines[LineNum])<MaxLineWidth Then
                            Begin
                              If (Ord(HelpLines[LineNum,RealLinePos])>127) And (RealLinePos<=Length(HelpLines[LineNum])) Then
                                CH:=Chr(Ord(CH)+128);
                              Insert(CH,HelpLines[LineNum],RealLinePos);
                              Inc(RealLinePos);
                              Inc(LinePos);
                              CH:=#255;
                            End;
        End;
    Until CH In [Esc,PgUp,PgDn];
    Input_HelpPage:=CH;
  End;

  Function Read_HelpRec(Var AHelpRec:HelpRecord;RecNum:Integer):Integer;
  Begin
    FillChar(AHelpRec,SizeOf(AHelpRec),0);
    {$I-}
    If FileSize(HelpFile)<RecNum Then Exit;
    Seek(HelpFile,RecNum-1);
    Read(HelpFile,AHelprec);
    Read_HelpRec:=IOResult;
    {$I+}
  End;

  Function Write_HelpRec(Var AHelpRec:HelpRecord;RecNum:Integer):Integer;
  Begin
    {$I-}
    Seek(HelpFile,RecNum-1);
    Write(HelpFile,AHelpRec);
    Write_HelpRec:=IOResult;
    {$I+}
  End;

  Function Open_HelpFile(FileName:String):Integer;
  Var Result : Integer;
  Begin
    Assign(HelpFile,FileName);
    {$I-}
    Reset(HelpFile);
    Result:=IOResult;
    If Result=2 Then
    Begin
      Rewrite(HelpFile);
      Result:=IOResult;
    End;
    Open_HelpFile:=Result;
    {$I+}
  End;

  Procedure Help_Editor(FileName:String);
  Const HelpMsgs = 13;
        HelpData : Array[1..HelpMsgs] Of String[17]
                 = ('Editing Keys:',
                    '-----------------',
                    'F2   : Link (+/-)',
                    '^Y   : Del EOLine',
                    'BkSpc: Del left',
                    'Del  : Del char',
                    #10+' Movement keys:',
                    '-----------------',
                    #24+#25+#27+#26+','+#17+#217+',',
                    'Tab,Home,End',
                    'PgUp : Prev Page',
                    'PgDn : Next Page',
                    #10+' Esc to quit');
  Var   I,HelpRecNum : Integer;
        AHelpRec     : HelpRecord;
        CH           : Char;
        S            : String[3];
        Result       : Integer;
        W            : MessageWindow;
  Begin
    New(W,Init(1,3,80,23,WColor,''));
    W^.Show;
    Result:=Open_HelpFile(FileName);
    If Result=0 Then
    Begin
      TextAttr:=NormalColor;
      Draw_Box(1,1,59,18,NormalColor,2);
      GotoXY(60,1);
      For I:=1 To HelpMsgs Do
      Begin
        GotoXY(61,WhereY+1);
        Write(HelpData[I]);
      End;
      HelpRecNum:=1;
      AbsWrite(4,2,'File: '+FileName);
      Repeat
        AbsWrite(4,4,' Reading ... ');
        Result:=Read_HelpRec(AHelpRec,HelpRecNum);
        Str(HelpRecNum:3,S);
        AbsWrite(4,4,' Page: '+S+' ══');
        CH:=Input_HelpPage(AHelpRec);
        AbsWrite(4,4,' Writing ... ');
        Result:=Write_HelpRec(AHelpRec,HelpRecNum);
        Case CH Of PgUp : If HelpRecNum>1 Then Dec(HelpRecNum);
                   PgDn : If HelpRecNum<255 Then Inc(HelpRecNum);
        End;
      Until CH=Esc;
    End Else Writeln('Error: ',Result,' opening ',FileName,'. Unable to continue.');
    {$I-}
    Close(HelpFile);
    Result:=IOResult;
    {$I+}
    Dispose(W,Done);
  End;

  Function Find_Next_Link(Var X,Y:Integer;EndX,EndY:Integer;Var AHelpRec:HelpRecord):Boolean;
  Var Col,Row,StartCol,StopCol : Integer;
  Begin
    Find_Next_Link:=False;
    For Row:=Y To EndY Do
    Begin
      If Row<>Y Then StartCol:=1
                Else StartCol:=X;
      If Row<>EndY Then StopCol:=Length(AHelpRec.HelpLines[Row])
                   Else StopCol:=EndX;
      If AHelpRec.HelpLines[Row]<>'' Then
        For Col:=StartCol To StopCol Do
          If (AHelpRec.HelpLines[Row,Col]=Nul) Then
          Begin
            Find_Next_Link:=True;
            X:=Col;
            Y:=Row;
            Exit;
          End;
    End;
    If (X<>1) And (Y<>1) Then
    Begin
      Row:=1;
      Col:=1;
      If Find_Next_Link(Col,Row,Pred(X),Y,AHelpRec) Then
      Begin
        X:=Col;
        Y:=Row;
        Find_Next_Link:=True;
      End;
    End;
  End;

  Function Find_Prev_Link(Var X,Y:Integer;EndX,EndY:Integer;Var AHelpRec:HelpRecord):Boolean;
  Var Col,Row,StartCol,StopCol : Integer;
  Begin
    Find_Prev_Link:=False;
    For Row:=Y DownTo 1 Do
    Begin
      StopCol:=1;
      If Row<>Y Then StartCol:=Length(AHelpRec.HelpLines[Row])
                Else StartCol:=X;
      If AHelpRec.HelpLines[Row]<>'' Then
        For Col:=StartCol DownTo StopCol Do
          If (AHelpRec.HelpLines[Row,Col]=Nul) Then
          Begin
            Find_Prev_Link:=True;
            X:=Col;
            Y:=Row;
            Exit;
          End;
    End;
    If (X<>Length(AHelpRec.HelpLines[Row])) And (Y<>MaxLinesPerPage) Then
    Begin
      Row:=MaxLinesPerPage;
      Col:=Length(AHelpRec.HelpLines[Row]);
      If Find_Prev_Link(Col,Row,Succ(X),Y,AHelpRec) Then
      Begin
        X:=Col;
        Y:=Row;
        Find_Prev_Link:=True;
      End;
    End;
  End;

  Procedure Do_Help(FileName:String;GoPage,HomePage:Word);
  Const XPos  = 10;
        YPos  = 5;
        Color : Byte = Black*16+White;
        MaxStackSize = 25;
  Type  StackRec = Record
                     Page : Byte;
                     Row,Col : Integer;
                   End;
  Var   Result   : Integer;
        Stack    : Array[0..MaxStackSize] Of StackRec;
        AHelpRec : HelpRecord;
        CH       : Char;
        StackLvl : Byte;
        StartCol : Integer;
        Linked,
        Load     : Boolean;
        W        : MessageWindow;
        CSave    : Word;

    Function PopStack:Byte;
    Begin
      If StackLvl>1 Then
      Begin
        Dec(StackLvl);
        Load:=True;
      End;
      PopStack:=StackLvl;
    End;

    Function PushStack(PageNum:Byte):Byte;
    Var I : Byte;
    Begin
      If StackLvl=MaxStackSize Then
      Begin
        For I:=1 To StackLvl-1 Do
          Stack[I]:=Stack[I+1];
        Dec(StackLvl);
      End;
      Inc(StackLvl);
      Stack[StackLvl].Page:=PageNum;
      Stack[StackLvl].Col:=1;
      Stack[StackLvl].Row:=1;
      PushStack:=StackLvl;
    End;

  Begin
    CSave:=Cursor.GetSize;
    Cursor.Off;
    If GoPage=0 Then GoPage:=1;
    Result:=Open_HelpFile(FileName);
    New(W,Init(XPos,YPos,XPos+59,YPos+MaxLinesPerPage+1,WColor,'Hypertext Help System'));
    W^.Show;
    If Result=0 Then
    Begin
      Load:=True;
      TextAttr:=Color;
      FillChar(Stack,SizeOf(Stack),0);
      StackLvl:=0;
      If HomePage In [1..255] Then StackLvl:=PushStack(HomePage);
      If (GoPage In [1..255]) And (GoPage<>HomePage) Then StackLvl:=PushStack(GoPage);
      GotoXY(XPos+29-Length(Header) Div 2,YPos);
      Repeat
        With Stack[StackLvl] Do
        Begin
          If Load Then
          Begin
            Result:=Read_HelpRec(AHelpRec,Page);
            Show_Help_Page(AHelpRec);
            If StackLvl>1 Then AbsWrite(XPos+46,YPos+MaxLinesPerPage+1,' PgUp/Home ')
                          Else AbsWrite(XPos+46,YPos+MaxLinesPerPage+1,'═══════════');
            Linked:=Find_Next_Link(Col,Row,80,MaxLinesPerPage,AHelpRec);
            Load:=False;
          End;
          If Linked Then
          Begin
            StartCol:=Col;
            While Ord(AHelpRec.HelpLines[Row,StartCol-1])>127 Do Dec(StartCol);
            Show_HelpLine(1,Row,StartCol,Pred(Col),AHelpRec.HelpLines[Row]);
          End;
          Repeat
            CH:=Read_Keyboard;
          Until CH<>Nul;
          Show_HelpLine(1,Row,0,0,AHelpRec.HelpLines[Row]);
          Case CH Of RArrow,Tab : Begin
                                    Inc(Col);
                                    Linked:=Find_Next_Link(Col,Row,80,MaxLinesPerPage,AHelpRec);
                                  End;
                     Return     : If Linked Then
                                  Begin
                                    Load:=True;
                                    If (StackLvl>1) And (Stack[StackLvl-1].Page=Ord(AHelpRec.HelpLines[Row,Col+1])) Then
                                      StackLvl:=PopStack
                                    Else
                                      StackLvl:=PushStack(Ord(AHelpRec.HelpLines[Row,Col+1]));
                                  End;
                     LArrow     : Begin
                                    Dec(Col);
                                    Linked:=Find_Prev_Link(Col,Row,1,1,AHelpRec);
                                  End;
                     DnArrow    : Begin
                                    Col:=1;
                                    If Row<MaxLinesPerPage Then Inc(Row)
                                                           Else Row:=1;
                                    Linked:=Find_Next_Link(Col,Row,80,MaxLinesPerPage,AHelpRec);
                                  End;
                     UpArrow    : Begin
                                    If Row>1 Then Dec(Row)
                                             Else Row:=MaxLinesPerPage;
                                    Col:=Length(AHelpRec.HelpLines[Row])+1;
                                    Linked:=Find_Prev_Link(Col,Row,1,1,AHelpRec);
                                  End;
                     HomeKey    : While StackLvl<>0 Do StackLvl:=PopStack;
                     PgUp       : StackLvl:=PopStack;
                     PgDn       : Begin
                                    { Set yourself }
                                  End;
          End;
        End;
      Until CH=Esc;
    End Else Writeln('Error: ',Result,' opening ',FileName,'. Unable to continue.');
    {$I-}
    Close(HelpFile);
    Result:=IOResult;
    {$I+}
    Dispose(W,Done);
    Cursor.SetSize(CSave);
  End;

End.