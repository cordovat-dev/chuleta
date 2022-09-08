#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMP_TOPICOS}" && test -f "${TEMP_TOPICOS}" && rm "${TEMP_TOPICOS}"
	test -n "${TEMP_RUTAS_TOPICOS}" && test -f "${TEMP_RUTAS_TOPICOS}" && rm "${TEMP_RUTAS_TOPICOS}"
	test -n "${TEMP_BACKUP}" && [[ "${TEMP_BACKUP}" =~ ^\/tmp\/.* ]] && test -d "${TEMP_BACKUP}" && rm -rf "${TEMP_BACKUP}"
	exit $1
}

set -euo pipefail
source ~/.config/chu/chu.conf
# variables read from conf file: NO_OLD_DB_WRN, LARGO_PERMITIDO, BASE_DIR, MAX_MENU_LENGTH
MAX_DB_AGE=""
test $NO_OLD_DB_WRN -eq 1 || MAX_DB_AGE="--max-database-age -1"

BASE_DIR=$1
NAMEDIRBASE=$(basename $BASE_DIR)
RUTA_SCRIPT=$(dirname $0)
RUTA_CACHE=~/.cache/chu
CHULETADB=$RUTA_CACHE/chuletas.db
ARCHIVO_TOPICOS=$RUTA_CACHE/lista_topicos
ARCHIVO_RUTAS_TOPICOS=$RUTA_CACHE/lista_rutas_topicos
ARCHIVO_TOPICOS_REPETIDOS=$RUTA_CACHE/lista_topicos_repetidos
ARCHIVO_LISTA_COMPLETA=$RUTA_CACHE/lista_comp
TEMP_TOPICOS=$(mktemp /tmp/chuleta.XXXXX)
TEMP_RUTAS_TOPICOS=$(mktemp /tmp/chuleta.XXXXX)
TEMP_BACKUP=$(mktemp -d /tmp/chuleta.XXXXX)

# 1. searches all chuletas in the db,
# 2. removes the basename,
# 3. removes the trailing slash (last char),
# 4. removes everything but the basename
# 5. creates a sorted unique list
# RESULT: a list of all topics
start=$(date +%s)
echo -n "...processing (sub)topics"

sqlite3 "${CHULETADB}" "select abs_path from v_chuleta_ap;"|\
grep -o "^/.*\/"|\
sed 's/.$//g'|\
grep -o '[^/]*$'|\
sort -u > $TEMP_TOPICOS

end=$(date +%s)
runtime=$((end-start))
echo " ${runtime}s"

# 1. searches all chuletas in the db,
# 2. removes the basename,
# 3. removes the trailing slash,
# 4. creates a sorted unique list
# 5. splits using slash and prints the last field, then all fields
# 6. creates a sorted unique list
# RESULT: a list of topics/suptopics and their corresponding folder
start=$(date +%s)
echo -n "...mapping folders"

sqlite3 "${CHULETADB}" "select abs_path from v_chuleta_ap;"|\
grep -o "^/.*/"|\
sed -r 's#/$##g'|\
sort -u|\
awk 'BEGIN {FS="/"; OFS="\t"}{print $NF, $0}'|\
sort -u > $TEMP_RUTAS_TOPICOS

end=$(date +%s)
runtime=$((end-start))
echo " ${runtime}s"

start=$(date +%s)
echo -n "...backing up"

cp -pr $RUTA_CACHE/* ${TEMP_BACKUP}/
rm $RUTA_CACHE/*

cp $TEMP_TOPICOS $ARCHIVO_TOPICOS
cp ${TEMP_RUTAS_TOPICOS} $ARCHIVO_RUTAS_TOPICOS

end=$(date +%s)
runtime=$((end-start))
echo " ${runtime}s"


if [ $(cat $ARCHIVO_RUTAS_TOPICOS |cut -f 1|uniq -c|grep -vn "1"|wc -l) -gt 0 ];then
	echo
	echo Duplicated topics found. Can''t update autocomplete data:
	echo
	x="$(cat $ARCHIVO_RUTAS_TOPICOS |cut -f 1|uniq -c|grep -v "1"|awk '{print $2}')"
	find $BASE_DIR -type d -iname "$x"
	cp -pr ${TEMP_BACKUP}/* $RUTA_CACHE/
	echo
	salir 1
else
	start=$(date +%s)
	echo -n "...recovering backups"

	find ${TEMP_BACKUP}/ -type f ! -iname "lista_*" -exec cp -pr {} $RUTA_CACHE/ \;

	end=$(date +%s)
	runtime=$((end-start))
	echo " ${runtime}s"
	
fi


start=$(date +%s)
echo -n "...autocompletion lists"

for line in $(cat $ARCHIVO_TOPICOS);do
	busqueda="^$line	"
	ruta_topico=$(egrep "$busqueda" $ARCHIVO_RUTAS_TOPICOS |cut -f 2)
	sqlite3 "${CHULETADB}" "select abs_path from v_chuleta_ap where abs_path like '$ruta_topico/%chuleta_%';"|\
	awk -v RTO="$ruta_topico" -f $RUTA_SCRIPT/glst.awk > $RUTA_CACHE/lista_$line
done

end=$(date +%s)
runtime=$((end-start))
echo " ${runtime}s"

sqlite3 "${CHULETADB}" "select abs_path from v_chuleta_ap;" |\
awk -v RTO="$BASE_DIR" -f $RUTA_SCRIPT/glst.awk >  "${ARCHIVO_LISTA_COMPLETA}"
sqlite3 "${CHULETADB}" "insert or replace into settings(key,value) values ('LAST_UPDATED_AC',CURRENT_TIMESTAMP);"
exit 0
