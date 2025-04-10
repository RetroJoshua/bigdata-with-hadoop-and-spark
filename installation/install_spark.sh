#!/bin/bash

# Install Spark 3.3.3 with Hadoop 3 (Java 8 compatible)
# Updated for 2025 mirror locations

set -e

# Configuration
SPARK_VERSION="3.3.3"
HADOOP_VERSION="3"
SPARK_TAR="spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"
INSTALL_DIR="/opt/spark"
MIRROR_URL="https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_TAR}"

# Check existing download
if [ -f "$SPARK_TAR" ]; then
    echo "Resuming existing download..."
    wget -c "$MIRROR_URL" -O "$SPARK_TAR"
else
    echo "Downloading from Apache archive..."
    wget --show-progress "$MIRROR_URL" -O "$SPARK_TAR"
fi

# Verify checksum
echo "Validating package integrity..."
wget "https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz.sha512"
sha512sum -c "spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz.sha512"

# Install
echo "Installing to ${INSTALL_DIR}..."
sudo tar -xf "$SPARK_TAR" -C /opt
sudo mv "/opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" "$INSTALL_DIR"

# Configure environment in system-wide profile
echo "export SPARK_HOME=${INSTALL_DIR}" | sudo tee -a /etc/profile.d/spark.sh
echo "export PATH=\$PATH:\${SPARK_HOME}/bin" | sudo tee -a /etc/profile.d/spark.sh
sudo chmod +x /etc/profile.d/spark.sh

# Add to current user's .bashrc for immediate use
echo "Adding Spark to current user's environment..."
echo "export SPARK_HOME=${INSTALL_DIR}" >> ~/.bashrc
echo "export PATH=\$PATH:\${SPARK_HOME}/bin" >> ~/.bashrc

# Set environment variables for current session
export SPARK_HOME=${INSTALL_DIR}
export PATH=$PATH:${SPARK_HOME}/bin

# Cleanup
rm "${SPARK_TAR}" "spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz.sha512"

echo "Spark ${SPARK_VERSION} installed to ${INSTALL_DIR}"
echo "Environment variables set for current session and added to ~/.bashrc"
echo "To verify installation, run: spark-shell --version"
