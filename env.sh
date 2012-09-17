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

export YCSB_HEAP_SIZE=1024

export user=$USER
export EMAIL=$USER@yahoo-inc.com
export BASE=$HOME/danielomid/omidcluster
export LOGBASE=$HOME

export JAVA_HOME=/System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/Home

export YCSB=$BASE/benchmarks/YCSB
export ZKSERVER=localhost
export ZKSERVERLIST=localhost:2223
export ZKDATADIR=$HOME/zookeeper/
export BKSERVERLIST=localhost
export BKSERVERS=`echo $BKSERVERLIST | sed "s/:/ /"`;
export BKPARAM1=1
export BKPARAM2=1
export BKDISK1=$HOME/bk_data/
export BKDISK2=$HOME/bk
export SEQSERVER=localhost
export SEQPORT=1230
export HBASEMASTER=localhost
export HDFSMASTER=localhost
#export HDFSDIR="/d1/$user/hdfsdir /home/$user/hdfsdir"
export HDFSDIR="$HOME/hdfsdir"
export SHORTSIZE=300000
export TABLE="benchmark${SHORTSIZE}"
export TABLESIZE=`echo $SHORTSIZE | sed "s/m/000000/"`
#number of status oracles
export PARTITIONS=1
#export BENCHTIME=600
export BENCHTIME=60

export STATS=$HOME/stats
export MAXVERSIONS=1000000
export TSOSERVER0=localhost
#export TSOSERVER1=wilbur7
#export TSOSERVER2=wilbur8
#export TSOSERVER3=wilbur9
#export TSOSERVER4=wilbur10
firstso=0
lastso=$((PARTITIONS-1))
TSOSERVERS=""
for i in $(seq $firstso $lastso); do
	so=TSOSERVER$i
	TSOSERVERS="$TSOSERVERS ${!so}"
done
export TSOSERVERS
