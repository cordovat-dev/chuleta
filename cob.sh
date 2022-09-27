#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMPORARY}" && test -f "${TEMPORARY}" && rm "${TEMPORARY}"
	exit $1
}

CACHE_DIR=""
TEMPORARY=$(mktemp /tmp/chuleta.XXXXX)
set -euo pipefail

while getopts c: flag
do
    case "${flag}" in
        c) CACHE_DIR=${OPTARG};;
    esac
done

test -z ${CACHE_DIR} && exit 1

sleep 2

cd ${CACHE_DIR}

compressed_file=backup.chuletas.tar.gz.$(date +%Y%m%d%H%M%S)
if [ ! -f compress_chuletas_backup ] || [[ $(find compress_chuletas_backup -mtime +7 -print) ]];then
	find . -iname "chuletas.db.*" -print0 | tar -czvf ${compressed_file} --remove-files --null -T -
	test $(tar -ztvf ${compressed_file}|wc -l) -eq 0 && rm ${compressed_file}
	touch compress_chuletas_backup
fi

compressed_file=backup.frequent.tar.gz.$(date +%Y%m%d%H%M%S)
if [ ! -f compress_frequent_backup ] || [[ $(find compress_frequent_backup -mtime +7 -print) ]];then
	find . -iname "frequent.db.*" -print0 | tar -czvf ${compressed_file} --remove-files --null -T -
	test $(tar -ztvf ${compressed_file}|wc -l) -eq 0 && rm ${compressed_file}
	touch compress_frequent_backup
fi

find . -iname "backup.*.tar.gz.*" -mtime +30 -delete
find /tmp/ -maxdepth 1 -iname "chuleta.nohup.*" -mmin +30 -delete
