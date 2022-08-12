#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMP}" && test -f "${TEMP}" && rm "${TEMP}"

	exit $1
}

set -euo pipefail
RUTA_CACHE=~/.cache/chu
BASE_DIR=~/chuleta/chuleta-data
TEMP=$(mktemp /tmp/chuleta.XXXXX)
EXCODE=0
new_name=""
TABLE_DELETED="deleted_$(date +%Y%m%d%H%M%S)"
TABLE_UPDATED="updated_$(date +%Y%m%d%H%M%S)"
cd $BASE_DIR

echo ".echo on"
echo "begin transaction;"
echo "create table $TABLE_DELETED(path text, count integer);"
echo "create table $TABLE_UPDATED(path text, count integer);"
while read old_name
do
  if [ ! -f $BASE_DIR/$old_name ];then
  	
    git show $(git rev-list -n 1 HEAD -- $old_name) | grep -A1 $old_name > $TEMP

	set +e 
	fgrep -q "+++ /dev/null" $TEMP
	EXCODE=$?
	set -e
	if [ $EXCODE -eq 0 ];then
		echo "insert into $TABLE_DELETED select * from frequent where path = '$old_name';"
		echo
		echo "delete from frequent where path = '$old_name';"
		echo
	fi
	set +e
	fgrep -q "rename to" $TEMP
	EXCODE=$?
	set -e
	if [ $EXCODE -eq 0 ];then
		new_name=$(grep -o "rename to .*" $TEMP|sed 's/rename to //g')
		echo "insert into $TABLE_UPDATED select * from frequent where path = '$new_name';"
		echo
		echo "update frequent set count=count+(select count from frequent where path ='$old_name') where path='$new_name';"
		echo
		echo "insert into $TABLE_DELETED select * from frequent where path = '$old_name';"
		echo
		echo "delete from frequent where path ='$old_name';"
		echo
		# echo $old_name $(grep -o "rename to .*" $TEMP|sed 's/rename to //g')
		
	fi	
  fi
done < <(sqlite3 $RUTA_CACHE/frequent.db "select path from frequent;")
echo "commit;"