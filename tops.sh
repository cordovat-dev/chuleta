#!/bin/bash
set -euo pipefail

ARCHIVO="$1"
RUTA=$(dirname $0)
TEMP1=$(mktemp /tmp/chuleta.XXXXX)
TEMP2=$(mktemp /tmp/chuleta.XXXXX)

arr[0]="You should consider trying to learn the following by heart:"
arr[1]="It's about time you memorize the following:"
arr[2]="Don't just copy and paste, understand!:"
arr[3]="You use these ones frequently, try to learn them for once:"
arr[4]="Try typing instead of copy+pasting, so you don't forget this:"
arr[5]="Print these ones and pin them to your corkboard:"
arr[6]="These ones should already have become second nature to you:"
arr[7]="I guess you already know these topics without looking them up:"
rand=$[$RANDOM % ${#arr[@]}]

echo
echo ${arr[$rand]}
echo
sort $ARCHIVO | uniq -c | sort -nrk 1 > $TEMP1
AVG=$(awk '{acum = acum + $1} END {print acum/NR}' $TEMP1)
awk -v AVG=$AVG '$1 >= AVG' < $TEMP1 > $TEMP2
AVG=$(awk '{acum = acum + $1} END {print acum/NR}' $TEMP2)
echo "Cant	Chuletas" > $TEMP1
awk -v AVG=$AVG '$1 >= AVG {print $1,$2}' < $TEMP2 >> $TEMP1
$RUTA/./fmt.sh -n < $TEMP1
rm "$TEMP1 $TEMP2" 2> /dev/null




