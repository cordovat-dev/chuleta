#!/bin/bash
set -eo pipefail

# these two parms must be used together in this sequence or not at all:
# -n -i
PARM1="$1" # no line numbers, but a total 
PARM2="$2" # change "chuletas" legend to "items"
set -u
RUTA=`dirname $0`
INICIAL_TABULADO=`mktemp /tmp/sbd_XXXXXXXX`
NUM_PARTE_INFERIOR=`mktemp /tmp/sbd_XXXXXXXX`
PRIMERA_FILA_TABULADO=`mktemp /tmp/sbd_XXXXXXXX`
FINAL_SIN_LINEA=`mktemp /tmp/sbd_XXXXXXXX`
FINAL_SIN_LINEA_RETABULADO=`mktemp /tmp/sbd_XXXXXXXX`
RESULTADO_FINAL=`mktemp /tmp/sbd_XXXXXXXX`
NB_ITEMS="chuletas"

column -t > $INICIAL_TABULADO
CANTIDAD=0

if [ "$PARM1" = "-n" ];then
	sed "2,1000 !d" $INICIAL_TABULADO | cat > $NUM_PARTE_INFERIOR
	NUM=""
	CANTIDAD=`cat $INICIAL_TABULADO | wc -l`
	CANTIDAD=$(( $CANTIDAD - 1 ))
else
	sed "2,1000 !d" $INICIAL_TABULADO | cat -b > $NUM_PARTE_INFERIOR
	NUM="#"
fi

echo "$NUM `sed '1,1 !d' $INICIAL_TABULADO`" | column -t > $PRIMERA_FILA_TABULADO
cat $PRIMERA_FILA_TABULADO > $FINAL_SIN_LINEA
#echo $SEPARADOR >> $FINAL_SIN_LINEA
cat $NUM_PARTE_INFERIOR >> $FINAL_SIN_LINEA
column -t $FINAL_SIN_LINEA > $FINAL_SIN_LINEA_RETABULADO

ANCHO=$($RUTA/./ca.awk < $FINAL_SIN_LINEA_RETABULADO)
SEPARADOR=$(eval printf '=%.0s' {1..$ANCHO})

sed '1,1 !d' $FINAL_SIN_LINEA_RETABULADO > $RESULTADO_FINAL
echo $SEPARADOR >> $RESULTADO_FINAL
sed "2,1000 !d" $FINAL_SIN_LINEA_RETABULADO >> $RESULTADO_FINAL

while read linea
do
  echo "  $linea"
done < $RESULTADO_FINAL
if [ $CANTIDAD -gt 4 ]; then

	if [ "$PARM2" = "-i" ];then
		NB_ITEMS="items"
	fi

	echo "  $linea"
	echo "  $CANTIDAD $NB_ITEMS"
fi

rm $INICIAL_TABULADO
rm $NUM_PARTE_INFERIOR
rm $PRIMERA_FILA_TABULADO
rm $FINAL_SIN_LINEA
rm $FINAL_SIN_LINEA_RETABULADO
rm $RESULTADO_FINAL


