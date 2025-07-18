@echo off
setlocal

@echo starting process...

set "folder=../Fedex_BC_Labels/SOR632650"
set "printer=TSC DA210"

@echo Default printer set to %printer%

RUNDLL32 PRINTUI.DLL,PrintUIEntry /y /n "%printer%"

for %%f in ("%folder%\*.png") do (
    mspaint /pt "%%f" "%printer%"
    @echo printed %%f
    timeout /t 5 >nul
)

@echo Default Task Complete!