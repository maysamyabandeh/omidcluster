source ../env.sh

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

f="\([0-9\.]\+\)"
numfile=/tmp/${USER}.num
afile=/tmp/${USER}.a
swpfile=/tmp/${USER}.swp
xchgfile=/tmp/${USER}.xchg
OUTF=/tmp/${USER}.sar.outf.txt
CPUF=/tmp/${USER}.sar.avgf.txt
WOF=/tmp/${USER}.sar.wof.txt
ROF=/tmp/${USER}.sar.rof.txt
WBF=/tmp/${USER}.sar.wbf.txt
RBF=/tmp/${USER}.sar.rbf.txt
NWOF=/tmp/${USER}.sar.nwof.txt
NROF=/tmp/${USER}.sar.nrof.txt
NWBF=/tmp/${USER}.sar.nwbf.txt
NRBF=/tmp/${USER}.sar.nrbf.txt
WPKF=/tmp/${USER}.sar.wpkt.txt
RPKF=/tmp/${USER}.sar.rpkt.txt
SDAF=/tmp/${USER}.sar.sdaf.txt

cutheadpercent=70 #40%
pickheadpercent=20 #40%

pickRegion() {
	lines=`cat $1 | wc -l`
	cuthead=$((cutheadpercent * lines / 100 + 1))
	pickhead=$((pickheadpercent * lines / 100))
	cat $1 | tail -n +$cuthead | head -$pickhead > $swpfile
	mv $swpfile $1
}

extract4avg() {
	files=${!1}
	pattern=${!2}
	param=$3
	rm -f $numfile
	for file in $files; do
		grep SERVER $file > $xchgfile
		pickRegion $xchgfile
		cat $xchgfile | sed "s/${pattern}/\\${param}/" >> $numfile
	done
}
extract4sum() {
	files=${!1}
	pattern=${!2}
	param=$3
	rm -f $numfile
	for file in $files; do
		grep SERVER $file > $xchgfile
		pickRegion $xchgfile
		cat $xchgfile | sed "s/${pattern}/\\${param}/" > $afile
		./averager.sh $afile >> $numfile
	done
}
extractTwo4avg() {
	files=${!1}
	pattern=${!2}
	param1=$3
	param2=$4
	rm -f $numfile
	for file in $files; do
		grep SERVER $file > $xchgfile
		pickRegion $xchgfile
		cat $xchgfile | sed "s/${pattern}/\\${param1} \\${param2}/" >> $numfile
	done
}
sumer() {
	COL=`head -1 $1 | wc -w`
	numinst=1
	if [[ $# -gt 1 ]]; then
		numinst=$2
	fi

	if [ $COL -eq 1 ]; then
		SUM=`awk 'BEGIN{SUM=0;} {SUM+=$1;} END{print SUM/"'"$numinst"'"}' $1`
	elif [ $COL -eq 2 ]; then
		SUM=`awk 'BEGIN{SUM=0; SUM2=0} {SUM+=$1; SUM2+=$2} END{print SUM/"'"$numinst"'"" "SUM2/"'"$numinst"'"}' $1`
	else
		echo "ERROR: Wrong number of colums ($COL) in file $1"
		exit
	fi
	echo $SUM
}

analyzeTSO() {
	numinst=$1
	shift
	tsos=$*

	#SERVER: 1794.6 (54264.6) TPS(G), 11670.8 ( 0.0) Abort/s(G)
	tpspattern=".* ${f} *( *${f} *).*TPS(G).* ${f} *( *${f} *).*Abort.*"
	extract4sum tsos tpspattern 1
	TPS=`sumer $numfile $numinst`
	extract4avg tsos tpspattern 2
	GTPS=`./averager.sh $numfile`

	#compute abort rate
	extract4sum tsos tpspattern 3
	ABORT=`sumer $numfile $numinst`
	extract4avg tsos tpspattern 4
	GABORT=`./averager.sh $numfile`

	#compute avg flush
	pattern=".*Avg flush: *${f} .*"
	extract4avg tsos pattern 1
	FLUSH=`./averager.sh $numfile`

	pattern=".*Avg write: *${f} .*"
	extract4avg tsos pattern 1
	WRITE=`./averager.sh $numfile`

	totflushpattern=".*Tot flushes: *${f} .*"
	extract4avg tsos totflushpattern 1
	NFLUSHES=`./averager.sh $numfile`

	totemptyflushpattern=".*Tot empty flu: *${f} .*"
	extract4avg tsos totemptyflushpattern 1
	NEMPTY_FLUSHES=`./averager.sh $numfile`

	# Empty flushes / Total flushes
	flushemptyflushpattern="${totflushpattern}${totemptyflushpattern}"
	extractTwo4avg tsos flushemptyflushpattern 1 2
	cat $numfile | awk '{if ($1 > 0) print ($2 / $1) * 100}' > $swpfile
	mv $swpfile $numfile
	NEMPTY_OVER_TOTAL_FLUSHES=`./averager.sh $numfile`


	echo $TPS $GTPS $ABORT $GABORT $FLUSH $WRITE $NFLUSHES $NEMPTY_FLUSHES $NEMPTY_OVER_TOTAL_FLUSHES
	echo TPS GTPS ABORT GABORT FLUSH WRITE NFLUSHES NEMPTY_FLUSHES NEMPTY_OVER_TOTAL_FLUSHES > analyzedHeader.txt

}


cutsar() {
	INF=$1
	S=`grep --text CPU -n -m 1 $INF | tail -1 | cut -d':' -f 1`
	E=`grep --text CPU -n -m 2 $INF | tail -1 | cut -d':' -f 1`
	NLINE=$((E-S))

#which part of the log should be used (in seconds)
#DISCARDPERIOD=20
#USEDPERIOD=60
#d1=`grep --text CPU -m 1 $INF | tail -1 | cut -d' ' -f 1`
#d1=`date --utc --date "$d1" +%s`
#d2=`grep --text CPU -m 2 $INF | tail -1 | cut -d' ' -f 1`
#d2=`date --utc --date "$d2" +%s`
#PRINTPERIOD=$((d2-d1))

	lines=`grep --text CPU $INF | wc -l`
	cuthead=$((cutheadpercent * lines / 100))
	pickhead=$((pickheadpercent * lines / 100))
	NOUTPUT=$((pickhead+cuthead))

	grep --text CPU $INF -m $NOUTPUT -A$NLINE | tail -$((pickhead*NLINE)) >> $OUTF
}

extractsar() {
	#extract cpu usage
	#01:58:59 AM       all      4.72      0.00      2.10      0.00      0.00     93.18
	cat $OUTF | grep --text CPU -A1 | grep all | awk '{print $4}' >> $CPUF

	#extract io info
	#01:58:49 AM       tps      rtps      wtps   bread/s   bwrtn/s
	#01:58:59 AM      6.47      0.00      6.47      0.00     76.46
	cat $OUTF | grep --text bread -A1 | grep -v bread | grep -v "\-\-" | awk '{print $4}' >> $ROF
	cat $OUTF | grep --text bread -A1 | grep -v bread | grep -v "\-\-" | awk '{print $5}' >> $WOF
	cat $OUTF | grep --text bread -A1 | grep -v bread | grep -v "\-\-" | awk '{print $6}' >> $RBF
	cat $OUTF | grep --text bread -A1 | grep -v bread | grep -v "\-\-" | awk '{print $7}' >> $WBF

	#extra sda info
	#10:44:39 PM       DEV       tps  rd_sec/s  wr_sec/s  avgrq-sz  avgqu-sz     await     svctm     %util
	#10:44:49 PM       sda      2.35      0.00     27.76     11.83      0.00      0.13      0.13      0.03
	cat $OUTF | grep --text "sda " | awk '{print $4}' >> $SDAF


	#extract net info
	#01:58:49 AM     IFACE   rxpck/s   txpck/s   rxbyt/s   txbyt/s   rxcmp/s   txcmp/s  rxmcst/s
	#01:58:59 AM        lo      0.00      0.00      0.00      0.00      0.00      0.00      0.00
	#01:58:59 AM      eth0   1055.09   1145.12 201141.73 355098.36      0.00      0.00      0.00
	#01:58:59 AM      eth1      0.00      0.00      0.00      0.00      0.00      0.00      0.00
	cat $OUTF | grep --text -A3 IFACE | grep eth0 | awk '{print $4}' >> $NROF
	cat $OUTF | grep --text -A3 IFACE | grep eth0 | awk '{print $5}' >> $NWOF
	cat $OUTF | grep --text -A3 IFACE | grep eth0 | awk '{print $6}' >> $NRBF
	cat $OUTF | grep --text -A3 IFACE | grep eth0 | awk '{print $7}' >> $NWBF
	cat $OUTF | grep --text -A3 IFACE | grep eth0 | awk '{print $7 / $5}' >> $WPKF
	cat $OUTF | grep --text -A3 IFACE | grep eth0 | awk '{print $6 / $4}' >> $RPKF
}

avgsar() {
	OUT=""
	OUT="$OUT `./averager.sh $CPUF`"
	OUT="$OUT `./averager.sh $WOF`"
	OUT="$OUT `./averager.sh $ROF`"
	OUT="$OUT `./averager.sh $WBF`"
	OUT="$OUT `./averager.sh $RBF`"
	OUT="$OUT `./averager.sh $NWOF`"
	OUT="$OUT `./averager.sh $NROF`"
	OUT="$OUT `./averager.sh $NWBF`"
	OUT="$OUT `./averager.sh $RPKF`"
	OUT="$OUT `./averager.sh $WPKF`"
	OUT="$OUT `./averager.sh $NRBF`"
	OUT="$OUT `./averager.sh $SDAF`"
	echo $OUT
}

#analyze the sar files of an experiment
analyzesar() {
FILES=$*

rm -f $OUTF $CPUF $WOF $ROF $WBF $RBF $NWOF $NROF $NWBF $NRBF $SDAF $WPKF $RPKF
for i in $FILES; do
	#cut the period related to the experiment
	cutsar $i
	#extract the related parameters
	extractsar
done
#do the average
avgsar
}
