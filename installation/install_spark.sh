#!/bin/bash

set -e

# Configuration variables
SPARK_VERSION="3.5.5"
HADOOP_VERSION="3.3.6"
SPARK_URL="https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz"
SPARK_INSTALL_DIR="/opt/spark"

# Check Java installation
if ! command -v java &> /dev/null; then
    echo "ERROR: Java is not installed. Please install Java 8 or 11 first."
    exit 1
fi

# ... rest of the script remains identical from the download section onward ...# Download Spark using official mirror
echo "Downloading Spark ${SPARK_VERSION}..."
wget "${SPARK_URL}" -O "spark-${SPARK_VERSION}-bin-hadoop3.tgz"

# Verify download integrity
wget "${SPARK_URL}.asc"
wget "https://downloads.apache.org/spark/KEYS"
gpg --import KEYS
gpg --verify "spark-${SPARK_VERSION}-bin-hadoop3.tgz.asc" "spark-${SPARK_VERSION}-bin-hadoop3.tgz"

# Install Spark
echo "Installing Spark to ${SPARK_INSTALL_DIR}..."
sudo tar xzf "spark-${SPARK_VERSION}-bin-hadoop3.tgz" -C /opt
sudo mv "/opt/spark-${SPARK_VERSION}-bin-hadoop3" "${SPARK_INSTALL_DIR}"
sudo chown -R ${USER}:${USER} "${SPARK_INSTALL_DIR}"

# Configure Spark environment
echo "Configuring Spark..."
export SPARK_HOME="${SPARK_INSTALL_DIR}"
export PATH="${PATH}:${SPARK_HOME}/bin:${SPARK_HOME}/sbin"

# Add to .bashrc
echo "export SPARK_HOME=${SPARK_INSTALL_DIR}" >> ~/.bashrc
echo "export PATH=\${PATH}:\${SPARK_HOME}/bin:\${SPARK_HOME}/sbin" >> ~/.bashrc

# Configure Hadoop integration
cat << EOF | tee "${SPARK_INSTALL_DIR}/conf/spark-env.sh" > /dev/null
export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
export LD_LIBRARY_PATH=${HADOOP_HOME}/lib/native:\${LD_LIBRARY_PATH}
EOF

# Verify installation
echo "Verifying Spark installation..."
source ~/.bashrc

# Version check
spark-submit --version

# Run a simple Spark test
echo "Running Spark test..."
cat << EOF > spark-test.py
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .master("local[*]") \
    .appName("InstallationTest") \
    .getOrCreate()

data = [("Hello", 1), ("World", 2)]
df = spark.createDataFrame(data, ["Word", "Count"])
df.show()
spark.stop()
EOF

spark-submit spark-test.py

# Cleanup
rm spark-test.py
rm spark-${SPARK_VERSION}-bin-hadoop3.tgz*
rm KEYS

echo "Spark ${SPARK_VERSION} successfully installed and verified!"
