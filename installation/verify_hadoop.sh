#!/bin/bash

# Hadoop Verification Script
# This script checks if Hadoop is properly installed and functioning in standalone mode

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

echo "=== Hadoop Installation Verification Script ==="
echo "Starting verification process..."
echo

# 1. Verify Java Installation
echo "1. Checking Java Installation..."
if command_exists java; then
    java -version 2>&1
    print_status "Java is installed"
else
    echo -e "${RED}[✗] Java is not installed${NC}"
    exit 1
fi
echo

# 2. Check Environment Variables
echo "2. Checking Environment Variables..."
if [ -n "$JAVA_HOME" ] && [ -n "$HADOOP_HOME" ]; then
    echo "JAVA_HOME = $JAVA_HOME"
    echo "HADOOP_HOME = $HADOOP_HOME"
    print_status "Environment variables are set"
else
    echo -e "${RED}[✗] Environment variables are not set properly${NC}"
    exit 1
fi
echo

# 3. Verify Hadoop Version
echo "3. Checking Hadoop Version..."
if command_exists hadoop; then
    hadoop version
    print_status "Hadoop is installed"
else
    echo -e "${RED}[✗] Hadoop is not installed or not in PATH${NC}"
    exit 1
fi
echo

# 4. Check Hadoop Configuration Files
echo "4. Checking Hadoop Configuration Files..."

# Check hadoop-env.sh
echo "Checking hadoop-env.sh..."
if grep -q "JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"; then
    print_status "hadoop-env.sh is properly configured"
else
    echo -e "${RED}[✗] hadoop-env.sh is not properly configured${NC}"
fi

# Check core-site.xml
echo "Checking core-site.xml..."
if grep -q "fs.defaultFS" "$HADOOP_HOME/etc/hadoop/core-site.xml"; then
    print_status "core-site.xml exists"
else
    echo -e "${RED}[✗] core-site.xml is not properly configured${NC}"
fi
echo

# 5. Run Test Job
echo "5. Running Test Job..."

# Create test directory and files
echo "Creating test files..."
mkdir -p ~/hadoop_test
echo "Hadoop is working" > ~/hadoop_test/file1.txt
echo "Hadoop standalone verification" > ~/hadoop_test/file2.txt
print_status "Test files created"

# Remove previous output directory if exists
rm -rf ~/hadoop_output

# Run WordCount example
echo "Running WordCount example..."
hadoop jar "$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-"*".jar" wordcount ~/hadoop_test ~/hadoop_output
print_status "WordCount job completed"

# Check output
echo "Checking job output..."
if [ -d ~/hadoop_output ]; then
    echo "WordCount Output:"
    cat ~/hadoop_output/*
    print_status "Output generated successfully"
else
    echo -e "${RED}[✗] No output generated${NC}"
fi
echo

# 6. Check Logs
echo "6. Checking Hadoop Logs..."
if [ -d "$HADOOP_HOME/logs" ]; then
    ls -l "$HADOOP_HOME/logs"
    print_status "Log directory exists"
else
    echo -e "${YELLOW}[!] No logs directory found${NC}"
fi
echo

# Final Summary
echo "=== Verification Summary ==="
echo -e "${GREEN}Verification process completed.${NC}"
echo "If all checks passed and WordCount example produced output, Hadoop is working correctly."
echo "Please review any warnings or errors above."

# Cleanup
read -p "Do you want to clean up test files? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf ~/hadoop_test ~/hadoop_output
    print_status "Cleanup completed"
fi
