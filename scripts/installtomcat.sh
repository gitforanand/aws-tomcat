#!/bin/bash

set -e

sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

CATALINA_HOME=/opt/tomcat
TOMCAT_VERSION=9.0.0.M21

# Tar file name
TOMCAT9_CORE_TAR_FILENAME="apache-tomcat-$TOMCAT_VERSION.tar.gz"
# Download URL for Tomcat9 core
TOMCAT9_CORE_DOWNLOAD_URL="http://ftp.wayne.edu/apache/tomcat/tomcat-9/v$TOMCAT_VERSION/bin/$TOMCAT9_CORE_TAR_FILENAME"
# The top-level directory after unpacking the tar file
TOMCAT9_CORE_UNPACKED_DIRNAME="apache-tomcat-$TOMCAT_VERSION"


# Check whether there exists a valid instance
# of Tomcat9 installed at the specified directory
[[ -d $CATALINA_HOME ]] && { service tomcat9 status; } && {
    echo "Tomcat9 is already installed at $CATALINA_HOME. Skip reinstalling it."
    exit 0
}

# Clear install directory
if [ -d $CATALINA_HOME ]; then
    rm -rf $CATALINA_HOME
fi
mkdir -p $CATALINA_HOME

# Download the latest Tomcat9 version
cd /tmp
{ which wget; } || { sudo apt-get install -y wget; }
wget $TOMCAT9_CORE_DOWNLOAD_URL
if [[ -d /tmp/$TOMCAT9_CORE_UNPACKED_DIRNAME ]]; then
    rm -rf /tmp/$TOMCAT9_CORE_UNPACKED_DIRNAME
fi
tar xzf $TOMCAT9_CORE_TAR_FILENAME

# Copy over to the CATALINA_HOME
cp -r /tmp/$TOMCAT9_CORE_UNPACKED_DIRNAME/* $CATALINA_HOME

# Install Java if not yet installed
{ which java; } || { sudo apt-get install -y java; }


sudo chown -R tomcat:tomcat /opt/tomcat
sudo chmod -R 0755 /opt/tomcat/bin
sudo chmod -R 0755 /opt/tomcat/logs

# Create the service init.d script
cat > /etc/systemd/system/tomcat.service <<'EOF'
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-8-oracle/jre
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable tomcat.service
sudo systemctl daemon-reload

sudo systemctl start tomcat
sudo systemctl status tomcat
sudo ufw allow 8080
# Change permission mode for the service script
chmod 755 /etc/init.d/tomcat9
