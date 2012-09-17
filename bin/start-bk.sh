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

ZKCLI=$BASE/zk/zkCli.sh
BOOKIE=$BASE/bookie/run-bookie.sh

echo "Clearing bookies ..."
./bookie/clean-all-bookies.sh

$ZKCLI -server $ZKSERVERLIST create /ledgers b ; 
$ZKCLI -server $ZKSERVERLIST create /ledgers/available b ;

until [[ $BKSERVER = $BKSERVERLIST ]]
do
	BKSERVER=${BKSERVERLIST%%:*}
	BKSERVERLIST=${BKSERVERLIST#*:}
	ssh -f $BKSERVER "$BOOKIE" ;
done

