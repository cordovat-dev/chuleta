#!/bin/bash
set -euo pipefail

DIR=$(dirname "$0")
MINGW=$([[ "$(uname -a)" =~ ^MINGW ]] && echo YES || echo NO)

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
if [ ! -d ~/.cache/chu.logs ];then
	mkdir ~/.cache/chu.logs
fi
if [ ! -d ~/.config/chu ];then
	mkdir ~/.config/chu
fi
if [ ! -f ~/.config/chu/chu.config ];then
	cp $DIR/chu.conf ~/.config/chu/
fi

if [ $MINGW == "YES" ];then
	cp -f $DIR/chu.auto /usr/share/bash-completion/completions/chu
else
	sudo cp -f $DIR/chu.auto /etc/bash_completion.d/
fi
