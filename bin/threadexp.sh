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

source ./bin/util.sh

# workloads
#for dist in " " "_zipfian" "_tail"; do
for dist in ""; do
#dist=_zipfian
#for e in writeonly$dist readonly$dist complexonly$dist mixed$dist; do
#for e in mixed$dist; do
for e in mixed readonly$dist mixed$dist; do
	#if [ "$e" = "complexonly_zipfian" ]; then
	#ALL_THREADS="32 64"
	#else
	ALL_THREADS="1 2 8 32 256"
	#ALL_THREADS="1 8 16 32 64"
	#fi

		#for tag in 0 1 2 3 4 5 6 7 8 9; do
		for tag in 0 1 2 3; do
	for threads in $ALL_THREADS; do
		#for tag in 0 1 2 3 4; do

		#tag has to be a number
		#for each tag we run the experiments once
		#for tag in 0 1 2 3 4; do

			#for d in hbase crcimbo cimbo; do
				#for d in rwcimbo rwcimboelderfetchall; do
				#for d in rwcimbobuggy rwcimboelderfetchall rwcimbo ; do
				#for d in crcimbo rwcimbo rwcimbowithww hbase ; do
				for d in crcimbo ; do

				stop_cluster
				clear_statistics
				start_cluster $d
				echo Working on $e $d ${threads}t $tag

				# wait for hbase to settle so the throughput is stable
				#sleep 300s
				sleep 5s

				outdir=$BASE/../results/$d-${SHORTSIZE}-$e-${threads}t-$tag
				run_bench $outdir $d $e $threads $tag
				#it is done in kill_switch now
				#collect_statistics $outdir
				cd analysis/
				analyzed=`. analyzeThis.sh $outdir`
				analyzedHeader=`cat analyzedHeader.txt`
				cd -
				mail -s "Finished $d $e with $threads clients" -b "$EMAIL" "$EMAIL" << EOF
You can check the results at $outdir/
$analyzedHeader
$analyzed
EOF

stop_cluster
exit

				sleep 60s

			done

		done
	done
done

done
stop_cluster
