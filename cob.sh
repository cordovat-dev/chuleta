#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMPORARY}" && test -f "${TEMPORARY}" && rm "${TEMPORARY}"
	exit $1
}

CACHE_DIR=""
LOGS_DIR=""
TEMPORARY=$(mktemp /tmp/chuleta.XXXXX)
set -euo pipefail

while getopts c:l: flag
do
    case "${flag}" in
        c) CACHE_DIR=${OPTARG};;
		l) LOGS_DIR=${OPTARG};;
    esac
done

test -z $CACHE_DIR && exit 1
test -z $LOGS_DIR && exit 1

sleep 2

cd $CACHE_DIR

find . -iname "chuletas.db.*" -mtime +30 -print0 > $TEMPORARY
test $(cat $TEMPORARY|wc -w) -gt 0 && \
tar -czvf backup.chuletas.tar.gz.$(date +%Y%m%d%H%M%S) --remove-files --null -T $TEMPORARY

find . -iname "frequent.db.*" -mtime +30 -print0 > $TEMPORARY
test $(cat $TEMPORARY|wc -w) -gt 0 && \
tar -czvf backup.frequent.tar.gz.$(date +%Y%m%d%H%M%S) --remove-files --null -T $TEMPORARY

