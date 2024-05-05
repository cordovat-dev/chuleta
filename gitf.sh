#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMP}" && test -f "${TEMP}" && rm "${TEMP}"
	test -n "${TEMP2}" && test -f "${TEMP2}" && rm "${TEMP2}"
	test -n "${TEMPCHANGES}" && test -f "${TEMPCHANGES}" && rm "${TEMPCHANGES}"	
	test -n "${TEMPSCRIPT}" && test -f "${TEMPSCRIPT}" && rm "${TEMPSCRIPT}"	
	test -n "${TEMPDIFFTREE}" && test -f "${TEMPDIFFTREE}" && rm "${TEMPDIFFTREE}"	
	exit $1
}

set -euo pipefail

CACHE_DIR=~/.cache/chu
CHULETADB="${CACHE_DIR}/chuletas.db"
FTSDB="${CACHE_DIR}/chuletas_fts.db"
somechange=0
TEMP="$(mktemp /tmp/chuleta.XXXXX)"
TEMP2="$(mktemp /tmp/chuleta.XXXXX)"
TEMPCHANGES="$(mktemp /tmp/chuleta.XXXXX)"
TEMPSCRIPT="$(mktemp /tmp/chuleta.XXXXX)"
TEMPDIFFTREE="$(mktemp /tmp/chuleta.XXXXX)"
SCRIPT_DIR="$(dirname $0)"
repodir=~/chuleta/chuleta-data
repopreffix=""
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
		#egrep -v "^M" "${TEMPDIFFTREE}"
		cat "${TEMPDIFFTREE}"
		set -e
	else
		echo >&2
		echo >&2 "FATAL!!!"
		echo >&2 "Repo in folder ${repodir} doesn't contain tag ${lasttag}"
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
	$1 == "M" {
		printf ("delete from chuleta where path = \x27%s\x27;\n",$2) 	
		printf ("insert or replace into chuleta (path) values (\x27%s\x27);\n",$2) 
	}
EOF
)
}

function addpreffix {
	local preffix="${1}"
	if [ $usedepobasename -eq 1 ]; then
		preffix=$(basename "${repodir}")/
	fi
	sed -e "s#('#('${preffix}#"
}

function markrepos {
	sqlite3 "${CHULETADB}" ".mode csv" ".separator ':'" "select path,use_preffix from v_git_repos;" > "${TEMP2}"
	for s in $(cat "${TEMP2}");do
		repodir=$(echo $s|awk -F: '{print $1}')
		cd "${repodir}"
		git tag "${updatetag}"
		sqlite3 "${CHULETADB}" "insert or replace into settings values ('LAST_GIT_TAG','${updatetag}');"
		# delete all tags except the current one
		"${SCRIPT_DIR}/cgt.sh" "${repodir}" "${updatetag}"
	done
}

function getrepos {
	sqlite3 "${CHULETADB}" ".mode csv" ".separator ':'" "select path,use_preffix from v_git_repos;" > "${TEMP2}"
	for s in $(cat "${TEMP2}");do
		repodir=$(echo $s|awk -F: '{print $1}')
		usedepobasename=$(echo $s|awk -F: '{printf "%d", $2}')
		repopreffix=""
		[ $usedepobasename -eq 1 ] && repopreffix=$(basename "${repodir}/")
		readrepo "$repodir" "$repopreffix"
	done
	if [ $somechange -eq 0 ];then
		echo "No changes found in any of the repos"
	fi
}

function readrepo {
	local directory="${1}"
	local preffix="${2:-}"
	if [ ! -d "${directory}" ];then
		echo "${directory} folder not found"
		exit 1
	fi
	cd "${directory}"
	if [ "$(ismaster)" -eq 1  ]; then
		echo "${masterbranch} is not the current branch in ${repodir}"
		exit 1
	fi
	if [ "$(iswtclean)" -eq 1  ]; then 
		echo >&2 "Working tree in ${repodir} is not clean"
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
	sqlite3 "${CHULETADB}" ".mode line" "select count(*) before from chuleta;" 
	echo -n "attach '" > "${TEMP}"
	echo -n ${FTSDB} >> "${TEMP}"
	echo "' as ftsdb;" >> "${TEMP}"
	cat "${SCRIPT_DIR}/chuleta_ins.trg" >> ${TEMP}	
	echo ".echo on" >> "${TEMP}"
	echo "BEGIN TRANSACTION;" >> "${TEMP}"
	cat "${TEMPSCRIPT}" >> "${TEMP}"
	echo "END TRANSACTION;" >> "${TEMP}"
	echo ".quit" >> "${TEMP}"
	mv "${TEMP}" "${TEMPSCRIPT}"
	sqlite3 ${CHULETADB} ".read "${TEMPSCRIPT}	
	markrepos
	sqlite3 "${CHULETADB}" ".mode line" "select count(*) after from chuleta;" 
fi
sqlite3 "${CHULETADB}" "insert or replace into settings(key,value) values ('LAST_UPDATED',CURRENT_TIMESTAMP);"
sqlite3 "${CHULETADB}" "insert or replace into last_opened values (1,(select path from chuleta where id = 1));"
exit 0

