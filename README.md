# What's that?
This is a PRODOS driver for the AE Time II Clock card.  
This card was build for Apple II/II+ computers with DOS 3.3 and has been replaced in the AE catalog by more efficient clock cards like the TIMEMASTE R II H.O. or clocks integrated in other card (Serial Pro, Z-RAM ultra, ...) usable with PRODOS.  
So there is no official PRODOS support for this card.  
Because I never found a driver I decided to develop it myself.  
# Why Merlin?
Merlin.8 was the in 80s and 90s the defacto Macro Assembler for Apple II computer. To understand how programming was done at that time, I decided to do everything from a real Apple IIe, and this is all the more necessary since no emulator simulates this card!  
# my inspiration?
A bad copy of the documentation (see resources), an image of the DOS 3.3 disk (basic programs to use the card) and the PRODOS DRIVER project (https://github.com/a2stuff/prodos-drivers). I took several portions of code directly from this project, in particular the system program chaining code (.system).  
# Next steps
- better autodetection of the card
- slot selection based on program name (<name>S<s>.system => selects location s instead of auto-detection)
Setup
Auto detect card slot  
Chain the next system (.system) program  
Fully build on Apple IIe with Merlin.8  
