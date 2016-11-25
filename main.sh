#!/bin/bash

LARGO_PERMITIDO=$1
DIRBASE=$2
TERMINO=$3
LISTA_PALABRAS="${@:3}"
COMANDO="abrir"

RUTA=`dirname $0`
TEMPORAL=`mktemp /tmp/chuleta.XXXXX`

if [ -n "`printf "%s\n" "$LISTA_PALABRAS"|fgrep -e '--editar'`" ];then	
	LISTA_PALABRAS="`echo $LISTA_PALABRAS|sed 's/--editar//g'`"
	COMANDO="editar"
fi

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

function editar {
	gnome-open $DIRBASE/$1
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

function filtrar {
	LISTA="$1"
	cat - | while read LINE
	do
		for termino in ${LISTA[@]}; do			
			LINE=`echo "$LINE"|fgrep -i $termino`
		done
		if [ -n "$LINE" ];then
			echo "$LINE"
		fi
	done	
}

if [ "$TERMINO" = "--reciente" ];then
	find "$DIRBASE" -type f -iname "chuleta*.txt" -mtime -30 | sed -r "s|$DIRBASE||g" > $TEMPORAL
elif [ "$TERMINO" = "--update" ];then
	echo "Generando autocompletación"
	$RUTA/gac.sh $DIRBASE
	echo "Actualizando BD locate"
	echo "sudo updatedb"
	sudo updatedb
	exit 0
elif [ "$TERMINO" = "--totales" ];then
	echo
	for f in $(ls $DIRBASE);do echo "$f: $(ls $DIRBASE${f}/chu*.txt 2>/dev/null|wc -l)"; done |column -t|sort -k 2 -gr
	echo
	echo $(find "$DIRBASE" -type f -iname "chuleta*.txt"|wc -l) chuletas
else
	locate -ib chuleta | fgrep "$DIRBASE" | grep "\.txt$" | filtrar "$LISTA_PALABRAS" | sed -r "s|$DIRBASE||g" > $TEMPORAL
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

rm $TEMPORAL
find /tmp/chuleta.* -mtime +1 -delete &>/dev/null
exit 0






