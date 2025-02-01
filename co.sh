#!/bin/bash

## check old. Check whether or not the database needs updating.

OLD_DB_WRN=""
CACHE_DIR=""
while getopts w:c: flag
do
    case "${flag}" in
        w) OLD_DB_WRN=${OPTARG};;
		c) CACHE_DIR=${OPTARG};;
    esac
done

test -z ${OLD_DB_WRN} && exit 1
test -z ${CACHE_DIR} && exit 1

CHULETADB=${CACHE_DIR}/chuletas.db

if [ "${OLD_DB_WRN}" == "YES" ];then
	sqlite3 "${CHULETADB}" "select * from v_old_db_msg;"
fi