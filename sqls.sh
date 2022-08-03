#!/bin/bash

set -euo pipefail

BASE_DIR=""
DB=""
while getopts b:d: flag
do
    case "${flag}" in
		b) BASE_DIR=${OPTARG};;
		d) DB=${OPTARG};;
    esac
done

test -z $BASE_DIR && exit 1
test -z $DB && exit 1

# BASE_DIR="/c/Users/Global/chuleta/chuleta-data/"
# DB="/c/Users/Global/chuleta/chuleta/chuletas.db"
DATATEMP=$(mktemp /tmp/chuleta_insertsXXXXX)
SCRIPTTEMP=$(mktemp /tmp/chuleta_insertsXXXXX)


find $BASE_DIR -regextype sed \
-regex "^.*[.a-z0-9/_-]*chuleta_[.a-z0-9/_-]*\.txt$"|\
sed "s|$BASE_DIR/||g" > $DATATEMP

echo ".echo on" >> $SCRIPTTEMP
echo "drop table if exists tempimp;" >> $SCRIPTTEMP
echo "create temp table tempimp(path TEXT);" >> $SCRIPTTEMP
echo "delete from chuleta;" >> $SCRIPTTEMP
echo "select count(*) from chuleta;" >> $SCRIPTTEMP
echo ".mode csv" >> $SCRIPTTEMP
echo ".import $DATATEMP tempimp" >> $SCRIPTTEMP
echo "insert into chuleta select null,path from tempimp;" >> $SCRIPTTEMP
echo "select count(*) from chuleta;" >> $SCRIPTTEMP
echo "select * from chuleta limit 5;" >> $SCRIPTTEMP
echo ".quit" >> $SCRIPTTEMP
# cat $SCRIPTTEMP
sqlite3 $DB ".read "$SCRIPTTEMP
rm $DATATEMP $SCRIPTTEMP

