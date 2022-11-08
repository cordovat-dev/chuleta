#!/bin/bash

set -euxo pipefail

depodir=~/chuleta/chuleta-data
masterbranch="prueba01"
lastpoint="HEAD~10"

function ismaster {
	[ "$(git symbolic-ref HEAD)" = "refs/heads/${masterbranch}" ] && echo 0 && echo 1
}

function listchanges {
	git diff-tree --name-status -r ${lastpoint}..HEAD|egrep -v "^M"
}

function iswtclean {
	[ $(git status -s|wc -l)  -eq 0 ] && echo 0 || echo 1
}

function filterDML {
awk -f <(cat - <<-"EOF"
	BEGIN {print "BEGIN TRANSACTION;"}
	$1 == "A" {printf ("insert into chuleta (path) values (\x27%s\x27);\n",$2) }
	$1 == "D" {printf ("delete from chuleta where path = \x27%s\x27;\n",$2) }
	END {print "END TRANSACTION;"}
EOF
)
}

cd "${depodir}"
[ $(ismaster) -eq 1  ] && echo "${masterbranch} is not the current branch" && exit 1
[ $(iswtclean) -eq 1  ] && echo "Working tree is not clean" && exit 1
listchanges|filterDML