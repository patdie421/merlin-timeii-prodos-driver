]E_ASCPRNT EQU 0

ASCPRNT   MAC
          LDA #<]1
          STA ASCPRNT1+3
          LDA #>]1
          STA ASCPRNT1+4
          JSR ASCPRNT1
          <<<
