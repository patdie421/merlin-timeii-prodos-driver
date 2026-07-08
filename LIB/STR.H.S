]E_STRPRINTEQU    0
]E_STRCMP1EQU    0
]E_STRCMPE1EQU    0
]E_STREWITH1EQU    0
]E_STRSWITH1EQU    0
]E_STRCPY1EQU    0

STRCENTERMAC
         LDA    #]2
         SEC
         SBC    ]1
         LSR
         STA    $24
         <<<


STRPRNT  MAC
         LDA    #<]1
         STA    STRPRINT+3
         LDA    #>]1
         STA    STRPRINT+4
         JSR    STRPRINT
         <<<


STRPRNTL MAC
         STRPRNT ]1
         JSR    CROUT
         <<<


STRPRNTLLMAC
         STRPRNT ]1
         JSR    CROUT
         JSR    CROUT
         <<<


STRSWITH MAC
         LDA    #<]1
         STA    STRSWITH1+3
         LDA    #>]1
         STA    STRSWITH1+4
         LDA    #<]2
         STA    STRSWITH1+5
         LDA    #>]2
         STA    STRSWITH1+6
         JSR    STRSWITH1
         <<<


STREWITH MAC
         LDA    #<]1
         STA    STREWITH1+3
         LDA    #>]1
         STA    STREWITH1+4
         LDA    #<]2
         STA    STREWITH1+5
         LDA    #>]2
         STA    STREWITH1+6
         JSR    STREWITH1
         <<<


STRCAT   MAC
         LDA    #<]1
         STA    STRCAT1+3
         LDA    #>]1
         STA    STRCAT1+4
         LDA    #<]2
         STA    STRCAT1+5
         LDA    #>]2
         STA    STRCAT1+6
         JSR    STRCAT1
         <<<


STRADD   MAC
         LDA    #<]1
         STA    STRCAT1+5
         LDA    #>]1
         STA    STRCAT1+6
         JSR    STRCAT1
         <<<


STRCPY   MAC
         LDA    #<]1
         STA    STRCPY1+3
         LDA    #>]1
         STA    STRCPY1+4
         LDA    #<]2
         STA    STRCPY1+5
         LDA    #>]2
         STA    STRCPY1+6
         LDA    ]3
         STA    STRCPY1+7
         JSR    STRCPY1
         <<<


STRCMP   MAC
         LDA    #<]1
         STA    STRCMP1+3
         LDA    #>]1
         STA    STRCMP1+4
         LDA    #<]2
         STA    STRCMP1+5
         LDA    #>]2
         STA    STRCMP1+6
         JSR    STRCMP1
         <<<


STRCMP_PPMAC
         LDA    ]1
         STA    STRCMP1+3
         LDA    ]1+1
         STA    STRCMP1+4
         LDA    ]2
         STA    STRCMP1+5
         LDA    ]2+1
         STA    STRCMP1+6
         JSR    STRCMP1
         <<<


STRCMP_PAMAC                   ; pointer and address
         LDA    ]1
         STA    STRCMP1+3
         LDA    ]1+1
         STA    STRCMP1+4
         LDA    #<]2
         STA    STRCMP1+5
         LDA    #>]2
         STA    STRCMP1+6
         JSR    STRCMP1
         <<<


STRCMP_APMAC                   ; pointer and address
         LDA    #<]1
         STA    STRCMP1+3
         LDA    #>]1
         STA    STRCMP1+4
         LDA    ]2
         STA    STRCMP1+5
         LDA    ]2+1
         STA    STRCMP1+6
         JSR    STRCMP1
         <<<
