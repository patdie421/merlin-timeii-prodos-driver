# What's that?
This is a PRODOS driver for the AE Time II Clock card.  
This card was build for Apple II/II+ computers with DOS 3.3 and has been replaced in the AE catalog by more efficient clock cards usable with PRODOS (like the TIMEMASTER II H.O. or clocks integrated in other cards like Serial Pro, Z-RAM ultra, ...).  
So there is no official PRODOS support for this card.  
Because I never found a driver I decided to develop it myself.  
# Why Merlin?
Merlin.8 was in 80s and 90s the defacto Macro Assembler for Apple II computer. To understand how programming was done at that time, I decided to do everything from a real Apple IIe, and this is all the more necessary since no emulator simulates this card!  
But because I have no debugger and because I haven't use assembler since a long time, I use an emulator (Virtual ][) to debug some code.  
# my inspiration?
A bad copy of the documentation (see resources), an image of the DOS 3.3 disk (basic programs to use the card) and the PRODOS DRIVER project (https://github.com/a2stuff/prodos-drivers). I took several portions of code directly from this project, in particular the system program chaining code (.system).  
# how to use it?
On a fresh initialized drive (hard drive or floppy), copy the timeii.system program on the disk.  
On a existing drive you have to put de program at the begining of the catalog list. For that you can use ...
# Next steps
- better autodetection of the card
- slot selection based on program name (nameSz.system => selects slot z instead of auto-detection)
- setup program to set date/time and install the driver on boot disk
- add the driver in PRODOS DRIVER project (or a fork)  
