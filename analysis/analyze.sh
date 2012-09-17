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

source ../env.sh
source utilAnalyze.sh
RESULTS="$BASE/../results/"

# 40 sec: 100341 operations; 2778.07 current ops/sec;
#operationpattern=".*operations; ${f} .*"

#crcimbo-30m-readonly-256t-7 => crcimbo-30m-readonly-256t
EXPRS=`ls $RESULTS | sed "s/\(.*\)-[0-9]\+/\1/" | tr " " "\n" | uniq`
cnt=0
total=`echo $EXPRS | wc -w`
echo -n "Progress: " 
tput sc

rm *.txt
for expr in $EXPRS; do 
	dir=`basename $expr`
	#crcimbo-30m-readonly-256t-7
	dirpattern="\(.*\)-\([0-9\.m]\+\)-\(.*\)-\([0-9]\+\)t"
	system=`echo $dir | sed "s/${dirpattern}/\1/"`
	size=`echo $dir | sed "s/${dirpattern}/\2/"`
	workload=`echo $dir | sed "s/${dirpattern}/\3/"`
	clients=`echo $dir | sed "s/${dirpattern}/\4/"`
	OUTPUT="${system}.${workload}.txt"

	# [MULTIREAD AverageLatency(ms)=92.07]
	latencypattern="^\[.*\=${f}].*"
	rm -f $numfile
	clientlogs=`ls $RESULTS/$expr-*/*/*A`
	for file in $clientlogs; do
		grep --text $latencypattern $file > $xchgfile
		pickRegion $xchgfile
		cat $xchgfile | sed "s/${latencypattern}/\1/" >> $numfile
		echo -n .
	done
	LAT=`./averager.sh $numfile`


	tsodir="$RESULTS/$expr"
	tsos="${tsodir}-*/*/tso*.log"
	numinst=`ls -d ${tsodir}-* | wc -w`
	TSO=`analyzeTSO $numinst $tsos`

	tsosarlogs=
	for tso in $TSOSERVERS; do
		tsosarlogs="$tsosarlogs `ls $RESULTS/$expr-*/$tso/sar_statistics.log`"
	done
	SAR=`analyzesar $tsosarlogs`

	echo $clients $LAT $TSO $SAR >> $OUTPUT

	cnt=$((++cnt))
	percent=$((cnt * 100 /total))
	tput rc
	echo -n $percent%
done
echo

for i in *.txt; do
	sort -n $i -o $i
done

