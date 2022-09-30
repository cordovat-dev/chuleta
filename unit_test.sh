#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	echo "Last succesful step: '$step'"
	if [ -d "$base_data_dir"/chu.back.test ]; then
		if [ -d "$base_data_dir"/chu ];then
			rm -rf "$base_data_dir"/chu
		else
			mv "$base_data_dir"/chu.back.test "$base_data_dir"/chu
		fi
	fi
	exit $1
}

function prompt_for_action {
	echo
	echo "$1"
	echo "Whas it succesful?"
	read -p "[n]=no,y=yes : " respuesta
	echo $respuesta
	test "$respuesta" = "y" || exit 1
}

function print_step {
	step=$1
	echo
	echo "====== $step ====="
	echo
}


set -euo pipefail
stable_branch=$1
new_branch=$2

program_dir=~/chuleta/chuleta
base_data_dir=~/.cache
respuesta=""

if [ -d "$base_data_dir"/chu.back.test ]; then
	echo "(1) Last test left base data dir in an uncomplete state"
	exit 1
fi
if [ ! -d "$base_data_dir"/chu ];then
	echo "(2) Last test left base data dir in an uncomplete state"
	exit 1
fi

test -d "$base_data_dir"/chu.back.1 && rm -rf "$base_data_dir"/chu.back.1
test -d "$base_data_dir"/chu.back.1.1 && rm -rf "$base_data_dir"/chu.back.1.1
test -d "$base_data_dir"/chu.back.2 && rm -rf "$base_data_dir"/chu.back.2
test -d "$base_data_dir"/chu.back.2.2 && rm -rf  "$base_data_dir"/chu.back.2.2

shopt -s expand_aliases
source ~/.bash_profile

cd $program_dir
step="git rev-parse --verify $stable_branch"
git rev-parse --verify $stable_branch
step="git rev-parse --verify $new_branch"
git rev-parse --verify $new_branch

print_step "Test complete chuletas report"
cd $program_dir
git co $stable_branch
chu > a.txt
git co $new_branch
chu > b.txt
diff a.txt b.txt

print_step "Test complete show config"
cd $program_dir
git co $stable_branch
chu --show-config > a.txt
git co $new_branch
chu --show-config > b.txt
diff a.txt b.txt

print_step "Test frequent"

cd $program_dir
git co $stable_branch
chu --frequent > a.txt
git co $new_branch
chu --frequent > b.txt
set +e
diff a.txt b.txt
set -e
prompt_for_action "There should not be any difference except for the random greeting"

print_step "Test deploy"
cd $base_data_dir
mv chu chu.back.test
cd $program_dir
git co $stable_branch
prompt_for_action "Run deploy as admin and then answer"
cd $base_data_dir
mv chu chu.back.1
cd $program_dir
git co $new_branch
prompt_for_action "Run deploy as admin and then answer"
cd $base_data_dir
mv chu chu.back.2
diff chu.back.1 chu.back.2

print_step "Test update (must be run after test deploy)"
rm -rf chu
mv chu.back.1 chu
cd $program_dir
git co $stable_branch
chu --update
cd $base_data_dir 
mv chu chu.back.1.1
cd $program_dir
git co $new_branch
cd $base_data_dir
mv chu.back.2 chu
chu --update
mv chu chu.back.2.2
set +e
diff chu.back.1.1 chu.back.2.2
set -e
prompt_for_action "There should not be any difference except for database backups"
mv chu.back.1.1 chu

print_step "Test frequent on an empty history"
cd $program_dir
git co $stable_branch
chu --frequent > a.txt
git co $new_branch
chu --frequent > b.txt
diff a.txt b.txt

print_step "Test menu choosing"
cd $program_dir
git co $stable_branch
printf "%s\n" 1| chu git merge branch > a.txt
git co $new_branch
printf "%s\n" 1| chu git merge branch > b.txt
diff a.txt b.txt

##################################

print_step "All tests passed"

cd $program_dir

