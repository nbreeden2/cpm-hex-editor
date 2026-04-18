# HEDIT — Hex Editor for CP/M 2.2

**Platform:** CP/M 2.2, Intel 8080
**Assembler:** Microsoft M80 / L80
**Version:** 1.05

---

## Overview

HEDIT is a full-screen hex editor for CP/M 2.2 written in Intel 8080 assembly language. It displays file contents in the standard hex editor format (address, hex bytes, ASCII) and can load and save both raw binary files and Intel HEX files.

HEDIT is distributed as five pre-built variants, one per supported terminal:

| Binary | Terminal | Notes |
|---|---|---|
| `HEDIT.COM` | VT100 / ANSI | Mono build — bold / dim / reverse only |
| `HEDIT-CL.COM` | VT100 / ANSI | Colour build — green addresses, cyan hex, yellow ASCII |
| `HEDIT-52.COM` | DEC VT52 (and clones) | Reverse-video via `ESC p` / `ESC q` on clones |
| `HEDIT-AD.COM` | Lear Siegler ADM-31 | Uses WordStar diamond for cursor (arrows collide) |
| `HEDIT-CR.COM` | Cromemco 3102 | Accepts both native `ESC A/B/C/D` and emulator CSI |

The VT100 builds auto-detect the terminal's real row count via DSR and expand the hex area to fill it (24 to 76 rows). The non-VT100 builds assume a fixed 24 rows.

### Features

- Dual editing modes: hex (0-9, A-F nibble input) and ASCII (printable character input)
- Insert and overwrite modes
- Raw binary and Intel HEX format support (auto-detected on load)
- Hex and ASCII pattern search with wrap-around
- Block mark, copy, delete, and paste operations
- Virtual buffer support for files larger than available RAM
- User-configurable key bindings via `HEDIT.KEY`
- WordStar-compatible control keys plus terminal-native arrow keys on VT100 / VT52 / Cromemco 3102

---

## Screen Layout

```
Row 1:          Info bar      — filename, size (hex), offset (hex), INS/OVR, HEX/ASC
Row 2:          Column header — Offset  00 01 02 ... 0F  ASCII
Rows 3..N-1:    Hex data area — N-4 rows of 16 bytes each
Row N-1:        Separator     — version string + '=' fill
Row N:          Status / prompts
```

On a 24-row terminal: N = 24, hex area spans rows 3-22 (20 rows / 320 bytes visible). On a 40-row terminal: N = 40, hex area spans rows 3-38 (36 rows / 576 bytes visible).

Each data row:
```
0000: 41 42 43 44 45 46 47 48  49 4A 4B 4C 4D 4E 4F 50  ABCDEFGHIJKLMNOP
```

---

## Key Bindings

### Navigation

| Key | Action |
|-----|--------|
| `^E` / Up arrow | Up 16 bytes (one row) |
| `^X` / Down arrow | Down 16 bytes (one row) |
| `^S` / Left arrow | Left 1 byte |
| `^D` / Right arrow | Right 1 byte |
| `^R` / PgUp | Up one page |
| `^C` / PgDn | Down one page |
| `^QS` / Home | Start of current row |
| `^QD` / End | End of current row |
| `^QR` | Top of file (offset 0) |
| `^QC` | End of file |

Page size depends on terminal height: 320 bytes on a 24-row terminal, more on taller ones.

### Editing

| Key | Action |
|-----|--------|
| `0`-`9`, `A`-`F` | Hex byte input (HEX mode, two keystrokes per byte) |
| Printable chars | ASCII byte input (ASCII mode) |
| `^I` / Tab | Toggle HEX / ASCII editing mode |
| `^V` / Insert | Toggle Insert / Overwrite mode |
| `^H` / Backspace | Delete byte left |
| `^G` / Delete | Delete byte right |
| `^Y` | Delete row (16 bytes) |

### Block Operations

| Key | Action |
|-----|--------|
| `^KB` / F3 | Toggle block mark (start / end / clear) |
| `^KC` / `^O` | Copy marked block to clipboard |
| `^KD` | Delete marked block |
| `^KP` | Paste clipboard at cursor |

### File and Search

| Key | Action |
|-----|--------|
| `^KS` / F2 | Save file |
| `^KX` / `^KQ` | Exit (with save prompt) |
| `^L` / F1 | Find next |
| ESC / F4 | Open menu |

### Terminal-specific arrow-key notes

On **ADM-31** and **Cromemco 3102**, the arrow keys transmit raw control characters (`^K` / `^J` / `^H` / `^L`) that collide with the WordStar block prefix, backspace, and find-next bindings. On those terminals, use the diamond keys (`^E` / `^X` / `^S` / `^D`, `^R` / `^C`) for cursor motion. **Cromemco 3102** additionally decodes the native `ESC A/B/C/D` arrow sequences and VT100-style `ESC [ A/B/C/D`, so an emulator sending either form works.

---

## ESC Menu

| # | Option |
|---|--------|
| 1 | Open File |
| 2 | Save File |
| 3 | Save As... |
| 4 | Find (hex/ASCII)... |
| 5 | Go To Offset... |
| 6 | Help / About |
| 7 | Base Offset... |
| 8 | Toggle Format (BIN/HEX) |
| 9 | Fill Block... |
| 0 | Exit |

---

## Intel HEX Format Support

HEDIT auto-detects Intel HEX format when the first byte of a file is `:` (3AH).

**Loading:** Parses standard Intel HEX records (type 00 = data, type 01 = EOF). Address gaps are filled with FFH. Checksum is validated.

**Saving:** When a file was loaded as Intel HEX, it is saved back in Intel HEX format with 16-byte data records and proper checksums. Files loaded as raw binary are saved as raw binary.

Intel HEX record format: `:LLAAAATT[DD...]CC`
- LL = byte count, AAAA = address, TT = type, DD = data, CC = checksum

---

## Building

### Host build (cpmulator, Python)

```
build-all.bat
```

Produces all five variants in one run. Requires `cpmulator.exe` on the PATH and Python 3 for `CPMFMT.PY` / `HEBUILD.PY`.

### CP/M-native build (SUBMIT)

Every variant has its own self-contained `.SUB` file. Each one rebuilds `HEPATCH.COM`, sets `COLOR` in `HECONFIG.INC`, clears `*.REL`, assembles every required module, links to `TEMP.COM`, then renames the result to the target name:

| Variant | SUBMIT command |
|---|---|
| VT100 mono | `SUBMIT HEDIT` |
| VT100 colour | `SUBMIT HEDIT-CL` |
| VT52 | `SUBMIT HEDIT-52` |
| ADM-31 | `SUBMIT HEDIT-AD` |
| Cromemco 3102 | `SUBMIT HEDIT-CR` |

Housekeeping:

```
SUBMIT CLEAN          REM remove *.REL and TEMP.COM
SUBMIT HEPATCH        REM rebuild just HEPATCH.COM
```

### Manual (build one variant by hand)

```
python CPMFMT.PY           # normalise line endings and EOF markers
python HEBUILD.PY 0        # set COLOR=0 (mono) or 1 (colour)
python CPMFMT.PY HECONFIG.INC
M80 =HEDIT
M80 =HEXSCR        (or =HEVT52 / =HEADM31 / =HEC3102 for non-VT100)
M80 =HEXKEY        (or =HEADM31K / =HEC3102K)
M80 =HEXGAP
M80 =HEXIO
M80 =HEXMENU       (or =HEXMNVT for non-VT100)
M80 =HEXSRCH
M80 =HEXBLK
M80 =HEXKBND
M80 =HEXVIRT
M80 =HEXHELP
L80 HEDIT,HEXSCR,HEXKEY,HEXGAP,HEXIO,HEXMENU,HEXSRCH,HEXBLK,HEXKBND,HEXVIRT,HEXHELP,HEDIT/N/E
```

Substitute screen driver / key module / menu module as shown in `build-all.bat` for the non-VT100 variants. M80 pulls in `HEDIT.INC` (and `HECONFIG.INC` for HEXSCR) via M80's native `INCLUDE` directive; `CPMFMT.PY` only normalises line endings and EOF markers.

**Note:** `HEXHELP` must be linked last — `BMDATEND EQU $` is at the end of its CSEG section and marks the bottom of the gap buffer.

---

## Module Structure

### Shared modules (all variants)

| File | Purpose |
|---|---|
| `HEDIT.MAC` | Entry point, main loop, action dispatch, runtime dimensions |
| `HEDIT.INC` | Shared equates (pulled in by M80 `INCLUDE`) |
| `HECONFIG.INC` | Compile-time config (`COLOR` EQU, patched by HEPATCH) |
| `HEXGAP.MAC` | Byte-oriented gap buffer engine |
| `HEXIO.MAC` | File load/save, Intel HEX format parser/writer |
| `HEXSRCH.MAC` | Hex and ASCII pattern search |
| `HEXBLK.MAC` | Block mark, copy, delete, paste |
| `HEXKBND.MAC` | Key binding loader (`HEDIT.KEY`) |
| `HEXVIRT.MAC` | Virtual buffer I/O for large files |
| `HEXHELP.MAC` | Help screen overlay, `BMDATEND` marker |

### Terminal-specific modules

| Role | VT100 | VT52 | ADM-31 | Cromemco 3102 |
|---|---|---|---|---|
| Screen driver | `HEXSCR.MAC` | `HEVT52.MAC` | `HEADM31.MAC` | `HEC3102.MAC` |
| Key input | `HEXKEY.MAC` | `HEXKEY.MAC` | `HEADM31K.MAC` | `HEC3102K.MAC` |
| ESC menu | `HEXMENU.MAC` | `HEXMNVT.MAC` | `HEXMNVT.MAC` | `HEXMNVT.MAC` |

Selection happens at link time — the linker picks which `.REL` files get bound into the final `.COM`. All four screen drivers export the same PUBLIC symbols (`SCRINIT`, `SCRDRAW`, `CURGOTO`, `ATTRON`, `ATROFF`, `DETSIZ`, etc.) so the rest of the program is terminal-agnostic.

### Build tools

| File | Purpose |
|---|---|
| `HEPATCH.MAC` | Standalone CP/M-native patcher for `COLOR` in `HECONFIG.INC` |
| `HEBUILD.PY` | Python equivalent of `HEPATCH` for host builds |
| `CPMFMT.PY` | Line-ending / EOF normaliser for `.MAC`, `.INC`, `.SUB` files |
| `build-all.bat` | Windows-side five-variant build via `cpmulator` |
| `*.SUB` | CP/M-side per-variant build scripts |

---

## Limitations

- Maximum displayable address: FFFFH (65535 bytes) without virtual buffer
- Virtual buffer mode supports larger files via disk-backed paging
- Single edit buffer (no split view)
- No undo
- Clipboard limited to 2048 bytes
- Search pattern limited to 64 bytes
- CP/M 8.3 filenames only
- Terminal auto-sizing (DETSIZ) only available on VT100 builds; other drivers are fixed at 24 rows
