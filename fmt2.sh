#!/bin/bash
set -eo pipefail

# these two parms must be used together in this sequence or not at all:
# -n -i
PARM1="$1" # no line numbers, but a total 
PARM2="$2" # change "chuletas" legend to "items"
set -u
RUTA=`dirname $0`
COUNT=0
COLOUR=1
COPEN=$(tput sgr0)
CCLOSE=$(tput sgr0)

if [ $COLOUR -eq 1 ] ;then
	COPEN=$(tput setaf 3) # yellow
	CCLOSE=$(tput sgr0)
fi

while read linea
do
	COUNT=$(( $COUNT + 1 ))
	if [ "$PARM1" = "-n" ]; then
		printf "  %s\n" $linea
	else
		PRUEBA=$(printf "  %s%-4s%s%s\n" $COPEN $COUNT $CCLOSE $linea)
		printf "  %s%-4s%s%s\n" $COPEN $COUNT $CCLOSE $linea
	fi
done
if [ "$PARM1" = "-n" ]; then
	echo
	echo "  Chuletas"
fi
#echo
#echo $PRUEBA


