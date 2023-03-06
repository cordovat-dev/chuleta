#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$0")
ALIAS_PATH=$(readlink -e ${SCRIPT_DIR})
MINGW=$([[ "$(uname -a)" =~ ^MINGW ]] && echo YES || echo NO)
BACKUPNAME=""
CACHE_DIR=~/.cache/chu
RUTA_CONF=~/.config/chu
CONFIG_FILE="${RUTA_CONF}"/chu.conf
CHULETADB="${CACHE_DIR}"/chuletas.db
FREQUENTDB="${CACHE_DIR}"/frequent.db

if ! command -v sqlite3 &> /dev/null; then
cat <<EOF

Sqlite3 could not be found
Please install sqlite3 in order to install
and use Chuleta.
EOF
    exit 1
fi

if ! command -v gawk &> /dev/null; then
cat <<EOF

gawk could not be found
Please install gawk in order to install
and use Chuleta.
EOF
    exit 1
fi

if ! command -v tree &> /dev/null; then
cat <<EOF

tree could not be found
Please install tree in order to install
and use Chuleta.
EOF
    exit 1
fi

if ! command -v xdg-open &> /dev/null; then
cat <<EOF

xdg-open could not be found
Please install tree in order to install
and use Chuleta.
EOF
    exit 1
fi

if [ "${MINGW}" = "YES" ];then
	set +e
	net session > /dev/null 2>&1
	if [ $? -ne 0 ];then
		echo "This action must be run as Administrator"
		exit 1
	fi
	set -e
fi

if [ ! -d "${CACHE_DIR}" ];then
	mkdir "${CACHE_DIR}"
fi

if [ -f "${CHULETADB}" ];then
	BACKUPNAME="$(echo ${CHULETADB}.$(date +%Y%m%d%H%M%S))"
	mv "${CHULETADB}" "${BACKUPNAME}"
	echo "Old chuletas.db moved to ${BACKUPNAME}"
fi
sqlite3 "${CHULETADB}" ".read "${SCRIPT_DIR}/sqlite_db_schema.sql
if [ -f "${FREQUENTDB}" ];then
	BACKUPNAME="$(echo ${FREQUENTDB}.$(date +%Y%m%d%H%M%S))"
	mv "${FREQUENTDB}" "${BACKUPNAME}"
	echo "Old frequent.db moved to ${BACKUPNAME}"
fi
sqlite3 "${FREQUENTDB}" ".read "${SCRIPT_DIR}/sqlite_frequent_db_schema.sql
	
if [ ! -d "${RUTA_CONF}" ];then
	mkdir "${RUTA_CONF}"
fi
if [ ! -f "${CONFIG_FILE}" ];then
	cp "${SCRIPT_DIR}"/chu.conf "${RUTA_CONF}/"
	echo MINGW=${MINGW} >> "${CONFIG_FILE}"
	echo "...Please edit ${CONFIG_FILE} file."
fi

if [ "${MINGW}" = "YES" ];then
	cp -f "${SCRIPT_DIR}"/chu.auto /usr/share/bash-completion/completions/chu
else
	sudo cp -f "${SCRIPT_DIR}"/chu.auto /etc/bash_completion.d/
fi

echo
echo "Setting file permissions..."
echo "Done"
echo
cd ${SCRIPT_DIR}
chmod 750 *.sh *.awk *.sed

cat <<EOF
Please do this steps before using the utility"

1. Add this alias to .bashrc

alias chu='${ALIAS_PATH}/main.sh'
source .bashrc

2. Edit the config file adding at least the path 
to the chuletas folder to BASE_DIR

chu --config

3. Populate the database

chu --update

EOF