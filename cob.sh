#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMPORAL}" && test -f "${TEMPORAL}" && rm "${TEMPORAL}"
	exit $1
}

RUTA_CACHE=""
TEMPORAL=$(mktemp /tmp/chuleta.XXXXX)
set -euo pipefail

while getopts c: flag
do
    case "${flag}" in
        c) RUTA_CACHE=${OPTARG};;
    esac
done

test -z $RUTA_CACHE && exit 1

sleep 2

cd $RUTA_CACHE
find $RUTA_CACHE -iname "db.*" -mtime +30 -print0 > $TEMPORAL
test $(cat $TEMPORAL|wc -w) -gt 0 && \
tar -czvf backup.db.tar.gz.$(date +%Y%m%d%H%M%S) --remove-files --null -T $TEMPORAL
