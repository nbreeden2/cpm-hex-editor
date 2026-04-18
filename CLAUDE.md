# HEDIT - CP/M 2.2 Hex Editor

## Project Rules

- **Intel 8080 assembly ONLY** — no Z80 instructions (no EX, DJNZ, JR, IX/IY, etc.)
- Assembler: **M80** (Microsoft Macro-80). Linker: **L80**.
- After every .MAC, .INC, or .SUB file edit, run: `python CPMFMT.PY <file>`
- CPMFMT.PY normalizes to CR+LF and appends a Ctrl-Z EOF marker for .MAC and .SUB files. It does *not* append Ctrl-Z to .INC files (M80 `INCLUDE` must be able to return to the parent after processing the include).
- .MAC files use M80 `INCLUDE` to pull in .INC files at assemble time (no textual inlining — CPMFMT only normalises line endings).
- BDOS calls clobber ALL registers. Any value needed across CALL must be saved to memory or stack.
- Version strings: header `VERSION:` line in every .MAC / .INC, separator `SPRVER` and `SPRBLD` in the four screen drivers (HEXSCR, HEVT52, HEADM31, HEC3102), `HLPHDR` in HEXHELP.MAC, and README.md / USER.DOC / TECH.DOC.
- Colour variant controlled by `COLOR EQU` in HECONFIG.INC (0=mono, 1=colour). Only HEXSCR reads it.
- For standalone .COM sources (e.g. HEPATCH.MAC): use `CSEG` + `END START` with **no `ORG 100H`**. L80 emits the 0100H entry JMP from the END directive; an explicit `ORG 100H` inside CSEG without a preceding `ASEG` creates a 0x100-byte gap that inherits the previous M80 run's TPA on real CP/M and breaks silently.

## Variants

HEDIT ships as five binaries, each with its own self-contained SUBMIT build script:

| Binary | Terminal | Screen | Keys | Menu | SUBMIT |
|---|---|---|---|---|---|
| `HEDIT.COM` | VT100 mono | HEXSCR | HEXKEY | HEXMENU | `SUBMIT HEDIT` |
| `HEDIT-CL.COM` | VT100 colour | HEXSCR | HEXKEY | HEXMENU | `SUBMIT HEDIT-CL` |
| `HEDIT-52.COM` | VT52 | HEVT52 | HEXKEY | HEXMNVT | `SUBMIT HEDIT-52` |
| `HEDIT-AD.COM` | ADM-31 | HEADM31 | HEADM31K | HEXMNVT | `SUBMIT HEDIT-AD` |
| `HEDIT-CR.COM` | Cromemco 3102 | HEC3102 | HEC3102K | HEXMNVT | `SUBMIT HEDIT-CR` |

All four screen drivers export the same PUBLIC surface (`SCRINIT`, `SCRDRAW`, `SCREDCL`, `INFOBAR`, `CURPOS`, `STATMSG`, `STATCLR`, `OUTCHAR`, `OUTSTR`, `CURGOTO`, `OUTN4HX`, `OUTN2HX`, `ISLOAD`, `DETSIZ`, `ATTRON`, `ATROFF`, `CLRTOE`), so selection happens at link time.

## Build

### Host (Windows + cpmulator)

```
build-all.bat                       # builds all 5 variants
```

### CP/M-native (SUBMIT)

Each per-variant .SUB is self-contained: rebuilds HEPATCH.COM, runs HEPATCH to set COLOR, `ERA *.REL`, assembles required modules, links to TEMP.COM, then renames.

```
SUBMIT HEDIT           ; VT100 mono
SUBMIT HEDIT-CL        ; VT100 colour
SUBMIT HEDIT-52        ; VT52
SUBMIT HEDIT-AD        ; ADM-31
SUBMIT HEDIT-CR        ; Cromemco 3102
SUBMIT CLEAN           ; remove *.REL and TEMP.COM
SUBMIT HEPATCH         ; rebuild just HEPATCH.COM
```

### Manual (one variant)

```
python HEBUILD.PY 0                 # set COLOR=0 (or 1 for colour)
python CPMFMT.PY                    # normalise .MAC / .INC / .SUB
M80 =HEDIT
M80 =HEXSCR           (or HEVT52 / HEADM31 / HEC3102)
M80 =HEXKEY           (or HEADM31K / HEC3102K)
M80 =HEXGAP
M80 =HEXIO
M80 =HEXMENU          (or HEXMNVT for non-VT100)
M80 =HEXSRCH
M80 =HEXBLK
M80 =HEXKBND
M80 =HEXVIRT
M80 =HEXHELP
L80 HEDIT,<screen>,<keys>,HEXGAP,HEXIO,<menu>,HEXSRCH,HEXBLK,HEXKBND,HEXVIRT,HEXHELP,HEDIT/N/E
```

HEXHELP must be linked last (`BMDATEND` marks end of static data / start of gap buffer).

## Screen Layout (dynamic, VT100 DSR-sized)

```
Row 1:        INFOBAR   — filename, size (hex), offset (hex), INS/OVR, HEX/ASC mode
Row 2:        COLHDR    — column header "Offset  00 01 02 ... 0F  ASCII"
Rows 3..N-2:  HEX AREA  — REROWS rows x 16 bytes
              "0000: 41 42 ... 50  ABCDEFGHIJKLMNOP"
Row N-1:      SEPRDRAW  — separator (version string + '=' fill)
Row N:        STATROW   — status / prompts
```

`N` is the runtime row count:
- VT100 builds: DETSIZ queries the terminal with DSR at startup and sets `N = RSTAT` to the real terminal height, clamped to `[24, 76]`.
- VT52 / ADM-31 / C3102: DETSIZ is a stub; `N` stays at the compile-time default of 24.

### Row format (72 chars)
- Cols 1-4: hex address (4 digits, 0000-FFFF)
- Col 5-6: ": "
- Cols 7-30: first 8 hex bytes
- Col 31: group separator space
- Cols 32-55: second 8 hex bytes
- Cols 56-57: "  " (gap)
- Cols 58-73: 16 ASCII chars (20H-7EH shown, else '.')

## Runtime Screen Dimensions (HEDIT.MAC DSEG, all PUBLIC)

| Var | Default | Role |
|---|---|---|
| `REROWS` | `EDITROW` (20) | hex-area row count |
| `RSEPR`  | `SEPRROW` (23) | separator row |
| `RSTAT`  | `STATROW` (24) | status / prompt row |
| `RBYTPG` | `BYTESPG` (320) | bytes per page |

`DETSIZ` in HEXSCR.MAC updates all four after parsing a DSR CPR response. Every `MVI B,STATROW`-style site in the codebase was converted to `LDA RSTAT / MOV B,A` in Step 5. Helper routine `BPG16` in HEDIT.MAC returns `DE = RBYTPG - 16` (HL preserved) for the two scroll-alignment sites that used `BYTESPG-16` literally.

## Selective Redraw System (HEDIT.MAC main loop)

| DIRTY | DRTLINE | Action |
|-------|---------|---|
| 1 | * | SCRDRAW (full REROWS rows + header + separator) |
| 0 | 1 | SCREDCL (current row only) |
| 0 | 0 | No content redraw (cursor-only move) |

INFOBAR and CURPOS always run at MLDONE regardless of flags.

## Module Map

### Shared (link every variant)
| File | Purpose | Key Exports |
|------|---------|---|
| HEDIT.MAC    | Entry point, main loop, action dispatch, runtime dim vars | INSMODE, DIRTY, DRTLINE, CURBDP, TPATOP, DOEXIT, EDITMODE, NIBBLE, REROWS, RSEPR, RSTAT, RBYTPG |
| HEDIT.INC    | Shared equates (M80 INCLUDE) | — |
| HECONFIG.INC | `COLOR EQU` (patched by HEPATCH) | — |
| HEXGAP.MAC   | Gap buffer byte engine | GBINIT, GBINSRT, GBDLFT, GBDELRT, GBMVLT, GBMVRT, GBMVTP, GBMVEND, GBMVTO, GBRDBLK, GBLOGRD, GBTXEND, GBCSOFF |
| HEXIO.MAC    | File load/save, Intel HEX | FIOPEN, FISAVE, FIPROMPT, FISAVFN, FISMOD, WRKFCB |
| HEXSRCH.MAC  | Hex/ASCII search | SRFIND, SRFNDNX |
| HEXBLK.MAC   | Block mark, copy, delete, paste | BLMARK, BLCOPY, BLDEL, BLPASTE |
| HEXKBND.MAC  | Key binding init from HEDIT.KEY | KBINIT |
| HEXVIRT.MAC  | Virtual buffer I/O for large files | VIMODE, VISAVALL, VIGOTO |
| HEXHELP.MAC  | Help screen overlay, BMDATEND | HLPSHOW, BMDATEND |

### Terminal-specific (pick one of each per variant)

| Role | VT100 | VT52 | ADM-31 | C3102 |
|---|---|---|---|---|
| Screen driver | HEXSCR.MAC | HEVT52.MAC | HEADM31.MAC | HEC3102.MAC |
| Key input | HEXKEY.MAC | HEXKEY.MAC | HEADM31K.MAC | HEC3102K.MAC |
| ESC menu | HEXMENU.MAC | HEXMNVT.MAC | HEXMNVT.MAC | HEXMNVT.MAC |

### Build tools
| File | Purpose |
|------|---|
| HEPATCH.MAC | Standalone CP/M patcher for `COLOR EQU` in HECONFIG.INC |
| HEBUILD.PY  | Python equivalent of HEPATCH for host builds |
| CPMFMT.PY   | Normaliser for .MAC / .INC / .SUB |
| build-all.bat | Windows build of all 5 variants via cpmulator |
| HEDIT.SUB, HEDIT-CL.SUB, HEDIT-52.SUB, HEDIT-AD.SUB, HEDIT-CR.SUB | Per-variant CP/M builds |
| HEPATCH.SUB | Build just HEPATCH.COM |
| CLEAN.SUB | `ERA *.REL` + `ERA TEMP.COM` |

## Gap Buffer Architecture (HEXGAP.MAC)

```
Memory:  [pre-gap bytes R1][---GAP---][post-gap bytes R2]
         base               GAPBG      GAPEN              base+BSIZE
```

- Purely byte-oriented — no line delimiters, no LF counting
- Cursor = byte offset in logical data
- Navigation: left/right = ±1 byte, up/down = ±16 bytes, page = ±RBYTPG bytes

## Buffer Descriptor (BD_SIZE = 34 bytes, via CURBDP)

| Offset | Size | Field | Description |
|--------|------|-------|-------------|
| 0 | 2 | BD_BSTAR | Buffer base address |
| 2 | 2 | BD_BSIZE | Capacity in bytes |
| 4 | 2 | BD_GAPBG | Gap start offset |
| 6 | 2 | BD_GAPEN | Gap end offset |
| 8 | 2 | BD_TXEND | Logical data length |
| 10 | 2 | BD_TOPOFF | Top visible byte offset (aligned to 16) |
| 12 | 2 | BD_CSOFF | Cursor byte offset |
| 14 | 2 | BD_MRKBG | Block mark start (FFFF=unset) |
| 16 | 2 | BD_MRKEN | Block mark end (FFFF=unset) |
| 18 | 1 | BD_MODIF | Modified flag |
| 19 | 1 | BD_FILEFMT | File format (0=binary, 1=Intel HEX) |
| 20 | 12 | BD_FNAME | Drive + filename + ext |
| 32 | 2 | BD_BADDR | Intel HEX base address |

## Editing Modes

- **HEX mode** (default): cursor in hex field, 0-9/A-F input, two keystrokes per byte
- **ASCII mode** (Tab to toggle): cursor in ASCII field, printable char input
- **Insert mode**: new bytes inserted at cursor, data shifts right
- **Overwrite mode**: bytes replaced in place (default for hex editors)

## Key Constants (HEDIT.INC)

- `EDITROW=20`, `EDITFR=3`, `SCRROWS=24`, `SCRCOLS=80` (compile-time defaults)
- `BYTESROW=16`, `BYTESPG=320` (= `EDITROW*BYTESROW`)
- `HEXFCOL=7`, `ASCFCOL=58`
- `INFOROW=1`, `HDRROW=2`, `SEPRROW=23`, `STATROW=24`
- `CLIPMAX=2048`, `SRCHMAX=64`, `RECSIZ=128`

The EQUs serve as initial values for the runtime dimension variables (REROWS / RSEPR / RSTAT / RBYTPG in HEDIT.MAC DSEG). After DETSIZ runs, the runtime vars may differ from the EQUs; code paths that need the actual screen size read the runtime vars, not the EQUs.
