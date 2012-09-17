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

source `dirname $0`/../env.sh
CONF=`dirname $0`/zoo-standalone.cfg
sed -e "/dataDir=.*/d" -i ' ' $CONF
echo "dataDir=$ZKDATADIR" >> $CONF
rm -rf $ZKDATADIR

echo "Going to start..."
CLASSPATH=`dirname $0`
for j in $BASE/lib/*.jar; do
    CLASSPATH=$CLASSPATH:$j
done
java -cp $CLASSPATH -Dlogdir="$STATS" -Dlog4j.configuration=log4j.properties org.apache.zookeeper.server.quorum.QuorumPeerMain $CONF &

echo  "Started..."
