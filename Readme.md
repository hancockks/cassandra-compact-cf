compactcf.sh
======================

A bash script working in conjunction with jmxterm to individually compact a Cassandra column family to reclaim
space used by tombstoned data.

### Background

Size-Tiered compaction strategy in Cassandra normally clears tombstones as part of the compaction process where multiple SSTables of similar size are merged into a new single SSTable.  In unsual circumstances, such as after load testing or running major compaction, few extremely large SSTables could be created. These tables would remain in place until a sufficient number of similar sized tables are created to trigger the compaction process. 

The default setting for min_compaction_threshold is four (4).  If any SSTable becomes larger than 1/4 of your available disk space, compaction will become impossible.

This script will use the JMX forceUserDefinedCompaction operation sequentially on each SSTable of a specified keyspace and column family.  If that column family utilizes TTL and the data is sufficiently old and has passed the configured gc_grace_seconds for that column family, the forceUserDefinedCompaction will be able to clear the tombstones and free up disk space.

### Requirements

o Tested only on CentOS and Apache Cassandra 1.21
o jxmterm jar placed in the same directory of the script.  See http://wiki.cyclopsgroup.org/jmxterm/
o nodetool in $PATH.  This is utilized for locating the cassandra.yaml file

### Usage
```
compactcf.sh

Usage: ./compactcf.sh compactcf KEYSPACE COLUMNN_FAMILY IP JMXPORT

Script will iterate over every SSTable in the column family and perform
a manual compaction, removing tombstoned data that has exceeded gc_grace_seconds.

Example: compactcf MyKeyspace Standard1 10.10.10.1 7199
```

### Sample

In the below example, we have a keyspace that uses a TTL of 30 days.  As of October 1, there are SSTables that contain only old expired data.

```
[cassandra@cassandra1 ~]$ ls -l /var/data/cassandra/data/SampleKS/Standard1/*-Data.db

-rw-r--r-- 1 cassandra cassandra 97752242 Aug 13 09:51 /var/data/cassandra/data/SampleKS/Standard1/SampleKS-Standard1-ic-22-Data.db
-rw-r--r-- 1 cassandra cassandra 63108640 Aug 13 13:34 /var/data/cassandra/data/SampleKS/Standard1/SampleKS-Standard1-ic-27-Data.db
-rw-r--r-- 1 cassandra cassandra 12142340 Aug 26 09:02 /var/data/cassandra/data/SampleKS/Standard1/SampleKS-Standard1-ic-32-Data.db
-rw-r--r-- 1 cassandra cassandra     1196 Sep  3 09:47 /var/data/cassandra/data/SampleKS/Standard1/SampleKS-Standard1-ic-33-Data.db

[cassandra@cassandra1 ~]$ compactcf.sh SampleKS Standard1 192.168.210.234 11000

Processing directory /var/data/cassandra/data/
Compacting SampleKS-Standard1-ic-22-Data.db
Welcome to JMX terminal. Type "help" for available commands.
$>run -b org.apache.cassandra.db:type=CompactionManager forceUserDefinedCompaction SampleKS SampleKS-Standard1-ic-22-Data.db
#calling operation forceUserDefinedCompaction of mbean org.apache.cassandra.db:type=CompactionManager
#operation returns:
null
$>Compacting SampleKS-Standard1-ic-27-Data.db
Welcome to JMX terminal. Type "help" for available commands.
$>run -b org.apache.cassandra.db:type=CompactionManager forceUserDefinedCompaction SampleKS SampleKS-Standard1-ic-27-Data.db
#calling operation forceUserDefinedCompaction of mbean org.apache.cassandra.db:type=CompactionManager
#operation returns:
null
$>Compacting SampleKS-Standard1-ic-32-Data.db
Welcome to JMX terminal. Type "help" for available commands.
$>run -b org.apache.cassandra.db:type=CompactionManager forceUserDefinedCompaction SampleKS SampleKS-Standard1-ic-32-Data.db
#calling operation forceUserDefinedCompaction of mbean org.apache.cassandra.db:type=CompactionManager
#operation returns:
null
$>Compacting SampleKS-Standard1-ic-33-Data.db
Welcome to JMX terminal. Type "help" for available commands.
$>run -b org.apache.cassandra.db:type=CompactionManager forceUserDefinedCompaction SampleKS SampleKS-Standard1-ic-33-Data.db
#calling operation forceUserDefinedCompaction of mbean org.apache.cassandra.db:type=CompactionManager
#operation returns:
null
$>Processing directory /var/data/cassandra/data2/

[cassandra@cassandra1 ~]$ ls -l /var/data/cassandra/data/SampleKS/Standard1/*-Data.db

-rw-r--r-- 1 cassandra cassandra 1196 Oct  1 11:59 /var/data/cassandra/data/SampleKS/Standard1/SampleKS-Standard1-ic-37-Data.db
```