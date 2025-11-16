* monitor entry points
BELL      EQU $FF3A
COUT      EQU $FDED
CROUT     EQU $FD8E
PRBYTE    EQU $FDDA
HOME      EQU $FC58
GETKEY    EQU $FD35
RDKEY     EQU $FD0C
CLREOL    EQU $FC9C
VTAB      EQU $FC22
VTABZ     EQU $FC24
SETINV    EQU $FE80
SETNORM   EQU $FE84
SETIFLG   EQU $FE86

* zero page
WNDLFT    EQU $20        ; window left (0-39)
WNDWDTH   EQU $21        ; window width (1-40)
WNDTOP    EQU $22        ; window top (0-22)
WNDBTM    EQU $23        ; window bottom (WNDTOP+1)-24
CH        EQU $24        ;
CV        EQU $25        ;


CWINDOW   MAC            ; create window x,y,w,h
          LDA ]1
          STA WNDLFT
          LDA ]2
          STA WNDTOP
          LDA ]3
          STA WNDWDTH
          LDA ]4
          CLC
          ADC ]2
          STA WNDBTM
          <<<

RWINDOW   MAC            ; reset window
          LDA #0
          STA WNDLFT
          STA WNDTOP
          LDA #40
          STA WNDWDTH
          LDA #24
          STA WNDBTM
          <<<
