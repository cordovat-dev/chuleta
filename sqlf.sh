#!/bin/bash

set -euo pipefail

DATAFILE=""
DB=""
while getopts f:d: flag
do
    case "${flag}" in
		f) DATAFILE=${OPTARG};;
		d) DB=${OPTARG};;
    esac
done

test -z $DATAFILE && exit 1
test -z $DB && exit 1

SCRIPTTEMP=$(mktemp /tmp/chuleta_insertsXXXXX)
# echo "=========================="
# cat $DATAFILE
# echo "=========================="

# echo ".echo on" >> $SCRIPTTEMP
echo "begin transaction;" >> $SCRIPTTEMP
echo "drop table if exists tempimp;" >> $SCRIPTTEMP
echo "create temp table tempimp(path TEXT);" >> $SCRIPTTEMP
echo ".mode csv" >> $SCRIPTTEMP
echo ".import $DATAFILE tempimp" >> $SCRIPTTEMP
echo "insert into frequent select path,1 from tempimp;" >> $SCRIPTTEMP
echo "drop table if exists tempimp;" >> $SCRIPTTEMP
echo "create temp table tempimp(path TEXT, count INTEGER);" >> $SCRIPTTEMP
echo "insert into tempimp select * from frequent;" >> $SCRIPTTEMP
echo "delete from frequent;" >> $SCRIPTTEMP
echo "insert into frequent select path, sum(count) from tempimp group by path;" >> $SCRIPTTEMP
echo "commit;" >> $SCRIPTTEMP
echo ".headers off" >> $SCRIPTTEMP
echo ".separator ' '" >> $SCRIPTTEMP
echo "select count,path from v_tops;" >> $SCRIPTTEMP
echo ".quit" >> $SCRIPTTEMP
# cat $SCRIPTTEMP
sqlite3 $DB ".read "$SCRIPTTEMP
if [ $? -eq 0 ];then
	# echo "good"
	mv $DATAFILE $DATAFILE$(date +%Y%m%d%H%M%S)
	touch $DATAFILE
# # else
	# # echo "bad"
fi
rm $SCRIPTTEMP

