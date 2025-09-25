PRINT     MAC
          LDA #<]1
          STA PRINTSTR
          LDA #>]1
          STA PRINTSTR+1
          JSR PRINT1
          <<<

PRINTPAS  MAC
          LDA #<]1
          STA PASSTR
          LDA #>]1
          STA PASSTR+1
          JSR PRINTPAS1
          <<<

PRINTLN   MAC
          PRINT ]1
          JSR CROUT
          <<<
