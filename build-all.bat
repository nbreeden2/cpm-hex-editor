@echo off
REM build-all.bat - Build HEDIT hex editor using cpmulator
REM Requires: cpmulator.exe, M80.COM, L80.COM in PATH or current dir

echo === Building HEDIT Hex Editor ===

echo Preprocessing .MAC files...
python CPMFMT.PY HEDIT.MAC HEXSCR.MAC HEXKEY.MAC HEXGAP.MAC HEXIO.MAC HEXMENU.MAC HEXSRCH.MAC HEXBLK.MAC HEXKBND.MAC HEXVIRT.MAC HEXHELP.MAC

echo Assembling modules...
cpmulator M80.COM =HEDIT
echo HEDIT
PAUSE
if errorlevel 1 goto :err
cpmulator M80.COM =HEXSCR
echo HEXSCR
PAUSE
if errorlevel 1 goto :err
cpmulator M80.COM =HEXKEY
echo HEXKEY
PAUSE
if errorlevel 1 goto :err
cpmulator M80.COM =HEXGAP
echo HEXGAP
PAUSE
if errorlevel 1 goto :err
cpmulator M80.COM =HEXIO
echo HEXIO
PAUSE
if errorlevel 1 goto :err
cpmulator M80.COM =HEXMENU
echo HEXMENU
PAUSE
if errorlevel 1 goto :err
cpmulator M80.COM =HEXSRCH
echo HEXSRCH
PAUSE
if errorlevel 1 goto :err
cpmulator M80.COM =HEXBLK
echo HEXBLK
PAUSE
if errorlevel 1 goto :err
cpmulator M80.COM =HEXKBND
echo HEXKBND
PAUSE
if errorlevel 1 goto :err
cpmulator M80.COM =HEXVIRT
echo HEXVIRT
PAUSE
if errorlevel 1 goto :err
cpmulator M80.COM =HEXHELP
echo HEXHELP
PAUSE
if errorlevel 1 goto :err

echo Linking...
cpmulator L80.COM HEDIT,HEXSCR,HEXKEY,HEXGAP,HEXIO,HEXMENU,HEXSRCH,HEXBLK,HEXKBND,HEXVIRT,HEXHELP,HEDIT/N/E
if errorlevel 1 goto :err

DIR *.REL
PAUSE
DIR H*.COM
PAUSE

echo === Build complete: HEDIT.COM ===
goto :end

:err
echo === BUILD FAILED ===
exit /b 1

:end
