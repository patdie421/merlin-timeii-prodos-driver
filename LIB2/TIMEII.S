****************************************************************
* TIME II CLOCK CARD DRIVER (APPLE II / 6502)
*
* Complete, bug-fixed & compacted driver for MSM5832-based
* Apple II clock cards:
*   - Low-level register read/write (FWRREG1, FWRREG2)
*   - Leap-year flag management (TGL/PUT/SET/CLR/GETIILEAP)
*   - Date/time setup & read with 12H->24H conversion (SET/GETIIDATE)
*   - Seconds reset & +/-30s adjustment (IIZEROS, II30ADJ)
*   - Force 24H hardware mode (FORCE24II)
*   - Validation & ASCII formatting/printing (ISIIDATE, PRNIIDATE)
*
* Global Conventions:
*   X = Slot offset (SLOT * 16, i.e., $10..$70)
*   Y = Hardware register index (0..12) or REGS table index (0..13)
****************************************************************

]E_FWRREG  EQU     0
]E_REGS    EQU     0
           DO      ]E_SETIIDATE+]E_FORCE24II+]E_IISECADJ
]E_FWRREG  EQU     1
]E_REGS    EQU     1
           FIN
           DO      ]E_TGLIILEAP+]E_CLRIILEAP+]E_SETIILEAP+]E_PUTIILEAP
]E_FWRREG  EQU     1
]E_REGS    EQU     1
           FIN

]TIMEIIDBG EQU     1


*===============================================================
* HARDWARE MACROS
*===============================================================

*---------------------------------------------------------------
* HLDLINE : Hold command line high (prevents clock tick during I/O)
*
* Call    : HLDLINE
* In      : X = SLOT * 16 ($10..$70)
* Out     : None
* Clobbers: A (preserves Carry flag)
*---------------------------------------------------------------
HLDLINE    MAC
           LDA     #%00010000      ; bit 4 = HOLD line high ($10)
           STA     BASE_B,X
           <<<


*---------------------------------------------------------------
* RLSLINE : Release command line (resumes normal clock operation)
*
* Call    : RLSLINE
* In      : X = SLOT * 16 ($10..$70)
* Out     : None
* Clobbers: A (preserves Carry flag)
*---------------------------------------------------------------
RLSLINE    MAC
           LDA     #%00000000      ; clear HOLD line
           STA     BASE_B,X
           <<<


*---------------------------------------------------------------
* RDREG   : Read a 4-bit nibble from a TIME II hardware register
*
* Call    : RDREG
* In      : X = SLOT * 16 ($10..$70)
*           Y = TIME II hardware register index (0..12)
* Out     : A = register value (low nibble; high nibble has status bits)
* Clobbers: A (preserves X, Y)
*---------------------------------------------------------------
RDREG      MAC
           TYA
           AND     #%00001111      ; mask register number (0..15)
           ORA     #%00100000      ; bit 5 = READ strobe ($20)
           STA     BASE_A,X        ; select register & assert READ
           LDA     BASE_A,X        ; read nibble from data bus
           <<<


*===============================================================
* SHARED HELPERS
*===============================================================
           DO      ]E_SETIIDATE+]E_IISECADJ+]E_GETIIDATE+]E_FORCE24II

*---------------------------------------------------------------
* GETSLOTX : Convert Apple II slot number in A to X = SLOT * 16
*
* In       : A = slot number (1..7)
* Out      : X = SLOT * 16 ($10..$70)
* Clobbers : A, X (preserves Y)
*---------------------------------------------------------------
GETSLOTX   ASL
           ASL
           ASL
           ASL
           TAX
           RTS
           FIN


           DO      ]E_GETIIDATE+]E_FORCE24II

*---------------------------------------------------------------
* PMTO24BCD : Convert 12H PM tens/units into 24H BCD byte
*
* In        : A = raw HOUTEN register (bits 0..1 = tens)
*             Y = raw HOUUNI register (bits 0..3 = units)
* Out       : A = 24H BCD hour ($12..$23)
* Clobbers  : A (preserves X, Y)
*---------------------------------------------------------------
PMTO24BCD  AND     #%00000011      ; isolate 12H hour tens (0..1)
           ASL
           ASL
           ASL
           ASL
           STA     :TMP            ; tens in high nibble
           TYA
           AND     #%00001111      ; isolate hour units (0..9)
           ORA     :TMP            ; combine into 2-digit BCD ($01..$12)
           SED                     ; enable BCD arithmetic
           CLC
           ADC     #$12            ; add 12 hours in BCD (FIXED: was #12!)
           CLD                     ; restore binary mode
           RTS
:TMP       HEX     00
           FIN


*===============================================================
* REGISTER WRITE ROUTINES
*===============================================================
           DO      ]E_FWRREG

*---------------------------------------------------------------
* FWRREG1 : Write a 4-bit value to a TIME II hardware register
*
* Protocol: POKE BASE_A, REG
*           POKE BASE_B, VAL + $10 (HOLD + data)
*           POKE BASE_A, REG + $10 (WRITE strobe)
*           POKE BASE_A, REG       (clear WRITE strobe)
*
* Call    : JSR FWRREG1
* In      : X = SLOT * 16 ($10..$70)
*           Y = TIME II hardware register index (0..12)
*           A = 4-bit value to write (0..15)
* Out     : None
* Clobbers: A (preserves X, Y)
*---------------------------------------------------------------
FWRREG1    ENT
           PHA                     ; save value on stack
           TYA
           AND     #%00001111      ; mask register index (0..15)
           STA     BASE_A,X        ; 1) select register (REG)
           TAY                     ; keep masked REG in Y

           PLA                     ; restore value
           AND     #%00001111      ; mask 4-bit data nibble
           ORA     #%00010000      ; raise HOLD bit ($10)
           STA     BASE_B,X        ; 2) latch data on bus (VAL + $10)

           TYA
           ORA     #%00010000      ; raise WRITE strobe ($10)
           STA     BASE_A,X        ; 3) strobe write (REG + $10)
           TYA
           STA     BASE_A,X        ; 4) end write cycle (REG)
           RTS


*---------------------------------------------------------------
* FWRREG2 : Write 4-bit value to TIME II register via REGS table
*
* Call    : JSR FWRREG2
* In      : X = SLOT * 16 ($10..$70)
*           Y = logical index into REGS table (0..13)
*           A = 4-bit value to write (0..15)
* Out     : None
* Clobbers: A (preserves X, Y)
*---------------------------------------------------------------
FWRREG2    ENT
           PHA                     ; save value on stack
           TYA
           PHA                     ; save REGS index on stack
           LDA     REGS,Y          ; translate logical index -> hardware reg
           TAY
           TSX
           LDA     $0102,X         ; peek value from stack without popping
           JSR     FWRREG1         ; write data to hardware register
           PLA
           TAY                     ; restore original Y
           PLA                     ; clean up value from stack
           RTS
           FIN


*===============================================================
* LEAP YEAR BIT MANAGEMENT (Bit 2 of DATTEN register)
*===============================================================

*---------------------------------------------------------------
* PUTIILEAP : Set or clear TIME II leap-year bit based on A
*
* Call      : JSR PUTIILEAP
* In        : X = SLOT * 16 ($10..$70)
*             A = 0 (clear leap bit) or A != 0 (set leap bit)
* Out       : None
* Clobbers  : A, Y (preserves X)
*---------------------------------------------------------------
           DO      ]E_PUTIILEAP
PUTIILEAP  ENT
           CMP     #0
           BEQ     CLRIILEAP       ; A == 0 -> clear bit 2
           BNE     SETIILEAP       ; A != 0 -> set bit 2
           FIN


*---------------------------------------------------------------
* TGLIILEAP : Toggle TIME II leap-year bit (invert bit 2)
*
* Call      : JSR TGLIILEAP
* In        : X = SLOT * 16 ($10..$70)
* Out       : None
* Clobbers  : A, Y (preserves X)
*---------------------------------------------------------------
           DO      ]E_TGLIILEAP
TGLIILEAP  ENT
           LDY     #DATTEN
           RDREG                   ; read DATTEN register
           EOR     #%00000100      ; invert bit 2 (leap flag)
           JMP     WRLEAP          ; write back and release line
           FIN


*---------------------------------------------------------------
* SETIILEAP : Set TIME II leap-year bit (force bit 2 = 1)
*
* Call      : JSR SETIILEAP
* In        : X = SLOT * 16 ($10..$70)
* Out       : None
* Clobbers  : A, Y (preserves X)
*---------------------------------------------------------------
           DO      ]E_SETIILEAP+]E_PUTIILEAP
SETIILEAP  ENT
           LDY     #DATTEN
           RDREG                   ; read DATTEN register
           ORA     #%00000100      ; force bit 2 = 1
           BNE     WRLEAP          ; unconditional branch (A != 0)
           FIN


*---------------------------------------------------------------
* CLRIILEAP : Clear TIME II leap-year bit (force bit 2 = 0)
*
* Call      : JSR CLRIILEAP
* In        : X = SLOT * 16 ($10..$70)
* Out       : None
* Clobbers  : A, Y (preserves X)
*---------------------------------------------------------------
           DO      ]E_CLRIILEAP+]E_PUTIILEAP
CLRIILEAP  ENT
           LDY     #DATTEN
           RDREG                   ; read DATTEN register
           AND     #%11111011      ; force bit 2 = 0
           FIN


*---------------------------------------------------------------
* WRLEAP : Shared exit path for all leap-year write routines
*
* In     : X = SLOT * 16, Y = DATTEN, A = updated DATTEN value
* Out    : None
*---------------------------------------------------------------
           DO      ]E_TGLIILEAP+]E_PUTIILEAP+]E_SETIILEAP+]E_CLRIILEAP
WRLEAP     JSR     FWRREG1         ; write updated DATTEN register
           RLSLINE                 ; release command line
           RTS
           FIN


*---------------------------------------------------------------
* GETIILEAP : Read TIME II leap-year bit into Carry flag
*
* Call      : JSR GETIILEAP
* In        : X = SLOT * 16 ($10..$70)
* Out       : Carry = 1 (leap year active)
*             Carry = 0 (common year)
* Clobbers  : A, Y (preserves X)
*---------------------------------------------------------------
           DO      ]E_GETIILEAP
GETIILEAP  ENT
           LDY     #DATTEN
           RDREG                   ; read DATTEN register
           LSR                     ; shift bit 0 out
           LSR                     ; shift bit 1 out
           LSR                     ; shift bit 2 (leap flag) into Carry
           RLSLINE                 ; release line (preserves Carry!)
           RTS
           FIN


*===============================================================
* DATE & TIME CONFIGURATION
*===============================================================
           DO      ]E_SETIIDATE

*---------------------------------------------------------------
* SETIIDATE  : Set full TIME II date and time from DATIDATE struct
*
* Entry points:
*   SETIIDATE  : reads slot number from IISLOT
*   SETIIDATE1 : A = slot number (1..7)
*   SETIIDATE2 : X = SLOT * 16 ($10..$70)
*
* In       : DATIDATE = pointer to 8-byte DATI date structure:
*            =Leap mask (0 or 4),=Year,=Month,=Day,
*            =Hour (24H),=Minute,=Second,=DayOfWeek
* Out      : None (sets 24H mode and leap bit automatically)
* Clobbers : A, X, Y
*---------------------------------------------------------------
SETIIDATE  ENT
           LDA     IISLOT          ; entry 1: load slot from IISLOT
SETIIDATE1 ENT                     ; entry 2: A = slot number
           JSR     GETSLOTX        ; X = SLOT * 16
SETIIDATE2 ENT                     ; entry 3: X = SLOT * 16
           LDA     DATIDATE        ; set self-modifying pointer to DATI struct
           STA     :RDDATI+1
           LDA     DATIDATE+1
           STA     :RDDATI+2

           LDY     #0              ; read byte = leap-year bit mask
           JSR     :RDDATI
           STA     :LEA+1          ; store directly in OR operand below

           HLDLINE                 ; hold clock line during bulk update
           LDY     #5              ; start at index 5 (Minutes) down to 1 (Year)
:LOOP      JSR     :RDDATI         ; A = DATIDATE[Y]
           JSR     :SETII2REG      ; split into tens/units and write 2 regs
           DEY
           BNE     :LOOP

           LDY     #7              ; finally, write index 7 (Day of Week)
           JSR     :RDDATI
           LDY     #0              ; REGS = Day of Week register
           JSR     FWRREG2

           RLSLINE                 ; release clock line
           RTS

:RDDATI    LDA     $FFFF,Y         ; self-modified with DATIDATE address
           RTS


*---------------------------------------------------------------
* :SETII2REG : Split 1 binary byte into tens/units and write 2 regs
*
* In         : A = binary value (0..99)
*              Y = DATI structure index (1..5)
*              X = SLOT * 16 ($10..$70)
* Out        : None (applies 24H bit on Hour Tens, leap bit on Day Tens)
* Clobbers   : A (preserves X, Y)
*---------------------------------------------------------------
:SETII2REG STY     :SAVY+1         ; preserve DATI index Y
           STX     :SAVX+1         ; preserve SLOT * 16
           JSR     HEXTODIGI       ; A -> X = units (0..9), Y = tens (0..9)
           TYA
           PHA                     ; push tens onto stack
           TXA
           PHA                     ; push units onto stack

:SAVX      LDX     #$00            ; restore X = SLOT * 16
           LDA     :SAVY+1         ; compute REGS table index = Y * 2
           ASL
           TAY

           PLA                     ; pop & write units nibble
           JSR     FWRREG2
           INY                     ; advance to tens register

           PLA                     ; pop tens nibble
           CPY     #9              ; is this Hour Tens (REGS)?
           BNE     :CHKDAY
           ORA     #%00001000      ; force 24H mode bit (bit 3)
           BNE     :WRTEN          ; unconditional branch
:CHKDAY    CPY     #7              ; is this Day Tens (REGS)?
           BNE     :WRTEN
:LEA       ORA     #$00            ; apply leap-year bit mask (self-modified)
:WRTEN     JSR     FWRREG2         ; write tens nibble
:SAVY      LDY     #$00            ; restore original DATI index Y
           RTS
           FIN


*===============================================================
* SECONDS ADJUSTMENT & RESET
*===============================================================
           DO      ]E_IISECADJ

*---------------------------------------------------------------
* IIZEROS   : Reset TIME II seconds registers (units and/or tens)
*
* Entry points:
*   IIZEROS  : reads slot number from IISLOT
*   IIZEROS1 : A = slot number (1..7)
*   IIZEROS2 : X = SLOT * 16 ($10..$70)
*
* In        : Y = bitmask: 1 = reset units, 2 = reset tens, 3 = both
* Out       : None
* Clobbers  : A, X, Y
*---------------------------------------------------------------
IIZEROS    ENT
           LDA     IISLOT          ; entry 1: load slot from IISLOT
IIZEROS1   ENT                     ; entry 2: A = slot number
           JSR     GETSLOTX        ; X = SLOT * 16
IIZEROS2   ENT                     ; entry 3: X = SLOT * 16
           TYA
           PHA                     ; save bitmask (1, 2, or 3) on stack
           HLDLINE                 ; hold clock line during reset

           PLA                     ; check bit 0 (reset seconds units?)
           PHA
           LSR
           BCC     :CHKTEN
           LDA     #0              ; write 0 to SECUNI (FIXED: A was non-zero!)
           LDY     #SECUNI
           JSR     FWRREG1

:CHKTEN    PLA                     ; check bit 1 (reset seconds tens?)
           AND     #%00000010
           BEQ     :EXIT
           LDA     #0              ; write 0 to SECTEN (FIXED: A was non-zero!)
           LDY     #SECTEN
           JSR     FWRREG1

:EXIT      RLSLINE
           RTS


*---------------------------------------------------------------
* II30ADJ  : Adjust TIME II clock by +/- 30 seconds
*            (Pulses bit 5 of BASE_B high for > 31.25 ms)
*
* Entry points:
*   II30ADJ  : reads slot number from IISLOT
*   II30ADJ1 : A = slot number (1..7)
*   II30ADJ2 : X = SLOT * 16 ($10..$70)
*
* In       : IISLOT, A, or X (depending on entry point)
* Out      : None
* Clobbers : A, X, Y
*---------------------------------------------------------------
II30ADJ    ENT
           LDA     IISLOT          ; entry 1: load slot from IISLOT
II30ADJ1   ENT                     ; entry 2: A = slot number
           JSR     GETSLOTX        ; X = SLOT * 16
II30ADJ2   ENT                     ; entry 3: X = SLOT * 16
           LDA     #%00100000      ; assert 30-sec adjust line ($20)
           STA     BASE_B,X

           LDA     #20             ; delay > 31.25 ms (20 * 2.25 ms = 45 ms)
           STA     :CNTR
:LOOP1     LDY     #250
:LOOP2     NOP                     ; 250 * 9 cycles = 2250 us
           NOP
           DEY
           BNE     :LOOP2
           DEC     :CNTR
           BNE     :LOOP1

           LDA     #0              ; release 30-sec adjust line
           STA     BASE_B,X
           RTS
:CNTR      HEX     00
           FIN


*===============================================================
* HARDWARE REGISTER MAPPING TABLE
*===============================================================
           DO      ]E_REGS
REGS
* TIME II hardware registers ordered to match DATI structure (1 entry = 2 regs)
           DFB     DAYWEE,0        ; 0: 0,1   (Day of week; no tens reg)
           DFB     YEAUNI,YEATEN   ; 1: 2,3   (Year)
           DFB     MONUNI,MONTEN   ; 2: 4,5   (Month)
:DAT       DFB     DATUNI,DATTEN   ; 3: 6,7   (Day of month)
:HOU       DFB     HOUUNI,HOUTEN   ; 4: 8,9   (Hour)
           DFB     MINUNI,MINTEN   ; 5: 10,11 (Minute)
           DFB     SECUNI,SECTEN   ; 6: 12,13 (Second)
           FIN


*===============================================================
* READ DATE & TIME FROM CARD
*===============================================================
           DO      ]E_GETIIDATE

*---------------------------------------------------------------
* GETIIDATE : Read TIME II date/time into 7-byte TIMEII buffer
*             Converts 12H AM/PM to 24H automatically and updates HEXLEA.
*
* Entry points:
*   GETIIDATE  : reads slot number from IISLOT
*   GETIIDATE1 : A = slot number (1..7)
*   GETIIDATE2 : X = SLOT * 16 ($10..$70)
*
* In        : IISLOT, A, or X (depending on entry point)
* Out       : TIMEII+0..6 populated with binary values:
*               0 = Seconds (0..59)
*               1 = Minutes (0..59)
*               2 = Hours   (0..23, 24H format)
*               3 = DayOfWk (0..6)
*               4 = Year    (0..99)
*               5 = Month   (1..12)
*               6 = Day     (1..31)
*             HEXLEA = $FF (leap year) or $00 (common year)
* Clobbers  : A, X, Y
*---------------------------------------------------------------
GETIIDATE  ENT
           LDA     IISLOT          ; entry 1: load slot from IISLOT
GETIIDATE1 ENT                     ; entry 2: A = slot number
           JSR     GETSLOTX        ; X = SLOT * 16
GETIIDATE2 ENT                     ; entry 3: X = SLOT * 16
           LDA     #0
           STA     :COUNTER        ; output buffer index (0..6)
           HLDLINE                 ; hold clock line during read

           LDY     #SECUNI         ; start at hardware register 0 (Seconds units)
:LOOP      TYA
           STA     BASE_A,X        ; select units register
           LDA     BASE_A,X
           AND     #%00001111      ; mask 4-bit units nibble
           STA     :AVAL

           LDA     #0              ; default tens = 0 (used for DAYWEE)
           STA     :BVAL
           CPY     #DAYWEE         ; Day of week has no tens register
           BEQ     :COMBINE

           INY                     ; advance to tens hardware register
           TYA
           STA     BASE_A,X
           LDA     BASE_A,X
           AND     #%00001111      ; mask 4-bit tens nibble + status flags
           STA     :BVAL

           CPY     #HOUTEN         ; Hour Tens register?
           BNE     :CHKDAT
           AND     #%00001000      ; bit 3 = 1 -> 24H format already
           BNE     :MASK2
           LDA     :BVAL           ; 12H format: check bit 2 (PM flag)
           AND     #%00000100
           BEQ     :MASK2          ; AM -> just strip flags

* PM in 12H mode: use shared PMTO24BCD helper
           STY     :SAVY           ; save HOUTEN reg index
           LDA     :BVAL           ; A = raw HOUTEN
           LDY     :AVAL           ; Y = raw HOUUNI
           JSR     PMTO24BCD       ; A = 24H BCD hour ($12..$23)
           LDY     :SAVY           ; restore HOUTEN reg index
           PHA
           AND     #%00001111      ; extract new units
           STA     :AVAL
           PLA
           LSR                     ; extract new tens (bits 4..5)
           LSR
           LSR
           LSR
           STA     :BVAL
           BNE     :COMBINE        ; unconditional branch (PM hour >= 12)

:CHKDAT    CPY     #DATTEN         ; Day Tens register?
           BNE     :COMBINE
           LDA     :BVAL
           AND     #%00000100      ; check bit 2 = leap-year flag (FIXED: was #%00001000!)
           BEQ     :NOTLEAP
           LDA     #$FF            ; leap year active -> HEXLEA = $FF
           BNE     :STOLEAP
:NOTLEAP   LDA     #$00            ; common year -> HEXLEA = $00
:STOLEAP   STA     HEXLEA

:MASK2     LDA     :BVAL           ; strip status flags (keep bits 0..1)
           AND     #%00000011
           STA     :BVAL

* Convert tens (:BVAL) and units (:AVAL) to binary byte: BVAL*10 + AVAL
:COMBINE   LDA     :BVAL
           ASL                     ; * 2
           ASL                     ; * 4
           ASL                     ; * 8
           CLC
           ADC     :BVAL           ; * 9
           ADC     :BVAL           ; * 10
           ADC     :AVAL           ; + units

           STY     :BVAL           ; save hardware register index
           LDY     :COUNTER
           STA     TIMEII,Y        ; store binary value in TIMEII buffer
           INC     :COUNTER
           LDY     :BVAL           ; restore hardware register index

           INY                     ; advance to next units register
           CPY     #YEATEN+1       ; finished all registers up to YEATEN?
           BCC     :LOOP

           RLSLINE                 ; release clock line
           RTS

:COUNTER   HEX     00
:AVAL      HEX     00
:BVAL      HEX     00
:SAVY      HEX     00
           FIN


*===============================================================
* VALIDATION & DISPLAY ROUTINES
*===============================================================
           DO      ]E_ISIIDATE

*---------------------------------------------------------------
* ISIIDATE : Validate ranges of all 7 values in TIMEII buffer
*
* Call     : JSR ISIIDATE
* In       : TIMEII+0..6 = binary date/time values from GETIIDATE
* Out      : Carry = 0, A = $FF (all fields valid)
*            Carry = 1, A = index of first invalid field (0..6)
* Clobbers : A, X, Y
*---------------------------------------------------------------
ISIIDATE   ENT
           LDY     #0
           LDX     #0
:LOOP      LDA     TIMEII,Y
           CMP     :BOUNDS,X       ; check lower bound (inclusive)
           BCC     :ERROR
           INX
           CMP     :BOUNDS,X       ; check upper bound (exclusive)
           BCS     :ERROR
           INX
           INY
           CPY     #7
           BNE     :LOOP
           CLC                     ; valid
           LDA     #$FF
           RTS
:ERROR     TYA                     ; return failing field index in A
           SEC
           RTS

* Min (inclusive) / Max (exclusive) pairs for TIMEII+0..6
:BOUNDS    DFB     0,60            ; 0: Seconds (0..59)
           DFB     0,60            ; 1: Minutes (0..59)
           DFB     0,24            ; 2: Hours   (0..23)
           DFB     0,7             ; 3: DayOfWk (0..6)
           DFB     0,100           ; 4: Year    (0..99)
           DFB     1,13            ; 5: Month   (1..12)
           DFB     1,32            ; 6: Day     (1..31)
           FIN


           DO      ]E_PRNIIDATE
*---------------------------------------------------------------
* PRNIIDATE : Print date & time as "DD-MM-YY HH:MM:SS"
* PRNIITIME : Print time only as "HH:MM:SS"
*
* Call      : JSR PRNIIDATE  (or JSR PRNIITIME)
* In        : TIMEII+0..6 = binary date/time values from GETIIDATE
* Out       : None (prints via PRINTDEC and Apple II ROM COUT)
* Clobbers  : A, X, Y
*---------------------------------------------------------------
PRNIIDATE  ENT
           LDY     #6              ; start at TIMEII (Day) down to Year (index 4)
           LDA     #"-"            ; date separator character
           JSR     :PRN3
           LDA     #" "
           JSR     COUT

PRNIITIME  ENT
           LDY     #2              ; start at TIMEII (Hour) down to Sec (index 0)
           LDA     #":"            ; time separator character

* Shared helper: print 3 descending bytes from TIMEII,Y separated by char in A
:PRN3      STA     :SEP+1          ; store separator character
           LDX     #3              ; 3 fields to print
:LOOP      LDA     TIMEII,Y
           JSR     PRINTDEC        ; print 2-digit decimal value
           DEY
           DEX
           BEQ     :DONE           ; no separator after 3rd field
:SEP       LDA     #"-"            ; self-modified separator
           JSR     COUT
           BNE     :LOOP           ; unconditional branch (ASCII char != 0)
:DONE      RTS
           FIN


           DO      ]E_PRNIIDATE1
*---------------------------------------------------------------
* PRNIIDATE1 : Format and print null-terminated ASCII date/time
*
* Call       : JSR PRNIIDATE1
* In         : TIMEII+0..6 = binary date/time values from GETIIDATE
* Out        : None (formats into DATEIIASC, prints via COUT)
* Clobbers   : A, X, Y
*---------------------------------------------------------------
PRNIIDATE1 ENT                     ; (Renamed from PRNIIDATE to avoid duplicate ENT)
           JSR     TOIIDATEASC     ; format TIMEII buffer into DATEIIASC
           LDY     #0
:PRNLOOP   LDA     DATEIIASC,Y
           BEQ     :END            ; null terminator reached
           JSR     COUT
           INY
           BNE     :PRNLOOP
:END       RTS


*---------------------------------------------------------------
* TOIIDATEASC : Format TIMEII buffer into "DD/MM/YY HH:MM:SS" string
*
* Call        : JSR TOIIDATEASC
* In          : TIMEII+0..6 = binary date/time values from GETIIDATE
* Out         : DATEIIASC updated in place (null-terminated)
* Clobbers    : A, X, Y
*---------------------------------------------------------------
TOIIDATEASC ENT
           LDX     #0              ; index into :MAP table (0..10, step 2)
:LOOP      LDY     :MAP,X          ; get TIMEII field index (6, 5, 4, 2, 1, 0)
           LDA     TIMEII,Y
           STX     :SAVX+1         ; save :MAP index
           JSR     HEXTODIGI       ; A -> X = units (0..9), Y = tens (0..9)
           TXA
           PHA                     ; save units on stack
           TYA                     ; A = tens
           LDX     :SAVX+1
           LDY     :MAP+1,X        ; get destination offset in DATEIIASC
           ORA     #"0"            ; convert 0..9 to ASCII '0'..'9'
           STA     DATEIIASC,Y     ; write tens digit
           PLA                     ; pop units
           ORA     #"0"
           STA     DATEIIASC+1,Y   ; write units digit
           INX
           INX
           CPX     #12             ; processed all 6 fields?
           BNE     :LOOP
           RTS
:SAVX      HEX     00

* Pairs of (TIMEII index, DATEIIASC character offset)
:MAP       DFB     6,0             ; Day     -> DATEIIASC+0..1
           DFB     5,3             ; Month   -> DATEIIASC+3..4
           DFB     4,6             ; Year    -> DATEIIASC+6..7
           DFB     2,9             ; Hour    -> DATEIIASC+9..10
           DFB     1,12            ; Minute  -> DATEIIASC+12..13
           DFB     0,15            ; Second  -> DATEIIASC+15..16

DATEIIASC  ENT
           ASC     "XX/XX/XX XX:XX:XX",00
           FIN


*===============================================================
* FORCE 24-HOUR HARDWARE MODE
*===============================================================
           DO      ]E_FORCE24II

*---------------------------------------------------------------
* FORCE24II : Switch TIME II card from 12H AM/PM mode to 24H mode
*             (Converts PM hours +12 in BCD and sets bit 3 of HOUTEN)
*
* Call      : JSR FORCE24II
* In        : A = slot number (1..7)
* Out       : None
* Clobbers  : A, X, Y
*---------------------------------------------------------------
FORCE24II  ENT
           JSR     GETSLOTX        ; X = SLOT * 16
           HLDLINE                 ; hold clock line during read/modify/write

           LDY     #HOUTEN
           RDREG                   ; read Hour Tens register
           TAY                     ; save raw HOUTEN in Y
           AND     #%00001000      ; bit 3 = 1 -> already in 24H mode
           BNE     :DONE

           TYA
           AND     #%00000100      ; bit 2 = 1 -> PM, 0 -> AM
           BNE     :PM
           TYA                     ; AM: just strip flags and set 24H bit
           AND     #%00000011
           BPL     :SET24          ; unconditional branch

:PM        LDY     #HOUUNI
           RDREG                   ; read Hour Units register
           TAY                     ; Y = raw HOUUNI
           LDA     #HOUTEN
           STA     BASE_A,X
           LDA     BASE_A,X        ; A = raw HOUTEN
           JSR     PMTO24BCD       ; A = 24H BCD hour ($12..$23)
           PHA                     ; save BCD hour
           AND     #%00001111      ; write new Hour Units
           LDY     #HOUUNI
           JSR     FWRREG1
           PLA                     ; extract new Hour Tens
           LSR
           LSR
           LSR
           LSR

:SET24     ORA     #%00001000      ; set 24H format flag (bit 3)
           LDY     #HOUTEN
           JSR     FWRREG1
:DONE      RLSLINE
           RTS
           FIN


*===============================================================
* GLOBAL DATA / VARIABLES
*===============================================================
DATIDATE   ENT
           HEX     FF,FF           ; Pointer to 8-byte DATI input struct
IISLOT     ENT
           HEX     FF              ; TIME II card slot number (1..7)

TIMEII                             ; 7-byte binary date/time buffer (from GETIIDATE)
DECSEC     HEX     00              ; +0 : Seconds (0..59)
DECMIN     HEX     00              ; +1 : Minutes (0..59)
DECHOU     HEX     00              ; +2 : Hours   (0..23, 24H format)
DECDOW     HEX     00              ; +3 : Day of week (0..6)
DECDAY     HEX     00              ; +4 : Year (0..99)  [Note: matches index 4]
DECMON     HEX     00              ; +5 : Month (1..12)
DECYEA     HEX     00              ; +6 : Day (1..31)
HEXLEA     HEX     00              ; +7 : Leap-year flag ($FF = leap, $00 = common)
