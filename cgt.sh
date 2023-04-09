#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMP}" && test -f "${TEMP}" && rm "${TEMP}"
	exit $1
}

set -euo pipefail

repodir="${1}"
tagtokeep="${2}"
TEMP="$(mktemp /tmp/chuleta.XXXXX)"

cd "${repodir}"
git tag -l | egrep "^chu_${USER}_update_[0-9]{14}"| fgrep -v "${tagtokeep}" > "${TEMP}"
for s in $(cat "${TEMP}");do
	git tag -d "${s}"
done


