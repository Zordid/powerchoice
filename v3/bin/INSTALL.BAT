@echo off
echo INSTALL.BAT installiert Power-Choice 3.1 nun im Verzeichnis
echo C:\PCHOICE. Falls dieses Verzeichnis schon existiert, MUSS es
echo erst beseitigt und eine alte Version von Power-Choice entfernt
echo werden !
echo Mit bel. Taste wird fortgefahren, Ctrl-C um jetzt abzubrechen...
pause>nul
md c:\pchoice
copy *.* c:\pchoice
c:
cd \pchoice
copy pch.bat ..
del *.bat
del register.exe
echo Power-Choice wurde kopiert.
echo.
echo Die Datei PCHPW.SYS mu· von Ihnen in der erste Zeile der Datei
echo CONFIG.SYS geladen werden:
echo   DEVICE=C:\PCHOICE\PCHPW.SYS
echo.
echo Das Programm PCHEGA.COM mu· in der AUTOEXEC.BAT bei jedem Starten
echo geladen werden. (Bei DOS 5.0 oder hîher auch mit LOADHIGH)
echo   C:\PCHOICE\PCHEGA.COM
echo.
echo Am Ende der AUTOEXEC.BAT sollte PCH.BAT aufgerufen werden, wodurch
echo das MenÅ bei jedem Starten erscheint !
echo.
