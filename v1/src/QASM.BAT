@echo off
masm %1;
link %1;
exe2bin %1.exe %1.com
del %1.exe
