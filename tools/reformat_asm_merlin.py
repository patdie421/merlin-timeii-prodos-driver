# simple, quick and dirty melin asm source code file reformater

import sys
from argparse import ArgumentParser

parser.add_argument("-f", "--file", dest="filename", help="file to reindent", required=True, metavar="FILE")

args = parser.parse_args()

if args.filename==None:
   print("usage: reformat_asm_merlin <filename>")
   sys.exit(1)

ftab=10 # tab to instruction column
ctab=32 # tab to comment column
isize=7 # instruction max len

try:
   with open(args.filename, "r", encoding="utf-8") as file:
      for line in file:
         a=line.split()
         l=""
         if a: # first word of line
            if line[0]==" " or line[0]=="\t":
               l=l+" ".ljust(ftab-1) # add "tabs"
            elif line[0]=="*":
               for e in a: # get file line and print
                  l=l+str(e)+" "
               print(l.rstrip())
               continue
            else:
               if line[0][0]==";":
                  l=l+" ".ljust(ctab-1)
                  for e in a:
                     l=l+str(e)+" "
                  print(l.rstrip())
                  continue
               else:
                  l=l+a[0].ljust(ftab-1)
                  a.pop(0)
         if a: # nexts words
            i=0
            for e in a:
               i_s=1
               if i==0:
                  i_s=isize-len(e)
               if e[0]!=";":
                  l=l+str(e)+" ".ljust(i_s)
               else:
                  l=l+" ".ljust(ctab-len(l)-1)+"; "
               i=i+1
         print(l.rstrip())
except(FileNotFoundError):
   print("File "+args.filename+" not found.", file=sys.stderr)
