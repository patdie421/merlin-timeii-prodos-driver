#!/bin/bash

if [ $# -ne 3 ]
then
   echo "usage: $0 <disk-image> <list-of-files> <dest-prefix>"
   exit 1
fi

DISK=$1
FILES=$2
DEST=$3

cat "$FILES" | while read line
do
   echo "$line"
   cat $line | compress_asm_merlin_raw.py > "/tmp/$FILENAME.raw"
   acx put -f -d "$DISKIMAGE" --raw -t txt -n "$FILENAME" "/tmp/$FILENAME.raw"
   rm /tmp/$FILENAME.raw
done
