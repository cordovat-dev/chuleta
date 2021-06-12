#!/bin/bash
set -euo pipefail
LARGO_PERMITIDO=$1
DIRBASE=$2
TERMINO=$3
LISTA_PALABRAS="${@:3}"
COMANDO="abrir"
RUTA_CACHE=~/.cache/chu
RUTA_LOGS=~/.cache/chu.logs

RUTA=`dirname $0`
TEMPORAL=`mktemp /tmp/chuleta.XXXXX`
TEMPORAL2=`mktemp /tmp/chuleta.XXXXX`

if [ -n "`printf "%s\n" "$LISTA_PALABRAS"|fgrep -e '--editar'`" ];then	
	LISTA_PALABRAS="`echo $LISTA_PALABRAS|sed 's/--editar//g'`"
	COMANDO="editar"
fi

function check_admin {
	net session > /dev/null 2>&1
	if [ $? -ne 0 ];then
		echo "Esta operación debe ejecutarse como Admin"
		salir 1
	fi
}

function abrir {
	CHULETA="$DIRBASE/$1"
	LONGITUD=`wc -l < "$CHULETA"`
	if [ $LONGITUD -gt $LARGO_PERMITIDO ];then
		start "$CHULETA"
	else
		echo
		cat "$CHULETA"
	fi	
	echo "$CHULETA" >> ${RUTA_LOGS}/frecuentes
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

if [ "$TERMINO" = "--reciente" ];then
	find "$DIRBASE" -type f -iname "chuleta*.txt" -mtime -30 > $TEMPORAL
	for s in $(cat $TEMPORAL);do
		echo "$(date '+%y-%m-%d_%H:%M' -r $s)" $(echo $s|sed -r "s|$DIRBASE||g" ) >> ${TEMPORAL2}
	done
	sort -r -k 1 ${TEMPORAL2} > ${TEMPORAL}
	
elif [ "$TERMINO" = "--update" ];then
	check_admin
	echo "Actualizando BD locate"
	echo "updatedb --localpaths=\"$DIRBASE\" --output=$RUTA_CACHE/db --prunepaths=\"$DIRBASE/.git\""
	updatedb --localpaths="$DIRBASE" --output="$RUTA_CACHE/db" --prunepaths="$DIRBASE/.git"
	echo "Generando autocompletación"
	$RUTA/gac.sh $DIRBASE
	salir 0
elif [ "$TERMINO" = "--totales" ];then
	echo
	for f in $(ls $DIRBASE);do
		if [ -d "${DIRBASE}/$f" ];then
			echo "$f: $(find ${DIRBASE}/${f}/ -type f -iname "chuleta_*.txt"|wc -l)"
		fi
	done |column -t|sort -k 2 -gr
	echo
	echo $(locate -A -d $RUTA_CACHE/db -icr "chuleta_.*\.txt") chuletas
elif [ "$TERMINO" = "--mostrar_topicos" ];then
	cd ${DIRBASE}
	cmd //c tree .
	cd - > /dev/null
	salir 0
elif [ "$TERMINO" = "--mostrar_terminos" ];then
	cat $RUTA_CACHE/lista_comp
	salir 0
elif [ "$TERMINO" = "--frecuentes" ];then
	TEMP1=$(mktemp /tmp/chuleta.XXXXX)
	cat "$RUTA_LOGS/frecuentes" | sed -r "s#${DIRBASE}/##g" > $TEMP1	
	$RUTA/tops.sh "$TEMP1"
	rm "$TEMP1" 2> /dev/null
else
	locate -A -d $RUTA_CACHE/db -iw chuleta $LISTA_PALABRAS | grep "\.txt$" | sed -r "s|$DIRBASE||g" > $TEMPORAL
fi

CANT_RESULTADOS=`cat $TEMPORAL | wc -l`

if [ $CANT_RESULTADOS -eq 1 ] && [ "$TERMINO" != "--reciente" ] ; then
	cat "$TEMPORAL"
	$COMANDO `cat "$TEMPORAL"`
elif [ $CANT_RESULTADOS -gt 0 -a $CANT_RESULTADOS -le 12 ]; then
	menu "$TEMPORAL"
elif [ $CANT_RESULTADOS -gt 12 ];then
	reporte "$TEMPORAL"
fi

find /tmp/chuleta.* -mtime +1 -delete &>/dev/null
salir 0






