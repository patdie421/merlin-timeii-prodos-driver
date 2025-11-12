
RJMP      MAC
          CLC
          BCC ]1
          <<<

MOVEW     MAC            ; copy source word to dest word
          LDA ]1
          STA ]2
          LDA ]1+1
          LDA ]2+1
          <<<

PSHADDR   MAC            ; push word to stack
          LDA #<]1
          PHA
          LDA #>]1
          PHA
          <<<

PSHWVAD   MAC            ; PuSHWordValueAddress
          LDA ]1
          PHA
          LDA ]1+1
          PHA
          <<<

POPWVAD   MAC            ;POPWordValueAddress
          PLA
          STA ]1+1
          PLA
          STA ]1
          <<<
