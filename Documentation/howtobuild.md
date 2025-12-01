# Before starting
This tutorial assumes you know how to use disk images and Prodos files with a real Apple II (IIe or IIc) or an emulator. I use… for macOS or Apple2TS (https://github.com/ct6502/apple2ts) in a web browser.  
The build process, at least for the initial assembly, is relatively lengthy. To simplify it, I used a hard drive image that already contained the necessary tools (and many others...). Since the source code is modular, only partial assemblies are required once the initial assembly is complete.  
# Source organisation
The source code is too large to fit in a single file. It has therefore been split into several files so that it can be assembled using the linker integrated into Merlin.  
Furthermore, the approach also aims to provide code that can be largely used in other projects as "configurable" libraries. This has led to an increase in the number of files and the complexity of the source code (I am sorry for that).  
## source code tree
* The root directory of the source code contains the main files.  
* LIB directory contains the source code for the "unconfigured" libraries.  
* LIBSRC directory contains the configured libraries. Each file includes one of the files from LIB. Only this file should be creaded/modified and build.  
## Libraries organisation (in LIB directory)
Each library consists of 3 files:  
* The source file (.S), contains the code of sub-routines. This files must be included (USE) if you do not use the linker. If the linker is used the file must not be included.
* The definitions associated with the library (.H.S), contains constants and macro needed to use the libraries. This file must be included (USE) before the .S inclusion of the library. Note: some libraries have only .H.S definitions (macro and/or constants).  
* The library entry points (.E.S) for the linker. Need to be include to use the library if you use the linker.
A librarie is configured by setting macro variables after .H.S inclusion and before including the .S file.
## Files in LIBCFG
This files must be create only if is the linker is used. Following an exemple of file :
```          LST OFF ; verbose off 
          REL ; geneate relocatable code 
          DSK OBJ/STR.L ; result output in OBJ directory 
          USE LIB/MONITOR.H ; include needed aditional definitions
          USE LIB/MEM.H
* Enable/disable sub-routines to build. See associated .H.S file for switches available.
* can help to reduce final binary footprint.
]E_STRPRINT  EQU 1  
]E_STRCMP1  EQU 1  
]E_STRCMPE1  EQU 0  
]E_STREWITH1  EQU 1  
]E_STRSWITH1  EQU 1  
]E_STRCPY1  EQU 1  
]E_STRCPY2  EQU 0  
]E_STRCAT1  EQU 1
* note: by default sub-routines are disabled in .H.S file
          USE LIB/STR ; library to build


# build process
To build the driver and setup tools you need a copy of Merlin if possible installed on a hard drive.

https://mirrors.apple2.org.za/ftp.apple.asimov.net/images/productivity/misc/71-PRODOS8HD.170612.2mg
