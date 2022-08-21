#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMPDATA}" && test -f "${TEMPDATA}" && rm "${TEMPDATA}"
	test -n "${TEMPSCRIPT}" && test -f "${TEMPSCRIPT}" && rm "${TEMPSCRIPT}"
	test -n "${TEMPSED}" && test -f "${TEMPSED}" && rm "${TEMPSED}"
	test -n "${TEMPRESULTDATA}" && test -f "${TEMPRESULTDATA}" && rm "${TEMPRESULTDATA}"
	test -n "${TEMPRESULTDATA2}" && test -f "${TEMPRESULTDATA2}" && rm "${TEMPRESULTDATA2}"
	exit $1
}

set -euo pipefail
RUTA_CACHE=~/.cache/chu
BASE_DIR=~/chuleta/chuleta-data
TEMPDATA=$(mktemp /tmp/chuleta.XXXXX)
TEMPRESULTDATA=$(mktemp /tmp/chuleta.XXXXX)
TEMPRESULTDATA2=$(mktemp /tmp/chuleta.XXXXX)
TEMPSCRIPT=$(mktemp /tmp/chuleta.XXXXX)
TEMPSED=$(mktemp /tmp/chuleta.XXXXX)
EXCODE=0
BACKUPTABLE="frequent_log_$(date +%Y%m%d%H%M%S)"

cp -p $RUTA_CACHE/frequent.db $RUTA_CACHE/frequent.db.$(date +%Y%m%d%H%M%S)

sqlite3 $RUTA_CACHE/frequent.db <<EOF
.echo on
select 'Exporting '||(select count(*) from frequent_log)||' rows';
.mode csv
.echo off
.output ${TEMPDATA}
select * from frequent_log;
EOF

cd $BASE_DIR

git diff --name-status -C $(git rev-list HEAD|tail -1)..HEAD|grep "^R"|awk '{printf("s#%s#%s#g\n",$2,$3)}' > ${TEMPSED}
sed -Ef ${TEMPSED} ${TEMPDATA} > ${TEMPRESULTDATA}
git diff --name-status -C $(git rev-list HEAD|tail -1)..HEAD|grep "^D"|awk '{printf("#%s#d\n",$2)}' > ${TEMPSED}
sed -Ef ${TEMPSED} ${TEMPRESULTDATA} > ${TEMPRESULTDATA2}

sqlite3 $RUTA_CACHE/frequent.db <<EOF
.echo on
create table ${BACKUPTABLE} as select * from frequent_log;
insert into ${BACKUPTABLE} select * from frequent_log;
delete from frequent_log;
.mode csv
.import ${TEMPRESULTDATA2} frequent_log
select 'Imported '||(select count(*) from frequent_log)||' rows';
.exit
EOF

exit 0

