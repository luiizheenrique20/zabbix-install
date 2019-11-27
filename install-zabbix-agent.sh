#!/bin/bash -e

# DESCRIPTION
    # This script install "zabbix-agent"

# NOTES
    # AUTHOR: Luiz Hossi
    # LASTEDIT: Aug 12, 2019

# Variables to set:
ZBX_SERVER_IP=172.31.46.122 # Server or proxy IP

if [ "$UID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

#   
if [ -x /usr/bin/apt-get ]; then
  dist=`cat -n /etc/lsb-release | grep -n ^ | grep ^3: | cut -d: -f2 | awk -F"=" '{ print $2 }'`
  wget https://repo.zabbix.com/zabbix/4.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.2-1+$dist"_all.deb"
  dpkg -i zabbix-release_4.2-1+$dist"_all.deb"
  apt-get update
  apt-get -y install zabbix-agent
  systemctl enable zabbix-agent
  sed -i 's/Server=127.0.0.1/Server='$ZBX_SERVER_IP'/' /etc/zabbix/zabbix_agentd.conf
  sed -i 's/ServerActive=127.0.0.1/ServerActive='$ZBX_SERVER_IP'/' /etc/zabbix/zabbix_agentd.conf
  HOSTNAME=`hostname` && sed -i "s/Hostname=Zabbix\ server/Hostname=$HOSTNAME/" /etc/zabbix/zabbix_agentd.conf
  systemctl restart zabbix-agent
fi

# Only run it if we can (ie. on RHEL/CentOS)
if [ -x /usr/bin/yum ]; then
  yum -y update
  rpm -Uvh https://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-1.el7.noarch.rpm
  yum -y install zabbix-agent
  chkconfig zabbix-agent on
  sed -i 's/Server=127.0.0.1/Server='$ZBX_SERVER_IP'/' /etc/zabbix/zabbix_agentd.conf
  sed -i 's/ServerActive=127.0.0.1/ServerActive='$ZBX_SERVER_IP'/' /etc/zabbix/zabbix_agentd.conf
  HOSTNAME=`hostname` && sed -i "s/Hostname=Zabbix\ server/Hostname=$HOSTNAME/" /etc/zabbix/zabbix_agentd.conf
  service zabbix-agent restart
fi
