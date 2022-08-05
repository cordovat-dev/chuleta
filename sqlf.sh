#!/bin/bash

set -euo pipefail

DATAFILE=""
DB=""
CACHE_DIR=""
while getopts f:d:c: flag
do
    case "${flag}" in
		f) DATAFILE=${OPTARG};;
		d) DB=${OPTARG};;
		c) CACHE_DIR=${OPTARG};;
    esac
done

test -z $DATAFILE && exit 1
test -z $DB && exit 1
test -z $CACHE_DIR && exit 1

SCRIPTTEMP=$(mktemp /tmp/chuleta_insertsXXXXX)

echo "attach database '$CACHE_DIR/frequent.db' as frequent;" >> $SCRIPTTEMP
echo "begin transaction;" >> $SCRIPTTEMP
echo "drop table if exists tempimp;" >> $SCRIPTTEMP
echo "create temp table tempimp(path TEXT);" >> $SCRIPTTEMP
echo ".mode csv" >> $SCRIPTTEMP
echo ".import $DATAFILE tempimp" >> $SCRIPTTEMP
echo ".mode line" >> $SCRIPTTEMP
echo "select count(*) groups_before from frequent.v_tops;" >> $SCRIPTTEMP
echo "select count(*) updating from tempimp;" >> $SCRIPTTEMP
echo "insert into frequent.frequent select path,1 from tempimp;" >> $SCRIPTTEMP
echo "drop table if exists tempimp;" >> $SCRIPTTEMP
echo "create temp table tempimp(path TEXT, count INTEGER);" >> $SCRIPTTEMP
echo "insert into tempimp select * from frequent.frequent;" >> $SCRIPTTEMP
echo "delete from frequent.frequent;" >> $SCRIPTTEMP
echo "insert into frequent.frequent select path, sum(count) from tempimp group by path;" >> $SCRIPTTEMP
echo "select count(*) groups_after from frequent.v_tops;" >> $SCRIPTTEMP
echo "commit;" >> $SCRIPTTEMP
echo ".headers off" >> $SCRIPTTEMP
echo ".mode list" >> $SCRIPTTEMP
echo ".separator ' '" >> $SCRIPTTEMP
echo "select count,path from frequent.v_tops;" >> $SCRIPTTEMP
echo ".quit" >> $SCRIPTTEMP

sqlite3 $DB ".read "$SCRIPTTEMP
if [ $? -eq 0 ];then
	mv $DATAFILE $DATAFILE$(date +%Y%m%d%H%M%S)
	touch $DATAFILE
fi
rm $SCRIPTTEMP

