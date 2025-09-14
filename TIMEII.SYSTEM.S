          LST OFF

          DSK TIMEII.SYSTEM
          TYP $FF

DEBUG     EQU 0

RWRAM1    EQU $C08B      ; R/W RAM bank 1
ROMIN2    EQU $C082      ; Rom no write

OPCJMPA   EQU $4C        ; JMP ABSOLUTE instruction

* NUMSLOT EQU 7
MM        EQU 0

* zero page temporary data
TMP       EQU $EB
TMP1      EQU $EB
TMP2      EQU $EC
PTR       EQU $EB
PTR2      EQU $ED

OPNBUFF   EQU $4000
BUFF      EQU $4800

* System Calls
GET_TIME  EQU $82

RELOCORG  EQU $1000
SYSORG    EQU $2000
SYSSIZE   EQU $BF00-SYSORG


          USE MONITOR.H
          USE MACRO.H
          USE PRODOS.H
          DO DEBUG
          USE PRINT.H
          FIN
          USE TIMEII.H


          ORG SYSORG

STAR
          JSR RELOC

* Check clock driver installed
          LDA MACHID
          AND #$01
          BEQ CONTINUE
          JMP NEXTSYS
CONTINUE
          JSR CHKSLOTS
          CMP #$FF       ; FF => not slot found
          STA SLOT
* load driver
          JSR INSTDRV
NEXTSYS
          JSR GETMYNAME
          JMP EXENXTSYS


GETMYNAME
* get my name
          LDX PATHNAME
          BEQ :ERREXIT
          LDY #0         ; Y = length
:LOOP1
          LDA PATHNAME,X
          AND #%01111111 ; ignore high bit
          CMP #'/'
          BEQ :GETNAME
          INY
          DEX
          BNE :LOOP1
:GETNAME
          CPY #0
          BEQ :ERREXIT
          STY MYNAME
          LDA #0
          STA MYNAME+2
          LDX PATHNAME
:LOOP2
          LDA PATHNAME,X
          AND #%01111111 ; ignore high bit
          STA MYNAME,Y
          DEX
          DEY
          BNE :LOOP2
          CLC
          RTS
:ERREXIT
          SEC
          RTS
*
MYNAME    DS 18


* before trying to get timeii data check known card
* signature
CHKSLOTS
          LDA #7
          STA :SLOT
:LOOP
          LDA :SLOT
          JSR KNWNCARD
          CMP #0
          BNE :NEXT
* add get timeii data and check is date
          LDA :SLOT
          JSR GETIIDATE1 ; try to read a date
          JSR ISIIDATE   ; check if date is ok
          BCS :NEXT
          LDA :SLOT      ; yes return slot
          CLC
          RTS
:NEXT     DEC :SLOT
          BNE :LOOP
          LDA #$FF
          SEC
          RTS

:SLOT     HEX 00
:STORAGE  HEX 01,20,03,00,05,03,FF
:PASCAL   HEX 05,38,07,18,0B,01,FF


CHECKSIG0                ; identify card signature
* get param
          CLC
          ADC #$C0
          STA PTR2+1
          LDA #0
          STA PTR2
          STA :IDX
          STX PTR
          STY PTR+1

* comparaison
:LOOP     LDY :IDX
          LDA (PTR),Y
          CMP #$FF
          BEQ :YES
          TAX
          INY
          LDA (PTR),Y
          STA :BYTE
          TXA
          TAY
          LDA (PTR2),Y
          CMP :BYTE
          BNE :NO
          INC :IDX
          INC :IDX
          RJMP :LOOP
:YES
          CLC
          RTS
:NO
          SEC
          RTS

:LEN      HEX 00
:SLOT     HEX 00
:BYTE     HEX 00
:IDX      HEX 00


CHECKSIG  MAC
          LDX #<]1
          LDY #>]1
          JSR CHECKSIG0
          <<<

KNWNCARD
          STA :SLOT
          STX :SAVX
          STY :SAVY
          CHECKSIG :STORAGE
          BCS :NEXT1
          LDA #$F0       ; Storage card identified
          RJMP :DONE
:NEXT1
          LDA :SLOT
          CHECKSIG :PASCAL
          BCS :NEXT2
          LDA #$F1       ; Pascal protocol card
          RJMP :DONE
* add get timeii data and check is date
:NEXT2
          LDA #$00       ; no card identified
:DONE
          LDX :SAVX
          LDY :SAVY
          RTS
:SLOT     HEX 00
:SAVX     HEX 00
:SAVY     HEX 00
:STORAGE  HEX 01,20,03,00,05,03,FF
:PASCAL   HEX 05,38,07,18,0B,01,FF


EXENXTSYS
          LDA DEVNUM
          STA ONLINEP+OL_UNI
          MLI_CALL ONLINE;ONLINEP
          BCC :OK1
          LDX "A"
          JMP MLIERROR
:OK1
          LDA #'/'
          STA PATHNAME+1
          LDA BUFF
          AND #$0F
          STA PATHNAME
          LDY #0
:LOOP1    LDA BUFF+1,Y
          STA PATHNAME+2,Y
          INY
          CPY PATHNAME
          BNE :LOOP1
          INY            ; update str size for "/" added
          STY PATHNAME
OPENDIR
          MLI_CALL OPEN  ;OPENP
          BCC :OK2
          LDX "B"
          JMP MLIERROR
:OK2
          LDA OPENP+OP_REF
          STA CLOSEP+CL_REF
          STA READP+RD_REF
READDIR
          MLI_CALL READ  ;READP
          BCC :OK3
          LDX "C"
          JMP MLIERROR
:OK3
          MLI_CALL CLOSE ;CLOSEP
          LDA BUFF+VD_ENTLGH
          STA ENTLGH
          LDA BUFF+VD_ENTBLK
          STA ENTBLK
          LDA #1
          STA NUM

          LDA #<BUFF+VD_S_SIZE
          STA PTR
          LDA #>BUFF+VD_S_SIZE
          STA PTR+1
:ENTRY
          LDY #FE_FTYPE
          LDA (PTR),Y
          CMP #$FF
          BNE :NEXTFE

          LDY #FE_NAMLGH
          LDA (PTR),Y
          AND #$30
          BEQ :NEXTFE
          LDA (PTR),Y
          AND #$0F
          STA LEN
          TAY

          LDX SYSTEMSTR  ; check system
:LOOP1    LDA (PTR),Y
          CMP SYSTEMSTR,X
          BNE :NEXTFE
          DEY
          DEX
          BNE :LOOP1

          LDY MYNAME
          CPY LEN
          BNE :FOUND     ; diff len => not me
:LOOP2    LDA (PTR),Y
          CMP MYNAME,Y
          BNE :FOUND
          DEY
          BNE :LOOP2
          SEC
          ROR MYFLAG
:NEXTFE
          LDA PTR
          CLC
          ADC ENTLGH
          STA PTR
          BCC :NEXT1
          INC PTR+1
:NEXT1    INC NUM
          LDA NUM
          CMP ENTBLK
          BCC :ENTRY
:RDBLK
          MLI_CALL READ  ;READP
          BCS :NOTFOUND
          LDA #0
          STA NUM
          LDA #<BUFF4
          STA PTR
          LDA #>BUFF4
          STA PTR+1
          RJMP :ENTRY
:NOTFOUND                ; no .system found to execute
          LDX #"E"
          CMP #0
          BEQ :EXIT
          JMP MLIERROR
:EXIT     JMP QUITPRG
:FOUND
          LDX PATHNAME
          INX
          LDA #'/'
          LDY #0
          STA PATHNAME,X
:LOOP3    INY
          INX
          LDA (PTR),Y
          STA PATHNAME,X
          CPY LEN
          BCC :LOOP3
          STX PATHNAME
          JMP SYSEXEC

BUFF4     EQU BUFF+$4
ENTLGH    HEX 00
ENTBLK    HEX 00
NUM       HEX 00
LEN       HEX 00
MYFLAG    HEX 00
ONLINEP   D_ONLINE 00    ;BUFF
SYSTEMSTR STR '.SYSTEM'

INSTDRV
* set slot * 16
          LDA SLOT
          ASL
          ASL
          ASL
          ASL
          STA SM01+1     ; update driver code before
                         ; relocation
* install driver
          LDA DATETIME+1
          STA PTR
          LDA DATETIME+2
          STA PTR+1

* enable write to bank 1
          LDA RWRAM1
          LDA RWRAM1

* copy driver to new location in bank 1
          LDY #DRVEND-DRIVER-1 ; driver size - 1
:LOOP     LDA DRIVER,Y
          STA (PTR),Y
          DEY
          BPL :LOOP

* inform time driver installed in prodos
          LDA MACHID
          ORA #$01
          STA MACHID

* updating time driver vector
          LDA #OPCJMPA   ; enable driver
          STA DATETIME

          JSR DATETIME   ; first run

* disable write to bank 1
          LDA ROMIN2

          CLC
          RTS


MLIERROR
          STX ERRCOMP
          JSR PRBYTE
          LDA #"-"
          JSR COUT
          LDA ERRCOMP
          JSR COUT
          JSR CROUT
          JSR BELL
QUITPRG   MLI_CALL CLOSE ;CLOSEP
QUITPRG1  MLI_CALL QUIT  ;QUITP
          BRK
ERRCOMP   HEX 00


          DO DEBUG
          USE PRINT
          FIN
          USE TIMEII

*
*
* DRIVER CODE TO RELOCATE
*
*
DRIVER
          PHP
          SEI

* Slot index
SM01      LDX #MM        ; self modified MM <- SLOT * 16

* hold line high
          LDA #$10
          STA BASE_B,X

* Read all timeII card registers
          LDY #SECUNI    ; first  register (second unit)
:LOOP
          TYA            ; start reading units
          STA BASE_A,X
          LDA BASE_A,X
          STA TMP1
* is this register DAY OF WEEK (ie regiter #38) ?
          CPY #DAYWEE
          BNE :NEXT1
          LDA #0         ; this register has no tens
                         ; replace by a 0
          STA TMP2       ; in TMP2
          BEQ :NEXT3     ; kind of "relative JMP"
:NEXT1
          INY            ; start reading tens
          TYA
          STA BASE_A,X
          LDA BASE_A,X
          STA TMP2
* check register having flags
          CPY #HOUTEN
          BEQ :NEXT2
          CPY #DATTEN
          BNE :NEXT3
:NEXT2                   ; remove HOUTEN and DATTEN flags
          LDA TMP2
          AND #%0011
          STA TMP2
:NEXT3
* Combine units and tens in 1 byte
* S =  TMP2 x 10 + TMP1 = TMP2 x 2x2x2 + TMP2 + TMP2 + TMP1
          LDA TMP2
          ASL            ; TMP2 x 2
          ASL            ; TMP2 x 2
          ASL            ; TMP2 x 2
          CLC
          ADC TMP2       ; + TMP2
          ADC TMP2       ; + TMP2
          ADC TMP1       ; + TMP1
          PHA            ; To stack

* an other register to read ?
          INY
          CPY #YEATEN
          BMI :LOOP      ; next unit register

* release TimeII line
          LDA #0
          STA BASE_B,X

* push data to PRODOS
* FROM n.clock.system.s GITHUB prodos-drivers
          PLA            ; Year
          STA DATEHI

          PLA            ; Month
          ASL
          ASL
          ASL
          ASL
          ASL
          STA DATELO
          ROL DATEHI

          PLA            ; Day
          ORA DATELO
          STA DATELO

          PLA            ; skip day of week

          PLA            ; Hour
          STA TIMEHI

          PLA            ; Minute
          STA TIMELO

          PLA            ; skip seconds
:EXIT
          PLP
          RTS
DRVEND    EQU *


RELOC                    ; relocate 255 bytes
          LDA #<_TORELOC_
          STA PTR
          LDA #>_TORELOC_
          STA PTR+1
          LDA #_ERELOC-_SRELOC+1
          STA :LEN
          LDX #0
          LDY #0
:LOOP     LDA (PTR),Y
          STA RELOCORG,X
          CPX :LEN
          BEQ :EXIT
          INX
          INY
          RJMP :LOOP
:EXIT     RTS
:LEN      HEX 00

_TORELOC_ EQU *
          ORG RELOCORG
_SRELOC   EQU *

SYSEXEC
          LDA #<SYSORG
          STA READP+RD_BUFF
          LDA #>SYSORG
          STA READP+RD_BUFF+1
          LDA #<SYSSIZE
          STA READP+RD_RCNT
          LDA #>SYSSIZE
          STA READP+RD_RCNT+1

          MLI_CALL OPEN  ;OPENP
          BCS :ERR

          LDA OPENP+OP_REF
          STA READP+RD_REF
          STA CLOSEP+CL_REF

          MLI_CALL READ  ;READP
          PHP
          MLI_CALL CLOSE ;CLOSEP
          PLP
          BCS :ERR

          JMP SYSORG
:ERR
          STX :ERRCOMP
          JSR PRBYTE
          LDA #"-"
          JSR COUT
          LDA :ERRCOMP
          JSR COUT
          JSR CROUT
          MLI_CALL QUIT  ;QUITP
          BRK
:ERRCOMP  HEX 00

SLOT      HEX 00
OPENP     D_OPEN PATHNAME;OPNBUFF
CLOSEP    D_CLOSE 00
READP     D_READ 00      ;BUFF;$2000
QUITP     D_QUIT
_ERELOC   EQU *
