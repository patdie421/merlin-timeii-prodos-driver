           LST     OFF
*
* DATE / TIME utils
*
FRSTCENT   EQU     19

*
* Calculate day of week
*
* Outputs:
*   A : day of week (0 = sunday, 1 = monday, ...)
*
           DO      0
           DO      ]E_GETDAYOFW
GETDAYOFW  ENT                     ; calculate day of week
           CLC
           BCC     :START
* inputs:
* CCYY/MM/DD
:DD        HEX     00              ; DAY
:MM        HEX     00              ; MONTH
:CC        HEX     00              ; CENTURY
:YY        HEX     00              ; YEAR

:START     LDX     :CC             ; check if leap year
           LDY     :YY             ; x and y contain the year
           JSR     ISLEAP
           BCS     :BXTIL
:NOTBXTIL                          ; get MONTH in standard table
           LDY     :MM
           DEY
           LDA     :MONTH,Y        ; lookup
           CLC
           BCC     :NEXT
:BXTIL
           LDY     :MM             ; get MONTH in leap table
           DEY
           LDA     :MONTHB,Y       ; lookup
:NEXT      STA     :M

* ALGORITHME : Zeller Congruence
* DoW = (K + Q + YY + M + DD + 2 + 5 * CC) % 7
* for date starting form Friday 15th october 1582
* calc k = int(YY / 4)
           LDA     :YY
           LSR                     ; division par 2
           LSR                     ; division par 2
           STA     :K
* calc q = int(CC / 4)
           LDA     :CC
           LSR
           LSR
           STA     :Q

* calc CC5 = 5 * CC = CC * 4 + CC (2 byte values)
* note: CC is one byte and maximum value of CC = 127
*       with this methode. Result is 2 bytes
           LDA     #0              ; data preparation
           STA     :CC5
           STA     :CC5+1
           LDA     :CC

           ASL                     ; x 2
           ASL                     ; x 2
           STA     :CC5
           LDA     #0
           ROL                     ; carry add to next byte
           STA     :CC5+1
           CLC
           LDA     :CC5
           ADC     :CC
           STA     :CC5
           LDA     #0
           ADC     :CC5+1
           STA     :CC5+1

* CALC
           CLC
           LDA     :K
           ADC     :Q
           ADC     #2
           ADC     :M
           ADC     :YY
           ADC     :DD

           ADC     :CC5
           STA     :RES
           LDA     #0
           ADC     :CC5+1
           STA     :RES+1

:LOOP                              ; RES modulus 7 by substraction
                                   ; 97 loop maximum, acceptable...
           SEC
           LDA     :RES
           SBC     #7
           STA     :RES
           LDA     :RES+1
           SBC     #0
           STA     :RES+1
           BNE     :LOOP
           LDA     :RES
           CMP     #7
           BCS     :LOOP
:END
           RTS
* month conversion tables
:MONTH     DFB     4,0,0,3,5,1,3,6,2,4,0,2
:MONTHB    DFB     3,6,0,3,5,1,3,6,2,4,0,2
* local variables
:K         HEX     00
:Q         HEX     00
:M         HEX     00
:CC5       HEX     00,00           ; 2 bytes
:RES       HEX     00,00           ; 2 bytes
           FIN
           FIN

           DO      1
           DO      ]E_GETDAYOFW
GETDAYOFW  ENT                     ; day of week (0 = sunday)
           CLC
           BCC     :START
* inputs: CCYY/MM/DD, 1 <= MM <= 12, DD <= 31
:DD        HEX     00              ; DAY
:MM        HEX     00              ; MONTH
:CC        HEX     00              ; CENTURY
:YY        HEX     00              ; YEAR
* out: A = day of week (0..6). X preserved (= CC), Y modified
:START
           LDA     :CC
           AND     #3
           TAX                     ; X = CC mod 4
           LDA     :YY
           LSR
           LSR                     ; K = YY / 4
           CLC
           ADC     :YY
           ADC     :DD
           ADC     :CENT,X         ; + century key
           STA     :S
           LDX     :CC             ; X = CC again (needed by GETCENT)
           LDY     :YY
           JSR     ISLEAP          ; C = 1 : leap year
           LDY     :MM
           LDA     :S
           BCC     :N
           CPY     #3
           BCS     :N              ; March or later
           ADC     #6              ; Jan/Feb of a leap year (C = 0 here)
:N         CLC
           ADC     :MONTH-1,Y      ; + month key (Y = 1..12)
           SEC
:L         SBC     #7              ; modulo 7 (A <= 171)
           BCS     :L
           ADC     #7
           RTS
:MONTH     DFB     4,0,0,3,5,1,3,6,2,4,0,2
:CENT      DFB     2,0,5,3         ; key for CC mod 4 = 0,1,2,3
:S         HEX     00
           FIN
           FIN
*
* Check if year (CCYY) is leap
*
* Inputs:
*   X : CC - century
*   Y : YY - year
* Outputs:
*   Cary flag : 0 not leap, 1 leap
*
           DO      0
           DO      ]E_ISLEAP
ISLEAP     ENT
           TYA
           BEQ     :CHECKC         ; when YY = 0 year can be leap
                                   ; or not. need, GO checking
                                   ; century
           AND     #%00000011      ; check multiple of 4
           BNE     :NO             ; shure not leap
           BCS     :YES            ; shure leap
:CHECKC
           TXA                     ; check century
           AND     #%00000011      ; every 400 years is leap
                                   ; ie century multiple of 4.
           BNE     :NO             ; Not multiple then not leap
:YES
           SEC                     ; CARRY = 1 : leap year
           RTS
:NO
           CLC                     ; CARRY = 0 : not leap year
           RTS
           FIN
           FIN

           DO      1
           DO      ]E_ISLEAP
ISLEAP     ENT
* in: X = CC (century), Y = YY (year). Carry not used on entry.
* out: C = 1 leap, C = 0 not leap. A modified, X,Y preserved
           TYA
           BNE     :Y4             ; YY <> 0 : multiple of 4 ?
           TXA                     ; YY = 0 : century multiple of 4 ?
:Y4        AND     #%00000011
           BNE     :NO
           SEC                     ; leap
           RTS
:NO        CLC
           RTS
           FIN
           FIN

           DO      ]E_GETCENT
*
* find century from date :DD/:MM/:YY and :DOW (Day Of Week)
* loop xx (in X) from 19 (1900) to 23 (2300)
* calc day of week (GETDAYOFWEEK) for :DD/:MM/xx:YY
* compare result with :DOW
* if match return yy in A
* not found after all loops return  #$FF in A
* in: :DD,:MM,:DOW,:YY
* in: Y = FF then also calc leap
* out: A = century
* out: Y = 0 not leap / Y = FF leap
* modified: X,Y
*
           DO      0
GETCENT    ENT
           CLC
           BCC     :START
:DD        HEX     00              ; _DD: DAY
:MM        HEX     00              ; _MM: MONTH
:DOW       HEX     00              ; _DW: DAY OF WEEK
:YY        HEX     00              ; _YY: YEAR
:START
           LDA     :DD
           STA     GETDAYOFW+_DD
           LDA     :MM
           STA     GETDAYOFW+_MM
           LDA     :YY
           STA     GETDAYOFW+_YY

           LDX     #FRSTCENT
:LOOP
           STX     GETDAYOFW+_CC
           JSR     GETDAYOFW
           CMP     :DOW
           BEQ     :DONE
           INX
           CPX     #FRSTCENT+4+1   ; 4=loop +1 for good comparaison
           BNE     :LOOP
           LDA     #$FF
           RTS
:DONE
           CPY     #$FF
           BNE     :RET
           LDY     :YY
           JSR     ISLEAP
           BCS     :LEAP
:NOLEAP    LDY     #00
           BCC     :RET
:LEAP      LDY     #$FF
:RET       TXA
           RTS
           FIN
           FIN

           DO      1
GETCENT    ENT
           CLC
           BCC     :START
:DD        HEX     00              ; DAY
:MM        HEX     00              ; MONTH
:DOW       HEX     00              ; DAY OF WEEK
:YY        HEX     00              ; YEAR
:START
* copy DD,MM,(DOW),YY to GETDAYOFW params DD,MM,(CC),YY.
* DOW lands in the CC slot : harmless, CC is set from X
* at the start of every :LOOP turn. Loop = 11 bytes.
           STY     :OPT            ; Y = $FF : also compute leap (Y is modified below)
           LDX     #3
:CP        LDA     :DD,X
           STA     GETDAYOFW+_DD,X ; DOW lands in the CC slot, overwritten below
           DEX
           BPL     :CP
           LDX     #FRSTCENT
:LOOP
           STX     GETDAYOFW+_CC
           JSR     GETDAYOFW       ; X preserved
           CMP     :DOW
           BEQ     :DONE
           INX
           CPX     #FRSTCENT+5     ; centuries 19..23
           BNE     :LOOP
           LDA     #$FF            ; not found
           RTS
:DONE
           LDA     :OPT
           CMP     #$FF
           BNE     :RET
           LDY     :YY
           JSR     ISLEAP          ; X = century
           BCS     :LEAP
:NOLEAP    LDY     #00
           BCC     :RET
:LEAP      LDY     #$FF
:RET       TXA
           RTS
:OPT       HEX     00
           FIN
