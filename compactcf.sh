
#!/usr/bin/env bash

function print_usage
{
cat << EOF

Usage: $0 compactcf KEYSPACE COLUMNN_FAMILY IP JMXPORT

Script will iterate over every SSTable in the column family and perform
a manual compaction, removing tombstoned data that has exceeded gc_grace_seconds.

Example: compactcf MyKeyspace Standard1 10.10.10.1 7199

EOF
}

if [[ "$#" -ne 4 ]]; then
        print_usage
        exit 1
fi

KEYSPACE=$1
shift
CF=$1
shift
IP=$1
shift
JMXPORT=$1
shift

YAML=$(which nodetool)
if [[ "$YAML" =~ "not found" ]]; then
	echo 'nodetool not found in $PATH'
	exit 1
fi


YAML=${YAML%/*}/../conf/cassandra.yaml
DIRS=( $(awk '/^data_file_directories:/{capture=1;next}/^$/{capture=0}capture' /seachange/local/apache-cassandra-latest/conf/cassandra.yaml) )

shopt -s nullglob
for i in "${DIRS[@]}"; do
	if [[ ! "$i" =~ "-" ]]; then
		echo "Processing directory $i/"
		SSTABLES=( "${i}/$KEYSPACE/$CF/"*"-Data.db" )
		for f in "${SSTABLES[@]}"; do
			echo "Compacting $(basename $f)"
			echo "run -b org.apache.cassandra.db:type=CompactionManager forceUserDefinedCompaction $KEYSPACE $(basename $f)" | java -jar jmxterm-1.0-alpha-4-uber.jar -l $IP:$JMXPORT
		done
	fi
done
