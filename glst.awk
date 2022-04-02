#!/usr/bin/gawk -f

# generates list of terms related to a topic

# this funcion substitutes a with b in $0
func change(a,b) {
	while (i=index($0,a))
			$0 = substr($0,1,i-1) b substr($0,i+length(a))	
}

{
	# we delete the base folder (received in var RTO) from the input line 
	# and clean it of other stuff
	change(RTO,"")
	change(".txt","")
	change("/"," ")
	change("_"," ")
	split($0,a," ")
	# using arr as associative array by using same string as index
	# this prevents duplicated strings and code is shorter 
	# since we don't have to maintain a counter for index
	for (x in a)
		arr[a[x]]=a[x]
}

END{
	n=asort(arr,sarr)
	for (x in sarr)
		printf("%s ",sarr[x])
}