          DO ]E_ASCPRNT
ASCPRNT1  ENT
          JMP :ASCPRNT1
:STRING   HEX 00,00
:ASCPRNT1
          LDA :STRING
          STA :C1+1
          LDA :STRING+1
          STA :C1+2
          LDY #0
:C1       LDA $FFFF,Y
          BEQ :EXIT
          JSR COUT
          INY
          JMP :C1
:EXIT     RTS
          FIN
