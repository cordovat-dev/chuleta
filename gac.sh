#!/bin/bash

DIRBASE=$1
TEMP=`mktemp /tmp/chuleta.XXXXX`
rm ~/.cache/chu/*
for line in $(find "$DIRBASE" -type f -iname "chuleta*.txt");do 
	echo "$line"|xargs dirname|sed 's#.*/##' >> $TEMP
done
sort -u $TEMP|tr '\n' ' ' > ~/.cache/chu/lista_topicos
rm $TEMP

for line in $(cat ~/.cache/chu/lista_topicos);do
	find "$DIRBASE/$line" -type f -iname "chuleta*.txt" \
	|sed -r "s|$DIRBASE/$line||g" \
	|sed -r "s|\.txt||g" \
	|sed -r "s|chuleta_||g" \
	|sed -r "s|/| |g" \
	|sed -r "s|_| |g" \
	|tr ' ' '\n' \
	|sort -u \
	|tr '\n' ' ' >  ~/.cache/chu/lista_$line
done

find "$DIRBASE" -type f -iname "chuleta*.txt" \
|sed -r "s|$DIRBASE||g" \
|sed -r "s|\.txt||g" \
|sed -r "s|chuleta_||g" \
|sed -r "s|/| |g" \
|sed -r "s|_| |g" \
|tr ' ' '\n' \
|sort -u \
|tr '\n' ' ' >  ~/.cache/chu/lista_comp

exit 0



