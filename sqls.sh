#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${DATATEMP}" && test -f "${DATATEMP}" && rm "${DATATEMP}"
	test -n "${SCRIPTTEMP}" && test -f "${SCRIPTTEMP}" && rm "${SCRIPTTEMP}"
	echo "ha fallado"
	exit $1
}

set -euo pipefail

BASE_DIR=""
DB=""
NUM_DAYS_OLD=""
FTSDB=""
while getopts b:d:t:w: flag
do
    case "${flag}" in
		b) BASE_DIR=${OPTARG};;
		d) DB=${OPTARG};;
		t) FTSDB=${OPTARG};;
		w) NUM_DAYS_OLD=${OPTARG};;
    esac
done

test -z ${BASE_DIR} && exit 1
test -z ${DB} && exit 1
test -z ${FTSDB} && exit 1
test -z ${NUM_DAYS_OLD} && exit 1

DATATEMP=$(mktemp /tmp/chuleta_inserts.XXXXX)
SCRIPTTEMP=$(mktemp /tmp/chuleta_inserts.XXXXX)


find ${BASE_DIR} -regextype sed \
-regex "^.*[.a-z0-9/_-]*chuleta_[.a-z0-9/_-]*\.txt$"|\
sed "s|${BASE_DIR}/||g" > ${DATATEMP}

echo "select 'Updating settings';" >> ${SCRIPTTEMP}
echo -n "attach '" >> ${SCRIPTTEMP}
echo -n ${FTSDB} >> ${SCRIPTTEMP}
echo "' as ftsdb;" >> ${SCRIPTTEMP}
echo "insert or replace into settings(key,value) values ('LAST_UPDATED',CURRENT_TIMESTAMP);" >> ${SCRIPTTEMP}
echo "drop table if exists tempimp;" >> ${SCRIPTTEMP}
echo "create temp table tempimp(path TEXT);" >> ${SCRIPTTEMP}
echo ".mode line" >> ${SCRIPTTEMP}
echo "select count(*) before from chuleta;" >> ${SCRIPTTEMP}
echo "delete from chuleta;" >> ${SCRIPTTEMP}
echo ".mode csv" >> ${SCRIPTTEMP}
echo ".import ${DATATEMP} tempimp" >> ${SCRIPTTEMP}
echo ".mode line" >> ${SCRIPTTEMP}
echo "select count(*) processing from tempimp;" >> ${SCRIPTTEMP}
echo "insert into chuleta select null,path from tempimp;" >> ${SCRIPTTEMP}
echo "select count(*) after from chuleta;" >> ${SCRIPTTEMP}
echo "insert or replace into last_opened values (1,(select path from chuleta where id = 1));" >> ${SCRIPTTEMP}
echo ".quit" >> ${SCRIPTTEMP}

cat ${SCRIPTTEMP}

sqlite3 ${DB} ".read "${SCRIPTTEMP}
