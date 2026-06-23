]E_FWRREG EQU 0
]E_REGS EQU 0
 DO ]E_SETIIDATE+]E_FORCE24II+]E_IISECADJ
]E_FWRREG EQU 1
]E_REGS EQU 1
 FIN
 DO ]E_TGLIILEAP+]E_CLRIILEAP+]E_SETIILEAP
]E_FWRREG EQU 1
]E_REGS EQU 1
 FIN


]TIMEIIDBG EQU 1

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

HLDLINE MAC
*
* hold cmd line
* in: X = SLOT * 16
* A is modified
*
 LDA #%00010000 ; 16 ($10)
 STA BASE_B,X ; Hold line high
 <<<


RLSLINE MAC
*
* release cmd line
* in:  X = SLOT * 16
* A is modified
*
 LDA #%00000000
* STA BASE_A,X
 STA BASE_B,X
 <<<


RDREG MAC
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


 DO ]E_FWRREG
********************************
FWRREG1 ENT
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
 STA :VAL ; save value to stack because
 TYA  ; we need A for bit manipulation
 AND #%00001111 ; reg num must be < 16
 STA BASE_A,X ; select register (REG)
 LDA :VAL ; now we need value
 AND #%00001111 ; value has only 4 bits
 ORA #%00010000 ; bit 5 up to store data
 STA BASE_B,X ; store data (VAL)
 TYA ; Y (reg num) in A
 AND #%00001111 ; reg num forced < 16
 ORA #%00010000 ; +16 register and flag raised
 STA BASE_A,X ; and store it (REG)
 AND #%00001111 ;
 STA BASE_A,X ; (VAL)
 RTS
:VAL HEX 00


********************************
FWRREG2 ENT
*
* write TIMEII register from REGS index
* in: X = SLOT * 16
* in: Y = index in REGS
* in: A = value to write
* A is modified
*
********************************
 STY :SAVY ; save Y
 PHA ; save A
 LDA REGS,Y ; get timeii register from REGS table
 TAY ; transfert in Y for FWRREG1
 PLA ; retrieve value
 JSR FWRREG1 ; write data
 LDY :SAVY ; restore Y
 RTS
:SAVY HEX 00
 FIN


 DO ]E_TGLIILEAP
********************************
TGLIILEAP ENT
*
* toggle leap bit of DATTEN register
* in: X = SLOT * 16
* A,Y are modified
*
********************************
* HLDLINE
 LDY #DATTEN
 RDREG
 EOR #%00000100 ; tc bit
 JSR FWRREG1
:EXIT RLSLINE
 RTS
 FIN


 DO ]E_PUTIILEAP
********************************
PUTIILEAP ENT
*
* PUT timeII LEAP bit of DATTEN register
* in: A = 0 reset leap, >0 set leap
* in: X = SLOT * 16
* A is modified
* Y is modified
*
********************************
* HLDLINE
 LDY #DATTEN
 CMP #0
 BEQ :RESET
:SET
 RDREG
 ORA #%00000100 ; tc bit
 BNE :DOIT ; JMP :DOIT
:RESET
 RDREG
 AND #%11111011 ; tc bit
:DOIT
 JSR FWRREG1
:EXIT RLSLINE
 RTS
 FIN


 DO ]E_SETIILEAP
********************************
SETIILEAP ENT
*
* SET timeII LEAP bit of DATTEN register
* in: X = SLOT * 16
* A is modified
* Y is modified
*
********************************
* HLDLINE
 LDY #DATTEN
 RDREG
 ORA #%00000100 ; tc bit
 JSR FWRREG1
:EXIT RLSLINE
 RTS
 FIN
* RTS
* FIN


 DO ]E_CLRIILEAP
********************************
CLRIILEAP ENT
*
* CLeaR timeII LEAP bit of DATTEN register
* in: X = SLOT * 16
* A is modified
* Y is modified
*
********************************
* HLDLINE
 LDY #DATTEN
 RDREG
 AND #%11111011 ; tc bit
 JSR FWRREG1
:EXIT RLSLINE
 RTS
 FIN


 DO ]E_GETIILEAP
********************************
GETIILEAP ENT
*
* get leap bit from DATTEN register
* in: X = SLOT * 16
* out: Carry = 1 : leap, Carry = 0 not leap
* A,Y is modified
*
********************************
* HLDLINE
 LDY #DATTEN
 RDREG
 AND #%00000100 ; tc bit
 BEQ :NO
:YES SEC
 BCS :EXIT
:NO
 CLC
 BCC :EXIT
:EXIT RLSLINE
 RTS
 FIN


 DO ]E_SETIIDATE
********************************
SETIIDATE ENT
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
 LDA IISLOT ; slot * 16 -> X
SETIIDATE1 ENT ; second entry (X = SLOT)
 ASL
 ASL
 ASL
 ASL
 TAX
SETIIDATE2 ENT ; third entry (X = SLOT * 16)
* self code modification
 LDA DATIDATE
 STA :DATE1+1
 STA :DATE2+1
 STA :DATE3+1
 LDA DATIDATE+1
 STA :DATE1+2
 STA :DATE2+2
 STA :DATE3+2

 LDY #0
:DATE1 LDA $0000,Y
 STA :LEA

 LDY #5 ; MINUTE FIRST
 HLDLINE
:LOOP
:DATE2 LDA $0000,Y
 JSR :SETII2REG
 DEY
 BNE :LOOP

* finaly write Day of Week
 LDY #7
:DATE3 LDA $0000,Y
 LDY #0
 JSR FWRREG2

* release line
:EXIT
 RLSLINE
 RTS


********************************
:SETII2REG
*
* local procedure for updating 2 registers from 1 byte from
* DATI date structure
* in: Y = DATI structure index to push to timeii registers
* in: DATE = "DATI" data structure cf TIMEII.SETUP
* unmodified : X,Y
* modified : A
*
********************************
 STY :SAVY
 STX :SAVX
 JSR HEXTODIGI ; A to X (uni) and Y (tens)
 STY :TEN
 STX :UNI
 LDX :SAVX
 LDA :SAVY
 ASL ; y=y*2
 TAY

* write Units
 LDA :UNI
 JSR FWRREG2
 INY

 LDA :TEN
* write Tens, but ...
* we have to update some tens before writing data
 CPY #9 ; is hour tens => force 24H
 BNE :IINEXT
 ORA #%00001000 ; set 24H flag
 BNE :WRTEN ; JMP :WRTEN
:IINEXT CPY #7 ; date tens => set leap flag
 BNE :WRTEN
 ORA :LEA
:WRTEN
 JSR FWRREG2
 LDX :SAVX
 LDY :SAVY
 RTS
:UNI HEX 00
:TEN HEX 00
:LEA HEX 00
:SAVX HEX 00
:SAVY HEX 00
 FIN


 DO ]E_IISECADJ
********************************
IIZEROS ENT
*
* reset TIMEII seconds
* in: IISLOT = slot number
* in: Y = 1,2,3
*     1=RESET UNI
*     2=RESET TEN
*     3=RESET UNI & TEN
* A,X,Y modified
*
* ep: IIZEROS
*   in: A = slot
* ep: IIZEROS2
*   in: X = solt x 16
********************************
 LDA IISLOT ; slot * 16 -> X
IIZEROS1 ENT ; second entry (X = SLOT)
 ASL
 ASL
 ASL
 ASL
 TAX
IIZEROS2 ENT ; third entry (X = SLOT * 16)
 STY :TENUNI
* HLDLINE
:UNITS
 LDA #%00000001
 AND :TENUNI
 BEQ :TENS
 LDY #SECUNI
 JSR FWRREG1
:TENS
 LDA #%00000010
 AND :TENUNI
 BEQ :EXIT
 LDY #SECTEN
 JSR FWRREG1
:EXIT
 RLSLINE
 RTS
:TENUNI HEX 00


********************************
II30ADJ ENT
*
* adjust TIMEII -/+30 seconds
* in: IISLOT = slot number
* A,X,Y modified
*
* ep: II30ADJ
*   in: A = slot
* ep: II30ADJ2
*   in: X = solt x 16
********************************
 LDA IISLOT ; slot * 16 -> X
II30ADJ1 ENT ; second entry (X = SLOT)
 ASL
 ASL
 ASL
 ASL
 TAX
II30ADJ2 ENT ; third entry (X = SLOT * 16)
 LDA #32
 STA BASE_B,X
* start delay. Must be > 31.25mS
 LDA #20 ; 2uS
 STA :CNTR ; 4uS
:LOOP1 LDY #250 ; 2uS
:LOOP2 ; 250 * 9uS = 2250uS
 NOP ; 2uS
 NOP  ; 2uS
 DEY  ; 2uS
 BNE :LOOP2 ; ~3uS => LOOP2 = 9uS
 DEC :CNTR ; 6uS
 BNE :LOOP1 ; ~3uS
* end delay.
 LDA #0
 STA BASE_B,X
 RTS
:CNTR HEX 00
 FIN


 DO ]E_REGS
REGS
* TIMEII regs to update : must be in the same order than
* DATE table from GETDATI and match 1 for 2
 DFB DAYWEE,0    ; 0: 0,1
 DFB YEAUNI,YEATEN ; 1: 2,3
 DFB MONUNI,MONTEN ; 2: 4,5
:DAT DFB DATUNI,DATTEN ; 3: 6,7
:HOU DFB HOUUNI,HOUTEN ; 4: 8,9
 DFB MINUNI,MINTEN ; 5: 10,11
 DFB SECUNI,SECTEN ; 6: 12,13
 FIN


 DO ]E_GETIIDATE
********************************
GETIIDATE ENT
*
* get TIMEII date and time from card.
* date is store in 24H format. Conversion is done if needed.
* in (GETIIDATE):  IISLOT = slot number (GETIIDATE)
* in (GETIIDATE1): A = slot number
* in (GETIIDATE2): X = slot x 16
* out: TIMEII = date structure (TimeII format)
* A,X,Y modified
*
********************************
 LDA IISLOT ; slot * 16 -> X
GETIIDATE1 ENT ; second entry (X = SLOT)
 ASL
 ASL
 ASL
 ASL
 TAX
GETIIDATE2 ENT ; third entry (X = SLOT * 16)
 LDA #0 ; #read counter
 STA :COUNTER

* hold line high
 HLDLINE

* Read all timeII card registers
 LDY #SECUNI ; first  register (second unit)
:LOOP
 TYA ; start reading units
 STA BASE_A,X
 LDA BASE_A,X
 AND #%00001111 ; only 4 lower bits are relevant
 STA :AVAL
* is this register DAY OF WEEK ?
 CPY #DAYWEE
 BNE :NEXT1 ; No, continue !
 LDA #0 ; Yes, this register has no tens
; replace by a 0
 STA :BVAL ; in BVAL
 BEQ :NEXT4 ; kind of "relative JMP"
:NEXT1
 INY ; start reading tens
 TYA
 STA BASE_A,X
 LDA BASE_A,X
 AND #%00001111 ; only lower bits are relevant
 STA :BVAL
* check registers (HOUTEN and DATTEN) having flags
 CPY #HOUTEN ; tens of hour
 BNE :NEXT2 ; No, go to check DATTEN
 AND #%00001000 ; check 12/24H format flag
 BNE :NEXT3 ; is 24H just remove flags
 LDA :BVAL ; is 12H
 AND #%00000100 ; we check AM or PM flag
 BEQ :NEXT3 ; AM nothing to do just remove flags
* PM flag, add 12H to hour and store result in :AVAL and :BVAL
* combine AVAL and BVAL in a BCD byte
 LDA :BVAL
 AND #%00000011
 ASL
 ASL
 ASL
 ASL
 ORA :AVAL
* add 12H in BCD Arithmetic
 SED  ; to BCD arithmetic
 CLC
 ADC #12
 PHA ; backup result
 CLD  ; to HEX arithmetic
* split result in :AVAL and :BVAL
 AND #%00001111 ; :AVAL (unit) extraction
 STA :AVAL
 PLA ; restore result for BVAL extraction
 AND #%00110000 ; :BVAL (tens) extraction
 LSR
 LSR
 LSR
 LSR
 STA :BVAL
 JMP :NEXT4 ; go combination
:NEXT2
 CPY #DATTEN ; tens of date
 BNE :NEXT4
 LDA :BVAL
 AND #$00001000
 BEQ :SLEAP
:NLEAP ; set not leap
 LDA #$00
 BEQ :STOLEAP ; JMP :STOLEAP
:SLEAP ; set leap
 LDA #$FF
:STOLEAP
 STA HEXLEA
:NEXT3 ; remove flags from :BVAL
 LDA :BVAL
 AND #%0011
 STA :BVAL
:NEXT4
* Combine units and tens in 1 byte (hex encoded)
* S =  BVAL x 10 + AVAL = BVAL x 2x2x2 + BVAL + BVAL + AVAL
 LDA :BVAL
 ASL ; :BVAL x 2
 ASL ; :BVAL x 2
 ASL ; :BVAL x 2
 CLC
 ADC :BVAL ; + :BVAL
 ADC :BVAL ; + :BVAL
 ADC :AVAL ; + :AVAL

**** store in buffer
* STA :AVAL
 STY :BVAL ; save Y
 LDY :COUNTER
 STA TIMEII,Y
 INC :COUNTER
 LDY :BVAL ; restore Y

* an other register to read ?
 INY
 CPY #YEATEN
 BMI :LOOP1 ; next unit register

:EXIT
 RLSLINE
 RTS
:LOOP1 ; for jmp to :LOOP
 JMP :LOOP

:COUNTER DFB $0
:AVAL HEX 00
:BVAL HEX 00
 FIN


 DO ]E_ISIIDATE
********************************
ISIIDATE ENT
*
* check if data from card are valid
* in: TIMEII : data read by GETIIDATE
* A,X,Y modified
*
********************************
 LDY #0
 LDX #0
:LOOP
 LDA TIMEII,Y
 CMP :VALDVAL,X
 BCC :ERROR ; <
 INX
 CMP :VALDVAL,X
 BCS :ERROR ; >=
 INX
 INY
 CPY #7
 BNE :LOOP
:OK CLC
 LDA #$FF
 RTS
:ERROR
; JSR BELL
 ; JSR BELL
 TYA
 SEC
 RTS
:VALDVAL DFB 0,60,0,60,0,24,0,7,0,100,1,13,1,32
 FIN

 DO ]E_PRNIIDATE
********************************
PRNIIDATE ENT
*
* print data from TIMEII
* TIMEII : data read by GETIIDATE
* A,X,Y modified
*
********************************

; PRINT DATESTR
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
PRNIITIME ENT
 LDA #2
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
 RTS
 FIN


 DO ]E_PRNIIDATE1
********************************
PRNIIDATE ENT
*
* print data from TIMEII
* TIMEII : data read by GETIIDATE
* A,X,Y modified
*
********************************
 JSR TOIIDATEASC
 LDY #0
:PRNLOOP
 LDA DATEIIASC,Y
 BEQ :END
 JSR COUT
 INY
 BNE :PRNLOOP ; JMP :PRNLOOP
:END RTS


********************************
TOIIDATEASC ENT
*
* dateii ASC string  from TIMEII
* TIMEII : data read by GETIIDATE
* A,X,Y modified
*
********************************
 LDX #0
 STX :PTR
:LOOP LDA :TDATE,X
 CMP #$FF
 BEQ :END
 CMP #10
 BCC :INDEX

; STY :SAV
 LDY :PTR
 STA DATEIIASC,Y
; LDY :SAV
 INC :PTR
 BNE :NEXT ; JMP :NEXT

:INDEX
 STX :SAV
 TAY
 LDA TIMEII,Y
 JSR HEXTODIGI
 STX :NUM
 STY :NUM+1

 LDX #2
 LDY :PTR
:LOOP1
 LDA #"0"
 CLC
 ADC :NUM-1,X
 STA DATEIIASC,Y
 INY
 DEX
 BNE :LOOP1
:NEXT1
 STY :PTR
 LDX :SAV
:NEXT
 INX
 BNE :LOOP
:END RTS
:SAV HEX 00
:NUM HEX 00,00
:PTR HEX 00
:TDATE DB 6,"/",5,"/",4," "
 DB 2,":",1,":",0,$FF
DATEIIASC ENT
 ASC "XX/XX/XX XX:XX:XX",00
 FIN


 DO ]E_FORCE24II
********************************
*
FORCE24II ENT
*
********************************
 ASL ; slot x 16 => X
 ASL
 ASL
 ASL
 TAX

 HLDLINE

 LDA #HOUTEN ; read hour ten
 STA BASE_A,X
 LDA BASE_A,X
 TAY

 AND #%00001000 ; check tb bit
 BNE :DONE ; allready 24H => nothing to do

 TYA
 AND #%00000100 ; AM or PM
 BNE :NEXT
:AM ; AM just set flag
 TYA
 AND #%00000011
 CLC
 BCC :SET24

* for add 12 to hour
:NEXT TYA ; hour tens to 4 higher bits
 AND #%00000011
 ASL
 ASL
 ASL
 ASL
 STA :TMP ; store result

 LDA #HOUUNI ; get hour unit
 STA BASE_A,X
 LDA BASE_A,X
 AND #%00001111 ; remove not needed bits

 ORA :TMP ; combine with unit with tens give
   ; that's now a dcb byte
 SED  ; switch to dcb
 CLC
 ADC #12 ; add 12
 CLD  ; return do hex
 PHA  ; save A

 AND #%00001111 ; write UNI
 LDY #HOUUNI
 JSR FWRREG1

 PLA ; write TEN
 LSR
 LSR
 LSR
 LSR
:SET24 ORA #%00001000 ; tb bit to 1
 LDY #HOUTEN
 JSR FWRREG1
:DONE
 RLSLINE
 RTS
:TMP HEX 00
 FIN

DATIDATE ENT
 HEX FF,FF
IISLOT ENT
 HEX FF ; slot of TIMEII card
TIMEII ; Copy of date/time from TIMEII
; UNI + 10 x TENS
DECSEC HEX 00 ; secondes
DECMIN HEX 00 ; minutes
DECHOU HEX 00 ; hour
DECDOW HEX 00 ; day of week
DECDAY HEX 00 ; day
DECMON HEX 00 ; month
DECYEA HEX 00 ; year
HEXLEA HEX 00 ; leap flag
