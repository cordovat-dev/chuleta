function notfound {
cat <<EOF

  FATAL: Can't find '$1'

  Run chu --update or --chu --quick-update
  This will solve the issue if file was renamed,
  moved, or deleted.
EOF
}

function abrir {
	CHULETA="$BASE_DIR/$1"
	set +u
	RNDCHU="$2"
	set -u
	if [ ! -f $CHULETA ];then
		   notfound $1
		   exit 1
	fi
	LONGITUD=$(wc -l < $CHULETA)
	if [ $LONGITUD -gt $MAX_CAT_LENGTH ];then
		echo "  opening in editor or viewer..."
		$OPEN_COMMAND "$CHULETA"
	else
		echo
		cat "$CHULETA"
	fi
	if [ "$RNDCHU" != "--random" ]; then
		sqlite3 ${FREQUENTDB} "insert into frequent_log values('$1',1);"
	fi
}

function editar {
	echo "  opening in editor ..."
	$OPEN_COMMAND $BASE_DIR/$1
}

function menu {
	echo
	TEMP=$(mktemp /tmp/chuleta.XXXXX)
	COUNT=$(wc -l < $1)
	cat $1 >> "$TEMP"
	colour=$(test $COLOUR = "YES" && echo "-c" || echo "")
	test -f ${MENUCACHE} && rm ${MENUCACHE}
	test -f ${MENUCACHE_NC} && rm ${MENUCACHE_NC}
	$RUTA/./fmt2.sh $colour -f ${MENUCACHE_NC} < "$TEMP" | tee ${MENUCACHE}

	echo
	read -p "  ?  " respuesta
	if [[ $respuesta =~ ^-?[0-9]+$ ]];then
		OPCION=$respuesta
		if [ $OPCION -ge 1 -a $OPCION -le $COUNT ];then
			OPCION=$(sed "${respuesta}q;d" "$1")
			echo
			$RUTA/ct.sh -n $respuesta -d $OPCION $(test $COLOUR = "YES" && echo "-c" || echo "")
			$COMANDO $OPCION
		fi
	fi
}

function reporte {
	echo
	TEMP=$(mktemp /tmp/chuleta.XXXXX)
	cat $1 >> "$TEMP"
	$RUTA/./fmt2.sh -r < "$TEMP"
	echo
}

function  update() {
	local autocomp=""
	set +u
	autocomp="$1"
	set -u
	echo "Backing up database"
	echo "Updating database"
	cp "${CHULETADB}" "${CHULETADB}.$(date +%Y%m%d%H%M%S)"
	cp "${FREQUENTDB}" "${FREQUENTDB}.$(date +%Y%m%d%H%M%S)"
	$RUTA/sqls.sh -b "$BASE_DIR" -d "${CHULETADB}" -w $NUM_DAYS_OLD
	test -n "${MENUCACHE}" && test -f "${MENUCACHE}" && rm "${MENUCACHE}"
	test -n "${MENUCACHE_NC}" && test -f "${MENUCACHE_NC}" && rm "${MENUCACHE_NC}"
	if [ "$autocomp" != "quick" ];then
		echo "Generating autocompletion"
		$RUTA/gac.sh $BASE_DIR
	else
		sleep 1
	fi
	echo Done.
	exit 0
}
