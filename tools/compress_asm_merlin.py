# simple, quick and dirty melin asm file compressor (remove blank chars)

import sys
from argparse import ArgumentParser

parser = ArgumentParser(description="Compress Merlin 8/16 asm file")
parser.add_argument("-f", "--file", dest="filename", help="file to compress", required=True, metavar="FILE")

args = parser.parse_args()

if args.filename==None:
   print("usage: deformat_asm_merlin <filename>")
   sys.exit(1)

try:
   with open(args.filename, "r", encoding="utf-8") as file:
      for line in file:
         a=line.split()
         l=""
         if a:
            if line[0]==" " or line[0]=="\t":
               l=l+" "
            for e in a:
               l=l+str(e)+" "
         print(l.rstrip())
except(FileNotFoundError):
   print("File "+args.filename+" not found.", file=sys.stderr)
