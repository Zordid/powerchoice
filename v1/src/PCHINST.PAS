{$A+,B-,D+,E-,F-,I+,L+,N-,O-,R+,S+,V-}
{$M 16384,66000,655360}
Program PCHINST;
Uses Crt,Dos,DeskTop,Install;
Const ID        : String[6] = 'PCH100';
      Zero      : Char = #0;
      ColorSet1 : DTColor = ((Black,LightGray),(Black,LightGray),(0,0));
      ColorSet2 : DTColor = ((White,Black),(LightGray,Black),(Black,LightGray));
      Color     = 0;
      Monochrome= 1;

      Completed : Boolean = False;

Var   CH   : Char;
      I    : Byte;
      W,W2 : MessageWindow;
      Main : MenuWindow;

      Drive       : Char;
      Path        : String[30];
      ChangeAuto  : Boolean;
      Reboot      : Boolean;
      ScreenSaver : Byte;
      Videomode   : Byte;

Procedure UpperCase(Var S:String);
Var I : Byte;
Begin
  For I:=1 To Length(S) Do S[I]:=UpCase(S[I]);
End;


Procedure GoInstall;
Type Autotype = Array[1..100] Of String[100];
Var ArcFile : PathStr;
    AutoTxt : ^Autotype;
    Lines   : Byte;
    F       : File Of Char;
    B       : Text;

  Procedure Modify_Autoexec;
  Var S : String;
      I : Byte;
  Begin
    For I:=1 To Lines Do
    Begin
      S:=AutoTxt^[I];
      UpperCase(S);
      If Pos('PCH_LL.COM',S)<>0 Then AutoTxt^[I]:='@@DELETE';
      If Pos('PCH.BAT',S)<>0 Then AutoTxt^[I]:='@@DELETE';
    End;
    Inc(Lines,2);
    AutoTxt^[Lines-1]:=Path+'PCH_LL.COM';
    AutoTxt^[Lines]:=Drive+':\PCH.BAT';
  End;

  {$I-}
  Procedure Read_Autoexec;
  Var I : Byte;
  Begin
    New(AutoTxt);
    Lines:=0;
    Reset(B);
    While (Not EoF(B)) And (Lines<100) Do
    Begin
      Inc(Lines);
      Readln(B,AutoTxt^[Lines]);
    End;
    Close(B);
  End;

  Procedure Write_Autoexec;
  Var I : Byte;
  Begin
    Assign(B,Autoexec);
    Rewrite(B);
    For I:=1 To Lines Do
      If AutoTxt^[I]<>'@@DELETE' Then Writeln(B,AutoTxt^[I]);
    Close(B);
    Dispose(AutoTxt);
  End;
  {$I+}

Begin
  W^.Show;
  ClrScr;
  Writeln(' Do you want to run Power-Choice in color or monochrome');
  Writeln(' mode ?');
  W2^.Show;
  ClrScr;
  Writeln;
  Writeln(' What videomode ?');
  Writeln;
  Writeln('    COLOR');
  Writeln('    MONOCHROME');
  I:=1;
  Repeat
    InvChars(3,16,3+I);
    CH:=ReadKey;
    InvChars(3,16,3+I);
    Case CH Of #13 : ;
               #27 : Exit;
               #0  : Case ReadKey Of #72 : Dec(I);
                                     #80 : Inc(I);
                     End;
    End;
    If I<1 Then I:=2;
    If I>2 Then I:=1;
  Until CH=#13;
  If I=1 Then Videomode:=Color Else Videomode:=Monochrome;
  If Videoboard In [HercMono,CGA,EGA,EGA64,EGAMono] Then
  Begin
    W^.Show;
    ClrScr;
    Writeln(' Do you want to use the screen saver ? It will switch off');
    Writeln(' the display after 3 minutes if there was no keypress,');
    Write(' mouse movement or other serial communication.');
    W2^.Show;
    ClrScr;
    Writeln;
    Writeln(' Use screen saver ?');
    Writeln;
    Writeln('    YES');
    Writeln('    NO');
    I:=1;
    Repeat
      InvChars(3,9,3+I);
      CH:=ReadKey;
      InvChars(3,9,3+I);
      Case CH Of #13 : ;
                 #27 : Exit;
                 #0  : Case ReadKey Of #72 : Dec(I);
                                       #80 : Inc(I);
                       End;
      End;
      If I<1 Then I:=2;
      If I>2 Then I:=1;
    Until CH=#13;
    If I=1 Then ScreenSaver:=1 Else ScreenSaver:=0;
  End Else ScreenSaver:=0;
  W^.Show;
  ClrScr;
  Writeln(' Please check the selected options and press "Y" if you');
  Writeln(' want to proceed or "N" to abort.');
  Abswrite(2,25,' Press "Y" or "N" . . .                                        ');
  W2^.Show;
  ClrScr;
  LowVideo;
  Writeln(' The following options are selected');
  LowVideo; Write('  Drive+Path : '); HighVideo; Writeln(Path);
  If Autoexec<>'' Then
  Begin
    LowVideo; Write('  Modify ',Autoexec,' .......... '); HighVideo;
    If ChangeAuto Then Writeln('Yes') Else Writeln('No');
  End;
  LowVideo; Write('  Reboot after installation ....... '); HighVideo;
  If Reboot Then Writeln('Yes') Else Writeln('No');
  LowVideo; Write('  Videomode ....................... '); HighVideo;
  If Videomode=Color Then Writeln('Color') Else Writeln('Monochrome');
  LowVideo; Write('  Screen Saver (only HGC,CGA,EGA) . '); HighVideo;
  If ScreenSaver=1 Then Write('Active') Else Write('Inactive');
  Repeat
    CH:=UpCase(ReadKey);
  Until CH In ['Y','N'];
  If CH='Y' Then
  Begin
    W2^.Hide;
    W^.Show;
    AbsWrite(2,25,'Please do not interrupt . . .');
    ClrScr;
    Writeln(' Installation proceeding ...');
    {$I-} ChDir(Path); {$I+}
    If IOResult<>0 Then
    Begin
      Write(#7#7' Problem - path does not exist.'#13);
      W2^.Show;
      Clrscr;
      Writeln;
      Center('Path '+Path+' doesn''t exist');
      GotoXY(1,3);
      Center('May I create it now ?');
      Writeln;
      Writeln('    YES');
      Write('    NO');
      I:=1;
      Repeat
        InvChars(3,9,4+I);
        CH:=ReadKey;
        InvChars(3,9,4+I);
        Case CH Of #13 : ;
                   #27 : Exit;
                   #0  : Case ReadKey Of #72 : Dec(I);
                                         #80 : Inc(I);
                         End;
        End;
        If I<1 Then I:=2;
        If I>2 Then I:=1;
      Until CH=#13;
      W2^.Hide;
      ClrEol;
      If I=2 Then
      Begin
        Dispose(W2,Done);
        Exit;
      End;
      {$I-} MkDir(Path); {$I+}
      If IOResult<>0 Then
      Begin
        Write(#7#7' Error - path cannot be created.'#13);
        W2^.Show;
        ClrScr;
        Writeln;
        Writeln(' Path could not be created.');
        Writeln(' Installation aborted.');
        Writeln;
        Writeln(' Press any key ...');
        CH:=ReadKey;
        Dispose(W2,Done);
        Exit;
      End;
      ChDir(Path);
    End;
    If Path[2]=':' Then GetDir(Ord(Path[1])-64,Path)
                   Else GetDir(0,Path);
    Drive:=Path[1];
    ArcFile:=FSearch('PCHOICE.DAT','A:\;B:');
    If ArcFile='' Then
    Begin
      ClrEol;
      Write(#7#7' Problem - Power-Choice disk not found.'#13);
      W2^.Show;
      Clrscr;
      Writeln;
      Writeln(' Power-Choice disk not found in drive A: or B: !');
      Writeln(' Installation aborted.');
      Writeln;
      Writeln(' Press any key ...');
      CH:=ReadKey;
      Dispose(W2,Done);
      Exit;
    End;
    UnArc(FExpand(ArcFile),Drive);
    If Result<>0 Then
    Begin
      ClrEol;
      Write(#7#7' Error - PCHOICE.DAT could not be expanded.'#13);
      W2^.Show;
      ClrScr;
      Writeln;
      Writeln(' Power-Choice could not be installed !');
      Writeln(' Installation aborted.');
      Writeln;
      Writeln(' Press any key ...');
      CH:=ReadKey;
      Dispose(W2,Done);
      Exit;
    End;
    ClrEol;
    Write(' Configuring PCH_LL.COM . . .'#13);
    If Path[Length(Path)]<>'\' Then Path:=Path+'\';
    Assign(F,Path+'PCH_LL.COM');
    {$I-}
    Reset(F);
    Seek(F,62);
    Read(F,CH);
    If CH=#6 Then
    Begin
      For I:=1 To 6 Do Write(F,ID[I]);
      CH:=Chr(ScreenSaver);
      Write(F,CH);
      CH:=Chr(Videomode);
      Write(F,CH);
      For I:=0 To Length(Path) Do Write(F,Path[I]);
    End Else Write(#7);
    Close(F);
    {$I+}
    If IOResult<>0 Then
    Begin
      ClrEol;
      Write(#7#7,' PCH_LL.COM cannot be modified.'#13);
      W2^.Show;
      ClrScr;
      Writeln;
      Writeln(' Low level application could not be configured !');
      Writeln(' Installation aborted.');
      Writeln;
      Writeln(' Press any key ...');
      CH:=ReadKey;
      Dispose(W2,Done);
      Exit;
    End;
    ClrEol;
    Write(' Writing ',Drive,':\PCH.BAT . . .'#13);
    Assign(B,Drive+':\PCH.BAT');
    {$I-}
    Rewrite(B);
    Writeln(B,'ECHO OFF');
    Writeln(B,':$AGAIN');
    Writeln(B,Path+'PCHOICE');
    Close(B);
    {$I+}
    If IOResult<>0 Then
    Begin
      ClrEol;
      Write(#7#7,' ',Drive,':\PCH.BAT cannot be created.'#13);
      W2^.Show;
      ClrScr;
      Writeln;
      Writeln(' Batch start file could not be created.');
      Writeln(' Installation aborted.');
      Writeln;
      Writeln(' Press any key ...');
      CH:=ReadKey;
      Dispose(W2,Done);
      Exit;
    End;
    ClrEol;
    Write(' Writing ',Path,'PCHOICE.MNU . . .'#13);
    Assign(B,Path+'PCHOICE.MNU');
    {$I-}
    Reset(B);
    {$I+}
    If IOResult=0 Then
    Begin
      W2^.Show;
      ClrScr;
      Writeln;
      Writeln(#7' A menu file already exists !');
      Writeln(' Do you really want to delete it ??');
      Writeln;
      Writeln('    NO');
      Writeln('    YES');
      I:=1;
      Repeat
        InvChars(3,9,3+I);
        CH:=ReadKey;
        InvChars(3,9,3+I);
        Case CH Of #13 : ;
                   #27 : Exit;
                   #0  : Case ReadKey Of #72 : Dec(I);
                                         #80 : Inc(I);
                         End;
        End;
        If I<1 Then I:=2;
        If I>2 Then I:=1;
      Until CH=#13;
      W2^.Hide;
    End Else I:=2;
    If I=2 Then
    Begin
      {$I-}
      Rewrite(B);
      For I:=1 To 4 Do Writeln(B);
      Writeln(B,'0');
      Writeln(B,'Main Group');
      For I:=1 To 2 Do Writeln(B,'0');
      Close(B);
      {$I+}
      If IOResult<>0 Then
      Begin
        ClrEol;
        Write(#7#7,' ',Path,'PCHOICE.MNU cannot be created.'#13);
        W2^.Show;
        ClrScr;
        Writeln;
        Writeln(' Menu file could not be created !');
        Writeln(' Installation aborted.');
        Writeln;
        Writeln(' Press any key ...');
        CH:=ReadKey;
        Dispose(W2,Done);
        Exit;
      End;
    End;
    If ChangeAuto Then
    Begin
      ClrEol;
      Find_Autoexec;
      Write(' Reading ',Autoexec,' . . .'#13);
      Assign(B,Copy(Autoexec,1,12)+'BAK');
      {$I-}
      Erase(B);
      I:=IOResult;
      Assign(B,Autoexec);
      Rename(B,Copy(Autoexec,1,12)+'BAK');
      Read_Autoexec;
      If IOResult<>0 Then
      Begin
        ClrEol;
        Write(#7#7,' ',Autoexec,' cannot be read.'#13);
        W2^.Show;
        ClrScr;
        Writeln;
        Writeln(' ',Autoexec,' could not be read !');
        Writeln(' Installation aborted.');
        Writeln;
        Writeln(' Press any key ...');
        CH:=ReadKey;
        Dispose(W2,Done);
        Exit;
      End;
      Modify_Autoexec;
      Write_Autoexec;
      {$I+}
      If IOResult<>0 Then
      Begin
        ClrEol;
        Write(#7#7,' ',Autoexec,' cannot be written.'#13);
        W2^.Show;
        ClrScr;
        Writeln;
        Writeln(' ',Autoexec,' could not be written to disk !');
        Writeln(' Installation aborted.');
        Writeln;
        Writeln(' Press any key ...');
        CH:=ReadKey;
        Dispose(W2,Done);
        Exit;
      End;
    End;
    Writeln;
    Write(' Installation complete.');
    W2^.Show;
    ClrScr;
    Writeln;
    Writeln(' Power-Choice is now completely installed.');
    Writeln;
    If Reboot Then
    Begin
      Writeln(' Press any key to reboot the computer !');
      CH:=ReadKey;
      Inline($B8/$40/$00/$8E/$D8/$B8/$34/$12/
             $A3/$72/$00/$EA/$00/$00/$FF/$FF);
    End;
    If Not ChangeAuto Then
    Begin
      Writeln(' Please insert the lines ');
      Writeln('  ',Path,'PCH_LL.COM');
      Writeln('  ',Drive,':\PCH.BAT');
      Writeln(' at the end of your AUTOEXEC.BAT file and');
      Writeln(' reboot the computer.');
      Write(' Press any key ...');
    End Else
    Begin
      Writeln(' You need to reboot the computer to start');
      Writeln(' Power-Choice.');
      Writeln(' Press any key ...');
    End;
    CH:=ReadKey;
    Completed:=True;
  End;
  Dispose(W2,Done);
End;

Procedure Easy;
Begin
  Path:='C:\PCHOICE';
  ChangeAuto:=True;
  Reboot:=True;
  New(W2,Init(15,5,65,12,ColorSet2,'Easy Installation'));
  AbsWrite(2,25,#24#25' - Move cursor   Enter - Select   Esc - Return to main screen');
  GoInstall;
End;

Procedure Customize;
Begin
  New(W2,Init(15,5,65,12,ColorSet2,'Custom Installation'));
  W^.Show;
  ClrScr;
  Writeln(' Please  type  the  complete  drive+path  where  you  want');
  Writeln(' Power-Choice to  be  installed, e.g. D:\TOOLS\PCHOICE !');
  Write(' Esc aborts the installation process.');
  AbsWrite(2,25,'Enter drive+path !   Esc - Return to main screen               ');
  W2^.Show;
  Writeln;
  Writeln(' Please enter drive+path :');
  Writeln;
  Writeln(' [                                ]');
  Path:='';
  Repeat
    CH:=EditString(4,4,Path,30,30);
    If CH=#27 Then Exit;
    If (CH=#13) And (Path='') Then Write(#7);
  Until (CH=#13) And (Path<>'');
  UpperCase(Path);
  ChangeAuto:=False;
  Reboot:=False;
  If Autoexec<>'' Then
  Begin
    W^.Show;
    ClrScr;
    Writeln(' If you want PCHINST.EXE to check and configure the');
    Writeln(' ',Autoexec,' file, select YES, otherwise select NO !');
    Write(' select NO !');
    AbsWrite(2,25,#24#25' - Move cursor   Enter - Select   Esc - Return to main screen');
    W2^.Show;
    ClrScr;
    Writeln;
    Writeln(' Permit modification of ',Autoexec,' ?');
    Writeln;
    Writeln('    YES');
    Writeln('    NO');
    I:=1;
    Repeat
      InvChars(3,9,3+I);
      CH:=ReadKey;
      InvChars(3,9,3+I);
      Case CH Of #13 : ;
                 #27 : Exit;
                 #0  : Case ReadKey Of #72 : Dec(I);
                                       #80 : Inc(I);
                       End;
      End;
      If I<1 Then I:=2;
      If I>2 Then I:=1;
    Until CH=#13;
    If I=1 Then
    Begin
      ChangeAuto:=True;
      W^.Show;
      ClrScr;
      Writeln(' Do you  want PCHINST.EXE to reboot the PC after having');
      Writeln(' completed the installation ? It is necessary to reboot');
      Write(' before Power-Choice is able to work !');
      W2^.Show;
      ClrScr;
      Writeln;
      Writeln(' Reboot after installation ?');
      Writeln;
      Writeln('    YES');
      Writeln('    NO');
      I:=1;
      Repeat
        InvChars(3,9,3+I);
        CH:=ReadKey;
        InvChars(3,9,3+I);
        Case CH Of #13 : ;
                   #27 : Exit;
                   #0  : Case ReadKey Of #72 : Dec(I);
                                         #80 : Inc(I);
                         End;
        End;
        If I<1 Then I:=2;
        If I>2 Then I:=1;
      Until CH=#13;
      If I=1 Then Reboot:=True;
    End;
  End;
  GoInstall;
End;

Begin
  Cursor.Off;
  TextBackGround(Black);
  ClrScr;
  TextBackGround(LightGray);
  TextColor(Black);
  ClrEol;
  Center('* * * P O W E R - C H O I C E  V1.0e Installation Utility * * *');
  GotoXY(1,24);
  ClrEol;
  Center('(C) 1990 Softwhere Associates. All rights reserved.');
  TextColor(White);
  TextBackGround(Black);
  GotoXY(1,4);
  Write('Checking hardware - Please wait . . .'#13);
  DetectHardWare;
  ClrEol;
  If Not CheckDos($0314) Then
  Begin
    NormVideo;
    ClrScr;
    Writeln('MS-Dos Version 3.20 or higher required.');
    Writeln('Installation aborted.');
    Cursor.On;
    Halt(1);
  End;
  InvByte:=$77;
  New(W,Init(10,18,70,22,ColorSet1,''));
  New(Main,Init(15,5,65,12,ColorSet2,'Power-Choice Installation'));
  Main^.Show;
  GotoXY(1,2);
  Writeln(' Easy Installation in C:\PCHOICE with defaults');
  Writeln(' Custom Installation in variable paths');
  Writeln;
  Writeln(' Don''t install and quit PCHINST');
  Main^.NoChoice([1,4,6]);
  Repeat
    AbsWrite(2,25,#24#25' - Move cursor   Enter - Select   Esc - Quit installation    ');
    W^.Show;
    ClrScr;
    Writeln(' Welcome to Power-Choice !!');
    Writeln(' Please choose between "Easy" and "Custom" Installation by');
    Write(' using the cursor keys !');
    Main^.Show;
    I:=Main^.Choose;
    Main^.Hide;
    Case I Of 2 : Easy;
              3 : Customize;
    End;
  Until (I In [0,5]) Or Completed;
  Dispose(W,Done);
  Dispose(Main,Done);
  Window(1,1,80,25);
  NormVideo;
  ClrScr;
  If Completed Then Writeln('PCHINST successfull.')
               Else Writeln('PCHINST terminated.');
  Writeln;
  Cursor.On;
End.