# Before starting
This tutorial assumes you know how to use disk images and Prodos files with a real Apple II (IIe or IIc) or an emulator. I use… for macOS or Apple2TS (https://github.com/ct6502/apple2ts) in a web browser.  
The build process, at least for the initial assembly, is relatively lengthy. To simplify it, I used a hard drive image that already contained the necessary tools (and many others...). Since the source code is modular, only partial assemblies are required once the initial assembly is complete.  
# Source organisation
The source code is too large to fit in a single file. It has therefore been split into several files so that it can be assembled using the linker integrated into Merlin.  
Furthermore, the approach also aims to provide code that can be largely used in other projects as "configurable" libraries. This has led to an increase in the number of files and the complexity of the source code (I am sorry for that).  

1. Build tools

To build the driver and setup tools you need a copy of Merlin if possible installed on a hard drive.

https://mirrors.apple2.org.za/ftp.apple.asimov.net/images/productivity/misc/71-PRODOS8HD.170612.2mg



