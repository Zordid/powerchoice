{$A-,B-,D-,E-,F-,G-,I-,L-,N-,O-,R-,S-,V-,X+}
Program PchRez;
Uses
  Objects, Drivers, Views, Dialogs, Menus, Fields, App,
  PchCmds, PchMsg, PchHelp, HintStat, Editor;

Var
  Rez: TResourceFile;
  Strm: PBufStream;
  Dlg: PDialog;
  R: TRect;
  Control, Labl, Histry : PView;

Procedure StrmError(Var S: TStream); far;
Begin
  Writeln('Stream error: ', S.Status);
  Halt(1);
End;

Procedure CreateStatusLine;
Var StatusLine: PHintStatusLine;
Begin
  Writeln('Adding statusline...');
  R.Assign(0, 24, 80, 25);
  StatusLine:=New(PHintStatusLine, Init(R,
    NewStatusDef(hcNoContext, hcMenuPage-1,
      NewStatusKey('~F1~ Hilfe', kbF1, cmHelp,
      nil),
    NewStatusDef(hcMenuStart, hcMenuEnd,
      NewStatusKey('~F1~ Hilfe', kbF1, cmHelp,
      nil),
    NewStatusDef(hcDlgStart, hcDlgEnd,
      NewStatusKey('~F1~ Hilfe', kbF1, cmHelp,
      nil),
    NewStatusDef(hcDragging, hcDragging,
      NewStatusKey('~'+#24#25#26#27+'~ Bewegen', kbNoKey, 0,
      NewStatusKey('~Shift-'+#24#25#26#27+'~ Größe verändern', kbNoKey, 0,
      NewStatusKey('~'+#17+'─┘~ Fertig', kbNoKey, 0,
      NewStatusKey('~Esc~ Abbruch', kbNoKey, 0,
      nil)))),
    NewStatusDef(hcMenuPage, hcMenuPage,
      NewStatusKey('~F1~ Hilfe', kbF1, cmHelp,
      NewStatusKey('~F4~ Dos Shell', kbF4, cmDosShell,
      NewStatusKey('~Alt-X~ Ende', kbAltX, cmDos,
      nil))),
    NewStatusDef(hcEditmodeActive, hcEditmodeActive,
      NewStatusKey('~F1~ Hilfe', kbF1, cmHelp,
      NewStatusKey('~F2~ Ende des Editmodus', kbF2, cmEditmode,
      NewStatusKey('~F3~ Neuer Menüpunkt', kbF3, cmNewMenuItem,
      NewStatusKey('~F10~ Menü', kbF10, cmMenu,
      NewStatusKey('~F4~ Dos Shell', kbF4, cmDosShell,
      nil))))),
    NewStatusDef(hcDosShell, hcDosShell,
      NewStatusKey('~F1~ Hilfe', kbF1, cmHelp,
      NewStatusKey('~F3~ Vorheriger Befehl', kbF3, cmPrevCmd,
      NewStatusKey('~F7~ Befehlsliste durchsuchen', kbF7, cmPrevCmdSearch,
      NewStatusKey('~Alt-X~ Ende', kbAltX, cmDos,
      nil)))),
    NewStatusDef(hcTetris, hcTetris,
      NewStatusKey('~Esc~ Ende', kbEsc, cmClose,
      NewStatusKey('~'#27'~ Links', kbLeft, cmLeft,
      NewStatusKey('~'#24'~ Rotieren', kbUp, cmRotate,
      NewStatusKey('~'#26'~ Rechts', kbRight, cmRight,
      NewStatusKey('~'#25'~ Fallenlassen', kbDown, cmDrop,
      nil))))),
    nil))))))))));
  Rez.Put(StatusLine, 'StatusLine');
  Dispose(StatusLine, Done);
End;

Procedure CreateHints;
Var Hints: TStrListMaker;
Begin
  Writeln('Adding hint strings...');
  With Hints Do
  Begin
    Init(16384, 256);
    { Hints zum Menüsystem }
    { System Menü }
    Put(hcSystemMenu, 'System Kommandos');
    Put(hcSCopyright, 'Zeigt Versionsnummer und Copyright Informationen');
    Put(hcSClearDeskTop, 'Schließt alle offenen Fenster bis auf das Hauptmenü');
    Put(hcSQuit, 'Beendet Power-Choice');
    { Edit Menü }
    Put(hcEditMenu, 'Editier-Funktionen sowie Optionen');
    Put(hcEEditmode, 'Schaltet Editmodus ein/aus');
    Put(hcENewItem, 'Fügt neuen Menüpunkt in aktuelle Gruppe ein');
    Put(hcEEditMainGroup, 'Hauptgruppe editieren');
    { Optionen Menü }
    Put(hcOptionsMenu, 'Diverse Einstellungen');
    Put(hcOSysOptions, 'Power-Choice System Optionen setzen');
    Put(hcODosOptions, 'Power-Choice Dos Optionen setzen');
    Put(hcOChangePassword, 'Verändern des Paßworts');
    { Tools Menü }
    Put(hcToolsMenu, 'Sonderfunktionen');
    Put(hcTDosShell, 'Öffnet ein Dos Shell Fenster bzw. aktiviert es');
    Put(hcTChangeDir, 'Verzeichnis wechseln');
    Put(hcTCalculator, 'Öffnet einen Taschenrechner');
    Put(hcTAscii, 'Öffnet eine Ascii-Tabelle');
    Put(hcTCleanDisk, 'Löscht verschiedene Dateien in allen Verzeichnissen');
    Put(hcTTetris, 'Tetris Spiel');
    { Fenster Menü }
    Put(hcWindowMenu, 'Fenster-Funktionen');
    Put(hcWNextPrev, 'Wechsle zum vorherigen/nächsten Fenster');
    Put(hcWClose, 'Akives Fenster schließen');
    Put(hcWResize, 'Größe ändern oder Bewegen');
    Put(hcWZoom, 'Fenster zoomen');
    { Hints zu Menüpunkt Dialogen }
    Put(hcCmdEditDialog, 'Programm editieren');
    Put(hcGroupEditDialog, 'Gruppe editieren');
    Put(hcDosCommands, 'Befehle angeben');
    Put(hcDosDirectory, 'Startverzeichnis angeben');
    Put(hcNamefield, 'Name des Menüpunktes angeben');
    Put(hcOptionsfield, 'Optionen: Uhr einblenden ?');
    Put(hcOptionsfield1, 'Optionen: Bildschirm Schoner aktiv ?');
    Put(hcOptionsfield2, 'Optionen: Nach Programmlauf auf Tastendruck warten ?');
    Put(hcOptionsfield3, 'Optionen: Soll der momentane Pfad beibehalten werden ?');
    Put(hcPasswordfield, 'Paßwort für Menüpunkt angeben');
    Put(hcHelpText, 'Hilfetext für Programm eingeben');
    Put(hcMemory, 'Speicheranforderungen angeben');
    Put(hcDeleteButton, 'Menüpunkt löschen');
    Put(hcSwitchGroupButton, 'Zur Gruppe wechseln');
    Put(hcColField, 'Spaltenanzahl festlegen');
    { Hints zu Dos Optionen }
    Put(hcDosOptionsDialog, 'Dos/Dos Shell Optionen einstellen');
    Put(hcDosShellOptField, 'Dos Shell im Quick-Run Modus ?');
    Put(hcDosShellOptField1, 'Dos Shell mit Auto ChangeDir ?');
    Put(hcDosShellPrptField, 'Dos Shell Prompt einstellen');
    Put(hcDosOptField, 'Uhr einblenden');
    Put(hcDosOptField1, 'Bildschrim Schoner aktiv');
    Put(hcDosOptField2, 'Bei Verlassen nach C:\ wechseln');
    Put(hcDosOptField3, 'Auf Tastendruck warten');
    { Hints zu System Optionen }
    Put(hcSysOptionsDialog, 'System Optionen einstellen');
    Put(hcDisplayLinesField, '25 Zeilen Modus');
    Put(hcDisplayLinesField1, '43/50 Zeilen Modus');
    Put(hcMenuField, 'Schließt bei <Tab> die aktuelle Gruppe');
  End;
  Rez.Put(@Hints, 'Hints');
  Hints.Done;
End;

Procedure CreateMenuBar;
Var MenuBar: PMenuBar;
Begin
  Writeln('Adding menubar...');
  R.Assign(0, 0, 80, 1);
  MenuBar:=New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~'+#240+'~', hcSystemMenu, NewMenu(
      NewItem('~Ü~ber Power-Choice', '', kbNoKey, cmAbout, hcSCopyright,
      NewItem('~D~esktop leeren', '', kbNoKey, cmClearDesktop, hcSClearDesktop,
      NewLine(
      NewItem('~E~nde', 'Alt-X', kbAltX, cmDos, hcSQuit,
      nil))))),
    NewSubMenu('~B~earbeiten', hcEditMenu, NewMenu(
      NewItem('~E~ditmodus', 'F2', kbF2, cmEditmode, hcEEditMode,
      NewLine(
      NewItem('~N~euen Menüpunkt hinzufügen...', 'F3', kbF3, cmNewMenuItem, hcENewItem,
      NewItem('~H~auptgruppe', 'Ctrl-F3', kbCtrlF3, cmEditMainGroup, hcEEditMainGroup,
      nil))))),
    NewSubMenu('~O~ptionen', hcOptionsMenu, NewMenu(
      NewItem('~S~ystem Optionen', '', kbNoKey, cmSysOptions, hcOSysOptions,
      NewItem('~D~os/Dos Shell Optionen', '', kbNoKey, cmDosOptions, hcODosOptions,
      NewLine(
      NewItem('~P~aßwort ändern', '', kbNoKey, cmChangePassword, hcOChangePassword,
      nil))))),
    NewSubMenu('~T~ools', hcToolsMenu, NewMenu(
      NewItem('~D~OS Shell', 'F4', kbF4, cmDosShell, hcTDosShell,
      NewItem('Verzeichnis ~w~echseln', 'F9', kbF9, cmChangeDir, hcTChangeDir,
      NewItem('~T~aschenrechner', '', kbNoKey, cmCalc, hcTCalculator,
      NewItem('~A~scii-Tabelle', '', kbNoKey, cmAscii, hcTAscii,
      NewItem('~F~estplatte aufräumen', '', kbNoKey, cmCleanDisk, hcTCleanDisk,
      NewLine(
      NewItem('Tet~r~is', '', kbNoKey, cmTetris, hcTTetris,
      nil)))))))),
    NewSubMenu('~F~enster', hcWindowMenu, NewMenu(
      NewItem('~N~ächstes', 'F6', kbF6, cmNext, hcWNextPrev,
      NewItem('~V~orheriges', 'Shift-F6', kbShiftF6, cmPrev, hcWNextPrev,
      NewItem('~S~chließen', 'Alt-F3', kbAltF3, cmClose, hcWClose,
      NewItem('~B~ewegen/Größe', 'Ctrl-F5', kbCtrlF5, cmResize, hcWResize,
      NewItem('~Z~oom', 'F5', kbF5, cmZoom, hcWZoom,
      nil)))))),
    nil)
  )))))));
  Rez.Put(MenuBar, 'MenuBar');
  Dispose(MenuBar, Done);
End;

Procedure CreateCmdEditDialog;
Begin
  Writeln('Adding CmdEditDialog...');
  R.Assign(4,1,71,21);
  New(Dlg, Init(R, 'Programm-Menüpunkt'));
  Dlg^.HelpCtx:=hcCmdEditDialog;
  R.Assign(14,2,34,3);
  Control := New(PKeyInputLine, Init(R, 22));
  Control^.HelpCtx := hcNameField;
  Dlg^.Insert(Control);
    R.Assign(2,2,8,3);
    Labl := New(PLabel, Init(R, '~N~ame:', Control));
    Dlg^.Insert(Labl);
  R.Assign(14,4,34,5);
  Control := New(PInputLine, Init(R, 10));
  Control^.HelpCtx := hcPasswordField;
  Dlg^.Insert(Control);
    R.Assign(2,4,11,5);
    Labl := New(PLabel, Init(R, '~P~aßwort:', Control));
    Dlg^.Insert(Labl);
  R.Assign(14,6,34,7);
  Control := New(PInputLine, Init(R, 80));
  Control^.HelpCtx := hcHelpText;
  Dlg^.Insert(Control);
    R.Assign(2,6,13,7);
    Labl := New(PLabel, Init(R, 'Hilfe~t~ext:', Control));
    Dlg^.Insert(Labl);
  R.Assign(2,10,34,11);
  Control := New(PInputLine, Init(R, 80));
  Control^.HelpCtx := hcDosDirectory;
  Dlg^.Insert(Control);
    R.Assign(2,9,19,10);
    Labl := New(PLabel, Init(R, '~S~tartverzeichnis', Control));
    Dlg^.Insert(Labl);
  R.Assign(2,12,34,18);
  Control := New(PMemoedit, Init(R, nil, nil));
  Control^.HelpCtx := hcDosCommands;
  Dlg^.Insert(Control);
    R.Assign(2,11,10,12);
    Labl := New(PLabel, Init(R, '~B~efehle', Control));
    Dlg^.Insert(Labl);
  R.Assign(48,2,58,3);
  Control := New(PNumInputLine, Init(R, 3, 0, 640));
  Control^.HelpCtx := hcMemory;
  Dlg^.Insert(Control);
    R.Assign(37,2,47,3);
    Labl := New(PLabel, Init(R, 'Sp~e~icher:', Control));
    Dlg^.Insert(Labl);
  R.Assign(59,2,65,3);
  Control := New(PStaticText, Init(R, 'KBytes'));
  Dlg^.Insert(Control);
  R.Assign(37,5,65,9);
  Control := New(PCheckboxes, Init(R,
    NewSItem('Uhr einblenden',
    NewSItem('Bildschirm Schoner',
    NewSItem('Auf Tastendruck warten',
    NewSItem('Alten Pfad sichern',Nil))))));
  PCluster(Control)^.Value := 0;
  Control^.HelpCtx := hcOptionsField;
  Dlg^.Insert(Control);
    R.Assign(37,4,46,5);
    Labl := New(PLabel, Init(R, '~O~ptionen', Control));
    Dlg^.Insert(Labl);
  R.Assign(44,11,57,13);
  Control := New(PButton, Init(R, '~O~K', cmOK, bfDefault));
  Dlg^.Insert(Control);
  R.Assign(44,13,57,15);
  Control := New(PButton, Init(R, 'Abbruch', cmCancel, bfNormal));
  Dlg^.Insert(Control);
  R.Assign(44,15,57,17);
  Control := New(PButton, Init(R, '~L~öschen', cmYes, bfNormal));
  Control^.HelpCtx := hcDeleteButton;
  Dlg^.Insert(Control);
  R.Assign(44,17,57,19);
  Control := New(PButton, Init(R, '~H~ilfe', cmHelp, bfNormal));
  Dlg^.Insert(Control);
  Dlg^.SelectNext(False);
  Rez.Put(Dlg, 'CmdEditDialog');
  Dispose(Dlg, Done);
End;

Procedure CreateGroupEditDialog;
Begin
  Writeln('Adding GroupEditDialog...');
  R.Assign(18,5,66,16);
  New(Dlg, Init(R, 'Gruppen-Menüpunkt'));
  Dlg^.Options := Dlg^.Options or ofCentered;
  Dlg^.HelpCtx := hcGroupEditDialog;
  R.Assign(13,2,31,3);
  Control := New(PKeyInputLine, Init(R, 22));
  Control^.HelpCtx := hcNameField;
  Dlg^.Insert(Control);
    R.Assign(2,2,8,3);
    Labl := New(PLabel, Init(R, '~N~ame:', Control));
    Dlg^.Insert(Labl);
  R.Assign(13,4,31,5);
  Control := New(PInputLine, Init(R, 10));
  Control^.HelpCtx := hcPasswordField;
  Dlg^.Insert(Control);
    R.Assign(2,4,11,5);
    Labl := New(PLabel, Init(R, '~P~aßwort:', Control));
    Dlg^.Insert(Labl);
  R.Assign(13,6,21,7);
  Control := New(PNumInputLine, Init(R, 2, 1, 3));
  Control^.HelpCtx := hcColField;
  Dlg^.Insert(Control);
    R.Assign(2,6,11,7);
    Labl := New(PLabel, Init(R, '~S~palten:', Control));
    Dlg^.Insert(Labl);
  R.Assign(22,6,31,7);
  Control := New(PStaticText, Init(R, '(1 bis 3)'));
  Dlg^.Insert(Control);
  R.Assign(32,2,46,4);
  Control := New(PButton, Init(R, '~W~echseln', cmCancel, bfNormal));
  Control^.HelpCtx := hcSwitchGroupButton;
  Dlg^.Insert(Control);
  R.Assign(32,5,46,7);
  Control := New(PButton, Init(R, '~L~öschen', cmCancel, bfNormal));
  Control^.HelpCtx := hcDeleteButton;
  Dlg^.Insert(Control);
  R.Assign(6,8,18,10);
  Control := New(PButton, Init(R, '~O~K', cmOK, bfDefault));
  Dlg^.Insert(Control);
  R.Assign(19,8,32,10);
  Control := New(PButton, Init(R, 'Abbruch', cmCancel, bfNormal));
  Dlg^.Insert(Control);
  R.Assign(33,8,46,10);
  Control := New(PButton, Init(R, '~H~ilfe', cmHelp, bfNormal));
  Dlg^.Insert(Control);
  Dlg^.SelectNext(False);
  Rez.Put(Dlg, 'GroupEditDialog');
  Dispose(Dlg, Done);
End;

Procedure CreateMainGroupEditDialog;
Begin
  Writeln('Adding MainGroupEditDialog...');
  R.Assign(10,3,48,11);
  New(Dlg, Init(R, 'Haupt Gruppe'));

  R.Assign(3,3,25,4);
  Control := New(PKeyInputLine, Init(R, 20));
  Control^.HelpCtx := hcNameField;
  Dlg^.Insert(Control);

    R.Assign(3,2,8,3);
    Labl := New(PLabel, Init(R, '~N~ame', Control));
    Dlg^.Insert(Labl);

  R.Assign(26,3,34,4);
  Control := New(PNumInputLine, Init(R, 2, 1, 3));
  Control^.HelpCtx := hcColField;
  Dlg^.Insert(Control);

    R.Assign(26,2,34,3);
    Labl := New(PLabel, Init(R, '~S~palten', Control));
    Dlg^.Insert(Labl);

  R.Assign(2,5,10,7);
  Control := New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
  Control^.HelpCtx := hcGroupEditDialog;
  Dlg^.Insert(Control);

  R.Assign(12,5,23,7);
  Control := New(PButton, Init(R, 'Abbruch', cmCancel, bfNormal));
  Control^.HelpCtx := hcGroupEditDialog;
  Dlg^.Insert(Control);

  R.Assign(24,5,35,7);
  Control := New(PButton, Init(R, '~H~ilfe', cmHelp, bfNormal));
  Control^.HelpCtx := hcGroupEditDialog;
  Dlg^.Insert(Control);
  Dlg^.SelectNext(False);
  Rez.Put(Dlg, 'MainGroupEditDialog');
  Dispose(Dlg, Done);
End;

Procedure CreateCleanAskDialog;
Begin
  Writeln('Adding CleanAskDlg...');
  R.Assign(5,8,74,21);
  New(Dlg, Init(R, 'Bestätigung'));
  Dlg^.Options := Dlg^.Options or ofCentered;
  R.Assign(53,3,54,11);
  Control := New(PScrollbar, Init(R));
  Dlg^.Insert(Control);
  R.Assign(3,3,53,11);
  Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
  Dlg^.Insert(Control);
  R.Assign(3,2,21,3);
  Labl := New(PLabel, Init(R, 'Gefundene ~D~ateien', Control));
  Dlg^.Insert(Labl);
  R.Assign(55,4,66,6);
  Control := New(PButton, Init(R, '~J~a', cmYes, bfDefault));
  Dlg^.Insert(Control);
  R.Assign(55,7,66,9);
  Control := New(PButton, Init(R, '~N~ein', cmNo, bfNormal));
  Dlg^.Insert(Control);
  R.Assign(55,10,66,12);
  Control := New(PButton, Init(R, 'Abbruch', cmCancel, bfNormal));
  Dlg^.Insert(Control);
  R.Assign(55,2,64,3);
  Control := New(PStaticText, Init(R, 'Löschen ?'));
  Dlg^.Insert(Control);
  Dlg^.SelectNext(False);
  Rez.Put(Dlg, 'CleanAskDlg');
  Dispose(Dlg, Done);
End;

Procedure CreateDialogs;
Begin
  CreateCmdEditDialog;
  CreateGroupEditDialog;
  CreateMainGroupEditDialog;
  CreateCleanAskDialog;
End;

Procedure RegisterTypes;
Begin
  RegisterObjects;
  RegisterMenus;
  RegisterDialogs;
  RegisterViews;
  RegisterHintStat;
  RegisterFields;
  RegisterEditor;
  RegisterType(RStrListMaker);
End;

Begin
  RegisterTypes;
  StreamError:=@StrmError;
  Writeln('Creating PCHOICE1.REZ file...');
  Strm := New(PBufStream, Init('PCHOICE1.REZ', stCreate, 1024));
  Rez.Init(Strm);
  CreateStatusLine;
  CreateMenuBar;
  CreateHints;
  CreateDialogs;
  Rez.Done;
End.