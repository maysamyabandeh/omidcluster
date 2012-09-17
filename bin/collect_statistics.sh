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

DIR=`dirname $0`

source $DIR/../env.sh

mkdir -p $STATS

sar 10 0 -P ALL -u -b -d -n DEV -p > ${STATS}/sar_statistics.log 2>&1 &
#vmstat -n 2 > $DIR/vmstat.log &
#vmstat -n -d 2 > $DIR/vmstat-d.log &
#iostat -d -t 2 > $DIR/iostat.log &
#iostat -d -t -x 2 > $DIR/iostat-x.log &
