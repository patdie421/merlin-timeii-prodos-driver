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
