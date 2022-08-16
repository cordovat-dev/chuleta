#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMPORAL}" && test -f "${TEMPORAL}" && rm "${TEMPORAL}"
	exit $1
}

RUTA_CACHE=""
RUTA_LOGS=""
TEMPORAL=$(mktemp /tmp/chuleta.XXXXX)
set -euo pipefail

while getopts c:l: flag
do
    case "${flag}" in
        c) RUTA_CACHE=${OPTARG};;
		l) RUTA_LOGS=${OPTARG};;
    esac
done

test -z $RUTA_CACHE && exit 1
test -z $RUTA_LOGS && exit 1

sleep 2

cd $RUTA_CACHE

find . -iname "chuletas.db.*" -mtime +30 -print0 > $TEMPORAL
test $(cat $TEMPORAL|wc -w) -gt 0 && \
tar -czvf backup.chuletas.tar.gz.$(date +%Y%m%d%H%M%S) --remove-files --null -T $TEMPORAL 

find $RUTA_CACHE -iname "frequent.db.*" -mtime +30 -print0 > $TEMPORAL
test $(cat $TEMPORAL|wc -w) -gt 0 && \
tar -czvf backup.frequent.tar.gz.$(date +%Y%m%d%H%M%S) --remove-files --null -T TEMPORAL

cd $RUTA_LOGS

find $RUTA_LOGS -iname "frequent_*" -mtime +30 -print0 > $TEMPORAL
test $(cat $TEMPORAL|wc -w) -gt 0 && \
tar -czvf backup.frequent_.tar.gz.$(date +%Y%m%d%H%M%S) --remove-files --null -T TEMPORAL
