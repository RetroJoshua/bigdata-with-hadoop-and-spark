#!/bin/bash

# Comprehensive Hadoop Verification Script
# This script verifies all aspects of the Hadoop installation

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
HADOOP_HOME=/usr/local/hadoop
HADOOP_DATA=/usr/local/hadoop/data

# Function to print status
print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] $1${NC}"
    else
        echo -e "${RED}[✗] $1${NC}"
        echo -e "${YELLOW}Error details: $2${NC}"
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check file/directory existence and permissions
check_permissions() {
    local path=$1
    local expected_perm=$2
    local type=$3
    
    if [ -e "$path" ]; then
        actual_perm=$(stat -c %a "$path")
        if [ "$actual_perm" = "$expected_perm" ]; then
            print_status "$type permissions are correct ($expected_perm)" ""
        else
            print_status "$type permissions are incorrect" "Expected: $expected_perm, Got: $actual_perm"
        fi
    else
        print_status "$type does not exist" "Path: $path"
    fi
}

echo "=== Comprehensive Hadoop Installation Verification ==="
echo "Starting verification process..."

### PART 1: SYSTEM REQUIREMENTS ###
echo -e "\n${YELLOW}1. Verifying System Requirements${NC}"

# Check Java
echo "Checking Java installation..."
if command_exists java; then
    java_version=$(java -version 2>&1 | head -n 1)
    print_status "Java is installed" "$java_version"
else
    print_status "Java is not installed" "Please install Java"
fi

# Check JAVA_HOME
echo "Checking JAVA_HOME..."
if [ -n "$JAVA_HOME" ]; then
    print_status "JAVA_HOME is set" "$JAVA_HOME"
else
    print_status "JAVA_HOME is not set" "Environment variable missing"
fi

### PART 2: SSH CONFIGURATION ###
echo -e "\n${YELLOW}2. Verifying SSH Configuration${NC}"

# Check SSH installation
echo "Checking SSH installation..."
if command_exists ssh; then
    print_status "SSH is installed" ""
else
    print_status "SSH is not installed" "Please install SSH"
fi

# Check SSH directory and files
echo "Checking SSH directory structure..."
check_permissions ~/.ssh "700" "SSH directory"
check_permissions ~/.ssh/id_rsa "600" "SSH private key"
check_permissions ~/.ssh/id_rsa.pub "644" "SSH public key"
check_permissions ~/.ssh/authorized_keys "640" "SSH authorized_keys"

# Test SSH connection
echo "Testing SSH connection..."
if ssh -o BatchMode=yes localhost exit 2>/dev/null; then
    print_status "SSH passwordless authentication" "Working correctly"
else
    print_status "SSH passwordless authentication" "Failed"
fi

### PART 3: HADOOP INSTALLATION ###
echo -e "\n${YELLOW}3. Verifying Hadoop Installation${NC}"

# Check Hadoop installation
echo "Checking Hadoop installation..."
if [ -d "$HADOOP_HOME" ]; then
    print_status "Hadoop is installed" "Location: $HADOOP_HOME"
else
    print_status "Hadoop is not installed" "HADOOP_HOME not found"
fi

# Check Hadoop environment variables
echo "Checking Hadoop environment variables..."
for var in HADOOP_HOME HADOOP_MAPRED_HOME HADOOP_COMMON_HOME HADOOP_HDFS_HOME YARN_HOME
do
    if [ -n "${!var}" ]; then
        print_status "$var is set" "${!var}"
    else
        print_status "$var is not set" "Environment variable missing"
    fi
done

### PART 4: HADOOP CONFIGURATION ###
echo -e "\n${YELLOW}4. Verifying Hadoop Configuration${NC}"

# Check configuration files
echo "Checking configuration files..."
config_files=("core-site.xml" "hdfs-site.xml" "mapred-site.xml" "yarn-site.xml" "hadoop-env.sh")
for file in "${config_files[@]}"
do
    if [ -f "$HADOOP_HOME/etc/hadoop/$file" ]; then
        print_status "$file exists" ""
    else
        print_status "$file is missing" "File not found in $HADOOP_HOME/etc/hadoop/"
    fi
done

# Check Hadoop directories
echo "Checking Hadoop directories..."
directories=("$HADOOP_DATA/namenode" "$HADOOP_DATA/datanode" "$HADOOP_DATA/tmp")
for dir in "${directories[@]}"
do
    if [ -d "$dir" ]; then
        print_status "Directory exists: $dir" ""
    else
        print_status "Directory missing: $dir" "Required directory not found"
    fi
done

### PART 5: HADOOP SERVICES ###
echo -e "\n${YELLOW}5. Verifying Hadoop Services${NC}"

# Check running services
echo "Checking running Hadoop services..."
services=("NameNode" "DataNode" "ResourceManager" "NodeManager" "JobHistoryServer")
running_processes=$(jps | awk '{print $2}')

for service in "${services[@]}"
do
    if echo "$running_processes" | grep -q "$service"; then
        print_status "$service is running" ""
    else
        print_status "$service is not running" "Service should be started"
    fi
done

### PART 6: HDFS OPERATIONS ###
echo -e "\n${YELLOW}6. Testing HDFS Operations${NC}"

# Test HDFS operations
echo "Testing basic HDFS operations..."
test_dir="/test_verification_$(date +%s)"

# Create test directory
if hdfs dfs -mkdir "$test_dir" 2>/dev/null; then
    print_status "HDFS directory creation" "Test directory created: $test_dir"
    
    # Create test file
    echo "Test content" > /tmp/test_file
    if hdfs dfs -put /tmp/test_file "$test_dir" 2>/dev/null; then
        print_status "HDFS file upload" "Test file uploaded"
        
        # Clean up
        hdfs dfs -rm -r "$test_dir" >/dev/null 2>&1
        rm /tmp/test_file
    else
        print_status "HDFS file upload" "Failed to upload test file"
    fi
else
    print_status "HDFS operations" "Failed to create test directory"
fi

### PART 7: SUMMARY ###
echo -e "\n${YELLOW}=== Verification Summary ===${NC}"
echo "Please review any [✗] marks above and address them accordingly."
echo -e "\nTo fix any issues:"
echo "1. For SSH issues: Run fix_ssh.sh"
echo "2. For service issues: Run start-all.sh and mr-jobhistory-daemon.sh start historyserver"
echo "3. For permission issues: Check ownership and permissions of Hadoop directories"
echo "4. For configuration issues: Review the configuration files in $HADOOP_HOME/etc/hadoop/"

echo -e "\n${YELLOW}Useful commands for troubleshooting:${NC}"
echo "- View logs: ls -l $HADOOP_HOME/logs/"
echo "- Check service status: jps"
echo "- Start all services: $HADOOP_HOME/sbin/start-all.sh"
echo "- Stop all services: $HADOOP_HOME/sbin/stop-all.sh"
echo "- Format namenode: hdfs namenode -format"
