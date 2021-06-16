#!/bin/bash
set -euo pipefail

DIRBASE=$1
NAMEDIRBASE=$(basename $DIRBASE)
RUTA_SCRIPT=$(dirname $0)
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

# 1. searches all chuletas in the db, 
# 2. removes the basename, 
# 3. removes the trailing slash (last char),
# 4. removes everything but the basename
# 5. creates a sorted unique list 
# RESULT: a list of all topics
locate -A -d $RUTA_CACHE/db -iwr "chuleta_.*\.txt"|\
grep -o "^/.*\/"|\
sed 's/.$//g'|\
grep -o '[^/]*$'|\
sort -u > $TEMP

# 1. searches all chuletas in the db, 
# 2. removes the basename, 
# 3. removes the trailing slash,
# 4. reates a sorted unique list
# 5. splits using slash and prints number of fields and all fields
# 6. creates a sorted unique list 
# RESULT: a list of folders names (a folder for each topic/subtopic)
locate -A -d $RUTA_CACHE/db -iwr "chuleta_.*\.txt"|\
grep -o "^/.*/"|\
sed -r 's#/$##g'|\
sort -u|\
awk 'BEGIN {FS="/"; OFS="\t"}{print $NF, $0}'|\
sort -u > $TEMP2

cp $RUTA_CACHE/* ${TEMP3}/
rm $RUTA_CACHE/*

cp $TEMP $ARCHIVO_TOPICOS
cp ${TEMP2} $ARCHIVO_RUTAS_TOPICOS

if [ $(cat $ARCHIVO_RUTAS_TOPICOS |cut -f 1|uniq -c|grep -vn "1"|wc -l) -gt 0 ];then
	echo
	echo Duplicated topics found. Can''t update autocomplete data:
	echo
	x="$(cat $ARCHIVO_RUTAS_TOPICOS |cut -f 1|uniq -c|grep -v "1"|awk '{print $2}')"
	find $DIRBASE -type d -iname "$x"
	cp -pr ${TEMP3}/* $RUTA_CACHE/
	echo
	borrar_temp
	salir 1
else
	cp ${TEMP3}/db $RUTA_CACHE/
fi

borrar_temp

for line in $(cat $ARCHIVO_TOPICOS);do
	busqueda="^$line	"
	ruta_topico=$(egrep "$busqueda" $ARCHIVO_RUTAS_TOPICOS |cut -f 2)
	locate -A -d $RUTA_CACHE/db -ir "$ruta_topico/chuleta_.*\.txt" |\
	awk -v RTO="$ruta_topico" -f $RUTA_SCRIPT/glst.awk > $RUTA_CACHE/lista_$line
done

locate -A -d $RUTA_CACHE/db -ir "chuleta_.*\.txt" |\
awk -v RTO="$DIRBASE" -f $RUTA_SCRIPT/glst.awk >  $RUTA_CACHE/lista_comp

exit 0



