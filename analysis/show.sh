#!/bin/bash

#
# Copyright (c) 2011 Yahoo! Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License. See accompanying LICENSE file.
#

#This scripts render the results on screen in a human-friendly way

if [ $# -lt 1 ]; then
	echo "Usage: ./show.sh file [avg] [cum_columns]"
	exit
fi
IN=$1
shift

HEADER=header.txt
FILTER=1
CN=`cat $HEADER | wc -w`
if [ $# -gt 0 ]
then
	if [ $1 = "avg" ]
	then
		FILTER=2
	fi
	shift
fi
if [ $# -gt 0 ]
then
	CN=$1
	shift
fi

COLUMNS=1
for (( i=2; i<=$CN; i++)); do 
	REM=`expr $i % $FILTER`
	if [ $REM -eq 0 ]
	then
		COLUMNS=$COLUMNS,$i; 
	fi
done


cp $HEADER /tmp/cf.txt; 
cat $IN >> /tmp/cf.txt; 
cat /tmp/cf.txt | cut -d' ' -f$COLUMNS | column -t

