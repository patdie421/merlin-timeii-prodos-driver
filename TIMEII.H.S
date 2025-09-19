* TimeII read register address
SECUNI    EQU 32 ; 0
SECTEN    EQU 33 ; 1
MINUNI    EQU 34 ; 2
MINTEN    EQU 35 ; 3
HOUUNI    EQU 36 ; 4
HOUTEN    EQU 37 ; 5
DATUNI    EQU 39 ; 6
DATTEN    EQU 40 ; 7
MONUNI    EQU 41 ; 8
MONTEN    EQU 42 ; 9
YEAUNI    EQU 43 ; 10
YEATEN    EQU 44 ; 11
DAYWEE    EQU 38 ; 12

* TimeII address
BASE_A    EQU $C082
BASE_B    EQU $C081

INITII    MAC
          LDA ]1
          STA IISLOT
          <<<
