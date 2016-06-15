#! /bin/bash

# Do CG plain files
for n in `ls ./cg*.txt | grep -v kh`;
	do 
		m=`echo $n | cut -d "." -f2`
		./html-gen.sh  $n   ".$m.html"; 
		echo ".$m.html"
		echo""
done

# Do CG kh files
for n in `ls ./cg*.txt | grep kh.txt`;
	do 
		m=`echo $n | cut -d "." -f2`
		./html-gen-kh.sh  $n   ".$m.html"; 
		echo ".$m.html"
		echo""
done

# Do KH files
for n in `ls ./kh*.txt`;
	do 
		m=`echo $n | cut -d "." -f2`
		./html-gen-kh.sh  $n   ".$m.html"; 
		echo ".$m.html"
		echo""
done

# Do AF files
for n in `ls ./af*.txt`;
	do 
		m=`echo $n | cut -d "." -f2`
		./html-gen.sh  $n   ".$m.html"; 
		echo ".$m.html"
		echo""
done


