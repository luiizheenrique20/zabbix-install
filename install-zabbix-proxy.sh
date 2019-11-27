#!bin/bash -e

# DESCRIPTION
    # This script install "zabbix-proxy-mysql" + "zabbix-agent" and configure MySQL

# NOTES
    # AUTHOR: Luiz Hossi
    # LASTEDIT: Aug 9, 2019
    # LASTEDIT BY: Marcelo Costa

# Variables to set:
ZBX_SERVER_IP=[zabbix server ip]
PROXY_NAME=[Bastion-Proxy-Claranet-Account-Name]
DB_NAME=[database name]
DB_USER_NAME=[database user name]
MYSQL_SECRET=[secret]

# Downloading zabbix
wget https://repo.zabbix.com/zabbix/4.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.2-1+bionic_all.deb

# Decompress & Update
sudo dpkg -i zabbix-release_4.2-1+bionic_all.deb && sudo apt update

# Install
sudo apt -y install zabbix-proxy-mysql zabbix-agent

# Config zabbix agent
sudo sed -i 's/Hostname=Zabbix server/Hostname='$PROXY_NAME'/' /etc/zabbix/zabbix_agentd.conf

# Config zabbix proxy
sudo sed -i 's/Server=127.0.0.1/Server='$ZBX_SERVER_IP'/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/# ServerPort=10051/ServerPort=10051/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/Hostname=Zabbix proxy/Hostname='$PROXY_NAME'/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/LogFileSize=0/LogFileSize=1024/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/DBName=zabbix_proxy/DBName='$DB_NAME'/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/DBUser=zabbix/DBUser='$DB_USER_NAME'/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/# DBPassword=/DBPassword='$MYSQL_SECRET'/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/# ProxyLocalBuffer=0/ProxyLocalBuffer=2/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/# HeartbeatFrequency=60/HeartbeatFrequency=300/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/# ConfigFrequency=3600/ConfigFrequency=300/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/# DataSenderFrequency=1/DataSenderFrequency=5/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/# StartPollers=5/StartPollers=5/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/# StartTrappers=5/StartTrappers=10/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/# StartPingers=1/StartPingers=5/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/# StartDiscoverers=1/StartDiscoverers=5/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/# HousekeepingFrequency=1/HousekeepingFrequency=4/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/# StartDBSyncers=4/StartDBSyncers=3/' /etc/zabbix/zabbix_proxy.conf
sudo sed -i 's/# AllowRoot=0/AllowRoot=1/' /etc/zabbix/zabbix_proxy.conf

# Restart agent and proxy, enable auto start
sudo service zabbix-agent restart && sudo service zabbix-proxy restart
sudo systemctl enable zabbix-proxy.service zabbix-agent.service

# Config MySQL
sudo mysql_secure_installation << EOF
y
$MYSQL_SECRET
$MYSQL_SECRET
y
y
y
y
EOF

# Config database settings
sudo mysql -uroot -p$MYSQL_SECRET -e "CREATE DATABASE $DB_NAME character set utf8 collate utf8_bin";
sudo mysql -uroot -p$MYSQL_SECRET -e "GRANT ALL PRIVILEGES ON $DB_NAME.* to $DB_USER_NAME@localhost IDENTIFIED BY '$MYSQL_SECRET'";
sudo mysql -uroot -p$MYSQL_SECRET -e "flush privileges";
zcat /usr/share/doc/zabbix-proxy-mysql/schema.sql.gz | mysql -u$DB_USER_NAME -p$MYSQL_SECRET $DB_NAME
