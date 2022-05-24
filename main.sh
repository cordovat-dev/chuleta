#!/bin/bash

MAX_DB_AGE=""
# if env var CHU_NO_OLD_DB_WRN is set (no matter the value), then age of locate database is ignored
test -z ${CHU_NO_OLD_DB_WRN+x} || MAX_DB_AGE="--max-database-age -1"

LARGO_PERMITIDO="$1"
DIRBASE="$2"
TERMINO="$3"
set -euo pipefail
LISTA_PALABRAS="${@:3}"
COMANDO="abrir"
RUTA_CACHE=~/.cache/chu
RUTA_LOGS=~/.cache/chu.logs

RUTA=`dirname $0`
TEMPORAL=`mktemp /tmp/chuleta.XXXXX`
TEMPORAL2=`mktemp /tmp/chuleta.XXXXX`

if [ -n "`printf "%s\n" "$LISTA_PALABRAS"|fgrep -e '--edit'`" ];then	
	LISTA_PALABRAS="`echo $LISTA_PALABRAS|sed 's/--edit//g'`"
	COMANDO="editar"
fi

function abrir {
	CHULETA="$DIRBASE/$1"
	LONGITUD=`wc -l < "$CHULETA"`
	if [ $LONGITUD -gt $LARGO_PERMITIDO ];then
		start "$CHULETA"
	else
		echo
		cat "$CHULETA"
	fi	
	echo "$CHULETA" |sed -r "s|$DIRBASE/||g">> ${RUTA_LOGS}/frecuentes
}

function editar {
	start $DIRBASE/$1
}

function menu {
	echo
	TEMP=`mktemp /tmp/chuleta.XXXXX`
	COUNT=`wc -l < $1`
	echo "Chuletas" > "$TEMP"
	cat $1 >> "$TEMP"
	$RUTA/./fmt.sh < "$TEMP"
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
	rm $TEMP
}

function reporte {
	echo
	TEMP=`mktemp /tmp/chuleta.XXXXX`
	echo "Chuletas" > "$TEMP"
	cat $1 >> "$TEMP"
	$RUTA/./fmt.sh -n < "$TEMP"	
	echo
	rm $TEMP
}

function salir {
	rm ${TEMPORAL2} ${TEMPORAL}
	exit $1
}

if [ "$TERMINO" = "--recent" ];then
	find "$DIRBASE" -type f -iname "chuleta*.txt" -mtime -30 > $TEMPORAL
	for s in $(cat $TEMPORAL);do
		echo "$(date '+%y-%m-%d_%H:%M' -r $s)" $(echo $s|sed -r "s|$DIRBASE/||g" ) >> ${TEMPORAL2}
	done
	sort -r -k 1 ${TEMPORAL2} > ${TEMPORAL}
elif [ "$TERMINO" = "--update" ];then
	echo "Updating database"
	echo "updatedb --localpaths=\"$DIRBASE\" --output=$RUTA_CACHE/db --prunepaths=\"$DIRBASE/.git\""
	updatedb --localpaths="$DIRBASE" --output="$RUTA_CACHE/db" --prunepaths="$DIRBASE/.git"
	echo "Generating autocompletion"
	$RUTA/gac.sh $DIRBASE
	salir 0
elif [ "$TERMINO" = "--totals" ];then
	echo
	for f in $(ls $DIRBASE);do
		if [ -d "${DIRBASE}/$f" ];then
			echo "$f: $(find ${DIRBASE}/${f}/ -type f -iname "chuleta_*.txt"|wc -l)"
		fi
	done |column -t|sort -k 2 -gr
	echo
	echo $(locate $MAX_DB_AGE -A -d $RUTA_CACHE/db -icr "chuleta_.*\.txt") chuletas
elif [ "$TERMINO" = "--topics" ];then
	cd ${DIRBASE}
	tree.com //a . | tail -n +3
	cd - > /dev/null
	salir 0
elif [ "$TERMINO" = "--terms" ];then
	cat $RUTA_CACHE/lista_comp
	salir 0
elif [ "$TERMINO" = "--frequent" ];then
	TEMP1=$(mktemp /tmp/chuleta.XXXXX)
	cat "$RUTA_LOGS/frecuentes" | sed -r "s#${DIRBASE}/##g" > $TEMP1
	$RUTA/tops.sh "$TEMP1"
	rm "$TEMP1" 2> /dev/null
else
	locate $MAX_DB_AGE -A -d $RUTA_CACHE/db -iwr "chuleta_.*\.txt$" $LISTA_PALABRAS | sed -r "s|$DIRBASE/||g" > $TEMPORAL
fi

CANT_RESULTADOS=`cat $TEMPORAL | wc -l`

if [ $CANT_RESULTADOS -eq 1 ] && [ "$TERMINO" != "--recent" ] ; then
	cat "$TEMPORAL"
	$COMANDO `cat "$TEMPORAL"`
elif [ $CANT_RESULTADOS -gt 0 -a $CANT_RESULTADOS -le 12 ]; then
	menu "$TEMPORAL"
elif [ $CANT_RESULTADOS -gt 12 ];then
	reporte "$TEMPORAL"
fi

set +e
find /tmp/chuleta.* -mtime +1 -delete &>/dev/null
salir 0






