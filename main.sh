#!/bin/bash

LARGO_PERMITIDO=$1
DIRBASE=$2
TERMINO=$3
LISTA_PALABRAS="${@:3}"

RUTA=`dirname $0`
TEMPORAL=`mktemp /tmp/chuleta.XXXXX`

function abrir {
	CHULETA="$DIRBASE/$1"
	LONGITUD=`wc -l < "$CHULETA"`
	if [ $LONGITUD -gt $LARGO_PERMITIDO ];then
		gnome-open "$CHULETA"
	else
		echo
		cat "$CHULETA"
	fi	
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
			abrir $OPCION
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

function filtrar {
	LISTA="$1"
	cat - | while read LINE
	do
		for termino in ${LISTA[@]}; do			
			LINE=`echo "$LINE"|grep -i $termino`
		done
		if [ -n "$LINE" ];then
			echo "$LINE"
		fi
	done	
}

locate -i chuleta | egrep "$DIRBASE" | egrep -r "\.txt$" | filtrar "$LISTA_PALABRAS" | sed -r "s|$DIRBASE||g" > $TEMPORAL

CANT_RESULTADOS=`cat $TEMPORAL | wc -l`

if [ $CANT_RESULTADOS -eq 1 ]; then
	cat "$TEMPORAL"
	abrir `cat "$TEMPORAL"`
elif [ $CANT_RESULTADOS -gt 0 -a $CANT_RESULTADOS -le 12 ]; then
	menu "$TEMPORAL"
elif [ $CANT_RESULTADOS -gt 12 ];then
	reporte "$TEMPORAL"
fi

rm $TEMPORAL
find /tmp/chuleta.* -mtime +1 -delete &>/dev/null
exit 0






