#!/bin/bash

cat files.lst | while read line
do
   echo $line
   acx get -d exchange.dsk $line --method=text | reformat_asm_merlin > tmp/$line
done
