#!/bin/bash

NUM=$1
while read line
do	
	if [[ $(echo $line|awk '{print $1}') -gt $NUM ]];then
		echo $line
	fi
done
	