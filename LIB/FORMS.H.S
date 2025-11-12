BOX_X     EQU 3
BOX_Y     EQU 4
BOX_L     EQU 5
BOX_H     EQU 6
BOX_T     EQU 7
BOX       MAC
          LDA ]1
          STA BOX2+BOX_X
          LDA ]2
          STA BOX2+BOX_Y
          LDA ]3
          STA BOX2+BOX_L
          LDA ]4
          STA BOX2+BOX_H
          LDA #<]5
          STA BOX2+BOX_T
          LDA #>]5
          STA BOX2+BOX_T+1
          JSR BOX2
          <<<
