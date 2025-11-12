          DO ]E_PRINTPAS
PRINTPAS1
          RJMP PRINTS
PASSTR    DW $0
PRINTS
          LDA PASSTR
          STA PTR
          LDA PASSTR+1
          STA PTR+1
          LDY #0
          LDA (PTR),Y
          TAX
          INY
:LOOP
          CPX #0
          BEQ :EXIT
          LDA (PTR),Y
          ORA #%10000000
          JSR COUT
          DEX
          INY
          RJMP :LOOP
:EXIT
          RTS
          FIN

          DO ]E_PRINT
PRINT1
          RJMP PRINTA
PRINTSTR  DW $0
PRINTA
          LDY #0
          LDA PRINTSTR
          STA PTR
          LDA PRINTSTR+1
          STA PTR+1
:LOOP     LDA (PTR),Y
          BEQ :EXIT
          JSR COUT
          INY
          RJMP :LOOP
:EXIT
          RTS
          FIN

          DO ]E_CENTER40
CENTER40
          STA :SAVA
          LDA #40
          SEC
          SBC :SAVA
          LSR
          STA CH
          RTS
:SAVA     HEX 00
          FIN
