#!/bin/bash

DIRBASE=$1
RUTA_CACHE=~/.cache/chu
ARCHIVO_TOPICOS=$RUTA_CACHE/lista_topicos
ARCHIVO_RUTAS_TOPICOS=$RUTA_CACHE/lista_rutas_topicos
ARCHIVO_TOPICOS_REPETIDOS=$RUTA_CACHE/lista_topicos_repetidos
TEMP=`mktemp /tmp/chuleta.XXXXX`
TEMP2=`mktemp /tmp/chuleta.XXXXX`
TEMP3=`mktemp -d /tmp/chuleta.XXXXX`

function borrar_temp()
{
	rm -rf $TEMP ${TEMP2} ${TEMP3}
}


for line in $(find "$DIRBASE" -type f -iname "chuleta*.txt");do
	VA=$(echo "$line"|xargs dirname|sed 's#.*/##')
	echo $VA >> $TEMP
	VB=$(echo "$line"|xargs dirname)
	echo "$VA	$VB" >> ${TEMP2}
done
cp $RUTA_CACHE/* ${TEMP3}/
rm $RUTA_CACHE/*
sort -u $TEMP|tr '\n' ' ' > $ARCHIVO_TOPICOS
sort -u ${TEMP2} > $ARCHIVO_RUTAS_TOPICOS

if [ $(cat $ARCHIVO_RUTAS_TOPICOS |cut -f 1|uniq -c|grep -vn "1"|wc -l) -gt 0 ];then
	echo
	echo Tópicos duplicados. No se puede actualizar datos
	echo de autocompletación:
	echo
	x="$(cat $ARCHIVO_RUTAS_TOPICOS |cut -f 1|uniq -c|grep -v "1"|awk '{print $2}')"
	find $DIRBASE -type d -iname "$x"
	cp -pr ${TEMP3}/* $RUTA_CACHE/
	echo
	borrar_temp
	salir 1
fi

borrar_temp

for line in $(cat $ARCHIVO_TOPICOS);do
	busqueda="^$line	"
	ruta_topico=$(egrep "$busqueda" $ARCHIVO_RUTAS_TOPICOS |cut -f 2)
	find "$ruta_topico" -type f -iname "chuleta*.txt" \
	|sed -r "s|$ruta_topico||g" \
	|sed -r "s|\.txt||g" \
	|sed -r "s|$DIRBASE||g" \
	|sed -r "s|/| |g" \
	|sed -r "s|_| |g" \
	|tr ' ' '\n' \
	|sort -u \
	|tr '\n' ' ' > $RUTA_CACHE/lista_$line
done

find "$DIRBASE" -type f -iname "chuleta*.txt" \
|sed -r "s|$DIRBASE||g" \
|sed -r "s|\.txt||g" \
|sed -r "s|chuleta_||g" \
|sed -r "s|/| |g" \
|sed -r "s|_| |g" \
|tr ' ' '\n' \
|sort -u \
|tr '\n' ' ' >  $RUTA_CACHE/lista_comp

echo '	' >> $RUTA_CACHE/lista_comp

exit 0



