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

cd $BASE

run_tso_only() {
    linkapp $*
    $BASE/bin/start-zk.sh
    $BASE/bin/start-bk.sh
    sleep 5
    start_tso $*
	 echo "sleep 5s to initialize the heap"
	 sleep 5;

	 for i in $HDFSMASTER `cat machines.txt` `cat $BASE/hdfs/conf/slaves` $SEQSERVER $TSOSERVERS; do
        ssh $i $BASE/bin/collect_statistics.sh
    done
}

run_sim_clients() {
	if [ $# -lt 5 ]; then
		echo "parameters <outdir> <type> <threads> <buffersize> <rows> <pause?>"
		exit 1;
	fi

	outdir=$1
	shift

	app=$1
	NumClient=$2; 
	NMSGS=$3
	MAX_ROWS=$4
	if [ $# -gt 4 ]
	then
		PAUSE_CLIENT="true"
	fi
	echo "Run clients $*"

	killall -u $USER kill_switch.sh
	./bin/kill_switch.sh $BENCHTIME $outdir &

	#split the client processes among the machines
	nmachines=`cat machines.txt | wc -l`;
	each=$((NumClient / nmachines))
	remainder=$((NumClient % nmachines))

	BPROC=
	for machine in `cat machines.txt`;
	do
		if [ $remainder -gt 0 ]; then 
			runs=$((each + 1));
			remainder=$((remainder - 1));
		else
			runs=$each;
		fi
		if [ $runs -eq 0 ]
		then
			break
		fi
		echo Running $runs Client\(s\) on $machine
		ssh -f $machine "$BASE/$app/bin/omid.sh simclients $machine $NMSGS $runs $MAX_ROWS $PAUSE_CLIENT "
		BPROC="$BPROC $!"
	done
	wait $BPROC
	pgrep kill_switch.sh; switchfinished=$?;
	if [[ $switchfinished -ne 1 ]]; then
		echo WARN kill_switch.sh is not finished!
		killall kill_switch.sh
		#if we force killing kill_switch.sh, perhasp the collect_statistics is not finished, so do it
		collect_statistics $outdir
	fi
}

#ulimit -u 8192
start_cluster() {
    linkapp $*
    $BASE/bin/start-zk.sh
    $BASE/bin/start-bk.sh
    sleep 5
    ssh -f $HDFSMASTER $BASE/hdfs/bin/start-dfs.sh
    sleep 15
    start_tso $*
    sleep 10
    ssh -f $HBASEMASTER $BASE/hbase/bin/start-hbase.sh

	 for i in $HDFSMASTER `cat machines.txt` `cat $BASE/hdfs/conf/slaves` $SEQSERVER $TSOSERVERS; do
        ssh $i $BASE/bin/collect_statistics.sh
    done
}

#link to the lib directory of the app
linkapp() {
  srcdir=$1
  echo "USING $1"
  if [ "$1" = "hbase" ]; then
    #I just need a working lib directory for hbase and hdfs
    srcdir="crcimbo"
  fi
  if [ ! -d "$BASE/$srcdir" ]; then
    echo "Error: Unknown application: $srcdir"
    exit 1
  fi
  for i in $ZKSERVER $BKSERVERS $TSOSERVERS $SEQSERVER $HDFSMASTER $HBASEMASTER `cat $BASE/hdfs/conf/slaves` `cat $BASE/machines.txt`; do 
    ssh $i "cp $BASE/$srcdir/target/omid*jar $BASE/$srcdir/lib/;  unlink $BASE/lib; ln -s -f $BASE/$srcdir/lib $BASE/lib ; if [[ ! -d $STATS ]]; then mkdir $STATS; fi"
  done
}

start_tso() {
	srcdir=$1
	echo "USING $1"
	if [ "$1" = "hbase" ]; then
		#I just need a working lib directory for hbase and hdfs
		srcdir="crcimbo"
	fi
	if [ ! -d "$BASE/$srcdir" ]; then
		echo "Error: Unknown application: $srcdir"
		exit 1
	fi

	echo "Compile Native Libray..."
	make -C $BASE/$srcdir/src/main/native clean
	make -C $BASE/$srcdir/src/main/native
	if [ $? -ne 0 ]; then 
		exit 1; 
	fi; 

	ssh -f $SEQSERVER $BASE/$srcdir/bin/omid.sh sequencer $SEQPORT &
	sleep 1
	firstso=0
	lastso=$((PARTITIONS-1))
	echo Launching $PARTITIONS status oracles
	for i in $(seq $firstso $lastso); do
		so=TSOSERVER$i
		ssh -f ${!so} $BASE/$srcdir/bin/omid.sh tso $i &
	done
	echo sleeping
	sleep 3

	for i in `cat machines.txt`; do 
		ssh $i ln -s -f $BASE/$srcdir/conf/omid-site.xml $BASE/benchmarks/YCSB/db/tranHbase/conf
	done
	prepare_ycsb
}

prepare_ycsb() {
	for i in `cat machines.txt`; do 
		ssh $i ln -s -f $BASE/hbase/conf/hbase-site.xml $YCSB/db/hbase/conf/
		ssh $i ln -s -f $BASE/hbase/conf/hbase-site.xml $YCSB/db/tranHbase/conf/
	done
}

get_load() {
	echo Machine Threads `sar | grep CPU | head -1` | column -t
	for i in $TSOSERVERS $HBASEMASTER `cat machines.txt` `cat $BASE/hdfs/conf/slaves`; do 
		#ssh -f $i "echo $i \`uptime\` Threads \`ps -u $user -m | wc -l\`"
		ssh -f $i "echo $i \`ps -u $user -m | wc -l\`t \`sar 1 | tail -1\` | column -t" 
	done
	wait
}

stop_cluster() {
	#Note: I observed a bug if we do not stop hbase before dfs. Make sure you wait for hbase to shut down
    ssh $HBASEMASTER $BASE/hbase/bin/stop-hbase.sh
    ssh $HDFSMASTER $BASE/hdfs/bin/stop-dfs.sh
    #Note: my stop functions are dump and use "pkill java". It is better to run them after cleanly stopping hbase and hdfs
    #otherwise hbase and hdfs processes are killed in a not so clean way
	 $BASE/bin/stop-sos.sh
    $BASE/bin/stop-zk.sh
    $BASE/bin/stop-bk.sh
    sleep 10
	 #if hbase and hdfs are not stopped already, do it the hard way
    ssh -f $HDFSMASTER "pkill -u $user sar; pkill -u $user sadc; pkill -9 -u $user java;"
    ssh -f $HBASEMASTER "pkill -u $user sar; pkill -u $user sadc; pkill -9 -u $user java;"
    for slave in `cat hdfs/conf/slaves`; do 
		 ssh -f $slave "pkill -9 -u $user java; pkill -u $user sar; pkill -u $user sadc; pkill -9 -u $user vmstat; pkill -9 -u $user iostat"
    done
   #for i in `cat machines.txt`; do 
	#   ssh -f $i "pkill -9 sar -u $user; pkill -9 vmstat -u $user; pkill -9 iostat -u $user"
   #done
   #ssh -f $HBASEMASTER "pkill -9 sar -u $user; pkill -9 vmstat -u $user; pkill -9 iostat -u $user"
   #ssh -f $HDFSMASTER "pkill -9 sar -u $user; pkill -9 vmstat -u $user; pkill -9 iostat -u $user"
   #ssh -f $ZKSERVER "pkill -9 sar -u $user; pkill -9 vmstat -u $user; pkill -9 iostat -u $user"
}

clean_cluster() {
	echo -e "Y\nY" | ssh $HDFSMASTER $BASE/hdfs/bin/hadoop namenode -format

	for i in $TSOSERVERS; do
		ssh ${i} "echo 0  > /tmp/tso-persist.txt"
	done

	ssh -f $HDFSMASTER "rm /tmp/hadoop*.pid; rm /tmp/hbase*.pid"
	ssh -f $HBASEMASTER "rm /tmp/hadoop*.pid; rm /tmp/hbase*.pid"
	for i in `cat $BASE/hdfs/conf/slaves`; do 
		echo "Cleaning $i"
		ssh -f $i "rm /tmp/hadoop*.pid; rm /tmp/hbase*.pid"
		for j in $HDFSDIR; do
			ssh $i rm -rf $j/data &
			ssh $i mkdir -p $j/ &
		done
	done

	echo "Wait on cleaning to finish"
	wait
	echo "Done"
}

create_hbase_table() {
    hbase/bin/hbase shell <<EOF
disable '$1'
drop '$1'
create '$1', {NAME=>'transactionSupport', VERSIONS=>$MAXVERSIONS}
exit

EOF
}

load_data() {
	if [ $# -lt 3 ]; then
		echo "parameters: <dbtype> <amount> <round>"
		exit
	fi

	TYPE=$1
	AMOUNT=$2
	ROUND=$3

	#a quick hack for the problem of reading vars from both env.sh and command line
	CHUNK=`echo $AMOUNT | sed "s/m/000000/"`
	if [ $CHUNK -ne $TABLESIZE ]; then 
		echo ERROR: the amount specified does not mathc the SHORTSIZE in evn.sh
		exit
	fi


	create_hbase_table $TABLE
	prepare_ycsb

	BENCHSERVERCOUNT=`cat machines.txt | wc -w`
	CHUNK=$(( $CHUNK/$BENCHSERVERCOUNT ))
	START=0
	for i in `cat machines.txt`; do
		echo "Loading from $START on $i"
		ssh $i "$BASE/bin/do.sh load-data-single $TYPE $AMOUNT $START $CHUNK $ROUND" &
		START=$(($START+$CHUNK))
	done
	wait
}

load_data_single() {
	if [ $# -lt 2 ]; then
		echo "parameters: <dbtype> <amount> [start] [count] [round]"
		exit
	fi

	TYPE=$1
	AMOUNT=$2
	AMOUNT=`echo $AMOUNT | sed "s/m/000000/"`
	START=$3
	COUNT=$4
	ROUND=$5
	if [ "$START" = "" ]; then
		START=0
	fi
	if [ "$COUNT" = "" ]; then
		COUNT=$AMOUNT
	fi
	THREADS=32

	COUNTPARAM="-p recordcount=$AMOUNT -p insertcount=$COUNT -p insertorder=inorder"

	EXTRAARGS="-p columnfamily=transactionSupport"
	if [ "$TYPE" = "hbase" ]; then
		DRIVER="com.yahoo.ycsb.db.HBaseClient"
		CLASSPATH=$YCSB/db/hbase/conf
	elif [ "$TYPE" = "hdfsZero" ]; then
		EXTRAARGS="$EXTRAARGS -p timestampZero=true "
		DRIVER="com.yahoo.ycsb.db.HBaseClient"
		CLASSPATH=$YCSB/db/hbase/conf
	elif [ ${TYPE:0:7} = "rwcimbo" ]; then
		DRIVER="com.yahoo.ycsb.db.TranHBaseClient"
		CLASSPATH=$YCSB/db/tranHbase/conf
	elif [ "$TYPE" = "crcimbo" ]; then
		DRIVER="com.yahoo.ycsb.db.TranHBaseClient"
		CLASSPATH=$YCSB/db/tranHbase/conf
	fi

	OUTPUT=$STATS/$TYPE.$TABLE.`hostname`.${THREADS}t.round$ROUND.txt
	echo "Running load, output to $OUTPUT"
	export YCSB_HEAP_SIZE=3072
	#Added by Maysam Yabandeh
	#To make the table tiny
	EXTRAARGS="$EXTRAARGS -p fieldcount=1 -p fieldlength=1"
	CLASSPATH=$YCSB/db/hbase/conf
	for j in $BASE/lib/*.jar; do
		CLASSPATH=$CLASSPATH:$j
	done
	export CLASSPATH
	$YCSB/bin/ycsb.sh com.yahoo.ycsb.Client -load -db $DRIVER -p table=$TABLE $EXTRAARGS -P $YCSB/workloads/workload_mixed -p insertstart=$START $COUNTPARAM -s -threads $THREADS &> $OUTPUT
}

collect_statistics() {
	if [ $# -lt 1 ]; then
		echo "parameters <type>-<numrec>-<set>-<#clients>"
		exit 1;
	fi

	OUTPUT=$1
	#OUTPUT=$BASE/../results/$1-$2-$3-${THREADS}t-$4

	#cp $BASE/hadoop_logs/* $OUTPUT
	#cp $BASE/hbase_logs/* $OUTPUT
	#cp $BASE/stats/* $OUTPUT

	mkdir -p $OUTPUT/bin
	cp $BASE/bin/*sh $OUTPUT/bin
	mkdir -p $OUTPUT/master
	scp $HDFSMASTER:$STATS/* $OUTPUT/master
	for i in `cat machines.txt` `cat $BASE/hdfs/conf/slaves` $SEQSERVER $TSOSERVERS; do
		mkdir -p $OUTPUT/$i
		scp $i:$STATS/* $OUTPUT/$i
	done
}

clear_statistics() {
    #rm $BASE/hadoop_logs/*
    #rm $BASE/hbase_logs/*
    #rm $BASE/stats/*

    CLEAR="rm -rf $STATS/; mkdir $STATS/"
    for i in $HBASEMASTER $HDFSMASTER $SEQSERVER $TSOSERVERS `cat machines.txt` `cat $BASE/hdfs/conf/slaves` ; do
         ssh -f $i "$CLEAR"
    done
}

run_bench() {
	if [ $# -lt 4 ]; then
		echo "parameters <outdir> <type> <set> <threads> <round> <globalchance>"
		exit 1;
	fi

	outdir=$1
	shift

	TYPE=$1
	SET=$2
	THREADS=$3
	ROUND=$4
	GLOBAL=$5

	killall kill_switch.sh
	./bin/kill_switch.sh $BENCHTIME $outdir &

	BPROC=
	for i in `cat machines.txt`; do
		ssh $i "$BASE/bin/do.sh run-bench-single $TYPE $SET $THREADS $ROUND $GLOBAL"  &
		BPROC="$BPROC $!"
	done
	wait $BPROC
	pgrep kill_switch.sh; switchfinished=$?;
	if [[ $switchfinished -ne 1 ]]; then
		echo WARN kill_switch.sh is not finished!
		killall kill_switch.sh
		#if we force killing kill_switch.sh, perhasp the collect_statistics is not finished, so do it
		collect_statistics $outdir
	fi
	flush_hbase $TABLE
}

flush_hbase() {
    hbase/bin/hbase shell <<EOF
major_compact '$1'
exit
EOF
}

run_bench_single() {
	if [ $# -lt 4 ]; then
		echo "parameters <type> <workload> <#clients> <round>"
		exit 1;
	fi

	TYPE=$1
	SET=$2
	THREADS=$3
	ROUND=$4
	if [ $# -gt 4 ]; then
		GLOBALARG="-p globalchance=$5"
	fi

	REALNUMREC=$TABLESIZE

	EXTRAARGS="-p columnfamily=transactionSupport "
	if [ "$TYPE" = "hbase" ]; then
		DRIVER="com.yahoo.ycsb.db.HBaseClient"
		CLASSPATH=$YCSB/db/hbase/conf
	elif [ ${TYPE:0:7} = "rwcimbo" ]; then
		DRIVER="com.yahoo.ycsb.db.TranHBaseClient"
		CLASSPATH=$YCSB/db/tranHbase/conf
	elif [ "$TYPE" = "crcimbo" ]; then
		DRIVER="com.yahoo.ycsb.db.TranHBaseClient"
		CLASSPATH=$YCSB/db/tranHbase/conf
	fi
	COUNT=90000000

	#OUTPUT=$BASE/stats/$TYPE.$SET.$SHORTSIZE.$ROUND.`hostname`.${THREADS}t.A
	OUTPUT=$STATS/$TYPE.$SET.$SHORTSIZE.$ROUND.`hostname`.${THREADS}t.A
	echo "Running bench, output to $OUTPUT"
	export YCSB_HEAP_SIZE=3072

	EXTRAARGS="$EXTRAARGS -p partitions=$PARTITIONS -p fieldcount=1 -p fieldlength=1"
	for j in $BASE/lib/*.jar; do
		CLASSPATH=$CLASSPATH:$j
	done
	export CLASSPATH
	$YCSB/bin/ycsb.sh com.yahoo.ycsb.Client -p measurementtype=timeseries -p timeseries.granularity=1000 -p table=$TABLE -p operationcount=$COUNT -p recordcount=$REALNUMREC -p insertorder=inorder $GLOBALARG $EXTRAARGS -t -db $DRIVER -P $YCSB/workloads/workload_$SET -s -threads $THREADS -target 50000 &> $OUTPUT 
}

