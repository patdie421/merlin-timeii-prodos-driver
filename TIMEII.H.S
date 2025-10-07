]E_SETIIDATE  EQU 0
]E_GETIIDATE  EQU 0
]E_ISIIDATE  EQU 0
]E_PRNIIDATE  EQU 0
]E_FINDSLOT  EQU 0
]E_GETIILEAP  EQU 0
]E_TGLIILEAP  EQU 0
]E_FORCE24II  EQU 0

* TimeII read register address
SECUNI    EQU 32         ; 0
SECTEN    EQU 33         ; 1
MINUNI    EQU 34         ; 2
MINTEN    EQU 35         ; 3
HOUUNI    EQU 36         ; 4
HOUTEN    EQU 37         ; 5
DAYWEE    EQU 38         ; 6
DATUNI    EQU 39         ; 7
DATTEN    EQU 40         ; 8
MONUNI    EQU 41         ; 9
MONTEN    EQU 42         ; 10 A
YEAUNI    EQU 43         ; 11 B
YEATEN    EQU 44         ; 12 C

* TimeII struct
_IISEC    EQU 0          ; secondes
_IIMIN    EQU 1          ; minutes
_IIHOU    EQU 2          ; hour
_IIDOW    EQU 3          ; day of week
_IIDAY    EQU 4          ; day
_IIMON    EQU 5          ; month
_IIYEA    EQU 6          ; year

* TimeII address
BASE_A    EQU $C082
BASE_B    EQU $C081

INITII    MAC
          LDA ]1
          STA IISLOT
          <<<
