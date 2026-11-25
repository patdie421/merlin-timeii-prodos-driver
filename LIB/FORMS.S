           DO      ]E_STATUSBAR
STATUSBAR  ENT
           LDA     #0
           STA     CH
           LDA     #23
           JSR     VTABZ
           ASCPRNT :BTTMLINE
           RTS
:BTTMLINE  ASC     " [ESC]CANCEL [ENTER]VALID [CTRL-C]EXIT",00
           FIN


           DO      ]E_BOX2
BOX2       ENT
           JMP     :BOX2
:X         HEX     00
:Y         HEX     00
:L         HEX     00
:H         HEX     00
:T         HEX     00,00  ; title string (ptr)
:BOX2
]E_BOX1    EQU     1
           LDA     :X
           STA     BOX1+3
           LDA     :Y
           STA     BOX1+4
           LDA     :L
           STA     BOX1+5
           LDA     :H
           STA     BOX1+6

           LDA     :T
           STA     :_T1+1
           STA     :_T2+1
           STA     :_T3+1
           LDA     :T+1
           STA     :_T1+2
           STA     :_T2+2
           STA     :_T3+2

           JSR     BOX1

           LDA     :Y
           JSR     VTABZ
           JSR     SETINV
           LDA     :L
           SEC
:_T1       SBC     $FFFF
           LSR
           CLC
           ADC     :X
           STA     CH
           LDY     #1
:_T2       LDX     $FFFF
:LOOPTTL
:_T3       LDA     $FFFF,Y
           JSR     COUT
           INY
           DEX
           BNE     :LOOPTTL
           JSR     SETNORM

* set window
           LDX     :X
           INX
           STX     WNDLFT

           LDX     :Y
           INX
           INX
           STX     WNDTOP

           LDX     :L
           DEX
           DEX
           STX     WNDWDTH

           LDX     :H
           DEX
           DEX
           DEX
           TXA
           CLC
           ADC     WNDTOP
           STA     WNDBTM
* clear window
           JSR     HOME
           RTS
           FIN


           DO      ]E_BOX1
BOX1       ENT
           JMP     :BOX
:X         HEX     00
:Y         HEX     00
:L         HEX     00
:H         HEX     00
:BOX
           LDX     :X
           DEC     :H
           DEC     :H
* TOP LINE OF BOX
           LDA     #"."
           STA     :C1+1
           STA     :C3+1
           LDA     #"_"
           STA     :C2+1
           JSR     :LINE
* MIDDLE LINES OF BOX
           LDA     #$FC
           STA     :C1+1
           STA     :C3+1
           LDA     #" "
           STA     :C2+1
:MIDLOOP   BEQ     :BOTTOM
           INC     :Y
           JSR     :LINE
           DEC     :H
           JMP     :MIDLOOP
* BOTTOM LINE OF BOX
:BOTTOM
           INC     :Y
           LDA     #"!"
           STA     :C1+1
           STA     :C3+1
           LDA     #"_"
           STA     :C2+1
           JSR     :LINE
           RTS
:LINE
           STX     CH
           LDA     :Y
           JSR     VTABZ
           LDY     :L
           DEY
           DEY
:C1        LDA     #"."
           JSR     COUT
:C2        LDA     #"_"
:LOOP
           JSR     COUT
           DEY
           BNE     :LOOP
:C3        LDA     #"."
           JSR     COUT
           RTS
           FIN


           DO      ]E_BOX2B
BOXZP      EQU     $EB             ; 2 bytes, zero page (title ptr)

BOX2I      ENT
           PLA                     ; return address - 1
           STA     BOXZP
           PLA
           STA     BOXZP+1
           LDY     #6              ; 6 bytes: X,Y,L,H,T(2)
:CP        LDA     (BOXZP),Y       ; params at +1..+6
           STA     BOX2+2,Y        ; -> BOX2+3..BOX2+8 (:X..:T+1)
           DEY
           BNE     :CP
           LDA     BOXZP           ; new return address = old + 6
           CLC                     ; (RTS will land after the data)
           ADC     #6
           TAX
           LDA     BOXZP+1
           ADC     #0
           PHA                     ; hi first
           TXA
           PHA                     ; then lo
           JMP     BOX2            ; BOX2 ends with RTS to the adjusted address


*
* BOX2 : box with centered title and text window
* in: X,Y,L,H : box position and size (H >= 4, L >= 3)
*     T : ptr to title string (length byte first,
*         length >= 1 and <= L)
* call RWINDOW before (CH is relative to WNDLFT)
* uses zero page BOXZP (2 bytes), not reentrant
* A,X,Y modified
*
BOX2       ENT
           JMP     :BOX2
:X         HEX     00
:Y         HEX     00
:L         HEX     00
:H         HEX     00              ; :X,:Y,:L,:H same order as BOX1
:T         HEX     00,00           ; title string (ptr)
:BOX2
]E_BOX1B   EQU     1
           LDA     :T              ; title ptr -> zero page
           STA     BOXZP
           LDA     :T+1
           STA     BOXZP+1

           LDX     #3              ; copy :X,:Y,:L,:H (4 bytes)
:CP        LDA     :X,X            ; relies on :X,:Y,:L,:H contiguous
           STA     BOX1+3,X        ; BOX1 params start at +3, same order
           DEX
           BPL     :CP

           JSR     BOX1

           LDA     :Y              ; title on the top border
           JSR     VTABZ
           JSR     SETINV
           LDY     #0
           LDA     :L
           SEC
           SBC     (BOXZP),Y       ; L - title length
           LSR
           CLC
           ADC     :X
           STA     CH
           LDA     (BOXZP),Y       ; title length
           TAX
           INY                     ; Y = 1 (first char)
:LOOPTTL
           LDA     (BOXZP),Y
           JSR     COUT
           INY
           DEX
           BNE     :LOOPTTL
           JSR     SETNORM

* set window
           LDX     :X
           INX
           STX     WNDLFT

           LDX     :Y
           INX
           INX
           STX     WNDTOP

           LDX     :L
           DEX
           DEX
           STX     WNDWDTH

           LDX     :H
           DEX
           DEX
           DEX
           TXA
           CLC
           ADC     WNDTOP
           STA     WNDBTM
* clear window
           JMP     HOME            ; tail call: HOME's RTS returns to our caller
           FIN


           DO      ]E_BOX1B
BOX1       ENT
           JMP     :BOX
:X         HEX     00
:Y         HEX     00
:L         HEX     00
:H         HEX     00
:BOX
           DEC     :H
           DEC     :H              ; H-2 middle lines (H >= 3)

* print top line
           LDX     #0              ; X = table offset : top line
           JSR     :LINE

* print middle lines
           LDX     #3              ; middle line
:MIDLOOP
           INC     :Y
           JSR     :LINE           ; X kept by :LINE (see notes)
           DEC     :H
           BNE     :MIDLOOP
           INC     :Y

* print bottom line
           LDX     #6              ; bottom line, falls into :LINE
:LINE
           LDA     :X
           STA     CH
           LDA     :Y
           JSR     VTABZ
           LDA     :TBL,X          ; left char
           JSR     COUT
           LDY     :L
           DEY
           DEY
:LOOP
           LDA     :TBL+1,X        ; center char
           JSR     COUT
           DEY
           BNE     :LOOP
           LDA     :TBL+2,X        ; right char
* COUT does the RTS
           JMP     COUT            ; COUT ends with RTS

:TBL       HEX     AE,DF,AE        ; top    . _ .
           HEX     FC,A0,FC        ; middle | space |
           HEX     A1,DF,A1        ; bottom ! _ !
           FIN




