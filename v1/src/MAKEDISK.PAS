{$A+,B-,D+,E-,F-,I+,L+,N-,O-,R+,S+,V-}
{$M 16384,65536,131072}
Program MakeDisk;
Uses Dos,Crt,Forms,DeskTop;
Const Color1 : DTColor = ((Yellow,Blue),(LightGray,Blue),(White,LightGray));
      Five   = 1;
      Three  = 2;
      Drives : Array[Five..Three] Of Char = ('A','B');

Type DateStr     = String[8];
     ProjectType = Record
                     Name     : String[30];
                     Ver      : String[4];
                     Code     : String[3];
                     Dir      : String[30];
                     MakeFile : String[8];
                     Date,
                     Last  : DateStr;
                     Serial: LongInt;
                   End;
     PrjListPtr  = ^PrjList;
     PrjList     = Record
                     Prj       : ProjectType;
                     Next,Prev : PrjListPtr;
                   End;
Var  SA        : MessageWindow;
     MainMenu  : MenuWindow;
     I         : Byte;
     Projects  : PrjListPtr;
     Available : Byte;
     SDir      : String;

  Procedure WriteProjects;
  Var F : File Of ProjectType;
      P : PrjListPtr;
      CH: Char;
  Begin
    AbsWrite(2,24,'Saving project file . . .');
    If Projects<>Nil Then
      While Projects^.Prev<>Nil Do Projects:=Projects^.Prev;
    Assign(F,'D:\SA\SA.PRJ');
    {$I-} Rewrite(F); {$I+}
    If IOResult<>0 Then
    Begin
      Write(#7);
      AbsWrite(2,24,'I/O-Error: Cannot save project file. Press any key . . .');
      CH:=ReadKey;
      AbsWrite(1,24,MakeStr(#32,80));
      Exit;
    End;
    P:=Projects;
    While P<>Nil Do
    Begin
      {$I-} Write(F,P^.Prj); {$I+}
      If IOResult<>0 Then
      Begin
        Write(#7);
        AbsWrite(2,24,'I/O-Error: Cannot write to project file. Press any key . . .');
        CH:=Readkey;
        AbsWrite(1,24,MakeStr(#32,80));
        Exit;
      End;
      P:=P^.Next;
    End;
    Close(F);
    AbsWrite(1,24,MakeStr(#32,80));
  End;

  Procedure ReadProjects;
  Var F : File Of ProjectType;
      P : Projecttype;
      CH: Char;
  Begin
    AbsWrite(2,24,'Reading project file ...');
    Projects:=Nil;
    Available:=0;
    Assign(F,'D:\SA\SA.PRJ');
    {$I-} Reset(F); {$I+}
    If IOResult<>0 Then
    Begin
      Write(#7);
      AbsWrite(2,24,'Project file not found. Press any key . . .');
      CH:=ReadKey;
      AbsWrite(1,24,MakeStr(#32,80));
      Exit;
    End;
    While Not Eof(F) Do
    Begin
      {$I-} Read(F,P); {$I+}
      If IOResult<>0 Then
      Begin
        Write(#7);
        AbsWrite(2,24,'I/O-Error: Cannot read project file. Press any key . . .');
        CH:=ReadKey;
        AbsWrite(1,24,MakeStr(#32,80));
        Exit;
      End;
      If Projects=Nil Then
      Begin
        New(Projects);
        With Projects^ Do
        Begin
          Prj:=P;
          Next:=Nil;
          Prev:=Nil;
        End;
      End Else
      Begin
        New(Projects^.Next);
        With Projects^.Next^ Do
        Begin
          Prj:=P;
          Next:=Nil;
          Prev:=Projects;
        End;
        Projects:=Projects^.Next;
      End;
      Inc(Available);
    End;
    Close(F);
    AbsWrite(1,24,MakeStr(#32,80));
  End;

  Function Today:DateStr;
  Var Y,M,D,DoW : Word;
      S         : DateStr;
      T         : String[2];
      I         : Byte;
  Begin
    GetDate(Y,M,D,DoW);
    Str(M:2,T);
    S:=T;
    Str(D:2,T);
    S:=S+'/'+T;
    If Y<2000 Then Dec(Y,1900) Else Dec(Y,2000);
    Str(Y:2,T);
    S:=S+'/'+T;
    For I:=1 To 8 Do If S[I]=' ' Then S[I]:='0';
    Today:=S;
  End;

  Procedure StatusLine;
  Var S,T : String;
      Y,M,D,DoW : Word;
  Begin
    GetDate(Y,M,D,DoW);
    Case DoW Of 0 : S:='Sunday';
                1 : S:='Monday';
                2 : S:='Tuesday';
                3 : S:='Wednesday';
                4 : S:='Thursday';
                5 : S:='Friday';
                6 : S:='Saturday';
    End;
    S:=S+', ';
    Case M Of 1 : S:=S+'January';
              2 : S:=S+'February';
              3 : S:=S+'March';
              4 : S:=S+'April';
              5 : S:=S+'May';
              6 : S:=S+'June';
              7 : S:=S+'July';
              8 : S:=S+'August';
              9 : S:=S+'September';
              10: S:=S+'October';
              11: S:=S+'November';
              12: S:=S+'October';
    End;
    Str(D:3,T);
    S:=S+T+', ';
    Str(Y:4,T);
    S:=S+T;
    AbsWrite(3,25,S);
    AbsWrite(58,25,'Project(s) available.');
    Str(Available:3,S);
    AbsWrite(54,25,S);
  End;

  Function ChooseProject:Boolean;
  Var W   : ChoiceWindow;
      P   : PrjListPtr;
      I,N : Byte;
      S   : String;
  Begin
    New(W,Init(33,6,75,22,Color1,'Projects available'));
    If Projects<>Nil Then
      While Projects^.Prev<>Nil Do Projects:=Projects^.Prev;
    P:=Projects;
    While P<>Nil Do
    Begin
      S:=P^.Prj.Name+' V'+P^.Prj.Ver;
      W^.AddChoice(S);
      P:=P^.Next;
    End;
    N:=W^.Choose;
    If N>1 Then
      For I:=1 To N-1 Do Projects:=Projects^.Next;
    ChooseProject:=(N>0);
    Dispose(W,Done);
  End;

  Procedure UpperCase(Var S:String);
  Var I : Byte;
  Begin
    For I:=1 To Length(S) Do S[I]:=UpCase(S[I]);
  End;

  Function EditProject:Boolean;
  Var W : MessageWindow;
      F : Form;
  Begin
    New(W,Init(25,12,79,24,Color1,'Edit Project'));
    W^.Show;
    F.Init;
    F.Add(New(FStrPtr, Init(3 ,2,'Project Name   ', 30)));
    F.Add(New(FStrPtr, Init(3 ,3,'Version Number ', 4 )));
    F.Add(New(FStrPtr, Init(3 ,4,'Code           ', 3 )));
    F.Add(New(FStrPtr, Init(3 ,6,'Directory      ', 30)));
    F.Add(New(FStrPtr, Init(3 ,7,'Make file name ', 8 )));
    F.Add(New(FStrPtr, Init(3 ,9,'Date introduced', 8 )));
    F.Add(New(FStrPtr, Init(30,9,'Last update    ', 8 )));
    F.Add(New(FIntPtr, Init(3,10,'Last Serial No.', 0,9999 )));
    F.Put(Projects^.Prj);
    F.Show(True);
    Cursor.On;
    If F.Edit=CSave Then
    Begin
      F.Get(Projects^.Prj);
      With Projects^.Prj Do
      Begin
        UpperCase(Code);
        UpperCase(Dir);
        UpperCase(MakeFile);
      End;
      EditProject:=True;
    End Else EditProject:=False;
    Cursor.Off;
    F.Done;
    Dispose(W,Done);
  End;

  Procedure DeleteProject;
  Var P : PrjListPtr;
  Begin
    If Projects<>Nil Then
    With Projects^ Do
    Begin
      If Next=Nil Then P:=Prev Else P:=Next;
      If Prev<>Nil Then Prev^.Next:=Next;
      If Next<>Nil Then Next^.Prev:=Prev;
    End;
    Projects:=P;
    Dec(Available);
  End;

  Procedure Config;
  Var W : MenuWindow;
      P : PrjListPtr;
      I : Byte;
  Begin
    New(W,Init(16,10,31,16,Color1,'Config Menu'));
    W^.Show;
    Write('Edit project  ');
    Write('Insert project');
    Write('Delete project');
    Write('--------------');
    Write('Back to main ');
    W^.NoChoice([4]);
    Repeat
      StatusLine;
      I:=W^.Choose;
      Case I Of 2 : Begin
                      P:=Projects;
                      If P<>Nil Then
                        While P^.Next<>Nil Do P:=P^.Next;
                      Inc(Available);
                      New(Projects);
                      With Projects^ Do
                      Begin
                        With Prj Do
                        Begin
                          Name:='';
                          Code:='';
                          Ver:='1.00';
                          Dir:='D:\SA';
                          MakeFile:='';
                          Date:=Today;
                          Last:=Today;
                          Serial:=0;
                        End;
                        If P<>Nil Then P^.Next:=Projects;
                        Prev:=P;
                        Next:=Nil;
                      End;
                      If EditProject Then WriteProjects Else DeleteProject;
                    End;
                1 : If ChooseProject Then
                    Begin
                      If Projects<>Nil Then
                        If EditProject Then WriteProjects;
                    End;
                3 : If ChooseProject Then
                    Begin
                      DeleteProject;
                      WriteProjects;
                    End;
    End;
    Until I In [0,5];
    Dispose(W,Done);
  End;

  Procedure DoFormat(F:Byte);
  Var S : ^ScreenType;
      P : String[10];
      W : MessageWindow;
      CH: Char;
  Begin
    Case F Of 1 : P:='/F:360';
              2 : P:='/T:80 /N:9';
    End;
    New(S);
    S^:=Screen^;
    Window(1,1,80,25);
    Clrscr;
    Writeln('Disk in drive ',Chr(F+64),' has to be formatted . . .');
    Writeln('Please leave the volume label blank and answer N to return to MAKEDISK');
    Writeln;
    SwapVectors;
    Exec('C:\DOS\FORMAT.COM',Drives[F]+': '+P);
    SwapVectors;
    Screen^:=S^;
    Dispose(S);
    Window(6,20,74,21);
    If DosExitCode<>0 Then
    Begin
      New(W,Init(23,10,50,13,Color1,'Error'));
      W^.Show;
      Write(#7);
      Center('FORMAT not successful');
      Writeln;
      Center('Press any key . . .');
      CH:=ReadKey;
      Dispose(W,Done);
    End;
  End;

  Procedure MakeDisks;
  Const FTxt : Array[Five..Three] Of String[5] = ('5.25"','3.5"');
  Var W1          : MenuWindow;
      W2          : MessageWindow;
      Make        : Text;
      Disks,
      Disk        : Byte;
      Instruction : String;
      Parameter   : String;
      Finished,
      Error,
      Again,
      Recognized  : Boolean;
      Format      : Byte;
      Original    : String;
      CH          : Char;
      S,A         : String;

    Function GetCommand:Boolean;
    Var Q : String;
    Begin
      Q:='';
      If EoF(Make) Then
      Begin
        Close(Make);
        GetCommand:=False;
        Exit;
      End;
      While ((Q='') Or (Q[1]=';')) And (Not Eof(Make)) Do
      Begin
        {$I-} Readln(Make,Q); {$I+}
        If IOResult<>0 Then
        Begin
          GetCommand:=False;
          Exit;
        End;
        Original:=Q;
        UpperCase(Q);
        While Q[1]=' ' Do Delete(Q,1,1);
      End;
      While Pos('=',Q)<>0 Do Q[Pos('=',Q)]:=' ';
      If Pos(' ',Q)<>0 Then
      Begin
        Instruction:=Copy(Q,1,Pos(' ',Q)-1);
        Delete(Q,1,Pos(' ',Q));
        While Q[1]=' ' Do Delete(Q,1,1);
        Parameter:=Q;
      End Else
      Begin
        Instruction:=Q;
        Parameter:='';
      End;
      GetCommand:=(Instruction[1]<>';');
    End;

    Procedure DoDisk;
    Var SR : SearchRec;
    Begin
      Recognized:=True;
      Inc(Disk);
      If (Format=Three) And (Disk Mod 2=0) Then Exit;
      ClrEol;
      Write(#7' Please insert disk ',Round(Disk/Format),' of ',Round(Disks/Format));
      Write(' in drive ',Drives[Format],': !'#13);
      CH:=ReadKey;
      ClrEol;
      If CH=#27 Then
      Begin
        Error:=True;
        Exit;
      End;
      Repeat
        SR.Name:='*.*';
        FindFirst(Drives[Format]+':\*.*',AnyFile,SR);
        Case DosError Of 152 : Begin
                                 ClrEol;
                                 Write(#7' Please insert disk ',Round(Disk/Format),' of ',Round(Disks/Format));
                                 Write(' in drive ',Drives[Format],': !'#13);
                                 CH:=ReadKey;
                                 ClrEol;
                                 If CH=#27 Then
                                 Begin
                                   Error:=True;
                                   Exit;
                                 End;
                               End;
                         18  :;
                         0   : Begin
                                 ClrEol;
                                 Write(#7' Disk in drive ',Drives[Format],': is not empty ! Please change disk.'#13);
                                 CH:=ReadKey;
                                 ClrEol;
                                 If CH=#27 Then
                                 Begin
                                   Error:=True;
                                   Exit;
                                 End;
                               End;
                         Else
                         Begin
                           DoFormat(Format);
                           W2^.Show;
                           GotoXY(1,2);
                         End;
        End;
      Until DosError=18;
      If Not Error Then
      Begin
        GotoXY(54,1);
        Write(Disk:3);
        GotoXY(1,2);
      End;
    End;

    Procedure SetDisks(P:String);
    Var D,N : Integer;
    Begin
      Val(P,D,N);
      Recognized:=(N=0);
      If N=0 Then
      Begin
        Disks:=D;
        GotoXY(61,1);
        Write(Disks:3);
        GotoXY(1,2);
      End;
    End;

    Procedure DoCopy(P:String);
    Var Source,Dest : File;
        NumRead,
        NumWritten  : Word;
        Buffer      : ^Byte;
        Size        : LongInt;
        Regs        : Registers;

      Procedure ReadBytes(Var F:File;Var B;C:Word);
      Begin
        With Regs Do
        Begin
          BX:=FileRec(F).Handle;
          CX:=C;
          DS:=Seg(B);
          DX:=Ofs(B);
          AH:=63;
        End;
        MsDos(Regs);
        NumRead:=Regs.AX;
      End;

      Procedure WriteBytes(Var F:File;Var B;C:Word);
      Begin
        With Regs Do
        Begin
          BX:=FileRec(F).Handle;
          CX:=C;
          DS:=Seg(B);
          DX:=Ofs(B);
          AH:=64;
        End;
        MsDos(Regs);
        NumWritten:=Regs.AX;
      End;

    Begin
      ClrEol;
      Write(' Copying ',P,' to drive ',Drives[Format],': . . .'#13);
      Assign(Source,P);
      Assign(Dest,Drives[Format]+':'+P);
      {$I-}
      Reset(Source);
      Rewrite(Dest);
      {$I+}
      If IOResult<>0 Then
      Begin
        Clrscr;
        Writeln(' I/O-error. Couldn''t copy ',P,' to drive ',Drives[Format],': !');
        Write  (' Press any key . . .');
        CH:=ReadKey;
        Error:=True;
        Exit;
      End;
      Size:=MaxAvail;
      If Size>65535 Then Size:=65535;
      GetMem(Buffer,Size);
      Repeat
        ReadBytes(Source,Buffer^,Size);
        WriteBytes(Dest,Buffer^,NumRead);
        If NumWritten<>NumRead Then
        Begin
          ClrScr;
          Writeln(' I/O-error. Couldn''t copy ',P,' to drive ',Drives[Format],': !');
          Write  (' Press any key . . .');
          CH:=ReadKey;
          Error:=True;
        End;
      Until (NumRead=0) Or (NumWritten<>NumRead);
      {$I-}
      Close(Source);
      Close(Dest);
      {$I+}
      FreeMem(Buffer,Size);
      Recognized:=True;
      ClrEol;
    End;

    Procedure DoSerial(P:String);
    Var F      : File Of Char;
        N      : String[12];
        Offset : Word;
        Code   : Integer;
        C      : Char;
        I      : Byte;
    Begin
      Recognized:=(Pos(' ',P)<>0);
      If Not Recognized Then Exit;
      ClrEol;
      Write(' Writing Serial Number ',S,' to drive ',Drives[Format],': . . .'#13);
      N:=Copy(P,1,Pos(' ',P)-1);
      Delete(P,1,Pos(' ',P));
      While P[1]=' ' Do Delete(P,1,1);
      Val(P,Offset,Code);
      If Code<>0 Then
      Begin
        Recognized:=False;
        Exit;
      End;
      Assign(F,Drives[Format]+':'+N);
      {$I-}
      Reset(F);
      Seek(F,Offset);
      Read(F,C);
      {$I+}
      Code:=IOResult;
      If (Code<>0) Or (C<>#10) Then
      Begin
        Clrscr;
        Writeln(#7,' Serial Number Offset is corrupted or cannot be written to disk ',Drives[Format],': !');
        Write  (' Press any key . . .');
        CH:=ReadKey;
        Error:=True;
        Exit;
      End;
      {$I-}
      For I:=1 To 10 Do Write(F,S[I]);
      {$I+}
      If IOResult<>0 Then
      Begin
        ClrScr;
        Writeln(#7' Serial Number Cannot be written to drive ',Drives[Format],': !');
        Write  (' Press any key . . .');
        CH:=ReadKey;
        Error:=True;
        Exit;
      End;
      Close(F);
    End;

    Procedure DoVolume(P:String);
    Var S : ^ScreenType;
    Begin
      Recognized:=(Length(P)<=11);
      If Recognized Then
      Begin
        New(S);
        S^:=Screen^;
        Window(1,1,80,25);
        ClrScr;
        SwapVectors;
        Exec('D:\SA\VL.EXE',Drives[Format]+': '+P);
        SwapVectors;
        Screen^:=S^;
        Dispose(S);
        Window(6,20,74,21);
      End Else Error:=True;
    End;

    Procedure DoEnd;
    Var P : PrjListPtr;
    Begin
      Recognized:=True;
      Finished:=True;
      With Projects^.Prj Do
      Begin
        If S=A Then
        Begin
          Inc(Serial);
          P:=Projects;
          WriteProjects;
          Projects:=P;
        End;
        ClrScr;
        Write(#7#7,' ',Projects^.Prj.Name,' Ver ',Projects^.Prj.Ver,', S/N ');
        TextColor(Red);
        TextBackGround(LightGray);
        Write(S);
        TextColor(Color1[1,1]);
        TextBackGround(Color1[1,2]);
        Writeln(' is completed !');
        Write(' Press Enter to make another copy or Esc to abort . . .');
        Repeat
          CH:=ReadKey;
        Until CH In [#13,#27];
        Again:=(CH=#13);
      End;
    End;

  Begin
    New(W1,Init(23,10,50,13,Color1,'What format ?'));
    W1^.Show;
    Writeln('  5.25" Disk  (Drive ',Drives[Five],':)');
    Write('  3.5"  Disk  (Drive ',Drives[Three],':)');
    Format:=W1^.Choose;
    Dispose(W1,Done);
    If Format=0 Then Exit;
    With Projects^.Prj Do
    Begin
      {$I-} ChDir(Dir); {$I+}
      If IOResult<>0 Then;
      Assign(Make,Makefile+'.SA');
      New(W1,Init(23,8,57,14,Color1,'Creating Disk'));
      W1^.Show;
      TextColor(LightGreen);
      Writeln;
      LowVideo; Write(' Program: '); HighVideo; Writeln(Name);
      LowVideo; Write(' Version: '); HighVideo; Writeln(Ver);
      Writeln;
    End;
    Repeat
      {$I-} Reset(Make); {$I+}
      If IOResult<>0 Then
      Begin
        ClrScr;
        Writeln;
        Writeln(' Make file not found !');
        Writeln(' Press any key . . .');
        CH:=ReadKey;
        Dispose(W1,Done);
        Exit;
      End;
      Again:=False;
      New(W2,Init(5,19,75,22,Color1,''));
      With Projects^.Prj Do
      Begin
        S:='000000';
        S:=Code;
        S[0]:=#3;
        S:=S+Ver;
        Delete(S,Pos('.',S),1);
        S[0]:=#6;
        UpperCase(S);
        Str(Serial:4,A);
        S:=S+A;
        For I:=1 To Length(S) Do If S[I]=' ' Then S[I]:='0';
      End;
      Repeat
        A:=S;
        W2^.Show;
        ClrScr;
        Write(' About to create serial number ');
        TextBackGround(LightGray);
        TextColor(Red);
        Write(S);
        TextBackGround(Color1[1,2]);
        TextColor(Color1[1,1]);
        Write(' in drive ');
        Writeln(Drives[Format],': !');
        Write(' Press "S" to change S/N, Enter to go on or press Esc to abort . . .');
        Repeat
          CH:=UpCase(ReadKey);
          If CH=#27 Then
          Begin
            Dispose(W2,Done);
            Dispose(W1,Done);
            Exit;
          End;
        Until CH in ['S',#13];
        If CH='S' Then
        Begin
          ClrScr;
          Writeln(' Change Serial Number');
          Write(' Please enter new serial number (10 characters): ');
          Repeat
            If EditString(50,2,S,10,10)=#27 Then S:=A;
            If S<>#10 Then Write(#7);
          Until Length(S)=10;
        End;
      Until CH=#13;
      Disks:=1;
      Disk:=0;
      ClrScr;
      Write(' Creating S/N ');
      TextColor(Red);
      TextBackGround(LightGray);
      Write(S);
      TextColor(Color1[1,1]);
      TextBackGround(Color1[1,2]);
      Write(' in drive ',Drives[Format],': !');
      Writeln(' Creating disk ',disk:3,' of ',disks:3,'.');
      Finished:=False;
      Error:=False;
      While (Not Error) And (Not Finished) And (GetCommand) Do
      Begin
        Recognized:=False;
        If Instruction='DISK'       Then DoDisk;
        If Instruction='DISKS'      Then SetDisks(Parameter);
        If Instruction='COPY'       Then DoCopy(Parameter);
        If Instruction='MAKESERIAL' Then DoSerial(Parameter);
        If Instruction='VOLUME'     Then DoVolume(Parameter);
        If Instruction='END'        Then DoEnd;
        If Not Recognized Then
        Begin
          ClrScr;
          Writeln(' Instruction ',Original,' not recognized !');
          Write  (' Press any key . . .');
          CH:=ReadKey;
          Error:=True;
        End;
      End;
      If Finished Or Error Then Close(Make);
      Dispose(W2,Done);
    Until Not Again;
    Dispose(W1,Done);
  End;

Begin
  GetDir(0,SDir);
  Cursor.Off;
  TextBackGround(Black);
  TextColor(White);
  ClrScr;
  TextColor(LightRed);
  TextBackGround(Blue);
  GotoXY(1,24);
  ClrEol;
  New(SA,Init(15,1,65,4,Color1,''));
  SA^.Show;
  Center('Softwhere Associates Make Disk Program ...');
  Writeln;
  Center('The Bottom Line in Quality Software');

  Statusline;
  ReadProjects;
  New(MainMenu,Init(4,7,17,15,Color1,'Main Menu'));
  MainMenu^.Show;
  Write('Make disk(s)');
  Write('------------');
  Write('See projects');
  Write('------------');
  Write('Config      ');
  Write('------------');
  Write('Quit       ');
  MainMenu^.NoChoice([2,4,6]);
  Repeat
    StatusLine;
    I:=MainMenu^.Choose;
    Case I Of 1 : If ChooseProject Then MakeDisks;
              3 : If ChooseProject Then;
              5 : Config;
    End;
  Until I In [0,7];
  Dispose(MainMenu,Done);
  Window(1,1,80,25);
  NormVideo;
  ClrScr;
  Cursor.On;
  ChDir(SDir);
End.