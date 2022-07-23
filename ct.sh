#!/bin/bash

set -euo pipefail

COPEN=$(tput setaf 3) # yellow
CCLOSE=$(tput sgr0)
CTOPEN=$(tput setaf 5) # magenta
C2TOPEN=$(tput setaf 2) # green
C3TOPEN=$(tput setaf 6) # cyan
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
printf "  %s%-4s%s%s" $COPEN $COUNT $CTOPEN ${myarray[0]}

if [ ${#myarray[@]} -gt 2 ];then
	printf "/%s%s" $C2TOPEN ${myarray[1]}
	y=2
	if [ ${#myarray[@]} -gt 3 ];then
		printf "/%s%s" $C3TOPEN ${myarray[2]}
		y=3
	fi
fi
printf "%s" $CCLOSE

for (( i=y; i<${#myarray[@]}; i++ ));
do
	if [ $i -lt ${#myarray[@]} ];then
		echo -n  "/"
	fi;
    printf "%s" ${myarray[$i]}
done
echo ""
