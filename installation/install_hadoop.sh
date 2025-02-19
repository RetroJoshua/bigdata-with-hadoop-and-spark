#!/bin/bash

# Hadoop Installation Script for Ubuntu (Standalone Mode)

echo "Starting Hadoop Installation..."

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Set variables
HADOOP_VERSION="3.3.6"
USERNAME=$(logname)  # Get the actual username of the user who ran sudo

echo "1. Updating System Packages..."
apt update

echo "2. Installing Java..."
apt install openjdk-8-jdk -y

echo "3. Verifying Java Installation..."
java -version

echo "4. Downloading Hadoop..."
wget "https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"

echo "5. Extracting Hadoop and Setting Permissions..."
tar -xzvf "hadoop-${HADOOP_VERSION}.tar.gz" -C /usr/local
mv "/usr/local/hadoop-${HADOOP_VERSION}" /usr/local/hadoop
chown -R "$USERNAME:$USERNAME" /usr/local/hadoop

echo "6. Setting Environment Variables..."
# Create backup of .bashrc
cp "/home/$USERNAME/.bashrc" "/home/$USERNAME/.bashrc.backup"

# Add environment variables to .bashrc
cat >> "/home/$USERNAME/.bashrc" << EOL

# Hadoop Environment Variables
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/usr/local/hadoop
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
EOL

echo "7. Configuring hadoop-env.sh..."
# Update JAVA_HOME in hadoop-env.sh
sed -i 's|^# export JAVA_HOME=.*|export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64|' /usr/local/hadoop/etc/hadoop/hadoop-env.sh

echo "8. Setting up test environment..."
# Create test directories and files
su - "$USERNAME" << 'EOF'
mkdir ~/input
echo "Hello World" > ~/input/file1.txt
echo "Hello Hadoop" > ~/input/file2.txt
EOF

echo "Cleaning up..."
rm "hadoop-${HADOOP_VERSION}.tar.gz"

echo "Installation completed!"
echo "Please run the following commands to complete setup:"
echo "1. source ~/.bashrc"
echo "2. hadoop jar \$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-${HADOOP_VERSION}.jar wordcount ~/input ~/output"
echo "3. cat ~/output/*"
