function config {
	if [ -z ${EDITOR+x} ]; then
			echo EDITOR environment variable must be set
			exit 1
	fi
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
	chu search_terms -e|--edit
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
	chu --clear-git-tags
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

function copy_to_clip {
	CHULETA="$1"
	if [ ${COPYTOCLIP} -eq 1 ] && [ "${MINGW}" = "YES" ];then
		cat "${CHULETA}" > /dev/clipboard
		echo
		echo "...copied to clipboard"
	elif [ ${COPYTOCLIP} -eq 1 ];then
		cat "${CHULETA}" | xclip -selection c
		echo
		echo "...copied to clipboard"
	fi
}

detect_language() {
    local file_content=$(cat "$1")

    shopt -s nocasematch

    bashpattern="#!/bin/bash"

    if [[ "$file_content" =~ ${bashpattern} ]]; then
        echo "sh"
    elif [[ "$file_content" =~ (^|[^[:alnum:]_])(public|class|static|void|main|System\.out\.println)(^|[^[:alnum:]_]) ]]; then
        echo "java"
    elif [[ "$file_content" =~ (^|[^[:alnum:]_])(SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER|TRUNCATE|MERGE|CALL|EXPLAIN|LOCK)(^|[^[:alnum:]_]) ]]; then
        echo "sql"
    elif [[ "$file_content" =~ (^|[^[:alnum:]_])(DECLARE|BEGIN|EXCEPTION|END|LOOP|IF|ELSIF|ELSE|EXIT|WHILE|FOR|GOTO|RETURN|RAISE|NULL)(^|[^[:alnum:]_]) ]]; then
        echo "sql"
    elif [[ "$file_content" =~ (^|[^[:alnum:]_])(function|var|let|const|console\.log|document\.getElementById)(^|[^[:alnum:]_]) ]]; then
        echo "js"
    else
        echo "txt"
    fi

   shopt -u nocasematch
}


function _bcat {
	_bcatpath=""
	cp "${1}" "${TEMPBCAT}."$(detect_language "${1}")
	#echo "${TEMPBCAT}."$(detect_language "${1}")
	batcat --paging never -p "${TEMPBCAT}."$(detect_language "${1}")
}

function _bless {
	_bcatpath=""
	cp "${1}" "${TEMPBCAT}."$(detect_language "${1}")
	#echo "${TEMPBCAT}."$(detect_language "${1}")
	batcat --pager "less -M" -p "${TEMPBCAT}."$(detect_language "${1}")
}

function _temp_file {
    _fullpath="${1}"
    _newextension="${2}"

    _path="${_fullpath%/*}"
    _filename="${_fullpath##*/}"
    _extension="${_filename##*.}"
    _filenamenoext="${_filename%.*}"
    _hash=$(echo -n "$_path" | md5sum | cut -d ' ' -f 1)
    _last5=${_hash: -5}

    echo /tmp/"${_filenamenoext}"_"${_last5}.${_newextension}"
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
			${LESS_COMMAND} "${CHULETA}"
		else
			cp "${CHULETA}" $(_temp_file "${CHULETA}" $(detect_language "${CHULETA}"))
			echo
			echo "  opening in editor or viewer..."
			echo
			${OPEN_COMMAND} $(_temp_file "${CHULETA}" $(detect_language "${CHULETA}"))
		fi
	else
		echo
		${CAT_COMMAND} "${CHULETA}"
	fi
	copy_to_clip "${CHULETA}"
	if [ "${RNDCHU}" != "--random" ]; then
		sqlite3 ${FREQUENTDB} "insert into frequent_log values('$1',1);"
		sqlite3 ${CHULETADB} "insert or replace into last_opened values(1,'$1');"
	fi
}

function editar {
	echo
	echo "  opening in editor ..."
	echo
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
	${SCRIPT_DIR}/sqls.sh -b "${BASE_DIR}" -d "${CHULETADB}" -t "${FTSDB}" -w ${NUM_DAYS_OLD}
}

function checkgitrepo {
	local result=0
	if [ ! -d "$1" ] ;then
		echo "Folder ${1} not found."
		exit 1
	fi	
	cd "${1}"
	set +e
	git status &>/dev/null
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

	set +u
	if [ -n "$1" ];then
		tag="$1"
	fi
	set -u

	sqlite3 "${CHULETADB}" ".mode csv" ".separator ':'" "select path,use_preffix from v_git_repos;" > "${TEMP2}"
	for s in $(cat "${TEMP2}");do
		repodir=$(echo $s|awk -F: '{print $1}')
		checkgitrepo "${repodir}"
		# abort if either not a folder or not a git repo
		cd "${repodir}"
		if [ "$tag" != "$NULLGITTAG" ]; then
			git tag ${tag} HEAD
		fi
		"${SCRIPT_DIR}/cgt.sh" "${repodir}" "${tag}"
		somechange=1
	done
	if [ $somechange -eq 0 ];then
		echo "No repos configured. You must configure at least one git repo by adding a line "
		echo "like this in config file: GIT_REPO1=path_to_repo_with_no_trailing_slash"
		exit 1
	fi
	if [ "$tag" != "$NULLGITTAG" ]; then
		sqlite3 "${CHULETADB}" "insert or replace into settings values ('LAST_GIT_TAG','${tag}');"
	else
		sqlite3 "${CHULETADB}" "insert or replace into settings values ('LAST_GIT_TAG',NULL);"
	fi
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
	cp "${FTSDB}" "${FTSDB}.$(date +%Y%m%d%H%M%S)"
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

function clear-git-tags() {
	echo "Clearing git tags"
	initgitupdates "$NULLGITTAG" 
}
