{$X+}
Program PchRez;
Uses Objects, Drivers, Views, Dialogs, Menus, Fields, ColorSel, Editors, App,
     PchCmds, PchMsg, PchHelp, PchPW, HintStat, Editor, StrObj, PchTetris, PchOpt;

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
    NewStatusDef(hcDragging, hcDragging,
      NewStatusKey('~'+#24#25#26#27+'~ Bewegen', kbNoKey, 0,
      NewStatusKey('~Shift-'+#24#25#26#27+'~ Größe verändern', kbNoKey, 0,
      NewStatusKey('~'+#17+'─┘~ Fertig', kbNoKey, 0,
      NewStatusKey('~Esc~ Abbruch', kbNoKey, 0,
      nil)))),
    NewStatusDef(hcMenuPage, hcMenuPage,
      NewStatusKey('~F1~ Hilfe', kbF1, cmHelp,
      NewStatusKey('~F4~ Dos Shell', kbF4, cmDosShell,
      nil)),
    NewStatusDef(hcEditmode, hcEditmode,
      NewStatusKey('~F1~ Hilfe', kbF1, cmHelp,
      NewStatusKey('~F2~ Ende des Editmodus', kbF2, cmEditmode,
      NewStatusKey('~F3~ Neuer Menüpunkt', kbF3, cmNewMenuItem,
      NewStatusKey('~F10~ Menü', kbF10, cmMenu,
      NewStatusKey('~F4~ Dos Shell', kbF4, cmDosShell,
      nil))))),
    NewStatusDef(hcOrderingMode, hcOrderingMode,
      NewStatusKey('~F1~ Hilfe', kbF1, cmHelp,
      NewStatusKey('│ Verschieben von Menüpunkten:', kbNoKey, hcNoContext,
      NewStatusKey('~'+#17+'─┘~ Fertig', kbEnter, cmOk,
      NewStatusKey('~Esc~ Abbruch', kbEsc, cmCancel,
      nil)))),
    NewStatusDef(hcDosShell, hcDosShell,
      NewStatusKey('~F1~ Hilfe', kbF1, cmHelp,
      NewStatusKey('~F3~ Vorheriger Befehl', kbF3, cmPrevCmd,
      NewStatusKey('~F7~ Befehlsliste durchsuchen', kbF7, cmPrevCmdSearch,
      NewStatusKey('~Alt-X~ Ende', kbAltX, cmDos,
      nil)))),
    NewStatusDef(hcMenuStart, hcMenuEnd,
      NewStatusKey('~F1~ Hilfe', kbF1, cmHelp,
      nil),
    NewStatusDef(hcDlgStart, hcDlgEnd,
      NewStatusKey('~F1~ Hilfe', kbF1, cmHelp,
      nil),
    NewStatusDef(hcTetris, hcTetris,
      NewStatusKey('~Esc~ Ende', kbEsc, cmClose,
      NewStatusKey('~'#27'~ Links', kbLeft, cmLeft,
      NewStatusKey('~'#24'~ Rotieren', kbUp, cmRotate,
      NewStatusKey('~'#26'~ Rechts', kbRight, cmRight,
      NewStatusKey('~'#25'~ Fallenlassen', kbDown, cmDrop,
      nil))))),
    nil)))))))))));
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
    Put(hcSystemMenu-hcMenuStart, 'System Kommandos');
    Put(hcSCopyright-hcMenuStart, 'Zeigt Versionsnummer und Copyright Informationen');
    Put(hcSClearDeskTop-hcMenuStart, 'Schließt alle offenen Fenster bis auf das Hauptmenü');
    Put(hcSQuit-hcMenuStart, 'Beendet Power-Choice');
    { Edit Menü }
    Put(hcEditMenu-hcMenuStart, 'Editier-Funktionen sowie Optionen');
    Put(hcEEditmode-hcMenuStart, 'Schaltet Editmodus ein/aus');
    Put(hcENewItem-hcMenuStart, 'Fügt neuen Menüpunkt in aktuelle Gruppe ein');
    Put(hcEEditMainGroup-hcMenuStart, 'Hauptgruppe editieren');
    Put(hcEChangeOrder-hcMenuStart, 'Reihenfolge der Menüpunkte ändern');
    Put(hcEUserList-hcMenuStart, 'Benutzerliste ändern');
    { Optionen Menü }
    Put(hcOptionsMenu-hcMenuStart, 'Diverse Einstellungen');
    Put(hcOSysOptions-hcMenuStart, 'Power-Choice System Optionen setzen');
    Put(hcODosOptions-hcMenuStart, 'Power-Choice Dos Optionen setzen');
    Put(hcOColors-hcMenuStart, 'Verändern der Power-Choice Farben');
    Put(hcOChangePassword-hcMenuStart, 'Verändern des Benutzer- bzw. Hauptpassworts');
    { Tools Menü }
    Put(hcToolsMenu-hcMenuStart, 'Sonderfunktionen');
    Put(hcTDosShell-hcMenuStart, 'Öffnet ein Dos Shell Fenster bzw. aktiviert es');
    Put(hcTChangeDir-hcMenuStart, 'Verzeichnis wechseln');
    Put(hcTCalculator-hcMenuStart, 'Öffnet einen Taschenrechner');
    Put(hcTAscii-hcMenuStart, 'Öffnet eine Ascii-Tabelle');
    Put(hcTCleanDisk-hcMenuStart, 'Löscht verschiedene Dateien in allen Verzeichnissen');
    { Fenster Menü }
    Put(hcWindowMenu-hcMenuStart, 'Fenster-Funktionen');
    Put(hcWNextPrev-hcMenuStart, 'Wechsle zum vorherigen/nächsten Fenster');
    Put(hcWClose-hcMenuStart, 'Akives Fenster schließen');
    Put(hcWResize-hcMenuStart, 'Größe ändern oder Bewegen');
    Put(hcWZoom-hcMenuStart, 'Fenster zoomen');
    
    { Hints zu Dialogboxen }
    Put(hcCmdEditDialog-hcMenuStart, 'Befehls Editierdialogbox');
    Put(hcGroupEditDialog-hcMenuStart, 'Gruppen Editierdialogbox');
    Put(hcAccesscontrol-hcMenuStart, 'Zugriffskontrollmodus: vollständig sperren');
    Put(hcAccesscontrol1-hcMenuStart, 'Zugriffskontrollmodus: nur Tastatur sperren');
    Put(hcAccessfield-hcMenuStart, 'Nicht-Zugriffsberechtigte Benutzer angeben');
    Put(hcDosCommands-hcMenuStart, 'Dos Befehls angeben');
    Put(hcDosDirectory-hcMenuStart, 'Dos Verzeichnis angeben');
    Put(hcNamefield-hcMenuStart, 'Name des Menüpunktes angeben');
    Put(hcOptionsfield-hcMenuStart, 'Optionen: Uhr einblenden ?');
    Put(hcOptionsfield1-hcMenuStart, 'Optionen: Bildschirm Schoner aktiv ?');
    Put(hcOptionsfield2-hcMenuStart, 'Optionen: Nach Programmlauf auf Tastendruck warten ?');
    Put(hcOptionsfield3-hcMenuStart, 'Optionen: Soll der momentane Pfad beibehalten werden ?');
    Put(hcPasswordfield-hcMenuStart, 'Passwort für Menüpunkt angeben');
    Put(hcPchInstructions-hcMenuStart, 'Power-Choice Befehle angeben');
    Put(hcDeleteButton-hcMenuStart, 'Menüpunkt löschen');
    Put(hcSwitchGroupButton-hcMenuStart, 'Zur Gruppe wechseln');
    Put(hcColField-hcMenuStart, 'Spaltenanzahl festlegen');
  End;
  Rez.Put(@Hints, 'Hints');
  Hints.Done;
End;

Procedure CreateMenuBar1;
Var MenuBar: PMenuBar;
Begin
  Writeln('Adding menubar 1 ...');
  R.Assign(0, 0, 80, 1);
  MenuBar:=New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~'+#240+'~', hcSystemMenu, NewMenu(
      NewItem('~Ü~ber Power-Choice', '', kbNoKey, cmAbout, hcSCopyright,
      NewItem('~D~esktop leeren', '', kbNoKey, cmClearDesktop, hcSClearDesktop,
      NewLine(
      NewItem('~E~nde', 'Alt-X', kbAltX, cmDos, hcSQuit,
      nil))))),
    NewSubMenu('~E~dit', hcEditMenu, NewMenu(
      NewItem('~E~ditmodus', 'F2', kbF2, cmEditmode, hcEEditMode,
      NewLine(
      NewItem('~N~euen Menüpunkt hinzufügen...', '', kbNoKey, cmNewMenuItem, hcENewItem,
      NewItem('~H~aupt-Gruppe editieren', 'Ctrl-F2', kbCtrlF2, cmEditMainGroup, hcEEditMainGroup,
      NewItem('~R~eihenfolge ändern', 'Alt-F2', kbAltF2, cmChangeOrder, hcEChangeOrder,
      NewLine(
      NewItem('~B~enutzerliste', '', kbNoKey, cmUserList, hcEUserList,
      nil)))))))),
    NewSubMenu('~O~ptionen', hcOptionsMenu, NewMenu(
      NewItem('~S~ystem Optionen', '', kbNoKey, cmSysOptions, hcOSysOptions,
      NewItem('~D~os/Dos Shell Optionen', '', kbNoKey, cmDosOptions, hcODosOptions,
      NewItem('~F~arbanpassung', '', kbNoKey, cmColors, hcOColors,
      NewLine(
      NewItem('~H~auptpasswort ändern', '', kbNoKey, cmChangePassword, hcOChangePassword,
      nil)))))),
    NewSubMenu('~T~ools', hcToolsMenu, NewMenu(
      NewItem('~D~OS Shell', 'F4', kbF4, cmDosShell, hcTDosShell,
      NewItem('Verzeichnis ~w~echseln', 'F9', kbF9, cmChangeDir, hcTChangeDir,
      NewItem('~T~aschenrechner', '', kbNoKey, cmCalc, hcTCalculator,
      NewItem('~A~scii-Tabelle', '', kbNoKey, cmAscii, hcTAscii,
      NewItem('~F~estplatte aufräumen', '', kbNoKey, cmCleanDisk, hcTCleanDisk,
      NewLine(
      NewItem('Tet~r~is', '', kbNoKey, cmTetris, hcNoContext,
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
  Rez.Put(MenuBar, 'MainMenuBar');
  Dispose(MenuBar, Done);
End;

Procedure CreateMenuBar2;
Var MenuBar: PMenuBar;
Begin
  Writeln('Adding menubar 2 ...');
  R.Assign(0, 0, 80, 1);
  MenuBar:=New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~'+#240+'~', hcSystemMenu, NewMenu(
      NewItem('~Ü~ber Power-Choice', '', kbNoKey, cmAbout, hcSCopyright,
      NewItem('~D~esktop leeren', '', kbNoKey, cmClearDesktop, hcSClearDesktop,
      NewLine(
      NewItem('~E~nde', 'Alt-X', kbAltX, cmDos, hcSQuit,
      nil))))),
    NewSubMenu('~O~ptionen', hcOptionsMenu, NewMenu(
      NewItem('~D~os/Dos Shell Optionen', '', kbNoKey, cmDosOptions, hcODosOptions,
      NewItem('~F~arbanpassung', '', kbNoKey, cmColors, hcOColors,
      NewLine(
      NewItem('~P~asswort ändern', '', kbNoKey, cmChangePassword, hcOChangePassword,
      nil))))),
    NewSubMenu('~T~ools', hcToolsMenu, NewMenu(
      NewItem('~D~OS Shell', 'F4', kbF4, cmDosShell, hcTDosShell,
      NewItem('Verzeichnis ~w~echseln', 'F9', kbF9, cmChangeDir, hcTChangeDir,
      NewItem('~T~aschenrechner', '', kbNoKey, cmCalc, hcTCalculator,
      NewItem('~A~scii-Tabelle', '', kbNoKey, cmAscii, hcTAscii,
      NewItem('~F~estplatte aufräumen', '', kbNoKey, cmCleanDisk, hcTCleanDisk,
      NewLine(
      NewItem('Tet~r~is', '', kbNoKey, cmTetris, hcNoContext,
      nil)))))))),
    NewSubMenu('~F~enster', hcWindowMenu, NewMenu(
      NewItem('~N~ächstes', 'F6', kbF6, cmNext, hcWNextPrev,
      NewItem('~V~orheriges', 'Shift-F6', kbShiftF6, cmPrev, hcWNextPrev,
      NewItem('~S~chließen', 'Alt-F3', kbAltF3, cmClose, hcWClose,
      NewItem('~B~ewegen/Größe', 'Ctrl-F5', kbCtrlF5, cmResize, hcWResize,
      NewItem('~Z~oom', 'F5', kbF5, cmZoom, hcWZoom,
      nil)))))),
    nil)
  ))))));
  Rez.Put(MenuBar, 'UserMenuBar');
  Dispose(MenuBar, Done);
End;

Procedure CreateCmdEditDialog;
Begin
  Writeln('Adding CmdEditDialog...');
  R.Assign(5,1,75,22);
  New(Dlg, Init(R, 'Befehls - Menüpunkt'));
  Dlg^.Options := Dlg^.Options or ofCentered;
  Dlg^.HelpCtx:=hcCmdEditDialog;
  R.Assign(3,2,27,3);
  Control := New(PKeyInputLine, Init(R, 22));
  Dlg^.Insert(Control);
    R.Assign(3,1,8,2);
    Labl := New(PLabel, Init(R, '~N~ame', Control));
    Dlg^.Insert(Labl);
  R.Assign(29,2,41,3);
  Control := New(PInputLine, Init(R, 10));
  Dlg^.Insert(Control);
    R.Assign(29,1,38,2);
    Labl := New(PLabel, Init(R, '~P~asswort', Control));
    Dlg^.Insert(Labl);
  R.Assign(43,2,66,3);
  Control := New(PInputLine, Init(R, 80));
  Dlg^.Insert(Control);
    R.Assign(43,1,64,2);
    Labl := New(PLabel, Init(R, '~H~ilfetext', Control));
    Dlg^.Insert(Labl);
  R.Assign(22,4,66,5);
  Control := New(PInputLine, Init(R, 80));
  Dlg^.Insert(Control);
    R.Assign(3,4,21,5);
    Labl := New(PLabel, Init(R, '~S~tartverzeichnis:', Control));
    Dlg^.Insert(Labl);
  R.Assign(33,7,34,17);
  Control := New(PScrollbar, Init(R));
  Dlg^.Insert(Control);
  R.Assign(3,7,33,17);
  Control := New(PMemoEdit, Init(R, nil, PScrollbar(Control)));
  Dlg^.Insert(Control);
    R.Assign(3,6,15,7);
    Labl := New(PLabel, Init(R, '~B~efehle', Control));
    Dlg^.Insert(Labl);
  R.Assign(36, 7, 66, 11);
  Control := New(PCheckboxes, Init(R,
    NewSItem('Uhr einblenden',
    NewSItem('Bildschirm Schoner',
    NewSItem('Auf Tastendruck warten',
    NewSItem('Alten Pfad sichern',Nil))))));
  PCluster(Control)^.Value := 0;
  Dlg^.Insert(Control);
    R.Assign(36, 6, 46, 7);
    Labl := New(PLabel, Init(R, '~O~ptionen', Control));
    Dlg^.Insert(Labl);
  R.Assign(57,13,67,14);
  Control := New(PIntInputLine, Init(R, 10, 0, 640));
  Dlg^.Insert(Control);
    R.Assign(35,13,50,14);
    Labl := New(PLabel, Init(R, 'Hauptspeicher:', Control));
    Dlg^.Insert(Labl);
  R.Assign(57,14,67,15);
  Control := New(PIntInputLine, Init(R, 10, 0, MaxInt));
  Dlg^.Insert(Control);
    R.Assign(35,14,57,15);
    Labl := New(PLabel, Init(R, 'Erweiterungsspeicher:', Control));
    Dlg^.Insert(Labl);
  R.Assign(2,18,17,20);
  Control := New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
  Dlg^.Insert(Control);
  R.Assign(19,18,34,20);
  Control := New(PButton, Init(R, 'Abbruch', cmCancel, bfNormal));
  Dlg^.Insert(Control);
  R.Assign(36,18,51,20);
  Control := New(PButton, Init(R, '~L~öschen', cmYes, bfNormal));
  Dlg^.Insert(Control);
  R.Assign(53,18,68,20);
  Control := New(PButton, Init(R, '~H~ilfe', cmHelp, bfNormal));
  Dlg^.Insert(Control);
  R.Assign(35,12,65,13);
  Control := New(PStaticText, Init(R, 'Speicheranforderungen (in KB)'));
  Dlg^.Insert(Control);
  Dlg^.SelectNext(False);
  Rez.Put(Dlg, 'CmdEditDialog');
  Dispose(Dlg, Done);
End;

Procedure CreateGroupEditDialog;
Begin
  Writeln('Adding GroupEditDialog...');
  R.Assign(14,5,66,16);
  New(Dlg, Init(R, 'Gruppen-Menüpunkt'));
  Dlg^.Options := Dlg^.Options or ofCentered;
  R.Assign(3,3,25,4);
  Control := New(PKeyInputLine, Init(R, 22));
  Control^.HelpCtx := hcNameField;
  Dlg^.Insert(Control);

    R.Assign(3,2,8,3);
    Labl := New(PLabel, Init(R, '~N~ame', Control));
    Dlg^.Insert(Labl);

  R.Assign(26,3,35,4);
  Control := New(PIntInputLine, Init(R, 2, 1, 3));
  Control^.HelpCtx := hcColField;
  Dlg^.Insert(Control);

    R.Assign(26,2,34,3);
    Labl := New(PLabel, Init(R, '~S~palten', Control));
    Dlg^.Insert(Labl);

  R.Assign(3,6,15,7);
  Control := New(PInputLine, Init(R, 10));
  Control^.HelpCtx := hcPasswordField;
  Dlg^.Insert(Control);

    R.Assign(3,5,12,6);
    Labl := New(PLabel, Init(R, '~P~asswort', Control));
    Dlg^.Insert(Labl);

  R.Assign(17,6,35,7);
  Control := New(PInputLine, Init(R, 80));
  Control^.HelpCtx := hcAccessfield;
  Dlg^.Insert(Control);

    R.Assign(17,5,30,6);
    Labl := New(PLabel, Init(R, 'Kein ~Z~ugriff', Control));
    Dlg^.Insert(Labl);

  R.Assign(36,2,50,4);
  Control := New(PButton, Init(R, '~W~echseln', cmNo, bfNormal));
  Control^.HelpCtx := hcSwitchGroupButton;
  Dlg^.Insert(Control);

  R.Assign(36,5,50,7);
  Control := New(PButton, Init(R, '~L~öschen', cmYes, bfNormal));
  Control^.HelpCtx := hcDeletebutton;
  Dlg^.Insert(Control);

  R.Assign(3,8,11,10);
  Control := New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
  Control^.HelpCtx := hcGroupEditDialog;
  Dlg^.Insert(Control);

  R.Assign(14,8,25,10);
  Control := New(PButton, Init(R, 'Abbruch', cmCancel, bfNormal));
  Control^.HelpCtx := hcGroupEditDialog;
  Dlg^.Insert(Control);

  R.Assign(27,8,38,10);
  Control := New(PButton, Init(R, '~H~ilfe', cmHelp, bfNormal));
  Control^.HelpCtx := hcGroupEditDialog;
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
  Control := New(PIntInputLine, Init(R, 2, 1, 3));
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

Procedure CreateColorDialog;
Var
  Dlg: PColorDialog;
  Groups: PColorGroup;
Begin
  Writeln('Adding ColorDialog...');
  Groups :=
    ColorGroup('Arbeitsfläche',
      ColorItem('Hintergrund',          1, nil),
    ColorGroup('Gruppen',
      ColorItem('Rahmen Passiv',        77,
      ColorItem('Rahmen Aktiv',         78,
      ColorItem('Rahmen Symbole',       79,
      ColorItem('Schalter',             80,
      ColorItem('Schalter Gewählt',     81,
      ColorItem('Schalter Hotkey',      82,
      ColorItem('Edit: Schalter',       83,
      ColorItem('Edit: " Gewählt',      84,
      ColorItem('Edit: " Hotkey',       85,
      ColorItem('Schalter Schatten',    86,
      nil)))))))))),
    ColorGroup('Menüs',
      ColorItem('Normal',               2,
      ColorItem('Deaktiviert',          3,
      ColorItem('Hotkey',               4,
      ColorItem('Hotkey Gewählt',       7,
      ColorItem('Gewählt',              5,
      ColorItem('Gewählt+Deaktiviert',  6, nil)))))),
    ColorGroup('Dateifenster',
      ColorItem('Rahmen Passiv',        8,
      ColorItem('Rahmen Aktiv',         9,
      ColorItem('Rahmen Symbole',      10,
      ColorItem('Rollbalken',          11,
      ColorItem('Rollbalken Pfeile',   12,
      ColorItem('Text Normal',         13,
      ColorItem('Text Intensiv',       14, nil))))))),
    ColorGroup('Dos Shell',
      ColorItem('Rahmen Passiv',       72,
      ColorItem('Rahmen Aktiv',        73,
      ColorItem('Rahmen Symbole',      74,
      ColorItem('Rollbalken',          75,
      ColorItem('Rollbalken Pfeile',   76,
      nil))))),
    ColorGroup('Hilfefenster',
      ColorItem('Rahmen Passiv',       64,
      ColorItem('Rahmen Aktiv',        65,
      ColorItem('Rahmen Symbole',      66,
      ColorItem('Rollbalken',          67,
      ColorItem('Rollbalken Pfeile',   68,
      ColorItem('Hilfetext',           69,
      ColorItem('Hotlinks',            70,
      ColorItem('Hotlinks Gewählt',    71,
      nil)))))))),
    ColorGroup('Dialoge',
      ColorItem('Rahmen Passiv',       32,
      ColorItem('Rahmen Aktiv',        33,
      ColorItem('Rahmen Symbole',      34,
      ColorItem('Text Normal',         37,
      ColorItem('Label Normal',        38,
      ColorItem('Label Gewählt',       39,
      ColorItem('Label HotKey',        40,
      ColorItem('Schalter Normal',     41,
      ColorItem('Schalter Default',    42,
      ColorItem('Schalter Gewählt',    43,
      ColorItem('Schalter Gesperrt',   44,
      ColorItem('Schalter Hotkey',     45,
      ColorItem('Schalter Schatten',   46,
      ColorItem('Cluster Normal',      47,
      ColorItem('Cluster Gewählt',     48,
      ColorItem('Cluster HotKey',      49,
      ColorItem('Eingabe Normal',      50,
      ColorItem('Eingabe Markiert',    51,
      ColorItem('Eingabe Pfeile',      52,
      ColorItem('History Pfeil',       53,
      ColorItem('History Seiten',      54,
      Nil))))))))))))))))))))),
    Nil)))))));
  Dlg := New(PColorDialog, Init('', Groups));
  Rez.Put(Dlg, 'ColorDialog');
  Dispose(Dlg, Done);
End;

Procedure CreateLockedDialog;
Begin
  Writeln('Adding LockedDialog...');
  R.Assign(12,5,66,14);
  New(Dlg, Init(R, ''));
  Dlg^.Options := Dlg^.Options or ofCentered;
  R.Assign(9,3,44,4);
  Dlg^.Insert(New(PStaticText, Init(R, 'Ihr Passwort ist zur Zeit gesperrt.')));
  R.Assign(5,5,48,6);
  Dlg^.Insert(New(PStaticText, Init(R, 'Bitte schalten Sie den Computer wieder aus.')));
  R.Assign(4,4,49,5);
  Dlg^.Insert(New(PStaticText, Init(R, '---------------------------------------------')));
  Dlg^.SelectNext(False);
  Rez.Put(Dlg, 'LockedDialog');
  Dispose(Dlg, Done);
End;

Procedure CreateCleanDialog;
Begin
  Writeln('Adding CleanDlg...');
  R.Assign(17,4,63,19);
  New(Dlg, Init(R, 'Festplatte aufräumen'));
  Dlg^.Options := Dlg^.Options or ofCentered;
  R.Assign(3,3,18,4);
  Control := New(PInputLine, Init(R, 10));
  Dlg^.Insert(Control);
  R.Assign(3,2,15,3);
  Labl := New(PLabel, Init(R, '~F~estplatten', Control));
  Dlg^.Insert(Labl);
  R.Assign(3,6,43,7);
  Control := New(PInputLine, Init(R, 100));
  Dlg^.Insert(Control);
  R.Assign(3,5,24,6);
  Labl := New(PLabel, Init(R, 'Zu löschende ~D~ateien', Control));
  Dlg^.Insert(Labl);
  R.Assign(3,9,27,11);
  Control := New(PCheckboxes, Init(R,
    NewSItem('Löschen bestätigen',
    NewSItem('Statistik zeigen',
    Nil))));
  Dlg^.Insert(Control);
  R.Assign(3,8,12,9);
  Labl := New(PLabel, Init(R, '~O~ptionen', Control));
  Dlg^.Insert(Labl);
  R.Assign(20,12,31,14);
  Control := New(PButton, Init(R, '~S~tart', cmOK, bfDefault));
  Dlg^.Insert(Control);
  R.Assign(32,12,43,14);
  Control := New(PButton, Init(R, 'Abbruch', cmCancel, bfNormal));
  Dlg^.Insert(Control);
  Dlg^.SelectNext(False);
  Rez.Put(Dlg, 'CleanDlg');
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

Procedure CreateSysOptionsDialog;
Var
  Dlg: PSysDialog;
Begin
  Writeln('Adding SysOptionsDialog...');
  R.Assign(0, 0, 34, 13);
  New(Dlg, Init(R, 'System Optionen'));
  Dlg^.Options := Dlg^.Options or ofCentered;
  R.Assign(3, 4, 30, 5);
  Dlg^.MouseScrollBar := New(PScrollBar, Init(R));
  Dlg^.MouseScrollBar^.SetParams(1, 1, 20, 1, 1);
  Dlg^.MouseScrollBar^.Options := Dlg^.MouseScrollBar^.Options or ofSelectable;
  Dlg^.Insert(Dlg^.MouseScrollBar);
  R.Assign(2, 2, 21, 3);
  Dlg^.Insert(New(PLabel, Init(R, '~M~aus Doppelklick', Dlg^.MouseScrollBar)));
  R.Assign(3, 3, 30, 4);
  Dlg^.Insert(New(PClickTester, Init(R, 'Schnell    Mittel   Langsam')));
  R.Assign(3, 7, 23, 9);
  Control:=New(PRadioButtons, Init(R, NewSItem('~2~5 Zeilen', NewSItem('~4~3/50 Zeilen', nil))));
  Dlg^.Insert(Control);
  R.Assign(3, 6, 23, 7);
  Dlg^.Insert(New(PLabel, Init(R, 'Anzeigemodus', Control)));
  R.Assign(9, 10, 20, 12);
  Dlg^.Insert(New(PButton, Init(R, 'O~K~', cmOk, bfDefault)));
  Inc(R.A.X, 12); Inc(R.B.X, 12);
  Dlg^.Insert(New(PButton, Init(R, 'Abbruch', cmCancel, bfNormal)));
  Dlg^.SelectNext(False);
  Rez.Put(Dlg, 'SysOptionsDialog');
  Dispose(Dlg, Done);
End;

Procedure CreateDialogs;
Begin
  CreateColorDialog;
  CreateCmdEditDialog;
  CreateGroupEditDialog;
  CreateMainGroupEditDialog;
  CreateLockedDialog;
  CreateCleanDialog;
  CreateCleanAskDialog;
  CreateSysOptionsDialog;
End;

Procedure RegisterTypes;
Begin
  RegisterObjects;
  RegisterMenus;
  RegisterDialogs;
  RegisterViews;
  RegisterHintStat;
  RegisterFields;
  RegisterColorSel;
  RegisterEditor;
  RegisterType(RStr);
  RegisterType(RStrListMaker);
  RegisterType(RClickTester);
  RegisterType(RSysDialog);
End;

Begin
  RegisterTypes;
  StreamError:=@StrmError;
  Writeln('Creating PCHOICE1.REZ file...');
  Strm := New(PBufStream, Init('PCHOICE1.REZ', stCreate, 1024));
  Rez.Init(Strm);
  CreateStatusLine;
  CreateMenuBar1;
  CreateMenuBar2;
  CreateHints;
  CreateDialogs;
  Rez.Done;
End.