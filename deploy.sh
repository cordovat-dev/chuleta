#!/bin/bash
set -euo pipefail

DIR=$(dirname "$0")
net session > /dev/null 2>&1
if [ $? -ne 0 ];then
	echo "Esta operación debe ejecutarse como Admin"
	exit 1
fi

#sudo cp -f sbd.1 /usr/share/man/man1/
#sudo gzip -f /usr/share/man/man1/sbd.1
if [ ! -d "~/.cache/chu" ];then
	mkdir ~/.cache/chu
fi
if [ ! -d "~/.cache/chu.logs" ];then
	mkdir ~/.cache/chu.logs
fi
cp -f $DIR/chu.auto /usr/share/bash-completion/completions/chu


