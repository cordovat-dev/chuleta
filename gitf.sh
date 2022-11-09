#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMP}" && test -f "${TEMP}" && rm "${TEMP}"	
	exit $1
}

set -euo pipefail

TEMP="$(mktemp /tmp/chuleta.XXXXX)"
depodir=~/chuleta/chuleta-data
usedepobasename=0
masterbranch="master"
lastpoint="HEAD~1"

function ismaster {
	if [ "$(git symbolic-ref HEAD)" = "refs/heads/${masterbranch}" ]; then 
		echo 0
	else
		echo 1
	fi
}

function listchanges {
	git diff-tree --name-status -r ${lastpoint}..HEAD|egrep -v "^M"
}

function iswtclean {
	if [ $(git status -s|wc -l)  -eq 0 ]; then
		echo 0
	else
		echo 1
	fi
}

function filterDML {
awk -f <(cat - <<-"EOF"
	$1 == "A" {printf ("insert into chuleta (path) values (\x27%s\x27);\n",$2) }
	$1 == "D" {printf ("delete from chuleta where path = \x27%s\x27;\n",$2) }
EOF
)
}

function addpreffix {
	preffix=""
	if [ $usedepobasename -eq 1 ]; then
		preffix=$(basename "${depodir}")/
	fi
	sed -e "s#('#('${preffix}#"
}

function readrepos {
	sqlite3 ~/.cache/chu/chuletas.db "select value from settings where key like 'GIT_REPO%' order by key;" > "${TEMP}"
	echo "BEGIN TRANSACTION;"
	for s in $(cat "${TEMP}");do
		depodir=$s
		usedepobasename=1
		cd "${depodir}"
		if [ "$(ismaster)" -eq 1  ]; then
			echo "${masterbranch} is not the current branch in ${depodir}"
			exit 1
		fi
		if [ "$(iswtclean)" -eq 1  ]; then 
			echo "Working tree in ${depodir} is not clean"
			exit 1
		fi
		listchanges|filterDML|addpreffix
	done
	echo "END TRANSACTION;"
}

readrepos 
exit 0
