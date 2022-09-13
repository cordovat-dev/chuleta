#!/bin/bash

trap exit_handler EXIT

function exit_handler {
	set +u
	test -n "${TEMP}" && test -f "${TEMP}" && rm "${TEMP}"
	exit $1
}

set -euo pipefail

FILE=""
SCRIPT_DIR=$(dirname $0)
TEMP=$(mktemp /tmp/chuleta.XXXXX)

COLOUR=0

while getopts f:c flag
do
    case "${flag}" in
		c) COLOUR=1;;
		f) FILE=${OPTARG};;
    esac
done

test -z $FILE && exit 1

arr[0]="You should consider trying to learn the following by heart:"
arr[1]="It's about time you memorize the following:"
arr[2]="Don't just copy and paste, understand!:"
arr[3]="You use these ones frequently, try to learn them for once:"
arr[4]="Try typing instead of copy+pasting, so you don't forget these:"
arr[5]="Print these ones and pin them to your corkboard:"
arr[6]="These ones should already have become second nature to you:"
arr[7]="I guess you already know these topics without looking them up:"
arr[8]="Do these ones ring a bell?:"
arr[9]="You will have to use some mnemonic to learn some of these:"
arr[10]="You should know better:"
rand=$[$RANDOM % ${#arr[@]}]

cat <<EOF > $TEMP

${arr[$rand]}

EOF

$SCRIPT_DIR/./fmt2.sh $(test $COLOUR = 1 && echo "-c" || echo "") -n < $FILE >> $TEMP
cat $TEMP
