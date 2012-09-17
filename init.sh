# Do the following to prepare the scripts for running

echo This will initialize the folder. Enter to continue; read

echo Have you updated the env.sh file?
echo OK?; read

# update BASE, JAVA_HOME in env.sh, and perhaps other variables
source env.sh; echo Is this your BASE ? $BASE
echo OK?; read
ls -d $JAVA_HOME
source env.sh; echo Is this your JAVA_HOME ? $JAVA_HOME
echo OK?; read

# copy the omid directory here, the default name in scripts is crcimbo
ls -d crcimbo
echo OK?; read

# download hadoop-1.0.3
wget http://www.us.apache.org/dist/hadoop/common/hadoop-1.0.3/hadoop-1.0.3.tar.gz
tar -xzf hadoop-1.0.3.tar.gz
ls -l hdfs
echo OK?; read

# download hbase-0.94.1
wget http://www.us.apache.org/dist/hbase/hbase-0.94.1/hbase-0.94.1.tar.gz
tar -xzf hbase-0.94.1.tar.gz
ls -l hbase
echo OK?; read

# update the config files
cp backupconf/hdfs/conf/hadoop-env.sh hdfs/conf/hadoop-env.sh
cp backupconf/hdfs/conf/hdfs-site.xml hdfs/conf/hdfs-site.xml
cp backupconf/hbase/conf/hbase-env.sh hbase/conf/hbase-env.sh
cp backupconf/hbase/conf/hbase-site.xml hbase/conf/hbase-site.xml
cd hbase/conf
ln -sf ../../hdfs/conf/slaves regionservers
cd -
bin/preparehbase.sh
echo OK?; read

# download the modified YCSB to benchmarks folder
cd benchmarks
git clone git://github.com/maysamyabandeh/YCSB.git
cd YCSB
git checkout txnycsb
cd ../..
ls -d benchmarks/YCSB
echo OK?; read

# create lib link
source bin/util.sh; linkapp crcimbo

# compile YCSB
cd benchmarks/YCSB
make
cd -
echo OK?; read

# clean the cluster
source ./bin/util.sh; clean_cluster
echo OK?; read

# start the cluster
./bin/do.sh start-cluster crcimbo
source env.sh; echo hdfs web access: http://$HDFSMASTER:52070/dfshealth.jsp
source env.sh; echo hbase web access: http://$HDFSMASTER:52070/dfshealth.jsp
echo OK?; read

# load some initial data
./bin/do.sh load-data hdfsZero 30000 1 1
echo OK?; read

# run a test
./bin/test.sh
echo OK?; read


