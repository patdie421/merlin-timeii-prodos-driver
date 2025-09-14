RJMP      MAC            ; relative jmp
          CLC
          BCC ]1
          <<<

PUSHW     MAC
          LDA #<]1
          PHA
          LDA #>]1
          PHA
          <<<

PULLWTO   MAC
          PLA
          STA ]1+1
          PLA
          STA ]1
          <<<

PUSHWFR   MAC
          LDA ]1
          PHA
          LDA ]1+1
          PHA
          <<<
