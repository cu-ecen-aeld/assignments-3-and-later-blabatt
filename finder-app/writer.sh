#!/usr/bin/bash

if [ $# -ne 2 ]
then
	exit 1
else
	writerfile=$1
	writerstr=$2
fi

mkdir -p $(dirname ${writerfile})
echo "${writerstr}" > ${writerfile}
if [ $? -ne 0 ]; then
	exit 1
fi

