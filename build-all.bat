@echo off
REM build-all.bat - Build HEDIT hex editor using cpmulator
REM Requires: cpmulator.exe, M80.COM, L80.COM in PATH or current dir

echo === Building HEDIT Hex Editor ===

echo Preprocessing .MAC files...
python CPMFMT.PY HEDIT.MAC HEXSCR.MAC HEXKEY.MAC HEXGAP.MAC HEXIO.MAC HEXMENU.MAC HEXSRCH.MAC HEXBLK.MAC HEXKBND.MAC HEXVIRT.MAC HEXHELP.MAC

echo Assembling modules...
cpmulator M80.COM =HEDIT
if errorlevel 1 goto :err
cpmulator M80.COM =HEXSCR
if errorlevel 1 goto :err
cpmulator M80.COM =HEXKEY
if errorlevel 1 goto :err
cpmulator M80.COM =HEXGAP
if errorlevel 1 goto :err
cpmulator M80.COM =HEXIO
if errorlevel 1 goto :err
cpmulator M80.COM =HEXMENU
if errorlevel 1 goto :err
cpmulator M80.COM =HEXSRCH
if errorlevel 1 goto :err
cpmulator M80.COM =HEXBLK
if errorlevel 1 goto :err
cpmulator M80.COM =HEXKBND
if errorlevel 1 goto :err
cpmulator M80.COM =HEXVIRT
if errorlevel 1 goto :err
cpmulator M80.COM =HEXHELP
if errorlevel 1 goto :err

echo Linking...
cpmulator L80.COM HEDIT,HEXSCR,HEXKEY,HEXGAP,HEXIO,HEXMENU,HEXSRCH,HEXBLK,HEXKBND,HEXVIRT,HEXHELP,HEDIT/N/E
if errorlevel 1 goto :err

echo === Build complete: HEDIT.COM ===
goto :end

:err
echo === BUILD FAILED ===
exit /b 1

:end
