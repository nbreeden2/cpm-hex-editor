cls
@echo off
REM ----------------------------------------------------------------
REM BUILD-ALL.BAT - Build HEDIT hex editor variants
REM
REM   HEDIT.COM    - VT100/ANSI mono
REM   HEDIT-CL.COM - VT100/ANSI color
REM   HEDIT-52.COM - VT52 (mono only)
REM   HEDIT-AD.COM - Lear Siegler ADM-31 (mono only)
REM
REM Requires: cpmulator.exe, M80.COM, L80.COM, Python (CPMFMT.PY)
REM ----------------------------------------------------------------

echo === HEDIT Multi-Variant Build ===

echo First cleanup
if exist HEDIT.COM    del HEDIT.COM    2>nul
if exist HEDIT-CL.COM del HEDIT-CL.COM 2>nul
if exist HEDIT-52.COM del HEDIT-52.COM 2>nul
if exist HEDIT-AD.COM del HEDIT-AD.COM 2>nul
if exist *.REL        del *.REL        2>nul

REM --- Format all source files (once) ---
echo Formatting source files...
python CPMFMT.PY
if errorlevel 1 goto fail

echo Assembling shared modules...
for %%M in (HEDIT HEXKEY HEXGAP HEXIO HEXMENU HEXMNVT HEXSRCH HEXBLK HEXKBND HEXVIRT HEXHELP HEVT52 HEADM31 HEADM31K) do (
    cpmulator M80.COM =%%M
    echo %%M
	pause
    if errorlevel 1 goto fail
)

REM --- Build each variant ---
echo.
echo --- Variant 1/4: HEDIT.COM (VT100 mono) ---
python HEBUILD.PY 0
if errorlevel 1 goto fail
python CPMFMT.PY HECONFIG.INC
if errorlevel 1 goto fail
cpmulator M80.COM =HEXSCR
if errorlevel 1 goto fail
cpmulator L80.COM HEDIT,HEXSCR,HEXKEY,HEXGAP,HEXIO,HEXMENU,HEXSRCH,HEXBLK,HEXKBND,HEXVIRT,HEXHELP,HEDIT/N/E
if errorlevel 1 goto fail
copy /y HEDIT.COM HEDIT-M.COM >nul
echo Built HEDIT.COM (VT100 mono)

echo.
echo --- Variant 2/4: HEDIT-CL.COM (VT100 color) ---
python HEBUILD.PY 1
if errorlevel 1 goto fail
python CPMFMT.PY HECONFIG.INC
if errorlevel 1 goto fail
cpmulator M80.COM =HEXSCR
if errorlevel 1 goto fail
cpmulator L80.COM HEDIT,HEXSCR,HEXKEY,HEXGAP,HEXIO,HEXMENU,HEXSRCH,HEXBLK,HEXKBND,HEXVIRT,HEXHELP,HEDIT/N/E
if errorlevel 1 goto fail
copy /y HEDIT.COM HEDIT-CL.COM >nul
echo Built HEDIT-CL.COM (VT100 color)

echo.
echo --- Variant 3/4: HEDIT-52.COM (VT52) ---
REM VT52 is always mono; uses HEVT52 for screen + HEXMNVT for menu.
REM No HEXSCR reassembly needed -- the VT100-specific HEXSCR.REL
REM is simply not passed to L80.
cpmulator L80.COM HEDIT,HEVT52,HEXKEY,HEXGAP,HEXIO,HEXMNVT,HEXSRCH,HEXBLK,HEXKBND,HEXVIRT,HEXHELP,HEDIT/N/E
if errorlevel 1 goto fail
copy /y HEDIT.COM HEDIT-52.COM >nul
echo Built HEDIT-52.COM (VT52)

echo.
echo --- Variant 4/4: HEDIT-AD.COM (ADM-31) ---
REM ADM-31 uses HEADM31 for screen, HEADM31K for keys, HEXMNVT
REM for menu. Always mono.
cpmulator L80.COM HEDIT,HEADM31,HEADM31K,HEXGAP,HEXIO,HEXMNVT,HEXSRCH,HEXBLK,HEXKBND,HEXVIRT,HEXHELP,HEDIT/N/E
if errorlevel 1 goto fail
copy /y HEDIT.COM HEDIT-AD.COM >nul
echo Built HEDIT-AD.COM (ADM-31)

REM --- Restore source to default (mono) ---
python HEBUILD.PY 0
python CPMFMT.PY HECONFIG.INC

REM --- Rename mono back to HEDIT.COM ---
copy /y HEDIT-M.COM HEDIT.COM >nul
del HEDIT-M.COM 2>nul

echo.
echo === All variants built ===
echo   HEDIT.COM    - VT100/ANSI mono
echo   HEDIT-CL.COM - VT100/ANSI color
echo   HEDIT-52.COM - VT52
echo   HEDIT-AD.COM - ADM-31
goto end

:fail
echo === BUILD FAILED ===
exit /b 1

:end
