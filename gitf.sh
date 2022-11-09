#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMP}" && test -f "${TEMP}" && rm "${TEMP}"	
	exit $1
}

set -euo pipefail

TEMP="$(mktemp /tmp/chuleta.XXXXX)"
TEMP2="$(mktemp /tmp/chuleta.XXXXX)"
depodir=~/chuleta/chuleta-data
depopreffix=""
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
	$1 == "A" {printf ("insert or replace into chuleta (path) values (\x27%s\x27);\n",$2) }
	$1 == "D" {printf ("delete from chuleta where path = \x27%s\x27;\n",$2) }
EOF
)
}

function addpreffix {
	local preffix="${1}"
	if [ $usedepobasename -eq 1 ]; then
		preffix=$(basename "${depodir}")/
	fi
	sed -e "s#('#('${preffix}#"
}

function getrepos {
	sqlite3 ~/.cache/chu/chuletas.db ".mode csv" ".separator ':'" "select path,use_preffix from v_git_repos;" > "$TEMP2"
	echo "BEGIN TRANSACTION;"
	for s in $(cat "${TEMP2}");do
		depodir=$(echo $s|awk -F: '{print $1}')
		usedepobasename=$(echo $s|awk -F: '{print $2}')
		depopreffix=""
		[ $usedepobasename -eq 1 ] && depopreffix=$(basename "${depodir}/")
		readrepo "$depodir" "$depopreffix"
	done
	echo "END TRANSACTION;"
}

function readrepo {
	local directory="${1}"
	local preffix="${2:-}"
	cd "${directory}"
	if [ "$(ismaster)" -eq 1  ]; then
		echo "${masterbranch} is not the current branch in ${depodir}"
		exit 1
	fi
	if [ "$(iswtclean)" -eq 1  ]; then 
		echo "Working tree in ${depodir} is not clean"
		exit 1
	fi
	listchanges|filterDML|addpreffix "${preffix}"
}

getrepos
exit 0
readrepos 
exit 0
