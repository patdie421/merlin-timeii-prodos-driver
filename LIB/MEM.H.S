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


PHAXY     MAC
          PHA

          TXA
          PHA

          TYA
          PHA
          <<<

PLYXA     MAC
          PLA
          TAY

          PLA
          TAX

          PLA
          <<<

PHXY      MAC
          TXA
          PHA
          TYA
          PLA
          <<<

PLYX      MAC
          PLA
          TAY
          PHA
          TAX
          <<<

PHZPP     MAC
          LDA ]1
          PHA
          LDA ]1+1
          PHA
          <<<

PLZPP     MAC
          PLA
          STA ]1+1
          PLA
          STA ]1
          <<<
