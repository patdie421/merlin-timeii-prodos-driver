
         DO ]E_SETIIDATE+]E_TGLIILEAP
E_FWRREG EQU 1
E_REGS EQU 1
          ELSE
E_FWRREG EQU 0
E_REGS EQU 0
          FIN

*
* TIMEII CARD
*
* BASIC program used this lines to set one reg
* R=<num reg>: REM 0 (sec unit) to 12 (year tens)
* V=<val> [0-9]
* POKE BASE_A, R
* POKE BASE_B, V+16
* POKE BASE_A, R+16
* POKE BASE_A, R
*

HLDLINE   MAC
*
* hold cmd line
* in: X = SLOT * 16
* A is modified
*
          LDA #%00001000 ; 16 ($10)
          STA BASE_B,X   ; Hold line high
          <<<


RLSLINE   MAC
*
* release cmd line
* in:  X = SLOT * 16
* A is modified
*
          LDA #%00000000
          STA BASE_B,X
          <<<


SETLEAP  MAC
*
* set leap flag
* in: X = SLOT * 16
* in: Y = TIMEII register
* A is modified
*
         JSR GETIILEAP
         BCS ]CONTINUE
         JSR TGLIILEAP
]CONTINUE
         <<<


CLRLEAP  MAC
*
* clear leap flag if set
* in: X = SLOT * 16
* in: Y = TIMEII register
* A is modified
*
         JSR GETIILEAP
         BCC ]CONTINUE
         JSR TGLIILEAP
]CONTINUE
         <<<


RDREG     MAC
*
* read register
* in: X = SLOT * 16
* in: Y = TIMEII register to read (TIMEII index)
* out: A = value retrieved
*
          TYA
          AND #%00001111
          ORA #%00100000
          STA BASE_A,X
          LDA BASE_A,X
          <<<


          DO E_FWRREG
********************************
FWRREG1
*
* write to TIMEII register by TIMEII index
* in: X = SLOT * 16
* in: Y = timeii reg num
* in: A = value to write
* A is modified
* BASIC is done like this :
* POKE BASE_A, REG
* POKE BASE_B, VAL+16
* POKE BASE_A, REG+16
* POKE BASE_A, REG
*
********************************
          PHA            ; save value to stack because
          TYA            ; we need A for bit manipulation
          AND #%00001111 ; reg num must be < 16
          STA BASE_A,X   ; select register ~ POKE BASE_A, REG
          PLA            ; now we need value
          AND #%00001111 ; value has only 4 bits
          ORA #%00010000 ; bit 5 up to store data
          STA BASE_B,X   ; store data ~ POKE BASE_B, VAL+16
          TYA            ; Y (reg num) in A for bit manipulation
          AND #%00001111 ; reg num is < 16
          ORA #%00010000 ; +16 register and flag raised
          STA BASE_A,X   ; and store ~ POKE BASE_A, REG+16
          AND #%00001111 ; 
          STA BASE_A,X   ; ~ POKE BASE_A, REG
          RTS


********************************
FWRREG2
*
* write TIMEII register from REGS index
* in: X = SLOT * 16
* in: Y = index in REGS
* in: A = value to write
* A is modified
*
********************************
          STY :SAVY     ; save Y
          PHA           ; save A
          LDA REGS,Y   ; get timeii register from REGS table
          TAY           ; transfert in Y for FWRREG1
          PLA           ; retrieve value
          JSR FWRREG1   ; write data
          LDY :SAVY     ; restore Y
          RTS
:SAVY     HEX 00
          FIN


         DO ]E_TGLIILEAP
********************************
TGLIILEAP
*
* toggle leap bit of DATTEN register
* in: X = SLOT * 16
* in: Y = TIMEII register
* A is modified
*
********************************
         HLDLINE
         LDY #7
         RDREG
         EOR #%00000100 ; tc bit
         JSR FWRREG2
:EXIT    RLSLINE
         RTS
         FIN


        DO ]E_GETIILEAP
********************************
GETIILEAP
*
* get leap bit from DATTEN register
* in: X = SLOT * 16
* in: Y = TIMEII register
* out: Carry = 1 : leap, Carry = 0 not leap
* A is modified
*
********************************
         HLDLINE
         LDY #7
         RDREG
         ORA #%00000100 ; tc bit
         BEQ :NO
:YES     SEC
         BCS :EXIT
:NO
         CLC
         BCC :EXIT
:EXIT    RLSLINE
         RTS
         FIN


          DO ]E_SETIIDATE
********************************
SETIIDATE
*
* set TIMEII date and time
* in: IISLOT = slot number
* in: DATE = "DATI" data structure cf TIMEII.SETUP
* A,X,Y modified
*
* ep: SETIIDATE1
*   in: A = slot
* ep: SETIIDATE2
*   in: X = solt x 16
********************************
          LDA IISLOT     ; slot * 16 -> X
SETIIDATE1               ; second entry (X = SLOT)
          ASL
          ASL
          ASL
          ASL
          TAX
SETIIDATE2               ; third entry (X = SLOT * 16)
          HLDLINE
          LDY #1
:LOOP
          LDA DATE,Y
          JSR :SETII2REG
          INY
          CPY #7
          BNE :LOOP

* finaly write Day of Week
          LDY #0
          LDA DATE+_DOW
          JSR FWRREG2
* release line
          RLSLINE
          RTS


********************************
:SETII2REG
*
* local procedure for updating 2 registers from 1 byte from DATI date structure
* in: Y = DATI structure index to push to timeii registers
* in: DATE = "DATI" data structure cf TIMEII.SETUP
* unmodified : X,Y
* modified : A
*
********************************
          STY :SAVY
          STX :SAVX
          JSR HEXTODIGI  ; A to X (uni) and Y (tens)
          STY :TEN
          STX :UNI
          LDX :SAVX
          LDA :SAVY
          ASL            ; y=y*2
          TAY
* write Units
          LDA :UNI
          JSR FWRREG2
          INY

          LDA :TEN
* write Tens, but ...
* we have to update some tens before writing data
          CPY #5 ; is hour tens register => force 24H format flag
          BNE :IINEXT
          ORA #%00001000 ; set 24H flag
          RJMP :WRTEN
:IINEXT   CPY #7 ; date tens => set leap flag
          BNE :WRTEN
          ORA DATE+_LEA  ; set leap flag (cf GETDATI)
:WRTEN
          JSR FRREG2
          LDX :SAVX
          LDY :SAVY
          RTS

:UNI      HEX 00
:TEN      HEX 00
:SAVX     HEX 00
:SAVY     HEX 00
          FIN


          DO E_REGS
REGS
* TIMEII regs to update : must be in the same order than
* DATE table from GETDATI and match 1 for 2
          DFB DAYWEE,0      ; 0: 0,1
          DFB YEAUNI,YEATEN ; 1: 2,3
          DFB MONUNI,MONTEN ; 2: 4,5
:DAT      DFB DATUNI,DATTEN ; 3: 6,7
:HOU      DFB HOUUNI,HOUTEN ; 4: 8,9
          DFB MINUNI,MINTEN ; 5: 10,11
          DFB SECUNI,SECTEN ; 6: 12,13
          FIN


          DO ]E_GETIIDATE
********************************
GETIIDATE
*
* get TIMEII date and time from card
* in: IISLOT = slot number
* out: TIMEII = TIMEII data structure
* A,X,Y modified
*
********************************
          LDA IISLOT     ; slot * 16 -> X
GETIIDATE1               ; second entry (X = SLOT)
          ASL
          ASL
          ASL
          ASL
          TAX
GETIIDATE2               ; third entry (X = SLOT * 16)
          LDA #0         ; #read counter
          STA :COUNTER

* hold line high
          HLDLINE

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

:EXIT     RLSLINE
          RTS
:COUNTER  DFB $0
:AVAL     HEX 00
:BVAL     HEX 00
          FIN


          DO ]E_ISIIDATE
********************************
ISIIDATE
*
* check if data from card are valid
* TIMEII : data read by GETIIDATE
* A,X,Y modified
*
********************************
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


          DO ]E_PRNIIDATE
********************************
PRNIIDATE
*
* print data from TIMEII
* TIMEII : data read by GETIIDATE
* A,X,Y modified
*
********************************
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


          DO ]E_FINDSLOT
********************************
*
FINDSLOT
*
* Find first slot with TIMEII card
* Card must have a correct date/time
* stored
*
********************************
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


IISLOT    HEX FF         ; slot of TIMEII card
TIMEII                   ; Copy of date/time from TIMEII 
                         ; UNI + 10 x TENS
DECSEC    HEX 00         ; secondes
DECMIN    HEX 00         ; minutes
DECHOU    HEX 00         ; hour
DECDOW    HEX 00         ; day of week
DECDAY    HEX 00         ; day
DECMON    HEX 00         ; month
DECYEA    HEX 00         ; year
