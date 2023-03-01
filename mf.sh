function config {
	BEFORE="${CONFIG_FILE}.$(date +%Y%m%d%H%M%S)"
	cp "${CONFIG_FILE}" "${BEFORE}"
	echo "Editing ${CONFIG_FILE}..."
	${EDITOR} "${CONFIG_FILE}"
	set +e
	diff "${BEFORE}" "${CONFIG_FILE}"
	set -e
	rm "${BEFORE}"
	source "${CONFIG_FILE}"
	"${SCRIPT_DIR}"/udbs.sh -c "${CONFIG_FILE}" -d "${CHULETADB}"
}

function usage {
cat <<EOF
	Usage:
	chu [search_terms]
	chu search_terms -e|--editar
	chu search_terms -c|--clipboard
	chu --cached
	chu [--cached] n [-c|--clipboard]
	chu -u|--update
	chu -q|--quick-update
	chu --frequent
	chu -r|--random
	chu --terms
	chu --stats
	chu --topics
	chu -s|--show-config
	chu -C|--config
	chu -h|--help
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
	CHULETA="${BASE_DIR}"/"$1"
	set +u
	RNDCHU="$2"
	set -u
	if [ ! -f "${CHULETA}" ];then
		   notfound $1
		   exit 1
	fi
	LENGTH=$(wc -l < "${CHULETA}")
	MAX_CAT_LENGTH=$(( $(tput lines ) - 3 - 3 ))
	if [ ${LENGTH} -gt ${MAX_CAT_LENGTH} ];then
		if [ ${PREFER_LESS} = "YES" ];then
			less "${CHULETA}"
		else
			echo "  opening in editor or viewer..."
			${OPEN_COMMAND} "${CHULETA}"
		fi
	else
		echo
		cat "${CHULETA}"
		if [ ${COPYTOCLIP} -eq 1 ] && [ "${MINGW}" = "YES" ];then
			cat "${CHULETA}" > /dev/clipboard
			echo
			echo "...copied to clipboard"
		fi
	fi
	if [ "${RNDCHU}" != "--random" ]; then
		sqlite3 ${FREQUENTDB} "insert into frequent_log values('$1',1);"
	fi
}

function editar {
	echo "  opening in editor ..."
	${OPEN_COMMAND} "${BASE_DIR}"/"$1"
}

function menu {
	echo
	TEMP="$(mktemp /tmp/chuleta.XXXXX)"
	COUNT=$(wc -l < $1)
	cat $1 >> "${TEMP}"
	colour=$(test ${COLOUR} = "YES" && echo "-c" || echo "")
	test -f "${MENUCACHE}" && rm "${MENUCACHE}"
	test -f "${MENUCACHE_NC}" && rm "${MENUCACHE_NC}"
	"${SCRIPT_DIR}"/./fmt2.sh ${colour} -f "${MENUCACHE_NC}" < "${TEMP}" | tee "${MENUCACHE}"

	echo
	read -p "  ?  " respuesta
	if [[ ${respuesta} =~ ^-?[0-9]+$ ]];then
		OPTION=${respuesta}
		if [ ${OPTION} -ge 1 -a ${OPTION} -le ${COUNT} ];then
			OPTION=$(sed "${respuesta}q;d" "$1")
			echo
			"${SCRIPT_DIR}"/ct.sh -n ${respuesta} -d ${OPTION} $(test ${COLOUR} = "YES" && echo "-c" || echo "")
			${COMMAND} "${OPTION}"
		fi
	fi
}

function reporte {
	echo
	TEMP=$(mktemp /tmp/chuleta.XXXXX)
	cat $1 >> "${TEMP}"
	"${SCRIPT_DIR}"/./fmt2.sh -r < "${TEMP}"
	echo
}

function fullupdate {
	${SCRIPT_DIR}/sqls.sh -b "${BASE_DIR}" -d "${CHULETADB}" -w ${NUM_DAYS_OLD}
}

function checkgitrepo {
	local result=0
	if [ ! -d "$1" ] ;then
		echo "Folder ${1} not found."
		exit 1
	fi	
	cd "${1}"
	set +e
	git st &>/dev/null
	result=$?
	set -e

	if [ $result -ne 0 ];then
		echo "Folder ${1} is not a git repository" 
		exit 1
	fi
}


function initgitupdates {
	local repos_configured=0
	local giterr=0
	local repodir=""
	local tag="chu_update_$(date +%Y%m%d%H%M%S)"
	local somechange=0
	sqlite3 "${CHULETADB}" ".mode csv" ".separator ':'" "select path,use_preffix from v_git_repos;" > "${TEMP2}"
	for s in $(cat "${TEMP2}");do
		repodir=$(echo $s|awk -F: '{print $1}')
		checkgitrepo "${repodir}"
		# abort if either not a folder or not a git repo
		cd "${repodir}"
		git tag ${tag} HEAD
		"${SCRIPT_DIR}/cgt.sh" "${repodir}" "${tag}"
		somechange=1
	done
	if [ $somechange -eq 0 ];then
		echo "No repos configured. You must configure at least one git repo by adding a line "
		echo "like this in config file: GIT_REPO1=path_to_repo_with_no_trailing_slash"
		exit 1
	fi
	sqlite3 "${CHULETADB}" "insert or replace into settings values ('LAST_GIT_TAG','${tag}');"
}

function update() {
	local autocomp=""
	local tag=""
	set +u
	autocomp="$1"
	set -u
	echo "Backing up database"
	echo "Updating database"
	cp "${CHULETADB}" "${CHULETADB}.$(date +%Y%m%d%H%M%S)"
	cp "${FREQUENTDB}" "${FREQUENTDB}.$(date +%Y%m%d%H%M%S)"
	if [ "${GIT_INTEGRATION}" = "YES" ];then
		tag=$(sqlite3 "${CHULETADB}" "select value from settings where key = 'LAST_GIT_TAG';")
		if [[ "${tag}" =~ ^chu_update_[0-9]{14} ]]; then
			echo "Running git-based update"
			"${SCRIPT_DIR}/gitf.sh"
		else
			echo "Running full update to initialize git-based updates"
			fullupdate
			echo "Tagging last update commits"
			initgitupdates
		fi
	else
		fullupdate	
	fi
	test -n "${MENUCACHE}" && test -f "${MENUCACHE}" && rm "${MENUCACHE}"
	test -n "${MENUCACHE_NC}" && test -f "${MENUCACHE_NC}" && rm "${MENUCACHE_NC}"
	if [ "${autocomp}" != "quick" ];then
		echo "Generating autocompletion"
		"${SCRIPT_DIR}"/gac.sh "${BASE_DIR}"
	else
		sleep 1
	fi
	echo Done.
	exit 0
}
