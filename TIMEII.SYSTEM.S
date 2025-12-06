          LST OFF

           DSK BIN/TIMEII.SYSTEM

          TYP $FF

DEBUG     EQU 1

RWRAM1    EQU $C08B      ; R/W RAM bank 1
ROMIN2    EQU $C082      ; Rom no write

OPCJMPA   EQU $4C        ; JMP ABSOLUTE instruction

MM        EQU 0

* zero page temporary data
TMP       EQU $EB
TMP1      EQU $EB
TMP2      EQU $EC
PTR       EQU $EB
PTR2      EQU $ED

* buffers for MLI
OPNBUFF   EQU $4000      ; 1KB
BUFF      EQU $4800      ; 8kB

* System Calls
GET_TIME  EQU $82

RELOCORG  EQU $1000      ; address for code relocated
SYSORG    EQU $2000      ; sys program start address
SYSSIZE   EQU $BF00-SYSORG ; max prg size

ERR1      EQU 1
ERR2      EQU 2
ERR3      EQU 3

          USE LIB/MONITOR.H
          USE LIB/MACRO.H
          USE LIB/PRODOS.H
          USE LIB/PRINT.H
          USE LIB/DATETIME.H
          USE LIB/TIMEII.H


          ORG SYSORG

START                    ; main proc
          JSR CROUT
          JSR RELOC      ; reloc some code and data

* Check clock driver installed
          LDA MACHID
          AND #$01
          BEQ CONTINUE
          JMP NEXTSYS
CONTINUE
          JSR GETSFN     ; GET Slot From Name
          BCS FINDSLOT   ; no slot in filename go autodetect

          STA SLOT
* JSR GETIIDATE1 ; try to read a date (time ii)
* JSR ISIIDATE ; check if date is ok
          JSR GETDATE
          BCS :ERROR
          LDA SLOT
          JMP INSTALL    ; OK, install driver
:ERROR
          LDY #ERR1
          JMP ERREXIT


FINDSLOT
*
* find the slot of timeii card, store result in SLOT,
* start installation of the date routine and start next
* .SYSTEM program
* if no card is detected start directly the next .SYSTEM
* fucntion will never return!
* modified : A,X,Y
*
          JSR GETTIISLT  ; search for timeii card slot
          CMP #$FF       ; FF => not slot found
          BEQ :ERROR
          STA SLOT
          JMP INSTALL
:ERROR
          LDY #ERR2
ERREXIT
          TYA
          PHA
          JSR HOME
          PLA
          TAY
:ERR1     CPY #ERR1
          BNE :ERR2
          LDA STRERR1
          JSR CENTER40
          PRINTPAS STRERR1
          RJMP :NOTLOAD
:ERR2
          LDA STRERR2
          JSR CENTER40
          PRINTPAS STRERR2
:NOTLOAD
          JSR CROUT
          LDA STRNLOAD
          JSR CENTER40
          PRINTPAS STRNLOAD
          JSR CROUT
:NEXTSYS
          LDA STRKEYPR
          JSR CENTER40
          PRINTPAS STRKEYPR
          JSR GETKEY
          JMP NEXTSYS    ; KO, run next .system


*
* adjust timeii (24H mode and reset leap), load driver and
* exec next .SYSTEM
* in A: SLOT of the card
* modified : A,X,Y
*
INSTALL
          JSR FORCE24II  ; card must in 24H mode
          LDA SLOT
          JSR UPDTLEAP   ; set leap flag on the card ?
          JSR INSTDRV    ; install the driver
NEXTSYS
          JSR GETMYNAME  ; who am i
          JMP EXENXTSYS  ; execute next .system file


GETMYNAME
*
* retrive program name
* needed to find the next .SYSTEM file in root directory
*
* get my name
          LDX PATHNAME
          BEQ :ERREXIT   ; pathname is empty
          LDY #0
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
:OKEXIT
          CLC
          RTS
:ERREXIT
          SEC
          RTS
*
MYNAME    DS 17 MAX 15 chars + 1 start + 1 zero


GETDATE
*
* get full date (include calculated century and leap flag)
* in: A slot
* out: A = century
* out: Y = leap flag (FF=leap, 00=not leap)
* Carry : 0 = valide date, 1 = invalide date
* modified : A,X,Y
*
          JSR GETIIDATE1 ; try to read a date (time ii)
          JSR ISIIDATE   ; check if date is ok
          BCS :EXIT

          LDA TIMEII+_IIDAY
          STA GETCENT+_DD
          LDA TIMEII+_IIMON
          STA GETCENT+_MM
          LDA TIMEII+_IIDOW
          STA GETCENT+_IIDOW
          LDA TIMEII+_IIYEA
          STA GETCENT+_YY
          LDY #$FF       ; ask GETCENT for leap calculation
          JSR GETCENT
          STA CENT       ; store results
          STY LEAP
          CLC
:EXIT
          RTS
CENT      HEX 00
LEAP      HEX 00


UPDTLEAP                 ; UPDate LEAP flag
*
* Update leap flag for current date
* in: A slot
* modified : A
*
          STX :SAVX
          STY :SAVY
          TAX
          LDA LEAP
          CMP TIMEII+_IILEA
          BEQ :DONE      ; leaps are aligned
          TXA
          ASL            ; X = X * 16
          ASL
          ASL
          ASL
          TAX
          JSR TGLIILEAP
:DONE
          LDY :SAVY
          LDX :SAVX
          RTS
:SAVX     HEX 00
:SAVY     HEX 00


GETSFN                   ; GET Slot From Name
*
* Get SLOT from file name if exist
* out A: SLOT number of FF if not found
* out CARRY: 0 = found, 1 = not found
* modified : A,X,Y
*
          LDA PATHNAME
          BEQ :ERR       ; empty string
          CMP #8         ; len(systemstr)+len("Sx") - 1
          BCC :ERR       ; A <= 8 -> impossible ...
          LDX SYSTEMSTR
          LDY PATHNAME
:LOOP1    LDA PATHNAME,Y ; loop ".system"
          CMP SYSTEMSTR,X
          BNE :ERR       ; char does not match exit
          DEY
          DEX
          BNE :LOOP1
                         ; all chars matched
          LDA PATHNAME,Y ; read possible slot number
          TAX            ; backup A
          DEY            ; next char
          LDA PATHNAME,Y ; must be
          CMP #'S'       ; an "S"
          BNE :ERR       ; no exit
          TXA            ; check if A is in range
          CMP #'1'       ; >= "1"
          BCC :ERR       ; no exit
          CMP #'8'       ; < "8"
          BCS :ERR       ; no exit
          SEC            ; yes
          SBC #'0'       ; convert char to number
          CLC            ; carry = 0 => ok
          RTS
:ERR
          LDA #$FF
          SEC            ; carry = 1 => ko
          RTS


GETTIISLT                ; GET TimeII SLoT
*
*
*
          LDA #7         ; form 7 to 1 loop
          STA :SLOT
* before trying to get timeii data check known card
* signature
:LOOP
          LDA :SLOT
          JSR KNWNCARD   ; check known cards
          CMP #0
          BNE :NEXT      ; card knowned => not TIMEII
:TIMEIITRY               ; unknown card
          LDA :SLOT can be a time II
          JSR GETDATE    ; try to read date form time ii
* JSR GETIIDATE1 ; try to read a date (time ii)
* JSR ISIIDATE ; check if date is ok
          BCS :NEXT      ; no => next slot
          LDA :SLOT      ; yes return slot
          CLC            ; carry = 0 => no error
          RTS
:NEXT     DEC :SLOT
          BNE :LOOP
          LDA #$FF       ; error
          SEC            ; carry = 1 => error
          RTS
:SLOT     HEX 00


*
* check signature
* A <= slot
* X,Y <= signature table address
*
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


*
* A <= SLOT : slot to check
* A => discover code (0, F0 or F1)
*
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


EXENXTSYS                ; exec next sys prog
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
          BNE :FOUND     ; diff len => not me so we find it
:LOOP2    LDA (PTR),Y
          CMP MYNAME,Y
          BNE :FOUND     ; diff char => not me so we find it
          DEY
          BNE :LOOP2
          SEC
          ROR MYFLAG     ; found myself, now next one will be executed
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
          BCS :ERROREOF  ; nothing more to read or error
          LDA #0
          STA NUM
          LDA #<BUFF4
          STA PTR
          LDA #>BUFF4
          STA PTR+1
          RJMP :ENTRY
:ERROREOF                ; no .system found to execute
          CMP #$4C       ; eof ?
          BEQ :EXIT      ; goto close and quit
          LDX #"E"       ; an error occured
          JMP MLIERROR
:EXIT     JMP QUITPRG
:FOUND
          BIT MYFLAG
          BPL :NEXTFE

          LDX PATHNAME
          INX
          LDA #'/'
          LDY #0
          STA PATHNAME,X
          STX PATHNAME

:LOOP3    INY
          INX
          LDA (PTR),Y
          STA PATHNAME,X
          CPY LEN
          BCC :LOOP3
          STX PATHNAME

          MLI_CALL CLOSE ;CLOSEP
          BCC :EXEC
          JSR PRBYTE
          LDA #"-"
          JSR COUT
          LDA #"F"
          JSR COUT
          JSR CROUT
          JMP QUITPRG1
:EXEC     JMP SYSEXEC

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

* declare time driver installed in prodos
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


* error and exit
MLIERROR
          PHA
          STX ERRCOMP
          LDA STRMLIER
          JSR CENTER40
          PRINTPAS STRMLIER
          PLA
          JSR PRBYTE
          LDA #"-"
          JSR COUT
          LDA ERRCOMP
          JSR COUT
          JSR CROUT
QUITPRG   MLI_CALL CLOSE ;CLOSEP
QUITPRG1  MLI_CALL QUIT  ;QUITP
          BRK
ERRCOMP   HEX 00


]E_SETIIDATE  EQU 0
]E_GETIIDATE  EQU 1
]E_ISIIDATE  EQU 1
]E_PRNIIDATE  EQU 0
]E_FINDSLOT  EQU 0
]E_GETIILEAP  EQU 1
]E_SETIILEAP  EQU 0
]E_TGLIILEAP  EQU 1
]E_FORCE24II  EQU 1
          USE LIB/TIMEII

]E_GETDAYOFW  EQU 1
]E_ISBXTILE  EQU 1
]E_GETCENT  EQU 1
          USE LIB/DATETIME

]E_PRINTPAS  EQU 1
]E_PRINT   EQU 0
]E_CENTER40  EQU 1
          USE LIB/PRINT

*
*
* DRIVER CODE TO RELOCATE
* 125 bytes maximum
*
_UNI      EQU $EB
_TEN      EQU $EC

DRIVER
          PHP
          SEI
          LDA _UNI
          PHA
          LDA _TEN
          PHA

* Slot index
SM01      LDX #MM        ; self modified MM <- SLOT * 16

* hold line high
          LDA #$10
          STA BASE_B,X

* Read all timeII card registers
          LDY #MINUNI    ; first  register (minute unit)
:LOOP
* is this register DAY OF WEEK (ie regiter #38) ?
          CPY #DAYWEE
          BEQ :NEXT      ; next register

          TYA            ; start reading units
          STA BASE_A,X
          LDA BASE_A,X
          STA _UNI

          INY

          TYA            ; start reading tens
          STA BASE_A,X
          LDA BASE_A,X

* check "tens" register having flags
          CPY #HOUTEN
          BEQ :NEXT2
          CPY #DATTEN
          BNE :NEXT3
:NEXT2                   ; remove HOUTEN and DATTEN flags
          AND #%00000011
:NEXT3
          STA _TEN
 
* Combine units and tens in 1 byte
* S =  _TEN x 10 + _UNI = _TEN x 2x2x2 + _TEN + _TEN + _UNI
                         ; LDA TMP2
          ASL            ; _TEN x 2
          ASL            ; _TEN x 2
          ASL            ; _TEN x 2
          CLC
          ADC _TEN       ; + _TEN
          ADC _TEN       ; + _TEN
          ADC _UNI       ; + _UNI
          PHA            ; To stack

* an other register to read ?
:NEXT
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

          PLA            ; Hour
          STA TIMEHI

          PLA            ; Minute
          STA TIMELO

:EXIT
          PLA
          STA _TEN
          PLA
          STA _UNI
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


*
* globale data
*
STRERR1   STR "AN INCONSISTENT DATE WAS READ!"
STRERR2   STR "NO TIMEII CARD FOUND!"

STRNLOAD  STR "DRIVER NOT LOADED"
STRKEYPR  STR "PRESS ANY KEY TO CONTINUE"
STRMLIER  STR "MLI ERROR: "


*
* section to relocate
*
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
