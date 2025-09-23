E_PRINTPAS1 EQU 1
E_PRINT1 EQU 1


         DO E_PRINTPAS1
PRINTPAS1
*
* print pascal string
* in: PASSTR = address of string (L/H) to print
* modified : A,Y
*
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


          DO E_PRINT1
PRINT1
*
* print zero ended string
* in: ZEROSTR = address of string (L/H) to print
* modified : A,Y
*
          RJMP PRINTA
ZEROSTR  DW $0
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
