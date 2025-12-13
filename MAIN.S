          LST OFF
          REL
          DSK OBJ/MAIN.L


          USE LIB/MONITOR.H ; monitor resources
          USE LIB/PRODOS.H

          USE LIB/INOUTDATA.H
          USE LIB/INOUTDATA.E
          USE LIB/STR.H
          USE LIB/STR.E
          USE LIB/TIMEII.H
          USE LIB/TIMEII.E
          USE LIB/FORMS.H
          USE LIB/FORMS.E

          USE SETDATE.E
          USE INSTALL.E
          USE INSTGUI.E


* init mem and variables
INIT      ENT
          JSR GETMYPATH  ; get launch path
* init TIMEII.S lib: set dati structure address
          LDA #<DATE
          STA DATIDATE   ; DATIDATE is define in TIMEII.S
          LDA #>DATE
          STA DATIDATE+1


MAIN
* get slot at startup
          JSR HOME
          STRCENTER TITLESTR;40
          STRPRNT TITLESTR
          JSR CROUT2
          JSR GETSLOT
          INITII SLOT    ; configure TIMEII

MENU
* display main menu
          JSR HOME
          JSR DISPSLOT   ; display slot
          JSR GETIIDATE  ; get date/time TIMEII from card
          STRPRNT DATESTR : display date
          JSR PRNIIDATE  ; print "RAW" date
          JSR ISIIDATE   ; check date "can be" correct
          BCC :MENU1
          LDY #$7F       ; if not display flashing warning
          JSR SETIFLG    ; flash on
          STRPRNT INVALSTR ; display invalid date
          JSR SETNORM    ; flash off
          JSR CROUT2
:MENU1
          STRPRNT MENUSTR
:GETKEY
          JSR GETKEY
:1
          CMP #"1"       ; set slot
          BNE :2
          JSR GETSLOT
          INITII SLOT    ; re set slot in timeii lib
          JMP MENU
:2
          CMP #"2"       ; set date/time
          BNE :3
          JSR SETDATE    ; from SETDATE.S
          JMP MENU
:3
          CMP #"3"
          BNE :4
          JSR INSTALLDRV ; from INSTGUI.S
          JMP MENU
:4
          CMP #"4"
          BNE :GETKEY
          JMP QUIT1
:NEXT
          JMP MENU


DISPSLOT  ENT
          STRCENTER  TITLESTR;40
          STRPRNTL  TITLESTR
          STRCENTER  SLOTSTR;36
          STRPRNT  SLOTSTR
          LDA SLOT
          JSR PRBYTE
          JSR CROUT2
          RTS


GETSLOT
          LDA #0
          BOX #7;#6;#26;#6;GSLOTTTL
          JSR CROUT
          STRPRNT  GSLOTSTR
          LDA CH
          STA :SAVCH
:GET1NUM  JSR GET1NUM
:EXIT     BCC :NEXT      ; ctrl-c
          RTS
:NEXT
          SEC
          SBC #"0"       ; Slot must be in 1,2,4,5,6,7
          BEQ :GETSLOT   ; 0 is not in list
          CMP #3         ; 1 ou 7 exclude 3
          BEQ :GETSLOT
          CMP #8
          BCS :GETSLOT   ; < 8 => greater than 7 not allowed
          STA SLOT       ; we have a valid slot
          JSR CROUT2
          RWINDOW
          RTS
:GETSLOT
          LDA :SAVCH     ; reset the cursor
          STA CH
          JSR CLREOL     ; clear line
          JMP :GET1NUM   ; go to read slot
:SAVCH    HEX 00


QUIT1
          MLI_CALL QUIT;QUITP
          BRK            ; on "QUIT" error goto to monitor
QUITP     D_QUIT


*
* DATA and STRINGS
*
SLOT      ENT
          HEX 00
DATE      ENT
          HEX 00,00,00,00,00,00,00,00,00

GSLOTTTL  STR " TIMEII CARD SLOT? "
GSLOTSTR  STR "   1,2,4,5,6 or 7:"
SLOTSTR   STR "SLOT: "
INVALSTR  STR "INVALID DATE! CHECK SLOT AND/OR AJSUT IT"
TITLESTR  STR "TIME II CLOCK CARD"
YOURSTR   STR "YOUR DATE: "
CRRCTSTR  STR "CONFIRM DATE ADJUSTMENT (Y/N)? "
DATESTR   STR "CURRENT DATE: "
MENUSTR   DB MENUSTRE-MENUSTRS
MENUSTRS  ASC "TIMEII CARD CONFIGURATION:",8D,8D
          ASC "(1) SELECT AN OTHER SLOT",8D
          ASC "(2) DATE/TIME ADJUSTMENT",8D
          ASC "(3) INSTALL PRODOS DRIVER",8D
          ASC "(4) EXIT",8D,8D
          ASC "CHOICE: "
MENUSTRE  EQU *
