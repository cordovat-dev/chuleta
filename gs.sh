#!/bin/bash

set -euo pipefail

if [ $# -eq 0 ]; then
	echo -n "select path from last_opened where id = 1 and path is not null;"
	exit 0
fi

COUNT=0
echo -n "select path from chuleta"
for ARG in $*; do
	COUNT=$(( ${COUNT} + 1 ))
	if [ ${COUNT} -eq 1 ];then
		echo -n " where "
	fi
	echo -n "path like '%${ARG}%'"
	if [ ${COUNT} -lt $# ]; then
		echo -n " and "
	fi
done
echo -n " order by id;"
