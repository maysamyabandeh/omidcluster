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

DIR=`dirname "$0"`
cd $DIR/..

source ./bin/util.sh

usage() {
     cat <<EOF
Usage: util.sh <action>
  where <action> is one of
     run-tso-only
     start-cluster [crcimbo]
     stop-cluster
     clean-cluster
     load-data <hdfsZero> <30m> 0
     load-data-single <hdfsZero> <30m> 0 30m 0
     run-bench [crcimbo] [mixed] <#clients> <tag>
     run-bench-single  [crcimbo] [mixed] <#clients> <tag>
     kill-bench
     collect-statistics
EOF
}

case "$1" in 
    run-tso-only)
	 shift
	run_tso_only $*
	;;
    start-cluster)
    shift
    if [ $# -lt 1 ]; then
      echo Wrong usage!
      exit
    fi
	start_cluster $1
	;;
    stop-cluster)
	stop_cluster
	;;
    clean-cluster)
	clean_cluster
	;;
    load-data)
	shift 
	load_data $@
	;;
    load-data-single)
	shift
	load_data_single $@
	;;
    run-bench-single)
	shift 
	run_bench_single $@
	;;
    run-bench)
	shift
	run_bench $@
	;;
    kill-bench)
	 ./bin/stop-clients.sh
	 ./bin/stop-sos.sh
	 ./bin/stop-bk.sh
	 ./bin/stop-zk.sh
	;;
    get-load)
	get_load
	;;
	collect-statistics)
	shift
	collect_statistics $@
	;;
	clear-statistics)
	clear_statistics
	;;
	*)
	usage
esac
