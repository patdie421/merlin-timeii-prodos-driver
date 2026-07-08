#!/usr/bin/python3
# simple, quick and dirty melin asm file compressor (remove blank chars)

import sys
import fileinput
from argparse import ArgumentParser

parser = ArgumentParser(description="Compress Merlin 8/16 asm file")
parser.add_argument("-f", "--file", dest="filename", help="file to compress", metavar="FILE")

args = parser.parse_args()

try:
   for line in fileinput.input(args.filename):
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
