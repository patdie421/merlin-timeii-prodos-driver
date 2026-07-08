]E_PRINTPASEQU    0
]E_PRINT EQU    0
]E_CENTER40EQU    0

PRINT    MAC
]E_PRINT EQU    1
         LDA    #<]1
         STA    PRINTSTR
         LDA    #>]1
         STA    PRINTSTR+1
         JSR    PRINT1
         <<<

PRINTPAS MAC
]E_PRINTPASEQU    1
         LDA    #<]1
         STA    PASSTR
         LDA    #>]1
         STA    PASSTR+1
         JSR    PRINTPAS1
         <<<

PRINTLN  MAC
         PRINT  ]1
         JSR    CROUT
         <<<
