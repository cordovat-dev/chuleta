#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(dirname $0)

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

if [ ${COLOUR} -eq 0 ];then
	printf "  %-4s%s\n" ${COUNT} ${DATA}
	exit 0
fi

printf "  %-4s%s\n" ${COUNT} ${DATA} | ${SCRIPT_DIR}/ac.sed

exit 0
