#!/usr/bin/bash

if [ $# -ne 2 ]
then
	exit 1
else
	filesdir=$1
	searchstr=$2
	if [ -d ${filesdir} ]
	then
		echo ""
	else
		exit 1
	fi
fi

numfiles=$(find ${filesdir} -type f | wc -l)
numlines=$(grep ${searchstr} $(find ${filesdir} -type f) | wc -l)

echo "The number of files are ${numfiles} and the number of matching lines are ${numlines}"
