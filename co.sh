#!/bin/bash

NO_OLD_DB_WRN=""
RUTA_CACHE=""
while getopts w:c: flag
do
    case "${flag}" in
        w) NO_OLD_DB_WRN=${OPTARG};;
		c) RUTA_CACHE=${OPTARG};;
    esac
done

test -z $NO_OLD_DB_WRN && exit 1
test -z $RUTA_CACHE && exit 1

CHULETADB=$RUTA_CACHE/chuletas.db

if [ $NO_OLD_DB_WRN -ne 1 ];then
	sqlite3 "${CHULETADB}" "select * from v_old_db_msg;"
fi