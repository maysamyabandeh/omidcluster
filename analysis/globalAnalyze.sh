#!/bin/bash

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

source ../env.sh
source utilAnalyze.sh
RESULTS="$BASE/results/"

RESULTS=../results-global/
#crcimbo-30m-readonly-256t-7
dirpattern="\(.*\)-\([0-9\.m]\+\)-\(.*\)-\([0-9]\+\)t-\(.*\)"

cnt=0
total=`ls -l $RESULTS | wc -l`
echo -n "Progress: " 
tput sc

for i in $RESULTS/*; do 
	dir=`basename $i`
	system=`echo $dir | sed "s/${dirpattern}/\1/"`
	size=`echo $dir | sed "s/${dirpattern}/\2/"`
	workload=`echo $dir | sed "s/${dirpattern}/\3/"`
	clients=`echo $dir | sed "s/${dirpattern}/\4/"`
	tag=`echo $dir | sed "s/${dirpattern}/\5/"`

	OUTPUT="${system}.${workload}.txt"
   analyzed=`analyzeTSO 1 $i/tso*.log`
	globalChance=$tag
	echo $globalChance $analyzed >> $OUTPUT

	cnt=$((++cnt))
	percent=$((cnt * 100 /total))
	tput rc
	echo -n $percent%
	#echo -ne "$cnt $total $percent"
done
echo

for i in *.txt; do
	sort -n $i -o $i
done

