#!/usr/bin/python3
# simple, quick and dirty melin asm file compressor (remove blank chars)
# generate directly an apple text (bit 7 high if needed)  
import sys
import fileinput
from argparse import ArgumentParser

parser = ArgumentParser(description="Compress Merlin 8/16 asm file")
parser.add_argument("-f", "--file", dest="filename", help="file to compress", metavar="FILE")

args = parser.parse_args()

def raw_print(str):
   space=0xA0
   prev=None
   comment=False
   for c in str:
      if comment==False:
         if prev==' ' and c == ';':
            space=0x20
            comment=True
         elif c == '*':
            comment=True
            space=0x20
      if comment==False and (c=='"' or c=="'"):
         if space==0xA0:
            space=0x20
         else:
            space=0xA0
      if c == ' ':
         cc=space
      else:
         cc = ord(c) | 0x80
      prev=c
      sys.stdout.buffer.write(bytes([cc]))
   sys.stdout.buffer.write(bytes([0x8D]))


try:
   for line in fileinput.input(args.filename):
      a=line.split()
      l=""
      if a:
         if line[0].startswith("*"):
            raw_print(line.rstrip())
            continue
         if line[0]==" " or line[0]=="\t":
            l=l+" "
         for e in a:
            l=l+str(e)+" "
      raw_print(l.rstrip())
except(FileNotFoundError):
   print("File "+args.filename+" not found.", file=sys.stderr)
