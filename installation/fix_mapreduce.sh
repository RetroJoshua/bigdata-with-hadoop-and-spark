#!/bin/bash

# Script to fix MapReduce configuration
# Save as fix_mapreduce.sh

# Color codes for output
GREEN='\033[0;32m'
NC='\033[0m'

HADOOP_HOME=/usr/local/hadoop

echo "Updating mapred-site.xml configuration..."

# Create updated mapred-site.xml
cat > $HADOOP_HOME/etc/hadoop/mapred-site.xml << EOL
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>\$HADOOP_HOME/share/hadoop/mapreduce/*:\$HADOOP_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>
    <property>
        <name>yarn.app.mapreduce.am.env</name>
        <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
    </property>
    <property>
        <name>mapreduce.map.env</name>
        <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
    </property>
    <property>
        <name>mapreduce.reduce.env</name>
        <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
    </property>
</configuration>
EOL

echo -e "${GREEN}Configuration updated successfully${NC}"
echo "Please follow these steps:"
echo "1. Stop all Hadoop services:"
echo "   $HADOOP_HOME/sbin/stop-all.sh"
echo "2. Start all Hadoop services:"
echo "   $HADOOP_HOME/sbin/start-all.sh"
echo "3. Start the History Server:"
echo "   $HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver"
echo "4. Try running the WordCount example again:"
echo "   hadoop jar \$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /test /output"
