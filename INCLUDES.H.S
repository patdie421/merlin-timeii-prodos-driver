          DO 0
* prodos entry points
* MLI EQU $BF00
GETBUFR   EQU $BEF5      ; Get buffer
FREEBUFR  EQU $BEF8      ; Free buffer

* prodos MLI commands
DESCMD    EQU $C1        ; Destroy file
CRECMD    EQU $C0        ; Create file
OPECMD    EQU $C8        ; Open file
CLOCMD    EQU $CC        ; Close file
REACMD    EQU $CA        ; Read file
WRICMD    EQU $CB        ; Write file
ONLCMD    EQU $C5
GPXCMD    EQU $C7

* prodos
SBM48     EQU $BF61      ; $48 to $4F
SBMMASK   EQU %11000000  ; 512B for buffer and data
SBMMASKI  EQU %00111111  ; SBMMASK XOR $FF for release
* DEVNUM EQU $BF30
          FIN

* page zero tempory data
PTR       EQU $EB        ; $EB and EC
STRPTR    EQU $ED        ; $ED and EE
AVAL      EQU $CE        ; 2 tempory memory bytes
BVAL      EQU $CF

          DO 0
* reset vector
VRESETC   EQU $3D3
VRESETH   EQU $3D0

* program constants
BUFFPAGE  EQU $40        ; opened files buffers fisrt page
                         ; we need 4x2 pages for files
                         ; descriptor
RDBUFF    EQU BUFFPAGE+8*$100 ; my read buffer : 1 page
MYDATA    EQU RDBUFF+$100 ; MYDATA on next page
SLOT      EQU MYDATA
SLOT2     EQU SLOT+1
MEMFLAG   EQU SLOT2+1
HPOSSAV   EQU MEMFLAG+1
VPOSSAV   EQU HPOSSAV+1
DATE      EQU VPOSSAV    ; 8 bytes
          FIN

_SEC      EQU 6
_MIN      EQU 5
_HOU      EQU 4
_DAY      EQU 3
_MON      EQU 2
_YEA      EQU 1
_CEN      EQU 0
_DOW      EQU 7
_LEA      EQU 8

DSLOTPOS  EQU $9         ; position of slot value in
                         ; driver file
