PRBYTEXYA
          STA :TMP1
          STX :TMP2
          STY :TMP3
          TXA
          JSR PRBYTE
          LDA #"-"
          JSR COUT
          LDA :TMP3
          JSR PRBYTE
          LDA #":"
          JSR COUT
          LDA :TMP1
          JSR PRBYTE
          LDA #" "
          JSR COUT
          LDY :TMP3
          LDX :TMP2
          LDA :TMP1
          RTS
:TMP1     HEX 00
:TMP2     HEX 00
:TMP3     HEX 00
