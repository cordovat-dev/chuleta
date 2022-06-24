#!/bin/bash
set -euo pipefail

DIR=$(dirname "$0")

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

sudo cp -f $DIR/chu.auto /etc/bash_completion.d/


