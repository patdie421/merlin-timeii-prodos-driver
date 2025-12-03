# What's that?
This is a PRODOS driver for the AE Time II Clock card written and build with Merlin assembler.  
This card was build for Apple II/II+ computers with DOS 3.3 and has been replaced in the AE catalog by more efficient clock cards usable with PRODOS (like the TIMEMASTER II H.O. or clocks integrated in other cards like Serial Pro, Z-RAM ultra, ...).  
So there was no official PRODOS support for this card.  
Because I never found a driver I decided to develop it myself.  
# Why Merlin?
I could use a modern tool chain (https://cc65.github.io/) but I'd to understand how programming was done in the 80s/90s, I decided to do everything by using a real Apple IIe (and now also an Apple IIc+), and this is all the more necessary since no emulator simulates this card!  
But because I have no native debugger and because I haven't use assembler since a long time (since 30+ years and it was 68k assembler), I use an emulator (Virtual ][) to debug some part of code.  
# My inspiration?
A bad copy of the documentation (see resources), an image of the DOS 3.3 disk (basic programs to use the card) and the PRODOS DRIVERS project (https://github.com/a2stuff/prodos-drivers). I took several portions of code directly from this project, in particular the system programs chaining code (.system).  
# How to use it?
Boot the TIMEII.EXE.X.Y disk, choose the slot where the card is plugged in and select option 3.  
For a manual install you can:
- For a fresh initialized disk (hard or floppy) bootable with PRODOS (prodos file on the disk), copy the TIMEII.INST program from TIME.EXE.X.Y disk on the root directory of the volume and rename it as TIMEII.SYSTEM.  
- For a existing disk, copy TIMEII.INST to the root directory, rename it as TIMEII.SYSTEM and then move the program at the begining of the catalog list. For that you can use CAT.DOCTOR (available in PRODOS 2.4.3: https://releases.prodos8.com/ProDOS_2_4_3.po)  
- Please create an issue if you need some help  
- To build the program I used the PRODOS8HD disk image (https://mirrors.apple2.org.za/ftp.apple.asimov.net/images/productivity/misc/71-PRODOS8HD.170612.2mg).
# How to build?
- a long process : [howtobuild](Documentation/howtobuild.md)
# Next steps?
- code optimization and documentation (this code really lacks comments) - work in progress  
- improve autodetection of the card  
- ~~slot selection based on program name (nameSz.system => selects slot z instead of auto-detection) - work in progress~~ - done  
- ~~update 12/24H flag of the card to force 24H format if time is set in 12H format (time is converted)~~ - done
- ~~update leap year flag of the card at startup (base on year stored by the card and century calculation with "Day Of Week" number). This will work greate for date between 1900 and 2399 (year 2400+ users, email me, I will help you work around the issue ...)~~ - done 
- ~~setup program to set date/time (with automatic leap year and day of week calculation) and install the driver on boot disk~~ - done
- ~~installation on volume and reorder the catalog to put the driver a the first ".system" position~~ - done
- add the driver in PRODOS DRIVER project (or a fork)  
