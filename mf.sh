function config {
	BEFORE="$CONFIG_FILE.$(date +%Y%m%d%H%M%S)"
	cp "$CONFIG_FILE" "$BEFORE"
	echo "Editing $CONFIG_FILE..."
	$EDITOR "$CONFIG_FILE"
	diff "$BEFORE" "$CONFIG_FILE"
	rm "$BEFORE"
}

function usage {
cat <<EOF
	Usage:
	chu [search_terms]
	chu search_terms --editar
	chu search_terms --clipboard
	chu --cached
	chu [--cached] n [--clipboard]
	chu --update
	chu --quick-update
	chu --frequent
	chu --random
	chu --terms
	chu --stats
	chu --topics
	chu --show-config
	chu --help
EOF
}

function notfound {
cat <<EOF

  FATAL: Can't find '$1'

  Run chu --update or --chu --quick-update
  This will solve the issue if file was renamed,
  moved, or deleted.
EOF
}

function abrir {
	CHULETA="$BASE_DIR"/"$1"
	set +u
	RNDCHU="$2"
	set -u
	if [ ! -f "$CHULETA" ];then
		   notfound $1
		   exit 1
	fi
	LENGTH=$(wc -l < "$CHULETA")
	MAX_CAT_LENGTH=$(( $(tput lines ) - 3 - 3 ))
	if [ $LENGTH -gt $MAX_CAT_LENGTH ];then
		if [ $PREFER_LESS = "YES" ];then
			less "$CHULETA"
		else
			echo "  opening in editor or viewer..."
			$OPEN_COMMAND "$CHULETA"
		fi
	else
		echo
		cat "$CHULETA"
		if [ $COPYTOCLIP -eq 1 ] && [ "$MINGW" = "YES" ];then
			cat "${CHULETA}" > /dev/clipboard
			echo
			echo "...copied to clipboard"
		fi
	fi
	if [ "$RNDCHU" != "--random" ]; then
		sqlite3 ${FREQUENTDB} "insert into frequent_log values('$1',1);"
	fi
}

function editar {
	echo "  opening in editor ..."
	$OPEN_COMMAND "$BASE_DIR"/"$1"
}

function menu {
	echo
	TEMP="$(mktemp /tmp/chuleta.XXXXX)"
	COUNT=$(wc -l < $1)
	cat $1 >> "$TEMP"
	colour=$(test $COLOUR = "YES" && echo "-c" || echo "")
	test -f "${MENUCACHE}" && rm "${MENUCACHE}"
	test -f "${MENUCACHE_NC}" && rm "${MENUCACHE_NC}"
	"$SCRIPT_DIR"/./fmt2.sh $colour -f "${MENUCACHE_NC}" < "$TEMP" | tee "${MENUCACHE}"

	echo
	read -p "  ?  " respuesta
	if [[ $respuesta =~ ^-?[0-9]+$ ]];then
		OPTION=$respuesta
		if [ $OPTION -ge 1 -a $OPTION -le $COUNT ];then
			OPTION=$(sed "${respuesta}q;d" "$1")
			echo
			"$SCRIPT_DIR"/ct.sh -n $respuesta -d $OPTION $(test $COLOUR = "YES" && echo "-c" || echo "")
			$COMMAND "$OPTION"
		fi
	fi
}

function reporte {
	echo
	TEMP=$(mktemp /tmp/chuleta.XXXXX)
	cat $1 >> "$TEMP"
	"$SCRIPT_DIR"/./fmt2.sh -r < "$TEMP"
	echo
}

function update() {
	local autocomp=""
	set +u
	autocomp="$1"
	set -u
	echo "Backing up database"
	echo "Updating database"
	cp "${CHULETADB}" "${CHULETADB}.$(date +%Y%m%d%H%M%S)"
	cp "${FREQUENTDB}" "${FREQUENTDB}.$(date +%Y%m%d%H%M%S)"
	$SCRIPT_DIR/sqls.sh -b "$BASE_DIR" -d "${CHULETADB}" -w $NUM_DAYS_OLD
	test -n "${MENUCACHE}" && test -f "${MENUCACHE}" && rm "${MENUCACHE}"
	test -n "${MENUCACHE_NC}" && test -f "${MENUCACHE_NC}" && rm "${MENUCACHE_NC}"
	if [ "$autocomp" != "quick" ];then
		echo "Generating autocompletion"
		"$SCRIPT_DIR"/gac.sh "$BASE_DIR"
	else
		sleep 1
	fi
	echo Done.
	exit 0
}
