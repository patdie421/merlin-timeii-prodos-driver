          DO ]E_PRINTDEC
]E_PRINT0  EQU 1
          FIN


          DO ]E_GET1NUM
GET1NUM                  ; Get one digit
          STX :XSAV
          STY :YSAV
:GCHAR    JSR BELL
:GCHAR1   JSR GETKEY
          CMP #$83       ; ctrl-c
          BNE :NEXT1
:ERREXIT  LDA #0
          SEC            ; cary as error flag
          RTS            ; exit with error
:NEXT1    CMP #"0"       ; #$B0
          BCC :GCHAR     ; <
          CMP #"9"+1     ; #$BA
          BCS :GCHAR     ; >=
:EXIT     JSR COUT
          LDX :XSAV
          LDY :YSAV
          CLC            ; no error
          RTS
:XSAV     DFB $00        ; local data reserved in code
:YSAV     DFB $00
:ASAV     DFB $00
          FIN


          DO ]E_GETNUMS
GETNUMS
          STX :XSAV
          STY :YSAV
          CMP #$0
          BNE :INIT1
          SEC
          RTS
:INIT1
          CMP #9         ; max 8 cars
          BCC :INIT2
          LDA #8         ; force to 8 chars
:INIT2    STA :AVAL      ; keep max car
          LDX $24        ; curent pos
          LDY :AVAL
          LDA #"_ "
:LOOP0    JSR COUT
          DEY
          BNE :LOOP0
          STX $24
          LDY #0
:GCHAR    JSR BELL
:GCHAR1   STY :BVAL
          JSR GETKEY
          LDY :BVAL
          CMP #$83       ; ctrl-c
          BNE :NEXT1
:ERREXIT  LDA #$0
          SEC            ; error
          RTS            ; exit with error
:NEXT1    CMP #$8D       ; return
          BEQ :EXIT      ; normal exit
          CMP #$88       ; left arrow
          BEQ :BSPACE
          CMP #$FF       ; backspace
          BNE :NEXT
          LDA #$88
:BSPACE
          CPY #$0
          BEQ :GCHAR
          DEY
          JSR COUT
          LDA #" "
          JSR COUT
          LDA #$88
          JSR COUT
          CLC
          BCC :GCHAR1
:NEXT     CPY :AVAL
          BEQ :GCHAR
          CMP #"0"       ; #$B0
          BCC :GCHAR     ; <
          CMP #"9"+1     ; #$BA
          BCS :GCHAR     ; >=
          JSR COUT

          AND #%00001111
          STA SGETNUMB,Y
          INY
          CLC
          BCC :GCHAR1
:EXIT
          TYA            ; a = nb car readed
          TAX
          STA :NBCARS
          AND #%00000001
          BEQ :EXIT1
:LOOP     DEY
          LDA SGETNUMB,Y
          STA SGETNUMB,X
          DEX
          CPY #0
          BNE :LOOP
          LDA #0
          STA SGETNUMB
          INC :NBCARS
:EXIT1
          CLC            ; no error
          LDX :XSAV
          LDY :YSAV
          LDA :NBCARS
          RTS
:NBCARS   DFB $00
:XSAV     DFB $00
:YSAV     DFB $00
:AVAL     HEX 00
:BVAL     HEX 00
SGETNUMB  DS 8
          FIN


          DO ]E_GETPATH
PATHMXC   EQU 64
GETPATH
          STX :XSAV
          STY :YSAV

          CMP #PATHMXC
          BCC :NEXT
          LDA #PATHMXC
:NEXT     STA :AVAL
:GCHAR    JSR BELL
:GCHAR1   STY :BVAL
          JSR GETKEY
          LDY :BVAL
          CMP #$83       ; ctrl-c
          BNE :NEXT1
:ERREXIT  LDA #$0
          SEC            ; error
          RTS            ; exit with error
:NEXT1    CMP #$8D       ; return
          BEQ :EXIT      ; normal exit
          CMP #$88       ; left arrow
          BEQ :BSPACE
          CMP #$FF       ; backspace
          BNE :NEXT2
          LDA #$88
:BSPACE
          CPY #$0
          BEQ :GCHAR
          DEY
          JSR COUT
          LDA #" "
          JSR COUT
          LDA #$88
          JSR COUT
          CLC
          BCC :GCHAR1
:NEXT2    CPY :AVAL
          BEQ :GCHAR
:NUM      CMP #"."       ; ".","/" are valid chars
          BCC :GCHAR
          CMP #"9"+1
          BCS :ALPHUP
          RJMP :OK
:ALPHUP   CMP #"A"
          BCC :GCHAR
          CMP #"Z"+1
          BCS :ALPHLO
          RJMP :OK
:ALPHLO   CMP #"a"
          BCC :GCHAR
          CMP #"z"+1
          BCS :OTHERS
          RJMP :OK
:OTHERS
          JMP :GCHAR
:OK       JSR COUT
          STA PATHSTR,Y
          INY
          CLC
          BCC :GCHAR1
:EXIT
          LDA #0
          STA PATHSTR,Y
          TYA            ; a = nb car readed
          STA PATHNBC
          CLC            ; no error
          LDX :XSAV
          LDY :YSAV
          RTS
:XSAV     DFB $00
:YSAV     DFB $00
:BVAL     HEX 00
:AVAL     HEX 00
PATHNBC   DFB $00
PATHSTR   DS PATHMXC+1   ; path string buffer
                         ; max prodos 64 bytes + zero
          FIN


          DO ]E_PRINTDEC
PRINTDEC
          STX :XSAV
          STY :YSAV
          STA :ASAV
          STA :BIN
          SED
          LDA #$0
          STA :BCD
          LDX #8
:CNVBIT   ASL :BIN
          LDA :BCD
          ADC :BCD
          STA :BCD
          DEX
          BNE :CNVBIT
          CLD

          LDA :BCD
          JSR PRBYTE

          LDA :ASAV
          LDX :XSAV
          LDY :YSAV
          RTS
:XSAV     DFB $00
:YSAV     DFB $00
:ASAV     DFB $00
:BIN      DFB $00
:BCD      DFB $00
          FIN


          DO ]E_PRINT0
*
* print a zero terminated string
*   string address is after JSR instruction
*
]PTR      EQU $EB
]STRPTR   EQU $ED
PRINT0    STX :XSAV
          STY :YSAV
          STA :ASAV
* pull return address form stack
          PLA            ; get low
          STA ]PTR
          PLA            ; get high
          STA ]PTR+1
* string address is in 2 next bytes after JSR
          INC ]PTR
          BNE :NEXT
          INC ]PTR+1
* make pointer on string
:NEXT     LDY #1
          LDA (]PTR),Y
          STA ]STRPTR+1
          DEY            ; Y=0
          LDA (]PTR),Y
          STA ]STRPTR
* now we can print eatch char on the zero terminated string
* note at this point Y=0
:LOOP
          LDA (]STRPTR),Y
          BEQ :EXIT      ; 0 of end of string
          ORA #%10000000
          JSR COUT
          INY
          CLC            ; relative
          BCC :LOOP      ; jump

:EXIT     CLC            ; prepare for add
          LDA ]PTR       ; low address byte

          ADC #$1        ; address after ptr + 1
                         ; address should by "stack pop"
                         ; +2 but rts add 1 to
                         ; address (see 6502 docs)
          TAX            ; save low

          LDA ]PTR+1     ; high address byte
          ADC #$0        ; to add carry only
          PHA            ; push high first

          TXA            ; retrieve low
          PHA            ; push low

          LDA :ASAV      ; restore all register
          LDY :YSAV
          LDX :XSAV
          RTS

:XSAV     DFB $00        ; local data reserved in code
:YSAV     DFB $00
:ASAV     DFB $00
          FIN
