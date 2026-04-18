;============================================================
; FILE:    HEDIT.INC
; PROJECT: HEDIT - Hex Editor for CP/M 2.2
; VERSION: 1.04
; DATE:    1984-01-01
; AUTHOR:  Claude Code and RetroTechReboot
;------------------------------------------------------------
; DESCRIPTION:
;   Shared equates for all HEDIT modules.
;   INCLUDE this as the first statement of every .MAC file.
;------------------------------------------------------------

;--- CP/M system addresses ----------------------------
BDOS    EQU     0005H       ; BDOS call entry
WBOOT   EQU     0000H       ; warm boot / exit
DFTFCB  EQU     005CH       ; default FCB (arg 1)
CMDTAIL EQU     0080H       ; command tail buffer

;--- BDOS function numbers ----------------------------
BF_CONIN  EQU   1           ; console input (wait)
BF_CONOUT EQU   2           ; console output: E=char
BF_RAWIO  EQU   6           ; direct I/O: E=FFH->in
BF_PRTSTR EQU   9           ; print $-string: DE=addr
BF_RDLINE EQU   10          ; buffered line input
BF_CONST  EQU   11          ; console status
BF_FOPEN  EQU   15          ; open file: DE=FCB
BF_FCLOSE EQU   16          ; close file: DE=FCB
BF_FDEL   EQU   19          ; delete: DE=FCB
BF_FREAD  EQU   20          ; seq read: DE=FCB
BF_FWRITE EQU   21          ; seq write: DE=FCB
BF_FMAKE  EQU   22          ; create: DE=FCB
BF_SETDMA EQU   26          ; set DMA: DE=addr
BF_USRNUM EQU   32          ; get/set user: E=num
BF_CURDSK EQU   25          ; get current disk

;--- FCB field offsets --------------------------------
FCB_DR  EQU     0           ; drive (0=default, 1=A, etc.)
FCB_F1  EQU     1           ; filename (8 bytes)
FCB_T1  EQU     9           ; extension (3 bytes)
FCB_EX  EQU     12          ; extent number
FCB_RC  EQU     15          ; record count
FCB_CR  EQU     32          ; current record

;--- ASCII control codes ------------------------------
NUL     EQU     00H
BEL     EQU     07H         ; bell
BS      EQU     08H         ; backspace
TAB     EQU     09H         ; horizontal tab
LF      EQU     0AH         ; line feed
CR      EQU     0DH         ; carriage return
ESC     EQU     1BH         ; escape
DEL     EQU     7FH         ; delete character
CPMEOF  EQU     1AH         ; CP/M EOF marker (Ctrl-Z)
CTRLK   EQU     0BH         ; Ctrl-K (prefix key)
CTRLQ   EQU     11H         ; Ctrl-Q (prefix key)

;--- Screen layout ------------------------------------
SCRROWS EQU     24          ; terminal row count
SCRCOLS EQU     80          ; terminal column count
EDITROW EQU     20          ; hex data rows (rows 3-22)
EDITFR  EQU     3           ; first edit row (1-based)
INFOROW EQU     1           ; info bar row
HDRROW  EQU     2           ; column header row
SEPRROW EQU     23          ; separator (===) row
STATROW EQU     24          ; status/message row

;--- Hex display layout -------------------------------
BYTESROW EQU    16          ; bytes per display row
BYTESPG EQU     320         ; bytes per page (EDITROW*BYTESROW)
HEXFCOL EQU     7           ; first hex column (1-based)
ASCFCOL EQU     58          ; first ASCII column (1-based)
GRPSEP  EQU     31          ; column of group separator space
ADDRWID EQU     6           ; width of "XXXX: " address field

;--- Hex input modes ----------------------------------
MODE_HEX EQU   0           ; editing in hex field
MODE_ASC EQU   1           ; editing in ASCII field
MODE_OVR EQU   0           ; overwrite mode
MODE_INS EQU   1           ; insert mode

;--- SGR attribute byte values ------------------------
ATTR_NRM EQU    00H         ; normal
ATTR_BLD EQU    01H         ; bold
ATTR_DIM EQU    02H         ; dim
ATTR_REV EQU    07H         ; reverse video
ATTR_CYN EQU    36H         ; cyan foreground
ATTR_GRN EQU    32H         ; green foreground
ATTR_YEL EQU    33H         ; yellow foreground
ATTR_MAG EQU    35H         ; magenta foreground
ATTR_RED EQU    31H         ; red foreground
ATTR_BLU EQU    34H         ; blue foreground

;--- Buffer descriptor field offsets ------------------
BD_BSTAR EQU    0           ; 2: buffer base address
BD_BSIZE EQU    2           ; 2: capacity in bytes
BD_GAPBG EQU    4           ; 2: gap start offset
BD_GAPEN EQU    6           ; 2: gap end offset
BD_TXEND EQU    8           ; 2: logical data length
BD_TOPOFF EQU   10          ; 2: top visible byte offset
BD_CSOFF EQU    12          ; 2: cursor byte offset
BD_MRKBG EQU    14          ; 2: block mark start (FFFF=unset)
BD_MRKEN EQU    16          ; 2: block mark end (FFFF=unset)
BD_MODIF EQU    18          ; 1: modified flag
BD_FILEFMT EQU  19          ; 1: file format (0=bin, 1=ihex)
BD_FNAME EQU    20          ; 12: drive + filename + ext
BD_BADDR EQU    32          ; 2: base address (Intel HEX origin)
BD_SIZE  EQU    34          ; total descriptor size

;--- File format codes --------------------------------
FMT_BIN EQU     0           ; raw binary
FMT_IHEX EQU    1           ; Intel HEX

;--- Key types (from GETKEY) --------------------------
KT_NONE EQU     0           ; no key
KT_ACT  EQU     1           ; action code
KT_CHAR EQU     2           ; printable character

;--- Action codes -------------------------------------
ACT_NONE  EQU   0
ACT_CURUP EQU   1           ; cursor up (16 bytes)
ACT_CURDN EQU   2           ; cursor down (16 bytes)
ACT_CURLT EQU   3           ; cursor left (1 byte)
ACT_CURRT EQU   4           ; cursor right (1 byte)
ACT_PGUP  EQU   5           ; page up (320 bytes)
ACT_PGDN  EQU   6           ; page down (320 bytes)
ACT_HOME  EQU   7           ; start of row
ACT_END   EQU   8           ; end of row
ACT_FTOP  EQU   9           ; top of file
ACT_FEND  EQU   10          ; end of file
ACT_DELLF EQU   11          ; delete left (backspace)
ACT_DELRT EQU   12          ; delete right
ACT_TOGIN EQU   13          ; toggle ins/ovr
ACT_TOGMD EQU   14          ; toggle hex/ascii mode
ACT_FNDNX EQU   15          ; find next
ACT_FSAVE EQU   16          ; save file
ACT_FEXIT EQU   17          ; exit
ACT_BLKMK EQU   18          ; block mark
ACT_BLKCP EQU   19          ; block copy
ACT_BLKDL EQU   20          ; block delete
ACT_BLKPS EQU   21          ; block paste
ACT_MENU  EQU   22          ; open ESC menu
ACT_DELRW EQU   23          ; delete row (16 bytes)
ACT_ENTER EQU   24          ; enter key (used by menu)
ACT_MAX   EQU   24          ; highest action code

;--- Miscellaneous ------------------------------------
MINMEM  EQU     9*1024      ; minimum TPA (9 KB)
CLIPMAX EQU     2048        ; clipboard buffer size
SRCHMAX EQU     64          ; max search pattern length
RECSIZ  EQU     128         ; CP/M record size
MAXADDR EQU     0FFFFH      ; max displayable address
