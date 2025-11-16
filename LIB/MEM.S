          DO ]E_MEMINI1
MEMINI1   ENT
          STX _SWPMMTMP
          STY _SWPMMTMP+1
          RTS
_SWPMMTMP HEX 00,00
          FIN


          DO ]E_MEMCPY
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
:_SRC     LDA $FFFF,Y    ; self modified
:_DST     STA $FFFF,Y    ; self modified
          INY
          DEX
          BNE :LOOP

          LDY :SAVY
          LDX :SAVX
          RTS
:SAVX     HEX 00
:SAVY     HEX 00
          FIN



MCP2SRC   EQU 1
MCP2DST   EQU 4

          DO ]E_MEMCPY2+]E_SWAPMEM1
* DO ]E_MEMCPY2
MEMCPY2   ENT
          PHAXY

          LDY #0
MCP2PARS  ENT
:LOOP
:_SRC     LDA $FFFF,Y    ; self modified
:_DST     STA $FFFF,Y    ; self modified
          INY
          DEX
          BNE :LOOP

          PLYXA
          RTS
          FIN


          DO ]E_SWAPMEM
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
          FIN


          DO ]E_SWAPMEM1
SWAPMEM1  ENT
          JMP :SWAPMEM1
:A        DW $0000
:B        DW $0000
:CNT      HEX 00
:SWAPMEM1
          PHAXY

          LDA :A         ; A -> TMP
          STA MCP2PARS+MCP2SRC
          LDA :A+1
          STA MCP2PARS+MCP2SRC+1
          LDA _SWPMMTMP
          STA MCP2PARS+MCP2DST
          LDA _SWPMMTMP+1
          STA MCP2PARS+MCP2DST+1

          LDX :CNT
          JSR MEMCPY2

          LDA :B         ; B -> A
          STA MCP2PARS+MCP2SRC
          LDA :B+1
          STA MCP2PARS+MCP2SRC+1
          LDA :A
          STA MCP2PARS+MCP2DST
          LDA :A+1
          STA MCP2PARS+MCP2DST+1
          JSR MEMCPY2

          LDA _SWPMMTMP  ; TMP -> B
          STA MCP2PARS+MCP2SRC
          LDA _SWPMMTMP+1
          STA MCP2PARS+MCP2SRC+1
          LDA :B
          STA MCP2PARS+MCP2DST
          LDA :B+1
          STA MCP2PARS+MCP2DST+1
          JSR MEMCPY2

          PLYXA

          RTS
          FIN
