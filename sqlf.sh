#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${SCRIPTTEMP}" && test -f "${SCRIPTTEMP}" && rm "${SCRIPTTEMP}"
	exit $1
}

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

SCRIPTTEMP=$(mktemp /tmp/chuleta_inserts.XXXXX)

echo "attach database '$CACHE_DIR/frequent.db' as frequent;" >> $SCRIPTTEMP
echo "begin transaction;" >> $SCRIPTTEMP
# create temporary table to import the contents of the file
echo "drop table if exists tempimp;" >> $SCRIPTTEMP
echo "create temp table tempimp(path TEXT);" >> $SCRIPTTEMP
# import the contents of file (paths)
echo ".mode csv" >> $SCRIPTTEMP
echo ".import $DATAFILE tempimp" >> $SCRIPTTEMP
echo ".mode line" >> $SCRIPTTEMP
# show the status before processing
echo "select count(*) groups_before from frequent.v_tops;" >> $SCRIPTTEMP
# show the numbers of rows to be processed
echo "select count(*) updating from tempimp;" >> $SCRIPTTEMP
# insert into frequents the path with a count of 1 (table has no PK)
echo "insert into frequent.frequent select path,1 from tempimp;" >> $SCRIPTTEMP
# we drop the temporary table and create another one with the same name but
# with an additional column for count, similar to frequent
echo "drop table if exists tempimp;" >> $SCRIPTTEMP
echo "create temp table tempimp(path TEXT, count INTEGER);" >> $SCRIPTTEMP
# we insert into this temp table everything from frequent (which already
# has the new rows
echo "insert into tempimp select * from frequent.frequent;" >> $SCRIPTTEMP
# delete  all from frequent
echo "delete from frequent.frequent;" >> $SCRIPTTEMP
# we do the maths and insert into frequent freshly summarized data
echo "insert into frequent.frequent select path, sum(count) from tempimp group by path;" >> $SCRIPTTEMP
# show the groups after processing.
echo "select count(*) groups_after from frequent.v_tops;" >> $SCRIPTTEMP
echo "commit;" >> $SCRIPTTEMP
echo ".headers off" >> $SCRIPTTEMP
echo ".mode list" >> $SCRIPTTEMP
echo ".separator ' '" >> $SCRIPTTEMP
# this is the report, v_tops shows the paths whose count is over the average, and that reduction
# is made twice
echo "select count,path from frequent.v_tops;" >> $SCRIPTTEMP
echo ".quit" >> $SCRIPTTEMP

sqlite3 $DB ".read "$SCRIPTTEMP
if [ $? -eq 0 ];then
	mv $DATAFILE $DATAFILE$(date +%Y%m%d%H%M%S)
	touch $DATAFILE
fi

