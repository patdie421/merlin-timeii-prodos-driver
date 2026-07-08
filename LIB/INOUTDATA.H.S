]E_GET1NUMEQU    0
]E_GETNUMSEQU    0
]E_GETPATHEQU    0
]E_PRINT0EQU    0
]E_PRINTDECEQU    0
]E_GETSTRW1EQU    0
]E_CROUT EQU    0
]E_MYGETKEYEQU    0

PRINT    MAC
         JSR    PRINT0
         DW     ]1
         <<<

PRINTLN  MAC
         PRINT  ]1
         JSR    CROUT
         <<<

GETSTR_S EQU    3
GETSTR_M EQU    5
GETSTR_I EQU    6
GETSTRW  MAC
         LDA    #<]1
         STA    GETSTRW1+GETSTR_S
         LDA    #>]1
         STA    GETSTRW1+GETSTR_S+1
         LDA    ]2
         STA    GETSTRW1+GETSTR_M
         LDA    #<]3
         STA    GETSTRW1+GETSTR_I
         LDA    #>]3
         STA    GETSTRW1+GETSTR_I+1
         JSR    GETSTRW1
         <<<

GKSETCB  MAC
         LDA    #<]1
         STA    GKCALLBACK+1
         LDA    #>]1
         STA    GKCALLBACK+2
         <<<

GKCLRCB  MAC
         GKSETCB GKNOPCB
         <<<
