#!/bin/bash

trap exit_handler_cgt EXIT

function exit_handler_cgt {
	set +u
	test -n "${TEMP}" && test -f "${TEMP}" && rm "${TEMP}"
	exit $1
}

set -euo pipefail

repodir="${1}"
tagtokeep="${2}"
TEMP="$(mktemp /tmp/chuleta.XXXXX)"

cd "${repodir}"

set +e
git tag -l | egrep "^chu_update_[0-9]{14}"| fgrep -v "${tagtokeep}" > "${TEMP}"
set -e

for s in $(cat "${TEMP}");do
	git tag -d "${s}"
done


