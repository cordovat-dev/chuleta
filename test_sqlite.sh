#!/bin/bash

set -euo pipefail

TEMP=$(mktemp /tmp/chuleta.XXXXX)
BASE_DIR=/c/Users/Global/chuleta/chuleta-data/
DB=/c/Users/Global/chuleta/chuleta/chuletas.db
SQLTEMP=$(mktemp /tmp/chuleta_insertsXXXXX.sql)
find $BASE_DIR -regextype sed \
-regex "^.*[a-z0-9/_-]*chuleta_[a-z0-9/_-]*\.txt$"|\
sed 's/$BASE_DIR//g' > $TEMP
COUNT=0
echo "delete from chuleta;" > $SQLTEMP
while read linea
do
	# -vx
	# sqlite3 $DB "insert into chuleta (path) values ('"$linea"');"
	# +vx
	COUNT=$(( $COUNT + 1 ))
	echo "insert into chuleta (path) values ('"$linea"');" >> $SQLTEMP
done < $TEMP
set -x 
set -v
sqlite3 $DB ".read "$SQLTEMP
rm $TEMP $SQLTEMP

