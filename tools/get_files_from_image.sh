#!/bin/bash

if [ $# -ne 3 ]
then
   echo "usage: $0 <disk-image> <list-of-files> <dest-dir>"
   exit 1
fi

DISK=$1
FILES=$2
DEST=$3

cat "$FILES" | while read line
do
   echo "$line"
   mkdir -p "$(dirname "$DEST/$line")" > /dev/null 2>&1
   acx get -d "$DISK" "$line" --method=text | reformat_asm_merlin > "$DEST/$line"
done
