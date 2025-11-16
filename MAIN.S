          LST OFF
          REL
          DSK OBJ/MAIN.L

SETDATE    EXT

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

          USE INSTALL.E
          USE INSTGUI.E


INIT      ENT

          JSR GETMYPATH  ; get launch path
* init timeii lib
          LDA #<DATE
          STA DATIDATE
          LDA #>DATE
          STA DATIDATE+1
* init strings
          JSR _MENUSTR
MAIN
          JSR HOME
          STRCENTER TITLESTR;40
          STRPRNT TITLESTR
          JSR CROUT2
          JSR GETSLOT
          INITII SLOT

MENU
          JSR HOME
          JSR DISPSLOT   ; display slot
          JSR GETIIDATE
          STRPRNT DATESTR
          JSR PRNIIDATE
          JSR ISIIDATE
          BCC :MENU1
          LDY #$7F
          JSR SETIFLG
          STRPRNT INVALSTR
          JSR SETNORM
          JSR CROUT2
:MENU1
          STRPRNT MENUSTR
:GETKEY
          JSR GETKEY
:1
          CMP #"1"       ; set slot
          BNE :2
          JSR GETSLOT
          INITII SLOT
          JMP MENU
:2
          CMP #"2"       ; set date/time
          BNE :3
          JSR SETDATE
          JMP MENU
:3
          CMP #"3"
          BNE :4
          JSR INSTALLDRV
          JMP MENU
:4
          CMP #"4"
          BNE :GETKEY
          JMP QUIT1
:NEXT
          JMP MENU


CROUT2
          JSR CROUT
          JSR CROUT
          RTS


DISPSLOT  ENT
          STRCENTER  TITLESTR;40
          STRPRNTL  TITLESTR
          STRCENTER  SLOTSTR;40
          STRPRNT  SLOTSTR
          LDA #$88
          JSR COUT
          JSR COUT
          LDA SLOT
          JSR PRBYTE
          JSR CROUT2
          RTS


GETSLOT
          LDA #0
          BOX #7         ;#6;#26;#6;GSLOTTTL
          JSR CROUT
          STRPRNT  GSLOTSTR
          LDA CH
          STA :SAVCH
:GET1NUM  JSR GET1NUM
:EXIT     BCC :NEXT      ; ctrl-c
          RTS
:NEXT
          SEC
          SBC #"0"
          BEQ :GETSLOT   ; Slot must be in 1,2,4,5,6,7
          CMP #3         ; exclude 3
          BEQ :GETSLOT
          CMP #8
          BCS :GETSLOT   ; < 8
          STA SLOT       ; we have a valid slot
          JSR CROUT2
          RWINDOW
          RTS
:GETSLOT
          LDA :SAVCH
          STA CH
          JSR CLREOL
          JMP :GET1NUM
:SAVCH    HEX 00


QUIT1
          MLI_CALL QUIT  ;QUITP
          BRK
QUITP     D_QUIT

SLOT      ENT
          HEX 00
DATE      ENT
          HEX 00,00,00,00,00,00,00,00

GSLOTTTL  STR " TIMEII CARD SLOT ? "
GSLOTSTR  STR "   1,2,4,5,6 or 7:"
SLOTSTR   STR "SLOT: __"
INVALSTR  STR "INVALID DATE! CHECK SLOT AND/OR AJSUT IT"
TITLESTR  STR "TIME II CLOCK CARD"
YOURSTR   STR "YOUR DATE: "
CRRCTSTR  STR "CONFIRM DATE ADJUSTMENT (Y/N)? "
DATESTR   STR "CURRENT DATE: "
MENUSTR   HEX 00
MENUSTRS  ASC "TIMEII CARD CONFIGURATION:",8D,8D
          ASC "(1) SELECT AN OTHER SLOT",8D
          ASC "(2) DATE/TIME ADJUSTMENT",8D
          ASC "(3) INSTALL PRODOS DRIVER",8D
          ASC "(4) EXIT",8D,8D
          ASC "CHOICE: "
MENUSTRL  EQU *-MENUSTRS-1
_MENUSTR  LDA #<MENUSTRL
          STA MENUSTR
          RTS
END       EQU *
