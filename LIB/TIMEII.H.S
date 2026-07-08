]E_SETIIDATEEQU    0
]E_GETIIDATEEQU    0
]E_ISIIDATEEQU    0
]E_PRNIIDATEEQU    0
]E_PRNIIDATE1EQU    0
]E_GETIILEAPEQU    0
]E_CLRIILEAPEQU    0
]E_SETIILEAPEQU    0
]E_TGLIILEAPEQU    0
]E_PUTIILEAPEQU    0
]E_FORCE24IIEQU    0
]E_IISECADJEQU    0

* TimeII read register address
SECUNI   EQU    32             ; 20 0
SECTEN   EQU    33             ; 21 1
MINUNI   EQU    34             ; 22 2
MINTEN   EQU    35             ; 23 3
HOUUNI   EQU    36             ; 24 4
HOUTEN   EQU    37             ; 25 5
DAYWEE   EQU    38             ; 26 6
DATUNI   EQU    39             ; 27 7
DATTEN   EQU    40             ; 28 8
MONUNI   EQU    41             ; 29 9
MONTEN   EQU    42             ; 2A 10 A
YEAUNI   EQU    43             ; 2B 11 B
YEATEN   EQU    44             ; 12 12 C

* TimeII address
BASE_A   EQU    $C082
BASE_B   EQU    $C081

_IISEC   EQU    0
_IIMIN   EQU    1
_IIHOU   EQU    2
_IIDOW   EQU    3
_IIDAY   EQU    4
_IIMON   EQU    5
_IIYEA   EQU    6
_IILEA   EQU    7

INITII   MAC
         LDA    ]1
         STA    IISLOT
         <<<

INITII2  MAC
         LDA    ]1
         STA    IISLOT
         LDA    #<]2
         STA    DATIDATE
         LDA    #>]2
         STA    DATIDATE+1
         <<<
