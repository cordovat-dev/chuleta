#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMPORARY2}" && test -f "${TEMPORARY2}" && rm "${TEMPORARY2}"
	test -n "${TEMPORARY}" && test -f "${TEMPORARY}" && rm "${TEMPORARY}"
	test -n "${TEMP}" && test -f "${TEMP}" && rm "${TEMP}"
	test -n "${TEMP1}" && test -f "${TEMP1}" && rm "${TEMP1}"

	exit $1
}

flag="$1"
set -euo pipefail
CONFIG_FILE=~/.config/chu/chu.conf
source $CONFIG_FILE
# variables read from conf file: NO_OLD_DB_WRN, MAX_CAT_LENGTH, BASE_DIR, MAX_MENU_LENGTH, MINGW, COLOUR
NO_OLD_DB_WRN=${NO_OLD_DB_WRN:-0}
MAX_CAT_LENGTH=${MAX_CAT_LENGTH:-20}
BASE_DIR=${BASE_DIR:-~/chuleta/chuleta-data}
MAX_MENU_LENGTH=${MAX_MENU_LENGTH:-12}
MINGW=${MINGW:-YES}
COLOUR=${COLOUR:-YES}
NUM_DAYS_OLD=${NUM_DAYS_OLD:-8}
PREFER_LESS=${PREFER_LESS:-YES}
# if env var NO_OLD_DB_WRN is set to 1, then age of database is ignored
WORD_LIST="${@:1}"
COMMAND="abrir"
COPYTOCLIP=0
CACHE_DIR=~/.cache/chu
LOGS_DIR=~/.cache/chu.logs
FREQUENTDB="$CACHE_DIR/frequent.db"
CHULETADB="$CACHE_DIR/chuletas.db"
MENUCACHE="$CACHE_DIR/menu$PPID"
MENUCACHE_NC="${MENUCACHE}_nc"
REPORT_CACHE_FILE="$CACHE_DIR/frequent_report_cache"

SCRIPT_DIR="$(dirname $0)"
TEMPORARY="$(mktemp /tmp/chuleta.XXXXX)"
TEMPORARY2="$(mktemp /tmp/chuleta.XXXXX)"
OPEN_COMMAND=$([[ $MINGW == "YES" ]] && echo start || echo gnome-open)
SUDO_COMMAND=$([[ $MINGW == "YES" ]] && echo -n "" || echo sudo)

if [ -n "$(printf "%s\n" "$WORD_LIST"|fgrep -e '--edit')" ];then
	WORD_LIST="$(echo $WORD_LIST|sed 's/--edit//g')"
	set -- $WORD_LIST
	COMMAND="editar"
fi

if [ -n "$(printf "%s\n" "$WORD_LIST"|fgrep -e '--clipboard')" ];then
	WORD_LIST="$(echo $WORD_LIST|sed 's/--clipboard//g')"
	set -- $WORD_LIST
	COPYTOCLIP=1
fi

if [ ${#} -eq 1 ] && [[ ${1} =~ ^[0-9]+$ ]];then
	flag="--cached"
	set -- "--cached" "$1"
fi

source "$SCRIPT_DIR"/mf.sh

if [ "$flag" = "--update" ];then
	update
elif [ "$flag" = "--quick-update" ];then
	update quick
elif [ "$flag" = "--totals" ];then
	echo
	sqlite3 "${CHULETADB}" ".mode csv" ".separator ' '" "select main_topic, count, pc, bar from v_totals_g"|\
	awk '{printf "%s: %s %2s%s %s\n", $1, $2, $3, "%", $4}'|sed 's/[^0-9]0%/-/'|\
	sed 's/\-$//g'|column -t
	echo
	"$SCRIPT_DIR"/co.sh -w $NO_OLD_DB_WRN -c "$CACHE_DIR"
	echo $(sqlite3 "${CHULETADB}" "select count(*) from chuleta;") chuletas
	exit 0
elif [ "$flag" = "--topics" ];then
	cd "${BASE_DIR}"
	if [ $MINGW == "YES" ];then
		tree.com //a . | tail -n +3
		cd - > /dev/null
	else
		tree -d .
		cd -
	fi
	exit 0
elif [ "$flag" = "--terms" ];then
	cat "$CACHE_DIR"/lista_comp
	exit 0
elif [ "$flag" = "--cached" ];then
	set +u
	LINENUM="$2"
	set -u
	if [ -f "${MENUCACHE_NC}" ];then
		if [[ $LINENUM =~ [0-9]+ ]];then
			FILEDIR=$(grep " $2 " "${MENUCACHE_NC}"|awk '{print $2}')
			if [ -n $FILEDIR ];then
				"$SCRIPT_DIR"/ct.sh -n $LINENUM -d "$FILEDIR" $(test $COLOUR = "YES" && echo "-c" || echo "")
				echo
				$COMMAND "$FILEDIR"
			fi
		else
			cat "${MENUCACHE}"
		fi
	fi
elif [ "$flag" = "--frequent" ];then
	if [ $(sqlite3 "$CACHE_DIR"/frequent.db "select count(*) from  v_log_summary;") -eq 0 ];then
		echo "Not enough info(2)"
	else
		TEMP1="$(mktemp /tmp/chuleta.XXXXX)"
		sqlite3 "${FREQUENTDB}" ".separator ' '" "select count, path from v_log_summary;" > "$TEMP1"
		"$SCRIPT_DIR"/tops.sh $(test $COLOUR = "YES" && echo "-c" || echo "") -f "$TEMP1"
	fi
	exit 0
elif [ "$flag" = "--show-config" ];then
	echo "$CONFIG_FILE"
	echo
	cat "$CONFIG_FILE"
	sqlite3 "${CHULETADB}" "select key||'='||datetime(value,'localtime') from settings where key in ('LAST_UPDATED','LAST_UPDATED_AC');"
	exit 0
elif [ "$flag" = "--random" ];then
	"$SCRIPT_DIR"/co.sh -w $NO_OLD_DB_WRN -c $CACHE_DIR
	CHULETA=$(sqlite3 "${CHULETADB}" "select path from chuleta order by random() limit 1;")
	"$SCRIPT_DIR"/ct.sh -n "!" -d "$CHULETA" $(test $COLOUR = "YES" && echo "-c" || echo "")
	$COMMAND "$CHULETA" "--random"
elif [ "$flag" = "--config" ];then
	config "$CONFIG_FILE"
elif [ "$flag" = "--help" ];then
	usage
elif [[ "$flag" =~ -- ]]; then
	usage
else
	"$SCRIPT_DIR"/co.sh -w $NO_OLD_DB_WRN -c "$CACHE_DIR"
	sqlite3 ${CHULETADB} "$($SCRIPT_DIR/gs.sh $WORD_LIST)" > $TEMPORARY
fi

RESULT_COUNT=$(cat "$TEMPORARY" | wc -l)

if [ $RESULT_COUNT -eq 1 ]; then
	"$SCRIPT_DIR"/ct.sh -n 1 -d $(cat "$TEMPORARY") $(test $COLOUR = "YES" && echo "-c" || echo "")
	$COMMAND $(cat "$TEMPORARY")
elif [ $RESULT_COUNT -gt 0 -a $RESULT_COUNT -le $MAX_MENU_LENGTH ]; then
	menu "$TEMPORARY"
elif [ $RESULT_COUNT -gt $MAX_MENU_LENGTH ];then
	reporte "$TEMPORARY"
fi

set +e
find /tmp/chuleta.* -mtime +1 -delete &>/dev/null
find "$CACHE_DIR" -iname "menu*" -mmin +240 -delete &>/dev/null

(nohup "$SCRIPT_DIR"/cob.sh -c "$CACHE_DIR" -l "$LOGS_DIR" > $(mktemp /tmp/chuleta.nohup.XXXXX)) 2>/dev/null &
exit 0
