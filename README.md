# HEDIT — Hex Editor for CP/M 2.2

**Platform:** CP/M 2.2, Intel 8080
**Assembler:** Microsoft M80 / L80
**Terminal:** VT100 / ANSI
**Version:** 1.04

---

## Overview

HEDIT is a full-screen hex editor for CP/M 2.2 written in Intel 8080 assembly language. It displays file contents in standard hex editor format with address, hex bytes, and ASCII representation. It can load and save both raw binary files and Intel HEX format files.

### Features

- Full-screen hex display: 20 rows x 16 bytes (320 bytes visible)
- Dual editing modes: hex (0-9, A-F nibble input) and ASCII (printable character input)
- Insert and overwrite modes
- Raw binary and Intel HEX format support (auto-detected on load)
- Hex and ASCII pattern search with wrap-around
- Block mark, copy, delete, and paste operations
- Virtual buffer support for files larger than available RAM
- User-configurable key bindings via HEDIT.KEY
- WordStar-compatible control keys with VT100/ANSI arrow key support

---

## Screen Layout

```
Row  1: Info bar — filename, size (hex), offset (hex), INS/OVR, HEX/ASC
Row  2: Column headers — Offset  00 01 02 ... 0F  ASCII
Row  3-22: Hex display — 20 rows of 16 bytes each
Row 23: Separator (version string + '=' fill)
Row 24: Status / prompts
```

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
| `^R` / PgUp | Up 320 bytes (one page) |
| `^C` / PgDn | Down 320 bytes (one page) |
| `^QS` / Home | Start of current row |
| `^QD` / End | End of current row |
| `^QR` | Top of file (offset 0) |
| `^QC` | End of file |

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

### On CP/M (via SUBMIT)

```
SUBMIT BUILD
```

### On host system (via cpmulator)

```
build-all.bat
```

This builds two variants:
- **HEDIT.COM** — Mono (bold/dim/reverse only, no ANSI color)
- **HEDIT-CL.COM** — Color (green addresses, cyan hex, yellow ASCII)

### Manual build

```
python CPMFMT.PY *.MAC          # preprocess
M80 =HEDIT                      # assemble each module
M80 =HEXSCR
M80 =HEXKEY
M80 =HEXGAP
M80 =HEXIO
M80 =HEXMENU
M80 =HEXSRCH
M80 =HEXBLK
M80 =HEXKBND
M80 =HEXVIRT
M80 =HEXHELP
L80 HEDIT,HEXSCR,HEXKEY,HEXGAP,HEXIO,HEXMENU,HEXSRCH,HEXBLK,HEXKBND,HEXVIRT,HEXHELP,HEDIT/N/E
```

**Note:** HEXHELP must be linked last — `BMDATEND EQU $` is at the end of its CSEG section.

---

## Module Structure

| Source File | Purpose |
|-------------|---------|
| `HEDIT.MAC` | Entry point, main loop, hex/ASCII input, action dispatch |
| `HEDIT.INC` | Shared equates (inlined by CPMFMT.PY) |
| `HEXSCR.MAC` | VT100 output, hex screen rendering, info bar, cursor positioning |
| `HEXKEY.MAC` | Key input, VT100 escape sequence decoder |
| `HEXGAP.MAC` | Byte-oriented gap buffer engine |
| `HEXIO.MAC` | File load/save, Intel HEX format parser/writer |
| `HEXMENU.MAC` | ESC menu overlay |
| `HEXSRCH.MAC` | Hex and ASCII pattern search |
| `HEXBLK.MAC` | Block mark, copy, delete, paste |
| `HEXKBND.MAC` | Key binding loader (HEDIT.KEY) |
| `HEXVIRT.MAC` | Virtual buffer I/O for large files |
| `HEXHELP.MAC` | Help screen overlay, BMDATEND marker |

---

## Limitations

- Maximum displayable address: FFFFH (65535 bytes) without virtual buffer
- Virtual buffer mode supports larger files via disk-backed paging
- Single edit buffer (no split view)
- No undo
- Clipboard limited to 2048 bytes
- Search pattern limited to 64 bytes
- CP/M 8.3 filenames only
