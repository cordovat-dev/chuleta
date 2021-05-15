#!/bin/bash

declare -i COUNT=0;
declare -i SUM=0;
while read line
do
	((COUNT ++))
	((SUM = SUM + $line))
done;
AVG=$(( $SUM/$COUNT ))
echo $AVG