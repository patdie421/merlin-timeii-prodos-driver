          LST OFF
          DSK TIMEII.SETUP
          TYP $FF

          USE UTILS.H    ; utils macro
          USE MONITOR.H  ; monitor resources
          USE INOUTDATA.H

          USE INCLUDES.H
          USE TIMEII.H
          USE DATETIME.H
          USE PRODOS.H

CENTER    MAC
          LDY #0         ; count char
]L1       LDA ]1,Y
          BEQ ]N1
          INY
          CLC
          BCC ]L1
]N1       TYA
          EOR #$FF       ; calc tab
          CLC
          ADC #40
          LSR
          STA CH         ; htab
          <<<

          ORG $2000

SETUP
* reserve memory in System Bit Map
          LDA #$FF
          STA MEMFLAG

* reserve 2000 to 2FFF for program
* 4000 to 47FF for file buffers (holded/released by prodos)
* and reserve 4800 to 49FF data
          LDA $BF5C
          BNE :NOTFREE
          LDA $BF5D
          BNE :NOTFREE
          LDA SBM48
          AND #SBMMASK   ; check if available
          BNE :NOTFREE
          LDA #$FF
          STA $BF5C
          STA $BF5D
          LDA SBM48
          ORA #SBMMASK   ; set reservation
          STA SBM48
          LDA #0
          STA MEMFLAG
          JMP MAIN

:NOTFREE  LDX "0"
          JMP ERROR


MAIN
          JSR HOME
          CENTER TITLESTR
          PRINT TITLESTR
          JSR CROUT
          JSR GETSLOT
          INITII SLOT
          RJMP MENU
          RTS

QUIT1     JSR FREEMEM
          MLI_CALL QUIT  ;QUITP
          BRK

MENU
          JSR HOME
          JSR DISPTTL
          JSR GETIIDATE
          JSR PRNIIDATE
          JSR ISIIDATE
          BCC MENU1
          PRINT INVALSTR
MENU1     PRINT MENUSTR
:GETKEY   JSR GETKEY
:1        CMP #"1"       ; set slot
          BNE :2
          JSR HOME
          CENTER TITLESTR ; replace with slot title
          PRINT TITLESTR
          JSR CROUT
          JSR GETSLOT
          INITII SLOT
          RJMP MENU
:2        CMP #"2"       ; set date/time
          BNE :3
          JSR SETDATE
          RJMP MENU
:3
* :3 CMP #"3"
* BNE :4
* JSR DOINST
* RJMP MENU
:4        CMP #"4"
          BEQ :QUIT1
:DEFAULT  CLC
          BCC :GETKEY
:QUIT1    JMP QUIT1
:NEXT
          RJMP MENU
DISPTTL
          CENTER TITLESTR
          PRINT TITLESTR
          CENTER SLOTSTR
          PRINT SLOTSTR
          LDA #$88
          JSR COUT
          JSR COUT
          LDA SLOT
          JSR PRBYTE
          JSR CROUT
          JSR CROUT
          RTS


SETDATE
          JSR GETDATI
          BCS :EXIT      ; ctrl-c ?
          JSR CROUT
          PRINT YOURSTR
          JSR DISPDATI
          PRINT CRRCTSTR
:LOOP     JSR GETKEY
          CMP #$E1       ; "a"   ; Check whether
          BMI :COMP      ;       ; character is
          CMP #$FB       ; "z"+1 ; lower case.
          BPL :COMP
          SEC
          SBC #$20       ; to upper
:COMP     CMP #"Y"
          BEQ :SETDATE
          CMP #"N"
          BEQ :EXIT
          JSR BELL
          RJMP :LOOP
          JSR CROUT
:SETDATE  JSR SETIIDATE
:EXIT     JSR HOME
          RTS


GETSLOT
          PRINT GSLOTSTR
          LDA CH
          STA :SAVCH
:GET1NUM  JSR GET1NUM
:EXIT     BCC :NEXT      ; ctrl-c
* JMP QUIT
          RTS
* :NEXT STA  :NUMSLOT  ; not sure we will keep this
* ; values but just in case ...
:NEXT
          SEC
          SBC #"0"
          BEQ :GETSLOT   ; Slot must be in 1,2,4,5,6,7
          CMP #3         ; exclude 3
          BEQ :GETSLOT
          CMP #8
          BCS :GETSLOT   ; < 8
          STA SLOT       ; we have a valid slot
          JSR CROUT
          JSR CROUT
          RTS
:GETSLOT
          LDA :SAVCH
          STA CH
          JSR CLREOL
          RJMP :GET1NUM
:SAVCH    HEX 00


GETDATI
          JSR HOME
          CENTER DATISTR
          PRINT DATISTR
          LDX #0
          STX :IDX
:LOOP     LDY #5
          LDA TABL,X
          BNE :CONT
          JMP :EXIT
:CONT     STA PTR
          LDA TABL+1,X
          STA PTR+1
:SLOOPL   LDA (PTR),Y    ; print label
          BEQ :FORMAT
          JSR COUT
          INY
          CLC
          BCC :SLOOPL
:FORMAT   INY            ; format str start aferter label
          LDA CH         ; Save cursor position
          PHA            ; to stack
:SLOOPF   LDA (PTR),Y    ; print format
          BEQ :RDSTRUC
          JSR COUT
          INY
          RJMP :SLOOPF
:RDSTRUC
          PLA            ; restore cusror position
          STA CH         ; from stack
          INC CH         ; cursor position after "["
          LDY #0         ; read data structure
          LDA (PTR),Y
          STA :MINL      ; min val low
          INY
          LDA (PTR),Y
          STA :MINH      ; min val high
          INY
          LDA (PTR),Y
          STA :MAXL      ; max val low
          INY
          LDA (PTR),Y
          STA :MAXH      ; max val high
          INY
          LDA (PTR),Y
          STA :FLAG      ; special flags

          STX :SAVX
          RJMP :GETNUM1  ; first loop CV/CH not restored
:GETNUM   LDA :SAVCV     ; restore VTAB position
          STA CV
          LDA :SAVCH     ; restore HTAB position
          STA CH
:GETNUM1
          LDA :FLAG
          AND #%00000010
          BNE :4DIGITS   ; else 2DIGITS
:2DIGITS  LDA #2         ; read 2 digits max
          RJMP :NEXT1
:4DIGITS  LDA  #4        ; read 4 digits max
:NEXT1
          LDX CV         ; save VTAB (for :GETNUM)
          STX :SAVCV
          LDX CH         ; save HTAB (for :GETNUM)
          STX :SAVCH
          JSR  GETNUMS   ; read number
          BNE :CONVERT   ; number to data
          BCC :GETNUM
          RTS            ; abord forms
***
*
*  convert result (str to hex val) and store in VALL/VALH
:CONVERT  CMP #2         ; a <= char count from GETNUMS
          BEQ :CONV2D    ; 4 digits (year)
          LDX SGETNUMB+1
          LDY SGETNUMB
          JSR DIGITOHEX
          STA :VALH
          LDX SGETNUMB+3
          LDY SGETNUMB+2
          JSR DIGITOHEX
          STA :VALL
          RJMP :VALDATA
:CONV2D                  ; only 2 digits
          LDX SGETNUMB+1
          LDY SGETNUMB
          JSR DIGITOHEX
          STA :VALL
          LDA #0
          STA :VALH
* validate data (compare with interval in structure)
:VALDATA
                         ; Check if VAL >= MIN
          LDA :VALH      ; VALH = high of VAL
          CMP :MINH      ; MINH = high of MIN
          BCC :FALSE1    ; if MINH < VALH then MIN < VAL
          BNE :TRUE1     ; and if VALH <> NUM2H then
                         ;    VAL > MIN (so VAL >= MIN)
          LDA :VALL      ; compare low bytes
          CMP :MINL
          BCS :TRUE1     ; if VALL >= MINL then VAL >= MIN
:FALSE1                  ; VAL is < MIN return to Getnum
          LDA :FLAG
          RJMP :GETNUM   ; no restart reading

:TRUE1
                         ; check VAL <= MAX (ie MAX >= VAL)
          LDA :MAXH      ;
          CMP :VALH      ;
          BCC :FALSE2    ; if MAXH < VALH then MAX < VAL
          BNE :TRUE2     ; and if MAXH <> VALH then
                         ;    MAX > VAL (so VAL <= MAX)
          LDA :MAXL      ; compare low bytes
          CMP :VALL
          BCS :TRUE2     ; if MAXL >= VALL then MAXL >= VALL
:FALSE2
          LDA :FLAG
          JMP :GETNUM    ; no restart reading
:TRUE2                   ; we get a valid value
* update some data for some type of value
:ISYEAR
          LDA :FLAG
          AND #%00000010 ; year
          BEQ :ISDAY
          RJMP :YEAR
:ISDAY
          LDA :FLAG
          AND #%00000001 ; day
          BEQ :ISMONTH
          RJMP :DAY
:ISMONTH
          LDA :FLAG
          AND #%00000100 ; month
          BEQ :OTHERS
          RJMP :MONTH
:YEAR                    ; if year we have to adjust
                         ; max month value for february
                         ; and store Century and year
          LDX :VALH
          LDY :VALL
          JSR ISBXTILE   ; is date leap ?
          BCC :NOTLEAP
          LDA #30        ; yes display a label
          STA CH         ; on the second part
          PRINT LEAPSTR  ; of the screen
          LDA #%000000100 ; set mask for timeii leap flag
          STA DATE+_LEA
          LDA #29        ; max day number of month
          RJMP :YEAR1    ; go update months table
:NOTLEAP  LDA #%000000000 ; no flag to set for time leap
          STA DATE+_LEA
          LDA #28
:YEAR1    STA :DMONTH+1  ; change value of february

          LDA :VALH      ; store values
          STA DATE+_CEN
          LDA :VALL
          STA DATE+_YEA
          INC :IDX       ; adjust index because we store
                         ; 2 values for date
          RJMP :DONE
:OTHERS
                         ; LDA #$FF ?
          LDY :IDX
          LDA :VALL
          STA DATE,Y
          RJMP :DONE
:MONTH                   ; month value update MAX for
                         ; GETNUM
          LDY :VALL
          DEY
          LDA :DMONTH,Y
          STA DAY+2
* update format string for month
* STX :SAVX1 ; save X
* STY :SAVY1 ; save Y
          JSR HEXTODIGI
          TYA
          CLC
          ADC #"0"
          STA SNUMDAY
          TXA
          ADC #"0"
          STA SNUMDAY+1
* LDY :SAVY1 ; restore Y
* LDX :SAVX1 ; restore X

          RJMP :OTHERS
:DAY
                         ; get day of week
          LDA :VALL
          STA GETDAYOFW+_DD
          LDA DATE+_MON
          STA GETDAYOFW+_MM
          LDA DATE+_CEN
          STA GETDAYOFW+_CC
          LDA DATE+_YEA
          STA GETDAYOFW+_YY
          JSR GETDAYOFW  ; calculate day of week
          STA DATE+_DOW
          STA AVAL
          LDA #25
          STA CH
          LDA #"<"
          JSR COUT
          LDA AVAL
          ASL
          ASL
          TAY
:DAYLOOP  LDA DAYSSTR,Y
          BEQ :DYLEXIT
          JSR COUT
          INY
          RJMP :DAYLOOP
:DYLEXIT
          LDA #">"
          JSR COUT
          LDA AVAL

          RJMP :OTHERS
*
***
:DONE
          JSR CROUT
          LDX :SAVX      ; restore x

:NEXT     INX            ; 2x inc for next address
          INX            ; of the table
          INC :IDX
          JMP :LOOP
:EXIT     CLC
          RTS
:DMONTH   DFB 31,28,31,30,31,30,31,31,30,31,30,31
:SAVCH    HEX 00
:SAVCV    HEX 00
:VALL     HEX 00
:VALH     HEX 00
:IDX      HEX 00         ; idx in dest date array
:MAXL     HEX 00
:MAXH     HEX 00
:MINL     HEX 00
:MINH     HEX 00
:FLAG     HEX 00
:SAVX     HEX 00
:SAVA     HEX 00
* :SAVX1 HEX 00
* :SAVY1 HEX 00


DISPDATI
          LDY #0
:LOOP     LDX :FDATE,Y
          CPX #$FF
          BEQ :EXIT
          CPX #$1F
          BCS :CHAR
:VAL
          STX :SAVX
          STY :SAVY
          LDA DATE,X
          JSR HEXTODIGI
          CLC
          TYA
          ADC #"0"
          JSR COUT
          TXA
          ADC #"0"
          JSR COUT
          LDY :SAVY
          LDX :SAVX
          RJMP :NEXT
:CHAR
          TXA
          JSR COUT
:NEXT
          INY
          RJMP :LOOP
:EXIT
          RTS
:SAVX     HEX 00
:SAVY     HEX 00
:FDATE    DFB _CEN,_YEA,"-",_MON,"-",_DAY," ",_HOU,":",_MIN,":",_SEC
          DFB $8D,$8D,$FF


DOINST
          JSR HOME
          RTS


*
* Memory managment
*
FREEMEM                  ; release memory
          LDA MEMFLAG
          CMP #$FF
          BEQ :EXIT      ; no mem reserved
          LDY SBM48
          TYA
          AND #SBMMASKI
          STA SBM48

          LDA #0
          STA $BF5C
          STA $BF5D
:EXIT     RTS


*
* Error handling
*
ERROR                    ; print error code
          STA :ERRNO     ; retrieve error number
          STX :ORIG      ; retrieve origin code
          JSR CROUT
          PRINT ERRORSTR
          LDA :ORIG
          JSR COUT
          LDA :ERRNO
          JSR PRBYTE
          JSR BELL
          JSR CROUT
          JSR GETKEY
* LDA #0 ; close all files
* JSR CLOSEF ; and exit
          JMP QUIT1
:ERRNO    DFB $0         ; local data reserved in code
:ORIG     DFB $0


*
* TIMEII CARD
*
IIDATE    EQU DATE
]E_SETIIDATE  EQU 1
]E_GETIIDATE  EQU 1
]E_ISIIDATE  EQU 1
]E_PRNIIDATE  EQU 1
]E_FINDSLOT  EQU 0
]E_GETIILEAP  EQU 0
]E_TGLIILEAP  EQU 0
          USE TIMEII

*
* DATE / TIME utils
*
]E_GETDAYOFW  EQU 1
]E_ISBXTILE  EQU 1
          USE DATETIME

*
* DATA convertion
*
]E_HEXTODIGI  EQU 1
]E_DIGITOHEX  EQU 1
          USE CONVANDCHECK

*
* I/O utils
*
]E_GET1NUM  EQU 1
]E_GETNUMS  EQU 1
* ]E_GETPATH  EQU 0
* ]E_PRINT0  EQU 0
]E_PRINTDEC  EQU 1
          USE INOUTDATA


*
*
* DATA
*
*

*
* zero terminated string
*
GSLOTSTR  ASC "SLOT NUMBER (1,2,4,5,6 or 7): ",00
SLOTSTR   ASC "SLOT: __",00
PATHCFGS  ASC "FILES USED FOR CONFIGURATION:",8D,8D,00
SRCSTR    ASC "SOURCE:",00
SRCFSTR   ASC "  (1) FILENAME: ",00
DESTSTR   ASC "DESTINATION:",00
DPRFXSTR  ASC "  (2) PREFIX: ",00
PATHQ1    ASC "UPDATE FILE PATH ? (1/2/N)",00
ERRORSTR  ASC "FATAL ERROR!!! ERRNO: ",00
DATESTR   ASC "CURRENT DATE: ",00
INVALSTR  ASC "INVALID DATE! CHECK SLOT AND/OR AJSUT",8D
          ASC "DATE BEFORE INSTALLING DRIVER.",8D,8D,00
MENUSTR   ASC "TIMEII CARD CONFIGURATION:",8D,8D
          ASC "(1) SELECT AN OTHER SLOT",8D
          ASC "(2) DATE/TIME ADJUSTMENT",8D
          ASC "(3) INSTALL PRODOS DRIVER",8D
          ASC "(4) EXIT",8D,8D
          ASC "CHOICE: ",00
LEAPSTR   ASC " <LEAP>",00
TITLESTR  ASC "TIME II CLOCK CARD",8D,00
YOURSTR   ASC "YOUR DATE: ",00
CRRCTSTR  ASC "CONFIRM DATE ADJUSTMENT (Y/N)? ",00


*
* data for GETDATI "forms"
*
DATISTR   ASC "DATE/TIME SETTING",8D,8D,00

HOUR
:MIN      DFB 0,0
:MAX      DFB 23,0       ; 23 max
:FLAG     DFB 0
:LABEL    ASC "   HOURS: ",00
:FORMAT   ASC "[  ] (0 - 23)",00
MINU
:MIN      DFB 0,0
:MAX      DFB 59,0       ; 59 max
:FLAG     DFB 0
:LABEL    ASC " MINUTES: ",00
:FORMAT   ASC "[  ] (0 - 59)",00
SECO
:MIN      DFB 0,0
:MAX      DFB 59,0
:FLAG     DFB 0
:LABEL    ASC "SECONDES: ",00
:FORMAT   ASC "[  ] (0 - 59)",00
DAY
:MIN      DFB 1,0
:MAX      DFB 31,0
:FLAG     DFB %00000001  ; max is external table
:LABEL    ASC "     DAY: ",00
:FORMAT   ASC "[  ] (1 - "
SNUMDAY   ASC "XX"
          ASC ")",00
MONTH
:MIN      DFB 1,0
:MAX      DFB 12,0
:FLAG     DFB %00000100
:LABEL    ASC "   MONTH: ",00
:FORMAT   ASC "[  ] (1 - 12)",00
YEAR
:MIN      DFB 83,15      ; 1583 first full year of
                         ; gregorian calandar.
:MAX      DFB 99,99
:FLAG     DFB %00000010  ; year flag =>  4 digits
:LABEL    ASC "    YEAR: ",00
:FORMAT   ASC "[    ] (1583 - 9999)",00
TABL      DW YEAR,MONTH,DAY,HOUR,MINU,SECO,00

DAYSSTR
:SUNSTR   ASC "SUN",00
:MONSTR   ASC "MON",00
:TUESTR   ASC "TUE",00
:WEDSTR   ASC "WED",00
:THUSTR   ASC "THU",00
:FRISTR   ASC "FRI",00
:SATSTR   ASC "SAT",00

QUITP     D_QUIT

END       EQU *
