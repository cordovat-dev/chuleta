#!/bin/bash

if [ ! -d ~/.cache/chu ];then
	mkdir ~/.cache/chu
fi
if [ ! -d ~/.cache/chu.logs ];then
	mkdir ~/.cache/chu.logs
fi
sudo cp -f chu.auto /etc/bash_completion.d/


