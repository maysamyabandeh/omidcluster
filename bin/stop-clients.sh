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

for machine in `cat machines.txt`; do
	ssh $machine "pkill -u $user sar; pkill -u $user sadc; pkill -f -u $user '^[^ ]*java.*com.yahoo.ycsb.Client'" &
done

sleep 1

killpid=
for machine in `cat machines.txt`; do
	ssh $machine "pkill -9 -f -u $user '^[^ ]*java.*com.yahoo.ycsb.Client'" &
done
echo waiting for pkills in $0 ...
wait $killpid
