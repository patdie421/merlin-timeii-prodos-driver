           DO      0
           DO      ]E_ASCPRNT
ASCPRNT1   ENT
           JMP     :ASCPRNT1
:STRING    HEX     00,00
:ASCPRNT1
           LDA     :STRING
           STA     :C1+1
           LDA     :STRING+1
           STA     :C1+2
           LDY     #0
:C1        LDA     $FFFF,Y
           BEQ     :EXIT
           JSR     COUT
           INY
           JMP     :C1
:EXIT      RTS
           FIN
           FIN

           DO      1
           DO      ]E_ASCPRNT
********************************
ASCPRNT1   ENT
*
* print a zero terminated string
*
* in: ASCPRNT1+3, ASCPRNT1+4 - string address
*     (it is the operand of the LDA below)
* out: -
* chars are sent to COUT as is (bit 7 must be 1)
* A,Y modified, X untouched (COUT must preserve it)
* 255 chars max, then silent stop
* self modified code : RAM only, not reentrant
*
********************************
           LDY     #0              ; +0..+1
:C1        LDA     $FFFF,Y         ; +2 opcode, +3/+4 = string address
           BEQ     :EXIT           ; $00 : end of string
           JSR     COUT
           INY
           BNE     :C1             ; Y wraps to 0 after 255 chars : stop
:EXIT      RTS
           FIN
           FIN
