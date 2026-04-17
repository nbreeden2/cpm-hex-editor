# HEDIT - CP/M 2.2 Hex Editor

## Project Rules

- **Intel 8080 assembly ONLY** — no Z80 instructions (no EX, DJNZ, JR, IX/IY, etc.)
- Assembler: **M80** (Microsoft Macro-80). Linker: **L80**.
- After every .MAC file edit, run: `python CPMFMT.PY <file>`
- CPMFMT.PY inlines HEDIT.INC, normalizes CR+LF, appends Ctrl-Z EOF.
- BDOS calls clobber ALL registers. Any value needed across CALL must be saved to memory or stack.
- Version shown via ESC menu -> "About". Update in HEXMENU.MAC.
- Version also in: HEXHELP.MAC (help header), HEXSCR.MAC (separator SPRVER).
- Color variant controlled by `COLOR EQU` in HEXSCR.MAC (0=mono, 1=color).

## Build

```
python CPMFMT.PY                    # preprocess all .MAC
M80 =<module>                       # assemble (one per .MAC)
L80 HEDIT,HEXSCR,HEXKEY,HEXGAP,HEXIO,HEXMENU,HEXSRCH,HEXBLK,HEXKBND,HEXVIRT,HEXHELP,HEDIT/N/E
```

### Variant Build (mono + color)

```
python HEBUILD.PY 0                 # patch COLOR=0 (mono)
python HEBUILD.PY 1                 # patch COLOR=1 (color)
```

After patching, rerun `CPMFMT.PY HEXSCR.MAC` and reassemble HEXSCR only.
`build-all.bat` automates this, producing HEDIT.COM (mono) and HEDIT-CL.COM (color).

## Screen Layout (VT100/ANSI, 80x24)

```
Row  1: INFOBAR  — filename, file size (hex), offset (hex), INS/OVR, HEX/ASC mode
Row  2: COLHDR   — column header "Offset  00 01 02 ... 0F  ASCII"
Row  3-22: HEX AREA — 20 rows x 16 bytes = 320 bytes visible
         "0000: 41 42 43 44 45 46 47 48  49 4A 4B 4C 4D 4E 4F 50  ABCDEFGHIJKLMNOP"
Row 23: SEPRDRAW — separator line (version string + `=` fill)
Row 24: STATROW  — status messages / prompts
```

### Row format (72 chars):
- Cols 1-4: hex address (4 digits, 0000-FFFF)
- Col 5-6: ": "
- Cols 7-30: first 8 hex bytes ("XX XX XX XX XX XX XX XX")
- Col 31: extra space (group separator)
- Cols 32-55: second 8 hex bytes ("XX XX XX XX XX XX XX XX")
- Cols 56-57: "  " (gap)
- Cols 58-73: 16 ASCII chars (printable 20H-7EH shown, others as '.')

## Selective Redraw System (HEDIT.MAC main loop)

| DIRTY | DRTLINE | Action                                          |
|-------|---------|-------------------------------------------------|
| 1     | *       | SCRDRAW (full 20 rows + header + separator)     |
| 0     | 1       | SCREDCL (current row only)                      |
| 0     | 0       | No content redraw (cursor-only move)            |

INFOBAR and CURPOS always run at MLDONE regardless of flags.

## Module Map (11 linked modules)

| File | Purpose | Key Exports |
|------|---------|-------------|
| HEDIT.MAC | Entry point, main loop, action dispatch | INSMODE, DIRTY, CURBDP, TPATOP, DOEXIT |
| HEXSCR.MAC | Terminal I/O, hex screen rendering | SCRINIT, SCRDRAW, SCREDCL, INFOBAR, CURPOS, STATMSG, OUTSTR, OUTCHAR, CURGOTO |
| HEXKEY.MAC | Key input, VT100 ESC decode | GETKEY |
| HEXGAP.MAC | Gap buffer byte engine | GBINIT, GBINSRT, GBDLFT, GBDELRT, GBMVLT, GBMVRT, GBMVTP, GBMVEND, GBRDBLK |
| HEXIO.MAC | File load/save, Intel HEX format | FIOPEN, FISAVE, FIPROMPT |
| HEXMENU.MAC | ESC menu overlay | MNUSHOW |
| HEXSRCH.MAC | Hex/ASCII search | SRFIND, SRFNDNX |
| HEXBLK.MAC | Block mark, copy, delete, paste | BLMARK, BLCOPY, BLDEL, BLPASTE |
| HEXKBND.MAC | Key binding init from HEDIT.KEY | KBINIT |
| HEXVIRT.MAC | Virtual buffer I/O for large files | VIMODE, VISAVALL, VIGOTO |
| HEXHELP.MAC | Help screen overlay, BMDATEND | HLPSHOW |

## Gap Buffer Architecture (HEXGAP.MAC)

```
Memory:  [pre-gap bytes R1][---GAP---][post-gap bytes R2]
         base               GAPBG      GAPEN              base+BSIZE
```

- Purely byte-oriented — no line delimiters, no LF counting
- Cursor = byte offset in logical data
- Navigation: left/right = +/-1 byte, up/down = +/-16 bytes, page = +/-320 bytes

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

## Editing Modes

- **HEX mode** (default): cursor in hex field, 0-9/A-F input, two keystrokes per byte
- **ASCII mode** (Tab to toggle): cursor in ASCII field, printable char input
- **Insert mode**: new bytes inserted at cursor, data shifts right
- **Overwrite mode**: bytes replaced in place (default for hex editors)

## Key Constants (HEDIT.INC)

- EDITROW=20, EDITFR=3, SCRROWS=24, SCRCOLS=80
- BYTESROW=16, BYTESPG=320 (EDITROW*BYTESROW)
- HEXFCOL=7, ASCFCOL=58
- INFOROW=1, HDRROW=2, SEPRROW=23, STATROW=24
- CLIPMAX=2048, SRCHMAX=64, RECSIZ=128
