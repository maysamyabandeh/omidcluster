OmidCluster
=====

This project provides scripts to run Omid (https://github.com/yahoo/omid) against a cluster of machines.
The scripts are tested under both Linux and Mac, but sometimes require some manutall attention to make it work.
The purpose is to make it easier for the researchers to run Omid against YCSB (or other) benchmarks.

Contributors
------------
Daniel Gomez Ferro

Ivan Kelly

Maysam Yabandeh


Architecture
------------


Configure
-----------
   * Update BASE and JAVA_HOME in env.sh

   * Read bin/init.sh which tells you what you need to do to run a test. If you are comfortable with the current
status, simply run it and it will walk you through the changes.

   * The scrip run a test on localhost, you can then configure it for your own cluster

   * Update env.sh, machines.txt, hdfs/conf/slaves

   * run bin/preparehbase.sh to propagate the changes into other conf files


Running
-------

