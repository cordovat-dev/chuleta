#!/bin/bash

LARGO_PERMITIDO=$1
TERMINO=$2
DIRBASE=$3

TEMPORAL=`mktemp /tmp/chuleta.XXXXX`

function abrir {
	CHULETA=`cat $1`
	LONGITUD=`wc -l < "$DIRBASE/$CHULETA"`
	if [ $LONGITUD -gt $LARGO_PERMITIDO ]; then
		gnome-open "$CHULETA"
	else
		echo
		cat "$DIRBASE/$CHULETA"
	fi	
}

locate -i chuleta | egrep -r "\.txt$" | grep -i "$TERMINO" | sed -r "s|$DIRBASE/||g" | tee $TEMPORAL

CANT_RESULTADOS=`cat $TEMPORAL | wc -l`

if [ $CANT_RESULTADOS -eq 1 ]; then

	abrir "$TEMPORAL"
fi

rm $TEMPORAL
exit 0






