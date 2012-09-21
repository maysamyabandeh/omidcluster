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

#MACHINES="1 2 4 8 16 32 64 128 256 512 1024"
#MACHINES="1024 512 256 128 64 32 16 8 4 2 1"
#BUFSIZES="100 10 1"
BUFSIZES="1 10 100"
NROWS="0 2 4 8 16 32 64 128 256 512 1024"

for app in crcimbo ; do
	for rows in $NROWS ; do
		#to convert [0,x) to [0,x]
		rows=$((rows+1));
		for buf in $BUFSIZES ; do
			if [ $buf -eq 1 ]; then
				MACHINES="1 1024 512 256 128 64 32 16 8 4 2 1"
			else
				MACHINES="64 32 16 8 4 2 1"
			fi
			for threads in $MACHINES ; do

				stop_cluster
				clear_statistics
				run_tso_only $app

				tag=0
				outdir=$BASE/../results/sim-$app-${buf}b-${rows}r-${threads}t-$tag
				if [ $buf -eq 1 ]; then
					run_sim_clients $outdir $app $threads $buf $rows true
				else
					run_sim_clients $outdir $app $threads $buf $rows
				fi
				cd analysis/
				analyzed=`. analyzeThis.sh $outdir`
				analyzedHeader=`cat tsoHeader.txt`
				cd -
				mail -s "Finished $app $e with $threads clients" -b "$EMAIL" "$EMAIL" << EOF
You can check the results at $outdir/
$analyzedHeader
$analyzed
EOF

exit 0

			done
		done
	done
done

