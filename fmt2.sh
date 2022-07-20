#!/bin/bash
set -eo pipefail

# these two parms must be used together in this sequence or not at all:
# -n -i
PARM1="$1" # no line numbers, but a total 
PARM2="$2" # change "chuletas" legend to "items"
set -u
RUTA=`dirname $0`
COUNT=0
COLOUR=0
COPEN=$(tput sgr0)
CCLOSE=$(tput sgr0)
CTOPEN=$(tput sgr0)
REPORT=0
LEGEND="chuletas"
TITLE="Chuletas"

while getopts rl:t:c flag
do
    case "${flag}" in
        r) REPORT=1;;
        l) LEGEND=${OPTARG};;
		t) TITLE=${OPTARG};;
        c) COLOUR=1;;
    esac
done

if [ $COLOUR -eq 1 ] ;then
	COPEN=$(tput setaf 3) # yellow
	CCLOSE=$(tput sgr0)
	CTOPEN=$(tput setaf 5)
fi

> /tmp/pruebacolor.txt
printf "  %-4s%s\n" "#" $TITLE
echo
while read linea
do
	COUNT=$(( $COUNT + 1 ))
	if [ $REPORT -eq 1 ]; then
		printf "  %s\n" $linea
	else
		if [ $COLOUR -eq 1 ];then
			MAIN_TOPIC=$(echo $linea | grep -Eo "^[^/]+")
			REST_OF_PATH=$(echo $linea | grep -Eo "/.*$")
			#PRUEBA=$(printf "  %s%-4s%s%s\n" $COPEN $COUNT $CCLOSE $linea)
			printf "  %s%-4s%s%s%s%s\n" $COPEN $COUNT $CTOPEN $MAIN_TOPIC $CCLOSE $REST_OF_PATH >> /tmp/pruebacolor.txt
		else
			printf "  %-4s%s\n" $COUNT $linea >> /tmp/pruebacolor.txt
		fi
	fi
done
cat /tmp/pruebacolor.txt
if [ $REPORT -eq 1 ]; then
	echo
	echo "  $LEGEND"
fi
#echo
#echo $PRUEBA


