@ECHO OFF
if NOT %1"==/r" goto ok
echo Erzeuge Ressourcen neu...
cd rezfiles
call rez
cd..
:ok
echo Kopiere PCHOICE.EXE...
if not exist pchoice.exe goto ende
copy /b pchoice.exe+pchoice.ovr+pchoice.rez c:\pchoice\pchoice.exe >nul
checkpos c:\pchoice\pchoice.exe userlst
copy pch3cpy.bat c:\pch.bat >nul
del pchoice.exe
del pchoice.ovr
dir c:\pchoice\pchoice.exe
pch
:ende
echo PCHOICE.EXE existiert nicht ! Neu compilieren !
