#!/bin/bash

set -euo pipefail

RUTA_CACHE=~/.cache/chu
BASE_DIR=~/chuleta/chuleta-data
DB=$RUTA_CACHE/chuletas.db
FTDB=~/chuleta/chuleta/chuletas_ft.db
RELPATH=""
ABSPATH=""
TOTAL=1166
sqlite3 $FTDB "delete from ft;"
while read line
do
	RELPATH="$(echo $line|awk -F, '{print $1}')"
	ABSPATH="$(echo $line|awk -F, '{print $2}')"
	sqlite3 $FTDB "insert into ft(path,doc) values ('$RELPATH',readfile('$ABSPATH'));"
	TOTAL=$(( $TOTAL - 1 ))
	echo "$TOTAL to go"
done < <(sqlite3 $DB ".mode csv" ".separator ','" "select rel_path, abs_path from v_chuleta_ap;")

# (sqlite3 $DB ".mode csv" ".separator = ' '" "select rel_path, abs_path from v_chuleta_ap;")