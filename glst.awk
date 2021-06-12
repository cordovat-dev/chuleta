#!/usr/bin/gawk -f

# generates list of terms related to a topic

func change(a,b) {
	while (i=index($0,a))
			$0 = substr($0,1,i-1) b substr($0,i+length(a))	
}

{
	change(RTO,"")
	change(".txt","")
	change("/"," ")
	change("_"," ")
	split($0,a," ")
	for (x in a)
		arr[a[x]]=a[x]
}

END{
	n=asort(arr,sarr)
	for (x in sarr)
		printf("%s ",sarr[x])
}