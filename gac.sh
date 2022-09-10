#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TOPICS_TEMP}" && test -f "${TOPICS_TEMP}" && rm "${TOPICS_TEMP}"
	test -n "${TOPICS_DIR_TEMP}" && test -f "${TOPICS_DIR_TEMP}" && rm "${TOPICS_DIR_TEMP}"
	test -n "${BACKUP_DIR_TEMP}" && [[ "${BACKUP_DIR_TEMP}" =~ ^\/tmp\/.* ]] && test -d "${BACKUP_DIR_TEMP}" && rm -rf "${BACKUP_DIR_TEMP}"
	exit $1
}

set -euo pipefail
source ~/.config/chu/chu.conf
# variables read from conf file: NO_OLD_DB_WRN, LARGO_PERMITIDO, BASE_DIR, MAX_MENU_LENGTH
MAX_DB_AGE=""
test $NO_OLD_DB_WRN -eq 1 || MAX_DB_AGE="--max-database-age -1"

BASE_DIR=$1
NAMEDIRBASE=$(basename $BASE_DIR)
SCRIPT_DIR=$(dirname $0)
CACHE_DIR=~/.cache/chu
CHULETADB=$CACHE_DIR/chuletas.db
TOPICS_FILE=$CACHE_DIR/lista_topicos
TOPICS_DIRS_FILE=$CACHE_DIR/lista_rutas_topicos
DUPLICATE_TOPICS_FILE=$CACHE_DIR/lista_topicos_repetidos
COMP_LIST_FILE=$CACHE_DIR/lista_comp
TOPICS_TEMP=$(mktemp /tmp/chuleta.XXXXX)
TOPICS_DIR_TEMP=$(mktemp /tmp/chuleta.XXXXX)
BACKUP_DIR_TEMP=$(mktemp -d /tmp/chuleta.XXXXX)

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
sort -u > $TOPICS_TEMP

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
sort -u > $TOPICS_DIR_TEMP

end=$(date +%s)
runtime=$((end-start))
echo " ${runtime}s"

set +e
mv $CACHE_DIR/lista_* ${BACKUP_DIR_TEMP}/
set -e

cp $TOPICS_TEMP $TOPICS_FILE
cp ${TOPICS_DIR_TEMP} $TOPICS_DIRS_FILE

if [ $(cat $TOPICS_DIRS_FILE |cut -f 1|uniq -c|grep -vn "1"|wc -l) -gt 0 ];then
	echo
	echo Duplicated topics found. Can''t update autocomplete data:
	echo
	x="$(cat $TOPICS_DIRS_FILE |cut -f 1|uniq -c|grep -v "1"|awk '{print $2}')"
	find $BASE_DIR -type d -iname "$x"
	cp -pr ${BACKUP_DIR_TEMP}/* $CACHE_DIR/
	echo
	salir 1
fi


start=$(date +%s)
echo -n "...autocompletion lists"

for line in $(cat $TOPICS_FILE);do
	search_line="^$line	"
	topic_path=$(egrep "$search_line" $TOPICS_DIRS_FILE |cut -f 2)
	sqlite3 "${CHULETADB}" "select abs_path from v_chuleta_ap where abs_path like '$topic_path/%chuleta_%';"|\
	awk -v RTO="$topic_path" -f $SCRIPT_DIR/glst.awk > $CACHE_DIR/lista_$line
done

end=$(date +%s)
runtime=$((end-start))
echo " ${runtime}s"

sqlite3 "${CHULETADB}" "select abs_path from v_chuleta_ap;" |\
awk -v RTO="$BASE_DIR" -f $SCRIPT_DIR/glst.awk >  "${COMP_LIST_FILE}"
sqlite3 "${CHULETADB}" "insert or replace into settings(key,value) values ('LAST_UPDATED_AC',CURRENT_TIMESTAMP);"
exit 0
