#!/bin/bash
set -euo pipefail

DIR=$(dirname "$0")
MINGW=$([[ "$(uname -a)" =~ ^MINGW ]] && echo YES || echo NO)
RUTA=$(dirname $0)
BACKUPNAME=""

if [ $MINGW == "YES" ];then
	set +e
	net session > /dev/null 2>&1
	if [ $? -ne 0 ];then
		echo "This action must be run as Administrator"
		exit 1
	fi
	set -e
fi

if [ ! -d ~/.cache/chu ];then
	mkdir ~/.cache/chu
fi

if [ -f ~/.cache/chu/chuletas.db ];then
	BACKUPNAME="$(echo ~/.cache/chu/chuletas.db.$(date +%Y%m%d%H%M%S))"
	mv ~/.cache/chu/chuletas.db $BACKUPNAME
	echo "Old chuletas.db moved to $BACKUPNAME"
fi
sqlite3 ~/.cache/chu/chuletas.db ".read "$RUTA/sqlite_db_schema.sql
if [ -f ~/.cache/chu/frequent.db ];then
	BACKUPNAME="$(echo ~/.cache/chu/frequent.db.$(date +%Y%m%d%H%M%S))"
	mv ~/.cache/chu/frequent.db $BACKUPNAME
	echo "Old frequent.db moved to $BACKUPNAME"
fi
sqlite3 ~/.cache/chu/frequent.db ".read "$RUTA/sqlite_frequent_db_schema.sql
	
if [ ! -d ~/.cache/chu.logs ];then
	mkdir ~/.cache/chu.logs
fi
if [ ! -d ~/.config/chu ];then
	mkdir ~/.config/chu
fi
if [ ! -f ~/.config/chu/chu.conf ];then
	cp $DIR/chu.conf ~/.config/chu/
	echo MINGW=$MINGW >> ~/.config/chu/chu.conf
	echo "...Please edit ~/.config/chu/chu.conf file."
fi

if [ $MINGW == "YES" ];then
	cp -f $DIR/chu.auto /usr/share/bash-completion/completions/chu
else
	sudo cp -f $DIR/chu.auto /etc/bash_completion.d/
fi

echo "... Please run chu --update before using the utility."
