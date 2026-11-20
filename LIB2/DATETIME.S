LST     OFF
****************************************************************
* DATE / TIME UTILS v2 (APPLE II / 6502)
*
* Compact Gregorian calendar routines using inline parameter
* passing (4 parameter bytes follow the JSR instruction).
*
* Zero Page usage : $06-$07 (temp caller return pointer)
*                   $EB-$EE (4-byte inline parameter buffer)
****************************************************************

FRSTCENT   EQU     19              ; First century tested by GETCENT (1900s)


*---------------------------------------------------------------
* GETDAYOFW2 : Calculate Day of Week (Gregorian calendar)
*
* Algorithm  : Zeller's Congruence reduced to 8-bit arithmetic:
*              DoW = (K + Q + YY + M + DD + 2 + 5*(CC mod 7)) mod 7
*              Valid for all Gregorian dates (Oct 15, 1582 onward).
*
* Call       : JSR GETDAYOFW2
*              DFB DD,MM,CC,YY     ; Day (1..31), Month (1..12),
*                                  ; Century (e.g. 19), Year (0..99)
* Output     : A = Day of week (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
* Clobbers   : A, X, Y, $06-$07, $EB-$EE
*---------------------------------------------------------------
           DO      ]E_GETDAYOFW2+]E_GETCENT2
GETDAYOFW2 ENT
           JSR     GET4B           ; $EB=DD, $EC=MM, $ED=CC, $EE=YY

:ENTRYZP   LDX     $ED             ; internal entry point when $EB-$EE are set
           LDY     $EE             ; X = CC, Y = YY
           JSR     ISLEAP2         ; Carry = 1 if leap year, 0 otherwise
           LDY     $EC             ; Y = 1-based month index (1..12)
           LDA     :MONTH-1,Y      ; lookup standard month offset (0..6)
           BCC     :NOTLEAP        ; common year -> keep standard offset
           CPY     #3              ; leap year: is month Jan (1) or Feb (2)?
           BCS     :NOTLEAP        ; Mar..Dec offsets are unchanged
           SBC     #0              ; Carry=0 -> subtract 1 (Jan: 4->3, Feb: 0->$FF)
           BPL     :NOTLEAP
           LDA     #6              ; wrap -1 ($FF) to +6 (mod 7) for Feb
:NOTLEAP   STA     :TMP            ; store adjusted month offset M (0..6)

* Compute 8-bit sum before modulo 7 (guaranteed <= 255, zero overflow):
           LDA     $ED             ; CC
           JSR     :MOD7           ; A = CC mod 7 (0..6)
           STA     :CCMOD
           ASL                     ; A = 2 * (CC mod 7)
           ASL                     ; A = 4 * (CC mod 7)
           ADC     :CCMOD          ; A = 5 * (CC mod 7) (max 30, Carry stays 0)
           ADC     :TMP            ; + M              (max 36)
           ADC     $EE             ; + YY             (max 135)
           ADC     $EB             ; + DD             (max 166)
           ADC     #2              ; + 2              (max 168)
           STA     :TMP

           LDA     $EE             ; compute K = int(YY / 4) (max 24)
           LSR
           LSR
           CLC
           ADC     :TMP            ; sum + K          (max 192)
           STA     :TMP

           LDA     $ED             ; compute Q = int(CC / 4) (max 63)
           LSR
           LSR
           CLC
           ADC     :TMP            ; final sum        (max 255 -> fits in 8 bits!)

* Fall-through into :MOD7 to compute final result (sum mod 7)
:MOD7      SEC                     ; 8-bit unsigned modulo 7 by subtraction
:MODLOOP   SBC     #7
           BCS     :MODLOOP        ; loop while A >= 7
           ADC     #7              ; restore positive remainder (0..6)
           RTS

:MONTH     DFB     4,0,0,3,5,1,3,6,2,4,0,2
:TMP       HEX     00
:CCMOD     HEX     00
           FIN


*---------------------------------------------------------------
* ISLEAP2 : Check if a Gregorian year (CCYY) is a leap year
*
* Rule    : Leap if (YY != 0 and YY mod 4 == 0)
*                or (YY == 0 and CC mod 4 == 0)
*
* Inputs  : X = CC (century, e.g., 19, 20)
*           Y = YY (year within century, 0..99)
* Output  : Carry = 1 (leap year)
*           Carry = 0 (common year)
* Clobbers: A (preserves X and Y)
*---------------------------------------------------------------
           DO      ]E_ISLEAP2+]E_GETDAYOFW2+]E_GETCENT2
ISLEAP2    ENT
           TYA                     ; check year within century (YY)
           BNE     :CHECK4         ; if YY != 0, test YY divisibility by 4
           TXA                     ; if YY == 0 (turn of century), test CC mod 4
:CHECK4    AND     #%00000011      ; test lowest 2 bits (divisible by 4?)
           BEQ     :YES            ; Z = 1 -> divisible by 4 -> leap year
           CLC                     ; Z = 0 -> not a leap year
           RTS
:YES       SEC                     ; Carry = 1 -> leap year
           RTS
           FIN


*---------------------------------------------------------------
* GETCENT2 : Deduce century (19..23) from DD/MM/YY and Day of Week
*
* Call     : LDY #$FF              ; (optional: request leap-year flag)
*            JSR GETCENT2
*            DFB DD,MM,DOW,YY      ; Day (1..31), Month (1..12),
*                                  ; Expected DOW (0..6), Year (0..99)
* Outputs  : A = matching century (19..23), or $FF if none matches
*            Y = $FF (leap year) or $00 (common year) when input Y = $FF
* Clobbers : A, X, Y, $06-$07, $EB-$EE
*---------------------------------------------------------------
           DO      ]E_GETCENT2
GETCENT2   ENT
           STY     :LEAPREQ+1      ; save leap-year request flag ($FF = requested)
           JSR     GET4B           ; $EB=DD, $EC=MM, $ED=DOW, $EE=YY
           LDA     $ED             ; save expected DOW
           STA     :EXPDOW+1

           LDX     #FRSTCENT       ; start testing from century 19 (1900s)
:LOOP      STX     $ED             ; set candidate century CC in $ED
           JSR     :ENTRYZP        ; calculate DOW directly from $EB-$EE -> A
:EXPDOW    CMP     #$00            ; compare with expected DOW (self-modified)
           BEQ     :DONE           ; match found -> century is in X
           INX                     ; try next century
           CPX     #FRSTCENT+5     ; tested all 5 centuries (19..23)?
           BNE     :LOOP
           LDA     #$FF            ; no matching century found -> return $FF
           RTS

:DONE      LDY     $EE             ; reload YY for optional leap-year check
:LEAPREQ   LDA     #$00            ; check if caller passed Y = $FF at entry
           CMP     #$FF
           BNE     :RET            ; no -> return century immediately
           JSR     ISLEAP2         ; X = CC, Y = YY -> Carry = leap status
           LDY     #$00            ; default Y = $00 (common year)
           BCC     :RET
           DEY                     ; Carry = 1 -> Y = $FF (leap year)
:RET       TXA                     ; return found century in A
           RTS
           FIN


*===============================================================
* INTERNAL HELPER
*===============================================================

*---------------------------------------------------------------
* GET4B : Extract 4 inline bytes following the caller's JSR,
*         store them in $EB-$EE, and advance return address by 4.
*---------------------------------------------------------------
           DO      ]E_GETDAYOFW2+]E_GETCENT2
GET4B      PLA                     ; pop internal return addr (GETDAYOFW2/GETCENT2)
           STA     :RET1+1
           PLA
           STA     :RET1+2

           PLA                     ; pop caller's return addr (JSR - 1)
           STA     $06
           PLA
           STA     $07

           LDY     #1              ; copy 4 inline bytes into $EB..$EE
:LOOP      LDA     ($06),Y
           STA     $EB-1,Y
           INY
           CPY     #5
           BNE     :LOOP

           LDA     $06             ; advance caller return addr by 4 bytes
           CLC
           ADC     #4
           STA     $06
           BCC     :PUSH
           INC     $07
:PUSH      LDA     $07             ; push updated return addr back to stack
           PHA
           LDA     $06
           PHA
:RET1      JMP     $FFFF           ; resume execution in caller routine
           FIN
