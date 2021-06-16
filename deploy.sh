#!/bin/bash

#sudo cp -f sbd.1 /usr/share/man/man1/
#sudo gzip -f /usr/share/man/man1/sbd.1
if [ ! -d ~/.cache/chu ];then
	mkdir ~/.cache/chu
fi
if [ ! -d ~/.cache/chu.logs ];then
	mkdir ~/.cache/chu.logs
fi
sudo cp -f chu.auto /etc/bash_completion.d/


