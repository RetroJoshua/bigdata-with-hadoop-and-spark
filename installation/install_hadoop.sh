#!/bin/bash

# Comprehensive Hadoop Installation and Configuration Script
# This script combines installation, SSH configuration, and service setup

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] $1${NC}"
    else
        echo -e "${RED}[✗] $1${NC}"
        echo -e "${YELLOW}Error occurred. Please check the installation.${NC}"
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Set variables
HADOOP_VERSION="3.3.6"
USERNAME=$(logname)
HADOOP_HOME=/usr/local/hadoop
HADOOP_DATA=/usr/local/hadoop/data

echo "=== Comprehensive Hadoop Installation and Configuration Script ==="
echo "Starting installation process..."

### PART 1: BASIC INSTALLATION ###
echo -e "\n${YELLOW}PART 1: Basic Installation${NC}"

echo "1. Updating System Packages..."
apt update && apt upgrade -y
print_status "System update completed"

echo "2. Installing Java and SSH..."
apt install openjdk-8-jdk openssh-server openssh-client -y
print_status "Java and SSH installation completed"

echo "3. Verifying Java Installation..."
java -version
print_status "Java verification completed"

echo "4. Downloading Hadoop..."
wget "https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
print_status "Hadoop download completed"

echo "5. Extracting Hadoop..."
tar -xzvf "hadoop-${HADOOP_VERSION}.tar.gz" -C /usr/local
mv "/usr/local/hadoop-${HADOOP_VERSION}" /usr/local/hadoop
chown -R "$USERNAME:$USERNAME" /usr/local/hadoop
print_status "Hadoop extraction completed"

### PART 2: SSH CONFIGURATION ###
echo -e "\n${YELLOW}PART 2: SSH Configuration${NC}"

echo "6. Configuring SSH..."
# Stop SSH service
service ssh stop

# Configure SSH for the user
su - "$USERNAME" << 'EOF'
# Clean up existing SSH configurations
rm -rf ~/.ssh/*

# Create .ssh directory with correct permissions
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate new SSH key pair without passphrase
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa

# Configure authorized_keys
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 640 ~/.ssh/authorized_keys
EOF

# Configure SSH server
cat > /etc/ssh/sshd_config << EOL
PermitRootLogin yes
PubkeyAuthentication yes
RSAAuthentication yes
PasswordAuthentication yes
EOL

# Restart SSH service
service ssh restart
print_status "SSH configuration completed"

### PART 3: HADOOP CONFIGURATION ###
echo -e "\n${YELLOW}PART 3: Hadoop Configuration${NC}"

echo "7. Setting up Hadoop environment..."
# Create backup of .bashrc
cp "/home/$USERNAME/.bashrc" "/home/$USERNAME/.bashrc.backup"

# Add environment variables to .bashrc
cat >> "/home/$USERNAME/.bashrc" << EOL

# Hadoop Environment Variables
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/usr/local/hadoop
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export YARN_HOME=\$HADOOP_HOME
EOL

# Update hadoop-env.sh
sed -i 's|^# export JAVA_HOME=.*|export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64|' $HADOOP_HOME/etc/hadoop/hadoop-env.sh

echo "8. Creating Hadoop directories..."
mkdir -p $HADOOP_DATA/{namenode,datanode,tmp}
chown -R $USERNAME:$USERNAME $HADOOP_DATA

echo "9. Configuring Hadoop files..."
# Configure core-site.xml
cat > $HADOOP_HOME/etc/hadoop/core-site.xml << EOL
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>$HADOOP_DATA/tmp</value>
    </property>
</configuration>
EOL

# Configure hdfs-site.xml
cat > $HADOOP_HOME/etc/hadoop/hdfs-site.xml << EOL
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>$HADOOP_DATA/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>$HADOOP_DATA/datanode</value>
    </property>
</configuration>
EOL

# Configure mapred-site.xml
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
</configuration>
EOL

# Configure yarn-site.xml
cat > $HADOOP_HOME/etc/hadoop/yarn-site.xml << EOL
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>
    </property>
</configuration>
EOL

print_status "Hadoop configuration completed"

echo "10. Setting permissions..."
chown -R $USERNAME:$USERNAME $HADOOP_HOME
chmod -R 755 $HADOOP_HOME
print_status "Permissions set"

echo "11. Formatting HDFS..."
su - $USERNAME -c "hdfs namenode -format"
print_status "HDFS formatted"

# Cleanup
echo "12. Cleaning up..."
rm "hadoop-${HADOOP_VERSION}.tar.gz"
print_status "Cleanup completed"

echo -e "\n${GREEN}Installation and Configuration Completed!${NC}"
echo -e "\n${YELLOW}Please follow these steps to complete the setup:${NC}"
echo "1. Log out and log back in, or run: source ~/.bashrc"
echo "2. Start Hadoop services:"
echo "   $HADOOP_HOME/sbin/start-all.sh"
echo "3. Start History Server:"
echo "   $HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver"
echo "4. Verify services are running:"
echo "   jps"
echo -e "\n${YELLOW}Expected services:${NC}"
echo "- NameNode"
echo "- DataNode"
echo "- ResourceManager"
echo "- NodeManager"
echo "- JobHistoryServer"
echo "- Jps"

echo -e "\n${YELLOW}To test the installation:${NC}"
echo "1. Create a test directory in HDFS:"
echo "   hdfs dfs -mkdir /test"
echo "2. List HDFS directories:"
echo "   hdfs dfs -ls /"
echo "3. Run the wordcount example:"
echo "   hadoop jar \$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-${HADOOP_VERSION}.jar wordcount /test /output"

echo -e "\n${YELLOW}To stop all services:${NC}"
echo "$HADOOP_HOME/sbin/stop-all.sh"
