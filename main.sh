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
# variables read from conf file: NO_OLD_DB_WRN, MAX_CAT_LENGTH, BASE_DIR, MAX_MENU_LENGTH, MINGW
MAX_DB_AGE=""
# if env var NO_OLD_DB_WRN is set to 1, then age of locate database is ignored
test $NO_OLD_DB_WRN -eq 1 && MAX_DB_AGE="--max-database-age -1"
if [ ${#} -eq 1 ] && [[ ${1} =~ ^[0-9]+$ ]];then
	TERMINO="--cached"
	set -- "--cached" "$1"
fi
LISTA_PALABRAS="${@:1}"
COMANDO="abrir"
RUTA_CACHE=~/.cache/chu
RUTA_LOGS=~/.cache/chu.logs
MENUCACHE=$RUTA_CACHE/menu$PPID

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
		echo "$CHULETA" |sed -r "s|$BASE_DIR/||g">> ${RUTA_LOGS}/frecuentes
	fi
}

function editar {
	$OPEN_COMMAND $BASE_DIR/$1
}

function menu {
	echo
	TEMP=`mktemp /tmp/chuleta.XXXXX`
	COUNT=`wc -l < $1`
	echo "Chuletas" > "$TEMP"
	cat $1 >> "$TEMP"
	$RUTA/./fmt.sh < "$TEMP" | tee $MENUCACHE
	echo 
	read -p "  ?  " respuesta
	if [[ $respuesta =~ ^-?[0-9]+$ ]];then
		OPCION=$respuesta
		if [ $OPCION -ge 1 -a $OPCION -le $COUNT ];then
			OPCION=`sed "${respuesta}q;d" "$1"`
			echo
			echo $OPCION
			$COMANDO $OPCION
		fi
	fi
}

function reporte {
	echo
	TEMP=`mktemp /tmp/chuleta.XXXXX`
	echo "Chuletas" > "$TEMP"
	cat $1 >> "$TEMP"
	$RUTA/./fmt.sh -n < "$TEMP"	
	echo
}

function  update() {
	local autocomp=""
	set +u
	autocomp="$1"
	set -u
	echo "Backing up database"
	echo "Updating database"
	cp "$RUTA_CACHE/db" "$RUTA_CACHE/db.$(date +%Y%m%d%H%M%S)"
	echo "$SUDO_COMMAND updatedb --localpaths=\"$BASE_DIR\" "
	echo " --output=$RUTA_CACHE/db "
	echo " --prunepaths=\"$BASE_DIR/.git\""
	$SUDO_COMMAND updatedb --localpaths="$BASE_DIR" --output="$RUTA_CACHE/db" --prunepaths="$BASE_DIR/.git"
	locate $MAX_DB_AGE -A -d $RUTA_CACHE/db -wr "chuleta_.*\.txt$" | sed -r "s|$BASE_DIR/||g" > "$RUTA_CACHE/db.txt"
	test -n "${MENUCACHE}" && test -f "${MENUCACHE}" && rm "${MENUCACHE}"
	if [ "$autocomp" != "quick" ];then
		echo "Generating autocompletion"
		$RUTA/gac.sh $BASE_DIR
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
	echo $(locate $MAX_DB_AGE -A -d $RUTA_CACHE/db -icr "chuleta_.*\.txt$") chuletas
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
	if [ -f $MENUCACHE ];then
		if [[ $LINENUM =~ [0-9]+ ]];then
			FILEPATH=$(grep "$2" $MENUCACHE|awk '{print $2}')
			if [ -n $FILEPATH ];then
				echo $FILEPATH
				echo
				$COMANDO $FILEPATH
			fi
		else
			cat $MENUCACHE
		fi
	fi
elif [ "$TERMINO" = "--frequent" ];then
	TEMP1=$(mktemp /tmp/chuleta.XXXXX)
	cat "$RUTA_LOGS/frecuentes" | sed -r "s#${BASE_DIR}/##g" > $TEMP1
	echo Done.
	$RUTA/tops.sh "$TEMP1"
	exit 0
elif [ "$TERMINO" = "--show_config" ];then
	echo ~/.config/chu/chu.conf
	echo
	cat ~/.config/chu/chu.conf
	exit 0
elif [ "$TERMINO" = "--random" ];then
	CHULETA=$(locate $MAX_DB_AGE -A -d $RUTA_CACHE/db -wr "chuleta_.*\.txt$" | sed -r "s|$BASE_DIR/||g"|shuf| head -1)
	echo $CHULETA
	$COMANDO $CHULETA "--random"
else
	set +e
	test $NO_OLD_DB_WRN -eq 1 || locate $MAX_DB_AGE -A -d $RUTA_CACHE/db $RANDOM$RANDOM$RANDOM$RANDOM
	set -e
	cat $RUTA_CACHE/db.txt|$RUTA/grl.sh $LISTA_PALABRAS  > $TEMPORAL
fi

CANT_RESULTADOS=`cat $TEMPORAL | wc -l`

if [ $CANT_RESULTADOS -eq 1 ]; then
	cat "$TEMPORAL"
	$COMANDO `cat "$TEMPORAL"`
elif [ $CANT_RESULTADOS -gt 0 -a $CANT_RESULTADOS -le $MAX_MENU_LENGTH ]; then
	menu "$TEMPORAL"
elif [ $CANT_RESULTADOS -gt $MAX_MENU_LENGTH ];then
	reporte "$TEMPORAL"
fi

set +e
find /tmp/chuleta.* -mtime +1 -delete &>/dev/null
find $RUTA_CACHE -iname "menu*" -mmin +240 -delete &>/dev/null
exit 0
