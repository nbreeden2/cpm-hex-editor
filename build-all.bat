cls
@echo off
REM ----------------------------------------------------------------
REM BUILD-ALL.BAT - Build HEDIT hex editor variants
REM
REM   HEDIT.COM    - Mono  (no color)
REM   HEDIT-CL.COM - Color (color)
REM
REM Requires: cpmulator.exe, M80.COM, L80.COM, Python (CPMFMT.PY)
REM ----------------------------------------------------------------

echo === HEDIT Multi-Variant Build ===

echo First cleanup
if exist HEDIT.COM   del HEDIT.COM 2>nul
if exist HEDIT-CL.COM del HEDIT-CL.COM 2>nul
if exist *.REL       del *.REL 2>nul

REM --- Format all source files (once) ---
echo Formatting source files...
python CPMFMT.PY
if errorlevel 1 goto fail

echo Assembling shared modules...
for %%M in (HEDIT HEXKEY HEXGAP HEXIO HEXMENU HEXSRCH HEXBLK HEXKBND HEXVIRT HEXHELP) do (
    cpmulator M80.COM =%%M
    echo %%M
	pause
    if errorlevel 1 goto fail
)

REM --- Build each variant ---
echo.
echo --- Variant 1/2: HEDIT.COM (mono) ---
python HEBUILD.PY 0
if errorlevel 1 goto fail
python CPMFMT.PY HECONFIG.INC
if errorlevel 1 goto fail
cpmulator M80.COM =HEXSCR
if errorlevel 1 goto fail
cpmulator L80.COM HEDIT,HEXSCR,HEXKEY,HEXGAP,HEXIO,HEXMENU,HEXSRCH,HEXBLK,HEXKBND,HEXVIRT,HEXHELP,HEDIT/N/E
if errorlevel 1 goto fail
copy /y HEDIT.COM HEDIT-MONO.COM >nul
echo Built HEDIT.COM (mono)

echo.
echo --- Variant 2/2: HEDIT-CL.COM (color) ---
python HEBUILD.PY 1
if errorlevel 1 goto fail
python CPMFMT.PY HECONFIG.INC
if errorlevel 1 goto fail
cpmulator M80.COM =HEXSCR
if errorlevel 1 goto fail
cpmulator L80.COM HEDIT,HEXSCR,HEXKEY,HEXGAP,HEXIO,HEXMENU,HEXSRCH,HEXBLK,HEXKBND,HEXVIRT,HEXHELP,HEDIT/N/E
if errorlevel 1 goto fail
copy /y HEDIT.COM HEDIT-CL.COM >nul
echo Built HEDIT-CL.COM (color)

REM --- Restore source to default (mono) ---
python HEBUILD.PY 0
python CPMFMT.PY HECONFIG.INC

REM --- Rename mono back to HEDIT.COM ---
copy /y HEDIT-MONO.COM HEDIT.COM >nul
del HEDIT-MONO.COM 2>nul

echo.
echo === All variants built ===
echo   HEDIT.COM    - Mono  (no color)
echo   HEDIT-CL.COM - Color (color)
goto end

:fail
echo === BUILD FAILED ===
exit /b 1

:end
