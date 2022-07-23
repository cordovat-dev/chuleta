#!/bin/bash
set -eo pipefail

set -u
RUTA=`dirname $0`
COUNT=0
COLOUR=0
REPORT=0
LEGEND="chuletas"
TITLE="Chuletas"
NOCOLOR_FILE=""
TEMP=$(mktemp /tmp/chuleta.XXXXX)

while getopts rl:t:cf: flag
do
    case "${flag}" in
        r) REPORT=1;;
        l) LEGEND=${OPTARG};;
		t) TITLE=${OPTARG};;
        c) COLOUR=1;;
		f) NOCOLOR_FILE=${OPTARG};;
    esac
done

	if [ $REPORT -ne 1 ]; then
		printf "  %-4s%s\n" "#" $TITLE
		echo
	fi
	if [ -n "$NOCOLOR_FILE" ];then
		echo -n "" > ${NOCOLOR_FILE}
	fi
while read linea
do
	COUNT=$(( $COUNT + 1 ))
	if [ $REPORT -eq 1 ]; then
		printf "  %s\n" $linea
	else
		if [ $COLOUR -eq 1 ];then
			$RUTA/ct.sh -n $COUNT -d $linea -c >> $TEMP
		else
			printf "  %-4s%s\n" $COUNT $linea
		fi
		if [ -n "$NOCOLOR_FILE" ];then
			printf "  %-4s%s\n" $COUNT $linea >> ${NOCOLOR_FILE}
		fi;
	fi
done
cat $TEMP
if [ $REPORT -eq 1 ]; then
	echo
	echo "  $COUNT $LEGEND"
fi
rm $TEMP


