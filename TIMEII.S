E_SETIIDATE EQU 0
E_GETIIDATE EQU 1
E_ISIIDATE EQU 1
E_PRNIIDATE EQU 0
E_FINDSLOT EQU 0

*
* TIMEII CARD
*
* BASIC program used this lines to set one reg
* R=<num reg>:REM 0 (sec unit) to 12 (year tens)
* POKE BASE_A, REG
* POKE BASE_B, VAL+16
* POKE BASE_A, REG+16
* POKE BASE_A, REG
WRREG     MAC
          LDA :REGS,Y
          AND #%00001111 ; reg num is < 16
          STA :REG
          STA BASE_A,X   ; select register
          LDA ]1
          ORA #%00010000 ; store data and raise flag
          STA BASE_B,X
          LDA :REG
          ORA #%00010000 ; +16 register and flag raised
          STA BASE_A,X
          LDA :REG       ; register and flag falled
          STA BASE_A,X
          <<<

          DO E_SETIIDATE
SETIIDATE
          LDA IISLOT     ; slot * 16 -> X
          ASL
          ASL
          ASL
          ASL
          TAX

          LDA #%00001000 ; 16 ($10)
          STA BASE_B,X   ; Hold line high

          LDY #0
:LOOP
          CPY #6
          BEQ :EXIT

          LDA DATE,Y
          STA :VAL
          JSR :SETII2REG
          INY
          RJMP :LOOP
:EXIT
* finaly write Day of Week
          LDA #DAYWEE
          STA :REG
          LDA DATE+_DOW
          STA :UNI
          WRREG :UNI
* release line
          LDA #%00000000
          STA BASE_B,X   ; Hold line low
          RTS

:SETII2REG               ; local procedure for updating 2
                         ; registers from 1 data from
                         ; GETDATI DATE table
          STY :SAVY
          STX :SAVX
          JSR HEXTODIGI
          STY :TEN
          STX :UNI
          LDX :SAVX
          LDA :SAVY
          ASL            ; y=y*2
          TAY
* write Units
          WRREG :UNI
          INY
* write Tens, but ...
* we have to update some tens before writing data
          CPY #5         ; hour tens => 24H format flag
          BNE :IINEXT
          LDA :VAL
          ORA #%00001000 ; set 24H flag
          STA :VAL
:IINEXT   CPY #7         ; date tens => leap flag
          BNE :WRTEN
          LDA :VAL
          ORA DATE+_LEA  ; set leap flag (cf GETDATI)
          STA :VAL
:WRTEN    WRREG :TEN

          LDX :SAVX
          LDY :SAVY
          RTS
:REGS
* TIMEII regs to update : must be in the same order than
* DATE table from GETDATI and match 1 for 2
          DFB YEAUNI,YEATEN,MONUNI,MONTEN,DATUNI,DATTEN
          DFB HOUUNI,HOUTEN,MINUNI,MINTEN,SECUNI,SECTEN
:REG      HEX 00
:VAL      HEX 00
:UNI      HEX 00
:TEN      HEX 00
:SAVX     HEX 00
:SAVY     HEX 00
          FIN


          DO E_GETIIDATE
GETIIDATE
          LDA IISLOT     ; slot * 16 -> X
GETIIDATE1
          ASL
          ASL
          ASL
          ASL
          TAX

          LDA #0         ; #read counter
          STA :COUNTER

* hold line high
          LDA #$10
          STA BASE_B,X

* Read all timeII card registers
          LDY #SECUNI    ; first  register (second unit)
:LOOP
          TYA            ; start reading units
          STA BASE_A,X
          LDA BASE_A,X
          STA :AVAL
* is this register DAY OF WEEK (ie regiter #38) ?
          CPY #DAYWEE
          BNE :NEXT1
          LDA #0         ; this register has no tens
                         ; replace by a 0
          STA :BVAL      ; in BVAL
          BEQ :NEXT3     ; kind of "relative JMP"
:NEXT1
          INY            ; start reading tens
          TYA
          STA BASE_A,X
          LDA BASE_A,X
          STA :BVAL
* check register having flags
          CPY #HOUTEN
          BEQ :NEXT2
          CPY #DATTEN
          BNE :NEXT3
:NEXT2                   ; remove HOUTEN and DATTEN flags
          LDA :BVAL
          AND #%0011
          STA :BVAL
:NEXT3
* Combine units and tens in 1 byte
* S =  BVAL x 10 + AVAL = BVAL x 2x2x2 + BVAL + BVAL + AVAL
          LDA :BVAL
          ASL            ; :BVAL x 2
          ASL            ; :BVAL x 2
          ASL            ; :BVAL x 2
          CLC
          ADC :BVAL      ; + :BVAL
          ADC :BVAL      ; + :BVAL
          ADC :AVAL      ; + :AVAL

**** store in buffer
          STA :AVAL
          STY :BVAL
          LDY :COUNTER
          STA TIMEII,Y
          INC :COUNTER
          LDY :BVAL

* an other register to read ?
          INY
          CPY #YEATEN
          BMI :LOOP      ; next unit register

          RTS
:COUNTER  DFB $0
:AVAL     HEX 00
:BVAL     HEX 00
          FIN


          DO E_ISIIDATE
ISIIDATE                 ; check if data from card are
                         ; valid
          LDY #0
          LDX #0
:LOOP
          LDA TIMEII,Y
          CMP :VALDVAL,X
          BCC :ERROR     ; <
          INX
          CMP :VALDVAL,X
          BCS :ERROR     ; >=
          INX
          INY
          CPY #7
          BNE :LOOP
:OK       CLC
          LDA #$FF
          RTS
:ERROR
                         ; JSR BELL
                         ; JSR BELL
          TYA
          SEC
          RTS
:VALDVAL  DFB 0,60,0,60,0,24,0,7,0,100,1,13,1,32
          FIN


          DO E_PRNIIDATE
PRNIIDATE
          PRINT DATESTR
          LDY #6
          LDA TIMEII,Y
          JSR PRINTDEC
          LDA #"-"
          JSR COUT
          DEY
          LDA TIMEII,Y
          JSR PRINTDEC
          LDA #"-"
          JSR COUT
          DEY
          LDA TIMEII,Y
          JSR PRINTDEC
          LDA #" "
          JSR COUT
          LDY #2
          LDA TIMEII,Y
          JSR PRINTDEC
          LDA #":"
          JSR COUT
          DEY
          LDA TIMEII,Y
          JSR PRINTDEC
          LDA #":"
          JSR COUT
          DEY
          LDA TIMEII,Y
          JSR PRINTDEC
          JSR CROUT
          JSR CROUT
          RTS
          FIN

          DO E_FINDSLOT
FINDSLOT
          LDY #0
LOOP
          LDA :SLOTS,Y
          BEQ :NFEXIT
          STY :SAVY
          JSR GETIIDATE1
          JSR ISIIDATE
          BCC :FEXIT
:NFEXIT
          LDA #0
          SEC
          RTS
:FEXIT
          CLC
          LDA :SAVY
          RTS
:SAVY     HEX 00
:SLOTS    HEX 07,06,05,04,02,01,00 ; possible slot
          FIN

IISLOT    HEX 00
TIMEII
DECSEC    HEX 00
DECMIN    HEX 00
DECHOU    HEX 00
DECDOW    HEX 00
DECDAY    HEX 00
DECMON    HEX 00
DECYEA    HEX 00
