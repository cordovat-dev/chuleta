#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMPORAL2}" && test -f "${TEMPORAL2}" && rm "${TEMPORAL2}"
	test -n "${TEMPORAL}" && test -f "${TEMPORAL}" && rm "${TEMPORAL}"
	test -n "${TEMP}" && test -f "${TEMP}" && rm "${TEMP}"
	test -n "${TEMP1}" && test -f "${TEMP1}" && rm "${TEMP1}"

	exit $1
}

TERMINO="$1"
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
if [ ${#} -eq 1 ] && [[ ${1} =~ ^[0-9]+$ ]];then
	TERMINO="--cached"
	set -- "--cached" "$1"
fi
LISTA_PALABRAS="${@:1}"
COMANDO="abrir"
RUTA_CACHE=~/.cache/chu
RUTA_LOGS=~/.cache/chu.logs
FREQUENTDB=$RUTA_CACHE/frequent.db
CHULETADB=$RUTA_CACHE/chuletas.db
MENUCACHE=$RUTA_CACHE/menu$PPID
MENUCACHE_NC=${MENUCACHE}_nc
REPORT_CACHE_FILE=$RUTA_CACHE/frequent_report_cache

RUTA=$(dirname $0)
TEMPORAL=$(mktemp /tmp/chuleta.XXXXX)
TEMPORAL2=$(mktemp /tmp/chuleta.XXXXX)
OPEN_COMMAND=$([[ $MINGW == "YES" ]] && echo start || echo gnome-open)
SUDO_COMMAND=$([[ $MINGW == "YES" ]] && echo -n "" || echo sudo)

if [ -n "$(printf "%s\n" "$LISTA_PALABRAS"|fgrep -e '--edit')" ];then
	LISTA_PALABRAS="$(echo $LISTA_PALABRAS|sed 's/--edit//g')"
	COMANDO="editar"
fi

source $RUTA/mf.sh

if [ "$TERMINO" = "--update" ];then
	update
elif [ "$TERMINO" = "--quick-update" ];then
	update quick
elif [ "$TERMINO" = "--totals" ];then
	echo
	sqlite3 ${CHULETADB} ".mode csv" ".separator ' '" "select main_topic, count, pc, bar from v_totals_g"|\
	awk '{printf "%s: %s %2s%s %s\n", $1, $2, $3, "%", $4}'|sed 's/[^0-9]0%/-/'|\
	sed 's/\-$//g'|column -t
	echo
	$RUTA/co.sh -w $NO_OLD_DB_WRN -c $RUTA_CACHE
	echo $(sqlite3 ${CHULETADB} "select count(*) from chuleta;") chuletas
	exit 0
elif [ "$TERMINO" = "--topics" ];then
	cd ${BASE_DIR}
	if [ $MINGW == "YES" ];then
		tree.com //a . | tail -n +3
		cd - > /dev/null
	else
		tree -d .
		cd -
	fi
	exit 0
elif [ "$TERMINO" = "--terms" ];then
	cat $RUTA_CACHE/lista_comp
	exit 0
elif [ "$TERMINO" = "--cached" ];then
	set +u
	LINENUM="$2"
	set -u
	if [ -f ${MENUCACHE_NC} ];then
		if [[ $LINENUM =~ [0-9]+ ]];then
			FILEPATH=$(grep " $2 " ${MENUCACHE_NC}|awk '{print $2}')
			if [ -n $FILEPATH ];then
				$RUTA/ct.sh -n $LINENUM -d $FILEPATH $(test $COLOUR = "YES" && echo "-c" || echo "")
				echo
				$COMANDO $FILEPATH
			fi
		else
			cat ${MENUCACHE}
		fi
	fi
elif [ "$TERMINO" = "--frequent" ];then
	if [ $(sqlite3 $RUTA_CACHE/frequent.db "select count(*) from  v_log_summary;") -eq 0 ];then
		echo "Not enough info(2)"
	else
		TEMP1=$(mktemp /tmp/chuleta.XXXXX)
		sqlite3 ${FREQUENTDB} ".separator ' '" "select count, path from v_log_summary;" > "$TEMP1"
		$RUTA/tops.sh $(test $COLOUR = "YES" && echo "-c" || echo "") -f "$TEMP1"
	fi
	exit 0
elif [ "$TERMINO" = "--show_config" ];then
	echo ~/.config/chu/chu.conf
	echo
	cat ~/.config/chu/chu.conf
	sqlite3 ${CHULETADB} "select key||'='||datetime(value,'localtime') from settings where key = 'LAST_UPDATED';"
	exit 0
elif [ "$TERMINO" = "--random" ];then
	$RUTA/co.sh -w $NO_OLD_DB_WRN -c $RUTA_CACHE
	CHULETA=$(sqlite3 ${CHULETADB} "select path from chuleta order by random() limit 1;")
	$RUTA/ct.sh -n "!" -d $CHULETA $(test $COLOUR = "YES" && echo "-c" || echo "")
	$COMANDO $CHULETA "--random"
elif [ "$TERMINO" = "--config" ];then
	config $CONFIG_FILE
elif [[ "$TERMINO" =~ -- ]]; then
		usage
else
	$RUTA/co.sh -w $NO_OLD_DB_WRN -c $RUTA_CACHE
	sqlite3 ${CHULETADB} "$($RUTA/gs.sh $LISTA_PALABRAS)" > $TEMPORAL
fi

CANT_RESULTADOS=$(cat $TEMPORAL | wc -l)

if [ $CANT_RESULTADOS -eq 1 ]; then
	$RUTA/ct.sh -n 1 -d $(cat $TEMPORAL) $(test $COLOUR = "YES" && echo "-c" || echo "")
	$COMANDO $(cat "$TEMPORAL")
elif [ $CANT_RESULTADOS -gt 0 -a $CANT_RESULTADOS -le $MAX_MENU_LENGTH ]; then
	menu "$TEMPORAL"
elif [ $CANT_RESULTADOS -gt $MAX_MENU_LENGTH ];then
	reporte "$TEMPORAL"
fi

set +e
find /tmp/chuleta.* -mtime +1 -delete &>/dev/null
find $RUTA_CACHE -iname "menu*" -mmin +240 -delete &>/dev/null

(nohup $RUTA/cob.sh -c $RUTA_CACHE -l $RUTA_LOGS > $(mktemp /tmp/chuleta.nohup.XXXXX)) 2>/dev/null &
exit 0
