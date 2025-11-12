          LST OFF
*
* DATE / TIME utils
*
FRSTCENT  EQU 19

*
* Calculate day of week
*
* Outputs:
*   A : day of week (0 = sunday, 1 = monday, ...)
*
          DO ]E_GETDAYOFW
GETDAYOFW ENT            ; calculate day of week
          CLC
          BCC :START
* inputs
* CCYY/MM/DD
:DD       HEX 00         ; DAY
:MM       HEX 00         ; MONTH
:CC       HEX 00         ; CENTURY
:YY       HEX 00         ; YEAR

:START    LDX :CC        ; check if leap year
          LDY :YY        ; x and y contain the year
          JSR ISBXTILE
          BCS :BXTIL
:NOTBXTIL                ; get MONTH in standard table
          LDY :MM
          DEY
          LDA :MONTH,Y   ; lookup
          CLC
          BCC :NEXT
:BXTIL
          LDY :MM        ; get MONTH in leap table
          DEY
          LDA :MONTHB,Y  ; lookup
:NEXT     STA :M

* ALGORITHME : Zeller Congruence
* DoW = (K + Q + YY + M + DD + 2 + 5 * CC) % 7
* for date starting form Friday 15th october 1582
* calc k = int(YY / 4)
          LDA :YY
          LSR            ; division par 2
          LSR            ; division par 2
          STA :K
* calc q = int(CC / 4)
          LDA :CC
          LSR
          LSR
          STA :Q

* calc CC5 = 5 * CC = CC * 4 + CC (2 byte values)
* note: CC is one byte and maximum value of CC = 127
*       with this methode. Result is 2 bytes
          LDA #0         ; data preparation
          STA :CC5
          STA :CC5+1
          LDA :CC

          ASL            ; x 2
          ASL            ; x 2
          STA :CC5
          LDA #0
          ROL            ; carry add to next byte
          STA :CC5+1
          CLC
          LDA :CC5
          ADC :CC
          STA :CC5
          LDA #0
          ADC :CC5+1
          STA :CC5+1

* CALC
          CLC
          LDA :K
          ADC :Q
          ADC #2
          ADC :M
          ADC :YY
          ADC :DD

          ADC :CC5
          STA :RES
          LDA #0
          ADC :CC5+1
          STA :RES+1

:LOOP                    ; RES modulus  7  by substraction
                         ; 97 loop maximum, acceptable...
          SEC
          LDA :RES
          SBC #7
          STA :RES
          LDA :RES+1
          SBC #0
          STA :RES+1
          BNE :LOOP
          LDA :RES
          CMP #7
          BCS :LOOP
:END
          RTS
* month conversion tables
:MONTH    DFB 4,0,0,3,5,1,3,6,2,4,0,2
:MONTHB   DFB 3,6,0,3,5,1,3,6,2,4,0,2
* local variables
:K        HEX 00
:Q        HEX 00
:M        HEX 00
:CC5      HEX 00,00      ; 2 bytes
:RES      HEX 00,00      ; 2 bytes
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
          DO ]E_ISBXTILE
ISBXTILE  ENT
          TYA
          BEQ :CHECKC    ; when YY = 0 year can be leap
                         ; or not. need, GO checking
                         ; century
          AND #%00000011 ; check multiple of 4
          BNE :NO        ; shure not leap
          BCS :YES       ; shure leap
:CHECKC
          TXA            ; check century
          AND #%00000011 ; every 400 years is leap
                         ; ie century multiple of 4.
          BNE :NO        ; Not multiple then not leap
:YES
          SEC            ; CARRY = 1 : leap year
          RTS
:NO
          CLC            ; CARRY = 0 : not leap year
          RTS
          FIN


          DO ]E_GETCENT
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
GETCENT   ENT
          CLC
          BCC :START
:DD       HEX 00         ; _DD: DAY
:MM       HEX 00         ; _MM: MONTH
:DOW      HEX 00         ; _DW: DAY OF WEEK
:YY       HEX 00         ; _YY: YEAR
:START
          LDA :DD
          STA GETDAYOFW+_DD
          LDA :MM
          STA GETDAYOFW+_MM
          LDA :YY
          STA GETDAYOFW+_YY

          LDX #FRSTCENT
:LOOP
          STX GETDAYOFW+_CC
          JSR GETDAYOFW
          CMP :DOW
          BEQ :DONE
          INX
          CPX #FRSTCENT+4+1
          BNE :LOOP
          LDA #$FF
          RTS
:DONE
          CPY #$FF
          BNE :RET
          LDY :YY
          JSR ISBXTILE
          BCS :LEAP
:NOLEAP   LDY #00
          BCC :RET
:LEAP     LDY #$FF
:RET      TXA
          RTS
          FIN
