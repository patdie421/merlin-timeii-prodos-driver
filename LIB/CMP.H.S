A_EQU     MAC
          CMP ]1
          BEQ ]2
          <<<


A_UGTR    MAC
          CMP ]1
          BEQ NOTGTR
          BCS ]2
NOTGTR
          <<<


A_ULOW    MAC
          CMP ]1
          BCC ]2
          <<<


A_UGRE    MAC            ; GReater or Equal
          CMP ]1
          BCS ]2
          <<<


A_ULWE    MAC            ; LoWer or Equal
          CMP ]1
          BEQ ]2
          BCC ]2
          <<<


A_UBTW    MAC
          CMP ]1
          BCC END
          CMP ]2
          BEQ ]3
          BCC ]3
END
          <<<

A_ISIN    MAC            ; a is in str
          LDY ]1
LOOP
          BEQ END
          CMP ]1,Y
          BEQ ]2
          DEY
          JMP LOOP
END
          <<<

A_ISINP   MAC            ; a is in str
          PHA
          LDY #0
          LDA (]1),Y
          TAY
          PLA
          CPY #0
LOOP
          BEQ END
          CMP (]1),Y
          BEQ ]2
          DEY
          JMP LOOP
END
          <<<
