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

#propagate the changes of env.sh into hdfs and hbase conf files

l=`grep -n "name.*zk" ./crcimbo/conf/omid-site.xml -A2 | grep value | head -1 | cut -d- -f1`
if [[ ! -z $l ]]; then
	sed -e "${l}s/\(<value>\).*\(<.value>\)/\1${ZKSERVERLIST}\2/" -i '' ./crcimbo/conf/omid-site.xml
fi

hadoopjar=$BASE/hbase/lib/hadoop-core*jar
echo The is your hbase hadoop jar file: $hadoopjar
echo make sure it matches the ones that hdfs uses

echo $HDFSMASTER > $BASE/hdfs/conf/masters

l=`grep -n "fs.default.name" hdfs/conf/hdfs-site.xml -A2 | grep value | head -1 | cut -d- -f1`
if [[ ! -z $l ]]; then
	sed -e "${l}s/\(<value>hdfs:..\).*\(:[0-9][0-9]*<.value>\)/\1$HDFSMASTER\2/" -i '' hdfs/conf/hdfs-site.xml
fi
l=`grep -n "dfs.http.address" hdfs/conf/hdfs-site.xml -A2 | grep value | head -1 | cut -d- -f1`
if [[ ! -z $l ]]; then
	sed -e "${l}s/\(<value>\).*\(:[0-9][0-9]*<.value>\)/\1$HDFSMASTER\2/" -i '' hdfs/conf/hdfs-site.xml
fi
l=`grep -n "dfs.secondary.http.address" hdfs/conf/hdfs-site.xml -A2 | grep value | head -1 | cut -d- -f1`
if [[ ! -z $l ]]; then
	sed -e "${l}s/\(<value>\).*\(:[0-9][0-9]*<.value>\)/\1$HDFSMASTER\2/" -i '' hdfs/conf/hdfs-site.xml
fi
#replace space with , and append name, and then replace \ to feed to sed
ALLHDFSDIRS=`echo $HDFSDIR | sed 's/ /\/name,/g' | sed 's/$/\/name/g' | sed 's/\//\\\\\//g'`
l=`grep -n "dfs.name.dir" hdfs/conf/hdfs-site.xml -A2 | grep value | head -1 | cut -d- -f1`
if [[ ! -z $l ]]; then
	sed -e "${l}s/\(<value>\).*\(<.value>\)/\1${ALLHDFSDIRS}\2/" -i '' hdfs/conf/hdfs-site.xml
fi
#replace space with , and append data, and then replace \ to feed to sed
ALLHDFSDIRS=`echo $HDFSDIR | sed 's/ /\/data,/g' | sed 's/$/\/data/g' | sed 's/\//\\\\\//g'`
l=`grep -n "dfs.data.dir" hdfs/conf/hdfs-site.xml -A2 | grep value | head -1 | cut -d- -f1`
if [[ ! -z $l ]]; then
	sed -e "${l}s/\(<value>\).*\(<.value>\)/\1${ALLHDFSDIRS}\2/" -i '' hdfs/conf/hdfs-site.xml
fi

l=`grep -n "fs.default.name" ./hdfs/conf/core-site.xml -A2 | grep value | head -1 | cut -d- -f1`
if [[ ! -z $l ]]; then
	sed -e "${l}s/\(<value>hdfs:..\).*\(:.*<.value>\)/\1${HDFSMASTER}\2/" -i '' ./hdfs/conf/core-site.xml
fi

l=`grep -n "tso.host" ./hbase/conf/hbase-site.xml -A2 | grep value | head -1 | cut -d- -f1`
if [[ ! -z $l ]]; then
	sed -e "${l}s/\(<value>\).*\(<.value>\)/\1${TSOSERVER0}\2/" -i '' ./hbase/conf/hbase-site.xml
fi
l=`grep -n "hbase.rootdir" ./hbase/conf/hbase-site.xml -A2 | grep value | head -1 | cut -d- -f1`
if [[ ! -z $l ]]; then
	sed -e "${l}s/\(<value>hdfs:..\).*\(:.*<.value>\)/\1${HDFSMASTER}\2/" -i '' ./hbase/conf/hbase-site.xml
fi
l=`grep -n "hbase.zookeeper.quorum" ./hbase/conf/hbase-site.xml -A2 | grep value | head -1 | cut -d- -f1`
if [[ ! -z $l ]]; then
	sed -e "${l}s/\(<value>\).*\(<.value>\)/\1${ZKSERVER}\2/" -i '' ./hbase/conf/hbase-site.xml
fi

