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

source util.sh

# Size of database, same we used for loading it
#SIZE=100m
SIZE=30m

# take the last $THRESHOLD seconds
THRESHOLD=80
# trim the ver last $TAIL_THRSH seconds
TAIL_THRESH=20
#TAIL_THRESH=0
# we end up with $THRESHOLD - @TAIL_THRSH seconds of data


# workloads
#for dist in " " "_zipfian" "_tail"; do
for dist in ""; do
#dist=_zipfian
#for e in writeonly$dist readonly$dist complexonly$dist mixed$dist; do
#for e in mixed$dist; do
for e in readonly$dist; do
	#if [ "$e" = "complexonly_zipfian" ]; then
	#ALL_THREADS="32 64"
	#else
	ALL_THREADS="256"
	#ALL_THREADS="1 8 16 32 64"
	#fi

		#for tag in 0 1 2 3 4 5 6 7 8 9; do
		#for tag in 0 1 2 3; do
			for tag in $(seq 40 100); do
				globalchance=$tag
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

				source util.sh

			stop_cluster
			clear_statistics
			start_cluster $d
				#start_tso $d
				echo Working on $e $d ${threads}t $tag

				# wait for hbase to settle so the throughput is stable
				#sleep 300s
				#for tso 5s is enough
				sleep 5s

				run_bench $d ${SIZE} $e $threads $tag $globalchance
				collect_statistics $d ${SIZE} $e $tag
				RESULTS="/mnt/scratch/maysam/cluster/stats/${d}.${e}.${SIZE}.${tag}.wilbur*.labs.corp.sp1.yahoo.com.${threads}t.A"
				rm /tmp/yabandehsumtmp
				rm /tmp/yabandehmaysam.avglattmp
				for result in $RESULTS; do
					THR_THRESHOLD=$(( THRESHOLD / 5 ))
					THR_TAIL=$(( TAIL_THRESH / 5 ))
					LAT_THRESHOLD=$(( THRESHOLD / 10 ))
					LAT_TAIL=$(( TAIL_THRESH / 10 ))

					grep --text "operations" $result | tail -n +5 | tail -$THR_THRESHOLD | head -n -$THR_TAIL | cut -d " " -f 6 > /tmp/yabandehmaysam.avgsumtmp
					./analysis/averager.sh /tmp/yabandehmaysam.avgsumtmp | cut -d " " -f 1 >> /tmp/yabandehsumtmp
					OPS=`grep "^\[.*\]" $result | cut -d " " -f 1 | sort -u`
					for op in $OPS; do
						OP=`echo $op | tr -d "[]"`
						grep "^\[$OP .*" $result | tail -n +5 | tail -$LAT_THRESHOLD | head -n -$LAT_TAIL | sed "s/.*=\(.*\)\]/\1/" >> /tmp/yabandehmaysam.avglattmp
					done
				done
				THR=`./analysis/sumer.sh /tmp/yabandehsumtmp`
				LAT=`./analysis/averager.sh /tmp/yabandehmaysam.avglattmp`
				#mail -s "Finished $d $e with $threads clients" "maysam@yahoo-inc.com" -- -f"maysam@yahoo-inc.com" << EOF
				mail -s "Finished $d $e with $threads clients" -b "maysam@yahoo-inc.com" "maysam@yahoo-inc.com" -- -f"maysam@yahoo-inc.com" << EOF
You can check the results at /mnt/scratch/maysam/cluster/results/${d}-${SIZE}-${e}-${threads}t-${tag}/
Throughput: $THR
Latency: $LAT
EOF

				sleep 60s
			done

		done
	done
done
done

