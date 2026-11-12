* page zero tempory data
PTR        EQU     $EB             ; $EB and EC
STRPTR     EQU     $ED             ; $ED and EE
AVAL       EQU     $CE             ; 2 tempory memory bytes
BVAL       EQU     $CF

* index of date values in DATE structure (define in MAIN.S)
_SEC       EQU     6               ; seconds
_MIN       EQU     5               ; minutes
_HOU       EQU     4               ; hours
_DAY       EQU     3               ; days of month
_MON       EQU     2               ; months
_YEA       EQU     1               ; years
_CEN       EQU     0               ; centuries
_DOW       EQU     7               ; days of week
_LEA       EQU     8               ; leap flags

; DSLOTPOS   EQU     $9            ; position of slot value in driver file
