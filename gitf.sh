#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMP}" && test -f "${TEMP}" && rm "${TEMP}"
	test -n "${TEMP2}" && test -f "${TEMP2}" && rm "${TEMP2}"
	test -n "${TEMPCHANGES}" && test -f "${TEMPCHANGES}" && rm "${TEMPCHANGES}"	
	test -n "${TEMPSCRIPT}" && test -f "${TEMPSCRIPT}" && rm "${TEMPSCRIPT}"	
	test -n "${TEMPDIFFTREE}" && test -f "${TEMPDIFFTREE}" && rm "${TEMPDIFFTREE}"	
	echo $1
	exit $1
}

set -euo pipefail

CACHE_DIR=~/.cache/chu
CHULETADB="${CACHE_DIR}/chuletas.db"
somechange=0
TEMP="$(mktemp /tmp/chuleta.XXXXX)"
TEMP2="$(mktemp /tmp/chuleta.XXXXX)"
TEMPCHANGES="$(mktemp /tmp/chuleta.XXXXX)"
TEMPSCRIPT="$(mktemp /tmp/chuleta.XXXXX)"
TEMPDIFFTREE="$(mktemp /tmp/chuleta.XXXXX)"
depodir=~/chuleta/chuleta-data
depopreffix=""
usedepobasename=0
masterbranch="master"
lasttag=$(sqlite3 "${CHULETADB}" "select value from settings where key = 'LAST_GIT_TAG';")
updatetag="chu_update_$(date +%Y%m%d%H%M%S)"

function ismaster {
	if [ "$(git symbolic-ref HEAD)" = "refs/heads/${masterbranch}" ]; then 
		echo 0
	else
		echo 1
	fi
}

function listchanges {
	local result=1
	set +e
	git diff-tree --name-status -r ${lasttag}..HEAD 2>/dev/null > "${TEMPDIFFTREE}"
	result=$?
	set -e
	if [ $result -eq 0 ];then
		set +e
		egrep -v "^M" "${TEMPDIFFTREE}"
		set -e
	else
		echo >&2
		echo >&2 "FATAL!!!"
		echo >&2 "Repo in folder ${depodir} doesn't contain tag ${lasttag}"
		echo >&2
		echo >&2 "Possible solutions:"
		echo >&2 "Solution 1: tag one commit repo with ${lasttag}"
		echo >&2 "Solution 2: set GIT_INTEGRATION to NO to make a full update"
		echo >&2 "Solution 3: set LAST_GIT_TAG to null in DB settings table to make a full update"
		exit 1
	fi
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
	$1 == "A" {
		printf ("delete from chuleta where path = \x27%s\x27;\n",$2) 	
		printf ("insert or replace into chuleta (path) values (\x27%s\x27);\n",$2) 
	}
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

function markrepos {
	sqlite3 "${CHULETADB}" ".mode csv" ".separator ':'" "select path,use_preffix from v_git_repos;" > "${TEMP2}"
	for s in $(cat "${TEMP2}");do
		depodir=$(echo $s|awk -F: '{print $1}')
		cd "${depodir}"
		git tag "${updatetag}"
		[[ "${lasttag}" =~ ^chu_update_[0-9]{14} ]] && git tag -d "${lasttag}"
		sqlite3 "${CHULETADB}" "insert or replace into settings values ('LAST_GIT_TAG','${updatetag}');"
	done
}

function getrepos {
	sqlite3 "${CHULETADB}" ".mode csv" ".separator ':'" "select path,use_preffix from v_git_repos;" > "${TEMP2}"
	for s in $(cat "${TEMP2}");do
		depodir=$(echo $s|awk -F: '{print $1}')
		usedepobasename=$(echo $s|awk -F: '{print $2}')
		depopreffix=""
		[ $usedepobasename -eq 1 ] && depopreffix=$(basename "${depodir}/")
		readrepo "$depodir" "$depopreffix"
	done
	if [ $somechange -eq 0 ];then
		echo "No changes found"
	fi
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
	listchanges > "${TEMPCHANGES}"
	if [ $(cat "${TEMPCHANGES}"|wc -l) -eq 0 ];then
		echo "No changes found in ${directory}"
	else
		cat "${TEMPCHANGES}"|filterDML|addpreffix "${preffix}" > "${TEMPSCRIPT}"
		somechange=1
	fi
}

getrepos
if [ $somechange -eq 1 ];then
	echo "BEGIN TRANSACTION;"
	cat "${TEMPSCRIPT}"
	echo "END TRANSACTION;"	
	markrepos
fi
exit 0
readrepos 
exit 0
