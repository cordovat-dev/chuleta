#!/bin/bash -x

set -euo pipefail

#if [ $# -eq 0 ]; then
#	echo -n "select path from last_opened where id = 1 and path is not null;"
#	exit 0
#fi

COUNT=0
echo -n "attach '/home/cordovat/.cache/chu/chuletas_fts.db' as ftsdb;"
echo -n "select path from chuleta_fts where chuleta_fts match '"
for ARG in $*; do
	COUNT=$(( ${COUNT} + 1 ))
	echo -n "${ARG}"
	if [ ${COUNT} -lt $# ]; then
		echo -n " "
	fi
done
echo -n "'"
echo -n " order by id;"
