RWBUFFSZ EQU    $4000
* memory reservation
RWBUFF   EQU    $4000          ; 12kb
FBUFF1   EQU    $8000          ; 1kb for opened file
FBUFF2   EQU    $8400          ; 1kb for opened file
TMPBUFF  EQU    $8800          ; 512b
SYSFENTS EQU    $8A00          ; 51x2b
SWPMMTMP EQU    $8B00          ; 128b
PREFIX   EQU    $8C00          ; 64b
MYPATH   EQU    $8C40          ; 64b
TMPSTR   EQU    $8C80          ; 256b (overlap TMPSTR2)
TMPSTR2  EQU    $8D00          ; 128b
BUFFSTR  EQU    $8D80          ; 128b
_FREE1   EQU    $8E00
