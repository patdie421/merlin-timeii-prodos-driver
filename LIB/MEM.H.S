]E_MEMINI1  EQU 0
]E_MEMCPY  EQU 0
]E_SWAPMEM  EQU 0
]E_SWAPMEM1  EQU 0
]E_MEMCPY2  EQU 0


MEMCPY_SRC EQU 3
MEMCPY_DST EQU 5
MEMCPY_CNT EQU 7

SWAPMEM_A EQU 3
SWAPMEM_B EQU 5
SWAPMEM_CNT EQU 7


*
* set mem lib memory buffer
* ]1 : address of a 256b buffer
*
MEMINIT   MAC
          TXA
          PHP
          TYA
          PHP
          LDX #<]1
          LDY #>]1
          JSR MEMINI1
          PLA
          TAY
          PLA
          TAX
          <<<

*
* save A,X and Y to stack
* (use PLYXA to restore)
*
PHAXY     MAC
          PHA

          TXA
          PHA

          TYA
          PHA
          <<<


*
* restore Y,X and A from stack
* (use to restore PHAXY)
*
PLYXA     MAC
          PLA
          TAY

          PLA
          TAX

          PLA
          <<<


*
* save X and Y to stack
* (use PLYX to restore)
*
PHXY      MAC
          TXA
          PHA
          TYA
          PHA
          <<<


*
* restore Y and X from stack
* (used to restore PHXY)
*
PLYX      MAC
          PLA
          TAY
          PLA
          TAX
          <<<


*
* save Zero Page Pointer (2 bytes) to the stack
* (use  PLZPP to restore)
*

PHZPP     MAC
          LDA ]1
          PHA
          LDA ]1+1
          PHA
          <<<


*
* restore Zero Page Pointer (2 bytes) from the stack
* (used to restore PHZPP)
PLZPP     MAC
          PLA
          STA ]1+1
          PLA
          STA ]1
          <<<
