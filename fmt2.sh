#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMP}" && test -f "${TEMP}" && rm "${TEMP}"
	exit $1
}

set -eo pipefail

set -u
SCRIPT_DIR=$(dirname $0)
COUNT=0
COLOUR=0
REPORT=0
LEGEND="chuletas"
TITLE="Chuletas"
NOCOLOR_FILE=""
HASNUMBERS=0
HEADERCOL1="#"
COUNT=0
TEMP=$(mktemp /tmp/chuleta.XXXXX)

while getopts rl:t:cnf: flag
do
    case "${flag}" in
		r) REPORT=1;;
		l) LEGEND=${OPTARG};;
		t) TITLE=${OPTARG};;
		c) COLOUR=1;;
		f) NOCOLOR_FILE=${OPTARG};;
		n) HASNUMBERS=1;;
    esac
done

if [ $HASNUMBERS -eq 1 ];then
	HEADERCOL1="N"
fi
if [ $REPORT -ne 1 ]; then
	printf "  %-4s%s\n" "$HEADERCOL1" $TITLE
	echo
fi
if [ -n "$NOCOLOR_FILE" ];then
	echo -n "" > ${NOCOLOR_FILE}
fi
	
while read line
do
	if [ $HASNUMBERS -eq 1 ];then
		   templine=$line
		   COUNT=$(awk '{print $1}' <(echo $templine))
		   line=$(awk '{print $2}' <(echo $templine))
	else
		   COUNT=$(( $COUNT + 1 ))
	fi
	if [ $REPORT -eq 1 ]; then
		printf "  %s\n" $line
	else
		printf "  %-4s%s\n" $COUNT $line
	fi
done > $TEMP

if [ $COLOUR -eq 1 ]; then
	$SCRIPT_DIR/ac.sed $TEMP
else
	cat $TEMP
fi

if [ -n "$NOCOLOR_FILE" ];then
	cp $TEMP ${NOCOLOR_FILE}
fi;

if [ $REPORT -eq 1 ]; then
	echo
	echo "  $COUNT $LEGEND"
fi


