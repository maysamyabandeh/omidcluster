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

source env.sh

ZK=$BASE/zk/startzk.sh
ZKCLI=$BASE/zk/zkCli.sh
ZKCMD=/tmp/zkcmd.$user.txt
rm $ZKCMD

ssh -f $ZKSERVER "$ZK" ;
sleep 2;
echo Registers the sequencer in the ZooKeeper
echo "create /sequencer b" >> $ZKCMD 
echo "create /sequencer/ip $SEQSERVER" >> $ZKCMD
echo "create /sequencer/port $SEQPORT" >> $ZKCMD
echo Registers the SOs in the ZooKeeper
total=$TABLESIZE
socount=$PARTITIONS
psize=$((total/socount))
len=`echo $total | awk '{print length($1)}'`
lastindex=0

firstso=0
lastso=$((socount-1))
echo "create /sos b" >> $ZKCMD
for i in $(seq $firstso $lastso); do
	echo "create /sos/$i b" >> $ZKCMD
	so=TSOSERVER$i
	echo "create /sos/$i/ip ${!so}"  >> $ZKCMD
	echo "create /sos/$i/port 1234" >> $ZKCMD
	if [ $i -ne $firstso ] ; then
		echo "create /sos/$i/start ${TABLE}user${li}" >> $ZKCMD
	fi
	lastindex=$((lastindex+psize))
	li=`printf "%0${len}d" $lastindex`
	if [ $i -ne $lastso ] ; then
		echo "create /sos/$i/end ${TABLE}user${li}" >> $ZKCMD
	fi
done

$ZKCLI -server $ZKSERVERLIST < $ZKCMD
echo covered up to $li
