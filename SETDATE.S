          LST OFF
          REL
          DSK OBJ/SETDATE.L

          USE MAIN.E

          USE INCLUDES.H
          USE LIB/MONITOR.H ; monitor resources
          USE LIB/PRODOS.H

          USE LIB/INOUTDATA.H
          USE LIB/INOUTDATA.E
          USE LIB/DATETIME.E
          USE LIB/DATETIME.H
          USE LIB/STR.H
          USE LIB/STR.E
          USE LIB/TIMEII.H
          USE LIB/TIMEII.E
          USE LIB/CNVANDCHCK.E
          USE LIB/FORMS.H
          USE LIB/FORMS.E
          USE LIB/MEM.H


SETDATE   ENT
          BOX #1         ;#6;#38;#13;DATISTR
          JSR CROUT
          JSR GETDATI
          BCS :EXIT      ; ctrl-c ?
          JSR CROUT
          STRPRNT  YOURSTR
          JSR DISPDATI
          STRPRNT  CRRCTSTR
:LOOP     JSR GETKEY
          AND #%11011111
          CMP #"Y"
          BEQ :SETDATE
          CMP #"N"
          BEQ :EXIT
          JSR BELL
          JMP :LOOP
          JSR CROUT
:SETDATE  JSR SETIIDATE
:EXIT
          RWINDOW
          JSR HOME
          RTS


GETDATI
          JSR HOME
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
          JMP :SLOOPF
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
          JMP :GETNUM1   ; first loop CV/CH not restored
:GETNUM   LDA :SAVCV     ; restore VTAB position
          STA CV
          LDA :SAVCH     ; restore HTAB position
          STA CH
:GETNUM1
          LDA :FLAG
          AND #%00000010
          BNE :4DIGITS   ; else 2DIGITS
:2DIGITS  LDA #2         ; read 2 digits max
          JMP :NEXT1
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
          JMP :VALDATA
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
          JMP :GETNUM    ; no restart reading

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
          JMP :YEAR
:ISDAY
          LDA :FLAG
          AND #%00000001 ; day
          BEQ :ISMONTH
          JMP :DAY
:ISMONTH
          LDA :FLAG
          AND #%00000100 ; month
          BEQ :OTHERS
          JMP :MONTH
:YEAR                    ; if year we have to adjust
                         ; max month value for february
                         ; and store Century and year
          LDX :VALH
          LDY :VALL
          JSR ISBXTILE   ; is date leap ?
          BCC :NOTLEAP
          LDA #30        ; yes display a label
          STA CH         ; on the second part
          STRPRNT LEAPSTR ; of the screen
          LDA #%000000100 ; set mask for timeii leap flag
          STA DATE+_LEA
          LDA #29        ; max day number of month
          JMP :YEAR1     ; go update months table
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
          JMP :DONE
:OTHERS
                         ; LDA #$FF ?
          LDY :IDX
          LDA :VALL
          STA DATE,Y
          JMP :DONE
:MONTH                   ; month value update MAX for
                         ; GETNUM
          LDY :VALL
          DEY
          LDA :DMONTH,Y
          STA DAY+2
* update format string for month
          JSR HEXTODIGI
          TYA
          CLC
          ADC #"0"
          STA SNUMDAY
          TXA
          ADC #"0"
          STA SNUMDAY+1
          JMP :OTHERS
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
          JMP :DAYLOOP
:DYLEXIT
          LDA #">"
          JSR COUT
          LDA AVAL

          JMP :OTHERS
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


DISPDATI
          LDY #0
:LOOP     LDX :FDATE,Y
          CPX #$FF
          BEQ :EXIT
          CPX #$1F
          BCS :CHAR
          PHXY
          LDA DATE,X
          JSR HEXTODIGI
          CLC
          TYA
          ADC #"0"
          JSR COUT
          TXA
          ADC #"0"
          JSR COUT
          PLYX
          JMP :NEXT
:CHAR
          TXA
          JSR COUT
:NEXT
          INY
          JMP :LOOP
:EXIT
          RTS
:FDATE    DFB _CEN,_YEA,"-",_MON,"-",_DAY," ",_HOU,":",_MIN,":",_SEC
          DFB $8D,$8D,$FF


*
* Pascal string
*
LEAPSTR   STR " <L>"
YOURSTR   STR "YOUR DATE: "
CRRCTSTR  STR "CONFIRM DATE ADJUSTMENT (Y/N)? "
DATESTR   STR "CURRENT DATE: "


*
* data for GETDATI "forms"
*
          HEX 00         ; don't know why be without a byte
                         ; set before data GETDATI routine
                         ; did'nt work properly ...
                         ; probably an assembler or link bug
DATISTR   STR " DATE/TIME SETTING "

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
:MIN      DFB 00,19      ; 1583 first full year of
                         ; gregorian calandar.
:MAX      DFB 99,23
:FLAG     DFB %00000010  ; year flag =>  4 digits
:LABEL    ASC "    YEAR: ",00
:FORMAT   ASC "[    ] (1583 - 2399)",00
TABL      DW YEAR,MONTH,DAY,HOUR,MINU,SECO,00

DAYSSTR
:SUNSTR   ASC "SUN",00
:MONSTR   ASC "MON",00
:TUESTR   ASC "TUE",00
:WEDSTR   ASC "WED",00
:THUSTR   ASC "THU",00
:FRISTR   ASC "FRI",00
:SATSTR   ASC "SAT",00
