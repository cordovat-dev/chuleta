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
UPDATES_TABLE="update_$(date +%Y%m%d%H%M%S)"
cd $BASE_DIR

echo ".echo on"
echo "drop table $UPDATES_TABLE;"
echo "begin transaction;"
echo "create frequent_$(date +%Y%m%d%H%M%S) as select * from frequent;"
echo
echo "create table $UPDATES_TABLE(path text, count integer, old_path text, oper text );"
while read old_name
do
  if [ ! -f $BASE_DIR/$old_name ];then
  	
    git show $(git rev-list -n 1 HEAD -- $old_name) | grep -A1 $old_name > $TEMP

	set +e 
	fgrep -q "+++ /dev/null" $TEMP
	EXCODE=$?
	set -e
	if [ $EXCODE -eq 0 ];then
		echo "insert into $UPDATES_TABLE select path, count, null, 'delete' from frequent where path = '$old_name';"
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
		echo "insert into $UPDATES_TABLE select path, count, '$old_name', 'update' from frequent where path = '$new_name';"
		echo
		echo "update frequent set count=count+(select count from frequent where path ='$old_name') where path='$new_name';"
		echo
		echo "insert into $UPDATES_TABLE select path, count, '$new_name', 'delete' from frequent where path = '$old_name';"
		echo
		echo "delete from frequent where path ='$old_name';"
		echo
		# echo $old_name $(grep -o "rename to .*" $TEMP|sed 's/rename to //g')
		
	fi	
  fi
done < <(sqlite3 $RUTA_CACHE/frequent.db "select path from frequent;")
echo "commit;"