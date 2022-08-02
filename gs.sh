#!/bin/bash

set -euo pipefail
COUNT=0
echo -n "select path from chuleta"
for ARG in $*; do
	COUNT=$(( $COUNT + 1 ))
	if [ $COUNT -eq 1 ];then
		echo -n " where "
	fi
	echo -n "path like '%$ARG%'"
	if [ $COUNT -lt $# ]; then
		echo -n " and "
	fi
done
