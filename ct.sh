#!/bin/bash

set -euo pipefail

declare -A hues
RUTA=`dirname $0`
source $RUTA/colorsets.conf

CNORMAL=${hues[NORMAL]}
CINDEX=${hues[YELLOW]}
C1TOPIC=${hues[GREEN]}
C2TOPIC=${hues[MAGENTA]}
C3TOPIC=${hues[CYAN]}
COUNT=0
DATA=""
COLOUR=0

while getopts n:d:c flag
do
    case "${flag}" in
        n) COUNT=${OPTARG};;
        d) DATA=${OPTARG};;
        c) COLOUR=1;;
    esac
done

if [ $COLOUR -eq 0 ];then
	printf "  %-4s%s\n" $COUNT $DATA
	exit 0
fi

IFS="/" read -a myarray <<< $DATA

declare -i y=1
printf "  %s%-4s%s%s" $CINDEX $COUNT ${C1TOPIC} ${myarray[0]}

if [ ${#myarray[@]} -gt 2 ];then
	printf "/%s%s" ${C2TOPIC} ${myarray[1]}
	y=2
	if [ ${#myarray[@]} -gt 3 ];then
		printf "/%s%s" ${C3TOPIC} ${myarray[2]}
		y=3
	fi
fi
printf "%s" $CNORMAL

for (( i=y; i<${#myarray[@]}; i++ ));
do
	if [ $i -lt ${#myarray[@]} ];then
		echo -n  "/"
	fi;
    printf "%s" ${myarray[$i]}
done
echo ""
