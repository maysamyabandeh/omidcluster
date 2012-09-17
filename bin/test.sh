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

for e in mixed; do
  for tag in 0; do
    ALL_THREADS="1"
    for threads in $ALL_THREADS; do
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

      done
    done
  done
done
