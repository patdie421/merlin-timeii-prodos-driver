DEVNUM    EQU $BF30
MLI       EQU $BF00
ONLINE    EQU $C5
OPEN      EQU $C8
READ      EQU $CA
CLOSE     EQU $CC
QUIT      EQU $65
PATHNAME  EQU $280
MACHID    EQU $BF98
DATETIME  EQU $BF06
DATELO    EQU $BF90
DATEHI    EQU $BF91
TIMELO    EQU $BF92
TIMEHI    EQU $BF93

D_QUIT    MAC
          HEX 04
          HEX 00
          HEX 00,00
          HEX 00
          HEX 00,00
          <<<


CL_REF    EQU 01
D_CLOSE   MAC
          HEX 01
          DFB ]1
          <<<


OP_PATH   EQU 1
OP_BUFF   EQU 3
OP_REF    EQU 5
D_OPEN    MAC
          HEX 03
          DFB <]1        ; OP_PATH
          DFB >]1
          DFB <]2        ; OP_BUFF
          DFB >]2
          DFB 0          ; OP_REF
          <<<


RD_REF    EQU 1
RD_BUFF   EQU 2
RD_RCNT   EQU 4
RD_TCNT   EQU 6
D_READ    MAC
          HEX 04         ; 0:
          DFB ]1         ; 1: RD_REF
          DFB <]2        ; 2: RD_BUFF
          DFB >]2        ; 3:
          DFB <]3        ; 4: RD_RCNT
          DFB >]3        ; 5:
          DFB 0          ; 6: RD_TCNT
          DFB 0          ; 7:
          <<<

S_FILEENT
FE_S_SIZE EQU 38
FE_NAMLGH EQU $00        ; storage_type + name_length
FE_FNAME  EQU $1         ; file_name
FE_FTYPE  EQU $10        ; file_type
FE_KEYPTR EQU $11        ; key_pointer
FE_BLKUSE EQU $13        ; blocks_used
FE_EOF    EQU $15        ; EOF
FE_CDATE  EQU $18        ; creation date
FE_CTIME  EQU $1B        ; creation time
FE_VER    EQU $1C        ; version
FE_MINVER EQU $1D        ; min_version
FE_ACCESS EQU $1E        ; access
FE_AUXTYP EQU $1F        ; aux_type
FE_LMDATE EQU $21        ; last mod date
FE_LMTIME EQU $23        ; last mod time
FE_HPTR   EQU $25        ; header_pointer

S_VOLDIRH
VD_S_SIZE EQU 43
VD_PRVBLK EQU $00        ; prev block
VD_NXTBLK EQU $02        ; next block
VD_NAMLGH EQU $04        ; storage_type + name_length
VD_NAME   EQU $05        ; file_name
VD_RESV   EQU $14        ; reserved
VD_CDATE  EQU $1C        ; creation date
VD_CTIME  EQU $1E        ; creation time
VD_VER    EQU $20        ; version
VD_MINVER EQU $21        ; min_version
VD_ACCESS EQU $22        ; access
VD_ENTLGH EQU $23        ; entry_length
VD_ENTBLK EQU $24        ; entries_per_block
VD_FLCNT  EQU $25        ; file_count
VD_MAPPTR EQU $27        ; bit_map_pointer
VD_TOTBLK EQU $29        ; total_blocks


OL_UNI    EQU 1
OL_BUFF   EQU 2
D_ONLINE  MAC
          HEX 02
          DFB ]1
          DFB <]2
          DFB >]2
          <<<

MLI_CALL  MAC            ; op,addr
          JSR MLI
          DFB ]1         ; op
          DFB <]2        ; data
          DFB >]2
          <<<
