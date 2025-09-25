          DO ]E_HEXTODIGI
*
* HEXTODIGI
* Inputs:
*   A : number
* Outputs
*   Y : tens
*   X : units
HEXTODIGI
          DO 1
          LDY #0
:LOOP
          CMP #10
          BCC :DONE
          SBC #10
          INY
          RJMP :LOOP
:DONE     TAX
          RTS

          ELSE

* first divid by 10
          STA AVAL       ; save A
                         ; first A / 10
          LSR
          STA BVAL
          LSR
          ADC BVAL
          ROR
          LSR
          LSR
          ADC BVAL
          ROR
          ADC BVAL
          ROR
          LSR
          LSR
          STA BVAL       ; BVAL = A / 10
          TAY            ; Y = Tens
* tens x 10
          ASL
          ASL
          ASL
          CLC
          ADC BVAL
          ADC  BVAL
          STA BVAL       ; BVAL = Tens x 10
* org A - BVAL => unit
          LDA AVAL
          SEC
          SBC BVAL
          TAX            ; X = Units
          RTS
          FIN

          FIN


          DO ]E_DIGITOHEX
* DIGITOHEX
* Inputs:
*   Y : tens
*   X : units
DIGITOHEX
          STX :UNIT
          STY :TENS
          TYA
          ASL
          ASL
          ASL
          CLC
          ADC :TENS
          ADC  :TENS
          ADC :UNIT
          RTS
:TENS     HEX 00
:UNIT     HEX 00
          FIN
