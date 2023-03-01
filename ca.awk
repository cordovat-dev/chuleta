#!/usr/bin/awk -f
BEGIN {
	LI=0
	LM=0
}
{
	LM = length($0)
	if (LM > LI) {
		LI = LM
	}
}
END {print LI}
