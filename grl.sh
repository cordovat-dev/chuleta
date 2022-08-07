#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMP}" && test -f "${TEMP}" && rm "${TEMP}"
	exit $1
}

set -euo pipefail
LISTA_PALABRAS=( $@ )
TEMP=$(mktemp /tmp/chuleta.XXXXX)

while read linea
do
	found=1
	for term in "${LISTA_PALABRAS[@]}"
	do
		if [[ $linea =~ $term ]];then
			dummy=1
		else
			found=0
			break
		fi
	done
	if [ $found -eq 1 ];then
		echo $linea
	fi
done
