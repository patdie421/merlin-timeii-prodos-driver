*
* HEXTODIGI
* Inputs:
*   A : number
* Outputs
*   Y : tens
*   X : units
           DO      ]E_HEXTODIGI
HEXTODIGI  ENT
* Loop version
           DO      1               ; loop version enabled
           LDY     #0
:LOOP
           CMP     #10
           BCC     :DONE
           SBC     #10
           INY
           BNE     :LOOP           ; JMP :LOOP
:DONE      TAX
           RTS
           FIN                     ; end loop version

* deterministic version
           DO      0               ; deterministic version disabled
           STA     AVAL            ; save A
* first divid A by 10 => tens (Y)
           LSR
           STA     BVAL
           LSR
           ADC     BVAL
           ROR
           LSR
           LSR
           ADC     BVAL
           ROR
           ADC     BVAL
           ROR
           LSR
           LSR
           STA     BVAL            ; now BVAL = org A / 10
           TAY                     ; Y = Tens
* tens x 10
           ASL
           ASL
           ASL
           CLC
           ADC     BVAL
           ADC     BVAL
           STA     BVAL            ; now BVAL = Tens x 10
* org A - BVAL => unit (X)
           LDA     AVAL
           SEC
           SBC     BVAL
           TAX                     ; X = Units
           RTS
           FIN                     ; deterministic loop version


* DIGITOHEX
* Inputs:
*   Y : tens
*   X : units
           DO      ]E_DIGITOHEX
DIGITOHEX  ENT
           STX     :UNIT           ; save unit
           STY     :TENS           ; save tens
           TYA                     ; tens * 10
           ASL
           ASL
           ASL
           CLC
           ADC     :TENS
           ADC     :TENS
           ADC     :UNIT           ; add unit to tens * 10
           RTS
:TENS      HEX     00
:UNIT      HEX     00
           FIN
