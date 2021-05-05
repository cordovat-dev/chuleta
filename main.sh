#!/bin/bash

LARGO_PERMITIDO=$1
DIRBASE=$2
TERMINO=$3
LISTA_PALABRAS="${@:3}"
COMANDO="abrir"
RUTA_LOGS=~/.cache/chu.logs

RUTA=`dirname $0`
TEMPORAL=`mktemp /tmp/chuleta.XXXXX`
TEMPORAL2=`mktemp /tmp/chuleta.XXXXX`

if [ -n "`printf "%s\n" "$LISTA_PALABRAS"|fgrep -e '--editar'`" ];then	
	LISTA_PALABRAS="`echo $LISTA_PALABRAS|sed 's/--editar//g'`"
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
	XXX=~
	echo "Actualizando BD locate"
	echo "updatedb --localpaths=\"$DIRBASE\" --output=$XXX/.cache/chu/db --prunepaths=\"$DIRBASE/.git\""
	updatedb --localpaths="$DIRBASE" --output="$XXX/.cache/chu/db" --prunepaths="$DIRBASE/.git"
	echo "Generando autocompletación"
	$RUTA/gac.sh $DIRBASE
	salir 0
elif [ "$TERMINO" = "--totales" ];then
	echo
	for f in $(ls $DIRBASE);do 
		echo "$f: $(find ${DIRBASE}/${f}/ -type f -iname "chuleta_*.txt"|wc -l)"
	done |column -t|sort -k 2 -gr
	echo
	echo $(find "$DIRBASE" -type f -iname "chuleta*.txt"|wc -l) chuletas
elif [ "$TERMINO" = "--mostrar_topicos" ];then
	cd ${DIRBASE}
	tree -d .
	cd -
	#for line in $(cat ~/.cache/chu/lista_topicos); do
	#	echo $line
	#done
	salir 0
elif [ "$TERMINO" = "--mostrar_terminos" ];then
	cat ~/.cache/chu/lista_comp
	salir 0
else
	locate -A -d ~/.cache/chu/db -iw chuleta $LISTA_PALABRAS | grep "\.txt$" | sed -r "s|$DIRBASE||g" > $TEMPORAL
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






