#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMP}" && test -f "${TEMP}" && rm "${TEMP}"
	test -n "${TEMPCONFILE}" && test -f "${TEMPCONFILE}" && rm "${TEMPCONFILE}"
	exit $1
}

set -euo pipefail

configfile=""
dbfile=""

while getopts c:d: flag
do
    case "${flag}" in
		c) configfile="${OPTARG}";;
		d) dbfile="${OPTARG}";;
    esac
done

test -z ${configfile} && exit 1
test -z ${dbfile} && exit 1

TEMP="$(mktemp /tmp/chuleta.XXXXX)"
TEMPCONFILE="$(mktemp /tmp/chuleta.XXXXX)"
egrep -v "^#" "${configfile}" > "${TEMPCONFILE}"

function generateDML {
echo ".echo on"
echo "BEGIN TRANSACTION;"
# these ones are deleted to PREVENT GAPS IN NUMBERS
echo "delete from settings where key like 'GIT_REPO%';"
echo "delete from settings where key like 'PREF_GIT_REPO2%';"
source ${TEMPCONFILE}
if [ "${GIT_INTEGRATION:-NO}" != "YES" ];then
       echo "delete from settings where key = 'LAST_GIT_TAG';"
else
awk -F= -f <(cat - <<-"EOF"
	/GIT_REPO[0-9]+/ {
		printf ("insert or replace into settings (key,value) values (\x27%s\x27,\x27%s\x27);\n",$1,$2) 
	}
EOF
)
fi

local bdir=$(echo ${BASE_DIR})
echo "insert or replace into settings (key,value) values ('BASE_DIR','${bdir}');"
echo "insert or replace into settings (key,value) values ('NUM_DAYS_OLD','${NUM_DAYS_OLD:-8}');"
echo "END TRANSACTION;"
}

cat "${TEMPCONFILE}" | generateDML > "${TEMP}"
sqlite3 "${dbfile}" ".read "${TEMP}
