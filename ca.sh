#!/bin/bash


LI=0
LM=0

while read fila; do

	if [ `echo "$fila" | wc -m` -gt $LI ];then		
		LM=`echo "$fila" | wc -m`
		LI=$LM
	fi
done < /dev/stdin

LM=`expr $LM - 1`

echo $LM
