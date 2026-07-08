#!/usr/bin/python3
# Simple, quick and dirty Merlin ASM source code file formatter.

import sys
import fileinput
from argparse import ArgumentParser

parser = ArgumentParser(description="Re-indent Merlin 8/16 asm file")
parser.add_argument("-f", "--file", dest="filename", help="file to re-indent", metavar="FILE")

args = parser.parse_args()

ftab=12 # tab to instruction column
ctab=36 # tab to comment column
isize=8 # instruction max len

try:
#   with open(args.filename, "r", encoding="utf-8") as file:
   for line in fileinput.input(args.filename):
      a=line.split()
      l=""
      if a: # first word of line
         if line[0]==" " or line[0]=="\t":
            l=l+" ".ljust(ftab-1) # add "tabs"
         elif line[0]=="*":
            print(line.rstrip())
            continue
         else:
            if line[0][0]==";":
               l=l+" ".ljust(ctab-1)
               for e in a:
                  l=l+str(e)+" "
               print(l.rstrip())
               continue
            else:
               l=l+a[0].ljust(ftab-2)+" "
               a.pop(0)
      if a: # nexts words
         i=0
         for e in a:
            i_s=1
            if i==0:
               i_s=isize-len(e)-(len(l)+1-ftab)
            if e[0]!=";":
               l=l+str(e)+" ".ljust(i_s)
            else:
               if len(l)>=ctab:
                  l=l+"; "
               else:
                  l=l+" ".ljust(ctab-len(l)-1)+"; "
            i=i+1
      print(l.rstrip())
except(FileNotFoundError):
   print("File "+args.filename+" not found.", file=sys.stderr)
