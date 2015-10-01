#!/bin/bash

LARGO_PERMITIDO=$1
DIRBASE=$2
TERMINO=$3

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

locate -i chuleta | egrep -r "\.txt$" | grep -i "$TERMINO" | sed -r "s|$DIRBASE||g" > $TEMPORAL

CANT_RESULTADOS=`cat $TEMPORAL | wc -l`

if [ $CANT_RESULTADOS -eq 1 ]; then
	cat "$TEMPORAL"
	abrir `cat "$TEMPORAL"`
elif [ $CANT_RESULTADOS -gt 0 -a $CANT_RESULTADOS -le 12 ]; then
	menu "$TEMPORAL"
fi

rm $TEMPORAL
find /tmp/chuleta.* -mtime +1 -delete &>/dev/null
exit 0






