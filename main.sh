#!/bin/bash

LARGO_PERMITIDO=$1
TERMINO=$2
TEMPORAL=`mktemp /tmp/chuleta.XXXXX`

locate -i chuleta | egrep -r "\.txt$" | grep -i "$TERMINO" | tee $TEMPORAL

CANT_RESULTADOS=`cat $TEMPORAL | wc -l`

if [ $CANT_RESULTADOS -eq 1 ]; then

	CHULETA=`cat $TEMPORAL`
	LONGITUD=`cat $CHULETA | wc -l`

	if [ $LONGITUD -gt $LARGO_PERMITIDO ]; then
		gnome-open $CHULETA
	else
		cat $CHULETA
	fi
fi

rm $TEMPORAL
exit 0






