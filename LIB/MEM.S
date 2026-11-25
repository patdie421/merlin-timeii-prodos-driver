           DO      ]E_MEMINI1
MEMINI1    ENT
           RTS
           FIN


           DO      ]E_MEMCPY
MCPZP      EQU     $EB
MEMCPY     ENT
           JMP     :MEMCPY
:SRC       DW      $0000
:DST       DW      $0000           ; must stay at :SRC+2
:CNT       HEX     00
:MEMCPY
           PHAXY                   ; X,Y preserved (A modified, as before)

           LDX     #3              ; copy :SRC,:DST (4 bytes) to SWPZP
:CP        LDA     :SRC,X
           STA     MCPZP,X
           DEX
           BPL     :CP

           LDX     :CNT            ; CNT = 0 => 256 bytes
           LDY     #0
:LOOP
           LDA     (MCPZP),Y       ; src
           STA     (MCPZP+2),Y     ; dst
           INY
           DEX
           BNE     :LOOP

           PLYXA
           RTS
           FIN


           DO      ]E_SWAPMEM1+E_SWAPMEM2
SWPZP      EQU     $EB             ; 4 bytes, zero page
SWAPMEM1   ENT
SWAPMEM2   ENT
           JMP     :SWAPMEM2
:A         DW      $0000
:B         DW      $0000           ; must stay at :A+2
:CNT       HEX     00
:SWAPMEM2
           PHAXY                   ; A,X,Y preserved

           LDX     #3              ; copy :A,:B (4 bytes) to SWPZP
:CP        LDA     :A,X
           STA     SWPZP,X
           DEX
           BPL     :CP

           LDX     :CNT            ; CNT = 0 => 256 bytes
           LDY     #0
:LOOP
           LDA     (SWPZP),Y       ; A[y] -> stack
           PHA
           LDA     (SWPZP+2),Y     ; B[y] -> A[y]
           STA     (SWPZP),Y
           PLA                     ; old A[y] -> B[y]
           STA     (SWPZP+2),Y
           INY
           DEX
           BNE     :LOOP

           PLYXA
           RTS
           FIN

