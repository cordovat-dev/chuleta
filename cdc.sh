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
cd $BASE_DIR

while read myline
do
  if [ ! -f $BASE_DIR/$myline ];then
  	
    git show $(git rev-list -n 1 HEAD -- $myline) | grep -A1 $myline > $TEMP

	set +e 
	fgrep -q "+++ /dev/null" $TEMP
	EXCODE=$?
	set -e
	if [ $EXCODE -eq 0 ];then
		echo $myline deleted!!
	fi
	set -x
	set +e
	fgrep -q "rename to" $TEMP
	EXCODE=$?
	set -e
	if [ $EXCODE -eq 0 ];then
		cat $TEMP
		echo $myline $(grep -o "rename to .*" $TEMP)
		fgrep -o "rename to .*" $TEMP
		exit 0
	fi	
	set +x
  fi
done < <(sqlite3 $RUTA_CACHE/frequent.db "select path from frequent;")