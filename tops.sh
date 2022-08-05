#!/bin/bash
set -euo pipefail

ARCHIVO=""
RUTA=$(dirname $0)

COLOUR=0

while getopts f:c flag
do
    case "${flag}" in
		c) COLOUR=1;;
		f) ARCHIVO=${OPTARG};;
    esac
done

arr[0]="You should consider trying to learn the following by heart:"
arr[1]="It's about time you memorize the following:"
arr[2]="Don't just copy and paste, understand!:"
arr[3]="You use these ones frequently, try to learn them for once:"
arr[4]="Try typing instead of copy+pasting, so you don't forget this:"
arr[5]="Print these ones and pin them to your corkboard:"
arr[6]="These ones should already have become second nature to you:"
arr[7]="I guess you already know these topics without looking them up:"
rand=$[$RANDOM % ${#arr[@]}]

echo
echo ${arr[$rand]}
echo

$RUTA/./fmt2.sh $(test $COLOUR = 1 && echo "-c" || echo "") -n < $ARCHIVO
