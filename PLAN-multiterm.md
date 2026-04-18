# Multi-Terminal Support for HEDIT

## Context

HEDIT currently only supports VT100/ANSI terminals. SEDIT (the companion text editor) supports VT100/ANSI, VT52, ADM-31, and Cromemco 3102 using link-time module substitution: each terminal type gets its own screen driver and key input module that exports identical PUBLIC symbols. The linker picks which `.REL` files to include. This plan ports that architecture to HEDIT, plus adds VT100 row auto-detection (DETSIZ).

## Architecture: Link-Time Module Substitution

NO conditional assembly for terminal type. Instead, swap modules at link time:

| Role | VT100/ANSI | VT52 | ADM-31 | Cromemco 3102 |
|---|---|---|---|---|
| Screen driver | HEXSCR.MAC | HEVT52.MAC | HEADM31.MAC | HEC3102.MAC |
| Key input | HEXKEY.MAC | HEXKEY.MAC | HEADM31K.MAC | HEC3102K.MAC |
| Menu | HEXMENU.MAC | HEXMNVT.MAC | HEXMNVT.MAC | HEXMNVT.MAC |
| Help | HEXHELP.MAC | HEXHELP.MAC | HEXHELP.MAC | HEXHELP.MAC |

- VT52 shares HEXKEY.MAC (same ESC prefix decode logic as VT100)
- ADM-31 and C3102 need custom key modules (different escape sequences)
- Non-VT100 terminals use HEXMNVT.MAC (plain-text menu, no embedded ANSI SGR)
- HEXHELP.MAC becomes terminal-agnostic by calling driver-exported attribute strings
- Color/mono remains VT100-only, controlled by `COLOR EQU` in HECONFIG.INC

## Output Files

| Variant | Output filename |
|---|---|
| VT100 mono | HEDIT.COM |
| VT100 color | HEDIT-CL.COM |
| VT52 | HEDIT-52.COM |
| ADM-31 | HEDIT-AD.COM |
| Cromemco 3102 | HEDIT-CR.COM |

---

## Implementation Steps

### Step 1: Create HECONFIG.INC and update HEBUILD.PY

**Goal**: Move `COLOR EQU` out of HEXSCR.MAC into its own config file (matching SEDIT's SECONFIG.INC pattern).

**Files to create**:
- `HECONFIG.INC` — two lines: comment + `COLOR   EQU     0`

**Files to modify**:
- `HEXSCR.MAC` — remove `COLOR EQU` from the inlined HEDIT.INC block; add `;INCLUDE HECONFIG.INC` directive (CPMFMT.PY will inline it)
- `CPMFMT.PY` — add HECONFIG.INC to the include inlining logic (currently only inlines HEDIT.INC)
- `HEBUILD.PY` — change target from HEXSCR.MAC to HECONFIG.INC; simplify regex to match `COLOR\s+EQU\s+\d+`
- `HEDIT.INC` — remove `COLOR EQU` if present (it may only exist in the inlined copy)

**Test**: Build mono and color variants. Verify identical `.COM` output to before.

---

### Step 2: Add ATTRON/ATROFF exports to HEXSCR.MAC

**Goal**: Export reverse-video-on and reverse-video-off strings so HEXHELP and HEXMNVT can use them without hardcoding ANSI sequences.

**Files to modify**:
- `HEXSCR.MAC` — add `PUBLIC ATTRON` / `PUBLIC ATROFF` exporting the existing `SGRREV` and `SGRRES` strings (or alias labels pointing to them)

**Test**: Build both variants. No functional change yet — just new exports.

---

### Step 3: Make HEXHELP.MAC terminal-agnostic

**Goal**: Remove all hardcoded ANSI escape sequences from HEXHELP.MAC so it works with any screen driver.

**Files to modify**:
- `HEXHELP.MAC`:
  - Replace local `HLPCLR` (ESC[0m+ESC[2J+ESC[H) with calls to SCRINIT or a new `SCRCLR` export
  - Replace `HLPHDR`/`HLPFTR` embedded ESC[7m/ESC[0m with `EXTRN ATTRON, ATROFF` + OUTSTR calls
  - Replace `HLPCEL` (ESC[K) with a call to an exported clear-to-EOL routine or keep as spaces
  - Fix hardcoded `MVI B,24` to use `STATROW`
  - Replace `MVI C,41` right-column offset with a named constant

**Test**: Build mono/color, verify help screen looks identical.

---

### Step 4: Create HEXMNVT.MAC (plain-text menu)

**Goal**: Menu variant for terminals without ANSI SGR. Copy of HEXMENU.MAC with all ANSI sequences removed.

**File to create**:
- `HEXMNVT.MAC` — copy from HEXMENU.MAC with these changes:
  - Replace local `ATTRREV`/`ATTRNRM` with `EXTRN ATTRON, ATROFF` from screen driver
  - Remove embedded `ESC[1m`/`ESC[0m` from all menu item text strings (MNTX1-MNTX0) — bold shortcut letters become plain text (like SEDIT's SEMENVT.MAC)
  - Must export `PUBLIC MNUSHOW`

**Test**: Can't test standalone yet — needed by Step 8.

---

### Step 5: Add runtime screen dimension variables

**Goal**: Convert compile-time screen constants to runtime variables so DETSIZ can adjust them. This is the most invasive change — it touches every module.

**Runtime variables to add to HEDIT.MAC DSEG** (exported as PUBLIC):
- `REROWS` DB EDITROW — actual edit row count (default 20)
- `RSEPR` DB SEPRROW — actual separator row (default 23)
- `RSTAT` DB STATROW — actual status row (default 24)
- `RBYTPG` DW BYTESPG — actual bytes per page (default 320 = REROWS * 16)

**EQU values stay in HEDIT.INC** as defaults — they are used to initialize the runtime variables and as compile-time fallbacks where the value can't change.

**Modules that need runtime variable references** (80 total uses across 11 files):
- `HEDIT.MAC` (23 uses) — page up/down use `LXI D,BYTESPG` which becomes `LHLD RBYTPG / XCHG`; scroll logic references BYTESPG; `MVI B,STATROW` becomes `LDA RSTAT / MOV B,A`
- `HEXSCR.MAC` (8 uses) — SCRDRAW loop count `CPI EDITROW` becomes `LDA REROWS / CMP B`; `MVI B,SEPRROW` becomes `LDA RSEPR / MOV B,A`; `MVI B,STATROW` similar
- `HEXMENU.MAC` (12 uses) — all `MVI B,STATROW` in prompt/status calls
- `HEXSRCH.MAC` (7 uses) — `MVI B,STATROW` in status messages
- `HEXIO.MAC` (5 uses) — `MVI B,STATROW`
- `HEXHELP.MAC` (5 uses) — `MVI B,STATROW`
- `HEXBLK.MAC`, `HEXVIRT.MAC`, `HEXKEY.MAC`, `HEXKBND.MAC`, `HEXGAP.MAC` — EQU defined but not referenced at runtime (only in inlined HEDIT.INC block)

**Pattern for conversion**: Every `MVI B,STATROW` becomes:
```asm
        EXTRN   RSTAT
        ...
        LDA     RSTAT
        MOV     B,A
```

Every `LXI D,BYTESPG` (or `LXI H,BYTESPG`) becomes:
```asm
        EXTRN   RBYTPG
        ...
        LHLD    RBYTPG
        XCHG
```

**Test**: Build both variants. Verify identical behavior (defaults match old compile-time values). No auto-detection yet.

---

### Step 6: Implement DETSIZ in HEXSCR.MAC (VT100 auto-detect)

**Goal**: Detect terminal rows at startup using VT100 Device Status Report.

**Add to HEXSCR.MAC** (adapted from SEDIT's SESCREEN.MAC lines 1983-2159):
```
PUBLIC  DETSIZ
```

**Algorithm**:
1. Save cursor: `ESC 7` (DECSC)
2. Move to far corner: `ESC[999;999H`
3. Query position: `ESC[6n` (DSR)
4. Poll BF_RAWIO with timeout, collect CPR response into buffer
5. Parse `ESC[rows;colsR` response
6. Restore cursor: `ESC 8` (DECRC)
7. Clamp rows to [24, 76]
8. Set: `RSTAT = rows`, `RSEPR = rows - 1`, `REROWS = rows - 4`, `RBYTPG = REROWS * 16`

**Add call in HEDIT.MAC**: Call `DETSIZ` before `SCRINIT` in startup sequence.

**Test**: Run in terminals of different sizes (24, 30, 40+ rows). Verify hex area expands/contracts correctly. Verify 24-row terminal still works identically to pre-DETSIZ.

---

### Step 7: Create HEVT52.MAC (VT52 screen driver)

**Goal**: First non-VT100 screen driver. Validates the module substitution architecture.

**File to create**: `HEVT52.MAC` — adapted from SEDIT's SEVT52.MAC, with HEDIT's rendering logic.

**Must export all PUBLIC symbols from HEXSCR.MAC**:
```
SCRINIT, SCRDRAW, SCREDCL, INFOBAR, CURPOS, STATMSG, STATCLR,
OUTCHAR, OUTSTR, CURGOTO, OUTN4HX, OUTN2HX, ISLOAD, DETSIZ,
ATTRON, ATROFF
```

**VT52 escape sequences**:
| Function | VT52 sequence |
|---|---|
| Clear screen | `ESC H ESC J` |
| Clear to EOL | `ESC K` |
| Cursor goto | `ESC Y (row+1FH) (col+1FH)` |
| Reverse on | `ESC p` |
| Reverse off | `ESC q` |
| Hide/show cursor | (not supported — omit) |
| Bold/dim/color | (not supported — mono only) |

**DETSIZ stub**: Fixed 80x24, same as SEDIT's VT52 stub.

**Key point**: CURGOTO is entirely different (binary encoding vs decimal ASCII). The rendering routines (SCRDRAW, SCREDCL, SCRHROW, INFOBAR etc.) are largely identical in logic but reference different escape string constants.

**Approach**: Copy HEXSCR.MAC as starting point. Replace all escape sequence strings. Replace CURGOTO. Remove COLOR conditional blocks (always mono). Remove HIDCUR/SHWCUR/APPKPD. Replace DETSIZ with stub.

**Test**: Link with `L80 HEDIT,HEVT52,HEXKEY,...,HEXMNVT,...,HEXHELP,...` and test in VT52 emulator.

---

### Step 8: Create HEADM31.MAC, HEADM31K.MAC (ADM-31)

**File to create**: `HEADM31.MAC` — screen driver adapted from SEDIT's SEADM31.MAC.

**ADM-31 escape sequences**:
| Function | ADM-31 sequence |
|---|---|
| Clear screen | `ESC *` |
| Clear to EOL | `ESC T` |
| Cursor goto | `ESC = (row+1FH) (col+1FH)` |
| Reverse on | `ESC G 4` |
| Reverse off | `ESC G 0` |

**File to create**: `HEADM31K.MAC` — key input adapted from SEDIT's SEADM31K.MAC. Exports same symbols as HEXKEY.MAC: `GETKEY, KBDTBL, CSITBL, SS3TBL, CTKTBL, CTQTBL`.

**Test**: Link and test in ADM-31 emulator.

---

### Step 9: Create HEC3102.MAC, HEC3102K.MAC (Cromemco 3102)

**File to create**: `HEC3102.MAC` — screen driver adapted from SEDIT's SEC3102.MAC.

**Cromemco 3102 escape sequences**:
| Function | C3102 sequence |
|---|---|
| Clear screen | `ESC E` |
| Clear to EOL | `ESC K` (same as VT52) |
| Cursor goto | `ESC F (row+20H) (col+20H)` |
| Reverse on | `ESC d P` |
| Reverse off | `ESC d @` |

**File to create**: `HEC3102K.MAC` — key input adapted from SEDIT's SEC3102K.MAC.

**Test**: Link and test in C3102 emulator.

---

### Step 10: Create HEPATCH.MAC (CP/M config patcher)

**Goal**: Standalone CP/M utility to patch HECONFIG.INC from the CP/M command line, enabling builds on real CP/M hardware without Python.

**File to create**: `HEPATCH.MAC` — simplified adaptation of SEDIT's SEPATCH.MAC.

**Usage**: `HEPATCH 0` (mono) or `HEPATCH 1` (color)

**Changes from SEPATCH**:
- FCB targets `HECONFIG INC` instead of `SECONFIG INC`
- Only one pattern: `COLOR   EQU`
- Only one argument (no SYNHI)
- Simplified usage/error messages

**Build**: `M80 =HEPATCH` / `L80 HEPATCH,HEPATCH/N/E` → HEPATCH.COM

**Test**: Run on CP/M, verify HECONFIG.INC is patched correctly.

---

### Step 11: Build infrastructure

**New .SUB files for CP/M builds**:
- `HEDIT.SUB` — VT100 mono (HEPATCH 0 + standard modules)
- `HEDITCL.SUB` — VT100 color (HEPATCH 1 + standard modules)
- `HEVT52.SUB` — VT52 (HEPATCH 0 + HEVT52/HEXKEY/HEXMNVT/HEXHELP)
- `HEADM31.SUB` — ADM-31 (HEPATCH 0 + HEADM31/HEADM31K/HEXMNVT/HEXHELP)
- `HEC3102.SUB` — Cromemco 3102 (HEPATCH 0 + HEC3102/HEC3102K/HEXMNVT/HEXHELP)

**Update build-all.bat**:
1. CPMFMT.PY on ALL .MAC files (including new ones)
2. Assemble shared modules once: HEDIT, HEXGAP, HEXIO, HEXSRCH, HEXBLK, HEXKBND, HEXVIRT
3. Assemble variant-specific modules (HEXMNVT once, each screen driver, each key module)
4. For VT100 mono: HEBUILD.PY 0 → format+assemble HEXSCR → link → HEDIT.COM
5. For VT100 color: HEBUILD.PY 1 → format+assemble HEXSCR → link → HEDIT-CL.COM
6. For VT52: link with HEVT52,HEXKEY,HEXMNVT,HEXHELP → HEDIT-52.COM
7. For ADM-31: link with HEADM31,HEADM31K,HEXMNVT,HEXHELP → HEDIT-AD.COM
8. For C3102: link with HEC3102,HEC3102K,HEXMNVT,HEXHELP → HEDIT-CR.COM

**Update documentation**: README.md, USER.DOC, TECH.DOC, CLAUDE.md

---

## Verification Plan

After each step, build and test:
1. **Steps 1-3**: VT100 mono + color builds produce identical behavior to pre-change
2. **Step 4**: HEXMNVT.MAC assembles without errors
3. **Step 5**: Runtime variables initialized correctly; 24-row terminal behaves identically
4. **Step 6**: DETSIZ detects rows on VT100; 24/30/40+ row terminals work; fallback on timeout works
5. **Steps 7-9**: Each terminal variant links, runs, and displays correctly in emulator
6. **Step 10**: HEPATCH patches HECONFIG.INC correctly on CP/M
7. **Step 11**: build-all.bat produces all 5 variants; full regression

## Critical Reference Files

| File | Role |
|---|---|
| `HEXSCR.MAC` | Primary terminal module — all escape sequences, CURGOTO, rendering |
| `HEDIT.MAC` | Main loop — screen variables, DETSIZ call site, page navigation |
| `HEXMENU.MAC` | Menu — embedded ANSI, template for HEXMNVT |
| `HEXHELP.MAC` | Help — hardcoded ANSI to remove |
| `HEDIT.INC` | Shared constants (compile-time defaults) |
| `HEBUILD.PY` | Python COLOR patcher (needs retarget to HECONFIG.INC) |
| `CPMFMT.PY` | Preprocessor (needs HECONFIG.INC support) |
| `build-all.bat` | Build orchestration |
| SEDIT `SEPATCH.MAC` | Template for HEPATCH.MAC |
| SEDIT `SEVT52.MAC` | Template for HEVT52.MAC |
| SEDIT `SEADM31.MAC` / `SEADM31K.MAC` | Templates for ADM-31 modules |
| SEDIT `SEC3102.MAC` / `SEC3102K.MAC` | Templates for C3102 modules |
| SEDIT `SESCREEN.MAC` lines 1983-2159 | Template for DETSIZ implementation |
