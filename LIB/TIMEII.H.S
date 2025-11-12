]E_SETIIDATE  EQU 0
]E_GETIIDATE  EQU 0
]E_ISIIDATE  EQU 0
]E_PRNIIDATE  EQU 0
]E_FINDSLOT  EQU 0
]E_GETIILEAP  EQU 0
]E_SETIILEAP  EQU 0
]E_TGLIILEAP  EQU 0
]E_FORCE24II  EQU 0

* TimeII read register address
SECUNI    EQU 32         ; 20 0
SECTEN    EQU 33         ; 21 1
MINUNI    EQU 34         ; 22 2
MINTEN    EQU 35         ; 23 3
HOUUNI    EQU 36         ; 24 4
HOUTEN    EQU 37         ; 25 5
DAYWEE    EQU 38         ; 26 6
DATUNI    EQU 39         ; 27 7
DATTEN    EQU 40         ; 28 8
MONUNI    EQU 41         ; 29 9
MONTEN    EQU 42         ; 2A 10 A
YEAUNI    EQU 43         ; 2B 11 B
YEATEN    EQU 44         ; 12 12 C

* TimeII address
BASE_A    EQU $C082
BASE_B    EQU $C081

_IISEC    EQU 0
_IIMIN    EQU 1
_IIHOU    EQU 2
_IIDOW    EQU 3
_IIDAY    EQU 4
_IIMON    EQU 5
_IIYEA    EQU 6
_IILEA    EQU 7

INITII    MAC
          LDA ]1
          STA IISLOT
          <<<
