#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMP}" && test -f "${TEMP}" && rm "${TEMP}"
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

function generateDML {
echo ".echo on"
echo "BEGIN TRANSACTION;"
# these ones are deleted to prevent gaps in numbers
echo "delete from settings where key like 'GIT_REPO%';"
echo "delete from settings where key like 'PREF_GIT_REPO2%';"
awk -F= -f <(cat - <<-"EOF"
	/GIT_REPO[0-9]+/ {
		printf ("insert or replace into settings (key,value) values (\x27%s\x27,\x27%s\x27);\n",$1,$2) 
	}
	/NUM_DAYS_OLD/ {
		printf ("insert or replace into settings (key,value) values (\x27%s\x27,\x27%s\x27);\n",$1,$2) 
	}
EOF
)
source ${configfile}
local bdir=$(echo ${BASE_DIR})
echo "insert or replace into settings (key,value) values ('BASE_DIR','${bdir}');"
echo "END TRANSACTION;"
}

cat "${configfile}" | generateDML > "${TEMP}"
sqlite3 "${dbfile}" ".read "${TEMP}
