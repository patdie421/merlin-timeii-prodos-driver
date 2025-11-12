          DO ]E_STATUSBAR
STATUSBAR ENT
          LDA #0
          STA CH
          LDA #23
          JSR VTABZ
          ASCPRNT :BTTMLINE
          RTS
:BTTMLINE ASC "  [ESC]CANCEL [ENTER]VALID [CTRL-C]EXIT",00
          FIN


          DO ]E_BOX2
BOX2      ENT
          JMP :BOX2
:X        HEX 00
:Y        HEX 00
:L        HEX 00
:H        HEX 00
:T        HEX 00,00
:BOX2
]E_BOX1   EQU 1
          LDA :X
          STA BOX1+3
          LDA :Y
          STA BOX1+4
          LDA :L
          STA BOX1+5
          LDA :H
          STA BOX1+6

          LDA :T
          STA :_T1+1
          STA :_T2+1
          STA :_T3+1
          LDA :T+1
          STA :_T1+2
          STA :_T2+2
          STA :_T3+2

          JSR BOX1

          LDA :Y
          JSR VTABZ
          JSR SETINV
          LDA :L
          SEC
:_T1      SBC $FFFF
          LSR
          CLC
          ADC :X
          STA CH
          LDY #1
:_T2      LDX $FFFF
:LOOPTTL
:_T3      LDA $FFFF,Y
          JSR COUT
          INY
          DEX
          BNE :LOOPTTL
          JSR SETNORM

* set window
          LDX :X
          INX
          STX WNDLFT

          LDX :Y
          INX
          INX
          STX WNDTOP

          LDX :L
          DEX
          DEX
          STX WNDWDTH

          LDX :H
          DEX
          DEX
          DEX
          TXA
          CLC
          ADC WNDTOP
          STA WNDBTM
* clear window
          JSR HOME
          RTS
          FIN


          DO ]E_BOX1
BOX1      ENT
          JMP :BOX
:X        HEX 00
:Y        HEX 00
:L        HEX 00
:H        HEX 00
:BOX
          LDX :X
          DEC :H
          DEC :H
* TOP LINE OF BOX
          LDA #"."
          STA :C1+1
          STA :C3+1
          LDA #"_"
          STA :C2+1
          JSR :LINE
* MIDDLE LINES OF BOX
          LDA #$FC
          STA :C1+1
          STA :C3+1
          LDA #" "
          STA :C2+1
:MIDLOOP  BEQ :BOTTOM
          INC :Y
          JSR :LINE
          DEC :H
          JMP :MIDLOOP
* BOTTOM LINE OF BOX
:BOTTOM
          INC :Y
          LDA #"!"
          STA :C1+1
          STA :C3+1
          LDA #"_"
          STA :C2+1
          JSR :LINE
          RTS
:LINE
          STX CH
          LDA :Y
          JSR VTABZ
          LDY :L
          DEY
          DEY
:C1       LDA #"."
          JSR COUT
:C2       LDA #"_"
:LOOP
          JSR COUT
          DEY
          BNE :LOOP
:C3       LDA #"."
          JSR COUT
          RTS
          FIN
