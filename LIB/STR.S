          DO ]E_STRPRINT
STRPRINT  ENT
          JMP STRPRINT1
          HEX 00
          HEX 00
STRPRINT1 ENT
          TYA
          PHA
          LDY #0
          PHZPP $ED

          LDA STRPRINT+3
          STA $ED
          LDA STRPRINT+4
          STA $ED+1
          LDA ($ED),Y
          BEQ :EXIT
          TAX
          INY
:LOOP
          LDA ($ED),Y
          ORA #%10000000
          JSR COUT
          INY
          DEX
          BNE :LOOP
:EXIT
          PLZPP $ED
          PLA
          TAY
          RTS
          FIN


          DO ]E_STRCMP1
STRCMP1   ENT
          JMP :STRCMP1
:STR1     HEX 00,00
:STR2     HEX 00,00
:STRCMP1
          PHAXY
* modifying code to set str addresses
          LDA :STR1
          STA :_STR11+1
          STA :_STR12+1
          LDA :STR1+1
          STA :_STR11+2
          STA :_STR12+2
          LDA :STR2
          STA :_STR21+1
          LDA :STR2+1
          STA :_STR21+2
* self modified section
:_STR11   LDY $FFFF
:LOOP
:_STR12   LDA $FFFF,Y
:_STR21   CMP $FFFF,Y
* end self modified section
          BNE :NOTEQU
:NEXT     DEY
          BNE :LOOP
          CLC            ; equal
          JMP :EXIT
:NOTEQU
          SEC            ; not equal
:EXIT
          PLYXA

          RTS
          FIN


          DO ]E_STRSWITH1
STRSWITH1 ENT
          JMP :STRSWITH1
:STRING   HEX 00,00
:START    HEX 00,00
:STRSWITH1
          PHZPP $EB
          PHZPP $ED

          LDA :STRING
          STA $EB
          LDA :STRING+1
          STA $EC
          LDA :START
          STA $ED
          LDA :START+1
          STA $EE

          LDY #0
          LDA ($ED),Y
          TAX
          INY
:LOOP
          LDA ($ED),Y
          CMP ($EB),Y
          BEQ :NEXT
          SEC
          JMP :EXIT
:NEXT
          INY
          DEX
          BNE :LOOP
          CLC
:EXIT
          PLZPP $ED
          PLZPP $EB
          RTS
          FIN


          DO ]E_STREWITH1
STREWITH1 ENT
          JMP :STREWITH1
:CMPES1   HEX 00,00
:CMPES2   HEX 00,00
:STREWITH1
          PHZPP $EB
          PHZPP $ED

          LDA :CMPES1
          STA $EB
          LDA :CMPES1+1
          STA $EC
          LDA :CMPES2
          STA $ED
          LDA :CMPES2+1
          STA $EE
          LDY #0
          LDA ($EB),Y
          STA :LSTR1
          LDA ($ED),Y
          STA :LSTR2
          TAX
:LOOP
          LDY :LSTR1
          LDA ($EB),Y
          LDY :LSTR2
          CMP ($ED),Y
          BNE :NOTEQU
          DEX
          BEQ :EQU
          DEC :LSTR1
          DEC :LSTR2
          JMP :LOOP
:EQU
          CLC
          JMP :EXIT
:NOTEQU
          SEC
:EXIT
          PLZPP $ED
          PLZPP $EB
          RTS
:LSTR1    HEX 00
:LSTR2    HEX 00
          FIN


          DO ]E_STRCPY2
]E_STRCPY1 EQU 0
STRCPY1   ENT
          JMP :STRCPY1
:S1       HEX 00,00
:S2       HEX 00,00
:OPT      HEX 00
:STRCPY1
          PHZPP $EB
          PHZPP $ED

          LDA :S1
          STA $EB
          LDA :S1+1
          STA $EB+1

          LDA :S2
          STA $ED
          LDA :S2+1
          STA $ED+1
          LDY #0
:LOOP
:C11      LDA ($EB),Y
          CPY #0
          BNE :NEXT
          TAX
          INX
          JMP :C21
:NEXT
          PHA
          LDA :OPT
:O1
          CMP #1
          BNE :O2
          PLA
          ORA #%10000000
          JMP :C21
:O2
          CMP #2
          BNE :O3
          PLA
          AND #%01111111
          JMP :C21
:O3       PLA

:C21      STA ($ED),Y
          INY
          DEX
          BNE :LOOP

          PLZPP $ED
          PLZPP $EB

          RTS
          FIN


          DO ]E_STRCPY1
STRCPY1   ENT
          JMP :STRCPY1
:S1       HEX 00,00
:S2       HEX 00,00
:OPT      HEX 00
:STRCPY1
          LDA :S1
          STA :C11+1
          LDA :S1+1
          STA :C11+2
          LDA :S2
          STA :C21+1
          LDA :S2+1
          STA :C21+2
          LDY #0
:LOOP
:C11      LDA $FFFF,Y
          CPY #0
          BNE :NEXT
          TAX
          INX
          JMP :C21
:NEXT
          PHA
          LDA :OPT
:O1
          CMP #1
          BNE :O2
          PLA
          ORA #%10000000
          JMP :C21
:O2
          CMP #2
          BNE :O3
          PLA
          AND #%01111111
          JMP :C21
:O3       PLA

:C21      STA $FFFF,Y
          INY
          DEX
          BNE :LOOP
          RTS
          FIN


          DO ]E_STRCAT1
STRCAT1   ENT
          JMP :STRCAT
:DST      HEX 00,00
:SRC      HEX 00,00
:STRCAT
          PHZPP $EB
          PHZPP $ED

          LDA :DST
          STA $EB
          LDA :DST+1
          STA $EB+1

          LDA :SRC
          STA $ED
          LDA :SRC+1
          STA $ED+1

          LDY #$00
          LDA ($EB),Y
          CLC
          ADC #$01
          STA :PTRDST    ; pointer to the last+1 pos
          LDA #$01
          STA :PTRSRC    ; pointer to the firt char
          LDA ($ED),Y    ; nb char counter
          TAX
:LOOP
          LDY :PTRSRC    ; read src char
          LDA ($ED),Y
          LDY :PTRDST    ; write to dest
          STA ($EB),Y
          INC :PTRSRC    ; src pointer + 1
          INC :PTRDST    ; src pointer + 1
          DEX
          BNE :LOOP
          DEC :PTRDST
          LDA :PTRDST    ; update string
          LDY #$00
          STA ($EB),Y
:EXIT
          PLZPP $ED
          PLZPP $EB
          RTS
:PTRSRC   HEX 00
:PTRDST   HEX 00
          FIN
