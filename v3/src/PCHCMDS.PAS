Unit PchCmds;
Interface

  { Menü-System Commands }

  Const
    { System Menü (≡) }
    cmAbout          = 100;   { ≡ │ Über Power-Choice }
    cmClearDeskTop   = 101;   { ≡ │ Desktop leeren }
    cmDos            = 102;   { ≡ │ Ende (Alt-X) }
    { Edit Menü }
    cmEditmode       = 103;   { Edit │ Editmodus }
    cmNewMenuItem    = 104;   { Edit │ Menüpunkt einfügen }
    cmEditMainGroup  = 105;   { Edit │ Hauptgruppe editiren }
    { Optionen Menü }
    cmSysOptions     = 108;   { Optionen │ System Optionen }
    cmDosOptions     = 109;   { Optionen │ Dos Optionen }
    cmChangePassword = 111;   { Optionen │ Passwort ändern  }
    { Tools Menü }
    cmDosShell       = 112;   { Tools │ Dos Shell }
    cmChangeDir      = 113;   { Tools │ Verzeichnis wechseln }
    cmCalc           = 114;   { Tools │ Taschenrechner }
    cmAscii          = 115;   { Tools │ Ascii Tabelle }
    cmCleanDisk      = 116;   { Tools │ Festplatte reinigen }
    cmTetris         = 118;   { Tools │ Tetris }

  { Weitere Commands }

  Const
    cmPrevCmd        = 1000;  { Dos Shell, vorheriger Befehl (F3) }
    cmPrevCmdSearch  = 1001;  { Dos Shell, in Befehlsliste suchen }
    cmReset          = 1002;
    cmMenuItem       = 1003;
    cmDeleteItem     = 12;    { Löschen Button (= cmYes) }
    cmSwitchGroup    = 13;    { Wechseln Button (= cmNo) }

  { Tetris Commands }
  Const
    cmDown           = 1100;
    cmRight          = 1101;
    cmLeft           = 1102;
    cmRotate         = 1103;
    cmDrop           = 1104;
    cmPause          = 1105;
    cmNewGame        = 1106;
    cmNoMoreGame     = 1107;
    hcTetris         = 2000;

  { Broadcasts and Messages }

  Const
    cmSearchMenuPage = 10001;  { Menüseite wird gesucht }
    cmRedrawMenu     = 10002;  { Menü wurde verändert }
    cmSearchDosShell = 10003;  { Dos Shell Fenster wird gesucht }
    cmRedrawPrompt   = 10004;  { Dos Shell Prompt neu zeichnen }
    cmRedrawMem      = 10005;  { Speicher hat sich verändert }
    cmSearchTetris   = 10006;  { Tetris Dialog suchen }
    cmModeChanged    = 10007;  { Modus, z.B. Editmodus, wurde gewechselt }

Implementation

End.