#!/bin/bash
set -euo pipefail

DIR=$(dirname "$0")
MINGW=$([[ "$(uname -a)" =~ ^MINGW ]] && echo YES || echo NO)
RUTA=$(dirname $0)
BACKUPNAME=""
RUTA_CACHE=~/.cache/chu
RUTA_LOGS=~/.cache/chu.logs
RUTA_CONF=~/.config/chu
CONFIG_FILE=$RUTA_CONF/chu.conf
CHULETADB=$RUTA_CACHE/chuletas.db
FREQUENTDB=$RUTA_CACHE/frequent.db

if ! command -v sqlite3 &> /dev/null; then
cat <<EOF

Sqlite3 could not be found
Please install sqlite3 in order to install
and use Chuleta.
EOF
    exit 1
fi

if [ $MINGW == "YES" ];then
	set +e
	net session > /dev/null 2>&1
	if [ $? -ne 0 ];then
		echo "This action must be run as Administrator"
		exit 1
	fi
	set -e
fi

if [ ! -d "${RUTA_CACHE}" ];then
	mkdir "${RUTA_CACHE}"
fi

if [ -f "${CHULETADB}" ];then
	BACKUPNAME="$(echo ${CHULETADB}.$(date +%Y%m%d%H%M%S))"
	mv "${CHULETADB}" "$BACKUPNAME"
	echo "Old chuletas.db moved to $BACKUPNAME"
fi
sqlite3 "${CHULETADB}" ".read "$RUTA/sqlite_db_schema.sql
if [ -f "${FREQUENTDB}" ];then
	BACKUPNAME="$(echo ${FREQUENTDB}.$(date +%Y%m%d%H%M%S))"
	mv "${FREQUENTDB}" "$BACKUPNAME"
	echo "Old frequent.db moved to $BACKUPNAME"
fi
sqlite3 "${FREQUENTDB}" ".read "$RUTA/sqlite_frequent_db_schema.sql
	
if [ ! -d "${RUTA_LOGS}" ];then
	mkdir "${RUTA_LOGS}"
fi
if [ ! -d "${RUTA_CONF}" ];then
	mkdir "${RUTA_CONF}"
fi
if [ ! -f "${CONFIG_FILE}" ];then
	cp $DIR/chu.conf "${RUTA_CONF}/"
	echo MINGW=$MINGW >> "${CONFIG_FILE}"
	echo "...Please edit ${CONFIG_FILE} file."
fi

if [ $MINGW == "YES" ];then
	cp -f $DIR/chu.auto /usr/share/bash-completion/completions/chu
else
	sudo cp -f $DIR/chu.auto /etc/bash_completion.d/
fi

echo "... Please run chu --update before using the utility."
