#!/bin/bash
set -euo pipefail

DIR=$(dirname "$0")
set +e
net session > /dev/null 2>&1
if [ $? -ne 0 ];then
	echo "Esta operación debe ejecutarse como Admin"
	exit 1
fi
set -e

if [ ! -d "~/.cache/chu" ];then
	mkdir ~/.cache/chu
fi
if [ ! -d "~/.cache/chu.logs" ];then
	mkdir ~/.cache/chu.logs
fi
cp -f $DIR/chu.auto /usr/share/bash-completion/completions/chu


