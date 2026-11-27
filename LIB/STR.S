           DO      ]E_STRPRINT
********************************
STRPRINT   ENT
*
* print a Pascal string
* 
* in: STRPRINT+3, STRPRINT+4 - string address
* out: -
* A,X,Y backuped on stack and restored
* zero page $ED/$EE backuped on stack and restored
*
********************************
           JMP     :STRPRINT
           HEX     00
           HEX     00
:STRPRINT
           PHAXY                   ; save A,X and Y to stack
           PHZPP   $ED

           LDY     #0              ; string offset

           LDA     STRPRINT+3      ; point to string
           STA     $ED
           LDA     STRPRINT+4
           STA     $ED+1

           LDA     ($ED),Y         ; get string size
           BEQ     :EXIT           ; if 0 exit
           TAX                     ; string counter
           INY                     ; to first char
:LOOP
           LDA     ($ED),Y
           ORA     #%10000000      ; to Apple "normal" char
           JSR     COUT
           INY
           DEX
           BNE     :LOOP
:EXIT
           PLZPP   $ED
           PLYXA
           RTS
           FIN


           DO      0
           DO      ]E_STRCMP1
********************************
STRCMP1    ENT
*
* compare (equal only) 2 Pascal strings
*
* in: STRCMP1+3, STRCMP1+4 - first string address
* in: STRCMP1+5, STRCMP1+6 - second string address
* out: Carry flag - clear => equal, set => not equal
* A,X,Y backuped on stack and restored
*
* self modified code
*
********************************
           JMP     :STRCMP1
:STR1      HEX     00,00
:STR2      HEX     00,00
:STRCMP1
           PHAXY
* modifying code to set str addresses
           LDA     :STR1
           STA     :_STR11+1
           STA     :_STR12+1
           LDA     :STR1+1
           STA     :_STR11+2
           STA     :_STR12+2
           LDA     :STR2
           STA     :_STR21+1
           LDA     :STR2+1
           STA     :_STR21+2
* self modified section
:_STR11    LDY     $FFFF
:LOOP
:_STR12    LDA     $FFFF,Y
:_STR21    CMP     $FFFF,Y
* end self modified section
           BNE     :NOTEQU
:NEXT      DEY
           BNE     :LOOP
           CLC                     ; equal
           JMP     :EXIT
:NOTEQU
           SEC                     ; not equal
:EXIT
           PLYXA

           RTS
           FIN
           FIN

           DO      1
           DO      ]E_STRCMP1
********************************
STRCMP1    ENT
*
* compare (equal only) 2 Pascal strings, length byte included
*
* in: :STR1 (+3,+4) - first string address
* in: :STR2 (+5,+6) - second string address (must stay at :STR1+2)
* out: Carry clear => equal, set => not equal
* length of STR1 must be <= 127
* A,X,Y preserved, $EB-$EE saved and restored (PHZP4B/PLZP4B)
* needs PHAXY / PLYXA / PHZP4B / PLZP4B (MEM.H)
*
********************************
           JMP     :STRCMP1
:STR1      HEX     00,00
:STR2      HEX     00,00
:STRCMP1
           PHAXY
           PHZP4B  $EB             ; save $EB-$EE

           LDX     #3              ; STR1 -> $EB/$EC, STR2 -> $ED/$EE
:CP        LDA     :STR1,X
           STA     $EB,X
           DEX
           BPL     :CP

           LDY     #0
           LDA     ($EB),Y         ; length of STR1
           TAY                     ; compare from last char down to index 0
:LOOP      LDA     ($EB),Y
           CMP     ($ED),Y
           BNE     :NOTEQU
           DEY
           BPL     :LOOP           ; index 0 included : lengths must match
           CLC                     ; equal
           BCC     :EXIT           ; always taken
:NOTEQU    SEC                     ; not equal
:EXIT      PLZP4B  $EB             ; restore, carry preserved
           PLYXA                   ; PLA/TAY/TAX do not touch carry
           RTS
           FIN
           FIN

           DO      0
           DO      ]E_STRSWITH1
********************************
STRSWITH1  ENT
*
* check if string start with sub-string
* 
* in: STRCMP1+3, STRCMP1+4 - first string address
* in: STRCMP1+5, STRCMP1+6 - string address to find
* out: -
* A,X,Y mofified
* zero page $ED/$EE backuped on stack and restored
*
********************************
           JMP     :STRSWITH1
:STRING    HEX     00,00
:START     HEX     00,00
:STRSWITH1
           PHZPP   $EB
           PHZPP   $ED

           LDA     :STRING
           STA     $EB
           LDA     :STRING+1
           STA     $EC
           LDA     :START
           STA     $ED
           LDA     :START+1
           STA     $EE

           LDY     #0
           LDA     ($ED),Y
           TAX
           INY
:LOOP
           LDA     ($ED),Y
           CMP     ($EB),Y
           BEQ     :NEXT
           SEC
           JMP     :EXIT
:NEXT
           INY
           DEX
           BNE     :LOOP
           CLC
:EXIT
           PLZPP   $ED
           PLZPP   $EB
           RTS
           FIN
           FIN

           DO      1
           DO      ]E_STRSWITH1
********************************
STRSWITH1  ENT
*
* check if a Pascal string starts with a sub-string
*
* in: :STRING (+3,+4) - string address
* in: :START  (+5,+6) - prefix address (must stay at :STRING+2)
* out: Carry clear => string starts with prefix, set => not
*      (empty prefix => match, prefix longer than string => not)
* A,X,Y modified, $EB-$EE saved and restored (PHZP4B/PLZP4B)
* needs PHZP4B / PLZP4B (MEM.H)
*
********************************
           JMP     :STRSWITH1
:STRING    HEX     00,00
:START     HEX     00,00
:STRSWITH1
           PHZP4B  $EB             ; save $EB-$EE

           LDX     #3              ; STRING -> $EB/$EC, START -> $ED/$EE
:CP        LDA     :STRING,X
           STA     $EB,X
           DEX
           BPL     :CP

           LDY     #0
           LDA     ($ED),Y         ; prefix length
           TAX
           BEQ     :OK             ; empty prefix : match
           CMP     ($EB),Y         ; prefix length vs string length
           BEQ     :GO
           BCS     :EXIT           ; prefix longer than string : C=1
:GO        SEC                     ; C=1 = mismatch, kept by INY/LDA/EOR/DEX
:LOOP      INY
           LDA     ($ED),Y
           EOR     ($EB),Y
           BNE     :EXIT           ; mismatch, C=1
           DEX
           BNE     :LOOP
:OK        CLC                     ; match
:EXIT      PLZP4B  $EB             ; restore, carry preserved
           RTS
           FIN
           FIN

           DO      1
           DO      ]E_STREWITH1
********************************
STREWITH1  ENT
*
* check if string end with sub-string
* 
* in: STRCMP1+3, STRCMP1+4 - first string address
* in: STRCMP1+5, STRCMP1+6 - string address to find
* out: -
* A,X,Y mofified
* zero page $ED/$EE backuped on stack and restored
*
********************************
           JMP     :STREWITH1
:CMPES1    HEX     00,00
:CMPES2    HEX     00,00
:STREWITH1
           PHZPP   $EB
           PHZPP   $ED

           LDA     :CMPES1
           STA     $EB
           LDA     :CMPES1+1
           STA     $EC
           LDA     :CMPES2
           STA     $ED
           LDA     :CMPES2+1
           STA     $EE
           LDY     #0
           LDA     ($EB),Y
           STA     :LSTR1
           LDA     ($ED),Y
           STA     :LSTR2
           TAX
:LOOP
           LDY     :LSTR1
           LDA     ($EB),Y
           LDY     :LSTR2
           CMP     ($ED),Y
           BNE     :NOTEQU
           DEX
           BEQ     :EQU
           DEC     :LSTR1
           DEC     :LSTR2
           JMP     :LOOP
:EQU
           CLC
           JMP     :EXIT
:NOTEQU
           SEC
:EXIT
           PLZPP   $ED
           PLZPP   $EB
           RTS
:LSTR1     HEX     00
:LSTR2     HEX     00
           FIN
           FIN

           DO      1
           DO      ]E_STREWITH1
********************************
STREWITH1  ENT
*
* check if a Pascal string ends with a sub-string
*
* in: :CMPES1 (+3,+4) - string address
* in: :CMPES2 (+5,+6) - suffix address (must stay at :CMPES1+2)
* out: Carry clear => string ends with suffix, set => not
*      (empty suffix => match, suffix longer than string => not)
* A,X,Y modified, $EB-$EE saved and restored (PHZP4B/PLZP4B)
* needs PHZP4B / PLZP4B (MEM.H)
*
********************************
           JMP     :STREWITH1
:CMPES1    HEX     00,00
:CMPES2    HEX     00,00
:STREWITH1
           PHZP4B  $EB             ; save $EB-$EE

           LDX     #3              ; CMPES1 -> $EB/$EC, CMPES2 -> $ED/$EE
:CP        LDA     :CMPES1,X
           STA     $EB,X
           DEX
           BPL     :CP

           LDY     #0
           LDA     ($ED),Y         ; suffix length
           TAX                     ; X = char counter
           BEQ     :OK             ; empty suffix : match
           LDA     ($EB),Y         ; string length
           SEC
           SBC     ($ED),Y         ; offset = string length - suffix length
           BCC     :FAIL           ; suffix longer than string
           CLC
           ADC     $EB             ; $EB/$EC += offset
           STA     $EB
           BCC     :GO
           INC     $EB+1
:GO        SEC                     ; C=1 = mismatch, kept by INY/LDA/EOR/DEX
:LOOP      INY
           LDA     ($ED),Y         ; suffix char Y
           EOR     ($EB),Y         ; string char at offset + Y
           BNE     :EXIT           ; mismatch, C=1
           DEX
           BNE     :LOOP
:OK        CLC                     ; match
           BCC     :EXIT           ; always taken
:FAIL      SEC                     ; refused
:EXIT      PLZP4B  $EB             ; restore, carry preserved
           RTS
           FIN
           FIN

           DO      0
           DO      ]E_STRCPY1
********************************
STRCPY1    ENT
*
* copy a string to an other
* 
* in: STRCMP1+3, STRCMP1+4 - source string address
* in: STRCMP1+5, STRCMP1+6 - dest string address
* out: -
* A,X,Y mofified
*
********************************
           JMP     :STRCPY1
:S1        HEX     00,00
:S2        HEX     00,00
:OPT       HEX     00
:STRCPY1
           LDA     :S1
           STA     :C11+1
           LDA     :S1+1
           STA     :C11+2
           LDA     :S2
           STA     :C21+1
           LDA     :S2+1
           STA     :C21+2
           LDY     #0
:LOOP
:C11       LDA     $FFFF,Y
           CPY     #0
           BNE     :NEXT
           TAX
           INX
           JMP     :C21
:NEXT
           PHA
           LDA     :OPT
:O1
           CMP     #1
           BNE     :O2
           PLA
           ORA     #%10000000
           JMP     :C21
:O2
           CMP     #2
           BNE     :O3
           PLA
           AND     #%01111111
           JMP     :C21
:O3        PLA

:C21       STA     $FFFF,Y
           INY
           DEX
           BNE     :LOOP
           RTS
           FIN
           FIN

           DO      1
           DO      ]E_STRCPY1
********************************
STRCPY1    ENT
*
* copy a Pascal string to another (SOURCE first, then DEST)
*
* in: :S1  (+3,+4) - source string address
* in: :S2  (+5,+6) - destination address (must stay at :S1+2)
* in: :OPT (+7)    - 0 : raw copy
*                    1 : bit 7 forced to 1 (chars only, not the length byte)
*                    2 : bit 7 forced to 0 (chars only, not the length byte)
* out: -
* The capacity of the destination buffer is NOT checked
* A,X,Y modified, $EB-$EE saved and restored (PHZP4B/PLZP4B)
* needs PHZP4B / PLZP4B (MEM.H)
*
********************************
           JMP     :STRCPY1
:S1        HEX     00,00
:S2        HEX     00,00
:OPT       HEX     00
:STRCPY1
           PHZP4B  $EB             ; save $EB-$EE

           LDX     #3              ; S1 -> $EB/$EC, S2 -> $ED/$EE
:CP        LDA     :S1,X
           STA     $EB,X
           DEX
           BPL     :CP

           LDY     #0
           LDA     ($EB),Y         ; length byte copied as is
           STA     ($ED),Y
           TAY                     ; Y = length, copy from the end
           BEQ     :EXIT           ; empty string
           LDX     :OPT
:LOOP      LDA     ($EB),Y
           CPX     #1
           BNE     :N2
           ORA     #%10000000
           BNE     :ST             ; always taken (result <> 0)
:N2        CPX     #2
           BNE     :ST
           AND     #%01111111
:ST        STA     ($ED),Y
           DEY
           BNE     :LOOP
:EXIT      PLZP4B  $EB             ; restore
           RTS
           FIN
           FIN


           D0      0
           DO      ]E_STRCAT1
********************************
STRCAT1    ENT
*
* copy a string to an other
* 
* in: STRCMP1+3, STRCMP1+4 - source string address
* in: STRCMP1+5, STRCMP1+6 - dest string address
* out: -
* A,X,Y mofified
* zero page $ED/$EE backuped on stack and restored
*
********************************
           JMP     :STRCAT
:DST       HEX     00,00
:SRC       HEX     00,00
:STRCAT
           PHZPP   $EB
           PHZPP   $ED

           LDA     :DST
           STA     $EB
           LDA     :DST+1
           STA     $EB+1

           LDA     :SRC
           STA     $ED
           LDA     :SRC+1
           STA     $ED+1

           LDY     #$00
           LDA     ($EB),Y
           CLC
           ADC     #$01
           STA     :PTRDST         ; pointer to the last+1 pos
           LDA     #$01
           STA     :PTRSRC         ; pointer to the firt char
           LDA     ($ED),Y         ; nb char counter
           TAX
:LOOP
           LDY     :PTRSRC         ; read src char
           LDA     ($ED),Y
           LDY     :PTRDST         ; write to dest
           STA     ($EB),Y
           INC     :PTRSRC         ; src pointer + 1
           INC     :PTRDST         ; src pointer + 1
           DEX
           BNE     :LOOP
           DEC     :PTRDST
           LDA     :PTRDST         ; update string
           LDY     #$00
           STA     ($EB),Y
:EXIT
           PLZPP   $ED
           PLZPP   $EB
           RTS
:PTRSRC    HEX     00
:PTRDST    HEX     00
           FIN
           FIN

           DO     1
           DO      ]E_STRCAT1
********************************
STRCAT1    ENT
*
* append a Pascal string (SRC) to another (DST)
*
* in: :DST (+3,+4) - destination string address
* in: :SRC (+5,+6) - source string address (must stay at :DST+2)
* out: Carry clear => done, set => refused (DST length + SRC length > 255,
*      DST unchanged)
* The capacity of the DST buffer is NOT checked (255 max here)
* A,X,Y modified, $EB-$EE saved and restored (PHZP4B/PLZP4B)
* needs PHZP4B / PLZP4B (MEM.H)
*
********************************
           JMP     :STRCAT
:DST       HEX     00,00
:SRC       HEX     00,00
:STRCAT
           PHZP4B  $EB             ; save $EB-$EE

           LDX     #3              ; DST -> $EB/$EC, SRC -> $ED/$EE
:CP        LDA     :DST,X
           STA     $EB,X
           DEX
           BPL     :CP

           LDY     #0
           LDA     ($ED),Y         ; n = SRC length
           BEQ     :OK             ; empty source : nothing to do
           TAX                     ; X = char counter
           LDA     ($EB),Y         ; L = DST length
           PHA
           TXA
           CLC
           ADC     ($EB),Y         ; L + n
           BCS     :OVF            ; > 255 : refused
           STA     ($EB),Y         ; new DST length
           PLA                     ; L (C stays 0)
           ADC     $EB             ; $EB/$EC = DST + L
           STA     $EB
           BCC     :C2
           INC     $EB+1
:C2        INY                     ; Y = 1 .. n
           LDA     ($ED),Y         ; SRC char Y
           STA     ($EB),Y         ; DST index L + Y
           DEX
           BNE     :C2
:OK        CLC                     ; done
           BCC     :EXIT
:OVF       PLA                     ; drop L (C stays 1)
:EXIT      PLZP4B  $EB             ; restore, carry preserved
           RTS
           FIN
           FIN

