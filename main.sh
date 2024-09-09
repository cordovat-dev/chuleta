#!/bin/bash

trap exit_handler_main EXIT

function exit_handler_main {
	set +u
	test -n "${TEMPDIR}" && test -d "${TEMPDIR}" && rm -rf "${TEMPDIR}"
	test -n "${TEMPORARY2}" && test -f "${TEMPORARY2}" && rm "${TEMPORARY2}"
	test -n "${TEMPORARY}" && test -f "${TEMPORARY}" && rm "${TEMPORARY}"
	test -n "${TEMP}" && test -f "${TEMP}" && rm "${TEMP}"
	test -n "${TEMP1}" && test -f "${TEMP1}" && rm "${TEMP1}"
	test -n "${TEMP2}" && test -f "${TEMP2}" && rm "${TEMP2}"

	exit $1
}

set -euo pipefail

set +e
parmtemp=$(getopt -o crChsequ --long update,stats,topics,terms,frequent,show-config,random,quick-update,config,help,edit,clipboard,cached,clear-git-tags -- "$@" 2> /dev/null )

if [ $? -eq 0 ];then
	eval set -- $parmtemp
else
	echo
	echo "	Unknown option!"
	echo
	set -- "--help" "--"
fi
set -e

COMMAND="abrir"
COPYTOCLIP=0
flag=""
WORD_LIST=""

while true; do
    case "$1" in
    -c|--clipboard)
		COPYTOCLIP=1
        ;;
    --frequent|--terms|--topics|--cached|--stats)
		flag="$1"
        ;;
    -r|--random)
		flag="--random"
        ;;
    -C|--config)
		flag="--config"
        ;;
    -h|--help)
		flag="--help"
        ;;
    -s|--show-config)
		flag="--show-config"
        ;;
    -e|--edit)
		COMMAND="editar"
        ;;
    -q|--quick-update)
		flag="--quick-update"
        ;;
    -u|--update)
		flag="--update"
        ;;
    --clear-git-tags)
		flag="--clear-git-tags"
		;;
    --)
        shift
        break
        ;;
    esac
    shift
done

WORD_LIST="$@"

CONFIG_FILE=~/.config/chu/chu.conf
source ${CONFIG_FILE}
# variables read from conf file: NO_OLD_DB_WRN, BASE_DIR, MAX_MENU_LENGTH, MINGW, COLOUR
NO_OLD_DB_WRN=${NO_OLD_DB_WRN:-0}
BASE_DIR=${BASE_DIR:-~/chuleta/chuleta-data}
MAX_MENU_LENGTH=${MAX_MENU_LENGTH:-12}
MINGW=${MINGW:-YES}
COLOUR=${COLOUR:-YES}
NUM_DAYS_OLD=${NUM_DAYS_OLD:-8}
PREFER_LESS=${PREFER_LESS:-YES}
GIT_INTEGRATION=${GIT_INTEGRATION:-NO}
# if env var NO_OLD_DB_WRN is set to 1, then age of database is ignored
CACHE_DIR=~/.cache/chu
FREQUENTDB="${CACHE_DIR}/frequent.db"
CHULETADB="${CACHE_DIR}/chuletas.db"
FTSDB="${CACHE_DIR}/chuletas_fts.db"
MENUCACHE="${CACHE_DIR}/menu${PPID}"
MENUCACHE_NC="${MENUCACHE}_nc"

SCRIPT_DIR="$(dirname $0)"
TEMPORARY="$(mktemp /tmp/chuleta.XXXXX)"
TEMPORARY2="$(mktemp /tmp/chuleta.XXXXX)"
TEMPDIR="$(mktemp -d /tmp/chuleta.XXXXX)"
TEMP2="$(mktemp /tmp/chuleta.XXXXX)"
OPEN_COMMAND=$([[ "${MINGW}" = "YES" ]] && echo start || echo xdg-open)
SUDO_COMMAND=$([[ "${MINGW}" = "YES" ]] && echo -n "" || echo sudo)
declare -r NULLGITTAG="chu_update_99999999999999"

if [ ${#} -eq 1 ] && [[ ${1} =~ ^[0-9]+$ ]];then
	flag="--cached"
	set -- "--cached" "$1"
fi

source "${SCRIPT_DIR}"/mf.sh

if [ "${flag}" = "--update" ];then
	update
elif [ "${flag}" = "--quick-update" ];then
	update quick
elif [ "${flag}" = "--stats" ];then
	echo
	sqlite3 "${CHULETADB}" ".mode csv" ".separator ' '" "select main_topic, count, pc, bar from v_totals_g"|\
	awk '{printf "%s: %s %2s%s %s\n", $1, $2, $3, "%", $4}'|sed 's/[^0-9]0%/-/'|\
	sed 's/\-$//g'|column -R 2,3 -t
	echo
	"${SCRIPT_DIR}"/co.sh -w ${NO_OLD_DB_WRN} -c "${CACHE_DIR}"
	echo $(sqlite3 "${CHULETADB}" "select count(*) from chuleta;") chuletas
	exit 0
elif [ "${flag}" = "--topics" ];then
	cd "${BASE_DIR}"
	if [ "${MINGW}" = "YES" ];then
		tree.com //a . | tail -n +3
		cd - > /dev/null
	else
		tree -d .
		cd -
	fi
	exit 0
elif [ "${flag}" = "--terms" ];then
	cat "${CACHE_DIR}"/lista_comp
	exit 0
elif [ "${flag}" = "--cached" ];then
	set +u
	LINENUM="$2"
	set -u
	if [ -f "${MENUCACHE_NC}" ];then
		if [[ ${LINENUM} =~ [0-9]+ ]];then
			FILEDIR=$(grep " $2 " "${MENUCACHE_NC}"|awk '{print $2}')
			if [ -n ${FILEDIR} ];then
				"${SCRIPT_DIR}"/ct.sh -n ${LINENUM} -d "${FILEDIR}" $(test ${COLOUR} = "YES" && echo "-c" || echo "")
				echo
				${COMMAND} "${FILEDIR}"
			fi
		else
			cat "${MENUCACHE}"
		fi
	fi
elif [ "${flag}" = "--frequent" ];then
	if [ $(sqlite3 "${CACHE_DIR}"/frequent.db "select count(*) from  v_log_summary;") -eq 0 ];then
		echo "Not enough info(2)"
	else
		TEMP1="$(mktemp /tmp/chuleta.XXXXX)"
		sqlite3 "${FREQUENTDB}" ".separator ' '" "select count, path from v_log_summary;" > "${TEMP1}"
		"${SCRIPT_DIR}"/tops.sh $(test ${COLOUR} = "YES" && echo "-c" || echo "") -f "${TEMP1}"
	fi
	exit 0
elif [ "${flag}" = "--show-config" ];then
	echo "-- Config file [ ${CONFIG_FILE} ] --"
	cat "${CONFIG_FILE}"|sort 
	echo
	echo "-- Database [ ${CHULETADB} ] --"
	sqlite3 "${CHULETADB}" "select * from v_settings_report;"
	exit 0
elif [ "${flag}" = "--random" ];then
	"${SCRIPT_DIR}"/co.sh -w ${NO_OLD_DB_WRN} -c ${CACHE_DIR}
	CHULETA=$(sqlite3 "${CHULETADB}" "select path from chuleta order by random() limit 1;")
	"${SCRIPT_DIR}"/ct.sh -n "!" -d "${CHULETA}" $(test ${COLOUR} = "YES" && echo "-c" || echo "")
	${COMMAND} "${CHULETA}" "--random"
elif [ "${flag}" = "--config" ];then
	config "${CONFIG_FILE}"
elif [[ "${flag}" = "--clear-git-tags" ]];then
	clear-git-tags
elif [ "${flag}" = "--help" ];then
	usage
elif [[ "${flag}" =~ -- ]]; then
	usage
else
	"${SCRIPT_DIR}"/co.sh -w ${NO_OLD_DB_WRN} -c "${CACHE_DIR}"
	sqlite3 ${CHULETADB} "$(${SCRIPT_DIR}/gs.sh ${WORD_LIST})" > ${TEMPORARY}
fi

RESULT_COUNT=$(cat "${TEMPORARY}" | wc -l)

if [ ${RESULT_COUNT} -eq 1 ]; then
	"${SCRIPT_DIR}"/ct.sh -n 1 -d $(cat "${TEMPORARY}") $(test ${COLOUR} = "YES" && echo "-c" || echo "")
	${COMMAND} $(cat "${TEMPORARY}")
elif [ ${RESULT_COUNT} -gt 0 -a ${RESULT_COUNT} -le ${MAX_MENU_LENGTH} ]; then
	menu "${TEMPORARY}"
elif [ ${RESULT_COUNT} -gt ${MAX_MENU_LENGTH} ];then
	reporte "${TEMPORARY}"
fi

set +e
find /tmp/chuleta.* -mtime +1 -delete &>/dev/null
find "${CACHE_DIR}" -iname "menu*" -mmin +240 -delete &>/dev/null

(nohup "${SCRIPT_DIR}"/cob.sh -c "${CACHE_DIR}" > $(mktemp /tmp/chuleta.nohup.XXXXX)) 2>/dev/null &
exit 0
