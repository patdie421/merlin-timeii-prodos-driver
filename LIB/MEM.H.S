]E_MEMINI1 EQU     0
]E_MEMCPY  EQU     0
]E_SWAPMEM EQU     0
]E_SWAPMEM1 EQU    0

MEMCPY_SRC EQU     3
MEMCPY_DST EQU     5
MEMCPY_CNT EQU     7

SWAPMEM_A  EQU     3
SWAPMEM_B  EQU     5
SWAPMEM_CNT EQU    7

*
* call MEMCPY (copy ]3 bytes from ]1 to ]2)
* ]1 : source address
* ]2 : destination address
* ]3 : byte count, ex: #16 (0 = 256)
* A modified (X,Y preserved)
* needs ]E_MEMCPY = 1 in MEM.O.S and MEMCPY EXT
*
MEMCPYM    MAC
           LDA     #<]1
           STA     MEMCPY+MEMCPY_SRC
           LDA     #>]1
           STA     MEMCPY+MEMCPY_SRC+1
           LDA     #<]2
           STA     MEMCPY+MEMCPY_DST
           LDA     #>]2
           STA     MEMCPY+MEMCPY_DST+1
           LDA     ]3
           STA     MEMCPY+MEMCPY_CNT
           JSR     MEMCPY
           <<<


*
* call SWAPMEM1 (swap ]3 bytes between ]1 and ]2)
* ]1 : address of zone A
* ]2 : address of zone B
* ]3 : byte count, ex: #39 (0 = 256)
* A modified (X,Y preserved)
* needs ]E_SWAPMEM1 = 1 (or ]E_SWAPMEM2) and SWAPMEM1 EXT
*
SWAPMEMM   MAC
           LDA     #<]1
           STA     SWAPMEM1+SWAPMEM_A
           LDA     #>]1
           STA     SWAPMEM1+SWAPMEM_A+1
           LDA     #<]2
           STA     SWAPMEM1+SWAPMEM_B
           LDA     #>]2
           STA     SWAPMEM1+SWAPMEM_B+1
           LDA     ]3
           STA     SWAPMEM1+SWAPMEM_CNT
           JSR     SWAPMEM1
           <<<


*
* set mem lib memory buffer
* ]1 : address of a 256b buffer
*
MEMINIT    MAC
           PHAXY
           LDX     #<]1
           LDY     #>]1
           JSR     MEMINI1
           PLYXA
           <<<

*
* save A,X and Y to stack
* (use PLYXA to restore)
*
PHAXY      MAC
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
PLYXA      MAC
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
PHXY       MAC
           TXA
           PHA
           TYA
           PHA
           <<<


*
* restore Y and X from stack
* (used to restore PHXY)
*
PLYX       MAC
           PLA
           TAY
           PLA
           TAX
           <<<


*
* save Zero Page Pointer (2 bytes) to the stack
* (use  PLZPP to restore)
*

PHZPP      MAC
           LDA     ]1
           PHA
           LDA     ]1+1
           PHA
           <<<


*
* restore Zero Page Pointer (2 bytes) from the stack
* (used to restore PHZPP)
PLZPP      MAC
           PLA
           STA     ]1+1
           PLA
           STA     ]1
           <<<

*
* Usage  : PHZP4B $EB   (saves $EB,$EC,$ED,$EE)
* ]1     : zero page address of 1st byte, must be <= $FC (above, zp,X wraps
*          inside page 0 : wrong bytes, NO assembly error)
* Regs   : A,X modified, Y untouched. Flags N,Z,C modified
* Stack  : 4 bytes. Must be restored by PLZP4B with the SAME address
* Notes  : X is overwritten (save it first with PHXY if needed)
*          Uses Merlin variable ]SV (reserved name)
*          Size : 10 bytes
PHZP4B     MAC
           LDX     #0
]SV        LDA     ]1,X
           PHA
           INX
           CPX     #4
           BNE     ]SV
           <<<


*
* Usage  : PLZP4B $EB   (restores $EB,$EC,$ED,$EE saved by PHZP4B $EB)
* ]1     : same zero page address as the matching PHZP4B (<= $FC)
* Regs   : A,X modified, Y untouched. Flags N,Z modified, carry PRESERVED
*          (a result can be returned in C just before the RTS)
* Stack  : pops 4 bytes (LIFO). Every exit path must go through PLZP4B
* Notes  : A is lost (return results in C, X or Y)
*          Uses Merlin variable ]RS (reserved name)
*          Size : 8 bytes
PLZP4B     MAC
           LDX     #3
]RS        PLA
           STA     ]1,X
           DEX
           BPL     ]RS
           <<<
