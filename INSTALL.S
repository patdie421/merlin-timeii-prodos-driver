          LST OFF
          DSK INSTALL.L
          REL

PTR       EQU $ED
PTR2      EQU $EB

RWBUFFSZ  EQU $3000
* memory reservation
RWBUFF    EQU $5000      ; 12kb
FBUFF1    EQU $8000      ; 1kb for opened file
FBUFF2    EQU $8400      ; 1kb for opened file
TMPBUFF   EQU $8800      ; 512b
SYSFENTS  EQU  $8A00     ; 51x2b
SWPMMTMP  EQU $8B00      ; 128b
PREFIX    EQU $8C00      ; 64b
MYPATH    EQU $8C40      ; 64b
TMPSTR    EQU $8C80      ; 256b (overlap TMPSTR2)
TMPSTR2   EQU $8D00      ; 128b
BUFFSTR   EQU $8D80      ; 128b
_FREE1    EQU $8E00

          USE LIB/MONITOR.H
          USE LIB/PRODOS.H
          USE LIB/CMP.H
          USE LIB/INOUTDATA.H
          USE LIB/INOUTDATA.E
          USE LIB/STR.H
          USE LIB/STR.E
          USE LIB/ASC.H
          USE LIB/ASC.E
          USE LIB/MEM.H
          USE LIB/MEM.E

SLOT      EXT

BLKSZ     EQU $200


INSTINIT  ENT
          MEMINIT SWPMMTMP
          JSR GETPREFIX  ; get current prefix
          JSR TOREALPATH ; combine prefix and mypath
          LDA #0
          STA PATHNAME
          RTS


GETMYPATH ENT
          LDX PATHNAME
          BEQ :NOPATH
          LDY #0
          STY MYPATH
:LOOP1
          LDA PATHNAME,X
          AND #%01111111
          CMP #'/'
          BEQ :GETPATH
          DEX
          BNE :LOOP1
          JMP :NOPATH
:GETPATH
          DEX            ; remove '/' from path
          STX MYPATH
          LDY #0
:LOOP2
          CPY MYPATH
          BEQ :OKEXIT
          LDA PATHNAME+1,Y
          AND #%01111111
          STA MYPATH+1,Y
          INY
          JMP :LOOP2
:OKEXIT
          CLC
          RTS
:NOPATH
          SEC
          RTS


TOREALPATH ENT
          LDA MYPATH
          BEQ :ADDPREFIX
          LDA MYPATH+1
          CMP #'/'
          BEQ :END
:ADDPREFIX
          LDA #0
          STA TMPSTR
          LDA MYPATH
          BEQ :CPY
          LDY #0
:LOOP1
          CPY MYPATH
          BEQ :NEXT1
          LDA MYPATH+1,Y
          STA TMPSTR+1,Y
          INY
          JMP :LOOP1
:NEXT1
          DEY
          STY TMPSTR
:CPY
          LDY #0
          LDX #0
:LOOP2
          CPY PREFIX
          BEQ :NEXT2
          LDA PREFIX+1,Y
          STA MYPATH+1,Y
          INX
          INY
          JMP :LOOP2
:NEXT2
          STX MYPATH
          LDA TMPSTR
          BEQ :END
          LDA #'/'
          STA MYPATH+1,X
          INX
          LDY #0
:LOOP3
          CPY TMPSTR
          BEQ :NEXT3
          LDA TMPSTR+1,Y
          STA MYPATH+1,X
          INY
          INX
          JMP :LOOP3
:NEXT3
          INX
          STX MYPATH
:END
          RTS


GETPREFIX ENT
          JSR MLIERRCLR
          MLI_CALL GETPRFX;PREFIXP
          BCC :OK
          LDX "O"
          JMP MLIERROR
:OK
          LDA PREFIX
          BEQ :EXIT
          DEC PREFIX     ; remove last char of prefix str
:EXIT
          RTS


FILEDEL
          LDY #1
          STY :FIDX

          LDY PATHNAME
          STY :SAVLEN
          INY
          LDA #'/'
          STA PATHNAME,Y
          STY :PIDX
          LDX FILENAME
:LOOP
          INC :PIDX
          LDY :FIDX
          LDA FILENAME,Y
          LDY :PIDX
          STA PATHNAME,Y
          INC :FIDX
          DEX
          BNE :LOOP
          LDA :PIDX
          STA PATHNAME

          LDA #$00
          CMP DELFLAG
          BNE :ALT
          LDA #<PATHNAME
          STA DESTROYP+DS_PATH
          LDA #>PATHNAME+1
          STA DESTROYP+DS_PATH+1
          MLI_CALL DESTROY;DESTROYP
          JMP :EXIT
:ALT
          CMP #$FE       ; count only
          BEQ :EXIT
          STRPRNTL PATHNAME
:EXIT
          LDA :SAVLEN
          STA PATHNAME
          RTS
:SAVLEN   HEX 00
:PIDX     HEX 00
:FIDX     HEX 00
DELFLAG   HEX FF


FILECPY   ENT
          JMP :FILECPY
:SRCPTR   HEX 00,00      ; ptr to a str
:DSTPTR   HEX 00,00      ; ptr to a str
:FILECPY

          JSR MLIERRCLR
* open source
          LDA :SRCPTR
          STA OPENP1+OP_PATH
          LDA :SRCPTR+1
          STA OPENP1+OP_PATH+1
          MLI_CALL OPEN  ;OPENP1
          BCC :OK1
          LDX "G"
          JMP :ERREXIT
:OK1
* prepare source MLI data
          LDA OPENP1+OP_REF
          STA CLOSEP1+CL_REF
          STA READP+RD_REF
* prepare read/write MLI data
          LDA #<RWBUFF
          STA READP+RD_BUFF
          STA WRITEP+WR_BUFF
          LDA #>RWBUFF
          STA READP+RD_BUFF+1
          STA WRITEP+WR_BUFF+1
                         ; LDA #$00
          LDA #<RWBUFFSZ
          STA READP+RD_RCNT
                         ; LDA #$40
          LDA #>RWBUFFSZ
          STA READP+RD_RCNT+1
* prepare delete/create MLI data
          LDA :DSTPTR
          STA DESTROYP+DS_PATH
          STA OPENP2+OP_PATH
          STA CREATEP+CR_PATH
          LDA :DSTPTR+1
          STA DESTROYP+DS_PATH+1
          STA OPENP2+OP_PATH+1
          STA CREATEP+CR_PATH+1

* delete dest
          MLI_CALL DESTROY;DESTROYP

* create dest
          MLI_CALL CREATE;CREATEP
          BCC :OK2
          LDX "H"
          JMP :ERREXIT
:OK2
* open dest
          MLI_CALL OPEN  ;OPENP2
          BCC :OK3
          LDX "I"
          JMP :ERREXIT
:OK3
          LDA OPENP2+OP_REF
          STA CLOSEP2+CL_REF
          STA WRITEP+WR_REF

* copy loop
          LDY #0
:LOOP
          MLI_CALL READ  ;READP
          BCC :OK4
          LDX "J"
          JMP :EOFORERR
:OK4
          LDA READP+RD_TCNT
          STA WRITEP+WR_RCNT
          LDA READP+RD_TCNT+1
          STA WRITEP+WR_RCNT+1

          MLI_CALL WRITE ;WRITEP
          BCC :OK5
          LDX "C"
          JMP :ERREXIT
:OK5
          INY
          JMP :LOOP

:EOFORERR
          CMP #$4C       ; eof ?
          BEQ :EXIT      ; goto close and quit
          LDX #"E"       ; an error occured
          JMP :ERREXIT
:EXIT
* close dest
          MLI_CALL CLOSE ;CLOSEP1
          MLI_CALL CLOSE ;CLOSEP2
          RTS
* errors
:ERREXIT
          PHA
          TXA
          PHA
          LDA #0         ; close all opened files
          STA CLOSEP2+CL_REF
          MLI_CALL CLOSE ;CLOSEP2
          PLA
          TAX
          PLA
          JMP MLIERROR


* move file up in directory, like a bubble ...
BUBBLEUP
          LDA ENTLGH
          STA SWAPMEM+SWAPMEM_CNT
          LDX NBFOUND
          BEQ :EXIT
:LOOP
          CPX #1
          BEQ :EXIT
          TXA            ; X x 2 -> Y
          TAY
          DEY
          TYA
          ASL
          TAY

          LDA SYSFENTS,Y
          STA SWAPMEM+SWAPMEM_A
          LDA SYSFENTS+1,Y
          STA SWAPMEM+SWAPMEM_A+1
          DEY
          DEY
          LDA SYSFENTS,Y
          STA SWAPMEM+SWAPMEM_B
          LDA SYSFENTS+1,Y
          STA SWAPMEM+SWAPMEM_B+1

          JSR SWAPMEM

          DEX
          JMP :LOOP
:EXIT
          RTS


* write 4 buffers to volume directory (block 2 to 5)
WRVOLDIR  ENT
          JSR MLIERRCLR

          LDA #<RWBUFF
          STA WRITEBKP+WB_BUFF
          LDA #>RWBUFF
          STA WRITEBKP+WB_BUFF+1

          LDA DRVSLT
          STA WRITEBKP+WB_UNI
          LDA #2
          STA WRITEBKP+WB_BNUM
          LDA #0
          STA WRITEBKP+WB_BNUM+1

          LDY #4         ; 4 blocks to write
:LOOP
          MLI_CALL WRITEBK;WRITEBKP
          BCC :OK
          LDX #"Y"
          JMP MLIERROR
:OK
          DEY
          BEQ :EXIT
          INC WRITEBKP+WB_BNUM ; Next block
          LDA WRITEBKP+WB_BUFF ; Next buffer
          CLC
          ADC #<BLKSZ
          STA WRITEBKP+WB_BUFF
          LDA WRITEBKP+WB_BUFF+1
          ADC #>BLKSZ
          STA WRITEBKP+WB_BUFF+1
          JMP :LOOP
:EXIT
          RTS


INSTDRV   ENT
          JSR MLIERRCLR

          LDA #$00
          STA TMPSTR     ; source
          STA TMPSTR2    ; dest

          STRCPY MYPATH  ;TMPSTR;#2
          INC TMPSTR
          LDA #'/'
          LDY TMPSTR
          STA TMPSTR,Y
          STRCAT TMPSTR  ;INSTSRCSTR

          STRCPY PATHNAME;TMPSTR2;#2
          INC TMPSTR2
          LDA #'/'
          LDY TMPSTR2
          STA TMPSTR2,Y
          STRCAT TMPSTR2 ;TIMEIISTR

          LDA INSTTYPE
          CMP #"S"
          BNE :CONT1

          LDY TMPSTR2
          INY
          LDA #'S'
          STA TMPSTR2,Y
          INY
          LDA SLOT
          CLC
          ADC #'0'
          STA TMPSTR2,Y
          STY TMPSTR2
:CONT1
          STRADD SYSTEMSTR

          LDA #<TMPSTR
          STA FILECPY+3
          LDA #>TMPSTR
          STA FILECPY+4

          LDA #<TMPSTR2
          STA FILECPY+5
          LDA #>TMPSTR2
          STA FILECPY+6

          JSR FILECPY
          BCC :NEXT1
          RTS
:NEXT1    JSR  LOADVOL   ; reload file list from directory
          BCC :NEXT2
          RTS
:NEXT2    JSR FINDUPTOME
          JSR BUBBLEUP   ; move up ME
          JSR WRVOLDIR   ; write to disk
          BCC :EXIT
          RTS
:EXIT
          CLC
          RTS
INSTTYPE  ENT
          HEX 00

CNTDRV    ENT
          LDA #$FE
          JMP DELDRV1
LSTDRV    ENT
          LDA #$FF
          JMP DELDRV1
DELDRV    ENT
          LDA #$00
DELDRV1   STA DELFLAG
          LDA #0
          STA ERRNO
          STA DELFOUND
          LDA #<DELDRVCB ; set callback for file_iter
          STA CALLBACK+1
          LDA #>DELDRVCB
          STA CALLBACK+2
          JSR FILE_ITER  ; do iteration
          CLC
          RTS


DELDRVCB                 ; delete driver callback
          LDA #$FF
          CMP FILETYPE
          BNE :NEXTFILE
          STREWITH FILENAME;SYSTEMSTR ; cmp end of string
          BCS :NEXTFILE
          STRSWITH FILENAME;TIMEIISTR ; cmp start string
          BCS :NEXTFILE
          INC DELFOUND
          JSR FILEDEL
:NEXTFILE
          CLC            ; next file
          RTS
DELFOUND  ENT
          HEX 00


          DO 0
CATALOG
          LDA #<_CALLBACK ; set callback for file_i
          STA CALLBACK+1
          LDA #>_CALLBACK
          STA CALLBACK+2
          JSR FILE_ITER  ; do iation
          RTS
          FIN


FINDUPTOME
          LDA #0
          STA NBFOUND
          LDA #<FINDMECB ; set callback for file_i
          STA CALLBACK+1
          LDA #>FINDMECB
          STA CALLBACK+2
          JSR FILE_ITER  ; do iteration
          RTS
NBFOUND   ENT
          HEX 00         ; number of entry in SYSFENTS
                         ; SYSFENTS DS 51*2 ; Maximum 51 files in root dir


* CallBack for FILE_ITER
* list all SYS file with ".SYSTEM" extension and store
* Entry address in SYSFENTS table
FINDMECB
          LDA #$FF
          CMP FILETYPE
          BNE :EXITKO

          STREWITH FILENAME;SYSTEMSTR ; cmp end of string
          BCS :EXITKO

          LDA NBFOUND
          ASL
          TAY

          LDA ENTADDR
          STA SYSFENTS,Y
          LDA ENTADDR+1
          STA SYSFENTS+1,Y
          INC NBFOUND

          STRCMP MESTR   ;FILENAME
          BCS :EXITKO
          JMP :EXITOK
:EXITKO
          CLC            ; next file
          RTS
:EXITOK
          SEC            ; break itreration
          RTS


TOPTHNME  ENT            ; copy selection to PATHNAME
          TAY
          LDA KEYVOL,Y
          TAX
          LDA RWBUFF,X
          STA DRVSLT
          AND #%00001111
          STA PATHNAME
          INC PATHNAME
          LDA #'/'
          STA PATHNAME+1
          LDY #0
          INX
:LOOP
          LDA RWBUFF,X
          BEQ :EXIT
          STA PATHNAME+2,Y
          INY
          INX
          JMP :LOOP
:EXIT
          LDA DRVSLT
          AND #%11110000
          STA DRVSLT
          RTS
DRVSLT    HEX 00


GETVOLS   ENT
          JSR MLIERRCLR
          LDA #0
          STA ONLINEP+OL_UNI
          MLI_CALL ONLINE;ONLINEP
          BCC :OK1
          LDX "A"
          JMP MLIERROR
:OK1
          RTS


PRINTVOLS ENT
          LDA #0
          STA :COUNTER
          STA KEY
:LOOP1
          LDA :COUNTER
          ASL
          ASL
          ASL
          ASL
          TAX
          LDA RWBUFF,X
          BEQ :EXIT
          AND #%00001111
          BEQ :NEXT
          STA :LEN
:SAVX4KEY
          LDY KEY
          TXA
          STA KEYVOL,Y
:PRSELKEY
          LDA #"("
          JSR COUT
          LDA KEY
          INC KEY
          CLC
          ADC #"A"
          JSR COUT
          LDA #")"
          JSR COUT
          LDA #" "
          JSR COUT
          LDA #"/"
          JSR COUT

          LDY :LEN
:LOOP2
          INX
          LDA RWBUFF,X
          ORA #%10000000
          JSR COUT
          DEY
          BNE :LOOP2
          JSR CROUT
:NEXT
          INC :COUNTER
          JMP :LOOP1
:EXIT
          LDA :LEN
          RTS
:COUNTER  HEX 00
:LEN      HEX 00
:UNI      HEX 00
KEY       ENT
          HEX 00
KEYVOL    DS 16


LOADVOL   ENT
          JSR MLIERRCLR
          LDA #<PATHNAME
          STA OPENP1+OP_PATH
          LDA #>PATHNAME
          STA OPENP1+OP_PATH+1
          MLI_CALL OPEN  ;OPENP1
          BCC :OK2
          LDX #"B"
          JMP MLIERROR
:OK2
          LDA OPENP1+OP_REF
          STA CLOSEP1+CL_REF
          STA READP+RD_REF

          LDA #0
          STA BLKCNT     ; init block coun

          LDA #<RWBUFF
          STA READP+RD_BUFF
          LDA #>RWBUFF
          STA READP+RD_BUFF+1
          LDA #<BLKSZ
          STA READP+RD_RCNT
          LDA #>BLKSZ
          STA READP+RD_RCNT+1
:RDBLK                   ; read loop
          MLI_CALL READ  ;READP
          BCC :OK3
          LDX "C"
          JMP :EOFORERR
* next buffer block address
:OK3
          INC BLKCNT

          LDA #1
          CMP BLKCNT     ; is first block ?
          BNE :NEXT
* block number == 1
          LDA  RWBUFF+VD_FLCNT ; number of file
          BNE :OK4       ; not 0, get data
          JMP :EXIT      ; no file in directory
:OK4
          STA FLCNT      ; store files number
          LDA RWBUFF+VD_ENTLGH
          STA ENTLGH     ; store file entry length
          LDA RWBUFF+VD_ENTBLK
          STA ENTBLK     ; store entry per block
:NEXT
          LDA READP+RD_BUFF
          CLC
          ADC #<BLKSZ
          STA READP+RD_BUFF
          LDA READP+RD_BUFF+1
          ADC #>BLKSZ
          STA READP+RD_BUFF+1

          JMP :RDBLK
:EOFORERR
          CMP #$4C       ; eof ?
          BEQ :EXIT      ; goto close and quit
          LDX #"E"       ; an error occured
          JMP MLIERROR

:EXIT
          MLI_CALL CLOSE ;CLOSEP1
          RTS
ENTLGH    HEX 00         ; entry length
ENTBLK    HEX 00         ; nb entry per block
FLCNT     HEX 00         ; file_count
BLKCNT    HEX 00         ; block coun


FILE_ITER
          LDA #1
          STA :COUNTER
* init block ptr
          LDA #<RWBUFF
          STA PTR
          LDA #>RWBUFF
          STA PTR+1
* init file entry ptr
* poin to first file entry (af volume dir struct)
          LDA #<RWBUFF+VD_S_SIZE
          STA PTR2
          LDA #>RWBUFF+VD_S_SIZE
          STA PTR2+1
          LDA #1         ; on first block, 1st entry
          STA :NUM       ; is number 1
:ENTLOOP
          LDY #FE_NAMLGH
          LDA (PTR2),Y
          AND #$30
          BNE :NEXTA
          JMP :NEXTFE
:NEXTA    LDA (PTR2),Y
          AND #$0F
          STA FILENAME
          TAX
          INY
* store file data
:FNLOOP                  ; file name
          LDA (PTR2),Y
          STA FILENAME,Y
          INY
          DEX
          BNE :FNLOOP

          LDY #FE_FTYPE  ; file type
          LDA (PTR2),Y
          STA FILETYPE

          LDA :COUNTER
          STA BLKNUM

          LDA PTR2       ; entry address in block
          STA ENTADDR
          LDA PTR2+1
          STA ENTADDR+1

          PHP
          STA :SAVA
          STX :SAVX
          STY :SAVY
          JSR CALLBACK
          BCC :CONTINUE
          PLP
          JMP :EXIT
:CONTINUE
          LDY :SAVY
          LDX :SAVX
          LDA :SAVA
          PLP

:NEXTFE
          LDA PTR2
          CLC
          ADC ENTLGH
          STA PTR2
          BCC :NEXT1
          INC PTR2+1
:NEXT1    INC :NUM
          LDA :NUM
          CMP ENTBLK
          BCC :ENTLOOP
:NEXTBLK
          LDA :COUNTER
          CMP BLKCNT
          BEQ :EXIT
          INC :COUNTER
* move block ptr
          LDA PTR
          CLC
          ADC #<BLKSZ
          STA PTR
          LDA PTR+1
          ADC #>BLKSZ
          STA PTR+1
* set file entry ptr
          LDA PTR
          CLC
          ADC #$4
          STA PTR2
          LDA PTR+1
          ADC #$0
          STA PTR2+1

          LDA #$0        ; second block and more file
          STA :NUM       ; entry number start at 0

          JMP :ENTLOOP
:EXIT
          RTS
:SAVA     HEX 00
:SAVX     HEX 00
:SAVY     HEX 00
:COUNTER  HEX 00
:NUM      HEX 00
FILENAME  DS 16
FILETYPE  HEX 00
BLKNUM    HEX 00
ENTADDR   HEX 00,00
CALLBACK  JMP _CALLBACK  ; to modify to change callback

_CALLBACK                ; default callback
          LDA FILETYPE
          JSR PRBYTE
          LDA #" "
          JSR COUT
          STRPRNTL FILENAME
          CLC            ; continue
          RTS


MLIERRCLR
          LDA #0
          STA ERRNO
          STA ERRCOMP
          SEC
          RTS


MLIERROR
          STX ERRCOMP
          STA ERRNO
          JSR BELL
          JSR BELL
          JSR BELL
          SEC
          RTS
ERRNO     ENT
          HEX 00
ERRCOMP   ENT
          HEX 00


ONLINEP   D_ONLINE 00    ;RWBUFF
PREFIXP   D_GETPRFX PREFIX
DESTROYP  D_DESTROY $0000
CREATEP   D_CREATE $0000 ;$FF;$2000
OPENP1    D_OPEN PATHNAME;FBUFF1
OPENP2    D_OPEN $0000   ;FBUFF2
READP     D_READ 00      ;RWBUFF;RWBUFFSZ
WRITEP    D_WRITE 00     ;RWBUFF;RWBUFFSZ
WRITEBKP  D_WRITEBK 00   ;RWBUFF;$0000
CLOSEP1   D_CLOSE 00
CLOSEP2   D_CLOSE 00
* QUITP D_QUIT
TIMEIISTR STR 'TIMEII'
SYSTEMSTR STR '.SYSTEM'
MESTR     STR 'TIMEII.SYSTEM'
INSTSRCSTR STR 'TIMEII.INST'
