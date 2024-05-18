#!/bin/bash

# Step 1: Install JDK if not installed already
if ! java -version &>/dev/null; then
    echo "Installing JDK..."
    sudo apt update && sudo apt install -y openjdk-8-jdk
else
    echo "JDK is already installed."
fi

# Step 2: Verify the Java version
java -version

# Step 3: Install prerequisites
echo "Installing prerequisites..."
sudo apt install -y wget

# Step 4: Download and install Hive
HIVE_VERSION=3.1.3
HIVE_HOME=/opt/hive

if [ ! -d "$HIVE_HOME" ]; then
    echo "Downloading and installing Hive..."
    wget https://dlcdn.apache.org/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz
    sudo tar -xvzf apache-hive-$HIVE_VERSION-bin.tar.gz -C /opt
    sudo mv /opt/apache-hive-$HIVE_VERSION-bin $HIVE_HOME
else
    echo "Hive is already installed."
fi

# Step 5: Configure environment variables for Hive
echo "Configuring environment variables for Hive..."
cat <<EOL >> ~/.bashrc
export HIVE_HOME=$HIVE_HOME
export PATH=\$PATH:\$HIVE_HOME/bin
EOL

# Source the updated ~/.bashrc to apply environment variables
source ~/.bashrc

# Step 6: Configure Hive
echo "Configuring Hive..."
sudo tee $HIVE_HOME/conf/hive-env.sh > /dev/null <<EOL
export HADOOP_HOME=$HADOOP_HOME
export HIVE_HOME=$HIVE_HOME
export JAVA_HOME=$JAVA_HOME
EOL

# Step 7: Create Hive directories in HDFS
echo "Creating Hive directories in HDFS..."
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -mkdir -p /tmp
hdfs dfs -chmod g+w /user/hive/warehouse
hdfs dfs -chmod g+w /tmp

# Step 8: Configure Hive metastore
echo "Configuring Hive metastore..."
sudo tee $HIVE_HOME/conf/hive-site.xml > /dev/null <<EOL
<configuration>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:derby:;databaseName=metastore_db;create=true</value>
        <description>JDBC connect string for a JDBC metastore</description>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>org.apache.derby.jdbc.EmbeddedDriver</value>
        <description>Driver class name for a JDBC metastore</description>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>APP</value>
        <description>Username to use against metastore database</description>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>mine</value>
        <description>Password to use against metastore database</description>
    </property>
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>/user/hive/warehouse</value>
        <description>location of default database for the warehouse</description>
    </property>
    <property>
        <name>hive.exec.scratchdir</name>
        <value>/tmp/hive</value>
        <description>HDFS root scratch dir for Hive jobs</description>
    </property>
    <property>
        <name>hive.exec.local.scratchdir</name>
        <value>/tmp/hive</value>
        <description>Local scratch space for Hive jobs</description>
    </property>
    <property>
        <name>hive.metastore.schema.verification</name>
        <value>false</value>
        <description>Enforce metastore schema version consistency</description>
    </property>
    <property>
        <name>hive.metastore.schema.verification.record.version</name>
        <value>true</value>
        <description>Record the schema version in the metastore</description>
    </property>
</configuration>
EOL

# Source the environment variables explicitly within the script
export HIVE_HOME=$HIVE_HOME
export PATH=$PATH:$HIVE_HOME/bin

# Step 9: Initialize Hive schema
echo "Initializing Hive schema..."
schematool -dbType derby -initSchema

# Step 10: Start Hive
echo "Starting Hive..."
nohup hive --service metastore &
nohup hive --service hiveserver2 &

echo "Hive installation and configuration completed."
