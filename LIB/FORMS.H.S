]E_BOX1    EQU     0
]E_BOX2    EQU     0
]E_BOX1B   EQU     0
]E_BOX2B   EQU     0
]E_STATUSBAR EQU   0


* offsets of BOX2 parameters (from entry point : JMP = 3 bytes)
BOX_X      EQU     3
BOX_Y      EQU     BOX_X+1
BOX_L      EQU     BOX_Y+1
BOX_H      EQU     BOX_L+1
BOX_T      EQU     BOX_H+1         ; title string ptr (16 bits)


*
* BOX : draw a box with centered title and text window
* ]1..]4 : X, Y, L, H with '#' (or a variable), H >= 4, L >= 3
* ]5 : title string address (length byte first, 1 <= length <= L)
* call RWINDOW before. Needs ]E_BOX2 = 1 and BOX2 EXT.
* A modified (33 bytes per call)
*
BOX        MAC
           LDA     ]1
           STA     BOX2+BOX_X
           LDA     ]2
           STA     BOX2+BOX_Y
           LDA     ]3
           STA     BOX2+BOX_L
           LDA     ]4
           STA     BOX2+BOX_H
           LDA     #<]5
           STA     BOX2+BOX_T
           LDA     #>]5
           STA     BOX2+BOX_T+1
           JSR     BOX2
           <<<


*
* BOXI : same as BOX, constant parameters stored inline (9 bytes per call)
* ]1..]4 : X, Y, L, H WITHOUT '#' (constants only)
* ]5 : title string address
* Needs ]E_BOX2 = 1 and BOX2I EXT. Called by JSR only (never JMP).
* Profitable from 2 calls (see size table).
*
BOXI       MAC
           JSR     BOX2I
           DB      ]1
           DB      ]2
           DB      ]3
           DB      ]4
           DW      ]5
           <<<
