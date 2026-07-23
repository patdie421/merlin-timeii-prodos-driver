#!/bin/bash

if [ $# -ne 2 ]
then
   echo "usage: $0 <file> <disk-image>"
   exit 1
fi

FILENAME="`basename $1`"
DISKIMAGE="$2"

cat $1 | compress_asm_merlin_raw.py > /tmp/$FILENAME.raw
acx put -f -d "$DISKIMAGE" --raw -t txt -n "$FILENAME" /tmp/$FILENAME.raw

