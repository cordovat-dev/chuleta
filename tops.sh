#!/bin/bash

ARCHIVO="$1"
RUTA=$(dirname $0)
TEMP1=$(mktemp /tmp/chuleta.XXXXX)
TEMP2=$(mktemp /tmp/chuleta.XXXXX)

avg() {
	local -i COUNT=0;
	local -i SUM=0;
	while read line
	do
		((COUNT ++))
		((SUM = SUM + $line))
	done;
	AVG=$(( $SUM/$COUNT ))
	echo $AVG	
}

filter() {
	NUM=$1
	while read line
	do	
		if [[ $(echo $line|awk '{print $1}') -gt $NUM ]];then
			echo $line
		fi
	done
}

echo
echo You should consider trying to learn the following by heart:
echo
sort $ARCHIVO | uniq -c | sort -nrk 1 > $TEMP1
AVG=$(cat $TEMP1| awk '{print $1}' | avg)
filter $AVG < $TEMP1 > $TEMP2
AVG=$(cat $TEMP2| awk '{print $1}' | avg)
filter $AVG < $TEMP2
rm "$TEMP1 $TEMP2" 2> /dev/null





