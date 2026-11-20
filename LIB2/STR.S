****************************************************************
* PASCAL STRING LIBRARY v2 (APPLE II / 6502)
*
* Compact, bug-fixed string manipulation library using inline
* parameter passing (addresses follow the JSR instruction).
*
* Zero Page usage : $06-$07 (temp return ptr)
*                   $EB-$EC (1st string ptr / DST)
*                   $ED-$EE (2nd string ptr / SRC)
* Registers       : A, X, Y are clobbered by all routines.
****************************************************************


*---------------------------------------------------------------
* STRPRINT2 : Print a Pascal string using Apple II ROM COUT
*
* Call    : JSR STRPRINT2
*           DA  MYSTR           ; address of Pascal string
* Out     : None (high bit forced to 1 for Apple normal video)
* Clobbers: A, X, Y, $06-$07, $EB-$EC
*---------------------------------------------------------------
           DO      ]E_STRPRINT2
STRPRINT2  ENT
           JSR     GET1PTR         ; ($EB) <- MYSTR
           LDY     #0
           LDA     ($EB),Y         ; get string length
           BEQ     :EXIT           ; empty string -> nothing to print
           TAX                     ; X = character counter
           INY                     ; Y = 1 (index of 1st character)
:LOOP      LDA     ($EB),Y         ; read character
           ORA     #%10000000      ; set bit 7 (Apple normal text)
           JSR     COUT            ; output character via ROM
           INY                     ; next character
           DEX                     ; decrement counter
           BNE     :LOOP
:EXIT      RTS
           FIN


*---------------------------------------------------------------
* STRCMP2 : Compare two Pascal strings for exact equality
*
* Call    : JSR STRCMP2
*           DA  STR1,STR2       ; addresses of both strings
* Out     : Carry = 0 (equal)
*           Carry = 1 (not equal)
* Clobbers: A, Y, $06-$07, $EB-$EE
*---------------------------------------------------------------
           DO      ]E_STRCMP2
STRCMP2    ENT
           JSR     GET2PTR         ; ($EB) <- STR1, ($ED) <- STR2
           LDY     #0
           LDA     ($EB),Y         ; get len(STR1)
           CMP     ($ED),Y         ; compare with len(STR2)
           BNE     NOTEQU          ; different lengths -> not equal
           TAY                     ; Y = string length (loop counter)
           BNE     CMPLOOP         ; non-empty -> compare characters
           CLC                     ; both strings are empty -> equal
           RTS
           FIN


*---------------------------------------------------------------
* STRSWITH2 : Check if STR1 starts with prefix SUBSTR
*
* Call    : JSR STRSWITH2
*           DA  STR1,SUBSTR     ; main string, prefix to match
* Out     : Carry = 0 (STR1 starts with SUBSTR)
*           Carry = 1 (false)
* Clobbers: A, Y, $06-$07, $EB-$EE
*---------------------------------------------------------------
           DO      ]E_STRSWITH2
STRSWITH2  ENT
           JSR     GET2PTR         ; ($EB) <- STR1, ($ED) <- SUBSTR
           LDY     #0
           LDA     ($ED),Y         ; get len(SUBSTR)
           BEQ     EQU             ; empty prefix always matches
           CMP     ($EB),Y         ; compare len(SUBSTR) vs len(STR1)
           BEQ     :OKLEN          ; same length -> valid
           BCS     NOTEQU          ; len(SUBSTR) > len(STR1) -> false
:OKLEN     TAY                     ; Y = len(SUBSTR)
           BNE     CMPLOOP         ; jump to shared comparison loop
           FIN


*---------------------------------------------------------------
* STREWITH2 : Check if STR1 ends with suffix SUBSTR
*
* Call    : JSR STREWITH2
*           DA  STR1,SUBSTR     ; main string, suffix to match
* Out     : Carry = 0 (STR1 ends with SUBSTR)
*           Carry = 1 (false)
* Clobbers: A, X, Y, $06-$07, $EB-$EE
*---------------------------------------------------------------
           DO      ]E_STREWITH2
STREWITH2  ENT
           JSR     GET2PTR         ; ($EB) <- STR1, ($ED) <- SUBSTR
           LDY     #0
           LDA     ($ED),Y         ; get len(SUBSTR)
           BEQ     EQU             ; empty suffix always matches
           TAX                     ; save len(SUBSTR) in X
           LDA     ($EB),Y         ; get len(STR1)
           SEC
           SBC     ($ED),Y         ; A = len(STR1) - len(SUBSTR)
           BCC     NOTEQU          ; len(SUBSTR) > len(STR1) -> false
           JSR     ADDEB           ; advance ($EB) to start of suffix in STR1
           TXA
           TAY                     ; Y = len(SUBSTR)
           FIN


*---------------------------------------------------------------
* CMPLOOP : Shared backward character comparison loop
*           Used by STRCMP2, STRSWITH2, and STREWITH2
*
* In      : ($EB), ($ED) = pointers, Y = byte count to compare
* Out     : Carry = 0 (match), Carry = 1 (mismatch)
*---------------------------------------------------------------
           DO      ]E_STRCMP2+]E_STRSWITH2+]E_STREWITH2
CMPLOOP    LDA     ($EB),Y         ; compare characters from end to index 1
           CMP     ($ED),Y
           BNE     NOTEQU          ; mismatch found
           DEY
           BNE     CMPLOOP
EQU        CLC                     ; all characters matched
           RTS
NOTEQU     SEC                     ; strings differ
           RTS
           FIN


*---------------------------------------------------------------
* STRCPY2 : Copy SRC string to DST with optional bit-7 mask
*
* Call    : JSR STRCPY2
*           DA  DST,SRC         ; destination, source addresses
*           DFB OPT             ; 0 = raw copy (unchanged)
*                               ; 1 = Apple normal (force bit 7 = 1)
*                               ; 2 = standard ASCII (force bit 7 = 0)
* Out     : None
* Clobbers: A, X, Y, $06-$07, $EB-$EE
*---------------------------------------------------------------
           DO      ]E_STRCPY2
STRCPY2    ENT
           JSR     GET2PTR         ; ($EB) <- DST, ($ED) <- SRC
           LDY     #1              ; fetch inline OPT byte after addresses
           LDA     ($06),Y
           TSX                     ; adjust caller return address on stack
           INC     $0101,X         ; skip over the 1-byte OPT parameter
           BNE     :NOINC
           INC     $0102,X
:NOINC
           LDX     #$00            ; default ORA mask = $00 (no bit set)
           LDY     #$FF            ; default AND mask = $FF (no bit cleared)
           CMP     #1
           BNE     :CHK2
           LDX     #%10000000      ; OPT 1: set bit 7 ($80)
           BNE     :SETMSK         ; unconditional branch (X != 0)
:CHK2      CMP     #2
           BNE     :SETMSK
           LDY     #%01111111      ; OPT 2: clear bit 7 ($7F)
:SETMSK    STX     :ORA+1          ; self-modify masks in copy loop
           STY     :AND+1

           LDY     #0
           LDA     ($ED),Y         ; read len(SRC)
           STA     ($EB),Y         ; write len(DST)
           BEQ     :EXIT           ; empty string -> done
           TAY                     ; Y = character count
:LOOP      LDA     ($ED),Y         ; copy backward from len to 1
:ORA       ORA     #$00            ; apply high-bit set mask (self-modified)
:AND       AND     #$FF            ; apply high-bit clear mask (self-modified)
           STA     ($EB),Y
           DEY
           BNE     :LOOP
:EXIT      RTS
           FIN


*---------------------------------------------------------------
* STRCAT2 : Append SRC string to the end of DST string
*
* Call    : JSR STRCAT2
*           DA  DST,SRC         ; destination (modified), source
* Out     : None (Note: total length must not exceed 255 chars)
* Clobbers: A, X, Y, $06-$07, $EB-$EE
*---------------------------------------------------------------
           DO      ]E_STRCAT2
STRCAT2    ENT
           JSR     GET2PTR         ; ($EB) <- DST, ($ED) <- SRC
           LDY     #0
           LDA     ($ED),Y         ; get len(SRC)
           BEQ     :EXIT           ; empty SRC -> nothing to append
           TAX                     ; save len(SRC) in X
           LDA     ($EB),Y         ; get current len(DST)
           PHA                     ; save original len(DST) on stack
           CLC
           ADC     ($ED),Y         ; compute new total length
           STA     ($EB),Y         ; update length byte of DST
           PLA                     ; restore original len(DST)
           JSR     ADDEB           ; advance ($EB) to end of original DST
           TXA
           TAY                     ; Y = len(SRC)
:LOOP      LDA     ($ED),Y         ; copy SRC chars backward into DST
           STA     ($EB),Y
           DEY
           BNE     :LOOP
:EXIT      RTS
           FIN


*===============================================================
* INTERNAL HELPERS
*===============================================================

*---------------------------------------------------------------
* ADDEB : Add 8-bit unsigned offset in A to 16-bit pointer ($EB/$EC)
*---------------------------------------------------------------
           DO      ]E_STREWITH2+]E_STRCAT2
ADDEB      CLC
           ADC     $EB
           STA     $EB
           BCC     :RTS
           INC     $EC             ; propagate carry to high byte
:RTS       RTS
           FIN

*---------------------------------------------------------------
* GET1PTR / GET2PTR : Extract 1 or 2 inline 16-bit addresses
*                     following the caller's JSR instruction,
*                     store them in ($EB) and ($ED), and fix
*                     the return address on the stack.
*---------------------------------------------------------------
           DO      ]E_STRPRINT2
GET1PTR    LDA     #2              ; 1 pointer = 2 inline bytes
           BNE     GETPTRS         ; unconditional branch
           FIN

GET2PTR    LDA     #4              ; 2 pointers = 4 inline bytes
GETPTRS    STA     :OFFSET+1       ; store inline byte count to skip
