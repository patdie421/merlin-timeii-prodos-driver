           LST     OFF
           DSK     OBJ/INSTALL.L
           REL

DEBUG      EQU     0

PTR1       EQU     $ED
PTR2       EQU     $EB

           USE     MEMALLOC.H
           USE     LIB/MONITOR.H
           USE     LIB/PRODOS.H
           USE     LIB/CMP.H
           USE     LIB/INOUTDATA.H
           USE     LIB/INOUTDATA.E
           USE     LIB/STR.H
           USE     LIB/STR.E
           USE     LIB/ASC.H
           USE     LIB/ASC.E
           USE     LIB/MEM.H
           USE     LIB/MEM.E

SLOT       EXT

BLKSZ      EQU     $200


INSTINIT   ENT
           MEMINIT SWPMMTMP        ; clean memory for mem swaping
           JSR     GETPREFIX       ; get current prefix
           BCS     :EXIT
           JSR     TOREALPATH      ; combine prefix and mypath
           LDA     #0
           STA     PATHNAME        ; reset PATHNAME
:EXIT      RTS


********************************
GETMYPATH  ENT
*
* read "my path" from "command line" and store it in MYPATH
* PATHNAME = /EX/AMPLE/CMD => MYPATH = /EX/AMPLE
*
* in: PATHNAME (PRODOS.H.S)
* out: MYPATH (MEMALLOC.H.S)
* A,X,Y modified
*
********************************
           LDX     PATHNAME        ; pointer to last char
           BEQ     :NOPATH         ; is 0 (PATHNAME empty)
           LDY     #0              ; by default MYPATH is empty
           STY     MYPATH
:LOOP1                             ; find last '/' of PATHNAME
           LDA     PATHNAME,X
           AND     #%01111111      ; char to ascii
           CMP     #'/'
           BEQ     :GETPATH        ; '/' found
           DEX                     ; not found check previous char
           BNE     :LOOP1
           BEQ     :NOPATH         ; ~ JMP :NOPATH
:GETPATH
           DEX                     ; pointer before last '/'
           STX     MYPATH          ; fix MYPATH size
* copy PATHNAME to MYPATH len
           LDY     #0              ; dest char point
:LOOP2
           CPY     MYPATH          ; Y = MYPATH len ?
           BEQ     :OKEXIT         ; yes, copy done
           LDA     PATHNAME+1,Y
           AND     #%01111111      ; to ascii
           STA     MYPATH+1,Y
           INY
           BNE     :LOOP2          ; JMP :LOOP2
:OKEXIT
           CLC
           RTS
:NOPATH
           SEC
           RTS


********************************
TOREALPATH ENT
*
* Convert MYPATH to asbolute path :
* MYPATH = /XX/YY => MYPATH = /XX/YY
* MYPATH = XX/YY  => MYPATH = PREFIX/XX/YY
* MYPATH = '' <empty string> => MYPATH = PREFIX
*
* in: PREFIX (MEMALLOC.H.S)
* in/out: MYPATH (MEMALLOC.H.S)
* A,X,Y modified
*
********************************
           LDA     #0              ; init vars
           TAY                     ; and Y=0
           STA     TMPSTR          ; empty TMPSTR
* MYPATH = ''
           CMP     MYPATH          ; is MYPATH 0 length string
           BEQ     :COPYPRFX       ; empty path => MYPATH = PREFIX
           LDA     MYPATH+1
           CMP     #'/'            ; first char is "/" : absolute path
           BEQ     :EXIT           ; prefix not used => MYPATH is REALPATH

* MYPATH = XX/YY
:LOOP1                             ; save MYPATH to TMPSTR
           CPY     MYPATH
           BEQ     :NEXT1
           LDA     MYPATH+1,Y
           STA     TMPSTR+1,Y
           INY
           BNE     :LOOP1          ; JMP :LOOP1
:NEXT1
           DEY
           STY     TMPSTR
* copy PREFIX to MYPATH
:COPYPRFX
           LDY     #0
           LDX     #0
:LOOP2
           CPY     PREFIX
           BEQ     :NEXT2
           LDA     PREFIX+1,Y
           STA     MYPATH+1,Y
           INX
           INY
           BNE     :LOOP2          ; JMP :LOOP2
:NEXT2
           STX     MYPATH
           LDA     TMPSTR
           BEQ     :EXIT           ; TMPSTR empty string MYPATH is good
* append '/' to MYPATH
           LDA     #'/'
           STA     MYPATH+1,X
           INX
* append TMPSTR to MYPATH
           LDY     #0
:LOOP3
           CPY     TMPSTR
           BEQ     :NEXT3
           LDA     TMPSTR+1,Y
           STA     MYPATH+1,X
           INY
           INX
           BNE     :LOOP3
:NEXT3
           INX
           STX     MYPATH
:EXIT
           RTS


********************************
GETPREFIX  ENT
*
* GET current prefix from PRODOS
* out: PREFIX (MEMALLOC.H.S)
* A,X,Y modified
*
********************************
           JSR     MLIERRCLR
           MLI_CALL GETPRFX;PREFIXP
           BCC     :OK
           LDX     "O"             ; error exit code
           JMP     MLIERROR
:OK
           LDA     PREFIX
           BEQ     :EXIT
           DEC     PREFIX          ; remove last char (/) from prefix str
:EXIT
           RTS


********************************
FILEDEL
*
* delete file from volume
* (used by DELDRVCB)
* in: FILENAME (see FILE_ITER)
* in: PATHNAME (PRODOS.H.S) : path of file to delete (basename)
*     (PATHNAME is modified during operation but restored
*     before exit)
* A,X,Y modified
*
********************************
* append filename to pathname: PATHNAME+"/"+FILENAME -> PATHNAME
           LDA     PATHNAME        ; get PATHNAME (PRODOS.H.S) length
           PHA                     ; save for exit clean up
           TAX                     ; X is the PATHNAME pointer
* append '/' to PATHNAME
           INX                     ; X pointer to last PATHNAME char + 1
           LDA     #'/'            ; add '/' ...
           STA     PATHNAME,X      ; to end of PATHNAME
           LDA     FILENAME        ; init countdown counter ...
           STA     :CNTR           ; with FILENAME length
* append FILENAME to PATHNAME
           LDY     #0              ; Y is now the FILENAME pointer
:LOOP                              ; char by char copy
           INY                     ; next FILENAME char position
           INX                     ; next PATHNAME char position
           LDA     FILENAME,Y      ; copy FILENAME char
           STA     PATHNAME,X      ; to PATHNAME
           DEC     :CNTR           ; An other char to copy ?
           BNE     :LOOP
           STX     PATHNAME        ; update PATHNAME length
* real file deletion or simulation ?
           LDA     DELFLAG         ; test delete option
           BNE     :NOTDEL         ; not zero, no deletion
* MLI call to delete file
           LDA     #<PATHNAME      ; DEFLAG = 0 => real deletion
           STA     DESTROYP+DS_PATH ; update data in MLI structure
           LDA     #>PATHNAME
           STA     DESTROYP+DS_PATH+1
           MLI_CALL DESTROY;DESTROYP ; and delete file call
           JMP     :EXIT           ; Always exit after MLI call
                                   ; no error handling
:NOTDEL                            ; other deletion options
           CMP     #$FE            ; do nothing if DELFLAG = #$FE
           BEQ     :EXIT
           STRPRNTL PATHNAME       ; print PATHNAME if DEFLAG != 0 and != #$FE
:EXIT
           PLA                     ; restore PATHNAME (reset original length)
           STA     PATHNAME        ; before exit
           RTS
:CNTR      HEX     00
DELFLAG    HEX     FF


********************************
FILECPY    ENT
*
* copy file
* in: :SRCPTR - address of source filename (FILECPY+3)
* in: :DSTPTR - address of destination filename (FILECPY+5)
* A,X,Y modified
*
********************************
           JMP     :FILECPY
:SRCPTR    HEX     00,00           ; ptr to a str
:DSTPTR    HEX     00,00           ; ptr to a str
:FILECPY
           JSR     MLIERRCLR
* open source
           LDA     :SRCPTR
           STA     OPENP1+OP_PATH
           LDA     :SRCPTR+1
           STA     OPENP1+OP_PATH+1
           MLI_CALL OPEN;OPENP1
           BCC     :OK1
           LDX     "G"
           JMP     :ERREXIT
:OK1
* prepare source MLI data
           LDA     OPENP1+OP_REF
           STA     CLOSEP1+CL_REF  ; close file data
           STA     READP+RD_REF    ; read file data
* prepare read/write MLI data
           LDA     #<RWBUFF        ; buffer shared
           STA     READP+RD_BUFF   ; for read
           STA     WRITEP+WR_BUFF  ; and write
           LDA     #>RWBUFF
           STA     READP+RD_BUFF+1
           STA     WRITEP+WR_BUFF+1
           LDA     #<RWBUFFSZ      ; adjust buffer size
           STA     READP+RD_RCNT
           LDA     #>RWBUFFSZ
           STA     READP+RD_RCNT+1
* prepare delete/create MLI data
           LDA     :DSTPTR
           STA     DESTROYP+DS_PATH
           STA     OPENP2+OP_PATH
           STA     CREATEP+CR_PATH
           LDA     :DSTPTR+1
           STA     DESTROYP+DS_PATH+1
           STA     OPENP2+OP_PATH+1
           STA     CREATEP+CR_PATH+1
* delete dest
           MLI_CALL DESTROY;DESTROYP ; delete dest if exist
* create dest
           MLI_CALL CREATE;CREATEP
           BCC     :OK2
           LDX     "H"
           JMP     :ERREXIT
:OK2
* open dest
           MLI_CALL OPEN;OPENP2
           BCC     :OK3
           LDX     "I"
           JMP     :ERREXIT
:OK3
* update MLI structure for dest file
           LDA     OPENP2+OP_REF
           STA     CLOSEP2+CL_REF
           STA     WRITEP+WR_REF
* copy loop
           LDY     #0
:LOOP
           MLI_CALL READ;READP
           BCC     :OK4
           LDX     "J"
           JMP     :EOFORERR
:OK4
           LDA     READP+RD_TCNT
           STA     WRITEP+WR_RCNT
           LDA     READP+RD_TCNT+1
           STA     WRITEP+WR_RCNT+1
           LDA     #$0
           STA     WRITEP+WR_TCNT
           STA     WRITEP+WR_TCNT+1

           MLI_CALL WRITE;WRITEP
           BCC     :OK5
           LDX     "C"
           BNE     :ERREXIT        ; JMP :ERREXIT
:OK5
           INY
           BNE     :LOOP           ; JMP :LOOP
:EOFORERR                          ; eof or error ?
           CMP     #$4C            ; eof ?
           BEQ     :EXIT           ; goto close and quit
           LDX     #"E"            ; an error occured
           BNE     :ERREXIT        ; JMP :ERREXIT
:EXIT
* close source and dest
           MLI_CALL CLOSE;CLOSEP1
           MLI_CALL CLOSE;CLOSEP2
           RTS
* errors
:ERREXIT
           PHA
           TXA
           PHA
           LDA     #0              ; close all opened files
           STA     CLOSEP2+CL_REF
           MLI_CALL CLOSE;CLOSEP2
           PLA
           TAX
           PLA
           JMP     MLIERROR


********************************
BUBBLEUP
*
* move file up in directory structure, like a bubble ...
*
* in: SYSFENTS (MEMALLOC.H), table of ptr to file in
*     file entry structure (see B.2.4 - File Entries
*     from https://prodos8.com/docs/techref/file-organization/)
*     SYSFENTS is populate before by FINDUPTOME
* in: NBFOUND, number of file entry in SYSFENTS
* in: ENTLGH, size of file entry structure
* A,X,Y modified
*
********************************
           LDX     NBFOUND         ; if no .SYSTEM file found
           BEQ     :EXIT           ; nothing to do
           LDA     ENTLGH          ; cf PRODOS.H
           STA     SWAPMEM1+SWAPMEM_CNT
* from end to begining swap successively file
* entry in directory struct
:LOOP
           CPX     #1              ; only one .SYSTEM file remaining ?
           BEQ     :EXIT           ; it is allway in first position
           DEX                     ; X = X-1 (X is allways > 1 & <= 51)
           TXA                     ; A = X
           ASL                     ; A = A * 2
           TAY                     ; => Y = (X-1) * 2
                                   ; INX ; restore X

           LDA     SYSFENTS,Y      ; address off file entry #1 to swap
           STA     SWAPMEM1+SWAPMEM_A
           LDA     SYSFENTS+1,Y
           STA     SWAPMEM1+SWAPMEM_A+1
           DEY
           DEY
           LDA     SYSFENTS,Y      ; address off file entry #2 to swap
           STA     SWAPMEM1+SWAPMEM_B
           LDA     SYSFENTS+1,Y
           STA     SWAPMEM1+SWAPMEM_B+1

           JSR     SWAPMEM1

                                   ; DEX
           BNE     :LOOP           ; JMP :LOOP
:EXIT
           RTS


********************************
GETVOLS    ENT
*
* list volumes available from PRODOS
*
* out: RWBUFF (cf MLI structure ONLINEP)
* A,X,Y modified
*
********************************
           JSR     MLIERRCLR
           LDA     #0
           STA     ONLINEP+OL_UNI
           MLI_CALL ONLINE;ONLINEP
           BCC     :OK1
           LDX     "A"
           JMP     MLIERROR
:OK1
           RTS


********************************
PRINTVOLS  ENT
*
* print (using COUNT) volumes list.
* name of volume is prefixed by a letter in parentheses
*
* in: RWBUFF (update by GETVOLS).
*     Name is in 16 bytes block
* out: KEYVOL, table of byte index in RWBUFF of volume info
*      (drive, slot, name length - 1 byte and name - 15 bytes)
* A,X,Y modified
*
********************************
           LDA     #0
           STA     KEY
           STA     :COUNTER
* BEQ :FIRSTL ; zero did'nt need x16 code
:LOOP1
           LDA     :COUNTER
           ASL
           ASL
           ASL
           ASL
:FIRSTL    TAX     X = :COUNTER * 16
           LDA     RWBUFF,X        ; read dev and filename length
           BEQ     :EXIT           ; null => no more volume
           AND     #%00001111      ; get Volume name length
           BEQ     :NEXT
           STA     :LEN            ; save length
:SAVX4KEY
           LDY     KEY
           TXA
           STA     KEYVOL,Y        ; key trace of X (byte index of file)
:PRSELKEY
* print (<letter>) [A,B,C,D,...]
           LDA     #"("
           JSR     COUT
           LDA     KEY
           CLC
           ADC     #"A"
           JSR     COUT
           LDA     #")"
           JSR     COUT
           LDA     #" "
           JSR     COUT
           LDA     #"/"
           JSR     COUT
           INC     KEY             ; next letter
* volumename print loop
           LDY     :LEN
:LOOP2
           INX
           LDA     RWBUFF,X
           ORA     #%10000000
           JSR     COUT
           DEY
           BNE     :LOOP2
           JSR     CROUT
:NEXT                              ; next volumename
           INC     :COUNTER
           BNE     :LOOP1          ; JMP :LOOP1
:EXIT
           LDA     :LEN
           RTS
:COUNTER   HEX     00
:LEN       HEX     00
:UNI       HEX     00
KEY        ENT
           HEX     00
KEYVOL     DS      16


********************************
LOADVOL    ENT
*
* load all directory structure from volume
* and store in RWBUFF. Read block by block.
*
* in: PATHNAME, name of volume to read
* out: RWBUFF, all block of file entries
* A,X,Y modified
*
********************************
           JSR     MLIERRCLR
           LDA     #<PATHNAME
           STA     OPENP1+OP_PATH
           LDA     #>PATHNAME
           STA     OPENP1+OP_PATH+1
           MLI_CALL OPEN;OPENP1    ; open a read volume or directory
                                   ; get directory file list
           BCC     :OK2
           LDX     #"B"
           JMP     MLIERROR
:OK2
           LDA     OPENP1+OP_REF
           STA     CLOSEP1+CL_REF
           STA     READP+RD_REF
* block read initialisation
           LDA     #0
           STA     BLKCNT          ; init block count
           LDA     #<RWBUFF
           STA     READP+RD_BUFF
           LDA     #>RWBUFF
           STA     READP+RD_BUFF+1
           LDA     #<BLKSZ
           STA     READP+RD_RCNT
           LDA     #>BLKSZ
           STA     READP+RD_RCNT+1
:RDBLK                             ; read loop
           MLI_CALL READ;READP
           BCC     :OK3
           LDX     "C"
           BNE     :EOFORERR       ; JMP :EOFORERR
* next buffer block address
:OK3
           INC     BLKCNT          ; update counter
           LDA     #1
           CMP     BLKCNT          ; is this the first block ?
           BNE     :NEXT
* block number == 1
           LDA     RWBUFF+VD_FLCNT  ; number of file
           BEQ     :EXIT
:OK4
           STA     FLCNT           ; store files number
           LDA     RWBUFF+VD_ENTLGH
           STA     ENTLGH          ; store file entry length
           LDA     RWBUFF+VD_ENTBLK
           STA     ENTBLK          ; store entry per block
:NEXT                              ; prepare read of next block
* calc RD_BUFF = RD_BUFF + BLKSZ
           LDA     READP+RD_BUFF
           CLC
           ADC     #<BLKSZ
           STA     READP+RD_BUFF
           LDA     READP+RD_BUFF+1
           ADC     #>BLKSZ
           STA     READP+RD_BUFF+1
           JMP     :RDBLK          ; goto read next block
:EOFORERR
           CMP     #$4C            ; eof ?
           BEQ     :EXIT           ; goto close and quit
           LDX     #"E"            ; an error occured
           JMP     MLIERROR

:EXIT
           MLI_CALL CLOSE;CLOSEP1
           RTS
ENTLGH     HEX     00              ; entry length
ENTBLK     HEX     00              ; nb entry per block
FLCNT      HEX     00              ; file_count
BLKCNT     HEX     00              ; block count



********************************
WRVOLDIR   ENT
*
* write 4 buffer blocks to volume directory (block 2 to 5)
*
* in: RWBUFF, buffer of 2048 (4x512) bytes to write
* in: DRVSLT (write_block is done with Drive and Slot)
*     see TOPTHNME
* A,X,Y modified
*
********************************
           JSR     MLIERRCLR
           LDA     #<RWBUFF
           STA     WRITEBKP+WB_BUFF
           LDA     #>RWBUFF
           STA     WRITEBKP+WB_BUFF+1
           LDA     DRVSLT          ; set drive and slot
           STA     WRITEBKP+WB_UNI
           LDA     #2
           STA     WRITEBKP+WB_BNUM
           LDA     #0
           STA     WRITEBKP+WB_BNUM+1

           LDY     #4              ; 4 blocks to write
:LOOP
           MLI_CALL WRITEBK;WRITEBKP
           BCC     :OK
           LDX     #"Y"
           JMP     MLIERROR
:OK
           DEY
           BEQ     :EXIT
           INC     WRITEBKP+WB_BNUM ; Next block
           LDA     WRITEBKP+WB_BUFF ; Next buffer
           CLC
           ADC     #<BLKSZ
           STA     WRITEBKP+WB_BUFF
           LDA     WRITEBKP+WB_BUFF+1
           ADC     #>BLKSZ
           STA     WRITEBKP+WB_BUFF+1
           JMP     :LOOP           ; next block
:EXIT
           RTS


********************************
INSTDRV    ENT
*
* install driver to volume (copy file)
*
********************************
           JSR     MLIERRCLR
* init string
           LDA     #$00
           STA     TMPSTR          ; source
           STA     TMPSTR2         ; dest

           STRCPY  MYPATH;TMPSTR;#2
           INC     TMPSTR
           LDY     TMPSTR
           LDA     #'/'
           STA     TMPSTR,Y
           STRCAT  TMPSTR;INSTSRCSTR
           STRCPY  PATHNAME;TMPSTR2;#2
           INC     TMPSTR2
           LDA     #'/'
           LDY     TMPSTR2
           STA     TMPSTR2,Y
           STRCAT  TMPSTR2;TIMEIISTR

           LDA     INSTTYPE
           CMP     #"S"            ; apple display character
           BNE     :CONT1
* filename with slot number (Sx), update dest string
           LDY     TMPSTR2
           INY
           LDA     #'S'            ; ascii
           STA     TMPSTR2,Y
           INY
           LDA     SLOT
                                   ; CLC
                                   ; ADC #'0'
           ORA     #'0'            ; A <= slot + '0'
           STA     TMPSTR2,Y
           STY     TMPSTR2
:CONT1
           STRADD  SYSTEMSTR       ; (add to previous manipulated string)
* copy file
           LDA     #<TMPSTR        ; source
           STA     FILECPY+3
           LDA     #>TMPSTR
           STA     FILECPY+4
           LDA     #<TMPSTR2       ; dest
           STA     FILECPY+5
           LDA     #>TMPSTR2
           STA     FILECPY+6
           JSR     FILECPY         ; start copy
           BCS     :EXIT
           JSR     LOADVOL         ; reload file list from directory
           BCS     :EXIT
           JSR     FINDUPTOME      ; find position in directory entry
           JSR     BUBBLEUP        ; move ME up
           JSR     WRVOLDIR        ; write dir entries to disk
:EXIT      RTS
INSTTYPE   ENT
           HEX     00


********************************
CNTDRV     ENT
*
*  Count existing driver files
*
********************************
           LDA     #$FE
           BNE     DELDRV1         ; JMP DELDRV1
********************************
LSTDRV     ENT
*
* list existing driver files
*
********************************
           LDA     #$FF
           BNE     DELDRV1         ; JMP DELDRV1
********************************
DELDRV     ENT
*
* delete existing driver files
*
********************************
           LDA     #$00
DELDRV1    STA     DELFLAG
           LDA     #$00
           STA     ERRNO
           STA     DELFOUND
           LDA     #<DELDRVCB      ; set callback for file_iter
           STA     CALLBACK+1
           LDA     #>DELDRVCB
           STA     CALLBACK+2
           JSR     FILE_ITER       ; do iteration
           CLC
           RTS


********************************
DELDRVCB
*
* delete driver callback
*
********************************
           LDA     #$FF
           CMP     FILETYPE
           BNE     :NEXTFILE
           STREWITH FILENAME;SYSTEMSTR ; cmp end of string
           BCS     :NEXTFILE
           STRSWITH FILENAME;TIMEIISTR ; cmp start string
           BCS     :NEXTFILE
           INC     DELFOUND
           JSR     FILEDEL
:NEXTFILE
           CLC                     ; next file
           RTS
DELFOUND   ENT
           HEX     00


********************************
FINDUPTOME
*
* Find "up to me" all ".SYSTEM" file entries
* from the begining of Volume directory
* and store it in SYSFENTS.
* rq: Use FILE_ITER and FINDMECB callback
*
* out: NBFOUND, number of file entry in SYSFENTS
* out: SYSFENTS, list of address ptr to selected file entries
* A,X,Y modified
*
********************************
           LDA     #$00
           STA     NBFOUND
           LDA     #<FINDMECB      ; set callback for FILE_INTER
           STA     CALLBACK+1
           LDA     #>FINDMECB
           STA     CALLBACK+2
           JSR     FILE_ITER       ; do iteration
           RTS
NBFOUND    ENT                     ; number of entry in SYSFENTS
           HEX     00


********************************
FINDMECB
*
* Find up to me callback used with FILE_ITER
* list all files with SYSTEM type and ".SYSTEM" extension
* who are before "me" in directory entries
* and store it in SYSFENTS and update NBFOUND accordingly
*
* in: ENTADDR, current file entry address (from FILE_ITER)
* in: FILENAME (from FILE_ITER)
* in: FILETYPE (from FILE_ITER)
* out: NBFOUND, number of file entry in SYSFENTS
* out: SYSFENTS, ptr table
* A,X,Y modified
*
********************************
           LDA     #$FF
           CMP     FILETYPE
           BNE     :EXITKO

           STREWITH FILENAME;SYSTEMSTR ; cmp end of string
           BCS     :EXITKO

           LDA     NBFOUND
           ASL
           TAY

           LDA     ENTADDR
           STA     SYSFENTS,Y
           LDA     ENTADDR+1
           STA     SYSFENTS+1,Y
           INC     NBFOUND

* STRCMP MESTR;FILENAME
           STRSWITH FILENAME;TIMEIISTR
           BCS     :EXITKO
           JMP     :EXITOK
:EXITKO
           CLC                     ; next file
           RTS
:EXITOK
           SEC                     ; break itreration
           RTS


********************************
TOPTHNME   ENT
*
* copy selection to PATHNAME
*
* in: Y
* in: RWBUFF
* out: PATHNAME
* out: DRVSLT
*
********************************
           TAY
           LDA     KEYVOL,Y
           TAX
           LDA     RWBUFF,X
           STA     DRVSLT
           AND     #%00001111
           STA     PATHNAME
           INC     PATHNAME
           LDA     #'/'
           STA     PATHNAME+1
           LDY     #0
           INX
:LOOP
           LDA     RWBUFF,X
           BEQ     :EXIT
           STA     PATHNAME+2,Y
           INY
           INX
           BNE     :LOOP           ; JMP :LOOP
:EXIT
                                   ; LDA DRVSLT
                                   ; AND #%11110000
                                   ; STA DRVSLT
           RTS
DRVSLT     HEX     00              ; 1bit = drive, 3bit = slot


********************************
FILE_ITER
*
* Iterate all file entry block
* get some data for callbacks (see Data for callbakcs)
* and start callback defined in CALLBACK+3 (2 bytes)
*
* in: RWBUFF, full volume file intries structure
* Data usable by callbacks
*    out: BLKNUM, current block number
*    out: FILENAME, file name string
*    out: FILETYPE, file type
*    out: ENTADDR, address off block
*
********************************
           LDA     #1
           STA     :COUNTER        ; iteration counter
* init block ptr
           LDA     #<RWBUFF
           STA     PTR1
           LDA     #>RWBUFF
           STA     PTR1+1
* init file entry ptr
* point to first file entry (in volume dir struct)
           LDA     #<RWBUFF+VD_S_SIZE
           STA     PTR2
           LDA     #>RWBUFF+VD_S_SIZE
           STA     PTR2+1
           LDA     #1              ; on first block, 1st entry
           STA     :NUM            ; is number 1
:ENTLOOP
           LDY     #FE_NAMLGH
           LDA     (PTR2),Y
           TAX                     ; save A
           AND     #$30            ; storage type = $0, $d, $e, $f
           BEQ     :NEXTFE         ; => next file entry
           TXA                     ; retrieve A
           AND     #$0F            ; extract filename length
           TAX                     ; X = filename lengh
           STX     FILENAME        ; prepare FILENAME
           INY
* store file data for callbacks
:FNLOOP                            ; copy file name to FILENAME
           LDA     (PTR2),Y
           STA     FILENAME,Y
           INY
           DEX
           BNE     :FNLOOP
           LDY     #FE_FTYPE
           LDA     (PTR2),Y        ; get file type
           STA     FILETYPE        ; and store

           LDA     :COUNTER
           STA     BLKNUM          ; save counter as block number

           LDA     PTR2            ; entry address in block
           STA     ENTADDR         ; saved in ENTADDR
           LDA     PTR2+1
           STA     ENTADDR+1

           PHP                     ; save register before call back
           STA     :SAVA
           STX     :SAVX
           STY     :SAVY
           JSR     CALLBACK        ; start callback
           BCC     :CONTINUE       ; callback OK
           PLP                     ; callback stopped execution
                                   ; restore Status register only
           JMP     :EXIT
:CONTINUE
           LDY     :SAVY           ; restore registers
           LDX     :SAVX
           LDA     :SAVA
           PLP
:NEXTFE
           INC     :NUM
           LDA     :NUM
           CMP     ENTBLK
           BCS     :NEXTBLK
           LDA     PTR2            ; move point by adding entry length
           CLC
           ADC     ENTLGH
           STA     PTR2
           BCC     :NEXT1
           INC     PTR2+1
:NEXT1
           JMP     :ENTLOOP
:NEXTBLK
           LDA     :COUNTER
           CMP     BLKCNT
           BEQ     :EXIT
           INC     :COUNTER
* move block ptr
           LDA     PTR1
           CLC
           ADC     #<BLKSZ
           STA     PTR1
           LDA     PTR1+1
           ADC     #>BLKSZ
           STA     PTR1+1
* set file entry ptr
           LDA     PTR1
           CLC
           ADC     #$4
           STA     PTR2
           LDA     PTR1+1
           ADC     #$0
           STA     PTR2+1

           LDA     #$0             ; second block and more file
           STA     :NUM            ; entry number start at 0
           JMP     :ENTLOOP
:EXIT
           RTS
:SAVA      HEX     00
:SAVX      HEX     00
:SAVY      HEX     00
:COUNTER   HEX     00
:NUM       HEX     00
FILENAME   DS      16
FILETYPE   HEX     00
BLKNUM     HEX     00
ENTADDR    HEX     00,00
CALLBACK   JMP     _CALLBACK       ; to modify to change callback

_CALLBACK                          ; default callback
           DO      DEBUG
           LDA     FILETYPE
           JSR     PRBYTE
           LDA     #" "
           JSR     COUT
           STRPRNTL FILENAME
           FIN
           CLC                     ; continue
           RTS


********************************
MLIERRCLR
*
* clear error values
*
********************************
           LDA     #0
           STA     ERRNO
           STA     ERRCOMP
           RTS


********************************
MLIERROR
* in: A, MLI errno
* in: X, error code (custom error code)
* (use it by JMP to MLIERROR)
*
********************************
           STX     ERRCOMP
           STA     ERRNO
* JSR BELL
* JSR BELL
           JSR     BELL
           SEC
           RTS
ERRNO      ENT
           HEX     00
ERRCOMP    ENT
           HEX     00


           DO      DEBUG
********************************
CATALOG
*
*
*
********************************
           LDA     #<_CALLBACK     ; Set callback for file
           STA     CALLBACK+1      ; list
           LDA     #>_CALLBACK
           STA     CALLBACK+2
           JSR     FILE_ITER       ; do iteration
           RTS
           FIN


ONLINEP    D_ONLINE 00;RWBUFF
PREFIXP    D_GETPRFX PREFIX
DESTROYP   D_DESTROY $0000
CREATEP    D_CREATE $0000;$FF;$2000
OPENP1     D_OPEN  PATHNAME;FBUFF1
OPENP2     D_OPEN  $0000;FBUFF2
READP      D_READ  00;RWBUFF;RWBUFFSZ
WRITEP     D_WRITE 00;RWBUFF;RWBUFFSZ
WRITEBKP   D_WRITEBK 00;RWBUFF;$0000
CLOSEP1    D_CLOSE 00
CLOSEP2    D_CLOSE 00
* QUITP D_QUIT
TIMEIISTR  STR     'TIMEII'
SYSTEMSTR  STR     '.SYSTEM'
* MESTR STR 'TIMEII.SYSTEM'
INSTSRCSTR STR     'TIMEII.INST'
