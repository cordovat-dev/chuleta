#!/bin/bash

ARCHIVO=~/.cache/chu.logs/frecuentes
RUTA=$(dirname $0)
TEMP1=$(mktemp /tmp/chuleta.XXXXX)
TEMP2=$(mktemp /tmp/chuleta.XXXXX)

sort $ARCHIVO | uniq -c | sort -nrk 1 > $TEMP1
AVG=$(cat $TEMP1| awk '{print $1}' | $RUTA/avg.sh)
$RUTA/filter.sh $AVG < $TEMP1 > $TEMP2
AVG=$(cat $TEMP2| awk '{print $1}' | $RUTA/avg.sh)
$RUTA/filter.sh $AVG < $TEMP2
rm "$TEMP1 $TEMP2" 2> /dev/null





