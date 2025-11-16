* page zero tempory data
PTR       EQU $EB        ; $EB and EC
STRPTR    EQU $ED        ; $ED and EE
AVAL      EQU $CE        ; 2 tempory memory bytes
BVAL      EQU $CF

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
