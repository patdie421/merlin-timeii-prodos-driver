         LST    OFF
         REL
         DSK    OBJ/MAIN.L


         USE    LIB/MONITOR.H  ; monitor resources
         USE    LIB/PRODOS.H

         USE    LIB/INOUTDATA.H
         USE    LIB/INOUTDATA.E
         USE    LIB/STR.H
         USE    LIB/STR.E
         USE    LIB/TIMEII.H
         USE    LIB/TIMEII.E
         USE    LIB/FORMS.H
         USE    LIB/FORMS.E

         USE    SETDATE.E
         USE    INSTALL.E
         USE    INSTUI.E


* init mem and variables
INIT     ENT
         JSR    GETMYPATH      ; get launch path (from install.s)


MAIN
         JSR    HOME
* get slot at startup
         STRCENTER TITLESTR;40
         STRPRNT TITLESTR
         JSR    GETSLOT
         INITII2 SLOT;DATE     ; configure timeii (for lib/timeii.s)

MENU
* display main menu
         RWINDOW               ; reset window
         JSR    HOME
         STRCENTER TITLESTR;40
         STRPRNTL TITLESTR
         JSR    DISPSLOT       ; display selected slot
         JSR    GETIIDATE      ; get date & time from TIMEII card
         STRPRNT DATESTR       ; display date

* save cursor for direct screen acces by date display CB
         LDA    CH
         STA    DISPCH
         LDA    BASL
         STA    DISPBAS+1
         LDA    BASH
         STA    DISPBAS+2

         JSR    PRNIIDATE      ; print "RAW" date
         JSR    CROUT2         ;

         JSR    ISIIDATE       ; check if date "can be" correct
         BCC    :MENU0
                               ; invalid date
         JSR    SETINV         ; inverse on
         STRPRNT INVALSTR      ; display invalid date
         JSR    SETNORM        ; inverse off
         JSR    CROUT2
:MENU0
         GKSETCB DISPDATECB    ; enable date/time display update
:MENU1
         STRPRNT MENUSTR
:GETKEY
         JSR    MYGETKEY1      ; JSR GETKEY
:1
         CMP    #"1"           ; set slot
         BNE    :2
         JSR    GETSLOT
         INITII SLOT           ; re set slot in timeii lib
         JMP    MENU
:2
         CMP    #"2"           ; set date/time
         BNE    :3
         JSR    SETDATE        ; from SETDATE.S
         JMP    MENU
:3
         CMP    #"3"
         BNE    :4
         JSR    RESETSEC       ; from SETDATE.S
         JMP    MENU
:4
         CMP    #"4"
         BNE    :5
         GKCLRCB               ; disable date/time continus display update
         JSR    INSTALLDRV     ; from INSTGUI.S
         JMP    MENU
:5
         CMP    #"5"
         BEQ    QUIT1
:DEFAULT
         BNE    :GETKEY        ; JMP :GETKEY


DISPSLOT ENT
         STRCENTER SLOTSTR;36
         STRPRNT SLOTSTR
         LDA    SLOT
         JSR    PRBYTE
         JSR    CROUT2
         RTS


QUIT1
         MLI_CALL QUIT;QUITP
         BRK                   ; on "QUIT" error goto to monitor
QUITP    D_QUIT


GETSLOT
         BOX    #7;#7;#26;#6;GSLOTTTL
         JSR    CROUT
         STRPRNT GSLOTSTR
:GET1NUM JSR    MYGETKEY1
         CMP    #$83           ; ctrl-c
         BEQ    QUIT1
         SEC
         SBC    #"0"
                               ; BEQ :GETSLOT ; = 0 not allowed
                               ; BCC :GETSLOT ; < 0 not allowed
         BEQ    :GET1NUM       ; = 0 not allowed
         BCC    :GET1NUM       ; < 0 not allowed
         CMP    #8
         BCS    :GET1NUM       ; < 8 => greater than 7 not allowed
         STA    SLOT           ; we have a valid slot
         RTS


DISPDATECB
         INC    DISPCNTR
         LDA    DISPCNTR
         AND    #%00000011
         BNE    DISPRET
         JSR    GETIIDATE
         JSR    TOIIDATEASC
         LDX    #$00
         LDY    DISPCH
DISPLOOP
         LDA    DATEIIASC,X
         BEQ    DISPRET
DISPBAS  STA    $0000,Y
         INY
         INX
         BNE    DISPLOOP
DISPRET  RTS
DISPCH   HEX    00
DISPCNTR HEX    00


*
* DATA and STRINGS
*
SLOT     ENT
         HEX    00
DATE     ENT
         HEX    00,00,00,00,00,00,00,00,00

GSLOTTTL STR    " CARD SLOT? "
GSLOTSTR STR    " SELECT 1 TO 7:"
SLOTSTR  STR    "SLOT: "
INVALSTR STR    "INVALID DATE! CHECK SLOT AND/OR AJSUT IT"
TITLESTR STR    "TIME II CLOCK CARD"
YOURSTR  STR    "YOUR DATE: "
CRRCTSTR STR    "CONFIRM DATE ADJUSTMENT (Y/N) "
DATESTR  STR    "CURRENT DATE: "
MENUSTR  DB     MENUSTRE-MENUSTRS
MENUSTRS ASC    "(1) SELECT AN OTHER SLOT",8D
         ASC    "(2) DATE/TIME ADJUSTMENT",8D
         ASC    "(3) ADJUST SECONDS",8D
         ASC    "(4) INSTALL PRODOS DRIVER",8D
         ASC    "(5) EXIT",8D,8D
         ASC    "CHOICE:"
MENUSTRE EQU    *
