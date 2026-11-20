****************************************************************
* PASCAL STRING LIBRARY v2 - MERLIN MACROS
*
* Macro wrappers for the v2 Pascal string routines.
* Automatically enables the required ]E_...2 assembly flags
* upon invocation so only used routines are compiled.
*
* Note: All macros clobber A, X, Y and ZP $06-$07, $EB-$EE.
****************************************************************


*---------------------------------------------------------------
* Conditional assembly flags
* (Initialized to 0 = excluded; set to 1 automatically by macros)
*---------------------------------------------------------------
]E_STRPRINT2  EQU  0
]E_STRCMP2    EQU  0
]E_STREWITH2  EQU  0
]E_STRSWITH2  EQU  0
]E_STRCPY2    EQU  0
]E_STRCAT2    EQU  0


*---------------------------------------------------------------
* STRCENTER : Center a Pascal string horizontally on screen
*
* Usage     : STRCENTER MYSTR;WIDTH
* In        : ]1 = address of Pascal string (reads length byte)
*             ]2 = screen width in columns (e.g., 40 or 80)
* Out       : Updates Apple II horizontal cursor position ($24)
* Clobbers  : A
*---------------------------------------------------------------
STRCENTER  MAC
           LDA     #]2             ; screen column width (40 or 80)
           SEC
           SBC     ]1              ; subtract string length (byte 0)
           LSR                     ; divide by 2
           STA     $24             ; set Apple II CH (Cursor Horizontal)
           <<<


*---------------------------------------------------------------
* STRPRNT : Print a Pascal string via Apple II ROM COUT
*
* Usage   : STRPRNT MYSTR
* In      : ]1 = address of Pascal string
* Out     : None (prints characters with high bit forced to 1)
*---------------------------------------------------------------
STRPRNT    MAC
]E_STRPRINT2 EQU   1
           JSR     STRPRINT2
           DA      ]1              ; inline string address
           <<<


*---------------------------------------------------------------
* STRPRNTL : Print a Pascal string followed by 1 Carriage Return
*
* Usage    : STRPRNTL MYSTR
* In       : ]1 = address of Pascal string
* Out      : None
*---------------------------------------------------------------
STRPRNTL   MAC
           STRPRNT ]1
           JSR     CROUT           ; output 1 CR ($FD8E)
           <<<


*---------------------------------------------------------------
* STRPRNTLL : Print a Pascal string followed by 2 Carriage Returns
*
* Usage     : STRPRNTLL MYSTR
* In        : ]1 = address of Pascal string
* Out       : None
*---------------------------------------------------------------
STRPRNTLL  MAC
           STRPRNT ]1
           JSR     CROUT           ; output 1st CR ($FD8E)
           JSR     CROUT           ; output 2nd CR ($FD8E)
           <<<


*---------------------------------------------------------------
* STRSWITH : Check if string STR1 starts with prefix SUBSTR
*
* Usage    : STRSWITH STR1;SUBSTR
* In       : ]1 = address of main Pascal string
*            ]2 = address of prefix Pascal string
* Out      : Carry = 0 (STR1 starts with SUBSTR)
*            Carry = 1 (false)
*---------------------------------------------------------------
STRSWITH   MAC
]E_STRSWITH2 EQU   1
           JSR     STRSWITH2
           DA      ]1,]2           ; inline addresses: STR1, SUBSTR
           <<<


*---------------------------------------------------------------
* STREWITH : Check if string STR1 ends with suffix SUBSTR
*
* Usage    : STREWITH STR1;SUBSTR
* In       : ]1 = address of main Pascal string
*            ]2 = address of suffix Pascal string
* Out      : Carry = 0 (STR1 ends with SUBSTR)
*            Carry = 1 (false)
*---------------------------------------------------------------
STREWITH   MAC
]E_STREWITH2 EQU   1
           JSR     STREWITH2
           DA      ]1,]2           ; inline addresses: STR1, SUBSTR
           <<<


*---------------------------------------------------------------
* STRCAT : Append source string SRC to destination string DST
*          (Preserves original ]1=SRC, ]2=DST macro argument order)
*
* Usage  : STRCAT SRC;DST
* In     : ]1 = address of source string
*          ]2 = address of destination string (modified in place)
* Out    : None (total combined length must be <= 255)
*---------------------------------------------------------------
STRCAT     MAC
]E_STRCAT2 EQU     1
           JSR     STRCAT2
           DA      ]2,]1           ; v2 routine expects DST, SRC
           <<<


*---------------------------------------------------------------
* STRADD : Append source string SRC to destination string DST
*          (Alias for STRCAT; v2 requires explicit DST parameter)
*
* Usage  : STRADD SRC;DST
* In     : ]1 = address of source string
*          ]2 = address of destination string (modified in place)
* Out    : None
*---------------------------------------------------------------
STRADD     MAC
]E_STRCAT2 EQU     1
           JSR     STRCAT2
           DA      ]2,]1           ; v2 routine expects DST, SRC
           <<<


*---------------------------------------------------------------
* STRCPY : Copy source string SRC to destination string DST
*          with optional bit-7 conversion
*          (Preserves original ]1=SRC, ]2=DST, ]3=OPT argument order)
*
* Usage  : STRCPY SRC;DST;OPT
* In     : ]1 = address of source string
*          ]2 = address of destination string
*          ]3 = conversion option (literal value WITHOUT '#'):
*               0 = raw copy (unchanged)
*               1 = Apple normal text (force bit 7 = 1)
*               2 = standard ASCII (force bit 7 = 0)
* Out    : None
*---------------------------------------------------------------
STRCPY     MAC
]E_STRCPY2 EQU     1
           JSR     STRCPY2
           DA      ]2,]1           ; v2 routine expects DST, SRC
           DFB     ]3              ; inline option byte
           <<<


*---------------------------------------------------------------
* STRCMP : Compare two Pascal strings at fixed addresses
*
* Usage  : STRCMP STR1;STR2
* In     : ]1 = address of 1st string
*          ]2 = address of 2nd string
* Out    : Carry = 0 (strings are equal)
*          Carry = 1 (strings differ)
*---------------------------------------------------------------
STRCMP     MAC
]E_STRCMP2 EQU     1
           JSR     STRCMP2
           DA      ]1,]2           ; inline addresses: STR1, STR2
           <<<


*---------------------------------------------------------------
* STRCMP_PP : Compare two strings referenced by Zero Page pointers
*
* Usage     : STRCMP_PP PTR1;PTR2
* In        : ]1 = Zero Page pointer to 1st string (2 bytes)
*             ]2 = Zero Page pointer to 2nd string (2 bytes)
* Out       : Carry = 0 (strings are equal)
*             Carry = 1 (strings differ)
*---------------------------------------------------------------
STRCMP_PP  MAC
]E_STRCMP2 EQU     1
           LDA     ]1              ; copy PTR1 into inline parameter block
           STA     :ADDR+1
           LDA     ]1+1
           STA     :ADDR+2
           LDA     ]2              ; copy PTR2 into inline parameter block
           STA     :ADDR+3
           LDA     ]2+1
           STA     :ADDR+4
           JSR     STRCMP2
:ADDR      DA      $0000,$0000     ; self-modified inline addresses
           <<<


*---------------------------------------------------------------
* STRCMP_PA : Compare string via ZP pointer (]1) and fixed addr (]2)
*
* Usage     : STRCMP_PA PTR1;STR2
* In        : ]1 = Zero Page pointer to 1st string (2 bytes)
*             ]2 = fixed address of 2nd string
* Out       : Carry = 0 (strings are equal)
*             Carry = 1 (strings differ)
*---------------------------------------------------------------
STRCMP_PA  MAC
]E_STRCMP2 EQU     1
           LDA     ]1              ; copy PTR1 into inline parameter block
           STA     :ADDR+1
           LDA     ]1+1
           STA     :ADDR+2
           JSR     STRCMP2
:ADDR      DA      $0000,]2        ; self-modified PTR1, fixed STR2
           <<<


*---------------------------------------------------------------
* STRCMP_AP : Compare string at fixed addr (]1) and ZP pointer (]2)
*
* Usage     : STRCMP_AP STR1;PTR2
* In        : ]1 = fixed address of 1st string
*             ]2 = Zero Page pointer to 2nd string (2 bytes)
* Out       : Carry = 0 (strings are equal)
*             Carry = 1 (strings differ)
*---------------------------------------------------------------
STRCMP_AP  MAC
]E_STRCMP2 EQU     1
           LDA     ]2              ; copy PTR2 into inline parameter block
           STA     :ADDR+3
           LDA     ]2+1
           STA     :ADDR+4
           JSR     STRCMP2
:ADDR      DA      ]1,$0000        ; fixed STR1, self-modified PTR2
           <<<
