@echo off
echo Erzeuge pchoice.rez...
if not exist pchrez.exe goto w1
pchrez
if not exist pchoice1.rez goto error
del pchrez.exe
:w1
if not exist pchoice1.rez goto error
copy pchoice1.rez pchoice.rez
if not exist pchoice2.rez goto error
makerez
tvsc /r pchmsg pchoice Messages
copy pchoice.rez ..
del pchoice.rez
goto ok
:error
echo Die Dateien pchoice1.rez und pchoice2.rez existieren nicht
echo und/oder lassen sich nicht erzeugen.
:ok
