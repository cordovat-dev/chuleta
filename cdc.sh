#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMPDATA}" && test -f "${TEMPDATA}" && rm "${TEMPDATA}"
	test -n "${TEMPSCRIPT}" && test -f "${TEMPSCRIPT}" && rm "${TEMPSCRIPT}"
	test -n "${TEMPSED}" && test -f "${TEMPSED}" && rm "${TEMPSED}"
	test -n "${TEMPRESULTDATA}" && test -f "${TEMPRESULTDATA}" && rm "${TEMPRESULTDATA}"
	exit $1
}

set -euo pipefail
RUTA_CACHE=~/.cache/chu
BASE_DIR=~/chuleta/chuleta-data
TEMPDATA=$(mktemp /tmp/chuleta.XXXXX)
TEMPRESULTDATA=$(mktemp /tmp/chuleta.XXXXX)
TEMPSCRIPT=$(mktemp /tmp/chuleta.XXXXX)
TEMPSED=$(mktemp /tmp/chuleta.XXXXX)
EXCODE=0
BACKUPTABLE="frequent_log_$(date +%Y%m%d%H%M%S)"
cd $BASE_DIR

echo ".echo on" > "${TEMPSCRIPT}"
echo "select 'Exporting '||(select count(*) from frequent_log)||' rows';" >> "${TEMPSCRIPT}"
echo ".mode csv" >> "${TEMPSCRIPT}"
echo ".separator ' '" >> "${TEMPSCRIPT}"
echo ".output $TEMPDATA " >> "${TEMPSCRIPT}"
echo ".output $TEMPDATA " >> "${TEMPSCRIPT}"
sqlite3 $RUTA_CACHE/frequent.db ".read "${TEMPSCRIPT}

cd $BASE_DIR

git diff --name-status -C $(git rev-list HEAD|tail -1)..HEAD|grep "^R"|awk '{printf("s#%s#%s#g\n",$2,$3)}' > $TEMPSED
sed -Ef $TEMPSED $TEMPDATA > $TEMPRESULTDATA

echo ".echo on" > "${TEMPSCRIPT}"
echo "create table $BACKUPTABLE as select * from frequent_log;" >> "${TEMPSCRIPT}"
echo "insert into $BACKUPTABLE select * from frequent_log;" >> "${TEMPSCRIPT}"
echo "delete from frequent_log;" >> "${TEMPSCRIPT}"
echo ".mode csv" >> "${TEMPSCRIPT}" >> "${TEMPSCRIPT}"
echo ".separator ' '" >> "${TEMPSCRIPT}" >> "${TEMPSCRIPT}"
echo ".import $TEMPRESULTDATA frequent_log"
echo ".exit"

