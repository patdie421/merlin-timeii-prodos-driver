          LST OFF
          DSK OBJ/INSTGUI.L
          REL

          USE MEMALLOC.H
          USE LIB/MONITOR.H
          USE LIB/PRODOS.H
          USE LIB/INOUTDATA.H
          USE LIB/INOUTDATA.E
          USE LIB/CMP.H
          USE LIB/STR.H
          USE LIB/STR.E
          USE LIB/ASC.H
          USE LIB/ASC.E
          USE LIB/FORMS.H
          USE LIB/FORMS.E
* USE INSTALL.H
          USE INSTALL.E


CLINE     MAC
          LDA ]1
          LDY ]2
LOOP
          JSR COUT
          DEY
          BNE LOOP
          <<<


CROUT2
          JSR CROUT
          JSR CROUT
          RTS


KPRESS
          STRPRNT KPRESS_S
          JSR GETKEY
          JSR RWINDOW2
          RTS


INSTALLDRV ENT
          JSR INSTINIT
          JSR MENUINST
          RTS


RWINDOW2
          PHA
          RWINDOW
          PLA
          RTS


PRNTWAIT
          JSR RWINDOW2
          JSR HOME
          LDA #12
          STA CV
          STRCENTER WAIT_S;40
          JSR VTAB
          JSR SETINV
          STRPRNTL WAIT_S
          JSR SETNORM
          RTS


MENUINST  ENT
          JSR HOME
          STRCENTER :MENUINST_S;40
          STRPRNTL :MENUINST_S
          JSR CROUT2
          STRPRNTL :SRCPTH_S
          STRPRNTL MYPATH
          JSR CROUT2
          STRPRNTL :DESTVOL_S
          STRPRNTL PATHNAME
          ASCPRNT :INSTASC
          STRPRNT CHOICE_S
:LOOP     JSR GETKEY
          CMP #"1"
          BNE :NEXT1
          JSR CHPREF
          CMP #$FF
          BEQ :EXIT
          JMP MENUINST
:NEXT1
          CMP #"2"
          BNE :NEXT2
          JSR BOXSEL
          JMP MENUINST
:NEXT2
          CMP #"3"
          BNE :NEXT3
          JSR DOINST
          JMP MENUINST
:NEXT3
          CMP #"4"
          BNE :NEXT4
          JSR DODEL
          JMP MENUINST
:NEXT4
          CMP #"5"
          BNE :NEXT5
          JMP :EXIT
:NEXT5
          JMP :LOOP
:EXIT
          RTS
:MENUINST_S STR "INSTALL DRIVER"
:SRCPTH_S STR "SOURCE PREFIX:"
:DESTVOL_S STR "TARGET VOLUME: "
:INSTASC  HEX 8D,8D
          ASC "(1) CHANGE SOURCE PREFIX",8D
          ASC "(2) SELECT VOLUME",8D
          ASC "(3) INSTALL DRIVER TO TARGET",8D
          ASC "(4) REMOVE DRIVER FROM TARGET",8D
          ASC "(5) RETURN TO MAIN MENU",8D
          HEX 8D,00


CHPREF
          STRCPY MYPATH  ;TMPSTR;#1
          BOX #3         ;#7;#34;#5;:NEWPREFT
          GETSTRW TMPSTR ;#63;LCHARS
          BCS :EXIT
          STRCPY TMPSTR  ;MYPATH;#2
:EXIT
          JSR RWINDOW2
          RTS
:NEWPREFT STR " NEW PREFIX "


DOINST    ENT
          JSR CHKVOL
          BCC :NEXT1
          RTS
:NEXT1    JSR LOADVOL    ; load file list from directory
          JSR CNTDRV     ; count driver files on volume
          LDA DELFOUND
          BNE :KO1
          JMP :NEXT2
:KO1
          BOX #3         ;#7;#34;#7;:ARINSTT
          STRCENTER :ARINST1;32
          STRPRNTL :ARINST1
          STRCENTER :ARINST2;32
          STRPRNT :ARINST2
          JSR CROUT2
          STRCENTER KPRESS_S;32
          JSR KPRESS
          SEC
          JMP :EXIT
:NEXT2
          BOX #4         ;#6;#32;#7;:GENORSLTT_S
          STRCENTER :GENORSLT1_S;30
          STRPRNTL :GENORSLT1_S
          STRCENTER :GENORSLT2_S;30
          STRPRNT :GENORSLT2_S
          JSR CROUT2
          STRCENTER CHOICE_S;30
          STRPRNT CHOICE_S
:LOOP
          JSR GETKEY
          AND #$DF
          CMP #"S"
          BEQ :NEXT3
          CMP #"G"
          BEQ :NEXT3
          JMP :LOOP
:NEXT3
          STA INSTTYPE
          JSR PRNTWAIT
          JSR INSTDRV
          BCC :SUCCESS
:ERROR
          JSR ERROR
          SEC
          RTS
:SUCCESS
          BOX #6         ;#7;#28;#6;SUCCES_S
          STRCENTER :SUCCMSG;26
          STRPRNT :SUCCMSG
          JSR CROUT2
          STRCENTER KPRESS_S;26
          JSR KPRESS
          CLC
:EXIT
          RTS
:ARINSTT  STR " ALLREADY INSTALLED "
:ARINST1  STR "DRIVER FILE FOUND ON VOLUME."
:ARINST2  STR "REMOVE IT BEFORE INSTALLATION."
:SUCCMSG  STR "DRIVER INSTALLED"
:GENORSLTT_S STR "INSTALLATION TYPE"
:GENORSLT1_S STR "(S)LOT BINDED OR (G)ENERIC"
:GENORSLT2_S STR "INSTALLATION ?"


DODEL
          JSR CHKVOL
          BCC :NEXT1
          RTS
:NEXT1    JSR LOADVOL    ; load file list from directory
          BCC :NEXT2
          JMP :ERROR
:NEXT2    JSR CNTDRV     ; count driver files on volume
          LDA DELFOUND
          BNE :NEXT
          BOX #6         ;#7;#28;#6;:NOTFNDT
          STRCENTER :NOTFND;26
          STRPRNT :NOTFND
          JSR CROUT2
          STRCENTER KPRESS_S;26
          JSR KPRESS
          JMP :EXIT
:NEXT
          CLC
          ADC #7
          STA :HBOXSZ
          BOX #4         ;#6;#32;:HBOXSZ;CONFIRM_S
          STRPRNT :WLBEDEL
          JSR CROUT2
          JSR LSTDRV
          JSR CROUT
          STRCENTER CONFYN_S;30
          STRPRNT CONFYN_S
:LOOP
          JSR GETKEY
          AND #$DF
          CMP #"Y"
          BEQ :DEL
          CMP #"N"
          BNE :LOOP
          JSR RWINDOW2
          SEC
          JMP :EXIT
:DEL
          JSR PRNTWAIT
          JSR DELDRV
          BCC :SUCCES
:ERROR
          JSR ERROR
          SEC
          RTS
:SUCCES
          BOX #6         ;#7;#28;#6;SUCCES_S
          STRCENTER :SUCCMSG;26
          STRPRNT :SUCCMSG
          JSR CROUT2
          STRCENTER KPRESS_S;26
          JSR KPRESS
          CLC
:EXIT
          RTS
:NOTFNDT  STR " NOT FOUND "
:NOTFND   STR "NO DRIVER FILE ON VOLUME"
:WLBEDEL  STR "THIS FILE(S) WILL BE DELETED:"
:SUCCMSG  STR "FILE(S) DELETED"
:HBOXSZ   HEX 00


ERROR
          BOX #6         ;#7;#28;#6;ERROR_S
          STRCENTER :ERRMSG;22
          STRPRNT :ERRMSG
          LDA ERRNO
          JSR PRBYTE
          LDA #"-"
          JSR COUT
          LDA ERRCOMP
          JSR COUT
          JSR CROUT2
          STRCENTER KPRESS_S;26
          JSR KPRESS
          RTS
:ERRMSG   STR "ERROR: "


CHKVOL
          LDA PATHNAME
          BNE :NEXT1
          BOX #4         ;#7;#32;#6;INFO_S
          STRCENTER NOVOL;30
          STRPRNTL NOVOL
          STRCENTER KPRESS_S;30
          JSR KPRESS
          SEC
          RTS
:NEXT1
          CLC
          RTS


BOXSEL
          BOX #3         ;#2;#34;#20;:MENUSEL_S
:SCAN     JSR GETVOLS
          JSR HOME
          JSR PRINTVOLS  ; print volumes + char index
          STA :TMP
          LDA #13
          SEC
          SBC :TMP
          TAY
:LOOP
          TYA
          PHA
          JSR CROUT
          PLA
          TAY
          DEY
          BNE :LOOP
          STRPRNTL :RSCAN_S
          STRPRNT :QMENU_S
          JSR CROUT2
          STRPRNT CHOICE_S
          JSR SELVOL     ; choose a volume
          BCC :NEXT
          CMP #$FF
          BEQ :SCAN
          SEC
          JMP :EXIT
:NEXT
          JSR TOPTHNME   ; copy selection to PATHNAME
:EXIT
          JSR RWINDOW2
          RTS
:MENUSEL_S STR " VOLUME SELECTION "
:RSCAN_S  STR "(1) RESCAN VOLUMES"
:QMENU_S  STR "(2) ABORT SELECTION"
:TMP      HEX 00


* select volume
SELVOL
          LDA KEY
          CLC
          ADC #"A"
          STA :MAXKEY
          BEQ :GETCHAR
          DEC :MAXKEY
:GETCHAR
          JSR GETKEY
          A_EQU #$83     ;:NCEXIT ; ctrl-c
          A_EQU #"1"     ;:RESCAN
          A_EQU #"2"     ;:NCEXIT
          AND #$DF
          A_ULOW #"A"    ;:GETCHAR
          A_UGTR :MAXKEY ;:GETCHAR
          JMP :EXIT
:RESCAN
          LDA #$FF
          SEC
          RTS
:NCEXIT
          LDA #0
          SEC
          RTS            ; exit with error
:EXIT
          SEC
          SBC #"A"
          CLC            ; no error
          RTS
:MAXKEY   HEX 00


CHOICE_S  STR "YOUR CHOICE:"
KPRESS_S  STR "PRESS ANY KEY"
CONFIRM_S STR "OK TO PROCESS ?"
CONFYN_S  STR "CONFIRM (Y/N):"
WAIT_S    STR "PLEASE WAIT"
INFO_S    STR " ALERT "
SUCCES_S  STR " SUCCESS "
ERROR_S   STR " ERROR "
NOVOL     STR "PLEASE, CHOICE A VOLUME FIRST"
LCHARS    STR "./"
