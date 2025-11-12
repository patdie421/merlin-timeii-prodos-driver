MEMINI1   ENT
          STX _SWPMMTMP
          STY _SWPMMTMP+1
          RTS
_SWPMMTMP HEX 00,00


MEMCPY    ENT
          JMP :MEMCPY
:SRC      DW $0000
:DST      DW $0000
:CNT      HEX 00
:MEMCPY
          STX :SAVX
          STY :SAVY

          LDA :SRC
          STA :_SRC+1
          LDA :SRC+1
          STA :_SRC+2

          LDA :DST
          STA :_DST+1
          LDA :DST+1
          STA :_DST+2

          LDY #0
          LDX :CNT
:LOOP
:_SRC     LDA $0000,Y    ; self modified
:_DST     STA $0000,Y    ; self modified
          INY
          DEX
          BNE :LOOP

          LDY :SAVY
          LDX :SAVX
          RTS
:SAVX     HEX 00
:SAVY     HEX 00


SWAPMEM   ENT
          JMP :SWAPMEM
:A        DW $0000
:B        DW $0000
:CNT      HEX 00
:SWAPMEM
          LDA :CNT
          STA MEMCPY+MEMCPY_CNT

          LDA :A         ; A -> TMP
          STA MEMCPY+MEMCPY_SRC
          LDA :A+1
          STA MEMCPY+MEMCPY_SRC+1
          LDA _SWPMMTMP
          STA MEMCPY+MEMCPY_DST
          LDA _SWPMMTMP+1
          STA MEMCPY+MEMCPY_DST+1
          JSR MEMCPY

          LDA :B         ; B -> A
          STA MEMCPY+MEMCPY_SRC
          LDA :B+1
          STA MEMCPY+MEMCPY_SRC+1
          LDA :A
          STA MEMCPY+MEMCPY_DST
          LDA :A+1
          STA MEMCPY+MEMCPY_DST+1
          JSR MEMCPY

          LDA _SWPMMTMP  ; TMP -> B
          STA MEMCPY+MEMCPY_SRC
          LDA _SWPMMTMP+1
          STA MEMCPY+MEMCPY_SRC+1
          LDA :B
          STA MEMCPY+MEMCPY_DST
          LDA :B+1
          STA MEMCPY+MEMCPY_DST+1
          JSR MEMCPY

          RTS
