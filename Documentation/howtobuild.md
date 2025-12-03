# Before starting
This tutorial assumes you know how to use disk images and Prodos files with a real Apple II (IIe or IIc) or an emulator (I use [Virtual \]\[](https://www.virtualii.com/) for macOS or Apple2TS (https://github.com/ct6502/apple2ts) in a web browser).  
The build process, at least for the initial assembly, is relatively long. To simplify it, I used a hard drive image that already contained the necessary tools (and many others...). Since the source code is modular, only partial assemblies are required once the initial assembly is complete.  
# Source organisation
The source code is too large to fit in a single file. It has therefore been split into several files so that it can be assembled using the linker integrated into **Merlin-8 2.58**.  
Furthermore, the approach also aims to provide code that can be largely used in other projects as "configurable" libraries. This has led to an increase in the number of files and the complexity of the source code (I am sorry for that, I'm a classic C developper I can't to things simply).  
## source code tree
* The root directory of the source code contains the main files.  
* LIB directory contains the source code for the "unconfigured" libraries.  
* The LIBSRC directory contains the configured libraries. Each file (.O.S extension) includes one or more of the files from the LIB directory. Only that .O.S file needs to be created/modified and assembled.  
## Libraries organisation (in LIB directory)
Each library consists of 3 files:  
* The source file (.S), contains the code of all sub-routines. This files must be included (USE) if you do not use the linker. If the linker is used the file must not be included.
* The definitions associated with the library (.H.S), contains constants and macro needed to use the libraries. If the linker is not used, this file must be included (USE) before the .S inclusion of the library. Note: some libraries have only .H.S definitions (macro and/or constants).  
* The library entry points (.E.S) for the linker. Need to be include to use the library if you use the linker.
A librarie is configured by setting macro variables after .H.S inclusion and before including the .S file.
## Files in LIBCFG
This files must be create only if is the linker is used. Following an exemple of file :
```          LST OFF ; verbose off 
          REL ; geneate relocatable code 
          DSK OBJ/STR.L ; result output in OBJ directory 
          USE LIB/MONITOR.H ; include needed by .S file
          USE LIB/MEM.H
* Enable/disable sub-routines. See associated .H.S file for switches available.
* disabling unused sub-routines help reducing final binary footprint.
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
```

# build process
Because there's no scripting solution for Merlin, you'll have to follow all this step manually (sorry).
## before building
To build the driver and setup tools you need a copy of Merlin if possible installed on a hard drive. That's the image I use:  
[PRODOS8HD image](https://mirrors.apple2.org.za/ftp.apple.asimov.net/images/productivity/misc/71-PRODOS8HD.170612.2mg)  
Start your Apple II with this image, create a src directory (`/PRODOS8HD/TIMEIISRC` for example).  
Copy all file from `timeii.0.1.src.po` image into this directory.  
## build the driver file (timeii.system)
The driver is not build by the linker.  
Follow this step to: build
1. Start Merlin (Prosel "Development" menu page)
2. Change prefix to `/PRODOS8HD/TIMEIISRC` (at the menu, press `P` key, type `/PRODOS8HD/TIMEIISRC` followed by `Return` key 2 times)
3. Load the file `TIMEII.SYSTEM.S` (at the menu, press `L`, type `TIMEII.SETUP` followed by `Return`)
4. Go in edit/asm mode (press `E`)
5. At the prompt (`:`) type `ASM` followed by `Return`
6. press `Q` followed by `<Return>`
The `TIMEII.SYSTEM` file is now in the `/PRODOS8HD/TIMEIISRC` directory.
## build the TIMEII setup program
1. Start Merlin (Prosel "Development" menu page)
2. Change prefix to `/PRODOS8HD/TIMEIISRC` (at the menu, press `P` key, type `/PRODOS8HD/TIMEIISRC` followed by `Return` key 2 times)
### linker directives
3. Load the file `TIMEIISETUP.S` (at the menu, press `L`, type `TIMEIISETUP` followed by `<Return>` key)
4. Go in edit/asm mode (press `E` key)
5. At the prompt (`:`) type `ASM` followed by `<Return>` key
6. press `Q` followed by `<Return>` key
A linker file 
A `TIMEIISETUP` file containing linker directives is generated
### libraries
for all following files in `LIBCFG` apply step 7 to 10:
```
ASC.O.S
CNVANDCHCK.O.S
DATETIME.O.S
FORMS.O.S
INOUTDATA.O.S
MEM.O.S
STR.O.S
TIMEII.O.S
```
7. Load the file (at the menu press `L` type `LIBCFG/<filename_without_dot_S>` (ex: `LIBCFG/MEM.O`)
8. Go in edit/asm mode (press `E`)
9. At the prompt (`:`) type `ASM` followed by `<Return>` key
10. Press `Q` key followed by `<Return>`
A relocatable file is now in `OBJ` directory.
### main program
for all following file in root directory apply step 11 to 14:
```
INSTALL.S
INSTGUI.S
MAIN.S
SETDATE.S
```
11. Load the file (at the menu press `L` type `<filename_without_dot_S>` (ex: `MAIN`)
12. Go in edit/asm mode (press `E` key)
13. At the prompt (`:`) type `ASM` followed by `<Return>` key
14. Press `Q`
A relocatable file is now in `OBJ` directory.
### connect everything
15. Go in edit/asm mode (press `E` key)
16. At the prompt (`:`) type `new` followed by `<Return>` key
17. type `LINK $2000 "TIMEIISETUP"` followed by `<Return>` key
18. Press `Q`
19. At the main menu, save object file (press `O` key) and type `TIMEII.SETUP` followed by `<Return>` key
A `TIMEII.SETUP` file is now available in root directory



