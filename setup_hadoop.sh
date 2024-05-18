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

# Step 3: Install SSH
echo "Installing SSH..."
sudo apt install -y ssh

# Step 4: Configure SSH if not already configured
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Configuring SSH..."
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    chmod 640 ~/.ssh/authorized_keys
else
    echo "SSH is already configured."
fi

# Step 5: SSH to the localhost
echo "Testing SSH to localhost..."
ssh -o StrictHostKeyChecking=no localhost exit

# Step 6: Download and install Hadoop if not already downloaded
if [ ! -d /etc/hadoop ]; then
    echo "Downloading and installing Hadoop..."
    wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
    tar -xvzf hadoop-3.3.6.tar.gz
    sudo mv hadoop-3.3.6 /etc/hadoop
else
    echo "Hadoop is already installed."
fi

# Step 7: Configure environment variables
echo "Configuring environment variables..."
cat <<EOL >> ~/.bashrc
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/etc/hadoop
export HADOOP_INSTALL=\$HADOOP_HOME
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export HADOOP_YARN_HOME=\$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native
export PATH=\$PATH:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin
export HADOOP_OPTS="-Djava.library.path=\$HADOOP_HOME/lib/native"
EOL

# Source the updated ~/.bashrc to apply environment variables
source ~/.bashrc

# Configure JAVA_HOME in hadoop-env.sh
echo "Configuring JAVA_HOME in hadoop-env.sh..."
sudo sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64:' /etc/hadoop/etc/hadoop/hadoop-env.sh

# Step 8: Configuring Hadoop
echo "Configuring Hadoop directories..."
mkdir -p ~/hadoopdata/hdfs/{namenode,datanode}

# Edit core-site.xml
echo "Editing core-site.xml..."
sudo tee /etc/hadoop/etc/hadoop/core-site.xml > /dev/null <<EOL
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOL

# Edit hdfs-site.xml
echo "Editing hdfs-site.xml..."
sudo tee /etc/hadoop/etc/hadoop/hdfs-site.xml > /dev/null <<EOL
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:///home/$USER/hadoopdata/hdfs/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:///home/$USER/hadoopdata/hdfs/datanode</value>
    </property>
</configuration>
EOL

# Edit mapred-site.xml
echo "Editing mapred-site.xml..."
sudo tee /etc/hadoop/etc/hadoop/mapred-site.xml > /dev/null <<EOL
<configuration>
    <property>
        <name>yarn.app.mapreduce.am.env</name>
        <value>HADOOP_MAPRED_HOME=\$HADOOP_HOME/home/$USER/hadoop/bin/hadoop</value>
    </property>
    <property>
        <name>mapreduce.map.env</name>
        <value>HADOOP_MAPRED_HOME=\$HADOOP_HOME/home/$USER/hadoop/bin/hadoop</value>
    </property>
    <property>
        <name>mapreduce.reduce.env</name>
        <value>HADOOP_MAPRED_HOME=\$HADOOP_HOME/home/$USER/hadoop/bin/hadoop</value>
    </property>
</configuration>
EOL

# Edit yarn-site.xml
echo "Editing yarn-site.xml..."
sudo tee /etc/hadoop/etc/hadoop/yarn-site.xml > /dev/null <<EOL
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
</configuration>
EOL

# Step 9: Start Hadoop Cluster
echo "Formatting Namenode..."
hdfs namenode -format

echo "Starting Hadoop Cluster..."
start-all.sh

echo "Checking Hadoop services status..."
jps
