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
source ~/.config/chu/chu.conf
# variables read from conf file: NO_OLD_DB_WRN, MAX_CAT_LENGTH, BASE_DIR, MAX_MENU_LENGTH, MINGW, COLOUR
NO_OLD_DB_WRN=${NO_OLD_DB_WRN:-0}
MAX_CAT_LENGTH=${MAX_CAT_LENGTH:-20}
BASE_DIR=${BASE_DIR:-~/chuleta/chuleta-data}
MAX_MENU_LENGTH=${MAX_MENU_LENGTH:-12}
MINGW=${MINGW:-YES}
COLOUR=${COLOUR:-YES}
NUM_DAYS_OLD=${NUM_DAYS_OLD:-8}
# if env var NO_OLD_DB_WRN is set to 1, then age of database is ignored
if [ ${#} -eq 1 ] && [[ ${1} =~ ^[0-9]+$ ]];then
	TERMINO="--cached"
	set -- "--cached" "$1"
fi
LISTA_PALABRAS="${@:1}"
COMANDO="abrir"
RUTA_CACHE=~/.cache/chu
RUTA_LOGS=~/.cache/chu.logs
MENUCACHE=$RUTA_CACHE/menu$PPID
MENUCACHE_NC=${MENUCACHE}_nc

RUTA=`dirname $0`
TEMPORAL=`mktemp /tmp/chuleta.XXXXX`
TEMPORAL2=`mktemp /tmp/chuleta.XXXXX`
OPEN_COMMAND=$([[ $MINGW == "YES" ]] && echo start || echo gnome-open)
SUDO_COMMAND=$([[ $MINGW == "YES" ]] && echo -n "" || echo sudo)

if [ -n "`printf "%s\n" "$LISTA_PALABRAS"|fgrep -e '--edit'`" ];then	
	LISTA_PALABRAS="`echo $LISTA_PALABRAS|sed 's/--edit//g'`"
	COMANDO="editar"
fi

function abrir {
	CHULETA="$BASE_DIR/$1"
	set +u
	RNDCHU="$2"
	set -u
	LONGITUD=$(wc -l < $CHULETA)
	if [ $LONGITUD -gt $MAX_CAT_LENGTH ];then
		echo "  opening in editor or viewer..."
		$OPEN_COMMAND "$CHULETA"
	else
		echo
		cat "$CHULETA"
	fi
	if [ "$RNDCHU" != "--random" ]; then
		sqlite3 $RUTA_CACHE/frequent.db "insert into frequent_log values('$1',1);"
	fi
}

function editar {
	echo "  opening in editor ..."
	$OPEN_COMMAND $BASE_DIR/$1
}

function menu {
	echo
	TEMP=`mktemp /tmp/chuleta.XXXXX`
	COUNT=`wc -l < $1`
	cat $1 >> "$TEMP"
	colour=$(test $COLOUR = "YES" && echo "-c" || echo "")
	test -f ${MENUCACHE} && rm ${MENUCACHE}
	test -f ${MENUCACHE_NC} && rm ${MENUCACHE_NC}
	$RUTA/./fmt2.sh $colour -f ${MENUCACHE_NC} < "$TEMP" | tee ${MENUCACHE}
	
	echo 
	read -p "  ?  " respuesta
	if [[ $respuesta =~ ^-?[0-9]+$ ]];then
		OPCION=$respuesta
		if [ $OPCION -ge 1 -a $OPCION -le $COUNT ];then
			OPCION=`sed "${respuesta}q;d" "$1"`
			echo
			$RUTA/ct.sh -n $respuesta -d $OPCION $(test $COLOUR = "YES" && echo "-c" || echo "")
			$COMANDO $OPCION
		fi
	fi
}

function reporte {
	echo
	TEMP=`mktemp /tmp/chuleta.XXXXX`
	cat $1 >> "$TEMP"
	$RUTA/./fmt2.sh -r < "$TEMP"
	echo
}

function  update() {
	local autocomp=""
	set +u
	autocomp="$1"
	set -u
	echo "Backing up database"
	echo "Updating database"
	cp "$RUTA_CACHE/chuletas.db" "$RUTA_CACHE/chuletas.db.$(date +%Y%m%d%H%M%S)"
	cp "$RUTA_CACHE/frequent.db" "$RUTA_CACHE/frequent.db.$(date +%Y%m%d%H%M%S)"
	$RUTA/sqls.sh -b "$BASE_DIR" -d "$RUTA_CACHE/chuletas.db" -w $NUM_DAYS_OLD
	test -n "${MENUCACHE}" && test -f "${MENUCACHE}" && rm "${MENUCACHE}"
	test -n "${MENUCACHE_NC}" && test -f "${MENUCACHE_NC}" && rm "${MENUCACHE_NC}"
	if [ "$autocomp" != "quick" ];then
		echo "Generating autocompletion"
		$RUTA/gac.sh $BASE_DIR
	else
		sleep 1
	fi
	echo Done.
	exit 0
}

if [ "$TERMINO" = "--update" ];then
	update
elif [ "$TERMINO" = "--quick-update" ];then	
	update quick
elif [ "$TERMINO" = "--totals" ];then
	echo
	for f in $(ls $BASE_DIR);do
		if [ -d "${BASE_DIR}/$f" ];then
			echo "$f: $(find ${BASE_DIR}/${f}/ -type f -iname "chuleta_*.txt"|wc -l)"
		fi
	done |column -t|sort -k 2 -gr
	echo
	$RUTA/co.sh -w $NO_OLD_DB_WRN -c $RUTA_CACHE
	echo $(sqlite3 $RUTA_CACHE/chuletas.db "select count(*) from chuleta;") chuletas
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
	TEMP1=$(mktemp /tmp/chuleta.XXXXX)
	sqlite3 $RUTA_CACHE/frequent.db ".separator ' '" "select count, path from v_log_summary;" > "$TEMP1"
	$RUTA/tops.sh $(test $COLOUR = "YES" && echo "-c" || echo "") -f "$TEMP1"
	exit 0
elif [ "$TERMINO" = "--show_config" ];then
	echo ~/.config/chu/chu.conf
	echo
	cat ~/.config/chu/chu.conf
	exit 0
elif [ "$TERMINO" = "--random" ];then
	$RUTA/co.sh -w $NO_OLD_DB_WRN -c $RUTA_CACHE
	CHULETA=$(sqlite3 $RUTA_CACHE/chuletas.db "select path from chuleta order by random() limit 1;")
	$RUTA/ct.sh -n "!" -d $CHULETA $(test $COLOUR = "YES" && echo "-c" || echo "")
	$COMANDO $CHULETA "--random"
else
	$RUTA/co.sh -w $NO_OLD_DB_WRN -c $RUTA_CACHE
	sqlite3 $RUTA_CACHE/chuletas.db "$($RUTA/gs.sh $LISTA_PALABRAS)" > $TEMPORAL
fi

CANT_RESULTADOS=`cat $TEMPORAL | wc -l`

if [ $CANT_RESULTADOS -eq 1 ]; then
	$RUTA/ct.sh -n 1 -d $(cat $TEMPORAL) $(test $COLOUR = "YES" && echo "-c" || echo "")
	$COMANDO `cat "$TEMPORAL"`
elif [ $CANT_RESULTADOS -gt 0 -a $CANT_RESULTADOS -le $MAX_MENU_LENGTH ]; then
	menu "$TEMPORAL"
elif [ $CANT_RESULTADOS -gt $MAX_MENU_LENGTH ];then
	reporte "$TEMPORAL"
fi

set +e
find /tmp/chuleta.* -mtime +1 -delete &>/dev/null
find $RUTA_CACHE -iname "menu*" -mmin +240 -delete &>/dev/null

(nohup $RUTA/cob.sh -c $RUTA_CACHE -l $RUTA_LOGS ) 2>/dev/null &
exit 0
